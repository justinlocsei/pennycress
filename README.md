<p align="center">
  <img src="./assets/logo.svg" width="600" alt="Pennycress">
</p>

<br>

<p align="center">
  Pennycress is a Rails gem that allows you to describe expensive, model-based computations as Ruby classes.  You define a list of input models, a way to transform those models into a cached output value, and any model changes that should invalidate it.  Values can also provide a plan for warming the cache, enabling distributed, batch-focused precomputation.  By capturing the full lifecycle of a cached value in Ruby, Pennycress offers a lightweight alternative to materialized views that lets you fix hot read paths without recreating them in SQL.
</p>

---

[![Verify](https://github.com/justinlocsei/pennycress/actions/workflows/verify.yml/badge.svg)](https://github.com/justinlocsei/pennycress/actions/workflows/verify.yml)
[![Gem Version](https://img.shields.io/gem/v/pennycress.svg)](https://rubygems.org/gems/pennycress)
[![License](https://img.shields.io/github/license/justinlocsei/pennycress.svg)](https://github.com/justinlocsei/pennycress/blob/main/LICENSE)

<!-- <toc> -->
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Rails Integration](#rails-integration)
- [How Values Work](#how-values-work)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Fetching a Value](#fetching-a-value)
  - [Fetching Multiple Values](#fetching-multiple-values)
- [Cache Invalidation](#cache-invalidation)
  - [Producing Invalidation Inputs](#producing-invalidation-inputs)
  - [Specifying Invalidation Triggers](#specifying-invalidation-triggers)
  - [Handling Destroyed Records](#handling-destroyed-records)
- [Cache Warming](#cache-warming)
  - [Warming the Cache](#warming-the-cache)
- [Batch Computation](#batch-computation)
- [Configuring Pennycress](#configuring-pennycress)
- [Why the Name?](#why-the-name)
<!-- </toc> -->

## Installation

Add Pennycress to your application's `Gemfile`:

```ruby
gem "pennycress"
```

Then install it:

```sh
bundle install
```

## Quick Start

Create the following file at `app/values/account_order_total.rb`:

```ruby
class AccountOrderTotal < Pennycress::Value
  # Derive the order total from the Account model
  input :account

  # Compute and cache a numeric order total
  output Integer

  # Evict the cached value for a changed account
  watch :account do |account|
    [{ account: account }]
  end

  # Evict the cached value for the account associated with a changed order
  watch :order do |order|
    [{ account: order.account_id }]
  end

  # Run a cache-warming job for every active organization
  seeds { Organization.active.ids }

  # Use a model method to calculate the order total
  #
  # In this example, we're assuming that this is an expensive call that triggers
  # lots of reads.  Maybe it's legacy code that hasn't been touched in ten years.
  def compute(account:)
    account.calculate_completed_order_total
  end

  # Warm the cache for each account in an organization
  #
  # This runs in the context of a background job.  Each value emitted by `seeds`
  # enqueues one background job, so allowing multiple warming jobs to run at
  # once can rapidly populate cached values.
  def seed_to_inputs(organization_id)
    Organization
      .find(organization_id)
      .active_accounts
      .map { |account| { account: account } }
  end
end
```

Any application code that needs the order total for an account can request it by passing an `Account` instance:

```ruby
AccountOrderTotal.fetch(account: account)
```

## Rails Integration

Any class that subclasses `Pennycress::Value` and lives under `app/values` is loaded automatically when your Rails app boots or reloads.  Values can be placed in nested directories, allowing for paths like `app/values/billing/account_order_total.rb`.

All discovered values have [invalidation handlers](#cache-invalidation) registered and are made available for [cache warming](#cache-warming).  To use a different location for your value definitions, see [Configuring Pennycress](#configuring-pennycress) for details.

## How Values Work

A Pennycress `Value` describes the transformation of a set of model inputs into an output with a stable cache key.  The smallest useful value specifies its input, output, and a `#compute` method that can delegate to the application's existing logic:

```ruby
class AccountOrderTotal < Pennycress::Value
  input :account
  output Integer

  def compute(account:)
    account.calculate_completed_order_total
  end
end
```

The `input` and `output` declarations act as both documentation and validation.  If a caller provides an invalid account input, or `#compute` returns a non-numeric value, `Pennycress::ValidationError` is raised.

### Inputs

The `input` declaration accepts one or more model identifiers:

```ruby
input :account
input :account, :organization
```

A model identifier follows Rails naming conventions, with `:account` resolving to `Account` and `:uploaded_file` mapping to `UploadedFile`.  The resolved class must be a database-backed model that inherits from `ActiveRecord::Base`.

### Outputs

The `output` declaration describes the type of data a value produces from its model inputs, which can be either a Ruby class or a hash with multiple typed fields:

```ruby
output Integer
output count: Integer, labels: Array
```

A hash output validates the type of each key's value and raises an error when unknown or missing keys are detected.  Pennycress performs shallow validation of each field against its declared type, so deep validation of an array's items or child hashes should be handled by the caller of `.fetch`.

### Fetching a Value

Application code requests a computed value by calling `.fetch`.  This validates the model inputs, computes the value in the case of a cache miss, and verifies the type of the resulting output.

When requesting a computed value, callers can provide either a persisted model instance or its primary key:

```ruby
AccountOrderTotal.fetch(account: account)
AccountOrderTotal.fetch(account: 1)
```

Pennycress uses the primary key when constructing the cache key, so these forms are equivalent.  On a cache hit, passing a primary key does not load the model from the database.  Composite primary keys are supported by passing their key values as an array.

### Fetching Multiple Values

When application code needs a computed value for several models, it should use `.fetch_many`:

```ruby
totals = AccountOrderTotal.fetch_many([
  { account: alfa },
  { account: bravo },
  { account: charlie }
])
```

The returned values match the order of the inputs, with the second item in `totals` containing the value computed for account `bravo`.  Cached outputs are reused, and only misses are computed.

By default, Pennycress calls `#compute` once for each miss.  Values can override `#compute_many` to replace those calls with a more efficient batch calculation, which is explored in depth in [Batch Computation](#batch-computation).

## Cache Invalidation

Pennycress enables fine-grained invalidation in response to committed changes to Active Record models.  A value declares invalidation rules using `watch`, which specifies a model and logic to run when an instance of that model changes:

```ruby
class AccountOrderTotal < Pennycress::Value
  watch :account do |account|
    [{ account: account }]
  end
end
```

The symbol passed to `watch` resolves to an Active Record class using Rails naming conventions.  When a matching model is created, updated, or destroyed, Pennycress calls the block with the changed record and evicts the cached output for every input returned by the block.  With an input's value removed from the cache, the next call to `.fetch` will calculate it with the latest model data.

### Producing Invalidation Inputs

A watch block returns an enumerable of inputs for the value.  It may return one input, several inputs, or an empty array when a change does not affect the value.  Inputs follow the same rules used for the values passed to `.fetch`, supporting either model instances or IDs:

```ruby
watch :account { |account| [{ account: account }] }
watch :order { |order| [{ account: order.account_id }] }
```

Inputs can be any valid `Enumerable`, rather than just a concrete `Array`.  If your list of inputs may be large, you can use a lazy or custom `Enumerator` to reduce memory usage during invalidation.

### Specifying Invalidation Triggers

By default, a watch responds to `:create`, `:update`, and `:destroy` commits.  If you would like to only respond to a subset of those events, use `on:` to narrow the actions that trigger invalidation:

```ruby
watch :order, on: %i[create update] do |order|
  [{ account: order.account_id }]
end
```

If a value should only be invalidated when specific fields change, the watch block can inspect Active Record's saved-change information and return an empty list of inputs for unrelated changes:

```ruby
watch :account, on: [:update] do |account|
  account.saved_change_to_billing_status? ? [{ account: account }] : []
end
```

### Handling Destroyed Records

Destroy invalidations run after the destroy transaction is committed.  The record's in-memory attributes, including its primary and foreign keys, are generally still available, but the row will no longer exists in the database.

These conditions can result in errors when trying to fetch associated records.  For watches that respond to a `:destroy` commit, derive inputs from attributes retained on the destroyed instance:

```ruby
watch :order, on: %i[create update destroy] do |order|
  [{ account: order.account_id }]
end
```

If a watch cannot handle destroyed records using the same logic as created or updated ones, you can define separate invalidation handlers for each action:

```ruby
watch :order, on: %i[create update] do |order|
  [{ account: order.account.id }]
end

watch :order, on: [:destroy] do |order|
  [{ account: order.account_id }]
end
```

## Cache Warming

Pennycress values can define seeds that divide the work of cache warming into discrete background jobs.  Each seed returned from the `seeds` block creates an Active Job that passes its seed to `.seed_to_inputs`, and the resulting inputs are fetched through the normal cache pipeline.

```ruby
class AccountOrderTotal < Pennycress::Value
  input :account
  output Integer

  seeds { Organization.active.ids }

  def seed_to_inputs(organization_id)
    Organization
      .find(organization_id)
      .active_accounts
      .map { |account| { account: account } }
  end

  def compute(account:)
    account.calculate_completed_order_total
  end
end
```

Seeds can be any value that can be safely serialized in the context of an Active Job.  When possible, prefer primitive values like numbers and strings.

Seeding is a performance optimization to eagerly populate the cache for values that are known to put pressure on the database.  A value can define as narrow or wide a set of inputs for warming as are appropriate to the computed value.

### Warming the Cache

All registered `Value` classes that define seeds can be warmed via the `pennycress:warm_cache` Rake task, making it a natural fit for post-deployment tasks.  If you prefer to start cache warming through Ruby code, you can call `Pennycress.warm_cache`.

Both operations will block while they enqueue Active Jobs for each warming seed.  This should be a fast operation, since the computation of each value is performed in the background jobs, and the only synchronous work is the calculation of seeds.

Warming jobs will be added to the default queue without any further configuration.  If you wish to use a named queue to limit concurrent jobs, you can use the `warming_queue` option detailed in [Configuring Pennycress](#configuring-pennycress).

## Batch Computation

The default `#compute_many` implementation calls `#compute` for each input that resulted in a cache miss.  If a value can be calculated more efficiently in bulk, define a custom `compute_many` implementation:

```ruby
class AccountOrderTotal < Pennycress::Value
  input :account
  output Integer

  def compute(account:)
    account.calculate_completed_order_total
  end

  def compute_many(inputs)
    ids = inputs.map do |input|
      input[:account].id
    end

    by_id = Account.calculate_completed_order_totals_for_ids(ids)

    ids.map do |id|
      by_id.fetch(id)
    end
  end
end
```

This example uses a theoretical method that efficiently calculates order totals for multiple accounts and exposes the totals in a hash keyed by account ID.  By fetching these values once and mapping them to the ordered inputs, `compute_many` avoids N+1 issues when calculating multiple account totals.

## Configuring Pennycress

While Pennycress comes with sane defaults, you can customize its integration with your Rails app using an initializer.  The available settings and their default values are shown below:

```ruby
# config/initializers/pennycress.rb
Pennycress.configure do |config|
  # The ActiveSupport::Cache::Store instance used for all cache operations
  config.cache = Rails.cache

  # The prefix used for the cache key of all Pennycress values
  config.cache_namespace = "pennycress"

  # The directories in which values can be defined
  config.directories = ["app/values"]

  # The queue to which warming jobs are added
  config.warming_queue = :default
end
```

## Why the Name?

In [floristry](https://www.instagram.com/justinlocsei/), pennycress is a filler flower with lots of tiny leaves.  Fine, granular foliage feels appropriate for a library that offers fine-grained cache invalidation.
