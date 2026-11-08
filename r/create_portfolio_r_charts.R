# NYC Motor Vehicle Collision Analysis - Temporal visualizations in R
# Summarizes monthly, weekday, hourly, and severity patterns from the local CSV.
# Exports figures to visualizations/r/ without altering the source data.
# Run from the project root or r/ directory. Requires ggplot2.

library(ggplot2)

# 1. Locate the source dataset and destination folders.
file_name <- "Motor_Vehicle_Collisions_-_Crashes_20260831.csv"

if (file.exists(file.path("data", file_name))) {
  project_root <- "."
} else if (file.exists(file.path("..", "data", file_name))) {
  project_root <- ".."
} else {
  stop(
    "Could not find the CSV. Run from NYC_Collision_Portfolio/ or r/ ",
    "and keep the dataset in NYC_Collision_Portfolio/data/.",
    call. = FALSE
  )
}

source_file <- file.path(project_root, "data", file_name)
figures_dir <- file.path(project_root, "visualizations", "r")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

# 2. Load the source CSV (read only), and check required fields.
crashes <- read.csv(source_file, stringsAsFactors = FALSE)
required <- c(
  "CRASH.DATE", "CRASH.TIME", "NUMBER.OF.PERSONS.KILLED",
  "NUMBER.OF.PERSONS.INJURED"
)
missing_columns <- setdiff(required, names(crashes))
if (length(missing_columns) > 0) {
  stop("Missing CSV columns: ", paste(missing_columns, collapse = ", "))
}

n <- nrow(crashes)
cat("\n=== NYC COLLISION TEMPORAL ANALYSIS ===\n")
cat("Total source records:", format(n, big.mark = ","), "\n")

# Reusable style. Clear labels and footnotes are part of good chart design.
axis_comma <- function(x) format(x, big.mark = ",", trim = TRUE, scientific = FALSE)
portfolio_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "#4B5563"),
    plot.caption = element_text(size = 9, color = "#4B5563", hjust = 0),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.margin = margin(12, 14, 14, 14)
  )

save_png <- function(plot, filename, width = 10, height = 5.7) {
  ggsave(
    filename = file.path(figures_dir, filename),
    plot = plot, width = width, height = height, units = "in",
    dpi = 200, bg = "white"
  )
  cat("Saved: visualizations/r/", filename, "\n", sep = "")
}

# 3. Parse dates and check for missing or invalid dates.
crash_date <- as.Date(crashes$CRASH.DATE, format = "%m/%d/%Y")
valid_date <- !is.na(crash_date)
cat("Valid crash dates:", sum(valid_date), "\n")
cat("Missing/invalid crash dates:", sum(!valid_date), "\n")
if (!any(valid_date)) stop("No valid crash dates found.")

# CHART 1: Monthly collision counts, with a true date axis.
month_start <- as.Date(format(crash_date[valid_date], "%Y-%m-01"))
all_months <- seq(min(month_start), max(month_start), by = "month")
monthly_counts <- as.integer(table(factor(
  as.character(month_start), levels = as.character(all_months)
)))
monthly <- data.frame(month = all_months, crashes = monthly_counts)

monthly_plot <- ggplot(monthly, aes(x = month, y = crashes)) +
  geom_line(color = "#3274A1", linewidth = 1.1) +
  geom_point(color = "#3274A1", size = 2) +
  scale_x_date(date_breaks = "3 months", date_labels = "%b %Y") +
  scale_y_continuous(labels = axis_comma, expand = expansion(mult = c(0.04, 0.08))) +
  labs(
    title = "Recorded NYC collisions by month (2024-2025)",
    subtitle = "Monthly frequency across the 2024-2025 collision dataset",
    x = "Crash month", y = "Number of recorded collisions",
    caption = paste0(
      "Based on ", format(sum(valid_date), big.mark = ","),
      " records with valid dates. Counts are descriptive and not traffic-adjusted."
    )
  ) +
  portfolio_theme +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

save_png(monthly_plot, "04_r_monthly_collision_trend.png", width = 11, height = 6)
cat("Monthly collision counts (first and last three months):\n")
print(rbind(head(monthly, 3), tail(monthly, 3)), row.names = FALSE)

# ANALYTICAL CHECK: February has fewer days than most months. Compare
# average recorded collisions per CALENDAR day, not just monthly totals.
# This is not a traffic-adjusted rate and assumes the extract has full
# reporting coverage throughout each calendar month.
next_month <- seq(from = all_months[1], by = "month", length.out = length(all_months) + 1L)[-1]
monthly$days_in_month <- as.integer(next_month - all_months)
monthly$average_per_day <- monthly$crashes / monthly$days_in_month

cat("\nMonthly counts adjusted for number of calendar days:\n")
print(monthly[, c("month", "crashes", "days_in_month", "average_per_day")],
      row.names = FALSE)
cat("Source date range:", as.character(min(crash_date, na.rm = TRUE)),
    "to", as.character(max(crash_date, na.rm = TRUE)), "\n")
if (min(crash_date, na.rm = TRUE) > min(all_months)) {
  cat("NOTE: The first source record is after the first day of the initial month. ",
      "Verify coverage before interpreting that month's daily average.\n", sep = "")
}

average_daily_plot <- ggplot(monthly, aes(x = month, y = average_per_day)) +
  geom_line(color = "#3274A1", linewidth = 1.1) +
  geom_point(color = "#3274A1", size = 2) +
  scale_x_date(date_breaks = "3 months", date_labels = "%b %Y") +
  scale_y_continuous(labels = function(x) sprintf("%.0f", x),
                     expand = expansion(mult = c(0.04, 0.08))) +
  labs(
    title = "Average recorded collisions per calendar day by month",
    subtitle = "Monthly collision count divided by number of calendar days in that month",
    x = "Crash month", y = "Average recorded collisions per day",
    caption = paste0(
      "Adjusts for month length (including leap-year February 2024). ",
      "Assumes complete monthly reporting; not adjusted for traffic volume."
    )
  ) +
  portfolio_theme +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

save_png(average_daily_plot, "07_r_average_collisions_per_day.png", width = 11, height = 6)

# 4. Parse crash times; report invalid times rather than silently dropping them.
raw_time <- trimws(as.character(crashes$CRASH.TIME))
valid_time <- !is.na(raw_time) & grepl(
  "^([01]?[0-9]|2[0-3]):[0-5][0-9]$", raw_time
)
crash_hour <- rep(NA_integer_, n)
crash_hour[valid_time] <- as.integer(sub(":.*$", "", raw_time[valid_time]))

# as.POSIXlt(...)$wday: Sunday = 0, Monday = 1 ... Saturday = 6.
# Convert to Monday = 1 ... Sunday = 7 without relying on Mac locale.
weekday_num <- rep(NA_integer_, n)
weekday_num[valid_date] <-
  ((as.POSIXlt(crash_date[valid_date])$wday + 6L) %% 7L) + 1L
weekday_names <- c(
  "Monday", "Tuesday", "Wednesday", "Thursday",
  "Friday", "Saturday", "Sunday"
)

valid_day_hour <- !is.na(weekday_num) & !is.na(crash_hour)
cat("Valid day + hour records:", sum(valid_day_hour), "\n")
cat("Excluded from day/hour chart:", sum(!valid_day_hour), "\n")
if (!any(valid_day_hour)) stop("No records with valid crash day and hour.")

# DATA-QUALITY CHECK: midnight may be a true crash time OR a default time
# used when the original time was unknown. Counts cannot prove which.
# Examine how often EXACTLY midnight appears before interpreting the dark
# 00:00 cells as a real peak in crash occurrence.
exact_midnight <- sum(valid_day_hour & (raw_time %in% c("0:00", "00:00")))
midnight_hour <- sum(valid_day_hour & crash_hour == 0L)
hour_one <- sum(valid_day_hour & crash_hour == 1L)
hour_23 <- sum(valid_day_hour & crash_hour == 23L)
cat("\n=== MIDNIGHT TIME QUALITY CHECK ===\n")
cat("Exactly 00:00 (or 0:00):", format(exact_midnight, big.mark = ","), "\n")
cat("Total records from 00:00 through 00:59:",
    format(midnight_hour, big.mark = ","), "\n")
cat("Hour 01:00–01:59:", format(hour_one, big.mark = ","), "\n")
cat("Hour 23:00–23:59:", format(hour_23, big.mark = ","), "\n")
if (midnight_hour > 0L) {
  cat("Exactly midnight as a share of hour-00 records:",
      sprintf("%.1f%%", 100 * exact_midnight / midnight_hour), "\n")
}
cat("Most frequent recorded times within the 00:00–00:59 hour:\n")
print(head(sort(table(raw_time[valid_day_hour & crash_hour == 0L]),
                decreasing = TRUE), 10))
cat("NOTE: A concentration at 00:00 suggests a possible placeholder, ",
    "but does not establish one without source documentation.\n", sep = "")

# CHART 2: Heatmap by weekday and hour (counts, not traffic-adjusted risk).
heatmap_counts <- as.data.frame(table(
  factor(crash_hour[valid_day_hour], levels = 0:23),
  factor(weekday_num[valid_day_hour], levels = 1:7)
))
names(heatmap_counts) <- c("hour", "weekday", "crash_count")
heatmap_counts$weekday <- factor(
  as.integer(as.character(heatmap_counts$weekday)),
  levels = 1:7, labels = weekday_names
)

heatmap_plot <- ggplot(heatmap_counts, aes(x = hour, y = weekday, fill = crash_count)) +
  geom_tile(color = "white", linewidth = 0.2) +
  scale_y_discrete(limits = rev(weekday_names)) +
  scale_x_discrete(
    breaks = as.character(seq(0, 21, by = 3)),
    labels = paste0(sprintf("%02d", seq(0, 21, by = 3)), ":00")
  ) +
  scale_fill_gradient(
    low = "#E7F1F8", high = "#3274A1", labels = axis_comma,
    name = "Crashes"
  ) +
  labs(
    title = "Recorded collisions by day of week and hour",
    subtitle = "Darker cells indicate more recorded collisions",
    x = "Hour of day (24-hour clock)", y = NULL,
    caption = paste0(
      format(sum(valid_day_hour), big.mark = ","),
      " valid day/hour records; ", sum(!valid_day_hour),
      " excluded for missing/invalid date or time. Not traffic-adjusted.\n",
      "Midnight times are shown as recorded; whether 00:00 includes defaults has not been verified."
    )
  ) +
  portfolio_theme +
  theme(panel.grid = element_blank())

save_png(heatmap_plot, "05_r_weekday_hour_heatmap.png", width = 11, height = 6)

# 5. Classify Crash Impact from the original injury and fatality fields.
# A confirmed fatality takes priority. Otherwise, missing required values
# remain Unknown rather than being silently interpreted as zero.
killed <- suppressWarnings(as.numeric(crashes$NUMBER.OF.PERSONS.KILLED))
injured <- suppressWarnings(as.numeric(crashes$NUMBER.OF.PERSONS.INJURED))
impact <- rep("Unknown", n)
impact[!is.na(killed) & killed > 0] <- "Fatality"
impact[!is.na(killed) & killed == 0 & !is.na(injured) & injured > 0] <- "Injury"
impact[!is.na(killed) & killed == 0 & !is.na(injured) & injured == 0] <- "No Injury"

cat("Source-aware severity counts:\n")
print(table(factor(impact, levels = c("No Injury", "Injury", "Fatality", "Unknown"))))

# CHART 3: For each weekday, share of CLASSIFIED crashes involving injury/fatality.
# Denominator is the number of known-severity crashes on that weekday.
# This is descriptive, not a causal model or a risk per trip.
valid_severity_day <- !is.na(weekday_num) & impact != "Unknown"
weekday_table <- table(
  factor(weekday_num[valid_severity_day], levels = 1:7),
  factor(impact[valid_severity_day], levels = c("No Injury", "Injury", "Fatality"))
)
day_total <- rowSums(weekday_table)
if (any(day_total == 0)) stop("At least one weekday has zero classified records.")
with_injury_or_fatality <- weekday_table[, "Injury"] + weekday_table[, "Fatality"]
severity_day <- data.frame(
  weekday = factor(weekday_names, levels = weekday_names),
  classified_records = as.integer(day_total),
  injury_or_fatality = as.integer(with_injury_or_fatality),
  percent = as.numeric(with_injury_or_fatality / day_total * 100)
)

severity_plot <- ggplot(severity_day, aes(x = weekday, y = percent)) +
  geom_col(fill = "#3274A1", width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", percent)), vjust = -0.5, size = 3.7) +
  scale_y_continuous(
    labels = function(x) paste0(x, "%"),
    limits = c(0, max(severity_day$percent) * 1.2)
  ) +
  labs(
    title = "Share of crashes involving injury or fatality by weekday",
    subtitle = "Within each weekday, percent of crashes with a known severity classification",
    x = NULL, y = "Share of classified collisions (%)",
    caption = paste0(
      "Includes ", format(sum(valid_severity_day), big.mark = ","),
      " dated crashes with known severity. Unknown or invalid dates excluded. ",
      "Not a traffic-adjusted risk or evidence of causation."
    )
  ) +
  portfolio_theme +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

save_png(severity_plot, "06_r_injury_fatality_share_by_weekday.png", width = 11, height = 6)
cat("Weekday severity comparison:\n")
print(severity_day, row.names = FALSE)

cat("\nTemporal visualization exports complete.\n")
