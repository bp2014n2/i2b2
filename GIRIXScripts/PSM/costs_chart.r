library(plotrix)

costs_chart <- function(control, treated) {

  par(pin=c(5,3), mai=c(0.5,1.1,0,0.5),omi=c(0.5,0.5,0.8,0.5),las=1, mfrow=c(1,2))
  cost_chart(control)
  cost_chart(treated)

}

cost_chart <- function(group) {

  colors <- c("brown", "black", "grey", "forestgreen", "blue", "lightgoldenrod")

  years <- group$datum
  total <- group$summe_aller_kosten

  group$datum <- NULL
  group$summe_aller_kosten <- NULL

  stackpoly(group, main="",xaxlab=rep("", nrow(control)),boder="white", stack=TRUE, axis2=F, col=colors)

  lines(total, lwd=4, col="lightgoldenrod4")
  name <- names(control)

}
