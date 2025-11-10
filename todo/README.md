# OAuth Scopes Implementation Todo List

This document tracks all locations in the project where OAuth scopes need to be properly handled for sandbox vs production environments.

## Overview

Two scope configuration files have been added:
- `docs/auth/production_scopes.json` - Production environment scopes (27 unique scopes)
- `docs/auth/sandbox_scopes.json` - Sandbox environment scopes (35 unique scopes)

Key differences:
- Sandbox includes additional Buy API scopes (e.g., `buy.order.readonly`, `buy.guest.order`, `buy.shopping.cart`)
- Sandbox includes extended Identity scopes (email, phone, address, name, status)
- Sandbox includes `sell.item.draft` and `sell.item` scopes
- Production includes `sell.edelivery` scope (not in sandbox)
- Production includes `commerce.message` scope explicitly
- Production includes `commerce.shipping` scope (not in sandbox)

## 🔴 Critical Priority Tasks

### 1. Environment-Specific Scope Configuration

**File:** `src/config/environment.ts`
**Lines:** 57-91
**Issue:** Hardcoded scope array in `getOAuthAuthorizationUrl()` uses sandbox scopes but applies to both environments

**Action Required:**
- [ ] Create separate `getProductionScopes()` and `getSandboxScopes()` functions
- [ ] Load scopes from `docs/auth/production_scopes.json` and `docs/auth/sandbox_scopes.json`
- [ ] Update `getOAuthAuthorizationUrl()` to select scopes based on `environment` parameter
- [ ] Add scope validation to ensure requested scopes match environment capabilities

**Code Location:** src/config/environment.ts:57-91

**Current Implementation:**
```typescript
const defaultScopes = [
  "https://api.ebay.com/oauth/api_scope",
  "https://api.ebay.com/oauth/api_scope/buy.order.readonly",
  // ... 30+ hardcoded scopes
];
```

**Required Implementation:**
```typescript
// Load from JSON files
function getProductionScopes(): string[]
function getSandboxScopes(): string[]
function getDefaultScopes(environment: "production" | "sandbox"): string[]
```

### 2. OAuth Tool Scope Parameter Support

**File:** `src/tools/tool-definitions.ts`
**Lines:** 25-32
**Issue:** `ebay_get_oauth_url` tool accepts optional scopes but doesn't validate them against environment

**Action Required:**
- [ ] Add scope validation in tool execution
- [ ] Warn users if requesting production-only scopes in sandbox environment
- [ ] Warn users if requesting sandbox-only scopes in production environment
- [ ] Document which scopes are environment-specific in tool description

**Code Location:** src/tools/tool-definitions.ts:25-32

### 3. OAuth Client Default Scope

**File:** `src/auth/oauth.ts`
**Line:** 236
**Issue:** Client credentials flow hardcodes basic scope: `https://api.ebay.com/oauth/api_scope`

**Action Required:**
- [ ] Verify if client credentials should use environment-specific scopes
- [ ] Consider if additional scopes are needed for client credentials flow
- [ ] Document scope limitations for client credentials vs user tokens

**Code Location:** src/auth/oauth.ts:236

## 🟡 Medium Priority Tasks

### 4. HTTP Server OAuth Scopes Configuration

**File:** `src/server-http.ts`
**Lines:** 44-46, 109-110
**Issue:** MCP OAuth scopes (`mcp:tools`) are separate from eBay OAuth scopes, but not clearly separated

**Action Required:**
- [ ] Document distinction between MCP OAuth scopes and eBay OAuth scopes
- [ ] Add configuration example showing both scope types
- [ ] Consider if MCP scopes should be environment-aware
- [ ] Update README with dual OAuth system explanation

**Code Locations:**
- src/server-http.ts:44-46 (requiredScopes configuration)
- src/server-http.ts:109-110 (metadata router scopes)

### 5. Token Storage Scope Persistence

**File:** `src/auth/oauth.ts`
**Lines:** 150, 207
**Issue:** Scopes are stored in `StoredTokenData` but not validated against environment

**Action Required:**
- [ ] Add scope validation when loading persisted tokens
- [ ] Warn if stored token scopes don't match current environment requirements
- [ ] Implement scope comparison utility function
- [ ] Consider auto-refresh if scopes are insufficient

**Code Locations:**
- src/auth/oauth.ts:150 (exchangeCodeForToken scope storage)
- src/auth/oauth.ts:207 (refreshUserToken scope storage)

### 6. OAuth Metadata Endpoints

**File:** `src/auth/oauth-metadata.ts`
**Lines:** 27, 57
**Issue:** `scopes_supported` in metadata doesn't reflect environment-specific scopes

**Action Required:**
- [ ] Update `createMetadataRouter()` to accept environment parameter
- [ ] Return environment-appropriate scopes in `/.well-known/oauth-protected-resource`
- [ ] Update `/.well-known/mcp-server-info` to show eBay environment
- [ ] Document OAuth metadata endpoints in README

**Code Locations:**
- src/auth/oauth-metadata.ts:27 (MetadataConfig interface)
- src/auth/oauth-metadata.ts:57 (scopes_supported in metadata response)

## 🟢 Low Priority / Enhancement Tasks

### 7. Scope Documentation

**Action Required:**
- [ ] Create `docs/auth/README.md` explaining scope differences
- [ ] Document which APIs require which scopes
- [ ] Create scope requirement matrix (API endpoint → required scopes)
- [ ] Add scope troubleshooting guide
- [ ] Document rate limit differences between scope types

**Files to Create:**
- `docs/auth/README.md`
- `docs/auth/scope-requirements.md`
- `docs/auth/troubleshooting.md`

### 8. Tool-Specific Scope Requirements

**File:** `src/tools/tool-definitions.ts`
**Issue:** Tool descriptions don't indicate required scopes

**Action Required:**
- [ ] Add scope requirements to tool descriptions
- [ ] Group tools by scope requirements
- [ ] Add tool that checks if current token has required scopes
- [ ] Implement scope-based tool filtering (hide tools if scopes missing)

**Example Enhancement:**
```typescript
{
  name: 'ebay_create_offer',
  description: 'Create a new offer for an inventory item',
  requiredScopes: ['https://api.ebay.com/oauth/api_scope/sell.inventory'],
  inputSchema: { ... }
}
```

### 9. Scope Utility Functions

**Action Required:**
- [ ] Create `src/auth/scope-utils.ts` with helper functions
- [ ] Implement `validateScopes(scopes: string[], environment: string): ValidationResult`
- [ ] Implement `getRequiredScopesForTool(toolName: string): string[]`
- [ ] Implement `hasRequiredScopes(tokenScopes: string[], requiredScopes: string[]): boolean`
- [ ] Implement `getScopeDifferences(production: string[], sandbox: string[]): Diff`

### 10. Environment Variable Validation

**File:** `src/config/environment.ts`
**Action Required:**
- [ ] Validate `EBAY_ENVIRONMENT` matches available scope configuration
- [ ] Warn on startup if environment/scope mismatch detected
- [ ] Add `EBAY_CUSTOM_SCOPES` environment variable for override
- [ ] Document all environment variables in README

### 11. Test Coverage for Scopes

**Action Required:**
- [ ] Create test suite for scope handling
- [ ] Test environment-specific scope loading
- [ ] Test scope validation for OAuth URL generation
- [ ] Test token storage with different scope sets
- [ ] Test error handling for invalid scopes

**Files to Create:**
- `tests/auth/scopes.test.ts`
- `tests/auth/scope-validation.test.ts`

### 12. Scope Migration Helper

**Action Required:**
- [ ] Create CLI tool to migrate tokens between environments
- [ ] Implement scope comparison when switching environments
- [ ] Add warning system for scope downgrades
- [ ] Document token migration process

**File to Create:**
- `scripts/migrate-tokens.ts`

## 📋 Implementation Checklist

### Phase 1: Critical Scope Handling (Week 1)
- [ ] Load scopes from JSON files dynamically
- [ ] Environment-specific scope selection in `getOAuthAuthorizationUrl()`
- [ ] Scope validation in `ebay_get_oauth_url` tool
- [ ] Update documentation with environment differences

### Phase 2: Scope Validation & Storage (Week 2)
- [ ] Scope validation when loading persisted tokens
- [ ] Scope validation in OAuth metadata endpoints
- [ ] Warning system for scope mismatches
- [ ] Enhanced error messages for scope-related issues

### Phase 3: Developer Experience (Week 3)
- [ ] Tool descriptions with scope requirements
- [ ] Comprehensive scope documentation
- [ ] Scope utility functions
- [ ] CLI helper tools

### Phase 4: Testing & Refinement (Week 4)
- [ ] Test coverage for all scope handling
- [ ] Integration tests with both environments
- [ ] Documentation review and updates
- [ ] Migration guide for existing users

## 🔍 Scope Analysis Results

### Production-Only Scopes
```
https://api.ebay.com/oauth/scope/sell.edelivery
https://api.ebay.com/oauth/api_scope/commerce.message (explicit)
https://api.ebay.com/oauth/api_scope/commerce.shipping
```

### Sandbox-Only Scopes
```
https://api.ebay.com/oauth/api_scope/buy.order.readonly
https://api.ebay.com/oauth/api_scope/buy.guest.order
https://api.ebay.com/oauth/api_scope/sell.marketplace.insights.readonly
https://api.ebay.com/oauth/api_scope/commerce.catalog.readonly
https://api.ebay.com/oauth/api_scope/buy.shopping.cart
https://api.ebay.com/oauth/api_scope/buy.offer.auction
https://api.ebay.com/oauth/api_scope/commerce.identity.email.readonly
https://api.ebay.com/oauth/api_scope/commerce.identity.phone.readonly
https://api.ebay.com/oauth/api_scope/commerce.identity.address.readonly
https://api.ebay.com/oauth/api_scope/commerce.identity.name.readonly
https://api.ebay.com/oauth/api_scope/commerce.identity.status.readonly
https://api.ebay.com/oauth/api_scope/sell.item.draft
https://api.ebay.com/oauth/api_scope/sell.item
https://api.ebay.com/oauth/api_scope/buy.item.feed
https://api.ebay.com/oauth/api_scope/buy.marketing
https://api.ebay.com/oauth/api_scope/buy.product.feed
https://api.ebay.com/oauth/api_scope/buy.marketplace.insights
https://api.ebay.com/oauth/api_scope/buy.proxy.guest.order
https://api.ebay.com/oauth/api_scope/buy.item.bulk
https://api.ebay.com/oauth/api_scope/buy.deal
```

### Common Scopes (Both Environments)
```
https://api.ebay.com/oauth/api_scope
https://api.ebay.com/oauth/api_scope/sell.marketing.readonly
https://api.ebay.com/oauth/api_scope/sell.marketing
https://api.ebay.com/oauth/api_scope/sell.inventory.readonly
https://api.ebay.com/oauth/api_scope/sell.inventory
https://api.ebay.com/oauth/api_scope/sell.account.readonly
https://api.ebay.com/oauth/api_scope/sell.account
https://api.ebay.com/oauth/api_scope/sell.fulfillment.readonly
https://api.ebay.com/oauth/api_scope/sell.fulfillment
https://api.ebay.com/oauth/api_scope/sell.analytics.readonly
https://api.ebay.com/oauth/api_scope/commerce.identity.readonly
https://api.ebay.com/oauth/api_scope/sell.finances
https://api.ebay.com/oauth/api_scope/sell.payment.dispute
https://api.ebay.com/oauth/api_scope/sell.reputation
https://api.ebay.com/oauth/api_scope/sell.reputation.readonly
https://api.ebay.com/oauth/api_scope/commerce.notification.subscription
https://api.ebay.com/oauth/api_scope/commerce.notification.subscription.readonly
https://api.ebay.com/oauth/api_scope/sell.stores
https://api.ebay.com/oauth/api_scope/sell.stores.readonly
https://api.ebay.com/oauth/api_scope/commerce.vero
https://api.ebay.com/oauth/api_scope/sell.inventory.mapping
https://api.ebay.com/oauth/api_scope/commerce.feedback
https://api.ebay.com/oauth/api_scope/commerce.feedback.readonly
```

## 📚 Reference Files

- Production scopes: `/docs/auth/production_scopes.json`
- Sandbox scopes: `/docs/auth/sandbox_scopes.json`
- OAuth configuration: `/src/config/environment.ts`
- OAuth client: `/src/auth/oauth.ts`
- Tool definitions: `/src/tools/tool-definitions.ts`
- HTTP server: `/src/server-http.ts`
- OAuth metadata: `/src/auth/oauth-metadata.ts`

## 🚀 Quick Start for Contributors

1. Review scope JSON files to understand environment differences
2. Start with Critical Priority tasks (Section 1-3)
3. Test changes in both sandbox and production environments
4. Update documentation as you implement changes
5. Add tests for any new scope validation logic

## ⚠️ Important Notes

- Always test scope changes in sandbox before production
- Maintain backward compatibility with existing stored tokens
- Document breaking changes in CHANGELOG.md
- Consider security implications of scope expansion
- Rate limits differ between client credentials and user tokens (1k vs 10k-50k requests/day)

---

**Last Updated:** 2025-11-11
**Status:** Initial scan complete, implementation pending
**Priority:** Critical - Blocks proper environment separation
