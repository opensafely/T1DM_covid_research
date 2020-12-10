
/*==============================================================================
DO FILE NAME:			02_t1dm_cr_matched_cohort
PROJECT:				T1DM and COVID outcomes
DATE: 					7th September 2020 
AUTHOR:					Rohini Mathur 									
DESCRIPTION OF FILE:	program 02 format data for matching using Krishnan's ado fule
DATASETS USED:			data in memory (from analysis/input.csv)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir

Format needs to be
patid	indexdate	gender	startdate	enddate	exposed	yob

				
==============================================================================*/

* Open a log file
cap log close
log using $logdir/02_t1dm_cr_matched_cohort.log, replace t


set seed 4006

 getmatchedcohort, practice gender yob yobwindow(2) followup dayspriorreg(0) ctrlsperexp(2) updates(100) cprddb(gold) ///
 savedir("$Tempdir") filesuffix(t1dm) 
 
 use "$Tempdir/getmatchedcohortt1dm", clear
