/**
 * BACKEND ENTRY POINT
 * Exports functions from modular files.
 */

const auth = require("./auth");
const webhook = require("./webhook");
const sync = require("./sync");
const scheduledSync = require("./scheduled_sync");
const orphanCleanup = require("./orphan_cleanup");
const subscription = require("./subscription");
const subscriptionCleanup = require("./subscription_cleanup");

// Auth + availability
exports.exchangeToken = auth.exchangeToken;
exports.checkStravaAvailability = auth.checkStravaAvailability;

// Webhook
exports.stravaWebhook = webhook.stravaWebhook;
exports.webhookWorker = webhook.webhookWorker;

// Sync
exports.syncActivities = sync.syncActivities;
exports.syncFullHistory = sync.syncFullHistoryCloud;
exports.enqueueWeeklySyncs = scheduledSync.enqueueWeeklySyncs;
exports.scheduledSyncWorker = scheduledSync.scheduledSyncWorker;

// Orphan cleanup (Firestore trigger on users/{uid})
exports.cleanupOrphanedAthletes = orphanCleanup.cleanupOrphanedAthletes;

// Daily cron: unlink athletes for users whose entitlement expired GRACE_DAYS ago
exports.cleanupExpiredSubscriptions = subscriptionCleanup.cleanupExpiredSubscriptions;

// Subscriptions
exports.verifySubscription = subscription.verifySubscription;
exports.playSubscriptionWebhook = subscription.playSubscriptionWebhook;
exports.appStoreServerNotifications = subscription.appStoreServerNotifications;
