import subprocess
import tkinter as tk
from tkinter import filedialog, messagebox
import os

def run_script(schedule_path):
    # Get the absolute path to script.sh
    script_path = os.path.join(os.path.dirname(__file__), 'script.sh')
    try:
        result = subprocess.run(['wsl', 'bash', script_path, schedule_path], check=True, capture_output=True, text=True)
        messagebox.showinfo("Success", result.stdout)
    except subprocess.CalledProcessError as e:
        messagebox.showerror("Error", e.stderr)

def select_file():
    schedule_path = filedialog.askopenfilename(title="Select Your Schedule PDF", filetypes=[("PDF files", "*.pdf")])
    if schedule_path:
        run_script(schedule_path)

# Create the main window
root = tk.Tk()
root.title("Schedule Processor")

# Create and place the button
button = tk.Button(root, text="Select Schedule PDF", command=select_file)
button.pack(pady=20)

# Run the application
root.mainloop()