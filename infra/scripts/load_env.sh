#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="ap-northeast-1"

RAILS_MASTER_KEY_PARAM="/parking-management/rails/master-key"
DB_PASSWORD_PARAM="/parking-management/rds/master-password"

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

echo "Loaded RAILS_MASTER_KEY and PARKING_MANAGEMENT_DATABASE_PASSWORD from SSM."
