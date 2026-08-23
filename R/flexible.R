#' Quantile regression sensitivity analysis
#'
#' Fits the same scientific specification at one or more conditional quantiles.
#' This is useful when associations differ between low-response, median and
#' high-response conditions rather than only at the conditional mean.
#'
#' @param x An OLS `mr_fit` object used for formula and data.
#' @param tau Numeric vector of quantiles strictly between zero and one.
#' @param ... Additional arguments passed to `quantreg::rq()`.
#' @return An `mr_quantile` object.
#' @export
mr_quantile <- function(x, tau = c(0.1, 0.25, 0.5, 0.75, 0.9), ...) {
  .mr_assert_fit(x)
  .mr_require("quantreg", "for quantile regression")
  if (any(!is.finite(tau)) || any(tau <= 0 | tau >= 1)) {
    stop("`tau` must contain quantiles strictly between 0 and 1.", call. = FALSE)
  }
  fit <- quantreg::rq(x$formula, data = x$data, tau = tau, ...)
  structure(list(model = fit, tau = tau, formula = x$formula, data = x$data),
            class = "mr_quantile")
}

#' Kernel regression sensitivity analysis
#'
#' Uses data-driven bandwidth selection from package `np`. It is intended for
#' genuine nonlinear conditional-mean exploration, particularly when the
#' functional form is uncertain. It should not automatically replace a
#' scientifically interpretable linear model.
#'
#' @param x An OLS `mr_fit` object used for formula and data.
#' @param ... Additional arguments passed to `np::npregbw()`.
#' @return An `mr_kernel` object.
#' @export
mr_kernel <- function(x, ...) {
  .mr_assert_fit(x)
  .mr_require("np", "for kernel regression")
  d_np <- x$data
  f_np <- x$formula
  environment(f_np) <- environment()
  bw <- np::npregbw(formula = f_np, data = d_np, ...)
  fit <- np::npreg(bws = bw)
  structure(list(model = fit, bandwidth = bw, formula = x$formula, data = x$data),
            class = "mr_kernel")
}

#' @export
print.mr_quantile <- function(x, ...) {
  cat("multiRegFlow quantile sensitivity analysis\n Tau:",
      paste(x$tau, collapse = ", "), "\n")
  invisible(x)
}

#' @export
print.mr_kernel <- function(x, ...) {
  cat("multiRegFlow kernel regression sensitivity analysis\n")
  print(x$bandwidth)
  invisible(x)
}
