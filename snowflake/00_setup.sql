-- Generated from generator/demo_specs/aws-indonesia-mining-nickel-esg.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-indonesia-mining-nickel-esg
-- This is the schema that is actually deployed for ID_MINING_NICKEL_ESG.

-- ID_MINING_NICKEL_ESG  (Mining ESG & Sustainability)
-- generated from generator/demo_specs/aws-indonesia-mining-nickel-esg.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS ID_MINING_NICKEL_ESG;
CREATE SCHEMA IF NOT EXISTS ID_MINING_NICKEL_ESG.RAW;
CREATE SCHEMA IF NOT EXISTS ID_MINING_NICKEL_ESG.CURATED;
CREATE SCHEMA IF NOT EXISTS ID_MINING_NICKEL_ESG.APP;
USE DATABASE ID_MINING_NICKEL_ESG;

-- 5 real regions; entity names carry their region so the two always agree
