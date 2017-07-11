library(dplyr)

setwd("C:/Projects/NYCDS/Projects/010 Shiny")

all_companies=read.csv("Research/DualListedCompanies.csv")
companies = all_companies[all_companies$in_stock_exchange!="?", ]

# load raw data of US shares in one data.frame
fileNames = list.files("raw_data", pattern="us_[A-Z]+.csv")
us_shares = NULL
for (fileName in fileNames) {
  cat(paste0(fileName, "\n"))
  symbol = regmatches(fileName, regexpr("[A-Z]+", fileName))
  us_share = read.csv(paste0("raw_data/", fileName), stringsAsFactors = F)
  us_share$symbol = rep(symbol, nrow(us_share))
  if(is.null(us_shares))
    us_shares = us_share
  else
    us_shares = rbind(us_shares, us_share)
}

# load raw data of IN shares in one data.frame
fileNames = list.files("raw_data", pattern="in_[A-Z]+.csv")
in_shares = NULL
for (fileName in fileNames) {
  cat(paste0(fileName, "\n"))
  symbol = regmatches(fileName, regexpr("[A-Z]+", fileName))
  in_share = read.csv(paste0("raw_data/", fileName), stringsAsFactors = F)
  in_share$symbol = rep(symbol, nrow(in_share))
  if(is.null(in_shares))
    in_shares = in_share
  else
    in_shares = rbind(in_shares, in_share)
}

# convert date columns to data type Date
Sys.setlocale("LC_TIME", "C") # set english month names
us_shares$date = as.Date(us_shares$date)
in_shares$Date = as.Date(in_shares$Date, format='%d-%B-%Y')

# delete all dates not in 2016
us_shares = us_shares[us_shares$date >= as.Date("2016-01-01") & us_shares$date<as.Date("2017-01-01"), ]
in_shares = in_shares[in_shares$Date >= as.Date("2016-01-01") & in_shares$Date<as.Date("2017-01-01"), ]


################################ build clear data.frame

shares = data.frame(
  flip=character(),
  us_symbol=character(),
  in_symbol=character(),
  us_date=integer(), 
  in_date=integer(), 
  days_lag=integer(), 
  us_open=numeric(), 
  us_close=numeric(), 
  in_open=numeric(), 
  in_close=numeric()
)


for(c in 1:nrow(companies))
{
  
  us_symbol = companies[c, "us_symbol"]
  in_symbol = companies[c, "in_symbol"]
  
  
  ### flip in->us
  print(paste0(in_symbol, "->", us_symbol))
  
  for(d in sort(as.Date(unique(us_shares$date)))) {
    print(format(as.Date(d, origin="1970-01-01"), "%d/%m/%Y"))
    
    us_line = us_shares %>% filter(date==d & symbol==us_symbol)
    in_line = in_shares %>% filter(Date<=d & symbol==in_symbol) %>% top_n(1, wt=Date)

    if (nrow(in_line)==1)
    {
      shares = rbind(
        shares, 
        data.frame(flip="in->us", us_symbol=us_line$symbol, in_symbol=in_line$symbol, us_date=us_line$date, in_date=in_line$Date, days_lag=abs(as.numeric(difftime(us_line$date, in_line$Date, "days"))), us_open=us_line$open, us_close=us_line$close, in_open=in_line$Open.Price, in_close=in_line$Close.Price)
        )
    }
  }
  
  ### flip us->in
  print(paste0(us_symbol, "->", in_symbol))
  
  for(d in sort(as.Date(unique(in_shares$Date)))) {
    print(format(as.Date(d, origin="1970-01-01"), "%d/%m/%Y"))
    
    in_line = in_shares %>% filter(Date==d & symbol==in_symbol)
    us_line = us_shares %>% filter(date<d & symbol==us_symbol) %>% top_n(1, wt=date)
  
    if(nrow(us_line)==1) {  
      shares = rbind(
        shares, 
        data.frame(flip="us->in", us_symbol=us_line$symbol, in_symbol=in_line$symbol, us_date=us_line$date, in_date=in_line$Date, days_lag=abs(as.numeric(difftime(us_line$date, in_line$Date, "days"))), us_open=us_line$open, us_close=us_line$close, in_open=in_line$Open.Price, in_close=in_line$Close.Price)
      )
    }
  }

}

shares$us_perf = (shares$us_open-shares$us_close)/shares$us_open
shares$in_perf = (shares$in_open-shares$in_close)/shares$in_open

write.csv(x=shares, file='double_listed_shares.csv')

library(ggplot2)


shares %>% filter(days_lag==0) %>% ggplot(aes(x=us_perf, y=in_perf)) + geom_point()

shares %>% filter(flip=="in->us" & days_lag==0 & in_perf>0) %>% summarize(in_perf=sum(in_perf), us_perf=sum(us_perf), count=n()) 
shares %>% filter(flip=="us->in" & days_lag==1 & us_perf>0) %>% summarize(us_perf=sum(us_perf), in_perf=sum(in_perf), count=n()) 
