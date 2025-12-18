# R/analysis.R
# Statistical analysis and modeling functions

#' Perform STL decomposition with fallback
#' @param ts_data Time series object
#' @param sales_weekly Associated dataframe with dates
#' @return Tibble with original, trend, seasonal, and residual components
perform_decomposition <- function(ts_data, sales_weekly) {
    stl_fit <- safe(stl(ts_data, s.window = "periodic"))

    if (is.null(stl_fit)) {
        message("STL decomposition failed, using simple decomposition...")
        trend <- rep(mean(ts_data), length(ts_data))
        seasonal <- rep(0, length(ts_data))
        remainder <- ts_data - trend
    } else {
        trend <- stl_fit$time.series[, "trend"]
        seasonal <- stl_fit$time.series[, "seasonal"]
        remainder <- stl_fit$time.series[, "remainder"]
    }

    tibble::tibble(
        date = sales_weekly$date,
        original = as.numeric(ts_data),
        trend = as.numeric(trend),
        seasonal = as.numeric(seasonal),
        residual = as.numeric(remainder)
    )
}

#' Detect change points and anomalies
#' @param decomp_df Decomposition dataframe
#' @return List containing change points and anomalies indices
detect_anomalies <- function(decomp_df) {
    # Change points
    change_points <- safe(
        {
            cp <- changepoint::cpt.meanvar(decomp_df$residual, method = "PELT")
            as.integer(changepoint::cpts(cp))
        },
        default = integer()
    )

    # Anomaly detection using IQR method
    anomaly_threshold <- 1.5 * IQR(decomp_df$residual, na.rm = TRUE)
    anomalies <- which(abs(decomp_df$residual) > anomaly_threshold)

    list(
        change_points = change_points,
        anomalies = anomalies,
        threshold = anomaly_threshold
    )
}

#' Multi-step forecasting function with fallback
#' @param ts_data Time series object
#' @param h Forecast horizon
#' @return Forecast object or simple fallback list
fit_forecast_model <- function(ts_data, h = 12) {
    arima_fit <- safe(
        {
            forecast::auto.arima(ts_data, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
        },
        default = NULL
    )

    if (!is.null(arima_fit)) {
        message(sprintf("ARIMA model: %s", arima_fit$arma))
        forecast::forecast(arima_fit, h = h)
    } else {
        message("ARIMA fitting failed, using simple forecast...")
        list(
            mean = rep(mean(ts_data), h),
            lower = matrix(rep(mean(ts_data) - sd(ts_data), h), ncol = 1),
            upper = matrix(rep(mean(ts_data) + sd(ts_data), h), ncol = 1),
            model = NULL
        )
    }
}

#' Run statistical diagnostic tests
#' @param ts_data Time series object
#' @param residuals Residuals from decomposition
#' @return List of test results
calculate_diagnostics <- function(ts_data, residuals) {
    list(
        ljung_box = stats::Box.test(residuals, type = "Ljung-Box", lag = 10),
        adf = tseries::adf.test(ts_data),
        kpss = tseries::kpss.test(ts_data)
    )
}
