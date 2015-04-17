accentColor <- c()

baseColor <- rgb(255, 130, 0, maxColorValue=255)
accentColor[1] <- rgb(0, 115, 152, maxColorValue=255)
accentColor[2] <- rgb(51, 142, 172, maxColorValue=255)
lightGray <- rgb(248, 248, 248, maxColorValue=255)
gray <- rgb(171, 171, 171, maxColorValue=255)
darkGray <- rgb(83, 86, 90, maxColorValue=255)

par(fg=darkGray, col=baseColor, col.axis=darkGray, col.lab=darkGray, col.main=darkGray)

## Add an alpha value to a colour
set.alpha <- function(col, alpha=1){
  apply(
    sapply(col, col2rgb)/255, 
    2, 
    function(x){ rgb(x[1], x[2], x[3], alpha=alpha) }
   )  
}
