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

-- Install optional extensions
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

END $$;

-- Create service-specific users with LOGIN capability
-- These users are used by individual Supabase services for least-privilege access
-- All users share the same password as doadmin for simplicity in managed environments

DO $$
BEGIN
    -- Create supabase_auth_admin
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
        CREATE USER supabase_auth_admin NOINHERIT CREATEROLE LOGIN;
    END IF;

    -- Create supabase_storage_admin
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
        CREATE USER supabase_storage_admin NOINHERIT CREATEROLE LOGIN;
    END IF;

    -- Create authenticator
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticator') THEN
        CREATE USER authenticator NOINHERIT;
    END IF;

    -- Create supabase_admin
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_admin') THEN
        CREATE USER supabase_admin CREATEROLE CREATEDB BYPASSRLS;
    END IF;
END $$;

-- Grant API roles to authenticator (allows PostgREST to switch roles based on JWT)
GRANT anon TO authenticator;
GRANT authenticated TO authenticator;
GRANT service_role TO authenticator;

-- Grant service_role to storage admin (allows Storage API to impersonate service_role)
GRANT service_role TO supabase_storage_admin;

-- Grant service_role to auth admin (allows Auth service to impersonate service_role)
GRANT service_role TO supabase_auth_admin;

-- Set passwords using psql variable (passed from run-db-init.sh)
-- All users use the same password as doadmin for simplicity
-- ALTER USER is idempotent - setting password multiple times is safe
\gset
ALTER USER supabase_auth_admin WITH PASSWORD :'admin_password';
ALTER USER supabase_storage_admin WITH PASSWORD :'admin_password';
ALTER USER authenticator WITH PASSWORD :'admin_password';
ALTER USER supabase_admin WITH PASSWORD :'admin_password';

-- Grant database privileges to supabase_admin
GRANT ALL PRIVILEGES ON DATABASE defaultdb TO supabase_admin;

-- Grant CREATE on database to supabase_storage_admin (for migrations)
GRANT CREATE ON DATABASE defaultdb TO supabase_storage_admin;

-- Grant supabase_admin to authenticator (allows Studio to manage database)
GRANT supabase_admin TO authenticator;

-- Set statement timeouts for API roles (prevent long-running queries)
ALTER ROLE anon SET statement_timeout = '3s';
ALTER ROLE authenticated SET statement_timeout = '8s';

-- Grant schema permissions to supabase_admin
GRANT ALL ON SCHEMA public TO supabase_admin;
GRANT ALL ON SCHEMA auth TO supabase_admin;
GRANT ALL ON SCHEMA storage TO supabase_admin;
GRANT USAGE ON SCHEMA extensions TO supabase_admin;
GRANT ALL ON SCHEMA realtime TO supabase_admin;
GRANT ALL ON SCHEMA _realtime TO supabase_admin;

-- Transfer schema ownership to service-specific users
-- Each service owns its own schema for migrations
ALTER SCHEMA auth OWNER TO supabase_auth_admin;
ALTER SCHEMA storage OWNER TO supabase_storage_admin;
ALTER SCHEMA realtime OWNER TO supabase_admin;
ALTER SCHEMA _realtime OWNER TO supabase_admin;

-- Keep doadmin grants as fallback for complex migrations that might need elevated privileges
GRANT ALL ON SCHEMA auth TO doadmin;
GRANT ALL ON SCHEMA storage TO doadmin;
GRANT ALL ON SCHEMA realtime TO doadmin;
GRANT ALL ON SCHEMA _realtime TO doadmin;

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

-- Grant permissions on auth tables to supabase_admin (for Studio/Meta access)
-- This allows Studio to view users, audit logs, etc.
GRANT USAGE ON SCHEMA auth TO supabase_admin;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO supabase_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA auth TO supabase_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA auth GRANT ALL ON TABLES TO supabase_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA auth GRANT ALL ON SEQUENCES TO supabase_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA auth GRANT ALL ON ROUTINES TO supabase_admin;

-- Grant permissions on storage schema to supabase_storage_admin
GRANT USAGE ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;

-- Set default privileges for future objects in storage schema
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON TABLES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON SEQUENCES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON ROUTINES TO supabase_storage_admin;

-- Grant storage permissions to supabase_admin (for Studio/Meta access to buckets)
GRANT USAGE ON SCHEMA storage TO supabase_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA storage TO supabase_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON TABLES TO supabase_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON SEQUENCES TO supabase_admin;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON ROUTINES TO supabase_admin;

-- Grant storage permissions to service_role (CRITICAL for Storage API access)
GRANT USAGE ON SCHEMA storage TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE doadmin IN SCHEMA storage GRANT ALL ON SEQUENCES TO service_role;

-- Grant permissions on extensions schema
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO anon, authenticated, service_role;

-- Set default privileges for future objects in public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- Set default privileges for objects created by supabase_admin
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role;

-- ============================================================================
-- AUTH SCHEMA SETUP
-- ============================================================================
-- NOTE: Auth tables are created by GoTrue migrations, not here
-- We only set permissions and search paths for the auth schema

-- Grant permissions for future auth tables (created by GoTrue migrations)
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA auth TO supabase_auth_admin;

-- Grant permissions to supabase_admin for Studio access
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO supabase_admin;
GRANT ALL ON ALL ROUTINES IN SCHEMA auth TO supabase_admin;

-- ============================================================================
-- CREATE STORAGE SCHEMA TABLES
-- ============================================================================
-- Storage API expects these tables to exist
-- NOTE: Foreign keys to auth.users are omitted because auth tables are created
-- by GoTrue migrations after this script runs. Storage API handles auth checks
-- via RLS policies and application logic instead.

-- Buckets table
CREATE TABLE IF NOT EXISTS storage.buckets (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    owner UUID,  -- References auth.users(id) but FK added later by Storage migrations
    public BOOLEAN DEFAULT false,
    avif_autodetection BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    file_size_limit BIGINT,
    allowed_mime_types TEXT[]
);

-- Objects table
CREATE TABLE IF NOT EXISTS storage.objects (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    bucket_id TEXT REFERENCES storage.buckets(id),
    name TEXT NOT NULL,
    owner UUID,  -- References auth.users(id) but FK added later by Storage migrations
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB,
    path_tokens TEXT[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED,
    version TEXT,
    UNIQUE(bucket_id, name)
);

-- S3 Multipart uploads table
CREATE TABLE IF NOT EXISTS storage.s3_multipart_uploads (
    id TEXT PRIMARY KEY,
    in_progress_size BIGINT DEFAULT 0,
    upload_signature TEXT NOT NULL,
    bucket_id TEXT NOT NULL REFERENCES storage.buckets(id),
    key TEXT NOT NULL,
    version TEXT NOT NULL,
    owner_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(bucket_id, key)
);

-- S3 Multipart uploads parts table
CREATE TABLE IF NOT EXISTS storage.s3_multipart_uploads_parts (
    id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    upload_id TEXT NOT NULL REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE,
    size BIGINT DEFAULT 0,
    part_number INT NOT NULL,
    bucket_id TEXT NOT NULL REFERENCES storage.buckets(id),
    key TEXT NOT NULL,
    etag TEXT NOT NULL,
    owner_id TEXT,
    version TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for storage tables
CREATE INDEX IF NOT EXISTS objects_bucket_id_idx ON storage.objects(bucket_id);
CREATE INDEX IF NOT EXISTS objects_name_idx ON storage.objects(name);
CREATE INDEX IF NOT EXISTS objects_bucket_id_name_idx ON storage.objects(bucket_id, name);

-- Transfer ownership of storage tables to supabase_storage_admin
ALTER TABLE IF EXISTS storage.buckets OWNER TO supabase_storage_admin;
ALTER TABLE IF EXISTS storage.objects OWNER TO supabase_storage_admin;
ALTER TABLE IF EXISTS storage.s3_multipart_uploads OWNER TO supabase_storage_admin;
ALTER TABLE IF EXISTS storage.s3_multipart_uploads_parts OWNER TO supabase_storage_admin;

-- ============================================================================
-- CONFIGURE SEARCH PATH (Supabase best practice)
-- ============================================================================
-- Use ALTER ROLE ... IN DATABASE for highest precedence
-- This ensures search_path is set for each role specifically in this database

-- Set search_path for service_role (Storage API uses this role!)
-- CRITICAL: Must include storage schema FIRST for Storage API to find buckets table
ALTER ROLE service_role IN DATABASE defaultdb SET search_path = storage, public, auth, extensions;

-- Set search_path for doadmin
ALTER ROLE doadmin IN DATABASE defaultdb SET search_path = storage, public, auth, extensions;

-- Set search_path for authenticator (used by PostgREST)
ALTER ROLE authenticator IN DATABASE defaultdb SET search_path = public, extensions;

-- Set search_path for storage admin
ALTER ROLE supabase_storage_admin IN DATABASE defaultdb SET search_path = storage, public, extensions;

-- Set search_path for auth admin
ALTER ROLE supabase_auth_admin IN DATABASE defaultdb SET search_path = auth, public, extensions;

-- Set search_path for supabase_admin (don't include auth schema per official setup)
ALTER ROLE supabase_admin IN DATABASE defaultdb SET search_path = public, extensions;
