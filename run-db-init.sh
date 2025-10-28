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

# Run the initialization script
psql "$DATABASE_URL" -f /app/init-db.sql

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
