# HEKETON RTL prototype

The RTL prototype contains the AXI4-Lite register interface, authentication FSM, deterministic behavioral PUF model, SHA-256 core, and HMAC-SHA-256 controller. The PUF is a simulation/behavioral model and does not represent physical ring-oscillator measurements or establish physical uniqueness, entropy, or reliability.

## Authentication register map

- `0x00` CONTROL: bit 0 START, bit 1 RESET, bit 2 AUTH_START, bit 3 ZEROIZE
- `0x04` STATUS: bit 0 BUSY, bit 1 DONE, bit 2 AUTH_OK, bit 3 ERROR, bit 4 FAULT, bit 5 ZEROIZED
- `0x10–0x2C` CHALLENGE_0–7
- `0x30–0x3C` NONCE_0–3
- `0x40–0x5C` DATA_0–7
- `0x60–0x7C` RESPONSE_0–7 (computed HMAC output)
- `0x80–0x9C` EXPECTED_HMAC_0–7 (write-only supplied authentication tag)

`AUTH_OK` is asserted only after PUF completion, HMAC completion, and a full 256-bit match between the computed and expected HMAC. A mismatch sets DONE and ERROR and clears the output registers. ZEROIZE clears the PUF response, FSM key, HMAC/SHA intermediate state, response registers, and expected-tag registers.

## Simulation

From `sim/`, run `make test_sha test_puf test_fsm test_hmac test_integration`. These Verilator targets check SHA-256 known-answer vectors, the behavioral PUF interface, FSM security behavior, RFC 4231 HMAC case 1 against Python `hashlib/hmac`, and the top-level AXI authentication/zeroization flow.
