-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TELEMETRY.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic environmental-response knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.ESG_SOP_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, s.CATEGORY
  FROM RAW.SITE_DAILY r JOIN RAW.SITES s ON s.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.EXCEEDANCE_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' exceedance response' AS TITLE,
  'Synthetic demo SOP. Site type: ' || CATEGORY || '. Exceedance cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: notify the site environmental officer, log the event in the environmental register and take a confirmation sample. '
  || 'Step 2: ' || CASE
       WHEN (ROOT_CAUSE ILIKE '%sediment%' OR ROOT_CAUSE ILIKE '%runoff%') AND ROOT_CAUSE NOT ILIKE '%flood%' AND ROOT_CAUSE NOT ILIKE '%rainfall%' THEN 'divert runoff to the backup settling pond, dose flocculant at the pond inlet and inspect silt fences and drainage channels.'
       WHEN ROOT_CAUSE ILIKE '%dust%' THEN 'increase water-cart passes on haul roads, slow haul traffic near the community boundary and check dust monitors.'
       WHEN ROOT_CAUSE ILIKE '%stack%' THEN 'reduce furnace feed, inspect the bag filters and electrostatic precipitator, and record opacity every 15 minutes until stable.'
       WHEN ROOT_CAUSE ILIKE '%cooling%' THEN 'route cooling water through the holding pond until the temperature is back within the internal threshold.'
       WHEN ROOT_CAUSE ILIKE '%ph%' OR ROOT_CAUSE ILIKE '%process water%' THEN 'stop the discharge, adjust lime dosing in the neutralisation circuit and re-sample before restarting.'
       WHEN ROOT_CAUSE ILIKE '%seepage%' OR ROOT_CAUSE ILIKE '%freeboard%' THEN 'pump seepage back to the facility, lower the operating water level and ask the geotechnical engineer to inspect the embankment.'
       WHEN ROOT_CAUSE ILIKE '%spill%' THEN 'deploy booms and absorbents at the jetty, pause loading and recover spilled ore from the water line.'
       WHEN ROOT_CAUSE ILIKE '%flood%' OR ROOT_CAUSE ILIKE '%rainfall%' THEN 'open emergency spillways in a controlled sequence, close exposed work fronts and warn downstream villages through the community liaison team.'
       ELSE 'record the issue, contain the source and escalate to the regional ESG lead.'
     END
  || ' Step 3: if turbidity stays above 80 NTU or pond level above 90% after containment, keep the site on the watch list and inform the community liaison team. '
  || 'Step 4: confirm that samples are back within the internal threshold and record the root cause in the environmental register.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.ESG_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.ESG_SOP_DOCS);

-- ---------- Discharge turbidity anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.TURBIDITY_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, TURBIDITY_NTU::FLOAT AS TURBIDITY
FROM RAW.SITE_DAILY;
CREATE OR REPLACE VIEW ML.TURBIDITY_TRAIN AS
SELECT * FROM ML.TURBIDITY_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.TURBIDITY_SERIES);
CREATE OR REPLACE VIEW ML.TURBIDITY_DETECT AS
SELECT * FROM ML.TURBIDITY_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.TURBIDITY_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.TURBIDITY_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.TURBIDITY_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'TURBIDITY',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.TURBIDITY_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS TURBIDITY, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.TURBIDITY_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.TURBIDITY_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'TURBIDITY'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.ESG_ANALYTICS
  TABLES (
    sites AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'sites', 'operations', 'facilities')
      COMMENT = 'One row per mining or processing site (entity), 90-day totals',
    risk AS ML.EXCEEDANCE_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day environmental exceedance probability per site',
    causes AS CURATED.EXCEEDANCE_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Environmental exceedances by root cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Operator-wide totals per day'
  )
  RELATIONSHIPS (risk_site AS risk (ENTITY_ID) REFERENCES sites)
  FACTS (
    sites.samples_in_limit_f AS SAMPLES_IN_LIMIT,
    sites.water_samples_f AS WATER_SAMPLES,
    sites.ore_tonnes_f AS ORE_TONNES,
    sites.co2e_tonnes_f AS CO2E_TONNES,
    sites.grievances_f AS GRIEVANCES,
    sites.exceedances_f AS EXCEEDANCE_COUNT,
    sites.downtime_hours_f AS DOWNTIME_HOURS,
    sites.operating_hours_f AS OPERATING_HOURS,
    sites.planned_hours_f AS PLANNED_HOURS,
    risk.exceedance_prob_f AS EXCEEDANCE_PROB_7D,
    causes.cause_exceedances_f AS EXCEEDANCE_COUNT,
    causes.cause_over_limit_f AS SAMPLES_OVER_LIMIT,
    causes.cause_hours_f AS DOWNTIME_HOURS,
    daily.day_in_limit_f AS SAMPLES_IN_LIMIT,
    daily.day_samples_f AS WATER_SAMPLES,
    daily.day_co2e_f AS CO2E_TONNES,
    daily.day_exceedances_f AS EXCEEDANCE_COUNT
  )
  DIMENSIONS (
    sites.site_id AS ENTITY_ID WITH SYNONYMS = ('site', 'entity', 'entity id', 'site id'),
    sites.site_name AS ENTITY_NAME,
    sites.province AS REGION WITH SYNONYMS = ('province', 'region', 'island') COMMENT = 'Indonesian province',
    sites.site_type AS CATEGORY WITH SYNONYMS = ('site type', 'facility type', 'category'),
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    sites.site_count AS COUNT(sites.site_id) WITH SYNONYMS = ('number of entities', 'entity count', 'number of sites'),
    sites.discharge_in_threshold_pct AS 100 * SUM(sites.samples_in_limit_f) / NULLIF(SUM(sites.water_samples_f), 0)
      WITH SYNONYMS = ('discharge quality', 'samples within threshold') COMMENT = 'Water samples within the internal demo threshold / water samples',
    sites.total_exceedances AS SUM(sites.exceedances_f) WITH SYNONYMS = ('exceedances', 'environmental exceedances'),
    sites.emissions_intensity_kg_per_t AS 1000 * SUM(sites.co2e_tonnes_f) / NULLIF(SUM(sites.ore_tonnes_f), 0)
      WITH SYNONYMS = ('emissions intensity', 'carbon intensity') COMMENT = 'kg CO2e per tonne of material handled',
    sites.total_co2e_tonnes AS SUM(sites.co2e_tonnes_f) WITH SYNONYMS = ('emissions', 'total emissions'),
    sites.total_ore_tonnes AS SUM(sites.ore_tonnes_f) WITH SYNONYMS = ('throughput', 'tonnes handled'),
    sites.total_grievances AS SUM(sites.grievances_f) WITH SYNONYMS = ('grievances', 'community grievances'),
    sites.water_treatment_uptime_pct AS 100 * SUM(sites.operating_hours_f) / NULLIF(SUM(sites.planned_hours_f), 0),
    sites.total_downtime_hours AS SUM(sites.downtime_hours_f),
    risk.avg_exceedance_prob AS AVG(risk.exceedance_prob_f),
    causes.cause_exceedances AS SUM(causes.cause_exceedances_f),
    causes.cause_samples_over_limit AS SUM(causes.cause_over_limit_f),
    causes.cause_downtime_hours AS SUM(causes.cause_hours_f),
    daily.daily_in_threshold_pct AS 100 * SUM(daily.day_in_limit_f) / NULLIF(SUM(daily.day_samples_f), 0),
    daily.daily_co2e_tonnes AS SUM(daily.day_co2e_f),
    daily.daily_exceedances AS SUM(daily.day_exceedances_f)
  )
  COMMENT = 'Synthetic Indonesia nickel mining ESG analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.ESG_AGENT
  COMMENT = 'ESG assistant over a synthetic Indonesian nickel mining and processing operator'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic and that thresholds are internal demo thresholds, not regulatory limits. Give site IDs and numbers with units."
  orchestration: "Use esg_analyst for discharge samples within threshold, exceedances, emissions and emissions intensity, grievances, treatment uptime, sites, provinces, risk and root causes. Use sop_search for exceedance response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: esg_analyst
      description: "Discharge samples within the internal threshold, environmental exceedances, CO2e emissions and intensity, community grievances, water treatment uptime, root causes and exceedance-risk scores per site"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic exceedance-response SOPs by site type and cause"
tool_resources:
  esg_analyst:
    semantic_view: __DEMO_DB__.APP.ESG_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.ESG_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), SITE_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, TURBIDITY_NTU FLOAT, POND_LEVEL_PCT FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION ID_NICKEL_ESG_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (SITE_ID, EVENT_TS, TURBIDITY_NTU, POND_LEVEL_PCT, SOP_HINT)
    SELECT t.SITE_ID, t.EVENT_TS, t.TURBIDITY_NTU, t.POND_LEVEL_PCT,
           'Check ' || s.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.SITES s ON s.ID = t.SITE_ID
    LEFT JOIN ML.EXCEEDANCE_RISK_SCORES r ON r.ENTITY_ID = t.SITE_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.SITE_ID = t.SITE_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('ID_NICKEL_ESG_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Indonesia nickel ESG water-quality alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.SITE_ID = t.SITE_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.EXCEEDANCE_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.EXCEEDANCE_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.EXCEEDANCE_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.EXCEEDANCE_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'TURBIDITY_NTU', TURBIDITY_NTU,
             'POND_LEVEL_PCT', POND_LEVEL_PCT, 'TURBIDITY_7D', TURBIDITY_7D, 'EXCEEDANCES_30D', EXCEEDANCES_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:EXCEEDANCE::FLOAT, 4) AS EXCEEDANCE_PROB_7D,
         CASE WHEN PRED:probability:EXCEEDANCE::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:EXCEEDANCE::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
