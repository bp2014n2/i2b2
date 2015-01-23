GIRI.output["Lower quantile"] <- quantile(GIRI.patients[[1]]$age_in_years_num, as.numeric(GIRI.input[["p for lower quantile"]]))
GIRI.output["Upper quantile"] <- quantile(GIRI.patients[[1]]$age_in_years_num, as.numeric(GIRI.input[["p for upper quantile"]]))
boxplot(GIRI.patients[[1]]$age_in_years_num, horizontal=T)