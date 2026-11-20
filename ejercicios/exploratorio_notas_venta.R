# =============================================================================
# exploratorio_notas_venta.R
# Análisis exploratorio de las notas de venta (antes del cruce)
# Lee los xlsx de data/raw/notas_venta/: se puede correr en cualquier momento
# =============================================================================

library(data.table)
library(readxl)
library(ggplot2)

# --- 1. Lectura: todos los .xlsx de la carpeta -------------------------------
ficheros_nv <- list.files("data/raw/notas_venta", pattern = "^[^~].*\\.xlsx$", full.names = TRUE)
ficheros_nv

lista_nv <- vector("list", length(ficheros_nv))
for (i in seq_along(ficheros_nv)) {
  lista_nv[[i]] <- as.data.table(read_xlsx(ficheros_nv[i]))
}
NV <- rbindlist(lista_nv, use.names = TRUE, fill = TRUE)

NV[, FECHAVENTA := as.Date(FECHAVENTA)]
NV[, ANYO := year(FECHAVENTA)]
NV[, FT_REF := paste0(ID_UDPROD, "_", format(FECHAVENTA, "%Y_%m_%d"))]

# --- 2. Estructura -----------------------------------------------------------
dim(NV)
str(NV)
head(NV)
NV[, .(desde = min(FECHAVENTA), hasta = max(FECHAVENTA))]

# --- 3. Líneas, barcos y mareas por año --------------------------------------
NV[, .(lineas = .N,
       barcos = uniqueN(ID_UDPROD),
       mareas = uniqueN(FT_REF)),
   by = ANYO][order(ANYO)]

# Líneas (especies) por marea
NV[, .(n_lineas = .N), by = FT_REF][, .N, by = n_lineas][order(n_lineas)]

# --- 4. Artes declarados (texto de la Junta) ---------------------------------
NV[, .(lineas = .N, mareas = uniqueN(FT_REF), barcos = uniqueN(ID_UDPROD)),
   by = ARTE][order(-mareas)]

# Mareas con más de un arte declarado
NV[, .(n_artes = uniqueN(ARTE)), by = FT_REF][, .N, by = n_artes]

# --- 5. Especies -------------------------------------------------------------
NV[, .(toneladas = round(sum(TOTAL_KILOS) / 1000, 1),
       mareas    = uniqueN(FT_REF)),
   by = .(FAO, NOMBRE_ESPECIE)][order(-toneladas)]

# Especies por arte
dcast(NV[, .(t = round(sum(TOTAL_KILOS) / 1000, 1)), by = .(ARTE, NOMBRE_ESPECIE)],
      NOMBRE_ESPECIE ~ ARTE, value.var = "t", fill = 0)

# --- 6. Kilos y euros por año y arte -----------------------------------------
kg_arte <- NV[, .(toneladas   = sum(TOTAL_KILOS) / 1000,
                  miles_euros = sum(TOTAL_EUROS) / 1000),
              by = .(ANYO, ARTE)]
kg_arte[order(ARTE, ANYO)]

ggplot(kg_arte, aes(factor(ANYO), miles_euros, fill = ARTE)) +
  geom_col() +
  labs(x = "Año", y = "Miles de euros", fill = "Arte") +
  theme_bw()

# --- 7. Precio medio por especie (€/kg) --------------------------------------
NV[, .(precio_medio = round(sum(TOTAL_EUROS) / sum(TOTAL_KILOS), 2)),
   by = .(NOMBRE_ESPECIE, ANYO)][order(NOMBRE_ESPECIE, ANYO)]

# --- 8. Ventas por mes -------------------------------------------------------
NV[, MES := month(FECHAVENTA)]
mareas_mes <- NV[, .(mareas = uniqueN(FT_REF)), by = .(ANYO, MES)]

ggplot(mareas_mes, aes(MES, mareas, colour = factor(ANYO))) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = 1:12) +
  labs(x = "Mes", y = "Mareas con venta", colour = "Año") +
  theme_bw()
