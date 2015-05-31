library(plotrix)
source("../lib/ColorPlateGenerator.r")
source("../lib/style.r")

costs_chart <- function(control, treated) {

  control <- control[match(names(control), names(treated))]
  binded <- rbind(control, treated)
  binded$datum <- NULL
  binded$summe_aller_kosten <- NULL
  sorting <- order(sapply(binded, var))
  par(mai=c(0.2,0.2,0.2,0.2),omi=c(0.2,0.2,0.2,0.2),las=1, col="black")
  ymax <- max(treated$summe_aller_kosten, control$summe_aller_kosten)
  ymin <- min(treated$summe_aller_kosten, control$summe_aller_kosten, 0)
  
  cost_chart(treated, "Treatment Group", ylim=c(ymin, ymax), sorting=sorting)
  cost_chart(control, "Control Group", ylim=c(ymin, ymax), sorting=sorting)

}

cost_chart <- function(group, name, ylim, sorting) {
  par(mai=c(0.2,0.2,0.2,0.2),omi=c(0.2,0.2,0.2,0.2),las=1, col="black")

  colors <- rev(tetradicColors(baseColor, 8))

  years <- group$datum
  total <- group$summe_aller_kosten

  group$datum <- NULL
  group$summe_aller_kosten <- NULL

  group <- group[sorting]

  stackpoly(group, main="",xaxlab=rep("", nrow(group)),border="white", stack=TRUE, axis2=F, col=colors, ylim=ylim)

  legend("topright", name)
  legend("topleft", rev(names(group)), cex=0.95,border=F,bty="n",fill=rev(colors))
}
