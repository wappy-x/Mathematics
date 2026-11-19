# Pell's equation from the continued fraction of a square root -- the check
# behind the card.  Standard library only; math.isqrt is the one import.
# Road 1: the continued fraction of root d, run in whole numbers (m, c, a).
# Road 2: brute force, trying y = 1, 2, 3, ... until d*y*y + 1 is a square.
# Road 3: algebra, multiplying units of the form x + y*root(d).
from math import isqrt

def expand(d, terms):              # states (m_k, c_k, a_k): alpha_k = (m_k + root d) / c_k
    a0 = isqrt(d)
    m, c, a = 0, 1, a0
    out = [(m, c, a)]
    for _ in range(terms - 1):
        m = c * a - m
        c = (d - m * m) // c       # always exact: c_k divides d - m_(k+1)^2
        a = (a0 + m) // c
        out.append((m, c, a))
    return out

def convergents(states):           # p_k / q_k from p_k = a_k p_(k-1) + p_(k-2)
    p0, p1, q0, q1, out = 0, 1, 1, 0, []
    for _, _, a in states:
        p0, p1 = p1, a * p1 + p0
        q0, q1 = q1, a * q1 + q0
        out.append((p1, q1))
    return out

def period(d):                     # first k >= 1 with c_k = 1
    k = 1
    while expand(d, k + 1)[k][1] != 1:
        k += 1
    return k

def fundamental(d):                # convergent at the end of one period, or two if odd
    l = period(d)
    k = l - 1 if l % 2 == 0 else 2 * l - 1
    return convergents(expand(d, k + 1))[k]

def brute(d, ymax):                # road 2: the first y with d y^2 + 1 a perfect square
    for y in range(1, ymax + 1):
        n = d * y * y + 1
        if isqrt(n) ** 2 == n:
            return isqrt(n), y
    return None

def mul(u, v, d):                  # (x1 + y1 root d)(x2 + y2 root d)
    return (u[0] * v[0] + d * u[1] * v[1], u[0] * v[1] + u[1] * v[0])

def yn(b):
    return "yes" if b else "no"

D = 61
st = expand(D, 67)
cv = convergents(st)
norm = [p * p - D * q * q for p, q in cv]
l = period(D)
print(f"root {D}: a0 = {st[0][2]}, period length {l} ({'odd' if l % 2 else 'even'})")
print(" k m_k c_k a_k    p_k   q_k  p_k^2 - 61 q_k^2")
for k in range(12):
    print(f"{k:>2} {st[k][0]:>3} {st[k][1]:>3} {st[k][2]:>3} {cv[k][0]:>6} {cv[k][1]:>5} {norm[k]:>5}")
print("continued fraction:", [a for _, _, a in st[:12]])
ident = all(norm[k] == (-1) ** (k + 1) * st[k + 1][1] for k in range(44))
print(f"p_k^2 - 61 q_k^2 = (-1)^(k+1) c_(k+1) for k = 0..43: {yn(ident)}")
ones = [k for k in range(67) if st[k][1] == 1]
print(f"c_k = 1 at k = {ones}")
x1, y1 = fundamental(D)
print(f"one period, k = 10: ({cv[10][0]}, {cv[10][1]}), norm {norm[10]}")
print(f"two periods, k = 21: ({x1}, {y1}), norm {x1 * x1 - D * y1 * y1}; x has {len(str(x1))} digits")
print(f"(29718 + 3805 root 61)^2 = {mul(cv[10], cv[10], D)}")
h = (39, 5)                        # (39 + 5 root 61) / 2, kept as its doubled pair
h3 = mul(mul(h, h, D), h, D)
print(f"(39 + 5 root 61)/2: norm {(39 * 39 - D * 25) // 4}; cubed = {h3[0] // 8} + {h3[1] // 8} root 61")
pw, same = (1, 0), []
for n in (1, 2, 3):
    pw = mul(pw, (x1, y1), D)
    same.append(cv[22 * n - 1] == pw)
    print(f"solution {n}: convergent k = {22 * n - 1} is {cv[22 * n - 1]}; "
          f"equals power {n}: {yn(cv[22 * n - 1] == pw)}")
plus = [k for k in range(44) if norm[k] == 1]
print(f"convergents with norm +1, k = 0..43: {plus}")
YMAX = 100000
ds = [d for d in range(2, 101) if isqrt(d) ** 2 != d]
fund = {d: fundamental(d) for d in ds}
bf = {d: brute(d, YMAX) for d in ds}
agree = [d for d in ds if bf[d] == fund[d]]
none = [d for d in ds if bf[d] is None]
beyond = [d for d in ds if fund[d][1] > YMAX]
print(f"nonsquare d up to 100: {len(ds)}; brute force to y = {YMAX:,} agrees on {len(agree)}")
print(f"brute force finds nothing for d = {none}; their y = {[fund[d][1] for d in none]}, all beyond {YMAX:,}: {yn(none == beyond)}")
rec = max(ds, key=lambda d: fund[d][0])
print(f"largest smallest x below 100: d = {rec}, x = {fund[rec][0]}")
print(f"root 13: period {period(13)}, first +1 solution at k = 9: {fundamental(13)}")
for d in range(55, 68):
    if d != 64:
        n = len(str(fund[d][0]))
        print(f"bar,{d},{n},{'#' * n},x = {fund[d][0]}, y = {fund[d][1]}")
sw = [d for d in range(2, 1001) if isqrt(d) ** 2 != d]
ends = pal = bounds = onlyends = True
odd = 0
for d in sw:
    a0, L = isqrt(d), period(d)
    s = expand(d, 3 * L + 1)
    a = [t[2] for t in s[1:L + 1]]
    ends &= a[-1] == 2 * a0
    pal &= a[:-1] == a[-2::-1]
    bounds &= all(0 < t[0] <= a0 and 0 < t[1] <= 2 * a0 for t in s[1:])
    onlyends &= [k for k, t in enumerate(s) if t[1] == 1] == [0, L, 2 * L, 3 * L]
    odd += L % 2
print(f"nonsquare d up to 1,000: {len(sw)}; every period ends in 2 a0: {yn(ends)}; "
      f"rest reads the same backwards: {yn(pal)}")
print(f"0 < m_k <= a0 and 0 < c_k <= 2 a0 throughout: {yn(bounds)}; "
      f"c_k = 1 only at period ends: {yn(onlyends)}; odd periods: {odd}")
print(f"mistake, one step too far (k = 11): ({cv[11][0]}, {cv[11][1]}), norm {norm[11]}")
print(f"mistake, d = 64 a square: root 64 = [8], stops; brute force to y = {YMAX:,}: {brute(64, YMAX)}")
print(f"mistake, brute force on 61 to y = 1,000,000: {brute(D, 10 ** 6)}")
assert l == 11 and (cv[10], norm[10]) == ((29718, 3805), -1)          # one period gives -1
assert (x1, y1) == (1766319049, 226153980) and x1 * x1 - D * y1 * y1 == 1
assert mul(cv[10], cv[10], D) == (x1, y1) and h3 == (8 * 29718, 8 * 3805)   # algebra road
assert ident and ones == [0, 11, 22, 33, 44, 55, 66] and plus == [21, 43] and all(same)
assert agree == [d for d in ds if d not in beyond] and none == beyond      # brute-force road
assert ends and pal and bounds and onlyends and brute(64, YMAX) is None
print("ALL CHECKS PASS")
