library(dplyr)

shares = read.csv("double_listed_stocks.csv", stringsAsFactors = F)
date.origin = '1970-01-01'
shares$us_date = as.Date(shares$us_date, origin=date.origin)
shares$in_date = as.Date(shares$in_date, origin=date.origin)
shares = distinct(shares)

