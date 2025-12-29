-- Supabase Database Initialization Script
-- This script is idempotent and safe to run multiple times
-- It will create schemas, extensions, roles, and permissions needed for Supabase

-- Exit early if already initialized
DO $$
BEGIN
    -- Check if we've already initialized by looking for the auth schema
    IF EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth'
    ) AND EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'anon'
    ) THEN
        RAISE NOTICE 'Supabase database already initialized. Skipping initialization.';
        RETURN;
    END IF;

    RAISE NOTICE 'Initializing Supabase database...';
END $$;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS extensions;

-- Install extensions (must be superuser or have appropriate privileges)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;

-- Optional extensions (may not be available on all PostgreSQL installations)
DO $$
BEGIN
    -- Try to create pg_net extension
    CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
    RAISE NOTICE 'pg_net extension created successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'pg_net extension not available: %', SQLERRM;
END $$;

DO $$
BEGIN
    -- Try to create pgvector extension
    CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;
    RAISE NOTICE 'vector extension created successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'vector extension not available: %', SQLERRM;
END $$;

-- Create Supabase roles (skip if they already exist)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN NOINHERIT;
        RAISE NOTICE 'Created role: anon';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN NOINHERIT;
        RAISE NOTICE 'Created role: authenticated';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
        RAISE NOTICE 'Created role: service_role';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        CREATE ROLE supabase_auth_admin NOLOGIN NOINHERIT;
        RAISE NOTICE 'Created role: supabase_auth_admin';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE ROLE supabase_storage_admin NOLOGIN NOINHERIT;
        RAISE NOTICE 'Created role: supabase_storage_admin';
    END IF;
END $$;

-- Create supabase_admin user with same password as doadmin (for Studio/Meta)
-- Note: On DO managed DB, we can't make it SUPERUSER, but we grant it all other privileges
-- Studio hardcodes 'supabase_admin' as the username in encrypted connection strings
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE ROLE supabase_admin LOGIN CREATEROLE CREATEDB;
        RAISE NOTICE 'Created role: supabase_admin';
    END IF;
END $$;

-- Set supabase_admin password to match doadmin password
\set password_sql 'ALTER ROLE supabase_admin WITH PASSWORD ' :'admin_password'
:password_sql;

-- Grant extensive privileges to supabase_admin
GRANT ALL PRIVILEGES ON DATABASE defaultdb TO supabase_admin;

-- Grant membership in doadmin role to inherit its privileges
-- This allows supabase_admin to have similar capabilities to doadmin
GRANT doadmin TO supabase_admin;

-- Grant postgres role to allow SET ROLE postgres (needed for schema creation)
GRANT postgres TO supabase_admin WITH ADMIN OPTION;

-- Grant permissions on public schema
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Auth schema permissions
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA auth TO supabase_auth_admin;

-- Storage schema permissions
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA storage TO supabase_storage_admin;

-- Extensions schema permissions
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO anon, authenticated, service_role;

-- Enable Row Level Security by default for new tables in public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;

-- Confirm initialization
DO $$
BEGIN
    RAISE NOTICE '✓ Supabase database initialization complete!';
    RAISE NOTICE '  - Schemas: auth, storage, extensions';
    RAISE NOTICE '  - Extensions: uuid-ossp, pgcrypto, pgjwt';
    RAISE NOTICE '  - Roles: anon, authenticated, service_role, supabase_auth_admin, supabase_storage_admin';
END $$;
