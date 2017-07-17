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
        #corSet$local_perf = ifelse(corSet$local_perf>0, +1, -1)
        #corSet$remote_perf = ifelse(corSet$remote_perf>0, 1, -1)
        c = cor(corSet$local_perf, corSet$remote_perf, method=input$corMethod)
        cor.df = rbind(cor.df, data.frame(us_symbol=symb, date=d, perf_cor=c))
      }
    }
    cor.df$date = as.Date(cor.df$date, origin = "1970-01-01")
    
    rs = rs %>%
      left_join(cor.df, by=c("us_symbol"="us_symbol", "local_date"="date")) %>%
      filter(rs$local_date>=as.Date(input$date.range[1]) & rs$local_date<=as.Date(input$date.range[2])) %>%
      arrange(local_date)

    rs$pos_trade = ifelse((rs$remote_perf>0 & rs$local_perf>0), 1, ifelse(rs$remote_perf>0 & rs$local_perf<0, -1, 0))
    rs$pos_trade_total_cumsum = cumsum(rs$pos_trade)
    
    return (rs)
  })
  
  buying.shares = reactive({
    report.shares() %>%
      filter(remote_perf>as.numeric(input$buying.threshold)/100 & perf_cor>as.numeric(input$corr.threshold) #& cor_10>0.02# & cor_30>=0.10 & cor_20 > 0.5
             )
  })
    
  
  ##########################################################################################################
  ##    Day Trading Tab 
  ###
  
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
          
        g = t %>% 
          ggplot(aes(x=local_date)) + 
          geom_area(aes(y=company_local_perf_cumsum, fill=us_symbol)) +
          geom_smooth(data=total, aes(y=total_perf_cumsum, x=local_date), method = "loess") +
          ggtitle("Trading Performance Running Total") +
          scale_y_continuous(labels = scales::percent) +
          labs(x="Time",y="Performance") +
          theme(plot.title = element_text(color="#666666", face="bold", size=22, hjust=0)) +
          theme(axis.title = element_text(color="#666666", face="bold", size=15))            
        
        return (g)          
      }
    })
  })

  
  output$sliding.cor.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      rs = report.shares()
      
      g = ggplot(rs, aes(x=local_date, y=perf_cor)) + 
        geom_line(aes(color=us_symbol)) +
        ggtitle("Sliding Correlation Plot") +
        scale_y_continuous(labels = scales::percent) +
        labs(x="Time",y="Correlation") +
        geom_hline(yintercept=0) +
        theme(plot.title = element_text(color="#666666", face="bold", size=22, hjust=0)) +
        theme(axis.title = element_text(color="#666666", face="bold", size=15))        
      
      if (length(unique(rs$us_symbol))==1)
        g = g + geom_smooth(method="loess") 
      
      return (g)
    })    
  })
  
  
  output$buying.boxplot.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      bs = buying.shares()
      
      ggplot(bs, aes(x=us_symbol)) + 
        geom_boxplot(aes(y=local_perf, fill=us_symbol)) +
        scale_y_continuous(labels = scales::percent) +
        ggtitle("Trading Performance Boxplot") +
        labs(x="Company",y="Correlation") +
        theme(plot.title = element_text(color="#666666", face="bold", size=22, hjust=0)) +
        theme(axis.title = element_text(color="#666666", face="bold", size=15))        
    })    
    
  })
  
  
  output$corr.boxplot.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      rs = report.shares()
      
      ggplot(rs, aes(x=us_symbol)) + 
        geom_boxplot(aes(y=perf_cor, fill=us_symbol)) +
        scale_y_continuous(labels = scales::percent) +
        ggtitle("Sliding Correlation Boxplot") +
        labs(x="Company",y="Correlation") +
        theme(plot.title = element_text(color="#666666", face="bold", size=22, hjust=0)) +
        theme(axis.title = element_text(color="#666666", face="bold", size=15))          
    })    
  })  

  output$pos.trade.cumsum.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      rs = report.shares()
      
      ggplot(rs, aes(x=local_date, y=pos_trade_total_cumsum)) + 
        geom_line(aes(color=us_symbol)) +
        geom_smooth(method="loess")
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
  
  ##########################################################################################################
  ##    Stock Price Tab 
  ###
  
  output$us.stock.price.perf.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      rs = report.shares()
      
      ggplot(rs, aes(x=local_date, y=us_open, color=us_symbol)) + 
        geom_line() +
        geom_smooth(method="loess", se = F) +
        ggtitle("US Stock Prices") +
        labs(x="Time",y="US Stock Price") +
        theme(plot.title = element_text(color="#666666", face="bold", size=22, hjust=0)) +
        theme(axis.title = element_text(color="#666666", face="bold", size=15))        
    })      
  })
  
  output$in.stock.price.perf.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      rs = report.shares()
      
      ggplot(rs, aes(x=local_date, y=in_open, color=us_symbol)) + 
        geom_line() +
        geom_smooth(method="loess", se = F) +
        ggtitle("IN Stock Prices") +
        labs(x="Time",y="IN Stock Price") +
        theme(plot.title = element_text(color="#666666", face="bold", size=22, hjust=0)) +
        theme(axis.title = element_text(color="#666666", face="bold", size=15))         
    })      
  })
  
  
  output$stock.price.cor.table <- renderTable({
    
    input$refreshBtn
    
    isolate({
      
      rs = as.data.table(report.shares())
      
      
      df = data.frame(
        Serie = character(),#"Total",
        Pearson = numeric(),#cor(rs$us_open, rs$in_open, method="pearson"),
        Kendall = numeric(),#cor(rs$us_open, rs$in_open, method="kendall"),
        Spearman = numeric()#cor(rs$us_open, rs$in_open, method="spearman")
      )
      
      for(c in input$companies)
      {
        cc = as.character(c)
        df = rbind(
          df,
          data.frame(
            Serie = cc,
            Pearson = cor(rs[us_symbol==cc]$us_open, rs[us_symbol==cc]$in_open, method="pearson"),
            Kendall = cor(rs[us_symbol==cc]$us_open, rs[us_symbol==cc]$in_open, method="kendall"),
            Spearman = cor(rs[us_symbol==cc]$us_open, rs[us_symbol==cc]$in_open, method="spearman")
          )
        )
        
      }
      
      return (df)
    })
  })
  
  output$stock.price.scatter.plot <- renderPlot({
    
    input$refreshBtn
    
    isolate({
      rs = report.shares()
      
      ggplot(rs, aes(x=us_open, y=in_open, color=us_symbol)) + 
        geom_point() +

        ggtitle("Stock Prices Scatter Plot") +
        labs(x="US Stock Price",y="IN Stock Price") +
        geom_smooth(method="lm", se = F) +
        theme(plot.title = element_text(color="#666666", face="bold", size=22, hjust=0)) +
        theme(axis.title = element_text(color="#666666", face="bold", size=15))         
    })      
  })  
})
