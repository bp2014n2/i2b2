require(Matrix)

output <- matrix(c(1,4,0.2,0.5,2,3,0.15,0.77), ncol=4, nrow=2)
colnames(output) <- c("Treatment group patient number", "Score", "Control group patient number", "Score")
girix.output[["Matched patients"]] <- output
girix.output[["Matching description"]] <- "Dummy matching"