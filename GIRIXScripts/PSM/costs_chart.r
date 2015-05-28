library(plotrix)
source("../lib/ColorPlateGenerator.r")
source("../lib/style.r")

costs_chart <- function(control, treated) {

  par(mai=c(0.2,0.2,0.2,0.2),omi=c(0.2,0.2,0.2,0.2),las=1, col="black")
  ymax <- max(treated$summe_aller_kosten, control$summe_aller_kosten)
  
  cost_chart(treated, "Treatment Group", ymax)
  cost_chart(control, "Control Group", ymax)

}

cost_chart <- function(group, name, ymax) {
  par(mai=c(0.2,0.2,0.2,0.2),omi=c(0.2,0.2,0.2,0.2),las=1, col="black")

  colors <- rev(tetradicColors(baseColor, 8))

  years <- group$datum
  total <- group$summe_aller_kosten

  order(sapply(group, var))

  group$datum <- NULL
  group$summe_aller_kosten <- NULL

  group <- group[order(sapply(group, var))]

  stackpoly(group, main="",xaxlab=rep("", nrow(group)),border="white", stack=TRUE, axis2=F, col=colors, ylim=c(0,ymax))

  legend("topright", name)
  legend("topleft", rev(names(group)), cex=0.95,border=F,bty="n",fill=colors)
}
