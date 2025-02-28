#!/bin/bash

# Default values
DEFAULT_CONTAINER_NAME="postgres"
DEFAULT_PORT="5432"

# Parse command-line options
while getopts "n:p:" opt; do
  case $opt in
    n)
      CONTAINER_NAME="$OPTARG"
      ;;
    p)
      HOST_PORT="$OPTARG"
      ;;
    \?)
      echo "Usage: $0 [-n container_name] [-p port]"
      exit 1
      ;;
  esac
done

# Set defaults if not set by user
CONTAINER_NAME="${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}"
HOST_PORT="${HOST_PORT:-$DEFAULT_PORT}"

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
  local retries=30
  local wait_interval=1

  echo "Waiting for PostgreSQL to be ready on port ${HOST_PORT}..."

  for ((i=0; i<retries; i++)); do
    if PGPASSWORD=pwd psql -h localhost -p ${HOST_PORT} -U postgres -c "SELECT 1" > /dev/null 2>&1; then
      echo "PostgreSQL is ready."
      return 0
    fi
    sleep $wait_interval
  done

  echo "PostgreSQL did not become ready in time."
  exit 1
}

# Store the name of the existing container
existing_container=$(docker ps -a --format "{{.Names}}" | grep "^${CONTAINER_NAME}$")

# Check if the container name is empty
if [ -z "$existing_container" ]; then
  # Container does not exist, so run the new container
  echo "Container '${CONTAINER_NAME}' does not exist. Creating a new one..."
  docker run -d --name "${CONTAINER_NAME}" -e POSTGRES_PASSWORD=pwd -p "${HOST_PORT}:5432" pgvector/pgvector:pg16

  # Wait for PostgreSQL to be ready
  wait_for_postgres
else
  # Container exists
  echo "Container named '${CONTAINER_NAME}' already exists."

  container_started=$(docker ps --format "{{.Names}}" | grep "^${CONTAINER_NAME}$")
  if [ -z "$container_started" ]; then
    docker start "${CONTAINER_NAME}"

    # Wait for PostgreSQL to be ready
    wait_for_postgres
  fi
fi

# Define SQL commands
POSTGRES_COMMANDS=$(cat <<EOF
CREATE Role powercard WITH PASSWORD 'pwd';
CREATE DATABASE powercard_db ENCODING 'UTF8' OWNER powercard;
GRANT ALL PRIVILEGES ON DATABASE powercard_db TO powercard;
ALTER ROLE powercard WITH LOGIN;
ALTER ROLE powercard WITH CREATEROLE;
EOF
)

POWERCARD_COMMANDS=$(cat <<EOF
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE Role app WITH PASSWORD 'pwd';
ALTER ROLE app WITH LOGIN;
CREATE Role bat WITH PASSWORD 'pwd';
ALTER ROLE bat WITH LOGIN;
CREATE Role content WITH PASSWORD 'pwd';
ALTER ROLE content WITH LOGIN;
CREATE Role event WITH PASSWORD 'pwd';
ALTER ROLE event WITH LOGIN;
CREATE Role idm WITH PASSWORD 'pwd';
ALTER ROLE idm WITH LOGIN;
CREATE Role integration WITH PASSWORD 'pwd';
ALTER ROLE integration WITH LOGIN;
CREATE Role pii WITH PASSWORD 'pwd';
ALTER ROLE pii WITH LOGIN;
CREATE Role settlement WITH PASSWORD 'pwd';
ALTER ROLE settlement WITH LOGIN;
CREATE Role underwriting WITH PASSWORD 'pwd';
ALTER ROLE underwriting WITH LOGIN;
CREATE Role issuer WITH PASSWORD 'pwd';
ALTER ROLE issuer WITH LOGIN;
CREATE Role fsm WITH PASSWORD 'pwd';
ALTER ROLE fsm WITH LOGIN;

GRANT app TO powercard;
GRANT bat TO powercard;
GRANT content TO powercard;
GRANT event TO powercard;
GRANT idm TO powercard;
GRANT integration TO powercard;
GRANT pii TO powercard;
GRANT settlement TO powercard;
GRANT underwriting TO powercard;
GRANT issuer TO powercard;
GRANT fsm TO powercard;

CREATE SCHEMA IF NOT EXISTS app AUTHORIZATION app;
CREATE SCHEMA IF NOT EXISTS bat AUTHORIZATION bat;
CREATE SCHEMA IF NOT EXISTS content AUTHORIZATION content;
CREATE SCHEMA IF NOT EXISTS event AUTHORIZATION event;
CREATE SCHEMA IF NOT EXISTS idm AUTHORIZATION idm;
CREATE SCHEMA IF NOT EXISTS integration AUTHORIZATION integration;
CREATE SCHEMA IF NOT EXISTS pii AUTHORIZATION pii;
CREATE SCHEMA IF NOT EXISTS settlement AUTHORIZATION settlement;
CREATE SCHEMA IF NOT EXISTS underwriting AUTHORIZATION underwriting;
CREATE SCHEMA IF NOT EXISTS issuer AUTHORIZATION issuer;
CREATE SCHEMA IF NOT EXISTS fsm AUTHORIZATION fsm;
EOF
)

# Function to execute SQL commands with different users and databases
execute_sql() {
  local sql_commands=$1
  local user=$2
  local db=$3

  echo "$sql_commands" | while IFS= read -r line; do
    # Skip empty lines and comments
    if [[ -n "$line" && ! "$line" =~ ^\s*-- ]]; then
      echo "Executing: $line"
      output=$(psql postgresql://$user:pwd@localhost:${HOST_PORT}/$db -c "$line" 2>&1)
      status=$?
      echo "$output"
      if [ $status -ne 0 ] && ! echo "$output" | grep -q "already exists"; then
        echo "Error executing command: $line"
        exit 1
      fi
    fi
  done
}

# Execute SQL commands for creating role and database
echo "Executing SQL commands to create roles and the database..."

execute_sql "$POSTGRES_COMMANDS" "postgres" "postgres"

echo "Created powercard role with powercard_db database."

execute_sql "CREATE EXTENSION IF NOT EXISTS \"vector\";" "postgres" "powercard_db"
execute_sql "$POWERCARD_COMMANDS" "powercard" "powercard_db"

echo "Created powercard schemas."

# Start database migration
echo "Starting database migration for all schemas with port ${HOST_PORT}..."

cd "$(dirname "$(realpath "$0")")/.." || { echo "Failed to navigate to root directory"; exit 1; }

make migration-powercard-up-all port="${HOST_PORT}"

echo "Database migration for all schemas completed successfully."

echo "Done."
