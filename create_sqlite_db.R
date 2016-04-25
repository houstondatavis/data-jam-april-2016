library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(ggthemes)
library(ggmap)
library(RSQLite)

# Set the Working to directory to your filepath leading to
# data-jam-april-2016 directory with raw data
setwd(paste0("C:/Users/",
"User_Name/", "data-jam-april-2016"))

public_data_mhi_swm <-
  read.delim2("311-Public-Data-Extract-2015-swm-tab-mhhi.txt",
              stringsAsFactors = FALSE
              # , row.names = NULL,
  )

public_data_mhi <-
  read.delim2("311-Public-Data-Extract-2015-tab-mhhi.txt",
              stringsAsFactors = FALSE
              # , row.names = NULL,
  )

df <- rbind(public_data_mhi, public_data_mhi_swm)
rm(public_data_mhi, public_data_mhi_swm)

df <- 
  mutate_each(df, 
            funs(as.numeric), 
            LATITUDE, LONGITUDE, 
            OVERDUE) %>%
  mutate_each(funs(ymd_hms(., tz = "UTC")),
              SR.CREATE.DATE,
              DUE.DATE,
              DATE.CLOSED
              )

my_db <- 
  src_sqlite("shiny/public_data.sqlite3", create = T)

df_sqlite <- 
  copy_to(my_db, df, temporary = FALSE, indexes = list("CASE.NUMBER"))
