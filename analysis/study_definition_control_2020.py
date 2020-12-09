from cohortextractor import (
    StudyDefinition,
    patients,
    codelist,
    codelist_from_csv,
    combine_codelists,
)
from common_variables import common_variable_define
from codelists import *


start_date = "2020-02-01"
end_date = "2020-12-01"

common_variables = common_variable_define(
    start_date,
    end_date,
)

study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.1,
    },
    


# STUDY POPULATION
   # This line defines the study population
    population=patients.all(),

    has_follow_up=patients.registered_with_one_practice_between(
        "2019-02-28", "2020-02-01", return_expectations={"incidence": 0.9},         
    ),
    **common_variables
)
