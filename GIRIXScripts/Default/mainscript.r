girix.output.1 = "foo"
girix.output.2 = data.frame(a=c(1, 2))

mat <- matrix(1:5, ncol=5)
colnames(mat) <- c("1","2","3","4","5")

girix.output[["testmatrix"]] <- mat
girix.output[["foo"]] <- "rololosd"