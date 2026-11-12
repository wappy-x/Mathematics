# Weighted Gauss rules -- the check behind the card.  Python standard library only.
# Nodes are roots of the three-term recurrences, found by a scan and bisection;
# weights come from the closed weight formulas.  Nothing imported knows a node.
# Road 1: closed forms.  Road 2: the weighted Gauss rule at many sizes, with the
# first-missed-term estimate.  Road 3: Simpson's rule on a fine grid, no weights.
from math import exp, sqrt, pi, log, log10, cos
def sci(x, d=2):                                # 1.23e-5, the same digits in Rust
    m, e = f"{x:.{d}e}".split("e")
    return f"{m}e{int(e)}"
def herm(n, x):                                 # physicists' H_n(x) and H_(n-1)(x)
    a, b = 0.0, 1.0
    for k in range(n):
        a, b = b, 2.0 * x * b - 2.0 * k * a
    return b, a
def lag(n, x):                                  # Laguerre L_n(x) and L_(n-1)(x)
    a, b = 0.0, 1.0
    for k in range(n):
        a, b = b, ((2 * k + 1 - x) * b - k * a) / (k + 1)
    return b, a
def roots(p, n, lo, count):                     # scan in steps of 0.001, then bisect
    out, x0, f0 = [], lo, p(n, lo)[0]
    for i in range(1, count + 1):
        x1 = lo + i * 0.001
        f1 = p(n, x1)[0]
        if (f0 < 0) != (f1 < 0):
            a, b = x0, x1
            for _ in range(60):
                m = 0.5 * (a + b)
                if (p(n, m)[0] < 0) == (f0 < 0): a = m
                else: b = m
            out.append(0.5 * (a + b))
        x0, f0 = x1, f1
    return out
def fact(n):
    f = 1.0
    for k in range(2, n + 1): f *= k
    return f
def pw(x, k):                                   # x to the power k, by plain multiplying
    r = 1.0
    for _ in range(k): r *= x
    return r
def dot(ws, vs):                                # plain left-to-right sum of w times v
    s = 0.0
    for w, v in zip(ws, vs): s += w * v
    return s
def hermite(n):                                 # nodes x_i, probabilities p_i = w_i / sqrt(pi)
    xs = roots(herm, n, -7.000123, 14000)
    return xs, [pw(2.0, n - 1) * fact(n) / (n * n * pw(herm(n - 1, x)[0], 2)) for x in xs]
def laguerre(n):                                # nodes x_i, weights w_i for the weight e^(-x)
    xs = roots(lag, n, 0.000123, 60000)
    return xs, [x / (n * n * pw(lag(n - 1, x)[0], 2)) for x in xs]
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0
def ncdf(d):                                    # normal area left of d, from the erf series
    x, t, s = d / sqrt(2.0), d / sqrt(2.0), 0.0
    for k in range(40):
        s += t / (2 * k + 1)
        t *= -x * x / (k + 1)
    return 0.5 + s / sqrt(pi)
S0, MU, SIG, T, K = 50.0, 0.08, 0.60, 2.0, 50.0  # share $50, drift 8%, volatility 60%, 2 years
M, V = (MU - 0.5 * SIG * SIG) * T, SIG * sqrt(T) # centre and spread of log(S_T / S0)
def share(z): return S0 * exp(M + V * z)        # the share's price when the normal draw is z
def call(z): return max(share(z) - K, 0.0)      # the option's payoff: kinked at the strike
def phi(z): return exp(-0.5 * z * z) / sqrt(2.0 * pi)
def gh(f, n, r2=sqrt(2.0), twice=False):        # E[f(Z)] by n Gauss-Hermite nodes
    xs, ps = hermite(n)
    return dot(ps, [(exp(-x * x) if twice else 1.0) * f(r2 * x) for x in xs])
exact = S0 * exp(MU * T)
d2 = (log(S0 / K) + M) / V
c_exact = exact * ncdf(d2 + V) - K * ncdf(d2)
xs, ps = hermite(7)
print(f"log-price centre m = {M:.6f}, spread v = {V:.10f}, slope a = v sqrt2 = {V * sqrt(2.0):.10f}")
print("i  node x_i       z = sqrt2 x_i  probability p_i  share at node  p_i x share")
for i in range(7):
    s = share(sqrt(2.0) * xs[i])
    print(f"{i + 1}  {xs[i]:+.10f}  {sqrt(2.0) * xs[i]:+.6f}      {ps[i]:.10f}  {s:12.6f}  {ps[i] * s:11.6f}")
psum = dot(ps, [1.0] * 7)
z12 = dot(ps, [pw(sqrt(2.0) * x, 12) for x in xs])
z14 = dot(ps, [pw(sqrt(2.0) * x, 14) for x in xs])
print(f"sum of probabilities {psum:.15f}; E[Z^12] rule {z12:.6f} (true 10395); E[Z^14] rule {z14:.6f} (true 135135, short {135135.0 - z14:.6f})")
g7 = gh(share, 7)
simp = simpson(lambda z: phi(z) * share(z), -10.0, 10.0, 2000)
print(f"expected share price: closed form {exact:.10f}; 7 nodes {g7:.10f} err {sci(g7 - exact)}")
print(f"Simpson, 2000 steps on [-10, 10]: {simp:.10f} err {sci(simp - exact)}")
se = {n: simpson(lambda z: phi(z) * share(z), -10.0, 10.0, n) - exact for n in range(2, 101, 2)}
ns = max(n for n in se if abs(se[n]) > abs(g7 - exact)) + 2   # from here on Simpson stays within the 7-node error
print(f"Simpson on [-10, 10] stays within the 7-node error from {ns} steps, {ns + 1} payoffs: err {sci(se[ns])}")
print(" n  rule E[S_T]      true err   estimate   ratio  log10|err|  call err  log10|err|")
ratio, cerr = {}, {}
for n in range(1, 13):
    g = gh(share, n)
    est = -S0 * exp(M) * pw(V * sqrt(2.0), 2 * n) * fact(n) / (fact(2 * n) * pw(2.0, n))
    ratio[n], cerr[n] = (est / (g - exact) if g != exact else 0.0), gh(call, n) - c_exact
    print(f"{n:2d}  {g:15.10f}  {sci(g - exact):>9}  {sci(est):>9}  {ratio[n]:6.3f}  {log10(max(abs(g - exact), 1e-16)):6.2f}"
          f"  {sci(cerr[n]):>9}  {log10(abs(cerr[n])):6.2f}")
zk = (log(K / S0) - M) / V                      # where the payoff kinks: the share hits the strike
c_simp = simpson(lambda z: phi(z) * call(z), zk, 10.0, 2000)
print(f"call, strike 50: closed form {c_exact:.10f}; Simpson from the kink {c_simp:.10f}; 7 nodes {c_exact + cerr[7]:.6f}")
no_r2, no_pi, twice = gh(share, 7, 1.0), g7 * sqrt(pi), gh(share, 7, sqrt(2.0), True)
print(f"wrong: no sqrt2 {no_r2:.6f}; no 1/sqrt(pi) {no_pi:.6f}; weight counted twice {twice:.6f}")
def refund(x): return 1.0 / (1.0 + x)           # warranty refund fraction for a failure at year x
w_simp = simpson(lambda x: exp(-x) * refund(x), 0.0, 40.0, 40000)
print(f"warranty, Simpson on [0, 40], 40000 steps: {w_simp:.12f}")
lag_err = {}
for n in (3, 7, 14):
    lx, lw = laguerre(n)
    q = dot(lw, [refund(x) for x in lx])
    lag_err[n] = q - w_simp
    lm = max(abs(dot(lw, [pw(x, k) for x in lx]) / fact(k) - 1.0) for k in range(2 * n))   # exact: k! up to degree 2n - 1
    print(f"Laguerre {n:2d} nodes: {q:.12f} err {sci(q - w_simp)}; weights sum {dot(lw, [1.0] * n):.12f}; moments k! to degree {2 * n - 1} within {sci(lm)}")
    assert lm < 1e-10, "Laguerre moments match k!"
i0, t = 0.0, 1.0
for k in range(30):
    i0 += t
    t /= 4.0 * (k + 1) * (k + 1)
ch = dot([pi / 7] * 7, [exp(cos((2 * i - 1) * pi / 14)) for i in range(1, 8)])
print(f"Chebyshev 7 nodes on e^x/sqrt(1-x^2): {ch:.12f}; pi I0(1) series {pi * i0:.12f}; err {sci(ch - pi * i0)}")
for lab, sg, tt in (("volatility 30%", 0.30, 2.0), ("8 years", 0.60, 8.0)):
    m2, v2 = (MU - 0.5 * sg * sg) * tt, sg * sqrt(tt)
    gg = gh(lambda z: S0 * exp(m2 + v2 * z), 7)
    print(f"try {lab}: exact {S0 * exp(MU * tt):.10f}; 7 nodes {gg:.10f} err {sci(gg - S0 * exp(MU * tt))}")
assert abs(psum - 1.0) < 1e-13, "probabilities must sum to 1"
assert abs(z12 - 10395.0) < 1e-8, "exact for the degree-12 moment"
assert abs(z14 - (135135.0 - 5040.0)) < 1e-7, "short by exactly 7! at degree 14"
assert abs(g7 - exact) < 1e-6, "7 nodes meet the closed form to a millionth of a dollar"
assert abs(simp - exact) < 1e-9, "Simpson meets the closed form"
assert all(0.8 < ratio[n] < 0.86 for n in range(2, 11)), "the first missed term explains most of the error"
assert abs(c_simp - c_exact) < 1e-8, "kinked payoff: Simpson from the kink meets the closed form"
assert 0.01 < abs(cerr[7]) < 0.1, "kinked payoff: 7 Gauss nodes are off by cents, not dollars"
assert abs(lag_err[7]) < 1e-3 and abs(lag_err[14]) < abs(lag_err[7]), "Laguerre closes in on Simpson"
assert abs(ch - pi * i0) < 1e-9, "Chebyshev against the I0 series"
print("ALL CHECKS PASS")
