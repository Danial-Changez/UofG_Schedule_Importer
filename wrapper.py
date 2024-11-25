import tkinter as tk
from tkinter import filedialog, messagebox
import subprocess
import os

class MyWindow(tk.Tk):
    def __init__(self):
        super().__init__()

        self.title("Schedule Processor")
        self.geometry("300x150")
        
        self.configure(bg="#2e2e2e")

        self.label = tk.Label(self, text="PDF-ICS Schedule Converter", font=("Arial", 14), bg="#2e2e2e", fg="white")
        self.label.pack(pady=5)

        self.subtitle = tk.Label(self, text="Guelph University", font=("Arial", 10), bg="#2e2e2e", fg="white")
        self.subtitle.pack(pady=5)

        self.button = tk.Button(self, text="Select Schedule PDF", command=self.on_button_clicked, bg="#4a4a4a", fg="white")
        self.button.pack(pady=20)

    def on_button_clicked(self):
        schedule_path = filedialog.askopenfilename(
            title="Select Your Schedule PDF",
            filetypes=[("PDF files", "*.pdf")]
        )
        if schedule_path:
            self.run_script(schedule_path)

    def run_script(self, schedule_path):
        script_path = os.path.join(os.path.dirname(__file__), 'script.sh')
        try:
            result = subprocess.run(['wsl', 'bash', '-c', f'bash "{script_path}" "{schedule_path}"'], check=True, capture_output=True, text=True)
            self.show_message("Success", result.stdout)
        except subprocess.CalledProcessError as e:
            self.show_message("Error", e.stderr)

    def show_message(self, title, message):
        messagebox.showinfo(title, message, parent=self) if title == "Success" else messagebox.showerror(title, message, parent=self)

if __name__ == "__main__":
    win = MyWindow()
    win.mainloop()