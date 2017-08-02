import pp
import bookscraper
import time
import numpy as np

def getBookDic(bookUrl):
    result = {}
    try:
        bookscraper.defaultDriver_deleteAllCookies()
        result =  bookscraper.getBookProperties(bookUrl)
    except Exception as e:
        result["exception_type"] = type(e)
        result["exception_str"] = e.__str__()
    return result

def quitDefaultDriver():
    bookscraper.quitDefaultDriver()

#############################################
# main code

start_time = time.time()

# start job_server with 7 workers 
job_server = pp.Server(7, ppservers=())

bestSellersLink = "http://www.audible.com/adblbestsellers"
bookscraper.defaultDriver_deleteAllCookies()
parallel_jobs = []
for bookUrl in bookscraper.getListOfBooksGen(bestSellersLink):
    newJob = job_server.submit(getBookDic, (bookUrl,), (), ("bookscraper",))
    parallel_jobs.append(newJob)
    #newJob()

adblBestSellerBooks = []
for job in parallel_jobs:
    adblBestSellerBooks.append(job())

end_time = time.time()
print("seconds elapsed: " + str(end_time - start_time))

print(len(adblBestSellerBooks))
np.save("bestsellers_2017-08-02", adblBestSellerBooks)
#print(adblBestSellerBooks)

###########################################################################
# clean up

quitDefaultDriver()

quitJobs = [job_server.submit(quitDefaultDriver, (), (), ("bookscraper",)) for i in range(50)]
map(lambda j: j(), quitJobs)

job_server.destroy()
