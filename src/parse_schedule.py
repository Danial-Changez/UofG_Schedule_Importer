from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import requests
import re
import json

def fetch_page_info(term: str) -> str:
    
    # Configure chrome to suppress GPU and reduce logging data
    options = webdriver.ChromeOptions()
    options.add_argument("--disable-gpu")
    options.add_argument("--log-level=3")
    
    # Start Chrome WebDriver
    driver = webdriver.Chrome(
        service=ChromeService(ChromeDriverManager().install()), 
        options=options
    )

    url = f"https://colleague-ss.uoguelph.ca/Student/Planning/DegreePlans/PrintSchedule?termId={term}"
    try:
        # Open the schedule URL and wait (up to 10 minutes) for MFA/login
        driver.get(url)
        WebDriverWait(driver, 600).until(
            EC.url_contains("/PrintSchedule")
        )
        
        # Store cookies
        cookies = driver.get_cookies()
    finally:
        # Close browser
        driver.quit()
        
    # Create a requests session and replay the Selenium cookies into it
    sess = requests.Session()
    for ck in cookies:
        sess.cookies.set(ck['name'], ck['value'], domain=ck['domain'])
        
    # Fetch the same URL via requests and return HTML
    resp = sess.get(url)
    resp.raise_for_status()
    return resp.text

def extract_courses(html: str, term: str) -> list[dict]:
    # Load into BeautifulSoup for script tag extraction
    soup = BeautifulSoup(html, 'html.parser')

    # Grab the script tag text with "var result"
    script = next(
        (s.string for s in soup.find_all('script') 
        if s.string and s.string.strip().startswith("var result")),
        None
    )
    if not script: 
        raise RuntimeError("No result script found")

    # Isolate the JS object
    m = re.search(r"var\s+result\s*=\s*(\{[\s\S]*?\})\s*;", script)
    if not m:
        raise RuntimeError("Could not extract JS object")
    
    # Parse via json
    js_obj = m.group(1)
    data = json.loads(js_obj)

    # Navigate to Terms array and select correct terms for PlannedCourses
    terms = data["Terms"]
    planned = next(
        t["PlannedCourses"] for t in terms 
            if t["Code"] == term
        )
    return planned
        
def sorted_courses(raw: list[dict]) -> list[dict]:        
    output = []

    for entry in raw:
        # Metadata under section
        sec = entry["Section"]
        
        # Shared course fields
        course_name     = sec["CourseName"]
        section_number  = sec["Number"]
        min_credits     = sec["MinimumCredits"]
        instructors     = sec.get("Faculty", [])
        
        # Create a row per meeting
        for meeting in sec["PlannedMeetings"]:
            output.append({
                "CourseName":        course_name,
                "SectionNumber":     section_number,
                "MinimumCredits":    min_credits,
                "InstructionalMethod": meeting["InstructionalMethod"],
                "StartTime":           meeting["StartTime"],
                "EndTime":             meeting["EndTime"],
                "FormattedTime":       meeting["FormattedTime"],
                "DaysOfWeek":          meeting["DaysOfWeek"],
                "Location":            meeting["MeetingLocation"].strip(),
                "StartDate":           meeting["StartDateString"],
                "EndDate":             meeting["EndDateString"],
                "Instructors":         instructors
            })
    return output

def main():
    term = "W25"
    
    # Fetch the schedule page HTML (handles login/MFA)
    html = fetch_page_info(term)
    
    # Extract the raw list of course dicts
    courses = extract_courses(html, term)
    output_path = "../res/courses.json"
    
    # Write raw JSON for inspection/debugging
    with open(output_path, "w", encoding="UTF-8") as f:
        json.dump(courses, f, indent=2)

    # Sort results, then overwrite the same json
    sorted_results = sorted_courses(courses)
    with open(output_path, "w", encoding="UTF-8") as f:
        json.dump(sorted_results, f, indent=2)
    
    print(f"Wrote {len(courses)} courses to {output_path}")
        
if __name__ == "__main__":
    main()