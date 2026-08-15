-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Mining ESG & Sustainability
-- ============================================================================
USE DATABASE MINING_ESG;
USE SCHEMA CURATED;

-- EMISSIONS_DASHBOARD: Scope 1-3 emissions aggregation by site, source, and period with intensity metrics
-- Source: EMISSIONS_DATA
CREATE OR REPLACE DYNAMIC TABLE CURATED.EMISSIONS_DASHBOARD
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ESG_WH
AS
SELECT * FROM RAW.EMISSIONS_DATA;
-- TODO: Replace with actual join/aggregation logic per demo

-- WATER_BALANCE: Site-level water intake, recycling, and discharge with compliance status
-- Source: WATER_MONITORING
CREATE OR REPLACE DYNAMIC TABLE CURATED.WATER_BALANCE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ESG_WH
AS
SELECT * FROM RAW.WATER_MONITORING;
-- TODO: Replace with actual join/aggregation logic per demo

-- SAFETY_METRICS: LTIFR, TRIFR, and near-miss rates by site and period
-- Source: SAFETY_INCIDENTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.SAFETY_METRICS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ESG_WH
AS
SELECT * FROM RAW.SAFETY_INCIDENTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- TAILINGS_RISK: Tailings facility capacity, stability index, and risk scoring
-- Source: TAILINGS_MONITORING
CREATE OR REPLACE DYNAMIC TABLE CURATED.TAILINGS_RISK
  TARGET_LAG = '5 minutes'
  WAREHOUSE = ESG_WH
AS
SELECT * FROM RAW.TAILINGS_MONITORING;
-- TODO: Replace with actual join/aggregation logic per demo

