import json
import glob
import pandas as pd

rows = []

for file in glob.glob("../results/raw/*.json"):
    with open(file) as f:
        data = json.load(f)

    metrics = data["metrics"]

    if "http_req_duration" in metrics:
        p95 = metrics["http_req_duration"]["values"]["p(95)"]

        rows.append({
            "file": file,
            "p95": p95
        })

df = pd.DataFrame(rows)
df.to_csv("../results/summary.csv", index=False)

print(df)