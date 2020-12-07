********************************************************************************
*
*	Do-file:		000_cr_matches.do
*
*	Programmed by:	Krishnan & John 
*
*	Data used:		None
*
*	Data created:   None
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		T
*
*	Note:			
********************************************************************************

* Open a log file
capture log close
log using "output/104_cr_matched_cohort_control_2019", text replace

foreach outcome in primary {

use "data/cr_matches_control_2019_`outcome'", clear
reshape long matchedto_, i(patient_id)

rename patient_id setid
rename matchedto patient_id

expand 2 if setid!=setid[_n-1], gen(expanded)
replace patient_id=setid if expanded==1
drop expanded

replace patient_id = -_n if patient_id==-999

sort setid patient_id

drop if patient_id<0 | patient_id==.
drop _j
* create flag for matched set

drop if patient_id == setid
gen flag = "control_2019" if patient_id!=setid
 * merge on patient characteristics 
merge 1:1 patient_id flag using "data/cohort_`outcome'_control_2019"
keep if _merge ==3
drop _merge

gen matchedFlag = 1 
save "data/cr_matches_long_control_2019_`outcome'.dta", replace
erase "data/cr_matches_control_2019_`outcome'.dta"

use "data/cr_matched_cohort_`outcome'", replace 

append using "data/cr_matches_long_control_2019_`outcome'.dta"

bysort setid: egen eligibleMatchFound = max(matchedFlag)
keep if eligibleMatchFound == 1
safecount
if `r(N)'==0 {
	
	noi di "No control 2019 patients matched" 
	global noMatchFlag1 = 1 
}
else {
    global noMatchFlag1 = 0
drop matchedFlag eligibleMatchFound

bysort setid patient: gen duplicatePatid = _n
safecount if duplicatePatid > 1
drop if duplicatePatid > 1
drop duplicatePatid

sort setid
bysort setid: gen indexPneumonia = indexdate if flag == "pneumonia_hosp"
egen index2019 = max(indexPneumonia), by(setid)
format index2019 %td


bysort setid: replace indexdate = index2019 if indexdate==.
drop indexPneumonia index2019
order setid patient_id indexdate flag 

}

save "data/cr_matched_cohort_`outcome'", replace 
}

log close