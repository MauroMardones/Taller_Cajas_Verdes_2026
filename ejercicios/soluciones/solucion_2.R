# =============================================================================
# Solución ejercicio 2
# =============================================================================

library(data.table)
library(ggplot2)

CV_NV <- readRDS("outputs/CV_NV.rds")

# 2.1
umb <- data.table(LE_MET4 = c("DRB", "DRB", "HMD", "HMD"), v = c(0.1, 1.0, 1.0, 3.0))
ggplot(CV_NV[EN_PUERTO == 0 & SI_SPCA < 12], aes(SI_SPCA)) +
  geom_histogram(binwidth = 0.2) +
  geom_vline(data = umb, aes(xintercept = v), colour = "red", linetype = 2) +
  facet_wrap(~ LE_MET4, scales = "free_y") +
  theme_bw()

# 2.2
horas_pesca <- function(datos, arte, v_min, v_max) {
  datos[LE_MET4 == arte & SI_SPCA >= v_min & SI_SPCA <= v_max,
        sum(SI_TDIFF) / 3600]
}
horas_pesca(CV_NV, "DRB", 0.1, 1.0)

# 2.3  En DRB la curva se estabiliza a partir de ~1.4 nudos: el valle entre modos está limpio
sens <- data.table(v_max = seq(0.6, 2.0, by = 0.1))
sens[, horas := sapply(v_max, function(v) horas_pesca(CV_NV, "DRB", 0.1, v))]
ggplot(sens, aes(v_max, horas)) + geom_line() + geom_point() + theme_bw()

# 2.4  En FPO hay tránsitos cortos entre calamentos a 4.5-6.5 nudos:
#      subir v_max por encima de ~4 empieza a contar esos tránsitos como pesca
sens_fpo <- data.table(v_max = seq(2, 6, by = 0.25))
sens_fpo[, horas := sapply(v_max, function(v) horas_pesca(CV_NV, "FPO", 0.1, v))]
ggplot(sens_fpo, aes(v_max, horas)) + geom_line() + geom_point() + theme_bw()
