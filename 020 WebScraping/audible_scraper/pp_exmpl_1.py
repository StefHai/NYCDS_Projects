import selenium.webdriver
import selenium.webdriver.support
import selenium.webdriver.support.expected_conditions
import selenium.webdriver.common.by

import math, sys, time
import pp

def testDriver(url):
    browser = selenium.webdriver.Chrome()
    browser.delete_all_cookies()
    bookDic = getBookProperties(browser, url)
    return bookDic

def webDriverWait(browser, xpath, timeout):
        wait = selenium.webdriver.support.ui.WebDriverWait(browser, timeout)
        return wait.until(selenium.webdriver.support.expected_conditions.element_to_be_clickable((selenium.webdriver.common.by.By.XPATH, xpath)))

def findElementByXPath (browser, xpath):
    try:
        return browser.find_element_by_xpath(xpath)
    except selenium.webdriver.support.expected_conditions.NoSuchElementException as ex:
        return None

def findElementsByXPath (browser, xpath):
    try:
        return browser.find_elements_by_xpath(xpath)
    except selenium.webdriver.support.expected_conditions.NoSuchElementException as ex:
        return None

def findElementByXPath_text(browser, xpath):
    e = findElementByXPath(browser, xpath)
    if e is None:
        return None
    else:
        return e.text

def getBookProperties(browser, url):
    result = {}
    browser.get(url)
    
    # wait till site loaded, respectively the product image
    webDriverWait(browser, '//div[@class="adbl-reviews"]', 20)

    amazonReviewsLink = findElementByXPath(browser, '//li[@data-paging-type="AmazonReviews"]')
    if not amazonReviewsLink is None:
         amazonReviewsLink.click()

    breadcrumb = findElementByXPath(browser, '//div[@class="adbl-pd-breadcrumb"]')
    breadcrumb_items = findElementsByXPath(breadcrumb, './/span[@itemprop="name"]')
    result['breadcrumbs'] = list(map(lambda i: i.text, breadcrumb_items))
    result['title'] = findElementByXPath_text(browser, '//h1[@class="adbl-prod-h1-title"]')
    result['authors'] = findElementByXPath_text(browser, '//span[@class="adbl-prod-author"]')
    result['narrated_by'] = findElementByXPath_text(browser, '//li[@class="adbl-narrator-row"]/span[2]')
    result['length'] = findElementByXPath_text(browser, '//span[@class="adbl-run-time"]')
    result['release_date'] = findElementByXPath_text(browser, '//span[@class="adbl-date adbl-release-date"]')
    result['publisher'] = findElementByXPath_text(browser, '//span[@class="adbl-publisher"]')
    result['series'] = findElementByXPath_text(browser, '//div[@class="adbl-series-link"]')
    result['program_format'] = findElementByXPath_text(browser, '//span[@class="adbl-format-type"]')
    result['price'] = findElementByXPath_text(browser, '//button[@id="addWithoutMemButton"]//div[@class="adbl-price"]')
    
    result['adbl.rating.overall.value'] = findElementByXPath_text(browser, "//span[@class='adbl-product-rating-star-text-wrap boldrating']")
    result['adbl.rating.overall.count'] = findElementByXPath_text(browser, '//span[@class="adbl-product-rating-star-text-wrap"]')
    
    result['adbl.rating.story.value'] = findElementByXPath_text(browser, '//span[@class="adbl-product-rating-star-text-wrap boldrating"]')
    result['adbl.rating.story.count'] = findElementByXPath_text(browser, '//span[@class="adbl-product-rating-star-text-wrap"]')
    
    result['adbl.rating.performance.value'] = findElementByXPath_text(browser, '//span[@class="adbl-product-rating-star-text-wrap boldrating"]')
    result['adbl.rating.performance.count'] = findElementByXPath_text(browser, '//span[@class="adbl-product-rating-star-text-wrap"]')

    browser.switch_to.frame("adbl-amzn-reviews")

    imgElement = findElementByXPath(browser, '/html/body/div[2]/div[2]/div[1]/div[3]/span/span/a/img')
    if not imgElement is None:
        result['amazon.rating.overall.value'] = imgElement.get_attribute("alt")
    else:
        result['amazon.rating.overall.value'] = None
    result['amazon.rating.overall.count'] = findElementByXPath_text(browser, '//body/div[2]/div[2]/div/div[3]')

    return result





# tuple of all parallel python servers to connect with
ppservers = ()
#ppservers = ("10.0.0.1",)

if len(sys.argv) > 1:
    ncpus = int(sys.argv[1])
    # Creates jobserver with ncpus workers
    job_server = pp.Server(ncpus, ppservers=ppservers)
else:
    # Creates jobserver with automatically detected number of workers
    job_server = pp.Server(ppservers=ppservers)

print("Starting pp with", job_server.get_ncpus(), "workers")

start_time = time.time()

#print(testDriver("https://www.audible.com/pd/Sci-Fi-Fantasy/A-Clash-of-Kings-Audiobook/B002UZKIBO?ref_=a_adblbests_c2_16_t"))



# The following submits 8 jobs and then retrieves the results
inputs = ("https://www.audible.com/pd/Sci-Fi-Fantasy/A-Clash-of-Kings-Audiobook/B002UZKIBO?ref_=a_adblbests_c2_16_t",\
"https://www.audible.com/pd/Sci-Fi-Fantasy/A-Knight-of-the-Seven-Kingdoms-Audiobook/B011PVYB2A/ref=a_pd_Sci-Fi_c4_1_1_i?ie=UTF8&pf_rd_r=QS1M7K6CZF5RK1FWMMWN&pf_rd_m=A2ZO8JX97D5MN9&pf_rd_t=101&pf_rd_i=detail-page&pf_rd_p=3004414202&pf_rd_s=center-4",\
"https://www.audible.com/pd/Sci-Fi-Fantasy/Rogues-Audiobook/B00L1GU3WC/ref=a_pd_Sci-Fi_c4_1_4_i?ie=UTF8&pf_rd_r=S3N7A229DN4AGVQ9A0VA&pf_rd_m=A2ZO8JX97D5MN9&pf_rd_t=101&pf_rd_i=detail-page&pf_rd_p=3004414202&pf_rd_s=center-4")

helperFunctions = (webDriverWait, findElementByXPath, findElementsByXPath, findElementByXPath_text, getBookProperties,)
modulList = ("selenium.webdriver", "selenium.webdriver.support", "selenium.webdriver.support.expected_conditions", "selenium.webdriver.common.by",)
jobs = [(input, job_server.submit(testDriver,(input,), helperFunctions, modulList)) for input in inputs]

for input, job in jobs:
    print("Sum of primes below", input, "is", job())

print("Time elapsed: ", time.time() - start_time, "s")
job_server.print_stats()



# Parallel Python Software: http://www.parallelpython.com
