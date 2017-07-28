
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import csv

def webDriverWait(browser, xpath, timeout):
        wait = WebDriverWait(browser, timeout)
        return wait.until(EC.element_to_be_clickable((By.XPATH, xpath)))

def findElementByXPath (browser, xpath):
    try:
        return browser.find_element_by_xpath(xpath)
    except Exception as ex:
        return None

def findElementsByXPath (browser, xpath):
    try:
        return browser.find_elements_by_xpath(xpath)
    except Exception as ex:
        return None

def findElementByXPath_text(browser, xpath):
    e = findElementByXPath(browser, xpath)
    if e is None:
        return None
    else:
        return e.text

def getListOfBooks(browser, url):
    bestSellerLinksLst = []

    browser.get(url)

    isLastSite = False
    while not isLastSite:
        # wait till site loaded, respectively the last list element
        webDriverWait(browser, '//li[@class="adbl-result-item adbl-last"]', 20)

        # get list of best sellers
        bestSellerLst = browser.find_elements_by_xpath('//div[@class="adbl-results-content"]/li')

        # get best seller links
        for i, best_seller in enumerate(bestSellerLst):
            prodTitle = best_seller.find_element_by_xpath('.//div[@class="adbl-prod-title"]')
            link = prodTitle.find_element_by_xpath('.//a[@class="adbl-link"]').get_attribute("href")
            bestSellerLinksLst += [link]
        
        nextSiteButton = browser.find_element_by_xpath('//span[@class="adbl-page-next"]')
        
        try:
            e = nextSiteButton.find_element_by_xpath('.//span[@class="adbl-link-off"]')
            isLastSite = True
        except Exception as e:
            isLastSite = False
        
        if not isLastSite:
            nextSiteButton.click()
    
    return bestSellerLinksLst

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
    #result[''] = findElementByXPath_text(browser, '')
    #result[''] = findElementByXPath_text(browser, '')


    return result






browser = webdriver.Chrome()
browser.delete_all_cookies()
try:
    try:
        
        url = "http://www.audible.com/adblbestsellers"
        bstSellerLst = getListOfBooks(browser, url)
        #print(bstSellerLst)

        for b in bstSellerLst:
            print(b)
            browser.delete_all_cookies()
            print(getBookProperties(browser, b))   
        
        #url = "https://www.audible.com/pd/Sci-Fi-Fantasy/A-Clash-of-Kings-Audiobook/B002UZKIBO?ref_=a_adblbests_c2_16_t"
        #print(getBookProperties(browser, url))        
    except Exception as e:
        print(type(e))
        print(e)
        print(e.__context__)

finally:
    browser.close()


print("Done.")


