# Trinomial trees and the grid connection -- the check behind the card.
# Standard library only, and nothing imported that already knows an answer:
# the bell-curve area is built by adding thin slices (Simpson's rule), and
# every price below is a loop written out here.  Acme: S = 100, K = 100,
# r = 5 percent, q = 2 percent, sigma = 20 percent, T = 1 year.
from math import log, sqrt, exp, pi

S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
LAM = sqrt(3.0)                              # the stretch: dx = LAM * sigma * sqrt(dt)

def bell(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)             # bell-curve height at x

def ncdf(x):                                 # area to the left of x, by Simpson's rule
    if x < 0.0:
        return 1.0 - ncdf(-x)
    n, total = 4000, bell(0.0) + bell(x)
    h = x / n
    for i in range(1, n):
        total += (4.0 if i % 2 else 2.0) * bell(i * h)
    return 0.5 + total * h / 3.0

def black_scholes_call():                    # road C: the closed form, for comparison only
    vt = SIG * sqrt(T)
    d1 = (log(S / K) + (R - Q + 0.5 * SIG * SIG) * T) / vt
    return S * exp(-Q * T) * ncdf(d1) - K * exp(-R * T) * ncdf(d1 - vt)

def weights(n, lam=LAM, tilt_on=True):       # three branch weights: mean and variance matched
    dt = T / n
    dx = lam * SIG * sqrt(dt)
    nu = R - Q - 0.5 * SIG * SIG
    spread = (SIG * SIG * dt + nu * nu * dt * dt) / (dx * dx)      # p_u + p_d
    tilt = nu * dt / dx if tilt_on else 0.0                        # p_u - p_d
    return dt, dx, nu, 0.5 * (spread + tilt), 1.0 - spread, 0.5 * (spread - tilt)

def tree_backward(n, lam=LAM, tilt_on=True, disc=None):            # road A
    dt, dx, _, pu, pm, pd = weights(n, lam, tilt_on)
    step = exp(-R * dt) if disc is None else disc
    v = [max(S * exp(dx * k) - K, 0.0) for k in range(-n, n + 1)]
    for _ in range(n):
        v = [step * (pd * v[j] + pm * v[j + 1] + pu * v[j + 2]) for j in range(len(v) - 2)]
    return v[0]

def tree_forward(n, lam=LAM):                # road B: the tree's own ending spread of prices
    dt, dx, _, pu, pm, pd = weights(n, lam)
    dist = [1.0]
    for _ in range(n):
        nxt = [0.0] * (len(dist) + 2)
        for j, w in enumerate(dist):
            nxt[j] += w * pd
            nxt[j + 1] += w * pm
            nxt[j + 2] += w * pu
        dist = nxt
    ends = [S * exp(dx * (j - n)) for j in range(len(dist))]
    price = exp(-R * T) * sum(w * max(e - K, 0.0) for w, e in zip(dist, ends))
    return price, dist, ends, sum(w * e for w, e in zip(dist, ends))

def grid_explicit(n, half=None):             # road D: coefficients read off the equation itself
    half = n if half is None else half
    dt = T / n
    dx = LAM * SIG * sqrt(dt)
    nu = R - Q - 0.5 * SIG * SIG
    a_u = dt * (0.5 * SIG * SIG / (dx * dx) + nu / (2.0 * dx))
    a_m = 1.0 - dt * SIG * SIG / (dx * dx)
    a_d = dt * (0.5 * SIG * SIG / (dx * dx) - nu / (2.0 * dx))
    df = 1.0 / (1.0 + R * dt)                                      # not e^-r dt: the equation's own
    v = [max(S * exp(dx * k) - K, 0.0) for k in range(-half, half + 1)]
    for _ in range(n):
        nv = [0.0] * len(v)                                        # edges held at zero
        for j in range(1, len(v) - 1):
            nv[j] = df * (a_d * v[j - 1] + a_m * v[j] + a_u * v[j + 1])
        v = nv
    return v[half], a_u, a_m, a_d, df

def crr_binomial(n):                         # two branches, for the convergence picture
    dt = T / n
    u = exp(SIG * sqrt(dt))
    d = 1.0 / u
    p = (exp((R - Q) * dt) - d) / (u - d)
    disc = exp(-R * dt)
    v = [max(S * u ** j * d ** (n - j) - K, 0.0) for j in range(n + 1)]
    for step in range(n, 0, -1):
        v = [disc * (p * v[j + 1] + (1.0 - p) * v[j]) for j in range(step)]
    return v[0]

bs = black_scholes_call()
dt3, dx3, nu3, pu3, pm3, pd3 = weights(3)
back3 = tree_backward(3)
fwd3, dist3, ends3, mean3 = tree_forward(3)
back200, (fd200, a_u, a_m, a_d, df200) = tree_backward(200), grid_explicit(200)
dt200, dx200, nu200, pu200, pm200, pd200 = weights(200)

print(f"Acme call: S {S:.0f}, K {K:.0f}, r {R:.2f}, q {Q:.2f}, sigma {SIG:.2f}, T {T:.0f} year")
print(f"road C, Black-Scholes closed form              {bs:12.6f}")
print(f"three steps: lambda {LAM:.6f}  dt {dt3:.6f}  dx {dx3:.6f}  nu {nu3:.6f}  "
      f"u {exp(dx3):.6f}  d {exp(-dx3):.6f}")
print(f"three-step weights: p_u {pu3:.6f}  p_m {pm3:.6f}  p_d {pd3:.6f}  sum {pu3+pm3+pd3:.6f}")
print(f"three-step split: p_u + p_d {pu3+pd3:.6f}  p_u - p_d {pu3-pd3:.6f}")
print("ending nodes of the three-step tree: node, Acme price, weight, payoff")
for j, (w, e) in enumerate(zip(dist3, ends3)):
    print(f"   k {j-3:+d}   {e:10.6f}   {w:.6f}   {max(e-K,0.0):10.6f}")
print(f"road A, three-step tree, backward induction    {back3:12.6f}")
print(f"road B, three-step tree, ending sum            {fwd3:12.6f}")
print(f"three-step tree's own average ending price {mean3:11.6f}   exact S e^(r-q)T {S*exp((R-Q)*T):11.6f}")
print(f"road A, 200-step tree, backward induction      {back200:12.6f}")
print(f"road D, 200-step explicit grid                 {fd200:12.6f}")
print(f"road A, 2000-step tree                         {tree_backward(2000):12.6f}")
print(f"road D, 2000-step explicit grid                {grid_explicit(2000)[0]:12.6f}")
print(f"200 steps, tree weights: p_u {pu200:.9f}  p_m {pm200:.9f}  p_d {pd200:.9f}")
print(f"200 steps, grid weights: a_u {a_u:.9f}  a_m {a_m:.9f}  a_d {a_d:.9f}")
print(f"  p_u - a_u {pu200-a_u:.9f}   predicted (nu dt)^2 / (2 dx^2) "
      f"{0.5*nu200*nu200*dt200*dt200/(dx200*dx200):.9f}")
print(f"  one step: e^-r dt {exp(-R*dt200):.9f}   1 / (1 + r dt) {df200:.9f}")
print()
print("convergence, cents away from 9.227006: the trinomial marches, the binomial flips")
print(f"{'steps':>6}{'trinomial':>12}{'cents':>9}{'binomial':>12}{'cents':>9}")
tri_cents, bin_cents = [], []
for n in range(20, 32):
    tri, bino = tree_backward(n), crr_binomial(n)
    tri_cents.append((tri - bs) * 100.0)
    bin_cents.append((bino - bs) * 100.0)
    print(f"{n:>6}{tri:>12.6f}{tri_cents[-1]:>9.2f}{bino:>12.6f}{bin_cents[-1]:>9.2f}")
print()
print("what breaks if a piece is dropped")
pm_l1, pm_l08, lam_min = weights(3, lam=1.0)[4], weights(3, lam=0.8)[4], sqrt(1.0 + nu3 * nu3 * dt3 / (SIG * SIG))
print(f"  the middle weight vanishes at lambda {lam_min:.6f}, not at 1.000000")
print(f"  lambda 1.00, three steps: p_m {pm_l1:.6f}, price {tree_backward(3, lam=1.0):12.6f}")
print(f"  lambda 0.80, three steps: p_m {pm_l08:.6f}, price {tree_backward(3, lam=0.8):12.6f}")
for n in (5, 10, 15, 20):
    print(f"  lambda 0.80, {n:>2} steps:     price {tree_backward(n, lam=0.8):18.6f}")
print(f"  drift tilt dropped, 200 steps:    price {tree_backward(200, tilt_on=False):12.6f}")
print(f"  discount forgotten, 200 steps:    price {tree_backward(200, disc=1.0):12.6f}")
print(f"  grid chopped to 20 nodes either side, 200 steps: price {grid_explicit(200, 20)[0]:12.6f}")
assert abs(back3 - fwd3) < 1e-12, "backward induction must match the tree's own ending sum"
assert abs(back200 - bs) < 0.01, "200-step tree lands within a cent of the closed form"
assert abs(fd200 - back200) < 0.00001, "the explicit grid is the tree"
assert abs((pu200 - a_u) - 0.5 * nu200 * nu200 * dt200 * dt200 / (dx200 * dx200)) < 1e-15, "the gap is (nu dt)^2 / (2 dx^2)"
assert abs(weights(3, lam=lam_min)[4]) < 1e-15 and pm_l1 < 0.0 < pm3, "the middle weight vanishes at lam_min, is negative at stretch 1, positive at sqrt(3)"
assert max(tri_cents) < 0.0 < max(bin_cents), "the trinomial stays one side, the binomial crosses"
print("ALL CHECKS PASS")
