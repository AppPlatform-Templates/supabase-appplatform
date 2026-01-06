-- Supabase Database Initialization Script
-- Idempotent - safe to run multiple times

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE SCHEMA IF NOT EXISTS realtime;
CREATE SCHEMA IF NOT EXISTS _realtime;

-- Install required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;

-- Install optional extensions (fail silently if not available)
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- Create Supabase API roles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN NOINHERIT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN NOINHERIT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        CREATE ROLE supabase_auth_admin NOLOGIN NOINHERIT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE ROLE supabase_storage_admin NOLOGIN NOINHERIT;
    END IF;
END $$;

-- Create supabase_admin user (used by Studio/Meta)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE ROLE supabase_admin LOGIN CREATEROLE CREATEDB;
    END IF;
END $$;

-- Set supabase_admin password to match doadmin
\set password_sql 'ALTER ROLE supabase_admin WITH PASSWORD ' :'admin_password'
:password_sql;

-- Grant database privileges to supabase_admin
GRANT ALL PRIVILEGES ON DATABASE defaultdb TO supabase_admin;

-- Grant schema permissions to supabase_admin
GRANT ALL ON SCHEMA public TO supabase_admin;
GRANT ALL ON SCHEMA auth TO supabase_admin;
GRANT ALL ON SCHEMA storage TO supabase_admin;
GRANT USAGE ON SCHEMA extensions TO supabase_admin;
GRANT ALL ON SCHEMA realtime TO supabase_admin;
GRANT ALL ON SCHEMA _realtime TO supabase_admin;

-- Grant auth schema permissions to doadmin (used by GoTrue for migrations)
GRANT ALL ON SCHEMA auth TO doadmin;
ALTER SCHEMA auth OWNER TO doadmin;

-- Grant realtime schema permissions to doadmin (used by Realtime for migrations)
GRANT ALL ON SCHEMA realtime TO doadmin;
ALTER SCHEMA realtime OWNER TO doadmin;

-- Grant _realtime schema permissions to doadmin (used by Realtime for internal tables)
GRANT ALL ON SCHEMA _realtime TO doadmin;
ALTER SCHEMA _realtime OWNER TO doadmin;

-- Grant storage schema permissions to doadmin (used by Storage API for migrations)
GRANT ALL ON SCHEMA storage TO doadmin;
ALTER SCHEMA storage OWNER TO doadmin;

-- Grant permissions to API roles (anon, authenticated, service_role) on public schema
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Grant permissions on realtime schema (for Realtime migrations and subscriptions)
GRANT USAGE ON SCHEMA realtime TO anon, authenticated, service_role;

-- Grant permissions on auth schema to supabase_auth_admin
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA auth GRANT ALL ON TABLES TO supabase_auth_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA auth GRANT ALL ON SEQUENCES TO supabase_auth_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA auth GRANT ALL ON ROUTINES TO supabase_auth_admin;

-- Grant permissions on storage schema to supabase_storage_admin
GRANT USAGE ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;

-- Set default privileges for future objects in storage schema
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON TABLES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON SEQUENCES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON ROUTINES TO supabase_storage_admin;

-- Grant permissions on extensions schema
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO anon, authenticated, service_role;

-- Set default privileges for future objects in public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
