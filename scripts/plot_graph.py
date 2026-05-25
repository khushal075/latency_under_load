import pandas as pd
import matplotlib.pyplot as plt
import re

df = pd.read_csv("../results/summary.csv")

# Extract VUs
df["vus"] = df["file"].apply(lambda x: int(re.search(r'vus(\d+)', x).group(1)))

# Extract type
df["type"] = df["file"].apply(lambda x: "async" if "async" in x else "sync")

# Extract scenario
df["scenario"] = df["file"].apply(lambda x: "hold" if "hold" in x else "io")

for scenario in df["scenario"].unique():
    subset = df[df["scenario"] == scenario]

    for t in subset["type"].unique():
        s = subset[subset["type"] == t]
        plt.plot(s["vus"], s["p95"], label=f"{t}-{scenario}")

    plt.xlabel("VUs")
    plt.ylabel("p95 latency (ms)")
    plt.title(f"p95 vs VUs ({scenario})")
    plt.legend()
    plt.savefig(f"../results/p95_{scenario}.png")
    plt.clf()