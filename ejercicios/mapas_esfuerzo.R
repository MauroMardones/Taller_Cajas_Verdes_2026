# =============================================================================
# mapas_esfuerzo.R
# Mapas: tracks de mareas y esfuerzo en la grilla
# Correr después de R/04_effort_grid.R
# =============================================================================

library(data.table)
library(fst)
library(ggplot2)
library(sf)
library(rnaturalearth)

CV_NV    <- read_fst("outputs/CV_NV_2021_2024_ZE.fst", as.data.table = TRUE)
esfuerzo <- read_fst("outputs/esfuerzo_2021_2024.fst", as.data.table = TRUE)

dir.create("figs", showWarnings = FALSE)

# --- Costa y límites del mapa ------------------------------------------------
# scale = "large" (1:10 M) es la más fina; requiere rnaturalearthhires
costa <- ne_countries(scale = "large", country = c("Spain", "Portugal"),
                      returnclass = "sf")

lim_lon <- range(esfuerzo$lon_cel) + c(-0.1, 0.1)
lim_lat <- range(esfuerzo$lat_cel) + c(-0.1, 0.1)

# --- 1. Track de una marea ---------------------------------------------------
limites <- data.table(
  LE_MET4 = c("DRB", "HMD", "FPO", "GNS", "GTR", "LLS", "LLSX", "OTB", "PS"),
  v_min   = c(0.1,   1.5,   0.1,   0.1,   0.1,   0.1,   0.1,    2.0,   0.1),
  v_max   = c(1.0,   2.5,   0.3,   2.1,   2.1,   2.5,   2.5,    4.5,   1.6)
)

# Cambia el arte o el número de marea para ver otras
arte_track <- "OTB"
marea      <- CV_NV[LE_MET4 == arte_track, unique(FT_REF)][1]

track <- CV_NV[FT_REF == marea][limites, on = "LE_MET4", nomatch = NULL]
track[, estado := fifelse(SI_SPCA >= v_min & SI_SPCA <= v_max, "pesca", "no pesca")]

ggplot() +
  geom_sf(data = costa, fill = "grey85", colour = "grey50") +
  geom_path(data = track, aes(SI_LONG, SI_LATI), colour = "grey40") +
  geom_point(data = track, aes(SI_LONG, SI_LATI, colour = estado), size = 1) +
  coord_sf(xlim = lim_lon, ylim = lim_lat) +
  labs(title = marea, x = NULL, y = NULL, colour = NULL) +
  theme_bw()

# --- 2. Esfuerzo de un arte, con los años en paneles -------------------------
# Cambia el arte y vuelve a correr el bloque
arte <- "DRB"

p_arte <- ggplot() +
  geom_tile(data = esfuerzo[LE_MET4 == arte],
            aes(lon_cel, lat_cel, fill = horas_pesca),
            width = 0.05, height = 0.05) +
  geom_sf(data = costa, fill = "grey85", colour = "grey50") +
  scale_fill_viridis_c(trans = "log10", name = "Horas de pesca") +
  facet_wrap(~ ANYO) +
  coord_sf(xlim = lim_lon, ylim = lim_lat) +
  labs(title = arte, x = NULL, y = NULL) +
  theme_bw()
p_arte

ggsave(paste0("figs/esfuerzo_", arte, ".png"), p_arte, width = 10, height = 8, dpi = 200)

# --- 3. Esfuerzo total (todos los artes) ------------------------------------
total <- esfuerzo[LE_MET4 == "TOTAL",
                  .(horas_pesca = sum(horas_pesca)),
                  by = .(lon_cel, lat_cel)]

ggplot() +
  geom_tile(data = total, aes(lon_cel, lat_cel, fill = horas_pesca),
            width = 0.05, height = 0.05) +
  geom_sf(data = costa, fill = "grey85", colour = "grey50") +
  scale_fill_viridis_c(trans = "log10", name = "Horas de pesca") +
  coord_sf(xlim = lim_lon, ylim = lim_lat) +
  labs(title = "Todos los artes, 2021-2024", x = NULL, y = NULL) +
  theme_bw()

