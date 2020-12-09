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
    default_expectations={
        "date": {"earliest": "1900-01-01", "latest": "today"},
        "rate": "exponential_increase",
        "incidence": 0.7,
    },
    population=patients.satisfying(
        """
            has_follow_up
        AND (pneumonia_admission_date = "True")
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "2019-02-01", "2020-02-01"
        ),
    ),
    pneumonia_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=pneumonia_codelist,  # optional
        on_or_after=start_date,
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": start_date}, "incidence" : 0.25},
   ),
    
    **common_variables
)



