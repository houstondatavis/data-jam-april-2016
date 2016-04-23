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


d[which(d[, "NEIGHBORHOOD"] == "BRAESWOOD"), ] <- "BRAESWOOD PLACE"
d[which(d[, "NEIGHBORHOOD"] == "FORT BEND HOUSTON"), ]  <- "FORT BEND / HOUSTON"
d[which(d[, "NEIGHBORHOOD"] == "OST / SOUTH UNION"), ]  <- "GREATER OST / SOUTH UNION"
