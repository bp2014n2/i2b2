# hsv2rgb algorithm from http://en.wikipedia.org/wiki/HSL_and_HSV#From_HSV
hsv2rgb <- function(h,s,v) { 
  h <- h/60
  chroma <- v*s
  X <- chroma * (1 - abs((h %% 2) - 1))
  i <- floor(h)

  rgbVector <- switch(as.character(i),  
    "0"=c(chroma,X,0),
    "1"=c(X,chroma,0),
    "2"=c(0,chroma,X),
    "3"=c(0,X,chroma),
    "4"=c(X,0,chroma),
    "5"=c(chroma,0,X)
  )
  m <- v - chroma
  rgbVector <- rgbVector + m

  return(rgb(rgbVector[1],rgbVector[2],rgbVector[3]))
}

complement <- function(hex, typeVal="") {
  count <- 1
  rotation <- 180
  scope <- 0

 if(typeVal == "split") {
   count <- 3
   rotation <- 180
   scope <- 180
 } else if(typeVal == "double") {
   count <- 5
   rotation <- 180
   scope <- 180
 }
 
 return(rotational_dispersion(hex,count,"hue",scope,rotation))
}

triadic <- function(hex) {
  return(rotational_dispersion(hex,3,"hue",360,0))
}

tetradic<- function(hex) {
  return(rotational_dispersion(hex,4,"hue",360,0))
}

pentadic <- function(hex) {
  return(rotational_dispersion(hex,5,"hue",360,0))
}

degrees <- function(degrees, offset) {
  degrees <- degrees + 360 + offset
  return(degrees %% 360)
}

# pick a point on the wheel, the number of degrees either side to cover and the split
rotational_dispersion <- function(hex,count,typeVal,scope,rotation) {
  hexcol <- col2rgb(hex)
  hsv <- rgb2hsv(
           r=hexcol["red",],
           g=hexcol["green",],
           b=hexcol["blue",]
         )
  h <- hsv["h",]*360
  s <- hsv["s",]*100
  v <- hsv["v",]*100
  palette <- c()
  offset <- 0
  i <- 0

  # if scope is 360, the start and end point are the same color, so should be avoided
  steps <- scope / (count - 1)
  if(typeVal=="hue" && (scope == 360 || scope == 0)){
    steps <- scope / count
  }

  # if scope is 360, start on the current color
  origin <- 0
  if(scope != 360) {
    origin <- degrees(degrees(h, rotation), -1 * scope / 2)
  }

  for(i in 0:(count-1)) {
    offset <- steps * i
    if(typeVal=="hue") {
      palette <- c(palette, c(hsv2rgb(degrees(origin,offset)%%360,s/100,v/100)))
    } else if(typeVal=="saturation") {
      palette <- c(palette, c(hsv2rgb(h,offset/100,v/100)))
    } else if(typeVal=="value" || typeVal == "lightness" || typeVal == "brightness") {
      palette <- c(palette, hsv2rgb(h,s/100,offset/100))
    }
  }
  return(palette)
}

generateMonochromaticColors <- function(baseColor, count) {
  base <- baseColor
  colors <- c(baseColor) 
  rgbColor <- col2rgb(baseColor)
  top <- 255 - max(rgbColor["red",], rgbColor["green",], rgbColor["blue",])
  bottom <- min(rgbColor["red",], rgbColor["green",], rgbColor["blue",])

  addGrayValue <- (top + bottom) / count
  way <- 1

  while(T){
    rgbColor <- col2rgb(baseColor)

    highest <- max(rgbColor["red",], rgbColor["green",], rgbColor["blue",])+addGrayValue*way
    if(highest > 255) {
      way <- -1
      baseColor <- base
    }

    lowest <- min(rgbColor["red",], rgbColor["green",], rgbColor["blue",])+addGrayValue*way
    if(lowest < 0) {
      break
    }

    baseColor <- rgb(
      (rgbColor["red",]+addGrayValue*way)/255, 
      (rgbColor["green",]+addGrayValue*way)/255, 
      (rgbColor["blue",]+addGrayValue*way)/255
    )

    if(col2rgb(baseColor)["red",] > rgbColor["red",]) {
       colors <- c(colors, c(baseColor))
    } else {
        colors <- c(c(baseColor), colors)
    }
  }

  return(tail(colors, n=count))
}

complementColors <- function(baseColor, count) {
  return(c(generateMonochromaticColors(baseColor, ceiling(count/2)), generateMonochromaticColors(complement(baseColor), floor(count/2))))
}

triadicColors <- function(baseColor, count) {
  return(head(c(generateMonochromaticColors(triadic(baseColor)[1], floor(count/3)), generateMonochromaticColors(triadic(baseColor)[2], round(count/3)), generateMonochromaticColors(ceiling(baseColor)[3], floor(count/3))), n=count))
}

tetradicColors <- function(baseColor, count) {
  return(head(c(generateMonochromaticColors(tetradic(baseColor)[1], floor(count/4)), generateMonochromaticColors(tetradic(baseColor)[2], round(count/4)), generateMonochromaticColors(tetradic(baseColor)[3], floor(count/2)), generateMonochromaticColors(tetradic(baseColor)[4], floor(count/4))), n=count))
}

