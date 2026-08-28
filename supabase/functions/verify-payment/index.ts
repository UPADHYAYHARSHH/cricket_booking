import { serve } from "https://deno.land/std/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { order_id } = await req.json()
    
    const appId = Deno.env.get('CASHFREE_APP_ID')!
    const secretKey = Deno.env.get('CASHFREE_SECRET_KEY')!
    const environment = Deno.env.get('CASHFREE_ENVIRONMENT') || 'SANDBOX';
    
    const endpoint = environment === 'PRODUCTION' 
        ? `https://api.cashfree.com/pg/orders/${order_id}` 
        : `https://sandbox.cashfree.com/pg/orders/${order_id}`;

    const cashfreeResponse = await fetch(endpoint, {
      method: 'GET',
      headers: {
        'x-client-id': appId,
        'x-client-secret': secretKey,
        'x-api-version': '2023-08-01',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    });

    const responseData = await cashfreeResponse.json();
    
    if (!cashfreeResponse.ok) {
      throw new Error(`Failed to fetch order: ${JSON.stringify(responseData)}`);
    }

    const isValid = responseData.order_status === 'PAID';

    return new Response(
      JSON.stringify({ success: isValid, status: responseData.order_status }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})
