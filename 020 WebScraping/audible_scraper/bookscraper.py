from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
import atexit

def exit_handler():
    quitDefaultDriver()

atexit.register(exit_handler)

defaultDriver = None
def getDefaultDriver():
    global defaultDriver
    if defaultDriver is None:
        defaultDriver = webdriver.Chrome()
    return defaultDriver

def defaultDriver_deleteAllCookies():
    driver = getDefaultDriver()
    if not driver.session_id is None:
        driver.delete_all_cookies()

def quitDefaultDriver():
    global defaultDriver
    if not defaultDriver is None:
        defaultDriver.quit()
        defaultDriver = None

def webDriverWait(driver, xpath, timeout):
        wait = WebDriverWait(driver, timeout)
        return wait.until(EC.element_to_be_clickable((By.XPATH, xpath)))

def findElementByXPath (driver, xpath):
    try:
        return driver.find_element_by_xpath(xpath)
    except EC.NoSuchElementException as ex:
        return None

def findElementsByXPath (driver, xpath):
    try:
        return driver.find_elements_by_xpath(xpath)
    except EC.NoSuchElementException as ex:
        return None

def findElementByXPath_text(driver, xpath):
    e = findElementByXPath(driver, xpath)
    if e is None:
        return None
    else:
        return e.text

def getListOfBooksGen(url, driver=None):
    if driver is None:
        driver = getDefaultDriver()

    driver.get(url)

    isLastSite = False
    while not isLastSite:
        # wait till site loaded, respectively the last list element
        #webDriverWait(driver, '//li[@class="adbl-result-item adbl-last"]', 20)

        # get list of best sellers
        bestSellerLst = driver.find_elements_by_xpath('//div[@class="adbl-results-content"]/li')

        # get best seller links
        for i, best_seller in enumerate(bestSellerLst):
            prodTitle = best_seller.find_element_by_xpath('.//div[@class="adbl-prod-title"]')
            link = prodTitle.find_element_by_xpath('.//a[@class="adbl-link"]').get_attribute("href")
            yield link
        
        nextSiteButton = driver.find_element_by_xpath('//span[@class="adbl-page-next"]')
        
        try:
            e = nextSiteButton.find_element_by_xpath('.//span[@class="adbl-link-off"]')
            isLastSite = True
        except Exception as e:
            isLastSite = False
        
        if not isLastSite:
            nextSiteButton.click()

def getListOfBooks(url, driver=None):
    if driver is None:
        driver = getDefaultDriver()

    bestSellerLinksLst = []
    for bookLink in getListOfBooksGen(url, driver):  
        bestSellerLinksLst += [bookLink]
    return bestSellerLinksLst

def getBookProperties(url, driver=None):
    if driver is None:
        driver = getDefaultDriver()
    
    result = {}
    result["url"] = url
    driver.get(url)
    
    # wait till site loaded, respectively the product image
    webDriverWait(driver, '//div[@class="adbl-reviews"]', 20)

    amazonReviewsLink = findElementByXPath(driver, '//li[@data-paging-type="AmazonReviews"]')
    if not amazonReviewsLink is None:
         amazonReviewsLink.click()

    breadcrumb = findElementByXPath(driver, '//div[@class="adbl-pd-breadcrumb"]')
    breadcrumb_items = findElementsByXPath(breadcrumb, './/span[@itemprop="name"]')
    result['breadcrumbs'] = list(map(lambda i: i.text, breadcrumb_items))
    result['title'] = findElementByXPath_text(driver, '//h1[@class="adbl-prod-h1-title"]')
    result['authors'] = findElementByXPath_text(driver, '//span[@class="adbl-prod-author"]')
    result['narrated_by'] = findElementByXPath_text(driver, '//li[@class="adbl-narrator-row"]/span[2]')
    result['length'] = findElementByXPath_text(driver, '//span[@class="adbl-run-time"]')
    result['release_date'] = findElementByXPath_text(driver, '//span[@class="adbl-date adbl-release-date"]')
    result['publisher'] = findElementByXPath_text(driver, '//span[@class="adbl-publisher"]')
    result['series'] = findElementByXPath_text(driver, '//div[@class="adbl-series-link"]')
    result['program_format'] = findElementByXPath_text(driver, '//span[@class="adbl-format-type"]')
    result['price'] = findElementByXPath_text(driver, '//button[@id="addWithoutMemButton"]//div[@class="adbl-price"]')
    if result['price'] is None:
        result['price'] = findElementByXPath_text(driver, '//button[@id="preorderWithoutMemButton"]//div[@class="adbl-price"]')

    result['adbl.rating.overall.value'] = findElementByXPath_text(driver, "//span[@class='adbl-product-rating-star-text-wrap boldrating']")
    result['adbl.rating.overall.count'] = findElementByXPath_text(driver, '//span[@class="adbl-product-rating-star-text-wrap"]')
    
    result['adbl.rating.story.value'] = findElementByXPath_text(driver, '//span[@class="adbl-product-rating-star-text-wrap boldrating"]')
    result['adbl.rating.story.count'] = findElementByXPath_text(driver, '//span[@class="adbl-product-rating-star-text-wrap"]')
    
    result['adbl.rating.performance.value'] = findElementByXPath_text(driver, '//span[@class="adbl-product-rating-star-text-wrap boldrating"]')
    result['adbl.rating.performance.count'] = findElementByXPath_text(driver, '//span[@class="adbl-product-rating-star-text-wrap"]')

    driver.switch_to.frame("adbl-amzn-reviews")

    imgElement = findElementByXPath(driver, '/html/body/div[2]/div[2]/div[1]/div[3]/span/span/a/img')
    if not imgElement is None:
        result['amazon.rating.overall.value'] = imgElement.get_attribute("alt")
    else:
        result['amazon.rating.overall.value'] = None
    result['amazon.rating.overall.count'] = findElementByXPath_text(driver, '//body/div[2]/div[2]/div/div[3]')
    #result[''] = findElementByXPath_text(driver, '')
    #result[''] = findElementByXPath_text(driver, '')


    return result
