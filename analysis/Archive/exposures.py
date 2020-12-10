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
        return_expectations={"date": {"earliest": start_date}},
        
    ),
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