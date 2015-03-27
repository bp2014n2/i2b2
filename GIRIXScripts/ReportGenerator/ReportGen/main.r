# Install packages if necessary
list.of.packages <- c("knitr", "extrafont")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(knitr); 
library(extrafont)

source("lib/i2b2.r")

scriptlet.fulldir <- dirname(sys.frame(1)$ofile)
scriptlet.dir <- sub(".*/(.*)/ReportGen/.*", "\\1", scriptlet.fulldir,perl=TRUE)

options(warn=-1)

# Unique information
randomNumber <- floor(runif(1, 10000000, 99999999))
currentTimestamp <- print(as.numeric(Sys.time()))
tmpFolder <- paste(scriptlet.dir, '/tmp/', randomNumber, currentTimestamp, "/", sep='')

dir.create(tmpFolder, mode="0777")
dir.create(paste(tmpFolder, '/plots',  sep=''), mode="0777")

input <- girix.input

#Setup Knitr

# Deactivates code output globally
knitr::opts_chunk$set(echo=FALSE, fig.path=paste0(tmpFolder, 'plots/'), cache=FALSE, dev='svg', results='hide')
opts_knit$set(progress = FALSE, verbose = FALSE)
opts_chunk$set(fig.width=5, fig.height=5)

# Embed SVGs in HTML
hook_plot = knit_hooks$get('plot')
knit_hooks$set(plot = function(x, options) {
 x = paste(x, collapse = '.')
 if (!grepl('\\.svg', x)) return(hook_plot(x, options))
 # read the content of the svg image and write it out without <?xml ... ?>
 paste("<img src='data:image/svg+xml;utf8,", paste(readLines(x)[-1], collapse = '\n'), "'>", sep="")
})

# Generate File
fileName <- 'main.html'
if(input["requestDiagram"] == "all"){
  knit(paste0(scriptlet.dir, '/layout/main.Rhtml'), output=paste(tmpFolder, fileName, sep=""))
} else if(input["requestDiagram"] == "age_histogram") {
  knit(paste0(scriptlet.dir, '/diagrams/age_histogram/layout.Rhtml'), output=paste(tmpFolder, fileName, sep=""))
} else if(input["requestDiagram"] == "frequence_of_visits_chart") {
  knit(paste0(scriptlet.dir, '/diagrams/frequence_of_visits_chart/layout.Rhtml'), output=paste(tmpFolder, fileName, sep=""))
}

# Output
girix.output[["Report"]] <- readChar(paste(tmpFolder, fileName, sep=""), file.info(paste(tmpFolder, fileName, sep=""))$size)

unlink(tmpFolder, recursive=T)
