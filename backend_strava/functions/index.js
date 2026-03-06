/**
 * BACKEND ENTRY POINT
 * Exports functions from modular files.
 */

const auth = require("./auth");
const webhook = require("./webhook");
const sync = require("./sync");
const scheduledSync = require("./scheduled_sync");

// Auth
exports.exchangeToken = auth.exchangeToken;
exports.deauthorizeUser = auth.deauthorizeUser;

// Webhook
exports.stravaWebhook = webhook.stravaWebhook;

// Sync
exports.syncActivities = sync.syncActivities;
exports.syncFullHistory = sync.syncFullHistoryCloud;
exports.enqueueWeeklySyncs = scheduledSync.enqueueWeeklySyncs;
exports.syncWorker = scheduledSync.syncWorker;