#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(dplyr)
library(shiny)
library(ggplot2)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  report.shares = reactive({
    rs = 
      shares %>%
      filter(flip == input$flip) %>%
      filter(us_symbol %in% input$companies) %>%
      filter(days_lag>=input$days.lag[1] & days_lag<=input$days.lag[2])
    
    rs$local_date = ifelse(rs$flip=="in->us", rs$us_date, rs$in_date)
    rs$remote_date = ifelse(rs$flip=="in->us", rs$in_date, rs$us_date)
    rs$local_date = as.Date(rs$local_date, origin = date.origin)
    rs$remote_date = as.Date(rs$remote_date, origin = date.origin)
    #rs$local_date_form = format(rs$local_date, "%m/%d")
    #rs$remote_date_form = format(rs$remote_date, "%m/%d")
    
    
    rs$local_perf = ifelse(rs$flip=="in->us", rs$us_perf, rs$in_perf)
    rs$remote_perf = ifelse(rs$flip=="in->us", rs$in_perf, rs$us_perf)
    
    rs = rs %>%
      filter(rs$local_date>=as.Date(input$date.range[1]) & rs$local_date<=as.Date(input$date.range[2]))

    return (rs)
  })
  
  buying.shares = reactive({
    report.shares() %>%
      filter(remote_perf>=as.numeric(input$buying.threshold)/100)
  })
    
  output$perf.overview.table <- renderDataTable({
    rs = report.shares()
    bs = buying.shares()

    df = data.frame(
      name = c("Buying", "Local", "Remote"),
      sum = c(sum(bs$local_perf), sum(rs$local_perf), sum(rs$remote_perf)),
      count = c(length(bs$local_perf), length(rs$local_perf), length(rs$remote_perf)),
      mean = c(mean(bs$local_perf), mean(rs$local_perf), mean(rs$remote_perf)),
      median = c(median(bs$local_perf), median(rs$local_perf), median(rs$remote_perf)),
      sd = c(sd(bs$local_perf), sd(rs$local_perf), sd(rs$remote_perf))
    )
    colnames(df) = c("Data", "Sum", "Count", "Mean", "Median", "Std.dev")
    
    return (df)
  })
  
  output$buying.boxplot.plot <- renderPlot({
    
    # generate bins based on input$bins from ui.R
    rs = report.shares()
    bs = buying.shares()
    
    perf.df = data.frame(name=character(),perf=numeric())
    
    perf.df = rbind(perf.df, rs %>% mutate(name="local perf") %>% select(name, perf=local_perf))
    perf.df = rbind(perf.df, rs %>% mutate(name="remote perf") %>% select(name, perf=remote_perf))
    perf.df = rbind(perf.df, bs %>% mutate(name="buying perf") %>% select(name, perf=local_perf))
    
        
    ggplot(perf.df, aes(x=name, y=perf, fill=name)) + 
      geom_boxplot(show.legend = T) +
      stat_summary(fun.y=mean, colour="darkred", geom="point", 
                   shape=18, size=3,show_guide = FALSE)
    
  })
  
  
  output$local.perf.plot <- renderPlot({
    
    # generate bins based on input$bins from ui.R
    rs = report.shares()
    
    ggplot(rs, aes(x=local_date, y=local_perf)) + geom_line(aes(color=us_symbol))
      
  })
  
  output$remote.perf.plot <- renderPlot({
    
    # generate bins based on input$bins from ui.R
    rs = report.shares()
    
    ggplot(rs, aes(x=remote_date, y=remote_perf)) + geom_line(aes(color=us_symbol))
    
  })
})
