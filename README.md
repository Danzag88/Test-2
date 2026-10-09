# Test

Plan: stand up Snowflake objects in `SNOWFLAKE_LEARNING_DB.TEST2`, then connect **Cursor** to that schema over the Snowflake SQL API and Cortex REST API using a programmatic access token (PAT). This is a normal API connection, not MCP.

## Goals

1. Use database `SNOWFLAKE_LEARNING_DB` and schema `TEST2`.
2. Authenticate with a PAT (not a password in git).
3. Run SQL against the schema from Cursor via `POST /api/v2/statements`.
4. Call Cortex from Cursor via the Cortex REST API (same PAT).
5. Keep warehouse compute explicit so SQL statements can run.

## Account

- Account URL: `AZBWVHR-QE89977.snowflakecomputing.com`
- Account identifier: `AZBWVHR-QE89977`
- User: `DANZAG88`
- Role: `ACCOUNTADMIN`
- Warehouse: `COMPUTE_WH` (required for SQL that needs compute; Snowsight currently has none selected)
- Database: `SNOWFLAKE_LEARNING_DB`
- Schema: `TEST2`

Do not commit passwords or PAT secrets. Store the token as `SNOWFLAKE_PAT`.

The role needs Cortex access (`SNOWFLAKE.CORTEX_USER` or `SNOWFLAKE.CORTEX_REST_API_USER`). `ACCOUNTADMIN` usually already has this.

## Cursor connection to the schema

Cursor will talk to Snowflake over HTTPS using the PAT as a Bearer token. Session context for SQL:

- warehouse: `COMPUTE_WH`
- database: `SNOWFLAKE_LEARNING_DB`
- schema: `TEST2`
- role: `ACCOUNTADMIN`

Fully qualified objects: `SNOWFLAKE_LEARNING_DB.TEST2.<object>`.

## Create a PAT

Run in a Snowsight worksheet:

```sql
ALTER USER DANZAG88 ADD PROGRAMMATIC ACCESS TOKEN test_api_pat
  ROLE_RESTRICTION = 'ACCOUNTADMIN'
  DAYS_TO_EXPIRY = 90
  COMMENT = 'Cursor SQL and Cortex API for TEST2';
```

Copy `token_secret` once. It is not shown again.

## SQL API (schema access)

`https://AZBWVHR-QE89977.snowflakecomputing.com/api/v2/statements`

```bash
curl -sS -X POST \
  "https://AZBWVHR-QE89977.snowflakecomputing.com/api/v2/statements" \
  --header "Authorization: Bearer $SNOWFLAKE_PAT" \
  --header "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
    "statement": "SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA()",
    "warehouse": "COMPUTE_WH",
    "database": "SNOWFLAKE_LEARNING_DB",
    "schema": "TEST2",
    "role": "ACCOUNTADMIN"
  }'
```

A successful response includes a `statementHandle` and `data`. Cursor can use this same call to list and query objects in `TEST2`.

## Cortex REST API

Same host and Bearer PAT. Cursor uses this for LLM calls inside the Snowflake perimeter.

Chat Completions:

`https://AZBWVHR-QE89977.snowflakecomputing.com/api/v2/cortex/v1/chat/completions`

```bash
curl -sS -X POST \
  "https://AZBWVHR-QE89977.snowflakecomputing.com/api/v2/cortex/v1/chat/completions" \
  --header "Authorization: Bearer $SNOWFLAKE_PAT" \
  --header "X-Snowflake-Authorization-Token-Type: PROGRAMMATIC_ACCESS_TOKEN" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{
    "model": "llama3.1-8b",
    "messages": [
      {"role": "user", "content": "Summarize what SNOWFLAKE_LEARNING_DB.TEST2 is used for in one sentence."}
    ]
  }'
```

List models:

`GET https://AZBWVHR-QE89977.snowflakecomputing.com/api/v2/cortex/models`

You can also call Cortex from SQL (for example `SNOWFLAKE.CORTEX.COMPLETE(...)`) through the SQL API against the same schema session.
