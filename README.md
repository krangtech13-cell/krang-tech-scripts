# Krang Tech Scripts

Free Windows automation and security scripts from the **Krang Tech** YouTube channel, where I learn cybersecurity and Windows automation in public.

---

## krang-pc-maintenance.ps1

One script that cleans up your PC and checks its health, then saves a report to your Desktop.

**What it does**

1. Shows free space on each drive
2. Clears temp files (yours and Windows')
3. Empties the Recycle Bin
4. Checks your drives' health
5. Checks that Windows Defender is on and up to date
6. Checks for pending Windows updates
7. Shows how long since your last restart
8. Saves a report to your Desktop

Works on Windows 10 and 11 with the built-in PowerShell.

### How to run it

1. Download `krang-pc-maintenance.ps1` (click the file above, then the download button).
2. Right-click the Start button and choose **Terminal (Admin)**.
3. Go to your Downloads folder:
   ```
   cd $HOME\Downloads
   ```
4. **Test it first (deletes nothing):**
   ```
   powershell -ExecutionPolicy Bypass -File .\krang-pc-maintenance.ps1 -DryRun
   ```
5. **Run it for real:**
   ```
   powershell -ExecutionPolicy Bypass -File .\krang-pc-maintenance.ps1
   ```

Files that are in use get skipped, so it's safe to run any time. Running it without Admin still works, but skips a few steps.

### Read before you run

Always read a script before running it, including this one. It's plain text, so you can open it in Notepad and see exactly what it does.

---

## Disclaimer

These scripts are for educational purposes and are provided as-is, with no warranty. Use them at your own risk, and only on computers you own or have permission to manage.

---

📺 **Watch the videos:** search **Krang Tech** on YouTube# krang-tech-scripts
