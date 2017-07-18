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
  
      actionButton("refreshBtn", "Refresh"),
        
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
      dateRangeInput("date.range", label = h3("Date range"), start = "2016-01-01", end = "2017-05-14"),
      
      # buying threshold
      numericInput("buying.threshold", label = h3("Buying threshold (%)"),  min = -10, max = 10, step=0.1, value=0),
      
      selectInput("corLen", label = h3("Corr-window size(days):"), 
                  choices = list("15" = 15, "30" = 30, "60" = 60, "90" = 90, "120" = 120), 
                  selected = 60),

      selectInput("corMethod", label = h3("Corr method:"), 
            choices = list("Pearson" = "pearson", "Kendall" = "kendall", "Spearman" = "spearman"), 
            selected = "pearson"),
      
      # buying threshold corr
      numericInput("corr.threshold", label = h3("Corr threshold"),  min = -1, max = 1, step=0.05, value=-1)
      

    ),
    
 
    
    # Show a plot of the generated distribution
    mainPanel(
        
      tabsetPanel(
        tabPanel("Day Trading",
          tableOutput("perf.overview.table"),
          plotOutput("buying.cumsum.performance.plot"),
          plotOutput("sliding.cor.plot"),
          tableOutput("perf.cor.table"),
          plotOutput("corr.boxplot.plot"),
          plotOutput("buying.boxplot.plot"),
          tableOutput("trading.perf.perf.cor.table"),
          plotOutput("cor.trade_perf.scatter.plot")
          #plotOutput("buying.boxplot.plot"),
          #plotOutput("pos.trade.cumsum.plot"),
        ),
        tabPanel("Stock Prices",
          plotOutput("us.stock.price.perf.plot"),
          plotOutput("in.stock.price.perf.plot"),
          plotOutput("stock.price.scatter.plot"),
          tableOutput("stock.price.cor.table")    
        )      
      )
    )
  )
))
