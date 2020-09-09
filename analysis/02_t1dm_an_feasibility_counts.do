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
drop if baseline_t1dm==1
safecount


local var "incident_t1dm"
foreach i of local var {
	safetab `i'
	safetab `i' confirmed, col
	bysort agecat: safetab `i' confirmed, col
	bysort sex: safetab `i' confirmed, col
	bysort eth5: safetab `i' confirmed, col
	bysort imd: safetab `i' confirmed, col
	bysort region: safetab `i' confirmed, col
}

preserve
collapse (count) population=confirmed  (sum) confirmed  baseline_t1dm incident_t1dm, by(agecat)
gen var=1
save "$Tempdir/table0_overall.dta", replace
restore

preserve
collapse (count) population=confirmed (sum) confirmed baseline_t1dm incident_t1dm, by(agecat sex)
gen var=2
save "$Tempdir/table0_sex.dta", replace
restore

preserve
collapse (count) population=confirmed (sum) confirmed  baseline_t1dm incident_t1dm, by(agecat eth5)
gen var=3
save "$Tempdir/table0_eth.dta", replace
restore

*combine datasets to create a simple table of proportions and counts
use "$Tempdir/table0_overall.dta"
append using "$Tempdir/table0_sex.dta"
append using "$Tempdir/table0_eth.dta"
destring var, replace

label define var 1"Overall" 2"Sex" 3"Eth"
label values var var
sort agecat var 

*create proportions

gen baseline_t1dm_percent=baseline_t1dm/confirmed*100
gen incident_t1dm_percent=incident_t1dm/confirmed*100
gen confirmed_percent=confirmed/baseline_t1dm*100

label var baseline_t1dm_percent "% of people with COVID who had T1DM prior to infection"
label var incident_t1dm_percent "% of people with COVID who had T1DM after"
label var confirmed_percent "% of people with T1DM who had COVID after T1DM diagnosis"

*save dataset for use as table
outsheet using "$Tabfigdir/02_t1dm_an_feasibility_counts.txt", replace
save "$Tempdir/02_t1dm_an_feasibility_count.dta", replace
insheet using "$Tabfigdir/02_t1dm_an_feasibility_counts.txt", clear
