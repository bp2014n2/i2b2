# Install packages if necessary
list.of.packages <- c("knitr", "extrafont")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# Load necessary libraries
library(knitr); 
library(extrafont)
source("lib/i2b2.r")

generateOutput <- function() {
  #Working Directory is top folder of all scriptlets, so get current scriptlet directory
  scriptlet.fulldir <- dirname(sys.frame(1)$ofile)
  scriptlet.dir <- sub(".*/(.*)/ReportGen/.*", "\\1", scriptlet.fulldir,perl=TRUE)

  #Don't print warnings
  options(warn=-1)

  # Generate unique information for temporary files
  randomNumber <- floor(runif(1, 10000000, 99999999))
  currentTimestamp <- print(as.numeric(Sys.time()))
  tmpFolder <- paste(scriptlet.dir, '/ReportGen/tmp/', randomNumber, currentTimestamp, "/", sep='')

  # Create temporary folder
  dir.create(tmpFolder, mode="0777", recursive=T)
  dir.create(paste(tmpFolder, '/plots',  sep=''), mode="0777")

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
  if(girix.input["requestDiagram"] == "all"){
    knit(paste0(scriptlet.dir, '/layout/main.Rhtml'), output=paste(tmpFolder, fileName, sep=""))
  } else {
    knit(paste0(scriptlet.dir, '/diagrams/', girix.input["requestDiagram"], '/layout.Rhtml'), output=paste(tmpFolder, fileName, sep=""))
  }

  output <- readChar(paste(tmpFolder, fileName, sep=""), file.info(paste(tmpFolder, fileName, sep=""))$size) 

  #Cleanup
  unlink(tmpFolder, recursive=T)

  return(output)
}
