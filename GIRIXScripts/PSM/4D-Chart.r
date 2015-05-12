
vierdchart <- function(control, treated) {

  UNPop <- data.frame(Provider= character(0), Group= character(0), Datum = double(0), Value = numeric(0))
  selection<-c("summe_aller_kosten", "arztkosten", "zahnarztkosten", "apothekenkosten", "krankenhauskosten","hilfsmittel","heilmittel","dialysesachkosten","krankengeld")

  j <- 0
  i <- 0
  for (j in 1:length(selection)) {
    for (i in 1:nrow(control)) {
      UNPop <- rbind2(UNPop,data.frame(Provider=selection[j],Group="control",Datum=control$datum[i],Value=control[selection[j]][i,]))
      UNPop <- rbind2(UNPop,data.frame(Provider=selection[j],Group="treated",Datum=treated$datum[i],Value=treated[selection[j]][i,]))
      UNPop <- rbind2(UNPop,data.frame(Provider=selection[j],Group="cmedium",Datum=control$datum[i],Value=((control[selection[j]][i,]+treated[selection[j]][i,])/2)))
    }
  }

  # Setting Layout
  par(mfcol=c(1,5),omi=c(1.0,0.25,1.45,0.25),mai=c(0,0.75,0.25,0),
        family="Lato Light",las=1)

#  UNPop<-read.csv("daten/UNPop.csv")

  tite<-c("summe_aller_kosten", "arztkosten", "zahnarztkosten", "apothekenkosten", "krankenhauskosten","hilfsmittel","heilmittel","dialysesachkosten","krankengeld")

  for (i in 1:length(selection)) {
    Land<-subset(UNPop,UNPop$Provider==selection[i] & UNPop$Group=="cmedium")

    Prognosen<-subset(UNPop,UNPop$Provider == selection[i])
    Prognose_L<-subset(Prognosen,Prognosen$Group=="treated")$Value
    Prognose_M<-subset(Prognosen,Prognosen$Group=="cmedium")$Value
    Prognose_H<-subset(Prognosen,Prognosen$Group=="control")$Value
    Jahre<-Prognosen$Datum

    plot(axes=F,type="n",xlab="",ylab="",Land$Datum,Land$Value)
#     py<-c(0,100,200,300,400,500)
#     abline(h=py[2:6], col="lightgray",lty="dotted")
#     axis(1,tck=-0.01,col="grey",at=c(1950,2010,2100),cex.axis=1.2) 
#     py<-c(0,100,200,300,400,500)
#     if (selection[i]=="World")
#     {
#       axis(2,tck=-0.01,col="grey",at=py,labels=format(py,big.mark="."),
#              cex.axis=1.2) 
#     }
#     xx<-c(Jahre,rev(Jahre))
#     yy<-c(100*Prognose_H,rev(100*Prognose_L))

#     polygon(xx,yy,col=rgb(192,192,192,maxColorValue=255),border=F)

    lines(Land$Datum,(Land$Value),col="grey",lwd=2)
    lines(Land$Datum,Prognose_H,col="black",lwd=2)
    lines(Land$Datum,Prognose_L,col="orange",lwd=2)
    lines(Land$Datum,Prognose_M,col="white",lwd=2)

    mtext(titel[i],side=3,adj=0,line=1,cex=1.1,font=3)

    if (i==1)
    {
      legend(1900,-70,c("obere Prognose","mittlere Prognose","untere Prognose"),
              fill=c("grey","grey","grey"),border=F,pch=15,xpd=NA,
                col=c("black","white","orange"),bty="n",cex=1.6,ncol=3)
    }
  }

  # Betitelung

}

