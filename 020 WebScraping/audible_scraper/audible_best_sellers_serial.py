
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import csv

def webDriverWait(browser, xpath, timeout):
        wait = WebDriverWait(browser, timeout)
        return wait.until(EC.element_to_be_clickable((By.XPATH, xpath)))

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
    webDriverWait(browser, '//div[@class="adbl-rating-cont adbl-new-stars "]', 20)

    breadcrumb = browser.find_element_by_xpath('//div[@class="adbl-pd-breadcrumb"]')
    breadcrumb_items = breadcrumb.find_elements_by_xpath('.//span[@itemprop="name"]')
    result['breadcrumbs'] = list(map(lambda i: i.text, breadcrumb_items))
    result['title'] = browser.find_element_by_xpath('//h1[@class="adbl-prod-h1-title"]').text
    result['authors'] = browser.find_element_by_xpath('//span[@class="adbl-prod-author"]').text
    result['narrated_by'] = browser.find_element_by_xpath('//li[@class="adbl-narrator-row"]/span[2]').text
    result['length'] = browser.find_element_by_xpath('//span[@class="adbl-run-time"]').text
    result['release_date'] = browser.find_element_by_xpath('//span[@class="adbl-date adbl-release-date"]').text
    result['publisher'] = browser.find_element_by_xpath('//span[@class="adbl-publisher"]').text
    #result[''] = browser.find_element_by_xpath('').text
    #result[''] = browser.find_element_by_xpath('').text
    #result[''] = browser.find_element_by_xpath('').text
    

    return result






browser = webdriver.Chrome()
try:
    try:
        #url = "http://www.audible.com/adblbestsellers"
        #bstSellerLst = getListOfBooks(browser, url)
        #print(bstSellerLst)

        url = "http://www.audible.com/pd/Science-Technology/Homo-Deus-Audiobook/B01N4DCBK6/ref=a_adblbests_c2_20_t?ie=UTF8&pf_rd_r=1HFKPMMX8A65VF1739Z6&pf_rd_m=A2ZO8JX97D5MN9&pf_rd_t=101&pf_rd_i=adblbestsellers&pf_rd_p=1815570102&pf_rd_s=center-2"
        print(getBookProperties(browser, url))        
    except Exception as e:
        print(e)

finally:
    browser.close()


print("Done.")


