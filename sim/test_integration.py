#!/usr/bin/env python3
import hashlib
import hmac
import subprocess
import sys

challenge = list(range(1, 9))
nonce = list(range(0x10, 0x14))
data = list(range(0x20, 0x28))
mask32 = 0xFFFFFFFF
seed = 0x6D2B79F5
for word in reversed(challenge):
    seed = ((seed << 5) | (seed >> 27)) & mask32
    seed ^= word
    seed = ((seed << 1) | (((seed >> 31) ^ (seed >> 21) ^ (seed >> 1) ^ seed) & 1)) & mask32
if seed == 0:
    seed = 1
response = 0
lfsr = seed
for _ in range(256):
    response = ((response << 1) | (lfsr & 1)) & ((1 << 256) - 1)
    feedback = ((lfsr >> 31) ^ (lfsr >> 21) ^ (lfsr >> 1) ^ lfsr) & 1
    lfsr = ((lfsr << 1) | feedback) & mask32
key = response.to_bytes(32, "big")
message = b"".join(word.to_bytes(4, "big") for word in challenge + nonce + data)
tag = hmac.new(key, message, hashlib.sha256).hexdigest()
print(f"Python expected HMAC: {tag}")
raise SystemExit(subprocess.run([sys.argv[1], tag], check=False).returncode)
