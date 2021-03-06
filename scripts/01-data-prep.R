# === Data Prep -----------------------------------------------------------
# Alec Robitaille


# Packages ----------------------------------------------------------------
pkgs <- c('data.table', 'rgdal', 'raster')
p <- lapply(pkgs, library, character.only = TRUE)


# Variables ---------------------------------------------------------------
if(interactive()) {
  source('scripts/00-variables.R')
}


# Input -------------------------------------------------------------------
DT <- fread('data/raw-data/FogoCaribou.csv')

lc <- raster('../nl-landcover/output/fogo_lc.tif')


# Date time ---------------------------------------------------------------
DT[, c(datecol, timecol) := .(as.IDate(get(datecol), tz = tz), as.ITime(get(timecol)))]
DT[, 'datetime' := as.POSIXct(paste(get(datecol), get(timecol)), tz)]

# Seasons
DT[between(JDate, winterlow, winterhigh), season := 'winter']
DT[between(JDate, summerlow, summerhigh), season := 'summer']

# Drop individuals 
indianisland <- c('FO2016011', 'FO2017013', 'FO2017001')
diffixrate <- 'FO2016014'
dropind <- c(indianisland, diffixrate)

DT <- DT[!ANIMAL_ID %in% dropind] 


# Project relocations -----------------------------------------------------
DT[, (projCols) := as.data.table(project(cbind(get(xcol), get(ycol)), utm21N))]



# Land cover prep ---------------------------------------------------------
water <- 7
open <- c(1, 6, 9)
forest <- c(2, 3, 4, 5)
lichen <- 8

mlc <- mask(lc, lc == water, maskvalue = TRUE)

rcl <- matrix(c(
  open,
  forest,
  lichen,
  rep(1, length(open)),
  rep(2, length(forest)),
  rep(3, length(lichen))
),
ncol = 2)
rclnms <- list(open = 1, forest = 2, lichen = 3)

reclass <- reclassify(mlc, rcl, include.lowest = TRUE)



# Sample land cover -------------------------------------------------------
## Landcover sample
DT[, (lccol) := extract(reclass, matrix(c(EASTING, NORTHING), ncol = 2))]



# Sub data ----------------------------------------------------------------
## 2017 summer and 2018 winter
sub <- DT[(Year == 2017 & JDate > 110) |
            Year == 2018 |
            (Year == 2019 & JDate < 87)]

subseasons <- sub[!is.na(season)]


# Output ------------------------------------------------------------------
saveRDS(sub, 'data/derived-data/01-sub-fogo-caribou.Rds')
saveRDS(subseasons, 'data/derived-data/01-sub-seasons-fogo-caribou.Rds')
saveRDS(reclass, 'data/derived-data/01-reclass-lc.Rds')