-- Supabase Database Initialization Script
-- This script is idempotent and safe to run multiple times
-- Each section checks if its work is already done before executing

-- Initialization start
DO $$
BEGIN
    RAISE NOTICE '======================================';
    RAISE NOTICE 'Starting Supabase database initialization...';
    RAISE NOTICE '======================================';
END $$;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS extensions;

-- Install required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;

-- Install optional extensions (if available)
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
    RAISE NOTICE 'pg_net extension created successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'pg_net extension not available (optional): %', SQLERRM;
END $$;

DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;
    RAISE NOTICE 'vector extension created successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'vector extension not available (optional): %', SQLERRM;
END $$;

-- Create Supabase API roles (for RLS and API access)
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

-- Create supabase_admin user for Studio
-- Studio encrypts connection strings with this username hardcoded
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE ROLE supabase_admin LOGIN CREATEROLE CREATEDB;
        RAISE NOTICE 'Created role: supabase_admin';
    END IF;
END $$;

-- Set supabase_admin password to match doadmin password
-- This allows Studio to connect using the same credentials
\set password_sql 'ALTER ROLE supabase_admin WITH PASSWORD ' :'admin_password'
:password_sql;

-- Grant database-level privileges to supabase_admin
GRANT ALL PRIVILEGES ON DATABASE defaultdb TO supabase_admin;

-- CRITICAL: Grant schema-level permissions to supabase_admin
-- This allows Studio to create tables, schemas, and other objects
GRANT ALL ON SCHEMA public TO supabase_admin;
GRANT ALL ON SCHEMA auth TO supabase_admin;
GRANT ALL ON SCHEMA storage TO supabase_admin;
GRANT USAGE ON SCHEMA extensions TO supabase_admin;

-- Grant permissions on public schema for API access
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Grant permissions on auth schema
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin, supabase_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin, supabase_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA auth TO supabase_auth_admin, supabase_admin;

-- Grant permissions on storage schema
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin, supabase_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin, supabase_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA storage TO supabase_storage_admin, supabase_admin;

-- Grant permissions on extensions schema
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO anon, authenticated, service_role, supabase_admin;

-- Set default privileges for future objects in public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;

-- CRITICAL: Grant postgres role membership to supabase_admin
-- This allows supabase_admin to execute "SET ROLE postgres" when creating schemas
-- Studio/Meta requires this capability for schema management operations
DO $$
BEGIN
    -- Check if supabase_admin already has postgres role
    IF NOT EXISTS (
        SELECT 1 FROM pg_auth_members
        WHERE roleid = (SELECT oid FROM pg_roles WHERE rolname = 'postgres')
        AND member = (SELECT oid FROM pg_roles WHERE rolname = 'supabase_admin')
    ) THEN
        -- Try to grant postgres role to supabase_admin
        BEGIN
            GRANT postgres TO supabase_admin;
            RAISE NOTICE '✓ Granted postgres role to supabase_admin (enables SET ROLE postgres)';
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE WARNING 'Failed to grant postgres role to supabase_admin: insufficient privileges';
                RAISE NOTICE 'Schema creation in Studio UI may fail with "must be able to SET ROLE postgres" error';
            WHEN OTHERS THEN
                RAISE WARNING 'Failed to grant postgres role to supabase_admin: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '✓ supabase_admin already has postgres role membership';
    END IF;
END $$;

-- Confirm initialization
DO $$
BEGIN
    RAISE NOTICE '======================================';
    RAISE NOTICE '✓ Supabase database initialization complete!';
    RAISE NOTICE '  - Schemas: auth, storage, extensions, public';
    RAISE NOTICE '  - Extensions: uuid-ossp, pgcrypto, pgjwt';
    RAISE NOTICE '  - Roles: anon, authenticated, service_role, supabase_auth_admin, supabase_storage_admin, supabase_admin';
    RAISE NOTICE '  - supabase_admin can create tables, schemas, and manage database objects';
    RAISE NOTICE '======================================';
END $$;
