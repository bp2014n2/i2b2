#!/usr/local/bin/Rscript

if(!exists("load_data")){
    load_data_r_data <- read.csv("data/Raw.csv")
}

load_data <- function(){
  return(load_data_r_data)
}

