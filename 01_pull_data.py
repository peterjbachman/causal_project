# I need to check if the API Call is over the limit
import json
import re
import time

import pandas as pd
import requests

from secrets_cl import api_key

search_url = "https://www.courtlistener.com/api/rest/v3/search/"
op_url = "https://www.courtlistener.com/api/rest/v3/opinions/"
op_form = "&fields=html,plain_text"
fed_court = "&court__jurisdiction=F"
# author_pattern = r"\b\w+,\s*Circuit\s*Judge:"
cases = pd.read_csv("data/uncleaned/glynn_sen_daughters_by_case_1.csv")
cases_filtered = cases[cases["unpub"] == 0]
# Drop cases where this information is not found
cases_filtered = cases_filtered.dropna(subset=["docket", "cite"])
cases_filtered = cases_filtered.assign(opinion="", opinion_type="")
cases_filtered["cite"] = cases_filtered["cite"].replace("Fed.", "F.")

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

    try:
        try:
            res = requests.get(search_term, headers=api_key)
            response = json.loads(res.text)
        except json.JSONDecodeError:
            print("Decode Error, Trying again")
            time.sleep(5)
            res = requests.get(search_term, headers=api_key)
            response = json.loads(res.text)

        # Request was throttled. Expected available in 101 seconds.
        # I need to check for this, wait for seconds, then retry
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
        except KeyError:
            # lol idk
            int(1)

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
            # lol idk
            int(1)

        # I think this will set up things right for the opinions?
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

    cases_filtered.at[index, "opinion"] = opinion
    cases_filtered.at[index, "opinion_type"] = op_type

# Save as a new file
cases_filtered = cases_filtered.dropna(subset=["casename"])
cases_filtered.to_csv("data/uncleaned/case_text.csv")

# I need to get the authors but I may do that once I get all the opinions first
# author = re.search(author_pattern, opinion)
# author.group()

# RANDOLPH, Circuit Judge: Signals the author.
# In this case it's Randolph
