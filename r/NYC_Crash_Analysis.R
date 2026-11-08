# NYC Motor Vehicle Collision Analysis — R exploratory analysis
#
# Run from the NYC_Collision_Portfolio folder, or from its r/ folder.
# Keep the source CSV in data/ (excluded from GitHub).
# Severity classifications preserve missing values from the source CSV.

library(ggplot2)

# 1. Find the dataset and choose an output folder.
file_name <- "Motor_Vehicle_Collisions_-_Crashes_20260831.csv"

if (file.exists(file.path("data", file_name))) {
  project_root <- "."
} else if (file.exists(file.path("..", "data", file_name))) {
  project_root <- ".."
} else {
  stop(
    "Dataset not found. Place the CSV in NYC_Collision_Portfolio/data/ ",
    "and run this script from the portfolio root or r/ folder.",
    call. = FALSE
  )
}

csv_file <- file.path(project_root, "data", file_name)
figures_dir <- file.path(project_root, "visualizations", "r")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

# 2. Load and inspect the dataset once.
crashes <- read.csv(csv_file)

cat("\nFIRST FIVE RECORDS:\n")
print(head(crashes))

cat("\nDATASET DIMENSIONS (ROWS, COLUMNS):\n")
print(dim(crashes))

cat("\nDATA TYPES:\n")
str(crashes)

cat("\nMISSING VALUES BY COLUMN:\n")
print(colSums(is.na(crashes)))

# Add row numbers after loading the original records.
crashes$Record_Number <- seq_len(nrow(crashes))

# 3. Create the ordered Crash Impact category.
# Missing values are not assumed to be zeros. A confirmed fatality always
# takes priority; otherwise we need both counts to classify severity.
killed <- crashes$NUMBER.OF.PERSONS.KILLED
injured <- crashes$NUMBER.OF.PERSONS.INJURED

impact_labels <- rep(NA_character_, nrow(crashes))
confirmed_fatality <- !is.na(killed) & killed > 0
confirmed_injury <- !is.na(killed) & killed == 0 &
  !is.na(injured) & injured > 0
confirmed_no_injury <- !is.na(killed) & killed == 0 &
  !is.na(injured) & injured == 0

impact_labels[confirmed_fatality] <- "Fatality"
impact_labels[confirmed_injury] <- "Injury"
impact_labels[confirmed_no_injury] <- "No Injury"

crashes$Crash_Impact <- factor(
  impact_labels,
  levels = c("No Injury", "Injury", "Fatality"),
  ordered = TRUE
)

cat("\nCRASH IMPACT COUNTS (CLASSIFIED ONLY):\n")
print(table(crashes$Crash_Impact))
cat("\nUNCLASSIFIED CRASH IMPACT RECORDS:\n")
print(sum(is.na(crashes$Crash_Impact)))

# 4. Nominal variable: Borough.
borough_missing <- is.na(crashes$BOROUGH) | trimws(crashes$BOROUGH) == ""
known_boroughs <- crashes[!borough_missing, , drop = FALSE]
borough_counts <- table(known_boroughs$BOROUGH)

cat("\nCRASH COUNTS BY KNOWN BOROUGH:\n")
print(borough_counts)
cat("\nPERCENTAGE OF ALL RECORDS BY KNOWN BOROUGH:\n")
print(round(borough_counts / nrow(crashes) * 100, 2))
cat("\nMISSING OR BLANK BOROUGH VALUES:\n")
print(sum(borough_missing))

borough_plot <- ggplot(known_boroughs, aes(x = BOROUGH)) +
  geom_bar() +
  labs(
    title = "Number of Crashes by Borough",
    x = "Borough",
    y = "Number of Crashes"
  ) +
  theme_minimal()

print(borough_plot)
ggsave(
  filename = file.path(figures_dir, "r_crashes_by_borough.png"),
  plot = borough_plot, width = 9, height = 5, dpi = 160
)

# 5. Ordinal variable: Crash Impact.
# Percentages use all 176,615 source records as the denominator, including
# unclassified records. Unknown does not become an ordinal severity level.
cat("\nCRASH IMPACT PERCENTAGES (OF ALL RECORDS):\n")
print(round(table(crashes$Crash_Impact) / nrow(crashes) * 100, 3))
cat("Unknown percentage:",
    round(sum(is.na(crashes$Crash_Impact)) / nrow(crashes) * 100, 5), "\n")

impact_plot <- ggplot(
  crashes[!is.na(crashes$Crash_Impact), , drop = FALSE],
  aes(x = Crash_Impact)
) +
  geom_bar() +
  labs(
    title = "Crashes by Impact Level",
    x = "Crash Impact",
    y = "Number of Crashes"
  ) +
  theme_minimal()

print(impact_plot)
ggsave(
  filename = file.path(figures_dir, "r_crash_impact.png"),
  plot = impact_plot, width = 8, height = 5, dpi = 160
)

# 6. Ratio variable: Number of persons injured.
cat("\nPERSONS INJURED SUMMARY:\n")
print(summary(crashes$NUMBER.OF.PERSONS.INJURED))
cat("Mean:\n")
print(mean(crashes$NUMBER.OF.PERSONS.INJURED, na.rm = TRUE))
cat("Median:\n")
print(median(crashes$NUMBER.OF.PERSONS.INJURED, na.rm = TRUE))
cat("Standard deviation (sample):\n")
print(sd(crashes$NUMBER.OF.PERSONS.INJURED, na.rm = TRUE))

injury_plot <- ggplot(crashes, aes(x = NUMBER.OF.PERSONS.INJURED)) +
  geom_histogram(binwidth = 1) +
  labs(
    title = "Distribution of Persons Injured per Crash",
    x = "Number of Persons Injured",
    y = "Number of Crashes"
  ) +
  theme_minimal()

print(injury_plot)
ggsave(
  filename = file.path(figures_dir, "r_persons_injured.png"),
  plot = injury_plot, width = 8, height = 5, dpi = 160
)

# 7. Interval variable: Crash date and monthly frequency.
crashes$CRASH.DATE <- as.Date(
  crashes$CRASH.DATE,
  format = "%m/%d/%Y"
)

cat("\nCRASH DATE SUMMARY:\n")
print(summary(crashes$CRASH.DATE))

crashes$Crash_Month <- format(crashes$CRASH.DATE, "%Y-%m")
monthly_crashes <- as.data.frame(table(crashes$Crash_Month))

monthly_plot <- ggplot(
  monthly_crashes,
  aes(x = Var1, y = Freq, group = 1)
) +
  geom_line() +
  labs(
    title = "Crashes Over Time",
    x = "Month",
    y = "Number of Crashes"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

print(monthly_plot)
ggsave(
  filename = file.path(figures_dir, "r_monthly_crashes.png"),
  plot = monthly_plot, width = 10, height = 5, dpi = 160
)

cat("\nFour R visualizations saved to:\n")
cat(normalizePath(figures_dir), "\n")
