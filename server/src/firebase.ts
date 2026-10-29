import * as admin from "firebase-admin";

let initialized = false;

export function initFirebase() {
  if (initialized) return;
  const json = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!json) {
    console.warn("FIREBASE_SERVICE_ACCOUNT not set; push disabled");
    return;
  }
  try {
    const cred = JSON.parse(json);
    admin.initializeApp({ credential: admin.credential.cert(cred) });
    initialized = true;
    console.log("Firebase initialized");
  } catch (e) {
    console.error("Firebase init failed", e);
  }
}

export function getMessaging() {
  if (!initialized) return null;
  return admin.messaging();
}