execute_sql() {
  local sql_commands=$1
  local user=$2
  local db=$3

  echo "$sql_commands" | while IFS= read -r line; do
    # Skip empty lines and comments
    if [[ -n "$line" && ! "$line" =~ ^\s*-- ]]; then
      echo "Executing: $line"
      output=$(psql postgresql://$user:pwd@localhost:5434/$db -c "$line" 2>&1)
      status=$?
      echo "$output"
      if [ $status -ne 0 ] && ! echo "$output" | grep -q "already exists"; then
        echo "Error executing command: $line"
        exit 1
      fi
    fi
  done
}

APPLICATION_UUID="00000000-0000-0000-0000-000000000000"
TENANT_UUID="00000000-0000-0000-0000-000000000009"
DEPT_UUID="00000000-0000-0000-0000-000000000008"
USER_UUID="00000000-0000-0000-0000-000000000007"
EXPENSE_UUID_1="00000000-0000-0000-0000-000000000001"
EXPENSE_UUID_2="00000000-0000-0000-0000-000000000002"
ITEM_UUID_1="10000000-0000-0000-0000-000000000000"
ITEM_UUID_2="20000000-0000-0000-0000-000000000000"
ITEM_UUID_3="30000000-0000-0000-0000-000000000000"
ITEM_UUID_4="40000000-0000-0000-0000-000000000000"
ITEM_UUID_5="50000000-0000-0000-0000-000000000000"
EXPENSE_TYPE="transaction"

APP_COMMANDS=$(cat <<EOF
DELETE FROM app.expense_item_rel;
DELETE FROM app.expense_item;
DELETE FROM app.expense;
DELETE FROM app.users;
DELETE FROM app.dept;
DELETE FROM app.tenant;

INSERT INTO app.tenant (uuid, name, key, credit_type, application_uuid) VALUES ('$TENANT_UUID', 'Test Tenant', 'Test Key', 'charge', '$APPLICATION_UUID');

INSERT INTO app.dept (uuid, name, spend_limit, tenant_uuid) VALUES ('$DEPT_UUID', 'Test Dept', 1000000, '$TENANT_UUID');

INSERT INTO app.users (uuid, fullname, spend_limit, is_dynamic, employment_type, role, tenant_uuid) VALUES ('$USER_UUID', 'Test User', 1000000, true, 'fulltime', 'admin', '$TENANT_UUID');

INSERT INTO app.expense (uuid, tenant_uuid, department_uuid, user_uuid, memo, approval_status, type, name) VALUES ('$EXPENSE_UUID_1', '$TENANT_UUID', '$DEPT_UUID', '$USER_UUID', 'Testing 1', 'created', '$EXPENSE_TYPE', 'Test 1'), ('$EXPENSE_UUID_2', '$TENANT_UUID', '$DEPT_UUID', '$USER_UUID', 'Testing 2', 'created', '$EXPENSE_TYPE', 'Test 2');

INSERT INTO app.expense_item (uuid, merchant_name, amount, transaction_date, settlement_date) VALUES ('$ITEM_UUID_1', 'Costco', 100.00, '2024-10-23', '2024-10-23'), ('$ITEM_UUID_2', 'Walmart', 78.21, '2024-10-22', '2024-10-22'), ('$ITEM_UUID_3', 'Target', 48.23, '2024-10-21', '2024-10-21'), ('$ITEM_UUID_4', 'Target', 12.12, '2024-10-20', '2024-10-20'), ('$ITEM_UUID_5', 'Costco', 123.45, '2024-10-19', '2024-10-19');

INSERT INTO app.expense_item_rel (tenant_uuid, expense_uuid, expense_item_uuid) VALUES ('$TENANT_UUID', '$EXPENSE_UUID_1', '$ITEM_UUID_1'), ('$TENANT_UUID', '$EXPENSE_UUID_1', '$ITEM_UUID_2'), ('$TENANT_UUID', '$EXPENSE_UUID_1', '$ITEM_UUID_3'), ('$TENANT_UUID', '$EXPENSE_UUID_2', '$ITEM_UUID_4'), ('$TENANT_UUID', '$EXPENSE_UUID_2', '$ITEM_UUID_5');
EOF
)

execute_sql "$APP_COMMANDS" "app" "powercard_db"