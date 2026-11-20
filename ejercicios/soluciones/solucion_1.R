# =============================================================================
# Solución ejercicio 1
# =============================================================================

library(data.table)
library(ggplot2)

CV <- readRDS("outputs/CV_ZE_fmt.rds")

# 1.1
CV[, .(barcos = uniqueN(VE_REF), mareas = uniqueN(FT_REF)), by = ANYO]

# 1.2  Dominan ~151 s y ~191 s (dos tipos de caja); los huecos > 10 min son pings perdidos
CV[, quantile(SI_TDIFF, c(0.05, 0.25, 0.5, 0.75, 0.95))]
CV[, mean(SI_TDIFF > 600)]

# 1.3
ggplot(CV[EN_PUERTO == 0 & SI_SPCA < 15], aes(SI_SPCA)) +
  geom_histogram(binwidth = 0.25) +
  theme_bw()

# 1.4  Los SI_SPCA más altos coinciden con SI_TDIFF muy cortos (10-40 s):
#      un error GPS de ~10 m dividido por 20 s ya son ~1 nudo de velocidad ficticia
CV[order(-SI_SPCA)][1:10, .(VE_REF, SI_TIMESTAMP, SI_SP, SI_SPCA, SI_TDIFF, SI_DISTANCECA)]
CV[EN_PUERTO == 1, .(dif_media = mean(abs(SI_SPCA - SI_SP))), by = .(intervalo_corto = SI_TDIFF < 60)]
