from match import match




## Match COVID population to pneumonia pop
match(
    case_csv="input_covid",
    match_csv="input_pneumonia",
    matches_per_case=5,
    match_variables={
        "sex": "category",
        "age": 1,
        "stp": "category",
    },
    closest_match_variables=["age"],
    replace_match_index_date_with_case="no_offset",
    index_date_variable="patient_index_date",
    date_exclusion_variables={
        "died_date_ons": "before",
        "exposure_hospitalisation": "before",
    },
)
