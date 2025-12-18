# R/data.R
# Data loading and processing functions

#' Infer and aggregate weekly time series from a raw dataframe
#' @param df Raw dataframe containing dates and values
#' @return Aggregated weekly dataframe with columns 'date' and 'value', or NULL on failure
infer_weekly_ts <- function(df) {
  # Try to detect a date column and a numeric measure column
  date_cols <- names(df)[sapply(df, function(x) inherits(x, c("Date", "POSIXct", "POSIXt")) ||
                                  is.character(x))]
  
  # Convert character-like date columns where possible
  for (col in date_cols) {
    if (is.character(df[[col]])) {
      suppressWarnings({
        parsed <- lubridate::parse_date_time(df[[col]], orders = c("ymd", "mdy", "dmy", "Ymd", "mdY", "dmy HMS", "mdy HMS"))
      })
      if (sum(!is.na(parsed)) >= 0.7 * nrow(df)) {
        df[[col]] <- lubridate::as_date(parsed)
      }
    }
  }
  
  candidate_dates <- names(df)[sapply(df, function(x) inherits(x, "Date"))]
  if (length(candidate_dates) == 0) stop("No date-like column detected.")
  
  num_cols <- names(df)[sapply(df, is.numeric)]
  if (length(num_cols) == 0) stop("No numeric value column detected.")
  
  # Heuristic: choose the first date column and the first numeric column
  date_col <- candidate_dates[[1]]
  value_col <- num_cols[[1]]
  
  {
    date_sym <- rlang::sym(date_col)
    value_sym <- rlang::sym(value_col)
    df %>%
      dplyr::filter(!is.na(!!date_sym)) %>%
      dplyr::transmute(date = lubridate::as_date(!!date_sym), measure = as.numeric(!!value_sym)) %>%
      dplyr::arrange(date) %>%
      dplyr::group_by(date = lubridate::floor_date(date, unit = "week", week_start = 1)) %>%
      dplyr::summarise(value = sum(!!rlang::sym("measure"), na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(date)
  }
}

#' Create synthetic sample data for demonstration
#' @return Dataframe with synthetic sales data
create_sample_data <- function() {
  set.seed(123)
  start_date <- as.Date("2023-07-01")
  n_weeks <- 107
  
  sample_data <- data.frame(
    date = start_date + (0:(n_weeks-1)) * 7,
    value = 40000 + (0:(n_weeks-1)) * 177.86 + 
      rnorm(n_weeks, 0, 2000) + 
      8000 * sin(2 * pi * (0:(n_weeks-1)) / 52) +
      4000 * sin(2 * pi * (0:(n_weeks-1)) / 26)
  )
  
  message(sprintf("Created sample data: %d weeks from %s to %s", 
                  nrow(sample_data), 
                  min(sample_data$date), 
                  max(sample_data$date)))
  
  return(sample_data)
}

#' Load sales data from Excel files in the current directory
#' @return Dataframe with weekly sales data
load_sales_data <- function() {
  # Enhanced file detection - check all Excel files in directory
  all_excel_files <- list.files(pattern = "\\.xlsx$|\\.xls$")
  
  # Primary: Excel file known in repo
  candidates <- c(
    "Copy of Weekly Sales 5_29_23-5_25.xlsx",
    "weekly_sales.xlsx",
    "sales.xlsx"
  )
  
  # Add all Excel files found in directory
  candidates <- unique(c(candidates, all_excel_files))
  
  message(sprintf("Checking %d candidate files: %s", length(candidates), paste(candidates, collapse = ", ")))
  
  for (path in candidates) {
    if (file.exists(path)) {
      message(sprintf("Trying file: %s", path))
      
      # Try to read the file
      wb <- safe(readxl::excel_sheets(path), default = NULL)
      if (is.null(wb)) {
        message(sprintf("  Failed to read sheets from %s", path))
        next
      }
      
      message(sprintf("  Sheets found: %s", paste(wb, collapse = ", ")))
      
      for (sheet in wb) {
        message(sprintf("  Trying sheet: %s", sheet))
        df <- safe(readxl::read_excel(path, sheet = sheet), default = NULL)
        if (is.null(df)) {
          message(sprintf("    Failed to read sheet %s", sheet))
          next
        }
        
        message(sprintf("    Rows: %d, Columns: %d", nrow(df), ncol(df)))
        
        # Check if we have enough data
        if (nrow(df) < 10) {
          message("    Not enough rows (need at least 10)")
          next
        }
        
        out <- safe(infer_weekly_ts(df), default = NULL)
        if (!is.null(out) && nrow(out) >= 20) {
          message(sprintf("    Success! Found %d weeks of data", nrow(out)))
          return(out)
        } else {
          message("    Failed to create usable time series")
        }
      }
      
      # Try first sheet directly if sheet iteration failed
      message("  Trying first sheet directly...")
      df <- safe(readxl::read_excel(path), default = NULL)
      if (!is.null(df)) {
        out <- safe(infer_weekly_ts(df), default = NULL)
        if (!is.null(out) && nrow(out) >= 20) {
          message(sprintf("    Success! Found %d weeks of data", nrow(out)))
          return(out)
        }
      }
    } else {
      message(sprintf("  File not found: %s", path))
    }
  }
  
  # If no data found, create sample data for testing
  message("No usable data found. Creating sample data for demonstration...")
  return(create_sample_data())
}

#' Preprocess data: fill gaps and impute missing values
#' @param sales_weekly Dataframe with date and value
#' @return Processed dataframe
preprocess_data <- function(sales_weekly) {
  start_date <- min(sales_weekly$date, na.rm = TRUE)
  end_date   <- max(sales_weekly$date, na.rm = TRUE)
  
  sales_weekly %>%
    tidyr::complete(date = seq(lubridate::floor_date(start_date, "week"), end_date, by = "week")) %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(value = zoo::na.locf(value, na.rm = FALSE)) %>%
    dplyr::mutate(value = zoo::na.locf(value, fromLast = TRUE))
}
