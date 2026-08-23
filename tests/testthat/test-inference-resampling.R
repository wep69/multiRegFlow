test_that("classical and HC inference preserve OLS coefficients", {
  skip_if_not_installed("sandwich")
  d <- mr_example_data("agronomy_heteroskedastic")
  fit <- mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                  soil_water_m3_m3, d)
  a <- mr_inference(fit, "classical")
  b <- mr_inference(fit, "HC3")
  expect_equal(a$estimate, b$estimate, tolerance = 1e-12)
  expect_false(isTRUE(all.equal(a$std_error, b$std_error)))
})

test_that("cluster inference uses cluster degrees of freedom", {
  skip_if_not_installed("sandwich")
  d <- mr_example_data("agronomy_heteroskedastic")
  d$block <- rep(seq_len(18), length.out = nrow(d))
  fit <- mr_fit(grain_yield_t_ha ~ N_rate_kg_ha + P_rate_kg_ha +
                  soil_water_m3_m3, d)
  out <- mr_inference(fit, "cluster", cluster = "block")
  expect_true(all(out$clusters == 18))
  expect_true(all(out$df == 17))
})

test_that("bootstrap interval types and replicate counts work", {
  d <- mr_example_data("soil_fertility")
  fit <- mr_fit(yield_t_ha ~ organic_matter_pct + available_P_mg_dm3 +
                  season_rain_mm, d)
  p <- mr_bootstrap(fit, R = 30, type = "pairs", interval = "percentile", seed = 1)
  b <- mr_bootstrap(fit, R = 30, type = "residual", interval = "basic", seed = 1)
  n <- mr_bootstrap(fit, R = 30, type = "wild", interval = "normal", seed = 1)
  expect_equal(nrow(p$coefficients), 30)
  expect_true(p$successful_replicates > 0)
  expect_equal(colnames(b$intervals), c("lower", "median", "upper"))
  expect_equal(colnames(n$intervals), c("lower", "median", "upper"))
})
