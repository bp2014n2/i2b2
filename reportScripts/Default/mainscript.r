# Visualisierung Altersverteilungen
Age <- report.patients[[1]]$age_in_years_num

# Histogram
hist(Age)

# Boxplot
boxplot(Age)

# Barplot
barplot(sort(Age))

# Plot
plot(sort(Age), xlab="Patient", ylab="Age", pch=20, col="black")
plot(sort(Age), xlab="Patient", ylab="Age", pch=20, col="black", type="h")

report.output.1 <- table(sort(Age))

# Strip Chart
stripchart(sort(Age), method="stack")

# Scatter Plot
pairs(report.patients[[1]][,7:11])

# ??
qqnorm(Age)
qqline(Age)

# Multiple at once
par(mfrow=c(2,2))
hist(Age, freq=F)
boxplot(Age)
barplot(Age)
qqnorm(Age)

# Reset multiple
par(mfrow=c(1,1))

library("lattice")
xyplot(Age~report.patients[[1]]$religion_cd) #Not working?
