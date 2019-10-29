### Python initializer

# A simple script to activate python within R using reticulate and Conda
reticulate::use_condaenv(condaenv = "pymake", conda = "~/bin/conda", required = T)
reticulate::py_config()
library(reticulate)

## Access interactive python
# repl_python()
# exit

## Import python libraries for use within R
# np <- import("numpy")
## NOTE: the L suffix specifies integer type, necessary for correct interpretation in python
# np$random$binomial(n = 10, p = 0.3, size = 20L)

## Run python lines
# py_run_string("
# x = 10
# y = np.random.binomial(1, 0.5, x)
#               ")
# py$y
