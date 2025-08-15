# Scenario Planning & MMM

## What-if: Price Scenarios
- Base sales: $50,000.
- Price -5%: $53,000
- Price -10%: $56,000
- Price +5%: $47,000
- Price +10%: $44,000

## MMM
- Template: Fit Bayesian MMM (e.g., using PyMC or Stan via cmdstanr/brms) with adstock and saturation to estimate ROAS and optimize spend.
- This repository focuses on R; for a full MMM, we’ll integrate brms/cmdstanr next.

## Plain-English Summary
- Scenarios show how sales might change if you adjust price; elasticity converts price changes into expected demand shifts.
- MMM helps split credit across channels and budgets so you spend where it works best.
