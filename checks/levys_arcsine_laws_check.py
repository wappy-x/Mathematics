# Levy's arcsine laws for a year-long fair coin game: the last tie and the time in the lead, by five roads.
import math

S, N, PATHS, SEED = 0.1, 364, 10000, 20261123   # fraction of the year, tosses (one a day), simulated years, seed
n = N // 2                                     # ties can only happen on even days

def arcsine(s):                                # road 1: the formula (2/pi) arcsin sqrt(s)
    return 2 / math.pi * math.asin(math.sqrt(s))

def simpson(f, a, b, m):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, m)))

def phi(x): return math.exp(-x * x / 2) / math.sqrt(2 * math.pi)
def Phi(x): return 0.5 + simpson(phi, 0.0, x, 200)

def reflection_road(s):                        # road 2: P(|fresh motion over 1 - s| < |W_s|), no arcsin
    r = math.sqrt(s / (1 - s))
    return simpson(lambda z: 2 * phi(z) * (2 * Phi(r * z) - 1), 0.0, 9.0, 600)

def u_list(m):                                 # u[k] = chance of a tie on day 2k = C(2k, k) / 4^k
    u = [1.0]
    for k in range(1, m + 1): u.append(u[-1] * (2 * k - 1) / (2 * k))
    return u

def walk_product(m, s):                        # road 3a: sum of u[k] u[m-k] over ties on days 2k <= s * 2m
    u = u_list(m)
    return sum(u[k] * u[m - k] for k in range(int(s * m + 1e-9) + 1))

def walk_flow(days, d, p=0.5):                 # road 3b: probability flow, no reflection: P(last tie on day <= d)
    size, off = 2 * days + 3, days + 1
    f = [1.0] * size                           # f[x]: chance of no tie in the remaining days, starting at x
    for _ in range(days - d):
        f = [1.0] + [p * (0.0 if i + 1 == off else f[i + 1]) + (1 - p) * (0.0 if i - 1 == off else f[i - 1])
                     for i in range(1, size - 1)] + [1.0]
    q = [0.0] * size; q[off] = 1.0             # q[x]: chance the score is x on day d
    for _ in range(d):
        q = [0.0] + [p * q[i - 1] + (1 - p) * q[i + 1] for i in range(1, size - 1)] + [0.0]
    return sum(a * b for a, b in zip(q, f))

def show(label, v, w=10): print(f"{label:<44}{v:>{w}.4f}")

c = arcsine(S); show("1 formula (2/pi) arcsin sqrt(0.1)", c)
show("  sqrt(0.1)", math.sqrt(S)); show("  arcsin sqrt(0.1), radians", math.asin(math.sqrt(S)))
show("  arctan(1/3), the same angle", math.atan(1 / 3))
r2 = reflection_road(S); show("2 reflection road, no arcsin", r2)
assert abs(r2 - c) < 1e-6, "reflection road disagrees with the arcsine formula"
show("lead >= 90% of the year, either side, 2 x", 2 * c)
show("density at mid-year, 1/(pi sqrt(0.25))", 1 / (math.pi * math.sqrt(0.25)))
w364, f364 = walk_product(n, S), walk_flow(N, 36)
show("3 walk 364 days: last tie by day 36, product", w364); show("  same, probability flow", f364)
assert abs(w364 - f364) < 1e-12, "product law u u disagrees with the probability flow"
for m in (n, 10 * n, 100 * n):
    v = walk_product(m, S); print(f"  walk {2 * m:>6} tosses: P(last tie <= 10%) {v:.4f}  gap {v - c:+.4f}")
assert abs(walk_product(100 * n, S) - c) < 0.002, "the walk does not approach the arcsine law"
show("  tilted coin 0.52: last tie by day 36, flow", walk_flow(N, 36, 0.52))
u = u_list(n); ties_sum = sum(u[1:]); ties_id = (2 * n + 1) * u[n] - 1
show("expected ties in 364 days, sum of u", ties_sum); show("  identity (2n + 1) u_n - 1", ties_id)
assert abs(ties_sum - ties_id) < 1e-9

M = 16; counts_last, counts_lead = [0] * (M // 2 + 1), [0] * (M // 2 + 1)   # road 4: every 16-toss match
for bits in range(1 << M):
    pos = last = lead = 0
    for i in range(M):
        prev = pos; pos += 1 if bits >> i & 1 else -1
        if pos == 0: last = i + 1
        if prev > 0 or pos > 0: lead += 1
    counts_last[last // 2] += 1; counts_lead[lead // 2] += 1
law = [math.comb(2 * k, k) * math.comb(M - 2 * k, M // 2 - k) for k in range(M // 2 + 1)]
print("4 all 65536 matches of 16, k = 0..8:", " ".join(str(x) for x in law))
assert counts_last == law and counts_lead == law, "16-toss counts break the discrete arcsine law"
print("  last tie on day 2k, and Ana in the lead 2k rounds: both match")

state = SEED                                   # road 5: SplitMix64, one bit per toss
def rand64():
    global state
    state = (state + 0x9E3779B97F4A7C15) & (2**64 - 1); z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1); z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return z ^ (z >> 31)
hit_last = hit_lead = hit_ana = ties_total = 0
for _ in range(PATHS):
    pos = last = lead = ties = 0; word = 0
    for i in range(N):
        if i % 64 == 0: word = rand64()
        prev = pos; pos += 1 if word >> (i % 64) & 1 else -1
        if pos == 0: last = i + 1; ties += 1
        if prev > 0 or pos > 0: lead += 1
    hit_last += last <= 36; hit_lead += lead >= 328 or lead <= 36; hit_ana += lead >= 328; ties_total += ties
for label, hits, exact in [("5 sim: last tie by day 36", hit_last, w364), ("  one side leads >= 328 days", hit_lead, 2 * w364)]:
    p = hits / PATHS; se = math.sqrt(p * (1 - p) / PATHS)
    print(f"{label:<34}{p:>8.4f}  std err {se:.4f}  exact walk {exact:.4f}")
    assert abs(p - exact) < 4 * se, label
show("  Ana alone leads >= 328 days", hit_ana / PATHS); show("  average ties per year", ties_total / PATHS)
assert abs(ties_total / PATHS - ties_id) < 0.5

wrong_bin = 2 * sum(math.comb(N, j) for j in range(37)) / 2**N
show("wrong: last tie uniform over the year", S)
print(f"{'wrong: lead days as 364 independent coins':<44}{wrong_bin:>10.2e}")
show("wrong: one side only (Ana leads >= 90%)", c)
for s in (0.5, 0.01, 0.99): show(f"try: P(last tie <= {s})", arcsine(s))
show("try: lead >= 99% either side", 2 * arcsine(0.01))
tenths = [round(arcsine(j / 10) * 100, 2) for j in range(11)]
print("chart, arcsine CDF %   ", " ".join(f"{x:.2f}" for x in tenths))
print("chart, walk 364 days % ", " ".join(f"{walk_product(n, j / 10) * 100:.2f}" for j in range(11)))
print("bars, P(last tie in tenth) %", " ".join(f"{(arcsine((j + 1) / 10) - arcsine(j / 10)) * 100:.2f}" for j in range(10)))
assert abs(arcsine(0.5) - 0.5) < 1e-12, "the median of the last tie is not mid-year"
print("ALL CHECKS PASS")
