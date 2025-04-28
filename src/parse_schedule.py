from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
from lxml import html
import requests
import re
import json

options = webdriver.ChromeOptions()
options.add_argument("--disable-gpu")
options.add_argument("--log-level=3")
driver = webdriver.Chrome(
    service=ChromeService(ChromeDriverManager().install()), 
    options=options
)

term = "W24"
schedule_url = f"https://colleague-ss.uoguelph.ca/Student/Planning/DegreePlans/PrintSchedule?termId={term}"

try:
    # Wait up to 5 minutes till the user is logged in
    driver.get(schedule_url)
    wait = WebDriverWait(driver, 300)
    wait.until(EC.url_contains("/Student/Planning/DegreePlans/PrintSchedule"))
    
    # Store cookies
    selenium_cookies = driver.get_cookies()
finally:
    driver.quit

# Start a session using selenium cookies 
session = requests.Session()
for cookie in selenium_cookies:
    session.cookies.set(cookie['name'], cookie['value'], domain=cookie['domain'])
    
resp = session.get(schedule_url)
resp.raise_for_status()

html = resp.text
soup = BeautifulSoup(html, 'html.parser')

# Grab the script tag text
script = next(
    (s.string for s in soup.find_all('script') 
     if s.string and s.string.strip().startswith("var result")),
    None
)
if not script: raise RuntimeError("No result script found")

# Isolate the JS object
m = re.search(r"var\s+result\s*=\s*(\{[\s\S]*?\})\s*;", script)
if not m: raise RuntimeError("Could not extract JS object")
js_obj = m.group(1)

# Parse via json5
data = json.loads(js_obj)

# Transfer into the Python dict
terms = data["Terms"]
output_path = "../res/results.json"
planned = next(t["PlannedCourses"] for t in terms if t["Code"] == term)

with open(output_path, "w", encoding="UTF-8") as f:
    json.dump(planned, f, indent=2)
    
with open(output_path, encoding="UTF-8") as f:
    courses = json.load(f)
    
output = []

for entry in courses:
    sec = entry["Section"]
    
    # Top-level course info
    course_name     = sec["CourseName"]
    section_number  = sec["Number"]
    min_credits     = sec["MinimumCredits"]
    instructors     = sec.get("Faculty", [])
    
    for m in sec["PlannedMeetings"]:
        output.append({
            "CourseName":        course_name,
            "SectionNumber":     section_number,
            "MinimumCredits":    min_credits,
            "InstructionalMethod": m["InstructionalMethod"],
            "StartTime":           m["StartTime"],
            "EndTime":             m["EndTime"],
            "FormattedTime":       m["FormattedTime"],
            "DaysOfWeek":          m["DaysOfWeek"],
            "Location":            m["MeetingLocation"].strip(),
            "StartDate":           m["StartDateString"],
            "EndDate":             m["EndDateString"],
            "Instructors":         instructors
        })
        
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(output, f, indent=2)

print(f"Wrote {len(planned)} courses to {output_path}")