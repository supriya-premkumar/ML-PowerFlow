import pandas as pd
f = pd.read_csv("voltage.csv")
col = ['0','1', '2', '3', '4', '5', '6', '7']
new_f = f[col]
new_f.to_csv("Voltage.csv", index=False)
