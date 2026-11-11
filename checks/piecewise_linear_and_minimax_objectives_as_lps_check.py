# Modelling tricks -- the check behind the card.  Standard library only.
# A workshop makes t tables (£19 each) and c chairs (£20 each) from 160 m of timber,
# 92 regular hours of labour and 64 l of finish.  Overtime costs £2 an hour extra for
# the first 10 hours and £5 an hour after that.  Maximise profit, £.  Every LP is
# solved by listing every corner in exact fractions: no solver is imported.
from fractions import Fraction as Fr

def solve(A, b):                      # Gauss-Jordan elimination; None if singular
    n = len(A); M = [[Fr(v) for v in row] + [Fr(bi)] for row, bi in zip(A, b)]
    for i in range(n):
        p = next((r for r in range(i, n) if M[r][i] != 0), None)
        if p is None: return None
        M[i], M[p] = M[p], M[i]
        for r in range(n):
            if r != i and M[r][i] != 0:
                f = M[r][i] / M[i][i]; M[r] = [x - f * y for x, y in zip(M[r], M[i])]
    return [M[i][n] / M[i][i] for i in range(n)]

def best_corner(c, A, b):             # maximise c.x over Ax <= b: try every corner
    n, best = len(c), None
    for mask in range(1 << len(A)):
        if bin(mask).count("1") != n: continue
        rows = [i for i in range(len(A)) if mask >> i & 1]
        x = solve([A[i] for i in rows], [b[i] for i in rows])
        if x is None or any(sum(a * v for a, v in zip(A[i], x)) > b[i] for i in range(len(A))):
            continue
        val = sum(a * v for a, v in zip(c, x))
        if best is None or val > best[0]: best = (val, x)
    return best

def m(x):                             # money to the penny, rounded half up, exactly
    s = "-" if x < 0 else ""; x = abs(Fr(x)); p = (x * 200 + 1) // 2
    return f"{s}{p // 100}.{p % 100:02d}"
def nums(xs): return " ".join(m(x) if Fr(x).denominator > 1 else str(x) for x in xs)

TIMBER, FINISH, HOURS = [4, 2], [1, 2], 92
def segment_lp(p1, p2, cap):          # variables t, c, h1, h2: tier hours apart
    A = [TIMBER + [0, 0], [3, 1, -1, -1], FINISH + [0, 0], [0, 0, 1, 0],
         [-1, 0, 0, 0], [0, -1, 0, 0], [0, 0, -1, 0], [0, 0, 0, -1]]
    return best_corner([19, 20, -p1, -p2], A, [160, HOURS, 64, cap, 0, 0, 0, 0])
def epigraph_lp(lines):               # variables t, c, h, z: z sits above every line
    A = [TIMBER + [0, 0], [3, 1, -1, 0], FINISH + [0, 0], [-1, 0, 0, 0],
         [0, -1, 0, 0], [0, 0, -1, 0]] + [[0, 0, s, -1] for s, k in lines]
    return best_corner([19, 20, 0, -1], A, [160, HOURS, 64, 0, 0, 0] + [k for s, k in lines])
def true_cost(h, p1=2, p2=5, cap=10): return p1 * min(h, cap) + p2 * max(h - cap, 0)
def kinked(p1=2, p2=5, cap=10):       # road 3: no new variables; try every crossing
    L = [(TIMBER, 160), (FINISH, 64), ([1, 0], 0), ([0, 1], 0), ([3, 1], HOURS), ([3, 1], HOURS + cap)]
    best = None
    for i in range(len(L)):
        for j in range(i + 1, len(L)):
            x = solve([L[i][0], L[j][0]], [L[i][1], L[j][1]])
            if x is None or min(x) < 0 or 4 * x[0] + 2 * x[1] > 160 or x[0] + 2 * x[1] > 64: continue
            h = max(Fr(0), 3 * x[0] + x[1] - HOURS)
            val = 19 * x[0] + 20 * x[1] - true_cost(h, p1, p2, cap)
            if best is None or val > best[0]: best = (val, x, h)
    return best

v1, x1 = segment_lp(2, 5, 10)
v2, x2 = epigraph_lp([(2, 0), (5, 30)])
v3, x3, h3 = kinked()
print("tiers as two variables  t c h1 h2:", nums(x1), " profit", m(v1))
print("cost as z above lines   t c h z:  ", nums(x2), " profit", m(v2))
print("kinked cost, crossings  t c hours:", nums(x3 + [h3 + HOURS]), " profit", m(v3))
v0, x0 = best_corner([19, 20], [TIMBER, [3, 1], FINISH, [-1, 0], [0, -1]], [160, HOURS, 64, 0, 0])
print("no overtime             t c:", nums(x0), " profit", m(v0))
print("all 20 hours            t c: 32 16  profit", m(19 * 32 + 20 * 16 - true_cost(20)))
dt, dc = Fr(2, 5), Fr(-1, 5)          # one more hour on the finish edge: +0.4 table, -0.2 chair
print("one more hour: tables", m(dt), "chairs", m(dc), "gained", m(19 * dt), "lost", m(-20 * dc),
      "worth", m(19 * dt + 20 * dc))
y = solve([[3, 1, 0], [1, 2, 0], [-1, 0, 1]], [19, 20, -2])   # prices: labour, finish, tier cap
cols = [(19, [4, 3, 1, 0]), (20, [2, 1, 2, 0]), (-2, [0, -1, 0, 1]), (-5, [0, -1, 0, 0])]
Y = [Fr(0)] + y                       # timber is not used up, so its price is 0
red = [sum(a * p for a, p in zip(col, Y)) - cj for cj, col in cols]
bound = sum(p * r for p, r in zip(Y, [160, HOURS, 64, 10]))
print("prices timber labour finish cap:", nums(Y), " shortfalls", nums(red), " bound", m(bound))
print("timber used", 4 * x1[0] + 2 * x1[1], " bound parts", nums([Y[1] * HOURS, Y[2] * 64, Y[3] * 10]),
      " against no overtime", m(v1 - v0), " against all 20 hours", m(v1 - 858))
print("chart hours  ", " ".join(str(h) for h in range(0, 21, 2)))
print("chart 2h     ", " ".join(str(2 * h) for h in range(0, 21, 2)))
print("chart 5h-30  ", " ".join(str(5 * h - 30) for h in range(0, 21, 2)))
print("chart 3.6h   ", nums([Fr(18, 5) * h for h in range(0, 21, 2)]))
b1, xb1 = segment_lp(2, 1, 10)        # what breaks: slopes fall (a bulk discount)
print("falling tiers 2 then 1:  h1 h2", nums(xb1[2:]), " real bill", true_cost(20, 2, 1), " LP says", m(b1), " bill says",
      m(19 * xb1[0] + 20 * xb1[1] - true_cost(xb1[2] + xb1[3], 2, 1)))
b2, xb2 = segment_lp(2, 5, 1000)
print("tier-1 cap dropped:      hours", nums([xb2[2]]), " LP says", m(b2), " bill says",
      m(19 * xb2[0] + 20 * xb2[1] - true_cost(xb2[2])))
b3, xb3 = epigraph_lp([(0, 0), (5, 30)])
print("only the 5h-30 line:     hours", nums([xb3[2]]), " LP says", m(b3), " bill says",
      m(19 * xb3[0] + 20 * xb3[1] - true_cost(xb3[2])))
T1, T2, T3 = segment_lp(2, 3, 10), segment_lp(4, 5, 10), kinked(2, 5, 20)
print("try tier 2 at 3: t c", nums(T1[1][:2]), m(T1[0]), "| tier 1 at 4:", nums(T2[1][:2]), m(T2[0]),
      "| cap 20:", nums(T3[1]), m(T3[0]))

WEEKS = [(10, 30), (30, 90), (20, 80), (25, 75), (15, 46)]   # tables made, hours taken
def total(a): return sum(abs(H - a * q) for q, H in WEEKS)
def worst(a): return max(abs(H - a * q) for q, H in WEEKS)
def fits(weeks):
    n, A, b = len(weeks), [], []
    for i, (q, H) in enumerate(weeks):  # -e_i <= H_i - a q_i <= e_i
        e = [0] * n; e[i] = -1
        A += [[-q] + e, [q] + e]; b += [-H, H]
    l1 = best_corner([0] + [-1] * n, A, b)
    A2 = [[r[0], -1] for r in A]
    return l1, best_corner([0, -1], A2, b)
(l1, la), (mm, ma) = fits(WEEKS)
kinks = sorted({Fr(H, q) for q, H in WEEKS})
cross = {Fr(Hi + s * Hj, qi + s * qj) for qi, Hi in WEEKS for qj, Hj in WEEKS for s in (1, -1) if qi + s * qj != 0}
ak = min(kinks, key=total); am = min(cross, key=worst)
print("absolute: LP a", m(la[0]), "total", m(-l1), "| every kink a", m(ak), "total", m(total(ak)))
print("errors at a = 3:", nums([H - 3 * q for q, H in WEEKS]), " rates", nums([Fr(H, q) for q, H in WEEKS]),
      " tables in exact weeks", sum(q for q, H in WEEKS if H == 3 * q), "others", sum(q for q, H in WEEKS if H != 3 * q))
print("slopes of the total just below and above 3:", -sum(q for q, H in WEEKS),
      sum(q if Fr(H, q) <= 3 else -q for q, H in WEEKS))
print("minimax:  LP a", m(ma[0]), "worst", m(-mm), "| every crossing a", m(am), "worst", m(worst(am)))
print("weights 3/5 on week 3, 2/5 on week 2 give, for every a:", m(Fr(3, 5) * 80), "-", m(Fr(2, 5) * 90),
      "=", m(Fr(3, 5) * 80 - Fr(2, 5) * 90))
ls = Fr(sum(q * H for q, H in WEEKS), sum(q * q for q, H in WEEKS))
(_, la2), (mm2, ma2) = fits([(10, 30), (30, 90), (20, 100), (25, 75), (15, 46)])
print("least squares a", m(ls), "| bad week at 100 h: absolute a", m(la2[0]),
      "minimax a", m(ma2[0]), "worst", m(-mm2))

assert v1 == v2 == v3 == 872 and x1 == [28, 18, 10, 0] and h3 == 10   # three roads agree
assert bound == v1 and min(Y) >= 0 and min(red) >= 0                  # prices certify 872
assert v0 == 856 and 19 * dt + 20 * dc == y[0]                       # labour worth 3.60
assert b1 - (19 * xb1[0] + 20 * xb1[1] - true_cost(xb1[2] + xb1[3], 2, 1)) == 10
assert la[0] == ak == 3 and -l1 == total(3) and ma[0] == am == Fr(17, 5) and -mm == worst(am) == 12
assert Fr(3, 5) * 80 - Fr(2, 5) * 90 == -mm   # weights certify 12
print("ALL CHECKS PASS")
