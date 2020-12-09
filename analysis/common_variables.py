from cohortextractor import filter_codes_by_category, patients, combine_codelists
from codelists import *
from datetime import datetime, timedelta


def days_before(s, days):
    date = datetime.strptime(s, "%Y-%m-%d")
    modified_date = date - timedelta(days=days)
    return datetime.strftime(modified_date, "%Y-%m-%d")


def common_variable_define(
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
):
    
    common_variables = dict(
    age=patients.age_as_of(
        start_date,
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
            start_date,
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
            start_date,
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

        practice_id=patients.registered_practice_as_of(
            start_date,
            returning="pseudo_id",
            return_expectations={
                "int": {"distribution": "normal", "mean": 1000, "stddev": 100},
                "incidence": 1,
            },
        ),
        region=patients.registered_practice_as_of(
            start_date,
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

    #DIABETES OUTCOME PRIMARY CARE
    gp_t1dm_date=patients.with_these_clinical_events(
        diabetes_t1_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase",
        "incidence": 0.01,},
    ),
    gp_ketoacidosis_date=patients.with_these_clinical_events(
        diabetic_ketoacidosis_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase",
        "incidence": 0.01,},
    ),
    gp_t2dm_date=patients.with_these_clinical_events(
        diabetes_t2_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase",
        "incidence": 0.2,},
    ),
    gp_unknowndm_date=patients.with_these_clinical_events(
        diabetes_unknown_codes,
        returning="date",
        find_first_match_in_period=True,
        date_format="YYYY-MM-DD",
        return_expectations={"rate" : "exponential_increase",
        "incidence": 0.05,},
    ),
     diabetes_type=patients.categorised_as(
        {
            "T1DM":
                """
                        (gp_t1dm_date AND NOT
                        gp_t2dm_date) 
                    OR
                        (((gp_t1dm_date AND gp_t2dm_date) OR 
                        (gp_t1dm_date AND gp_unknowndm_date AND NOT gp_t2dm_date) OR
                        (gp_unknowndm_date AND NOT gp_t1dm_date AND NOT gp_t2dm_date))
                        AND 
                        (insulin_lastyear_meds > 0 AND NOT
                        oad_lastyear_meds > 0))
                """,
            "T2DM":
                """
                        (gp_t2dm_date AND NOT
                        gp_t1dm_date)
                    OR
                        (((gp_t1dm_date AND gp_t2dm_date) OR 
                        (gp_t2dm_date AND gp_unknowndm_date AND NOT gp_t1dm_date) OR
                        (gp_unknowndm_date AND NOT gp_t1dm_date AND NOT gp_t2dm_date))
                        AND 
                        (oad_lastyear_meds > 0))
                """,
            "UNKNOWN_DM":
                """
                        ((gp_unknowndm_date AND NOT gp_t1dm_date AND NOT gp_t2dm_date) AND NOT
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
            between=[days_before(start_date, 365), start_date],
            returning="number_of_matches_in_period",
        ),
        insulin_lastyear_meds=patients.with_these_medications(
            insulin_med_codes,
            between=[days_before(start_date, 365), start_date],
            returning="number_of_matches_in_period",
        ),

     ),   

    #DIABETES OUTCOME SECONDARY CARE
    t1dm_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=diabetes_t1_codes_secondary,  # optional
        on_or_after=start_date
,
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": start_date}, 
        "incidence" : 0.15},
   ),
    ketoacidosis_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=diabetic_ketoacidosis_codes_secondary,  # optional
        on_or_after=start_date,
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": start_date}, 
        "incidence" : 0.15},
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
            on_or_after=days_before(start_date, 3653),
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
                on_or_before=days_before(start_date, 1),
                returning="category",
            ),
            ever_smoked=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S", "E"]),
                on_or_before=days_before(start_date, 1),
            ),
            smoked_last_18_months=patients.with_these_clinical_events(
                filter_codes_by_category(clear_smoking_codes, include=["S"]),
                between=[days_before(start_date, 548), start_date],
            ),
        ),
        hypertension_date=patients.with_these_clinical_events(
            hypertension_codes, return_first_date_in_period=True, include_month=True,
        ),
        hba1c_mmol_per_mol=patients.with_these_clinical_events(
            hba1c_new_codes,
            find_last_match_in_period=True,
            between=[days_before(start_date, 730), start_date],
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
            between=[days_before(start_date, 730), start_date],
            returning="numeric_value",
            include_date_of_match=True,
            return_expectations={
                "float": {"distribution": "normal", "mean": 5, "stddev": 2},
                "incidence": 0.95,
            },
        ),

    dereg_date=patients.date_deregistered_from_all_supported_practices(
        on_or_before=end_date, 
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest": start_date}},
    ),


    died_ons_covid_flag_any=patients.with_these_codes_on_death_certificate(
        covid_codelist,
        on_or_after=start_date,
        match_only_underlying_cause=False,
        return_expectations={"date": {"earliest" : start_date},
        "rate" : "exponential_increase"},
    ),
    died_ons_date=patients.died_from_any_cause(
        on_or_after=start_date,
        returning="date_of_death",
        include_month=True,
        include_day=True,
        return_expectations={"date": {"earliest" : start_date},
        "rate" : "exponential_increase"},
    ),

    gp_covid_code_date=patients.with_these_clinical_events(
        covid_primary_care_code,        
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_date,
            return_expectations={"date": {"earliest": start_date},},
        ),

    gp_positivetest_date=patients.with_these_clinical_events(
        covid_primary_care_positive_test,        
            return_first_date_in_period=True,
            date_format="YYYY-MM-DD",
            on_or_after=start_date,
            return_expectations={"date": {"earliest": start_date},},
        ),
    sgss_tested_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="any",
        on_or_after=start_date,
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest" : start_date},
        "rate" : "exponential_increase"},
    ),
    sgss_positive_date=patients.with_test_result_in_sgss(
        pathogen="SARS-CoV-2",
        test_result="positive",
        on_or_after=start_date,
        find_first_match_in_period=True,
        returning="date",
        date_format="YYYY-MM-DD",
        return_expectations={"date": {"earliest" : start_date},
        "rate" : "exponential_increase"},
    ),

    covid_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=covid_codelist,  # optional
        on_or_after=start_date,
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": start_date}, "incidence" : 0.25},
   ),
    
    covid_admission_primary_diagnosis=patients.admitted_to_hospital(
        returning="primary_diagnosis",
        with_these_diagnoses=covid_codelist,  # optional
        on_or_after=start_date,
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD", 
        return_expectations={"date": {"earliest": start_date},"incidence" : 0.25,
            "category": {"ratios": {"U071":0.5, "U072":0.5}},
        },
    ),
    ####  
    pneumonia_admission_date=patients.admitted_to_hospital(
        returning= "date_admitted" ,  # defaults to "binary_flag"
        with_these_diagnoses=pneumonia_codelist,  # optional
        on_or_after=start_date,
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD",  
        return_expectations={"date": {"earliest": start_date}, "incidence" : 0.25},
   ),
    
    pneumonia_admission_primary_diagnosis=patients.admitted_to_hospital(
        returning="primary_diagnosis",
        with_these_diagnoses=pneumonia_codelist,  # optional
        on_or_after=start_date,
        find_first_match_in_period=True,  
        date_format="YYYY-MM-DD", 
        return_expectations={"date": {"earliest": start_date}},
    ),
    pneumonia_discharge_date=patients.admitted_to_hospital(
        returning="date_discharged",
        with_these_diagnoses=pneumonia_codelist,
        on_or_after=start_date,
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest": start_date}},
    ),

    )
    return common_variables
