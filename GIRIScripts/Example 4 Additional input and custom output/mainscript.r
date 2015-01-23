# This scriptlet shows how to define and use additional input parameters and custom output variables (in contrast to standard output variables)

# All additional input is in GIRI.input, all custom output in GIRI.output

# Note that GIRI.output is a list (different types of data possible) while GIRI.input is a vector (only strings als values)
GIRI.output[["Your entered text"]] <- GIRI.input["A textfield"]
GIRI.output[["Your chosen color"]] <- GIRI.input["A dropdown list"]
GIRI.output[["Your concept"]] <- GIRI.input["A concept drag and drop field"]
