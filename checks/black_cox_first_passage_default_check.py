# Black-Cox first-passage default -- the check behind the card.  Standard library
# only, and nothing imported knows the answer: the bell-curve area is a power
# series written out below, the integrals are Simpson's rule, and the random
# numbers come from a 64-bit xorshift generator defined here.
from math import log, exp, sqrt, cos, pi

V0, D, T, r, sigma = 100.0, 80.0, 1.0, 0.05, 0.20    # $m of assets, $m of debt, years, rates
nu = r - 0.5 * sigma * sigma                         # pricing-world drift of log assets

def N(x):                                            # bell-curve area left of x, by series
    if abs(x) > 7.0: return 0.0 if x < 0 else 1.0
    term, total, k = x, x, 0                         # integral of exp(-t^2/2) from 0 to x
    while abs(term) > 1e-18:
        k += 1
        term *= -x * x / (2.0 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2.0 * pi)

def simpson(f, lo, hi, n):
    h = (hi - lo) / n
    s = f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * h) for i in range(1, n))
    return s * h / 3.0

def black_cox(H, nu=nu, sigma=sigma, T=T):          # road 1: the reflection formula
    b, s = log(H / V0), sigma * sqrt(T)
    finish = N((b - nu * T) / s)                     # below H at the end
    mirror = exp(2 * nu * b / sigma ** 2) * N((b + nu * T) / s)   # touched, ended above
    return finish, mirror, finish + mirror

def by_density(H, nu=nu, sigma=sigma, T=T):          # road 2: add up the first-touch times
    b = log(H / V0)
    f = lambda t: 0.0 if t == 0 else -b / (sigma * sqrt(2 * pi * t ** 3)) * exp(-(b - nu * t) ** 2 / (2 * sigma ** 2 * t))
    return simpson(f, 0.0, T, 4000)

def mirror_by_bridge(H):                             # the mirror term as an integral of bridge chances
    b, s = log(H / V0), sigma * sqrt(T)
    g = lambda y: exp(-(y - nu * T) ** 2 / (2 * s * s)) / (s * sqrt(2 * pi))
    return simpson(lambda y: g(y) * exp(2 * b * (y - b) / (s * s)), b, b + 12 * s, 6000)

def whole_contract(H):                               # touch H at any time, or end below D
    b, d, s = log(H / V0), log(D / V0), sigma * sqrt(T)
    return N((d - nu * T) / s) + exp(2 * nu * b / sigma ** 2) * N((2 * b - d + nu * T) / s)

state = 0x2026092843050001                           # xorshift64*, same stream in the Rust twin
def uniform():
    global state
    state ^= state >> 12; state ^= (state << 25) & 0xFFFFFFFFFFFFFFFF; state ^= state >> 27
    return (((state * 0x2545F4914F6CDD1D) & 0xFFFFFFFFFFFFFFFF) >> 11) / 2.0 ** 53 + 2.0 ** -54

PATHS, STEPS, BARS = 40000, 12, (80.0, 70.0, 60.0)   # road 3: simulate monthly, bridge in between
dt, lb, ld = T / STEPS, [log(h / V0) for h in BARS], log(D / V0)
bridge, grid, qtr, end, whole, month_hit = [0] * 3, [0] * 3, 0, 0, [0] * 3, [0] * STEPS
for _ in range(PATHS):
    x, hit, seen, first = 0.0, [False] * 3, [False] * 3, STEPS
    q = False
    for k in range(STEPS):
        z = sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())
        y, u = x + nu * dt + sigma * sqrt(dt) * z, uniform()
        for j in range(3):
            if y <= lb[j]: hit[j] = seen[j] = True
            elif not hit[j] and u < exp(-2.0 * (x - lb[j]) * (y - lb[j]) / (sigma * sigma * dt)): hit[j] = True
        q = q or (k % 3 == 2 and y <= lb[0])
        if hit[0] and first == STEPS: first = k
        x = y
    for j in range(3):
        bridge[j] += hit[j]; grid[j] += seen[j]; whole[j] += hit[j] or x <= ld
    qtr += q; end += x <= lb[0]
    if first < STEPS: month_hit[first] += 1
mc = lambda c: c / PATHS
se = lambda p: sqrt(p * (1 - p) / PATHS)

merton = N((log(D / V0) - nu * T) / (sigma * sqrt(T)))
print(f"inputs: V0 {V0:.0f}, D {D:.0f}, T {T:.0f}, r {r:.2f}, sigma {sigma:.2f}, nu {nu:.6f}, weight exponent {2 * nu / sigma ** 2:.6f}")
print(f"Merton, below 80 at year end        {merton:.6f}")
print("barrier   finish    mirror    Black-Cox  by density  bridge MC  monthly MC  whole contract  its MC")
rows = []
for j, H in enumerate(BARS):
    fin, mir, bc = black_cox(H); dens = by_density(H); rows.append((fin, mir, bc, dens))
    print(f"{H:7.0f}  {fin:.6f}  {mir:.6f}  {bc:.6f}   {dens:.6f}    {mc(bridge[j]):.4f}     {mc(grid[j]):.4f}      {whole_contract(H):.6f}    {mc(whole[j]):.4f}")
wt = exp(2 * nu * lb[0] / sigma ** 2)
print(f"H 80: b = ln(H/V0) {lb[0]:.6f}, alpha {(lb[0] - nu * T) / sigma:.6f}, beta {(lb[0] + nu * T) / sigma:.6f}")
print(f"weight (H/V0)^(2nu/sigma^2), H 80   {wt:.6f}")
print(f"N((b + nu T)/sigma sqrt T), H 80    {N((lb[0] + nu * T) / sigma):.6f}")
print(f"mirror term by bridge integral, 80  {mirror_by_bridge(80.0):.6f}")
print(f"MC {PATHS} paths, {STEPS} monthly steps; standard error at 0.2224  {se(rows[0][2]):.4f}")
shift = 80.0 * exp(-0.5826 * sigma * sqrt(dt))       # monthly covenant: shifted-barrier rule
print("monitoring at H 80, %: year end formula, year end MC, quarterly MC, monthly MC, monthly by shifted barrier, continuous formula, bridge MC")
print(f"  {100 * merton:.2f}  {100 * mc(end):.2f}  {100 * mc(qtr):.2f}  {100 * mc(grid[0]):.2f}  {100 * black_cox(shift)[2]:.2f}  {100 * rows[0][2]:.2f}  {100 * mc(bridge[0]):.2f}")
print(f"  shifted barrier 80 exp(-0.5826 sigma sqrt(1/12))  {shift:.4f}")
print(f"wrong: drop the mirror term         {rows[0][0]:.6f}")
print(f"wrong: mirror without the weight    {rows[0][0] + N((lb[0] + nu * T) / sigma):.6f}")
print(f"wrong: weight with flipped sign     {rows[0][0] + N((lb[0] + nu * T) / sigma) / wt:.6f}")
print("chart, barrier $m      " + " ".join(f"{h:6.0f}" for h in range(60, 100, 5)))
print("chart, Black-Cox %     " + " ".join(f"{100 * black_cox(float(h))[2]:6.2f}" for h in range(60, 100, 5)))
print("chart, year-end at H % " + " ".join(f"{100 * black_cox(float(h))[0]:6.2f}" for h in range(60, 100, 5)))
print("chart, month           " + " ".join(f"{m:5d}" for m in range(1, 13)))
print("chart, touched by m %  " + " ".join(f"{100 * black_cox(80.0, T=m / 12)[2]:5.2f}" for m in range(1, 13)))
cum = [sum(month_hit[:m]) / PATHS for m in range(1, 13)]
print("chart, MC touched by m " + " ".join(f"{100 * c:5.2f}" for c in cum))
print("chart, below 80 at m % " + " ".join(f"{100 * black_cox(80.0, T=m / 12)[0]:5.2f}" for m in range(1, 13)))
z0 = black_cox(80.0, nu=0.0)
print(f"try: r 0.02 so nu 0: first-touch density {by_density(80.0, nu=0.0):.6f}, twice finish-below {2 * z0[0]:.6f}")
print(f"try: sigma 0.30: Black-Cox {black_cox(80.0, nu=0.005, sigma=0.30)[2]:.6f}, year end {black_cox(80.0, nu=0.005, sigma=0.30)[0]:.6f}")
print(f"try: T 5 years: Black-Cox {black_cox(80.0, T=5.0)[2]:.6f}, year-5 end {black_cox(80.0, T=5.0)[0]:.6f}")
print(f"try: real-world drift 8%: Black-Cox {black_cox(80.0, nu=0.06)[2]:.6f}, year end {black_cox(80.0, nu=0.06)[0]:.6f}")

assert abs(merton - 0.1028) < 5e-5, "the shelf's Merton default chance, 10.28%"
for fin, mir, bc, dens in rows:
    assert abs(bc - dens) < 1e-8, "reflection formula vs adding up first-touch times"
for j in range(3):
    assert abs(mc(bridge[j]) - rows[j][2]) < 4 * se(rows[j][2]) + 1e-3, "bridge-corrected simulation vs formula"
assert abs(mirror_by_bridge(80.0) - rows[0][1]) < 1e-8, "mirror term vs integral of bridge chances"
assert abs(mc(end) - merton) < 4 * se(merton), "simulated year-end check vs Merton"
assert mc(end) < mc(qtr) < mc(grid[0]) < mc(bridge[0]), "more watching finds more defaults"
assert abs(2 * z0[0] - by_density(80.0, nu=0.0)) < 1e-8, "no drift: twice the finish-below chance, by first-touch times"
print("ALL CHECKS PASS")
