-- Update handle_new_user trigger to read username and role from signup metadata
CREATE OR REPLACE FUNCTION mods4hire.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO mods4hire.profiles (id, username, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'hirer')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;
