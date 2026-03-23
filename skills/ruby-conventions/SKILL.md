---
name: ruby-conventions
description: Idiomatic Ruby conventions for solid engineering discipline - naming, error handling, blocks, testing, metaprogramming, and project structure
---

# Ruby Conventions

## Overview

Ruby has a strong community culture around readability, expressiveness, and convention over configuration. Most style questions have a canonical answer from the Ruby Style Guide and the broader community. Deviating from these conventions makes code harder to read, harder to maintain, and harder to review.

**Announce at start:** "I'm using the ruby-conventions skill to apply idiomatic Ruby patterns."

**Sources:** Ruby Style Guide (rubocop), Sandi Metz's rules, Confident Ruby (Avdi Grimm), Rails conventions (where applicable).

## Core Mental Model

- **Everything is an object** - integers, strings, nil, true, false. Use this to write expressive code.
- **Convention over configuration** - follow naming conventions and directory layouts; tools and humans expect them.
- **Duck typing over type checking** - ask "can it quack?" not "is it a duck?" Respond to messages, not classes.
- **Blocks are fundamental** - they are not callbacks or lambdas bolted on; they are core to how Ruby flows.
- **Least surprise** - code should do what a reader expects. If a method name sounds like a query, it should not mutate state.

## Naming

### snake_case everywhere

```ruby
max_length       # local variables and methods
user_id          # not userId or userID
parse_url        # not parseUrl or parseURL
MAX_PACKET_SIZE  # constants are SCREAMING_SNAKE_CASE
```

### Class and module names are CamelCase

```ruby
class UserProfile; end       # not User_Profile or Userprofile
module HTTPClient; end       # not HttpClient or Http_Client
class CSVParser; end         # acronyms stay all-caps: HTTP, CSV, JSON, HTML, SSL, XML
```

### Predicate methods end with `?`

```ruby
def empty?
  @items.length.zero?
end

def valid?
  errors.empty?
end
```

Return truthy/falsy values. Do not return strings or numbers from `?` methods.

### Dangerous methods end with `!`

```ruby
# Bang methods indicate a "dangerous" variant - usually mutates in place or raises on failure
array.sort     # returns a new sorted array
array.sort!    # sorts in place

user.save      # returns false on failure
user.save!     # raises on failure
```

The `!` does not mean "mutates" - it means "this is the more dangerous of a pair." Only use `!` when a non-bang counterpart exists.

### Method name length proportional to scope

```ruby
# Short names for small scopes and common patterns
items.each { |v| process(v) }
users.map(&:name)

# Longer names as scope and complexity grow
def process_user_registration(params)
  # ...
end
```

### Getters and setters

```ruby
# Use attr_reader, attr_writer, attr_accessor - not manual get/set methods
class User
  attr_reader :name          # generates def name; @name; end
  attr_accessor :email       # generates reader and writer

  def initialize(name, email)
    @name = name
    @email = email
  end
end

# Never write Java-style getters
def get_name    # wrong
  @name
end
```

### Boolean attribute accessors

```ruby
# For boolean attributes, define a predicate method
class User
  attr_reader :active

  def active?
    @active
  end
end
```

## Error Handling

### Use exceptions for exceptional conditions

```ruby
# Good - exception for something truly unexpected
def find_user!(id)
  user = User.find_by(id: id)
  raise UserNotFoundError, "no user with id #{id}" unless user
  user
end

# Good - return nil for expected "not found" cases
def find_user(id)
  User.find_by(id: id)
end
```

### Custom exception classes inherit from StandardError

```ruby
# Good - inherits from StandardError (caught by bare rescue)
class UserNotFoundError < StandardError; end
class InvalidTokenError < StandardError; end

# Bad - inherits from Exception (not caught by bare rescue, reserved for system errors)
class UserNotFoundError < Exception; end
```

### Never use bare rescue

```ruby
# Bad - catches StandardError and all subclasses silently
begin
  do_something
rescue
  nil
end

# Bad - catches Exception, including NoMemoryError, SignalException, SystemExit
begin
  do_something
rescue Exception => e
  log(e)
end

# Good - catch specific exceptions
begin
  do_something
rescue UserNotFoundError => e
  handle_not_found(e)
rescue ActiveRecord::RecordInvalid => e
  handle_validation(e)
end
```

### Rescue modifier for simple cases only

```ruby
# Acceptable for simple, non-critical fallbacks
value = Integer(input) rescue nil

# Bad - hides complex error handling in a one-liner
result = complex_operation_that_might_fail_many_ways rescue default_value
```

### Retry with limits

```ruby
def fetch_with_retry(url, max_attempts: 3)
  attempts = 0
  begin
    attempts += 1
    http_get(url)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise if attempts >= max_attempts
    sleep(2**attempts)
    retry
  end
end
```

### Ensure for cleanup

```ruby
def process_file(path)
  file = File.open(path)
  parse(file.read)
rescue IOError => e
  log_error(e)
  raise
ensure
  file&.close
end

# Better - use blocks that handle cleanup automatically
def process_file(path)
  File.open(path) do |file|
    parse(file.read)
  end
end
```

Prefer block forms (`File.open`, `Tempfile.create`, `Dir.mktmpdir`) that handle cleanup automatically over explicit `ensure`.

### Handle each error once

Either log it or raise it - never both. Double-handling causes log spam and confuses callers.

## Blocks, Procs, and Lambdas

### Blocks are the default

```ruby
# Use blocks for iteration, resource management, and callbacks
[1, 2, 3].each { |n| puts n }

File.open("data.txt") do |f|
  process(f)
end
```

### Braces for single-line, do/end for multi-line

```ruby
# Single-line: braces
names = users.map { |u| u.name }

# Multi-line: do/end
users.each do |user|
  validate(user)
  save(user)
end
```

This is not just style - braces bind tighter than `do/end`, which matters when chaining or passing blocks to methods.

### Symbol-to-proc shorthand

```ruby
# Good - concise and idiomatic
names = users.map(&:name)
valid_users = users.select(&:valid?)

# Equivalent but verbose
names = users.map { |u| u.name }
```

Use `&:method_name` when the block simply calls one method with no arguments on the yielded object.

### Proc vs Lambda

```ruby
# Lambda: strict arity, return exits the lambda
validator = ->(x) { x > 0 }
validator = lambda { |x| x > 0 }

# Proc: loose arity, return exits the enclosing method
handler = proc { |x| process(x) }
handler = Proc.new { |x| process(x) }
```

Prefer lambdas over procs. Lambdas behave like methods (strict arity, scoped return). Procs have surprising behavior with `return` and wrong argument counts.

### Avoid `&method(:name)` when a block is clearer

```ruby
# Clear
users.each { |u| send_welcome_email(u) }

# Obscure - harder to read, no real benefit
users.each(&method(:send_welcome_email))
```

Use `&method(:name)` only when it genuinely improves readability, such as in point-free composition.

## Enumerable and Collections

### Prefer Enumerable methods over manual loops

```ruby
# Good
evens = numbers.select(&:even?)
names = users.map(&:name)
total = prices.sum
found = items.find { |i| i.id == target_id }

# Bad - manual loop reimplementing select
evens = []
numbers.each { |n| evens << n if n.even? }
```

### Common Enumerable patterns

```ruby
# Transform
users.map { |u| u.name.upcase }

# Filter
adults = users.select { |u| u.age >= 18 }
minors = users.reject { |u| u.age >= 18 }

# Aggregate
total = orders.sum(&:amount)
grouped = users.group_by(&:role)
counts = tags.tally

# Query
users.any?(&:admin?)
users.all?(&:active?)
users.none?(&:banned?)
users.count(&:premium?)

# Chaining
users
  .select(&:active?)
  .sort_by(&:name)
  .map { |u| "#{u.name} <#{u.email}>" }
```

### Use `each_with_object` over `inject` for building collections

```ruby
# Good - intent is clear, no need to return accumulator
hash = items.each_with_object({}) do |item, memo|
  memo[item.id] = item.name
end

# Worse - must remember to return memo
hash = items.inject({}) do |memo, item|
  memo[item.id] = item.name
  memo  # easy to forget
end
```

Use `inject`/`reduce` for arithmetic accumulation where the return value is naturally the accumulator.

### Prefer `fetch` over `[]` for hashes with required keys

```ruby
# Good - raises KeyError if missing
config.fetch(:database_url)

# Good - explicit default
config.fetch(:timeout, 30)

# Risky - returns nil silently, bugs hide
config[:database_url]
```

## Classes and Modules

### Single Responsibility

A class should have one reason to change. If you find yourself describing a class with "and," it does too much.

### Prefer composition over inheritance

```ruby
# Good - compose behavior
class Order
  def initialize(pricing_strategy:)
    @pricing = pricing_strategy
  end

  def total
    @pricing.calculate(line_items)
  end
end

# Avoid deep inheritance hierarchies
# Order -> DiscountedOrder -> SpecialDiscountedHolidayOrder  # too deep
class Order; end
class DiscountedOrder < Order; end
class SpecialDiscountedHolidayOrder < DiscountedOrder; end
```

Limit inheritance to at most two levels. Use modules for shared behavior.

### Modules for shared behavior (mixins)

```ruby
module Loggable
  def log(message)
    Logger.info("[#{self.class.name}] #{message}")
  end
end

class OrderProcessor
  include Loggable

  def process(order)
    log("Processing order #{order.id}")
    # ...
  end
end
```

### Include vs Extend vs Prepend

```ruby
module Greetable
  def greet
    "Hello, #{name}"
  end
end

class User
  include Greetable   # adds as instance methods
end

class User
  extend Greetable    # adds as class methods
end

class User
  prepend Greetable   # adds before existing methods in lookup chain (useful for wrapping)
end
```

Use `include` for instance behavior, `extend` for class-level behavior, `prepend` when you need to wrap or override existing methods.

### Struct for simple value objects

```ruby
# Good - concise value object
Point = Struct.new(:x, :y, keyword_init: true) do
  def distance_to(other)
    Math.sqrt((x - other.x)**2 + (y - other.y)**2)
  end
end

point = Point.new(x: 3, y: 4)
```

Use `Data.define` (Ruby 3.2+) for immutable value objects:

```ruby
Point = Data.define(:x, :y) do
  def distance_to(other)
    Math.sqrt((x - other.x)**2 + (y - other.y)**2)
  end
end
```

### Visibility: private and protected

```ruby
class Account
  def deposit(amount)
    self.balance += amount
  end

  private

  def validate_amount(amount)
    raise ArgumentError, "amount must be positive" unless amount.positive?
  end
end
```

- `private` - cannot be called from outside the object (since Ruby 2.7, explicit `self` receiver is allowed)
- `protected` - callable by objects of the same class or subclasses
- Default to `private`. Use `protected` only when objects of the same class need to compare internal state.
- Place `private` keyword once, with all private methods below it

### Freeze constants

```ruby
VALID_STATUSES = %w[active inactive suspended].freeze
DEFAULT_OPTIONS = { timeout: 30, retries: 3 }.freeze
```

Without `freeze`, constants can be mutated at runtime. Ruby only warns on reassignment, not mutation.

## Duck Typing

### Respond to messages, not classes

```ruby
# Good - duck typing
def process(io)
  data = io.read
  parse(data)
end
# Works with File, StringIO, any object that responds to #read

# Bad - type checking
def process(io)
  raise TypeError unless io.is_a?(IO)
  data = io.read
  parse(data)
end
```

### Use respond_to? when you must check

```ruby
def serialize(obj)
  if obj.respond_to?(:to_json)
    obj.to_json
  elsif obj.respond_to?(:to_s)
    obj.to_s
  else
    raise ArgumentError, "cannot serialize #{obj.class}"
  end
end
```

### Avoid is_a? and kind_of? in application code

Type checks couple code to specific classes. They break polymorphism and make testing harder. Reserve them for framework code and type coercion at system boundaries.

## Metaprogramming

### Use sparingly

Metaprogramming is powerful but makes code harder to read, debug, and search. Prefer explicit code unless the metaprogramming eliminates significant duplication.

### define_method for dynamic method creation

```ruby
# Acceptable - eliminates real duplication
%w[name email phone].each do |attr|
  define_method("normalize_#{attr}") do
    send(attr)&.strip&.downcase
  end
end
```

### method_missing requires respond_to_missing?

```ruby
class DynamicConfig
  def initialize(data)
    @data = data
  end

  def method_missing(name, *args)
    if @data.key?(name)
      @data[name]
    else
      super
    end
  end

  # Required - without this, respond_to? lies
  def respond_to_missing?(name, include_private = false)
    @data.key?(name) || super
  end
end
```

Never define `method_missing` without `respond_to_missing?`. Objects that respond to messages must report that they do.

### Prefer explicit over clever

```ruby
# Good - explicit, searchable, debuggable
class User
  def admin?
    role == "admin"
  end

  def moderator?
    role == "moderator"
  end
end

# Questionable - clever, but harder to find and debug
class User
  %w[admin moderator].each do |r|
    define_method("#{r}?") { role == r }
  end
end
```

For two or three methods, write them out. For ten or twenty, metaprogramming is justified.

## Testing

### Minitest is the standard library default

```ruby
require "minitest/autorun"

class TestCalculator < Minitest::Test
  def test_addition
    assert_equal 4, Calculator.add(2, 2)
  end

  def test_division_by_zero
    assert_raises(ZeroDivisionError) do
      Calculator.divide(1, 0)
    end
  end
end
```

### RSpec is the community standard

```ruby
RSpec.describe Calculator do
  describe "#add" do
    it "adds two positive numbers" do
      expect(Calculator.add(2, 2)).to eq(4)
    end

    it "handles negative numbers" do
      expect(Calculator.add(-1, -2)).to eq(-3)
    end
  end

  describe "#divide" do
    it "raises on division by zero" do
      expect { Calculator.divide(1, 0) }.to raise_error(ZeroDivisionError)
    end
  end
end
```

Follow whichever framework the project already uses. Do not mix Minitest and RSpec in the same project.

### Describe the behavior, not the implementation

```ruby
# Good - describes what the code does
it "returns the user's full name" do
  user = User.new(first: "Jane", last: "Doe")
  expect(user.full_name).to eq("Jane Doe")
end

# Bad - describes how the code works
it "concatenates first and last with a space" do
  # ...
end
```

### Use factories over fixtures

```ruby
# Good - explicit, flexible, readable
let(:user) { build(:user, name: "Jane", role: :admin) }

# Avoid - fixtures are implicit, hard to trace, and brittle
# test/fixtures/users.yml
```

### Test doubles: prefer real objects

Use real collaborators when practical. Use test doubles only when the real object is slow, non-deterministic, or has side effects (network, filesystem, external APIs).

```ruby
# Good - real object
let(:parser) { CSVParser.new }

# Acceptable - external dependency
let(:http_client) { instance_double(HTTPClient, get: response) }
```

### One assertion per test (guideline, not law)

Each test should verify one behavior. Multiple assertions are fine when they verify different aspects of the same behavior.

```ruby
# Good - one behavior, multiple aspects
it "creates a valid user" do
  user = User.create!(name: "Jane", email: "jane@example.com")
  expect(user).to be_persisted
  expect(user.name).to eq("Jane")
  expect(user.email).to eq("jane@example.com")
end
```

### Setup and teardown

```ruby
# Minitest
class TestDatabase < Minitest::Test
  def setup
    @db = Database.connect(test_config)
  end

  def teardown
    @db.disconnect
  end
end

# RSpec
RSpec.describe Database do
  let(:db) { Database.connect(test_config) }
  after { db.disconnect }
end
```

Prefer `let` (lazy) over `before` blocks for object creation in RSpec. Use `let!` (eager) only when the side effect of creation matters.

## Common Pitfalls

### Mutating arguments passed by reference

```ruby
# Bug: mutating an argument affects the caller's object
def add_defaults(options)
  options[:timeout] ||= 30
  options
end

config = { retries: 3 }
add_defaults(config)
config  # => { retries: 3, timeout: 30 } - caller's hash was mutated!

# Fix: work on a copy
def add_defaults(options)
  result = options.dup
  result[:timeout] ||= 30
  result
end

# Or use keyword arguments to avoid the problem entirely
def add_defaults(retries: nil, timeout: 30, **rest)
  { retries: retries, timeout: timeout, **rest }
end
```

Ruby passes object references, not copies. Mutating an argument (with `<<`, `[]=`, `merge!`, etc.) changes the caller's object. Always `dup` or `freeze` if you need to modify arguments safely.

### String mutation

```ruby
# Bug: mutating a string affects all references
greeting = "hello"
shout = greeting
shout.upcase!
greeting  # => "HELLO" - surprise!

# Fix: use non-mutating methods or dup
shout = greeting.dup.upcase!
# Or better:
shout = greeting.upcase  # returns new string
```

Use `# frozen_string_literal: true` at the top of every file to catch accidental string mutation.

### Equality confusion

```ruby
# == checks value equality (most common)
"hello" == "hello"  # => true

# equal? checks object identity (rarely needed)
"hello".equal?("hello")  # => false (different objects)

# eql? checks value equality with strict type (used by Hash)
1 == 1.0    # => true
1.eql?(1.0) # => false
```

Use `==` for almost everything. Use `equal?` only when you specifically need identity comparison.

### Accidental nil propagation

```ruby
# Bug: NoMethodError deep in a chain
user.address.city.upcase

# Fix: safe navigation operator
user&.address&.city&.upcase

# Better: avoid long chains - ask the object for what you need
user.city_name  # encapsulate the traversal
```

Do not overuse `&.` - a chain of five safe navigation operators is a code smell. It usually means the object graph is too loosely structured.

### Shadowing outer variables in blocks

```ruby
# Bug: block parameter shadows outer variable
name = "original"
["new"].each { |name| puts name }
puts name  # => "original" (not "new", but confusing)

# Fix: use distinct names
name = "original"
["new"].each { |item| puts item }
```

Ruby warns about this with `-w`. Run with warnings enabled during development.

### Forgetting that return value of assignment is the value

```ruby
# Bug: always truthy because assignment returns the value
if user = find_user(id)
  # This works but looks like a typo (== vs =)
end

# Fix: be explicit
user = find_user(id)
if user
  # ...
end
```

### Using `and`/`or` instead of `&&`/`||`

```ruby
# Bug: and/or have lower precedence than assignment
result = true and false
result  # => true! Parsed as: (result = true) and false

# Fix: use && and ||
result = true && false
result  # => false - parsed as: result = (true && false)
```

`and`/`or` have lower precedence than `=`, which leads to subtle bugs. Use `&&`/`||` for boolean logic. Reserve `and`/`or` for nothing - they are not worth the confusion.

### Using class variables (@@)

```ruby
# Bug: class variables are shared across the entire hierarchy
class Animal
  @@count = 0
  def initialize
    @@count += 1
  end
end

class Dog < Animal; end

Dog.new
Animal.class_variable_get(:@@count)  # => 1 - shared!

# Fix: use class instance variables
class Animal
  @count = 0
  class << self
    attr_accessor :count
  end
  def initialize
    self.class.count += 1
  end
end
```

Class variables (`@@`) are almost never what you want. Use class instance variables (`@` on `self` in class scope) instead.

## Performance Considerations

### Freeze string literals

```ruby
# Add to the top of every file
# frozen_string_literal: true
```

This makes all string literals frozen by default, preventing accidental mutation and enabling string deduplication by the runtime. Code snippets in this skill omit the pragma for brevity, but it should appear in every real file.

### Use symbols for hash keys

```ruby
# Good - symbols are immutable and interned (fast lookup)
config = { timeout: 30, retries: 3 }

# Avoid for internal hashes - strings allocate new objects
config = { "timeout" => 30, "retries" => 3 }
```

Use string keys only at system boundaries (JSON parsing, HTTP headers) where the keys come from external sources.

### Avoid N+1 queries (Rails)

```ruby
# Bad - fires one query per user
users.each { |u| puts u.posts.count }

# Good - eager load associations
users = User.includes(:posts).all
users.each { |u| puts u.posts.size }
```

### Lazy enumerators for large collections

```ruby
# Bad - creates intermediate arrays
File.readlines("huge.txt").select { |l| l.include?("ERROR") }.first(10)

# Good - processes lazily, stops after 10 matches
File.foreach("huge.txt").lazy.select { |l| l.include?("ERROR") }.first(10)
```

## Project Structure

### Standard gem layout

```
my_gem/
  lib/
    my_gem.rb           # entry point, requires sub-files
    my_gem/
      version.rb
      client.rb
      parser.rb
  spec/ or test/
    spec_helper.rb
    my_gem/
      client_spec.rb
      parser_spec.rb
  my_gem.gemspec
  Gemfile
  Rakefile
  README.md
```

### Standard Rails layout

```
my_app/
  app/
    models/
    controllers/
    views/
    services/           # plain Ruby objects for business logic
    jobs/
  config/
  db/
  lib/
  spec/ or test/
```

Follow whichever layout the project already uses. Do not reorganize without a clear reason.

### Require structure

```ruby
# lib/my_gem.rb - entry point
require_relative "my_gem/version"
require_relative "my_gem/client"
require_relative "my_gem/parser"

module MyGem
  class Error < StandardError; end
end
```

Use `require_relative` for files within the same project. Use `require` for gems and standard library.

### Gemfile discipline

```ruby
# Group dependencies by purpose
source "https://rubygems.org"

gem "rails", "~> 7.1"
gem "pg"

group :development, :test do
  gem "rspec-rails"
  gem "rubocop", require: false
end

group :test do
  gem "factory_bot_rails"
  gem "webmock"
end
```

Pin major versions with `~>` (pessimistic constraint). Run `bundle update --conservative` to update within constraints.

## Tooling

### Non-negotiable baseline

```sh
rubocop                  # style and lint checking (configure via .rubocop.yml)
bundle exec rake spec    # or: bundle exec rspec
```

RuboCop is the community standard linter. Configure it per-project; do not fight every default - disable rules deliberately with comments explaining why.

### Highly recommended

```sh
rubocop -a               # auto-correct safe violations
rubocop -A               # auto-correct all violations (review changes)
bundle audit check       # check for known vulnerabilities in gems
brakeman                 # static security analysis (Rails)
```

### Recommended CI sequence

```sh
bundle install --jobs 4
rubocop --parallel                    # style + lint
bundle exec rspec --format progress   # tests
bundle audit check --update           # dependency vulnerabilities
```

## Example Workflow

A realistic class applying multiple conventions together - a service object that processes an order:

```ruby
# frozen_string_literal: true

module Orders
  class ProcessingError < StandardError; end
  class InsufficientStockError < ProcessingError; end

  # Processes a confirmed order: validates stock, charges payment, and dispatches.
  class Processor
    def initialize(payment_gateway:, inventory:, notifier:)
      @payment_gateway = payment_gateway
      @inventory = inventory
      @notifier = notifier
    end

    def call(order)
      validate_stock!(order)
      charge = process_payment(order)
      fulfill(order, charge)
    rescue Payments::DeclinedError => e
      handle_declined_payment(order, e)
    end

    private

    def validate_stock!(order)
      order.line_items.each do |item|
        available = @inventory.available_quantity(item.sku)
        next if available >= item.quantity

        raise InsufficientStockError,
              "insufficient stock for #{item.sku}: need #{item.quantity}, have #{available}"
      end
    end

    def process_payment(order)
      @payment_gateway.charge(
        amount: order.total,
        currency: order.currency,
        source: order.payment_source
      )
    end

    def fulfill(order, charge)
      order.line_items.each { |item| @inventory.reserve(item.sku, item.quantity) }
      order.mark_fulfilled!(charge_id: charge.id)
      @notifier.order_fulfilled(order)
      order
    end

    def handle_declined_payment(order, error)
      order.mark_payment_failed!(reason: error.message)
      @notifier.payment_declined(order)
      raise ProcessingError, "payment declined for order #{order.id}: #{error.message}"
    end
  end
end
```

Key patterns demonstrated:
- `frozen_string_literal: true` at the top of every file
- Custom exceptions inheriting from `StandardError`, organized in a hierarchy
- Dependency injection via constructor (composition over inheritance)
- `private` keyword with all private methods below it
- Duck typing - `payment_gateway`, `inventory`, `notifier` are interfaces by convention
- Specific exception rescue, not bare rescue
- Error messages are lowercase, descriptive
- `each` and Enumerable methods over manual loops
- `next` for early continue in iteration
- Keyword arguments for clarity at call sites
- Single public method (`call`) for service objects

## Quick Reference

| Pattern | Correct | Wrong |
|---|---|---|
| Variable naming | `user_name` | `userName` or `UserName` |
| Class naming | `HTTPClient` | `HttpClient` or `Http_client` |
| Constants | `MAX_RETRIES` | `MaxRetries` or `maxRetries` |
| Predicate method | `def active?` | `def is_active` |
| Bang method | `save!` (with `save` counterpart) | `save!` (without non-bang pair) |
| Exception base | `< StandardError` | `< Exception` |
| Rescue clause | `rescue SpecificError` | bare `rescue` |
| Block (single-line) | `items.map { \|i\| i.name }` | `items.map do \|i\| i.name end` |
| Block (multi-line) | `do ... end` | `{ ... }` spanning lines |
| Hash keys (internal) | `{ timeout: 30 }` | `{ "timeout" => 30 }` |
| Attribute access | `attr_reader :name` | `def get_name` |
| String literals | `# frozen_string_literal: true` | mutable strings by default |
| Collection building | `each_with_object` | `inject` forgetting to return memo |
| Type checking | `obj.respond_to?(:read)` | `obj.is_a?(IO)` |
| Class variables | `@count` (class instance var) | `@@count` (class variable) |

## Never / Always

**Never:**
- Use bare `rescue` without specifying an exception class
- Rescue `Exception` - it catches `SignalException`, `NoMemoryError`, and `SystemExit`
- Define `method_missing` without `respond_to_missing?`
- Use class variables (`@@`) - use class instance variables instead
- Mutate frozen strings or constants without `dup`
- Use `is_a?`/`kind_of?` in application logic when duck typing works
- Mix Minitest and RSpec in the same project
- Write Java-style `get_`/`set_` methods - use `attr_reader`/`attr_writer`
- Swallow exceptions silently - either log or re-raise
- Use `and`/`or` for control flow - use `&&`/`||` (different precedence, surprising bugs)

**Always:**
- Add `# frozen_string_literal: true` to every Ruby file
- Inherit custom exceptions from `StandardError`
- Use `snake_case` for methods and variables, `CamelCase` for classes
- End predicate methods with `?`
- Prefer composition and duck typing over inheritance and type checking
- Use `fetch` for required hash keys
- Freeze mutable constants (`NAMES = %w[a b c].freeze`)
- Run RuboCop (or the project's configured linter) before committing
- Use keyword arguments for methods with more than two parameters
- Prefer block forms for resource management (`File.open { }`)
