from cohortextractor import (
    codelist,
    codelist_from_csv,
)

covid_codelist = codelist(["U071", "U072"], system="icd10")

confirmed_covid_codelist = codelist(["U071"], system="icd10")

suspected_covid_codelist = codelist(["U072"], system="icd10")

covid_primary_care_positive_test=codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-positive-test.csv",
    system="ctv3", 
    column="CTV3ID",
)

covid_primary_care_code=codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-clinical-code.csv",
    system="ctv3", 
    column="CTV3ID",
)

covid_primary_care_sequalae=codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-probable-covid-sequelae.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_primary_care_exposure = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-exposure-to-disease.csv", 
    system="ctv3", 
    column="CTV3ID",
)

covid_primary_care_historic_case = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-historic-case.csv", 
    system="ctv3", 
    column="CTV3ID",
)

covid_primary_care_potential_historic_case = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-potential-historic-case.csv", 
    system="ctv3", 
    column="CTV3ID",
)

covid_suspected_code = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-suspected-covid-suspected-codes.csv", 
    system="ctv3", 
    column="CTV3ID",
)

covid_suspected_111 = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-helper-111-suspected.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_suspected_advice = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-suspected-covid-advice.csv",
    system="ctv3",
    column="CTV3ID",
)

covid_suspected_test = codelist_from_csv(
    "codelists/opensafely-covid-identification-in-primary-care-suspected-covid-had-test.csv",  
    system="ctv3",
    column="CTV3ID",
)




ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
ethnicity_codes_16 = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_16",
)


diabetes_t1_codes = codelist_from_csv(
    "codelists/opensafely-type-1-diabetes.csv", system="ctv3", column="CTV3ID"
)

diabetes_t2_codes = codelist_from_csv(
    "codelists/opensafely-type-2-diabetes.csv", system="ctv3", column="CTV3ID"
)

diabetes_unknown_codes = codelist_from_csv(
    "codelists/opensafely-diabetes-unknown-type.csv", system="ctv3", column="CTV3ID"
)

diabetes_t1_codes_secondary = codelist_from_csv(
    "codelists/opensafely-type-1-diabetes-secondary-care.csv", system="icd10", column="icd10_code"
)

diabetic_ketoacidosis_codes = codelist_from_csv(
    "codelists/opensafely-diabetes-ketoacidosis-ctv3-dka-unspecific.csv", system="ctv3", column="ctv3_id"
)

diabetic_ketoacidosis_codes_secondary = codelist_from_csv(
    "codelists/opensafely-diabetic-ketoacidosis-secondary-care.csv", system="icd10", column="icd10_code"
)


insulin_med_codes = codelist_from_csv(
    "codelists/opensafely-insulin-medication.csv", 
    system="snomed", 
    column="id"
)


oad_med_codes = codelist_from_csv(
    "codelists/opensafely-antidiabetic-drugs.csv",
    system="snomed",
    column="id"
)