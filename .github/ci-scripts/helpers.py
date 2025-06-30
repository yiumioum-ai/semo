import re
import sys

# ASCII color codes for terminal output
GREEN = "\033[92m"
YELLOW = "\033[93m"
PURPLE = "\033[35m"
RED = "\033[91m"
RESET = "\033[0m"

# Flush output to ensure immediate display
def log(message="", type="none"):
    message_prefix = ""
    if type == "info":
        message_prefix = f"{PURPLE}[INFO]{RESET}"
    elif type == "warning":
        message_prefix = f"{YELLOW}[WARNING]{RESET}"
    elif type == "error":
        message_prefix = f"{RED}[ERROR]{RESET}"
    elif type == "success":
        message_prefix = f"{GREEN}[SUCCESS]{RESET}"
    print(f"{message_prefix} {message}", flush=True)
    sys.stdout.flush()

# Sanitize text
def sanitize(text):
    return re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', text)