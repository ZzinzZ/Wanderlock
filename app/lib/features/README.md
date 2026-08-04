# Features

Each feature has four layers. See section 2 of
[../../../docs/12-engineering-guide.md](../../../docs/12-engineering-guide.md).

```
features/<name>/
├─ domain/         entity + repository interface. Pure Dart, no outside imports
├─ data/           dto, remote/local sources, repository implementations
├─ application/    services, notifiers, use cases
└─ presentation/   screens, widgets
```

## Dependency rules — these protect the two-layer architecture

1. `domain` imports nothing but plain Dart.
2. `presentation` never calls a repository directly; it goes through
   `application`.
3. **Features do not import each other.** The single exception: every feature
   may depend on `unlock`, and `unlock` may depend on none of them.
4. `design/` never imports `features/`.

Rule 3 is the whole product thesis expressed as code. Every lens reads
`visit_state` from `unlock`; no lens knows another lens exists, and no lens
stores unlock state of its own. Only `unlock` writes `visit_state`.

## The feature set is closed for v1

`checkpoint` · `unlock` · `fog` · `story` · `quest` · `itinerary` · `collection`

The Social lens is deferred to v1.5 — do not add it. See
[../../../docs/08-scope.md](../../../docs/08-scope.md).
