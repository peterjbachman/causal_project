# Causal Inference Project

- **NOTE**: I used the [pyenv](https://github.com/pyenv/pyenv), and
[pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv) to set up my
`python` environment.
- For `R` I set it up using [renv](https://github.com/rstudio/renv/)
  - I used `R` version 4.2.2

## Setup

To run this first set up the project as follows:

```shell
git clone https://github.com/peterjbachman/causal_project.git
cd causal_project
pyenv virtualenv 3.11.1 causal_project
pyenv local causal_project
pip install -r requirements.txt
```

Set up R for this project by then running the following:

```shell
R
```

You will need to create a python script in this directory named `secrets_cl.py`
formatted as follows:

```python
api_key = {"Authorization": "Token <insert CAP API token here>"}
```

## Replication

- `01_pull_data.py`
  - Pulls the opinion text using the [CAP API](https://case.law/)
- `02_clean_text.py`
  - Cleans up the text and cleans the opinion author section
- `03_split_cases.R`
  - Splits the data into a training and test dataset to learn about the topics
    in this data.