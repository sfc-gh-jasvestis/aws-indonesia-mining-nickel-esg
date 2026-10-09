# Indonesia Nickel ESG Monitoring

**Indonesia - Nickel Mining and Processing**
Use case: Site environmental performance and exceedance risk

> ESG monitoring for a fictional nickel operator with 30 synthetic sites across 4 Indonesian provinces: dynamic tables, a holdout-evaluated exceedance-risk classifier, a CO2e emissions forecast and grounded AI answers. Thresholds are internal demo thresholds, not regulatory limits.

## Why Snowflake

- **Dynamic tables** reconcile discharge within threshold, exceedances, emissions intensity and treatment uptime from RAW site data, with checks in `run_core.py`
- **Exceedance-risk classification** gives a holdout-evaluated next-7-day exceedance probability per site
- **Emissions forecast** projects 14 days of operator-wide t CO2e with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.SITES` (30 rows) |
| Fact table | `RAW.SITE_DAILY` (2,700 site-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `EXCEEDANCE_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.EXCEEDANCE_RISK_SCORES`, `ML.EXCEEDANCE_RISK_HOLDOUT_METRICS`, `ML.EMISSIONS_FORECAST`, `ML.TURBIDITY_ANOMALIES` |

Provinces: Central Sulawesi, Southeast Sulawesi, South Sulawesi, North Maluku.
Site types: Open-Pit Mine, RKEF Smelter, HPAL Plant, Tailings Facility, Jetty and Stockpile.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Discharge Within Threshold | 88.3% |
| Environmental Exceedances | 331 |
| Emissions Intensity | 192.2 kg CO2e/t |
| Total Emissions (t CO2e) | 3,260,220 |
| Water Treatment Uptime | 98.1% |
| Sites Monitored | 30 |
| Land Rehabilitated | 50.2% |
| Community Grievances | 75 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily discharge within threshold, samples over threshold by exceedance cause, site table
2. Predictive: holdout metrics, risk bands, 14-day emissions forecast, turbidity anomalies
3. Site Health: water treatment uptime, land rehabilitated, inspection completion against discharge within threshold, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Per-site discharge within threshold ranges from 82.1% to 90.9%. North Maluku is the lowest province, at 87.6%.
- Seepage turbidity puts the most samples over the threshold of the 13 exceedance causes.
- RKEF smelters carry the highest emissions intensity (904.5 kg CO2e/t in the synthetic factors); open-pit mines are around 13 kg CO2e/t.
- The risk model is evaluated on a time-based holdout: precision 0.51 and recall 0.50 at 0.5, against a 0.43 base rate. Present it as triage, not a guarantee.
- The Central Sulawesi rainfall runoff and North Maluku flash flood events are excluded from exceedance labels, because they are regional events, not site-driven.
- No figure is a compliance finding against any regulation; all thresholds are internal to the demo.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
