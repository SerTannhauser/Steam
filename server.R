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
library(reshape2)
library(viridis)
library(datasets)
library(Hmisc)
library(DT)

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
      menuItem("Prices", tabName = "price", icon = icon("dollar")),
      menuItem("Rated Games", tabName = "rating", icon = icon("cloud")),
      menuItem("Genres", tabName = "genres", icon = icon("align-justify")),
      menuItem("Future Development", tabName = "future", icon = icon("cog"))
    )
  })
  
  #### Rated Games
  
  load("steam4.rdata")
  
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
                             dplyr::arrange(., metascore, price))
  
  output$games_price <- renderPlot({
    game_score %>% 
      ggplot(aes(x = date, y = price, color = metascore)) + 
      geom_point() +
      theme_classic() + 
      scale_color_gradient() +
      xlab("Date") + ylab("Price") +
      theme(legend.position= 'None') +
      geom_smooth(method = 'lm', color = "red") +
      ggtitle("Current Game Prices by Release Date")
  })
  
  output$games_meta <- renderPlot({
    game_score %>% 
      ggplot(aes(x = date, y = metascore, color = price)) + 
      geom_point() +
      theme_classic() + 
      scale_color_gradient() +
      xlab("Date") + ylab("Metascore") +
      theme(legend.position= 'None') +
      geom_smooth(method = 'lm', color = "red") +
      ggtitle("Current Game Metascores by Release Date")
  })
  
  output$games_pricescore <- renderPlot({
    game_score %>%
      ggplot(aes(x = price, y = metascore, color = metascore)) +
      geom_point() +
      theme_classic() + 
      scale_color_gradient() +
      xlab("Price USD") + ylab("Metascore") +
      theme(legend.position= 'None') +
      geom_smooth(method = 'lm', color = "red") +
      ggtitle("Metascore and Prices of Games")
  })
  
  output$games_list <- renderDataTable({
    DT::datatable(game_score, options = list(pageLength = 15))
  })
  
  #### Price
  
  output$price_density <- renderPlot({
    game_score %>% 
      ggplot(aes(x = price, color = metascore)) +
      geom_density()
  })
  
  #### Genres
  
  selectInput <- reactive ({
    switch(input$tags,
           "Action" = 'Action',
           "Adventure" = 'Adventure',
           "Casual" = 'Casual',
           "Indie" = 'Indie',
           "MMO" = 'MMO',
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
      xlab("Price USD") + ylab("Metascore") +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  #### Overall
  
  steam_action <- data.frame(game_score %>%
                               dplyr::filter(., grepl('Action', genres)))
  
  steam_adventure <- data.frame(game_score %>%
                                  dplyr::filter(., grepl('Adventure', genres)))
  
  steam_casual <- data.frame(game_score %>%
                                  dplyr::filter(., grepl('Casual', genres)))
  
  steam_indie <- data.frame(game_score %>%
                                  dplyr::filter(., grepl('Indie', genres)))
  
  steam_mmo <- data.frame(game_score %>%
                               dplyr::filter(., grepl('MMO', genres)))
  
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
  
  output$plot_action <- renderPlot({
    steam_action %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_adventure <- renderPlot({
    steam_adventure %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_casual <- renderPlot({
    steam_casual %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_indie <- renderPlot({
    steam_indie %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_mmo <- renderPlot({
    steam_mmo %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_racing <- renderPlot({
    steam_racing %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_rpg <- renderPlot({
    steam_rpg %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_simulation <- renderPlot({
    steam_simulation %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_sports <- renderPlot({
    steam_sports %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
  
  output$plot_strategy <- renderPlot({
    steam_strategy %>%
      ggplot(aes(x = price, y = metascore, color = price)) + 
      geom_boxplot(alpha=.75,size=.25) +
      geom_jitter(shape = 16, position = position_jitter(0.5), size = 2, alpha = .5) +
      theme_fivethirtyeight() + 
      scale_color_gradientn(colours = viridis::plasma(10)) +
      theme(legend.position= 'None') +
      xlab("Price USD") + ylab("Metascore") + labs(title='Adventure') +
      geom_smooth(method = 'lm', se = FALSE, color = "red")
  })
    
  output$genre_all <- renderPlot({
    p = grid.arrange(plot_action, plot_adventure, plot_casual, plot_indie, plot_mmo, plot_racing, plot_rpg, plot_simulation, plot_sports, plot_strategy, ncol=5)
    print(p)
  })
  
}