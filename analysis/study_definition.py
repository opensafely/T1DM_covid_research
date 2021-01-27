from cohortextractor import StudyDefinition, filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta



def days_before(s, days):
    date = datetime.strptime(s, "%Y-%m-%d")
    modified_date = date - timedelta(days=days)
    return datetime.strftime(modified_date, "%Y-%m-%d")

## CODE LISTS
# All codelist are held within the codelist/ folder and this imports them from
# codelists.py file which imports from that folder

from codelists import *

## STUDY POPULATION
# Defines both the study population and points to the important covariates

study = StudyDefinition(
    default_expectations={
        "date": {"earliest": "1970-01-01", "latest": "today"},
        "rate": "uniform",
        "incidence": 0.2,
    },

   population=patients.registered_with_one_practice_between(
        "2019-02-01", "2020-02-01"
   ),

    age=patients.age_as_of(
        "2020-02-01",
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

    imd=patients.address_as_of(
        "2020-02-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),

    # GEOGRAPHIC REGION CALLED STP
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

    # OTHER REGION
    region=patients.registered_practice_as_of(
        "2020-02-01",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and the Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East of England": 0.1,
                    "London": 0.2,
                    "South East": 0.2,
                },
            },
        },
    ),

    #ETHNICITY IN 16 CATEGORIES
    ethnicity_16=patients.with_these_clinical_events(
        ethnicity_codes_16,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
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
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2":0.2, "3":0.2, "4":0.2, "5": 0.2}},
            "incidence": 0.75,
        },
    ),
    bmi=patients.most_recent_bmi(
            on_or_after=days_before("2020-02-01", 3653),
            minimum_age_at_measurement=16,
            include_measurement_date=True,
            include_month=True,
            return_expectations={
                "incidence": 0.6,
                "float": {"distribution": "normal", "mean": 35, "stddev": 10},
            },
        ),
    
    smoking_status=patients.categorised_as(
            {
                "S": "most_recent_smoking_code = 'S' OR smoked_last_18_months",
                "E": """
                     (most_recent_smoking_code = 'E' OR (
                       most_recent_smoking_code = 'N' AND ever_smoked
                       )
                     ) AND NOT smoked_last_18_months
                """,
                "N": "most_recent_smoking_code = 'N' AND NOT ever_smoked",
                "M": "DEFAULT",
            },
            return_expectations={
                "category": {"ratios": {"S": 0.6, "E": 0.1, "N": 0.2, "M": 0.1}}
            },
            most_recent_smoking_code=patients.with_these_clinical_events(
                clear_smoking_codes,
                find_last_match_in_period=True,
                on_or_before=days_before("2020-02-01", 1),
                returning="category",
            ),
            ever_smoked=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
                on_or_before=days_before("2020-02-01", 1),
            ),
            smoked_last_18_months=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S"]),
                between=[days_before("2020-02-01", 548), "2020-02-01"],
            ),
        ),
    hypertension_date=patients.with_these_clinical_events(
            hypertension_codes, return_first_date_in_period=True, include_month=True,
        ),
    hba1c_mmol_per_mol=patients.with_these_clinical_events(
            hba1c_new_codes,
            find_last_match_in_period=True,
            between=[days_before("2020-02-01", 730), "2020-02-01"],
            returning="numeric_value",
            include_date_of_match=True,
            return_expectations={
                "float": {"distribution": "normal", "mean": 40.0, "stddev": 20},
                "incidence": 0.95,
            },
        ),
    hba1c_percentage=patients.with_these_clinical_events(
            hba1c_old_codes,
            find_last_match_in_period=True,
            between=[days_before("2020-02-01", 730), "2020-02-01"],
            returning="numeric_value",
            include_date_of_match=True,
            return_expectations={
                "float": {"distribution": "normal", "mean": 5, "stddev": 2},
                "incidence": 0.95,
            },
        ),

    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_before="2020-12-01", 
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-02-01"}},
    ),
    

    #DIABETES OUTCOME PRIMARY CARE
    type1_diabetes=patients.with_these_clinical_events(
        diabetes_t1_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase"},
    ),
    ketoacidosis=patients.with_these_clinical_events(
        diabetic_ketoacidosis_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase"},
    ),
    type2_diabetes=patients.with_these_clinical_events(
        diabetes_t2_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase"},
    ),
    unknown_diabetes=patients.with_these_clinical_events(
        diabetes_unknown_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase"},
    ),

    #DIABETES OUTCOME SECONDARY CARE
    t1dm_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=diabetes_t1_codes_secondary,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence" : 0.10},
   ),
    ketoacidosis_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=diabetic_ketoacidosis_codes_secondary,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence" : 0.10},
   ),


    #EXPOSURE
    gp_covid_code_date=patients.with_these_clinical_events(
        covid_primary_care_code,        
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after="2020-02-01",
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence" : 0.10},
    ),

    gp_positivetest_date=patients.with_these_clinical_events(
        covid_primary_care_positive_test,        
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after="2020-02-01",
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence" : 0.10},
    ),

    sgss_positive_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence" : 0.10},
    ),

    
    covid_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=covid_codelist,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence" : 0.25},
   ),


    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        on_or_after="2020-02-01",
        match_only_underlying_cause=False,
        return_expectations={"date": {"earliest" : "2020-02-01"},
        "rate" : "exponential_increase"},
    ),
    died_date_ons=patients.died_from_any_cause(
        on_or_after="2020-02-01",
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest" : "2020-02-01"},
        "rate" : "exponential_increase"},
    ),

    pneumonia_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=pneumonia_codelist,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-02-01"}, "incidence" : 0.15},
   ),



    
)
