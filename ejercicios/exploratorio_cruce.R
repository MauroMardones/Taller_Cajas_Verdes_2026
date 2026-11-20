# =============================================================================
# exploratorio_cruce.R
# Análisis exploratorio de los datos cruzados: cajas verdes × notas de venta
# Correr después de R/03_join_CV_NV.R
# =============================================================================

library(data.table)
library(fst)
library(ggplot2)

CV_NV <- read_fst("outputs/CV_NV_2021_2024_ZE.fst", as.data.table = TRUE)

# --- 1. Estructura -----------------------------------------------------------
dim(CV_NV)
str(CV_NV)
CV_NV[, .(desde = min(SI_TIMESTAMP), hasta = max(SI_TIMESTAMP))]

# --- 2. Qué se pierde en el cruce (inner join) -------------------------------
# Mareas en cajas verdes (después del 02) y en notas de venta (brutas)
# Las notas de venta se leen de nuevo de los xlsx porque el 03 no guarda
# las mareas sin caja verde: el inner join las elimina antes de guardar CV_NV.
CV <- read_fst("outputs/CV_2021_2024_ZE_fmt.fst", columns = "FT_REF", as.data.table = TRUE)
mareas_cv <- unique(CV$FT_REF)
rm(CV)

ficheros_nv <- list.files("data/raw/notas_venta", pattern = "^[^~].*\\.xlsx$", full.names = TRUE)
lista_nv <- vector("list", length(ficheros_nv))
for (i in seq_along(ficheros_nv)) {
  lista_nv[[i]] <- as.data.table(readxl::read_xlsx(ficheros_nv[i]))
}
NV <- rbindlist(lista_nv, use.names = TRUE, fill = TRUE)
mareas_nv <- unique(paste0(NV$ID_UDPROD, "_", format(as.Date(NV$FECHAVENTA), "%Y_%m_%d")))

mareas_cruce <- unique(CV_NV$FT_REF)

data.table(
  conjunto = c("Mareas con caja verde", "Mareas con nota de venta",
               "Mareas en el cruce",
               "Caja verde sin nota de venta", "Nota de venta sin caja verde"),
  mareas   = c(length(mareas_cv), length(mareas_nv),
               length(mareas_cruce),
               length(setdiff(mareas_cv, mareas_nv)), length(setdiff(mareas_nv, mareas_cv)))
)

# --- 3. Barcos por arte y año ------------------------------------------------
barcos <- CV_NV[, .(n_barcos = uniqueN(VE_REF)), by = .(ANYO, LE_MET4)]
dcast(barcos, LE_MET4 ~ ANYO, value.var = "n_barcos")

# Barcos totales y artes por barco (¿algún barco con más de un arte?)
CV_NV[, uniqueN(VE_REF)]
CV_NV[, .(n_artes = uniqueN(LE_MET4)), by = VE_REF][, .N, by = n_artes]

# --- 4. Mareas (barco-día) por arte y año ------------------------------------
mareas <- CV_NV[, .(n_mareas = uniqueN(FT_REF)), by = .(ANYO, LE_MET4)]
dcast(mareas, LE_MET4 ~ ANYO, value.var = "n_mareas")

ggplot(mareas, aes(factor(ANYO), n_mareas, fill = LE_MET4)) +
  geom_col() +
  labs(x = "Año", y = "Mareas", fill = "Arte") +
  theme_bw()

# --- 5. Pings por arte y proporción en puerto --------------------------------
CV_NV[, .(pings      = .N,
          pct_puerto = round(100 * mean(EN_PUERTO == 1), 1)),
      by = LE_MET4][order(-pings)]

# --- 6. Captura y valor por arte y año ---------------------------------------
# TOTAL_KILOS y TOTAL_EUROS se repiten en cada ping de la marea:
# primero una fila por marea, luego sumar
nv_marea <- unique(CV_NV[, .(FT_REF, ANYO, LE_MET4, TOTAL_KILOS, TOTAL_EUROS, N_ESPECIES)])

nv_marea[, .(toneladas   = round(sum(TOTAL_KILOS) / 1000, 1),
             miles_euros = round(sum(TOTAL_EUROS) / 1000, 1),
             kg_marea    = round(mean(TOTAL_KILOS)),
             especies    = round(mean(N_ESPECIES), 1)),
         by = .(LE_MET4, ANYO)][order(LE_MET4, ANYO)]

# --- 7. Duración de las mareas -----------------------------------------------
duracion <- CV_NV[, .(horas = as.numeric(difftime(max(SI_TIMESTAMP), min(SI_TIMESTAMP),
                                                  units = "hours"))),
                  by = .(FT_REF, LE_MET4)]

ggplot(duracion, aes(LE_MET4, horas)) +
  geom_boxplot() +
  labs(x = "Arte", y = "Duración de la marea (h)") +
  theme_bw()

# --- 8. Intervalo entre pings ------------------------------------------------
CV_NV[, quantile(SI_TDIFF, c(0.05, 0.25, 0.5, 0.75, 0.95))]
CV_NV[, .(pct_mayor_10min = round(100 * mean(SI_TDIFF > 600), 2))]

ggplot(CV_NV[SI_TDIFF < 450], aes(SI_TDIFF)) +
  geom_histogram(binwidth = 5) +
  labs(x = "SI_TDIFF (s)", y = "Pings") +
  theme_bw()

# escala log

ggplot(CV_NV[SI_TDIFF < 450], aes(SI_TDIFF)) +
  geom_histogram(binwidth = 5) +
  scale_y_log10() +
  labs(x = "SI_TDIFF (s)", y = "Pings (escala log)") +
  theme_bw()


# --- 9. Velocidad calculada por arte y límites de pesca ----------------------
limites <- data.table(
  LE_MET4 = c("DRB", "HMD", "FPO", "GNS", "GTR", "LLS", "LLSX", "OTB", "PS"),
  v_min   = c(0.1,   1.5,   0.1,   0.1,   0.1,   0.1,   0.1,    2.0,   0.1),
  v_max   = c(1.0,   2.5,   0.3,   2.1,   2.1,   2.5,   2.5,    4.5,   1.6)
)

ggplot(CV_NV[EN_PUERTO == 0 & SI_SPCA < 12], aes(SI_SPCA)) +
  geom_histogram(binwidth = 0.2) +
  geom_vline(data = limites, aes(xintercept = v_min), colour = "red", linetype = 2) +
  geom_vline(data = limites, aes(xintercept = v_max), colour = "red", linetype = 2) +
  facet_wrap(~ LE_MET4, scales = "free_y") +
  labs(x = "SI_SPCA (nudos)", y = "Pings") +
  theme_bw()

# Proporción de pings dentro del rango de pesca por arte
CV_NV[limites, on = "LE_MET4"][
  , .(pct_pesca = round(100 * mean(SI_SPCA >= v_min & SI_SPCA <= v_max), 1)),
  by = LE_MET4]
