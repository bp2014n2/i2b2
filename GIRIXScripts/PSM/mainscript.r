require(Matrix)

source("lib/i2b2.r")

if(!exists('girix.input')) {
  source("PSM/girix_input.r")
}

pset.t <- girix.input['Treatment group']
pset.c <- girix.input['Control group']

pnums.t<- i2b2$crc$getPatients(patient_set=pset.t)
pnums.c<- i2b2$crc$getPatients(patient_set=pset.c)

output <- matrix(c(1,4,0.2,0.5,2,3,0.15,0.77), ncol=4, nrow=2)
colnames(output) <- c("Treatment group patient number", "Score", "Control group patient number", "Score")
girix.output[["Matched patients"]] <- output
girix.output[["Matching description"]] <- "Dummy matching"