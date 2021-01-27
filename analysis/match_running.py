from match import match




## Match COVID population to general population from 2020
match(
    case_csv="input_covid",
    match_csv="input_control_2020",
    matches_per_case=5,
    match_variables={
        "sex": "category",
        "age": 1,
        "stp": "category",
    },
    closest_match_variables=["age"],
    replace_match_index_date_with_case="no_offset",
    index_date_variable="indexdate",
    date_exclusion_variables={
        "died_date_ons": "before",
        "covid_date": "before",
    },
)
