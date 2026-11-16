# When prices jump -- the check behind the card.  Standard library only.
# Acme at $100, a one-year call struck at $100; jumps arrive 0.5 times a year
# and multiply the price by Y, log Y normal with mean -0.10 and spread 0.15.
# Roads to the price: (1) Merton's series of Black-Scholes prices, (2) the
# PIDE on a grid in log price at three steps, (3) the PIDE's residual at the
# series by centred differences and Simpson's rule.  Nothing imported knows
# the answer: the normal area, the integrals and the solver are written out.
from math import exp, log, sqrt, pi

S0, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
LAM, MUJ, DEL = 0.5, -0.10, 0.15
X0 = log(S0)

def kj(muj=MUJ): return exp(muj + 0.5 * DEL * DEL) - 1.0      # average jump k

def ncdf(x):                                     # normal area, Marsaglia's series
    if abs(x) > 9.0: return 0.0 if x < 0.0 else 1.0
    s, b, i = x, x, 1.0
    while s + b * x * x / (i + 2.0) != s:
        i += 2.0; b *= x * x / i; s += b
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)

def bs(S, s, q, sig):                            # Black-Scholes call, s years to go
    v = sig * sqrt(s); d1 = (log(S / K) + (R - q + 0.5 * sig * sig) * s) / v
    return S * exp(-q * s) * ncdf(d1) - K * exp(-R * s) * ncdf(d1 - v)

def merton(S, s, terms=40, lam=LAM, muj=MUJ, comp=True):    # sum of w_n C_BS
    k = kj(muj); tot, w = 0.0, exp(-lam * s)
    for n in range(terms):
        if n: w *= lam * s / n
        qn = Q + (lam * k if comp else 0.0) - n * log(1.0 + k) / s
        tot += w * bs(S, s, qn, sqrt(SIG**2 + n * DEL**2 / s))
    return tot

def add(vals):                                   # plain left-to-right sum, as in the Rust
    t = 0.0
    for v in vals: t += v
    return t

def g(z): return exp(-0.5 * ((z - MUJ) / DEL) ** 2) / (DEL * sqrt(2.0 * pi))

def simpson(f, m=400):                           # integral of g(z) f(z) over mean +- 8 spreads
    a, h = MUJ - 8.0 * DEL, 16.0 * DEL / m
    return h / 3.0 * add((1 if i in (0, m) else 4 if i % 2 else 2) * g(a + i * h) * f(a + i * h)
                         for i in range(m + 1))

def far(x, s):                                   # the call far from the strike
    return max(exp(x - Q * s) - K * exp(-R * s), 0.0) if x > X0 else 0.0

def grid(h, nst, L=1.2, W=7, zero=False):    # Crank-Nicolson, Rannacher start
    M = round(L / h); n = 2 * M + 1; xs = [X0 + (i - M) * h for i in range(n)]
    a, b, c = 0.5 * SIG**2, R - Q - LAM * kj() - 0.5 * SIG**2, -(R + LAM)
    lo, up, mid = a / h**2 - b / (2 * h), a / h**2 + b / (2 * h), c - 2 * a / h**2
    j0, j1 = int((MUJ - W * DEL) / h) - 1, int((MUJ + W * DEL) / h) + 2
    ws = [(j, h * g(j * h)) for j in range(j0, j1)]          # trapezoid weights in z = j h
    def jump(V, s):                              # lambda * sum over j of w_j V(x_i + j h)
        out = lambda y: 0.0 if zero else far(y, s)              # values beyond the grid
        return [LAM * add(w * (V[i + j] if 0 <= i + j < n else out(xs[i] + j * h))
                          for j, w in ws) for i in range(n)]
    V, s = [max(exp(x) - K, 0.0) for x in xs], 0.0
    for th, dt in [(1.0, T / nst / 2)] * 4 + [(0.5, T / nst)] * (nst - 2):
        Jn, s1 = jump(V, s), s + dt
        rhs = [V[i] + (1 - th) * dt * (lo * V[i - 1] + mid * V[i] + up * V[i + 1] + Jn[i])
               if 0 < i < n - 1 else 0.0 for i in range(n)]
        rhs[0], rhs[-1] = far(xs[0], s1), far(xs[-1], s1)
        guess = V
        for _ in range(20):                      # fixed-point passes on the jump term
            Jg = jump(guess, s1)
            d = [rhs[i] + th * dt * Jg[i] if 0 < i < n - 1 else rhs[i] for i in range(n)]
            A, B, Cc = -th * dt * lo, 1 - th * dt * mid, -th * dt * up
            cp, dp = [0.0] * n, [0.0] * n; dp[0] = d[0]           # Thomas algorithm
            for i in range(1, n - 1):
                m = B - A * cp[i - 1]; cp[i] = Cc / m; dp[i] = (d[i] - A * dp[i - 1]) / m
            new = [0.0] * n; new[0], new[-1] = d[0], d[-1]
            for i in range(n - 2, 0, -1): new[i] = dp[i] - cp[i] * new[i + 1]
            done = max(abs(p - q) for p, q in zip(new, guess)) < 1e-10
            guess = new
            if done: break
        V, s = guess, s1
    return V[M], len(ws)

k = kj()
print(f"average jump k = {k:.6f}; compensator lambda k = {LAM * k:.6f}; drift r - q - lambda k = {R - Q - LAM * k:.6f} a year")
print(f"E[Y] by Simpson = {simpson(exp):.6f}; 1 + k = {1 + k:.6f}")
bands = [0, 70, 80, 90, 100, 110, 120, 1e9]
cdf = [0.0] + [ncdf((log(v / S0) - MUJ) / DEL) for v in bands[1:-1]] + [1.0]
names = ["under 70", "70-80", "80-90", "90-100", "100-110", "110-120", "over 120"]
print("where one jump from $100 lands (%): " + ", ".join(
    f"{names[i]} {100 * (cdf[i + 1] - cdf[i]):.2f}" for i in range(7)))
print(f"middle 99% of landings: ${S0 * exp(MUJ - 2.5758 * DEL):.2f} to ${S0 * exp(MUJ + 2.5758 * DEL):.2f}")
ser = [merton(S0, T, terms=N) for N in (1, 2, 6)]
C = merton(S0, T)
p6 = add(exp(-LAM) * LAM**n / [1, 1, 2, 6, 24, 120][n] for n in range(6))  # P(N <= 5)
bound = S0 * exp(-(Q + LAM * k) * T) * (1 - p6)
print("series after 1, 2, 6 terms: " + ", ".join(f"{v:.6f}" for v in ser)
      + f"; tail {C - ser[2]:.6f}, bound {bound:.6f}")
print(f"road 1, Merton series: {C:.6f}")
assert 0.0 < C - ser[2] <= bound
assert abs(simpson(exp) - (1 + k)) < 1e-9
EV = simpson(lambda z: merton(exp(X0 + z), T))
print(f"jump average E[V(100 Y)] = {EV:.6f}; V at $80, ${S0 * exp(MUJ):.2f}, $100 = "
      f"{merton(80.0, T):.6f}, {merton(S0 * exp(MUJ), T):.6f}, {C:.6f}")
print(f"net jump term lambda (E[V] - V) = {LAM * (EV - C):.4f} a year")
res = []
for e in (0.02, 0.01):
    Vp, Vm = merton(exp(X0 + e), T), merton(exp(X0 - e), T)
    Vs = (merton(S0, T + e) - merton(S0, T - e)) / (2 * e)
    terms = [0.5 * SIG**2 * (Vp - 2 * C + Vm) / e**2, (R - Q - LAM * k - 0.5 * SIG**2) * (Vp - Vm) / (2 * e),
             -R * C, -LAM * C, LAM * EV]
    res.append(Vs - add(terms))
    print(f"step {e}: V_x {(Vp - Vm) / (2 * e):.4f}, V_xx {(Vp - 2 * C + Vm) / e**2:.4f}, V_s {Vs:.4f}; diffusion {terms[0]:.4f}, drift {terms[1]:.4f}, "
          f"-rV {terms[2]:.4f}, -lambda V {terms[3]:.4f}, lambda E[V] {terms[4]:.4f}; sum {add(terms):.4f}; residual {res[-1]:.7f}")
assert abs(res[1]) < 1e-3 and 3.5 < res[0] / res[1] < 4.5
print(f"grid edges ${S0 * exp(-1.2):.2f} to ${S0 * exp(1.2):.2f}; nodes {round(2.4 / 0.04) + 1}, "
      f"{round(2.4 / 0.02) + 1}, {round(2.4 / 0.01) + 1}; derivative stencil 3 nodes")
runs = [grid(h, nst) for h, nst in ((0.04, 25), (0.02, 50), (0.01, 100))]
for (h, nst), (v, nw) in zip(((0.04, 25), (0.02, 50), (0.01, 100)), runs):
    print(f"road 2, grid h = {h}, {nst} steps, jump stencil {nw} nodes: {v:.6f}, error {v - C:.6f}")
e = [v - C for v, _ in runs]
rich = (4 * runs[2][0] - runs[1][0]) / 3
print(f"error ratios {e[0] / e[1]:.3f}, {e[1] / e[2]:.3f}; observed order {log(e[1] / e[2]) / log(2):.3f}")
print(f"Richardson from h = 0.02 and 0.01: {rich:.6f}, off by {rich - C:.6f}")
assert abs(e[2]) < 3e-3 and 3.5 < e[1] / e[2] < 4.5 and abs(rich - C) < 2e-5
print("what breaks:")
print(f"  no jumps at all (Black-Scholes at 20%): {bs(S0, T, Q, SIG):.6f}; jumps add {C - bs(S0, T, Q, SIG):.6f}")
print(f"  drop the integral, keep -lambda V: {exp(-LAM * T) * bs(S0, T, Q + LAM * k, SIG):.6f}")
print(f"  drop the compensator: {merton(S0, T, comp=False):.6f}")
se = sqrt(SIG**2 + LAM * (MUJ**2 + DEL**2)); qe = Q + LAM * k - LAM * MUJ - 0.5 * LAM * (MUJ**2 + DEL**2)
print(f"  local Taylor stand-in (vol {100 * se:.2f}%, yield {100 * qe:.4f}%): {bs(S0, T, qe, se):.6f}")
w2 = grid(0.02, 50, W=2)
print(f"  jump stencil cut to mean +- 2 spreads ({w2[1]} nodes), h = 0.02: {w2[0]:.6f}")
assert w2[0] < runs[1][0] - 0.1
print("try changing:")
print(f"  one jump a year: {merton(S0, T, lam=1.0):.6f}; gaps of +10% instead: {merton(S0, T, muj=0.10):.6f}")
v6 = grid(0.02, 50, L=0.6, zero=True)[0]
print(f"  grid h = 0.02 on ${S0 * exp(-0.6):.2f} to ${S0 * exp(0.6):.2f}, zero beyond: {v6:.6f}, error {v6 - C:.6f}")
assert abs(v6 - C) > 3 * abs(e[1])
print("ALL CHECKS PASS")
