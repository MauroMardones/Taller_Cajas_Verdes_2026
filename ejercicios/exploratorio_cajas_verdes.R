# =============================================================================
# exploratorio_cajas_verdes.R
# Análisis exploratorio de las cajas verdes (antes del cruce con notas de venta)
# Correr después de R/02_format_CV.R
# =============================================================================

library(data.table)
library(fst)
library(ggplot2)

CV <- read_fst("outputs/CV_2021_2024_ZE_fmt.fst", as.data.table = TRUE)

# --- 1. Estructura -----------------------------------------------------------
dim(CV)
str(CV)
head(CV)
CV[, .(desde = min(SI_TIMESTAMP), hasta = max(SI_TIMESTAMP))]

# --- 2. Pings, barcos y mareas por año ---------------------------------------
CV[, .(pings  = .N,
       barcos = uniqueN(VE_REF),
       mareas = uniqueN(FT_REF)),
   by = ANYO][order(ANYO)]

# --- 3. Pings y mareas por barco ---------------------------------------------
por_barco <- CV[, .(pings = .N, mareas = uniqueN(FT_REF)), by = VE_REF][order(-mareas)]
por_barco
summary(por_barco$mareas)

ggplot(por_barco, aes(mareas)) +
  geom_histogram(bins = 20) +
  labs(x = "Mareas por barco (2021-2024)", y = "Barcos") +
  theme_bw()

# --- 4. Pings por mes --------------------------------------------------------
CV[, MES := month(SI_TIMESTAMP)]
pings_mes <- CV[, .(pings = .N), by = .(ANYO, MES)]
dcast(pings_mes, MES ~ ANYO, value.var = "pings")

ggplot(pings_mes, aes(MES, pings, colour = factor(ANYO))) +
  geom_line() +
  geom_point() +
  scale_x_continuous(breaks = 1:12) +
  labs(x = "Mes", y = "Pings", colour = "Año") +
  theme_bw()

# --- 5. Pings en puerto ------------------------------------------------------
CV[, .N, by = EN_PUERTO]
CV[, .(pct_puerto = round(100 * mean(EN_PUERTO == 1), 1)), by = ANYO][order(ANYO)]

# --- 6. Intervalo entre pings (SI_TDIFF, segundos) ---------------------------
CV[, quantile(SI_TDIFF, c(0.05, 0.25, 0.5, 0.75, 0.95))]
CV[, .(pct_menor_1min  = round(100 * mean(SI_TDIFF < 60), 2),
       pct_mayor_10min = round(100 * mean(SI_TDIFF > 600), 2))]

ggplot(CV[SI_TDIFF < 450], aes(SI_TDIFF)) +
  geom_histogram(binwidth = 5) +
  labs(x = "SI_TDIFF (s)", y = "Pings") +
  theme_bw()

# --- 7. Velocidad reportada (SI_SP) y calculada (SI_SPCA) --------------------
CV[, .(SI_SP   = round(quantile(SI_SP,   c(0.5, 0.95, 0.99)), 2),
       SI_SPCA = round(quantile(SI_SPCA, c(0.5, 0.95, 0.99)), 2))]

# Pings con velocidad calculada irreal: ¿qué intervalo tienen?
CV[SI_SPCA > 15, .N]
CV[SI_SPCA > 15][order(-SI_SPCA)][1:10, .(VE_REF, SI_TIMESTAMP, SI_SP, SI_SPCA, SI_TDIFF)]

ggplot(CV[EN_PUERTO == 0 & SI_SPCA < 14], aes(SI_SPCA)) +
  geom_histogram(binwidth = 0.25) +
  labs(x = "SI_SPCA (nudos)", y = "Pings fuera de puerto") +
  theme_bw()

# --- 8. Posiciones de un día cualquiera --------------------------------------
dia <- as.Date("2023-03-15")

ggplot(CV[as.Date(SI_TIMESTAMP) == dia], aes(SI_LONG, SI_LATI, colour = VE_REF)) +
  geom_point(size = 0.3) +
  coord_quickmap() +
  labs(title = dia, x = NULL, y = NULL) +
  theme_bw() +
  theme(legend.position = "none")
