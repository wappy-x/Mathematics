# Lusin's theorem -- the check behind the card.  Standard library only.
# Exact fractions throughout.  Every number is reached by two roads:
# Dirichlet: the length deleted around the rationals, by sorting and merging
#   the intervals, against the geometric sum minus the parts outside [0, 1].
# Tariff: the gap between the step s and its joined-up version g, by the
#   triangle formula |J| w / 4 per jump, against a midpoint sum on a grid
#   that every corner of |s - g| lines up with (so the sum is exact).
from fractions import Fraction as F
from math import gcd

def dec(x, digits=10):                       # exact decimal, rounded half up
    sign, x = ("-" if x < 0 else ""), abs(x)
    n = (x.numerator * 10**digits * 2 + x.denominator) // (2 * x.denominator)
    s = f"{n // 10**digits}.{n % 10**digits:0{digits}d}".rstrip("0").rstrip(".")
    return sign + s

def rationals(qmax):                         # 0, 1, then p/q by denominator
    out = [F(0), F(1)]
    for q in range(2, qmax + 1):
        out += [F(p, q) for p in range(1, q) if gcd(p, q) == 1]
    return out

def merged_length(centres, width):           # length of the union inside [0, 1]
    iv = sorted((max(F(0), c - width(n) / 2), min(F(1), c + width(n) / 2))
                for n, c in enumerate(centres, 1))
    total, (lo, hi) = F(0), iv[0]
    for a, b in iv[1:]:
        if a > hi:
            total, lo, hi = total + hi - lo, a, b
        else:
            hi = max(hi, b)
    return total + hi - lo

def totient(n):                              # n times (1 - 1/p) over primes p
    r, m, p = n, n, 2
    while p * p <= m:
        if m % p == 0:
            r -= r // p
            while m % p == 0:
                m //= p
        p += 1
    return r - r // m if m > 1 else r

def farey(n):                                # count and smallest b*d of neighbours
    a, b, c, d, count, small = 0, 1, 1, n, 2, n
    while (c, d) != (1, 1):
        k = (n + b) // d
        a, b, c, d = c, d, k * c - a, k * d - b
        count, small = count + 1, min(small, b * d)
    return count, small

def s_at(x, base, jumps):                    # the step: base, plus J from c on
    return base + sum(J for c, J in jumps if x >= c)

def g_at(x, base, jumps, w):                 # straight line across each gap
    return base + sum(J * min(F(1), max(F(0), (x - c + w / 2) / w)) for c, J in jumps)

def gap_by_grid(base, jumps, w, lo, hi, h):  # integral and largest |s - g|
    n = int((hi - lo) / h)
    area = sum(abs(s_at(lo + (k + F(1, 2)) * h, base, jumps)
                   - g_at(lo + (k + F(1, 2)) * h, base, jumps, w)) for k in range(n)) * h
    top = max(abs(s_at(lo + k * h, base, jumps) - g_at(lo + k * h, base, jumps, w)) for k in range(n + 1))
    return area, top, n

def gap_by_formula(jumps, w):
    return sum(abs(J) for c, J in jumps) * w / 4, max(abs(J) for c, J in jumps) / 2

# ---- Dirichlet: delete width eps * 2^-n around the n-th rational ----
eps = F(1, 100)
width = lambda n: eps / 2**n
q8 = rationals(8)
first = ", ".join(str(x) for x in q8[:5])
d_merge = merged_length(q8, width)
outside = width(1) / 2 + width(2) / 2        # half of the intervals at 0 and at 1
d_sum = eps * (1 - F(1, 2**len(q8))) - outside
bound = lambda e: e - e / 4 - e / 8          # all rationals: the same overhangs
assert d_merge == d_sum and bound(eps) - d_merge == eps / 2**len(q8)
print("Dirichlet on [0, 1]: delete width 0.01 * 2^-n around the n-th rational")
print(f"denominator up to 8: {len(q8)} rationals; first five {first}")
print("widths of the first five: " + ", ".join(dec(width(n)) for n in range(1, 6)))
print(f"deleted, first 23, by merging: {dec(d_merge)}; by the sum: {dec(d_sum)}")
print(f"deleted, every rational, at most {dec(bound(eps))}; closed set left at least {dec(1 - bound(eps))}")

# ---- the tariff: 10, then 30 from 1/3, then 20 from 2/3 cents per kWh ----
w = F(1, 2000)
tariff = [(F(1, 3), F(20)), (F(2, 3), F(-10))]
area, top, n = gap_by_grid(F(10), tariff, w, F(0), F(1), F(1, 12000))
f_area, f_top = gap_by_formula(tariff, w)
assert area == f_area and top == f_top
print(f"tariff: gaps {dec(w)} at 1/3 and 2/3, kept length {dec(1 - 2 * w)}")
print(f"integral |s - g|: triangles {dec(f_area)}; grid of {n} cells {dec(area)}")
print(f"largest |s - g|: J/2 gives {dec(f_top)}; grid gives {dec(top)}")

# ---- continuous with compact support, close in L1: the tariff on the line ----
line = [(F(0), F(10))] + tariff + [(F(1), F(-20))]
l_area, l_top, n = gap_by_grid(F(0), line, w, F(-1, 1000), F(1001, 1000), F(1, 12000))
assert l_area == gap_by_formula(line, w)[0] and l_area < 60 * 4 * w
print(f"line: h is 0 outside [{dec(-w / 2)}, {dec(1 + w / 2)}]; integral |s - h| "
      f"{dec(gap_by_formula(line, w)[0])}; grid {dec(l_area)}; proof's bound 60 x {dec(4 * w)} = {dec(60 * 4 * w)}")

# ---- what breaks ----
q100 = rationals(100)
f_count, small = farey(100)
tot = 1 + sum(totient(q) for q in range(1, 101))
fixed = merged_length(q100, lambda n: eps)
assert f_count == tot == len(q100) and small >= 100 and fixed == 1
print(f"break, width 0.01 for all: {tot} rationals with denominator up to 100, widest neighbour gap {dec(F(1, small))}, deleted {dec(fixed)}")
cut = [(c - width(k) / 2, c + width(k) / 2) for k, c in enumerate(q8, 1)]
left = sum(1 for x in q100 if not any(a < x < b for a, b in cut))
assert left == tot - len(q8)
print(f"break, first 23 only: rationals up to denominator 100 left {left} = {tot} - 23")
fine = gap_by_grid(F(10), tariff, w / 10, F(0), F(1), F(1, 120000))
assert fine[:2] == gap_by_formula(tariff, w / 10)
print(f"break, sup reading: largest |s - g| {dec(top)} at gap 0.0005, {dec(fine[1])} at gap 0.00005")

# ---- try changing ----
print(f"try, eps 0.001: deleted at most {dec(bound(F(1, 1000)))}, left at least {dec(1 - bound(F(1, 1000)))}")
print(f"try, gap 0.00005: integral |s - g| {dec(fine[0])}")
w3 = F(1, 1000) / 15
a3 = gap_by_grid(F(0), line, w3, F(-1, 1000), F(1001, 1000), F(1, 30000))[0]
assert a3 == F(1, 1000)
print(f"try, target 0.001 on the line: gap 1/15000 = {dec(w3)}, integral |s - h| {dec(a3)}")
peak = [(F(1, 3), F(40)), (F(2, 3), F(-30))]
a4, t4, _ = gap_by_grid(F(10), peak, w, F(0), F(1), F(1, 12000))
assert (a4, t4) == gap_by_formula(peak, w)
print(f"try, peak 50: integral |s - g| {dec(a4)}, largest gap {dec(t4)}")
print("ALL CHECKS PASS")
