-- ============================================================================
-- Mining ESG & Sustainability
-- ESG compliance and sustainability reporting for Indonesia's nickel mining industry — Dynamic Tables aggregate emissions and social impact metrics, Cortex AI generates GRI-aligned narratives from operational data.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS MINING_ESG;
CREATE WAREHOUSE IF NOT EXISTS ESG_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE MINING_ESG;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE ESG_WH;
