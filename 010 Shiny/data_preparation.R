library(dplyr)
library(data.table)

setwd("C:/Projects/NYCDS/Projects/010 Shiny")

all_companies=read.csv("Research/DualListedCompanies.csv", stringsAsFactors = F)
companies = all_companies[all_companies$in_stock_exchange!="?", ]
rm(all_companies)

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
us_shares$id = 1:nrow(us_shares)
us_shares = as.data.table(us_shares)
rm(us_share)

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
in_shares = as.data.table(in_shares)
in_shares$id = 1:nrow(in_shares)
rm(in_share)
rm(fileName)
rm(fileNames)
rm(symbol)

#check for doube date/symbol in us_shares
#us_shares[, .N, by=.(date, symbol)] %>% filter(N>1)

#check for doube Date/symbol in in_shares
#in_shares[, .N, by=.(Date, symbol)] %>% filter(N>1)

#clear some redundant lines in india data set
double_dates = in_shares[, .(.N, id), by=.(symbol, Date)] %>% filter(N>1) %>% group_by(symbol, Date) %>% summarize(double_id = min(id)) 
while( nrow(double_dates)>0 ) {
  in_shares = in_shares[!id %in% double_dates$double_id,,]
  double_dates = in_shares[, .(.N, id), by=.(symbol, Date)] %>% filter(N>1) %>% group_by(symbol, Date) %>% summarize(double_id = min(id)) 
}
rm(double_dates)


# convert date columns to data type Date
Sys.setlocale("LC_TIME", "C") # set english month names
us_shares$date = as.Date(us_shares$date)
in_shares$Date = as.Date(in_shares$Date, format='%d-%B-%Y')



################################ build clear data.frame


shares = data.table(
  flip=character(),
  us_symbol=character(),
  in_symbol=character(),
  us_date=integer(), 
  in_date=integer(), 
  us_open=numeric(), 
  us_close=numeric(), 
  in_open=numeric(), 
  in_close=numeric(),
  us_perf = numeric(),
  in_perf = numeric(),  
  cor_10 = numeric(),
  cor_20 = numeric(),
  cor_30 = numeric(),
  cor_60 = numeric(),
  cor_90 = numeric(),
  cor_120 = numeric()
)
shares$us_date = as.Date(shares$us_open)
shares$in_date = as.Date(shares$in_date)

setkeyv(us_shares, c("date", "symbol", "id"))
setkeyv(in_shares, c("Date", "symbol", "id"))

for(c in nrow(companies):1)
{
  
  us_symbol = companies[c, "us_symbol"]
  in_symbol = companies[c, "in_symbol"]
  
  
  ### flip in->us
  print(paste0(in_symbol, "->", us_symbol))
  
  dates = us_shares[symbol==us_symbol,,]$date
  for(d in dates) {
    print(format(as.Date(d, origin="1970-01-01"), "%d/%m/%Y"))
    
    us_line = us_shares[date==d & symbol==us_symbol,,]
    in_line = in_shares[Date==d & symbol==in_symbol,,]
    
    if (nrow(us_line)==1 & nrow(in_line)==1)
    {
      symbol = us_symbol
      to_date =  d-1
      from_date = to_date-30
      date_range = shares[flip=="in->us" & us_date>=from_date & us_date<to_date & us_symbol==symbol,,][,.(us_perf, in_perf),]
      c30=cor(date_range$us_perf, date_range$in_perf, method = "kendall")
      
      from_date = to_date-60
      date_range = shares[flip=="in->us" & us_date>=from_date & us_date<to_date & us_symbol==symbol,,][,.(us_perf, in_perf),]
      c60=cor(date_range$us_perf, date_range$in_perf, method = "kendall")
      
      from_date = to_date-90
      date_range = shares[flip=="in->us" & us_date>=from_date & us_date<to_date & us_symbol==symbol,,][,.(us_perf, in_perf),]
      c90=cor(date_range$us_perf, date_range$in_perf, method = "kendall")

      from_date = to_date-120
      date_range = shares[flip=="in->us" & us_date>=from_date & us_date<to_date & us_symbol==symbol,,][,.(us_perf, in_perf),]
      c120=cor(date_range$us_perf, date_range$in_perf, method = "kendall")
      
      from_date = to_date-10
      date_range = shares[flip=="in->us" & us_date>=from_date & us_date<to_date & us_symbol==symbol,,][,.(us_perf, in_perf),]
      c10=cor(date_range$us_perf, date_range$in_perf, method = "kendall")
      
      from_date = to_date-20
      date_range = shares[flip=="in->us" & us_date>=from_date & us_date<to_date & us_symbol==symbol,,][,.(us_perf, in_perf),]
      c20=cor(date_range$us_perf, date_range$in_perf, method = "kendall")
      
      dt =  data.table(
        flip="in->us", 
        us_symbol = us_line$symbol, 
        in_symbol = in_line$symbol, 
        us_date = as.integer(us_line$date), 
        in_date = as.integer(in_line$Date), 
        us_open = us_line$open, 
        us_close = us_line$close, 
        in_open = in_line$Open.Price, 
        in_close = in_line$Close.Price,
        us_perf = (us_line$close-us_line$open) / us_line$open,
        in_perf = (in_line$Close.Price-in_line$Open.Price) / in_line$Open.Price,
        cor_10 = coalesce(c10, 0),
        cor_20 = coalesce(c20, 0),  
        cor_30 = coalesce(c30, 0),
        cor_60 = coalesce(c60, 0),
        cor_90 = coalesce(c90, 0),
        cor_120 = coalesce(c120, 0)
      )

      shares = rbind(
        shares, 
        dt
      )
    
    }
  }
  
  ### flip us->in
  print(paste0(us_symbol, "->", in_symbol))
  
  dates = in_shares[symbol==in_symbol,,]$Date
  for(d in dates) {
    print(format(as.Date(d, origin="1970-01-01"), "%d/%m/%Y"))
    
    in_line = in_shares[Date==d & symbol==in_symbol]
    us_line = us_shares[date==(d-1) & symbol==us_symbol] 
  
    if(nrow(us_line)==1 & nrow(in_line)==1) {  
      shares = rbind(
        shares, 
        data.frame(
          flip="us->in", 
          us_symbol=us_line$symbol, 
          in_symbol=in_line$symbol, 
          us_date=us_line$date, 
          in_date=in_line$Date, 
          us_open=us_line$open, 
          us_close=us_line$close, 
          in_open=in_line$Open.Price, 
          in_close=in_line$Close.Price,
          us_perf = (us_line$close-us_line$open) / us_line$open,
          in_perf = (in_line$Close.Price-in_line$Open.Price) / in_line$Open.Price          
        ),
        fill=T
      )
    }
  }
}


write.csv(x=shares, file='double_listed_shares.csv')




