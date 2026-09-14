import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function getCashfreeToken(clientId: string, clientSecretOrKey: string, env: string) {
  const tokenEndpoint = env === 'PRODUCTION' ? 'https://payout-api.cashfree.com/payout/v1/authorize' : 'https://payout-gamma.cashfree.com/payout/v1/authorize';
  
  const headers: Record<string, string> = {
    'X-Client-Id': clientId,
    'Content-Type': 'application/json'
  };

  if (clientSecretOrKey.includes('BEGIN PUBLIC KEY')) {
    const epoch = Math.floor(Date.now() / 1000).toString();
    const dataToSign = `${clientId}.${epoch}`;

    const pemHeader = "-----BEGIN PUBLIC KEY-----";
    const pemFooter = "-----END PUBLIC KEY-----";
    const pemContents = clientSecretOrKey.replace(pemHeader, "").replace(pemFooter, "").replace(/\s/g, "");
    
    const binaryDerString = atob(pemContents);
    const binaryDer = new Uint8Array(binaryDerString.length);
    for (let i = 0; i < binaryDerString.length; i++) {
      binaryDer[i] = binaryDerString.charCodeAt(i);
    }

    // Try importing as RSA-OAEP with SHA-1 (common default for Cashfree)
    const key = await crypto.subtle.importKey(
      "spki",
      binaryDer,
      {
        name: "RSA-OAEP",
        hash: "SHA-1",
      },
      false,
      ["encrypt"]
    );

    const data = new TextEncoder().encode(dataToSign);
    const encryptedBuffer = await crypto.subtle.encrypt("RSA-OAEP", key, data);
    const signature = btoa(String.fromCharCode(...new Uint8Array(encryptedBuffer)));

    headers['X-Client-Signature'] = signature;
  } else {
    headers['X-Client-Secret'] = clientSecretOrKey;
  }

  const tokenResponse = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: headers
  });

  const tokenData = await tokenResponse.json();
  if (tokenData.status !== 'SUCCESS') {
    throw new Error('Cashfree Auth Failed: ' + tokenData.message);
  }
  return tokenData.data.token;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { withdrawal_id, action } = await req.json();
    
    if (!withdrawal_id || !action || !['approve', 'reject'].includes(action)) {
      return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }});
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: withdrawal, error: fetchError } = await supabase.from('withdrawals').select('*').eq('id', withdrawal_id).single();
    if (fetchError || !withdrawal) return new Response(JSON.stringify({ error: 'Withdrawal not found' }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' }});
    if (withdrawal.status !== 'pending') return new Response(JSON.stringify({ error: 'Cannot process withdrawal with status: ' + withdrawal.status }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }});

    if (action === 'reject') {
      const { data: ownerWallet } = await supabase.from('owner_wallets').select('available_balance').eq('owner_id', withdrawal.owner_id).single();
      await supabase.from('owner_wallets').update({ available_balance: (ownerWallet?.available_balance || 0) + withdrawal.amount }).eq('owner_id', withdrawal.owner_id);
      await supabase.from('withdrawals').update({ status: 'rejected' }).eq('id', withdrawal_id);
      return new Response(JSON.stringify({ success: true, message: 'Rejected' }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }});
    }

    await supabase.from('withdrawals').update({ status: 'processing' }).eq('id', withdrawal_id);

    try {
      const clientId = Deno.env.get('CASHFREE_PAYOUT_CLIENT_ID') || Deno.env.get('CASHFREE_CLIENT_ID');
      const clientSecret = Deno.env.get('CASHFREE_PAYOUT_CLIENT_SECRET') || Deno.env.get('CASHFREE_CLIENT_SECRET');
      const env = Deno.env.get('CASHFREE_ENVIRONMENT') || 'SANDBOX';
      
      if (!clientId || !clientSecret) throw new Error('Cashfree credentials missing');

      const bearerToken = await getCashfreeToken(clientId, clientSecret, env);
      
      const endpoint = env === 'PRODUCTION' ? 'https://payout-api.cashfree.com/payout/v1/requestTransfer' : 'https://payout-gamma.cashfree.com/payout/v1/requestTransfer';
      const transferId = 'TR_' + withdrawal_id.replace(/-/g, '').substring(0, 20);
      
      const payoutResponse = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + bearerToken,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          beneId: "test_bene_1",
          amount: withdrawal.amount,
          transferId: transferId,
          transferMode: "upi",
          remarks: "TurfPro Owner Withdrawal"
        })
      });

      const payoutData = await payoutResponse.json();

      if (payoutData.status === 'SUCCESS' || payoutData.status === 'PENDING') {
        await supabase.from('withdrawals').update({ status: 'success', cashfree_transfer_id: transferId }).eq('id', withdrawal_id);
        const { data: ownerWallet } = await supabase.from('owner_wallets').select('withdrawn_amount').eq('owner_id', withdrawal.owner_id).single();
        await supabase.from('owner_wallets').update({ withdrawn_amount: (ownerWallet?.withdrawn_amount || 0) + withdrawal.amount }).eq('owner_id', withdrawal.owner_id);
        return new Response(JSON.stringify({ success: true, message: 'Payout successful', transferId }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      } else {
        const { data: ownerWallet } = await supabase.from('owner_wallets').select('available_balance').eq('owner_id', withdrawal.owner_id).single();
        await supabase.from('owner_wallets').update({ available_balance: (ownerWallet?.available_balance || 0) + withdrawal.amount }).eq('owner_id', withdrawal.owner_id);
        await supabase.from('withdrawals').update({ status: 'failed', failure_reason: payoutData.message }).eq('id', withdrawal_id);
        return new Response(JSON.stringify({ error: 'Cashfree Payout Failed: ' + payoutData.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
      }
    } catch (innerError) {
      await supabase.from('withdrawals').update({ status: 'pending' }).eq('id', withdrawal_id);
      throw innerError;
    }

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
