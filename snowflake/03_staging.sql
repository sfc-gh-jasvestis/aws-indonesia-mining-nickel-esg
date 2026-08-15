-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Mining ESG & Sustainability
-- Country: INDONESIA | Currency: IDR
-- ============================================================================
USE DATABASE MINING_ESG;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- EMISSIONS_DATA: 100,000 rows — Scope 1, 2, and 3 GHG emissions by source, site, and month
-- WATER_MONITORING: 200,000 rows — Water intake, discharge, and quality measurements at all sites
-- COMMUNITY_PROGRAMS: 500 rows — CSR programs, community investments, and social impact metrics
-- SAFETY_INCIDENTS: 2,000 rows — Workplace safety incidents, near misses, and LTIFR data
-- TAILINGS_MONITORING: 50,000 rows — Tailings storage facility levels, stability, and dam safety data
-- ESG_REPORTS: 80 rows — Annual sustainability reports, GRI disclosures, and third-party audits
