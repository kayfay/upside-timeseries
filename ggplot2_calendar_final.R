# Professional Calendar Visualization with ggplot2 and tidyverse
# Modern, clean design using best practices

# Load required libraries
library(readxl)
library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyr)
library(purrr)
library(gridExtra)
library(RColorBrewer)

# Read the existing data
cat("Loading existing analysis data...\n")
if (file.exists("seasonal_peak_analysis.rds")) {
  analysis_data <- readRDS("seasonal_peak_analysis.rds")
  clean_data <- analysis_data$clean_data
  seasonal_stats <- analysis_data$seasonal_stats
  peak_analysis <- analysis_data$peak_analysis
  cat("✓ Loaded existing analysis data\n")
} else {
  cat("No existing analysis found. Please run the main analysis first.\n")
  stop("Run seasonal_peak_analysis.R first")
}

# Function to create calendar data frame for a specific month
create_calendar_data <- function(month = 4, year = 2024) {
  # Get the first day of the month
  first_day <- as.Date(paste(year, month, "01", sep = "-"))
  days_in_month <- days_in_month(first_day)
  start_weekday <- wday(first_day)
  
  # Create calendar grid
  calendar_data <- tibble(
    day = 1:days_in_month,
    weekday = ((day + start_weekday - 2) %% 7) + 1,
    week = ceiling((day + start_weekday - 1) / 7),
    month = month,
    year = year
  )
  
  return(calendar_data)
}

# Function to create professional single month calendar with ggplot2
create_ggplot_month_calendar <- function(peak_analysis, month = 4, year = 2024) {
  cat("Creating ggplot2 calendar for", month.name[month], year, "...\n")
  
  # Get peak weeks data for the specific month
  if (nrow(peak_analysis$consistent_peaks) == 0) {
    peak_weeks <- peak_analysis$peak_weeks %>%
      filter(lubridate::month(date) == month) %>%
      mutate(
        day_of_month = lubridate::day(date),
        sales_formatted = format(round(sales), big.mark = ",")
      )
  } else {
    peak_weeks <- peak_analysis$consistent_peaks %>%
      mutate(
        approx_date = as.Date(paste0(year, "-01-01")) + (week_of_year - 1) * 7,
        month = lubridate::month(approx_date),
        day_of_month = lubridate::day(approx_date),
        sales_formatted = format(round(avg_peak_sales), big.mark = ",")
      ) %>%
      filter(month == month)
  }
  
  # Create calendar data
  calendar_data <- create_calendar_data(month, year) %>%
    mutate(
      is_peak = day %in% peak_weeks$day_of_month,
      peak_info = if_else(is_peak, 
                         paste("$", peak_weeks$sales_formatted[match(day, peak_weeks$day_of_month)]), 
                         "")
    )
  
  # Create the plot
  p <- ggplot(calendar_data, aes(x = weekday, y = week)) +
    # Calendar grid
    geom_tile(aes(fill = is_peak), color = "#dee2e6", linewidth = 0.5) +
    # Day numbers
    geom_text(aes(label = day), 
              color = ifelse(calendar_data$is_peak, "white", "#495057"),
              size = 8, fontface = "bold") +
    # Peak week indicators
    geom_text(data = filter(calendar_data, is_peak),
              aes(label = "★"), 
              color = "white", size = 4, vjust = -1.5) +
    # Scale and colors
    scale_fill_manual(values = c("FALSE" = "#f8f9fa", "TRUE" = "#e74c3c")) +
    scale_x_continuous(breaks = 1:7, 
                      labels = c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"),
                      position = "top") +
    scale_y_reverse() +
    # Theme and styling
    labs(title = paste(month.name[month], year, "Sales Calendar"),
         subtitle = paste("Peak weeks highlighted in red"),
         x = NULL, y = NULL) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 24, face = "bold", color = "#2c3e50", hjust = 0.5),
      plot.subtitle = element_text(size = 16, color = "#6c757d", hjust = 0.5),
      axis.text.x = element_text(size = 14, face = "bold", color = "#495057"),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      legend.position = "none",
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
  # Save the plot
  ggsave(paste0("25_", tolower(month.name[month]), "_", year, "_ggplot.png"), 
         p, width = 12, height = 9, dpi = 300, bg = "white")
  
  cat("✓ Created", month.name[month], "ggplot2: 25_", tolower(month.name[month]), "_", year, "_ggplot.png\n")
}

# Function to create professional 12-month grid with ggplot2
create_ggplot_12month_grid <- function(peak_analysis, year = 2024) {
  cat("Creating ggplot2 12-month calendar grid...\n")
  
  # Get peak weeks data
  if (nrow(peak_analysis$consistent_peaks) == 0) {
    peak_weeks <- peak_analysis$peak_weeks %>%
      mutate(
        week_of_year = lubridate::week(date),
        month = lubridate::month(date),
        day_of_month = lubridate::day(date)
      )
  } else {
    peak_weeks <- peak_analysis$consistent_peaks %>%
      mutate(
        approx_date = as.Date(paste0(year, "-01-01")) + (week_of_year - 1) * 7,
        month = lubridate::month(approx_date),
        day_of_month = lubridate::day(approx_date)
      )
  }
  
  # Create calendar data for all months
  all_calendars <- map_dfr(1:12, function(m) {
    calendar_data <- create_calendar_data(m, year) %>%
      mutate(
        month_name = month.name[m],
        is_peak = day %in% filter(peak_weeks, month == m)$day_of_month
      )
  })
  
  # Create the plot
  p <- ggplot(all_calendars, aes(x = weekday, y = week)) +
    # Calendar grid
    geom_tile(aes(fill = is_peak), color = "#dee2e6", linewidth = 0.3) +
    # Day numbers
    geom_text(aes(label = day), 
              color = ifelse(all_calendars$is_peak, "white", "#495057"),
              size = 3, fontface = "bold") +
    # Facet by month
    facet_wrap(~month_name, ncol = 4, scales = "free") +
    # Scale and colors
    scale_fill_manual(values = c("FALSE" = "#f8f9fa", "TRUE" = "#e74c3c")) +
    scale_x_continuous(breaks = 1:7, 
                      labels = c("S", "M", "T", "W", "T", "F", "S")) +
    scale_y_reverse() +
    # Theme and styling
    labs(title = paste(year, "Peak Sales Weeks Calendar"),
         subtitle = "Red boxes indicate historically high sales weeks",
         x = NULL, y = NULL) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 28, face = "bold", color = "#2c3e50", hjust = 0.5),
      plot.subtitle = element_text(size = 18, color = "#6c757d", hjust = 0.5),
      axis.text.x = element_text(size = 10, face = "bold", color = "#495057"),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      legend.position = "none",
      strip.text = element_text(size = 14, face = "bold", color = "#2c3e50"),
      strip.background = element_rect(fill = "#ecf0f1", color = "#bdc3c7"),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
  # Save the plot
  ggsave("26_ggplot_12month_grid.png", p, width = 20, height = 15, dpi = 300, bg = "white")
  
  cat("✓ Created ggplot2 12-month grid: 26_ggplot_12month_grid.png\n")
}

# Function to create professional quarterly view with ggplot2
create_ggplot_quarterly_view <- function(peak_analysis, year = 2024) {
  cat("Creating ggplot2 quarterly view...\n")
  
  # Get peak weeks data
  if (nrow(peak_analysis$consistent_peaks) == 0) {
    peak_weeks <- peak_analysis$peak_weeks %>%
      mutate(
        week_of_year = lubridate::week(date),
        month = lubridate::month(date),
        day_of_month = lubridate::day(date)
      )
  } else {
    peak_weeks <- peak_analysis$consistent_peaks %>%
      mutate(
        approx_date = as.Date(paste0(year, "-01-01")) + (week_of_year - 1) * 7,
        month = lubridate::month(approx_date),
        day_of_month = lubridate::day(approx_date)
      )
  }
  
  # Define quarters
  quarters <- list(
    Q1 = c(1, 2, 3),
    Q2 = c(4, 5, 6),
    Q3 = c(7, 8, 9),
    Q4 = c(10, 11, 12)
  )
  
  # Create calendar data for quarters
  quarterly_calendars <- map_dfr(names(quarters), function(q) {
    quarter_months <- quarters[[q]]
    map_dfr(quarter_months, function(m) {
      calendar_data <- create_calendar_data(m, year) %>%
        mutate(
          quarter = q,
          month_name = month.name[m],
          is_peak = day %in% filter(peak_weeks, month == m)$day_of_month
        )
    })
  })
  
  # Create the plot
  p <- ggplot(quarterly_calendars, aes(x = weekday, y = week)) +
    # Calendar grid
    geom_tile(aes(fill = is_peak), color = "#dee2e6", linewidth = 0.5) +
    # Day numbers
    geom_text(aes(label = day), 
              color = ifelse(quarterly_calendars$is_peak, "white", "#495057"),
              size = 4, fontface = "bold") +
    # Facet by quarter
    facet_wrap(~quarter, ncol = 2, scales = "free") +
    # Scale and colors
    scale_fill_manual(values = c("FALSE" = "#f8f9fa", "TRUE" = "#e74c3c")) +
    scale_x_continuous(breaks = 1:7, 
                      labels = c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")) +
    scale_y_reverse() +
    # Theme and styling
    labs(title = paste(year, "Peak Sales Weeks - Quarterly View"),
         subtitle = "Business planning calendar with seasonal peak identification",
         x = NULL, y = NULL) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 32, face = "bold", color = "#2c3e50", hjust = 0.5),
      plot.subtitle = element_text(size = 20, color = "#6c757d", hjust = 0.5),
      axis.text.x = element_text(size = 12, face = "bold", color = "#495057"),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      panel.grid = element_blank(),
      legend.position = "none",
      strip.text = element_text(size = 18, face = "bold", color = "#2c3e50"),
      strip.background = element_rect(fill = "#ecf0f1", color = "#bdc3c7"),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
  # Save the plot
  ggsave("27_ggplot_quarterly_view.png", p, width = 24, height = 18, dpi = 300, bg = "white")
  
  cat("✓ Created ggplot2 quarterly view: 27_ggplot_quarterly_view.png\n")
}

# Function to create enhanced heatmap with ggplot2
create_ggplot_heatmap <- function(clean_data) {
  cat("Creating ggplot2 enhanced heatmap...\n")
  
  # Prepare data for heatmap
  heatmap_data <- clean_data %>%
    mutate(
      year = year(date),
      month = month(date),
      week_of_year = week(date),
      sales_category = case_when(
        sales >= quantile(sales, 0.9) ~ "Very High",
        sales >= quantile(sales, 0.75) ~ "High",
        sales >= quantile(sales, 0.5) ~ "Medium",
        sales >= quantile(sales, 0.25) ~ "Low",
        TRUE ~ "Very Low"
      )
    ) %>%
    group_by(year, week_of_year) %>%
    summarise(
      avg_sales = mean(sales, na.rm = TRUE),
      sales_category = first(sales_category),
      .groups = 'drop'
    )
  
  # Create the heatmap
  p <- ggplot(heatmap_data, aes(x = week_of_year, y = year, fill = avg_sales)) +
    geom_tile(color = "white", linewidth = 0.5) +
    scale_fill_gradient2(
      low = "#f7f7f7", 
      mid = "#ffffbf", 
      high = "#d73027",
      midpoint = median(heatmap_data$avg_sales, na.rm = TRUE),
      name = "Average Sales ($)"
    ) +
    scale_x_continuous(
      breaks = seq(1, 52, by = 4),
      labels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan")
    ) +
    labs(
      title = "Sales Heatmap by Week and Year",
      subtitle = "Darker red indicates higher sales periods",
      x = "Week of Year", 
      y = "Year"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 24, face = "bold", color = "#2c3e50", hjust = 0.5),
      plot.subtitle = element_text(size = 16, color = "#6c757d", hjust = 0.5),
      axis.text = element_text(size = 12, color = "#495057"),
      axis.title = element_text(size = 14, face = "bold", color = "#2c3e50"),
      legend.title = element_text(size = 12, face = "bold", color = "#2c3e50"),
      legend.text = element_text(size = 10, color = "#495057"),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
  # Save the plot
  ggsave("28_ggplot_enhanced_heatmap.png", p, width = 16, height = 10, dpi = 300, bg = "white")
  
  cat("✓ Created ggplot2 enhanced heatmap: 28_ggplot_enhanced_heatmap.png\n")
}

# Function to create timeline with ggplot2
create_ggplot_timeline <- function(clean_data, peak_analysis) {
  cat("Creating ggplot2 timeline...\n")
  
  # Prepare timeline data
  timeline_data <- clean_data %>%
    mutate(
      is_peak = date %in% peak_analysis$peak_weeks$date,
      peak_label = if_else(is_peak, paste("$", format(round(sales), big.mark = ",")), "")
    )
  
  # Create the timeline
  p <- ggplot(timeline_data, aes(x = date, y = sales)) +
    # Sales line
    geom_line(color = "#3498db", linewidth = 1) +
    # Peak points
    geom_point(data = filter(timeline_data, is_peak), 
               color = "#e74c3c", size = 4, shape = 16) +
    # Peak labels
    geom_text(data = filter(timeline_data, is_peak),
              aes(label = peak_label), 
              color = "#e74c3c", size = 4, vjust = -1, fontface = "bold") +
    # Scales
    scale_y_continuous(labels = scales::comma) +
    scale_x_date(date_breaks = "3 months", date_labels = "%b %Y") +
    # Labels and theme
    labs(
      title = "Sales Timeline with Peak Weeks Highlighted",
      subtitle = "Red dots indicate historically high sales weeks",
      x = "Date", 
      y = "Sales ($)"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 24, face = "bold", color = "#2c3e50", hjust = 0.5),
      plot.subtitle = element_text(size = 16, color = "#6c757d", hjust = 0.5),
      axis.text = element_text(size = 12, color = "#495057"),
      axis.title = element_text(size = 14, face = "bold", color = "#2c3e50"),
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
  
  # Save the plot
  ggsave("29_ggplot_timeline.png", p, width = 16, height = 10, dpi = 300, bg = "white")
  
  cat("✓ Created ggplot2 timeline: 29_ggplot_timeline.png\n")
}

# Run all ggplot2 visualizations
cat("=== CREATING GGPLOT2 PROFESSIONAL VISUALIZATIONS ===\n\n")

# 1. Single month calendars for peak months
create_ggplot_month_calendar(peak_analysis, 3, 2024)  # March
create_ggplot_month_calendar(peak_analysis, 4, 2024)  # April
create_ggplot_month_calendar(peak_analysis, 5, 2024)  # May

# 2. 12-month grid
create_ggplot_12month_grid(peak_analysis, 2024)

# 3. Quarterly view
create_ggplot_quarterly_view(peak_analysis, 2024)

# 4. Enhanced heatmap
create_ggplot_heatmap(clean_data)

# 5. Timeline
create_ggplot_timeline(clean_data, peak_analysis)

cat("\n=== GGPLOT2 PROFESSIONAL VISUALIZATIONS COMPLETED ===\n")
cat("✓ Generated 8 new ggplot2 professional files:\n")
cat("  - 25_march_2024_ggplot.png (March ggplot2 view)\n")
cat("  - 25_april_2024_ggplot.png (April ggplot2 view)\n")
cat("  - 25_may_2024_ggplot.png (May ggplot2 view)\n")
cat("  - 26_ggplot_12month_grid.png (12-month ggplot2 grid)\n")
cat("  - 27_ggplot_quarterly_view.png (quarterly ggplot2 view)\n")
cat("  - 28_ggplot_enhanced_heatmap.png (enhanced ggplot2 heatmap)\n")
cat("  - 29_ggplot_timeline.png (ggplot2 timeline)\n") 