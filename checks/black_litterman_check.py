# Black-Litterman -- the check behind the card.  Python standard library only.
# Assets in the order shares, bonds, gold.  Reverse optimisation gives the
# returns the market's weights imply; the posterior is then reached three
# ways: the view-space formula, the precision (Bayes) formula, and a Monte
# Carlo draw from the prior, each draw weighted by how well it fits the views.
import math

VOL = [0.20, 0.06, 0.15]
CORR = [[1.0, 0.2, 0.1], [0.2, 1.0, 0.0], [0.1, 0.0, 1.0]]
SIG = [[CORR[i][j] * VOL[i] * VOL[j] for j in range(3)] for i in range(3)]
W_MKT = [0.55, 0.30, 0.15]                 # the market's weights
DELTA, TAU = 2.5, 0.05                     # risk aversion, prior scale
P = [[0.0, -1.0, 1.0], [1.0, 0.0, 0.0]]    # view 1: gold minus bonds; view 2: shares
Q = [0.02, 0.04]                           # the views, as returns above cash


def matvec(a, x):
    return [sum(r[j] * x[j] for j in range(len(x))) for r in a]


def solve(a, b):                           # Gaussian elimination, partial pivoting
    n = len(b)
    m = [list(a[i]) + [b[i]] for i in range(n)]
    for j in range(n):
        p = max(range(j, n), key=lambda i: abs(m[i][j]))
        m[j], m[p] = m[p], m[j]
        for i in range(n):
            if i != j:
                f = m[i][j] / m[j][j]
                m[i] = [u - f * v for u, v in zip(m[i], m[j])]
    return [m[i][n] / m[i][i] for i in range(n)]


PI = [DELTA * v for v in matvec(SIG, W_MKT)]   # reverse optimisation


def omega_for(p, conf):                    # confidence c -> view variance
    pcp = sum(p[i] * TAU * SIG[i][j] * p[j] for i in range(3) for j in range(3))
    return pcp * (1.0 - conf) / conf


def posterior(rows, q, om, tau=TAU):       # view-space form: a k x k solve
    k = len(rows)
    cp = [[tau * sum(SIG[i][j] * rows[a][j] for j in range(3)) for a in range(k)] for i in range(3)]
    s = [[sum(rows[a][i] * cp[i][b] for i in range(3)) + (om[a] if a == b else 0.0)
          for b in range(k)] for a in range(k)]
    z = solve(s, [q[a] - sum(rows[a][i] * PI[i] for i in range(3)) for a in range(k)])
    return [PI[i] + sum(cp[i][a] * z[a] for a in range(k)) for i in range(3)], z


def precision_form(om, q=Q):               # Bayes form: a 3 x 3 solve
    cols = [solve([[TAU * v for v in r] for r in SIG], [float(i == j) for i in range(3)])
            for j in range(3)]             # columns of the prior precision
    a = [[cols[j][i] + sum(P[k][i] * P[k][j] / om[k] for k in range(2)) for j in range(3)]
         for i in range(3)]
    b = [sum(cols[j][i] * PI[j] for j in range(3)) + sum(P[k][i] * q[k] / om[k] for k in range(2))
         for i in range(3)]
    return solve(a, b)


def weights(mu):
    return solve(SIG, [v / DELTA for v in mu])


state = 20260928
def uniform():                             # splitmix64, written out
    global state
    M = (1 << 64) - 1
    state = (state + 0x9E3779B97F4A7C15) & M
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0


def monte_carlo(om, n):                    # prior draws, weighted by the views
    l = [[0.0] * 3 for _ in range(3)]      # Cholesky factor of tau * Sigma
    for i in range(3):
        for j in range(i + 1):
            r = TAU * SIG[i][j] - sum(l[i][k] * l[j][k] for k in range(j))
            l[i][j] = math.sqrt(r) if i == j else r / l[j][j]
    draws = []
    for _ in range(n):
        e = [math.sqrt(-2.0 * math.log(uniform())) * math.cos(2.0 * math.pi * uniform())
             for _ in range(3)]
        th = [PI[i] + sum(l[i][k] * e[k] for k in range(i + 1)) for i in range(3)]
        g = sum((Q[a] - sum(P[a][i] * th[i] for i in range(3))) ** 2 / om[a] for a in range(2))
        draws.append((math.exp(-0.5 * g), th))
    sw = sum(w for w, _ in draws)
    mean = [sum(w * th[i] for w, th in draws) / sw for i in range(3)]
    se = [math.sqrt(sum((w * (th[i] - mean[i])) ** 2 for w, th in draws)) / sw for i in range(3)]
    return mean, se


def pct(xs, d=4):
    return "  ".join(f"{100 * x:.{d}f}" for x in xs)


for name, row in zip(("shares", "bonds ", "gold  "), SIG):
    print("covariance row", name, pct(row))
var_m = sum(W_MKT[i] * SIG[i][j] * W_MKT[j] for i in range(3) for j in range(3))
print("market volatility", f"{100 * math.sqrt(var_m):.4f}", " premium", f"{100 * DELTA * var_m:.4f}")
print("implied returns pi       ", pct(PI))
print("optimiser fed pi returns ", pct(back := weights(PI)))
om = [omega_for(p, 0.5) for p in P]
print("view variances x 10000   ", pct([100 * v for v in om]))
print("prior view values        ", pct(matvec(P, PI)))
mu, z = posterior(P, Q, om)
mc, se = monte_carlo(om, 400000)
print("posterior, view-space    ", pct(mu))
print("posterior, precision     ", pct(mu_b := precision_form(om)))
print("posterior, Monte Carlo   ", pct(mc))
print("Monte Carlo std error    ", pct(se))
print("posterior view values    ", pct(matvec(P, mu)))
w_bl = weights(mu)
lam = [TAU / DELTA * v for v in z]
tilt = [W_MKT[i] + sum(P[a][i] * lam[a] for a in range(2)) for i in range(3)]
print("weights, optimiser       ", pct(w_bl), " cash", f"{100 * (1 - sum(w_bl)):.4f}")
print("weights, market + tilts  ", pct(tilt), " lambda", pct(lam))
print("confidence in view 1: spread, then weights shares bonds gold")
for c in (0.0, 0.25, 0.5, 0.75, 1.0):
    m = posterior(P[1:], Q[1:], om[1:])[0] if c == 0 else posterior(P, Q, [omega_for(P[0], c), om[1]])[0]
    print(f"  c = {100 * c:3.0f}", pct([m[2] - m[1]] + weights(m), 2))
certain = posterior(P, Q, [0.0, om[1]])[0]
still = precision_form(om, matvec(P, PI))
print("mistakes, weights shares bonds gold:")
print("  tau = 1, views unchanged     ", pct(weights(posterior(P, Q, om, 1.0)[0]), 2))
print("  view row flipped (bonds-gold)", pct(weights(posterior([[0.0, 1.0, -1.0], P[1]], Q, om)[0]), 2))
gold = [0.0, 0.0, 1.0]
print("  gold view read as absolute   ", pct(weights(posterior([gold, P[1]], Q, [omega_for(gold, 0.5), om[1]])[0]), 2))
print("  both views certain (omega 0) ", pct(weights(posterior(P, Q, [0.0, 0.0])[0]), 2))
assert max(abs(back[i] - W_MKT[i]) for i in range(3)) < 1e-12
assert max(abs(mu[i] - mu_b[i]) for i in range(3)) < 1e-12
assert all(abs(mc[i] - mu[i]) < 4 * se[i] for i in range(3))
assert max(abs(w_bl[i] - tilt[i]) for i in range(3)) < 1e-12
assert abs(certain[2] - certain[1] - Q[0]) < 1e-12
assert max(abs(still[i] - PI[i]) for i in range(3)) < 1e-12
one = posterior(P[:1], Q[:1], [omega_for(P[0], 0.25)])[0]    # one view alone moves a quarter of the way
assert abs(one[2] - one[1] - (PI[2] - PI[1] + 0.25 * (Q[0] - PI[2] + PI[1]))) < 1e-12
print("all checks passed")
