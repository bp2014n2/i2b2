# Abbrevations
binsNumber <- as.numeric(GIRI.input["Number of bins"])
groupname1 <- GIRI.input["Name of patient set 1"]
groupname2 <- GIRI.input["Name of patient set 2"]
mainname <- GIRI.input["Plot label"]
vals1 <- GIRI.observations[[1]]$nvalnum_value[!is.na(GIRI.observations[[1]]$nvalnum_value)]
vals2 <- GIRI.observations[[2]]$nvalnum_value[!is.na(GIRI.observations[[2]]$nvalnum_value)]
allVals <- c(vals1,vals2)

if (length(vals1) == 0 || length(vals2) == 0) {
	write("No laboratory values of the specified type available for a given patient set!", stderr())
}

# Defining equidistant break points
breaks <- seq(min(allVals),max(allVals),((max(allVals) - min(allVals))/binsNumber))

# Compute relative frequency of bins
bins1 <- table(cut(vals1,breaks,include.lowest=T))/length(cut(vals1,breaks,include.lowest=T))
bins2 <- table(cut(vals2,breaks,include.lowest=T))/length(cut(vals2,breaks,include.lowest=T))

# Create plotable matrix
plotMat <- matrix(c(bins1,bins2),2,dimnames=list(c(groupname1, groupname2),dimnames(bins1)[[1]]), byrow=T)

# Plot it
barplot(plotMat, beside=T, legend.text=T, col=c("cornflowerblue","darkcyan"), main=mainname, xlab="Bins", ylab="Relative frequencies", cex.names=(5/binsNumber))