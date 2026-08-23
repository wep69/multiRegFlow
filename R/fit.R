#' Fit a guided multiple-regression model
#'
#' Fits an ordinary least-squares reference model by default and records the
#' scientific goal so downstream functions can distinguish explanation from
#' prediction. Specialized engines are optional and use established backends.
#'
#' @param formula Model formula.
#' @param data A data frame.
#' @param goal Either "explanation" or "prediction".
#' @param engine One of "ols", "robust", "quantile", "kernel", or "gam".
#' @param tau Quantile used when `engine = "quantile"`.
#' @param ... Additional arguments passed to the selected backend.
#' @return An object of class `mr_fit`.
#' @export
mr_fit <- function(formula, data, goal = c("explanation", "prediction"),
                   engine = c("ols", "robust", "quantile", "kernel", "gam"),
                   tau = 0.5, ...) {
  goal <- match.arg(goal)
  engine <- match.arg(engine)
  if (!inherits(formula, "formula")) stop("`formula` must be a formula.", call. = FALSE)
  if (!is.data.frame(data)) stop("`data` must be a data frame.", call. = FALSE)

  response <- all.vars(formula)[1L]
  if (!response %in% names(data)) {
    stop("The response variable was not found in `data`.", call. = FALSE)
  }
  if (!is.numeric(data[[response]])) {
    stop("multiRegFlow currently supports numeric responses.", call. = FALSE)
  }
  if (engine == "quantile" && (any(!is.finite(tau)) || any(tau <= 0 | tau >= 1))) {
    stop("`tau` must contain quantiles strictly between 0 and 1.", call. = FALSE)
  }

  backend_args <- list(...)
  d_fit <- data
  f_fit <- formula
  environment(f_fit) <- environment()

  model <- switch(
    engine,
    ols = do.call(stats::lm, c(list(formula = f_fit, data = d_fit), backend_args)),
    robust = {
      .mr_require("robustbase", "for robust regression")
      do.call(robustbase::lmrob, c(list(formula = f_fit, data = d_fit), backend_args))
    },
    quantile = {
      .mr_require("quantreg", "for quantile regression")
      do.call(quantreg::rq,
              c(list(formula = f_fit, data = d_fit, tau = tau), backend_args))
    },
    kernel = {
      .mr_require("np", "for kernel regression")
      bw <- do.call(np::npregbw,
                    c(list(formula = f_fit, data = d_fit), backend_args))
      np::npreg(bws = bw)
    },
    gam = {
      .mr_require("mgcv", "for generalized additive models")
      env_gam <- new.env(parent = environment(f_fit))
      env_gam$s <- mgcv::s
      env_gam$te <- mgcv::te
      env_gam$ti <- mgcv::ti
      env_gam$t2 <- mgcv::t2
      environment(f_fit) <- env_gam
      do.call(mgcv::gam,
              c(list(formula = f_fit, data = d_fit), backend_args))
    }
  )

  n_fit <- tryCatch(stats::nobs(model), error = function(e) NA_integer_)
  if (length(n_fit) == 0L || is.na(n_fit)) {
    vars <- intersect(all.vars(formula), names(data))
    n_fit <- if (length(vars)) {
      sum(stats::complete.cases(data[, vars, drop = FALSE]))
    } else nrow(data)
  }
  predictors <- tryCatch(attr(stats::terms(model), "term.labels"),
                         error = function(e) NULL)
  if (is.null(predictors) || length(predictors) == 0L) {
    predictors <- setdiff(all.vars(formula), response)
  }

  out <- list(
    call = match.call(), formula = formula, data = data, goal = goal,
    engine = engine, model = model, tau = tau, backend_args = backend_args,
    n = n_fit, response = response, predictors = predictors
  )
  class(out) <- "mr_fit"
  out
}

#' @export
print.mr_fit <- function(x, ...) {
  cat("multiRegFlow model\n")
  cat(" Engine:", x$engine, "\n")
  cat(" Goal:", x$goal, "\n")
  cat(" Formula:", paste(deparse(x$formula), collapse = " "), "\n")
  cat(" Complete observations:", x$n, "\n")
  invisible(x)
}

#' @export
summary.mr_fit <- function(object, ...) {
  .mr_assert_fit(object)
  s <- summary(object$model, ...)
  attr(s, "multiRegFlow_goal") <- object$goal
  s
}

#' @export
coef.mr_fit <- function(object, ...) {
  .mr_assert_fit(object)
  stats::coef(object$model, ...)
}

#' @export
predict.mr_fit <- function(object, newdata = NULL, ...) {
  .mr_assert_fit(object)
  if (is.null(newdata)) newdata <- object$data
  .mr_engine_predict(object, newdata = newdata, ...)
}

#' @export
plot.mr_fit <- function(x, ...) {
  .mr_assert_fit(x)
  graphics::plot(x$model, ...)
  invisible(x)
}
