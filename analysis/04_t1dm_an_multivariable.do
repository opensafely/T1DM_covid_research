/*==============================================================================
DO FILE NAME:			04_t1dm_an_multivariable_
PROJECT:				Ethnicity and COVID
AUTHOR:					R Mathur (modified from A wong and A Schultze)
DATE: 					15 July 2020					
DESCRIPTION OF FILE:	program 06 
						univariable regression
						multivariable regression 
DATASETS USED:			data in memory ($tempdir/analysis_dataset_STSET_outcome)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir
						time_to_t1dm, printed to $Tabfigdir
						complete case analysis	
==============================================================================*/

* Open a log file

cap log close
macro drop hr
log using "$Logdir/04_t1dm_an_multivariable_", replace t 

cap file close tablecontent
file open tablecontent using $Tabfigdir/time_to_t1dm.txt, write text replace
file write tablecontent ("Table 2: Association between COVID-19 exposure and T1DM/Ketoacidosis outcomes - Complete Case Analysis") _n
file write tablecontent _tab ("Denominator") _tab ("Event") _tab ("Total person-weeks") _tab ("Rate per 1,000") _tab ("Crude") _tab _tab ("Age-Sex Adjusted") _tab _tab ("Plus ethnicity") _tab _tab 	("plus IMD")  _tab _tab  _n
file write tablecontent _tab _tab _tab _tab _tab   ("HR") _tab ("95% CI") _tab ("HR") _tab ("95% CI") _tab ("HR") _tab ("95% CI") _tab ("HR") _tab ("95% CI") _tab _tab _n


foreach i of global outcomes3 {
use "$Tempdir/analysis_dataset_STSET_`i'.dta", clear
safetab covid  `i', missing row
} //end outcomes

foreach i of global outcomes3 { //start outcomes
	di "`i'"
	
* Open Stata dataset
use "$Tempdir/analysis_dataset_STSET_`i'.dta", clear

/* Main Models=================================================================*/

*crude
stcox i.covid, strata(stp) nolog
estimates save "$Tempdir/model1_`i'", replace 
eststo model1
parmest, label eform format(estimate p lb ub) saving("$Tempdir/model1_`i'", replace) idstr("model1_`i'") 
local hr "`hr' "$Tempdir/model1_`i'" "


*Age and gender
stcox i.covid i.male i.agecat, strata(stp) nolog
estimates save "$Tempdir/model2_`i'", replace 
eststo model2
parmest, label eform format(estimate p lb ub) saving("$Tempdir/model2_`i'", replace) idstr("model2_`i'")
local hr "`hr' "$Tempdir/model2_`i'" "
 
* Age, Gender, ethncity
stcox i.covid i.male i.agecat i.eth5, strata(stp) nolog
estimates save "$Tempdir/model3_`i'", replace 
eststo model3
parmest, label eform format(estimate p lb ub) saving("$Tempdir/model3_`i'", replace) idstr("model3_`i'")
local hr "`hr' "$Tempdir/model3_`i'" "

* Age, Gender, ethncity, IMD
stcox i.covid i.male i.agecat i.eth5 i.imd, strata(stp) nolog
estimates save "$Tempdir/model4_`i'", replace 
eststo model4
parmest, label eform format(estimate p lb ub) saving("$Tempdir/model4_`i'", replace) idstr("model4_`i'")
local hr "`hr' "$Tempdir/model4_`i'" "


/* Estout================================================================*/ 
esttab model1 model2 model3 model4 using "$Tabfigdir/estout_time_to_t1dm.txt", b(a2) ci(2) label wide compress eform ///
	title ("`i'") ///
	varlabels(`e(labels)') ///
	stats(N_sub) ///
	append 
eststo clear

										
/* Print table================================================================*/ 
*  Print the results for the main model 


* Column headings 
file write tablecontent ("`i'") _n

*  labelled columns
local lab0: label covid 0
local lab1: label covid 1

/* counts */
 
* First row,  = 0 No COVID
	qui safecount if covid ==0
	local denominator = r(N)
	qui safecount if  covid ==0 & `i' == 1
	local event = r(N)
    bysort covid: egen total_follow_up = total(_t)
	qui su total_follow_up if  covid ==0
	local person_week = r(mean)/7
	local rate = 1000*(`event'/`person_week')
	
	file write tablecontent  ("`lab0'") _tab (`denominator') _tab (`event') _tab %10.0f (`person_week') _tab %3.2f (`rate') _tab
	file write tablecontent ("1.00") _tab _tab ("1.00") _tab _tab ("1.00")  _tab _tab ("1.00")  _n
	
* COVID exposure
	qui safecount if covid == 1
	local denominator = r(N)
	qui safecount if covid == 1 & `i' == 1
	local event = r(N)
	qui su total_follow_up if covid == 1
	local person_week = r(mean)/7
	local rate = 1000*(`event'/`person_week')
	file write tablecontent  ("`lab1'") _tab (`denominator') _tab (`event') _tab %10.0f (`person_week') _tab %3.2f (`rate') _tab  
	cap estimates use "$Tempdir/model1_`i'" 
	 cap lincom 1.covid, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab 
	cap estimates clear
	cap estimates use "$Tempdir/model2_`i'" 
	 cap lincom 1.covid, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab 
	cap estimates clear
	cap estimates use "$Tempdir/model3_`i'" 
	 cap lincom 1.covid, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _tab 
	cap estimates clear
	cap estimates use "$Tempdir/model4_`i'" 
	 cap lincom 1.covid, eform
	file write tablecontent  %4.2f (r(estimate)) _tab ("(") %4.2f (r(lb)) (" - ") %4.2f (r(ub)) (")") _n
	cap estimates clear

} //end outcomes

file close tablecontent

************************************************create forestplot dataset
di `hr'
dsconcat `hr'
duplicates drop
split idstr, p(_)
ren idstr1 model
ren idstr2 outcome
replace outcome=idstr3 if idstr3!=""
tab model

*save dataset for later
outsheet using "$Tabfigdir/FP_time_to_t1dm.txt", replace

* Close log file 
log close

insheet using $Tabfigdir/FP_time_to_t1dm.txt, clear
insheet using $Tabfigdir/estout_time_to_t1dm.txt, clear
insheet using $Tabfigdir/time_to_t1dm.txt, clear
