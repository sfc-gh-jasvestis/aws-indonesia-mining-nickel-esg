# Mining ESG & Sustainability

**Indonesia - Mining & Nickel Processing**
Use case: ESG & Sustainability Reporting

> ESG compliance and sustainability reporting for Indonesia's nickel mining industry — Dynamic Tables aggregate emissions and social impact metrics, Cortex AI generates GRI-aligned narratives from operational data.

## Why Snowflake

Snowflake automates ESG reporting at mining scale — Dynamic Tables aggregate scope 1-3 emissions, water usage, and community impact; ML detects anomalous discharge events; Cortex AI drafts GRI-aligned sustainability reports

- **ML.FORECAST for emissions trajectory vs target** - Only demo projecting mining emissions against reduction pathway with ML
- **Discharge anomaly detection** - ML.ANOMALY_DETECTION flags unusual water quality readings before regulatory breach
- **AI-generated GRI sustainability narratives** - Cortex AI drafts GRI-aligned disclosure text from structured ESG data
- **Tailings stability real-time monitoring** - Only demo tracking tailings storage facility risk with real-time sensor data
- **Indonesian nickel mining ESG context** - EV supply chain scrutiny, RKEF/HPAL emissions, tropical tailings management

## What is deployed

| | |
|---|---|
| Database | `ID_MINING_NICKEL_ESG` |
| Service | `ID_MINING_NICKEL_ESG_APP` |
| Compute pool | `SEA_DEMOS_INDONESIA_POOL` |
| Dimension table | `RAW.ESG_REPORTS` (20 rows) |
| Fact table | `RAW.WATER_MONITORING` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | IDR (Rp) |

Regions in play: Jakarta, North Sumatra, Riau, East Kalimantan, Sulawesi
Segments: Water Management, Tailings, Rehabilitation, Community

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh ID_MINING_NICKEL_ESG
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| ESG Score (Avg) | `72/100` | average per event |
| Emissions (MTD) | `124K tCO2e` | total across Esg Reports |
| Rehabilitation Area | `847 ha` | average per event |
| Sites Monitored | `34` | total across Esg Reports |
| Water Recycled | `78%` | average per event |
| Biodiversity Index | `0.72` | average per event |
| Tailings Stability | `Safe` | fixed label (not numeric) |

## Demo flow

1. ESG Overview
2. Environmental
3. Tailings & Safety
4. Ask AI
5. Architecture & Data

## Talking points

- **1.2M tCO2e** - Scope 1+2 annual emissions (8% above target pathway)
- **78% recycling** - water recycling rate (target: 85%)
- **1.8 LTIFR** - lost time injury frequency rate per million hours
- **200,000 readings** - water quality monitoring data points
- **4 TSFs** - tailings storage facilities monitored in real-time
- **80 reports** - ESG documents searchable via Cortex Search

## Business impact

- Indonesian nickel processing emissions intensity is 35-50 tCO2/t Ni — among the highest globally (IEA)
- EV OEMs (Tesla, BMW, Hyundai) requiring full ESG traceability from nickel suppliers by 2025 (Reuters)
- ESG-rated mining companies command 12-18% valuation premium over non-rated peers (McKinsey Mining)
- Indonesia has 12 operating nickel HPAL and RKEF facilities — all face ESG reporting requirements (ESDM)

---
Generated from `generator/demo_specs/aws-indonesia-mining-nickel-esg.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-indonesia-mining-nickel-esg` instead.
