import dotenv from "dotenv";
dotenv.config({ path: "backend.env" });

import express from "express";
import bodyParser from "body-parser";
import { createClient } from "@supabase/supabase-js";

const app = express();

// Twilio sends data as URL encoded
app.use(bodyParser.urlencoded({ extended: false }));

console.log('Has SUPABASE_URL?', !!process.env.SUPABASE_URL);
console.log('Has SERVICE_ROLE?', !!process.env.SUPABASE_SERVICE_ROLE);

// ✅ Use SERVICE_ROLE key here
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE
);

app.post("/twilio-webhook", async (req, res) => {
  const from = req.body.From || null;
  const message = req.body.Body || "";

  // Expected SMS Format: "CPR,12.9173,77.6043"
  let latitude = null;
  let longitude = null;

  const parts = message.split(",");
  if (parts.length >= 3) {
    latitude = parts[1];
    longitude = parts[2];
  }

  // ✅ Store in Supabase
  const { error } = await supabase
    .from("device_events")
    .insert({
      from_number: from,
      message,
      latitude,
      longitude
    });

  if (error) {
    console.error(error);
    res.set("Content-Type", "text/xml");
    return res.send(`<Response><Message>❌ DB Error</Message></Response>`);
  }

  // Twilio must receive XML
  res.set("Content-Type", "text/xml");
  res.send(`<Response><Message>✅ Location stored!</Message></Response>`);
});

// ✅ Start server
app.listen(3000, () => {
  console.log("✅ Backend running on http://localhost:3000");
});
