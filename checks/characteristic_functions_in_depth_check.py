# Characteristic functions in depth -- the check behind the card.  Standard library
# only: math supplies sin, cos, exp, tan, atan, sqrt and hypot, none of which knows an answer.
# Four laws: a fair coin paying +1 or -1 dollar, the uniform law on [-sqrt 3, sqrt 3],
# the standard bell and the standard Cauchy (a lighthouse 1 km off a straight shore).
# The fingerprint is phi(t) = E[cos tX] + i E[sin tX]; all four laws are symmetric.
import math

R3, PI = math.sqrt(3.0), math.pi
def coin(t): return math.cos(t)
def unif(t): return 1.0 if t == 0 else math.sin(R3 * t) / (R3 * t)
def bell(t): return math.exp(-t * t / 2)
def cauchy(t): return math.exp(-abs(t))
def fake(t): return math.exp(-t * t * t * t)            # 1 at 0, at most 1, smooth, even: a fake
def z(x): return 0.0 if abs(x) < 5e-10 else x      # print a rounding-level number as 0

def simpson(f, a, b, n):                           # n even
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n))) * h / 3

# Road two: the defining average, a sum over the coin's two faces or an integral against a density.
def coin_sum(t): return (math.cos(t) + math.cos(-t)) / 2, (math.sin(t) + math.sin(-t)) / 2
def unif_int(t): return simpson(lambda x: math.cos(t * x) / (2 * R3), -R3, R3, 2000)
def bell_int(t): return simpson(lambda x: math.cos(t * x) * math.exp(-x * x / 2) / math.sqrt(2 * PI), -12, 12, 4000)
L = 2000.0                                         # Cauchy cut-off: the tail beyond is at most 2/(pi L)
def cauchy_int(t): return 2 * simpson(lambda x: math.cos(t * x) / (PI * (1 + x * x)), 0, L, 400000)

print("fingerprints at t = 1        closed form  defining average")
c_re, c_im = coin_sum(1.0)
rows = [("coin, cos t", coin(1), c_re), ("uniform, sin(r3 t)/(r3 t)", unif(1), unif_int(1)),
        ("bell, e^(-t^2/2)", bell(1), bell_int(1)), ("Cauchy, e^(-|t|)", cauchy(1), cauchy_int(1)),
        ("Cauchy again, at t = 2", cauchy(2), cauchy_int(2))]
for name, closed, avg in rows:
    print(f"  {name:27s}{closed:9.6f}  {avg:9.6f}")
    assert abs(closed - avg) < 2 / (PI * L)        # the Cauchy tail bound; the others are far closer
print(f"  sqrt 3 = {R3:.6f}; coin's sine part {z(c_im):.6f}; Cauchy cut-off {L:.0f}, tail bound {2 / (PI * L):.6f}")
for t in (PI, 5.0):
    print(f"at t = {t:.4f}: coin {coin(t):.6f}  uniform {unif(t):.6f}  bell {bell(t):.6f}  Cauchy {cauchy(t):.6f}")

# Positive definiteness at the rates 0, 0.5, 1: the matrix [g(tj - tk)] is [[1,a,b],[a,1,a],[b,a,1]].
def eig_closed(g):                                 # road one: the smallest eigenvalue in closed form
    a, b = g(0.5), g(1.0)
    return min(1 - b, (2 + b - math.sqrt(b * b + 8 * a * a)) / 2)
def eig_bisect(g):                                 # road two: first root of det(M - lam I), from below
    a, b = g(0.5), g(1.0)
    det = lambda l: (1 - l) * ((1 - l) * (1 - l) - a * a) - a * (a * (1 - l) - a * b) + b * (a * a - b * (1 - l))
    lo = -3.0
    while det(lo + 0.001) > 0: lo += 0.001
    hi = lo + 0.001
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if det(mid) > 0 else (lo, mid)
    return (lo + hi) / 2
print("rates 0, 0.5, 1: a = g(0.5), b = g(1), smallest eigenvalue by closed form / bisection")
for name, g in (("coin", coin), ("uniform", unif), ("bell", bell), ("Cauchy", cauchy), ("fake e^(-t^4)", fake)):
    e1, e2 = eig_closed(g), eig_bisect(g)
    print(f"  {name:14s}{g(0.5):9.6f}{g(1.0):9.6f}{z(e1):11.6f}{z(e2):11.6f}")
    assert abs(e1 - e2) < 1e-6 and (e1 > -1e-9) == (name != "fake e^(-t^4)")
for name, g in (("bell", bell), ("fake", fake)):
    a, b = g(0.5), g(1.0)
    print(f"  by hand, {name}: 2 + b = {2 + b:.6f}, b^2 = {b * b:.6f}, 8a^2 = {8 * a * a:.6f}")
print("four-times rule at t = 0.5: 1 - g(1)  against  4(1 - g(0.5))")
for name, g in (("coin", coin), ("bell", bell), ("fake e^(-t^4)", fake)):
    print(f"  {name:14s}{1 - g(1):9.6f}  {4 * (1 - g(0.5)):9.6f}")
assert 1 - fake(1) > 4 * (1 - fake(0.5)) and 1 - bell(1) <= 4 * (1 - bell(0.5))

# Lattice and fading.  |phi(t0)| = 1 at t0 != 0 exactly for laws on evenly spaced points.
die = lambda t: math.hypot(sum(math.cos(k * t) for k in range(1, 7)), sum(math.sin(k * t) for k in range(1, 7))) / 6
print(f"|phi| at the lattice rate: coin at pi {abs(coin(PI)):.6f}, die at 2 pi {die(2 * PI):.6f}")
peak = max(abs(unif(1 + k / 100)) for k in range(0, 2000))
print(f"largest |uniform phi| for t in [1, 21): {peak:.6f}; never 1 again")
T = 100.0
avg_coin = simpson(lambda t: coin(t) ** 2, -T, T, 20000) / (2 * T)
avg_die = simpson(lambda t: die(t) ** 2, -T, T, 20000) / (2 * T)
avg_unif = simpson(lambda t: unif(t) ** 2, -T, T, 20000) / (2 * T)
print(f"average of |phi|^2 over [-{T:.0f}, {T:.0f}] / sum of squared point chances")
print(f"  coin {avg_coin:.6f} / {0.5 ** 2 + 0.5 ** 2:.6f}; exact 1/2 + sin(2T)/(4T) = {0.5 + math.sin(2 * T) / (4 * T):.6f}")
die_exact = (6 + sum(math.sin((j - k) * T) / ((j - k) * T) for j in range(6) for k in range(6) if j != k)) / 36
print(f"  die {avg_die:.6f} / {6 / 36:.6f}; exact (6 + sum of sin(dT)/(dT))/36 = {die_exact:.6f}")
print(f"  uniform {avg_unif:.6f} / 0, bound pi/(2 r3 T) = {PI / (2 * R3 * T):.6f}")
assert abs(avg_coin - (0.5 + math.sin(2 * T) / (4 * T))) < 1e-6 and abs(avg_die - die_exact) < 1e-6
assert avg_unif < PI / (2 * R3 * T) and abs(die(2 * PI) - 1) < 1e-12 and peak < 0.6

# The Cauchy: a corner at 0, and the mean of n draws has the fingerprint of one draw.
h = 1e-4
print(f"slopes at 0 from the right / left: Cauchy {(cauchy(h) - 1) / h:.5f} / {(cauchy(-h) - 1) / -h:.5f};"
      f" bell {(bell(h) - 1) / h:.5f} / {(bell(-h) - 1) / -h:.5f}")
print(f"mean of 100 Cauchy draws: phi(1/100)^100 = {cauchy(1 / 100) ** 100:.6f}, one draw {cauchy(1):.6f}")
print(f"P(|one draw| > 1 km) = 1 - (2/pi) atan 1 = {1 - 2 / PI * math.atan(1):.6f}")

MASK = (1 << 64) - 1
state = 20261115                                   # SplitMix64, seed 20261115
def unit():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    x = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & MASK
    return (((x ^ (x >> 31)) >> 11) + 0.5) / 2.0 ** 53
M, N = 20000, 100
far_one = far_mean = 0
cos_sum = 0.0
for _ in range(M):
    total = 0.0
    for j in range(N):
        x = math.tan(PI * (unit() - 0.5))      # where the beam meets the shore, in km
        far_one += j == 0 and abs(x) > 1
        total += x
        cos_sum += math.cos(x)
    far_mean += abs(total / N) > 1
se = math.sqrt(0.25 / M)
print(f"simulated, {M} trials of {N} lighthouse flashes: P(|one| > 1) {far_one / M:.4f}, "
      f"P(|mean| > 1) {far_mean / M:.4f}, standard error {se:.4f}")
print(f"simulated phi(1) from {M * N} flashes: {cos_sum / (M * N):.4f}, against e^(-1) {cauchy(1):.4f}")
assert abs(far_one / M - 0.5) < 4 * se and abs(far_mean / M - 0.5) < 4 * se
assert abs(cos_sum / (M * N) - cauchy(1)) < 0.003

for name, g in (("coin", coin), ("uniform", unif), ("bell", bell)):
    print(f"figure, {name:8s}" + " ".join(f"{z(g(k / 2)):.2f}" for k in range(13)))
print("ALL CHECKS PASS")
