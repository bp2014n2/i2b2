# ---- code ----
source("../../lib/style.r")

# newpie is a pi chart with labels inside
newpie <- pie
newlbs <- quote(if (!is.na(lab) && nzchar(lab)) {
  text(0.5 * P$x, 0.5 * P$y, labels[i], xpd = TRUE, adj = ifelse(P$x < 0, 1, 0), ...)
})
body(newpie)[[22]][[4]][[7]] <- newlbs

sex_pi <- function(patients){
  data <- table(patients$sex_cd)

  par(
    omi=c(0.5,0,0,7), # Outer border (bottom, top, left, right)
    mai=c(0.3,0,0,0), # Inner border
    mgp=c(3,3,0),     # Space axle text 
    las=1,            # Style of axle labels (horizontal) 
    col="white",      # Default color
    family="Lato"     # Default font
  )  

  # Plot
  newpie(
    data, 
    labels=c("Female", "Male"), 
    col=c(set.alpha(baseColor,0.7),set.alpha(accentColor[1], 0.7)), 
    border="white"
  )

  # Footer
  mtext("Elsevier Health Analytics",1,line=1,adj=1.0,cex=0.65,outer=T,font=3, col=darkGray)
}
patients <- i2b2$crc$getPatients(model.patient_set)
if(nrow(patients) == 0) {
  stop("Patient set empty!")
} else {
  sex_pi(patients)
}
