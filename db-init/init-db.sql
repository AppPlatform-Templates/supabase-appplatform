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
-- Drop and recreate to ensure clean state with correct password
DROP ROLE IF EXISTS supabase_admin CASCADE;
CREATE ROLE supabase_admin LOGIN CREATEROLE CREATEDB BYPASSRLS;

-- Set password using psql variable (passed from run-db-init.sh)
\gset
ALTER ROLE supabase_admin WITH PASSWORD :'admin_password';

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

-- Grant permissions on extensions schema
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO anon, authenticated, service_role;

-- Set default privileges for future objects in public schema
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

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

-- Buckets table
CREATE TABLE IF NOT EXISTS storage.buckets (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    owner UUID REFERENCES auth.users(id),
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
    owner UUID REFERENCES auth.users(id),
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

-- Grant permissions to storage roles
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_admin;

-- Set default search_path for storage admin (critical for Storage service to find tables)
ALTER ROLE supabase_storage_admin SET search_path = storage, public, extensions;

-- Set search_path for auth admin (critical for GoTrue to find auth tables)
ALTER ROLE supabase_auth_admin SET search_path = auth, public, extensions;

-- Set search_path for doadmin (Storage and other services connect as doadmin)
-- CRITICAL: Must include both storage and auth schemas
ALTER ROLE doadmin SET search_path = public, auth, storage, extensions;

-- Set search_path for service_role (sometimes used by Storage)
ALTER ROLE service_role SET search_path = public, storage, extensions;

-- Set search_path for authenticated and anon roles
ALTER ROLE authenticated SET search_path = public, storage, extensions;
ALTER ROLE anon SET search_path = public, extensions;
