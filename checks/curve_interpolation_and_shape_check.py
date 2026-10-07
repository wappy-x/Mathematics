# Curve interpolation and shape -- the check behind the card.  Standard library only: the quadrature rule,
# the three-by-three solve and the tau sweep are written out.  Six pillars, filled three ways, then compared.
from math import log, exp, sqrt

T = [0.0, 0.25, 1.0, 2.0, 5.0, 10.0, 30.0]            # today, then the six quoted dates, in years
Z = [0.0430, 0.0400, 0.0380, 0.0390, 0.0420, 0.0450]  # the bootstrap's zero rates, a year each
D = [1.0] + [exp(-z * t) for z, t in zip(Z, T[1:])]   # discount factors at the pillars
L = [log(d) for d in D]                               # and their logarithms
H = [T[i + 1] - T[i] for i in range(6)]               # gap lengths, in years
SEG = [(L[i] - L[i + 1]) / H[i] for i in range(6)]    # the segment forwards the quotes pin down

def gauss(f, a, b, n):                                # two sample points per strip, ends untouched
    h = (b - a) / n; c = h / (2.0 * sqrt(3.0))        # exact for any cubic on each strip
    return h / 2.0 * sum(f(a + (i + 0.5) * h - c) + f(a + (i + 0.5) * h + c) for i in range(n))
def integral(f, a, b, breaks, n):                     # cut at the breaks, n strips per piece
    p = [a] + sorted(x for x in breaks if a < x < b) + [b]
    return sum(gauss(f, p[k], p[k + 1], n) for k in range(len(p) - 1))
def gap(t): return next((i for i in range(6) if t < T[i + 1]), 5)   # a pillar starts a new gap
def f_loglin(t): return SEG[gap(t)]                   # rule 1's forward: one flat step per gap
def d_loglin(t):                                      # rule 1: a straight line between the log discounts
    i = gap(t); w = (t - T[i]) / H[i]; return exp((1.0 - w) * L[i] + w * L[i + 1])

PF = [0.0] * 7                                        # rule 2, step one: a forward at every pillar
for i in range(1, 6):
    PF[i] = (H[i] * SEG[i - 1] + H[i - 1] * SEG[i]) / (H[i - 1] + H[i])
PF[0] = SEG[0] - 0.5 * (PF[1] - SEG[0])
PF[6] = SEG[5] - 0.5 * (PF[5] - SEG[5])

def shape(i):                                         # Hagan-West: which region, and where it turns
    g0, g1 = PF[i] - SEG[i], PF[i + 1] - SEG[i]       # the two ends, measured from the segment forward
    if g0 == 0.0 or g1 == 0.0 or (g0 < 0 and -0.5 * g0 <= g1 <= -2.0 * g0) or (g0 > 0 and -0.5 * g0 >= g1 >= -2.0 * g0):
        return g0, g1, 1, 1.0                         # the plain parabola already behaves
    if (g0 < 0 and g1 > -2.0 * g0) or (g0 > 0 and g1 < -2.0 * g0):
        return g0, g1, 2, (g1 + 2.0 * g0) / (g1 - g0)   # flat, then a curve
    if (g0 > 0 > g1 > -0.5 * g0) or (g0 < 0 < g1 < -0.5 * g0):
        return g0, g1, 3, 3.0 * g1 / (g1 - g0)        # a curve, then flat
    return g0, g1, 4, g1 / (g0 + g1)                  # both ends the same side: a dip between them

def f_mc(t):                                          # rule 2: the monotone convex forward
    i = gap(t); x = (t - T[i]) / H[i]
    g0, g1, region, eta = shape(i)
    if region == 1:
        g = g0 * (1.0 - 4.0 * x + 3.0 * x * x) + g1 * (3.0 * x * x - 2.0 * x)
    elif region == 2:
        g = g0 if x <= eta else g0 + (g1 - g0) * ((x - eta) / (1.0 - eta)) ** 2
    elif region == 3:
        g = g1 + (g0 - g1) * ((eta - x) / eta) ** 2 if x < eta else g1
    else:
        a = -g0 * g1 / (g0 + g1)
        g = a + (g0 - a) * ((eta - x) / eta) ** 2 if x < eta else a + (g1 - a) * ((x - eta) / (1.0 - eta)) ** 2
    return SEG[i] + g

BREAKS = T + [T[i] + shape(i)[3] * H[i] for i in range(6)]    # pillars plus every turning point
def d_mc(t): return exp(-integral(f_mc, 0.0, t, BREAKS, 1))
def basis(t, tau):                                    # rule 3: the three Nelson-Siegel shapes at t
    e = exp(-t / tau); slope = (1.0 - e) / (t / tau); return 1.0, slope, slope - e
def solve3(A, v):                                     # Gaussian elimination, largest pivot first
    M = [row[:] + [b] for row, b in zip(A, v)]
    for c in range(3):
        p = max(range(c, 3), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(3):
            if r != c:
                M[r] = [M[r][k] - M[r][c] / M[c][c] * M[c][k] for k in range(4)]
    return [M[i][3] / M[i][i] for i in range(3)]

def fit(tau):                                         # least squares on the six quotes, tau held fixed
    rows = [basis(t, tau) for t in T[1:]]
    A = [[sum(r[a] * r[b] for r in rows) for b in range(3)] for a in range(3)]
    return solve3(A, [sum(r[a] * z for r, z in zip(rows, Z)) for a in range(3)])

def sse(tau, beta):                                   # total squared miss across the six quotes
    return sum((sum(c * r for c, r in zip(beta, basis(t, tau))) - z) ** 2 for t, z in zip(T[1:], Z))
TAU = min((k * 0.01 for k in range(10, 1501)), key=lambda tau: sse(tau, fit(tau)))
BETA = fit(TAU)
def z_ns(t): return sum(c * r for c, r in zip(BETA, basis(t, TAU)))
def f_ns(t): return BETA[0] + (BETA[1] + BETA[2] * t / TAU) * exp(-t / TAU)
def d_ns(t): return exp(-z_ns(t) * t)

def d_lind(t):                                        # mistake: a straight line between the discounts
    i = gap(t); w = (t - T[i]) / H[i]; return (1.0 - w) * D[i] + w * D[i + 1]
def f_lind(t): return (D[gap(t)] - D[gap(t) + 1]) / H[gap(t)] / d_lind(t)
ZF = [Z[0]] + Z                                       # mistake: a straight line between the zero rates
def z_linz(t):
    i = gap(t); w = (t - T[i]) / H[i]; return (1.0 - w) * ZF[i] + w * ZF[i + 1]
def f_linz(t): return z_linz(t) + t * (ZF[gap(t) + 1] - ZF[gap(t)]) / H[gap(t)]

PAY, EPS = 10000000.0, 1e-9
print("six pillars from one morning: years, zero rate %, discount factor, log discount")
for t, z, d, l in zip(T[1:], Z, D[1:], L[1:]):
    print(f"{t:8.2f}{100 * z:9.4f}{d:12.6f}{l:12.6f}")
print("across each gap: the segment forward %, then the shape monotone convex gives it")
for i in range(6):
    g0, g1, region, eta = shape(i)
    print(f"{T[i]:6.2f} to{T[i + 1]:6.2f}{100 * SEG[i]:9.4f}   region {region}   ends"
          f"{100 * g0:+8.4f}{100 * g1:+8.4f}   turn at{eta:7.4f}")
print("monotone convex, forward at each pillar %: " + " ".join(f"{100 * p:.4f}" for p in PF))
print("three forward curves, % a year: years, log-linear, monotone convex, Nelson-Siegel")
for k in range(10):
    t = 0.5 + k
    print(f"{t:8.2f}{100 * f_loglin(t):8.2f}{100 * f_mc(t):8.2f}{100 * f_ns(t):8.2f}")
three = (f_loglin(2.5), f_mc(2.5), f_ns(2.5))
print(f"forward at 2.50 years %: log-linear {100 * three[0]:.4f}, monotone convex {100 * three[1]:.4f}, "
      f"Nelson-Siegel {100 * three[2]:.4f}; widest gap {10000 * (max(three) - min(three)):.2f} basis points")
print(f"forward at 3.00 years %: log-linear {100 * f_loglin(3.0):.4f}, monotone convex {100 * f_mc(3.0):.4f}, "
      f"Nelson-Siegel {100 * f_ns(3.0):.4f}")
print(f"monotone convex, average forward from 2 to 3 years %: {100 * integral(f_mc, 2.0, 3.0, BREAKS, 1):.4f}")
print(f"Nelson-Siegel fit: tau {TAU:.2f} years, beta0 {100 * BETA[0]:.4f}, beta1 {100 * BETA[1]:.4f}, "
      f"beta2 {100 * BETA[2]:.4f}, all % a year")
print("Nelson-Siegel minus the quote at each pillar, basis points: "
      + " ".join(f"{10000 * (z_ns(t) - z):+.2f}" for t, z in zip(T[1:], Z)))
def worst(rule): return 10000 * max(abs(log(rule(t) / d) / t) for t, d in zip(T[1:], D[1:]))
print(f"largest quote missed, basis points: log-linear {worst(d_loglin):.4f}, monotone convex "
      f"{worst(d_mc):.4f}, Nelson-Siegel {worst(d_ns):.4f}")
print(f"{PAY:.2f} due in 1 year: the quotes say {PAY * D[2]:.2f}, Nelson-Siegel says {PAY * d_ns(1.0):.2f}, "
      f"a gap of {PAY * (d_ns(1.0) - D[2]):.2f}")
print(f"the 3-year discount factor, {PAY:.2f} due in 3 years, and the gap to the log-linear value")
for name, d in (("log-linear", d_loglin(3.0)), ("monotone convex", d_mc(3.0)), ("Nelson-Siegel", d_ns(3.0)),
                ("line between discounts", d_lind(3.0)), ("line between zero rates", exp(-z_linz(3.0) * 3.0))):
    print(f"  {name:<24}{d:12.6f}{PAY * d:16.2f}{PAY * (d - d_loglin(3.0)):+12.2f}")
print("forward across the 10-year pillar, % a year: log-linear "
      f"{100 * f_loglin(10.0 - EPS):.4f} to {100 * f_loglin(10.0 + EPS):.4f}, monotone convex "
      f"{100 * f_mc(10.0 - EPS):.4f} to {100 * f_mc(10.0 + EPS):.4f}, line between zero rates "
      f"{100 * f_linz(10.0 - EPS):.4f} to {100 * f_linz(10.0 + EPS):.4f}")
print(f"inside the 2-to-5-year gap the line between discounts slides the forward from {100 * f_lind(2.0):.4f}"
      f" to {100 * f_lind(5.0 - EPS):.4f} % a year, on no instruction from the quotes")
for i in range(1, 6):                                 # the pillar forwards, read off the step midpoints
    assert abs(PF[i] - (SEG[i - 1] + (SEG[i] - SEG[i - 1]) * H[i - 1] / (H[i - 1] + H[i]))) < 1e-15
for t, d in zip(T[1:], D[1:]):                        # both exact rules hand every quote back
    assert abs(d_loglin(t) - d) < 1e-12 and abs(d_mc(t) - d) < 1e-12
assert abs(d_loglin(3.0) - exp(-integral(f_loglin, 0.0, 3.0, T, 1))) < 1e-12
for i in range(6):                                    # area under the forward equals the quoted gap
    assert abs(integral(f_mc, T[i], T[i + 1], BREAKS, 1) - H[i] * SEG[i]) < 1e-14
assert abs(z_ns(5.0) * 5.0 - integral(f_ns, 0.0, 5.0, [], 2000)) < 1e-11
for j in range(3):                                    # the fitted levels sit at a genuine low point
    for step in (1e-5, -1e-5):
        moved = [BETA[0], BETA[1], BETA[2]]; moved[j] += step
        assert sse(TAU, moved) > sse(TAU, BETA)
assert max(abs(f_mc(t + EPS) - f_mc(t - EPS)) for t in T[1:6]) < 1e-9
assert abs(f_loglin(10.0 + EPS) - f_loglin(10.0 - EPS)) > 0.001
print("ALL CHECKS PASS")
