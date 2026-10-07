# Birthday problem and coupon collector -- the check behind the card.
# Standard library only. Roads: exact formula, brute-force enumeration on a
# small calendar, a step-by-step count of the chance itself, and a seeded simulation.
import math

M64 = (1 << 64) - 1
class SplitMix64:                       # the random numbers, written out
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def day(self, d): return ((self.next() >> 32) * d) >> 32   # 0 .. d-1

def no_match(n, d):                     # road 1: product of shrinking fractions
    p = 1.0
    for i in range(n): p *= (d - i) / d
    return p

def brute_no_match(n, d):               # road 2: list every way n people can fall
    good = 0
    for code in range(d ** n):
        days = [(code // d ** j) % d for j in range(n)]
        good += len(set(days)) == n
    return good / d ** n

def harmonic(d): return sum(1.0 / k for k in range(1, d + 1))

def cover_dp(d, tmax):                  # road 2 for the collector: carry P(k days seen) forward
    p = [0.0] * (d + 1); p[0] = 1.0; mean = 0.0; median = None; cdf = []
    for t in range(1, tmax + 1):
        mean += 1.0 - p[d]              # E[T] = sum over t of P(T > t-1)
        q = [0.0] * (d + 1)
        for k in range(d + 1):
            if p[k] == 0.0: continue
            q[k] += p[k] * k / d
            if k < d: q[k + 1] += p[k] * (d - k) / d
        p = q; cdf.append(p[d])
        if median is None and p[d] >= 0.5: median = t
    return mean, median, cdf

D = 365
print("== birthdays: 365 equally likely days ==")
p23 = 1 - no_match(23, D)
print(f"n=22  P(shared) = {1 - no_match(22, D):.6f}")
print(f"n=23  P(shared) = {p23:.6f}   pairs = {23 * 22 // 2}")
n50 = next(n for n in range(1, D + 2) if 1 - no_match(n, D) > 0.5)
print(f"first n above one half = {n50}   sqrt(2 d ln 2) = {math.sqrt(2 * D * math.log(2)):.4f}")
approx = 1 - math.exp(-23 * 22 / (2 * D))
print(f"approx 1 - exp(-n(n-1)/2d) at 23 = {approx:.6f}")
for n in (40, 57, 70):
    print(f"n={n}  P(shared) = {1 - no_match(n, D):.6f}")
print("chart1," + ",".join(f"{1 - no_match(n, D):.2f}" for n in range(5, 65, 5)))

rng = SplitMix64(20260928); rooms = 20000; hits = 0
for _ in range(rooms):
    seen = [False] * D
    for _ in range(23):
        k = rng.day(D)
        if seen[k]: hits += 1; break
        seen[k] = True
ph = hits / rooms; se = math.sqrt(ph * (1 - ph) / rooms)
print(f"simulated 23-person rooms: {ph:.4f}  (standard error {se:.4f}, {rooms} rooms)")
assert abs(ph - p23) < 4 * se, "simulation disagrees with the product formula"

pb, pf = 1 - brute_no_match(4, 12), 1 - no_match(4, 12)
m50 = next(n for n in range(1, 14) if 1 - no_match(n, 12) > 0.5)
print(f"birth months, 4 people ({12 ** 4} lists): enumerated {pb:.6f}   formula {pf:.6f}   first n above one half = {m50}")
assert abs(pb - pf) < 1e-12, "enumeration disagrees with the product formula"
assert n50 == math.ceil(math.sqrt(2 * D * math.log(2))), "threshold and square-root rule disagree"

print("== what breaks ==")
print(f"match one fixed person, 22 others: {1 - (364 / 365) ** 22:.6f}")
print(f"add pair chances 253/365: {253 / 365:.6f}")
w = [1.2] * 182 + [0.8] * 183; tot = sum(w); e = [1.0] + [0.0] * 23
for x in w:                             # e[k]: sum over k distinct days of their chances
    for k in range(23, 0, -1): e[k] += e[k - 1] * x / tot
uneven = 1 - math.factorial(23) * e[23]
print(f"uneven calendar (half the year 1.5x the other): {uneven:.6f}")
assert uneven > p23, "an uneven calendar should raise the match chance"

print("== collecting all 365 days ==")
h = harmonic(D); exact = D * h
var = sum((1 - (D - i) / D) / ((D - i) / D) ** 2 for i in range(D))
print(f"H_365 = {h:.6f}   E[T] = 365 H_365 = {exact:.4f}   sd = {math.sqrt(var):.4f}")
print(f"d ln d = {D * math.log(D):.4f}   d(ln d + gamma) + 1/2 = {D * (math.log(D) + 0.5772156649) + 0.5:.4f}")
print("wait for new day number 1, 183, 365: " + ", ".join(f"{D / (D - i):.4f}" for i in (0, 182, 364)))
mean, med, cdf = cover_dp(D, 14000)
print(f"step-by-step mean = {mean:.4f}   median = {med}   P(done by 2365) = {cdf[2364]:.6f}")
assert abs(mean - exact) < 1e-6, "step-by-step mean disagrees with d H_d"
print(f"P(all days covered by 365 people) = {math.factorial(D) / D ** D:.3e}")
print(f"naive: wait 365 for each day = {D * D}")
fifths = [D * (harmonic(D - a) - harmonic(D - a - 73)) for a in range(0, D, 73)]
print("chart2," + ",".join(f"{x:.2f}" for x in fifths))

rng = SplitMix64(365); runs = 2000; s = s2 = 0.0
for _ in range(runs):
    seen = [False] * D; got = t = 0
    while got < D:
        t += 1; k = rng.day(D)
        if not seen[k]: seen[k] = True; got += 1
    s += t; s2 += t * t
m = s / runs; sem = math.sqrt((s2 / runs - m * m) / runs)
print(f"simulated collectors: mean {m:.2f}  (standard error {sem:.2f}, {runs} runs)")
assert abs(m - exact) < 4 * sem, "simulation disagrees with d H_d"

print("== a die, all six faces ==")
print(f"E[T] = 6 H_6 = {6 * harmonic(6):.4f}")
