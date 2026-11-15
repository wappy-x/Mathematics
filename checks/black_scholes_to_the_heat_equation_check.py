# Black-Scholes is the heat equation after a change of variables -- the check
# behind the card.  Nothing is imported but math.exp, math.log, math.sqrt and math.pi.
# A 3-month call on a 100 share is turned into a rod: log price, time to
# expiry in heat units, and one exponential factor.  The price is then found
# three ways: the Black-Scholes formula, the heat kernel by quadrature, and
# an explicit grid on the plain heat equation.
from math import exp, log, sqrt, pi

S, K, T, r, q, sig = 100.0, 100.0, 0.25, 0.05, 0.02, 0.20
KAPPA, HALF_M = 1.11e-4, 0.5          # copper diffusivity m^2/s; metres per log unit
LQ = 1.5                               # quadrature reach either side of x, in log units

def fe(v, d=2):                        # e-notation with the same digits in Python and Rust
    if v == 0.0:
        return "0." + "0" * d + "e0"
    e = 0
    m = abs(v)
    while m >= 10.0: m, e = m / 10.0, e + 1
    while m < 1.0: m, e = m * 10.0, e - 1
    return ("-" if v < 0 else "") + f"{m:.{d}f}e{e}"

def ncdf(z):                           # normal CDF by its all-positive series
    term, total, n = z, z, 0
    while abs(term) > 1e-17 * abs(total):
        n += 1
        term *= z * z / (2 * n + 1)
        total += term
    return 0.5 + exp(-z * z / 2) / sqrt(2 * pi) * total

kq, kr = 2 * (r - q) / sig**2, 2 * r / sig**2     # drift and discount, in heat units
al = -(kq - 1) / 2                     # the exponential factor's slope in x
be = -(kq - 1)**2 / 4 - kr             # and its rate in tau
tau = sig**2 * T / 2                   # time to expiry on the heat clock
x0 = log(S / K)
c1, c2 = (kq + 1) / 2, (kq - 1) / 2    # the start: u0 = e^(c1 x) - e^(c2 x) for x > 0

def u0(x):                             # the payoff in strikes, with the factor divided out
    return exp(-al * x) * max(exp(x) - 1, 0.0)

def heat_exp(c, x, t):                 # e^(cy) for y > 0, run through the heat kernel
    return exp(c * x + c * c * t) * ncdf((x + 2 * c * t) / sqrt(2 * t))

def u_exact(x, t):
    return heat_exp(c1, x, t) - heat_exp(c2, x, t)

def bs_call(s_, t):                    # road 1: the Black-Scholes formula
    d1 = (log(s_ / K) + (r - q + sig**2 / 2) * t) / (sig * sqrt(t))
    d2 = d1 - sig * sqrt(t)
    return s_ * exp(-q * t) * ncdf(d1) - K * exp(-r * t) * ncdf(d2), d1, d2

def kernel_conv(x, t, L=LQ, n=3000):    # road 2: Simpson's rule on u0 times the kernel
    a, b = max(x - L, 0.0), x + L
    h = (b - a) / n
    f = lambda y: u0(y) * exp(-(x - y)**2 / (4 * t)) / sqrt(4 * pi * t)
    s_ = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s_ * h / 3

def grid(h, nu=0.4, xl=-1.0, xr=1.0):  # road 3: explicit steps of u_tau = u_xx
    m = round((xr - xl) / h)
    dt = nu * h * h
    steps = round(tau / dt)
    u = [u0(xl + i * h) for i in range(m + 1)]
    for k in range(1, steps + 1):
        new = [0.0] * (m + 1)
        for i in range(1, m):
            new[i] = u[i] + nu * (u[i + 1] - 2 * u[i] + u[i - 1])
        t = k * dt                     # far right: both exponentials run exactly
        new[m] = exp(c1 * xr + c1 * c1 * t) - exp(c2 * xr + c2 * c2 * t)
        u = new
    return u[round((x0 - xl) / h)], steps

V1, d1, d2 = bs_call(S, T)
uq = kernel_conv(x0, tau)
V2 = K * exp(al * x0 + be * tau) * uq
xa = 0.1                               # a second price, off the strike: S = K e^0.1
Va1, Va2 = bs_call(K * exp(xa), T)[0], K * exp(al * xa + be * tau) * kernel_conv(xa, tau)
uh = u_exact(x0, tau)
g1, n1 = grid(0.01)
g2, n2 = grid(0.005)
e1, e2 = abs(g1 - uh), abs(g2 - uh)
zt = (LQ - 2 * c1 * tau) / sqrt(2 * tau)
tail = exp(c1 * c1 * tau) * exp(-zt * zt / 2) / (sqrt(2 * pi) * zt)
t_rod = tau * HALF_M**2 / KAPPA

print(f"call: S {S:.2f}, K {K:.2f}, T {T:.2f} yr, r {r:.2f}, q {q:.2f}, sigma {sig:.2f}")
print(f"heat-unit rates: drift k' = {kq:.4f}, discount k = {kr:.4f}")
print(f"factor e^(alpha x + beta tau): alpha = {al:.4f}, beta = {be:.4f}")
print(f"heat clock tau = sigma^2 T / 2 = {tau:.4f}; x = ln(S/K) = {x0:.4f}")
print(f"start: u0(x) = e^({c1:.2f} x) - e^({c2:.2f} x) for x > 0, else 0")
print(f"d1 = {d1:.6f}, d2 = {d2:.6f}, N(d1) = {ncdf(d1):.6f}, N(d2) = {ncdf(d2):.6f}")
print(f"heat terms: e^(c1^2 tau) = {exp(c1*c1*tau):.6f}, e^(c2^2 tau) = {exp(c2*c2*tau):.6f}")
print(f"u(0, tau), closed form       = {uh:.6f}")
print(f"u(0, tau), kernel quadrature = {uq:.6f}  (tail past {LQ} below {fe(tail)})")
print(f"discount e^(beta tau)        = {exp(be*tau):.6f}")
print(f"road 1, Black-Scholes formula: {V1:.6f}")
print(f"road 2, heat kernel, times K e^(beta tau): {V2:.6f}")
print(f"roads 1 and 2 off the strike, S {K * exp(xa):.2f} (x = {xa:.1f}): {Va1:.6f} and {Va2:.6f}  (tail below {fe(exp(c1 * xa) * tail)})")
print(f"road 3, grid h 0.010, {n1} steps: {K*exp(be*tau)*g1:.6f}  error in u {fe(e1)}")
print(f"road 3, grid h 0.005, {n2} steps: {K*exp(be*tau)*g2:.6f}  error in u {fe(e2)}")
print(f"grid observed order: {log(e1 / e2) / log(2):.2f}")
for dx in (0.002, 0.001):                # the residual u_tau - u_xx, by centred differences
    dt = dx * dx / 4
    res = ((u_exact(0.05, tau + dt) - u_exact(0.05, tau - dt)) / (2 * dt)
           - (u_exact(0.05 + dx, tau) - 2 * u_exact(0.05, tau) + u_exact(0.05 - dx, tau)) / dx**2)
    print(f"residual u_tau - u_xx at x 0.05, step {dx:.3f}: {fe(res)}")
print(f"rod: 1 m holds x from -1 to 1; copper kappa {fe(KAPPA)} m^2/s")
print(f"rod time for tau: {t_rod:.2f} s; spread sqrt(2 tau) = {sqrt(2*tau):.4f} log units"
      f" = {100*HALF_M*sqrt(2*tau):.2f} cm")
for x in (-0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3):
    print(f"chart, x {x:+.1f}, S {K*exp(x):.2f}: start {u0(x):.4f}, at tau {u_exact(x, tau):.4f}")
w1 = K * exp(be * T) * u_exact(x0, T)             # mistake: years on the heat clock
w2 = K * uh                                           # mistake: drop e^(beta tau)
w3 = K * exp(be * tau) * (heat_exp(1 + al, x0, tau) - heat_exp(al, x0, tau))  # alpha flipped
amp = 1e-6 * exp(100**2 * tau)
print(f"mistake 1, years on the heat clock (tau = 0.25): {w1:.6f}")
print(f"mistake 2, drop the factor e^(beta tau): {w2:.6f}")
print(f"mistake 3, alpha's sign flipped in the start: {w3:.6f}")
print(f"mistake 4, calendar time kept: a 1e-6 ripple at mode 100 grows to {fe(amp)}")
assert abs(V1 - V2) < 1e-9                       # formula against kernel quadrature
assert e2 < 1e-4 and 3.5 < e1 / e2 < 4.5         # grid converges at second order
assert abs(uq - uh) < 1e-10                      # quadrature against completed square
assert abs(Va1 - Va2) < 1e-9                     # and off the strike, where e^(alpha x) is not 1
assert abs(res) < 1e-4                           # the closed form solves the heat equation
assert abs(w2 - V1) > 0.05 and abs(w1 - V1) > 1  # the mistakes really move the price
print("ALL CHECKS PASS")
