from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import requests
import re
import json
from datetime import datetime, timedelta, timezone
import uuid
import time

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
    data = json.loads(m.group(1))

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
        sec = entry.get("Section", {})
        
        # Shared course fields
        base = {
            "CourseName":     sec.get("CourseName"),
            "SectionNumber":  sec.get("Number"),
            "Credits":        sec.get("MinimumCredits"),
            "Instructors":    sec.get("Faculty", [])
        }
        
        # Create a row per meeting
        for meeting in sec.get("PlannedMeetings", []):
            if not meeting.get("StartTime") or not meeting.get("EndTime"):
                continue
            output.append({
                **base,
                "InstructionalMethod": meeting["InstructionalMethod"],
                "StartTime":           meeting["StartTime"],
                "EndTime":             meeting["EndTime"],
                "FormattedTime":       meeting["FormattedTime"],
                "DaysOfWeek":          meeting["DaysOfWeek"],
                "Location":            meeting["MeetingLocation"].strip(),
                "StartDate":           meeting["StartDateString"],
                "EndDate":             meeting["EndDateString"],
            })
    return output

def generate_ics(events: list[dict], output_file: str):
    cal_lines = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "CALSCALE:GREGORIAN"
    ]
    
    for ev in events:
        # Parse dates and times
        start_dt = datetime.strptime(
            f"{ev['StartDate']} {ev['StartTime']}",
            "%m/%d/%Y %I:%M %p"
        )
        end_dt   = datetime.strptime(
            f"{ev['StartDate']} {ev['EndTime']}",
            "%m/%d/%Y %I:%M %p"
        )
        
        # Build BYDAY from DaysOfWeek string
        dow = ev.get("DaysOfWeek", "")
        bydays = []
        if "Th" in dow:
            bydays.append("TH")
            dow = dow.replace("Th", "")
        mapping = {"M":"MO","T":"TU","W":"WE","F":"FR"}
        for char, code in mapping.items():
            if char in dow:
                bydays.append(code)
        byday_str = ",".join(bydays)

        until_dt = datetime.strptime(ev['EndDate'], "%m/%d/%Y") + timedelta(hours=23, minutes=59, seconds=59)
        uid = uuid.uuid4().hex + "@schedule"
        
        cal_lines += [
            "BEGIN:VEVENT",
            f"UID:{uid}",
            f"DTSTAMP:{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
            f"DTSTART:{start_dt.strftime('%Y%m%dT%H%M%S')}",
            f"DTEND:{end_dt.strftime('%Y%m%dT%H%M%S')}",
            f"RRULE:FREQ=WEEKLY;BYDAY={byday_str};UNTIL={until_dt.strftime('%Y%m%dT%H%M%S')}",
            f"SUMMARY:{ev['InstructionalMethod']} {ev['CourseName']}*{ev['SectionNumber']}",
            f"DESCRIPTION:Instructor(s): {', '.join(ev['Instructors'])}\\nCredits: {ev['Credits']}",
            f"LOCATION:{ev['Location']}",
            "END:VEVENT"
        ]

    cal_lines.append("END:VCALENDAR")
    
    with open(output_file, "w", encoding="UTF-8") as f:
        f.write("\n".join(cal_lines))

def main():
    start_time = time.perf_counter()
    term = "W24"
    
    # Fetch the schedule page HTML (handles login/MFA)
    html = fetch_page_info(term)
    
    # Extract the raw list of course dicts
    courses = extract_courses(html, term)
    sorted_results = sorted_courses(courses)
    ics_path = "../schedule.ics"
    generate_ics(sorted_results, ics_path)
    
    end_time = time.perf_counter()
    execution_time = end_time - start_time
    print(f"Wrote {len(courses)} courses to {ics_path} in {execution_time:.2f} seconds")
        
if __name__ == "__main__":
    main()