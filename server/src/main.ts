import express from "express";
import cors from "cors";
import { initFirebase } from "./firebase";
import { devicesRouter } from "./routes/devices";
import { alertsRouter } from "./routes/alerts";

initFirebase();

const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => res.json({ ok: true }));
app.use("/api/devices", devicesRouter);
app.use("/api/alerts", alertsRouter);

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Server on :${port}`));