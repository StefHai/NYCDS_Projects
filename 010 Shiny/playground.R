
library(ggplot2)


shares %>% filter(days_lag==0) %>% ggplot(aes(x=us_perf, y=in_perf)) + geom_point()

us_trading = shares %>% filter(flip=="in->us" & in_perf>0) 
in_trading = shares %>% filter(flip=="us->in" & us_perf>0) 

us_trading %>% group_by(us_symbol) %>% summarize(in_perf=sum(in_perf), us_perf=sum(us_perf), count=n()) 
in_trading %>% group_by(us_symbol) %>% summarize(us_perf=sum(us_perf), in_perf=sum(in_perf), count=n()) 


t=
  merge(
    distinct(us_trading, us_date),
    distinct(us_trading, us_symbol)
  ) %>%
  left_join(us_trading, by=c("us_date"="us_date", "us_symbol"="us_symbol")) %>%
  arrange(us_date)

t$us_perf = ifelse(is.na(t$us_perf), 0, t$us_perf)


t %>%
  filter(us_date>as.Date("2016-10-05") & us_date<as.Date("2016-10-11")) %>%
  arrange(us_date) %>%
  group_by(us_symbol) %>% 
  mutate(us_perf_cumsum = cumsum(us_perf)) %>%
  ggplot(aes(x=us_date, y=us_perf_cumsum, fill=us_symbol)) + 
  geom_area()

t1=
  merge(
    distinct(in_trading, in_date),
    distinct(in_trading, us_symbol)
  ) %>%
  left_join(in_trading, by=c("in_date"="in_date", "us_symbol"="us_symbol")) %>%
  arrange(in_date)

t1$in_perf = ifelse(is.na(t1$in_perf), 0, t1$in_perf)


t1 %>% 
  arrange(in_date) %>%
  group_by(us_symbol) %>% 
  mutate(in_perf_cumsum = cumsum(in_perf)) %>%
  ggplot(aes(x=in_date, y=in_perf_cumsum, fill=us_symbol)) + 
  geom_area()

#############################
t1 %>% filter(us_symbol=="WIT" & in_date>as.Date("2016-10-04") & in_date<as.Date("2016-10-10") ) %>% mutate(in_perf_cumsum=cumsum(in_perf))

merge(
  distinct(in_trading, in_date),
  distinct(in_trading, us_symbol)
) %>%
  filter(us_symbol=="INFY" & in_date>as.Date("2016-10-04") & in_date<as.Date("2016-10-10") )




shares %>% filter(flip=="in->us") %>% group_by(us_date, us_symbol) %>% summarize(count=n()) %>% filter(count>1)


shares[flip=="us->in", cor(us_perf,in_perf), by=us_symbol]


########### working snipped running cor
shares = as.data.table(shares)
c = apply(shares[flip=="in->us" & us_symbol=="INFY",,], 1, 
          function(r) {
            rflip = r["flip"]
            symbol = r["us_symbol"]
            to_date =  as.Date(as.Date(r["us_date"])-1)
            from_date = as.Date(to_date-120, origin="1970-01-01")
            date_range = shares[flip==rflip & us_date>=from_date & us_date<to_date & us_symbol==symbol,,][,.(us_perf, in_perf),]
            return (cor(date_range$us_perf, date_range$in_perf))
          }
)
data.frame(i=1:length(c), cor=c) %>% ggplot(aes(x=i, y=c)) + geom_line()

shares[flip=="in->us", cor(us_perf,in_perf), by=us_symbol]



s1[flip=="in->us" & us_date>as.Date("2017-01-01", origin="1970-01-01"),,] %>% 
  ggplot(aes(x=us_symbol, y=cor_30, fill=us_symbol)) + 
  geom_boxplot() 
#geom_histogram(aes(fill=us_symbol)) + 
#geom_vline(xintercept=mean(s1$cor_30), color="red") +
#facet_wrap(~us_symbol)

ex$pos_cor = ifelse((ex$in_perf>0 & ex$us_perf>0) | ex$in_perf<=0 & ex$us_perf<=0, 1, 0)

ex$pos_trade = ifelse((ex$in_perf>0 & ex$us_perf>0), 1, ifelse(ex$in_perf>0 & ex$us_perf<0, -1, 0))
ex$pos_trade_cumsum = cumsum(ex$pos_trade)
ggplot(ex, aes(x=us_date, y=pos_trade_cumsum))+ geom_line()

##################################################################################################################################
################# bayes cor detector
shares = data.table(shares)
ex = shares[us_symbol=="TTM" &  flip=="in->us" & us_date>as.Date("2013-01-01", origin="1970-01-01") & us_date<as.Date("2018-01-01", origin="1970-01-01"),,]

ex$pos_cor = ifelse(
  (ex$in_perf>0 & ex$us_perf>0) 
  | ex$in_perf<=0 & ex$us_perf<=0
  , 1, 0)
ex$pos_trade = ifelse((ex$in_perf>0 & ex$us_perf>0), 1, ifelse(ex$in_perf>0 & ex$us_perf<0, -1, 0))
ex$pos_trade_cumsum = cumsum(ex$pos_trade)

bs = 5
ex$pos_cor_count = apply(ex, 1, function(r)
{
  w = ex %>% filter(us_date<as.Date(r["us_date"], origin="1970-01-01")) %>% top_n(bs, wt = us_date) 
  return (sum(w$pos_cor))
})  
ex$bin_neutral = dbinom(ex$pos_cor_count, prob = 0.5, size = bs)
ex$bin_pos = dbinom(ex$pos_cor_count, prob = 0.53, size = bs)
ex$bin_neg = dbinom((bs-ex$pos_cor_count), prob = 0.53, size = bs)



bayes = data.table(
  pos_cor_p = 1/3,
  neg_cor_p = 1/3,
  neutral_cor_p = 1/3,
  bayes_pos_cor = 1/3,
  bayes_neg_cor = 1/3,
  bayes_neutral_cor = 1/3
)
prop_threshold = 0.7
for(i in 2:nrow(ex)) 
{
  p_pos = ex[i, .(bin_pos),]$bin_pos * bayes[i-1, .(bayes_pos_cor)]$bayes_pos_cor
  p_neg = ex[i, .(bin_neg),]$bin_neg * bayes[i-1, .(bayes_neg_cor)]$bayes_neg_cor
  p_neutral = ex[i, .(bin_neutral),]$bin_neutral * bayes[i-1, .(bayes_neutral_cor)]$bayes_neutral_cor
  
  bayes_pos = p_pos/(p_pos+p_neg+p_neutral)
  bayes_neg = p_neg/(p_pos+p_neg+p_neutral)
  bayes_neutral = p_neutral/(p_pos+p_neg+p_neutral)
  
  if (bayes_pos > prop_threshold){
    bayes_pos = prop_threshold
    bayes_neg = (1-prop_threshold)/2 # * bayes_neg / (bayes_neg + bayes_neutral)
    bayes_neutral = (1-prop_threshold)/2 # * bayes_neutral/ (bayes_neg + bayes_neutral)
  } 
  else if (bayes_neg > prop_threshold){
    bayes_neg = prop_threshold
    bayes_pos = (1-prop_threshold)/2# * bayes_pos / (bayes_pos + bayes_neutral)
    bayes_neutral = (1-prop_threshold)/2# * bayes_neutral / (bayes_pos + bayes_neutral)
  } 
  else if (bayes_neutral > prop_threshold){
    bayes_neutral = prop_threshold
    bayes_neg = (1-prop_threshold)/2# * bayes_neg / (bayes_pos + bayes_neg)
    bayes_pos = (1-prop_threshold)/2# * bayes_pos / (bayes_pos + bayes_neg)
  } 
  
  bayes = rbind(
    bayes,
    data.table(
      pos_cor_p = p_pos,
      neg_cor_p = p_neg,
      neutral_cor_p = p_neutral,
      bayes_pos_cor = bayes_pos,
      bayes_neg_cor = bayes_neg,
      bayes_neutral_cor = bayes_neutral
    )
  )
}

exb = cbind(ex, bayes)
exb$pos_cor_dominates = ifelse(exb$bayes_pos_cor>0.7 #& exb$cor_30>=0.15
                               #| (exb$cor_30>=0.15 & exb$bayes_pos_cor>0.3 & exb$bayes_neg_cor<0.3)
                               , 1, 0)#!(bayes$bayes_neg_cor>bayes$bayes_pos_cor & bayes$bayes_neg_cor>bayes$bayes_neutral_cor), 1, 0) #& bayes$bayes_pos_cor>bayes$bayes_neutral_cor
exb$date2 = exb$us_date-7

exb %>% 
  filter(us_date>=as.Date("2016-01-01", origin="1970-01-01") & us_date>=as.Date("2017-01-01", origin="1970-01-01") ) %>% 
  ggplot() + 
  geom_line(aes(x=date2, y=cor_30), color="red") + 
  geom_line(aes(x=us_date, y=(bayes_pos_cor-0.5)*0.5))


exb$trade2_buy = ifelse(
  exb$in_perf>0.001 & 
    (
      (exb$pos_cor_dominates==1) 
      #exb$bayes_pos_cor>exb$bayes_neg_cor & exb$cor_30>0.15 & exb$bayes_pos_cor>0.2
    ), ifelse(exb$us_perf>0, 1, -1), 0)

exb$trade2_cumsum = cumsum(exb$trade2_buy*abs(exb$us_perf))
ggplot(exb, aes(x=us_date)) + 
  #geom_line(aes(y=pos_trade_cumsum)) + 
  #geom_line(aes(y=pos_cor_dominates*20-10), color="red") + 
  geom_line(aes(y=trade2_cumsum), color="blue", size=2)
#geom_line(aes(y=cor_30*30), color="brown", size=1)

summary(exb$trade2_buy)
sum(exb$trade2_buy)
sum(abs(exb$trade2_buy))/2


