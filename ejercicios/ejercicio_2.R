# =============================================================================
# Ejercicio 2: sensibilidad del esfuerzo a los umbrales de velocidad (después de 03)
# Completa los huecos marcados con ___
# =============================================================================

library(data.table)
library(ggplot2)

CV_NV <- readRDS("outputs/CV_NV.rds")

# 2.1 Histograma de SI_SPCA por arte (LE_MET4), fuera de puerto.
#     Dibuja las líneas de los umbrales usados en 04 para DRB (0.1-1.0) y HMD (1.0-3.0).
ggplot(CV_NV[EN_PUERTO == 0 & SI_SPCA < 12], aes(SI_SPCA)) +
  geom_histogram(binwidth = 0.2) +
  facet_wrap(~ ___, scales = "free_y") +
  theme_bw()

# 2.2 Función que devuelve horas de pesca totales por arte para un v_max dado
horas_pesca <- function(datos, arte, v_min, v_max) {
  datos[LE_MET4 == arte & SI_SPCA >= v_min & SI_SPCA <= ___,
        sum(SI_TDIFF) / 3600]
}

horas_pesca(CV_NV, "DRB", 0.1, 1.0)

# 2.3 Sensibilidad: horas de pesca de DRB para v_max entre 0.6 y 2.0
sens <- data.table(v_max = seq(0.6, 2.0, by = 0.1))
sens[, horas := sapply(v_max, function(v) horas_pesca(CV_NV, "DRB", 0.1, v))]

ggplot(sens, aes(v_max, horas)) +
  geom_line() + geom_point() +
  labs(x = "v_max (nudos)", y = "Horas de pesca DRB") +
  theme_bw()

# 2.4 Repite 2.3 para FPO con v_max entre 2 y 6. ¿Por qué la curva no se estabiliza?
#     Pista: mira el histograma de FPO en 2.1.
___
