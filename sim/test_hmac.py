#!/usr/bin/env python3
import hashlib
import hmac
import subprocess
import sys

key = bytes([0x0B]) * 20
message = b"Hi There"
expected = hmac.new(key, message, hashlib.sha256).hexdigest()
print(f"Python hashlib/hmac RFC 4231 case 1: {expected}")
raise SystemExit(subprocess.run([sys.argv[1], expected], check=False).returncode)
