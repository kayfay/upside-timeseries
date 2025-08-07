# Professional Calendar Visualization
# Clean, minimal design following data visualization best practices

# Load required libraries
library(readxl)
library(dplyr)
library(lubridate)

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

# Function to create professional single month calendar
create_professional_month_calendar <- function(peak_analysis, month = 4, year = 2024) {
  cat("Creating professional calendar for", month.name[month], year, "...\n")
  
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
  
  # Create professional single month calendar
  png(paste0("22_", tolower(month.name[month]), "_", year, "_professional.png"), 
      width = 4000, height = 3000, res = 300)
  
  # Set up the plot with clean margins
  par(mar = c(2, 2, 4, 2), bg = "white")
  
  # Create empty plot with proper spacing
  plot(1, 1, type = "n",
       xlim = c(0.5, 7.5), ylim = c(0.5, 6.5),
       main = paste(month.name[month], year, "Sales Calendar"),
       xlab = "", ylab = "",
       axes = FALSE,
       cex.main = 4, font.main = 1, col.main = "#2c3e50")
  
  # Add day labels - clean and simple
  day_labels <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  for (i in 1:7) {
    text(i, 6.2, day_labels[i], cex = 2.5, font = 2, col = "#34495e")
  }
  
  # Get month details
  first_day <- as.Date(paste(year, month, "01", sep = "-"))
  days_in_month <- lubridate::days_in_month(first_day)
  start_weekday <- lubridate::wday(first_day)
  
  # Draw calendar grid - clean and minimal
  for (day in 1:days_in_month) {
    # Calculate position
    col <- ((day + start_weekday - 2) %% 7) + 1
    row <- ceiling((day + start_weekday - 1) / 7)
    
    # Check if this day has peak week data
    peak_info <- peak_weeks %>%
      filter(day_of_month == day)
    
    if (nrow(peak_info) > 0) {
      # Draw peak week box - clean red background
      rect(col - 0.45, row - 0.45, col + 0.45, row + 0.45,
           col = "#e74c3c", border = "#c0392b", lwd = 2)
      
      # Add day number only - clean and large
      text(col, row, day, cex = 3, font = 2, col = "white")
    } else {
      # Draw regular day box - subtle styling
      rect(col - 0.45, row - 0.45, col + 0.45, row + 0.45,
           col = "#f8f9fa", border = "#dee2e6", lwd = 1)
      text(col, row, day, cex = 2.8, font = 1, col = "#495057")
    }
  }
  
  # Add clean summary at bottom
  if (nrow(peak_weeks) > 0) {
    total_peaks <- nrow(peak_weeks)
    avg_sales <- mean(peak_weeks$sales, na.rm = TRUE)
    if (is.na(avg_sales)) avg_sales <- mean(peak_weeks$avg_peak_sales, na.rm = TRUE)
    
    text(0.5, 0.8, paste("Peak Weeks:", total_peaks),
         cex = 2.5, font = 2, col = "#e74c3c", pos = 4)
    text(0.5, 0.4, paste("Avg Sales: $", format(round(avg_sales), big.mark = ",")),
         cex = 2, font = 1, col = "#6c757d", pos = 4)
  }
  
  # Add clean legend
  legend(5.5, 1.5, 
         legend = c("Peak Sales Week", "Regular Day"),
         fill = c("#e74c3c", "#f8f9fa"),
         border = c("#c0392b", "#dee2e6"),
         cex = 2, bty = "n", text.col = "#495057")
  
  dev.off()
  cat("✓ Created", month.name[month], "professional: 22_", tolower(month.name[month]), "_", year, "_professional.png\n")
}

# Function to create professional 12-month grid
create_professional_12month_grid <- function(peak_analysis, year = 2024) {
  cat("Creating professional 12-month calendar grid...\n")
  
  # Get peak weeks data
  if (nrow(peak_analysis$consistent_peaks) == 0) {
    peak_weeks <- peak_analysis$peak_weeks %>%
      mutate(
        week_of_year = lubridate::week(date),
        month = lubridate::month(date),
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
      )
  }
  
  # Create professional 12-month grid
  png("23_professional_12month_grid.png", width = 6000, height = 4500, res = 300)
  
  # Set up the plot with clean margins
  par(mar = c(1, 1, 2, 1), oma = c(2, 2, 4, 2), bg = "white")
  
  # Create a 12-month calendar layout (3 rows, 4 columns)
  months <- month.name
  layout(matrix(1:12, nrow = 3, ncol = 4, byrow = TRUE))
  
  for (month_idx in 1:12) {
    month_name <- months[month_idx]
    month_data <- peak_weeks %>% filter(month == month_idx)
    
    # Create empty plot for the month
    plot(1, 1, type = "n",
         xlim = c(0.5, 7.5), ylim = c(0.5, 6.5),
         main = month_name,
         xlab = "", ylab = "",
         axes = FALSE,
         cex.main = 3, font.main = 2, col.main = "#2c3e50")
    
    # Add day labels - clean and simple
    day_labels <- c("S", "M", "T", "W", "T", "F", "S")
    for (i in 1:7) {
      text(i, 6.2, day_labels[i], cex = 2, font = 2, col = "#6c757d")
    }
    
    # Get the first day of the month and number of days
    first_day <- as.Date(paste(year, month_idx, "01", sep = "-"))
    days_in_month <- lubridate::days_in_month(first_day)
    start_weekday <- lubridate::wday(first_day)
    
    # Draw calendar grid - clean and minimal
    for (day in 1:days_in_month) {
      # Calculate position in grid
      col <- ((day + start_weekday - 2) %% 7) + 1
      row <- ceiling((day + start_weekday - 1) / 7)
      
      # Check if this day has peak week data
      peak_info <- month_data %>%
        filter(day_of_month == day)
      
      if (nrow(peak_info) > 0) {
        # Draw peak week box - clean red background
        rect(col - 0.45, row - 0.45, col + 0.45, row + 0.45,
             col = "#e74c3c", border = "#c0392b", lwd = 1)
        text(col, row, day, cex = 2.2, font = 2, col = "white")
      } else {
        # Draw regular day box - subtle styling
        rect(col - 0.45, row - 0.45, col + 0.45, row + 0.45,
             col = "#f8f9fa", border = "#dee2e6", lwd = 0.5)
        text(col, row, day, cex = 2, font = 1, col = "#495057")
      }
    }
    
    # Add month summary if there are peak weeks
    if (nrow(month_data) > 0) {
      total_peaks <- nrow(month_data)
      text(0.5, 0.8, paste(total_peaks, "peaks"),
           cex = 1.5, font = 2, col = "#e74c3c", pos = 4)
    }
  }
  
  # Add overall title
  mtext(paste(year, "Peak Sales Weeks Calendar"),
        side = 3, line = 0, outer = TRUE,
        cex = 5, font = 2, col = "#2c3e50")
  
  # Add subtitle
  mtext("Red boxes indicate historically high sales weeks",
        side = 3, line = -2, outer = TRUE,
        cex = 2.5, font = 1, col = "#6c757d")
  
  dev.off()
  cat("✓ Created professional 12-month grid: 23_professional_12month_grid.png\n")
}

# Function to create professional quarterly view
create_professional_quarterly_view <- function(peak_analysis, year = 2024) {
  cat("Creating professional quarterly view...\n")
  
  # Get peak weeks data
  if (nrow(peak_analysis$consistent_peaks) == 0) {
    peak_weeks <- peak_analysis$peak_weeks %>%
      mutate(
        week_of_year = lubridate::week(date),
        month = lubridate::month(date),
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
      )
  }
  
  # Create professional quarterly view
  png("24_professional_quarterly_view.png", width = 7000, height = 5000, res = 300)
  
  # Set up the plot with clean margins
  par(mar = c(2, 2, 3, 2), oma = c(3, 3, 6, 3), bg = "white")
  
  # Create a 2x2 layout for quarters
  layout(matrix(1:4, nrow = 2, ncol = 2, byrow = TRUE))
  
  quarters <- list(
    Q1 = c(1, 2, 3),
    Q2 = c(4, 5, 6),
    Q3 = c(7, 8, 9),
    Q4 = c(10, 11, 12)
  )
  
  for (q_idx in 1:4) {
    quarter_name <- names(quarters)[q_idx]
    quarter_months <- quarters[[q_idx]]
    
    # Create empty plot for the quarter
    plot(1, 1, type = "n",
         xlim = c(0.5, 21.5), ylim = c(0.5, 6.5),
         main = paste("Quarter", q_idx, "-", quarter_name),
         xlab = "", ylab = "",
         axes = FALSE,
         cex.main = 3.5, font.main = 2, col.main = "#2c3e50")
    
    # Add day labels - clean and simple
    day_labels <- c("S", "M", "T", "W", "T", "F", "S")
    for (i in 1:7) {
      text(i, 6.2, day_labels[i], cex = 2.5, font = 2, col = "#6c757d")
    }
    
    # Process each month in the quarter
    for (month_idx in quarter_months) {
      month_name <- month.name[month_idx]
      month_data <- peak_weeks %>% filter(month == month_idx)
      
      # Add month label
      month_x <- 8 + (month_idx - quarter_months[1]) * 7
      text(month_x + 3, 6.2, month_name, cex = 2.8, font = 2, col = "#27ae60")
      
      # Get month details
      first_day <- as.Date(paste(year, month_idx, "01", sep = "-"))
      days_in_month <- lubridate::days_in_month(first_day)
      start_weekday <- lubridate::wday(first_day)
      
      # Draw calendar for this month
      for (day in 1:days_in_month) {
        # Calculate position
        col <- ((day + start_weekday - 2) %% 7) + 1
        row <- ceiling((day + start_weekday - 1) / 7)
        
        # Adjust for month position
        month_offset <- (month_idx - quarter_months[1]) * 7
        col <- col + month_offset
        
        # Check if this day has peak week data
        peak_info <- month_data %>%
          filter(day_of_month == day)
        
        if (nrow(peak_info) > 0) {
          # Draw peak week box - clean red background
          rect(col - 0.45, row - 0.45, col + 0.45, row + 0.45,
               col = "#e74c3c", border = "#c0392b", lwd = 1.5)
          text(col, row, day, cex = 2, font = 2, col = "white")
        } else {
          # Draw regular day box - subtle styling
          rect(col - 0.45, row - 0.45, col + 0.45, row + 0.45,
               col = "#f8f9fa", border = "#dee2e6", lwd = 0.5)
          text(col, row, day, cex = 1.8, font = 1, col = "#495057")
        }
      }
    }
    
    # Add quarter summary
    quarter_data <- peak_weeks %>% filter(month %in% quarter_months)
    if (nrow(quarter_data) > 0) {
      total_peaks <- nrow(quarter_data)
      text(0.5, 1, paste(total_peaks, "peak weeks"),
           cex = 2.5, font = 2, col = "#e74c3c", pos = 4)
    }
  }
  
  # Add overall title
  mtext(paste(year, "Peak Sales Weeks - Quarterly View"),
        side = 3, line = 1, outer = TRUE,
        cex = 6, font = 2, col = "#2c3e50")
  
  # Add subtitle
  mtext("Business planning calendar with seasonal peak identification",
        side = 3, line = -1, outer = TRUE,
        cex = 3, font = 1, col = "#6c757d")
  
  dev.off()
  cat("✓ Created professional quarterly view: 24_professional_quarterly_view.png\n")
}

# Run all professional calendar visualizations
cat("=== CREATING PROFESSIONAL CALENDAR VISUALIZATIONS ===\n\n")

# 1. Professional single month calendars for peak months
create_professional_month_calendar(peak_analysis, 3, 2024)  # March
create_professional_month_calendar(peak_analysis, 4, 2024)  # April
create_professional_month_calendar(peak_analysis, 5, 2024)  # May

# 2. Professional 12-month grid
create_professional_12month_grid(peak_analysis, 2024)

# 3. Professional quarterly view
create_professional_quarterly_view(peak_analysis, 2024)

cat("\n=== PROFESSIONAL CALENDAR VISUALIZATIONS COMPLETED ===\n")
cat("✓ Generated 5 new professional calendar files:\n")
cat("  - 22_march_2024_professional.png (March professional view)\n")
cat("  - 22_april_2024_professional.png (April professional view)\n")
cat("  - 22_may_2024_professional.png (May professional view)\n")
cat("  - 23_professional_12month_grid.png (12-month professional grid)\n")
cat("  - 24_professional_quarterly_view.png (quarterly professional view)\n") 