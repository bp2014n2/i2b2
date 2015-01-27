# This is the most simple scriptlet It doesn't have a config.xml file and hence no description etc.
# Note that a) for passing output options default values (both are passed) are taken and b) as there is no name 
# in the config.xml, the folder name is supposed to be the scriptlet's name

# Such a simple scriptlet can be useful for playing around, testing, teaching...without any preparations

report.output.1 <- "Hello world!"

# Compute the average age of the first given patient set
report.output.2 <- mean(report.patients[[1]]$age_in_years_num)