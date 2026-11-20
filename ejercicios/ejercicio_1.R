# =============================================================================
# Ejercicio 1: explorar los datos brutos (después de 01 y 02)
# Completa los huecos marcados con ___
# =============================================================================

library(data.table)
library(ggplot2)

CV <- readRDS("outputs/CV_ZE_fmt.rds")

# 1.1 ¿Cuántos barcos y cuántas mareas (barco-día) hay por año?
CV[, .(barcos = uniqueN(___), mareas = uniqueN(___)), by = ANYO]

# 1.2 Distribución del intervalo entre pings (SI_TDIFF, segundos).
#     ¿Qué dos valores dominan? ¿Qué proporción supera los 10 min?
CV[, quantile(SI_TDIFF, c(0.05, 0.25, 0.5, 0.75, 0.95))]
CV[, mean(SI_TDIFF > ___)]

# 1.3 Histograma de velocidad calculada (SI_SPCA) fuera de puerto.
#     ¿Ves los dos modos (pesca / navegación)?
ggplot(CV[EN_PUERTO == ___ & SI_SPCA < 15], aes(SI_SPCA)) +
  geom_histogram(binwidth = 0.25) +
  theme_bw()

# 1.4 Compara la velocidad reportada por la caja (SI_SP) con la calculada (SI_SPCA).
#     ¿Dónde aparecen los valores más disparatados de SI_SPCA? Pista: mira SI_TDIFF.
CV[order(-SI_SPCA)][1:10, .(VE_REF, SI_TIMESTAMP, SI_SP, SI_SPCA, SI_TDIFF, SI_DISTANCECA)]
