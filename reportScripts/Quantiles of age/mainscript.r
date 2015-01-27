report.output["Lower quantile"] <- quantile(report.patients[[1]]$age_in_years_num, as.numeric(report.input[["p for lower quantile"]]))
report.output["Upper quantile"] <- quantile(report.patients[[1]]$age_in_years_num, as.numeric(report.input[["p for upper quantile"]]))
boxplot(report.patients[[1]]$age_in_years_num, horizontal=T)