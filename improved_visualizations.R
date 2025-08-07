# Improved Visualizations for Seasonal Peak Analysis
# Focus on: Better heatmap, enhanced timeline, professional calendar

# Load required libraries
library(readxl)
library(dplyr)
library(lubridate)
library(tidyr)

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

# Function to create improved heatmap
create_improved_heatmap <- function(clean_data) {
  cat("Creating improved heatmap...\n")
  
  # Create weekly data for heatmap
  weekly_data <- clean_data %>%
    group_by(year, week_of_year) %>%
    summarise(avg_sales = mean(sales, na.rm = TRUE), .groups = 'drop') %>%
    arrange(year, week_of_year)
  
  # Create a complete grid of weeks and years
  all_years <- unique(weekly_data$year)
  all_weeks <- 1:52
  
  complete_grid <- expand.grid(
    year = all_years,
    week_of_year = all_weeks
  ) %>%
    left_join(weekly_data, by = c("year", "week_of_year")) %>%
    mutate(avg_sales = ifelse(is.na(avg_sales), 0, avg_sales))
  
  # Create heatmap matrix
  heatmap_matrix <- complete_grid %>%
    pivot_wider(names_from = year, values_from = avg_sales) %>%
    arrange(week_of_year)
  
  # Convert to matrix for plotting
  plot_matrix <- as.matrix(heatmap_matrix[, -1])
  rownames(plot_matrix) <- heatmap_matrix$week_of_year
  
  # Create improved heatmap
  png("02_sales_heatmap_improved.png", width = 1200, height = 800, res = 150)
  
  # Set up the plot
  par(mar = c(8, 8, 6, 4))
  
  # Create color palette
  color_palette <- colorRampPalette(c("#FFFFFF", "#FFEDA0", "#FED976", "#FEB24C", "#FD8D3C", "#FC4E2A", "#E31A1C", "#BD0026", "#800026"))(100)
  
  # Create heatmap
  heatmap(plot_matrix,
          main = "Sales Performance Heatmap by Week and Year",
          xlab = "Year",
          ylab = "Week of Year",
          col = color_palette,
          scale = "none",
          margins = c(8, 8),
          cexRow = 1.2,
          cexCol = 1.2,
          cex.main = 2,
          cex.lab = 1.5)
  
  dev.off()
  cat("✓ Created improved heatmap: 02_sales_heatmap_improved.png\n")
}

# Function to create enhanced timeline
create_enhanced_timeline <- function(clean_data, peak_analysis) {
  cat("Creating enhanced timeline...\n")
  
  png("03_peak_weeks_timeline_enhanced.png", width = 1400, height = 800, res = 150)
  
  # Set up the plot with better margins
  par(mar = c(10, 8, 6, 4))
  
  # Create the main plot
  plot(peak_analysis$peak_weeks$date, peak_analysis$peak_weeks$sales,
       main = "Peak Sales Weeks Timeline",
       xlab = "", ylab = "Sales ($)",
       pch = 21, col = "red", bg = "red", cex = 2,
       xaxt = "n", yaxt = "n",
       ylim = c(0, max(clean_data$sales) * 1.1))
  
  # Add regular sales for comparison
  points(clean_data$date, clean_data$sales, 
         pch = 16, col = "lightblue", cex = 0.8)
  
  # Add threshold line
  abline(h = peak_analysis$peak_threshold, col = "red", lty = 2, lwd = 3)
  
  # Create custom x-axis with month labels
  date_range <- range(c(clean_data$date, peak_analysis$peak_weeks$date))
  month_breaks <- seq(as.Date(paste0(format(date_range[1], "%Y-%m"), "-01")),
                      as.Date(paste0(format(date_range[2], "%Y-%m"), "-01")),
                      by = "month")
  
  # Add x-axis with month labels
  axis(1, at = month_breaks, 
       labels = format(month_breaks, "%b %Y"),
       las = 2, cex.axis = 1.2, font = 2)
  
  # Add y-axis with better formatting
  axis(2, at = pretty(clean_data$sales), 
       labels = format(pretty(clean_data$sales), big.mark = ","),
       cex.axis = 1.2, font = 2)
  
  # Add grid lines for better readability
  abline(v = month_breaks, col = "lightgray", lty = 3)
  abline(h = pretty(clean_data$sales), col = "lightgray", lty = 3)
  
  # Add enhanced legend
  legend("topleft", 
         legend = c("Regular Sales", "Peak Weeks", "Peak Threshold"),
         col = c("lightblue", "red", "red"), 
         pch = c(16, 21, NA),
         pt.bg = c(NA, "red", NA),
         lty = c(NA, NA, 2), 
         lwd = c(NA, NA, 3),
         cex = 1.5,
         bg = "white",
         box.col = "black",
         box.lwd = 2)
  
  # Add peak week annotations
  top_peaks <- peak_analysis$peak_weeks %>%
    arrange(desc(sales)) %>%
    head(5)
  
  for (i in 1:nrow(top_peaks)) {
    text(top_peaks$date[i], top_peaks$sales[i] + max(clean_data$sales) * 0.05,
         paste("Week", top_peaks$week_of_year[i], "\n", format(top_peaks$sales[i], big.mark = ",")),
         cex = 1, font = 2, col = "darkred")
  }
  
  dev.off()
  cat("✓ Created enhanced timeline: 03_peak_weeks_timeline_enhanced.png\n")
}

# Function to create professional calendar
create_professional_calendar <- function(peak_analysis) {
  cat("Creating professional calendar...\n")
  
  if (nrow(peak_analysis$consistent_peaks) == 0) {
    cat("No consistent peak weeks found for calendar visualization\n")
    return()
  }
  
  # Prepare calendar data
  calendar_data <- peak_analysis$consistent_peaks %>%
    mutate(
      approx_date = as.Date("2024-01-01") + (week_of_year - 1) * 7,
      month_name = format(approx_date, "%B"),
      month_num = lubridate::month(approx_date),
      day_of_month = lubridate::day(approx_date),
      preparation_start = format(approx_date - 21, "%B %d"),
      sales_formatted = format(round(avg_peak_sales), big.mark = ",")
    ) %>%
    arrange(month_num, day_of_month)
  
  # Create calendar visualization
  png("08_peak_weeks_calendar.png", width = 1600, height = 1200, res = 150)
  
  # Set up the plot
  par(mar = c(2, 2, 4, 2))
  
  # Create a 12-month calendar layout
  months <- month.name
  layout(matrix(1:12, nrow = 3, ncol = 4, byrow = TRUE))
  
  for (month_idx in 1:12) {
    month_name <- months[month_idx]
    month_data <- calendar_data %>% filter(month_num == month_idx)
    
    # Create empty plot for the month
    plot(1, 1, type = "n", 
         xlim = c(1, 31), ylim = c(1, 7),
         main = month_name,
         xlab = "", ylab = "",
         axes = FALSE,
         cex.main = 2, font.main = 2)
    
    # Add day labels
    day_labels <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
    for (i in 1:7) {
      text(0.5, i, day_labels[i], cex = 1.2, font = 2, pos = 2)
    }
    
    # Get the first day of the month and number of days
    first_day <- as.Date(paste("2024", month_idx, "01", sep = "-"))
    days_in_month <- lubridate::days_in_month(first_day)
    start_weekday <- lubridate::wday(first_day)
    
    # Draw calendar grid
    for (day in 1:days_in_month) {
      row <- ceiling((day + start_weekday - 1) / 7)
      col <- ((day + start_weekday - 2) %% 7) + 1
      
      # Check if this day has peak week data
      peak_info <- month_data %>% 
        filter(day_of_month == day)
      
      if (nrow(peak_info) > 0) {
        # Draw peak week box
        rect(col - 0.4, row - 0.4, col + 0.4, row + 0.4, 
             col = "red", border = "darkred", lwd = 2)
        text(col, row, paste(day, "\nPEAK", sep = ""), 
             cex = 0.8, font = 2, col = "white")
        
        # Add sales info
        text(col, row - 0.3, paste("$", peak_info$sales_formatted[1]), 
             cex = 0.6, font = 2, col = "white")
      } else {
        # Draw regular day box
        rect(col - 0.4, row - 0.4, col + 0.4, row + 0.4, 
             col = "lightgray", border = "gray")
        text(col, row, day, cex = 0.8)
      }
    }
    
    # Add month summary if there are peak weeks
    if (nrow(month_data) > 0) {
      total_peaks <- nrow(month_data)
      avg_sales <- mean(month_data$avg_peak_sales)
      text(16, 6.5, paste("Peak Weeks:", total_peaks), 
           cex = 1, font = 2, col = "red", pos = 4)
      text(16, 6, paste("Avg Sales: $", format(round(avg_sales), big.mark = ",")), 
           cex = 0.8, font = 2, col = "red", pos = 4)
    }
  }
  
  # Add overall title
  mtext("2024 Peak Sales Weeks Calendar", 
        side = 3, line = -2, outer = TRUE, 
        cex = 2.5, font = 2, col = "darkred")
  
  dev.off()
  cat("✓ Created professional calendar: 08_peak_weeks_calendar.png\n")
  
  # Also create a summary table visualization
  png("09_peak_weeks_summary.png", width = 1200, height = 800, res = 150)
  
  par(mar = c(8, 8, 6, 4))
  
  # Create summary table
  summary_data <- calendar_data %>%
    select(Month = month_name, 
           `Peak Week` = week_of_year,
           `Avg Sales` = sales_formatted,
           `Years with Peaks` = years_with_peaks,
           `Preparation Start` = preparation_start)
  
  # Create table visualization
  plot(1, 1, type = "n", 
       xlim = c(0, 6), ylim = c(0, nrow(summary_data) + 2),
       main = "Peak Weeks Summary",
       xlab = "", ylab = "",
       axes = FALSE,
       cex.main = 2, font.main = 2)
  
  # Draw table headers
  headers <- c("Month", "Peak Week", "Avg Sales", "Years", "Prep Start")
  for (i in 1:length(headers)) {
    rect(i-0.5, nrow(summary_data) + 0.5, i+0.5, nrow(summary_data) + 1.5, 
         col = "darkred", border = "black")
    text(i, nrow(summary_data) + 1, headers[i], 
         cex = 1.2, font = 2, col = "white")
  }
  
  # Draw table data
  for (row in 1:nrow(summary_data)) {
    for (col in 1:ncol(summary_data)) {
      rect(col-0.5, row-0.5, col+0.5, row+0.5, 
           col = ifelse(row %% 2 == 0, "lightgray", "white"), 
           border = "gray")
      text(col, row, as.character(summary_data[row, col]), 
           cex = 1, font = 1)
    }
  }
  
  dev.off()
  cat("✓ Created summary table: 09_peak_weeks_summary.png\n")
}

# Run all improved visualizations
cat("=== CREATING IMPROVED VISUALIZATIONS ===\n\n")

# 1. Improved heatmap
create_improved_heatmap(clean_data)

# 2. Enhanced timeline
create_enhanced_timeline(clean_data, peak_analysis)

# 3. Professional calendar
create_professional_calendar(peak_analysis)

cat("\n=== IMPROVED VISUALIZATIONS COMPLETED ===\n")
cat("✓ Generated 4 new improved PNG files:\n")
cat("  - 02_sales_heatmap_improved.png (cleaner heatmap)\n")
cat("  - 03_peak_weeks_timeline_enhanced.png (better labels)\n")
cat("  - 08_peak_weeks_calendar.png (professional calendar)\n")
cat("  - 09_peak_weeks_summary.png (summary table)\n") 