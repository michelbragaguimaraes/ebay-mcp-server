import { config } from "dotenv";
import type { EbayConfig } from "../types/ebay.js";

config();

export function getEbayConfig(): EbayConfig {
  const clientId = process.env.EBAY_CLIENT_ID;
  const clientSecret = process.env.EBAY_CLIENT_SECRET;
  const environment = (process.env.EBAY_ENVIRONMENT || "sandbox") as
    | "production"
    | "sandbox";

  if (!clientId || !clientSecret) {
    console.error(
      "Missing required eBay credentials. Please set EBAY_CLIENT_ID and EBAY_CLIENT_SECRET environment variables.",
    );
    return {
      clientId: "",
      clientSecret: "",
      redirectUri: "",
      environment: "sandbox",
    };
  }

  return {
    clientId,
    clientSecret,
    redirectUri: process.env.EBAY_REDIRECT_URI,
    environment,
  };
}

export function getBaseUrl(environment: "production" | "sandbox"): string {
  return environment === "production"
    ? "https://api.ebay.com"
    : "https://api.sandbox.ebay.com";
}

export function getAuthUrl(environment: "production" | "sandbox"): string {
  return environment === "production"
    ? "https://api.ebay.com/identity/v1/oauth2/token"
    : "https://api.sandbox.ebay.com/identity/v1/oauth2/token";
}

/**
 * Generate the OAuth authorization URL for user consent
 * This URL should be opened in a browser for the user to grant permissions
 */
export function getOAuthAuthorizationUrl(
  clientId: string,
  redirectUri: string,
  environment: "production" | "sandbox",
  scopes?: string[],
  state?: string,
): string {
  // Default scopes for eBay Sell APIs
  const defaultScopes = [
    "https://api.ebay.com/oauth/api_scope",
    "https://api.ebay.com/oauth/api_scope/buy.order.readonly",
    "https://api.ebay.com/oauth/api_scope/buy.guest.order",
    "https://api.ebay.com/oauth/api_scope/sell.marketing.readonly",
    "https://api.ebay.com/oauth/api_scope/sell.marketing",
    "https://api.ebay.com/oauth/api_scope/sell.inventory.readonly",
    "https://api.ebay.com/oauth/api_scope/sell.inventory",
    "https://api.ebay.com/oauth/api_scope/sell.account.readonly",
    "https://api.ebay.com/oauth/api_scope/sell.account",
    "https://api.ebay.com/oauth/api_scope/sell.fulfillment.readonly",
    "https://api.ebay.com/oauth/api_scope/sell.fulfillment",
    "https://api.ebay.com/oauth/api_scope/sell.analytics.readonly",
    "https://api.ebay.com/oauth/api_scope/sell.marketplace.insights.readonly",
    "https://api.ebay.com/oauth/api_scope/commerce.catalog.readonly",
    "https://api.ebay.com/oauth/api_scope/buy.shopping.cart",
    "https://api.ebay.com/oauth/api_scope/buy.offer.auction",
    "https://api.ebay.com/oauth/api_scope/commerce.identity.readonly",
    "https://api.ebay.com/oauth/api_scope/commerce.identity.email.readonly",
    "https://api.ebay.com/oauth/api_scope/commerce.identity.phone.readonly",
    "https://api.ebay.com/oauth/api_scope/commerce.identity.address.readonly",
    "https://api.ebay.com/oauth/api_scope/commerce.identity.name.readonly",
    "https://api.ebay.com/oauth/api_scope/commerce.identity.status.readonly",
    "https://api.ebay.com/oauth/api_scope/sell.finances",
    "https://api.ebay.com/oauth/api_scope/sell.payment.dispute",
    "https://api.ebay.com/oauth/api_scope/sell.item.draft",
    "https://api.ebay.com/oauth/api_scope/sell.item",
    "https://api.ebay.com/oauth/api_scope/sell.reputation",
    "https://api.ebay.com/oauth/api_scope/sell.reputation.readonly",
    "https://api.ebay.com/oauth/api_scope/commerce.notification.subscription",
    "https://api.ebay.com/oauth/api_scope/commerce.notification.subscription.readonly",
    "https://api.ebay.com/oauth/api_scope/sell.stores",
    "https://api.ebay.com/oauth/api_scope/sell.stores.readonly",
    "https://api.ebay.com/oauth/api_scope/commerce.vero",
  ];

  const scopesList = scopes && scopes.length > 0 ? scopes : defaultScopes;
  const scopeParam = scopesList.join(" ");

  // Build the authorize URL
  const authDomain =
    environment === "production"
      ? "https://auth.ebay.com"
      : "https://auth.sandbox.ebay.com";

  const authorizeEndpoint = `${authDomain}/oauth2/authorize`;

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: scopeParam,
  });

  if (state) {
    params.append("state", state);
  }

  // Build the signin URL that redirects to authorize
  const signinDomain =
    environment === "production"
      ? "https://signin.ebay.com"
      : "https://signin.sandbox.ebay.com";

  const ruParam = encodeURIComponent(`${authorizeEndpoint}?${params.toString()}`);

  return `${signinDomain}/signin?ru=${ruParam}&sgfl=oauth2_login&AppName=${clientId}`;
}
