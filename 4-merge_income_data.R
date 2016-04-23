require(readr)
require(dplyr)
require(maptools)

# load files
d <- read_delim("311-Public-Data-Extract-2015-tab.txt", "\t") %>% mutate(IDX = 1:n())
swm <- read_delim("311-Public-Data-Extract-2015-swm-tab.txt", "\t") %>% mutate(IDX = 1:n())
shp <- readShapeSpatial("income2010/Median_Household_Income_by_Census_Block_Group_2010.shp")

# convert lon/lat to SpatialPoints (need to filter out missing cases)
d_ll <- d %>% filter(!is.na(LONGITUDE)) %>% select(LONGITUDE, LATITUDE, IDX)
d_pts <- SpatialPoints(as.data.frame(select(d_ll, -IDX)))
swm_ll <- swm %>% filter(!is.na(LONGITUDE)) %>% select(LONGITUDE, LATITUDE, IDX)
swm_pts <- SpatialPoints(as.data.frame(select(swm_ll, -IDX)))

# overlay spatialpoint on shapefile
d_overlay <- over(d_pts, shp)
swm_overlay <- over(swm_pts, shp)

# assign matched median income data to original data
d[d_ll$IDX, "Median_HHI"] <- d_overlay$Median_HHI
swm[swm_ll$IDX, "Median_HHI"] <- swm_overlay$Median_HHI

# export
write_delim(d, "311-Public-Data-Extract-2015-tab-mhhi.txt", delim = "\t")
write_delim(swm, "311-Public-Data-Extract-2015-swm-tab-mhhi.txt", delim = "\t")
