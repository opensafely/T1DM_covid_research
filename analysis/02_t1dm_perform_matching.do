
/*==============================================================================
DO FILE NAME:			02_t1dm_cr_matched_cohort
PROJECT:				T1DM and COVID outcomes
DATE: 					7th September 2020 
AUTHOR:					Rohini Mathur 									
DESCRIPTION OF FILE:	program 02 format data for matching using Krishnan's ado file
DATASETS USED:			data in memory (from analysis/input.csv)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir

Format needs to be
patid	indexdate	gender	startdate	enddate	exposed	yob

				
==============================================================================*/
sysdir set PLUS ./analysis/adofiles
sysdir set PERSONAL ./analysis/adofiles

* Open a log file
cap log close
log using ./released_analysis_results/02_t1dm_cr_matched_cohort.log, replace t

use ./output/analysis_dataset_formatching.dta, clear
set seed 4006

 getmatchedcohort, practice gender yob yobwindow(2) followup dayspriorreg(0) ctrlsperexp(2) updates(100) cprddb(gold) ///
 savedir(./output) filesuffix(t1dm) 
 
 use "./output/getmatchedcohortt1dm", clear
