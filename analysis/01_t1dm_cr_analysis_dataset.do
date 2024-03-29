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
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles


* Open a log file
cap log close
log using ./released_analysis_results/01_t1dm_cr_create_analysis_dataset.log, replace t

import delimited ./output/input.csv, clear

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


*******************************************************************************



/* CREATE VARIABLES===========================================================*/

/* COVID EXPOSURE AND T1DM OUTCOME DEFINITIONS==================================================*/

*COVID	
ren gp_covid_code_date				gp_confirmed_date
ren gp_positivetest_date			gp_positive_date
ren covid_admission_date			c19_hospitalised_date
ren died_ons_covid_flag_any			coviddeath_flag
*don't need to rename sgss_positive_date

*T1DM
ren type1_diabetes				gp_t1dm_date
ren type2_diabetes				gp_t2dm_date
ren ketoacidosis				gp_keto_date

ren t1dm_admission_date			t1dm_hospitalised_date
ren ketoacidosis_admission_date	keto_hospitalised_date
ren pneumonia_admission_date	pneumonia_hospitalised_date
	 
*DEATH
ren died_date_ons				death_date

/* CONVERT STRINGS TO DATE FOR COVID EXPOSURE VARIABLES =============================*/
*Note: kw edited to remove reliance on global (and therefore model.do) in the pipeline

foreach var of varlist gp_confirmed_date gp_positive_date sgss_positive_date c19_hospitalised_date pneumonia_hospitalised_date gp_t1dm_date gp_t2dm_date t1dm_hospitalised_date  gp_keto_date  keto_hospitalised_date death_date {
		confirm string variable `var'
		rename `var' _tmp
		gen `var' = date(_tmp, "YMD")
		drop _tmp
		format %d `var'
}


* Binary indicators for exposures and outcomes
foreach var of varlist gp_confirmed_date gp_positive_date sgss_positive_date c19_hospitalised_date pneumonia_hospitalised_date gp_t1dm_date gp_t2dm_date t1dm_hospitalised_date  gp_keto_date  keto_hospitalised_date death_date {
		
		local binaryVersion=subinstr("`var'","_date", "", 1)
		display "``var''"
		gen `binaryVersion'=0
		replace  `binaryVersion'=1 if `var'< .
		safetab `binaryVersion'
		label variable `binaryVersion' "`binaryVersion'"
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
gen covid_date=min(gp_confirmed_date, gp_positive_date, sgss_positive_date, c19_hospitalised_date)
format covid_date %td

gen covid=0
replace covid=1 if covid_date!=.
safetab covid

*identify t1dm cases
gen t1dm_date=min(gp_t1dm_date, t1dm_hospitalised_date)

gen t1dm=0
replace t1dm=1 if t1dm_date!=.

*identify keto cases
gen keto_date=min(gp_keto_date, keto_hospitalised_date)
gen keto=0
replace keto=1 if keto_date!=.

*identify either
gen t1dm_keto_date=min(gp_keto_date, keto_hospitalised_date, gp_t1dm_date, t1dm_hospitalised_date)
gen t1dm_keto=0
replace t1dm_keto=1 if t1dm_keto_date!=.

*identify t2dm cases
ren gp_t2dm* t2dm*

local p "covid t1dm keto t1dm_keto t2dm"
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

******************************
*  Convert strings to dates  *
******************************

* To be added: dates related to outcomes
foreach var of varlist bmi_date_measured 	///
					   hypertension 	{ 
	capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
		rename `var' `var'_date
	}
	else {
		rename `var' `var'_dstr
		gen `var'_date = date(`var'_dstr, "YMD") 
		order `var'_date, after(`var'_dstr)
		drop `var'_dstr
	}
	format `var'_date %td
}

/* BMI */

* Set implausible BMIs to missing:
replace bmi = . if !inrange(bmi, 15, 50)

****************************************
*   Hba1c:  Level of diabetic control  *
****************************************

label define hba1ccat	0 "<6.5%"  		///
						1">=6.5-7.4"  	///
						2">=7.5-7.9" 	///
						3">=8-8.9" 		///
						4">=9"

* Set zero or negative to missing
	replace hba1c_percentage   = . if hba1c_percentage   <= 0
	replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol <= 0


	/* Express  HbA1c as percentage  */ 

	* Express all values as perecentage 
	noi summ hba1c_percentage hba1c_mmol_per_mol
	gen 	hba1c_pct = hba1c_percentage 
	replace hba1c_pct = (hba1c_mmol_per_mol/10.929) + 2.15  ///
				if hba1c_mmol_per_mol<. 

	* Valid % range between 0-20  
	replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
	replace hba1c_pct = round(hba1c_pct, 0.1)


	/* Categorise hba1c and diabetes  */

	* Group hba1c
	gen 	hba1ccat_1 = 0 if hba1c_pct <  6.5
	replace hba1ccat_1 = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
	replace hba1ccat_1 = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
	replace hba1ccat_1 = 3 if hba1c_pct >= 8    & hba1c_pct < 9
	replace hba1ccat_1 = 4 if hba1c_pct >= 9    & hba1c_pct !=.
	label values hba1ccat_1 hba1ccat
	
	* Delete unneeded variables
	drop hba1c_pct hba1c_percentage hba1c_mmol_per_mol
	

* Smoking
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"
gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = .u if smoking_status=="M"
replace smoke = .u if smoking_status==""
label values smoke smoke
drop smoking_status


/* SET DATES===============================================================*/ 
*generate indexdate as date of COVID-19 infection
gen indexdate=covid_date

*gen startdate as start of cohort followup
gen startdate=d("01/02/2020")

* Censoring dates for each outcome (last date outcome data available) 
*https://github.com/opensafely/rapid-reports/blob/master/notebooks/latest-dates.ipynb

*outcomes are t1dm and ketoacidosis- censoring should be at earliest of TPP or SUS end date
gen censor_date = d("01/11/2020")
sum censor_date, format

gen enddate=min(dereg_date,death_date,censor_date)

gen yob=2020-age


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
lab var bmi 						"BMI"
lab var hypertension				"Hypertension"

*Outcome dates
foreach i of global outcomes {
	label var `i'_date					"Failure date:  `i'"
	d `i'_date
}

sort patient_id

format *date* %d
save ./output/analysis_dataset.dta, replace


*prepare dataset for matching
keep patient_id indexdate sex startdate enddate covid yob
ren patient_id patid
ren sex gender
ren covid exposed
sort indexdate
save ./output/analysis_dataset_formatching.dta, replace

*create a 10% sample of the matching-prepared dataset
set seed 10853
sample 10
count
save ./output/analysis_dataset_formatchingTENPERCENT.dta, replace

*create two datasets for python matching algorithm written by Alex W.

*COVID-19 cases
use ./output/analysis_dataset.dta, clear
keep patient_id indexdate sex startdate enddate covid_date covid age 
label variable enddate "min(dereg_date,death_date,censor_date)"
label variable startdate "2nd Feb 2020"
label variable covid_date "Date of COVID-19 diagnosis in primary or secondary care"
keep if covid==1
gen case=1
tab case
save ./output/input_covid.csv, replace

*2020 controls - excludes all covid cases (for now consensus is that bias is low)
use ./output/analysis_dataset.dta, clear
keep patient_id sex startdate enddate covid_date covid age 
label variable enddate "min(dereg_date,death_date,censor_date)"
label variable startdate "2nd Feb 2020"
label variable covid_date "Date of COVID-19 diagnosis in primary or secondary care"
keep if covid==0
gen case=0
tab case
save ./output/input_controls_2020.csv, replace


* Close log file 
log close

