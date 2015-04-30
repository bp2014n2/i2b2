# ---- code ----
source("../../lib/style.r")

hist_age_extended <- function(patients) {
  options(scipen=10) # don't convert into exponential format

  # The only needed information from patients
  ages <- patients$age_in_years_num

  # Break the ages down to a histogram with specified age breaks
  ages.hist <- hist(
    ages,             # values for histogram
    plot=F,           # should not plottet, only data generated
    breaks=c(0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,200), 
    right=F           # intervals should be right closed
  )
 
  ages.hist$mean <- mean(ages.hist$counts)
  ages.hist$max <- utils.roundUp(max(ages.hist$counts))

  # Setting the layout
  par(
    omi=c(0.37,0,0,0),          # Outer border
    mai=c(0.3,0.9,0.35,0.3),    # Inner border
    mgp=c(0,0,0),               # Space axle text
    family="Lato",              # Font
    las=1,                      # Style of axle labels (horizontal)
    col=darkGray                # Default color
  )  

  # Creating the plot
  x<-barplot(
    ages.hist$counts,           # Print the counts
    horiz=T,                    # Horizontal
    border=NA,                  # No border
    xlim=c(0,ages.hist$max),    # Limits to be not always at 100%
    col=set.alpha(baseColor, 0.6), # Color of bars 
    axes=F                      # Axes are created with text labels later
  )
  
  # Background bars
  for (i in 0:4) {
    rect(
      ages.hist$max/10*2*i,     # X start
      0,                        # Y start
      ages.hist$max/10*(2*i+2), # X end
      20.7,                     # Y end
      col=set.alpha(baseColor, ((i)%%2+1) * 0.1), # Alternating color
      border=NA                 # No borders
    )
  }

  # Highlight the desired bars
  overlay<-c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
  if(!is.null(params$highlight)) {
    if(params$highlight == "none") {
      indexes <- c()
    } else if (params$highlight == "highest") {
      indexes <- c(which.max(ages.hist$counts))
    } else if (params$highlight == "aboveAverage") {
      indexes <- which(ages.hist$counts>ages.hist$mean, arr.in=TRUE)
    } else if (params$highlight == "index") {
       indexes <- params$highlightIndexes
    }
  } else {
    indexes <- c(which.max(ages.hist$counts))
  }

  for(index in indexes) {
    overlay[index] <- ages.hist$counts[index] # Print only a overlay for the highest 
    x2<-barplot(
      overlay,                    # Array of values to overlay
      horiz=T,                    # Horizontal
      border=NA,                  # No border
      xlim=c(0,ages.hist$max),    # Limits of original plot
      col=baseColor,              # Color
      axes=F,                     # Don't print axes
      add=T                       # Additive
    )
  }

  #Y Legend
  for (i in 1:length(ages.hist$counts))
  {
    legendText <- paste(ages.hist$breaks[i], "-", ages.hist$breaks[i+1]-1)

    # Oldest groupt gets >= interval
    if(i == length(ages.hist$counts)) {
      legendText <- paste(">=", ages.hist$breaks[i])
    } 
     
    # Y legend label 
    text(
      (-0.02)*ages.hist$max,    # If the scale is bigger the pixel scale is smaller so relative and 1/50 negative 
      x[i],                     # Position of the i'th bar
      legendText,               # Text left of the chart for this row
      xpd=T,                    # Plotting clipped to figure region
      adj=1                     # X adjustment ot labels   
    )
   
    # Bar label (hide for bars with less than 10% of maximum)
    if(ages.hist$counts[i] > ages.hist$max/10) {
      text(
        ages.hist$counts[i],    # X Position
        x[i],                   # Position of the i'th bar
        ages.hist$counts[i],    # Text
        xpd=T,                  # Plotting clipped to figure region
        adj=1.2,                # Move text to left to be on the bar
        cex=0.8,                # Font size 80%
        col="white"
      )
    }
  }

  # Average line
  arrows(ages.hist$mean,-0.25,ages.hist$mean,20.75,lwd=1.5,length=0,xpd=T,col=accentColor[1]) 
  arrows(ages.hist$mean,-0.25,ages.hist$mean,0,lwd=3,length=0,xpd=T)
  arrows(ages.hist$mean,20.75,ages.hist$mean,21,lwd=3,length=0,xpd=T)
  text(ages.hist$mean,22,"Average",adj=0.5,xpd=T,cex=0.65,font=3)

  # Header
  text(ages.hist$mean,21.5,round(ages.hist$mean, digits=0)+20,adj=0.5,xpd=T,cex=0.65,family="Lato",font=4)
  text(ages.hist$max/100*(-5.5),21.3,"Age",adj=0.5,xpd=T,cex=0.65,font=3)
  text(ages.hist$max,21.3,"Values are absolute",adj=1,xpd=T,cex=0.65,font=3)
  
  # X-Legend
  legend_positions <- c(0,2,4,6,8,10) * 0.1 * ages.hist$max
  mtext(legend_positions,at=legend_positions,1,line=0,cex=0.80)

  # Footer
  mtext("Elsevier Health Analytics",1,line=1,adj=1.0,cex=0.65,outer=T,font=3)
}

age_histogram_main <- function() {
  # Check if limit is set as a parameter
  if(is.null(params$limit) || (params$limit == -1)){
    # All patients
    patients <- i2b2$crc$getPatients(model.patient_set)
  } else {
    # Patients with limit
    patients <- i2b2$crc$getPatientsWithLimit(model.patient_set, params$limit)
  }
  # age_in_years_num is not set in database so calculate it
  patients$age_in_years_num = age(as.Date(patients$birth_date), Sys.Date())
  # create the diagram
  hist_age_extended(patients)
}

age_histogram_main()
