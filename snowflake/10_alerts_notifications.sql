-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Mining ESG & Sustainability
-- ============================================================================
USE DATABASE MINING_ESG;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_indonesia_mining_nickel_esg_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: EMISSIONS_TARGET_ALERT
CREATE OR REPLACE ALERT APP.EMISSIONS_TARGET_ALERT
  WAREHOUSE = ESG_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Emissions trajectory exceeds 2025 reduction target'
IF (EXISTS (
  SELECT 1 FROM CURATED.EMISSIONS_DASHBOARD
  WHERE 1=1 -- Condition: Projected annual emissions exceed 2025 reduction target
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_mining_nickel_esg_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Mining ESG & Sustainability: Emissions trajectory exceeds 2025 reduction target',
    'Emissions trajectory exceeds 2025 reduction target'
  );

ALTER ALERT APP.EMISSIONS_TARGET_ALERT RESUME;

-- Alert: DISCHARGE_EXCEEDANCE_ALERT
CREATE OR REPLACE ALERT APP.DISCHARGE_EXCEEDANCE_ALERT
  WAREHOUSE = ESG_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Effluent quality exceedance detected at monitoring point'
IF (EXISTS (
  SELECT 1 FROM CURATED.EMISSIONS_DASHBOARD
  WHERE 1=1 -- Condition: Water discharge quality exceeds regulatory limit
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_mining_nickel_esg_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Mining ESG & Sustainability: Effluent quality exceedance detected at monitoring point',
    'Effluent quality exceedance detected at monitoring point'
  );

ALTER ALERT APP.DISCHARGE_EXCEEDANCE_ALERT RESUME;

