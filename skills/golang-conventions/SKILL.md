---
name: golang-conventions
description: Idiomatic Go conventions for solid engineering discipline - error handling, interfaces, concurrency, testing, naming, and project structure
---

# Go Conventions

## Overview

Go has strong opinions baked into the language and toolchain. Most style questions have a canonical answer from the Go team. Deviating from these conventions makes code harder to read, harder to maintain, and harder to review.

**Announce at start:** "I'm using the golang-conventions skill to apply idiomatic Go patterns."

**Sources:** Effective Go, Go Code Review Comments, Google Go Style Guide, Uber Go Style Guide.

## Core Mental Model

- **Errors are values** - return them, check them, wrap them. Never ignore them.
- **Interfaces belong to consumers** - define them where they are used, not where they are implemented.
- **Concurrency is explicit** - goroutines are cheap but not free; always know when one exits.
- **The zero value is useful** - design types so the zero value works without initialization.
- **Formatting is not a debate** - `gofmt` decides. Run it. Always.

## Naming

### MixedCaps everywhere

```go
maxLength      // not max_length or MAX_LENGTH
ServeHTTP      // initialisms stay all-caps: URL, ID, DB, API, HTTP, RPC
userID         // not userId or user_id
parseURL       // not parseUrl
```

### Package names

- All lowercase, no underscores, no mixedCaps: `tabwriter`, `oauth2`
- The package name is used at callsites - avoid repeating it in exported names:

```go
// Good - called as bufio.Reader
package bufio
type Reader struct{}

// Bad - called as bufio.BufReader
type BufReader struct{}
```

- Never name a package `util`, `common`, `helper`, `misc`, `api`, `types`, or `interfaces` - these names force consumers to rename imports and obscure intent.

### Variable name length proportional to scope

```go
// Short names for small scopes and common types
for i, v := range items { ... }
func (c *Client) Connect() { ... }   // c, not this or self
r io.Reader                          // r, w for reader/writer
ctx context.Context                  // always ctx

// Longer names as scope grows
func processUserRegistration(ctx context.Context, req *RegistrationRequest) error { ... }
```

### Getters and setters

```go
obj.Owner()         // getter - no Get prefix
obj.SetOwner(u)     // setter - Set prefix is fine
obj.ComputeHash()   // signals cost - use Compute, Fetch, Load for expensive ops
```

### Constants and enums

```go
// MixedCaps, not ALL_CAPS
const MaxPacketSize = 1024

// iota enums: start at 1 unless zero is a meaningful default
type Status int
const (
    Active Status = iota + 1
    Inactive
    Deleted
)
```

### Unexported globals

Prefix with `_` to make them visually distinct from locals:

```go
var _defaultTimeout = 5 * time.Second
var _mu sync.Mutex
```

## Error Handling

### Errors are the last return value

```go
func Open(path string) (*File, error)   // correct
func Open(path string) (error, *File)   // wrong
```

Always check errors. Never discard with `_` unless you have a documented reason.

### Error strings: lowercase, no trailing punctuation

```go
errors.New("connection refused")        // correct
errors.New("Connection refused.")       // wrong - appears mid-sentence in logs
```

### Indent error flow - keep the happy path left

```go
// Good - normal code flows left
if err != nil {
    return fmt.Errorf("open config: %w", err)
}
// normal code continues here

// Bad - normal code buried in else
if err != nil {
    return err
} else {
    process(f)
}
```

### Wrapping: `%w` vs `%v`

Use `%w` when callers should be able to inspect the underlying error with `errors.Is` / `errors.As`. Use `%v` to hide it (at system boundaries: RPC, storage, external APIs).

```go
// Wrapping - caller can errors.Is(err, fs.ErrNotExist)
return fmt.Errorf("read config: %w", err)

// Hiding - translating at a system boundary
return fmt.Errorf("internal error: %v", err)
```

By convention, place `%w` at the end of the format string - it reads naturally as "context: underlying error".

### When to use each error form

| Caller needs to match? | Message | Use |
|---|---|---|
| No | static | `errors.New("msg")` |
| No | dynamic | `fmt.Errorf("msg: %v", detail)` |
| Yes | static | `var ErrFoo = errors.New("msg")` |
| Yes | dynamic | custom type implementing `Error() string` |

Sentinel error naming: `ErrXxx` (exported) or `errXxx` (unexported).
Custom error type naming: `XxxError` suffix (e.g., `NotFoundError`).

### Handle each error once

Either log it or return it - never both. Double-handling causes log spam and confuses callers.

### `os.Exit` and `log.Fatal` belong in `main` only

Library functions must never call `os.Exit`. Use this pattern:

```go
func main() {
    if err := run(); err != nil {
        fmt.Fprintln(os.Stderr, err)
        os.Exit(1)
    }
}

func run() error {
    // all business logic here
}
```

### Don't panic for normal error handling

Panic is acceptable for: program initialization failures, invariant violations that indicate a bug, and API misuse in libraries (only if it never escapes the package boundary). In all other cases, return an error.

In tests: use `t.Fatal` / `t.FailNow`, not `panic`.

## Interfaces

### Define interfaces at the consumer, not the producer

```go
// Good - consumer defines the interface it needs
package consumer

type Thinger interface {
    Thing() bool
}

func Foo(t Thinger) string { ... }

// Good - producer returns a concrete type
package producer

type Thinger struct{}
func (t Thinger) Thing() bool { ... }
func NewThinger() Thinger { return Thinger{} }

// Bad - producer defines an interface "for mocking"
package producer

type Thinger interface { Thing() bool }  // don't do this
func NewThinger() Thinger { ... }
```

### Keep interfaces small

Single-method interfaces are idiomatic and powerful: `io.Reader`, `io.Writer`, `fmt.Stringer`. Name them with the method + `-er` suffix: `Reader`, `Writer`, `Closer`.

Don't define an interface before you have two distinct implementations - you can't know the right shape yet.

### Never use a pointer to an interface

```go
var r io.Reader = &os.File{...}   // correct
var r *io.Reader = ...            // almost never correct
```

Interface values already contain a pointer internally. A pointer to an interface is nearly always a mistake.

### Verify interface compliance at compile time

```go
var _ http.Handler = (*Handler)(nil)   // pointer receiver implementation
var _ http.Handler = LogHandler{}      // value receiver implementation
```

This causes a compile error if the type stops satisfying the interface.

### Value vs pointer receivers and interface satisfaction

- Value receiver methods are in the method set of both `T` and `*T`
- Pointer receiver methods are only in the method set of `*T`
- If any method uses a pointer receiver, use pointer receivers for all methods on that type - don't mix

## Functions and Methods

### Receiver type: pointer vs value

Use a **pointer receiver** when:
- The method mutates the receiver
- The receiver contains a mutex or other sync field (copying breaks it)
- The receiver is a large struct
- Any other method on the type uses a pointer receiver (be consistent)

Use a **value receiver** when:
- The receiver is a small, naturally immutable value type (like `time.Time`)
- No method on the type needs a pointer receiver

When in doubt, use a pointer receiver.

### Context is always first, named `ctx`

```go
func DoThing(ctx context.Context, arg string) error { ... }
```

Never store a `context.Context` in a struct field. Pass it as a parameter to every function that may block or do I/O.

### Functional options for complex constructors

```go
type Server struct {
    host    string
    timeout time.Duration
}

type Option func(*Server)

func WithTimeout(d time.Duration) Option {
    return func(s *Server) { s.timeout = d }
}

func NewServer(host string, opts ...Option) *Server {
    s := &Server{host: host, timeout: 30 * time.Second}
    for _, opt := range opts {
        opt(s)
    }
    return s
}

s := NewServer("localhost", WithTimeout(60*time.Second))
```

Use this pattern when a constructor would otherwise take many parameters, or when parameters are optional.

### Defer for cleanup

```go
f, err := os.Open(path)
if err != nil {
    return err
}
defer f.Close()
```

`defer` ensures cleanup runs on all code paths. Use it for `Close`, `Unlock`, `cancel`, and similar teardown.

Avoid `defer` inside loops - deferred calls accumulate until the function returns, not the iteration.

```go
// Bug: files not closed until function returns
for _, path := range paths {
    f, _ := os.Open(path)
    defer f.Close()  // wrong
}

// Fix: wrap in a function
for _, path := range paths {
    func() {
        f, err := os.Open(path)
        if err != nil { return }
        defer f.Close()
        process(f)
    }()
}
```

## Concurrency

### Always know when a goroutine exits

Never fire-and-forget. Goroutines that block forever are leaks - the GC does not collect them.

```go
var wg sync.WaitGroup
wg.Add(1)
go func() {
    defer wg.Done()
    doWork()
}()
wg.Wait()
```

### Prefer synchronous APIs

Let callers add concurrency by calling your function from a goroutine. Synchronous functions are easier to test, compose, and reason about.

### Channel sizing

- Default: unbuffered (`make(chan T)`)
- Size 1: handoff patterns where sender must not block
- Larger sizes: require documented justification

Use `chan struct{}` for signaling - zero allocation.

### Only the sender closes a channel

Closing signals "no more values." Closing from the receiver side, or closing twice, panics.

```go
// Cancellation via done channel
done := make(chan struct{})
defer close(done)  // signals all workers to stop

go func() {
    select {
    case work <- item:
    case <-done:
        return
    }
}()
```

### Embed mutexes as unexported fields

```go
// Good - mutex is unexported, not part of public API
type SafeMap struct {
    mu   sync.Mutex
    data map[string]string
}

// Bad - embedding leaks Lock/Unlock into public API
type SafeMap struct {
    sync.Mutex  // don't embed
    data map[string]string
}
```

`sync.Mutex` zero value is unlocked and ready to use - no initialization needed.

Use `defer mu.Unlock()` immediately after `mu.Lock()`.

### Use `errgroup` for goroutine groups

```go
import "golang.org/x/sync/errgroup"

g, ctx := errgroup.WithContext(ctx)
g.Go(func() error { return fetchA(ctx) })
g.Go(func() error { return fetchB(ctx) })
if err := g.Wait(); err != nil {
    return err
}
```

### Always run tests with the race detector

```sh
go test -race ./...
```

Run this in CI on every commit. The race detector catches data races that are otherwise nearly impossible to reproduce.

## Types and Structs

### Design for the zero value

```go
var mu sync.Mutex     // valid, unlocked
var buf bytes.Buffer  // valid, empty, ready to use
var items []string    // nil slice - preferred over items := []string{}
```

A nil slice has length 0 and can be appended to. Note: a nil slice marshals to `null` in JSON, while an empty slice (`[]string{}`) marshals to `[]`. If the JSON distinction matters, use an empty slice literal; otherwise prefer nil.

### Use field names when initializing structs from other packages

```go
// Good - explicit, resilient to field reordering
r := csv.Reader{
    Comma:   ',',
    Comment: '#',
}

// Bad - breaks if fields are reordered
r := csv.Reader{',', '#', ...}
```

### Don't embed types in public structs

Embedding leaks the embedded type's entire API as your own and prevents future evolution.

```go
// Bad - all AbstractList methods become public API
type ConcreteList struct {
    *AbstractList
}

// Good - explicit delegation
type ConcreteList struct {
    list *AbstractList
}
func (l *ConcreteList) Add(e Entity) { l.list.Add(e) }
```

### Copy slices and maps at API boundaries

```go
// Bug: caller can mutate internal state
func (d *Driver) SetTrips(trips []Trip) {
    d.trips = trips
}

// Fix: copy incoming data
func (d *Driver) SetTrips(trips []Trip) {
    d.trips = make([]Trip, len(trips))
    copy(d.trips, trips)
}
```

## Testing

### Table-driven tests are the canonical pattern

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name    string
        a, b    int
        want    int
    }{
        {name: "positive", a: 1, b: 2, want: 3},
        {name: "negative", a: -1, b: -2, want: -3},
        {name: "zero", a: 0, b: 0, want: 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
            }
        })
    }
}
```

- Use `t.Run` for subtests - output is `TestAdd/positive`, `TestAdd/negative`
- Error message format: `got X; want Y` (actual before expected)
- `t.Errorf` continues the test; `t.Fatalf` stops it immediately

### Mark test helpers with `t.Helper()`

```go
func mustParseURL(t *testing.T, s string) *url.URL {
    t.Helper()  // stack traces point to the caller, not this function
    u, err := url.Parse(s)
    if err != nil {
        t.Fatalf("mustParseURL(%q): %v", s, err)
    }
    return u
}
```

Without `t.Helper()`, failure output points to the helper line instead of the test case that called it.

### Prefer real implementations over mocks

Test against the real implementation using the public API. Define interfaces at the consumer when you need a test double - don't define them in the production package "for mocking."

Use `google/go-cmp` (`cmp.Diff`) for comparing complex structs:

```go
if diff := cmp.Diff(want, got); diff != "" {
    t.Errorf("mismatch (-want +got):\n%s", diff)
}
```

### Testable examples

```go
func ExampleSort() {
    s := []int{5, 2, 4, 1, 3}
    sort.Ints(s)
    fmt.Println(s)
    // Output:
    // [1 2 3 4 5]
}
```

These appear in godoc and run as tests. They verify that documentation stays correct.

## Common Pitfalls

### nil interface vs nil concrete value

```go
// Bug: returns a non-nil interface wrapping a nil pointer
func getError() error {
    var e *MyError = nil
    return e  // interface value is (*MyError, nil) - NOT nil
}

// Fix: return untyped nil
func getError() error {
    return nil
}
```

An interface value is nil only when both its type and value are nil. Returning a typed nil pointer as an `error` interface produces a non-nil interface.

### Closures capturing loop variables (Go < 1.22)

```go
// Bug: all goroutines capture the same variable
for _, v := range items {
    go func() { process(v) }()  // v is the last value by the time goroutines run
}

// Fix pre-1.22: shadow the variable inside the loop
for _, v := range items {
    v := v
    go func() { process(v) }()
}
// Go 1.22+: loop variables are per-iteration automatically
```

### Copying a type that contains a mutex

```go
// Bug: copies the mutex, which is undefined behavior if locked
s2 := s  // if s contains sync.Mutex

// Fix: always use a pointer when a mutex is involved
func process(s *SafeStruct) { ... }
```

### Context variable shadowing

```go
// Bug: inner ctx shadows outer; outer ctx is unchanged after the if block
func handle(ctx context.Context) {
    if needsTimeout {
        ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
        defer cancel()
    }
    doWork(ctx)  // still using original ctx
}

// Fix: declare cancel before the conditional so = can reassign it
func handle(ctx context.Context) {
    var cancel context.CancelFunc
    if needsTimeout {
        ctx, cancel = context.WithTimeout(ctx, 3*time.Second)
        defer cancel()
    }
    doWork(ctx)  // uses the updated ctx
}
```

### Type assertion without the comma-ok idiom

```go
// Bug: panics if the assertion fails
s := i.(string)

// Fix: always use comma-ok
s, ok := i.(string)
if !ok {
    // handle gracefully
}
```

### Using `math/rand` for security-sensitive values

```go
// Bug: predictable
token := strconv.Itoa(rand.Int())

// Fix: use crypto/rand
b := make([]byte, 32)
_, err := cryptorand.Read(b)
token := hex.EncodeToString(b)
```

### Mutable global state

```go
// Bug: global state makes tests flaky and hard to parallelize
var _now = time.Now

// Fix: inject dependencies
type Service struct {
    now func() time.Time
}
func NewService() *Service { return &Service{now: time.Now} }
```

## Project Structure

### Organize by domain, not by type

```
myapp/
  cmd/
    myapp/
      main.go         # thin - calls run()
  internal/
    auth/
      handler.go
      service.go
      store.go
    billing/
      handler.go
      service.go
  pkg/                # exported packages for external use (if any)
```

Avoid flat `handlers/`, `models/`, `services/` folders that mix unrelated concerns.

### `internal/` for packages not meant for external use

Code under `internal/` can only be imported by code in the parent tree. Use it aggressively to keep your public API surface small.

### `cmd/` for binaries

Each binary gets its own subdirectory under `cmd/`. The `main.go` in each should be thin - parse flags, call `run()`, handle the error.

### Avoid `init()`

`init()` runs automatically, is hard to test, and creates ordering dependencies. Prefer explicit initialization:

```go
// Bad
func init() {
    data, _ := os.ReadFile("config.yaml")
    yaml.Unmarshal(data, &globalConfig)
}

// Good - explicit, testable
func loadConfig(path string) (*Config, error) { ... }
// Called in main() or run()
```

If `init()` is unavoidable: it must be deterministic, must not do I/O, must not start goroutines.

## Modules and Dependencies

### Keep `go.mod` tidy

```sh
go mod tidy   # add missing, remove unused dependencies
```

Run this before every commit. CI should verify `go.mod` and `go.sum` are clean:

```sh
go mod tidy && git diff --exit-code go.mod go.sum
```

### Minimal Version Selection

Go picks the minimum version satisfying all requirements - not the latest. This makes builds reproducible without a separate lock file. `go.sum` records checksums, not selected versions.

### Major version bumps require a path suffix

```go
// v2+ modules must have /v2 in the module path
module github.com/foo/bar/v2

// All imports must use the suffix
import "github.com/foo/bar/v2/pkg"
```

## Tooling

### Non-negotiable baseline

```sh
goimports -w .      # gofmt + manages imports (run on every save)
go vet ./...        # catches real bugs: printf format mismatches, atomic misuse, composite literal issues
```

`gofmt` / `goimports` is not optional. All Go code is formatted the same way. Configure your editor to run `goimports` on save.

### Highly recommended

```sh
staticcheck ./...   # comprehensive static analysis - catches deprecated APIs, bugs, style
golangci-lint run   # meta-linter: runs multiple linters in parallel
go test -race ./... # data race detector - run in CI on every commit
govulncheck ./...   # check for known vulnerabilities in dependencies
```

### Recommended CI sequence

```sh
go mod tidy && git diff --exit-code go.mod go.sum   # module hygiene
goimports -l . | grep . && exit 1 || true           # formatting
go vet ./...                                         # correctness
staticcheck ./...                                    # static analysis
go test -race ./...                                  # tests + race detector
```

## Example Workflow

A realistic function applying multiple conventions together - an HTTP handler that fetches a user and returns their profile:

```go
package user

import (
    "context"
    "errors"
    "fmt"
    "net/http"

    "github.com/myorg/myapp/internal/store"
)

// ErrNotFound is returned when the requested user does not exist.
var ErrNotFound = errors.New("user not found")

// ProfileHandler handles GET /users/{id}/profile.
// It satisfies http.Handler via a pointer receiver.
type ProfileHandler struct {
    store store.UserStore  // interface defined here in the consumer package
}

func NewProfileHandler(s store.UserStore) *ProfileHandler {
    return &ProfileHandler{store: s}
}

// Compile-time interface check.
var _ http.Handler = (*ProfileHandler)(nil)

func (h *ProfileHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    // Context flows through; never stored in struct.
    ctx := r.Context()

    id := r.PathValue("id")
    profile, err := h.fetchProfile(ctx, id)
    if err != nil {
        // Handle each error once - log OR return, not both.
        if errors.Is(err, ErrNotFound) {
            http.Error(w, "not found", http.StatusNotFound)
            return
        }
        http.Error(w, "internal error", http.StatusInternalServerError)
        return
    }

    // Happy path flows left - no else needed.
    writeJSON(w, profile)
}

func (h *ProfileHandler) fetchProfile(ctx context.Context, id string) (*Profile, error) {
    user, err := h.store.GetUser(ctx, id)
    if err != nil {
        // Wrap with %w so callers can errors.Is(err, store.ErrNotFound).
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return toProfile(user), nil
}
```

Key patterns demonstrated:
- Interface (`store.UserStore`) defined in the consumer package, not the store package
- Compile-time interface compliance check
- `context.Context` as first parameter, never stored in struct
- Error wrapping with `%w` for caller inspection
- Indent-the-error-flow: happy path stays left
- Handle each error once - no logging and returning
- Pointer receiver used consistently (handler mutates nothing, but consistency with other methods)
- `ErrNotFound` sentinel with `Err` prefix

## Quick Reference

| Pattern | Correct | Wrong |
|---|---|---|
| Error last | `func F() (T, error)` | `func F() (error, T)` |
| Error string | `"something failed"` | `"Something failed."` |
| Error wrapping | `fmt.Errorf("do x: %w", err)` | `fmt.Errorf("do x: " + err.Error())` |
| Interface location | defined in consumer package | defined in producer package |
| Pointer to interface | almost never | `var r *io.Reader` |
| Receiver naming | `func (c *Client)` | `func (this *Client)` |
| Context parameter | first, named `ctx` | stored in struct field |
| Nil slice | `var s []string` | `s := []string{}` |
| Struct init | named fields | positional fields (external types) |
| Mutex embedding | unexported field `mu sync.Mutex` | embedded `sync.Mutex` |
| Loop goroutine (pre-1.22) | `v := v` inside loop | capture loop var directly |
| Type assertion | `v, ok := x.(T)` | `v := x.(T)` |
| Formatting | `goimports` on save | manual import management |

## Never / Always

**Never:**
- Ignore a returned error without a documented reason
- Define interfaces in the package that implements them
- Use a pointer to an interface
- Mix value and pointer receivers on the same type
- Call `os.Exit` or `log.Fatal` outside of `main`
- Use `panic` for normal error handling
- Store `context.Context` in a struct field
- Use `math/rand` for security-sensitive random values
- Embed `sync.Mutex` (or any sync type) as a public embedded field
- Use `init()` for I/O, goroutines, or global state mutation

**Always:**
- Run `goimports` on every save
- Run `go test -race ./...` in CI
- Run `go mod tidy` before committing
- Check errors - every one
- Define interfaces at the consumer
- Pass `context.Context` as the first parameter
- Use `t.Helper()` in test helper functions
- Use table-driven tests with `t.Run`
- Design types so the zero value is useful
- Use `%w` when callers need to inspect wrapped errors
