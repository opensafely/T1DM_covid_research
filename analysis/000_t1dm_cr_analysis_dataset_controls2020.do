********************************************************************************
*
*	Do-file:		000_cr_define_covariates.do
*
*	Programmed by:	Alex & John (Based on Fizz & Krishnan)
*
*	Data used:		None
*
*	Data created:   None
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		To create dataset for cases with COVID-19
*
*	Note:			
********************************************************************************

*start with cases of COVID-19
import delimited "`c(pwd)'/output/input_control_2020.csv", clear

********** INSERT DATA END DATE ************
global dataEndDate td(01dec2020)


di "STARTING COUNT FROM IMPORT:"
noi safecount

****************************************
*   POPULATION FLOWCHART
****************************************
safecount

* Age: Exclude children and implausibly old people
qui summ age // Should be no missing ages
noi di "DROPPING AGE>105:" 
drop if age>105
noi di "DROPPING AGE<18:" 
drop if age<18
assert inrange(age, 18, 105)

* Age: Exclude those with implausible ages
assert age<.
noi di "DROPPING AGE<105:" 
drop if age>105
safecount

* Sex: Exclude categories other than M and F
assert inlist(sex, "M", "F", "I", "U")
noi di "DROPPING GENDER NOT M/F:" 
drop if inlist(sex, "I", "U")
safecount

* STP
noi di "DROPPING IF STP MISSING:"
drop if stp==""
safecount

* IMD 
noi di "DROPPING IF NO IMD" 
capture confirm string var imd 
if _rc==0 {
	drop if imd==""
}
else {
	drop if imd>=.
}
safecount


/* COVID EXPOSURE AND T1DM OUTCOME DEFINITIONS==================================================*/

*COVID	
ren gp_covid_code_date			gp_confirmed_date
ren gp_positivetest_date		gp_positive_date
ren sgss_positive_date			sgss_positive_date
ren covid_admission_date		c19_hospitalised_date
ren died_ons_covid_flag_any		coviddeath_date

*T1DM
ren t1dm_admission_date			t1dm_hospitalised_date
ren ketoacidosis_admission_date	keto_hospitalised_date
	 
*DEATH
ren died_ons_date				death_date

/* CONVERT STRINGS TO DATE FOR COVID EXPOSURE VARIABLES =============================*/
* Recode to dates from the strings 

foreach var of global allvar {
	confirm string variable `var'_date
	rename `var'_date `var'_dstr
	gen `var'_date = date(`var'_dstr, "YMD")
	drop `var'_dstr
	format `var'_date %td 

}

******************************
*  Convert strings to dates  *
******************************
ren bmi_date_measured bmi_date
foreach var of varlist hypertension_date	///
					   gp_unknowndm_date	///
					   bmi_date			 	///
					   sgss_tested			{
	di "`var'"
	capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
	}
	else {
		rename `var' `var'_dstr
		gen `var'_date = date(`var'_dstr, "YMD") 
		order `var'_date, after(`var'_dstr)
		drop `var'_dstr
	}
	format `var'_date %td
}

* Binary indicators for exposures and outcomes
foreach i of global allvar {
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


**********************
* Exposure
*Diagnosed with covid in primary care, SGSS, or hospital - for controls this is a censoring event, their follow-up ends if they develop the exposure of interest
**********************

gen covid_date=min(gp_confirmed_date, gp_positive_date,sgss_positive_date, c19_hospitalised_date)
format covid_date %td

* for matching - no index date as this will be determined by the C19 cases
gen covid_exposed = 0
gen flag = "controls_2020"

**************
*  Outcomes  *
* T1DM or Ketoacidosis, T2DM as a control outcome
**************

/*   Outcomes   */
*identify t1dm cases
gen t1dm_date=min(gp_t1dm_date, t1dm_hospitalised_date)

gen t1dm=0
replace t1dm=1 if t1dm_date!=.

*identify keto cases
gen keto_date=min(gp_ketoacidosis_date, keto_hospitalised_date)
gen keto=0
replace keto=1 if keto_date!=.

*identify either
gen t1dm_keto_date=min(t1dm_date, keto_date)
gen t1dm_keto=0
replace t1dm_keto=1 if t1dm_keto_date!=.

*identify t2dm cases
ren gp_t2dm* t2dm*

local p "covid_exposed t1dm keto t1dm_keto t2dm"
foreach i of local p {
label define `i' 0"No `i'" 1"`i'"
label values `i' `i'
safetab `i'
}


* Note: There may be deaths recorded after end of our study 
* Set these to missing
replace death_date = . if death_date>$dataEndDate
format *date %td

**********************
*  Recode variables  *
**********************

/*  Demographics  */

* Sex
assert inlist(sex, "M", "F")
gen male = (sex=="M")
drop sex

gen gender = male 
drop male
label define genderLab 1 "male" 0 "female"
label values gender genderLab
label var gender "gender = 0 F, 1 M"


/* BMI */

* Set implausible BMIs to missing:
replace bmi = . if !inrange(bmi, 15, 50)

* Smoking
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"
gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = .u if smoking_status=="M"
replace smoke = .u if smoking_status==""
label values smoke smoke
drop smoking_status


* Ethnicity (5 category)
rename ethnicity ethnicity_5
replace ethnicity_5 = .u if ethnicity_5==.
label define ethnicity 	1 "White"  								///
						2 "Mixed" 								///
						3 "Asian or Asian British"				///
						4 "Black"  								///
						5 "Other"								///
						.u "Unknown"
label values ethnicity_5 ethnicity


/*  Geographical location  */

* Region
rename region region_string
assert inlist(region_string, 								///
					"East Midlands", 						///
					"East",  								///
					"London", 								///
					"North East", 							///
					"North West", 							///
					"South East", 							///
					"South West",							///
					"West Midlands", 						///
					"Yorkshire and The Humber") 
* Nine regions
gen     region_9 = 1 if region_string=="East Midlands"
replace region_9 = 2 if region_string=="East"
replace region_9 = 3 if region_string=="London"
replace region_9 = 4 if region_string=="North East"
replace region_9 = 5 if region_string=="North West"
replace region_9 = 6 if region_string=="South East"
replace region_9 = 7 if region_string=="South West"
replace region_9 = 8 if region_string=="West Midlands"
replace region_9 = 9 if region_string=="Yorkshire and The Humber"

label define region_9 	1 "East Midlands" 					///
						2 "East"   							///
						3 "London" 							///
						4 "North East" 						///
						5 "North West" 						///
						6 "South East" 						///
						7 "South West"						///
						8 "West Midlands" 					///
						9 "Yorkshire and The Humber"
label values region_9 region_9
label var region_9 "Region of England (9 regions)"

* Seven regions
recode region_9 2=1 3=2 1 8=3 4 9=4 5=5 6=6 7=7, gen(region_7)

label define region_7 	1 "East"							///
						2 "London" 							///
						3 "Midlands"						///
						4 "North East and Yorkshire"		///
						5 "North West"						///
						6 "South East"						///	
						7 "South West"
label values region_7 region_7
label var region_7 "Region of England (7 regions)"
drop region_string



**************************
*  Categorise variables  *
**************************

/*  Age variables  */ 

* Create categorised age
recode 	age 			18/39.9999=1 	///
						40/49.9999=2 	///
						50/59.9999=3 	///
						60/69.9999=4 	///
						70/79.9999=5 	///
						80/max=6, 		///
						gen(agegroup) 

label define agegroup 	1 "18-<40" 		///
						2 "40-<50" 		///
						3 "50-<60" 		///
						4 "60-<70" 		///
						5 "70-<80" 		///
						6 "80+"
label values agegroup agegroup


* Check there are no missing ages
assert age<.
assert agegroup<.

/*  Body Mass Index  */

label define bmicat 	1 "Underweight (<18.5)" 				///
						2 "Normal (18.5-24.9)"					///
						3 "Overweight (25-29.9)"				///
						4 "Obese I (30-34.9)"					///
						5 "Obese II (35-39.9)"					///
						6 "Obese III (40+)"						///
						.u "Unknown (.u)"


	* Categorised BMI (NB: watch for missingness)
    gen 	bmicat = .
	recode  bmicat . = 1 if bmi<18.5
	recode  bmicat . = 2 if bmi<25
	recode  bmicat . = 3 if bmi<30
	recode  bmicat . = 4 if bmi<35
	recode  bmicat . = 5 if bmi<40
	recode  bmicat . = 6 if bmi<.
	replace bmicat = .u  if bmi>=.
	label values bmicat bmicat

/*  IMD  */

* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes
replace imd = imd + 1
replace imd = .u if imd_o==-1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5=1 4=2 3=3 2=4 1=5 .u=.u

label define imd 	1 "1 least deprived"	///
					2 "2" 					///
					3 "3" 					///
					4 "4" 					///
					5 "5 most deprived" 	///
					.u "Unknown"
label values imd imd 


	
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
	gen 	hba1ccat = 0 if hba1c_pct <  6.5
	replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
	replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
	replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
	replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
	label values hba1ccat hba1ccat

**************
*DROP THOSE WITH OUTCOME BEFORE EXPOSURE (ANY DIABETES)
**************
drop if t1dm_keto_date < covid_date 
drop if t2dm_date < covid_date
safecount	

save "$Tempdir/cohort_controls_2020.dta", replace 






