#!/bin/bash
set -e

echo "================================================"
echo "Supabase Database Initialization"
echo "================================================"
echo ""

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL environment variable is not set"
    exit 1
fi

echo "✓ Database connection URL found"
echo ""

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "ERROR: psql command not found. Installing postgresql-client..."
    apt-get update && apt-get install -y postgresql-client
fi

echo "Running database initialization script..."
echo ""

# Extract the database password from DATABASE_URL
# Format: postgresql://user:password@host:port/dbname
DB_PASSWORD=$(echo "$DATABASE_URL" | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')

# Run the initialization script
psql "$DATABASE_URL" -f /app/init-db.sql

# Set supabase_admin password to match the database password
echo ""
echo "Setting supabase_admin password..."
PGPASSWORD="$DB_PASSWORD" psql "$DATABASE_URL" -c "ALTER USER supabase_admin WITH PASSWORD '$DB_PASSWORD';"

exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "✓ Database initialization completed successfully"
    echo "================================================"
else
    echo ""
    echo "================================================"
    echo "✗ Database initialization failed with exit code: $exit_code"
    echo "================================================"
    exit $exit_code
fi
