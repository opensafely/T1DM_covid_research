import delimited `c(pwd)'/output/input.csv, clear

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


*will add death to the global when we do survival analysis for censoring purposes

global outcomes "confirmed tested positivetest c19_hospitalised t1dm_primarycare t1dm_hospitalised t2dm_primarycare keto_primarycare  keto_hospitalised death"
global  outcomes2 "t1dm keto t1dm_keto baseline_t1dm incident_t1dm monthbefore_t1dm baseline_keto incident_keto monthbefore_t1dm_keto  baseline_t1dm_keto incident_t1dm_keto monthbefore_keto"
/**********************
Data cleaning
**********************/

*Create analysis dataset
do "$Dodir/01_t1dm_cr_analysis_dataset.do"

*Feasibility counts
do "$Dodir/02_t1dm_an_feasibility_counts.do"

*Table 1 descriptives
do "$Dodir/03_t1dm_table1_descriptives.do"
