
my_db <- 
  src_sqlite("public_data.sqlite3")

df_sqlite <- 
tbl(my_db, "df")
# 
# df <- 
#   df_sqlite %>%
#   collect()

df_closed <-
  df_sqlite %>%
  filter(STATUS == "Closed") %>%
  collect()

df_open <-
  df_sqlite %>%
  filter(STATUS == "Open") %>%
  collect()

neigh_income <-
  group_by(df_closed, NEIGHBORHOOD) %>%
  summarize_each(funs(mean(., na.rm = TRUE), n()), 
                 Median_HHI, OVERDUE, LATITUDE, LONGITUDE) %>%
  select(-LONGITUDE_n, -LATITUDE_n, -OVERDUE_n) %>%
  rename(Frequency_count = Median_HHI_n)

call_type_count <-
  group_by(df_closed, SR.TYPE) %>%
  summarize(n())

neigh_group <- 
  split(df_closed, df_closed$NEIGHBORHOOD)

neigh_group <- 
  lapply(neigh_group, function(x) {
    df <- as.data.frame(x)
    df_group <-
      group_by(df, SR.TYPE) %>%
      summarize(count = n(),
                Median_HHI_mean =
                  mean(Median_HHI),
                OVERDUE_mean = mean(OVERDUE),
                LONGITUDE_mean = mean(LONGITUDE),
                LATITUDE_mean = mean(LATITUDE)) %>%
      ungroup() %>%
      arrange(desc(count))
    df_sub <- df_group[1,]
    df_sub
  })

neigh_sr_type <-
  do.call(rbind, neigh_group) 

  neigh_sr_type <-
  mutate(neigh_sr_type ,
         NEIGHBORHOOD = row.names(neigh_sr_type))
  
  
#   map <- get_map(location = 'Houston', zoom = 10
#                  )
# ggmap(map) + geom_point(data = df_open,
#                         aes(LONGITUDE, LATITUDE,
#                             col = DEPARTMENT), shape = 21,
#                         alpha = 0.5) 
