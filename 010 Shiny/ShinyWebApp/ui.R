#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Double listed shares trading evaluation"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(

      
      # stock exchange selection 
      selectInput("flip", label = h3("Stock Exchange"), 
                  choices = list(
                    "NYSE / NASDAQ" = "in->us", 
                    "BSE" = "us->in"), 
                  selected = "in->us"),      
       
       
       # company selection
       checkboxGroupInput("companies", label = h3("Companies"), 
                          choices = list(
                            "ICICI Bank" = "IBN", 
                            "Infosys" = "INFY", 
                            "Vedanta Limited" = "VEDL",
                            "Tata Motors" = "TTM", 
                            "Videocon d2h" = "VDTH", 
                            "Wipro" = "WIT"
                          ),
                          selected = "IBN"),
      # date range
      dateRangeInput("date.range", label = h3("Date range"), start = "2016-01-01", end = "2016-12-31"),
      
      # buying threshold
      numericInput("buying.threshold", label = h3("Buying threshold (%)"),  min = -10, max = 10, step=0.1, value=0),
      
      # day lag min max 
      sliderInput("days.lag", label = h3("Day lag"), min = 0, 
                  max = 5, value = c(0, 5))
    ),
    
 
    
    # Show a plot of the generated distribution
    mainPanel(
       tableOutput("perf.overview.table"),
       plotOutput("buying.boxplot.plot"),
       plotOutput("local.perf.plot"),
       plotOutput("remote.perf.plot")
    )
  )
))
