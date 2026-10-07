# Rating transition matrix -- the check behind the card.  Standard library only.
# Three grades: 0 Solid, 1 Shaky, 2 Default (absorbing).  Every number on the card is printed here.
from math import log, exp, sqrt

P = [[0.90, 0.09, 0.01], [0.10, 0.80, 0.10], [0.00, 0.00, 1.00]]
G = ("Solid", "Shaky", "Default")

def mul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

def power(A, n):                        # road 1: multiply the one-year table n times
    R = [[float(i == j) for j in range(3)] for i in range(3)]
    for _ in range(n):
        R = mul(R, A)
    return R

def by_paths(i, n):                     # road 2: list every grade path, add up those ending in Default
    if n == 0:
        return 1.0 if i == 2 else 0.0
    return sum(P[i][j] * by_paths(j, n - 1) for j in range(3))

a, b, c, d = P[0][0], P[0][1], P[1][0], P[1][1]      # the two living grades only
root = sqrt((a - d) ** 2 + 4 * b * c)
mu1, mu2 = (a + d + root) / 2, (a + d - root) / 2     # eigenvalues of the living block

def by_eigen(i, n):                     # road 3: survival = A mu1^n + B mu2^n, no matrix powers
    s1 = P[i][0] + P[i][1]              # one-year survival from grade i
    A = (s1 - mu2) / (mu1 - mu2)
    return 1.0 - (A * mu1 ** n + (1.0 - A) * mu2 ** n)

state = 20260928                        # our own random numbers: 64-bit linear congruential
def uniform():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return (state >> 11) / 2.0 ** 53

def step(i):
    u, cum = uniform(), 0.0
    for j in range(3):
        cum += P[i][j]
        if u < cum:
            return j
    return 2

def simulate(i, n, firms):              # road 4: follow firms one year at a time
    hit = 0
    for _ in range(firms):
        g = i
        for _ in range(n):
            g = step(g)
        hit += g == 2
    return hit / firms

def hazard_by_bisection(pd, T):         # solve 1 - e^(-h T) = pd for h; one root since the left side only rises
    lo, hi = 0.0, 10.0
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if 1 - exp(-mid * T) < pd else (lo, mid)
    return (lo + hi) / 2

def row(label, *vals):
    print(f"{label:<40}" + "".join(f"{v:>11.6f}" for v in vals))

P2, P5 = power(P, 2), power(P, 5)
for i in range(2):
    row(f"P^2 row {G[i]} (to Solid Shaky Default)", *P2[i])
for i in range(2):
    row(f"P^5 row {G[i]} (to Solid Shaky Default)", *P5[i])
hand2 = P[0][0] * P[0][2] + P[0][1] * P[1][2] + P[0][2] * 1.0
row("PD Solid 2y: 0.9x0.01 + 0.09x0.10 + 0.01", hand2)
pd5 = P5[0][2]
mc = simulate(0, 5, 200000)
se = sqrt(pd5 * (1 - pd5) / 200000)
row("PD Solid 5y  road 1 matrix power", pd5)
row("PD Solid 5y  road 2 all 243 paths", by_paths(0, 5))
row("PD Solid 5y  road 3 eigenvalues", by_eigen(0, 5))
row("PD Solid 5y  road 4 simulated 200000", mc)
row("  simulation standard error", se)
row("PD Shaky 5y  roads 1 and 3", P5[1][2], by_eigen(1, 5))
row("eigenvalues mu1 mu2", mu1, mu2)
A0 = (P[0][0] + P[0][1] - mu2) / (mu1 - mu2)
row("eigen weights A, 1 - A, from Solid", A0, 1 - A0)
row("long-run yearly default 1 - mu1", 1 - mu1)
h_log, h_bis = -log(1 - pd5) / 5, hazard_by_bisection(pd5, 5)
row("avg hazard Solid 5y  log formula", h_log)
row("avg hazard Solid 5y  bisection", h_bis)
print()
print("   T   PD Solid   PD Shaky  hazard Solid  hazard Shaky  next-year PD Solid")
prev = 0.0
for T in range(1, 11):
    PT = power(P, T)
    ps, pk = PT[0][2], PT[1][2]
    print(f"{T:>4} {ps:>10.6f} {pk:>10.6f} {-log(1 - ps) / T:>13.6f} {-log(1 - pk) / T:>13.6f}"
          f" {(ps - prev) / (1 - prev):>18.6f}")
    prev = ps
years = range(11)
print("chart, year          " + "".join(f"{T:>6}" for T in years))
print("chart, PD Solid %    " + "".join(f"{100 * power(P, T)[0][2]:>6.2f}" for T in years))
print("chart, PD Shaky %    " + "".join(f"{100 * power(P, T)[1][2]:>6.2f}" for T in years))
print("chart, 1% x years    " + "".join(f"{1.0 * T:>6.2f}" for T in years))
print()
row("wrong: 5 x 1%", 5 * P[0][2])
row("wrong: 2 x 1%", 2 * P[0][2])
row("wrong: Solid forever, 1 - 0.99^5", 1 - (1 - P[0][2]) ** 5)
row("wrong: hazard = PD / T", pd5 / 5)
# cohort estimator: one simulated year for 100000 Solid and 100000 Shaky firms
counts = [[0, 0, 0], [0, 0, 0]]
for i in range(2):
    for _ in range(100000):
        counts[i][step(i)] += 1
Phat = [[n / 100000 for n in counts[i]] for i in range(2)] + [[0.0, 0.0, 1.0]]
for i in range(2):
    row(f"cohort row {G[i]}", *Phat[i])
row("PD Solid 5y from the cohort table", power(Phat, 5)[0][2])
# try changing
def pd_with(M, i, n):
    return power(M, n)[i][2]
row("try: Solid->Shaky 18%, stay 81%", pd_with([[0.81, 0.18, 0.01], P[1], P[2]], 0, 5))
row("try: Shaky defaults 20%, stays 70%", pd_with([P[0], [0.10, 0.70, 0.20], P[2]], 0, 5))
row("try: Shaky never recovers (0, 90%, 10%)", pd_with([P[0], [0.0, 0.90, 0.10], P[2]], 0, 5))
row("try: 30 years", pd_with(P, 0, 30))

assert abs(hand2 - P2[0][2]) < 1e-15, "two-year default: three paths by hand vs the matrix"
assert abs(pd5 - 0.108053) < 5e-7 and abs(h_log - 0.022870) < 5e-7, "the card's 10.81% and 2.29%, to six places"
assert abs(by_paths(0, 5) - pd5) < 1e-13, "path sum vs matrix power"
assert abs(by_eigen(0, 5) - pd5) < 1e-13 and abs(by_eigen(1, 5) - P5[1][2]) < 1e-13, "eigen road"
assert abs(mc - pd5) < 4 * se, "simulation within four standard errors"
assert abs(h_bis - h_log) < 1e-12, "bisection hazard vs log formula"
assert all(abs(sum(r) - 1.0) < 1e-13 for r in P5), "each row of P^5 is a full set of chances"
print("ALL CHECKS PASS")
