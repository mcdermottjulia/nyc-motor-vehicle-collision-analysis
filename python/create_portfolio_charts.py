"""Export figures for geographic patterns, severity, and injury counts.

Reads the local 2024–2025 collision extract and saves PNGs to
visualizations/python/. Missing values remain separate from confirmed zeros.

Run from the project root:
    python3 python/create_portfolio_charts.py
"""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")  # Save images even without a display (e.g., AWS EC2).

import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter
import numpy as np
import pandas as pd
import seaborn as sns


ROOT = Path(__file__).resolve().parent.parent
DATASET = ROOT / "data" / "Motor_Vehicle_Collisions_-_Crashes_20260831.csv"
OUTPUT = ROOT / "visualizations" / "python"


# Common formatting keeps the figures consistent across the portfolio.
sns.set_theme(style="whitegrid", context="notebook", font_scale=1.05)


def save_chart(fig, filename, note):
    """Reserve room for a footnote and save a readable GitHub image."""
    fig.tight_layout(rect=(0, 0.12, 1, 1))
    fig.text(0.11, 0.035, note, ha="left", va="bottom", fontsize=9)
    fig.savefig(OUTPUT / filename, dpi=200, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: visualizations/python/{filename}")


def plot_boroughs(df):
    """Compare named boroughs; keep missing geography visible as a limitation."""
    borough = df["BOROUGH"].astype("string").fillna("").str.strip().str.upper()
    missing_count = int(borough.eq("").sum())
    counts = borough[borough.ne("")].value_counts().sort_values(ascending=False)

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.barh(counts.index, counts.to_numpy())
    ax.invert_yaxis()  # Largest category first.
    ax.set_title("Recorded collisions by NYC borough (2024–2025)", loc="left", pad=16)
    ax.set_xlabel("Number of recorded collisions")
    ax.set_ylabel("")
    ax.xaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))
    ax.set_xlim(0, max(counts) * 1.25)
    ax.bar_label(bars, labels=[f"{n:,}" for n in counts], padding=5)
    ax.grid(axis="y", visible=False)
    sns.despine(ax=ax, left=True)

    note = (
        f"Known boroughs only. Borough missing for {missing_count:,} of "
        f"{len(df):,} records ({missing_count / len(df):.1%}); "
        "counts are not adjusted for population or traffic volume."
    )
    save_chart(fig, "01_crashes_by_borough.png", note)
    print(f"  Missing/blank borough: {missing_count:,}")
    print(counts.to_string())


def classify_impact(df):
    """Preserve source missingness; do not make Unknown an ordered severity."""
    killed = pd.to_numeric(df["NUMBER OF PERSONS KILLED"], errors="coerce")
    injured = pd.to_numeric(df["NUMBER OF PERSONS INJURED"], errors="coerce")
    impact = np.select(
        [
            killed.gt(0),
            killed.isna() | injured.isna(),
            injured.gt(0),
            killed.eq(0) & injured.eq(0),
        ],
        ["Fatality", "Unknown", "Injury", "No Injury"],
        default="Unknown",
    )
    return pd.Series(impact, index=df.index, name="Crash Impact"), injured


def plot_severity(impact, total):
    """Percentages use ALL records; Unknown is reported, not ranked."""
    severity_order = ["No Injury", "Injury", "Fatality"]
    counts = impact.value_counts().reindex(severity_order, fill_value=0)
    unknown = int(impact.eq("Unknown").sum())
    pct = counts / total * 100

    fig, ax = plt.subplots(figsize=(9, 6))
    bars = ax.bar(severity_order, pct.to_numpy())
    ax.set_title("Collision severity classifications (2024–2025)", loc="left", pad=16)
    ax.set_xlabel("")
    ax.set_ylabel("Share of all collision records (%)")
    ax.set_ylim(0, max(pct) * 1.20)
    ax.bar_label(
        bars,
        labels=[f"{p:.2f}%\n({n:,})" for p, n in zip(pct, counts)],
        padding=5,
    )
    ax.grid(axis="x", visible=False)
    sns.despine(ax=ax)

    note = (
        f"Percentages use all {total:,} records. "
        f"Unknown = {unknown:,} records ({unknown / total:.3%}); "
        "excluded from the severity bars."
    )
    save_chart(fig, "02_crash_severity.png", note)
    print("  Impact categories:\n" + impact.value_counts().reindex(
        severity_order + ["Unknown"], fill_value=0).to_string())


def plot_injuries(injured, total):
    """Show common injury counts while including the tail in an explicit 7+ bin."""
    valid = injured.dropna()
    if ((valid < 0) | (valid % 1 != 0)).any():
        raise ValueError("Unexpected negative or non-integer injury counts: inspect source data.")

    counts = valid.astype(int).value_counts()
    labels = [str(i) for i in range(7)] + ["7+"]
    values = [int(counts.get(i, 0)) for i in range(7)] + [
        int(counts.loc[counts.index >= 7].sum())
    ]
    missing = int(injured.isna().sum())

    fig, ax = plt.subplots(figsize=(10, 6))
    bars = ax.bar(labels, values)
    ax.set_title("People injured per collision (2024–2025)", loc="left", pad=16)
    ax.set_xlabel("Number of people injured (7+ grouped)")
    ax.set_ylabel("Number of collision records")
    ax.yaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))
    ax.set_ylim(0, max(values) * 1.20)
    ax.bar_label(bars, labels=[f"{n:,}" for n in values], padding=4, fontsize=10)
    ax.grid(axis="x", visible=False)
    sns.despine(ax=ax)

    note = (
        f"7+ combines injury counts from 7 to {int(valid.max())}; "
        f"mean = {valid.mean():.3f}, max = {int(valid.max())}. "
        f"Missing injury counts: {missing:,}."
    )
    save_chart(fig, "03_people_injured.png", note)
    if sum(values) + missing != total:
        raise AssertionError("Injury bins plus missing values do not add up to the dataset size.")
    print(f"  Injury-count bins: {dict(zip(labels, values))}")


def main():
    if not DATASET.is_file():
        raise FileNotFoundError(
            f"Dataset not found:\n{DATASET}\n"
            "Keep the source CSV in the portfolio's local data/ directory."
        )

    df = pd.read_csv(DATASET, low_memory=False)
    required = ["BOROUGH", "NUMBER OF PERSONS INJURED", "NUMBER OF PERSONS KILLED"]
    absent = [name for name in required if name not in df.columns]
    if absent:
        raise ValueError(f"Missing required columns: {absent}")

    OUTPUT.mkdir(parents=True, exist_ok=True)
    print(f"Source records: {len(df):,}")
    print("Generating collision visualizations...")
    plot_boroughs(df)
    impact, injured = classify_impact(df)
    plot_severity(impact, len(df))
    plot_injuries(injured, len(df))
    print("Visualization exports complete.")


if __name__ == "__main__":
    main()
