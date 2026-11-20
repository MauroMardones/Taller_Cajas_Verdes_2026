# Taller: esfuerzo pesquero con cajas verdes y notas de venta en R

Material del taller de una mañana sobre el flujo de trabajo en R para calcular esfuerzo pesquero a partir de **cajas verdes** (VMS GPS-GPRS) y **notas de venta** (primera venta), con los mismos scripts que se usan con los datos reales del Golfo de Cádiz.

Instituto Español de Oceanografía (IEO-CSIC), Centro Oceanográfico de Cádiz.

> **Los datos del taller son simulados y no están en el repositorio.** Cada participante los genera con `data/simular_datos.R`, con el mismo formato que los ficheros de la Junta de Andalucía. Ningún barco, identificador, posición ni venta es real. Los datos reales son confidenciales y no se distribuyen.

## Requisitos

- R ≥ 4.1 y RStudio
- Paquetes:

```r
install.packages(c("data.table", "fst", "tidyverse", "lubridate",
                   "geosphere", "readxl", "writexl", "rmarkdown"))
```

## Cómo empezar

1. Clona el repositorio y abre `Taller_Cajas_Verdes_2026.Rproj`.
2. Genera los datos simulados (~5 min, ~140 MB en `data/raw/`):

```r
source("data/simular_datos.R")
```

3. Corre los scripts en orden. El 01 y el 02 en la misma sesión: el 02 usa `CV_all` en memoria.

```r
source("R/01_load_CV.R")      # lectura y recorte espacial
source("R/02_format_CV.R")    # CFR, timestamp, velocidad, rumbo, marea (FT_REF)
source("R/03_join_CV_NV.R")   # notas de venta, arte dominante, LE_MET4
source("R/04_effort_grid.R")  # estado de pesca, grilla 0.05°, C-square, horas de pesca
```

Cada script guarda su salida en `outputs/` (`.fst`) y el siguiente la lee.

| Script | Salida |
|---|---|
| 01 | `outputs/CV_2021_2024_ZE.fst` |
| 02 | `outputs/CV_2021_2024_ZE_fmt.fst` (y `.rds`) |
| 03 | `outputs/CV_NV_2021_2024_ZE.fst` |
| 04 | `outputs/esfuerzo_2021_2024.fst` |

## Estructura

```
Taller_Cajas_Verdes_2026/
├── Taller_Cajas_Verdes_2026.Rproj
├── README.md
├── LICENSE
├── data/
│   ├── simular_datos.R          # genera los datos simulados
│   ├── flota_simulada.csv       # (generado) barcos simulados y su arte
│   └── raw/                     # (generado) no se versiona
│       ├── cajas_verdes/Resultado_2_CAJAS_NUEVAS_<año>.csv
│       └── notas_venta/NV <año>.xlsx
├── R/
│   ├── 01_load_CV.R
│   ├── 02_format_CV.R
│   ├── 03_join_CV_NV.R
│   └── 04_effort_grid.R
├── ejercicios/
│   └── soluciones/
├── slides/taller.Rmd            # ioslides
├── outputs/                     # (generado) no se versiona
└── figs/                        # (generado) no se versiona
```

## Datos simulados

| | Cajas verdes | Notas de venta |
|---|---|---|
| Formato | CSV `;`, BOM UTF-8, CRLF, `dd/mm/aaaa` | xlsx, una fila por especie y marea |
| Columnas | `FECHA; HORA; CFPO; VELOCIDAD; LATITUD; LONGITUD; RUMBO; ¿EN PUERTO?` | `ID_UDPROD, NOMBRE_UDPROD, FECHAVENTA, FAO, NOMBRE_ESPECIE, ARTE, TOTAL_KILOS, TOTAL_EUROS` |
| Volumen | ~630 000 pings/año | ~5 800 líneas/año |

- 2021–2024, 45 barcos (5 por arte, CFPO inventados 999001–999045), 3 puertos
- 9 artes: DRB, HMD, FPO, GNS, GTR, LLS, LLSX, OTB y PS
- Dos caladeros fijos por barco, a la distancia de la costa propia de cada arte, sobre una línea de costa simplificada
- Intervalo entre pings ~151 s o ~191 s según la caja, con pings perdidos, transmisiones muy seguidas, duplicados exactos, pings con error de GPS fuera de la zona y error de posición de ~10 m
- Velocidad bimodal (pesca / navegación) ajustada a los límites de estado de pesca del script 04
- Días laborables, días de temporal comunes a toda la flota y veda de bivalvos (1 mayo–15 junio, solo para simular)
- Notas de venta por barco y día, con ~5 % de mareas sin nota, ~3 % de notas sin caja verde y algunas mareas con un arte secundario

## Estado de pesca (script 04)

| LE_MET4 | ARTE (notas de venta) | SI_SPCA (nudos) |
|---|---|---|
| DRB | RASTRA | 0.1–1.0 |
| HMD | DRAGAS MECANIZADAS (HIDRÁULICAS...) | 1.5–2.5 |
| FPO | NASAS, TRAMPAS | 0.1–0.3 |
| GNS | REDES DE ENMALLE DE FONDO (CALADAS) | 0.1–2.1 |
| GTR | TRASMALLOS | 0.1–2.1 |
| LLS | PALANGRES CALADOS | 0.1–2.5 |
| LLSX | PALANGRES (SIN ESPECIFICAR) | 0.1–2.5 |
| OTB | ARRASTRE | 2.0–4.5 (preliminar) |
| PS | CERCO | 0.1–1.6 (preliminar) |

## Origen del código

Los scripts `R/01–04` son los del proyecto HUMUH (análisis espacio-temporal del esfuerzo multi-flota en el Golfo de Cádiz), commit `80a0fe4`. Cambios:

- Rutas a `data/raw/`, años 2021–2024 y nombres de salida `*_2021_2024_*`
- 03: `PALANGRES (SIN ESPECIFICAR)` → LLSX; arrastre → OTB y cerco → PS; se mantienen arrastre y cerco en el cálculo
- 04: límites de velocidad de la tabla anterior

## Licencia

Código bajo licencia MIT (ver `LICENSE`).
