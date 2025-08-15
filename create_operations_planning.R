# Operations Planning: Inventory and Staffing from Weekly Forecasts
# Uses tidyverse and forecast to derive safety stock and staffing plans.

suppressPackageStartupMessages({
  pkgs <- c("tidyverse", "readxl", "lubridate", "scales", "zoo", "forecast", "magrittr", "rlang", "stringr", "readr")
  for (p in pkgs) if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  lapply(pkgs, function(p) suppressPackageStartupMessages(library(p, character.only = TRUE)))
})
library(magrittr)
utils::globalVariables(c(".data","value","date","raw_date","measure"))
raw_date <- NULL; value <- NULL

safe <- function(expr, default = NULL) tryCatch(expr, error = function(e) default)

# Robust helpers to infer dates/values from messy sheets
excel_to_date <- function(x) {
  if (is.character(x)) {
    suppressWarnings(xn <- as.numeric(x))
  } else {
    xn <- x
  }
  out <- try(as.Date(xn, origin = "1899-12-30"), silent = TRUE)
  if (inherits(out, "try-error")) return(rep(NA, length(x)))
  out
}

parse_any_date_from_text <- function(x) {
  d1 <- suppressWarnings(lubridate::parse_date_time(x, orders = c(
    "ymd","Ymd","mdy","dmy","bdY","bdy","dbY","dby","mdY","dmY",
    "ymd HMS","mdy HMS","dmy HMS"
  )))
  if (all(is.na(d1))) {
    s <- stringr::str_extract(x, "[0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}")
    d2 <- suppressWarnings(lubridate::mdy(s))
    if (all(is.na(d2))) d2 <- suppressWarnings(lubridate::ymd(s))
    if (all(is.na(d2))) d2 <- suppressWarnings(lubridate::dmy(s))
    return(d2)
  }
  as.Date(d1)
}

guess_date_column <- function(df) {
  name_scores <- sapply(names(df), function(nm) {
    n <- tolower(nm)
    if (grepl("date|week|period|ending|start|end", n)) 2 else 0
  })
  candidates <- names(df)[order(name_scores, decreasing = TRUE)]
  if (length(candidates) == 0) candidates <- names(df)
  for (col in candidates) {
    v <- df[[col]]
    if (inherits(v, c("Date","POSIXct","POSIXt"))) return(col)
    if (is.numeric(v)) {
      d <- excel_to_date(v)
      if (sum(!is.na(d)) >= 0.7 * length(d)) return(col)
    }
    if (is.character(v)) {
      d <- parse_any_date_from_text(v)
      if (sum(!is.na(d)) >= 0.7 * length(d)) return(col)
    }
  }
  NULL
}

guess_value_column <- function(df) {
  preferred <- c("sales","revenue","amount","net","gross","value","qty","quantity")
  lower_names <- tolower(names(df))
  for (p in preferred) {
    idx <- which(lower_names == p | grepl(paste0("^", p), lower_names))
    if (length(idx) > 0 && is.numeric(df[[idx[1]]])) return(names(df)[idx[1]])
  }
  num_cols <- names(df)[sapply(df, is.numeric)]
  if (length(num_cols) == 0) return(NULL)
  vars <- sapply(df[num_cols], function(x) stats::var(x, na.rm = TRUE))
  num_cols[which.max(vars)]
}

infer_weekly_ts <- function(df) {
  env_date <- Sys.getenv("OP_DATE_COL", unset = NA_character_)
  env_value <- Sys.getenv("OP_VALUE_COL", unset = NA_character_)

  date_col <- if (!is.na(env_date) && nzchar(env_date) && env_date %in% names(df)) env_date else guess_date_column(df)
  if (is.null(date_col)) stop("No date-like column detected.")

  value_col <- if (!is.na(env_value) && nzchar(env_value) && env_value %in% names(df)) env_value else guess_value_column(df)
  if (is.null(value_col)) stop("No numeric value column detected.")

  message(sprintf("Using date column: %s; value column: %s", date_col, value_col))

  v_date <- df[[date_col]]
  if (inherits(v_date, c("Date","POSIXct","POSIXt"))) {
    d <- as.Date(v_date)
  } else if (is.numeric(v_date) || (is.character(v_date) && suppressWarnings(!all(is.na(as.numeric(v_date)))))) {
    d <- excel_to_date(v_date)
  } else {
    d <- parse_any_date_from_text(as.character(v_date))
  }

  df_norm <- tibble::tibble(raw_date = d, value = as.numeric(df[[value_col]]))

  out <- df_norm %>%
    dplyr::filter(!is.na(raw_date)) %>%
    dplyr::transmute(date = as.Date(raw_date), value = value) %>%
    dplyr::arrange(date) %>%
    dplyr::group_by(date = lubridate::floor_date(date, unit = "week", week_start = 1)) %>%
    dplyr::summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(date)
  if (nrow(out) == 0) stop("Failed to build weekly series; check OP_DATE_COL/OP_VALUE_COL or data format.")
  out
}

load_sales_data <- function() {
  # Env override
  op_file <- Sys.getenv("OP_FILE", unset = NA_character_)
  op_sheet <- Sys.getenv("OP_SHEET", unset = NA_character_)
  if (!is.na(op_file) && nzchar(op_file) && file.exists(op_file)) {
    message(sprintf("Reading OP_FILE: %s", op_file))
    ext <- tolower(tools::file_ext(op_file))
    if (ext %in% c("xlsx","xls","xlsm")) {
      if (!is.na(op_sheet) && nzchar(op_sheet)) {
        df <- safe(readxl::read_excel(op_file, sheet = op_sheet), default = NULL)
        out <- safe(infer_weekly_ts(df), default = NULL)
        if (!is.null(out) && nrow(out) >= 8) return(out)
      }
      sheets <- safe(readxl::excel_sheets(op_file), default = NULL)
      if (!is.null(sheets)) {
        for (s in sheets) {
          df <- safe(readxl::read_excel(op_file, sheet = s), default = NULL)
          out <- safe(infer_weekly_ts(df), default = NULL)
          if (!is.null(out) && nrow(out) >= 8) return(out)
        }
      }
      df <- safe(readxl::read_excel(op_file), default = NULL)
      out <- safe(infer_weekly_ts(df), default = NULL)
      if (!is.null(out) && nrow(out) >= 8) return(out)
    } else if (ext %in% c("csv","txt")) {
      df <- safe(readr::read_csv(op_file, show_col_types = FALSE), default = NULL)
      out <- safe(infer_weekly_ts(df), default = NULL)
      if (!is.null(out) && nrow(out) >= 8) return(out)
    }
  }

  for (path in c("Copy of Weekly Sales 5_29_23-5_25.xlsx","weekly_sales.xlsx","sales.xlsx","weekly_sales.csv","sales.csv")) {
    if (file.exists(path)) {
      sheets <- safe(readxl::excel_sheets(path), default = NULL)
      if (!is.null(sheets)) {
        for (s in sheets) {
          df <- safe(readxl::read_excel(path, sheet = s), default = NULL)
          out <- safe(infer_weekly_ts(df), default = NULL)
          if (!is.null(out) && nrow(out) >= 8) return(out)
        }
      }
      if (grepl("\\.csv$", path)) {
        df <- safe(readr::read_csv(path, show_col_types = FALSE), default = NULL)
      } else {
        df <- safe(readxl::read_excel(path), default = NULL)
      }
      out <- safe(infer_weekly_ts(df), default = NULL)
      if (!is.null(out) && nrow(out) >= 8) return(out)
    }
  }
  stop("No usable weekly time series found. Set OP_FILE to your file path and optionally OP_SHEET, OP_DATE_COL, OP_VALUE_COL.")
}

sales_weekly <- load_sales_data()

ts_data <- ts(sales_weekly$value, frequency = 52)
fit <- forecast::auto.arima(ts_data)
fc_h <- 12
fc <- forecast::forecast(fit, h = fc_h)

forecast_df <- tibble::tibble(
  date = max(sales_weekly$date) + lubridate::weeks(seq_len(fc_h)),
  mean = as.numeric(fc$mean),
  lo80 = as.numeric(fc$lower[,1]),
  hi80 = as.numeric(fc$upper[,1]),
  lo95 = as.numeric(fc$lower[,2]),
  hi95 = as.numeric(fc$upper[,2])
)

# In-sample residual sd as demand uncertainty proxy
resid_sd <- stats::sd(stats::residuals(fit), na.rm = TRUE)

# Parameters (tweak as needed)
service_level <- 0.95
z_value <- qnorm(service_level)
lead_time_weeks <- 2
sales_to_labor_ratio <- 150  # $ sales per labor hour

safety_stock <- z_value * resid_sd * sqrt(lead_time_weeks)

inventory_plan <- forecast_df %>%
  dplyr::mutate(
    safety_stock = safety_stock,
    reorder_point = mean * lead_time_weeks + safety_stock
  )

staffing_plan <- forecast_df %>%
  dplyr::mutate(labor_hours = pmax(0, mean / sales_to_labor_ratio))

# Visuals
p_inv <- ggplot(inventory_plan, aes(date)) +
  geom_line(aes(y = mean), color = "#1f77b4", size = 1) +
  geom_ribbon(aes(ymin = lo80, ymax = hi80), fill = "#6baed6", alpha = 0.35) +
  geom_line(aes(y = reorder_point), color = "#e6550d", linetype = "dashed") +
  labs(title = "Inventory Planning: Forecast and Reorder Point",
       subtitle = sprintf("Service level %.0f%%, lead time %d weeks", service_level*100, lead_time_weeks),
       y = "Weekly Units (proxy)", x = NULL) +
  theme_minimal(base_size = 12)

ggsave("20_inventory_safety_stock.png", p_inv, width = 14, height = 6, dpi = 300, bg = "white")

p_staff <- ggplot(staffing_plan, aes(date, labor_hours)) +
  geom_col(fill = "#31a354", alpha = 0.8) +
  geom_text(aes(label = round(labor_hours,1)), vjust = -0.2, size = 3, color = "#2c3e50") +
  labs(title = "Staffing Plan from Sales Forecast",
       subtitle = sprintf("Sales to labor ratio: $%s per hour", scales::comma(sales_to_labor_ratio)),
       y = "Labor Hours", x = NULL) +
  theme_minimal(base_size = 12)

ggsave("21_staffing_plan.png", p_staff, width = 14, height = 6, dpi = 300, bg = "white")

# Markdown report
md <- c(
  "# Operations Planning: Inventory and Staffing",
  "",
  sprintf("- Model: %s; Horizon: %d weeks.", fit$method, fc_h),
  sprintf("- Residual SD: %.2f; Service Level: %.0f%%; Lead Time: %d weeks.", resid_sd, service_level*100, lead_time_weeks),
  sprintf("- Safety Stock (per week proxy): %.2f.", safety_stock),
  sprintf("- Sales to Labor Ratio: $%s per hour.", scales::comma(sales_to_labor_ratio)),
  "",
  "## Visuals",
  "![Inventory Planning](20_inventory_safety_stock.png)",
  "![Staffing Plan](21_staffing_plan.png)",
  "",
  "## Notes",
  "- Units proxy assumes proportionality of sales and demand; calibrate with item-level data.",
  "- Adjust service level, lead time, and sales-to-labor ratio to your operation.",
  "- For SKU/store optimization, run hierarchical forecasts and compute per-node buffers.",
  "",
  "## Plain-English Summary",
  "- Safety stock is a small buffer to avoid stockouts during normal ups and downs.",
  sprintf("- We assume your supplier takes %d weeks; reorder points include expected sales during lead time plus a buffer.", lead_time_weeks),
  sprintf("- Staffing converts forecasted sales into labor hours using a simple ratio ($%s per hour); adjust to your store.", scales::comma(sales_to_labor_ratio)),
  "- Use higher service levels if you prefer fewer stockouts, but expect more inventory on hand."
)
writeLines(md, "OPERATIONS_PLANNING_REPORT.md")

cat("Created OPERATIONS_PLANNING_REPORT.md and images 20_*.png\n")


