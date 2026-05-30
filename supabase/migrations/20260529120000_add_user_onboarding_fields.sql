-- Add onboarding preference fields to public.users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS country VARCHAR(10);
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS dialect VARCHAR(50);
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS language VARCHAR(10);

-- Enable RLS (already enabled on users, but ensures it stays solid)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
