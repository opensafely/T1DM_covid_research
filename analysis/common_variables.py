from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


common_variables = dict(
    # Outcomes
    # History of outcomes
    previous_diabetes=patients.with_these_clinical_events(
        combine_codelists(diabetes_t1_codes, diabetes_t2_codes, diabetes_unknown_codes),
        on_or_before="patient_index_date",
        return_expectations={"incidence": 0.05},
    ),

    # Diabetes
    t1dm_gp=patients.with_these_clinical_events(
        diabetes_t1_codes,
        on_or_after="patient_index_date + 1 days",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t2dm_gp=patients.with_these_clinical_events(
        diabetes_t2_codes,
        on_or_after="patient_index_date + 1 days",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    unknown_diabetes_gp=patients.with_these_clinical_events(
        diabetes_unknown_codes,
        on_or_after="patient_index_date + 1 days",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    ketoacidosis_gp=patients.with_these_clinical_events(
        diabetic_ketoacidosis_codes,
        on_or_after="patient_index_date + 1 days",
        return_first_date_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t1dm_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=diabetes_t1_codes_hospital,
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t2dm_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=diabetes_t2_codes_hospital,
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    ketoacidosis_hospital=patients.admitted_to_hospital(
        returning="date_admitted",
        with_these_diagnoses=ketoacidosis_codes_hospital,
        on_or_after="patient_index_date + 1 days",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t1dm_ons=patients.with_these_codes_on_death_certificate(
        diabetes_t1_codes_hospital,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    t2dm_ons=patients.with_these_codes_on_death_certificate(
        diabetes_t2_codes_hospital,
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        match_only_underlying_cause=False,
        on_or_after="patient_index_date + 1 days",
        return_expectations={"date": {"earliest": "index_date"}},
    ),
    oad_lastyear_meds=patients.with_these_medications(
        oad_med_codes,
        between=["patient_index_date - 1 year", "patient_index_date + 1 days"],
        return_expectations={"incidence": 0.05},
    ),
    insulin_lastyear_meds=patients.with_these_medications(
        insulin_med_codes,
        between=["patient_index_date - 1 year", "patient_index_date + 1 days"],
        return_expectations={"incidence": 0.05},
    ),
    type1_agg=patients.satisfying("t1dm_gp OR t1dm_hospital OR t1dm_ons"),
    type2_agg=patients.satisfying("t2dm_gp OR t2dm_hospital OR t2dm_ons"),
    t1dm=patients.satisfying(
        """
            (type1_agg AND NOT
            type2_agg)
        OR
            (((type1_agg AND type2_agg) OR
            (type1_agg AND unknown_diabetes_gp AND NOT type2_agg) OR
            (unknown_diabetes_gp AND NOT type1_agg AND NOT type2_agg))
            AND
            (insulin_lastyear_meds AND NOT
            oad_lastyear_meds))
        """,
        return_expectations={"incidence": 0.05},
    ),
    t2dm=patients.satisfying(
        """
            (type2_agg AND NOT
            type1_agg)
        OR
            (((type1_agg AND type2_agg) OR
            (type2_agg AND unknown_diabetes_gp AND NOT type1_agg) OR
            (unknown_diabetes_gp AND NOT type1_agg AND NOT type2_agg))
            AND
            (oad_lastyear_meds))
        """,
        return_expectations={"incidence": 0.05},
    ),
    hba1c_mmol=patients.with_these_clinical_events(
        hba1c_new_codes,
        find_last_match_in_period=True,
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        between=["patient_index_date - 1 year", "patient_index_date + 1 days"],
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "date": {"earliest": "2019-02-28", "latest": "2020-02-29"},
            "incidence": 0.95,
        },
    ),
    hba1c_pct=patients.with_these_clinical_events(
        hba1c_old_codes,
        find_last_match_in_period=True,
        returning="numeric_value",
        include_date_of_match=True,
        include_month=True,
        between=["patient_index_date - 1 year", "patient_index_date + 1 days"],
        return_expectations={
            "float": {"distribution": "normal", "mean": 60.0, "stddev": 15},
            "date": {"earliest": "2019-02-28", "latest": "2020-02-29"},
            "incidence": 0.95,
        },
    ),
    died_date_ons=patients.died_from_any_cause(
        returning="date_of_death",
        date_format="YYYY-MM-DD",
        return_expectations={
            "date": {"earliest": "index_date"},
            "incidence": 0.1,
        },
    ),
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
    #ETHNICITY IN 16 CATEGORIES
    ethnicity_16=patients.with_these_clinical_events(
        ethnicity_codes_16,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=False,
        return_expectations={
            "category": {
                "ratios": {
                    "1": 0.0625,
                    "2": 0.0625,
                    "3": 0.0625,
                    "4": 0.0625,
                    "5": 0.0625,
                    "6": 0.0625,
                    "7": 0.0625,
                    "8": 0.0625,
                    "9": 0.0625,
                    "10": 0.0625,
                    "11": 0.0625,
                    "12": 0.0625,
                    "13": 0.0625,
                    "14": 0.0625,
                    "15": 0.0625,
                    "16": 0.0625,
                }
            },
            "incidence": 0.75,
        },
    ),

   
    # ETHNICITY IN 6 CATEGORIES
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=False,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2":0.2, "3":0.2, "4":0.2, "5": 0.2}},
            "incidence": 0.75,
        },
    ),
    practice_id=patients.registered_practice_as_of(
        "2020-02-01",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
            "incidence": 1,
        },
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
    region=patients.registered_practice_as_of(
        "2020-02-01",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and The Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East": 0.1,
                    "London": 0.2,
                    "South East": 0.1,
                    "South West": 0.1,
                },
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
