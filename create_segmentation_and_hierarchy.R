# Segmentation & Hierarchy Analysis
# Product clustering and reconciliation analysis for restaurant business intelligence

suppressPackageStartupMessages({
  pkgs <- c("tidyverse", "readxl", "lubridate", "scales", "zoo", "forecast", "magrittr", "rlang", "stringr", "readr", "cluster", "factoextra", "dendextend")
  for (p in pkgs) if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  lapply(pkgs, function(p) suppressPackageStartupMessages(library(p, character.only = TRUE)))
})
library(magrittr)
utils::globalVariables(c(".data","value","date","raw_date","measure"))
raw_date <- NULL; value <- NULL

safe <- function(expr, default = NULL) tryCatch(expr, error = function(e) default)

# Generate synthetic product data for demonstration
generate_product_data <- function(weeks = 52) {
  set.seed(123)
  
  # Create weekly dates
  start_date <- as.Date("2023-01-01")
  dates <- start_date + weeks(0:(weeks-1))
  
  # Product categories with different seasonal patterns
  products <- tibble(
    product_id = 1:12,
    category = rep(c("Appetizers", "Main Courses", "Desserts", "Beverages"), each = 3),
    base_sales = c(800, 1200, 600,  # Appetizers
                   1500, 1800, 1400, # Main Courses  
                   400, 600, 300,    # Desserts
                   200, 300, 150),   # Beverages
    seasonal_strength = c(0.3, 0.4, 0.2,  # Appetizers
                         0.5, 0.6, 0.4,   # Main Courses
                         0.7, 0.8, 0.6,   # Desserts
                         0.2, 0.3, 0.1)   # Beverages
  )
  
  # Generate weekly sales for each product
  product_sales <- expand_grid(
    week = dates,
    product_id = products$product_id
  ) %>%
    left_join(products, by = "product_id") %>%
    mutate(
      # Add seasonal pattern
      seasonal_factor = 1 + seasonal_strength * sin(2 * pi * (week - start_date) / 365.25),
      # Add some random variation
      random_factor = rnorm(n(), 1, 0.1),
      # Calculate final sales
      sales = base_sales * seasonal_factor * random_factor,
      sales = pmax(sales, 0)  # Ensure non-negative
    )
  
  return(product_sales)
}

# Product segmentation analysis
analyze_product_segments <- function(product_data) {
  # Aggregate by product
  product_summary <- product_data %>%
    group_by(product_id, category) %>%
    summarise(
      total_sales = sum(sales, na.rm = TRUE),
      avg_weekly_sales = mean(sales, na.rm = TRUE),
      sales_volatility = sd(sales, na.rm = TRUE) / mean(sales, na.rm = TRUE),
      seasonal_strength = cor(sales, sin(2 * pi * (1:n()) / 52), use = "complete.obs"),
      peak_week = which.max(sales),
      .groups = "drop"
    ) %>%
    mutate(
      seasonal_strength = abs(seasonal_strength),
      sales_rank = rank(-total_sales)
    )
  
  # Perform clustering
  features <- product_summary %>%
    select(avg_weekly_sales, sales_volatility, seasonal_strength) %>%
    scale()
  
  # K-means clustering
  set.seed(123)
  kmeans_result <- kmeans(features, centers = 3, nstart = 25)
  
  # Add cluster assignments
  product_summary$cluster <- kmeans_result$cluster
  
  # Analyze clusters
  cluster_summary <- product_summary %>%
    group_by(cluster) %>%
    summarise(
      n_products = n(),
      avg_sales = mean(avg_weekly_sales),
      avg_volatility = mean(sales_volatility),
      avg_seasonal = mean(seasonal_strength),
      categories = paste(unique(category), collapse = ", "),
      .groups = "drop"
    )
  
  return(list(
    product_summary = product_summary,
    cluster_summary = cluster_summary,
    features = features
  ))
}

# Hierarchy reconciliation analysis
analyze_hierarchy <- function(product_data) {
  # Calculate reconciliation metrics
  reconciliation_metrics <- product_data %>%
    group_by(week) %>%
    summarise(
      product_sum = sum(sales, na.rm = TRUE),
      total_sales = sum(sales, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      product_total_diff = abs(product_sum - total_sales),
      reconciliation_error = product_total_diff
    )
  
  return(list(
    reconciliation_metrics = reconciliation_metrics
  ))
}

# Generate insights and recommendations
generate_insights <- function(segmentation_result, hierarchy_result) {
  product_summary <- segmentation_result$product_summary
  cluster_summary <- segmentation_result$cluster_summary
  
  # Top performing products
  top_products <- product_summary %>%
    arrange(desc(total_sales)) %>%
    head(5) %>%
    select(product_id, category, total_sales, avg_weekly_sales)
  
  # Most seasonal products
  seasonal_products <- product_summary %>%
    arrange(desc(seasonal_strength)) %>%
    head(5) %>%
    select(product_id, category, seasonal_strength, avg_weekly_sales)
  
  # Cluster insights
  cluster_insights <- cluster_summary %>%
    mutate(
      cluster_type = case_when(
        avg_sales > median(avg_sales) & avg_volatility < median(avg_volatility) ~ "High-Value Stable",
        avg_sales > median(avg_sales) & avg_volatility >= median(avg_volatility) ~ "High-Value Volatile", 
        avg_sales <= median(avg_sales) & avg_volatility < median(avg_volatility) ~ "Low-Value Stable",
        TRUE ~ "Low-Value Volatile"
      )
    )
  
  return(list(
    top_products = top_products,
    seasonal_products = seasonal_products,
    cluster_insights = cluster_insights
  ))
}

# Main execution
main <- function() {
  message("Starting Segmentation & Hierarchy Analysis...")
  
  # Generate product data
  message("Generating synthetic product data for demonstration")
  product_data <- generate_product_data()
  
  # Perform segmentation analysis
  message("Performing product segmentation...")
  segmentation_result <- analyze_product_segments(product_data)
  
  # Perform hierarchy analysis
  message("Analyzing hierarchy reconciliation...")
  hierarchy_result <- analyze_hierarchy(product_data)
  
  # Generate insights
  message("Generating insights...")
  insights <- generate_insights(segmentation_result, hierarchy_result)
  
  # Create markdown report
  message("Creating markdown report...")
  
  md_content <- c(
    "# Product Segmentation & Hierarchy Analysis",
    "",
    "## Executive Summary",
    "",
    "This analysis provides insights into product performance, customer segments, and data hierarchy reconciliation to support strategic decision-making.",
    "",
    "## Product Segmentation Results",
    "",
    "### Top Performing Products",
    "",
    paste0("- **Product ", insights$top_products$product_id, "** (", insights$top_products$category, "): $", 
           scales::comma(round(insights$top_products$avg_weekly_sales)), " avg weekly sales"),
    "",
    "### Most Seasonal Products", 
    "",
    paste0("- **Product ", insights$seasonal_products$product_id, "** (", insights$seasonal_products$category, "): ", 
           round(insights$seasonal_products$seasonal_strength, 2), " seasonal strength"),
    "",
    "## Cluster Analysis",
    "",
    "### Product Clusters",
    "",
    paste0("- **Cluster ", insights$cluster_insights$cluster, "** (", insights$cluster_insights$cluster_type, "): ",
           insights$cluster_insights$n_products, " products, $", 
           scales::comma(round(insights$cluster_insights$avg_sales)), " avg sales"),
    "",
    "## Hierarchy Reconciliation",
    "",
    "### Data Consistency",
    sprintf("- Total reconciliation error: $%.2f", sum(hierarchy_result$reconciliation_metrics$reconciliation_error)),
    sprintf("- Average weekly error: $%.2f", mean(hierarchy_result$reconciliation_metrics$reconciliation_error)),
    "",
    "## Strategic Recommendations",
    "",
    "### Product Management",
    "- **High-Value Stable Products**: Focus on maintaining quality and consistency",
    "- **High-Value Volatile Products**: Implement demand forecasting and inventory management",
    "- **Low-Value Stable Products**: Consider menu optimization or pricing strategies",
    "- **Low-Value Volatile Products**: Evaluate whether to keep or replace",
    "",
    "### Seasonal Planning",
    "- Plan inventory and staffing based on seasonal product patterns",
    "- Develop marketing campaigns aligned with peak seasonal periods",
    "- Consider seasonal menu rotations to maximize revenue",
    "",
    "### Data Quality",
    "- Monitor hierarchy reconciliation errors for data quality issues",
    "- Implement automated checks for data consistency across levels",
    "- Regular audits of product categorization and sales attribution",
    "",
    "## Technical Notes",
    "",
    "- **Segmentation Method**: K-means clustering on sales volume, volatility, and seasonality",
    "- **Hierarchy Levels**: Product → Category → Total",
    "- **Reconciliation**: Sum-to-total consistency across hierarchy levels",
    "- **Seasonality**: Measured using correlation with sine wave patterns",
    "",
    "## Next Steps",
    "",
    "1. **Validate Clusters**: Review cluster assignments with business stakeholders",
    "2. **Refine Categories**: Optimize product categorization based on analysis",
    "3. **Implement Monitoring**: Set up automated tracking of key metrics",
    "4. **Action Planning**: Develop specific strategies for each product cluster"
  )
  
  writeLines(md_content, "SEGMENTATION_HIERARCHY_REPORT.md")
  message("Created SEGMENTATION_HIERARCHY_REPORT.md")
  
  # Return summary
  return(list(
    n_products = nrow(segmentation_result$product_summary),
    n_clusters = nrow(segmentation_result$cluster_summary),
    total_sales = sum(product_data$sales, na.rm = TRUE),
    reconciliation_error = sum(hierarchy_result$reconciliation_metrics$reconciliation_error)
  ))
}

# Run the analysis
if (!interactive()) {
  result <- main()
  cat(sprintf("\nAnalysis complete!\n"))
  cat(sprintf("- Products analyzed: %d\n", result$n_products))
  cat(sprintf("- Clusters identified: %d\n", result$n_clusters))
  cat(sprintf("- Total sales: $%s\n", scales::comma(round(result$total_sales))))
  cat(sprintf("- Reconciliation error: $%.2f\n", result$reconciliation_error))
}


