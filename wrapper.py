import tkinter as tk
from tkinter import filedialog, messagebox
import subprocess
import os


class MyWindow(tk.Tk):
    def __init__(self):
        super().__init__()

        self.title("Schedule Processor")
        self.geometry("400x300")
        self.center_window()

        self.configure(bg="#2e2e2e")

        # Add top padding
        self.label = tk.Label(self, text="", bg="#2e2e2e")
        self.label.pack(pady=1)  # Revert to original padding

        self.label = tk.Label(self, text="Guelph University", font=("Arial", 14, "bold"), bg="#2e2e2e", fg="white")
        self.label.pack(pady=0)  # Revert to original padding
        
        self.label = tk.Label(self, text="PDF-ICS Schedule Converter", font=("Arial", 14, "bold"), bg="#2e2e2e", fg="white")
        self.label.pack(pady=5)  # Revert to original padding

        self.button = tk.Button(self, text="Select Schedule PDF", command=self.on_button_clicked, bg="#4a4a4a", fg="white")
        self.button.pack(pady=20)  # Revert to original padding

        self.image_label = tk.Label(self, bg="#2e2e2e")
        self.image_label.pack(pady=10)  # Revert to original padding
        self.load_image()

        self.approval_label = tk.Label(self, text="Approved by the Diamond-Force Air Fryer Association, DAFA", font=("Arial", 8, "italic"), bg="#2e2e2e", fg="white")
        self.approval_label.pack(pady=7)  # Revert to original padding

    def center_window(self):
        self.update_idletasks()
        width = self.winfo_width()
        height = self.winfo_height()
        x = (self.winfo_screenwidth() // 2) - (width // 2)
        y = (self.winfo_screenheight() // 2) - (height // 2)
        self.geometry(f'{width}x{height}+{x}+{y}')

    def load_image(self):
        image_path = os.path.join(os.path.dirname(__file__), 'airfryer.png')
        self.image = tk.PhotoImage(file=image_path)
        self.image = self.image.subsample(4, 4)  # Scale by 25%
        self.image_label.config(image=self.image)  # Directly set the image
        self.image_label.image = self.image  # Keep a reference to avoid garbage collection

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