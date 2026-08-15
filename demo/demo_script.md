# Demo Script: Mining ESG & Sustainability
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake automates ESG reporting at mining scale — Dynamic Tables aggregate scope 1-3 emissions, water usage, and community impact; ML detects anomalous discharge events; Cortex AI drafts GRI-aligned sustainability reports"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Dr. Yanti Sumarno** | VP Sustainability & ESG | React App (SPCS) | GRI reporting, emissions targets, water discharge compliance, community relations, investor ESG ratings |
| **Eko Prasetyo** | Environmental Engineer | Amazon QuickSight | Tailings management, air quality monitoring, effluent treatment, biodiversity offsets |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | EMISSIONS_DATA (100000), WATER_MONITORING (200000), COMMUNITY_PROGRAMS (500), SAFETY_INCIDENTS (2000), TAILINGS_MONITORING (50000), ESG_REPORTS (80) |
| **CURATED** | 4 Dynamic Tables | EMISSIONS_DASHBOARD, WATER_BALANCE, SAFETY_METRICS, TAILINGS_RISK |
| **ML** | ML.FORECAST + ML.ANOMALY_DETECTION | Forecasting + anomaly detection |
| **AI** | COMPLETE, SUMMARIZE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 80 documents indexed |
| **Agent** | ESG_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

Indonesia's nickel mining boom has attracted US$33B in investment, but ESG scrutiny is intensifying as EV OEMs demand responsible sourcing. A VP Sustainability must track emissions, water discharge, tailings stability, and community impact across 12 sites — while generating GRI-aligned reports for investors and maintaining social license to operate.

---

## Script

### [0:00–0:45] ESG OVERVIEW

**Show**: ESG Overview tab

> "Scope 1+2 emissions at 1.2M tCO2e — tracking 8% above 2025 reduction pathway."

**Action**: Point at emissions vs target trend line

### [0:45–1:30] ENVIRONMENTAL

**Show**: Environmental tab

> "RKEF smelters are the primary emissions source — 72% of Scope 1."

**Action**: Show emissions breakdown by source pie chart

### [1:30–2:15] TAILINGS & SAFETY

**Show**: Tailings & Safety tab

> "Four tailings storage facilities monitored — TSF-3 at 82% capacity, highest risk score."

**Action**: Show tailings capacity gauge chart

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Dr. Yanti asks: 'Are we on track to meet our 2025 emissions target?'"

**Action**: Type emissions target question

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, six AWS services in the dual-build architecture."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.FORECAST for emissions trajectory vs target** — Only demo projecting mining emissions against reduction pathway with ML
2. **Discharge anomaly detection** — ML.ANOMALY_DETECTION flags unusual water quality readings before regulatory breach
3. **AI-generated GRI sustainability narratives** — Cortex AI drafts GRI-aligned disclosure text from structured ESG data
4. **Tailings stability real-time monitoring** — Only demo tracking tailings storage facility risk with real-time sensor data
5. **Indonesian nickel mining ESG context** — EV supply chain scrutiny, RKEF/HPAL emissions, tropical tailings management


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM MINING_ESG.RAW.EMISSIONS_DATA` → 100000
- [ ] `SELECT COUNT(*) FROM MINING_ESG.RAW.WATER_MONITORING` → 200000
- [ ] `SELECT COUNT(*) FROM MINING_ESG.RAW.TAILINGS_MONITORING` → 50000

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM MINING_ESG.ML.EMISSIONS_FORECAST_RESULTS` → >0
- [ ] `SELECT COUNT(*) FROM MINING_ESG.ML.DISCHARGE_ANOMALY_RESULTS WHERE IS_ANOMALY = TRUE` → >=2

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM MINING_ESG.AI.INCIDENT_CLASSIFICATION` → 2000

