import json
import time

import pandas as pd
import requests

# You need to create a secrets_cl.py file with an object called api_key
# not about to hand mine out lol.
from secrets_cl import api_key

# Create strings with constant parts of url
case_search = "https://api.case.law/v1/cases/?cite="
case_ops = "&page_size=1&full_case=true"

# read in case data, filter for only published opinions
cases = pd.read_csv("data/uncleaned/glynn_sen_daughters_by_case_1.csv")
cases_filtered = cases[cases["unpub"] == 0]

# Drop cases where this information is not found
cases_filtered = cases_filtered.dropna(subset=["docket", "cite"])
cases_filtered = cases_filtered.assign(opinion="", opinion_type="")
cases_filtered["cite"] = cases_filtered["cite"].replace("Fed.", "F.")

# For each case do the following
for index, row in cases.iterrows():
    print("Finding opinion for {}".format(row["casename"]))

    # Convert citation to url-friendly
    citation = row["cite"]

    # Create search term based on citation and docket number
    search_term = case_search + citation + case_ops

    # I was running into instances where the api was not loading the data
    # correctly, so mitigate that by retrying then I get the decode error
    try:
        res = requests.get(search_term, headers=api_key)
        response = json.loads(res.text)
    except json.JSONDecodeError:
        print("Decode Error, Trying again")
        time.sleep(5)
        res = requests.get(search_term, headers=api_key)
        response = json.loads(res.text)

    # Save the opinion to the right row
    try:
        cases_filtered.at[index, "opinion"] = response["results"][0]["casebody"][
            "data"
        ]["opinions"][0]["text"]
        cases_filtered.at[index, "opinion_author"] = response["results"][0]["casebody"][
            "data"
        ]["opinions"][0]["author"]
    except IndexError:
        cases_filtered.at[index, "opinion"] = "NA"
        cases_filtered.at[index, "opinion_author"] = "NA"

    # idk why it's adding a bunch of NA rows but they're easy to remove
    cases_filtered = cases_filtered.dropna(subset=["casename"])
    cases_filtered = cases_filtered.drop(["Unnamed: 0"], axis=1)

# Save as a new file
cases_filtered.to_csv("data/uncleaned/case_text.csv")
