# Editorial-Style Business Intelligence Dashboard
# Redesigned with data journalism aesthetic - avoiding generic AI patterns
# Inspired by Bloomberg Businessweek, FiveThirtyEight, The Economist

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(gridExtra)
library(ggtext)
library(showtext)

# Attempt to load custom fonts (graceful fallback if not available)
tryCatch({
  font_add_google("Playfair Display", "playfair")  # Elegant serif for headlines
  font_add_google("Source Sans Pro", "source")    # Clean sans for body
  font_add_google("IBM Plex Mono", "ibm")         # Monospace for numbers
  showtext_auto()
}, error = function(e) {
  message("Custom fonts not available, using system defaults")
})

# Create enhanced business metrics data
business_metrics <- data.frame(
  metric = c(
    "Total Sales Period",
    "Average Original Sales",
    "Growth Rate (per week)",
    "Original Peak Weeks",
    "Detrended Peak Weeks", 
    "Seasonal Strength",
    "Original Volatility (CV)",
    "Detrended Volatility (CV)",
    "Detrended Stationarity",
    "Trend Significance",
    "Forecast Horizon",
    "Average Detrended Sales"
  ),
  value = c(
    "107 weeks",
    "$48,673",
    "$177.86",
    "11 weeks",
    "11 weeks",
    "66.5%",
    "16.3%",
    "-105.3%",
    "Non-stationary",
    "Significant",
    "12 weeks",
    "-$42"
  ),
  importance = c(
    "High",
    "High", 
    "High",
    "Medium",
    "Medium",
    "High",
    "Medium",
    "Medium",
    "Low",
    "High",
    "Medium",
    "Low"
  ),
  category = c(
    "Scale", "Scale", "Momentum", "Pattern", "Pattern",
    "Pattern", "Risk", "Risk", "Risk", "Confidence", "Confidence", "Scale"
  )
)

# Editorial color palette - earth tones, muted, sophisticated
editorial_colors <- list(
  high_primary = "#8B4513",      # Saddle brown - warm, authoritative
  high_accent = "#CD853F",        # Peru - lighter warm tone
  medium = "#6B8E6B",             # Sage green - calm, balanced
  low = "#D3D3D3",                # Light gray - subtle
  background = "#FDFBF7",         # Warm off-white (like aged paper)
  text_dark = "#2C2416",          # Almost black with brown undertone
  text_medium = "#5C4E37",        # Medium brown-gray
  accent_warm = "#C97D60",        # Terracotta
  accent_cool = "#7A9CC6"         # Dusty blue
)

# Helper function to create metric value with custom formatting
format_metric_value <- function(val, importance) {
  if (importance == "High") {
    return(paste0("<span style='font-size:18pt; font-weight:700; color:", 
                  editorial_colors$high_primary, "'>", val, "</span>"))
  } else if (importance == "Medium") {
    return(paste0("<span style='font-size:16pt; font-weight:600; color:", 
                  editorial_colors$medium, "'>", val, "</span>"))
  } else {
    return(paste0("<span style='font-size:14pt; color:", 
                  editorial_colors$text_medium, "'>", val, "</span>"))
  }
}

# Create editorial-style main visualization
# Asymmetric layout with emphasis on hierarchy through size, not just color
enhanced_summary <- ggplot(business_metrics, aes(x = reorder(metric, desc(importance)))) +
  
  # Background: subtle paper texture effect using very light rectangles
  geom_rect(aes(xmin = -Inf, xmax = Inf, ymin = 0, ymax = 1), 
            fill = editorial_colors$background, color = NA) +
  
  # Vertical accent lines - editorial style guide lines
  geom_vline(xintercept = seq(0.5, 12.5, by = 1), 
             color = "#E8E4DC", size = 0.3, linetype = "dotted", alpha = 0.5) +
  
  # Importance-based horizontal bars - but thinner, more subtle
  geom_bar(aes(y = 1, fill = importance), 
           stat = "identity", 
           alpha = 0.15, 
           width = 0.6,
           position = position_nudge(y = 0)) +
  
  # Thick accent line for high importance metrics
  geom_segment(aes(x = metric, xend = metric, 
                   y = 0.05, yend = 0.95),
               data = business_metrics %>% filter(importance == "High"),
               color = editorial_colors$high_primary,
               size = 3.5,
               alpha = 0.4) +
  
  # Category labels - small, subtle, positioned left
  geom_text(aes(label = category, y = 0.15),
            size = 3.2,
            color = editorial_colors$text_medium,
            fontface = "italic",
            angle = 0,
            hjust = 0,
            family = if(exists("source")) "source" else "sans") +
  
  # Metric names - large, varied sizes based on importance
  geom_text(aes(label = metric, y = 0.5),
            size = ifelse(business_metrics$importance == "High", 5.5,
                         ifelse(business_metrics$importance == "Medium", 4.8, 4.2)),
            fontface = ifelse(business_metrics$importance == "High", "bold", "plain"),
            color = editorial_colors$text_dark,
            hjust = 0,
            x = as.numeric(reorder(business_metrics$metric, desc(business_metrics$importance))) + 0.35,
            family = if(exists("source")) "source" else "sans") +
  
  # Values - large, bold, right-aligned with emphasis
  geom_richtext(aes(label = paste0("<span style='font-size:",
                                    ifelse(importance == "High", "20", 
                                          ifelse(importance == "Medium", "16", "13")),
                                    "pt; font-weight:700; color:",
                                    ifelse(importance == "High", editorial_colors$high_primary,
                                          ifelse(importance == "Medium", editorial_colors$medium, 
                                                editorial_colors$text_medium)),
                                    "'>", value, "</span>"),
                 y = 0.5),
            hjust = 1,
            x = 12.2,
            fill = NA,
            label.color = NA,
            family = if(exists("ibm")) "ibm" else "mono") +
  
  # Custom fill colors - muted, sophisticated
  scale_fill_manual(values = c(
    "High" = editorial_colors$high_primary,
    "Medium" = editorial_colors$medium, 
    "Low" = editorial_colors$low
  )) +
  
  # Editorial theme - minimal, clean, lots of whitespace
  theme_void() +
  theme(
    plot.background = element_rect(fill = editorial_colors$background, color = NA),
    panel.background = element_rect(fill = editorial_colors$background, color = NA),
    
    # Typography - editorial style
    plot.title = element_text(
      size = 36,
      face = "bold",
      color = editorial_colors$text_dark,
      margin = margin(b = 8, t = 20),
      hjust = 0,
      family = if(exists("playfair")) "playfair" else "serif"
    ),
    plot.subtitle = element_text(
      size = 14,
      color = editorial_colors$text_medium,
      margin = margin(b = 35, t = 0),
      hjust = 0,
      lineheight = 1.6,
      family = if(exists("source")) "source" else "sans"
    ),
    plot.caption = element_text(
      size = 10,
      color = editorial_colors$text_medium,
      margin = margin(t = 25),
      hjust = 1,
      family = if(exists("source")) "source" else "sans"
    ),
    
    # Remove all default elements
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    legend.position = "none",
    
    # Generous margins - editorial breathing room
    plot.margin = margin(50, 60, 50, 60)
  ) +
  
  # Editorial labels - understated, informative
  labs(
    title = "Business Performance Metrics",
    subtitle = "Twelve indicators derived from 107 weeks of sales data. Metrics are organized by statistical importance, with high-priority indicators shown in bold. The analysis accounts for both trend and seasonal components.",
    caption = "Analysis period: July 2023 — July 2025 | Data processed using detrended time series methodology"
  ) +
  
  coord_flip() +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_x_discrete(expand = c(0.1, 0.1))

# Create insights visualization with editorial card layout
key_insights_data <- data.frame(
  insight = c(
    "Strong Seasonal Patterns",
    "Healthy Growth Trajectory", 
    "Predictable Peak Periods",
    "Manageable Volatility",
    "Reliable Forecasting"
  ),
  description = c(
    "66.5% seasonal strength indicates clear recurring patterns",
    "$177.86 weekly growth rate shows consistent expansion",
    "11 peak weeks identified for strategic planning",
    "16.3% CV shows stable performance metrics",
    "12-week forecast horizon with high confidence"
  ),
  stat = c("66.5%", "$177.86", "11", "16.3%", "12"),
  stat_label = c("Seasonal", "Weekly", "Peaks", "Volatility", "Weeks"),
  position = c(1, 2, 3, 4, 5)
)

# Editorial insights layout - card-based but asymmetric
insights_viz <- ggplot(key_insights_data, aes(x = position)) +
  
  # Background
  geom_rect(aes(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf),
            fill = editorial_colors$background, color = NA) +
  
  # Card backgrounds - varying widths for visual interest
  geom_rect(aes(xmin = position - 0.35, xmax = position + 0.35,
                ymin = 0.05, ymax = 0.95),
            fill = "white",
            color = editorial_colors$text_medium,
            size = 0.8,
            alpha = 0.9) +
  
  # Accent bars on left side of cards
  geom_rect(aes(xmin = position - 0.35, xmax = position - 0.28,
                ymin = 0.05, ymax = 0.95),
            fill = editorial_colors$accent_warm,
            color = NA) +
  
  # Large statistic - editorial style
  geom_text(aes(label = stat, y = 0.75),
            size = 24,
            fontface = "bold",
            color = editorial_colors$high_primary,
            hjust = 0.5,
            family = if(exists("ibm")) "ibm" else "mono") +
  
  # Stat label
  geom_text(aes(label = stat_label, y = 0.65),
            size = 9,
            color = editorial_colors$text_medium,
            hjust = 0.5,
            fontface = "italic",
            family = if(exists("source")) "source" else "sans") +
  
  # Insight title
  geom_text(aes(label = insight, y = 0.45),
            size = 5.5,
            fontface = "bold",
            color = editorial_colors$text_dark,
            hjust = 0.5,
            family = if(exists("source")) "source" else "sans") +
  
  # Description
  geom_text(aes(label = description, y = 0.25),
            size = 3.8,
            color = editorial_colors$text_medium,
            hjust = 0.5,
            lineheight = 1.3,
            family = if(exists("source")) "source" else "sans") +
  
  theme_void() +
  theme(
    plot.background = element_rect(fill = editorial_colors$background, color = NA),
    panel.background = element_rect(fill = editorial_colors$background, color = NA),
    plot.title = element_text(
      size = 28,
      face = "bold",
      color = editorial_colors$text_dark,
      margin = margin(b = 25, t = 15),
      hjust = 0,
      family = if(exists("playfair")) "playfair" else "serif"
    ),
    plot.margin = margin(30, 40, 30, 40)
  ) +
  
  labs(title = "Key Findings") +
  
  scale_x_continuous(limits = c(0.5, 5.5), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0))

# Save the enhanced visualization
ggsave(
  "07_enhanced_business_insights_summary.png",
  enhanced_summary,
  width = 18,
  height = 12,
  dpi = 300,
  bg = editorial_colors$background
)

# Save insights separately
ggsave(
  "07b_key_insights_summary.png", 
  insights_viz,
  width = 18,
  height = 6,
  dpi = 300,
  bg = editorial_colors$background
)

cat("Editorial-style Business Intelligence Dashboard created successfully!\n")
cat("Files saved:\n")
cat("- 07_enhanced_business_insights_summary.png (main metrics)\n")
cat("- 07b_key_insights_summary.png (insights)\n")
cat("\nDesign philosophy: Editorial data journalism aesthetic\n")
cat("- Typography-first hierarchy\n")
cat("- Asymmetric, hand-crafted layouts\n")
cat("- Muted earth-tone palette\n")
cat("- Generous whitespace\n")
cat("- Print-inspired warmth\n")
