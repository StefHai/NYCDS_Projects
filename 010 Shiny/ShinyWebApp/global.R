
shares = read.csv("../double_listed_shares.csv", stringsAsFactors = F)
shares$us_date = as.Date(shares$us_date)
shares$in_date = as.Date(shares$in_date)

date.origin = '1970-01-01'