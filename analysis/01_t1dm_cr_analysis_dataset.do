/*==============================================================================
DO FILE NAME:			01_t1dm_cr_analysis_dataset
PROJECT:				T1DM and COVID outcomes
DATE: 					7th September 2020 
AUTHOR:					Rohini Mathur adapted from ethnicity study, subsequent edits (adding SUS data) by Kevin Wing									
DESCRIPTION OF FILE:	program 01, data management for project  
						reformat variables 
						categorise variables
						label variables 
						apply exclusion criteria
DATASETS USED:			data in memory (from analysis/input.csv)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir


				
==============================================================================*/

* Open a log file
cap log close
log using 01_t1dm_cr_create_analysis_dataset.log, replace t
import delimited `c(pwd)'/output/input.csv, clear

di "STARTING safecount FROM IMPORT:"
safecount

****************************
*  Create required cohort  *
****************************

* Age: Exclude those with implausible ages
cap assert age<.
noi di "DROPPING AGE<105:" 
drop if age>105
safecount

* Sex: Exclude categories other than M and F
cap assert inlist(sex, "M", "F", "I", "U")
noi di "DROPPING GENDER NOT M/F:" 
drop if inlist(sex, "I", "U")

gen male = 1 if sex == "M"
replace male = 0 if sex == "F"
label define male 0"Female" 1"Male"
label values male male
safetab male
safecount


*Start dates
gen index 			= "01/02/2020"

* Date of cohort entry, 1 Feb 2020
gen indexdate = date(index, "DMY")
format indexdate %d


*******************************************************************************



/* CREATE VARIABLES===========================================================*/

/* COVID EXPOSURE AND T1DM OUTCOME DEFINITIONS==================================================*/

*COVID	
ren primary_care_case					confirmed_date
ren first_tested_for_covid				tested_date
ren first_positive_test_date			positivetest_date
ren covid_admission_date			 	c19_hospitalised_date
ren died_ons_covid_flag_any				coviddeath_date

*T1DM
ren type1_diabetes				t1dm_primarycare_date
ren type2_diabetes				t2dm_primarycare_date
ren ketoacidosis				keto_primarycare_date

ren t1dm_admission_date			t1dm_hospitalised_date
ren ketoacidosis_admission_date	keto_hospitalised_date
	 
*DEATH
ren died_date_ons				death_date

/* CONVERT STRINGS TO DATE FOR COVID EXPOSURE VARIABLES =============================*/
* Recode to dates from the strings 

foreach var of global outcomes {
	confirm string variable `var'_date
	rename `var'_date `var'_dstr
	gen `var'_date = date(`var'_dstr, "YMD")
	drop `var'_dstr
	format `var'_date %td 

}

* Binary indicators for covid
foreach i of global outcomes {
		gen `i'=0
		replace  `i'=1 if `i'_date < .
		safetab `i'
		label variable `i' "`i'"
}


*date of deregistration
rename dereg_date dereg_dstr
	gen dereg_date = date(dereg_dstr, "YMD")
	drop dereg_dstr
	format dereg_date %td 
	
gen dereg=0
replace dereg=1 if dereg_date < .
safetab dereg

*identify covid cases
gen covid_date=min(confirmed_date, positivetest_date, c19_hospitalised_date)
format covid_date %td

gen covid=0
replace covid=1 if covid_date!=.
safetab covid

*identify t1dm cases
gen t1dm_date=min(t1dm_primarycare_date, t1dm_hospitalised_date)

gen t1dm=0
replace t1dm=1 if t1dm_date!=.

*identify keto cases
gen keto_date=min(keto_primarycare_date, keto_hospitalised_date)
gen keto=0
replace keto=1 if keto_date!=.

*identify either
gen t1dm_keto_date=min(keto_primarycare_date, keto_hospitalised_date, t1dm_primarycare_date, t1dm_hospitalised_date)
gen t1dm_keto=0
replace t1dm_keto=1 if t1dm_keto_date!=.


local p "covid t1dm keto t1dm_keto"
foreach i of local p {
label define `i' 0"No `i'" 1"`i'"
label values `i' `i'
safetab `i'
}


*identify those with baseline t1dm/dka (prior to covid) and incident t1dm/dka (post covid)
local p "t1dm keto t1dm_keto"
foreach i of local p {
gen baseline_`i'=0
replace baseline_`i'=1 if `i'_date<(covid_date-30) & covid_date!=.

gen incident_`i'=0
replace incident_`i'=1 if `i'_date>=covid_date & `i'_date!=. & covid_date!=.

*identify people with T1DM/dka in the 30 days before covid
gen monthbefore_`i'=0
replace monthbefore_`i'=1 if `i'_date>=(covid_date-30) & `i'_date!=. & covid_date!=.
}

local p "t1dm keto t1dm_keto"
foreach i of local p {

safetab `i'
safetab baseline_`i'
safetab incident_`i'
safetab monthbefore_`i'
}

/* CENSORING */
/* SET FU DATES===============================================================*/ 

* Censoring dates for each outcome (last date outcome data available) 
*https://github.com/opensafely/rapid-reports/blob/master/notebooks/latest-dates.ipynb

*outcomes are t1dm and ketoacidosis- censoring should be at earliest of TPP or SUS end date
gen t1dm_censor_date = d("31/08/2020")
gen keto_censor_date = d("31/08/2020")
gen t1dm_keto_censor_date = d("31/08/2020")

format *censor_date %d
sum *censor_date, format
*******************************************************************************


/* DEMOGRAPHICS */ 

* Ethnicity (5 category)
label define ethnicity 	1 "White"  					///
						2 "Mixed" 					///
						3 "Asian or Asian British"	///
						4 "Black"  					///
						5 "Other"					
						
label values ethnicity ethnicity
safetab ethnicity, m

 *re-order ethnicity
 gen eth5=1 if ethnicity==1
 replace eth5=2 if ethnicity==3
 replace eth5=3 if ethnicity==4
 replace eth5=4 if ethnicity==2
 replace eth5=5 if ethnicity==5
 replace eth5=6 if ethnicity==.

 label define eth5	 	1 "White"  					///
						2 "South Asian"		  ///						
						3 "Black"  					///
						4 "Mixed"					///
						5 "Other"					///
						6 "Unknown"
					

label values eth5 eth5
safetab eth5, m

* Ethnicity (16 category)
replace ethnicity_16 = 17 if ethnicity_16==.
label define ethnicity_16 									///
						1 "British" 		///
						2 "Irish" 							///
						3 "Other White" 					///
						4 "White + Black Caribbean" 		///
						5 "White + Black African"			///
						6 "White + Asian" 					///
 						7 "Other mixed" 					///
						8 "Indian" 		///
						9 "Pakistani" 	///
						10 "Bangladeshi" ///
						11 "Other Asian" 					///
						12 "Caribbean" 						///
						13 "African" 						///
						14 "Other Black" 					///
						15 "Chinese" 						///
						16 "Other" 							///
						17 "Unknown"
						
label values ethnicity_16 ethnicity_16
safetab ethnicity_16,m

* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old

/*  Age variables  */ 

* Create categorised age 
recode age 	0/17.9999=0 ///
			18/29.9999 = 1 /// 
		    30/39.9999 = 2 /// 
			40/49.9999 = 3 ///
			50/59.9999 = 4 ///
			60/69.9999 = 5 ///
			70/79.9999 = 6 ///
			80/max = 7, gen(agegroup) 

label define agegroup 	0 "0-<18" ///
						1 "18-<30" ///
						2 "30-<40" ///
						3 "40-<50" ///
						4 "50-<60" ///
						5 "60-<70" ///
						6 "70-<80" ///
						7 "80+"
						
label values agegroup agegroup

gen agecat=.
replace agecat=1 if age<18
replace agecat=2 if age>=18 & age<=45
replace agecat=3 if age>=46 & age<=105

label define agecat 1"Children" 2"Adults 18-45" 3"Adults 46-105"
label values agecat agecat
safetab agecat, m

/*  IMD  */
* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes

* add one to create groups 1 - 5 
replace imd = imd + 1

* - 1 is missing, should be excluded from population 
replace imd = .u if imd_o == -1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5 = 1 4 = 2 3 = 3 2 = 4 1 = 5 .u = .u

label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" .u "Unknown"
label values imd imd 
safetab imd, m


/**** Create survival times  ****/
* For looping later, name must be stime_binary_outcome_name

* Survival time = last followup date (first: deregistration date, end study, death, or that outcome)
*Ventilation does not have a survival time because it is a yes/no flag
foreach i of global outcomes3 {
	gen stime_`i' = min(`i'_censor_date, death_date, `i'_date, dereg_date)
}

* If outcome occurs after censoring, set to zero
foreach i of global outcomes3 {
	replace `i'=0 if `i'_date>stime_`i'
	tab `i'
}

* Format date variables
format  stime* %td 

/* LABEL VARIABLES============================================================*/
*  Label variables you are intending to keep, drop the rest 


* Demographics
label var patient_id				"Patient ID"
label var age 						"Age (years)"
label var agegroup					"Grouped age"
label var agecat					"3 catgories of age"
label var sex 						"Sex"
label var male 						"Male"
label var imd 						"Index of Multiple Deprivation (IMD)"
label var eth5						"Eth 5 categories"
label var ethnicity_16				"Eth 16 categories"
label var stp 						"Sustainability and Transformation Partnership"
lab var region						"Region of England"

/* Outcomes and follow-up
label var indexdate					"Date of study start (Feb 1 2020)"
foreach i of global outcomes {
	label var `i'_censor_date		 "Date of admin censoring"
}
*/
*Outcome dates
foreach i of global outcomes {
	label var `i'_date					"Failure date:  `i'"
	d `i'_date
}

* binary outcome indicators
foreach i of global outcomes {
	lab var `i' 					"`i'"
	safetab `i'
}

foreach i of global outcomes2 {
	lab var `i' 					"`i'"
	safetab `i'
}

sort patient_id


save "$Tempdir/analysis_dataset.dta", replace

****************************************************************
*  Create outcome specific datasets for the whole population  *
*****************************************************************


foreach i of global outcomes3 {
	use "$Tempdir/analysis_dataset.dta", clear
	
	drop if `i'_date <= indexdate 

	stset stime_`i', fail(`i') 				///	
	id(patient_id) enter(indexdate) origin(indexdate)
	save "$Tempdir/analysis_dataset_STSET_`i'.dta", replace
}	

	
* Close log file 
log close

