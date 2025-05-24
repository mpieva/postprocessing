#! /usr/bin/env python3

import sys
import pandas as pd
import matplotlib.pyplot as plt

p = sys.argv[1]
id = sys.argv[2]

df = pd.read_csv(p, sep='\t')

# for plotting, show only the first 200bp
df = df[df.Length < 200].copy()

# remove a few columns that we dont want to see
filter = p.split(".")[-2] ##

df.drop(
    [
        f"{filter.split('M')[0]}", 
        f"%mapped{filter}"
    ],
    axis=1,
    inplace=True
)

# melt the dataset
df = df.melt(id_vars='Length')

# create the plot
fig, ax = plt.subplots()
for label, grp in df.groupby('variable', sort=False):
    grp.plot(x='Length', y='value', ax = ax, label = label)

ax.set_title(id)
ax.set_ylabel('Read-Count')
ax.set_xlabel('Read-Length')
plt.tight_layout()

plt.savefig(f"{p.replace('tsv','jpg')}", dpi=300)
