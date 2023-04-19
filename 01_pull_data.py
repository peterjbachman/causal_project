# Test comment at the top
import json

import requests
import pandas as pd

from secrets_cl import api_key

search_url = "https://www.courtlistener.com/api/rest/v3/search/"
op_url = "https://www.courtlistener.com/api/rest/v3/opinions/"
op_form = "&fields=plain_text"
fed_court = "&court__jurisdiction=F"
# author_pattern = r"\b\w+,\s*Circuit\s*Judge:"




citation = "310 F.3d 758"
citation = citation.replace(" ", "+")
search_term = search_url + "?citation=" + citation + fed_court
search_term

res = requests.get(search_term, headers=api_key)
response = json.loads(res.text)["results"][0]
clust_id = response["cluster_id"]
dock_id = response["docket_id"]

# Create search term for pulling opinion
search_op = op_url + "?docket__id=" + str(dock_id) + "&id=" + str(clust_id) + op_form
search_op

# Actually pull the opinion
res = requests.get(search_op, headers=api_key)
opinion = json.loads(res.text)["results"][0]["plain_text"]
opinion

# I need to get the authors but I may do that once I get all the opinions first
# author = re.search(author_pattern, opinion)
# author.group()

# RANDOLPH, Circuit Judge: Signals the author.
# In this case it's Randolph
