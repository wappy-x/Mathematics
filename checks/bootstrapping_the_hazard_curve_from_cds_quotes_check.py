# Bootstrapping a CDS hazard curve: Northwind quotes 120, 200, 250 bp at 1, 3, 5 years.
# Quarterly premiums paid while alive, protection paid at the default date. Standard library only.
from math import exp, log

RATE, LOSS = 0.05, 0.60                 # riskless rate; loss on default = 1 - recovery 40%
KNOTS = [0.0, 1.0, 3.0, 5.0]
QUOTES = [0.0120, 0.0200, 0.0250]

def surv(t, lam):                       # S(t) = exp(-area under the step hazard); last piece runs on
    area = 0.0
    for i, h in enumerate(lam):
        right = KNOTS[i + 1] if i + 1 < len(lam) else float("inf")
        area += h * max(0.0, min(t, right) - KNOTS[i])
    return exp(-area)

def annuity(T, lam):                    # risky annuity: 0.25 years of premium per quarter survived, discounted
    return sum(0.25 * exp(-RATE * j / 4) * surv(j / 4, lam) for j in range(1, round(4 * T) + 1))

def pieces(T, lam):                     # (left, right, hazard) for each flat piece inside [0, T]
    edges = [0.0] + [k for k in KNOTS[1:len(lam)] if k < T] + [T]
    return [(edges[i], edges[i + 1], lam[i]) for i in range(len(edges) - 1)]

def prot_closed(T, lam):                # road 1: protection leg, exact integral on each flat piece
    total = 0.0
    for a, b, h in pieces(T, lam):
        k = RATE + h
        total += LOSS * exp(-RATE * a) * surv(a, lam) * h / k * (1 - exp(-k * (b - a)))
    return total

def prot_simpson(T, lam, n=64):         # road 2: the same integral, L * D(t) * hazard * S(t), by Simpson's rule
    total = 0.0
    for a, b, h in pieces(T, lam):
        g = lambda t: LOSS * exp(-RATE * t) * h * surv(t, lam)
        w = (b - a) / n
        total += w / 3 * sum((1 if j in (0, n) else 4 if j % 2 else 2) * g(a + j * w) for j in range(n + 1))
    return total

par, par2 = (lambda T, lam: prot_closed(T, lam) / annuity(T, lam)), (lambda T, lam: prot_simpson(T, lam) / annuity(T, lam))

def bisect(f, lo, hi):                  # own root finder; f rises from negative at lo to positive at hi
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < 0 else (lo, mid)
    return 0.5 * (lo + hi)

def bootstrap(quotes, low=0.0):         # one piece at a time, earlier pieces frozen
    lam = []
    for i, s in enumerate(quotes):
        lam.append(bisect(lambda h: par(KNOTS[i + 1], lam + [h]) - s, low, 1.0))
    return lam

f6, bp = (lambda x: f"{x:.6f}"), (lambda x: f"{10000 * x:.2f}")
lam = bootstrap(QUOTES)
print("Northwind: r 0.05, recovery 0.40, quarterly premiums, quotes 120/200/250 bp")
print("road 1: one piece at a time, bisection on closed-form legs")
for i in range(3):
    print(f"  piece {KNOTS[i]:.0f}-{KNOTS[i + 1]:.0f}y  hazard {f6(lam[i])}  S({KNOTS[i + 1]:.0f}) {f6(surv(KNOTS[i + 1], lam))}")
for T in (1.0, 3.0, 5.0):
    print(f"  legs to {T:.0f}y  annuity {f6(annuity(T, lam))}  protection {f6(prot_closed(T, lam))}")
print(f"  frozen weight D(1)S(1) {f6(exp(-RATE) * surv(1.0, lam))}  triangle guess 1y {f6(QUOTES[0] / LOSS)}  flat 2% 5y par {bp(par(5.0, [0.02]))} bp")
print("round trip: reprice every quote with the Simpson protection leg")
trip = [par2(KNOTS[i + 1], lam) for i in range(3)]
for i in range(3):
    print(f"  {KNOTS[i + 1]:.0f}y quote {bp(QUOTES[i])} bp  repriced {10000 * trip[i]:.6f} bp")

x = [s / LOSS for s in QUOTES]          # road 2: all three equations at once, Newton from the triangle guesses
for _ in range(8):
    G = [par2(KNOTS[i + 1], x) - QUOTES[i] for i in range(3)]
    J = [[(par2(KNOTS[i + 1], [x[m] + (1e-6 if m == j else 0.0) for m in range(3)]) - QUOTES[i] - G[i]) / 1e-6
          for j in range(3)] for i in range(3)]
    upper = [J[0][1], J[0][2], J[1][2]]
    A = [J[i][:] + [-G[i]] for i in range(3)]
    for c in range(3):                  # Gaussian elimination, written out
        for r in range(c + 1, 3):
            m = A[r][c] / A[c][c]
            A[r] = [A[r][k] - m * A[c][k] for k in range(4)]
    dx = [0.0, 0.0, 0.0]
    for r in (2, 1, 0):
        dx[r] = (A[r][3] - sum(A[r][k] * dx[k] for k in range(r + 1, 3))) / A[r][r]
    x = [x[i] + dx[i] for i in range(3)]
print("road 2: all three at once, Newton on Simpson legs, from triangle guesses")
print(f"  hazards {f6(x[0])} {f6(x[1])} {f6(x[2])}  Jacobian above diagonal {' '.join(f6(u) for u in upper)}")

state = 42                              # road 3: simulate default dates on the fitted curve, own generator
N, cum = 1000000, [0.0]
for j in range(1, 41): cum.append(cum[-1] + 0.25 * exp(-RATE * j / 4))
pr2 = pp2 = pr5 = pp5 = alive5 = 0.0
for _ in range(N):
    state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    e, tau = -log(((state >> 11) + 0.5) / 2 ** 53), None   # default when the hazard area reaches this draw
    for i, h in enumerate(lam):
        width = KNOTS[i + 1] - KNOTS[i] if i < 2 else float("inf")
        if e <= h * width: tau = KNOTS[i] + e / h; break
        e -= h * width
    q = min(int(4 * tau), 40)
    pr2 += cum[min(q, 8)]; pr5 += cum[min(q, 20)]
    pp2 += LOSS * exp(-RATE * tau) if tau <= 2 else 0.0
    pp5 += LOSS * exp(-RATE * tau) if tau <= 5 else 0.0
    alive5 += 1.0 if tau > 5 else 0.0
mc2, mc5, mcS5 = pp2 / pr2, pp5 / pr5, alive5 / N
print(f"road 3: Monte Carlo, {N} default dates on the road-1 curve")
se2 = 10000 * par(2.0, lam) * ((surv(2.0, lam) / (1 - surv(2.0, lam))) / N) ** 0.5
print(f"  2y par {bp(mc2)} bp (standard error {se2:.2f})  5y par {bp(mc5)} bp  S(5) {mcS5:.4f}")

print("unquoted tenors, hazard held at the last piece after 5y")
print(f"  2y par {bp(par(2.0, lam))} bp  straight line between quotes {bp(0.5 * (QUOTES[0] + QUOTES[1]))} bp  S(2) {f6(surv(2.0, lam))}")
print(f"  10y par {bp(par(10.0, lam))} bp  S(10) {f6(surv(10.0, lam))}")
yrs = range(1, 11)
line = lambda T: QUOTES[0] + (QUOTES[1] - QUOTES[0]) * (T - 1) / 2 if T <= 3 else min(QUOTES[1] + (QUOTES[2] - QUOTES[1]) * (T - 3) / 2, QUOTES[2])
print("chart, tenor (years)      " + " ".join(f"{T:6d}" for T in yrs))
print("chart, fitted par (bp)    " + " ".join(f"{10000 * par(float(T), lam):6.2f}" for T in yrs))
print("chart, straight line (bp) " + " ".join(f"{10000 * line(T):6.2f}" for T in yrs))
print("chart, hazard in year (%) " + " ".join(f"{100 * lam[0 if T <= 1 else 1 if T <= 3 else 2]:6.2f}" for T in yrs))
print("chart, par / loss (%)     " + " ".join(f"{100 * par(float(T), lam) / LOSS:6.2f}" for T in yrs))

tri = [s / LOSS for s in QUOTES]        # what breaks: the triangle, or each tenor's flat hazard, as the pieces
flat = [bisect(lambda h: par(KNOTS[i + 1], [h]) - QUOTES[i], 0.0, 1.0) for i in range(3)]
print("what breaks")
print(f"  triangle s/L as the pieces: 3y reprices {bp(par(3.0, tri))} bp, 5y {bp(par(5.0, tri))} bp")
print(f"  each tenor's flat hazard as its piece {f6(flat[1])} {f6(flat[2])}: 3y {bp(par(3.0, flat))} bp, 5y {bp(par(5.0, flat))} bp")
print(f"  no defaults after 5y: 10y par {bp(par(10.0, lam + [0.0]))} bp")

bad = [0.0600, 0.0200]                  # the failure case: an inverted pair
b1, neg, ok = bootstrap(bad[:1]), bootstrap(bad, low=-0.04), bootstrap([0.0600, 0.0300])
floor = par(3.0, b1 + [0.0])
print("failure case: 1y 600 bp, then 3y 200 bp")
print(f"  1y piece {f6(b1[0])}  3y floor at zero hazard {bp(floor)} bp")
print(f"  3y piece needed {f6(neg[1])}  S(1) {f6(surv(1.0, neg))}  S(3) {f6(surv(3.0, neg))}")
print(f"  1y 600 then 3y 300 bp fits: piece {f6(ok[1])}")

assert max(abs(x[i] - lam[i]) for i in range(3)) < 1e-9, "Newton on Simpson legs must find the bisection pieces"
assert max(abs(trip[i] - QUOTES[i]) for i in range(3)) < 1e-10, "round trip through the other integrator"
assert upper == [0.0, 0.0, 0.0], "a quote must not depend on later pieces"
assert abs(10000 * (mc2 - par(2.0, lam))) < 4 * se2, "simulation agrees with the formula at 2y"
assert abs(mcS5 - surv(5.0, lam)) < 4 * (surv(5.0, lam) * (1 - surv(5.0, lam)) / N) ** 0.5, "simulated survival"
assert floor > bad[1] and neg[1] < 0 < ok[1], "200 bp sits below the floor; 300 bp does not"
assert abs(10000 * par(5.0, [0.02]) - 121.06) < 0.005, "shelf's flat-hazard Northwind CDS"
assert abs(10000 * par(2.0, lam) - 180.1) < 0.05, "card's 2y number"
assert abs(10000 * par(10.0, lam) - 285.7) < 0.05, "card's 10y number"
print("ALL CHECKS PASS")
