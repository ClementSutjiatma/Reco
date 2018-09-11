import pandas as pd
import sys
print(sys.argv[1])

df = pd.read_csv(sys.argv[1])
df["name"] = df["name"].str.lower()
split_name =  df["name"].str.split(" ", expand=True)
print(split_name)
df["FirstName"] = split_name[0]
df["LastName"] = split_name[1]

df.to_json( orient = "records")

with open(sys.argv[1].split('.')[0] + ".json", 'w') as f:
    f.write(out)
