# All data of patient set one
report.output[["Raw"]] <- report.patients[[1]] # Data from patient_dimension
report.output[["Mean Age"]] <- mean(report.patients[[1]]$age_in_years_num)
