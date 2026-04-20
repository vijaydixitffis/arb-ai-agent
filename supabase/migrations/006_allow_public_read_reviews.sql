-- Allow public read access to reviews table for demo purposes
-- This allows demo users (without Supabase auth) to see reviews

DROP POLICY IF EXISTS "SA can read own reviews" ON reviews;

CREATE POLICY "SA can read own reviews" ON reviews 
  FOR SELECT USING (
    auth.uid() = sa_user_id OR
    auth.uid() IS NULL  -- Allow demo users without auth
  );
