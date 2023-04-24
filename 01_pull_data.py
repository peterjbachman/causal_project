import json
import re
import time

import pandas as pd
import requests

# You need to create a secrets_cl.py file with an object called api_key
# not about to hand mine out lol.
from secrets_cl import api_key

# Create strings with constant parts of url
search_url = "https://www.courtlistener.com/api/rest/v3/search/"
op_url = "https://www.courtlistener.com/api/rest/v3/opinions/"
op_form = "&fields=html,plain_text"
fed_court = "&court__jurisdiction=F"

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
    citation = citation.replace(" ", "+")
    dock_num = row["docket"]

    # Create search term based on citation and docket number
    search_term = (
        search_url + "?citation=" + citation + "&docketNumber=" + dock_num + fed_court
    )

    # Try to do all of the following
    # If there is an index or key error that indicates the case is not found
    try:
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

        # If the api complains I'm using it too much, sleep for the required
        # time and retry
        try:
            if bool(re.search("Request was throttled.*", response["detail"])):
                print(
                    "-- API Throttled, waiting {} seconds --".format(
                        re.search("\d+", response["detail"]).group()
                    )
                )
                time.sleep(int(re.search("\d+", response["detail"]).group()))
                try:
                    res = requests.get(search_term, headers=api_key)
                    response = json.loads(res.text)
                except json.JSONDecodeError:
                    print("Decode Error, Trying again")
                    time.sleep(5)
                    res = requests.get(search_term, headers=api_key)
                    response = json.loads(res.text)

        # lol idk it won't run without this.
        except KeyError:
            int(1)

        # Get the required information from the API search to pull the correct
        # opinion in the next API call
        clust_id = response["results"][0]["cluster_id"]
        dock_id = response["results"][0]["docket_id"]

        # Create search term for pulling opinion based on the resulting ids
        search_op = (
            op_url + "?docket__id=" + str(dock_id) + "&id=" + str(clust_id) + op_form
        )

        # Actually pull the opinion
        try:
            res = requests.get(search_op, headers=api_key)
            opinion = json.loads(res.text)
        except json.JSONDecodeError:
            print("Decode Error, Trying again")
            time.sleep(5)
            res = requests.get(search_op, headers=api_key)
            opinion = json.loads(res.text)

        try:
            if bool(re.search("Request was throttled.*", opinion["detail"])):
                print(
                    "-- API Throttled, waiting {} seconds --".format(
                        re.search("\d+", response["detail"]).group()
                    )
                )
                time.sleep(int(re.search("\d+", response["detail"]).group()))
                try:
                    res = requests.get(search_term, headers=api_key)
                    response = json.loads(res.text)
                except json.JSONDecodeError:
                    print("Decode Error, Trying again")
                    time.sleep(5)
                    res = requests.get(search_term, headers=api_key)
                    response = json.loads(res.text)
        except KeyError:
            int(1)

        # prioitize the html opinion first, and then the plain_text
        if opinion["results"][0]["html"] == "":
            if opinion["results"][0]["plain_text"] == "":
                print("-- Opinion is not found despite existing")
                opinion = "NA"
                op_type = "NA"
            else:
                opinion = opinion["results"][0]["plain_text"]
                op_type = "plain_text"
        else:
            opinion = opinion["results"][0]["html"]
            op_type = "html"

    except IndexError:
        print("-- Cannot find opinion for {}".format(row["casename"]))
        opinion = "NA"
        op_type = "NA"
    except KeyError:
        print("-- Cannot find opinion for {}".format(row["casename"]))
        opinion = "NA"
        op_type = "NA"

    # Save the opinion to the right row
    cases_filtered.at[index, "opinion"] = opinion
    cases_filtered.at[index, "opinion_type"] = op_type

# idk why it's adding a bunch of NA rows but they're easy to remove
cases_filtered = cases_filtered.dropna(subset=["casename"])

# Save as a new file
cases_filtered.to_csv("data/uncleaned/case_text.csv")
