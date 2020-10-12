/*==============================================================================
DO FILE NAME:			03_t1dm_table1_descriptives
PROJECT:				T1DM and COVID-19 
DATE: 					8th October 2020 
AUTHOR:					R Mathur, additional edits by K Wing
						adapted from Ethnicity study	
DESCRIPTION OF FILE:	Produce a table of baseline characteristics by COVID exposure
						Output to a textfile for further formatting
DATASETS USED:			$Tempdir\analysis_dataset.dta
DATASETS CREATED: 		None
OTHER OUTPUT: 			Results in txt: $Tabfigdir\table1.txt 
						Log file: $Logdir\03_t1dm_table1_descriptives
USER-INSTALLED ADO: 	 
  (place .ado file(s) in analysis folder)	
  
 Notes:
Table 1 population is people who are alive on indexdate

 ==============================================================================*/

* Open a log file
capture log close
log using "$Logdir/03_t1dm_table1_descriptives", replace t

* Open Stata dataset
use $Tempdir/analysis_dataset, clear
safetab covid,m 

 /* PROGRAMS TO AUTOMATE TABULATIONS===========================================*/ 

********************************************************************************
* All below code from K Baskharan 
* Generic code to output one row of table

cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string) 
	
	qui cou
	local overalldenom=r(N)
	
	qui sum `variable' if `variable' `condition'
	file write tablecontent (r(max)) _tab
	
	qui cou   if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	forvalues i=0/1{
	qui cou if covid == `i'
	local rowdenom = r(N)
	qui cou if covid == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontent _n
end


* Output one row of table for co-morbidities and meds

cap prog drop generaterow2
program define generaterow2
syntax, variable(varname) condition(string) 
	
	qui cou
	local overalldenom=r(N)
	
	qui cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent %9.0gc (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	forvalues i=0/1{
	qui cou if covid == `i'
	local rowdenom = r(N)
	qui cou if covid == `i' & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontent %9.0gc (r(N)) (" (") %3.1f (`pct') (")") _tab
	}
	
	file write tablecontent _n
end



/* Explanatory Notes 

defines a program (SAS macro/R function equivalent), generate row
the syntax row specifies two inputs for the program: 

	a VARNAME which is your variable 
	a CONDITION which is a string of some condition you impose 
	
the program counts if variable and condition and returns the counts
column percentages are then automatically generated
this is then written to the text file 'tablecontent' 
the number followed by space, brackets, formatted pct, end bracket and then tab

the format %3.1f specifies length of 3, followed by 1 dp. 

*/ 

********************************************************************************
* Generic code to output one section (varible) within table (calls above)

cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) min(real) max(real) [missing]

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 

	forvalues varlevel = `min'/`max'{ 
		generaterow, variable(`variable') condition("==`varlevel'")
	}
	
	if "`missing'"!="" generaterow, variable(`variable') condition("== 12")
	


end

********************************************************************************

/* Explanatory Notes 

defines program tabulate variable 
syntax is : 

	- a VARNAME which you stick in variable 
	- a numeric minimum 
	- a numeric maximum 
	- optional missing option, default value is . 

forvalues lowest to highest of the variable, manually set for each var
run the generate row program for the level of the variable 
if there is a missing specified, then run the generate row for missing vals

*/ 

********************************************************************************
* Generic code to qui summarize a continous variable 

cap prog drop summarizevariable 
prog define summarizevariable
syntax, variable(varname) 

	local lab: variable label `variable'
	file write tablecontent ("`lab'") _n 


	qui summarize `variable', d
	file write tablecontent ("Mean (SD)") _tab 
	file write tablecontent  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	
	forvalues i=0/1{							
	qui summarize `variable' if covid == `i', d
	file write tablecontent  %3.1f (r(mean)) (" (") %3.1f (r(sd)) (")") _tab
	}

file write tablecontent _n

	
	qui summarize `variable', d
	file write tablecontent ("Median (IQR)") _tab 
	file write tablecontent %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	
	forvalues i=0/1{
	qui summarize `variable' if covid == `i', d
	file write tablecontent %3.1f (r(p50)) (" (") %3.1f (r(p25)) ("-") %3.1f (r(p75)) (")") _tab
	}
	
file write tablecontent _n
	
end

/* INVOKE PROGRAMS FOR TABLE 1================================================*/ 

*Set up output file
cap file close tablecontent
file open tablecontent using $Tabfigdir/table1_covid.txt, write text replace

file write tablecontent ("Table 1: Demographic and Clinical Characteristics of COVID population") _n

* covid labelled columns

local lab1: label covid 0
local lab2: label covid 1



file write tablecontent _tab ("Total")				  			  _tab ///
							 ("`lab1'")  						  _tab ///
							 ("`lab2'")  						  _tab ///
				 


* DEMOGRAPHICS (more than one level, potentially missing) 

gen byte Denominator=1
qui tabulatevariable, variable(Denominator) min(1) max(1) 
file write tablecontent _n 

qui summarizevariable, variable(age) 
file write tablecontent _n

qui tabulatevariable, variable(male) min(0) max(1) 
file write tablecontent _n 

qui tabulatevariable, variable(eth5) min(1) max(6) 
file write tablecontent _n 

qui tabulatevariable, variable(imd) min(1) max(5) 
file write tablecontent _n 

* OUTCOMES (binary)
foreach var of global outcomes2 { 
	di "`var'"
	local lab: variable label `var'
	file write tablecontent ("`lab'") _tab								
	generaterow2, variable(`var') condition("==1")
	file write tablecontent _n
}

** OTHER TREATMENT VARIABLES (binary)
* Close log file 
log close

clear
insheet using "$Tabfigdir/table1_covid.txt", clear
