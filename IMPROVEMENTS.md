# Improvements

Suggested next steps for this Snowflake + Cursor test project. Ordered by impact.

## Security

1. **Rotate any PAT that was pasted into `SnowflakeDB` or chat.** Create a new token in Snowsight, put it only in `.env` as `SNOWFLAKE_PAT`, then drop the old token.
2. **Stop using `ACCOUNTADMIN` for MCP and the SQL API.** Create a dedicated role (for example `MCP_ROLE`) with USAGE/SELECT on `SNOWFLAKE_LEARNING_DB.TEST2` and `SHARED_DB.PUBLIC.EMAIL_RECIPIENTS`, USAGE on `COMPUTE_WH` and `TEST_EMAIL_INTEGRATION`, and restrict the PAT with `ROLE_RESTRICTION`.
3. **Tighten `MCP_EXTERNAL_ACCESS_RULE`.** `0.0.0.0/0` allows every IPv4 address. Replace it with your office/home/VPN CIDRs.
4. **Apply the network policy to the MCP user only**, not `ALTER ACCOUNT SET NETWORK_POLICY`, unless you intend to lock the whole account.
5. **Keep secrets out of `mcp.json`.** Continue using `${SNOWFLAKE_PAT}`. Never commit `.env`.
6. **Grant SELECT/INSERT explicitly** instead of relying on `PUBLIC`. `DB_Setup.sql` currently grants only USAGE.

## Connectivity

1. **Point MCP at the managed server path** after `CREATE MCP SERVER`, not only the account host:
   `https://AZBWVHR-QE89977.snowflakecomputing.com/api/v2/databases/<DB>/schemas/<SCHEMA>/mcp-servers/<NAME>`
2. **Load `.env` in `SnowflakeDB`** (parse the file or use `python-dotenv`) so `python3 SnowflakeDB` works without `source .env`.
3. **Set a default warehouse** on user `DANZAG88` or the MCP role (`ALTER USER ... SET DEFAULT_WAREHOUSE = COMPUTE_WH`) so SQL does not fail when none is selected in Snowsight.
4. **Copy `mcp.json` to `.cursor/mcp.json`** if Cursor does not pick up the repo-root file.
5. **Add `.env.example`** (no secrets) so others know which variables to set.

## Snowflake objects

1. **Create `SHARED_DB.PUBLIC.EMAIL_RECIPIENTS`** from the agreed DDL and keep it in a versioned `.sql` file (it is not in the repo yet).
2. **Replace the email placeholder** in `email_integration.sql` with a verified Snowflake user address before enabling sends.
3. **Grant SELECT (and INSERT/UPDATE if needed)** on `EMAIL_RECIPIENTS` to the MCP role.
4. **Create the MCP server object** in `SNOWFLAKE_LEARNING_DB.TEST2` with `SYSTEM_EXECUTE_SQL` (and Cortex tools if required).
5. **Avoid `CREATE OR REPLACE TABLE` on populated tables.** Use `CREATE TABLE IF NOT EXISTS` or migrations.

## Application code

1. **Give `SnowflakeDB` a `.py` extension** (or a Makefile target) so editors and CI treat it as Python.
2. **Read account/warehouse/database/schema from `.env`** instead of hardcoding them in `SnowflakeDB`.
3. **Handle SQL API async/polling and pagination** (`partition` / next URL) for large result sets; the current script is a first pass.
4. **Write fetch output to `snowflake_dump.json` (gitignored)** by default, or take an `--out` path, so stdout is not the only option.
5. **Add a small Cortex example script** using `/api/v2/cortex/v1/chat/completions` with the same PAT.

## Docs and Cursor

1. **Keep `.cursorrules` and `CURSOR_RULES.md` in sync** when either changes.
2. **Optionally add `.cursor/rules/*.mdc`** with `alwaysApply: true` so Cursor reliably loads the rules.
3. **Document run order** in README: `authentication.sql` → `DB_Setup.sql` → `email_integration.sql` → table DDL → MCP server → set `SNOWFLAKE_PAT`.
4. **Link `IMPROVEMENTS.md` from README** so the backlog is visible.

## Reliability and accuracy

1. **Verify PAT with a session query** (`CURRENT_USER()`, warehouse, database, schema) before fetch/email.
2. **Treat empty `SHOW TABLES` as empty, not as failure.** Distinguish HTTP errors (`390432`, etc.) from zero rows.
3. **Honor `EMAIL_RECIPIENTS` filters** (`IS_ACTIVE`, `ENVIRONMENT`, `STATUS_SCOPE`, `SEND_DAYS`) before `SYSTEM$SEND_EMAIL`.
4. **Store and compare timestamps as `TIMESTAMP_NTZ(9)`**; set `UPDATED_AT` on every update.
5. **Do not assume PRIMARY KEY uniqueness is enforced** on standard Snowflake tables.

## Suggested first slice

1. Rotate PAT; put it in `.env` only.
2. Finish network policy + authentication policy in Snowsight (`authentication.sql`).
3. Teach `SnowflakeDB` to load `.env` and succeed at the session query.
4. Check MCP URL and warehouse, then fetch `TEST2` / `EMAIL_RECIPIENTS`.
