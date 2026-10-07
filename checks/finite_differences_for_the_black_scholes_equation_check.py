# Pricing on a grid -- the check behind the card.  Standard library only.  Nothing
# imported that already holds an option price: the bell-curve area is built from
# math.erf, the tridiagonal solver is written out, and the grid is stepped by hand.
from math import log, sqrt, exp, erf
S0, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
XMAX = 1.0                      # grid edge in x = ln(S/K): five times sigma sqrt(T)
A = 0.5 * SIG * SIG             # spreading coefficient
B = R - Q - 0.5 * SIG * SIG     # sliding coefficient

def ncdf(z):  return 0.5 * (1.0 + erf(z / sqrt(2.0)))    # bell-curve area left of z

def formula(call):              # the closed form: an independent road to the price
    vt = SIG * sqrt(T)
    d1 = (log(S0 / K) + (R - Q + 0.5 * SIG * SIG) * T) / vt
    if call: return S0 * exp(-Q * T) * ncdf(d1) - K * exp(-R * T) * ncdf(d1 - vt)
    return K * exp(-R * T) * ncdf(vt - d1) - S0 * exp(-Q * T) * ncdf(-d1)

def thomas(sub, diag, sup, rhs):            # sweep down, then back up: O(n) work
    n = len(diag)
    c, d, out = [0.0] * n, list(rhs), [0.0] * n
    c[0], d[0] = sup[0] / diag[0], rhs[0] / diag[0]
    for i in range(1, n):
        m = diag[i] - sub[i] * c[i - 1]
        c[i], d[i] = sup[i] / m, (rhs[i] - sub[i] * d[i - 1]) / m
    out[n - 1] = d[n - 1]
    for i in range(n - 2, -1, -1): out[i] = d[i] - c[i] * out[i + 1]
    return out

def cell_average(h, call):      # the payoff averaged across the strike's own cell
    return K * (exp(h / 2) - 1 - h / 2) / h if call else K * (exp(-h / 2) - 1 + h / 2) / h

def edges(tau, call, xmax):     # the far edges: true far out, and moving with the clock
    if call: return 0.0, K * (exp(xmax) * exp(-Q * tau) - exp(-R * tau))
    return K * (exp(-R * tau) - exp(-xmax) * exp(-Q * tau)), 0.0

def run(theta, M, N, call=True, smooth=True, xmax=XMAX):
    """theta: 0 explicit, 1 implicit, 1/2 Crank-Nicolson.  Returns the last row, the
    strike node after every step, the largest size anywhere after every step, and the
    largest residual the solves left behind."""
    h, k = 2.0 * xmax / M, T / N
    V = [max(K * exp(-xmax + i * h) - K, 0.0) if call else max(K - K * exp(-xmax + i * h), 0.0)
         for i in range(M + 1)]
    if smooth: V[M // 2] = cell_average(h, call)
    nu, eta, rk = A * k / (h * h), B * k / (2.0 * h), R * k
    lo, mid, hi = nu - eta, 2.0 * nu + rk, nu + eta
    sub, diag = [-theta * lo] * (M - 1), [1.0 + theta * mid] * (M - 1)
    sup, centre, peak, resid = [-theta * hi] * (M - 1), [], [], 0.0
    for n in range(N):
        V[0], V[M] = edges(n * k, call, xmax)                   # the old row's own edges
        rhs = [V[i] + (1.0 - theta) * (lo * V[i - 1] - mid * V[i] + hi * V[i + 1])
               for i in range(1, M)]
        e0, eM = edges((n + 1) * k, call, xmax)                 # the new row's edges
        rhs[0] += theta * lo * e0
        rhs[M - 2] += theta * hi * eM
        inner = thomas(sub, diag, sup, rhs)
        for i in range(M - 1):                                  # put the answer back in
            back = diag[i] * inner[i] + (sub[i] * inner[i - 1] if i else 0.0)
            resid = max(resid, abs(back + (sup[i] * inner[i + 1] if i < M - 2 else 0.0) - rhs[i]))
        V = [e0] + inner + [eM]
        centre.append(V[M // 2])
        peak.append(max(abs(v) for v in V))
    return V, centre, peak, resid

def line(name, *vals):  print(f"{name:<45}" + "".join(f"{v:>11.6f}" for v in vals))

def row(name, vals, width=7, dp=2):  print(f"{name:<12}" + "".join(f"{v:>{width}.{dp}f}" for v in vals))

M0 = N0 = 200
h0, k0 = 2.0 * XMAX / M0, T / N0
nu0, eta0, rk0 = A * k0 / (h0 * h0), B * k0 / (2.0 * h0), R * k0
nu1, eta1, rk1 = A * (T / 500) / (h0 * h0), B * (T / 500) / (2.0 * h0), R * (T / 500)
print(f"Acme call, one year: S = {S0:.2f}, K = {K:.2f}, r = 5%, q = 2%, sigma = 20%")
print(f"grid: x = ln(S/K) from {-XMAX:.2f} to {XMAX:.2f}, so S from {K * exp(-XMAX):.2f} to {K * exp(XMAX):.2f}")
print(f"      M = {M0} cells of h = {h0:.6f} across, N = {N0} steps of k = {k0:.6f} up")
line("a = sigma^2/2", A)
line("b = r - q - sigma^2/2", B)
line("nu = a k / h^2", nu0)
line("eta = b k / (2 h)", eta0)
line("r k", rk0)
line("payoff averaged across the strike's cell", cell_average(h0, True))
line("explicit row   nu-eta, 1-2nu-rk, nu+eta", nu0 - eta0, 1.0 - 2.0 * nu0 - rk0, nu0 + eta0)
line("implicit row  -nu+eta, 1+2nu+rk, -nu-eta", eta0 - nu0, 1.0 + 2.0 * nu0 + rk0, -nu0 - eta0)
line("CN row        sides halved, middle 1+nu+rk/2", 0.5 * (eta0 - nu0), 1.0 + nu0 + 0.5 * rk0, -0.5 * (nu0 + eta0))
line("explicit row with 500 steps instead of 200", nu1 - eta1, 1.0 - 2.0 * nu1 - rk1, nu1 + eta1)
line("payoff one cell above the strike, K(e^h - 1)", K * (exp(h0) - 1.0))
line("that row's first step at the strike node", (1.0 - 2.0 * nu1 - rk1) * cell_average(h0, True)
     + (nu1 + eta1) * K * (exp(h0) - 1.0))
cn, centre, _, resid = run(0.5, M0, N0)
im, pt = run(1.0, M0, N0)[0], run(0.5, M0, N0, call=False)[0]
ex, rough = run(0.0, M0, 500)[0], run(0.5, M0, N0, smooth=False)[0]
narrow, wide = run(0.5, M0, N0, xmax=0.2)[0], run(0.5, M0, N0, xmax=3.0)[0]
C, P = formula(True), formula(False)
print()
line("1 Crank-Nicolson, 200 x 200", cn[M0 // 2])
line("2 Black-Scholes formula", C)
line("  grid minus formula", cn[M0 // 2] - C)
line("3 implicit, 200 x 200", im[M0 // 2])
line("4 explicit, 200 x 500", ex[M0 // 2])
line("5 put, Crank-Nicolson, 200 x 200", pt[M0 // 2])
line("  call minus put, both off the grid", cn[M0 // 2] - pt[M0 // 2])
line("  S e^-qT - K e^-rT", S0 * exp(-Q * T) - K * exp(-R * T))
line("  put by formula", P)
print(f"6 largest residual left by the 200 solves     {resid:.2e}")
print()
print("refinement, Crank-Nicolson, same domain:")
print("   M x N       h         k        call      error")
errs = []
for M in (50, 100, 200, 400):
    last = run(0.5, M, M)[0]
    errs.append(last[M // 2] - C)
    print(f"  {M:4d} x {M:4d}  {2.0 * XMAX / M:.6f}  {T / M:.6f}  {last[M // 2]:.6f}  {errs[-1]:+.6f}")
print("what breaks:")
line("  kink left unaveraged in the strike cell", rough[M0 // 2])
line("  domain x in [-0.2, 0.2], same 200 cells", narrow[M0 // 2])
line("  domain x in [-3, 3], same 200 cells", wide[M0 // 2])
uns, upeak = run(0.0, M0, N0)[1:3]
print()
print("explicit on the 200 x 200 grid, nu = 1: price at the strike node after step")
row("  1 to 8", uns[:8], 8)
print(f"  largest size anywhere after steps 10, 20 and 50: {upeak[9]:.3e} {upeak[19]:.3e} {upeak[49]:.3e}")
print(f"  the 'price' after all 200 steps: {uns[-1]:.2e}")
spots = [K * exp(-0.5 + 0.1 * j) for j in range(11)]
print("today's price across the last row, Crank-Nicolson:")
row("  S", spots)
row("  grid", [cn[50 + 10 * j] for j in range(11)])
row("  payoff", [max(s - K, 0.0) for s in spots])
print("the strike node with 3, 6, 9 and 12 months to go, Crank-Nicolson:")
row("  dollars", [centre[49], centre[99], centre[149], centre[199]], 10)
row("  six d.p.", [centre[49], centre[99], centre[149], centre[199]], 10, 6)
assert abs(cn[M0 // 2] - C) < 2.0e-4, "grid price against the closed form"
assert abs(ex[M0 // 2] - C) < 5.0e-3, "explicit road against the closed form"
assert abs(im[M0 // 2] - C) < 8.0e-3, "implicit road against the closed form"
assert max(abs(cn[i] - pt[i] - K * (exp(-XMAX + i * h0 - Q * T) - exp(-R * T)))
           for i in range(1, M0)) < 1.0e-4, "parity must hold at every node, not just the middle"
assert resid < 1.0e-10, "each Thomas solution must satisfy its own equations"
assert errs[1] / errs[2] > 3.0 and errs[2] / errs[3] > 3.0, "halving h must cut the error by about four"
assert upeak[49] > 1.0e6, "the explicit scheme must blow up when nu = 1"
assert abs(rough[M0 // 2] - C) > 20.0 * abs(cn[M0 // 2] - C), "averaging the strike cell must earn its place"
print("ALL CHECKS PASS")
