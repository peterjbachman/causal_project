# Test comment at the top
import json

import pandas as pd
import requests

from secrets_cl import api_key

search_url = "https://www.courtlistener.com/api/rest/v3/search/"
op_url = "https://www.courtlistener.com/api/rest/v3/opinions/"
op_form = "&fields=plain_text"
fed_court = "&court__jurisdiction=F"
# author_pattern = r"\b\w+,\s*Circuit\s*Judge:"
cases = pd.read_csv("data/uncleaned/glynn_sen_daughters_by_case_1.csv")
cases_filtered = cases[cases["unpub"] == 0]
cases_filtered = cases_filtered.assign(opinion="")

for index, row in cases.iterrows():
    citation = row["cite"]
    citation = citation.replace(" ", "+")
    dock_num = row["docket"]
    search_term = (
        search_url + "?citation=" + citation + "&docketNumber=" + dock_num + fed_court
    )
    res = requests.get(search_term, headers=api_key)
    response = json.loads(res.text)["results"][0]
    clust_id = response["cluster_id"]
    dock_id = response["docket_id"]

    # Create search term for pulling opinion
    search_op = (
        op_url + "?docket__id=" + str(dock_id) + "&id=" + str(clust_id) + op_form
    )

    # Actually pull the opinion
    res = requests.get(search_op, headers=api_key)
    opinion = json.loads(res.text)["results"][0]["plain_text"]
    opinion

    cases_filtered.loc[index, "opinion"] = opinion

# I need to get the authors but I may do that once I get all the opinions first
# author = re.search(author_pattern, opinion)
# author.group()

# RANDOLPH, Circuit Judge: Signals the author.
# In this case it's Randolph
