# Multi-Touch Attribution & CPA Pipeline

A marketing-analytics pipeline that cleans raw ad-touchpoint data, removes bot/fraud
traffic, builds multi-touch attribution models (Markov removal-effect and Shapley
value), and converts attributed conversions into actionable cost-per-acquisition
(CPA) metrics with budget-reallocation flags.

## Pipeline order

The five notebooks form a sequential pipeline. **Run them in this order** — each
stage consumes a CSV produced by the previous one:

```
1. BOT_Detection3.ipynb
   reads:  touchpoints.csv
   writes: touchpoints_clean_v3.csv, bot_detection_report_v3.csv
        |
        v
2. Diagnose.ipynb              (exploratory — informs modeling choices)
   reads:  touchpoints_clean_v3.csv
        |
        v
3. EDA2.ipynb                  (exploratory — informs modeling choices)
   reads:  touchpoints_clean_v3.csv
   writes: eda_channel_funnel.csv
        |
        v
4. Models.ipynb
   reads:  touchpoints_clean_v3.csv
   writes: attribution_overall_v2.csv, attribution_per_brand.csv
           (saved/renamed as per_brand_attribution.csv for step 5)
        |
        v
5. CPA_calculation.ipynb
   reads:  per_brand_attribution.csv, touchpoints_clean_v3.csv, campaign_spend.csv
   writes: spend_actual.csv, cpa_final.csv
```

`Diagnose.ipynb` and `EDA2.ipynb` are exploratory — they don't produce inputs that a
later notebook strictly requires to *run*, but the patterns they surface (most
journeys are multi-channel; last-click attribution undercounts upper-funnel
channels) are the direct justification for using Markov + Shapley models in
`Models.ipynb` rather than a simpler last-click rule.

## What each notebook does

| Notebook | Purpose |
|---|---|
| **BOT_Detection3** | Diagnoses 4 candidate bot/fraud signals against raw data, keeps only the one with genuine statistical evidence (event-volume outliers via IQR × 4), and removes flagged users before any modeling happens. |
| **Diagnose** | Checks how channels behave in converting journeys — last-touch vs. first-touch vs. "appears anywhere" — to motivate using a multi-touch attribution model. |
| **EDA2** | Characterizes the cleaned dataset: funnel shape, channel-level CTR/conversion, campaign spread, journey complexity, time patterns, and a final data-quality check. |
| **Models** | Implements two independent multi-touch attribution models — Markov chain removal-effect and Shapley value — run both overall and per-brand (10 brands), and compares them against a last-click baseline. |
| **CPA_calculation** | Combines Shapley-attributed conversions with actual ad spend (derived from real CPC/CPM event counts) to compute CPA per brand-channel, then flags defund and frequency-cap candidates. |

## Key methodology decisions

- **Bot detection is evidence-based, not assumption-based.** Two of four candidate
  signals (sub-second timing, burst duplicates) turned out to be artifacts of
  timestamp rounding, not real bot behavior, and were dropped after diagnosis. A
  third (impressions-only = bot) was conflating normal low-CTR human behavior with
  fraud and was dropped after testing. Only event-volume outliers survived scrutiny.
- **Two attribution models are run side-by-side, not just one.** Markov
  removal-effect and Shapley value make different structural assumptions about how
  credit should flow through a journey. Where they agree, that's stronger evidence;
  where they diverge (see per-brand results in `Models.ipynb`), that divergence is
  itself a useful signal about how much to trust a given result.
- **CPA uses fractional (Shapley-weighted) conversions, not raw counts**, to avoid
  double-counting a conversion across every channel in a multi-touch journey.
- **Actual spend is derived from real event counts**, not read from planned budget
  figures, so CPA reflects what was actually spent rather than what was allocated.

## Requirements

Python 3.12, with `pandas` and `numpy`. No other dependencies.

## Files in this submission

```
BOT_Detection3.ipynb     — Stage 1: bot/fraud detection & data cleaning
Diagnose.ipynb           — Stage 2: channel-behavior diagnostics
EDA2.ipynb               — Stage 3: exploratory data analysis
Models.ipynb             — Stage 4: Markov & Shapley attribution models
CPA_calculation.ipynb    — Stage 5: CPA calculation & budget flags
README.md                — this file
```
