# This scriptlet shows how to access all the preinitialized data of the patient sets (left drag&drop fields)
# It just assigns it to standard output variables so that the data is displayed in the front end

# Caution: If an empty data.frame is assigned there will be an error message (it works however). To avoid this message
# please consider this case in a real scriptlet by using e.g. nrow function

# All data of patient set one
report.output.1 <- report.patients[[1]] # Data from patient_dimension
report.output.2 <- report.observations[[1]] # Data from observation_fact and concept_dimension
report.output.3 <- report.events[[1]] # Data from visit_dimension
report.output.4 <- report.observers[[1]] # Data from provider_dimension
report.output.5 <- report.modifiers[[1]] # Data from modifier_dimension

# Holds the concept_paths of the specified concepts (right drag&drop fields)
report.output.11 <- report.concept.names
