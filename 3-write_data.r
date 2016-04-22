source('2-load_data.r')

swm <- subset(d, d$DEPARTMENT == "SWM Solid Waste Management")
write.table(swm,
						'311-Public-Data-Extract-2015-swm-tab.txt',
						sep='\t',
						row.names = FALSE
						)

d <- subset(d, d$DEPARTMENT != "SWM Solid Waste Management")
write.table(d,
						'311-Public-Data-Extract-2015-tab.txt', 
						sep='\t',
						row.names = FALSE
						)
