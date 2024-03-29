from cohortextractor import (
    StudyDefinition,
    patients,
    codelist,
    codelist_from_csv,
    combine_codelists,
)
from common_variables import common_variable_define
from codelists import *

prev_nov = "2018-11-01"
prev_dec = "2018-12-01"
start_jan = "2019-01-01"
start_date = "2019-02-01"
start_mar = "2019-03-01"
start_apr = "2019-04-01"
start_may = "2019-05-01"
start_jun = "2019-06-01"
start_jul = "2019-07-01"
start_aug = "2019-08-01"
start_sep = "2019-09-01"
start_oct = "2019-10-01"
end_date = "2019-11-01"

common_variables = common_variable_define(
    start_jan,
    prev_nov,
    prev_dec,
    start_date,
    start_mar,
    start_apr,
    start_may,
    start_jun,
    start_jul,
    start_aug,
    start_sep,
    start_oct,
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
        AND (age >=18 AND age <= 110)
        AND (sex = "M" OR sex = "F")
        AND imd > 0
        AND NOT stp = ""
        AND exposure_pneumonia
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "2018-02-01", "2019-02-01"
        ),
    ),
    exposure_pneumonia=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=pneumonia_codelist,
        on_or_after=start_date,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": start_date}},
    ),
    **common_variables
)



