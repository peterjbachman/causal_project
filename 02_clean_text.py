# Import libraries
import re

import eyecite as eye
import pandas as pd

# Read in data
df = pd.read_csv("data/uncleaned/case_text.csv")

# Drop unecessary columns and na cases
df = df.drop(["Unnamed: 0"], axis=1)

# Left with 3,189 cases before any other filtering

author_pattern = r"(\b\w+)(,\s(Circuit|Chief|Senior Circuit)\sJudge\b)(?!,).*(:|\.)"
per_curiam = r"PER CURIAM:"

for index, row in df.iterrows():
    # Convert all the text from html to plain text
    opinion = eye.clean_text(row["opinion"], ["html", "all_whitespace"])

    if re.match(per_curiam, opinion):
        df.at[index, "opinion_author"] = "Per Curiam"
    else:
        # Find the opinion author
        author = re.findall(author_pattern, row["opinion"])
        # Mark this in the dataset
        try:
            df.at[index, "opinion_author"] = author[-1][0]
        except AttributeError:
            df.at[index, "opinion_author"] = "NA"
        except IndexError:
            df.at[index, "opinion_author"] = "NA"

    # Get citations and remove some of them from the text so they don't muddle
    # up the topic model
    cites = eye.get_citations(opinion)

    for i in cites:
        try:
            opinion = re.sub(i.matched_text(), "", opinion)
        except re.error:
            continue

    df.at[index, "opinion"] = opinion

df.to_csv("data/uncleaned/cases_plain.csv")
