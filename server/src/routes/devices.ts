import { Router } from "express";

const tokens = new Set<string>();

export const devicesRouter = Router();

devicesRouter.post("/register", (req, res) => {
  const { token, platform } = req.body || {};
  if (!token) return res.status(400).json({ error: "token required" });
  tokens.add(token);
  console.log("Registered device", platform, token.slice(0, 12) + "...");
  res.json({ ok: true, count: tokens.size });
});

export function getTokens(): string[] {
  return Array.from(tokens);
}