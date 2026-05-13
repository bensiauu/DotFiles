---
name: angular-feature-module
description: Use this skill when the user wants to "add a new angular feature", "scaffold a feature module", "new component" in an Angular codebase. Adapts to the Angular version (16 vs 17+ vs 19) of the target repo. Delegate to frontend-angular-engineer for substantive work.
version: 0.1.0
---

# Scaffold an Angular feature module

## When to use
The user is adding a new feature, lazy-loaded route, or component group in one of the Angular codebases (rolls-royce A16, model-factory A16/17, aimpact A19).

## Version detection
Before scaffolding, read the repo's `package.json` and determine `@angular/core` major version:
- **A19** (aimpact): standalone components, signals, new control flow (`@if`/`@for`), `inject()`
- **A17** (model-factory upgraded parts): standalone components, signals, new control flow
- **A16** (rolls-royce, parts of model-factory): NgModules, RxJS BehaviorSubject for state, `*ngIf`/`*ngFor`

Do not retrofit A19 idioms into A16 code.

## Output (A17+ standalone, lazy-loaded)
```
src/app/features/<feature-name>/
  <feature-name>.routes.ts        # default-export route array
  <feature-name>.component.ts     # standalone, signals, OnPush
  <feature-name>.component.html
  <feature-name>.component.scss
  <feature-name>.service.ts       # providedIn: 'root' or 'feature' as appropriate
  components/                     # leaf presentational components
  models/                         # interfaces / types
  <feature-name>.component.spec.ts
```
Register in `app.routes.ts`:
```ts
{
  path: '<feature-name>',
  loadChildren: () => import('./features/<feature-name>/<feature-name>.routes')
                        .then(m => m.default),
}
```

## Output (A16 NgModule)
```
src/app/features/<feature-name>/
  <feature-name>.module.ts        # NgModule with routing
  <feature-name>-routing.module.ts
  <feature-name>.component.ts
  <feature-name>.component.html
  <feature-name>.component.scss
  <feature-name>.service.ts       # providedIn: 'root'
  <feature-name>.component.spec.ts
```
Register in `app-routing.module.ts`:
```ts
{
  path: '<feature-name>',
  loadChildren: () => import('./features/<feature-name>/<feature-name>.module')
                        .then(m => m.<FeatureName>Module),
}
```

## House style (matches existing Angular code)
- ChangeDetectionStrategy.OnPush always.
- Typed Reactive Forms (`FormControl<string>`).
- Auth/HTTP interceptors stay in `core/`; do not duplicate per feature.
- Kendo UI components consistent with the rest of the app; don't introduce a second UI kit.
- A16+ uses `takeUntilDestroyed()` for subscription teardown (never manual Subject unsub).

## Steps
1. Detect Angular major version.
2. Ask: feature name, route path, whether it needs its own service.
3. Generate the appropriate layout for the version.
4. Wire into the app's routing.
5. Write one `*.spec.ts` covering "renders without crashing" + one behaviour.
6. Use the typescript LSP plugin for type checks.
7. Hand off substantive component logic to `frontend-angular-engineer`.

## Reporting
Files created, route wired, and next prompt for `frontend-angular-engineer`.
