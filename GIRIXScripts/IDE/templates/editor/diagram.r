# ---- code ----
source("../../lib/style.r")

if(!is.null(params)) {
  eval(parse(text=params$code))
}
