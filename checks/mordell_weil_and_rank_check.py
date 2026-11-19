# Mordell-Weil for y^2 = x^3 - 2: torsion, a 2-descent, and the generator (3, 5).
# Standard library only. Fraction is exact fractions; every other routine is written here.
from fractions import Fraction as F
from math import gcd, exp, isqrt, log

def add(p, q, a=0):                           # chord-tangent rule on y^2 = x^3 + a x + b; None is O
    if p is None: return q
    if q is None: return p
    if p[0] == q[0] and p[1] == -q[1]: return None
    m = (3 * p[0] ** 2 + a) / (2 * p[1]) if p == q else (q[1] - p[1]) / (q[0] - p[0])
    x = m * m - p[0] - q[0]
    return (x, m * (p[0] - x) - p[1])
def show(p): return f"({p[0]}, {p[1]})"
def is_sq(v): return v >= 0 and isqrt(v) ** 2 == v
def is_cube(v): return any(c ** 3 == v for c in range(0, v + 1))
def lnbig(v):                                 # natural log of a big whole number, from its digits
    s = str(abs(v)); k = min(len(s), 17)
    return log(float(s[:k])) + (len(s) - k) * log(10)
def H(x): return max(abs(x.numerator), x.denominator)       # the naive height of x

P = (F(3), F(5))
# Torsion, road 1: Nagell-Lutz. A torsion point is whole, with y = 0 or y^2 dividing 4a^3 + 27b^2 = 108
ys = [y for y in range(0, 11) if y == 0 or 108 % (y * y) == 0]
print(f"Nagell-Lutz: 4a^3 + 27b^2 = {27 * 4}, |discriminant| = {16 * 108}; allowed y {ys}; x^3 = y^2 + 2 = {[y * y + 2 for y in ys]}; none is a cube")
assert not any(is_cube(y * y + 2) for y in ys)
# Torsion, road 2: torsion survives reduction mod a good prime, so its size divides every count
def count(p): return 1 + sum((y * y - x ** 3 + 2) % p == 0 for x in range(p) for y in range(p))
cs = [(p, count(p)) for p in (5, 7, 11, 13, 17)]
g = 0
for _, c in cs: g = gcd(g, c)
print("points mod p: " + ", ".join(f"{p}:{c}" for p, c in cs) + f"; gcd {g}, so the torsion is O alone")
assert g == 1 and all(c == p + 1 for p, c in cs if p % 3 == 2)    # p = 2 mod 3: cubing is one-to-one
# Rank at least 1: 2P is not whole, so P is not torsion
mult = [None]
for n in range(12): mult.append(add(mult[-1], P))
print(f"tangent slope at P = {3 * P[0] ** 2 / (2 * P[1])}; 2P = {show(mult[2])}, 3P = {show(mult[3])}")
assert mult[2] == (F(129, 100), F(-383, 1000))
assert all(pt[1] ** 2 == pt[0] ** 3 - 2 for pt in mult[1:])     # every multiple stays on the curve

# The descent map x - t, with t the real cube root of 2, in Z[t] = {a + b t + c t^2}, t^3 = 2
def m3(u, v):
    a, b, c = u; d, e, f = v
    return (a * d + 2 * (b * f + c * e), a * e + b * d + 2 * c * f, a * f + b * e + c * d)
def norm(u): a, b, c = u; return a ** 3 + 2 * b ** 3 + 4 * c ** 3 - 6 * a * b * c
U, T, T1, S = (-1, 1, 0), (0, 1, 0), (1, 1, 0), (1, 0, 1)        # u = t - 1, t, t + 1, 1 + t^2
assert m3(U, (1, 1, 1)) == (1, 0, 0) and m3(T, m3(T, T)) == (2, 0, 0)
assert m3(U, m3(T1, m3(T1, T1))) == (3, 0, 0)                  # 3 = u (t + 1)^3: only t, t + 1 sit over 2, 3
print(f"u (1 + t^2)^2 = {m3(U, m3(S, S))} = 3 - t, of norm {norm((3, -1, 0))}: P lands on the class of u")
assert m3(U, m3(S, S)) == (3, -1, 0) and norm((3, -1, 0)) == 25 and norm((1, 1, 1)) == 1
cls = [(sg, i, j, k) for sg in (1, -1) for i in (0, 1) for j in (0, 1) for k in (0, 1)]
def nrm(c): return c[0] * norm(U) ** c[1] * norm(T) ** c[2] * norm(T1) ** c[3]
ok = [c for c in cls if is_sq(nrm(c))]
print(f"norms of -1, u, t, t + 1: -1, {norm(U)}, {norm(T)}, {norm(T1)}")
print(f"classes: {len(cls)} before the norm test, {len(ok)} after: 1 and u; so 2^r <= {len(ok)} and r <= 1")
assert len(ok) == 2 and (1, 1, 0, 0) in ok

# Halving: a half R of Q (2R = Q) has x(R) a rational root of a quartic from the doubling formula
def divs(v):
    return [d for d in range(1, isqrt(abs(v)) + 1) if v % d == 0] + [abs(v) // d for d in range(1, isqrt(abs(v)) + 1) if v % d == 0]
def halves(xq, a=0, b=-2):                    # x(2R) = (x^4 - 2a x^2 - 8b x + a^2) / (4 (x^3 + a x + b))
    n, d = xq.numerator, xq.denominator
    co = [d, -4 * n, -2 * a * d, -8 * b * d - 4 * a * n, a * a * d - 4 * b * n]
    roots = set()
    for r in divs(co[4]) or [0]:
        for s in divs(co[0]):
            for x in (F(r, s), F(-r, s)):
                if sum(c * x ** (4 - i) for i, c in enumerate(co)) == 0: roots.add(x)
    return sorted(roots)
Q = mult[4]
print(f"descent from {mult.index(Q)}P, x = {Q[0]}:")
lh = []
while True:
    h = halves(Q[0]); lh.append(log(H(Q[0])))
    print(f"  ln H(x) = {log(H(Q[0])):.4f}; rational halves x(R): {', '.join(map(str, h)) or 'none'}")
    if not h: break
    y2 = h[0] ** 3 - 2; y = F(isqrt(y2.numerator), isqrt(y2.denominator))
    Q = next(r for r in [(h[0], y), (h[0], -y)] if add(r, r) == Q)   # put the half back: it doubles to Q
falls = ", then ".join(f"{h1 / h2:.2f}" for h1, h2 in zip(lh, lh[1:]))
print(f"stop at {show(Q)}: no rational half, so it is not in 2E(Q)" + (f"; ln H fell by {falls} times" if falls else ""))
assert Q == P
# Second road: mod 17, t = 8 and u = 7 is not a square, so x(nP) - 8 is a square exactly for even n
def modp(x, p): return x.numerator * pow(x.denominator, -1, p) % p
sh = [pow(modp(mult[n][0], 17) - 8, 8, 17) == 1 for n in range(1, 9)]
print("mod 17, is x(nP) - 8 a square, n = 1..8: " + " ".join("yes" if v else "no" for v in sh))
assert sh == [n % 2 == 0 for n in range(1, 9)]

# P generates: if P = kG with k odd >= 3, Silverman's height bounds put G in a small search box
Lo, Up = log(1728) / 12 + 0.973, log(1728) / 12 + 1.07         # j = 0, |discriminant| = 1728
hmax = (log(3) + 2 * Up) / 9 + 2 * Lo
print(f"ln 1728 / 12 = {log(1728) / 12:.5f}; h-hat(P) <= ln 3 + {2 * Up:.5f} = {log(3) + 2 * Up:.4f}")
print(f"a G with P = kG, k >= 3, has ln H(x(G)) <= {log(3) + 2 * Up:.4f}/9 + {2 * Lo:.5f} = {hmax:.4f}, so H <= {exp(hmax):.1f}")
box = [F(m, e * e) for e in range(1, 32) for m in range(-1000, 1001)      # x = m/e^2, H = max(|m|, e^2)
       if gcd(m, e) == 1 and is_sq(m ** 3 - 2 * e ** 6)]
print(f"search H <= 1000 finds x = {', '.join(map(str, box))}; with H <= 39 only x = {', '.join(str(x) for x in box if H(x) <= 39)}")
assert box == [F(3), F(129, 100)] and 39 < exp(hmax) < 40

# Canonical height: division polynomials psi_n give x(nP) = phi_n / psi_n^2 in whole numbers
ps = [0, 1, 10, 171, -7660]
while len(ps) < 67:
    k = len(ps); m = k // 2
    ps.append(ps[m + 2] * ps[m] ** 3 - ps[m - 1] * ps[m + 1] ** 3 if k % 2 else
              ps[m] * (ps[m + 2] * ps[m - 1] ** 2 - ps[m - 2] * ps[m + 1] ** 2) // 10)
def xn(n): return 3 * ps[n] ** 2 - ps[n + 1] * ps[n - 1], ps[n] ** 2
assert all(F(*xn(n)) == mult[n][0] and xn(n)[1] == mult[n][0].denominator for n in range(1, 13))
print(f"digits of the denominator of x(nP), n = 1..12: {[len(str(xn(n)[1])) for n in range(1, 13)]}")
hh = [max(lnbig(v) for v in xn(2 ** k)) / 4 ** k for k in range(7)]
print("ln H(x(nP)) / n^2 at n = 1, 2, 4, ..., 64: " + ", ".join(f"{v:.5f}" for v in hh) + f"; x(64P) has a {len(str(xn(64)[1]))}-digit denominator")
print(f"trend line 1.34958 n^2 / ln 10, n = 1..12: {[round(1.34958 * n * n / log(10)) for n in range(1, 13)]}")
assert abs(hh[6] - 1.34958) < 0.002                              # LMFDB 1728.o3: regulator 1.34958

# What breaks: the 2-torsion curve y^2 = x^3 - x, where |E/2E| = 2^(r + 2), not 2^r
two = [len(halves(F(x), -1, 0)) for x in (-1, 0, 1)]
print(f"y^2 = x^3 - x: rational halves of (-1, 0), (0, 0), (1, 0): {two}, so |E/2E| = 4, yet r = 0")
assert two == [0, 0, 0]
print(f"search box H <= 2 on y^2 = x^3 - 2 finds {len([x for x in box if H(x) <= 2])} points; P has H = 3")
print("ALL CHECKS PASS")
