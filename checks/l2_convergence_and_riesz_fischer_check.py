# Convergence in energy -- the check behind the card.  Standard library only.
# Two signals on one cycle of phase x in [-pi, pi):
#   the house siren, a +-1 V square wave (220 cycles a second), whose
#   coefficients are 2/(i pi n) on odd n;
#   the list 1/n, as cosine amounts in volts, which Riesz-Fischer turns into
#   a signal; the card identifies it as f(x) = -log(2 sin(|x|/2)).
# Every energy is (1/2pi) times the integral of the square over one cycle.
# Roads: the coefficient ledger (sums of |c_n|^2), Simpson's rule on the
# signal itself, and integral bounds on the tails.  Nothing imported knows
# the answer; math gives only sin, cos, log, sqrt and pi.
import math
PI = math.pi

def simpson(g, a, b, m=4000):            # Simpson's rule, m even slices
    h = (b - a) / m
    s = g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, m))
    return s * h / 3

def siren(x):                            # the square wave: +1 V on (0, pi), -1 V on (-pi, 0)
    return 1.0 if x > 0 else -1.0

def siren_sum(N, x):                     # S_N of the square wave, odd k <= N
    return 4 / PI * sum(math.sin(k * x) / k for k in range(1, N + 1, 2))

def siren_gap_ledger(N):                 # 1 - energies of harmonics |n| <= N
    return 1 - 8 / PI ** 2 * sum(1 / k ** 2 for k in range(1, N + 1, 2))

def siren_gap_direct(N):                 # (1/2pi) int (f - S_N)^2, by symmetry
    return simpson(lambda x: (1 - siren_sum(N, x)) ** 2, 0, PI) / PI

def log_signal(x):                       # the signal the list 1/n builds
    return -math.log(2 * math.sin(abs(x) / 2))

def log_sum(N, x):                       # P_N: cosines with amounts 1/n, n <= N
    return sum(math.cos(n * x) / n for n in range(1, N + 1))

def cycle_mean(g):                       # (1/pi) int_0^pi g dx for an even g;
    # x = pi u^3 tames the spike at x = 0, where the integrand tends to 0
    return simpson(lambda u: 0.0 if u == 0 else 3 * u * u * g(PI * u ** 3), 0, 1)

def tail(N, M):                          # (1/2) sum 1/n^2 for N < n <= M
    return 0.5 * sum(1 / n ** 2 for n in range(N + 1, M + 1))

f6 = lambda v: f"{v:.6f}"
print("== the siren: +-1 V square wave, 220 cycles a second ==")
print(f"switches per second {2 * 220}; odd harmonics at {220}, {3 * 220}, {5 * 220} Hz and up")
int_sq = simpson(lambda x: siren(x) ** 2, -PI, PI)  # int f^2 over a cycle, by Simpson
print(f"energy (1/2pi) int f^2 = {f6(int_sq / (2 * PI))} V^2; harmonic pair +-n holds 8/(pi^2 n^2)")
print("N | gap by ledger | gap by Simpson | lower 4/(pi^2 (N+2)) | upper 4/(pi^2 N)")
for N in (1, 3, 9, 99):
    led, direct = siren_gap_ledger(N), siren_gap_direct(N)
    lo, hi = 4 / (PI ** 2 * (N + 2)), 4 / (PI ** 2 * N)
    print(f"{N} | {f6(led)} | {f6(direct)} | {f6(lo)} | {f6(hi)}")
    assert abs(led - direct) < 1e-8                        # ledger = signal
    assert lo < led < hi                                   # tail bounds hold
p1, p3 = 8 / PI ** 2, 8 / (9 * PI ** 2)
print(f"worked N = 3: pair 1 = {f6(p1)}, pair 3 = {f6(p3)}, kept = {f6(p1 + p3)}, gap = {f6(1 - p1 - p3)} V^2")
print(f"CD copy keeps odd harmonics up to 99: {99 * 220} Hz <= 22050 Hz < {101 * 220} Hz")
print(f"CD copy misses {100 * siren_gap_ledger(99):.4f} % of the siren's energy")
odd = sum(1 / k ** 2 for k in range(1, 1000, 2))
print(f"Parseval on the siren: sum of 1/n^2 over odd n <= 999 = {f6(odd)}, "
      f"tail between {f6(1 / 2002)} and {f6(1 / 1998)}")
print(f"pi^2/8 = {PI ** 2 / 8:.9f} lies between {odd + 1 / 2002:.9f} and {odd + 1 / 1998:.9f}")
assert odd + 1 / 2002 < PI ** 2 / 8 < odd + 1 / 1998
print("chart, N | rms gap sqrt(gap) V | overshoot S_N(pi/(N+1)) - 1 V")
for N in (1, 3, 5, 9, 19, 49, 99, 199):
    over = siren_sum(N, PI / (N + 1)) - 1
    print(f"chart, {N} | {math.sqrt(siren_gap_ledger(N)):.3f} | {over:.3f}")
peak = siren_sum(999, PI / 1000) - 1
print(f"overshoot at N = 999: {f6(peak)} V; it does not go to 0")
assert peak > 0.178

print("== Riesz-Fischer: the list of cosine amounts 1/n V ==")
energy_list = PI ** 2 / 12
part = 0.5 * sum(1 / n ** 2 for n in range(1, 100001))
print(f"list energy: (1/2) sum 1/n^2 = pi^2/12 = {f6(energy_list)} V^2")
print(f"list energy summed to n = 100000: {f6(part)}, tail below {f6(0.5 / 100000)}")
energy_sig = cycle_mean(lambda x: log_signal(x) ** 2)
print(f"signal energy by Simpson, -log(2 sin(|x|/2)) squared: {f6(energy_sig)} V^2")
assert abs(energy_sig - energy_list) < 1e-6                # Parseval, both sides
assert 0 < energy_list - part < 0.5 / 100000
for N, M in ((10, 100), (100, 1000), (1000, 10000)):
    g = tail(N, M)
    print(f"Cauchy gap ||P_{M} - P_{N}||^2 = {f6(g)} <= 1/(2N) = {f6(0.5 / N)}")
    assert g < 0.5 / N
print("n | coefficient of the signal by Simpson | list value 1/(2n)")
for n in (1, 2, 3, 10):
    c = cycle_mean(lambda x: log_signal(x) * math.cos(n * x))
    print(f"{n} | {f6(c)} | {f6(1 / (2 * n))}")
    assert abs(c - 1 / (2 * n)) < 1e-6                     # rebuilt signal has the list
print("N | gap ||f - P_N||^2 by Simpson | by the list's tail")
for N in (1, 3, 10):
    direct = cycle_mean(lambda x: (log_signal(x) - log_sum(N, x)) ** 2)
    led = energy_list - 0.5 * sum(1 / n ** 2 for n in range(1, N + 1))
    print(f"{N} | {f6(direct)} | {f6(led)}")
    assert abs(direct - led) < 1e-6
print(f"at x = pi/2: f = {f6(log_signal(PI / 2))} V, P_1000 = {f6(log_sum(1000, PI / 2))} V")
for N in (10, 1000):
    print(f"at x = 0: P_{N}(0) = sum of 1/n = {f6(log_sum(N, 0))} V, still rising")
print("bars, energy of harmonic n = 1/(2n^2):", ", ".join(f6(0.5 / n ** 2) for n in range(1, 6)))

print("== what breaks ==")
for N in (1000, 1000000):
    h = 0.5 * sum(1 / n for n in range(1, N + 1))
    print(f"list 1/sqrt(n): energy of P_{N} = {f6(h)} V^2, no limit")
half = 4 / PI ** 2 * sum(1 / k ** 2 for k in range(1, 1000000, 2))  # n = 1, 3, ..., 999999
full = 2 * half                                        # the ledger over both signs of n
assert abs(int_sq / (2 * PI) - full) < 1e-6            # Parseval on the siren, both sides
print(f"no 1/2pi: int f^2 over a cycle = {f6(int_sq)} against sum |c_n|^2 = {f6(full)}")
print(f"positive n only: sum |c_n|^2 = {f6(half)} against {f6(full)}")
print(f"judged by the largest error: N = 99 rms gap {f6(math.sqrt(siren_gap_ledger(99)))} V, "
      f"overshoot {f6(siren_sum(99, PI / 100) - 1)} V")
print("ALL CHECKS PASS")
