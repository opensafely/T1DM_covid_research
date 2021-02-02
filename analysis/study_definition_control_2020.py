from cohortextractor import (
    StudyDefinition,
    patients,
    codelist,
    codelist_from_csv,
    combine_codelists,
)
from common_variables import common_variables
from codelists import *


study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1980-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.7,
    },
       population=patients.satisfying(
        """
            has_follow_up
        AND (age >=18 AND age <= 110)
        AND (sex = "M" OR sex = "F")
        AND imd > 0
        AND NOT stp = ""
        """,
        has_follow_up=patients.registered_with_one_practice_between(
            "2018-02-01", "2019-02-01"
        ),
    ),
    index_date="2020-02-01",

    age=patients.age_as_of(
        "patient_index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),

    stp=patients.registered_practice_as_of(
        "2020-02-01",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "STP1": 0.1,
                    "STP2": 0.1,
                    "STP3": 0.1,
                    "STP4": 0.1,
                    "STP5": 0.1,
                    "STP6": 0.1,
                    "STP7": 0.1,
                    "STP8": 0.1,
                    "STP9": 0.1,
                    "STP10": 0.1,
                }
            },
        },
    ),

    imd=patients.address_as_of(
        "2020-02-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "100": 0.1,
                    "200": 0.1,
                    "300": 0.1,
                    "400": 0.1,
                    "500": 0.1,
                    "600": 0.1,
                    "700": 0.1,
                    "800": 0.1,
                    "900": 0.1,
                    "1000": 0.1,
                }
            },
        },
    ),



)
