import time
import csv
import numpy as np
from bookscraper import getListOfBooks
from bookscraper import getBookProperties
from bookscraper import defaultDriver_deleteAllCookies
from bookscraper import quitDefaultDriver

start_time = time.time()

print(getBookProperties("https://www.audible.com/pd/Mysteries-Thrillers/Origin-Audiobook/B01LZ0188N/ref=a_search_c4_1_1_srTtl?qid=1501623587&sr=1-1")["price"])

try:
    
    url = "http://www.audible.com/adblbestsellers"
    #url = "https://www.audible.com/a/adblbestsellers"
    
    
    bstSellerLst = getListOfBooks(url)

    adblBestSellerBooks = []

    for b in bstSellerLst:
        #print(b)
        defaultDriver_deleteAllCookies()
        bestSellerBook = getBookProperties(b)
        adblBestSellerBooks += [bestSellerBook]
    
    #np.save("bestsellers_2017-07-31", adblBestSellerBooks)
    #url = "https://www.audible.com/pd/Sci-Fi-Fantasy/A-Clash-of-Kings-Audiobook/B002UZKIBO?ref_=a_adblbests_c2_16_t"
    #print(getBookProperties(browser, url))        
except Exception as e:
    print(type(e))
    print(e)
    print(e.stacktrace)

end_time = time.time()
print("seconds elapsed: " + str(end_time - start_time))

quitDefaultDriver()
print("Done.")
