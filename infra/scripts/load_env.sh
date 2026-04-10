#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="ap-northeast-1"

RAILS_MASTER_KEY_PARAM="/parking-management/rails/master-key"
DB_PASSWORD_PARAM="/parking-management/rds/master-password"
DB_HOST_PARAM="/parking-management/rds/host"

get_ssm_parameter() {
  local name="$1"
  aws ssm get-parameter \
    --name "$name" \
    --with-decryption \
    --region "$AWS_REGION" \
    --query 'Parameter.Value' \
    --output text
}

export RAILS_MASTER_KEY="$(get_ssm_parameter "$RAILS_MASTER_KEY_PARAM")"
export PARKING_MANAGEMENT_DATABASE_PASSWORD="$(get_ssm_parameter "$DB_PASSWORD_PARAM")"
export DATABASE_HOST="$(get_ssm_parameter "$DB_HOST_PARAM")"

echo "Loaded RAILS_MASTER_KEY, PARKING_MANAGEMENT_DATABASE_PASSWORD, and DATABASE_HOST."
