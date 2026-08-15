-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Mining ESG & Sustainability
-- ============================================================================
USE DATABASE MINING_ESG;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.ESG_ANALYTICS
  COMMENT = 'Mining ESG metrics: emissions, water, safety, community, and tailings analytics'
AS
  TABLES (
    CURATED.EMISSIONS_DASHBOARD AS emissions_dashboard,CURATED.WATER_BALANCE AS water_balance,CURATED.SAFETY_METRICS AS safety_metrics,CURATED.TAILINGS_RISK AS tailings_risk
  );
