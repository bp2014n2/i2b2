#!/usr/bin/Rscript

setwd("../")
source("lib/i2b2.r")
source("lib/utils.r")

patients <- executeCRCQuery("SELECT birth_date FROM i2b2demodata.patient_dimension LIMIT 10")
patients$age_in_years_num = age(as.Date(patients$birth_date), Sys.Date())

print(patients)



