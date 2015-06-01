library(plotrix)
source("../lib/ColorPlateGenerator.r")
source("../lib/style.r")

costs_chart <- function(control, treated,treatmentProvided=F) {

  control <- control[match(names(control), names(treated))]
  binded <- rbind(control, treated)
  binded$datum <- NULL
  binded$summe_aller_kosten <- NULL
  sorting <- order(sapply(binded, var))
  #par(mai=c(1.2,1.2,1.2,1.2),omi=c(0.2,0.2,0.2,0.2),las=1, col="black")
  ymax <- max(treated$summe_aller_kosten, control$summe_aller_kosten)
  ymin <- min(treated$summe_aller_kosten, control$summe_aller_kosten, 0)
  
  cost_chart(treated, "Treatment Group", ylim=c(ymin, ymax), sorting=sorting,treatmentProvided=treatmentProvided)
  cost_chart(control, "Control Group", ylim=c(ymin, ymax), sorting=sorting,treatmentProvided=treatmentProvided)

}

cost_chart <- function(group, name, ylim, sorting, treatmentProvided) {
  op <- par(col="black")

  colors <- rev(tetradicColors(baseColor, 8))
  p.col <<- colors
  if (treatmentProvided) {
    years <- group$datum
  } else {
    years <- format(group$datum, "%Y")
  }
  total <- group$summe_aller_kosten
  p.years <<- years
  p.ylim <<- ylim

  group$datum <- NULL
  group$summe_aller_kosten <- NULL

  group <- group[sorting]
  p.group <<- group

  stackpoly(group, main="",xaxlab=years,border="white", stack=TRUE, axis2=F, col=colors, ylim=ylim)

  legend("topright", name)
  legend("topleft", rev(names(group)), cex=0.95,border=F,bty="n",fill=rev(colors))
  par(op)
}
