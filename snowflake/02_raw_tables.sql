-- Synthetic site-day ESG observations for a fictional nickel mining and
-- processing operator in Sulawesi and North Maluku. Nothing is seeded as a
-- prediction. Randomness is HASH-seeded, so every rebuild is reproducible:
-- per-site throughput, asset age and exceedance propensity, weekly throughput
-- seasonality and a ramp-up peak, wear between environmental-control
-- inspections, category-weighted exceedance causes, and two rainfall events.
-- Thresholds are internal demo thresholds, not regulatory limits.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.SITES AS
WITH sites AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS SITE_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 30))
), draws AS (
  SELECT SITE_INDEX,
         MOD(ABS(HASH(SITE_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(SITE_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(SITE_INDEX, 'insp')), 1000000) / 1e6 AS U_INSP,
         MOD(ABS(HASH(SITE_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(SITE_INDEX, 'capacity')), 1000000) / 1e6 AS U_CAPACITY
  FROM sites
)
SELECT 'ST-' || LPAD(SITE_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic site ' || LPAD(SITE_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (7 and 5 are coprime): every region and site
       -- type is present, with Central Sulawesi and Southeast Sulawesi largest.
       CASE MOD(SITE_INDEX, 7) WHEN 0 THEN 'Central Sulawesi' WHEN 1 THEN 'Central Sulawesi'
            WHEN 2 THEN 'Southeast Sulawesi' WHEN 3 THEN 'Southeast Sulawesi'
            WHEN 4 THEN 'South Sulawesi' ELSE 'North Maluku' END AS REGION,
       CASE MOD(SITE_INDEX, 5) WHEN 0 THEN 'Open-Pit Mine' WHEN 1 THEN 'RKEF Smelter'
            WHEN 2 THEN 'HPAL Plant' WHEN 3 THEN 'Tailings Facility'
            ELSE 'Jetty and Stockpile' END AS CATEGORY,
       SITE_INDEX,
       ROUND(1 + U_AGE * 9, 1) AS AGE_YEARS,
       -- Base daily exceedance probability 0.5%-3.5%; ~15% of sites are chronic (x3).
       (0.005 + U_RATE * 0.03) * IFF(U_RATE > 0.85, 3, 1) AS BASE_EXCEEDANCE_RATE,
       7 * (1 + FLOOR(U_INSP * 3)) AS INSPECTION_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS INSPECTION_COMPLETION_PROB,
       -- Material handled per day (tonnes): ore mined, ore fed, tailings placed or ore shipped.
       ROUND(CASE MOD(SITE_INDEX, 5) WHEN 0 THEN 16000 WHEN 1 THEN 6000 WHEN 2 THEN 4000
                  WHEN 3 THEN 3000 ELSE 9000 END * (0.8 + U_CAPACITY * 0.4)) AS DAILY_CAPACITY,
       -- Emissions factor (t CO2e per tonne handled), synthetic and by site type.
       CASE MOD(SITE_INDEX, 5) WHEN 0 THEN 0.012 WHEN 1 THEN 0.90 WHEN 2 THEN 0.35
            WHEN 3 THEN 0.004 ELSE 0.006 END * (0.9 + U_AGE * 0.2) AS EMISSION_FACTOR,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.SITE_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), regional_events AS (
  -- Two region-wide rainfall events in the window.
  SELECT * FROM VALUES (27, 'Central Sulawesi', 'Extreme rainfall runoff', 6.0),
                       (64, 'North Maluku', 'Flash flood runoff', 9.0)
    AS o(DAY_INDEX, REGION, EVENT_CAUSE, HOURS)
), base AS (
  SELECT s.ID AS ENTITY_ID, s.SITE_INDEX, s.CATEGORY, s.REGION, s.AGE_YEARS,
         s.BASE_EXCEEDANCE_RATE, s.INSPECTION_INTERVAL_DAYS, s.INSPECTION_COMPLETION_PROB,
         s.DAILY_CAPACITY, s.EMISSION_FACTOR, d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         24.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + s.SITE_INDEX * 5, s.INSPECTION_INTERVAL_DAYS) AS DAYS_SINCE_INSPECTION,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'exc')), 1000000) / 1e6 AS U_EXC,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'inspdone')), 1000000) / 1e6 AS U_INSPDONE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'hit')), 1000000) / 1e6 AS U_HIT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'grv')), 1000000) / 1e6 AS U_GRV,
         e.EVENT_CAUSE, e.HOURS AS EVENT_HOURS
  FROM RAW.SITES s CROSS JOIN days d
  LEFT JOIN regional_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = s.REGION
), loaded AS (
  SELECT *,
         IFF(DAYS_SINCE_INSPECTION = 0, 1, 0) AS INSPECTION_DUE,
         IFF(DAYS_SINCE_INSPECTION = 0 AND U_INSPDONE < INSPECTION_COMPLETION_PROB, 1, 0) AS INSPECTION_DONE,
         -- Control wear rises between inspections; weak inspection discipline carries wear over.
         DAYS_SINCE_INSPECTION / INSPECTION_INTERVAL_DAYS + (1 - INSPECTION_COMPLETION_PROB) AS WEAR,
         -- Wet-season stress episode: 9 of every 28 days per site (staggered).
         IFF(MOD(DAY_INDEX + SITE_INDEX * 11, 28) < 9, 1, 0) AS STRESS,
         -- Throughput: weekly low day and a ramp-up peak on day 45 (+60%) easing over 3 days.
         ROUND(DAILY_CAPACITY * (0.70 + 0.25 * U_VOLUME)
               * IFF(MOD(DAY_INDEX, 7) = 6, 0.75, 1.0)
               * CASE DAY_INDEX - 45 WHEN 0 THEN 1.6 WHEN 1 THEN 1.4 WHEN 2 THEN 1.2 ELSE 1.0 END) AS ORE_TONNES
  FROM base
), exceedances AS (
  SELECT *, ORE_TONNES / DAILY_CAPACITY AS LOAD_RATIO,
         LEAST(0.5, BASE_EXCEEDANCE_RATE * (0.4 + 1.6 * WEAR) * (0.3 + ORE_TONNES / DAILY_CAPACITY)
                    * (1 + AGE_YEARS / 20) * (1 + 2.5 * STRESS)) AS P_EXC
  FROM loaded
), counted AS (
  SELECT *,
         CASE WHEN EVENT_HOURS IS NOT NULL THEN 1
              WHEN U_EXC < P_EXC / 4 THEN 2
              WHEN U_EXC < P_EXC THEN 1
              ELSE 0 END AS EXCEEDANCE_COUNT
  FROM exceedances
)
, timed AS (
  SELECT *,
         -- Water treatment plant offline hours: exponential, mean depends on site type.
         CASE WHEN EXCEEDANCE_COUNT = 0 THEN 0.0
              WHEN EVENT_HOURS IS NOT NULL THEN EVENT_HOURS
              ELSE LEAST(20.0, ROUND(EXCEEDANCE_COUNT * (0.5 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Open-Pit Mine' THEN 3.0 WHEN 'RKEF Smelter' THEN 2.0
                                 WHEN 'HPAL Plant' THEN 4.0 WHEN 'Tailings Facility' THEN 2.5 ELSE 3.5 END), 1))
         END AS DOWNTIME_HOURS,
         -- Share of water samples within the internal demo threshold.
         LEAST(0.995, GREATEST(0.50,
           CASE CATEGORY WHEN 'Open-Pit Mine' THEN 0.955 WHEN 'RKEF Smelter' THEN 0.960
                         WHEN 'HPAL Plant' THEN 0.940 WHEN 'Tailings Facility' THEN 0.935 ELSE 0.950 END
           - 0.025 * WEAR - 0.04 * GREATEST(0, LOAD_RATIO - 0.9) - 0.006 * U_NOISE
           - EXCEEDANCE_COUNT * (0.08 + 0.12 * U_HIT))) AS IN_LIMIT_RATE,
         12 + FLOOR(U_VOLUME * 13) AS WATER_SAMPLES
  FROM counted
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS,
       PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
       EXCEEDANCE_COUNT,
       CASE WHEN EXCEEDANCE_COUNT = 0 THEN 'None'
            WHEN EVENT_CAUSE IS NOT NULL THEN EVENT_CAUSE
            WHEN CATEGORY = 'Open-Pit Mine' THEN IFF(U_CAUSE < 0.5, 'Sediment pond overflow', IFF(U_CAUSE < 0.8, 'Haul road runoff', 'Dust suppression gap'))
            WHEN CATEGORY = 'RKEF Smelter' THEN IFF(U_CAUSE < 0.55, 'Stack opacity excursion', 'Cooling water temperature')
            WHEN CATEGORY = 'HPAL Plant' THEN IFF(U_CAUSE < 0.6, 'Neutralisation pH excursion', 'Process water bleed')
            WHEN CATEGORY = 'Tailings Facility' THEN IFF(U_CAUSE < 0.6, 'Seepage turbidity', 'Freeboard below target')
            ELSE IFF(U_CAUSE < 0.6, 'Stockpile runoff', 'Barge loading spill') END AS ROOT_CAUSE,
       INSPECTION_DUE, INSPECTION_DONE,
       WATER_SAMPLES,
       FLOOR(WATER_SAMPLES * IN_LIMIT_RATE) AS SAMPLES_IN_LIMIT,
       ORE_TONNES,
       ROUND(ORE_TONNES * EMISSION_FACTOR * (1 + 0.05 * U_NOISE + 0.03 * WEAR), 1) AS CO2E_TONNES,
       IFF(U_GRV < 0.02 + 0.04 * EXCEEDANCE_COUNT + 0.01 * STRESS, 1, 0) AS GRIEVANCES,
       ROUND(12 + 18 * WEAR + 25 * GREATEST(0, LOAD_RATIO - 0.8) + 10 * STRESS + 30 * EXCEEDANCE_COUNT + U_NOISE * 5, 1) AS TURBIDITY_NTU,
       ROUND(LEAST(100, 100 * LOAD_RATIO * (0.75 + 0.1 * U_NOISE) + 7 * STRESS + 4 * EXCEEDANCE_COUNT), 1) AS POND_LEVEL_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM timed;

-- Land rehabilitation progress per site (snapshot): disturbed versus rehabilitated hectares.
CREATE TABLE RAW.REHAB_PROGRESS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Open-Pit Mine' THEN 'Mined-out pit' WHEN 'RKEF Smelter' THEN 'Laydown area'
                     WHEN 'HPAL Plant' THEN 'Construction footprint' WHEN 'Tailings Facility' THEN 'Tailings embankment'
                     ELSE 'Stockpile pad' END AS LAND_USE,
       20 + MOD(ABS(HASH(ID, 'req')), 61) AS DISTURBED_HA,
       FLOOR((20 + MOD(ABS(HASH(ID, 'req')), 61)) * (0.30 + MOD(ABS(HASH(ID, 'avail')), 1000) / 1000 * 0.45)) AS REHABILITATED_HA,
       MOD(ABS(HASH(ID, 'order')), 8) AS PLANNED_HA,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.SITES;
