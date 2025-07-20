#!/bin/bash

# Get database connection info from config
DB_NAME=$(grep -A 10 "config :clinicpro, Clinicpro.Repo" config/dev.exs | grep "database:" | sed -E 's/.*database: "([^"]+)".*/\1/')
DB_USER=$(grep -A 10 "config :clinicpro, Clinicpro.Repo" config/dev.exs | grep "username:" | sed -E 's/.*username: "([^"]+)".*/\1/')
DB_PASSWORD=$(grep -A 10 "config :clinicpro, Clinicpro.Repo" config/dev.exs | grep "password:" | sed -E 's/.*password: "([^"]+)".*/\1/')
DB_HOST=$(grep -A 10 "config :clinicpro, Clinicpro.Repo" config/dev.exs | grep "hostname:" | sed -E 's/.*hostname: "([^"]+)".*/\1/')

echo "Setting up admin bypass tables for database: $DB_NAME"

# Run the SQL script
export PGPASSWORD="$DB_PASSWORD"
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f priv/repo/admin_bypass_setup.sql

# Check if the tables were created successfully
if [ $? -eq 0 ]; then
  echo "Admin bypass tables created successfully!"
else
  echo "Error creating admin bypass tables."
  exit 1
fi

echo "Done!"
