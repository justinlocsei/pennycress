# Agent notes

Coding preferences for this project. Not architectural guidance — see the code and README for that.

## Scope and style

- Keep diffs small and focused. Do not add helpers, abstractions, or guards unless they solve a real problem.
- Prefer code that reads as if one author wrote it: match naming, types, and documentation level in surrounding files.
- Comments explain non-obvious intent, not what the code already says.

## Naming and API surface

- Do not use `!` on method names unless there is a non-bang counterpart with different semantics.
- Prefer plain names over jargon (`load_values`, not `wire_watches!`).
- Do not expose public methods only for tests. Keep helpers private and test through the public API, or test via the same boundaries production code uses.
- When a group of items has a natural order (attributes, constants, method lists), alphabetize it.

## Configuration and testability

- Global singletons (`Configuration`, `Registry`) use instance state with `.current` and `.override` for isolated specs.
- Pass dependencies explicitly at boundaries (e.g. directories into loaders) instead of reaching for global config deep in core code.

## Ruby and Rails habits

- Treat inputs as hashes internally; reserve keyword arguments for user-facing entry points like `.fetch`.
- Prefer `File.join` / `File.absolute_path?` over `Pathname` when that is enough.
- Trust empty arrays: avoid extra guards when iterating or calling batch APIs on `[]`.
- When mapping a lazy enumerable, prefer `.map { ... }.to_a` over materializing with `.to_a` first.
- Validation lists (e.g. allowed symbols) should be a named constant used as both the default and the allowlist.

## Tests

- Specs should be obvious: assert after each meaningful step when behavior is sequential (e.g. compute counts per fetch).
- Prefer isolated registries/config via `override` over mutating global state and resetting in hooks.
- Use descriptive stand-ins in examples (NATO words, small fixed ids) rather than arbitrary magic values when it aids reading.

## Git

- Do not commit or open PRs unless asked.
