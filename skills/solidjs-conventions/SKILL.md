---
name: solidjs-conventions
description: Best conventions for writing SolidJS front ends - signals, reactivity, control flow, stores, effects, and component patterns
---

# SolidJS Conventions

## Overview

SolidJS has a fundamentally different execution model from React. Components run once as setup code; reactivity is fine-grained and subscription-based. Violating these conventions silently breaks reactivity rather than throwing errors.

**Announce at start:** "I'm using the solidjs-conventions skill to apply correct SolidJS patterns."

## Core Mental Model

- **Components run once** - the function body is setup code, not a render function. There is no re-render cycle.
- **Signals are functions** - read a signal by calling it: `count()`, not `count`.
- **Subscriptions are set up in reactive contexts** - JSX expressions, `createEffect`, `createMemo`, and `createResource` track signal reads automatically. Outside these contexts, reads are untracked.
- **Destructuring breaks reactivity** - pulling a value out of a signal or props into a plain variable severs the reactive link.

## Signals and State

### Primitive values - use `createSignal`

```tsx
const [count, setCount] = createSignal(0);

// Read
count()           // correct
count             // wrong - this is the getter function, not the value

// Write
setCount(1)
setCount(prev => prev + 1)
```

### Nested or complex objects - use `createStore`

```tsx
import { createStore, produce } from "solid-js/store";

const [form, setForm] = createStore({ name: "", email: "" });

// Read
form.name         // correct - store properties are reactive getters

// Write with produce for complex updates
setForm(produce(s => { s.name = "Alice"; }));

// Simple property update
setForm("name", "Alice");
```

Use `createStore` for form state, lists, and any object with multiple reactive fields.

### Derived state - use `createMemo`

```tsx
const doubled = createMemo(() => count() * 2);

// Read like a signal
doubled()
```

Never derive state by setting one signal inside an effect that reads another. Use `createMemo` instead.

## Effects

### `createEffect` - for side effects only

```tsx
createEffect(() => {
  console.log("count changed:", count());
  // API calls, DOM manipulation, logging
});
```

Reserve `createEffect` for side effects. If you find yourself setting a signal inside an effect, use `createMemo` instead.

### `onMount` - for one-time setup

```tsx
onMount(() => {
  // Runs once after the component is mounted to the DOM
});
```

Do not wrap one-time setup in `createEffect` - use `onMount`.

### `onCleanup` - for teardown

```tsx
createEffect(() => {
  const id = setInterval(() => tick(), 1000);
  onCleanup(() => clearInterval(id));
});
```

`onCleanup` can also be called at the top level of a component to run on unmount.

### Explicit tracking control

```tsx
import { on, untrack } from "solid-js";

// Depend only on `source`, not on anything read inside `fn`
createEffect(on(source, (value) => {
  const other = untrack(() => otherSignal());
  // ...
}));

// Read a signal without subscribing
const snapshot = untrack(() => count());
```

Use `on` when you want an effect to re-run only when specific signals change. Use `untrack` to read a signal without creating a dependency.

## Props

### Never destructure props at the top level

```tsx
// Wrong - breaks reactivity
function Greeting({ name }: { name: string }) { ... }

// Correct
function Greeting(props: { name: string }) {
  return <div>Hello {props.name}</div>;
}
```

### Use `mergeProps` for defaults

```tsx
import { mergeProps } from "solid-js";

function Button(props: ButtonProps) {
  const merged = mergeProps({ color: "blue", size: "md" }, props);
  return <button class={merged.color}>{merged.size}</button>;
}
```

### Use `splitProps` to forward a subset of props

```tsx
import { splitProps } from "solid-js";

function Input(props: InputProps) {
  const [local, rest] = splitProps(props, ["label", "error"]);
  return (
    <label>
      {local.label}
      <input {...rest} />
      {local.error && <span>{local.error}</span>}
    </label>
  );
}
```

## Control Flow

Use Solid's built-in control flow components. They are optimized to avoid unnecessary DOM recreation.

### Conditional rendering - `<Show>`

```tsx
<Show when={isLoggedIn()} fallback={<Login />}>
  <Dashboard />
</Show>
```

### List rendering - `<For>`

```tsx
<For each={items()} fallback={<p>No items</p>}>
  {(item) => <li>{item.name}</li>}
</For>
```

### Multi-branch conditionals - `<Switch>` / `<Match>`

```tsx
<Switch fallback={<NotFound />}>
  <Match when={route() === "home"}><Home /></Match>
  <Match when={route() === "about"}><About /></Match>
</Switch>
```

Prefer `<Show>` and `<Switch>` over ternaries or `&&` for conditional rendering, especially when the condition involves signals or the branches are non-trivial. Simple static conditions are fine with `&&`.

## Async Data

### Use `createResource` for async data fetching

```tsx
const [data, { refetch }] = createResource(userId, fetchUser);

// data() - the resolved value
// data.loading - boolean
// data.error - error if rejected
```

`createResource` integrates with `<Suspense>` and `<ErrorBoundary>` automatically.

### Wrap with `<Suspense>` and `<ErrorBoundary>`

```tsx
<ErrorBoundary fallback={(err) => <p>Error: {err.message}</p>}>
  <Suspense fallback={<Spinner />}>
    <UserProfile />
  </Suspense>
</ErrorBoundary>
```

### Code splitting with `lazy`

```tsx
import { lazy } from "solid-js";

const Settings = lazy(() => import("./Settings"));

// Use inside <Suspense>
<Suspense fallback={<Spinner />}>
  <Settings />
</Suspense>
```

## Context

Use `createContext` / `useContext` for dependency injection: theme, auth, router, i18n.

```tsx
const ThemeContext = createContext<Theme>();

function ThemeProvider(props: { children: JSX.Element }) {
  const [theme, setTheme] = createSignal<Theme>("light");
  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {props.children}
    </ThemeContext.Provider>
  );
}

function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme must be used inside ThemeProvider");
  return ctx;
}
```

Avoid context for highly dynamic state that changes frequently - pass signals directly instead.

## TypeScript

### Type props with `Component<T>` or explicit interfaces

```tsx
import { Component } from "solid-js";

interface CardProps {
  title: string;
  body: string;
  onClose?: () => void;
}

const Card: Component<CardProps> = (props) => (
  <div>
    <h2>{props.title}</h2>
    <p>{props.body}</p>
    <Show when={props.onClose !== undefined}>
      <button onClick={props.onClose}>Close</button>
    </Show>
  </div>
);
```

## Project Organization

Organize by feature, not by type:

```
src/
  features/
    auth/
      AuthProvider.tsx    # context + signals
      LoginForm.tsx
      auth.css
    dashboard/
      Dashboard.tsx
      useDashboardData.ts # createResource wrappers
      dashboard.css
  shared/
    ui/
      Button.tsx
      Input.tsx
```

Avoid flat `components/`, `hooks/`, `utils/` folders that mix unrelated concerns.

## Styles

Colocate styles with components. Prefer one of:

- **CSS Modules** - `import styles from "./Button.module.css"`
- **Tailwind** - utility classes directly in JSX
- **Solid's `css` tagged template** - for dynamic, scoped styles

Scoped styles prevent leakage across components.

## Example Workflow

A complete component applying multiple conventions together:

```tsx
import { Component, createSignal, createMemo, createResource, Show, For } from "solid-js";
import { createStore, produce } from "solid-js/store";
import { mergeProps, splitProps } from "solid-js";

interface TodoListProps {
  userId: string;
  title?: string;
}

const TodoList: Component<TodoListProps> = (rawProps) => {
  // Defaults via mergeProps - reactive, not destructured
  const props = mergeProps({ title: "My Todos" }, rawProps);

  // Async data with createResource - integrates with Suspense/ErrorBoundary
  const [todos] = createResource(() => props.userId, fetchTodos);

  // Local state with createStore for complex objects
  const [newTodo, setNewTodo] = createStore({ text: "", priority: "normal" });

  // Derived state with createMemo - not createEffect
  const completedCount = createMemo(() =>
    todos()?.filter(t => t.done).length ?? 0
  );

  function addTodo() {
    setNewTodo(produce(s => { s.text = ""; }));
  }

  return (
    // JSX expressions are reactive - todos() and completedCount() are called here
    <div>
      <h2>{props.title}</h2>
      <p>{completedCount()} completed</p>
      <Show when={!todos.loading} fallback={<Spinner />}>
        <For each={todos()}>
          {(todo) => <TodoItem todo={todo} />}
        </For>
      </Show>
      <input
        value={newTodo.text}
        onInput={(e) => setNewTodo("text", e.currentTarget.value)}
      />
      <button onClick={addTodo}>Add</button>
    </div>
  );
};
```

Key patterns demonstrated:
- `mergeProps` for defaults instead of destructuring
- `createResource` for async data
- `createStore` + `produce` for complex local state
- `createMemo` for derived values
- `<Show>` and `<For>` for control flow
- Signal calls (`todos()`, `completedCount()`) inside JSX, not captured outside

## Quick Reference

| Pattern | Correct | Wrong |
|---|---|---|
| Read a signal | `count()` | `count` |
| Props access | `props.name` | `const { name } = props` |
| Defaults | `mergeProps(defaults, props)` | `props.name ?? "default"` in body |
| Derived state | `createMemo(() => ...)` | `createEffect` setting a signal |
| One-time setup | `onMount(() => ...)` | `createEffect` with no deps |
| Conditional render | `<Show when={...}>` | `{cond && <Comp />}` (for complex cases) |
| List render | `<For each={...}>` | `.map()` in JSX |
| Async data | `createResource` | `createEffect` + `fetch` + `setData` |
| Prop forwarding | `splitProps` | spread after destructure |

## Never / Always

**Never:**
- Destructure props at the top level of a component
- Use `createEffect` to derive or sync state between signals
- Read signals outside reactive contexts and expect updates
- Use `.map()` for list rendering when `<For>` is available
- Wrap one-time setup in `createEffect`

**Always:**
- Call signals as functions to read their value
- Use `mergeProps` for prop defaults and `splitProps` for forwarding
- Use `createMemo` for computed values
- Use `<Show>`, `<For>`, `<Switch>` for control flow
- Wrap async components in `<Suspense>` and `<ErrorBoundary>`
- Use `createResource` for data fetching
- Keep JSX expressions reactive - write `{count()}` not a captured variable
