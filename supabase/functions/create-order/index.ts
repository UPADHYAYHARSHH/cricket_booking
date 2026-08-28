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
    const { amount, return_url } = await req.json()

    const appId = Deno.env.get('CASHFREE_APP_ID')!
    const secretKey = Deno.env.get('CASHFREE_SECRET_KEY')!
    const environment = Deno.env.get('CASHFREE_ENVIRONMENT') || 'SANDBOX';
    
    const endpoint = environment === 'PRODUCTION' 
        ? 'https://api.cashfree.com/pg/orders' 
        : 'https://sandbox.cashfree.com/pg/orders';

    const orderId = `order_${Date.now()}`;

    const requestBody: any = {
      order_amount: amount,
      order_currency: "INR",
      order_id: orderId,
      customer_details: {
        customer_id: `cust_${Date.now()}`,
        customer_phone: "9999999999", // Replace with actual user phone if available
        customer_email: "test@example.com", // Replace with actual user email
        customer_name: "Customer"
      }
    };

    if (return_url) {
      requestBody.order_meta = {
        return_url: return_url
      };
    }

    const cashfreeResponse = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'x-client-id': appId,
        'x-client-secret': secretKey,
        'x-api-version': '2023-08-01',
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    const responseData = await cashfreeResponse.json();

    if (!cashfreeResponse.ok) {
      throw new Error(`Cashfree Error: ${JSON.stringify(responseData)}`);
    }

    return new Response(
      JSON.stringify({
        order_id: orderId,
        payment_session_id: responseData.payment_session_id,
        raw_response: responseData
      }),
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
