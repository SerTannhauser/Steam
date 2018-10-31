#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)

dashboardPage(
  #### Header
  dashboardHeader(title = "Steam Games"),
  
  #### Sidebar
  dashboardSidebar(
    sidebarMenuOutput("menu"),
    textOutput("res")
  ),
  
  #### Dashboard Body
  dashboardBody(
    tabItems(
      tabItem(tabName = "overview", titlePanel("Overview"),
              tabsetPanel(type = "tabs",
                          tabPanel("Introduction",
                                   img(src="http://img.photobucket.com/albums/v669/5CN/steam_zpsnq2rcxxt.png", width = "60%"),
                                   br(),
                                   br(),
                                   p(paste("Steam is a digital distribution platform initially released in 2003 by Valve Corporation as a means of purchasing and playing video games")),
                                   p(tags$ul(
                                     tags$li("Estimated 291 million registered accounts"),
                                     tags$li("All-time peak of 18,537,490 users (January 14, 2018)."),
                                     tags$li("$4.3 billion in revenue (2017)."),
                                     tags$li("Accounted for 18% of PC game sales.")
                                   ))),
                          tabPanel("Data Scraped",
                                   sidebarLayout(
                                     sidebarPanel(img(src="http://img.photobucket.com/albums/v669/5CN/steam2_zpsfjoflmcb.png?t=1540858995", width = "95%")),
                                     mainPanel(p(paste("Data Scraped:")),
                                               p(tags$ul(
                                                 tags$li("Title"),
                                                 tags$li("Developer"),
                                                 tags$li("Publisher"),
                                                 tags$li("Price"),
                                                 tags$li("Release Date"),
                                                 tags$li("Genres"),
                                                 tags$li("Metascore"),
                                                 tags$li("Early Access")))))),
                          tabPanel("Metascore",
                                   img(src="http://img.photobucket.com/albums/v669/5CN/metascore_zpskqczindt.png?t=1540860145"),
                                   br(),
                                   br(),
                                   p(paste("Metascore is the weighed average of critic reviews, assigning more importance (or weight) to some critics and publications based on their quality and stature."))
                          ))),
      tabItem(tabName = "price", titlePanel("Prices"),
              plotOutput(outputId = "price_density")),
      tabItem(tabName = "rating", titlePanel("Rated Games"),
              tabsetPanel(type = "tabs",
                          tabPanel("Game Price",
                                   plotOutput(outputId = "games_price", height = 500)),
                          tabPanel("Metascore Rating",
                                   plotOutput(outputId = "games_meta", height = 500)),
                          tabPanel("Metascore and Price",
                                   plotOutput(outputId = "games_pricescore", height = 500)),
                          tabPanel("Spreadsheet",
                                   DT::dataTableOutput("games_list")))),
      tabItem(tabName = "genres", titlePanel("Genres"),
              tabsetPanel(type = "tabs",
                          tabPanel("Genres",
                                   sidebarLayout(
                                     sidebarPanel(
                                       selectInput(inputId = "tags", label = "Genres:", choices = c('Action','Adventure','Casual','Indie','MMO','Racing','RPG','Simulation','Sports','Strategy')),
                                       helpText("Select Genre")),
                                     mainPanel(
                                       plotOutput(outputId = "plot_tag")
                                     ))),
                          tabPanel("Overall",
                                   plotOutput(outputId = "genre_all")))),
      tabItem(tabName = "future", titlePanel("Future Developments"),
              img(src="http://img.photobucket.com/albums/v669/5CN/age%20checker_zpsqhfeea7f.png?t=1540859351"),
              br(),
              p(tags$ul(
                tags$li("Fix code to scrape Steam games behind age wall."),
                tags$li("Using Steam API to scrape most popular games."),
                tags$li("Determine release price and compare to current price"),
                tags$li("Scrape player reviews to:",
                        tags$ul(
                          tags$li("Determine short- and long-term trends in player reviews."),
                          tags$li("Compare with critic reviews.")
                        )))))
    )
  )
)