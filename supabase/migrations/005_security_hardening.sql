-- ============================================================
--  Security Hardening — All shared schemas (mods4hire, gamers4rent, medicinerate)
--  Run once in Supabase SQL Editor.
--
--  Fixes:
--  1. is_admin privilege escalation — users could set is_admin=true on themselves
--  2. Admin panel profile update — admins could not update other users' profiles
--  3. applicant_id / tester_id — force server-side value so clients can't spoof it
-- ============================================================


-- ════════════════════════════════════════════════════════════
--  MODS4HIRE
-- ════════════════════════════════════════════════════════════

-- 1a. Allow admins to update ANY profile (fixes admin panel toggle)
DROP POLICY IF EXISTS "profiles_update" ON mods4hire.profiles;
CREATE POLICY "profiles_update" ON mods4hire.profiles FOR UPDATE USING (
  auth.uid() = id
  OR COALESCE((SELECT is_admin FROM mods4hire.profiles WHERE id = auth.uid()), false)
);

-- 1b. Prevent non-admins from granting themselves is_admin = true
CREATE OR REPLACE FUNCTION mods4hire.guard_is_admin()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.is_admin = true AND OLD.is_admin = false THEN
    IF NOT COALESCE(
      (SELECT is_admin FROM mods4hire.profiles WHERE id = auth.uid()),
      false
    ) THEN
      RAISE EXCEPTION 'Forbidden: cannot grant admin privileges';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_is_admin ON mods4hire.profiles;
CREATE TRIGGER guard_is_admin
  BEFORE UPDATE ON mods4hire.profiles
  FOR EACH ROW EXECUTE FUNCTION mods4hire.guard_is_admin();

-- 2. Force applicant_id to auth.uid() on every insert (clients cannot spoof it)
CREATE OR REPLACE FUNCTION mods4hire.set_applicant_id()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  NEW.applicant_id = auth.uid();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_applicant_id ON mods4hire.applications;
CREATE TRIGGER set_applicant_id
  BEFORE INSERT ON mods4hire.applications
  FOR EACH ROW EXECUTE FUNCTION mods4hire.set_applicant_id();


-- ════════════════════════════════════════════════════════════
--  GAMERS4RENT
-- ════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "profiles_update" ON gamers4rent.profiles;
CREATE POLICY "profiles_update" ON gamers4rent.profiles FOR UPDATE USING (
  auth.uid() = id
  OR COALESCE((SELECT is_admin FROM gamers4rent.profiles WHERE id = auth.uid()), false)
);

CREATE OR REPLACE FUNCTION gamers4rent.guard_is_admin()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.is_admin = true AND OLD.is_admin = false THEN
    IF NOT COALESCE(
      (SELECT is_admin FROM gamers4rent.profiles WHERE id = auth.uid()),
      false
    ) THEN
      RAISE EXCEPTION 'Forbidden: cannot grant admin privileges';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_is_admin ON gamers4rent.profiles;
CREATE TRIGGER guard_is_admin
  BEFORE UPDATE ON gamers4rent.profiles
  FOR EACH ROW EXECUTE FUNCTION gamers4rent.guard_is_admin();

-- Force tester_id to auth.uid() on insert
CREATE OR REPLACE FUNCTION gamers4rent.set_tester_id()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  NEW.tester_id = auth.uid();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_tester_id ON gamers4rent.applications;
CREATE TRIGGER set_tester_id
  BEFORE INSERT ON gamers4rent.applications
  FOR EACH ROW EXECUTE FUNCTION gamers4rent.set_tester_id();


-- ════════════════════════════════════════════════════════════
--  MEDICINERATE
-- ════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "profiles_update" ON medicinerate.profiles;
CREATE POLICY "profiles_update" ON medicinerate.profiles FOR UPDATE USING (
  auth.uid() = id
  OR COALESCE((SELECT is_admin FROM medicinerate.profiles WHERE id = auth.uid()), false)
);

CREATE OR REPLACE FUNCTION medicinerate.guard_is_admin()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.is_admin = true AND OLD.is_admin = false THEN
    IF NOT COALESCE(
      (SELECT is_admin FROM medicinerate.profiles WHERE id = auth.uid()),
      false
    ) THEN
      RAISE EXCEPTION 'Forbidden: cannot grant admin privileges';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_is_admin ON medicinerate.profiles;
CREATE TRIGGER guard_is_admin
  BEFORE UPDATE ON medicinerate.profiles
  FOR EACH ROW EXECUTE FUNCTION medicinerate.guard_is_admin();


NOTIFY pgrst, 'reload schema';
