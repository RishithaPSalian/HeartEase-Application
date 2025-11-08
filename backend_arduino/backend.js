import dotenv from "dotenv";
dotenv.config({ path: "backend.env" });

import express from "express";
import bodyParser from "body-parser";
import { createClient } from "@supabase/supabase-js";

const app = express();

// Twilio sends application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false }));

// ---- Env checks ----
if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE) {
  console.error("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE in backend.env");
  process.exit(1);
}

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE
);

// ---- Simple routes ----
app.get("/", (_req, res) => res.send("Backend is running ✅"));
app.get("/health", (_req, res) => res.json({ ok: true }));

// ---- Twilio Webhook ----
app.post("/twilio-webhook", async (req, res) => {
  try {
    const from = (req.body.From || "").trim();
    const body = (req.body.Body || "").trim();

    // Expect: CPR,<lat>,<lng>
    // e.g., "CPR,12.9173,77.6043"
    let latitude = null;
    let longitude = null;

    // robust parse (case-insensitive, spaces allowed)
    const m = body.match(/^CPR\s*,\s*([+-]?\d+(?:\.\d+)?)\s*,\s*([+-]?\d+(?:\.\d+)?)$/i);
    if (m) {
      latitude = parseFloat(m[1]);
      longitude = parseFloat(m[2]);
    }

    // Store in Supabase (assumes numeric columns for lat/lng)
    const { error } = await supabase.from("device_events").insert({
      from_number: from || null,
      message: body,
      latitude: isFinite(latitude) ? latitude : null,
      longitude: isFinite(longitude) ? longitude : null
    });

    if (error) {
      console.error("Supabase insert error:", error);
      res.status(200).type("text/xml")
        .send(`<Response><Message>❌ DB Error</Message></Response>`);
      return;
    }

    // Respond TwiML
    res.status(200).type("text/xml")
      .send(`<Response><Message>✅ Location stored!</Message></Response>`);
  } catch (e) {
    console.error("Webhook error:", e);
    res.status(200).type("text/xml")
      .send(`<Response><Message>❌ Server error</Message></Response>`);
  }
});

// ---- Start server ----
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Backend running on http://localhost:${PORT}`);
});
