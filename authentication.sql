-- Authentication and network access for Cursor MCP / SQL API.
-- Run in a Snowsight worksheet as ACCOUNTADMIN.
-- Copy the PAT token_secret from the last statement once; do not commit it.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA TEST2;

-- Allow external MCP clients from any IPv4 address.
CREATE OR REPLACE NETWORK RULE MCP_EXTERNAL_ACCESS_RULE
  TYPE = IPV4
  VALUE_LIST = ('0.0.0.0/0')
  MODE = INGRESS
  COMMENT = 'MCP External Access Rule';

-- Network policy that allows the MCP External Access Rule.
CREATE OR REPLACE NETWORK POLICY MCP_NETWORK_POLICY
  ALLOWED_NETWORK_RULE_LIST = ('MCP_EXTERNAL_ACCESS_RULE')
  COMMENT = 'Allow external MCP access via MCP External Access Rule';

-- Apply the network policy to the MCP user (required before PAT authentication).
ALTER USER DANZAG88 SET NETWORK_POLICY = MCP_NETWORK_POLICY;

-- Optional: apply at account level instead of (or in addition to) the user.
-- ALTER ACCOUNT SET NETWORK_POLICY = MCP_NETWORK_POLICY;

-- Allow programmatic access tokens (required before a PAT can be created or used).
CREATE OR REPLACE AUTHENTICATION POLICY MCP_AUTH_POLICY
  AUTHENTICATION_METHODS = ('PASSWORD', 'PROGRAMMATIC_ACCESS_TOKEN')
  CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSQL', 'DRIVERS')
  PAT_POLICY = (
    DEFAULT_EXPIRY_IN_DAYS = 90
    NETWORK_POLICY_EVALUATION = ENFORCED
  )
  COMMENT = 'Allow password login and programmatic access tokens for MCP';

ALTER USER DANZAG88 SET AUTHENTICATION POLICY MCP_AUTH_POLICY;

-- Optional: apply at account level.
-- ALTER ACCOUNT SET AUTHENTICATION POLICY MCP_AUTH_POLICY;

-- Generate a new PAT for the MCP server (ACCOUNTADMIN restriction).
-- token_secret is returned only here; store it as SNOWFLAKE_PAT.
ALTER USER DANZAG88 ADD PROGRAMMATIC ACCESS TOKEN mcp_server_pat
  ROLE_RESTRICTION = 'ACCOUNTADMIN'
  DAYS_TO_EXPIRY = 90
  COMMENT = 'MCP Server PAT for Cursor';

-- SHOW USER PROGRAMMATIC ACCESS TOKENS FOR USER DANZAG88;
