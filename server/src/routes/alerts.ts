import { Router } from "express";
import { getMessaging } from "../firebase";
import { getTokens } from "./devices";

export const alertsRouter = Router();

alertsRouter.post("/send", async (req, res) => {
  const { title, body, severity } = req.body || {};
  const messaging = getMessaging();
  const tokens = getTokens();
  if (!messaging || tokens.length === 0) {
    return res.json({ ok: false, reason: "no messaging or no tokens" });
  }
  try {
    const resp = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: title || "ELM327 Alert", body: body || "" },
      data: { severity: severity || "INFO" },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            "interruption-level": severity === "CRITICAL" ? "critical" : "active",
          },
        },
      },
    });
    res.json({ ok: true, success: resp.successCount, failure: resp.failureCount });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});