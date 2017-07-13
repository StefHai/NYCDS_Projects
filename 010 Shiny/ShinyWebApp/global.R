library(dplyr)

shares = read.csv("../double_listed_shares.csv", stringsAsFactors = F)
shares$us_date = as.Date(shares$us_date)
shares$in_date = as.Date(shares$in_date)
shares = distinct(shares)
date.origin = '1970-01-01'