# RTL simulation

The simulation suite uses Verilator with C++ testbenches and Python reference calculations. From this directory, run:

```sh
make test_sha test_puf test_fsm test_hmac test_integration
```

Targets cover SHA-256 empty/`abc`/`hello` vectors, deterministic PUF reset/challenge/zeroize behavior, FSM security checks, actual HMAC RTL against RFC 4231 case 1, and an AXI-driven top-level integration test. The PUF test validates only the deterministic behavioral model; it does not model physical oscillator behavior.
