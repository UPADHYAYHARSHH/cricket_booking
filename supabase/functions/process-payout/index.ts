import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

serve(async (req) => {
  try {
    const { withdrawal_id, action } = await req.json();
    
    // Validate inputs
    if (!withdrawal_id || !action || !['approve', 'reject'].includes(action)) {
      return new Response(JSON.stringify({ error: 'Invalid payload' }), { status: 400 });
    }

    // Initialize Supabase Admin Client to bypass RLS
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Fetch withdrawal
    const { data: withdrawal, error: fetchError } = await supabase
      .from('withdrawals')
      .select('*')
      .eq('id', withdrawal_id)
      .single();

    if (fetchError || !withdrawal) {
      return new Response(JSON.stringify({ error: 'Withdrawal not found' }), { status: 404 });
    }

    if (withdrawal.status !== 'pending') {
      return new Response(JSON.stringify({ error: Cannot process withdrawal with status:  }), { status: 400 });
    }

    if (action === 'reject') {
      // Restore balance
      const { error: walletError } = await supabase.rpc('restore_withdrawal_balance', { p_withdrawal_id: withdrawal_id, p_owner_id: withdrawal.owner_id, p_amount: withdrawal.amount });
      // We will define this RPC or just do a raw update via JS
      
      const { data: ownerWallet } = await supabase.from('owner_wallets').select('available_balance').eq('owner_id', withdrawal.owner_id).single();
      await supabase.from('owner_wallets').update({ available_balance: (ownerWallet?.available_balance || 0) + withdrawal.amount }).eq('owner_id', withdrawal.owner_id);

      await supabase.from('withdrawals').update({ status: 'rejected' }).eq('id', withdrawal_id);
      
      return new Response(JSON.stringify({ success: true, message: 'Withdrawal rejected and balance restored.' }), { status: 200 });
    }

    // Action is APPROVE -> Process Cashfree Sandbox Payout
    await supabase.from('withdrawals').update({ status: 'processing' }).eq('id', withdrawal_id);

    // Cashfree Config
    const clientId = Deno.env.get('CASHFREE_PAYOUT_CLIENT_ID') || Deno.env.get('CASHFREE_CLIENT_ID');
    const clientSecret = Deno.env.get('CASHFREE_PAYOUT_CLIENT_SECRET') || Deno.env.get('CASHFREE_CLIENT_SECRET');
    const env = Deno.env.get('CASHFREE_ENVIRONMENT') || 'SANDBOX';
    const endpoint = env === 'PRODUCTION' ? 'https://payout-api.cashfree.com/payout/v1/requestAsyncPayout' : 'https://payout-gamma.cashfree.com/payout/v1/requestAsyncPayout';

    if (!clientId || !clientSecret) {
      throw new Error('Cashfree credentials missing');
    }

    // Mock Payload for Cashfree Sandbox
    const transferId = TR_;
    const payoutPayload = {
      beneId: "test_bene_1", // Dummy beneficiary
      amount: withdrawal.amount,
      transferId: transferId,
      transferMode: "upi",
      remarks: "TurfPro Owner Withdrawal"
    };

    // Authenticate with Cashfree (Get Token)
    const tokenEndpoint = env === 'PRODUCTION' ? 'https://payout-api.cashfree.com/payout/v1/authorize' : 'https://payout-gamma.cashfree.com/payout/v1/authorize';
    const tokenResponse = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: {
        'X-Client-Id': clientId,
        'X-Client-Secret': clientSecret,
        'Content-Type': 'application/json'
      }
    });

    const tokenData = await tokenResponse.json();
    if (tokenData.status !== 'SUCCESS') {
      throw new Error(Cashfree Auth Failed: );
    }

    const bearerToken = tokenData.data.token;

    // Request Payout
    const payoutResponse = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Authorization': Bearer ,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payoutPayload)
    });

    const payoutData = await payoutResponse.json();

    if (payoutData.status === 'SUCCESS' || payoutData.status === 'PENDING') {
      // Success or Pending processing
      await supabase.from('withdrawals').update({ 
        status: 'success', 
        cashfree_transfer_id: transferId 
      }).eq('id', withdrawal_id);
      
      // Update wallet withdrawn amount
      const { data: ownerWallet } = await supabase.from('owner_wallets').select('withdrawn_amount').eq('owner_id', withdrawal.owner_id).single();
      await supabase.from('owner_wallets').update({ withdrawn_amount: (ownerWallet?.withdrawn_amount || 0) + withdrawal.amount }).eq('owner_id', withdrawal.owner_id);

      // Mark bookings as settled
      // (Optional: Requires linking bookings to withdrawal or just settling all pending up to amount)
      
      return new Response(JSON.stringify({ success: true, message: 'Payout successful', transferId }), { status: 200 });
    } else {
      // Failed payout -> Restore balance
      const { data: ownerWallet } = await supabase.from('owner_wallets').select('available_balance').eq('owner_id', withdrawal.owner_id).single();
      await supabase.from('owner_wallets').update({ available_balance: (ownerWallet?.available_balance || 0) + withdrawal.amount }).eq('owner_id', withdrawal.owner_id);

      await supabase.from('withdrawals').update({ 
        status: 'failed', 
        failure_reason: payoutData.message 
      }).eq('id', withdrawal_id);

      return new Response(JSON.stringify({ error: Cashfree Payout Failed:  }), { status: 400 });
    }

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { 'Content-Type': 'application/json' } });
  }
});
