#!/Library/Frameworks/R.framework/Resources/Rscript

# ---- mainImports ----
options(warn=-1)

library(jsonlite)
library(extrafont)

source("lib/i2b2.r")
source("lib/utils.r")

source("ReportGenerator/utils/utils.r")
# source("utils/load_data.r")


main <- function(){
  # patients <- executeCRCQuery("SELECT birth_date FROM i2b2demodata.patient_dimension LIMIT 10")
  # patients$age_in_years_num = age(as.Date(patients$birth_date), Sys.Date())
  params <<- fromJSON(input[["params"]])
}

main()
