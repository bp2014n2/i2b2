# All data of patient set one
girix.output[["Raw"]] <- girix.patients[[1]] # Data from patient_dimension
girix.output[["Mean Age"]] <- mean(girix.patients[[1]]$age_in_years_num)
girix.output.1 <- paste("System commands (pwd): ", system("pwd", intern=TRUE))


ageReligionMatrix <- setNames(aggregate(girix.patients[[1]]$age_in_years_num, by=list(girix.patients[[1]]$religion_cd), FUN=mean), c("Religion", "Age"))

# Grafik erstellen
par(mar=c(5,12,4,2))
x <- barplot(ageReligionMatrix$Age,main="Age Average per Religion",names.arg=F,horiz=T,border=NA,xlim=c(0,100),col="grey", cex.names=0.85,axes=F)

for (i in 1:length(ageReligionMatrix$Religion))
{
if (ageReligionMatrix$Religion[i] %in% c("atheist")) 
    {schrift<-"Droid Sans"} else {schrift<-"Droid Sans"}
text(-15,x[i],ageReligionMatrix$Religion[i],xpd=T,adj=1,cex=1.15,family=schrift)
text(-3.5,x[i],round(ageReligionMatrix$Age[i], digits=2),xpd=T,adj=1,cex=0.85,family=schrift)
}
 
# weitere Elemente
 
rect(0,-0.5,20,28,col=rgb(191,239,255,80,maxColorValue=255),border=NA)
rect(20,-0.5,40,28,col=rgb(191,239,255,120,maxColorValue=255),border=NA)
rect(40,-0.5,60,28,col=rgb(191,239,255,80,maxColorValue=255),border=NA)
rect(60,-0.5,80,28,col=rgb(191,239,255,120,maxColorValue=255),border=NA)
rect(80,-0.5,100,28,col=rgb(191,239,255,80,maxColorValue=255),border=NA)
 
wert2<-c(0,0,0,0,head(tail(ageReligionMatrix$Age, n=2),1),0,0,0,0,0,0,0,0,84,0,0)
farbe2<-rgb(255,0,210,maxColorValue=255)
x2<-barplot(wert2,names.arg=F,horiz=T,border=NA,xlim=c(0,100),
    col=farbe2,cex.names=0.85,axes=F,add=T)
avg<-mean(girix.patients[[1]]$age_in_years_num) 
arrows(avg,-0.5,avg,20.5,lwd=1.5,length=0,xpd=T,col="skyblue3") 
arrows(avg,-0.5,avg,-0.75,lwd=3,length=0,xpd=T)
arrows(avg,20.5,avg,20.75,lwd=3,length=0,xpd=T)
mtext(c(0,20,40,60,80,100),at=c(0,20,40,60,80,100),1,line=0,cex=0.80)
 
girix.output[["Age Contribution"]] <- ageReligionMatrix
