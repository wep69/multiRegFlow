#' Compare fitted models without mixing inference and prediction
#'
#' Inferential fit summaries and out-of-sample predictive summaries are kept in
#' separate tables. Predictive validation is attempted for every supported
#' `mr_fit` engine rather than comparing training-set fit measures.
#'
#' @param ... `mr_fit` objects.
#' @param validation If TRUE, repeated cross-validation is added.
#' @param v Number of folds.
#' @param repeats Number of repetitions.
#' @param seed Random seed.
#' @return A list with inferential-fit and predictive-performance tables.
#' @export
mr_compare <- function(..., validation = TRUE, v = 10, repeats = 3, seed = 123) {
  xs <- list(...)
  if (length(xs) < 2L) stop("Supply at least two mr_fit objects.", call. = FALSE)
  invisible(lapply(xs, .mr_assert_fit))
  nms <- names(xs)
  if (is.null(nms) || any(nms == "")) nms <- paste0("model", seq_along(xs))

  infer <- lapply(seq_along(xs), function(i) {
    z <- xs[[i]]
    AICv <- tryCatch(stats::AIC(z$model), error = function(e) NA_real_)
    BICv <- tryCatch(stats::BIC(z$model), error = function(e) NA_real_)
    R2 <- adj <- NA_real_
    if (z$engine == "ols") {
      sm <- summary(z$model)
      R2 <- sm$r.squared
      adj <- sm$adj.r.squared
    } else if (z$engine == "gam") {
      sm <- summary(z$model)
      R2 <- if (!is.null(sm$r.sq)) sm$r.sq else NA_real_
      adj <- if (!is.null(sm$dev.expl)) sm$dev.expl else NA_real_
    }
    data.frame(model = nms[i], engine = z$engine,
               AIC = AICv, BIC = BICv, R2_or_gam_R2 = R2,
               adjusted_R2_or_deviance_explained = adj)
  })

  pred <- NULL
  if (validation) {
    pred_list <- lapply(seq_along(xs), function(i) {
      z <- xs[[i]]
      vv <- tryCatch(mr_validate(z, v = v, repeats = repeats, seed = seed),
                     error = function(e) e)
      if (inherits(vv, "error")) {
        return(data.frame(model = nms[i], engine = z$engine,
                          metric = "validation_error", mean = NA_real_, sd = NA_real_,
                          note = conditionMessage(vv)))
      }
      out <- vv$summary
      out$model <- nms[i]
      out$engine <- z$engine
      out$note <- NA_character_
      out[, c("model", "engine", "metric", "mean", "sd", "note")]
    })
    pred <- do.call(rbind, pred_list)
    rownames(pred) <- NULL
  }
  list(
    inference = do.call(rbind, infer),
    prediction = pred,
    note = paste("AIC/BIC and in-sample fit describe fitted models; predictive",
                 "metrics are computed from out-of-fold predictions and are",
                 "reported separately.")
  )
}

#' Methodological recommendations
#'
#' Produces an auditable rule-based summary. It does not choose a model
#' automatically and never recommends deleting a variable solely because of VIF.
#'
#' @param x An OLS `mr_fit` object.
#' @return A data frame of findings and recommended sensitivity analyses.
#' @export
mr_recommend <- function(x) {
  .mr_assert_fit(x)
  if (x$engine != "ols") stop("mr_recommend() currently starts from an OLS reference fit.", call. = FALSE)
  dg <- mr_diagnose(x)
  co <- mr_collinearity(x)
  maxvif <- suppressWarnings(max(co$VIF$VIF, na.rm = TRUE))
  if (!is.finite(maxvif)) maxvif <- NA_real_
  bp_p <- unname(dg$heteroscedasticity["p.value"])
  spec_p <- unname(dg$specification["p.value"])
  cookn <- unname(dg$influence["n_cook_gt_4_over_n"])
  ratio <- unname(dg$rank["n_to_effective_predictor_ratio"])
  rank_def <- isTRUE(unname(dg$rank["rank_deficient"]) == 1)
  rows <- list()
  add <- function(domain, finding, recommendation, priority) {
    rows[[length(rows) + 1L]] <<- data.frame(domain, finding, recommendation, priority,
                                             stringsAsFactors = FALSE)
  }
  if (rank_def) {
    add("rank", "The OLS design matrix is rank deficient.",
        "Identify aliased or redundant terms before interpreting individual coefficients.", "high")
  }
  if (is.finite(ratio) && ratio < 10) {
    add("information", paste0("Approximately ", round(ratio, 1), " observations per effective predictor."),
        "Treat coefficient estimates and variable selection as potentially unstable; consider shrinkage and resampling.", "medium")
  }
  if (!is.na(maxvif) && maxvif >= 5) {
    add("collinearity", paste0("Maximum VIF is ", round(maxvif, 2), "."),
        "Inspect condition indices and variance decomposition; retain scientifically required terms and compare OLS with ridge coefficient stability.", "high")
  } else {
    add("collinearity", "No strong VIF signal under the package screening rule.",
        "Still inspect correlated predictor groups when scientific redundancy is plausible.", "low")
  }
  if (!is.na(bp_p) && bp_p < 0.05) {
    add("heteroscedasticity", paste0("Breusch-Pagan screening p = ", signif(bp_p, 3), "."),
        "Keep the mean model if scientifically appropriate, but compare classical inference with HC3/HC4 and consider wild bootstrap sensitivity.", "high")
  }
  if (!is.na(spec_p) && spec_p < 0.05) {
    add("functional_form", paste0("Fitted-value-power specification screen p = ", signif(spec_p, 3), "."),
        "Inspect residual patterns and scientifically plausible nonlinear terms; compare polynomial, GAM or kernel sensitivity analyses rather than adding complexity automatically.", "high")
  }
  if (!is.na(cookn) && cookn > 0) {
    add("influence", paste(cookn, "observation(s) exceed Cook's 4/n screening value."),
        "Inspect leverage, DFFITS and DFBETAS; conduct sensitivity analysis rather than automatic deletion.", "medium")
  }
  if (x$goal == "prediction") {
    add("validation", "The declared goal is prediction.",
        "Use repeated out-of-fold validation and compare models on RMSE, MAE, out-of-fold R2 and calibration.", "high")
  } else {
    add("selection", "The declared goal is explanation/inference.",
        "Treat automated selection as exploratory; prioritize prespecified scientific terms, effect sizes and uncertainty.", "high")
  }
  do.call(rbind, rows)
}

#' Package capabilities
#'
#' @return A data frame showing methods, backends and installation status.
#' @export
mr_capabilities <- function() {
  items <- data.frame(
    module = c("OLS", "diagnostics", "influence flags", "VIF/condition indices",
               "robust covariance inference", "AIC/BIC selection", "best subsets",
               "ridge/lasso/elastic net", "stability selection", "bootstrap",
               "cross-engine validation", "robust regression", "quantile regression",
               "kernel regression", "GAM", "partial/semi-partial R2",
               "LMG importance", "SHAP", "marginal effects"),
    backend = c("stats", "multiRegFlow", "multiRegFlow", "multiRegFlow/performance",
                "sandwich", "stats", "leaps", "glmnet", "stabs+glmnet",
                "multiRegFlow", "multiRegFlow", "robustbase", "quantreg", "np",
                "mgcv", "multiRegFlow", "relaimpo", "kernelshap", "marginaleffects"),
    package = c(NA, NA, NA, "performance", "sandwich", NA, "leaps", "glmnet",
                "stabs", "", "", "robustbase", "quantreg", "np", "mgcv", "",
                "relaimpo", "kernelshap", "marginaleffects"),
    stringsAsFactors = FALSE
  )
  items$available <- vapply(items$package, function(p) {
    if (is.na(p) || p == "") TRUE else requireNamespace(p, quietly = TRUE)
  }, logical(1))
  items
}
