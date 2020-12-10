********************************************************************************
*
*	Do-file:		model.do
*
*	Programmed by:	Rohini & Kevin
*
*	Data used:		output/input_covid.csv

*	Data created:	a number of analysis datasets
*
*	Other output:	-
*
********************************************************************************
*
*	Purpose:		This do-file performs the data creation and preparation 
*					do-files. 
*  
********************************************************************************

*start with cases of COVID-19
import delimited "`c(pwd)'/output/input.csv", clear

********** INSERT DATA END DATE ************
global dataEndDate td(01dec2020)

set more off
cd  "`c(pwd)'"
adopath + "`c(pwd)'/analysis/ado"

*set filepaths
global Projectdir `c(pwd)'
global Dodir "$Projectdir/analysis" 
di "$Dodir"
global Outdir "$Projectdir/output" 
di "$Outdir"
global Logdir "$Outdir/log"
di "$Logdir"
global Tempdir "$Outdir/tempdata" 
di "$Tempdir"
global Tabfigdir "$Outdir/tabfig" 
di "$Tabfigdir"

cd  "`c(pwd)'/analysis"

adopath + "$Dodir/adofiles"
sysdir
sysdir set PLUS "$Dodir/adofiles"

cd  "$Projectdir"

***********************HOUSE-KEEPING*******************************************
* Create directories required 

capture mkdir "$Outdir/log"
capture mkdir "$Outdir/tempdata"
capture mkdir "$Outdir/tabfig"

* Set globals that will print in programs and direct output
global outdir  	  "$Outdir" 
global logdir     "$Logdir"
global tempdir    "$Tempdir"

global allvar "gp_confirmed gp_positive sgss_positive c19_hospitalised pneumonia_hospitalised gp_t1dm gp_t2dm t1dm_hospitalised  gp_keto  keto_hospitalised death"
global exposures "gp_confirmed gp_positive sgss_positive c19_hospitalised pneumonia_hospitalised "
global outcomes "t1dm t2dm t1dm_keto"

/**********************
Data cleaning
**********************/

*Create analysis dataset
do "$Dodir/01_t1dm_cr_analysis_dataset.do"

*Perform matching
do "$Dodir/02_t1dm_perform_matching.do"
