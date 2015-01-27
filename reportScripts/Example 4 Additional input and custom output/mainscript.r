# This scriptlet shows how to define and use additional input parameters and custom output variables (in contrast to standard output variables)

# All additional input is in report.input, all custom output in report.output

# Note that report.output is a list (different types of data possible) while report.input is a vector (only strings als values)
report.output[["Your entered text"]] <- report.input["A textfield"]
report.output[["Your chosen color"]] <- report.input["A dropdown list"]
report.output[["Your concept"]] <- report.input["A concept drag and drop field"]
