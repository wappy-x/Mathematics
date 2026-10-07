# Infinitely many coin tosses from one dart -- the check behind the card.
# Standard library only.  Roads: (1) one dart x = 0.7236 m, its digits read by
# exact doubling and split two ways; (2) Lebesgue measure of digit events,
# counted exactly on the 4,096 dyadic cells of level 12 and set against the
# product rule 0.5^n; (3) a simulation: SplitMix64, seed 20260929, 200,000
# darts, each x held to 128 binary digits.
from fractions import Fraction as Fr
def digits(p, q, n):                         # first n binary digits of p/q, by doubling
    out = []
    for _ in range(n):
        p *= 2
        out.append(1 if p >= q else 0)
        p -= q * out[-1]
    return out
def slot(n):                                 # position n = 2^(k-1) * (2j - 1)  ->  (k, j)
    k = 1
    while n % 2 == 0:
        n, k = n // 2, k + 1
    return k, (n + 1) // 2
def split(ds, count):                        # U_k = sum of digit(slot (k, j)) / 2^j
    u = [Fr(0)] * count
    for n, d in enumerate(ds, start=1):
        k, j = slot(n)
        if k <= count:
            u[k - 1] += Fr(d, 2 ** j)
    return u
def dec(v): return f"{float(v):.6f}"
# ---- road 1: one dart ----
ds = digits(1809, 2500, 320)                 # x = 0.7236 = 1809/2500
y, dbl = Fr(1809, 2500), []
for _ in range(4):
    y = 2 * y; dbl.append(f"{float(y):.4f}"); y -= int(y)
print("doubling 0.7236 four times:", ", ".join(dbl))
print("dart x = 0.7236 m, binary digits 1-16:", " ".join(map(str, ds[:16])))
print("position 1-16 goes to uniform k:     ", " ".join(str(slot(n)[0]) for n in range(1, 17)))
U = split(ds, 4)
by_slicing = [sum(Fr(d, 2 ** (j + 1)) for j, d in enumerate(ds[2 ** k - 1::2 ** (k + 1)][:20])) for k in range(4)]
print("U1..U4 from 20 digits each:", ", ".join(dec(v) for v in by_slicing))
print(f"dart 1 = (U1, U2) = ({dec(by_slicing[0])}, {dec(by_slicing[1])}); dart 2 = (U3, U4) = ({dec(by_slicing[2])}, {dec(by_slicing[3])})")
print("die rolls floor(6U) + 1:", [int(6 * v) + 1 for v in by_slicing])
assert all(abs(U[k] - by_slicing[k]) < Fr(1, 2 ** 20) for k in range(4))   # two readings of the split
x_px = 30 + 300 * Fr(1809, 2500)
print(f"figure, x scale 30 + 300x px; dart at {float(x_px):.2f} px; digit-1 cells row 1 [0.5,1], row 2 [0.25,0.5] [0.75,1], row 3 [0.125,0.25] [0.375,0.5] [0.625,0.75] [0.875,1]")
# ---- road 2: Lebesgue measure on the 4,096 cells of level 12 ----
M = 12
cells = [digits(2 * i + 1, 2 ** (M + 1), M) for i in range(2 ** M)]      # digits of each cell's midpoint
worst = Fr(0)
for n in range(1, M + 1):
    tally = {}
    for c in cells:
        tally[tuple(c[:n])] = tally.get(tuple(c[:n]), 0) + 1
    assert len(tally) == 2 ** n
    worst = max([worst] + [abs(Fr(t, 2 ** M) - Fr(1, 2) ** n) for t in tally.values()])
print(f"all 8,190 words of lengths 1 to 12: measure = 0.5^n, largest gap {worst}")
pair = Fr(sum(1 for c in cells if c[1] == 1 and c[4] == 0 and c[6] == 1), 2 ** M)
print(f"P(d2 = 1, d5 = 0, d7 = 1) = {float(pair)} by counting cells; 0.5^3 = {0.5 ** 3}")
combos = {tuple(split(c, 4)) for c in cells}
print(f"U1..U4 read from 12 digits: 64 x 8 x 4 x 2 = {64 * 8 * 4 * 2} value combinations, {len(combos)} distinct, each measure 1/4096")
rect = Fr(sum(1 for c in cells if split(c, 2)[0] < Fr(1, 2) and split(c, 2)[1] < Fr(1, 4)), 2 ** M)
print(f"P(U1 < 0.5, U2 < 0.25) = {float(rect)} by counting cells; 0.5 x 0.25 = {0.5 * 0.25}")
assert worst == 0 and pair == Fr(1, 8) and len(combos) == 4096 and rect == Fr(1, 2) * Fr(1, 4)
# ---- what breaks ----
for m in (4, 8, 12, 16):                     # U from digits 1..m, V from digits 2..m: a reused digit
    us, vs = [], []
    for i in range(2 ** m):
        c = digits(2 * i + 1, 2 ** (m + 1), m)
        us.append(sum(Fr(d, 2 ** (j + 1)) for j, d in enumerate(c)))
        vs.append(sum(Fr(d, 2 ** j) for j, d in enumerate(c) if j >= 1))
    N = 2 ** m; mu, mv = sum(us) / N, sum(vs) / N
    cov = sum((a - mu) * (b - mv) for a, b in zip(us, vs)) / N
    vu, vv = sum((a - mu) ** 2 for a in us) / N, sum((b - mv) ** 2 for b in vs) / N
    corr = float(cov) / (float(vu) * float(vv)) ** 0.5
    print(f"shifted digits, m = {m:2d}: correlation of U and V = {corr:.6f}")
var, cov_d1 = Fr(1, 12), Fr(3, 8) - Fr(1, 2) * Fr(1, 2)   # Var U; Cov(U, d1) = E[U d1] - E[U] E[d1]
limit = (2 * var - cov_d1) / var             # V = 2U - d1, worked on the card
print(f"shifted digits, by hand: Var U = {dec(var)}, Cov(U, d1) = {dec(cov_d1)}, Cov(U, V) = {dec(2 * var - cov_d1)}, limit {float(limit)}")
assert abs(corr - float(limit)) < 1e-3
cdf = lambda a: a * a                        # a dart with density 2x: P(x <= a) = a^2
anti = [1 - cdf(Fr(1, 2)), cdf(Fr(1, 2)) - cdf(Fr(1, 4)) + 1 - cdf(Fr(3, 4)), 1 - cdf(Fr(3, 4))]
mid = [Fr(0)] * 3                            # the same three chances by midpoint sums
for i, c in enumerate(cells):
    w = 2 * Fr(2 * i + 1, 2 ** (M + 1)) / 2 ** M
    mid[0] += w * c[0]; mid[1] += w * c[1]; mid[2] += w * c[0] * c[1]
print(f"density-2x dart: P(d1 = 1) = {float(anti[0])}, P(d2 = 1) = {float(anti[1])}, "
      f"P(both) = {float(anti[2])}, product {float(anti[0] * anti[1])}")
assert anti == mid and anti[2] != anti[0] * anti[1]
# ---- Kolmogorov's consistency condition ----
def sticky(w):                               # first toss fair, each later toss repeats with 0.8
    p = Fr(1, 2)
    for a, b in zip(w, w[1:]):
        p *= Fr(4, 5) if a == b else Fr(1, 5)
    return p
def parity(w): return Fr(1, 2 ** (len(w) - 1)) if w.count("H") % 2 == 0 else Fr(0)   # even heads only
def words(n): return [""] if n == 0 else [w + s for w in words(n - 1) for s in "HT"]
ok = all(sticky(w + "H") + sticky(w + "T") == sticky(w) for n in range(1, 10) for w in words(n))
print(f"sticky coin, consistent for n = 1 to 10: {'yes' if ok else 'no'}; mu_3(HHH) = {float(sticky('HHH'))}")
print(f"parity family: mu_1(H) = {float(parity('H')):.2f}, but mu_2 gives the first toss H with {float(parity('HH') + parity('HT')):.2f}")
assert ok and parity("H") != parity("HH") + parity("HT")
# ---- road 3: simulation ----
MASK = 2 ** 64 - 1
state = 20260929
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def uniforms(x):                             # U1..U4 from the 128 digits of x, by slot
    u = [0, 0, 0, 0]
    for k in range(1, 5):
        bits = 2 ** (7 - k)
        for j in range(1, bits + 1):
            n = 2 ** (k - 1) * (2 * j - 1)
            u[k - 1] = 2 * u[k - 1] + ((x >> (128 - n)) & 1)
        u[k - 1] = u[k - 1] / 2 ** bits
    return u
T = 200000
s1 = s11 = s2 = s22 = s12 = 0.0
three = six = hhh = darts = 0
for _ in range(T):
    x = (splitmix() << 64) | splitmix()
    u1, u2, u3, u4 = uniforms(x)
    s1 += u1; s11 += u1 * u1; s2 += u2; s22 += u2 * u2; s12 += u1 * u2
    three += u1 < 0.5 and u2 < 0.5 and u3 < 0.5
    six += int(6 * u1) + 1 == 6
    t1 = u1 < 0.5; t2 = t1 if u2 < 0.8 else not t1; t3 = t2 if u3 < 0.8 else not t2
    hhh += t1 and t2 and t3
    darts += u1 < 0.5 and u4 >= 0.5
m1, m2 = s1 / T, s2 / T
r = (s12 / T - m1 * m2) / ((s11 / T - m1 * m1) * (s22 / T - m2 * m2)) ** 0.5
print(f"simulated, {T} darts: mean U1 {m1:.6f}, correlation U1 U2 {r:.6f}")
sims = [("P(U1, U2, U3 all < 0.5)", three, 0.125), ("P(die from U1 shows 6)", six, 1 / 6),
        ("P(sticky HHH)", hhh, 0.32), ("P(dart 1 left half, dart 2 top half)", darts, 0.25)]
for label, hits, exact in sims:
    f, se = hits / T, (exact * (1 - exact) / T) ** 0.5
    print(f"simulated {label} = {f:.6f}; exact {exact:.6f}; standard error {se:.6f}")
    assert abs(f - exact) < 4 * se
assert abs(m1 - 0.5) < 4 * (1 / 12 / T) ** 0.5 and abs(r) < 4 / T ** 0.5
print("ALL CHECKS PASS")
