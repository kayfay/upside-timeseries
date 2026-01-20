document.addEventListener('DOMContentLoaded', () => {
    // Check if Chart.js is loaded
    if (typeof Chart === 'undefined') {
        console.warn('Chart.js not loaded - showing fallback images');
        showFallbacks();
        return;
    }

    const data = window.dashboardData ? window.dashboardData.time_series : null;

    // If no data, show fallbacks
    if (!data || data.length === 0) {
        showFallbacks();
        return;
    }

    const labels = data.map(d => d.date);
    const values = data.map(d => d.value);

    // 1. Trajectory Chart
    const ctx1 = document.getElementById('chart-trajectory');
    if (ctx1) {
        new Chart(ctx1, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Weekly Sales',
                    data: values,
                    borderColor: '#2563EB',
                    backgroundColor: 'rgba(37, 99, 235, 0.05)',
                    borderWidth: 2,
                    pointRadius: 0,
                    pointHoverRadius: 4,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                aspectRatio: 1.5,
                interaction: {
                    mode: 'index',
                    intersect: false,
                },
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: (ctx) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(ctx.raw)
                        }
                    }
                },
                scales: {
                    x: {
                        display: false
                    },
                    y: {
                        beginAtZero: false,
                        ticks: {
                            callback: (val) => '$' + (val / 1000) + 'k'
                        },
                        grid: {
                            color: '#F3F4F6'
                        }
                    }
                }
            }
        });
    }

    // 2. Decomposition Chart
    // Since we don't have the decomposed components in the JSON, we retain the scientific image.
    // This function hides the canvas and shows the fallback div for the decomposition chart specifically.
    const ctx2 = document.getElementById('chart-trajectory');
    const decompCanvas = document.getElementById('chart-decomposition');
    if (decompCanvas) {
        decompCanvas.style.display = 'none';
        const fallback = decompCanvas.nextElementSibling;
        if (fallback && fallback.classList.contains('no-js-chart')) {
            fallback.style.display = 'block';
        }
    }

    // Chart.js Default Font
    Chart.defaults.font.family = "'Inter', system-ui, -apple-system, sans-serif";
    Chart.defaults.color = '#6B7280';
});

function showFallbacks() {
    document.querySelectorAll('canvas').forEach(c => c.style.display = 'none');
    document.querySelectorAll('.no-js-chart').forEach(d => d.style.display = 'block');
}
