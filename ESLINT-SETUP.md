# ESLint & Prettier Setup Guide

This document explains the ESLint and Prettier configuration for the eBay API MCP Server project.

## 📦 Installed Packages

### ESLint & Plugins
- **eslint** (v9.39.1) - Core linting engine
- **@eslint/js** (v9.39.1) - ESLint's JavaScript rules
- **typescript-eslint** (v8.46.4) - TypeScript ESLint parser and rules
- **eslint-plugin-n** (v17.23.1) - Node.js specific linting rules
- **eslint-plugin-vitest** (v0.5.4) - Vitest testing framework rules
- **eslint-config-prettier** (v10.1.8) - Disables ESLint rules that conflict with Prettier

### Prettier
- **prettier** (v3.6.2) - Code formatter

## 🎯 Configuration Files

### `eslint.config.js` (Flat Config)
Uses ESLint's new flat config format with:
- TypeScript strict type checking
- Node.js best practices (ES modules, Node 18+)
- Security rules (no eval, no implied eval)
- Performance optimizations (nullish coalescing, optional chaining)
- Naming conventions enforcement
- Test-specific rules for Vitest

### `.prettierrc`
Code formatting rules:
- Single quotes
- Semicolons required
- 2-space indentation
- 100 character line width
- Trailing commas (ES5)
- LF line endings

### `.vscode/settings.json`
VS Code integration:
- Format on save with Prettier
- Auto-fix ESLint issues on save
- Auto-organize imports
- TypeScript workspace SDK

### `.vscode/extensions.json`
Recommended VS Code extensions:
- ESLint
- Prettier
- Vitest Explorer
- TypeScript

## 🚀 Available Scripts

```bash
# Linting
pnpm run lint          # Check for linting errors
pnpm run lint:fix      # Auto-fix linting errors

# Formatting
pnpm run format        # Format all code with Prettier
pnpm run format:check  # Check if code is formatted

# All checks (type + lint + format)
pnpm run check         # Run all quality checks
```

## 🔍 Key Rules Enforced

### TypeScript Rules
- ✅ Explicit return types on functions
- ✅ No unused variables (except prefixed with `_`)
- ✅ Consistent type imports (`import type`)
- ✅ No floating promises (must await or handle)
- ✅ No unsafe `any` usage (warns)
- ✅ Prefer nullish coalescing (`??`) over `||`
- ✅ Prefer optional chaining (`?.`)
- ✅ Always return awaited promises in async functions

### Node.js Rules
- ✅ Node 18+ features only
- ✅ ES module syntax required
- ✅ Warn on `process.exit()` usage

### Security Rules
- ✅ No `eval()`
- ✅ No `new Function()`
- ✅ Only throw Error objects

### Code Style
- ✅ Naming conventions:
  - **camelCase**: variables, functions, parameters
  - **PascalCase**: classes, types, interfaces
  - **UPPER_CASE**: constants, enum members
- ✅ No `var`, use `const` or `let`
- ✅ Always use `===` (except for `null` checks)
- ✅ Curly braces required for all control statements
- ✅ No console.log (except `console.warn` and `console.error`)

### Test Files (tests/**/*.test.ts)
- Relaxed rules for test files
- `any` allowed in tests
- `console.log` allowed
- Vitest-specific rules enabled

## 🛠️ Common Issues & Fixes

### Issue: "Returning an awaited promise is required"
**Fix:** Add `await` to returned promises in async functions
```typescript
// ❌ Wrong
async function getData() {
  return this.client.get('/endpoint');
}

// ✅ Correct
async function getData() {
  return await this.client.get('/endpoint');
}
```

### Issue: "Use import type"
**Fix:** Use type-only imports for types
```typescript
// ❌ Wrong
import { MyType } from './types.js';

// ✅ Correct
import type { MyType } from './types.js';
```

### Issue: "Missing return type on function"
**Fix:** Add explicit return type
```typescript
// ❌ Wrong
function getData() {
  return 'data';
}

// ✅ Correct
function getData(): string {
  return 'data';
}
```

### Issue: "Array type using 'Array<T>' is forbidden"
**Fix:** Use `T[]` syntax instead
```typescript
// ❌ Wrong
const items: Array<string> = [];

// ✅ Correct
const items: string[] = [];
```

## 🔧 Auto-Fix Most Issues

Run this command to automatically fix most linting issues:

```bash
pnpm run lint:fix
```

This will fix:
- Import sorting
- Type import conversions
- Formatting issues
- Simple syntax issues

## 📝 Ignored Files

The following are excluded from linting:
- `build/` - Compiled output
- `node_modules/` - Dependencies
- `coverage/` - Test coverage reports
- `docs/` - Documentation
- `src/types/sell_*.ts` - Generated OpenAPI types
- `src/types/commerce_*.ts` - Generated OpenAPI types
- `*.config.js` - Configuration files

## 🔄 CI/CD Integration

### GitHub Actions Workflow
The `.github/workflows/lint.yml` workflow runs on:
- Every push to `main`
- Every pull request to `main`

**Checks:**
1. ESLint validation
2. Prettier formatting check
3. TypeScript type checking

## 🎨 Editor Integration

### VS Code
1. Install recommended extensions when prompted
2. Format on save is enabled automatically
3. ESLint auto-fix on save is enabled
4. Import organization on save is enabled

### Other IDEs
- **WebStorm/IntelliJ**: Enable ESLint and Prettier plugins
- **Vim/Neovim**: Use ALE or CoC with ESLint and Prettier
- **Sublime Text**: Install ESLint and Prettier packages

## 📊 Current Linting Status

Run `pnpm run lint` to see current issues. Common issues found:
- Missing `await` on returned promises
- Missing explicit return types
- Type-only imports not using `import type`

**Recommended approach:**
1. Fix critical issues first (security, bugs)
2. Run `pnpm run lint:fix` to auto-fix simple issues
3. Manually fix remaining issues gradually
4. Consider adding exceptions for specific cases if needed

## 🚫 Disabling Rules

### For a single line
```typescript
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const data: any = {};
```

### For a file
```typescript
/* eslint-disable @typescript-eslint/no-explicit-any */
// File content
```

### For a block
```typescript
/* eslint-disable @typescript-eslint/no-explicit-any */
const data: any = {};
/* eslint-enable @typescript-eslint/no-explicit-any */
```

## 📚 Resources

- [ESLint Flat Config](https://eslint.org/docs/latest/use/configure/configuration-files-new)
- [typescript-eslint](https://typescript-eslint.io/)
- [Prettier](https://prettier.io/)
- [ESLint Plugin Node](https://github.com/eslint-community/eslint-plugin-n)
- [ESLint Plugin Vitest](https://github.com/veritem/eslint-plugin-vitest)

---

**Last Updated**: 2025-11-11
**ESLint Version**: 9.39.1
**Prettier Version**: 3.6.2
