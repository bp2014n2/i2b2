library(knitr); 
setwd("/home/ubuntu/i2b2/reportScripts/ReportGenerator")

# Unique information
randomNumber <- floor(runif(1, 10000000, 99999999))
currentTimestamp <- print(as.numeric(Sys.time()))
tmpFolder <- paste('tmp/', randomNumber, currentTimestamp, "/", sep='')

dir.create(tmpFolder, mode="0777")
dir.create(paste(tmpFolder, '/plots',  sep=''), mode="0777")

input <- report.input

# Generate File
fileName <- 'main.html'
knit('layout/main.Rhtml', output=paste(tmpFolder, fileName, sep=""))

# Output
report.output[["Report"]] <- readChar(paste(tmpFolder, fileName, sep=""), file.info(paste(tmpFolder, fileName, sep=""))$size)
