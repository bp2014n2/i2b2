library(plotrix)
source("../lib/ColorPlateGenerator.r")
source("../lib/style.r")

costs_chart <- function(control, treated) {

  par(mai=c(0.2,0.2,0.2,0.2),omi=c(0.2,0.2,0.2,0.2),las=1, col="black")
  cost_chart(control, "Control Group")
  cost_chart(treated, "Treaded Group")

}

cost_chart <- function(group, name) {
  par(mai=c(0.2,0.2,0.2,0.2),omi=c(0.2,0.2,0.2,0.2),las=1, col="black")

  colors <- rev(tetradicColors(baseColor, 8))

  years <- group$datum
  total <- group$summe_aller_kosten

  order(sapply(group, var))

  group$datum <- NULL
  group$summe_aller_kosten <- NULL

  group <- group[order(sapply(group, var))]

  stackpoly(group, main="",xaxlab=rep("", nrow(group)),border="white", stack=TRUE, axis2=F, col=colors)

  legend("topright", name)
  legend("topleft", rev(names(group)), cex=0.95,border=F,bty="n",fill=colors)
}
