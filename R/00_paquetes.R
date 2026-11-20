# =============================================================================
# 00_paquetes.R
# Instala los paquetes que faltan y carga todos los del taller
# Correr una vez al empezar la sesión
# =============================================================================

paquetes <- c("data.table", "fst", "tidyverse", "lubridate", "geosphere",
              "readxl", "writexl", "sf", "rnaturalearth", "rnaturalearthdata",
              "rmarkdown")

# Instalar solo los que no están
faltan <- paquetes[!paquetes %in% rownames(installed.packages())]
if (length(faltan) > 0) install.packages(faltan)

# rnaturalearthhires (costa a escala fina) no está en CRAN: se instala desde rOpenSci
if (!"rnaturalearthhires" %in% rownames(installed.packages()))
  install.packages("rnaturalearthhires", repos = "https://ropensci.r-universe.dev")

# Cargar todos
for (p in paquetes) library(p, character.only = TRUE)
