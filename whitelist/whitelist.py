#!/usr/bin/env python3

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options

chrome_options = Options()
chrome_options.add_argument("--headless")
driver = webdriver.Chrome(options=chrome_options)

try:
  driver.get("http://192.168.1.1/")
  password_field = driver.find_element(By.NAME, "password")
  password_field.send_keys("C457378N28", Keys.RETURN)
  driver.get("http://192.168.1.1/wlactrl.htm")
  select_element = Select(driver.find_element(By.NAME, "wlanAcEnabled"))
  selected_option = select_element.first_selected_option.text
  new_value = "Allow Listed" if selected_option == "Disable" else "Disable"
  select_element.select_by_visible_text(new_value)
  driver.find_element(By.NAME, "setFilterMode").click()
finally:
  driver.quit()
