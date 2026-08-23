test_that("core OLS workflow records scientific goal and backend arguments", {
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ soil_pH + organic_matter_pct +
                  available_P_mg_dm3 + season_rain_mm,
                d, goal = "explanation")
  expect_s3_class(fit, "mr_fit")
  expect_identical(fit$goal, "explanation")
  expect_identical(fit$engine, "ols")
  expect_true(is.list(fit$backend_args))
  expect_true(is.numeric(coef(fit)))
  expect_length(predict(fit, d[1:5, ]), 5)
})

test_that("diagnostics include rank, heteroscedasticity and specification", {
  d <- mr_example_data("plant_growth")
  fit <- mr_fit(biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
                  stomatal_conductance, d)
  dg <- mr_diagnose(fit)
  expect_true(all(c("fit", "rank", "residuals", "heteroscedasticity",
                    "specification", "influence") %in% names(dg)))
  expect_true(is.finite(dg$fit["R2"]))
  expect_true(is.finite(dg$specification["p.value"]))
})

test_that("influence flags are transparent and row aligned", {
  d <- mr_example_data("plant_growth")
  fit <- mr_fit(biomass_g ~ leaf_area_cm2 + chlorophyll_spad + leaf_N_pct +
                  stomatal_conductance, d)
  inf <- mr_influence(fit)
  expect_equal(nrow(inf), fit$n)
  expect_true(all(c("flag_leverage", "flag_cook", "flag_dffits",
                    "flag_dfbeta") %in% names(inf)))
  expect_true(all(vapply(inf[c("flag_leverage", "flag_cook", "flag_dffits",
                               "flag_dfbeta")], is.logical, logical(1))))
})

test_that("collinearity detects designed redundancy", {
  d <- mr_example_data("agronomy_collinear")
  fit <- mr_fit(yield_t_ha ~ ., d)
  co <- mr_collinearity(fit)
  expect_true(max(co$VIF$VIF, na.rm = TRUE) > 5)
  expect_true(any(co$VIF$flag_vif5))
  expect_true(nrow(co$correlations) > 0)
  expect_true(all(c("dimension", "condition_index") %in% names(co$condition_index)))
})

test_that("capability table covers integrated workflow", {
  z <- mr_capabilities()
  expect_true(nrow(z) >= 18)
  expect_true(all(c("module", "backend", "package", "available") %in% names(z)))
  expect_true(any(z$module == "cross-engine validation"))
})
