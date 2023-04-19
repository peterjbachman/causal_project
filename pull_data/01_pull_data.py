# Test comment at the top
import json
import secrets

import eyecite
import requests

search_url = "https://www.courtlistener.com/api/rest/v3/search/?citation=310+F.3d+758&court__jurisdiction=F"

opinion_url = "https://www.courtlistener.com/api/rest/v3/opinions/"

res = requests.get(search_url, headers=secrets.api_key)
response = json.loads(res.text)
response

# curl "https://www.courtlistener.com/api/rest/v3/search/?citation=310+F.3d+758&court__jurisdiction=F" | jq '.'
# # Get Docket ID and ID


# curl "https://www.courtlistener.com/api/rest/v3/opinions/?docket__id=162355&id=185810&fields=plain_text" | jq '.'


# RANDOLPH, Circuit Judge: Signals the author.
# In this case it's Randolph

eyecite.clean_text(text, steps)
