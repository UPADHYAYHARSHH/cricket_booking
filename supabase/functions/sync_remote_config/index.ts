import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { GoogleAuth } from "npm:google-auth-library@9.0.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse the Webhook payload
    const payload = await req.json();
    
    // Webhook from Supabase looks like: 
    // { type: 'UPDATE', table: 'app_config', record: { key: 'platform_fee', value: '25' }, old_record: ... }
    
    const record = payload.record;
    if (!record || !record.key || record.value === undefined) {
      return new Response(JSON.stringify({ error: "Invalid payload" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    const key = record.key;
    const value = record.value;

    console.log(`Received update for config: ${key} = ${value}`);

    // Map the Supabase app_config keys to Firebase Remote Config keys if necessary
    const keyMapping: Record<string, string> = {
      "platform_fee": "platform_fee",
      "commission_rate": "commission_rate",
      "commission_is_percentage": "commission_is_percentage",
      "android_min_version": "owner_android_min_version",
      "ios_min_version": "owner_ios_min_version",
      "android_store_url": "owner_android_store_url",
      "ios_store_url": "owner_ios_store_url",
      "owner_app_maintenance": "is_owner_under_maintenance",
      "user_app_maintenance": "is_under_maintenance"
    };

    const remoteConfigKey = keyMapping[key];
    if (!remoteConfigKey) {
      console.log(`Key ${key} does not have a mapped Remote Config parameter. Skipping.`);
      return new Response(JSON.stringify({ message: "Ignored" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // Initialize Google Auth with the service account
    // Ensure FIREBASE_SERVICE_ACCOUNT_JSON is set in Supabase Edge Function Secrets
    const serviceAccountJsonStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!serviceAccountJsonStr) {
      throw new Error("Missing FIREBASE_SERVICE_ACCOUNT_JSON in environment variables");
    }

    const credentials = JSON.parse(serviceAccountJsonStr);
    const projectId = credentials.project_id;

    const auth = new GoogleAuth({
      credentials,
      scopes: ["https://www.googleapis.com/auth/firebase.remoteconfig"],
    });

    const client = await auth.getClient();
    const tokenResponse = await client.getAccessToken();
    const accessToken = tokenResponse.token;

    if (!accessToken) {
      throw new Error("Failed to get access token");
    }

    const remoteConfigApiUrl = `https://firebaseremoteconfig.googleapis.com/v1/projects/${projectId}/remoteConfig`;

    // 1. Fetch current Remote Config Template
    console.log("Fetching current Remote Config template...");
    let getResponse = await fetch(remoteConfigApiUrl, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Accept-Encoding": "gzip",
      },
    });

    if (!getResponse.ok) {
      const errorText = await getResponse.text();
      throw new Error(`Failed to fetch remote config: ${getResponse.status} ${errorText}`);
    }

    // Important: ETag header is required for updates to prevent concurrent modification issues
    const eTag = getResponse.headers.get("ETag");
    const template = await getResponse.json();

    if (!template.parameters) {
      template.parameters = {};
    }

    // 2. Update the parameter
    console.log(`Updating parameter ${remoteConfigKey} to ${value}...`);
    template.parameters[remoteConfigKey] = {
      defaultValue: {
        value: value.toString()
      }
    };

    // 3. Publish the updated Remote Config Template
    console.log("Publishing updated template...");
    let putResponse = await fetch(remoteConfigApiUrl, {
      method: "PUT",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json; UTF8",
        "If-Match": eTag || "*",
      },
      body: JSON.stringify(template),
    });

    if (!putResponse.ok) {
      const errorText = await putResponse.text();
      throw new Error(`Failed to publish remote config: ${putResponse.status} ${errorText}`);
    }

    console.log(`Successfully updated Firebase Remote Config for ${remoteConfigKey}.`);

    return new Response(JSON.stringify({ success: true, message: "Remote config updated." }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: any) {
    console.error("Error updating remote config:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
