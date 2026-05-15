// Dashboard measurement charts using Chart.js

document.addEventListener("turbo:load", initMeasurementCharts);
document.addEventListener("DOMContentLoaded", initMeasurementCharts);

function initMeasurementCharts() {
  const charts = document.querySelectorAll(".measurement-chart-container canvas");

  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  charts.forEach((canvas) => {
    const ctx = canvas.getContext("2d");
    const labels = JSON.parse(canvas.dataset.labels || "[]");
    const values = JSON.parse(canvas.dataset.values || "[]");
    const unit = canvas.dataset.unit || "";

    if (labels.length === 0) return;

    const chartId = canvas.id;
    if (window[chartId + "_instance"]) {
      window[chartId + "_instance"].destroy();
    }

    const parsedValues = values.map((v) => {
      if (typeof v === "string" && v.includes("/")) {
        return parseFloat(v.split("/")[0]);
      }
      return parseFloat(v) || 0;
    });

    const isWeight = chartId.includes("weight");
    const isBp = chartId.includes("blood_pressure");
    const isSpo2 = chartId.includes("spo2");
    const isHeartBeat = chartId.includes("heart_beat");
    const isSugar = chartId.includes("sugar");

    let color = "#0d7377";
    let bgColor = "rgba(13, 115, 119, 0.1)";

    if (isWeight) {
      color = "#10b981";
      bgColor = "rgba(16, 185, 129, 0.1)";
    } else if (isSpo2) {
      color = "#0ea5e9";
      bgColor = "rgba(14, 165, 233, 0.1)";
    } else if (isHeartBeat) {
      color = "#ef4444";
      bgColor = "rgba(239, 68, 68, 0.1)";
    } else if (isSugar) {
      color = "#f59e0b";
      bgColor = "rgba(245, 158, 11, 0.1)";
    } else if (isBp) {
      color = "#8b5cf6";
      bgColor = "rgba(139, 92, 246, 0.1)";
    }

    const gradient = ctx.createLinearGradient(0, 0, 0, canvas.offsetHeight);
    gradient.addColorStop(0, bgColor.replace("0.1", "0.3"));
    gradient.addColorStop(1, bgColor.replace("0.1", "0"));

    const chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: labels,
        datasets: [
          {
            label: unit ? `Value (${unit})` : "Value",
            data: parsedValues,
            borderColor: color,
            backgroundColor: gradient,
            fill: true,
            tension: 0.4,
            pointRadius: 4,
            pointBackgroundColor: color,
            pointBorderColor: "#fff",
            pointBorderWidth: 2,
            pointHoverRadius: 6,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: prefersReducedMotion ? false : {
          duration: 1000,
          easing: "easeOutQuart"
        },
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
            mode: "index",
            intersect: false,
            backgroundColor: "#232b39",
            titleColor: "#fff",
            bodyColor: "#fff",
            padding: 12,
            cornerRadius: 6,
            displayColors: false,
            callbacks: {
              label: function(context) {
                return context.parsed.y + (unit ? " " + unit : "");
              }
            }
          },
        },
        scales: {
          x: {
            display: true,
            grid: {
              display: false,
            },
            ticks: {
              maxTicksLimit: 7,
              color: "#64748b",
              font: {
                size: 11,
              },
            },
          },
          y: {
            display: true,
            grid: {
              color: "#e2e8f0",
            },
            ticks: {
              color: "#64748b",
              font: {
                size: 11,
              },
            },
          },
        },
        interaction: {
          mode: "nearest",
          axis: "x",
          intersect: false,
        },
      },
    });

    window[chartId + "_instance"] = chart;
  });
}