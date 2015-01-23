# Has to be installed in R!
library(splines)
library(survival)

# Check for correct usage / input
if (length(GIRI.concept.names) < 2) {
	write("Script error: Please specify two concepts!\n", stderr())
}

# Initialize data structures
patient.event.dates <- list()
risk.concept <- GIRI.concept.names[1]
target.concept <- GIRI.concept.names[2]
km.id <- c()
km.period <- c()
km.status <- c()
km.group <- c()
sample.count <- 0

for (i in 1:length(GIRI.observations)) {
	
	# Error case: No observations / empty patient set
	if (dim(GIRI.observations[[i]])[1] == 0) {
		write(paste("Script error: No observations found for patient set ", i, " (empty patient set?).\n"), stderr())
		next
	}
	
	patient.event.dates[[i]] <- list()

	# For all rows in this observation table: Build tree / map like data structure
	for (j in 1:dim(GIRI.observations[[i]])[1]) {
		
		# Some abbreviations
		tmp.concept.path <- GIRI.observations[[i]][j,"concept_path"]
		tmp.patient.id <- GIRI.observations[[i]][j,"patient_id_value"]
		tmp.start.date <- GIRI.observations[[i]][j,"start_date"]
	
		# Check if there is already a list entry for this patient
		if ( is.null(patient.event.dates[[i]][[tmp.patient.id]]) ) {
			patient.event.dates[[i]][[tmp.patient.id]] <- list()
			patient.event.dates[[i]][[tmp.patient.id]][["risk.observation.dates"]] <- list()
			patient.event.dates[[i]][[tmp.patient.id]][["target.observation.dates"]] <- list()
		}
	
		# Check if observation is risk concept or target concept (= if concept_path starts with risk.concept oder target.concept)
		if ( substr(tmp.concept.path, 1, nchar(risk.concept)) == risk.concept ) {
			# Append date of the observation to the end of the list
			tmp.current.list.length <- length(patient.event.dates[[i]][[tmp.patient.id]][["risk.observation.dates"]])
			patient.event.dates[[i]][[tmp.patient.id]][["risk.observation.dates"]][[tmp.current.list.length + 1]] <- tmp.start.date
		} else if ( substr(tmp.concept.path, 1, nchar(target.concept)) == target.concept ) {
			# Append date of the observation to the end of the list
			tmp.current.list.length <- length(patient.event.dates[[i]][[tmp.patient.id]][["target.observation.dates"]])
			patient.event.dates[[i]][[tmp.patient.id]][["target.observation.dates"]][[tmp.current.list.length + 1]] <- tmp.start.date
		} else {
			# Error
			write("Script error: concept_path of observation is not part of risk or target concept\n", stderr())
		}
	}
}

# Get latest date of target observation as study end date
complete.date.vector <- list()
for (k in 1:length(GIRI.observations)) {
	for (l in 1:length(patient.event.dates[[k]])) {
		complete.date.vector <- c(complete.date.vector, patient.event.dates[[k]][[l]][["target.observation.dates"]])
	}
}
if (length(complete.date.vector) == 0) {
	write("Script error: No target events found\n", stderr())
}
end.of.study <- max(do.call(c,complete.date.vector))


# Consider the dates of risk events and target events for every patient and every patient group
for (m in 1:length(GIRI.observations)) {
	for (n in 1:length(patient.event.dates[[m]])) {
		# Error case. Shouldn't happen if properly used
		if( length(patient.event.dates[[m]][[n]][["risk.observation.dates"]]) == 0 ) {
			write(paste("Script error: No risk observation for patient with id ", attributes(patient.event.dates[[m]][n])[[1]], " found. Please read instructions on 'Choose scriptlet' tab!\n"), stderr())
			next
		}
	
		# Case: The target observation occured at least one time
		if( length(patient.event.dates[[m]][[n]][["target.observation.dates"]]) > 0 ) {
			# Sort the dates from old to new
			tmp.sorted.risks <- sort(do.call(c,patient.event.dates[[m]][[n]][["risk.observation.dates"]]))
			tmp.sorted.targets <- sort(do.call(c,patient.event.dates[[m]][[n]][["target.observation.dates"]]))
			# Choose the oldest target date that is newer than the oldest risk
			chosen.target <- c()
			for (o in 1:length(tmp.sorted.targets)) {
				if (tmp.sorted.targets[o] > tmp.sorted.risks[1]) {
					chosen.target <- tmp.sorted.targets[o]
					break
				}
			}
			# If all risk events are newer than target events -> take as censored event
			if (length(chosen.target) == 0) {
				# Determine time period to end of study
				tmp.period <- round(as.numeric(difftime(end.of.study, tmp.sorted.risks[1], units="days")))
				# Add it to sample data if risk event occured before the study ended
				if (tmp.period > 0) {
					km.id[sample.count + 1] <- attributes(patient.event.dates[[m]][n])[[1]]
					km.period[sample.count + 1] <- tmp.period
					km.status[sample.count + 1] <- 0 # 0 means censored
					km.group[sample.count + 1] <- paste("Patient set", m)
					sample.count <- sample.count + 1
				}
			} else {
			# At least one target event occured after the first risk event
				# Now determine the last risk event that occured before the chosen target event
				chosen.risk <- c()
				for (p in length(tmp.sorted.risks):1) {
					if (tmp.sorted.risks[p] < chosen.target) {
						chosen.risk <- tmp.sorted.risks[p]
						break
					}
				}
				# Determine time difference and add as normal (not censored) sample
				km.id[sample.count + 1] <- attributes(patient.event.dates[[m]][n])[[1]]
				km.period[sample.count + 1] <- round(as.numeric(difftime(chosen.target, chosen.risk, units="days")))
				km.status[sample.count + 1] <- 1 # 1 means normal/uncensored
				km.group[sample.count + 1] <- paste("Patient set", m)
				sample.count <- sample.count + 1
			}
		
		} else {
		# Case: The target observation never occured (censored event)
			# Determine the point of first occurence of risk event
			tmp.first.risk.occurence <- min(do.call(c,patient.event.dates[[m]][[n]][["risk.observation.dates"]]))
			# Determine time period to end of study
			tmp.period <- round(as.numeric(difftime(end.of.study, tmp.first.risk.occurence, units="days")))
			# Add it to sample data if risk event occured before the study ended
			if (tmp.period > 0) {
				km.id[sample.count + 1] <- attributes(patient.event.dates[[m]][n])[[1]]
				km.period[sample.count + 1] <- tmp.period
				km.status[sample.count + 1] <- 0 # 0 means censored
				km.group[sample.count + 1] <- paste("Patient set", m)
				sample.count <- sample.count + 1
			}
		}
	}
}

# Kaplan Meier specific
km.table <- data.frame(km.id, km.period, km.status, km.group)
surv.curve <- survfit(Surv(km.period, km.status) ~ km.group, data = km.table, conf.type="none")

# Case: Only one group is available, strata is set to null
if (is.null(surv.curve$strata)) {
	graph.number = 1
} else {
	graph.number = length(surv.curve$strata)
}

# Plot it
if (GIRI.input["Colorful or black-white plot graphic?"] == "Colorful") {
	colors <- seq(graph.number)
	lines = 1
} else {
	colors <- c("black","gray","black","gray","black","gray")
	lines = c(1,1,3,3,2,2)
}
plot(surv.curve,col=colors,lwd=3, main=GIRI.input["Plot heading"], xlab="t in days", ylab="P", lty=lines)
legend("topright",legend=paste("Patient Set", seq(graph.number)),lwd=3,col=colors, lty=lines)

# Write output data
GIRI.output[["End of study"]] <- end.of.study
output.table <- data.frame(Patient = km.id, Time.in.days = as.character(km.period), Censored = as.character(km.status), Group = km.group)
GIRI.output[["Kaplan-Meier-input-table"]] <- output.table



