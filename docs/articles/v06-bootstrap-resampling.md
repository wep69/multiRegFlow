# Bootstrap uncertainty and resampling for multiple regression

## Why resample?

Bootstrap procedures approximate repeated sampling by generating many
datasets from the observed data or fitted residual structure. They are
useful for coefficient uncertainty, sign stability and sensitivity
analyses, but the resampling unit must respect the experimental or
sampling design.

The current bootstrap implementation targets independent observational
units in OLS models. Clustered, repeated-measures or spatial experiments
require a resampling scheme aligned with those units and should not be
reduced to naive row resampling.

## Example 1: pairs bootstrap in a soil model

``` r

soil <- mr_example_data("soil_fertility")
fit <- mr_fit(
  yield_t_ha ~ soil_pH + organic_matter_pct + available_P_mg_dm3 +
    exchangeable_K_mg_dm3 + season_rain_mm,
  soil
)
b_pairs <- mr_bootstrap(fit, R = 250, type = "pairs", seed = 11)
b_pairs$intervals
#>                              lower       median       upper
#> (Intercept)            0.955681981  2.116548525 3.369682653
#> soil_pH               -0.182089128 -0.029446744 0.130857824
#> organic_matter_pct     0.063501777  0.154780726 0.267098753
#> available_P_mg_dm3     0.019397741  0.027551894 0.035897816
#> exchangeable_K_mg_dm3  0.004483584  0.006809163 0.009294962
#> season_rain_mm         0.002177953  0.003229118 0.004338143
b_pairs$sign_stability
#>           (Intercept)               soil_pH    organic_matter_pct 
#>                 1.000                 0.632                 0.992 
#>    available_P_mg_dm3 exchangeable_K_mg_dm3        season_rain_mm 
#>                 1.000                 1.000                 1.000
```

Pairs bootstrap resamples entire rows. It is a natural default for
independent observational data because both response and predictor
combinations are resampled.

## Example 2: residual bootstrap

``` r

b_resid <- mr_bootstrap(fit, R = 250, type = "residual", seed = 11)
b_resid$intervals
#>                              lower       median       upper
#> (Intercept)            1.111566601  2.149849707 3.121849004
#> soil_pH               -0.162865100 -0.029433293 0.106683085
#> organic_matter_pct     0.042316486  0.157817466 0.255531822
#> available_P_mg_dm3     0.019223330  0.027994069 0.037261333
#> exchangeable_K_mg_dm3  0.004561938  0.007039042 0.009352832
#> season_rain_mm         0.002328562  0.003175029 0.003922714
```

Residual bootstrap retains the observed design matrix and resamples
residuals. It is most defensible when the fitted mean is adequate and
residuals are approximately exchangeable with constant variance.

## Example 3: wild bootstrap under heteroscedasticity

``` r

het <- mr_example_data("agronomy_heteroskedastic")
fit_het <- mr_fit(
  grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha + soil_water_m3_m3,
  het
)
mr_diagnose(fit_het)$heteroscedasticity
#>    statistic           df      p.value 
#> 11.814804618  3.000000000  0.008045251
b_wild <- mr_bootstrap(fit_het, R = 250, type = "wild", seed = 12)
b_wild$intervals
#>                        lower     median      upper
#> (Intercept)      1.666473711 3.07470034 4.61178783
#> N_rate_kg_ha     0.021152592 0.02984808 0.03783170
#> P_rate_kg_ha     0.006797716 0.02628827 0.04611516
#> soil_water_m3_m3 1.253031705 4.82255179 9.23919942
```

The Rademacher wild bootstrap multiplies residuals by random signs. It
preserves heteroscedastic residual magnitudes more naturally than
ordinary residual resampling.

## Interval types

`multiRegFlow` provides percentile, basic and normal bootstrap
summaries.

``` r

b_pct <- mr_bootstrap(fit, R = 200, type = "pairs",
                      interval = "percentile", seed = 13)
b_basic <- mr_bootstrap(fit, R = 200, type = "pairs",
                        interval = "basic", seed = 13)
b_norm <- mr_bootstrap(fit, R = 200, type = "pairs",
                       interval = "normal", seed = 13)
```

``` r

cbind(
  percentile = b_pct$intervals["available_P_mg_dm3", c("lower", "upper")],
  basic = b_basic$intervals["available_P_mg_dm3", c("lower", "upper")],
  normal = b_norm$intervals["available_P_mg_dm3", c("lower", "upper")]
)
#>       percentile      basic     normal
#> lower 0.02010259 0.02059257 0.01978676
#> upper 0.03580454 0.03629452 0.03623561
```

The intervals answer similar but not identical questions. Percentile
intervals are easy to interpret but can perform poorly in some biased or
skewed settings. The basic interval reflects the bootstrap error around
the original estimate. The normal interval is compact but relies more
strongly on approximate symmetry. For advanced applications, specialized
bootstrap packages may provide BCa or design-specific resampling that is
preferable.

## Sign stability

``` r

sort(b_pairs$sign_stability)
#>               soil_pH    organic_matter_pct           (Intercept) 
#>                 0.632                 0.992                 1.000 
#>    available_P_mg_dm3 exchangeable_K_mg_dm3        season_rain_mm 
#>                 1.000                 1.000                 1.000
```

A coefficient that changes sign in many resamples deserves a different
interpretation from a coefficient with a narrow distribution entirely on
one side of zero. Sign stability is descriptive evidence, not a
replacement for a confidence interval or scientific effect-size
judgment.

## Bootstrap versus HC covariance

``` r

mr_inference(fit_het, "classical")
#>               term   estimate   std_error statistic  df      p_value
#> 1      (Intercept) 3.05266424 0.768754537  3.970922 176 1.042091e-04
#> 2     N_rate_kg_ha 0.02956894 0.004509140  6.557556 176 5.865936e-10
#> 3     P_rate_kg_ha 0.02704581 0.009986986  2.708106 176 7.434635e-03
#> 4 soil_water_m3_m3 4.82261205 2.157881155  2.234883 176 2.668304e-02
#>      conf_low  conf_high covariance clusters
#> 1 1.535500728 4.56982776  classical       NA
#> 2 0.020669995 0.03846788  classical       NA
#> 3 0.007336151 0.04675547  classical       NA
#> 4 0.563959388 9.08126472  classical       NA
mr_inference(fit_het, "HC3")
#>               term   estimate   std_error statistic  df      p_value
#> 1      (Intercept) 3.05266424 0.711992495  4.287495 176 2.972332e-05
#> 2     N_rate_kg_ha 0.02956894 0.004400595  6.719304 176 2.439879e-10
#> 3     P_rate_kg_ha 0.02704581 0.010447586  2.588714 176 1.043899e-02
#> 4 soil_water_m3_m3 4.82261205 2.117699423  2.277288 176 2.397224e-02
#>      conf_low  conf_high covariance clusters
#> 1 1.647522570 4.45780592        HC3       NA
#> 2 0.020884212 0.03825366        HC3       NA
#> 3 0.006427141 0.04766448        HC3       NA
#> 4 0.643259419 9.00196469        HC3       NA
```

``` r

b_wild$intervals
#>                        lower     median      upper
#> (Intercept)      1.666473711 3.07470034 4.61178783
#> N_rate_kg_ha     0.021152592 0.02984808 0.03783170
#> P_rate_kg_ha     0.006797716 0.02628827 0.04611516
#> soil_water_m3_m3 1.253031705 4.82255179 9.23919942
```

HC covariance and wild bootstrap attack the same heteroscedasticity
problem from different directions. Agreement between them can strengthen
confidence that a conclusion is not an artifact of the classical
constant-variance standard error. Disagreement should be investigated
rather than hidden.

## Plant-science resampling example

``` r

plant <- mr_example_data("plant_growth")
fit_plant <- mr_fit(
  biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
    stomatal_conductance + plant_height_cm + root_mass_g,
  plant
)
b_plant <- mr_bootstrap(fit_plant, R = 200, type = "pairs", seed = 14)
b_plant$intervals
#>                             lower     median       upper
#> (Intercept)          -1.753848421 1.19877305  4.03500038
#> leaf_area_cm2         0.120407883 0.14613922  0.17661359
#> chlorophyll_spad      0.140564773 0.17510497  0.20916507
#> leaf_N_pct            1.057597026 1.47820873  1.96306227
#> stomatal_conductance  5.400664703 8.41241598 10.71268778
#> plant_height_cm       0.007350874 0.02553143  0.04495065
#> root_mass_g           0.040050134 0.09341340  0.14264403
```

## Choosing the number of replicates

Small values of `R` are useful for teaching and automated examples.
Final scientific analyses should use enough replicates that reported
intervals and stability summaries do not change materially when the
bootstrap is rerun with a different seed. Values in the thousands are
common, but the required number depends on the precision needed and
computational cost.

## Reproducibility

Always record the bootstrap type, resampling unit, number of replicates,
confidence level, interval type and random seed. If exclusions or
transformations are applied before resampling, document those decisions
independently of the bootstrap results.
