# Enhanced Business Intelligence Summary Visualization
# Senior UI/UX Data Visualization using ggplot2

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(gridExtra)

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
  )
)

# Create a simple, clean visualization
enhanced_summary <- ggplot(business_metrics, aes(x = reorder(metric, desc(importance)), y = 1)) +
  # Background bars with importance-based colors
  geom_bar(aes(fill = importance), stat = "identity", alpha = 0.7, width = 0.8) +
  
  # Metric names - positioned clearly on the left
  geom_text(aes(label = metric), 
            hjust = 0, 
            x = 0.2, 
            size = 5, 
            fontface = "bold",
            color = "#2c3e50") +
  
  # Values - positioned clearly on the right
  geom_text(aes(label = value), 
            hjust = 1, 
            x = 12.8, 
            size = 4.8, 
            fontface = "bold",
            color = "#34495e") +
  
  # Custom color palette for importance levels
  scale_fill_manual(values = c(
    "High" = "#3498db",
    "Medium" = "#95a5a6", 
    "Low" = "#ecf0f1"
  )) +
  
  # Theme enhancements
  theme_minimal() +
  theme(
    # Remove unnecessary elements
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    
    # Enhanced typography
    text = element_text(family = "sans", color = "#2c3e50"),
    plot.title = element_text(
      size = 28, 
      face = "bold", 
      color = "#2c3e50",
      margin = margin(b = 25)
    ),
    plot.subtitle = element_text(
      size = 16, 
      color = "#7f8c8d",
      margin = margin(b = 35)
    ),
    plot.caption = element_text(
      size = 12, 
      color = "#95a5a6",
      margin = margin(t = 25)
    ),
    
    # Remove legend
    legend.position = "none",
    
    # Proper spacing
    plot.margin = margin(40, 25, 40, 25)
  ) +
  
  # Enhanced labels
  labs(
    title = "Advanced Business Insights Summary",
    subtitle = "Critical metrics derived from trend-adjusted seasonal analysis",
    caption = "Comprehensive analysis using detrended data and advanced statistical modeling"
  ) +
  
  # Coordinate system adjustments
  coord_flip() +
  scale_y_continuous(limits = c(0, 1.2), expand = c(0, 0)) +
  scale_x_discrete(expand = c(0, 0))

# Create a simple insights visualization
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
  icon = c("📈", "🚀", "🎯", "📊", "🔮"),
  color = c("#e74c3c", "#27ae60", "#f39c12", "#9b59b6", "#3498db")
)

insights_viz <- ggplot(key_insights_data, aes(x = reorder(insight, desc(insight)), y = 1)) +
  geom_bar(aes(fill = color), stat = "identity", alpha = 0.8, width = 0.7) +
  
  # Icons
  geom_text(aes(label = icon), 
            x = 0.3, 
            size = 7) +
  
  # Insight titles
  geom_text(aes(label = insight), 
            hjust = 0, 
            x = 1.0, 
            size = 5, 
            fontface = "bold",
            color = "#2c3e50") +
  
  # Descriptions
  geom_text(aes(label = description), 
            hjust = 0, 
            x = 1.0, 
            y = 0.5,
            size = 3.5, 
            color = "#7f8c8d") +
  
  scale_fill_identity() +
  
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    text = element_text(family = "sans", color = "#2c3e50"),
    plot.title = element_text(
      size = 22, 
      face = "bold", 
      color = "#2c3e50",
      margin = margin(b = 20)
    ),
    legend.position = "none",
    plot.margin = margin(25, 20, 25, 20)
  ) +
  
  labs(title = "Key Business Intelligence Insights") +
  
  coord_flip() +
  scale_y_continuous(limits = c(0, 1.2), expand = c(0, 0)) +
  scale_x_discrete(expand = c(0, 0))

# Save the enhanced visualization
ggsave(
  "07_enhanced_business_insights_summary.png",
  enhanced_summary,
  width = 16,
  height = 10,
  dpi = 300,
  bg = "white"
)

# Save insights separately
ggsave(
  "07b_key_insights_summary.png", 
  insights_viz,
  width = 16,
  height = 5,
  dpi = 300,
  bg = "white"
)

cat("Enhanced Business Intelligence Summary visualizations created successfully!\n")
cat("Files saved:\n")
cat("- 07_enhanced_business_insights_summary.png (main metrics)\n")
cat("- 07b_key_insights_summary.png (insights)\n")
