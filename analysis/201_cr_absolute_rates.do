********************************************************************************
*
*	Do-file:		201_cr_absolute_rates.do
*
*	Programmed by:	John & Alex
*
*	Data used:		None
*
*	Data created:   None
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		
*
*	Note:			
********************************************************************************

use "data/cr_matched_cohort_primary", replace 

tempname measures
	postfile `measures' str12(outcome) str12(analysis) str20(variable) category personTime numEvents rate lc uc using "data/rates_summary", replace

*foreach v in stroke dvt pe  {
foreach v in stroke   {

* Clean outcomes / dates

*******************
* Primary Outcome *
*******************

gen `v'_primary_outcome = cond( (`v'_gp_date > indexdate  & `v'_gp_date !=.) | 		/// 
								  (`v'_hospital_date > indexdate & `v'_hospital_date !=. ) | ///
								  (`v'_ons == 2020 & died_date_ons_date > indexdate & died_date_ons_date!=. ) & ///
								  died_date_ons_date!= indexdate, 1, 0)
								  
* Update to other end of follow up dates								  
gen `v'_primary_end_date = min(`v'_gp_date, `v'_hospital_date, died_date_ons_date, td(01oct2020))
format %td `v'_primary_end_date

*********************
* Secondary Outcome *
*********************
								 								   
gen `v'_secondary_outcome = cond( (`v'_hospital_date > indexdate & `v'_hospital_date !=. ) |  ///
								  (`v'_ons == 2020 & died_date_ons_date > indexdate & died_date_ons_date!=. ) & ///
								  died_date_ons_date!= indexdate, 1, 0)

gen `v'_secondary_end_date = min(`v'_gp_date, `v'_hospital_date, died_date_ons_date, td(01oct2020))								  
format %td `v'_secondary_end_date
								 

foreach a in primary secondary {

stset `v'_`a'_end_date , id(patient_id) failure(`v'_`a'_outcome) enter(indexdate)
 
foreach c in imd ethnicity smoke {
qui levelsof `c' , local(cats) 
di `cats'
foreach l of local cats {

/*
stptime
noi di "Person Time: `r(ptime)'"
noi di "No. Events : `r(failures)'"
noi di "Rate (95% CI): `r(rate)' (95%CI: `r(lb)' to `r(ub)')" 
*/

stptime if `c'==`l'

			* Save measures
			post `measures' ("`v'") ("`a'") ("`c'") (`l') (`r(ptime)') ///
							(`r(failures)') (`r(rate)') 							///
							(`r(lb)') (`r(ub))') 	

							
}




}
}

}

postclose `measures'

use "data/rates_summary", replace
