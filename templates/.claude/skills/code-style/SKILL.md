# Skill: Code Style

## TypeScript Conventions

### Strict Mode
- Enable `strict: true` in tsconfig.json.
- Never use `any`. Use `unknown` with type guards or explicit generic types.
- Prefer `interface` for object shapes, `type` for unions/intersections.

### Naming
- **Files**: PascalCase for components (`UserCard.tsx`), camelCase for utilities (`formatDate.ts`).
- **Variables/functions**: camelCase (`getUserById`).
- **Types/interfaces**: PascalCase (`UserProfile`, `ApiResponse<T>`).
- **Constants**: UPPER_SNAKE_CASE for true constants (`MAX_RETRY_COUNT`), camelCase for derived values.
- **Booleans**: prefix with `is`, `has`, `should`, `can` (`isLoading`, `hasPermission`).
- **Event handlers**: prefix with `handle` (`handleSubmit`), props with `on` (`onSubmit`).

### Import Order
Organize imports in this order, separated by blank lines:
1. Node built-in modules (`node:fs`, `node:path`)
2. External packages (`react`, `zod`, `express`)
3. Internal aliases (`{IMPORT_ALIAS}/components`, `{IMPORT_ALIAS}/utils`)
4. Relative imports (`./Button`, `../hooks/useAuth`)

### Exports
- Named exports only. No default exports.
- Re-export from barrel `index.ts` files at module boundaries.
- Explicit return types on all exported functions.

### Functions
- Prefer `const` arrow functions for components and callbacks.
- Use `function` declarations for top-level utility functions (hoisting benefits).
- Destructure parameters and props.
- **Max 40 lines per function.** This is a hard limit. Extract helpers for longer logic.
- **Max 4 parameters per function.** Use an options object for more: `createUser({ name, email, role })`.
- **Max 3 levels of nesting.** If you have `if > for > if`, extract the inner logic into a named function.

### Error Handling
- Never swallow errors silently (`catch (e) {}`).
- Use typed error classes or `Result<T, E>` patterns.
- Log errors with structured context (not bare `console.error`).
- Handle all promise rejections -- no floating promises.

### Comments
- Avoid obvious comments. Code should be self-documenting.
- Use JSDoc for exported functions with non-trivial signatures.
- TODO format: `// TODO({TICKET_PREFIX}-123): description`
