# Liouville to Roth -- the check behind the card.  Standard library only, no imports
# but math.log, math.log10 and math.sqrt.  Road 1: exact decimal digits of Liouville's constant.
# Road 2: the geometric-series bound of Why it works.  Road 3: every q up to 10^6
# against the continued fraction of the cube root of 2, built by Lagrange's method.
from math import log, log10, sqrt

def fact(n):
    return 1 if n == 0 else n * fact(n - 1)

def digits(places, length):        # 0.d1 d2 ... with a 1 at each listed place
    d = [0] * (length + 1)
    for k in places:
        d[k] = 1
    return d

def first_nonzero(x, y):           # x - y for two digit lists with x > y: place, mantissa
    diff, borrow = [0] * len(x), 0
    for i in range(len(x) - 1, 0, -1):
        v = x[i] - y[i] - borrow
        borrow = 1 if v < 0 else 0
        diff[i] = v + 10 * borrow
    j = next(i for i in range(1, len(x)) if diff[i])
    return j, int("".join(map(str, diff[j:j + 15])).ljust(15, "0")) / 1e14

def truncations(gaps, nmax, length, d_show):
    full = digits(gaps, length)
    rows = []
    for n in range(1, nmax + 1):
        j, m = first_nonzero(full, digits(gaps[:n], length))
        logq = gaps[n - 1]                         # q = 10^(n-th place)
        expo = (j - log10(m)) / logq
        rows.append((n, logq, j, m, expo, d_show * logq - j + log10(m)))
        tail = sum(10.0 ** (gaps[n] - g) for g in gaps[n + 1:])
        assert j == gaps[n] and abs(m - (1 + tail)) < 1e-12   # road 2 agrees
        assert 1 <= m < 2                                       # error < 2 / q^(n+1)
    return rows

print("Liouville's constant L = 0.1100010000...: a 1 at places 1!, 2!, 3!, ...")
L = digits([fact(k) for k in range(1, 6)], 130)
print("L to 30 places: 0." + "".join(map(str, L[1:31])))
print("n | q = 10^(n!) | L - p/q = 10^-j x m | exponent | log10(q^3 x error)")
rowsL = truncations([fact(k) for k in range(1, 6)], 4, 130, 3)
for n, logq, j, m, e, l3 in rowsL:
    print(f"{n} | 10^{logq} | 10^-{j} x {m:.12f} | {e:.6f} | {l3:.6f}")
print("doubling gaps S = 0.0101000100...: a 1 at places 2, 4, 8, 16, ...")
rowsS = truncations([2 ** k for k in range(1, 8)], 5, 130, 3)
for n, logq, j, m, e, l3 in rowsS:
    print(f"{n} | 10^{logq} | 10^-{j} x {m:.12f} | {e:.6f} | {l3:.6f}")

def icbrt(n):                      # floor of the real cube root, exact
    x = int(round(abs(n) ** (1 / 3)))
    while x ** 3 > abs(n): x -= 1
    while (x + 1) ** 3 <= abs(n): x += 1
    if n >= 0: return x
    return -x if x ** 3 == -n else -(x + 1)

a = 1.0
for _ in range(8): a = a - (a * a * a - 2) / (3 * a * a)
def err(p, q):                     # |cbrt2 - p/q| = |p^3 - 2q^3| / (q^3 (a^2 + a r + r^2))
    r = p / q
    return abs(p ** 3 - 2 * q ** 3) / (float(q ** 3) * (a * a + a * r + r * r))
print(f"cube root of 2 = {a:.12f}")
QMAX, best, records, low3, low25 = 10 ** 6, 9.0, [], (9.0, 0), (9.0, 0)
lowb = (9.0, 0)
for q in range(1, QMAX + 1):
    p0 = icbrt(2 * q ** 3)
    for p in (p0, p0 + 1):
        e = err(p, q)
        if q * e < best: best = q * e; records.append((p, q))
        low3 = min(low3, (q ** 3 * e, q)); low25 = min(low25, (q ** 2.5 * e, q))
        lowb = min(lowb, (q ** 2.955 * e, q))

cf, poly = [], [1, 0, 0, -2]       # road 3: Lagrange's method on x^3 - 2
for _ in range(len(records)):
    c3, c2, c1, c0 = poly
    P = lambda x: ((c3 * x + c2) * x + c1) * x + c0
    k = 1
    while c3 * P(k + 1) < 0: k += 1
    cf.append(k)
    poly = [P(k), 3 * k * k * c3 + 2 * k * c2 + c1, 3 * k * c3 + c2, c3]
conv, (p1, q1, p2, q2) = [], (1, 0, 0, 1)
for x in cf:
    p1, p2, q1, q2 = x * p1 + p2, p1, x * q1 + q2, q1
    conv.append((p1, q1))
assert conv == records             # brute force and Lagrange's method agree
print(f"convergents with q <= 10^6: {len(conv)}, partial quotients {cf}")
print("k | p/q | |p^3 - 2q^3| | q^2 x error | exponent")
for i, (p, q) in enumerate(conv):
    e = err(p, q)
    ex = "-" if q == 1 else f"{-log(e) / log(q):.6f}"
    print(f"{i} | {p}/{q} | {abs(p ** 3 - 2 * q ** 3)} | {q * q * e:.6f} | {ex}")
    assert q * q * e < 1                           # Dirichlet: below 1/q^2
c_proof = 1 / (3 * a * a + 3 * a + 1)
brk = max(a * a + a * r + r * r for r in (a - 1 + i / 1000 for i in range(2001)))
assert abs(c_proof * brk - 1) < 1e-9          # c = 1 / largest bracket, by sampling
c_tan = 1 / (3 * (a + 1) ** 2)                # Step 2's general proof: M = largest slope 3x^2
assert abs(c_tan * max(3 * x * x for x in (a - 1 + i / 1000 for i in range(2001))) - 1) < 1e-9
print(f"Liouville's c, general proof: M = {1 / c_tan:.6f}, c = {c_tan:.6f}; exact identity: "
      f"largest chord slope {1 / c_proof:.6f}, c = {c_proof:.6f}")
print(f"least q^3 x error to 10^6: {low3[0]:.6f} at q = {low3[1]}")
print(f"least q^2.5 x error to 10^6: {low25[0]:.6f} at q = {low25[1]} (Bennett: > 0.25)")
print(f"least q^2.955 x error to 10^6: {lowb[0]:.6f} at q = {lowb[1]} (Baker: > 10^-6)")
assert low3[0] >= c_proof and low25[0] > 0.25 and lowb[0] > 1e-6
print(f"exponent allowed at degree 3: Liouville 3, Thue {3 / 2 + 1}, Dyson {sqrt(6):.6f}, "
      "Roth 2 + any eps")
print(f"5/4 alone: error {err(5, 4):.6f}, exponent {-log(err(5, 4)) / log(4):.6f}, "
      f"q^3 x error {64 * err(5, 4):.6f}")

m = 1                              # x^3 - 2y^3 = m, bounded by Bennett's inequality
ybound = int((16 * abs(m) / (3 * a * a)) ** 2)
def thue(lo, hi):
    return [(icbrt(2 * y ** 3 + m), y) for y in range(lo, hi + 1)
            if icbrt(2 * y ** 3 + m) ** 3 == 2 * y ** 3 + m]
sols, wide = thue(-ybound, ybound), thue(-10 ** 5, 10 ** 5)
y_last = next(y for y in range(1, 10 ** 6) if 1 / (4 * y ** 2.5) > 4 * abs(m) / (3 * a * a * y ** 3)) - 1
assert sols == wide and ybound == y_last      # the box, against Bennett's bound tried y by y
print(f"x^3 - 2y^3 = {m}: Bennett forces |y| <= {ybound}; solutions {sols}; "
      f"search to |y| = 100,000 finds {len(wide)}")
def isqrt(n):                      # floor square root by Newton's method, exact
    x = n
    while x * x > n: x = (x + n // x) // 2
    return x
pts = [(x, isqrt(x ** 3 - x)) for x in range(-10 ** 4, 10 ** 4 + 1)
       if x ** 3 - x >= 0 and isqrt(x ** 3 - x) ** 2 == x ** 3 - x]
print(f"whole-number points on y^2 = x^3 - x with |x| <= 10,000: {pts}")
assert pts == [(-1, 0), (0, 0), (1, 0)]
print(f"Pythagorean comma 3^12 / 2^19 = {3 ** 12 / 2 ** 19:.6f}")
assert all(abs(r[4] - (r[0] + 1)) < 1e-4 for r in rowsL)   # Step 3: exponent n + 1 at the n-th cut
assert all(abs(r[4] - 2) < 1e-4 for r in rowsS)            # Step 4: doubling gaps stay at exponent 2
print("ALL CHECKS PASS")
