-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Mining ESG & Sustainability
-- ============================================================================
USE DATABASE MINING_ESG;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_INGEST_MONITORING
  WAREHOUSE = ESG_WH
  SCHEDULE = 'USING CRON 0 */2 * * * UTC'
  COMMENT = 'Ingest latest emissions and water monitoring data'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_DETECT_ANOMALIES
  WAREHOUSE = ESG_WH
  AFTER APP.TASK_INGEST_MONITORING
  COMMENT = 'Run anomaly detection on discharge monitoring points'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_FORECAST_EMISSIONS
  WAREHOUSE = ESG_WH
  AFTER APP.TASK_DETECT_ANOMALIES
  COMMENT = 'Run emissions trajectory forecast vs target'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_FORECAST_EMISSIONS RESUME;
ALTER TASK APP.TASK_DETECT_ANOMALIES RESUME;
ALTER TASK APP.TASK_INGEST_MONITORING RESUME;
