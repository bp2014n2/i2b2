#!/Library/Frameworks/R.framework/Resources/Rscript

# ---- mainImports ----
options(warn=-1)

library(extrafont)
loadfonts()

source("utils/utils.r")
source("utils/load_data.r")

main <- function(){
  loaded_data <<- load_data()
}

main()
