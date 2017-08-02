setwd("C:/Projects/NYCDS/Projects/020 WebScraping/audible_scraper")
library(dplyr)
library(ggplot2)

df = read.csv("bestsellers_2017-07-31.csv")

df1 = df %>% filter(!is.na(price) & price>0)

ggplot(df1, aes(x=length, y=price, color=category)) + 
  geom_point(aes(), na.rm=T)
  #geom_text(aes(label=title),hjust=0, vjust=0)

df1 %>% ggplot(aes(x=category)) + geom_bar()

nrow(df1)


