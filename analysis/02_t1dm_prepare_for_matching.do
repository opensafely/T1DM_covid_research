
/*==============================================================================
DO FILE NAME:			02_t1dm_prepare_for_matching
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
log using $logdir/02_t1dm_prepare_for_matching.log, replace t

use "$Tempdir/analysis_dataset.dta", clear
