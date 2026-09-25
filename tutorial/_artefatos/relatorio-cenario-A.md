# multiRegFlow analysis report

- Engine: `ols`
- Goal: `prediction`
- Formula: `yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 + season_rain_mm`
- Complete observations: 200

## Model fit

- R-squared: 0.2128
- Adjusted R-squared: 0.2007
- Residual sigma: 0.9984
- AIC: 572.89
- BIC: 589.38

## Diagnostic screens

- Breusch-Pagan p-value: 0.7404
- Fitted-value-power specification p-value: 0.5012
- Shapiro-Wilk p-value: 0.5127

## Coefficient inference (classical)

| term | estimate | std_error | p_value | conf_low | conf_high |
| --- | --- | --- | --- | --- | --- |
| (Intercept) | 3.4748 | 0.4340 | 0.0000 | 2.6190 | 4.3307 |
| organic_matter_pct | 0.4593 | 0.0682 | 0.0000 | 0.3248 | 0.5938 |
| available_P_mg_dm3 | -0.0004 | 0.0085 | 0.9656 | -0.0172 | 0.0165 |
| season_rain_mm | 0.0015 | 0.0006 | 0.0111 | 0.0003 | 0.0027 |

## Collinearity

| term | VIF | tolerance | flag_vif5 | flag_vif10 |
| --- | --- | --- | --- | --- |
| available_P_mg_dm3 | 1.0024 | 0.9976 | FALSE | FALSE |
| season_rain_mm | 1.0020 | 0.9980 | FALSE | FALSE |
| organic_matter_pct | 1.0019 | 0.9981 | FALSE | FALSE |

## Most influential observations for inspection

| row | leverage | cooks_distance | dffits | max_abs_dfbeta | flag_leverage | flag_cook |
| --- | --- | --- | --- | --- | --- | --- |
| 35 | 0.0364 | 0.0549 | 0.4747 | 0.3046 | FALSE | TRUE |
| 138 | 0.0446 | 0.0470 | -0.4368 | 0.2671 | TRUE | TRUE |
| 135 | 0.0407 | 0.0402 | -0.4037 | 0.2905 | TRUE | TRUE |
| 32 | 0.0357 | 0.0352 | -0.3779 | 0.2225 | FALSE | TRUE |
| 47 | 0.0331 | 0.0342 | 0.3726 | 0.2543 | FALSE | TRUE |
| 132 | 0.0614 | 0.0310 | -0.3532 | 0.2914 | TRUE | TRUE |
| 109 | 0.0177 | 0.0309 | -0.3572 | 0.2182 | FALSE | TRUE |
| 119 | 0.0208 | 0.0240 | 0.3128 | 0.1879 | FALSE | TRUE |

## Methodological recommendations

### collinearity [low]

No strong VIF signal under the package screening rule.

Still inspect correlated predictor groups when scientific redundancy is plausible.

### influence [medium]

15 observation(s) exceed Cook's 4/n screening value.

Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.

### validation [high]

The declared goal is prediction.

Use repeated out-of-fold validation and compare models on RMSE, MAE, out-of-fold R2 and calibration.

## Out-of-fold validation

| metric | mean | sd |
| --- | --- | --- |
| RMSE | 1.0137 | 0.0043 |
| MAE | 0.7907 | 0.0064 |
| R2 | 0.1718 | 0.0070 |
| calibration_intercept | 0.5447 | 0.0274 |
| calibration_slope | 0.8982 | 0.0048 |

## Interpretation note

Associations are conditional on the fitted specification and do not by themselves establish causality. Final interpretation must consider design, measurement process, agronomic plausibility and uncertainty.

