import customtkinter as ctk
import threading
from parse_schedule import *

def run_schedule(term: str):
    try:
        html = fetch_page_info(term)
        courses = extract_courses(html, term)
        parsed = sorted_courses(courses)
        output_path = "../res/Schedule.ics"
        
        generate_ics(parsed, output_path)
        
        return f"✔ Parsed {len(parsed)} meetings → {output_path}"
    except Exception as e:
        return f"❌ Error: {str(e)}"
        
def start_task():
    button.configure(state="disabled", text="Running...")
    status_label.configure(text="Running... Please log in when prompted.")

    def worker():
        term = term_var.get().strip().upper() or "W24"
        result = run_schedule(term)
        status_label.configure(text=result)
        button.configure(state="normal", text="Start")
    
    threading.Thread(target=worker, daemon=True).start()

# GUI setup
ctk.set_appearance_mode("System")
ctk.set_default_color_theme("blue")

app = ctk.CTk()
app.title("UofG Schedule to ICS")
app.geometry("400x220")

term_var = ctk.StringVar()

title_label = ctk.CTkLabel(app, text="Enter Term Code:")
title_label.pack(pady=(20, 5))

term_entry = ctk.CTkEntry(app, textvariable=term_var, placeholder_text="i.e. W24")
term_entry.pack(pady=5)

button = ctk.CTkButton(app, text="Run Parser", command=start_task)
button.pack(pady=10)

status_label = ctk.CTkLabel(app, text="")
status_label.pack(pady=5)

app.mainloop()