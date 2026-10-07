# Whose risk is it: component VaR by Euler's rule -- the check behind the card.
# Standard library only.  Nothing imported knows the answer: the normal CDF is
# Simpson's rule on the bell curve, the 99% point is found by bisection, the
# random numbers come from a 64-bit generator written out here.
from math import sqrt, exp, log, cos, sin, pi

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def N(x, n=2000):                                          # bell-curve area left of x
    h = x / n
    s = phi(0.0) + phi(x) + sum((4 if i % 2 else 2) * phi(i * h) for i in range(1, n))
    return 0.5 + s * h / 3.0
def z_of(p):                                               # bisection: N(z) = p
    lo, hi = 0.0, 10.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if N(mid) < p else (lo, mid)
    return 0.5 * (lo + hi)

# ---- the book: shares, bonds, and 1,000 Acme call contracts of 100 shares each ----
delta = exp(-0.02) * N(0.25)                     # house call's delta, d1 = 0.25
x = [10_000_000.0, 5_000_000.0, 1000 * 100 * delta * 100.0]   # dollars exposed, calls by delta
vol = [0.0135, 5 * 0.0006, 0.20 / sqrt(252)]     # one-day vols; bonds: 5-year duration x 6 bp
rho = [[1.0, -0.2, 0.5], [-0.2, 1.0, -0.1], [0.5, -0.1, 1.0]]   # bond price, so yield corrs flip sign
cov = [[rho[i][j] * vol[i] * vol[j] for j in range(3)] for i in range(3)]
names = ["shares", "bonds", "calls"]
z = z_of(0.99)
k = phi(z) / 0.01                                # normal ES multiplier

def sd(p): return sqrt(sum(p[i] * cov[i][j] * p[j] for i in range(3) for j in range(3)))
def var(p): return z * sd(p)

# Road 1: the gradient formula, dV/dx_i = z (Sigma x)_i / sigma
s = sd(x); V = var(x); ES = k * s
Sx = [sum(cov[i][j] * x[j] for j in range(3)) for i in range(3)]
marg = [z * Sx[i] / s for i in range(3)]
comp = [x[i] * marg[i] for i in range(3)]
comp_es = [k * x[i] * Sx[i] / s for i in range(3)]
# Road 2: nudge each position and watch VaR move (no gradient formula used)
fd = []
for i in range(3):
    h = 1e-4 * x[i]
    up = x[:]; up[i] += h; dn = x[:]; dn[i] -= h
    fd.append(x[i] * (var(up) - var(dn)) / (2 * h))
# Road 3: simulate 400,000 days and average each line's loss on the worst days
L = [[1.0, 0.0, 0.0], [0.0] * 3, [0.0] * 3]      # Cholesky factor of rho, by hand
L[1][0] = rho[1][0]; L[1][1] = sqrt(1 - L[1][0] ** 2)
L[2][0] = rho[2][0]; L[2][1] = (rho[2][1] - L[2][0] * L[1][0]) / L[1][1]
L[2][2] = sqrt(1 - L[2][0] ** 2 - L[2][1] ** 2)
state = 20260928
def unif():
    global state
    state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64
    return ((state >> 11) + 0.5) / 2 ** 53
days, M = [], 400_000
for _ in range(M):
    a, b = sqrt(-2 * log(unif())), 2 * pi * unif()
    c, g = sqrt(-2 * log(unif())), 2 * pi * unif()
    e = [a * cos(b), a * sin(b), c * cos(g)]     # three independent bell-curve draws
    w = [sum(L[i][j] * e[j] for j in range(3)) for i in range(3)]
    loss = [-x[i] * vol[i] * w[i] for i in range(3)]
    days.append((sum(loss), loss))
days.sort(key=lambda d: -d[0])
tail = M // 100
mc_var = days[tail][0]
mc_es = [sum(d[1][i] for d in days[:tail]) / tail for i in range(3)]
band = days[tail - 400: tail + 400]              # days whose loss sits near the VaR
mc_vc = [sum(d[1][i] for d in band) / len(band) for i in range(3)]
mc_sd = sqrt(sum(d[0] ** 2 for d in days) / M)

def t(v): return f"{v / 1000:10.2f}"             # thousands of dollars
print(f"z(99%) {z:.6f}   ES multiplier {k:.6f}   call delta {delta:.6f}")
print(f"exposure $k      {t(x[0])}{t(x[1])}{t(x[2])}")
print("Sigma x, dollars   " + "".join(f"{v:10.2f}" for v in Sx))
print("x_i (Sigma x)_i $k^2" + "".join(f"{x[i] * Sx[i] / 1e6:12.2f}" for i in range(3))
      + f"  sum {sum(x[i] * Sx[i] for i in range(3)) / 1e6:.2f}")
print(f"one-day sd $k {t(s)}   sd by simulation {t(mc_sd)}")
print(f"VaR 99% $k    {t(V)}   VaR by simulation {t(mc_var)}")
print(f"ES 99% $k     {t(ES)}   ES by simulation {t(sum(mc_es))}")
print(f"{'line':<8}{'marg c/$':>10}{'comp VaR':>10}{'by nudge':>10}{'by sim':>10}{'share %':>10}{'comp ES':>10}{'ES sim':>10}")
for i in range(3):
    print(f"{names[i]:<8}{100 * marg[i]:10.4f}{t(comp[i])}{t(fd[i])}{t(mc_vc[i])}"
          f"{100 * comp[i] / V:10.2f}{t(comp_es[i])}{t(mc_es[i])}")
print(f"{'sum':<8}{'':>10}{t(sum(comp))}{t(sum(fd))}{t(sum(mc_vc))}{100 * sum(comp) / V:10.2f}"
      f"{t(sum(comp_es))}{t(sum(mc_es))}")
print(f"Euler by scaling: VaR(2x) / VaR(x) = {var([2 * v for v in x]) / V:.6f}")
# ---- incremental VaR: recompute the whole book after a real trade ----
for i in range(3):
    p = x[:]; p[i] = 0.0
    print(f"sell all {names[i]:<7} VaR {t(var(p))}  change {t(var(p) - V)}  minus component {t(-comp[i])}")
p = x[:]; p[0] += 100_000.0
print(f"buy $100k shares: change {var(p) - V:10.2f}   marginal x 100k {marg[0] * 100_000:10.2f}")
# ---- what breaks ----
alone = [z * abs(x[i]) * vol[i] for i in range(3)]
print("standalone VaR $k " + "".join(t(a) for a in alone) + f"  sum {t(sum(alone))}")
print(f"wrong: shares % of standalone sum {100 * alone[0] / sum(alone):6.2f}")
own = [x[i] ** 2 * cov[i][i] for i in range(3)]
print(f"wrong: shares % of own-variance sum {100 * own[0] / sum(own):6.2f}")
print(f"wrong: remove-one changes summed $k {t(sum(V - var([0.0 if j == i else x[j] for j in range(3)]) for i in range(3)))}")
# ---- chart: VaR as the call position grows, and the tangent at 1,000 contracts ----
cs = [250 * n for n in range(9)]
curve = [var([x[0], x[1], c * 100 * delta * 100.0]) for c in cs]
tang = [V + marg[2] * (c - 1000) * 100 * delta * 100.0 for c in cs]
print("chart contracts " + " ".join(f"{c:7d}" for c in cs))
print("chart VaR $k    " + " ".join(f"{v / 1000:7.2f}" for v in curve))
print("chart tangent $k" + " ".join(f"{v / 1000:7.2f}" for v in tang))
# ---- try changing ----
for label, r in (("try: shares-Acme corr 0", 0.0), ("try: shares-Acme corr 0.9", 0.9)):
    rr = [row[:] for row in rho]; rr[0][2] = rr[2][0] = r
    cv = [[rr[i][j] * vol[i] * vol[j] for j in range(3)] for i in range(3)]
    sv = sqrt(sum(x[i] * cv[i][j] * x[j] for i in range(3) for j in range(3)))
    sh = x[0] * sum(cv[0][j] * x[j] for j in range(3)) / sv ** 2
    print(f"{label:<27} VaR {t(z * sv)}  shares % {100 * sh:6.2f}")

assert abs(sum(fd) - V) < 1e-6 * V                     # nudged pieces add to the total
assert all(abs(fd[i] - comp[i]) < 1e-6 * V for i in range(3))
assert abs(mc_var - V) < 0.02 * V                      # simulation lands on the formula
assert all(abs(sum(d[1][i] * d[1][j] for d in days) / (M * x[i] * vol[i] * x[j] * vol[j]) - rho[i][j]) < 0.01
           for i in range(3) for j in range(3))    # simulated days carry the model's correlations
assert all(abs(mc_es[i] - comp_es[i]) < 0.02 * ES for i in range(3))
assert all(abs(mc_vc[i] - comp[i]) < 0.03 * V for i in range(3))
assert 0.69 < comp[0] / V < 0.70                        # about 70 percent, as on the card
assert V - var([x[0], x[1], 0.0]) < comp[2]            # a whole sale saves less than the component
print("ALL CHECKS PASS")
