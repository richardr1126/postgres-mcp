#!/bin/bash

# Script to create Kubernetes secrets for the Postgres MCP server
# This script creates secrets from environment variables defined in .env file

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  echo "Please create a .env file with the following variables:"
  echo "DATABASE_URI=postgresql://username:password@host:port/database"
  echo "OPENAI_API_KEY=your_openai_api_key  # Optional for experimental LLM-based index tuning"
  exit 1
fi

# Load environment variables from .env file
echo "Loading environment variables from $ENV_FILE"
set -a  # automatically export all variables
source "$ENV_FILE"
set +a  # stop automatically exporting

# Validate that required variables are set
required_vars=("DATABASE_URI")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set in .env file"
    exit 1
  fi
done

# Delete existing secret and create new one
echo "Deleting existing postgres-mcp-secrets..."
kubectl delete secret postgres-mcp-secrets --ignore-not-found

# Create postgres-mcp secrets
echo "Creating postgres-mcp-secrets..."
SECRET_ARGS="--from-literal=DATABASE_URI=${DATABASE_URI}"

# Add OpenAI API key if provided
if [ ! -z "${OPENAI_API_KEY}" ]; then
  SECRET_ARGS="${SECRET_ARGS} --from-literal=OPENAI_API_KEY=${OPENAI_API_KEY}"
  echo "Including OpenAI API key for experimental LLM-based index tuning"
fi

kubectl create secret generic postgres-mcp-secrets $SECRET_ARGS

echo "Secrets created successfully!"