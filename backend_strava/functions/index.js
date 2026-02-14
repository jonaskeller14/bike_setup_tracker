/**
 * BACKEND ENTRY POINT
 * Exports functions from modular files.
 */

const auth = require("./auth");
const webhook = require("./webhook");
const sync = require("./sync");

// Auth
exports.exchangeToken = auth.exchangeToken;
exports.deauthorizeUser = auth.deauthorizeUser;

// Webhook
exports.stravaWebhook = webhook.stravaWebhook;

// Sync
exports.syncActivities = sync.syncActivities;
exports.syncFullHistory = sync.syncFullHistoryCloud;