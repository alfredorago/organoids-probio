### Import and collate patient metadata (from Yun) and experimental treatment (from Jette)

# Set library to local folder
.libPaths(
  c(
    './packrat/lib/x86_64-pc-linux-gnu/3.6.1',
    './packrat/lib-ext/x86_64-pc-linux-gnu/3.6.1',
    './packrat/lib-R/x86_64-pc-linux-gnu/3.6.1')
)

library(readxl)
library(magrittr)
library(tidyverse)
library(janitor)

patient_metadata <-
  read_xlsx(path = snakemake@input[["patient_data"]]) %>%
  clean_names() %>%
  transmute(.,
            patient_id = randomisation_number %>% as.factor(.),
            sex = factor(x = gender_male1_female2, levels = c(1,2), labels = c('m','f')),
            room = str_extract(string = patient_id, pattern = "^[1,2]") %>% factor(x = ., levels = c(1,2), labels = c('room_1', 'room_2'))
  )

sample_treatment <-
  read_xlsx(path = snakemake@input[["sample_treatment"]]) %>%
  clean_names() %>%
  transmute(.,
            tube_id = tube_number %>% paste("A", ., sep = "_") %>%  as.factor(.),
            patient_id = str_extract(string = id, pattern = "^[1,2]0[0-9]{2}") %>% as.factor(.),
            treatment = str_extract(string = id, pattern = "_[C,L,3]") %>% factor(x = ., levels = c("_C", "_L", "_3"), labels = c("Control", "LGG", "3D")),
            replicate = str_extract(string = id, pattern = "[1-3]$"),
            laboratory = ifelse(grepl(pattern = "chr", x = id), "CH", "BIO") %>% factor(.),
            batch = purification_round
  )

experiment_metadata <- left_join(
  x = sample_treatment,
  y = patient_metadata,
  by = c('patient_id')
)

write_csv(x = experiment_metadata, path = snakemake@output[[1]])
