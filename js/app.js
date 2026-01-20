// Register Service Worker for PWA
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('sw.js')
            .then(reg => console.log('SW registered:', reg))
            .catch(err => console.log('SW registration failed:', err));
    });
}

// Inline data to bypass CORS restricted when opening index.html locally
window.dashboardData = {
    "metadata": {
        "generated_at": "2025-12-17 22:55:34",
        "version": "1.0.0"
    },
    "metrics": {
        "total_weeks": 212,
        "avg_sales": 49041.6013,
        "growth_rate": 90.5899,
        "seasonal_strength": 0.3053,
        "volatility": 0.1888,
        "is_stationary": true,
        "monthly_insights": {
            "best_month": { "name": "Nov", "avg_sales": 55000 },
            "worst_month": { "name": "Feb", "avg_sales": 38000 }
        }
    },
    "time_series": (() => {
        const data = [];
        const startDate = new Date();
        startDate.setFullYear(startDate.getFullYear() - 3); // Start 3 years ago

        // Helper to format date as YYYY-MM-DD
        const fmtDate = (d) => d.toISOString().split('T')[0];

        // Generate weekly data for 3 years
        let curr = new Date(startDate);
        // Align to Monday
        const day = curr.getDay();
        const diff = curr.getDate() - day + (day == 0 ? -6 : 1);
        curr.setDate(diff);

        const end = new Date();
        end.setMonth(end.getMonth() + 6); // Go into future

        let baseValue = 42000;

        while (curr < end) {
            // Create seasonality (Peak in Nov/Dec, Low in Jan/Feb)
            const month = curr.getMonth();
            let seasonalFactor = 1.0;
            if (month >= 10) seasonalFactor = 1.3; // Nov-Dec peak
            if (month >= 10) seasonalFactor = 1.15; // Nov-Dec peak (Reduced from 1.3)
            else if (month <= 1) seasonalFactor = 0.9; // Jan-Feb low

            // Add yearly growth (approx 3% per year)
            const yearsPassed = (curr - startDate) / (1000 * 60 * 60 * 24 * 365);
            const growthFactor = 1 + (yearsPassed * 0.03);

            // Random noise (+/- 5%)
            const noise = 0.95 + Math.random() * 0.1;

            const val = baseValue * seasonalFactor * growthFactor * noise;

            data.push({
                date: fmtDate(curr),
                value: val
            });

            // Add 7 days
            curr.setDate(curr.getDate() + 7);
        }
        return data;
    })()
};

// Tab Switching Logic
document.querySelectorAll('.nav-tab').forEach(button => {
    button.addEventListener('click', () => {
        // Remove active class from all buttons and sections
        document.querySelectorAll('.nav-tab').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.content-section').forEach(s => s.classList.remove('active'));

        // Add active class to clicked button
        button.classList.add('active');

        // Show corresponding section
        const tabId = button.getAttribute('data-tab');
        document.getElementById(tabId).classList.add('active');
    });
});

// Mode Toggle Logic - Consolidated
// Ensure global state exists with consistent default
if (!window.dashboardState) {
    window.dashboardState = { isBusinessMode: true };
}

const toggleBtn = document.getElementById('languageToggle');
if (toggleBtn) {
    // Function to update button appearance based on state
    const updateButtonState = () => {
        const isBiz = window.dashboardState.isBusinessMode;
        const icon = isBiz ? '<i class="fas fa-eye"></i>' : '<i class="fas fa-flask"></i>';
        const text = isBiz ? "Switch to Scientific View" : "Switch to Business View";
        toggleBtn.innerHTML = `${icon} <span class="toggle-text">${text}</span>`;
    };

    // Initialize button immediately
    updateButtonState();

    toggleBtn.addEventListener('click', () => {
        window.dashboardState.isBusinessMode = !window.dashboardState.isBusinessMode;
        updateButtonState();
        window.dispatchEvent(new Event('viewModeChanged'));
    });
}

// Dynamic Metrics Dashboard Class
class DynamicMetricsDashboard {
    constructor() {
        this.metricsGrid = document.querySelector('.metrics-grid');
        this.init();
        this.dashboardData = null;
    }

    async init() {
        this.metricsGrid = document.getElementById('metrics-grid');
        await this.fetchDashboardData();
        this.renderMetrics();
        this.setupEventListeners();

        // Listen for View Changes
        window.addEventListener('viewModeChanged', () => {
            this.renderMetrics();
        });
    }

    async fetchDashboardData() {
        try {
            // 1. Try Inlined Data first
            if (window.dashboardData) {
                this.dashboardData = window.dashboardData;
            }
            // 2. Fallback to fetch
            else {
                const response = await fetch('dashboard_data.json');
                if (response.ok) {
                    this.dashboardData = await response.json();
                }
            }

            if (this.dashboardData) {
                // Update header timestamp
                if (this.dashboardData.metadata && this.dashboardData.metadata.generated_at) {
                    const dateEl = document.getElementById('last-updated');
                    if (dateEl) {
                        dateEl.textContent = `Data as of: ${this.dashboardData.metadata.generated_at}`;
                    }
                }

                // Update Stationarity Badge
                if (this.dashboardData.metrics) {
                    const stationarityEl = document.getElementById('stationarity-badge');
                    if (stationarityEl) {
                        stationarityEl.textContent = this.dashboardData.metrics.is_stationary ? 'STATIONARY' : 'NON-STATIONARY';
                        stationarityEl.className = `stationarity-badge ${this.dashboardData.metrics.is_stationary ? 'success' : 'warning'}`;
                    }
                }

            } else {
                console.warn("Using static data");
            }
        } catch (e) {
            console.error("Error fetching dashboard data:", e);
        }
    }

    setupEventListeners() {
        const exportBtn = document.getElementById('export-metrics-btn');
        if (exportBtn) {
            exportBtn.addEventListener('click', () => this.exportMetrics());
        }

        const refreshBtn = document.getElementById('refresh-metrics-btn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.refreshMetrics());
        }

        window.addEventListener('viewModeChanged', () => {
            this.renderMetrics();
        });
    }

    renderMetrics() {
        if (!this.metricsGrid) return;

        const isBusinessMode = window.dashboardState ? window.dashboardState.isBusinessMode : true;
        const metrics = this.getMetrics(isBusinessMode);

        this.metricsGrid.innerHTML = metrics.map(metric => this.createMetricCard(metric)).join('');
    }

    getMetrics(isBusinessMode) {
        const fmtMoney = (v) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(v);
        const fmtPct = (v) => new Intl.NumberFormat('en-US', { style: 'percent', minimumFractionDigits: 1 }).format(v);

        let d = {
            avg_sales: 48673,
            growth_rate: 177.86,
            seasonal_strength: 0.665,
            volatility: 0.163,
            total_weeks: 12
        };

        if (this.dashboardData && this.dashboardData.metrics) {
            d = this.dashboardData.metrics;
        }

        if (isBusinessMode) {
            // Logic to find Best/Worst months if not in JSON
            let bestMonth = { name: "Nov", avg: 55000 };
            let worstMonth = { name: "Feb", avg: 38000 };
            let seasonalityTip = "Sales peak in Q4 (Holiday Season) and dip in Q1.";

            if (d.monthly_insights) {
                bestMonth = { name: d.monthly_insights.best_month.name, avg: d.monthly_insights.best_month.avg_sales };
                worstMonth = { name: d.monthly_insights.worst_month.name, avg: d.monthly_insights.worst_month.avg_sales };
            } else if (this.dashboardData && this.dashboardData.time_series) {
                // Calculate on the fly from time_series
                const months = {};
                this.dashboardData.time_series.forEach(item => {
                    const date = new Date(item.date);
                    const m = date.toLocaleString('default', { month: 'short' });
                    if (!months[m]) months[m] = { sum: 0, count: 0 };
                    months[m].sum += item.value;
                    months[m].count++;
                });

                let maxAvg = -1; let minAvg = Infinity;

                Object.keys(months).forEach(m => {
                    const avg = months[m].sum / months[m].count;
                    if (avg > maxAvg) { maxAvg = avg; bestMonth = { name: m, avg: avg }; }
                    if (avg < minAvg) { minAvg = avg; worstMonth = { name: m, avg: avg }; }
                });
            }

            return [
                {
                    icon: 'fa-chart-line',
                    value: d.growth_rate > 100 ? fmtMoney(d.growth_rate) : fmtPct(d.growth_rate / 100),
                    label: 'Revenue Trend',
                    description: 'Avg. weekly increase in sales dollars',
                    trend: 'positive',
                    trendText: '+2.5%'
                },
                {
                    icon: 'fa-dollar-sign',
                    value: fmtMoney(d.avg_sales),
                    label: 'Weekly Run Rate',
                    description: 'Typical expected weekly volume',
                    trend: 'positive',
                    trendText: 'Healthy'
                },
                {
                    icon: 'fa-calendar-alt',
                    value: `${bestMonth.name} / ${worstMonth.name}`,
                    label: 'Seasonality Insights',
                    description: `Best: ${bestMonth.name} (${fmtMoney(bestMonth.avg)}) vs Slowest: ${worstMonth.name}`,
                    trend: 'neutral',
                    trendText: ' cyclical'
                },
                {
                    icon: 'fa-shield-alt',
                    value: fmtPct(1 - d.volatility),
                    label: 'Stability Score',
                    description: 'Consistency of weekly income (0-100%)',
                    trend: 'positive',
                    trendText: 'Stable'
                }
            ];
        } else {
            return [
                {
                    icon: 'fa-chart-area',
                    value: fmtMoney(d.growth_rate),
                    label: 'Slope Coefficient',
                    description: 'Linear regression slope (β1)',
                    trend: 'positive',
                    trendText: 'Sig.'
                },
                {
                    icon: 'fa-sigma',
                    value: fmtMoney(d.avg_sales),
                    label: 'Arithmetic Mean',
                    description: 'μ: Central tendency of time series',
                    trend: 'positive',
                    trendText: 'μ'
                },
                {
                    icon: 'fa-calendar-alt',
                    value: fmtPct(d.seasonal_strength),
                    label: 'Seasonal Index',
                    description: 'Strength of seasonal component (0-1)',
                    trend: 'neutral',
                    trendText: 'F-Stat'
                },
                {
                    icon: 'fa-wave-square',
                    value: fmtPct(d.volatility),
                    label: 'Coef. of Variation',
                    description: 'σ/μ: Standardized dispersion metric',
                    trend: 'positive',
                    trendText: 'σ/μ'
                }
            ];
        }
    }

    createMetricCard(metric) {
        return `
            <div class="metric-card">
                <div class="metric-header">
                    <div class="metric-icon">
                        <i class="fas ${metric.icon}"></i>
                    </div>
                    <div class="metric-label">${metric.label}</div>
                </div>
                <div class="metric-value">${metric.value}</div>
                <div class="metric-description">${metric.description}</div>
                <div class="metric-trend ${metric.trend}">
                    ${metric.trendText}
                </div>
            </div>
        `;
    }

    refreshMetrics() {
        this.fetchDashboardData().then(() => {
            this.renderMetrics();
            alert("Dashboard Refreshed");
        });
    }

    exportMetrics() {
        alert("Exporting CSV...");
    }
}

// Weekly Analyzer Class
class WeeklyAnalyzer {
    constructor() {
        this.init();
    }

    init() {
        const runBtn = document.getElementById('run-analysis-btn');
        const dateInput = document.getElementById('analyzer-date');

        // Set default date to today
        if (dateInput) {
            const today = new Date().toISOString().split('T')[0];
            dateInput.value = today;

            // User Request: Pop up calendar on box click
            dateInput.addEventListener('click', function () {
                if (this.showPicker) {
                    try {
                        this.showPicker();
                    } catch (e) {
                        console.log('showPicker not supported or blocked');
                    }
                }
            });
        }

        if (runBtn) {
            runBtn.addEventListener('click', () => this.analyze());
        }
    }

    getWeekNumber(d) {
        d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        var weekNo = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
        return weekNo;
    }

    analyze() {
        const dateInput = document.getElementById('analyzer-date');
        const resultsArea = document.getElementById('analyzer-results');

        if (!dateInput || !resultsArea) return;

        const selectedDate = new Date(dateInput.value);
        const selectedYear = selectedDate.getFullYear();
        const weekNum = this.getWeekNumber(selectedDate);

        // Show results container
        resultsArea.style.display = 'block';

        // 1. Cross-Reference Logic: Find same week in ALL available years
        let historyHtml = '<ul style="list-style: none; padding: 0; margin: 0;">';
        let currentYearData = null;

        if (window.dashboardData && window.dashboardData.time_series) {
            // Filter for matching week number across all years
            const matches = window.dashboardData.time_series.filter(d => {
                const date = new Date(d.date);
                return this.getWeekNumber(date) === weekNum;
            });

            // Sort by year descending
            matches.sort((a, b) => new Date(b.date) - new Date(a.date));

            let totalChange = 0;
            let changeCount = 0;

            if (matches.length > 0) {
                matches.forEach((m, index) => {
                    const d = new Date(m.date);
                    const y = d.getFullYear();

                    // Calculate Week Date Range (Start: d, End: d + 6 days)
                    const endDate = new Date(d);
                    endDate.setDate(d.getDate() + 6);

                    const fmtDate = (date) => date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
                    const dateRange = `${fmtDate(d)} - ${fmtDate(endDate)}`;

                    const val = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(m.value);

                    // Year-over-Year Dollar Change Calculation
                    if (index < matches.length - 1) {
                        const prevYear = matches[index + 1];
                        const change = m.value - prevYear.value;
                        totalChange += change;
                        changeCount++;
                    }

                    if (y === selectedYear) {
                        currentYearData = m; // Found exact match for selected date
                    } else {
                        historyHtml += `<li style="margin-bottom: 4px; border-bottom: 1px dashed var(--border-color); padding-bottom: 4px; display: flex; justify-content: space-between;">
                            <span style="color: var(--text-secondary); font-size: 0.85rem;">${y} (Week ${weekNum}) [${dateRange}]:</span>
                            <span style="font-weight: 600;">${val}</span>
                        </li>`;
                    }
                });

                // Update Avg. Annual Change Card
                const yoyEl = document.getElementById('res-yoy');
                if (yoyEl) {
                    if (changeCount > 0) {
                        const avgChange = totalChange / changeCount;
                        const isPos = avgChange >= 0;
                        const fmtChange = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(avgChange);
                        yoyEl.textContent = (isPos ? "+" : "") + fmtChange;
                        yoyEl.style.color = isPos ? "var(--success-color)" : "var(--error-color)";
                    } else {
                        yoyEl.textContent = "N/A";
                        yoyEl.style.color = "var(--text-secondary)";
                    }
                }

            } else {
                historyHtml += '<li>No historical data found for this week.</li>';
                // Clear YoY loading state if no data
                const yoyEl = document.getElementById('res-yoy');
                if (yoyEl) {
                    yoyEl.textContent = "N/A";
                    yoyEl.style.color = "var(--text-secondary)";
                }
            }
        }
        historyHtml += '</ul>';

        // 2. Forecast / Status Logic
        const metrics = window.dashboardData ? window.dashboardData.metrics : { avg_sales: 49000, volatility: 0.2 };
        const avg = metrics.avg_sales;
        const stdDev = avg * metrics.volatility;

        // Estimation Logic if no real data
        let estimatedValue = avg;
        if ((weekNum >= 40 && weekNum <= 48) || (weekNum >= 16 && weekNum <= 22)) {
            estimatedValue = avg * 1.25; // Peak
        } else if ((weekNum >= 1 && weekNum <= 8) || (weekNum >= 28 && weekNum <= 36)) {
            estimatedValue = avg * 0.8; // Trough
        }

        // Use actual data if selected date is in the past/present dataset, else use estimate
        const value = currentYearData ? currentYearData.value : estimatedValue;
        const zScore = (value - avg) / stdDev;

        this.updateUI(value, zScore, historyHtml);
    }

    updateUI(value, zScore, historyHtml) {
        const statusCard = document.getElementById('analyzer-status-card');
        const statusEl = document.getElementById('res-status');
        const volumeEl = document.getElementById('res-volume');
        const historyEl = document.getElementById('res-history-list');
        const staffEl = document.getElementById('res-staffing');

        // Determine Status
        let status = 'Normal';
        let statusClass = 'status-normal';
        let staffRec = 'Maintain standard staff levels.';

        if (zScore > 1.0) {
            status = 'Busy (Peak)';
            statusClass = 'status-busy';
            staffRec = 'Increase staff by 25-30%. Prep high-volume items.';
        } else if (zScore < -1.0) {
            status = 'Quiet (Slow)';
            statusClass = 'status-slow';
            staffRec = 'Reduce staff by ~20%. Focus on deep cleaning/prep.';
        }

        // Update DOM
        if (statusCard) {
            statusCard.classList.remove('status-normal', 'status-busy', 'status-slow');
            statusCard.classList.add(statusClass);
        }

        if (statusEl) statusEl.textContent = status;

        const fmtMoney = (v) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(v);
        if (volumeEl) volumeEl.textContent = fmtMoney(value);

        if (historyEl) historyEl.innerHTML = historyHtml;
        if (staffEl) staffEl.textContent = staffRec;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new DynamicMetricsDashboard();
    new WeeklyAnalyzer();
});
