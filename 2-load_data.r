require(data.table)
d <- fread(sep = '|',
					 '311-Public-Data-Extract-2015-ready.txt', 
					 header = TRUE,
					 stringsAsFactors = FALSE,
					 drop = c("TRASH DAY", "HEAVY TRASH DAY", "x", "y",
									 	"RECYCLE DAY", "RECYCLE QUAD", "TRASH QUAD",
										"KEY MAP"),
					 data.table = FALSE,
					 na.strings = c("NA", "Unknown"),
					 )


d[which(d[, "NEIGHBORHOOD"] == "BRAESWOOD"), "NEIGHBORHOOD"] <- "BRAESWOOD PLACE"
d[which(d[, "NEIGHBORHOOD"] == "BRIARFOREST AREA"), "NEIGHBORHOOD"] <- "BRIARFOREST"
d[which(d[, "NEIGHBORHOOD"] == "FORT BEND HOUSTON"), "NEIGHBORHOOD"]  <- "FORT BEND / HOUSTON"
d[which(d[, "NEIGHBORHOOD"] == "OST / SOUTH UNION"), "NEIGHBORHOOD"]  <- "GREATER OST / SOUTH UNION"
d[which(d[, "NEIGHBORHOOD"] == "NORTHSIDE VILLAGE"), "NEIGHBORHOOD"]  <- "NEAR NORTHSIDE"
