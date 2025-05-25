#! /usr/bin/env python3

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import sys

id = sys.argv[1]
txt = sys.argv[2:]

df = pd.DataFrame()

for t in txt:
    tmp = pd.read_csv(t, sep="\t")
    tmp['End'] = tmp['Position'].apply(lambda x: "5'" if x >= 0 else "3'" )
    tmp.loc[tmp.index[-1], 'End'] = "3'"
    rl = t.split('.')[0].replace('substitution_patterns_','')
    tmp['read_length'] = int(rl)
    df = pd.concat([df, tmp], ignore_index=False)

df = df.melt(id_vars=['Position','read_length',"End"])
bins = range(min(df['read_length']), max(df['read_length'])+1, 5)

df['SizeBins'] = pd.cut(df['read_length'], bins=list(bins), right=False)
df = df.groupby(['SizeBins','variable', 'Position', "End"], as_index=False, observed=True).sum(numeric_only=True)
df.drop('read_length', axis=1, inplace=True)

df['RefBase'] = df['variable'].apply(lambda x: x[0])

# now get the total number of reads per size-bin
summ = df.groupby(["SizeBins",'Position','End','RefBase'], as_index=False, observed=True).sum(numeric_only=True)

df = df.merge(summ, how='left', on=['SizeBins', 'Position', 'End', 'RefBase'])
df.columns = ['ReadLength','Base','Position','End','Count','Ref', 'Total']

df['Substitution frequencies'] = df['Count'] / df['Total']

bases = ['CT','GA','AC','AG','AT','CA','CG','GC','GT','TA','TC','TG']
palette = {x:'lightgrey' for x in bases}
palette.update({'CT':'red', "GA":'black'})

df = df[df.Base.isin(bases)]

#now plot the rate
# fix the positions first

df['Position in Sequence'] = df.apply(lambda x: x.Position if x.End=="5'" else x.Position+40, axis=1)
df['ReadLength'] = df.ReadLength.apply(lambda x: f"{x.left}-{x.right -1}")

g = sns.relplot(
    data = df, 
    kind='line', 
    x='Position in Sequence',
    y='Substitution frequencies', 
    col='ReadLength', 
    col_wrap=5, 
    hue='Base',
    palette=palette)

ticks = list(range(0,21))
ticks.extend(list(range(-20,1)))

# Apply to each subplot (Axes)
for ax in g.axes.flat:
    ax.set_xticks(list(range(0,42,5)))
    ax.set_xticklabels(ticks[::5])
    ax.axvline(x=20, ymax=0.5, ls="--", color='grey')

plt.tight_layout()
plt.savefig(f"{id}.jpg", dpi=300)
