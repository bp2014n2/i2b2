# Writing different types of R data into standard output variables

# Standard data types
GIRI.output.1 <- TRUE
GIRI.output.2 <- as.integer(5)
GIRI.output.3 <- 4.5
GIRI.output.4 <- "testing string"
# Vectors
GIRI.output.5 <- c(TRUE, FALSE, TRUE)
GIRI.output.6 <- c(1:3)
GIRI.output.7 <- c(1.5:3.5)
GIRI.output.8 <- c("tick", "trick", "track")
# Arrays
GIRI.output.9 <- array(TRUE, dim=c(4,5))
GIRI.output.10 <- array(1:20, dim=c(4,5))
GIRI.output.11 <- array(1.5:20.5, dim=c(4,5))
GIRI.output.12 <- array("test", dim=c(4,5))
# A list
GIRI.output.13 <- list("John", "male", 25, 1.78, TRUE)
# A data frame
a <- c(10,20,15,43,76,41,25,46)
b <- factor(c("m", "f", "m", "f", "m", "f", "m", "f"))
c <- c(2.1,5.2,8.3,3.6,6.0,1.6,5.1,6.8)
GIRI.output.14 <- data.frame(a,b,teststring=c)

# Plot something
boxplot(rnorm(10))

# Write something to standard output stream (only displayed if <passROutput>true</passROutput> in config)
write("Hello there", stdout())

# Write something to standard error stream (only displayed if <passRErrors>true</passRErrors> in config)
write("I am an error!", stderr())
