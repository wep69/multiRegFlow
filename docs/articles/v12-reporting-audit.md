# Reporting, audit trails and reproducible regression workflows

## Why an audit trail matters

A multiple-regression result is not just a final coefficient table.
Reproducible analysis requires a record of the scientific goal,
candidate variables, model formula, diagnostics, treatment of
heteroscedasticity, influence assessment, selection or regularization
decisions, resampling settings and predictive validation.

[`mr_report()`](https://wep69.github.io/multiRegFlow/reference/multiRegFlow.md)
creates a compact Markdown record from an OLS reference model. It is
designed to accompany, not replace, scientific interpretation.

## Example 1: explanatory soil report

``` r

soil <- mr_example_data("soil_fertility")
fit_soil <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct +
    available_P_mg_dm3 + exchangeable_K_mg_dm3 +
    soil_moisture_pct + season_rain_mm,
  soil,
  goal = "explanation"
)
rep1 <- mr_report(fit_soil)
cat(substr(rep1, 1, 1600))
#> # multiRegFlow analysis report
#> 
#> - Engine: `ols`
#> - Goal: `explanation`
#> - Formula: `yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct + available_P_mg_dm3 +      exchangeable_K_mg_dm3 + soil_moisture_pct + season_rain_mm`
#> - Complete observations: 180
#> 
#> ## Model fit
#> 
#> - R-squared: 0.4182
#> - Adjusted R-squared: 0.3945
#> - Residual sigma: 0.5777
#> - AIC: 323.12
#> - BIC: 351.85
#> 
#> ## Diagnostic screens
#> 
#> - Breusch-Pagan p-value: 0.9548
#> - Fitted-value-power specification p-value: 0.2696
#> - Shapiro-Wilk p-value: 0.2325
#> 
#> ## Coefficient inference (classical)
#> 
#> | term | estimate | std_error | p_value | conf_low | conf_high |
#> | --- | --- | --- | --- | --- | --- |
#> | (Intercept) | 1.5955 | 0.5940 | 0.0079 | 0.4230 | 2.7679 |
#> | soil_pH | -0.0394 | 0.0735 | 0.5928 | -0.1845 | 0.1057 |
#> | organic_matter_pct | 0.1614 | 0.0566 | 0.0049 | 0.0497 | 0.2731 |
#> | clay_pct | -0.0026 | 0.0050 | 0.5998 | -0.0124 | 0.0072 |
#> | available_P_mg_dm3 | 0.0273 | 0.0046 | 0.0000 | 0.0181 | 0.0364 |
#> | exchangeable_K_mg_dm3 | 0.0071 | 0.0013 | 0.0000 | 0.0046 | 0.0097 |
#> | soil_moisture_pct | 0.0248 | 0.0103 | 0.0167 | 0.0045 | 0.0451 |
#> | season_rain_mm | 0.0033 | 0.0005 | 0.0000 | 0.0023 | 0.0042 |
#> 
#> ## Collinearity
#> 
#> | term | VIF | tolerance | flag_vif5 | flag_vif10 |
#> | --- | --- | --- | --- | --- |
#> | clay_pct | 1.0743 | 0.9308 | FALSE | FALSE |
#> | soil_pH | 1.0669 | 0.9373 | FALSE | FALSE |
#> | exchangeable_K_mg_dm3 | 1.0412 | 0.9604 | FALSE | FALSE |
#> | season_rain_mm | 1.0272 | 0.9735 | FALSE | FALSE |
#> | soil_moisture_pct | 1.0206 | 0.9798 | FALSE | FALSE |
#> | organic_matter_pct | 1.0155 | 0.9848 | FALSE | FALSE |
#> | available_
```

When heteroscedasticity is detected and `sandwich` is available, the
default `vcov = "auto"` changes the reported coefficient uncertainty to
HC3 while leaving the OLS coefficients unchanged.

## Example 2: explicitly classical report

``` r

rep2 <- mr_report(fit_soil, vcov = "classical")
cat(substr(rep2, 1, 800))
#> # multiRegFlow analysis report
#> 
#> - Engine: `ols`
#> - Goal: `explanation`
#> - Formula: `yield_t_ha ~ soil_pH + organic_matter_pct + clay_pct + available_P_mg_dm3 +      exchangeable_K_mg_dm3 + soil_moisture_pct + season_rain_mm`
#> - Complete observations: 180
#> 
#> ## Model fit
#> 
#> - R-squared: 0.4182
#> - Adjusted R-squared: 0.3945
#> - Residual sigma: 0.5777
#> - AIC: 323.12
#> - BIC: 351.85
#> 
#> ## Diagnostic screens
#> 
#> - Breusch-Pagan p-value: 0.9548
#> - Fitted-value-power specification p-value: 0.2696
#> - Shapiro-Wilk p-value: 0.2325
#> 
#> ## Coefficient inference (classical)
#> 
#> | term | estimate | std_error | p_value | conf_low | conf_high |
#> | --- | --- | --- | --- | --- | --- |
#> | (Intercept) | 1.5955 | 0.5940 | 0.0079 | 0.4230 | 2.7679 |
#> | soil_pH | -0.0394 | 0.0735 | 0.5928 | -0.1845 | 0.1057 |
#> | organic_matter_pct | 0.1614 |
```

This is useful when the analyst needs to show exactly which covariance
estimator was used rather than rely on the automatic choice.

## Example 3: predictive report with cross-validation

``` r

plant <- mr_example_data("plant_growth")
fit_pred <- mr_fit(
  biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
    stomatal_conductance + plant_height_cm + root_mass_g,
  plant,
  goal = "prediction"
)
rep3 <- mr_report(fit_pred, validation = TRUE,
                  v = 5, repeats = 3, seed = 90)
cat(substr(rep3, 1, 1200))
#> # multiRegFlow analysis report
#> 
#> - Engine: `ols`
#> - Goal: `prediction`
#> - Formula: `biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct + stomatal_conductance +      plant_height_cm + root_mass_g`
#> - Complete observations: 160
#> 
#> ## Model fit
#> 
#> - R-squared: 0.7047
#> - Adjusted R-squared: 0.6931
#> - Residual sigma: 1.3604
#> - AIC: 561.39
#> - BIC: 585.99
#> 
#> ## Diagnostic screens
#> 
#> - Breusch-Pagan p-value: 0.007768
#> - Fitted-value-power specification p-value: 0.0003984
#> - Shapiro-Wilk p-value: 0.4734
#> 
#> ## Coefficient inference (HC3)
#> 
#> | term | estimate | std_error | p_value | conf_low | conf_high |
#> | --- | --- | --- | --- | --- | --- |
#> | (Intercept) | 1.1043 | 1.6388 | 0.5014 | -2.1333 | 4.3420 |
#> | leaf_area_cm2 | 0.1481 | 0.0150 | 0.0000 | 0.1184 | 0.1778 |
#> | chlorophyll_spad | 0.1767 | 0.0185 | 0.0000 | 0.1402 | 0.2133 |
#> | leaf_N_pct | 1.4767 | 0.2659 | 0.0000 | 0.9515 | 2.0020 |
#> | stomatal_conductance | 8.2362 | 1.4132 | 0.0000 | 5.4443 | 11.0281 |
#> | plant_height_cm | 0.0262 | 0.0098 | 0.0085 | 0.0068 | 0.0456 |
#> | root_mass_g | 0.0923 | 0.0282 | 0.0013 | 0.0366 | 0.1479 |
#> 
#> ## Collinearity
#> 
#> | term | VIF | tolerance | flag_vif5 | flag_vif10 |
#> | --- | --- | --- | --- | --- |
#> | stomatal_conductance |
```

## Writing the report to disk

``` r

tmp1 <- tempfile(fileext = ".md")
mr_report(fit_soil, file = tmp1)
file.exists(tmp1)
#> [1] TRUE
```

``` r

tmp2 <- tempfile(fileext = ".md")
mr_report(fit_pred, file = tmp2, validation = TRUE,
          v = 5, repeats = 2, seed = 91)
file.info(tmp2)$size
#> [1] 3714
```

A project workflow can store these reports next to scripts, frozen data
and session information.

## Recommendation examples

The recommendation engine is most useful when compared across different
statistical problems.

``` r

mr_recommend(fit_soil)
#>         domain                                                finding
#> 1 collinearity No strong VIF signal under the package screening rule.
#> 2    influence    7 observation(s) exceed Cook's 4/n screening value.
#> 3    selection            The declared goal is explanation/inference.
#>                                                                                                      recommendation
#> 1                                Still inspect correlated predictor groups when scientific redundancy is plausible.
#> 2                Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.
#> 3 Treat automated selection as exploratory; prioritize prespecified scientific terms, effect sizes and uncertainty.
#>   priority
#> 1      low
#> 2   medium
#> 3     high
```

``` r

coll <- mr_example_data("agronomy_collinear")
fit_coll <- mr_fit(yield_t_ha ~ ., coll)
mr_recommend(fit_coll)
#>         domain                                              finding
#> 1 collinearity                                Maximum VIF is 11.45.
#> 2    influence 12 observation(s) exceed Cook's 4/n screening value.
#> 3    selection          The declared goal is explanation/inference.
#>                                                                                                                                 recommendation
#> 1 Inspect condition indices and variance decomposition; retain scientifically required terms and compare OLS with ridge coefficient stability.
#> 2                                           Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.
#> 3                            Treat automated selection as exploratory; prioritize prespecified scientific terms, effect sizes and uncertainty.
#>   priority
#> 1     high
#> 2   medium
#> 3     high
```

``` r

nl <- mr_example_data("irrigation_nonlinear")
fit_nl <- mr_fit(
  yield_t_ha ~ irrigation_mm + N_rate_kg_ha + mean_temp_C,
  nl
)
mr_recommend(fit_nl)
#>         domain                                                finding
#> 1 collinearity No strong VIF signal under the package screening rule.
#> 2    influence   10 observation(s) exceed Cook's 4/n screening value.
#> 3    selection            The declared goal is explanation/inference.
#>                                                                                                      recommendation
#> 1                                Still inspect correlated predictor groups when scientific redundancy is plausible.
#> 2                Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.
#> 3 Treat automated selection as exploratory; prioritize prespecified scientific terms, effect sizes and uncertainty.
#>   priority
#> 1      low
#> 2   medium
#> 3     high
```

The outputs differ because the problems differ. Collinearity motivates
stability analysis, a functional-form signal motivates nonlinear
sensitivity, and an explanatory goal discourages treating automated
selection as confirmatory.

## Capability audit

``` r

cap <- mr_capabilities()
cap
#>                         module                  backend         package
#> 1                          OLS                    stats            <NA>
#> 2                  diagnostics             multiRegFlow            <NA>
#> 3              influence flags             multiRegFlow            <NA>
#> 4        VIF/condition indices multiRegFlow/performance     performance
#> 5  robust covariance inference                 sandwich        sandwich
#> 6            AIC/BIC selection                    stats            <NA>
#> 7                 best subsets                    leaps           leaps
#> 8      ridge/lasso/elastic net                   glmnet          glmnet
#> 9          stability selection             stabs+glmnet           stabs
#> 10                   bootstrap             multiRegFlow                
#> 11     cross-engine validation             multiRegFlow                
#> 12           robust regression               robustbase      robustbase
#> 13         quantile regression                 quantreg        quantreg
#> 14           kernel regression                       np              np
#> 15                         GAM                     mgcv            mgcv
#> 16     partial/semi-partial R2             multiRegFlow                
#> 17              LMG importance                 relaimpo        relaimpo
#> 18                        SHAP               kernelshap      kernelshap
#> 19            marginal effects          marginaleffects marginaleffects
#>    available
#> 1       TRUE
#> 2       TRUE
#> 3       TRUE
#> 4       TRUE
#> 5       TRUE
#> 6       TRUE
#> 7       TRUE
#> 8       TRUE
#> 9       TRUE
#> 10      TRUE
#> 11      TRUE
#> 12      TRUE
#> 13      TRUE
#> 14      TRUE
#> 15      TRUE
#> 16      TRUE
#> 17      TRUE
#> 18      TRUE
#> 19      TRUE
```

``` r

subset(cap, !available)
#> [1] module    backend   package   available
#> <0 rows> (or 0-length row.names)
```

``` r

table(cap$backend)
#> 
#>                   glmnet               kernelshap                    leaps 
#>                        1                        1                        1 
#>          marginaleffects                     mgcv             multiRegFlow 
#>                        1                        1                        5 
#> multiRegFlow/performance                       np                 quantreg 
#>                        1                        1                        1 
#>                 relaimpo               robustbase                 sandwich 
#>                        1                        1                        1 
#>             stabs+glmnet                    stats 
#>                        1                        2
```

This information is useful when a report depends on optional backends
that may not be installed on another computer.

## Minimum reproducibility record

For an analysis intended for publication or project review, save at
least:

- the original or analysis-ready data with provenance;
- the exact model formula and declared goal;
- package version and
  [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html);
- random seeds for bootstrap and validation;
- bootstrap type and number of replicates;
- covariance estimator used for inference;
- selection criterion, lambda rule or stability-selection settings;
- all exclusions and transformations with justification;
- out-of-fold metrics for predictive claims;
- scripts that regenerate tables and figures.

## Suggested Methods wording

A transparent Methods description should state that multiple linear
regression was fitted as a reference model, specify the candidate
predictors, describe residual and influence diagnostics, explain how
multicollinearity was evaluated, identify any robust covariance or
bootstrap analysis, and state whether variable selection or
regularization was exploratory. Predictive analyses should describe
cross-validation design and metrics.

## Suggested Results wording

Results should focus on estimates, uncertainty, effect sizes and
patterns that address the scientific question. Avoid repeating every
diagnostic statistic. Report material sensitivity to influential
observations, covariance estimators, selection procedures or flexible
alternatives when those analyses change the scientific conclusion.

## What the automated report intentionally does not do

[`mr_report()`](https://wep69.github.io/multiRegFlow/reference/multiRegFlow.md)
does not infer the experimental design, decide whether a predictor is a
confounder, convert associations into causal effects, determine
biological relevance from p-values, or decide whether an influential
observation is invalid. Those decisions remain the analyst’s scientific
responsibility.

## Final integrated audit

``` r

list(
  diagnostics = mr_diagnose(fit_soil),
  collinearity = mr_collinearity(fit_soil)$VIF,
  importance = mr_importance(fit_soil, "semi_partial_r2"),
  recommendation = mr_recommend(fit_soil)
)
#> $diagnostics
#> $diagnostics$goal
#> [1] "explanation"
#> 
#> $diagnostics$fit
#>              n              p effective_rank    residual_df             R2 
#>    180.0000000      7.0000000      8.0000000    172.0000000      0.4181638 
#>    adjusted_R2          sigma            AIC            BIC 
#>      0.3944845      0.5777249    323.1179645    351.8545762 
#> 
#> $diagnostics$rank
#>                 rank_deficient n_to_effective_predictor_ratio 
#>                        0.00000                       25.71429 
#> 
#> $diagnostics$residuals
#>         mean           sd    shapiro_W    shapiro_p 
#> 1.394992e-17 5.663160e-01 9.898918e-01 2.324635e-01 
#> 
#> $diagnostics$heteroscedasticity
#> statistic        df   p.value 
#> 2.0886930 7.0000000 0.9547686 
#> 
#> $diagnostics$specification
#>   statistic         df1         df2     p.value 
#>   1.3209121   2.0000000 170.0000000   0.2696168 
#> 
#> $diagnostics$influence
#>            max_hat max_cooks_distance n_cook_gt_4_over_n 
#>         0.14240600         0.04164969         7.00000000 
#> 
#> $diagnostics$note
#> [1] "Interpret diagnostics jointly. Normality is mainly relevant to exact small-sample inference; heteroscedasticity can often be addressed with robust covariance or wild bootstrap without changing the mean model."
#> 
#> 
#> $collinearity
#>                    term      VIF tolerance flag_vif5 flag_vif10
#> 1               soil_pH 1.066943 0.9372570     FALSE      FALSE
#> 2    organic_matter_pct 1.015473 0.9847628     FALSE      FALSE
#> 3              clay_pct 1.074343 0.9308011     FALSE      FALSE
#> 4    available_P_mg_dm3 1.012495 0.9876592     FALSE      FALSE
#> 5 exchangeable_K_mg_dm3 1.041205 0.9604257     FALSE      FALSE
#> 6     soil_moisture_pct 1.020630 0.9797871     FALSE      FALSE
#> 7        season_rain_mm 1.027173 0.9735458     FALSE      FALSE
#> 
#> $importance
#>                    term semi_partial_R2
#> 1               soil_pH    0.0009711845
#> 2    organic_matter_pct    0.0275086322
#> 3              clay_pct    0.0009347394
#> 4    available_P_mg_dm3    0.1176300654
#> 5 exchangeable_K_mg_dm3    0.1059005899
#> 6     soil_moisture_pct    0.0197575420
#> 7        season_rain_mm    0.1468327939
#> 
#> $recommendation
#>         domain                                                finding
#> 1 collinearity No strong VIF signal under the package screening rule.
#> 2    influence    7 observation(s) exceed Cook's 4/n screening value.
#> 3    selection            The declared goal is explanation/inference.
#>                                                                                                      recommendation
#> 1                                Still inspect correlated predictor groups when scientific redundancy is plausible.
#> 2                Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.
#> 3 Treat automated selection as exploratory; prioritize prespecified scientific terms, effect sizes and uncertainty.
#>   priority
#> 1      low
#> 2   medium
#> 3     high
```

This final object demonstrates the package philosophy: preserve separate
evidence streams and combine them through interpretation rather than
collapsing them into one automatic score.
