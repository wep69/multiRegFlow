# multiRegFlow: scope, workflow and package map

## Purpose

`multiRegFlow` is a guided workflow for multiple regression in
agricultural, soil and plant sciences. It does not replace
[`lm()`](https://rdrr.io/r/stats/lm.html), `glmnet`, `quantreg`,
`robustbase`, `mgcv`, `np`, or other specialized packages. Its purpose
is to make the statistical path explicit: define the scientific goal,
fit a transparent reference model, diagnose the specification,
investigate multicollinearity and influence, quantify uncertainty,
explore selection or shrinkage when justified, compare flexible
alternatives, validate prediction out of sample, and record the
reasoning in an auditable report.

The central distinction is between **explanation/inference** and
**prediction**. An explanatory analysis asks how a response changes
conditionally on the terms in a scientific model. A predictive analysis
asks how accurately new observations can be predicted. Selection
criteria, uncertainty statements and performance metrics must be
interpreted differently under these goals.

## Available modules

``` r

mr_capabilities()
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

The capability table also provides a quick check of optional backends
installed in the current R library.

``` r

subset(mr_capabilities(), available)
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

A third useful view is the set of modules that need optional packages.

``` r

subset(mr_capabilities(), !is.na(package) & package != "")
#>                         module                  backend         package
#> 4        VIF/condition indices multiRegFlow/performance     performance
#> 5  robust covariance inference                 sandwich        sandwich
#> 7                 best subsets                    leaps           leaps
#> 8      ridge/lasso/elastic net                   glmnet          glmnet
#> 9          stability selection             stabs+glmnet           stabs
#> 12           robust regression               robustbase      robustbase
#> 13         quantile regression                 quantreg        quantreg
#> 14           kernel regression                       np              np
#> 15                         GAM                     mgcv            mgcv
#> 17              LMG importance                 relaimpo        relaimpo
#> 18                        SHAP               kernelshap      kernelshap
#> 19            marginal effects          marginaleffects marginaleffects
#>    available
#> 4       TRUE
#> 5       TRUE
#> 7       TRUE
#> 8       TRUE
#> 9       TRUE
#> 12      TRUE
#> 13      TRUE
#> 14      TRUE
#> 15      TRUE
#> 17      TRUE
#> 18      TRUE
#> 19      TRUE
```

## Teaching datasets

The package ships frozen **synthetic** datasets. They were designed to
create known teaching situations and must not be represented as
observations from real field trials.

``` r

soil <- mr_example_data("soil_fertility")
plant <- mr_example_data("plant_growth")
coll <- mr_example_data("agronomy_collinear")
str(soil)
#> 'data.frame':    180 obs. of  9 variables:
#>  $ yield_t_ha           : num  4.94 5.8 5.6 5.07 5.87 ...
#>  $ soil_pH              : num  5.59 5.89 5.29 5.88 5.61 ...
#>  $ organic_matter_pct   : num  0.914 3.855 1.561 0.9 1.269 ...
#>  $ clay_pct             : num  30.3 28.3 19.3 16.7 52.2 ...
#>  $ available_P_mg_dm3   : num  21.24 23.9 36.42 9.36 6.08 ...
#>  $ exchangeable_K_mg_dm3: num  111.2 103.2 56.6 78.6 135.6 ...
#>  $ CEC_cmolc_dm3        : num  22 26.5 18.9 22.8 34.2 ...
#>  $ soil_moisture_pct    : num  18 21.4 24.2 27.9 26.5 ...
#>  $ season_rain_mm       : num  617 646 521 692 612 ...
```

``` r

nl <- mr_example_data("irrigation_nonlinear")
het <- mr_example_data("agronomy_heteroskedastic")
c(n_soil = nrow(soil), n_plant = nrow(plant), n_nonlinear = nrow(nl))
#>      n_soil     n_plant n_nonlinear 
#>         180         160         170
```

``` r

summary(coll[c("N_rate_kg_ha", "N_uptake_kg_ha", "canopy_N_g_m2")])
#>   N_rate_kg_ha   N_uptake_kg_ha   canopy_N_g_m2  
#>  Min.   : 40.0   Min.   : 31.87   Min.   :25.45  
#>  1st Qu.:102.5   1st Qu.: 70.82   1st Qu.:34.42  
#>  Median :119.9   Median : 85.47   Median :37.95  
#>  Mean   :121.4   Mean   : 86.81   Mean   :37.90  
#>  3rd Qu.:144.4   3rd Qu.:102.45   3rd Qu.:40.71  
#>  Max.   :198.2   Max.   :139.91   Max.   :51.72
```

The five datasets emphasize different questions:

| Dataset | Main teaching purpose |
|----|----|
| `soil_fertility` | explanatory OLS, effects, importance and reporting |
| `plant_growth` | physiology and biomass regression |
| `agronomy_collinear` | redundant N-status indicators and regularization |
| `irrigation_nonlinear` | functional-form failure and flexible alternatives |
| `agronomy_heteroskedastic` | robust covariance and wild bootstrap |

## A minimal explanatory workflow

``` r

fit_soil <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + available_P_mg_dm3 +
    exchangeable_K_mg_dm3 + soil_moisture_pct + season_rain_mm,
  data = soil,
  goal = "explanation"
)
fit_soil
#> multiRegFlow model
#>  Engine: ols 
#>  Goal: explanation 
#>  Formula: yield_t_ha ~ soil_pH + organic_matter_pct + available_P_mg_dm3 +      exchangeable_K_mg_dm3 + soil_moisture_pct + season_rain_mm 
#>  Complete observations: 180
```

``` r

mr_diagnose(fit_soil)$fit
#>              n              p effective_rank    residual_df             R2 
#>    180.0000000      6.0000000      7.0000000    173.0000000      0.4172291 
#>    adjusted_R2          sigma            AIC            BIC 
#>      0.3970174      0.5765153    321.4069086    346.9505634
mr_collinearity(fit_soil)$VIF
#>                    term      VIF tolerance flag_vif5 flag_vif10
#> 1               soil_pH 1.035742 0.9654917     FALSE      FALSE
#> 2    organic_matter_pct 1.014413 0.9857914     FALSE      FALSE
#> 3    available_P_mg_dm3 1.012355 0.9877961     FALSE      FALSE
#> 4 exchangeable_K_mg_dm3 1.006033 0.9940033     FALSE      FALSE
#> 5     soil_moisture_pct 1.019701 0.9806799     FALSE      FALSE
#> 6        season_rain_mm 1.023927 0.9766320     FALSE      FALSE
mr_recommend(fit_soil)
#>         domain                                                finding
#> 1 collinearity No strong VIF signal under the package screening rule.
#> 2    influence    8 observation(s) exceed Cook's 4/n screening value.
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

The output is deliberately modular. A single omnibus table can hide the
fact that model fit, coefficient uncertainty, collinearity and
predictive performance answer different questions.

## A minimal predictive workflow

``` r

fit_pred <- mr_fit(
  biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
    stomatal_conductance + plant_height_cm + root_mass_g,
  data = plant,
  goal = "prediction"
)
mr_validate(fit_pred, v = 5, repeats = 3, seed = 2026)$summary
#>                  metric      mean          sd
#> 1                  RMSE 1.3971341 0.024283304
#> 2                   MAE 1.1186854 0.011162512
#> 3                    R2 0.6741571 0.011381128
#> 4 calibration_intercept 0.5397122 0.142703035
#> 5     calibration_slope 0.9775596 0.006023731
```

Out-of-fold predictions are generated without using an observation in
the fit that predicts that same observation. This is preferable to
reporting training `R-squared` as predictive evidence.

## Flexible alternatives are sensitivity analyses, not automatic upgrades

``` r

fit_nl <- mr_fit(
  yield_t_ha ~ irrigation_mm + N_rate_kg_ha + mean_temp_C,
  data = nl,
  goal = "prediction"
)
mr_diagnose(fit_nl)$specification
#>   statistic         df1         df2     p.value 
#>   0.7537816   2.0000000 164.0000000   0.4722068
```

A significant functional-form screen is a reason to inspect the residual
pattern and agronomic mechanism. It is not proof that a particular
nonlinear model is correct. The dedicated flexible-alternatives vignette
demonstrates GAM, kernel, robust and quantile approaches.

## Recommended reading order

1.  `v01-foundations-to-advanced-tutorial.Rmd`
2.  `v02-diagnostics-influence.Rmd`
3.  `v03-collinearity-vif-condition.Rmd`
4.  `v04-selection-stability.Rmd`
5.  `v05-regularization.Rmd`
6.  `v06-bootstrap-resampling.Rmd`
7.  `v07-importance-effects-shap.Rmd`
8.  `v08-flexible-alternatives.Rmd`
9.  `v09-validation-comparison.Rmd`
10. `v10-soils-case-study.Rmd`
11. `v11-plant-science-case-study.Rmd`
12. `v12-reporting-audit.Rmd`

The tutorials intentionally repeat the **workflow logic**, but avoid
repeating whole sections of methodological discussion. Each vignette has
a distinct teaching responsibility.
