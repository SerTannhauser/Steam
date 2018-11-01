#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(rsconnect)
rsconnect::setAccountInfo(name='tannhauser',
                          token='8EBE8D030DB4274529B410624E2C7181',
                          secret='roTf9ebUhzIuwo6+3aVJ04n9yKXw8rn1havIhLJ0')
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(tidyverse)
library(lubridate)
library(imputeTS)
library(gtools)
library(RColorBrewer)
library(ggthemes)
library(viridis)
library(datasets)
library(Hmisc)
library(DT)
library(gridExtra)
library(plotly)

function(input, output, session) {
  output$res <- renderText({
    req(input$sidebarItemExpanded)
    paste("Expanded menuItem:", input$sidebarItemExpanded)
  })
  
  #### Dashboard
  
  output$menu <- renderMenu({
    sidebarMenu(
      id = "tabs",
      menuItem("Overview", tabName = "overview", icon = icon("info")),
      menuItem("Data", tabName = "data", icon = icon("dollar")),
      menuItem("Rated Games", tabName = "rating", icon = icon("cloud")),
      menuItem("Genres", tabName = "genres", icon = icon("align-justify")),
      menuItem("Recommendations", tabName = "recommender", icon = icon("font-awesome")),
      menuItem("Future Development", tabName = "future", icon = icon("cog"))
    )
  })
  
  #### Rated Games
  
  load("steam4.rdata")
  
  genre <- c('Action','Adventure','Casual','Indie','MMO','Racing','RPG','Simulation','Sports','Strategy')
  
  full_games <- data.frame(steam4 %>%
                             dplyr::filter(., early_access == "False") %>% 
                             dplyr::select(., app_name, developer, date, genres, price, metascore, id))
  
  game_score <- data.frame(full_games %>% 
                             dplyr::filter(., metascore != "NA") %>% 
                             dplyr::filter(., id != "NA") %>% 
                             dplyr::filter(., price != "") %>% 
                             dplyr::filter(., developer != "Fabraz") %>% 
                             dplyr::mutate(., price = ifelse(grepl('free', price), '0.00', price)) %>% 
                             dplyr::mutate(., price = ifelse(grepl('free to play', price), '0.00', price)) %>% 
                             dplyr::mutate(., price = ifelse(grepl('170.65', price), '19.99', price)) %>% 
                             dplyr::mutate(., price = ifelse(grepl('239.72', price), '23.97', price)) %>% 
                             dplyr::mutate(., price = ifelse(grepl('129.99', price), '4.99', price)) %>% 
                             dplyr::mutate(., price = ifelse(grepl('102.93', price), '0.00', price)) %>% 
                             dplyr::mutate(., price = ifelse(grepl('89.99', price), '29.99', price)) %>% 
                             dplyr::mutate(price = as.numeric(as.character(price))) %>% 
                             dplyr::mutate(date = as.Date(date)) %>% 
                             dplyr::mutate(metascore = as.numeric(metascore)) %>% 
                             dplyr::mutate(genres = as.character(genres)) %>% 
                             dplyr::arrange(., metascore, price) %>% 
                             dplyr::select(., app_name, developer, date, genres, price, metascore))
  
  output$games_price <- renderPlot({
    game_score %>% 
      ggplot(aes(x = date, y = price, color = metascore)) + 
      geom_point() +
      theme_fivethirtyeight() + 
      scale_color_gradient() +
      xlab("Date") + ylab("Price") +
      theme(legend.position= 'None') +
      geom_smooth(method = 'lm', color = "red") +
      ggtitle("Current Game Prices by Release Date") +
      xlab("Date") + ylab("Price (USD)")
  })
  
  output$games_meta <- renderPlot({
    game_score %>% 
      ggplot(aes(x = date, y = metascore, color = price)) + 
      geom_point() +
      theme_fivethirtyeight() + 
      scale_color_gradient() +
      xlab("Date") + ylab("Metascore") +
      theme(legend.position= 'None') +
      geom_smooth(method = 'lm', color = "red") +
      ggtitle("Current Game Metascores by Release Date") +
      xlab("Date") + ylab("Metascores")
  })
  
  output$games_pricescore <- renderPlot({
    game_score %>%
      ggplot(aes(x = price, y = metascore, color = metascore)) +
      geom_point() +
      theme_fivethirtyeight() + 
      scale_color_gradient() +
      xlab("Price USD") + ylab("Metascore") +
      theme(legend.position= 'None') +
      geom_smooth(method = 'lm', color = "red") +
      ggtitle("Metascore and Prices of Games") +
      xlab("Price (USD)") + ylab("Metascores")
  })
  
  #### Basic Data
  
  output$games_list <- renderDataTable({
    DT::datatable(game_score, options = list(pageLength = 10))
  })
  
  output$plot_price <- renderPlot({
    game_score %>% 
      ggplot(aes(x = price)) +
      geom_line(stat="bin", binwidth = 1) +
      theme_fivethirtyeight()
  })
  
  output$plot_meta <- renderPlot({
    game_score %>% 
      ggplot(aes(x = metascore)) +
      geom_line(stat="bin", binwidth = 1) +
      theme_fivethirtyeight()
  })
  
  #### Genres
  
  selectInput <- reactive ({
    switch(input$tags,
           "Action" = 'Action',
           "Adventure" = 'Adventure',
           "Casual" = 'Casual',
           "Indie" = 'Indie',
           "MMO" = 'Massively Multiplayer',
           "Racing" = 'Racing',
           "RPG" = 'RPG',
           "Simulation" = 'Simulation',
           "Sports" = 'Sports',
           "Strategy" = 'Strategy')
  })
  
  output$plot_tag <- renderPlot({
    steam_tag <- data.frame(game_score %>% 
                              dplyr::filter(., grepl(input$tags, genres)))
  
    ggplot(steam_tag, aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      geom_smooth(method = 'lm', se = FALSE, color = "red") +
      xlab("Price USD") + ylab("Metascore")
  })
  
  #### Game Recommendations
  
  selectInput <- reactive ({
    switch(input$reco1,
           "Action" = 'Action',
           "Adventure" = 'Adventure',
           "Casual" = 'Casual',
           "Indie" = 'Indie',
           "MMO" = 'Massively Multiplayer',
           "Racing" = 'Racing',
           "RPG" = 'RPG',
           "Simulation" = 'Simulation',
           "Sports" = 'Sports',
           "Strategy" = 'Strategy')
  })
  
  selectInput <- reactive({
    switch(input$reco2,
           "Action" = 'Action',
           "Adventure" = 'Adventure',
           "Casual" = 'Casual',
           "Indie" = 'Indie',
           "MMO" = 'Massively Multiplayer',
           "Racing" = 'Racing',
           "RPG" = 'RPG',
           "Simulation" = 'Simulation',
           "Sports" = 'Sports',
           "Strategy" = 'Strategy')
  })
  
  output$table_tag <- renderDataTable({
    steam_tag <- data.frame(game_score %>% 
                              dplyr::filter(., grepl(input$reco1, genres)) %>%
                              dplyr::filter(., price < input$cost ) %>% 
                              dplyr::arrange(., -metascore))
    
    if (input$reco1 == 'All' & input$reco2 == 'None')
      steam_tag <- data.frame(game_score %>% 
                                dplyr::filter(., price < input$cost ) %>% 
                                dplyr::arrange(., -metascore))
    
    if (input$reco2 != 'None')
      steam_tag <- data.frame(game_score %>% 
                                dplyr::filter(., grepl(input$reco1, genres)) %>% 
                                dplyr::filter(., grepl(input$reco2, genres)) %>%
                                dplyr::filter(., price < input$cost ) %>% 
                                dplyr::arrange(., -metascore))
    
    DT::datatable(steam_tag, options = list(pageLength = 5))
  })
  
  #### Overall
    
  output$genre_all <- renderPlot({
    steam_action <- data.frame(game_score %>%
                                 dplyr::filter(., grepl('Action', genres)))
    steam_adventure <- data.frame(game_score %>%
                                    dplyr::filter(., grepl('Adventure', genres)))
    steam_casual <- data.frame(game_score %>%
                                 dplyr::filter(., grepl('Casual', genres)))
    steam_indie <- data.frame(game_score %>%
                                dplyr::filter(., grepl('Indie', genres)))
    steam_mmo <- data.frame(game_score %>%
                              dplyr::filter(., grepl('Massively Multiplayer', genres)))
    steam_racing <- data.frame(game_score %>%
                                 dplyr::filter(., grepl('Racing', genres)))
    steam_rpg <- data.frame(game_score %>%
                              dplyr::filter(., grepl('RPG', genres)))
    steam_simulation <- data.frame(game_score %>%
                                     dplyr::filter(., grepl('Simulation', genres)))
    steam_sports <- data.frame(game_score %>%
                                 dplyr::filter(., grepl('Sports', genres)))
    steam_strategy <- data.frame(game_score %>%
                                   dplyr::filter(., grepl('Strategy', genres)))
    p1 <- steam_action %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Action') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p2 <- steam_adventure %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p3 <- steam_casual %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Casual') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p4 <- steam_indie %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Indie') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p5 <- steam_mmo %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='MMO') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p6 <- steam_racing %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Racing') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p7 <- steam_rpg %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='RPG') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p8 <- steam_simulation %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Simulation') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p9 <- steam_sports %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Sports') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    p10 <- steam_strategy %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Strategy') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
    grid.arrange(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, ncol=5)
  })
}