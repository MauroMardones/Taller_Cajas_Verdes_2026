# =============================================================================
# especies_cerco.R
# Composición de la captura del cerco (PS) y distribución espacio-temporal
# de las especies acompañantes (todo lo que no es sardina)
# Correr después de R/04_effort_grid.R
# =============================================================================

library(data.table)
library(fst)
library(readxl)
library(ggplot2)
library(sf)
library(rnaturalearth)

dir.create("figs", showWarnings = FALSE)

# --- 1. Notas de venta: una fila por especie y marea -------------------------
# ¿Por qué se vuelven a leer los xlsx?
# El script 03 lee las notas de venta con una fila por especie y marea (NV_all),
# pero las colapsa a una fila por marea (arte dominante, kilos y euros totales)
# antes del cruce. Lo que guarda es CV_NV, sin las columnas FAO ni NOMBRE_ESPECIE.
# Aquí necesitamos las especies, así que se leen de nuevo las notas brutas.
# Las cajas verdes NO se releen: los pings salen de CV_NV_2021_2024_ZE.fst (03).
# Se leen todos los .xlsx de la carpeta, sin importar cómo se llamen
ficheros_nv <- list.files("data/raw/notas_venta", pattern = "^[^~].*\\.xlsx$", full.names = TRUE)
ficheros_nv

lista_nv <- vector("list", length(ficheros_nv))
for (i in seq_along(ficheros_nv)) {
  lista_nv[[i]] <- as.data.table(read_xlsx(ficheros_nv[i]))
}
NV <- rbindlist(lista_nv, use.names = TRUE, fill = TRUE)

setnames(NV, "ID_UDPROD", "VE_REF")
NV[, FECHAVENTA := as.Date(FECHAVENTA)]
NV[, FT_REF := paste0(VE_REF, "_", format(FECHAVENTA, "%Y_%m_%d"))]

# --- 2. Mareas de cerco ------------------------------------------------------
# Mareas asignadas a PS en el script 03 (arte dominante por kilos)
CV_NV <- read_fst("outputs/CV_NV_2021_2024_ZE.fst", as.data.table = TRUE)

mareas_ps <- unique(CV_NV[LE_MET4 == "PS", FT_REF])
NV_ps     <- NV[FT_REF %in% mareas_ps]

NV_ps[, ANYO := year(FECHAVENTA)]
NV_ps[, MES  := month(FECHAVENTA)]
NV_ps[, tipo := fifelse(FAO == "PIL", "sardina", "acompañante")]

length(mareas_ps)
NV_ps[, .(kg = sum(TOTAL_KILOS), mareas = uniqueN(FT_REF)), by = .(FAO, NOMBRE_ESPECIE, tipo)]

# --- 3. Composición de la captura --------------------------------------------
# Por año
comp_anual <- NV_ps[, .(kg = sum(TOTAL_KILOS)), by = .(ANYO, NOMBRE_ESPECIE)]
comp_anual[, pct := round(100 * kg / sum(kg), 1), by = ANYO]
dcast(comp_anual, NOMBRE_ESPECIE ~ ANYO, value.var = "pct")

ggplot(comp_anual, aes(factor(ANYO), kg / 1000, fill = NOMBRE_ESPECIE)) +
  geom_col() +
  labs(x = "Año", y = "Toneladas", fill = "Especie") +
  theme_bw()

# Por mes (todos los años juntos)
comp_mes <- NV_ps[, .(kg = sum(TOTAL_KILOS)), by = .(MES, NOMBRE_ESPECIE)]
comp_mes[, pct := 100 * kg / sum(kg), by = MES]

ggplot(comp_mes, aes(factor(MES), pct, fill = NOMBRE_ESPECIE)) +
  geom_col() +
  labs(x = "Mes", y = "% de la captura (kg)", fill = "Especie") +
  theme_bw()

# --- 4. Frecuencia de aparición de las acompañantes --------------------------
# % de mareas de cerco en que aparece cada especie acompañante
mareas_anio <- NV_ps[, .(n_mareas = uniqueN(FT_REF)), by = ANYO]

frec <- NV_ps[tipo == "acompañante", .(mareas = uniqueN(FT_REF)), by = .(ANYO, NOMBRE_ESPECIE)]
frec <- merge(frec, mareas_anio, by = "ANYO")
frec[, pct_mareas := round(100 * mareas / n_mareas, 1)]
dcast(frec, NOMBRE_ESPECIE ~ ANYO, value.var = "pct_mareas")

# --- 5. Reparto de la captura entre los pings de pesca -----------------------
# Como splitAmongPings (VMStools): los kg de cada especie en una marea se
# reparten a partes iguales entre los pings en estado de pesca de esa marea
pings_ps <- CV_NV[LE_MET4 == "PS" & SI_SPCA >= 0.1 & SI_SPCA <= 1.6]
pings_ps[, n_pings := .N, by = FT_REF]

res <- 0.05
pings_ps[, lon_cel := floor(SI_LONG / res) * res + res / 2]
pings_ps[, lat_cel := floor(SI_LATI / res) * res + res / 2]

kg_marea <- NV_ps[, .(kg = sum(TOTAL_KILOS)), by = .(FT_REF, NOMBRE_ESPECIE, tipo)]

pings_kg <- merge(pings_ps[, .(FT_REF, ANYO, MES = month(SI_TIMESTAMP), lon_cel, lat_cel, n_pings)],
                  kg_marea, by = "FT_REF", allow.cartesian = TRUE)
pings_kg[, kg_ping := kg / n_pings]

# Comprobación: kg repartidos frente a kg vendidos
# (la diferencia son mareas sin ningún ping en estado de pesca)
c(vendidos = sum(NV_ps$TOTAL_KILOS), repartidos = sum(pings_kg$kg_ping))

captura_celda <- pings_kg[, .(kg = sum(kg_ping)),
                          by = .(lon_cel, lat_cel, ANYO, NOMBRE_ESPECIE, tipo)]

# --- 6. Mapas de captura por especie -----------------------------------------
# scale = "large" (1:10 M) es la más fina; requiere rnaturalearthhires
costa <- ne_countries(scale = "large", country = c("Spain", "Portugal"),
                      returnclass = "sf")

lim_lon <- range(captura_celda$lon_cel) + c(-0.1, 0.1)
lim_lat <- range(captura_celda$lat_cel) + c(-0.1, 0.1)

# Cambia la especie y vuelve a correr el bloque
especie <- "BOQUERON"

p_especie <- ggplot() +
  geom_tile(data = captura_celda[NOMBRE_ESPECIE == especie],
            aes(lon_cel, lat_cel, fill = kg),
            width = res, height = res) +
  geom_sf(data = costa, fill = "grey85", colour = "grey50") +
  scale_fill_viridis_c(trans = "log10", name = "kg") +
  facet_wrap(~ ANYO) +
  coord_sf(xlim = lim_lon, ylim = lim_lat) +
  labs(title = paste("Cerco -", especie), x = NULL, y = NULL) +
  theme_bw()
p_especie

ggsave(paste0("figs/cerco_", especie, ".png"), p_especie, width = 10, height = 8, dpi = 200)

# --- 7. Proporción de acompañantes por celda ---------------------------------
prop_celda <- captura_celda[, .(kg_total = sum(kg),
                                kg_acomp = sum(kg[tipo == "acompañante"])),
                            by = .(lon_cel, lat_cel, ANYO)]
prop_celda[, pct_acomp := 100 * kg_acomp / kg_total]

p_prop <- ggplot() +
  geom_tile(data = prop_celda, aes(lon_cel, lat_cel, fill = pct_acomp),
            width = res, height = res) +
  geom_sf(data = costa, fill = "grey85", colour = "grey50") +
  scale_fill_viridis_c(name = "% acompañantes", limits = c(0, 100)) +
  facet_wrap(~ ANYO) +
  coord_sf(xlim = lim_lon, ylim = lim_lat) +
  labs(title = "Cerco - % de especies acompañantes (kg)", x = NULL, y = NULL) +
  theme_bw()
p_prop

ggsave("figs/cerco_pct_acompanantes.png", p_prop, width = 10, height = 8, dpi = 200)

# --- 8. Serie mensual de las acompañantes ------------------------------------
serie <- NV_ps[, .(kg = sum(TOTAL_KILOS)), by = .(ANYO, MES, NOMBRE_ESPECIE, tipo)]
serie[, pct := 100 * kg / sum(kg), by = .(ANYO, MES)]
serie[, fecha := as.Date(paste(ANYO, MES, 1, sep = "-"))]

ggplot(serie[tipo == "acompañante"], aes(fecha, pct, colour = NOMBRE_ESPECIE)) +
  geom_line() +
  geom_point(size = 1) +
  labs(x = NULL, y = "% de la captura mensual (kg)", colour = "Especie") +
  theme_bw()

