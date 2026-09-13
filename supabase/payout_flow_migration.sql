-- Migration: Owner Payout Flow using Cashfree Sandbox

-- 1. Create owner_wallets table
CREATE TABLE IF NOT EXISTS public.owner_wallets (
    owner_id TEXT PRIMARY KEY,
    total_earnings NUMERIC NOT NULL DEFAULT 0.0,
    available_balance NUMERIC NOT NULL DEFAULT 0.0,
    withdrawn_amount NUMERIC NOT NULL DEFAULT 0.0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for owner_wallets
ALTER TABLE public.owner_wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can view their own wallet" 
ON public.owner_wallets FOR SELECT 
USING (auth.uid()::text = owner_id);

CREATE POLICY "Admin/Edge Functions can manage wallets" 
ON public.owner_wallets FOR ALL 
USING (auth.jwt()->>'role' = 'service_role' OR auth.jwt()->>'role' = 'admin');

-- 2. Create withdrawals table
CREATE TABLE IF NOT EXISTS public.withdrawals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id TEXT NOT NULL REFERENCES public.owner_wallets(owner_id),
    amount NUMERIC NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'processing', 'success', 'failed', 'rejected')),
    cashfree_transfer_id TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for withdrawals
ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can view their own withdrawals" 
ON public.withdrawals FOR SELECT 
USING (auth.uid()::text = owner_id);

CREATE POLICY "Owners can create withdrawals"
ON public.withdrawals FOR INSERT
WITH CHECK (auth.uid()::text = owner_id);

CREATE POLICY "Admin/Edge Functions can manage withdrawals" 
ON public.withdrawals FOR ALL 
USING (auth.jwt()->>'role' = 'service_role' OR auth.jwt()->>'role' = 'admin');

-- 3. Add payout status columns to bookings
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS payout_status TEXT DEFAULT 'pending' CHECK (payout_status IN ('pending', 'processing', 'settled', 'failed')),
ADD COLUMN IF NOT EXISTS withdrawal_id UUID REFERENCES public.withdrawals(id);

-- 4. Trigger to automatically credit owner wallet when booking is PAID/CONFIRMED
CREATE OR REPLACE FUNCTION update_owner_wallet_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    v_owner_id TEXT;
BEGIN
    -- Only trigger when status changes to 'paid' or 'confirmed'
    IF (NEW.status IN ('paid', 'confirmed') AND (OLD.status NOT IN ('paid', 'confirmed') OR OLD.status IS NULL)) THEN
        
        -- Get the owner_id from the grounds table
        SELECT owner_id INTO v_owner_id FROM public.grounds WHERE id = NEW.ground_id LIMIT 1;
        
        IF v_owner_id IS NOT NULL AND NEW.owner_earnings > 0 THEN
            -- Upsert the owner wallet
            INSERT INTO public.owner_wallets (owner_id, total_earnings, available_balance, updated_at)
            VALUES (v_owner_id, NEW.owner_earnings, NEW.owner_earnings, NOW())
            ON CONFLICT (owner_id) DO UPDATE SET
                total_earnings = owner_wallets.total_earnings + NEW.owner_earnings,
                available_balance = owner_wallets.available_balance + NEW.owner_earnings,
                updated_at = NOW();
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_owner_wallet ON public.bookings;
CREATE TRIGGER trigger_update_owner_wallet
AFTER UPDATE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION update_owner_wallet_on_payment();

-- 5. RPC to safely request a withdrawal
CREATE OR REPLACE FUNCTION request_withdrawal(p_amount NUMERIC)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_owner_id TEXT;
    v_wallet public.owner_wallets%ROWTYPE;
    v_withdrawal_id UUID;
    result JSON;
BEGIN
    v_owner_id := auth.uid()::text;
    
    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Lock the wallet row for update
    SELECT * INTO v_wallet FROM public.owner_wallets 
    WHERE owner_id = v_owner_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found for owner';
    END IF;

    IF v_wallet.available_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;

    -- Deduct from available balance immediately to prevent double spending
    UPDATE public.owner_wallets
    SET available_balance = available_balance - p_amount,
        updated_at = NOW()
    WHERE owner_id = v_owner_id;

    -- Create pending withdrawal record
    INSERT INTO public.withdrawals (owner_id, amount, status)
    VALUES (v_owner_id, p_amount, 'pending')
    RETURNING id INTO v_withdrawal_id;

    result := json_build_object(
        'success', true,
        'withdrawal_id', v_withdrawal_id,
        'new_balance', v_wallet.available_balance - p_amount
    );

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.request_withdrawal(NUMERIC) TO authenticated;

-- 6. RPC to get owner wallet details
CREATE OR REPLACE FUNCTION get_owner_wallet()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_owner_id TEXT;
    result JSON;
BEGIN
    v_owner_id := auth.uid()::text;
    
    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Upsert empty wallet if it doesn't exist just so we can return 0s
    INSERT INTO public.owner_wallets (owner_id)
    VALUES (v_owner_id)
    ON CONFLICT (owner_id) DO NOTHING;

    SELECT row_to_json(w) INTO result 
    FROM public.owner_wallets w 
    WHERE owner_id = v_owner_id;

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_owner_wallet() TO authenticated;
