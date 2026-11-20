# =============================================================================
# simular_datos.R
# Genera datos SIMULADOS con el mismo formato que los ficheros brutos de
# cajas verdes (VMS GPS-GPRS) y notas de venta de la Junta de Andalucía.
#
# Ningún barco, posición, identificador ni venta es real. Las posiciones se
# generan sobre una línea de costa simplificada del Golfo de Cádiz.
#
# Salida:
#   data/raw/cajas_verdes/Resultado_2_CAJAS_NUEVAS_<año>.csv
#   data/raw/notas_venta/NV <año>.xlsx
#
# Ejecutar desde la raíz del proyecto:  source("data/simular_datos.R")
# =============================================================================

library(data.table)
library(writexl)

set.seed(2026)

anyos  <- 2021:2024
dir_cv <- "data/raw/cajas_verdes"
dir_nv <- "data/raw/notas_venta"
dir.create(dir_cv, showWarnings = FALSE, recursive = TRUE)
dir.create(dir_nv, showWarnings = FALSE, recursive = TRUE)

# --- Geometría ---------------------------------------------------------------
# Costa simplificada (aprox.) de Ayamonte a Sanlúcar, solo para simular
costa <- data.table(
  lon = c(-7.45, -7.30, -7.00, -6.85, -6.55, -6.42),
  lat = c(37.20, 37.19, 37.17, 37.12, 36.98, 36.80)
)
lat_costa <- function(lon) approx(costa$lon, costa$lat, xout = lon, rule = 2)$y

km_lat <- 110.57
km_lon <- function(lat) 111.32 * cos(lat * pi / 180)

dist_km <- function(lon1, lat1, lon2, lat2) {
  sqrt(((lon2 - lon1) * km_lon(lat1))^2 + ((lat2 - lat1) * km_lat)^2)
}
rumbo_a <- function(lon1, lat1, lon2, lat2) {
  (atan2((lon2 - lon1) * km_lon(lat1), (lat2 - lat1) * km_lat) * 180 / pi) %% 360
}

puertos <- data.table(
  puerto = c("Isla Cristina", "Punta Umbria", "Sanlucar"),
  lon    = c(-7.33, -6.95, -6.43),
  lat    = c(37.185, 37.163, 36.795)
)

# --- Artes -------------------------------------------------------------------
# Velocidades en nudos; distancias a la costa del caladero en km.
# v_pesca/sd_pesca ajustadas a los límites de estado de pesca del script 04.
artes <- data.table(
  LE_MET4  = c("DRB", "HMD", "FPO", "GNS", "GTR", "LLS", "LLSX", "OTB", "PS"),
  ARTE     = c("RASTRA",
               "DRAGAS MECANIZADAS (HIDR\u00c1ULICAS...)",
               "NASAS",
               "REDES DE ENMALLE DE FONDO (CALADAS)",
               "TRASMALLOS",
               "PALANGRES CALADOS",
               "PALANGRES (SIN ESPECIFICAR)",
               "RED DE ARRASTRE DE FONDO CON PUERTAS",
               "RED DE CERCO CON JARETA"),
  v_pesca  = c(0.6,  2.0,  0.2,  0.9,  0.9,  1.2,  1.0,  3.2,  0.7),
  sd_pesca = c(0.2,  0.25, 0.06, 0.4,  0.4,  0.5,  0.5,  0.4,  0.35),
  giro_sd  = c(10,   10,   40,   30,   30,   25,   25,   5,    45),   # grados entre pings
  p_vuelta = c(0.04, 0.04, 0,    0,    0,    0,    0,    0.01, 0),    # virar 180° (lances rectos)
  p_transito = c(0,  0,    0.06, 0.04, 0.04, 0.03, 0.03, 0,    0.12), # tránsito corto en caladero
  v_nav    = c(7.0,  7.5,  8.0,  8.0,  8.0,  8.5,  8.5,  9.5,  10),
  d_min    = c(0.4,  0.6,  4,    3,    3,    8,    5,    15,   5),
  d_max    = c(2.0,  2.5,  15,   12,   12,   25,   20,   35,   25),
  h_pesca  = c(4,    4,    3,    4,    4,    5,    5,    9,    6),
  hora_sal = c(7,    7,    6,    5,    5,    5,    5,    5,    5),
  radio_km = c(1.5,  1.5,  3,    2.5,  2.5,  4,    4,    8,    6)
)

# --- Especies por arte (kg medios por marea y €/kg) --------------------------
especies <- rbindlist(list(
  data.table(LE_MET4 = "DRB", FAO = c("SVE", "DON"),
             NOMBRE_ESPECIE = c("CHIRLA", "COQUINA"),
             p = c(1, 0.3), kg = c(120, 25), eur_kg = c(4, 9)),
  data.table(LE_MET4 = "HMD", FAO = c("SVE", "DON"),
             NOMBRE_ESPECIE = c("CHIRLA", "COQUINA"),
             p = c(1, 0.2), kg = c(300, 30), eur_kg = c(3.5, 8)),
  data.table(LE_MET4 = "FPO", FAO = c("OCC", "CTC"),
             NOMBRE_ESPECIE = c("PULPO", "SEPIA"),
             p = c(1, 0.3), kg = c(90, 10), eur_kg = c(7, 9)),
  data.table(LE_MET4 = "GNS", FAO = c("SOL", "CTC", "HKE"),
             NOMBRE_ESPECIE = c("LENGUADO", "SEPIA", "MERLUZA"),
             p = c(1, 0.5, 0.4), kg = c(25, 15, 20), eur_kg = c(15, 9, 6)),
  data.table(LE_MET4 = "GTR", FAO = c("CTC", "SOL", "SBG"),
             NOMBRE_ESPECIE = c("SEPIA", "LENGUADO", "DORADA"),
             p = c(1, 0.6, 0.4), kg = c(40, 12, 15), eur_kg = c(9, 15, 12)),
  data.table(LE_MET4 = "LLS", FAO = c("HKE", "COE"),
             NOMBRE_ESPECIE = c("MERLUZA", "CONGRIO"),
             p = c(1, 0.6), kg = c(60, 30), eur_kg = c(7, 5)),
  data.table(LE_MET4 = "LLSX", FAO = c("PAC", "SWA"),
             NOMBRE_ESPECIE = c("BRECA", "SARGO"),
             p = c(1, 0.5), kg = c(40, 15), eur_kg = c(8, 6)),
  data.table(LE_MET4 = "OTB", FAO = c("HKE", "DPS", "CTC"),
             NOMBRE_ESPECIE = c("MERLUZA", "GAMBA BLANCA", "SEPIA"),
             p = c(1, 0.8, 0.5), kg = c(150, 60, 30), eur_kg = c(6, 12, 9)),
  data.table(LE_MET4 = "PS", FAO = c("PIL", "ANE", "MAC"),
             NOMBRE_ESPECIE = c("SARDINA", "BOQUERON", "CABALLA"),
             p = c(1, 0.7, 0.4), kg = c(1500, 800, 300), eur_kg = c(1.2, 3, 0.8))
))

# --- Flota simulada ----------------------------------------------------------
# 5 barcos por arte; CFPO inventados (rango 999xxx), nombres genéricos
n_barcos <- 5
flota <- data.table(LE_MET4 = rep(artes$LE_MET4, each = n_barcos))
flota[, `:=`(
  CFPO          = 999000L + seq_len(.N),
  NOMBRE_UDPROD = sprintf("SIMULADO %02d", seq_len(.N)),
  puerto        = sample(puertos$puerto, .N, replace = TRUE),
  dt_base       = sample(c(151, 191), .N, replace = TRUE, prob = c(0.6, 0.4)),
  p_salida      = runif(.N, 0.30, 0.45)
)]
flota[, VE_REF := paste0("ESP", formatC(CFPO, width = 9, flag = "0"))]

# Dos caladeros fijos por barco
caladeros <- flota[, {
  a  <- artes[LE_MET4 == .BY$LE_MET4]
  p  <- puertos[puerto == .BY$puerto]
  lo <- if (.BY$puerto == "Sanlucar") runif(2, -6.70, -6.47) else
    pmin(pmax(p$lon + runif(2, -0.20, 0.20), -7.42), -6.47)
  d  <- runif(2, a$d_min, a$d_max)
  .(cal = 1:2, lon = lo, lat = lat_costa(lo) - d / km_lat)
}, by = .(CFPO, LE_MET4, puerto)]

# --- Funciones de simulación -------------------------------------------------
siguiente_dt <- function(b) {
  u <- runif(1)
  if (u < 0.02) b * sample(2:6, 1)            # pings perdidos
  else if (u < 0.03) round(runif(1, 10, 40))  # transmisión muy seguida
  else b + sample(-1:1, 1)
}

avanzar <- function(lon, lat, rumbo, v_kn, dt) {
  d <- v_kn * 1.852 * dt / 3600
  c(lon + d * sin(rumbo * pi / 180) / km_lon(lat),
    lat + d * cos(rumbo * pi / 180) / km_lat)
}

sim_marea <- function(barco, fecha) {
  a   <- artes[LE_MET4 == barco$LE_MET4]
  p   <- puertos[puerto == barco$puerto]
  cal <- caladeros[CFPO == barco$CFPO][sample(.N, 1)]

  n_max <- 2000
  t_v <- numeric(n_max); lon_v <- lat_v <- sp_v <- hd_v <- numeric(n_max)
  pu_v <- integer(n_max); k <- 0
  reg <- function(t, lon, lat, sp, hd, pu) {
    k <<- k + 1
    t_v[k] <<- t; lon_v[k] <<- lon; lat_v[k] <<- lat
    sp_v[k] <<- sp; hd_v[k] <<- hd; pu_v[k] <<- pu
  }

  t0  <- as.numeric(as.POSIXct(paste(fecha, "00:00:00"), tz = "UTC")) +
    (a$hora_sal + runif(1, -0.5, 1)) * 3600
  fin <- as.numeric(as.POSIXct(paste(fecha, "23:55:00"), tz = "UTC"))
  t   <- t0 - runif(1, 20, 40) * 60
  lon <- p$lon; lat <- p$lat

  # 1. En puerto antes de salir
  while (t < t0) {
    reg(t, p$lon + rnorm(1, 0, 3e-5), p$lat + rnorm(1, 0, 3e-5),
        abs(rnorm(1, 0, 0.1)), runif(1, 0, 360), 1L)
    t <- t + siguiente_dt(barco$dt_base)
  }

  navegar <- function(lon_d, lat_d) {
    repeat {
      v  <- a$v_nav + rnorm(1, 0, 0.4)
      dt <- siguiente_dt(barco$dt_base)
      if (dist_km(lon, lat, lon_d, lat_d) < v * 1.852 * dt / 3600 || t > fin) break
      hd  <- (rumbo_a(lon, lat, lon_d, lat_d) + rnorm(1, 0, 3)) %% 360
      nxt <- avanzar(lon, lat, hd, v, dt)
      lon <<- nxt[1]; lat <<- min(nxt[2], lat_costa(nxt[1]) - 0.002)
      t   <<- t + dt
      pu  <- as.integer(dist_km(lon, lat, p$lon, p$lat) < 0.3)
      reg(t, lon, lat, v, hd, pu)
    }
    # Último tramo hasta el destino, con el tiempo que corresponde a la distancia
    d <- dist_km(lon, lat, lon_d, lat_d)
    t <<- t + d / (a$v_nav * 1.852) * 3600
    lon <<- lon_d; lat <<- lat_d
    reg(t, lon, lat, a$v_nav, rumbo_a(lon, lat, lon_d, lat_d),
        as.integer(dist_km(lon, lat, p$lon, p$lat) < 0.3))
  }

  # 2. Navegación al caladero
  ang  <- runif(1, 0, 2 * pi); r <- runif(1, 0, a$radio_km / 2)
  lon_c <- cal$lon + r * sin(ang) / km_lon(cal$lat)
  lat_c <- cal$lat + r * cos(ang) / km_lat
  navegar(lon_c, lat_c)

  # 3. Pesca
  t_fin_pesca <- t + (a$h_pesca + runif(1, -1, 1)) * 3600
  hd <- runif(1, 0, 360); transito <- 0
  while (t < t_fin_pesca && t < fin) {
    dt <- siguiente_dt(barco$dt_base)
    if (transito == 0 && runif(1) < a$p_transito) transito <- sample(2:5, 1)
    if (transito > 0) {
      v <- runif(1, 4.5, 6.5); hd <- (hd + rnorm(1, 0, 10)) %% 360
      transito <- transito - 1
    } else {
      v  <- max(0.05, rnorm(1, a$v_pesca, a$sd_pesca))
      hd <- (hd + rnorm(1, 0, a$giro_sd) + if (runif(1) < a$p_vuelta) 180 else 0) %% 360
    }
    if (dist_km(lon, lat, cal$lon, cal$lat) > a$radio_km)
      hd <- (rumbo_a(lon, lat, cal$lon, cal$lat) + rnorm(1, 0, 20)) %% 360
    if (lat > lat_costa(lon) - 0.003) hd <- (180 + rnorm(1, 0, 20)) %% 360
    nxt <- avanzar(lon, lat, hd, v, dt)
    lon <- nxt[1]; lat <- min(nxt[2], lat_costa(nxt[1]) - 0.002)
    t   <- t + dt
    reg(t, lon, lat, v, hd, 0L)
  }

  # 4. Regreso a puerto
  navegar(p$lon, p$lat)

  # 5. En puerto tras la marea
  t_lim <- t + runif(1, 15, 30) * 60
  while (t < t_lim && t < fin) {
    t <- t + siguiente_dt(barco$dt_base)
    reg(t, p$lon + rnorm(1, 0, 3e-5), p$lat + rnorm(1, 0, 3e-5),
        abs(rnorm(1, 0, 0.1)), runif(1, 0, 360), 1L)
  }

  i <- seq_len(k)
  data.table(
    t        = as.POSIXct(t_v[i], origin = "1970-01-01", tz = "UTC"),
    CFPO     = barco$CFPO,
    VELOCIDAD = pmax(0, sp_v[i] + rnorm(k, 0, 0.15)),
    LATITUD  = lat_v[i] + rnorm(k, 0, 1e-4),   # error GPS ~10 m
    LONGITUD = lon_v[i] + rnorm(k, 0, 1.2e-4),
    RUMBO    = (hd_v[i] + rnorm(k, 0, 2)) %% 360,
    EN_PUERTO = pu_v[i]
  )
}

sim_nv <- function(barco, fecha) {
  sp <- especies[LE_MET4 == barco$LE_MET4]
  sp <- sp[runif(.N) < p]
  a  <- artes[LE_MET4 == barco$LE_MET4]
  nv <- sp[, .(FAO, NOMBRE_ESPECIE, ARTE = a$ARTE,
               TOTAL_KILOS = round(rlnorm(.N, log(kg), 0.5), 1),
               precio = eur_kg * exp(rnorm(.N, 0, 0.15)))]
  # Algunas mareas declaran además un arte secundario con poca captura
  if (barco$LE_MET4 %in% c("FPO", "GNS", "GTR") && runif(1) < 0.05) {
    nv <- rbind(nv, data.table(FAO = "MUR", NOMBRE_ESPECIE = "SALMONETE",
                               ARTE = "REDES DE ENMALLE (SIN ESPECIFICAR)",
                               TOTAL_KILOS = round(runif(1, 2, 8), 1), precio = 8))
  }
  nv[, `:=`(TOTAL_EUROS = round(TOTAL_KILOS * precio, 2), precio = NULL)]
  cbind(data.table(ID_UDPROD = barco$VE_REF, NOMBRE_UDPROD = barco$NOMBRE_UDPROD,
                   FECHAVENTA = fecha), nv)
}

# --- Bucle por año -----------------------------------------------------------
for (yr in anyos) {
  message("Simulando ", yr, "...")
  fechas <- seq(as.Date(paste0(yr, "-01-01")), as.Date(paste0(yr, "-12-31")), by = "day")
  laborable <- as.POSIXlt(fechas)$wday %in% 1:5
  temporal  <- runif(length(fechas)) < 0.15          # días de mal tiempo (toda la flota)
  veda_biv  <- format(fechas, "%m-%d") >= "05-01" & format(fechas, "%m-%d") <= "06-15"

  cv_list <- list(); nv_list <- list()
  for (i in seq_len(nrow(flota))) {
    b <- flota[i]
    ok <- laborable & !temporal & runif(length(fechas)) < b$p_salida
    if (b$LE_MET4 %in% c("DRB", "HMD")) ok <- ok & !veda_biv
    for (f in as.character(fechas[ok])) {
      cv_list[[length(cv_list) + 1]] <- sim_marea(b, f)
      if (runif(1) > 0.05)                            # 5% de mareas sin nota de venta
        nv_list[[length(nv_list) + 1]] <- sim_nv(b, as.Date(f))
    }
    # 3% de notas de venta en días sin registro de caja verde
    f_sin_cv <- sample(fechas[laborable & !ok], max(1, round(0.03 * sum(ok))))
    for (f in as.character(f_sin_cv))
      nv_list[[length(nv_list) + 1]] <- sim_nv(b, as.Date(f))
  }

  cv <- rbindlist(cv_list)
  # Duplicados exactos (~1%) y pings con error de GPS fuera de la zona
  cv <- rbind(cv, cv[sample(.N, round(.N * 0.01))])
  basura <- cv[sample(.N, 20)]
  basura[, `:=`(LATITUD = sample(c(0, 45.1), .N, TRUE), LONGITUD = sample(c(0, -2.5), .N, TRUE))]
  cv <- rbind(cv, basura)
  setorder(cv, t, CFPO)

  cv_out <- cv[, .(
    FECHA     = format(t, "%d/%m/%Y"),
    HORA      = format(t, "%H:%M:%S"),
    CFPO,
    VELOCIDAD = round(VELOCIDAD, 2),
    LATITUD   = round(LATITUD, 5),
    LONGITUD  = round(LONGITUD, 5),
    RUMBO     = round(RUMBO, 1),
    EN_PUERTO
  )]
  setnames(cv_out, "EN_PUERTO", "¿EN PUERTO?")
  fwrite(cv_out, file.path(dir_cv, paste0("Resultado_2_CAJAS_NUEVAS_", yr, ".csv")),
         sep = ";", bom = TRUE, eol = "\r\n")

  nv <- rbindlist(nv_list)
  setorder(nv, FECHAVENTA, ID_UDPROD)
  write_xlsx(nv, file.path(dir_nv, paste0("NV ", yr, ".xlsx")))

  message(sprintf("  CV: %s pings | NV: %s líneas", format(nrow(cv_out), big.mark = ".", decimal.mark = ","),
                  format(nrow(nv), big.mark = ".", decimal.mark = ",")))
}

fwrite(flota[, .(VE_REF, CFPO, NOMBRE_UDPROD, LE_MET4, puerto)], "data/flota_simulada.csv")
message("Datos simulados en data/raw/")
