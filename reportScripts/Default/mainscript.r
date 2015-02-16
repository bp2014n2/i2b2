# Visualisierung Altersverteilungen
Age <- report.patients[[1]]$age_in_years_num
hist(Age)
boxplot(Age)
barplot(Age)
pairs(report.patients[[1]][,7:11]) #Scatter Plot
qqnorm(Age)
qqline(Age)

