# The central limit theorem by fingerprints -- the check behind the card.
# Model (illustrative): a stock's daily log return is 1.5 % times Y, where Y is
# a Student t law with 3 degrees of freedom scaled to variance 1: density
# 2/(pi (1 + y^2)^2), fingerprint (1 + |s|) exp(-|s|).  A month is 21 days.
# Roads: closed-form fingerprint against its defining integral and simulation;
# inversion of the fingerprint against the closed-form law and simulation.
import math
SIGMA, N, LOSS, CUT = 1.5, 21, 10.0, 40.0
def phi_y(s):                            # fingerprint of one standardised day
    s = abs(s)
    return (1 + s) * math.exp(-s)
def phi_z(t, n):                         # line 1: sums -> products, scale -> argument
    return phi_y(t / math.sqrt(n)) ** n
def big_phi(x):                          # normal law, one series written out
    term, total, k = x, x, 0
    while abs(term) > 1e-17:
        k += 1
        term *= -x * x / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / math.sqrt(2 * math.pi)
def add(xs):                             # plain left-to-right sum, as in Rust
    total = 0.0
    for x in xs:
        total += x
    return total
def simpson(f, a, b, m):                 # m even
    h = (b - a) / m
    s = f(a) + f(b) + add((4 if k % 2 else 2) * f(a + k * h) for k in range(1, m))
    return s * h / 3
def cdf(x, n, cut=CUT):                  # Gil-Pelaez inversion of a real, even fingerprint
    g = lambda t: x if t == 0 else math.sin(t * x) / t * phi_z(t, n)
    return 0.5 + simpson(g, 0.0, cut, 40000) / math.pi
def tail_bound(n, cut=CUT):              # |integral beyond cut| / pi, phi_y falling on s > 0
    a = cut / math.sqrt(n)
    return phi_y(a) ** (n - 1) * math.sqrt(n) * (a + 2) * math.exp(-a) / cut / math.pi
def cdf_one_day(x):                      # closed form of the scaled t law, 3 degrees
    return 0.5 + (math.atan(x) + x / (1 + x * x)) / math.pi
state = 20261115                         # SplitMix64, seed 20261115
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def normals():                           # Box-Muller: two standard normals
    r = math.sqrt(-2 * math.log(1 - unif()))
    a = 2 * math.pi * unif()
    return r * math.cos(a), r * math.sin(a)
def day():                               # t law, 3 degrees, scaled to variance 1
    g0, g1 = normals()
    g2, g3 = normals()
    return g0 / math.sqrt(g1 * g1 + g2 * g2 + g3 * g3)
z_loss = -LOSS / (SIGMA * math.sqrt(N))
s = 1 / math.sqrt(N)
dens = lambda y: 2 / (math.pi * (1 + y * y) * (1 + y * y))
by_integral = 2 * simpson(lambda y: math.cos(s * y) * dens(y), 0.0, 400.0, 80000)
print(f"one day: sd {SIGMA:.1f} %; month: {N} days, sd {SIGMA * math.sqrt(N):.6f} %")
print(f"a monthly log return of -{LOSS:.0f} % (a price fall of {100 * (1 - math.exp(-LOSS / 100)):.2f} %) is z = "
      f"{z_loss:.6f} month standard deviations")
print(f"fingerprint of one day at s = 1/sqrt(21) = {s:.6f}: closed form {phi_y(s):.9f}")
print(f"  by its defining integral to |y| = 400 (tail at most 0.000000007): {by_integral:.9f}")
r = phi_y(s) - (1 - s * s / 2)
print(f"line 2: 1 - s^2/2 = {1 - s * s / 2:.6f}; remainder r = {r:.6f}; |s|^3/3 = {s ** 3 / 3:.6f}")
a21, b21 = phi_z(1, N), (1 - 1 / (2 * N)) ** N
print(f"line 3 at t = 1: fingerprint^21 {a21:.6f}; (1 - 1/42)^21 {b21:.6f}; gap {abs(a21 - b21):.6f}"
      f" <= 21|r| = {N * abs(r):.6f}")
print(f"line 4: exp(-1/2) = {math.exp(-0.5):.6f}; bell fingerprint by integral "
      f"{simpson(lambda y: math.cos(y) * math.exp(-y * y / 2), -10, 10, 4000) / math.sqrt(2 * math.pi):.6f}")
print("n, fingerprint of Z_n at t = 1, minus exp(-1/2), n|r(1/sqrt n)|")
for n in [1, 2, 5, 21, 100, 1000]:
    rn = phi_y(1 / math.sqrt(n)) - 1 + 1 / (2 * n)
    print(f"  {n:4d}  {phi_z(1, n):.6f}  {phi_z(1, n) - math.exp(-0.5):.6f}  {n * abs(rn):.6f}")
print("chart t, fingerprint n = 1, n = 21, exp(-t^2/2)")
for k in range(13):
    t = k / 4
    print(f"  {t:.2f}  {phi_z(t, 1):.4f}  {phi_z(t, N):.4f}  {math.exp(-t * t / 2):.4f}")
p1, p21, pn = cdf(z_loss, 1), cdf(z_loss, N), big_phi(z_loss)
print(f"chance of a month at or below z, by inversion (cut-off t = {CUT:.0f}, tail below 1e-12: "
      f"{'yes' if max(tail_bound(1), tail_bound(N)) < 1e-12 else 'no'}):")
print(f"  one day's law {p1:.6f} (closed form {cdf_one_day(z_loss):.6f}); month {p21:.6f}; bell {pn:.6f}")
print("far tail: chance at or below -3 and -4 standard deviations")
tails = {}
for n in [1, 5, 21, 100, 1000]:
    tails[n] = (cdf(-3, n), cdf(-4, n))
    print(f"  n = {n:4d}  {tails[n][0]:.6f}  {tails[n][1]:.6f}")
print(f"  bell      {big_phi(-3):.6f}  {big_phi(-4):.6f};  ratio at -4, n = 21: {tails[21][1] / big_phi(-4):.1f}")
print("bars: chance at or below -3, one # per 0.0002")
for n in [1, 5, 21, 100, 1000]:
    print(f"  n = {n:<5d}|{'#' * round(tails[n][0] / 0.0002):<35}| {tails[n][0]:.6f}")
print(f"  bell     |{'#' * round(big_phi(-3) / 0.0002):<35}| {big_phi(-3):.6f}")
M = 20000                                # quarters of 84 days = 80,000 months
hits = hits3 = moved = 0
cos_sum = sq_sum = 0.0
for q in range(M):
    days = [day() for _ in range(84)]
    for m in range(4):
        zm = add(days[21 * m: 21 * m + 21]) / math.sqrt(N)
        hits += zm <= z_loss
        hits3 += zm <= -3
        cos_sum += math.cos(zm)
    z21, z84 = add(days[:21]) / math.sqrt(21), add(days) / math.sqrt(84)
    moved += abs(z84 - z21) > 1
    sq_sum += (z84 - z21) * (z84 - z21)
p_sim, se = hits / (4 * M), math.sqrt(p21 * (1 - p21) / (4 * M))
print(f"simulation, {4 * M} months, seed 20261115: at or below z {p_sim:.6f} (se {se:.6f}); "
      f"below -3 {hits3 / (4 * M):.6f}")
print(f"  fingerprint at t = 1 by averaging cos: {cos_sum / (4 * M):.6f}")
p84 = 2 * cdf(-1, 84)                    # Z_84 - Z_21 has the law of Z_84: the days are symmetric
print(f"  Z_84 - Z_21: mean square {sq_sum / M:.6f} (expected 1 at every n); beyond 1 in {moved / M:.6f}"
      f" of quarters, exact {p84:.6f}, bell {2 * (1 - big_phi(1)):.6f}")
print(f"break 1, divide by n, not sqrt n: fingerprint at t = 1 is {phi_y(1 / N) ** N:.6f}, n = 1000:"
      f" {phi_y(1 / 1000) ** 1000:.6f}")
print(f"break 2, one day copied 21 times: fingerprint {phi_y(1):.6f}, chance at or below z {p1:.6f}")
print(f"break 3, Cauchy days: fingerprint of sum/sqrt n at t = 1: n = 21 {math.exp(-math.sqrt(21)):.6f},"
      f" n = 1000 {math.exp(-math.sqrt(1000)):.6f}; mean of n: {math.exp(-1):.6f} for every n")
assert abs(by_integral - phi_y(s)) < 1e-8                      # closed form = defining integral
assert abs(cdf(z_loss, 1) - cdf_one_day(z_loss)) < 1e-10       # inversion = closed-form law
assert abs(cdf(-3, 1) - cdf_one_day(-3)) < 1e-10
assert abs(a21 - b21) <= N * abs(r)                            # the product lemma
assert abs(p_sim - p21) < 4 * se                               # inversion = simulation
assert abs(cos_sum / (4 * M) - a21) < 0.006                    # fingerprint = simulation
assert abs(moved / M - p84) < 4 * math.sqrt(p84 * (1 - p84) / M)  # law of Z_84 = simulation
assert abs(phi_z(1, 10 ** 6) - math.exp(-0.5)) < 0.001         # the limit is the bell's
assert abs(big_phi(z_loss) - 0.5 * (1 + math.erf(z_loss / math.sqrt(2)))) < 1e-12  # library
print("ALL CHECKS PASS")
