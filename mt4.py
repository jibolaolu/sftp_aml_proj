import os
import time
import win32gui
import win32con
import win32api
import cv2
import numpy as np
import pytesseract
import logging
from datetime import datetime

import win32ui

# Configure logging
logging.basicConfig(filename="mt4_autotrading.log", level=logging.INFO,
                    format="%(asctime)s - %(levelname)s - %(message)s")


def find_mt4_windows():
    logging.info("Searching for running MT4 terminals.")
    mt4_windows = []

    def callback(hwnd, extra):
        title = win32gui.GetWindowText(hwnd)
        if "MetaTrader 4" in title:
            mt4_windows.append((hwnd, title))

    win32gui.EnumWindows(callback, None)
    logging.info(f"Found {len(mt4_windows)} MT4 terminals.")
    return mt4_windows


# Function to detect AutoTrading status using OCR
def is_autotrading_enabled(hwnd):
    logging.info(f"Checking AutoTrading status using OCR for window {hwnd}.")
    x, y, w, h = 60, 30, 100, 40  # Adjust coordinates to the AutoTrading button position
    screenshot = capture_window(hwnd)
    if screenshot is not None:
        cropped = screenshot[y:y + h, x:x + w]
        text = pytesseract.image_to_string(cropped, config='--psm 6')
        logging.info(f"OCR detected text: {text}")
        return "AutoTrading" in text
    return False


# Function to capture a window screenshot
def capture_window(hwnd):
    logging.info(f"Capturing screenshot of window {hwnd}.")
    rect = win32gui.GetWindowRect(hwnd)
    x, y, w, h = rect[0], rect[1], rect[2] - rect[0], rect[3] - rect[1]

    hwndDC = win32gui.GetWindowDC(hwnd)
    mfcDC = win32ui.CreateDCFromHandle(hwndDC)
    saveDC = mfcDC.CreateCompatibleDC()
    saveBitMap = win32ui.CreateBitmap()
    saveBitMap.CreateCompatibleBitmap(mfcDC, w, h)
    saveDC.SelectObject(saveBitMap)
    saveDC.BitBlt((0, 0), (w, h), mfcDC, (0, 0), win32con.SRCCOPY)
    bmpinfo = saveBitMap.GetInfo()
    bmpstr = saveBitMap.GetBitmapBits(True)
    img = np.frombuffer(bmpstr, dtype=np.uint8).reshape((bmpinfo['bmHeight'], bmpinfo['bmWidth'], 4))
    saveDC.DeleteDC()
    mfcDC.DeleteDC()
    win32gui.ReleaseDC(hwnd, hwndDC)
    return img


# Function to read MT4 logs for AutoTrading status
def check_autotrading_from_logs(mt4_title):
    logging.info(f"Checking MT4 logs for AutoTrading status of {mt4_title}.")
    log_dir = os.path.expanduser("~\AppData\Roaming\MetaTrader 4\logs")
    try:
        latest_log = max([os.path.join(log_dir, f) for f in os.listdir(log_dir) if f.endswith(".log")],
                         key=os.path.getmtime)
        with open(latest_log, 'r', encoding='utf-8') as log_file:
            logs = log_file.readlines()
            for line in reversed(logs):
                if "AutoTrading enabled" in line:
                    logging.info(f"Log entry found: AutoTrading enabled for {mt4_title}.")
                    return True
                if "AutoTrading disabled" in line:
                    logging.info(f"Log entry found: AutoTrading disabled for {mt4_title}.")
                    return False
    except Exception as e:
        logging.error(f"Log reading error for {mt4_title}: {e}")
    return None


# Function to toggle AutoTrading based on user input
def toggle_autotrading(action):
    logging.info(f"User requested action: {action}")
    mt4_windows = find_mt4_windows()
    if not mt4_windows:
        logging.warning("No running MT4 terminals found.")
        return

    action_performed = []
    action_skipped = []
    enable = action == "ENABLE"

    for hwnd, title in mt4_windows:
        detected_state = is_autotrading_enabled(hwnd)
        log_state = check_autotrading_from_logs(title)

        if detected_state is not None:
            current_state = detected_state
        elif log_state is not None:
            current_state = log_state
        else:
            current_state = None

        if current_state is not None and ((enable and current_state) or (not enable and not current_state)):
            logging.info(f"Skipping {title}, already in the desired state.")
            action_skipped.append(title)
            continue

        logging.info(f"Toggling AutoTrading for {title}.")
        win32gui.SetForegroundWindow(hwnd)
        time.sleep(1)

        win32api.keybd_event(win32con.VK_CONTROL, 0, 0, 0)
        win32api.keybd_event(ord('E'), 0, 0, 0)
        time.sleep(0.5)
        win32api.keybd_event(ord('E'), 0, win32con.KEYEVENTF_KEYUP, 0)
        win32api.keybd_event(win32con.VK_CONTROL, 0, win32con.KEYEVENTF_KEYUP, 0)

        action_performed.append(title)
        time.sleep(1)

    # Log results
    if action_performed:
        logging.info(f"Action '{action}' performed on {len(action_performed)} MT4 terminals:")
        for terminal in action_performed:
            logging.info(f" - {terminal}")
    if action_skipped:
        logging.info(f"No action needed for {len(action_skipped)} MT4 terminals:")
        for terminal in action_skipped:
            logging.info(f" - {terminal}")


if __name__ == "__main__":
    user_action = input("Enter action (ENABLE/DISABLE): ").strip().upper()
    if user_action in ["ENABLE", "DISABLE"]:
        toggle_autotrading(user_action)
    else:
        logging.error("Invalid input. Please enter ENABLE or DISABLE.")
