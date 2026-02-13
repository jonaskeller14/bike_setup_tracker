const { setGlobalOptions } = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

// GLOBAL CONFIG: Set to europe-west3 as requested. maxInstances = 1 (Free Tier)
setGlobalOptions({ maxInstances: 1, region: "europe-west3" });

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

module.exports = {
  admin,
  db,
  logger,
};
