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
library(data.table)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  report.shares = reactive({
    
    
    rs = 
      shares %>%
      filter(flip == input$flip) %>%
      filter(us_symbol %in% input$companies)
    
    rs = as.data.table(rs)

    rs$local_date = ifelse(rs$flip=="in->us", rs$us_date, rs$in_date)
    rs$remote_date = ifelse(rs$flip=="in->us", rs$in_date, rs$us_date)
    rs$local_date = as.Date(rs$local_date, origin = date.origin)
    rs$remote_date = as.Date(rs$remote_date, origin = date.origin)
    
    rs$local_open = ifelse(rs$flip=="in->us", rs$us_open, rs$in_open)
    rs$local_close = ifelse(rs$flip=="in->us", rs$us_close, rs$in_close)
    
    rs$remote_open = ifelse(rs$flip=="in->us", rs$in_open, rs$us_open)
    rs$remote_close = ifelse(rs$flip=="in->us", rs$in_close, rs$us_close)

    rs$local_perf = ifelse(rs$flip=="in->us", rs$us_perf, rs$in_perf)
    rs$remote_perf = ifelse(rs$flip=="in->us", rs$in_perf, rs$us_perf)

    rs$avg_local = (rs$local_open + rs$local_close) / 2
    rs$avg_remote = (rs$remote_open + rs$remote_close) / 2
    
    rs = rs[rs$local_date>=as.Date(input$date.range[1])-as.numeric(input$corLen) & rs$local_date<=as.Date(input$date.range[2]),,]
    
    cor.df = data.frame(us_symbol = character(), date = integer(), perf_cor = numeric() )
    
    for(symb in input$companies)
    {

      # calculate corelation
      for (d in as.Date(input$date.range[1]):as.Date(input$date.range[2])) {
        
        corSet = rs[us_symbol==symb & local_date>=d-as.numeric(input$corLen) & local_date<d,.(local_perf, remote_perf),]
        c = cor(corSet$local_perf, corSet$remote_perf, method=input$corMethod)
        cor.df = rbind(cor.df, data.frame(us_symbol=symb, date=d, perf_cor=c))
      }
    }
    cor.df$date = as.Date(cor.df$date, origin = "1970-01-01")
    
    rs = rs %>%
      left_join(cor.df, by=c("us_symbol"="us_symbol", "local_date"="date")) %>%
      filter(rs$local_date>=as.Date(input$date.range[1]) & rs$local_date<=as.Date(input$date.range[2]))

    return (rs)
  })
  
  buying.shares = reactive({
    report.shares() %>%
      filter(remote_perf>as.numeric(input$buying.threshold)/100 & perf_cor>as.numeric(input$corr.threshold) #& cor_10>0.02# & cor_30>=0.10 & cor_20 > 0.5
             )
  })
    
  output$perf.overview.table <- renderTable({
    
    input$refreshBtn
    
    isolate({
      rs = report.shares()
      bs = buying.shares()
  
      df = data.frame(
        name = c("Trading", "Local", "Remote"),
        sum = c(sum(bs$local_perf)*100, sum(rs$local_perf)*100, sum(rs$remote_perf)*100),
        count = c(length(bs$local_perf), length(rs$local_perf), length(rs$remote_perf)),
        mean = c(mean(bs$local_perf)*100, mean(rs$local_perf)*100, mean(rs$remote_perf)*100),
        median = c(median(bs$local_perf)*100, median(rs$local_perf)*100, median(rs$remote_perf)*100),
        sd = c(sd(bs$local_perf)*100, sd(rs$local_perf)*100, sd(rs$remote_perf)*100),
        pos.days = c(sum(bs$local_perf>0)*100/nrow(bs), sum(rs$local_perf>0)*100/nrow(rs), sum(rs$remote_perf>0)*100/nrow(rs)),
        avg.win = c(mean(bs$local_perf[bs$local_perf>0])*100, mean(rs$local_perf[rs$local_perf>0])*100, mean(rs$remote_perf[rs$remote_perf>0])*100),
        avg.lost = c(mean(bs$local_perf[bs$local_perf<=0])*100, mean(rs$local_perf[rs$local_perf<=0])*100, mean(rs$remote_perf[rs$remote_perf<=0])*100)
      )
      colnames(df) = c("Serie", "Sum Perf. (%)", "Count", "Mean Perf. (%)", "Median Perf. (%)", "Std.dev Perf. (%)", "Pos.Days (%)", "Avg. Win pos. Days (%)", "Avg. Loss neg. Days (%)")
      
      return (df)
    })
  })

  output$buying.cumsum.performance.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      bs = buying.shares()
    
      if(nrow(bs)>0)
      {
        t=
          merge(
            data.frame(local_date=as.Date(seq(as.Date(input$date.range[1]), as.Date(input$date.range[2]), "days"))),
            distinct(bs, us_symbol)
          ) %>%
          left_join(bs, by=c("local_date"="local_date", "us_symbol"="us_symbol")) %>%
          arrange(local_date)
          
        
        t$local_perf = ifelse(is.na(t$local_perf), 0, t$local_perf)
        
        # add cumsum per company
        t =
          t %>% 
          arrange(local_date) %>%
          group_by(us_symbol) %>% 
          mutate(company_local_perf_cumsum = cumsum(local_perf)) 
        
        # add total cumsum
        total =
          t %>% 
          group_by(local_date) %>%
          summarize(date_perf=sum(local_perf)) %>%
          arrange(local_date) %>%
          mutate(total_perf_cumsum = cumsum(date_perf)) 
          
        t %>% 
          ggplot(aes(x=local_date)) + 
          geom_area(aes(y=company_local_perf_cumsum, fill=us_symbol)) +
          geom_smooth(data = total, aes(x=local_date, y=total_perf_cumsum), method = "loess")
          
      }
    })
  })
  
    
  output$buying.boxplot.plot <- renderPlot({
    
    # generate bins based on input$bins from ui.R
    rs = report.shares()
    bs = buying.shares()
    
    perf.df = data.frame(name=character(),perf=numeric())
    
    perf.df = rbind(perf.df, rs %>% mutate(name="Local Perf.") %>% select(name, perf=local_perf))
    perf.df = rbind(perf.df, rs %>% mutate(name="Remote Perf.") %>% select(name, perf=remote_perf))
    perf.df = rbind(perf.df, bs %>% mutate(name="Trading Perf.") %>% select(name, perf=local_perf))
    
        
    ggplot(perf.df, aes(x=name, y=perf, fill=name)) + 
      #geom_boxplot(show.legend = T) +
      geom_violin(aes(fill = name), draw_quantiles = c(0.25, 0.5, 0.75), trim = F) +
      #stat_summary(fun.y=mean, colour="darkred", geom="point", shape=18, size=3,show_guide = FALSE)
      scale_y_continuous(labels = scales::percent)    
    
  })
  
  
  output$local.perf.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
    
      # generate bins based on input$bins from ui.R
      rs = report.shares()
      
      ggplot(rs, aes(x=local_date, y=avg_local)) + 
        geom_line(aes(color=us_symbol)) +
        geom_smooth(method="loess")
    })      
  })
  
  output$sliding.cor.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
    
      # generate bins based on input$bins from ui.R
      rs = report.shares()
      
      ggplot(rs, aes(x=local_date, y=perf_cor)) + 
        geom_line(aes(color=us_symbol)) +
        geom_smooth(method="loess") 
      
    })    
  })
  
  output$scatter.perf.plot <- renderPlot({
    
    # generate bins based on input$bins from ui.R
    rs = report.shares()
    
    ggplot(rs, aes(x=remote_perf, y=local_perf)) + 
      geom_point(aes(color=us_symbol)) 
  })
  
  output$corr.boxplot.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      rs = report.shares()
      
      ggplot(rs, aes(y=perf_cor, x=us_symbol)) + 
        geom_boxplot(aes(color=us_symbol))
    })    
  })  
  
  output$perf.cor.table <- renderTable({
    
    input$refreshBtn
    
    isolate({
    
      rs = as.data.table(report.shares())
  
      
      df = data.frame(
        Serie = "Total",
        Pearson = cor(rs$remote_perf, rs$local_perf, method="pearson"),
        Kendall = cor(rs$remote_perf, rs$local_perf, method="kendall"),
        Spearman = cor(rs$remote_perf, rs$local_perf, method="spearman")
      )
      
      for(c in input$companies)
      {
        cc = as.character(c)
        df = rbind(
          df,
          data.frame(
            Serie = cc,
            Pearson = cor(rs[us_symbol==cc]$remote_perf, rs[us_symbol==c]$local_perf, method="pearson"),
            Kendall = cor(rs[us_symbol==cc]$remote_perf, rs[us_symbol==c]$local_perf, method="kendall"),
            Spearman = cor(rs[us_symbol==cc]$remote_perf, rs[us_symbol==c]$local_perf, method="spearman")
          )
        )
        
      }

      return (df)
    })
  })  
})
