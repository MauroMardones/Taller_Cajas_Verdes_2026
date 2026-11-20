# =============================================================================
# Ejercicio 3: resolución de la grilla y pings perdidos (después de 04)
# Completa los huecos marcados con ___
# =============================================================================

library(data.table)
library(ggplot2)
# csquare.cod() está en R/04_effort_grid.R: córrelo antes en la misma sesión

CV_NV <- readRDS("outputs/CV_NV.rds")
pesca <- CV_NV[LE_MET4 == "DRB" & SI_SPCA >= 0.1 & SI_SPCA <= 1.0]

# 3.1 Pings perdidos: SI_TDIFF de varios minutos se suma entero como esfuerzo.
#     Limita SI_TDIFF a un máximo (p. ej. 2 × intervalo típico ≈ 400 s) y compara.
pesca[, SI_TDIFF_cap := pmin(SI_TDIFF, ___)]
pesca[, .(horas = sum(SI_TDIFF) / 3600, horas_cap = sum(___) / 3600), by = ANYO]

# 3.2 Agrega el esfuerzo a 0.01° y a 0.05° y compara número de celdas y mapas
grilla <- function(datos, res) {
  datos[, .(horas_pesca = sum(SI_TDIFF_cap) / 3600),
        by = .(lon_cel = floor(SI_LONG / res) * res + res / 2,
               lat_cel = floor(SI_LATI / res) * res + res / 2)]
}

g05 <- grilla(pesca, 0.05)
g01 <- grilla(pesca, ___)
c(celdas_005 = nrow(g05), celdas_001 = nrow(g01))

ggplot(g01, aes(lon_cel, lat_cel, fill = horas_pesca)) +
  geom_tile(width = 0.01, height = 0.01) +
  scale_fill_viridis_c(trans = "log10") +
  coord_quickmap() +
  theme_bw()

# 3.3 Añade el código C-square a g01 con csquare.cod()
g01[, csq := csquare.cod(___, ___, degrees = 0.01)]
head(g01)
