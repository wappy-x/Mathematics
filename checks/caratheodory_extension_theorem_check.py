# Caratheodory's extension theorem -- the check behind the card.  Standard
# library only; Fraction keeps every duration exact.  A shift is a half-open
# stretch of hours [a, b), and the premeasure gives each its duration.  Roads:
# exact sums on the algebra, outer covers squeezing a set from outside, a
# seeded random sample, a small algebra listed in full, three counterexamples.
from fractions import Fraction as F

def dur(pieces):                         # the premeasure: add durations of disjoint shifts
    return sum((F(b) - F(a) for a, b in pieces), F(0))

def merge(pieces):                       # the same set written as few shifts as possible
    out = []
    for a, b in sorted((F(a), F(b)) for a, b in pieces):
        if out and a <= out[-1][1]:
            out[-1] = (out[-1][0], max(out[-1][1], b))
        else:
            out.append((a, b))
    return out

def inter(p, q):                         # intersection of two finite unions of shifts
    return [(max(a, c), min(b, d)) for a, b in p for c, d in q if max(a, c) < min(b, d)]

def comp(q):                             # complement inside the day [0, 24)
    out, x = [], F(0)
    for a, b in merge(q):
        if x < a:
            out.append((x, a))
        x = max(x, b)
    return out + ([(x, F(24))] if x < 24 else [])

def split(a, b, n):                      # [a, b) cut into halves of what is left: n pieces
    cuts = [F(b) - (F(b) - F(a)) / 2 ** k for k in range(n + 1)]
    return [(cuts[k], cuts[k + 1]) for k in range(n)]

def fmt2(x):                             # exact rational to two decimals, halves rounded up
    q = (x * 100 + F(1, 2)) // 1
    return f"{q // 100}.{q % 100:02d}"

def num(x):                              # dyadic coordinate, printed the same way in Rust
    return str(int(x)) if x.denominator == 1 else repr(float(x))

def burst(k):                            # pager burst k: first half of [24 - 2^(1-k), 24 - 2^-k)
    s = 24 - F(2) ** (1 - k)
    return (s, s + F(1, 2 ** (k + 1)))

def in_pager(t):                         # float road: find t's slot in [23, 24), then its half
    k = 1
    while t >= 24.0 - 0.5 ** k and k < 60:
        k += 1
    return t < 24.0 - 2.0 * 0.5 ** k + 0.5 ** (k + 1)

MASK = (1 << 64) - 1
def splitmix(s):                         # SplitMix64, written out; returns (state, draw)
    s = (s + 0x9E3779B97F4A7C15) & MASK
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return s, z ^ (z >> 31)

early, late, night = (6, 14), (14, 22), (22, 30)
print(f"shift durations: early {dur([early])}, late {dur([late])}, night {dur([night])} hours")
one_way, other_way = dur([early, late]), dur(merge([early, late]))
print(f"early and night together: {dur([early, night])}; [6, 22) as two shifts {one_way}, as one {other_way}")
cut8 = split(6, 14, 30)
sums = [dur(cut8[:n]) for n in range(1, 7)]
print("early shift cut into halves of what is left, sums after 1..6 pieces:", ", ".join(map(str, sums)))
print(f"left over after 30 pieces: {F(8) - dur(cut8)} hours")
for n in (1, 10, 100, 1000):
    print(f"cover n={n}: instant 14 inside [14, 14 + 1/n) -> {dur([(14, 14 + F(1, n))])}; "
          f"closed [6, 14] inside [6, 14 + 1/n) -> {dur([(6, 14 + F(1, n))])}")
print("first five bursts, minutes long: " + ", ".join(num(60 * dur([burst(k)])) for k in range(1, 6))
      + "; starting at minute " + ", ".join(num(60 * (burst(k)[0] - 23)) for k in range(1, 6)))
inner = {n: dur([burst(k) for k in range(1, n + 1)]) for n in range(1, 41)}
outer = {n: inner[n] + dur([(24 - F(1, 2 ** n), 24)]) for n in range(1, 41)}
for n in range(1, 7):
    print(f"chart, n={n}: inner {fmt2(60 * inner[n])} min, outer {fmt2(60 * outer[n])} min")
geometric = F(1, 4) / (1 - F(1, 2))      # first burst 1/4 hour, each next one half as long
print(f"pager set: geometric sum {geometric} hour = {60 * geometric} min; after 40 bursts the gap is {outer[40] - inner[40]}")
SEED = 20260929
state, hits, N = SEED, 0, 200000
for _ in range(N):
    state, z = splitmix(state)
    hits += in_pager(23.0 + (z >> 11) / 2.0 ** 53)
tol = 4 * 60 * (0.25 / N) ** 0.5                                                  # four standard errors
print(f"random sample, {N} times in [23, 24), seed {SEED}: {hits} hits, {60 * hits / N:.3f} min, allowed {tol:.3f}")
atoms = [(0, 6), (6, 14), (14, 22), (22, 24)]
algebra = [[atoms[i] for i in range(4) if m >> i & 1] for m in range(16)]
def outer_fin(p):                        # outer measure from the small algebra: atoms p touches
    return sum((dur([at]) for at in atoms if inter(p, [at])), F(0))
tests = algebra + [[(0, 3)], [(3, 6)], [(5, 15)], [(13, 23)], [(1, 2), (20, 21)]]
good = sum(outer_fin(inter(t, a)) + outer_fin(inter(t, comp(a))) == outer_fin(t) for a in algebra for t in tests)
e, t = [(0, 3)], [(0, 6)]
split_sum = outer_fin(inter(t, e)) + outer_fin(inter(t, comp(e)))
print(f"small algebra from the rota's day boundaries: {len(algebra)} sets; criterion holds {good} of {16 * len(tests)}")
print(f"[0, 3) is not in it: outer {outer_fin(e)}; splitting [0, 6) gives {split_sum}, not {outer_fin(t)}")
flag = lambda p: 1 if any(b == 24 for a, b in merge(p)) else 0     # 1 when the set runs up to 24
cut24 = split(0, 24, 20)
print(f"end flag: first {len(cut24)} halving pieces of the day score {sum(flag([p]) for p in cut24)}, the day scores {flag([(0, 24)])}, "
      f"[0, 12) and [12, 24) score {flag([(0, 12)])} + {flag([(12, 24)])}; pieces fill 24 - {24 - dur(cut24)} hours")
counts = [len({F(p, q) for q in range(1, Q + 1) for p in range(6 * q, 14 * q)}) for Q in (1, 2, 4, 8, 16)]
print(f"rational times in [6, 14) with denominator up to 1, 2, 4, 8, 16: {counts}; doubled {[2 * c for c in counts]}")
at14 = len({F(p, q) for q in range(1, 17) for p in range(14 * q, 14 * q + 1)})
print(f"instant 14: counting rational times {at14}, doubled {2 * at14}")
nu = lambda p: 2 * dur(inter(p, [(0, 6), (12, 18)]))
for name, p in (("[0, 12)", [(0, 12)]), ("[6, 18)", [(6, 18)]), ("[0, 24)", [(0, 24)]), ("[6, 12)", [(6, 12)])):
    print(f"two measures on {name}: duration {dur(p)}, other {nu(p)}")
x = lambda h: 30 + F(25, 2) * (F(h) - 6)
z = lambda h: 30 + 300 * (F(h) - 23)
print("figure, rota:", ", ".join(f"{num(x(a))}-{num(x(b))}" for a, b in (early, late, night, (23, 24))))
print("figure, zoom:", ", ".join(f"{num(z(a))}-{num(z(b))}" for a, b in map(burst, range(1, 6))))
assert all(sums[n - 1] == 8 - F(8, 2 ** n) for n in range(1, 7)) and one_way == other_way == 16
assert all(inner[n] + F(1, 2 ** (n + 1)) == geometric for n in range(1, 41))     # loop sum vs series
assert abs(60 * hits / N - 60 * geometric) < tol                                  # sample vs series
assert good == 16 * len(tests) and split_sum == 12 != outer_fin(t)
assert sum(flag([p]) for p in cut24) == 0 != flag([(0, 24)]) and 24 - dur(cut24) == F(24, 2 ** len(cut24))
assert nu([(0, 12)]) == 12 and nu([(6, 18)]) == 12 and nu([(6, 12)]) != dur([(6, 12)])
print("ALL CHECKS PASS")
