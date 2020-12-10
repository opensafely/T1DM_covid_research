/*==============================================================================
DO FILE NAME:			02_t1dm_an_feasibility_counts
PROJECT:				T1DM and COVID outcomes
DATE: 					7th September 2020 
AUTHOR:					Rohini Mathur adapted from ethnicity study										
DESCRIPTION OF FILE:	program 02, initial counts  
						reformat variables 
						categorise variables
						label variables 
						apply exclusion criteria
DATASETS USED:			data in memory (from analysis/input.csv)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir


import delimited `c(pwd)'/output/input.csv, clear
							
==============================================================================*/

* Open a log file
cap log close
log using "$Logdir/02_t1dm_an_feasibility_counts.log", replace t

use "$Tempdir/analysis_dataset.dta", clear
safecount
safetab baseline_t1dm

local var "incident_t1dm incident_keto incident_t1dm_keto monthbefore_t1dm monthbefore_keto monthbefore_t1dm_keto  "
foreach i of local var {
	safetab `i' if baseline_t1dm==0
	safetab `i' covid if baseline_t1dm==0, col
	bysort agecat: safetab `i' covid if baseline_t1dm==0, col
	bysort sex: safetab `i' covid if baseline_t1dm==0, col
	bysort eth5: safetab `i' covid if baseline_t1dm==0, col
}

preserve
collapse (count) population=covid  (sum) covid baseline_t1dm incident_t1dm incident_keto incident_t1dm_keto monthbefore_t1dm monthbefore_keto monthbefore_t1dm_keto
gen var=1
save "$Tempdir/table0_overall.dta", replace
restore

preserve
collapse (count) population=covid  (sum) covid baseline_t1dm incident_t1dm incident_keto incident_t1dm_keto monthbefore_t1dm monthbefore_keto monthbefore_t1dm_keto, by(sex)
gen var=2
save "$Tempdir/table0_sex.dta", replace
restore

preserve
collapse (count) population=covid  (sum) covid baseline_t1dm incident_t1dm incident_keto incident_t1dm_keto monthbefore_t1dm monthbefore_keto monthbefore_t1dm_keto, by(eth5)
gen var=3
save "$Tempdir/table0_eth.dta", replace
restore

preserve
collapse (count) population=covid  (sum) covid baseline_t1dm incident_t1dm incident_keto incident_t1dm_keto monthbefore_t1dm monthbefore_keto monthbefore_t1dm_keto, by(agecat)
gen var=4
save "$Tempdir/table0_age.dta", replace
restore

preserve
collapse (count) population=covid  (sum) covid baseline_t1dm incident_t1dm incident_keto incident_t1dm_keto monthbefore_t1dm monthbefore_keto monthbefore_t1dm_keto, by(agecat sex)
gen var=5
save "$Tempdir/table0_agesex.dta", replace
restore

preserve
collapse (count) population=covid  (sum) covid baseline_t1dm incident_t1dm incident_keto incident_t1dm_keto monthbefore_t1dm monthbefore_keto monthbefore_t1dm_keto, by(agecat eth5)
gen var=6
save "$Tempdir/table0_ageeth.dta", replace
restore

*combine datasets to create a simple table of proportions and counts
use "$Tempdir/table0_overall.dta", clear
append using "$Tempdir/table0_age.dta"
append using "$Tempdir/table0_sex.dta"
append using "$Tempdir/table0_eth.dta"
append using "$Tempdir/table0_agesex.dta"
append using "$Tempdir/table0_ageeth.dta"
destring var, replace
label define var 1"Overall" 2"Sex" 3"Eth" 4"Age" 5"Age-sex" 6"Age-eth"
label values var var
replace agecat=0 if agecat==. 
label define agecat 0 "All ages", modify
label values agecat agecat
sort var agecat  

*create proportions
local var "incident_t1dm incident_keto incident_t1dm_keto monthbefore_t1dm monthbefore_keto monthbefore_t1dm_keto  "
foreach i of local var {
gen `i'_percent=`i'/covid*100
label var `i'_percent "`i'"
}
gen covid_percent=covid/baseline_t1dm*100

label var covid_percent "% of people with T1DM who had COVID after T1DM diagnosis"

*save dataset for use as table
outsheet using "$Tabfigdir/02_t1dm_an_feasibility_counts.txt", replace
save "$Tempdir/02_t1dm_an_feasibility_count.dta", replace
insheet using "$Tabfigdir/02_t1dm_an_feasibility_counts.txt", clear
