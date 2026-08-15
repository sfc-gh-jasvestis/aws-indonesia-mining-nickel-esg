-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Mining ESG & Sustainability
-- ============================================================================
USE DATABASE MINING_ESG;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.ESG_INTELLIGENCE_AGENT
  COMMENT = 'Mining ESG & Sustainability AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'MINING_ESG.APP.ESG_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'MINING_ESG.SEARCH.ESG_REPORTS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Mining & Nickel Processing information')
  )
  SYSTEM_PROMPT = 'You are the ESG Intelligence Agent for an Indonesian nickel mining operation, tracking environmental, social, and governance metrics across 12 sites in Central Sulawesi and North Maluku.';
