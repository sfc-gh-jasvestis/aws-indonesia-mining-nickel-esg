-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Mining ESG & Sustainability
-- ============================================================================
USE DATABASE MINING_ESG;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.ESG_REPORTS_SEARCH
  ON CONTENT
  ATTRIBUTES REPORT_TYPE, YEAR, GRI_STANDARD
  WAREHOUSE = ESG_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.ESG_REPORTS
);
