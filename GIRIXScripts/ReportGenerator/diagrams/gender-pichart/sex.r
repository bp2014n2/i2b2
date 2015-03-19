sex_pi <- function(patients){
  data <- table(loaded_data$sex_cd)

  par(omi=c(0.65,0.25,0.75,0.75),mai=c(0.3,1.5,0.35,0),mgp=c(3,3,0),
        family="Lato Light", las=1)  

  # Diagram
  pie(data, labels=c("Weiblich", "Männlich"), col=c(rgb(235/255, 54/255, 180/255), rgb(54/255, 171/255, 235/255)), border="white")

  # Titles
  mtext("Sex Distribution",3,line=1.3,adj=0,cex=1.2,family="Lato Black",outer=T)
  mtext("Pi Chart",3,line=0,adj=0,cex=0.9,outer=T)
  mtext("Elsevier Health Analytics",1,line=1,adj=1.0,cex=0.65,outer=T,font=3)

}
