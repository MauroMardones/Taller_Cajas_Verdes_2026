# =============================================================================
# 01_load_CV.R
# Lectura y recorte espacial de datos de Cajas Verdes 2021-2024 (simulados)
# Golfo de Cádiz - Demarcación Sudatlántica
# =============================================================================

library(data.table)
library(tidyverse)
library(fst) 

# --- Crear carpetas si no existen --------------------------------------------
dir.create("outputs",      showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/shp",  showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/CSV",  showWarnings = FALSE, recursive = TRUE)
dir.create("figs",         showWarnings = FALSE, recursive = TRUE)
# --- Zona de estudio (bounding box) ------------------------------------------
lat_min <- 34; lat_max <- 38
lon_min <- -8; lon_max <- -5

# --- Ficheros de entrada -----------------------------------------------------
# Se leen TODOS los .csv de la carpeta, sin importar cómo se llamen.
# Lo que importa es el contenido: separador ";" y estas columnas:
#   FECHA;HORA;CFPO;VELOCIDAD;LATITUD;LONGITUD;RUMBO;¿EN PUERTO?
# El año se obtiene de la columna FECHA, no del nombre del fichero.
path_cv <- "data/raw/cajas_verdes"
anyos   <- 2021:2024

ficheros_cv <- list.files(path_cv, pattern = "\\.csv$", full.names = TRUE)
ficheros_cv                                  # comprobar qué se va a leer

# --- Lectura con filtro espacial inmediato ------------------------------------
message("Leyendo Cajas Verdes...")

lista_cv <- vector("list", length(ficheros_cv))

for (i in seq_along(ficheros_cv)) {

  dt <- fread(ficheros_cv[i],
              sep = ";",
              dec = ".",
              encoding = "UTF-8",
              showProgress = FALSE)

  # Renombrar columnas con caracteres especiales
  setnames(dt, "\xbf\xa1EN PUERTO?",  "EN_PUERTO", skip_absent = TRUE)
  setnames(dt, "\xef\xbb\xbfFECHA",   "FECHA",     skip_absent = TRUE)
  # Alternativa si el BOM llega diferente:
  old <- grep("FECHA|fecha", names(dt), value = TRUE)[1]
  if (!is.na(old) && old != "FECHA") setnames(dt, old, "FECHA")

  # Filtro espacial inmediato para reducir memoria
  dt <- dt[LATITUD >= lat_min & LATITUD <= lat_max &
           LONGITUD >= lon_min & LONGITUD <= lon_max]

  message(sprintf("  %s: %s filas tras filtro ZE",
                  basename(ficheros_cv[i]), format(nrow(dt), big.mark = ".")))
  lista_cv[[i]] <- dt
  rm(dt); gc()
}

# --- Unir todos los ficheros -------------------------------------------------
CV_all <- rbindlist(lista_cv, use.names = TRUE, fill = TRUE)
#elimina la lista de data.tables de la memoria RAM — ya no 
# la necesitas porque todo está unido en CV_all.
# fuerza al garbage collector de R a liberar esa memoria de inmediato,
# en lugar de esperar a que R lo haga solo. 
# Con 67M filas es importante hacerlo explícito 
#para no quedarte sin RAM antes de continuar con el formateo.
rm(lista_cv); gc()

# --- Año desde la fecha del ping (FECHA = dd/mm/aaaa) -------------------------
CV_all[, ANYO := as.integer(substr(FECHA, 7, 10))]
CV_all <- CV_all[ANYO %in% anyos]

message(sprintf("\nTotal filas CV: %s", format(nrow(CV_all), big.mark = ".")))
print(CV_all[, .N, by = ANYO][order(ANYO)])
message(sprintf("Columnas: %s", paste(names(CV_all), collapse = ", ")))

# --- Guardar como .fst para relectura rápida ---------------------------------

write_fst(CV_all, "outputs/CV_2021_2024_ZE.fst", compress = 75)
