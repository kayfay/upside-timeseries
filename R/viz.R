# R/viz.R
# Visualization functions and themes

#' Editorial-style ggplot theme
#' @param base_size Base font size
#' @param base_family Base font family
theme_editorial <- function(base_size = 12, base_family = "sans") {
    editorial_colors <- list(
        background = "#FDFBF7",
        text_dark = "#2C2416",
        text_medium = "#5C4E37"
    )

    ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
        ggplot2::theme(
            plot.background = ggplot2::element_rect(fill = editorial_colors$background, color = NA),
            panel.background = ggplot2::element_rect(fill = editorial_colors$background, color = NA),
            text = ggplot2::element_text(color = editorial_colors$text_dark),
            plot.title = ggplot2::element_text(face = "bold", size = base_size * 1.5, margin = ggplot2::margin(b = 10)),
            plot.subtitle = ggplot2::element_text(color = editorial_colors$text_medium, margin = ggplot2::margin(b = 20)),
            legend.position = "bottom"
        )
}

#' Create TL;DR dashboard plot
#' @param decomp_df Decomposition dataframe
#' @return ggplot object
plot_tldr <- function(decomp_df) {
    ggplot2::ggplot(decomp_df, ggplot2::aes(x = date)) +
        ggplot2::geom_line(ggplot2::aes(y = original, color = "Original"), alpha = 0.7) +
        ggplot2::geom_line(ggplot2::aes(y = trend, color = "Trend"), linewidth = 1.2) +
        ggplot2::geom_line(ggplot2::aes(y = trend + seasonal, color = "Trend + Seasonal"), linewidth = 1) +
        ggplot2::scale_color_manual(values = c("Original" = "blue", "Trend" = "green", "Trend + Seasonal" = "red")) +
        ggplot2::labs(
            title = "TL;DR: Original vs Trend vs Seasonal",
            x = "Date", y = "Sales ($)", color = "Component"
        ) +
        theme_editorial()
}

#' Create forecast plot
#' @param decomp_df Decomposition dataframe
#' @param forecast_res Forecast result object
#' @return ggplot object
plot_forecast <- function(decomp_df, forecast_res) {
    forecast_dates <- seq(max(decomp_df$date) + 7, by = "week", length.out = length(forecast_res$mean))
    forecast_df <- data.frame(
        date = forecast_dates,
        forecast = as.numeric(forecast_res$mean),
        lower_80 = if (is.matrix(forecast_res$lower)) forecast_res$lower[, 1] else forecast_res$lower,
        upper_80 = if (is.matrix(forecast_res$upper)) forecast_res$upper[, 1] else forecast_res$upper
    )

    ggplot2::ggplot() +
        ggplot2::geom_line(data = decomp_df, ggplot2::aes(x = date, y = original), alpha = 0.7) +
        ggplot2::geom_line(data = forecast_df, ggplot2::aes(x = date, y = forecast), color = "red", linewidth = 1.2) +
        ggplot2::geom_ribbon(
            data = forecast_df, ggplot2::aes(x = date, ymin = lower_80, ymax = upper_80),
            alpha = 0.3, fill = "red"
        ) +
        ggplot2::labs(
            title = "ARIMA Forecast (80% Prediction Interval)",
            x = "Date", y = "Sales ($)"
        ) +
        theme_editorial()
}

#' Generate markdown report content
#' @param audit Data audit list
#' @param model_info Model info string
#' @param anomaly_count Number of anomalies
#' @param cp_count Number of change points
#' @param stats List of statistical test results
#' @return Markdown string
generate_report_markdown <- function(audit, model_info, anomaly_count, cp_count, stats) {
    paste0(
        "# Scientific Time Series Analysis Report\n\n",
        "## Data Summary\n",
        "- **Number of weeks:** ", audit$num_weeks, "\n",
        "- **Date range:** ", audit$start_date, " to ", audit$end_date, "\n",
        "- **Missing values:** ", audit$missing_values, "\n",
        "- **Duplicates:** ", audit$num_duplicates, "\n\n",
        "## Model Results\n",
        "- **ARIMA model:** ", model_info, "\n",
        "- **Change points detected:** ", cp_count, "\n",
        "- **Anomalies detected:** ", anomaly_count, "\n\n",
        "## Statistical Tests\n",
        "- **Ljung-Box test p-value:** ", round(stats$ljung_box$p.value, 4), "\n",
        "- **ADF test p-value:** ", round(stats$adf$p.value, 4), "\n",
        "- **KPSS test p-value:** ", round(stats$kpss$p.value, 4), "\n\n",
        "## Key Insights\n",
        "- The time series shows ", ifelse(stats$adf$p.value < 0.05, "stationary", "non-stationary"), " behavior\n",
        "- ", anomaly_count, " anomalies were detected using the IQR method\n",
        "- ", cp_count, " structural change points were identified\n"
    )
}
