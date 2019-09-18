## Main drake launcher

library(drake)
library(here)

source(here("scripts/libraries.R"))
source(here("scripts/functions.R"))
source(here("scripts/plan.R"))

drake_config(plan = plan, verbose = 2)
