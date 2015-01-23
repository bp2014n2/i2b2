# This scriptlet shows how to access all the preinitialized data of the patient sets (left drag&drop fields)
# It just assigns it to standard output variables so that the data is displayed in the front end

# Caution: If an empty data.frame is assigned there will be an error message (it works however). To avoid this message
# please consider this case in a real scriptlet by using e.g. nrow function

# All data of patient set one
GIRI.output.1 <- GIRI.patients[[1]] # Data from patient_dimension
GIRI.output.2 <- GIRI.observations[[1]] # Data from observation_fact and concept_dimension
GIRI.output.3 <- GIRI.events[[1]] # Data from visit_dimension
GIRI.output.4 <- GIRI.observers[[1]] # Data from provider_dimension
GIRI.output.5 <- GIRI.modifiers[[1]] # Data from modifier_dimension

# All data of patient set two
GIRI.output.6 <- GIRI.patients[[2]] # Data from patient_dimension
GIRI.output.7 <- GIRI.observations[[2]] # Data from observation_fact and concept_dimension
GIRI.output.8 <- GIRI.events[[2]] # Data from visit_dimension
GIRI.output.9 <- GIRI.observers[[2]] # Data from provider_dimension
GIRI.output.10 <- GIRI.modifiers[[2]] # Data from modifier_dimension


# Holds the concept_paths of the specified concepts (right drag&drop fields)
GIRI.output.11 <- GIRI.concept.names