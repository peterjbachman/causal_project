# Import libraries
import re

import eyecite as eye
import pandas as pd

# Read in data
df = pd.read_csv("data/uncleaned/case_text.csv")

# Drop unecessary columns and na cases
df = df.drop(["Unnamed: 0"], axis=1)

# Left with 3,306 cases before any other filtering
df = df.dropna(subset=["opinion"])

author_pattern = r"(.*)?(\b\w+),"
per_curiam = r"(?i)(Per Curiam)"

df["per_curiam"] = df["opinion_author"].str.match(per_curiam, na=False)
df["opinion_author"] = df["opinion_author"].str.extract(author_pattern)[1]

for index, row in df.iterrows():
    # Convert all the text from html to plain text
    # opinion = eye.clean_text(row["opinion"], ["all_whitespace"])

    # Get citations and remove some of them from the text so they don't muddle
    # up the topic model
    opinion = row["opinion"]
    cites = eye.get_citations(opinion)

    for i in cites:
        try:
            opinion = re.sub(i.matched_text(), "", opinion)
        except re.error:
            continue

    df.at[index, "opinion"] = opinion

df

df.to_csv("data/uncleaned/cases_plain.csv", index=False)

# eye.clean_text(df["opinion"][6], ["all_whitespace"])

# # okay maybe I need to split based on line breaks.
# print(df["opinion"][4].split("\n")[7])
