### R Script create_sqlite_db.R must be run prior to running app.R

library(dplyr)
library(tidyr)
library(ggplot2)
library(lubridate)
library(ggthemes)
library(ggmap)
library(RSQLite)

source("helper.R")

options(scipen = 2000)
server <- function(input, output) {
  
  map_react <-
    reactive(#input$button_map, 
      {
      zoom1 <- input$zoom_id
      map <- get_map(location = 'Houston', zoom = zoom1)
      map
    })
  
  my_theme <- 
    theme(
      legend.position = c(0.9, 0.9),
      legend.title = element_text(face ="italic", size = 12),
      axis.title = element_text(face = "bold", size = 14)
    )
  output$plot <- renderPlot({
    ggplot(neigh_sr_type, aes(NEIGHBORHOOD, count, label = SR.TYPE)) +
      geom_point(alpha = 0.7, col = "darkblue") +
      # theme_tufte() + 
      geom_text(check_overlap = TRUE) +
      scale_y_continuous(limits = c(0, 1400)) +
      my_theme +
      theme(axis.text.x=element_text(angle=-90)) +
      ggtitle("Calls by Neighborhood")
  })
  
  output$plot2 <- renderPlot({
    ggplot(neigh_income, aes(Frequency_count, Median_HHI_mean)) +
      geom_point(col = "darkblue") + 
      geom_smooth(method = "lm") +
      my_theme + ggtitle("Income Over Counts by Neighborhood") +
      xlab("Count of Tickets per Neighborhoods")
      })
  
  output$plot3 <- renderPlot({
    ggplot(neigh_income, aes(Median_HHI_mean, OVERDUE_mean)) +
      geom_point(col = 
                   "darkblue") + 
      geom_smooth(method = "lm") +
      my_theme + ggtitle("Overdue Over Income by Neighborhood")
  })
  
  output$brush_df <- renderPrint({
    req(input$plot_brush)
    df <- 
      neigh_sr_type
    brush_df <- brushedPoints(df,
                              input$plot_brush)

#     brush_ls <- list(brush_df
#                      )
    return(brush_df)
  })
  
  output$brush_df2 <- renderPrint({
    req(input$plot_brush2)
    df <-  
      neigh_income
    brush_df <- brushedPoints(df,
                              input$plot_brush2)
    
    income_lm <- lm(data = neigh_income, Median_HHI_mean ~ Frequency_count, na.action = na.exclude)
    
    brush_ls <- list(brush_df = brush_df,
                     lm_coeff = summary(income_lm)$coefficients,
                     r_sq_adj = summary(income_lm)$adj.r.squared
    )
    return(brush_ls)
    
  })
  
  output$brush_df3 <- renderPrint({
    req(input$plot_brush3)
    df <-  
      neigh_income
    
    brush_df <-
      brushedPoints(df,
                    input$plot_brush3)
    
    income_lm <- lm(data = neigh_income,
                    OVERDUE_mean ~ Median_HHI_mean, 
                    na.action = na.exclude)
    
    brush_ls <- list(brush_df = brush_df,
                     lm_coeff = summary(income_lm)$coefficients,
                     r_sq = summary(income_lm)$adj.r.squared
    )
    return(brush_ls)
    
  })
  
  ranges <- reactiveValues(x = NULL, y = NULL)
  
  output$g_map <- renderPlot({
  ggmap(map_react()) + geom_point(data = neigh_income,
                          aes(x = LONGITUDE_mean, 
                              y = LATITUDE_mean, size = Frequency_count,
                              alpha = Median_HHI_mean)) +
      coord_cartesian(xlim = ranges$x, ylim = ranges$y) +
      ggtitle("Income and Frequency by Neighborhood")
  })
  
  observeEvent(input$plot1_dblclick, {
    brush <- input$map1_brush
    if (!is.null(brush)) {
      ranges$x <- c(brush$xmin, brush$xmax)
      ranges$y <- c(brush$ymin, brush$ymax)
      
    } else {
      ranges$x <- NULL
      ranges$y <- NULL
    }
  })
  
  output$g_map2 <- renderPlot({
  ggmap(map_react()) + geom_point(data = neigh_sr_type,
                          aes(x = LONGITUDE_mean, 
                              y = LATITUDE_mean, 
                              col = SR.TYPE, size = count)) +
      ggtitle("Greatest Frequency per Type by Neighborhood")
  })
  
}

ui <- fluidPage(
  # sidebarLayout(
    # sidebarPanel(
    # ),
    # mainPanel(
      plotOutput("plot",
      brush = brushOpts(
        id = "plot_brush")
     ),
     verbatimTextOutput("brush_df"),
     plotOutput("plot2",
                brush = brushOpts(
                  id = "plot_brush2")),
     verbatimTextOutput("brush_df2"),
     plotOutput("plot3",
                brush = brushOpts(
                  id = "plot_brush3")),
     verbatimTextOutput("brush_df3"),
     sliderInput("zoom_id", label = "Select Initial Map Zooming", 
                 min = 10, max = 20, value = 11, step = 1),
     # actionButton("button_map", "Size Map"),
     h3("Interactive Map"),
     p("Brush and Double Click to Zoom in Further"),
     plotOutput("g_map",
                dblclick = "plot1_dblclick",
                brush = brushOpts(
                  id = "map1_brush",
                  resetOnNew = TRUE)),
     h3("Static Map"),
     plotOutput("g_map2")
      # )
  )
# )

shinyApp(ui = ui, server = server)