"""Explore collision records, data quality, severity, and descriptive statistics.

Uses the 2024–2025 NYC collision extract and preserves missing fatality
information when deriving the Crash Impact category.
"""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # Save figures without opening a display window (e.g., on EC2).

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns


# Paths are based on this script's location, not the current working directory.
# Place the source CSV in the local data/ folder, which is excluded from GitHub.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
CSV_FILE = PROJECT_ROOT / "data" / "Motor_Vehicle_Collisions_-_Crashes_20260831.csv"
FIGURES_DIR = PROJECT_ROOT / "visualizations"


def main():
    if not CSV_FILE.is_file():
        raise FileNotFoundError(
            f"Could not find the dataset at:\n{CSV_FILE}\n\n"
            "Place the matching 2024–2025 CSV extract in the project data/ folder."
        )

    FIGURES_DIR.mkdir(parents=True, exist_ok=True)
    df = pd.read_csv(CSV_FILE, low_memory=False)

    required_columns = [
        "CRASH DATE", "BOROUGH", "NUMBER OF PERSONS INJURED",
        "NUMBER OF PERSONS KILLED",
    ]
    missing_columns = [col for col in required_columns if col not in df.columns]
    if missing_columns:
        raise ValueError(f"Required CSV columns are missing: {missing_columns}")

    # 1. Initial exploration and quality checks
    print("FIRST FIVE RECORDS:")
    print(df.head())
    print("\nDATASET SHAPE:", df.shape)
    print("\nCOLUMN NAMES:", list(df.columns))
    print("\nDUPLICATE RECORDS:", df.duplicated().sum())
    print("\nMISSING VALUES:")
    print(df.isna().sum())

    # Add record numbers only after the original duplicate check.
    df.insert(0, "Record Number", range(1, len(df) + 1))
    df["CRASH DATE"] = pd.to_datetime(df["CRASH DATE"], errors="coerce")

    print("\nCRASHES BY YEAR:")
    print(df["CRASH DATE"].dt.year.value_counts().sort_index())

    # 2. Derived ordinal variable: Crash Impact
    # Preserve missing fatality/injury counts rather than assuming they are 0.
    # Priority: confirmed fatality > unknown required field > confirmed injury
    # > confirmed no injury. Unknown is not an ordered severity category.
    killed = pd.to_numeric(df["NUMBER OF PERSONS KILLED"], errors="coerce")
    injured = pd.to_numeric(df["NUMBER OF PERSONS INJURED"], errors="coerce")

    impact_labels = np.select(
        [
            killed.gt(0),
            killed.isna() | injured.isna(),
            injured.gt(0),
            killed.eq(0) & injured.eq(0),
        ],
        ["Fatality", "Unknown", "Injury", "No Injury"],
        default="Unknown",
    )
    unknown_count = int((impact_labels == "Unknown").sum())
    # pd.Categorical converts labels absent from its ordered levels to NA.
    # This keeps Unknown distinct from the three ordered severity levels.
    df["Crash Impact"] = pd.Categorical(
        impact_labels,
        categories=["No Injury", "Injury", "Fatality"],
        ordered=True,
    )

    print("\nCRASH IMPACT COUNTS:")
    print(df["Crash Impact"].value_counts(sort=False))
    print("Unclassified (Unknown):", unknown_count)

    # 3. Nominal: crash frequency by known borough
    print("\nBOROUGH COUNTS (KNOWN BOROUGHS):")
    borough_counts = df["BOROUGH"].value_counts()
    print(borough_counts)
    print("Missing boroughs:", df["BOROUGH"].isna().sum())

    plt.figure(figsize=(9, 5))
    sns.countplot(data=df, x="BOROUGH", order=borough_counts.index, color="steelblue")
    plt.title("Crashes by Borough")
    plt.xlabel("Borough")
    plt.ylabel("Number of Crashes")
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "crashes_by_borough.pdf")
    plt.close()

    # 4. Ordinal: severity distribution among ALL dataset records.
    # Unknown records remain in the denominator but are not plotted as
    # a fourth (incorrectly ranked) severity category.
    impact_counts = df["Crash Impact"].value_counts(sort=False)
    impact_pct = 100 * impact_counts / len(df)
    print("\nCRASH IMPACT PERCENT OF ALL RECORDS:")
    print(impact_pct)
    print("Unknown percent:", round(100 * unknown_count / len(df), 5))

    impact_plot = impact_pct.reset_index()
    impact_plot.columns = ["Crash Impact", "Percent"]
    plt.figure(figsize=(8, 5))
    sns.barplot(data=impact_plot, x="Crash Impact", y="Percent", color="steelblue")
    plt.title("Percentage of Crashes by Severity")
    plt.xlabel("Crash Impact (classified records)")
    plt.ylabel("Percentage of All Crashes")
    plt.figtext(0.5, 0.015, f"Unknown severity: {unknown_count:,} records (not plotted)",
                ha="center", fontsize=9)
    plt.tight_layout(rect=[0, 0.04, 1, 1])
    plt.savefig(FIGURES_DIR / "crash_impact.pdf")
    plt.close()

    # 5. Ratio: persons injured per crash
    print("\nPERSONS INJURED SUMMARY:")
    print(df["NUMBER OF PERSONS INJURED"].describe())
    plt.figure(figsize=(8, 5))
    sns.histplot(data=df, x="NUMBER OF PERSONS INJURED", discrete=True, color="steelblue")
    plt.xlim(0, 6)  # Current chart shows 0–6; full-data statistics are above.
    plt.title("Distribution of Persons Injured per Crash")
    plt.xlabel("Number of Persons Injured")
    plt.ylabel("Number of Crashes")
    plt.tight_layout()
    plt.savefig(FIGURES_DIR / "persons_injured.pdf")
    plt.close()

    # 6. Date summary and saved file locations
    print("\nDATE RANGE:")
    print("Earliest:", df["CRASH DATE"].min())
    print("Latest:", df["CRASH DATE"].max())
    print("\nFIGURES SAVED IN:", FIGURES_DIR)
    for name in ["crashes_by_borough.pdf", "crash_impact.pdf", "persons_injured.pdf"]:
        print("-", name)


if __name__ == "__main__":
    main()
