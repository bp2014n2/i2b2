start <- proc.time()
library(knitr); 

# Unique information
randomNumber <- floor(runif(1, 10000000, 99999999))
currentTimestamp <- print(as.numeric(Sys.time()))
tmpFolder <- paste('ReportGenerator/tmp/', randomNumber, currentTimestamp, "/", sep='')

dir.create(tmpFolder, mode="0777")
dir.create(paste(tmpFolder, '/plots',  sep=''), mode="0777")

input <- girix.input

#Setup Knitr

# Deactivates code output globally
library(knitr)
knitr::opts_chunk$set(echo=FALSE, fig.path=paste0(tmpFolder, 'plots/'), cache=FALSE, dev='svg', results='hide')
opts_knit$set(progress = FALSE, verbose = FALSE)
opts_chunk$set(fig.width=5, fig.height=5)

source('ReportGenerator/main.r')

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
  knit('ReportGenerator/layout/main.Rhtml', output=paste(tmpFolder, fileName, sep=""))
} else {
  knit('ReportGenerator/diagrams/age-histogram/layout.Rhtml', output=paste(tmpFolder, fileName, sep=""))
}

# Output
girix.output[["Report"]] <- readChar(paste(tmpFolder, fileName, sep=""), file.info(paste(tmpFolder, fileName, sep=""))$size)
if(input["requestDiagram"] == "all"){
  girix.output.1 <- paste(round((proc.time() - start)[3], digit=3), "sec")
}
