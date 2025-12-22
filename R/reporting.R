# R/reporting.R
# Business reporting functions

#' Generate editorial business dashboard
#' @param metrics List of calculated metrics
generate_business_dashboard <- function(metrics) {
    # Helper for formatting
    fmt_currency <- function(x) scales::dollar(x)
    fmt_pct <- function(x) scales::percent(x, accuracy = 0.1)

    # Create metrics dataframe
    business_metrics <- data.frame(
        metric = c("Total Weeks", "Avg Weekly Sales", "Growth Trend", "Seasonal Strength", "Volatility (CV)", "Stationarity"),
        value = c(
            as.character(metrics$total_weeks),
            fmt_currency(metrics$avg_sales),
            fmt_currency(metrics$growth_rate),
            fmt_pct(metrics$seasonal_strength),
            fmt_pct(metrics$volatility),
            ifelse(metrics$is_stationary, "Yes", "No")
        ),
        importance = c("Medium", "High", "High", "High", "Medium", "Low"),
        category = c("Scale", "Scale", "Momentum", "Pattern", "Risk", "Risk")
    )

    # For simplicity, we reuse the code structure from the original script but wrapped in functions
    # Note: Ideally, specific plotting logic would be in viz.R, but since this is a highly specific
    # "infographic" style plot, we keep it here or move it to viz.R.
    # For this refactor, I will implement a simplified version that relies on viz.R's theme but
    # constructs the specific plot here.

    # Editorial colors (reused from viz.R concept)
    editorial_colors <- list(
        high_primary = "#8B4513",
        medium = "#6B8E6B",
        low = "#D3D3D3",
        background = "#FDFBF7",
        text_dark = "#2C2416"
    )

    p <- ggplot2::ggplot(business_metrics, ggplot2::aes(x = reorder(metric, desc(importance)))) +
        ggplot2::geom_col(ggplot2::aes(y = 1, fill = importance), alpha = 0.2, width = 0.6) +
        ggplot2::geom_text(ggplot2::aes(label = metric, y = 0.5),
            hjust = 0, nudge_x = 0.35,
            color = editorial_colors$text_dark, size = 5, fontface = "bold"
        ) +
        ggplot2::geom_text(ggplot2::aes(label = value, y = 0.5),
            hjust = 1, nudge_x = 0.35,
            color = editorial_colors$high_primary, size = 6, fontface = "bold"
        ) +
        ggplot2::scale_fill_manual(values = c(
            "High" = editorial_colors$high_primary,
            "Medium" = editorial_colors$medium,
            "Low" = editorial_colors$low
        )) +
        ggplot2::labs(
            title = "Business Performance Metrics",
            subtitle = "Key indicators derived from sales analysis"
        ) +
        ggplot2::coord_flip() +
        ggplot2::theme_void() +
        ggplot2::theme(
            plot.background = ggplot2::element_rect(fill = editorial_colors$background, color = NA),
            plot.title = ggplot2::element_text(size = 20, face = "bold", margin = ggplot2::margin(20, 0, 10, 20)),
            plot.subtitle = ggplot2::element_text(size = 12, color = "#5C4E37", margin = ggplot2::margin(0, 0, 20, 20)),
            legend.position = "none"
        )

    ggplot2::ggsave("07_enhanced_business_insights_summary.png", p, width = 10, height = 6)
}

#' Export dashboard data to JSON
#' @param metrics List of calculated metrics
#' @param sales_weekly Dataframe with weekly sales
#' @param output_path Path to save JSON file
export_dashboard_json <- function(metrics, sales_weekly, output_path = "dashboard_data.json") {
    # Structure data for the frontend
    payload <- list(
        metadata = list(
            generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            version = "1.0.0"
        ),
        metrics = list(
            total_weeks = metrics$total_weeks,
            avg_sales = metrics$avg_sales,
            growth_rate = metrics$growth_rate,
            seasonal_strength = metrics$seasonal_strength,
            volatility = metrics$volatility,
            is_stationary = metrics$is_stationary,
            monthly_insights = metrics$monthly_insights
        ),
        time_series = sales_weekly %>%
            dplyr::mutate(date = as.character(date)) %>%
            dplyr::select(date, value)
    )

    if (!requireNamespace("jsonlite", quietly = TRUE)) {
        warning("jsonlite package is missing. Installing...")
        utils::install.packages("jsonlite", repos = "https://cloud.r-project.org")
    }

    jsonlite::write_json(payload, output_path, pretty = TRUE, auto_unbox = TRUE)
    message(sprintf("Dashboard data exported to %s", output_path))
}
