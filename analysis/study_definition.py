from cohortextractor import (
    StudyDefinition,
    patients,
    codelist_from_csv,
    codelist,
    filter_codes_by_category,
    combine_codelists
)


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

    # STUDY POPULATION
   population=patients.registered_with_one_practice_between(
        "2019-02-01", "2020-02-01"
   ),

    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_before="2020-12-01", 
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": "2020-02-01"}},
    ),

    # PRIMARY CARE COVID EXPOSURE
    primary_care_case=patients.with_these_clinical_events(
        combine_codelists(covid_primary_care_code,
                          covid_primary_care_positive_test,
                          covid_primary_care_sequalae,
                          ),        
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase"},
    ),


    primary_care_historic_case=patients.with_these_clinical_events(
        combine_codelists(covid_primary_care_historic_case,
                        covid_primary_care_potential_historic_case,
                         ),
        returning="date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"rate" : "exponential_increase"},
    ),

    primary_care_exposure=patients.with_these_clinical_events(
        covid_primary_care_exposure,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase"},
    ),
    primary_care_suspect_case=patients.with_these_clinical_events(
        combine_codelists(covid_suspected_code,
                          covid_suspected_111,
                          covid_suspected_advice,
                          covid_suspected_test,
                          ),   
        returning="date",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"rate" : "exponential_increase"},

    ),

# SECONDARY CARE COVID DIAGNOSIS
    covid_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=covid_codelist,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence" : 0.25},
   ),
    covid_admission_primary_diagnosis=patients.admitted_to_hospital(
        returning="primary_diagnosis",
        with_these_diagnoses=covid_codelist,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD", 
        return_expectations={"date": {"earliest": "2020-03-01"},"incidence" : 0.25,
            "category": {"ratios": {"U071":0.5, "U072":0.5}},
        },
    ),

    #COVID DEATH
    # ons
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

    #COVID SGSS TEST
    first_tested_for_covid=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="any",
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest" : "2020-02-01"},
        "rate" : "exponential_increase"},
    ),
    first_positive_test_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after="2020-02-01",
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest" : "2020-02-01"},
        "rate" : "exponential_increase"},
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


 
     diabetes_type=patients.categorised_as(
        {
            "T1DM":
                """
                        (type1_diabetes AND NOT
                        type2_diabetes) 
                    OR
                        (((type1_diabetes AND type2_diabetes) OR 
                        (type1_diabetes AND unknown_diabetes AND NOT type2_diabetes) OR
                        (unknown_diabetes AND NOT type1_diabetes AND NOT type2_diabetes))
                        AND 
                        (insulin_lastyear_meds > 0 AND NOT
                        oad_lastyear_meds > 0))
                """,
            "T2DM":
                """
                        (type2_diabetes AND NOT
                        type1_diabetes)
                    OR
                        (((type1_diabetes AND type2_diabetes) OR 
                        (type2_diabetes AND unknown_diabetes AND NOT type1_diabetes) OR
                        (unknown_diabetes AND NOT type1_diabetes AND NOT type2_diabetes))
                        AND 
                        (oad_lastyear_meds > 0))
                """,
            "UNKNOWN_DM":
                """
                        ((unknown_diabetes AND NOT type1_diabetes AND NOT type2_diabetes) AND NOT
                        oad_lastyear_meds AND NOT
                        insulin_lastyear_meds) 
                   
                """,
            "NO_DM": "DEFAULT",
        },

        return_expectations={
            "category": {"ratios": {"T1DM": 0.03, "T2DM": 0.2, "UNKNOWN_DM": 0.02, "NO_DM": 0.75}},
            "rate" : "universal"

        },

 
        oad_lastyear_meds=patients.with_these_medications(
            oad_med_codes, 
            between=["2019-02-01", "2020-01-31"],
            returning="number_of_matches_in_period",
        ),
        insulin_lastyear_meds=patients.with_these_medications(
            insulin_med_codes,
            between=["2019-02-01", "2020-01-31"],
            returning="number_of_matches_in_period",
        ),

     ),   

    #DIABETES OUTCOME SECONDARY CARE
    t1dm_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=diabetes_t1_codes_secondary,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence" : 0.95},
   ),
    ketoacidosis_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=diabetic_ketoacidosis_codes_secondary,  # optional
        on_or_after="2020-02-01",
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": "2020-03-01"}, "incidence" : 0.95},
   ),




    ## DEMOGRAPHIC COVARIATES
    # AGE
    age=patients.age_as_of(
        "2020-02-01",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),

    # SEX
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),

    # DEPRIVIATION
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
    ),)
