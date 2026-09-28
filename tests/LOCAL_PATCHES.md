The imported Linux v6.18.54 ntsync selftest has two local test-only corrections:

- `wake_all` checks that the created event descriptor is nonnegative. A
  descriptor need not be zero.
- `stress_wait` uses atomic loads and stores for its shared counter so the C
  compiler cannot cache a thread's counter value across its ioctl-based
  critical sections. It also detects overlapping sections and failed wait or
  unlock ioctls. The original plain `++stress_counter` lost increments under
  optimization even when every thread completed all 10,000 successful cycles.

Neither correction changes the kernel driver or the UAPI.
