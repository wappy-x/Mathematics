# Continuous martingales and local martingales -- the check behind the card.
# Only math is imported. B is a 3-dimensional Brownian motion started at
# distance R0 = 1 from the origin, and X_t = 1/|B_t| is one over its distance.
# Roads to E[X_1]: the closed form 2 Phi(1) - 1; a Simpson integral of the
# Gaussian average over space; exact draws of B_1; whole simulated paths.
import math

R0, T, CAP = 1.0, 1.0, 10      # start distance, horizon, cap on X (stop when |B| <= 1/CAP)

def phi(x): return math.exp(-x * x / 2) / math.sqrt(2 * math.pi)   # the bell curve's height

def Phi(x):                    # its area to the left: 1/2 + phi(x) * (x + x^3/3 + x^5/15 + ...)
    term, total, k = x, x, 0
    while abs(term) > 1e-17:
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + phi(x) * total

def simpson(f, a, b, n):       # Simpson's rule, n even
    h = (b - a) / n
    acc = 0.0
    for i in range(1, n):
        acc += (4 if i % 2 else 2) * f(a + i * h)
    return (f(a) + f(b) + acc) * h / 3

def mean_closed(r0, t): return (2 * Phi(r0 / math.sqrt(t)) - 1) / r0   # E[1/|B_t|]

def mean_space(r0, t):         # the Gaussian average of 1/|y| over space, in shells:
    c = 2 * math.pi / (2 * math.pi * t) ** 1.5    # rho = |y|, u = cosine of y's angle to the start
    def inner(rho):
        g = lambda u: rho * math.exp(-(rho * rho - 2 * rho * r0 * u + r0 * r0) / (2 * t))
        return simpson(g, -1.0, 1.0, 200)
    return c * simpson(inner, 0.0, r0 + 12 * math.sqrt(t), 600)

def shell(rho, r0):            # average of 1/|y| over the sphere of radius rho around the start
    return simpson(lambda u: 0.5 / math.sqrt(rho * rho + r0 * r0 - 2 * rho * r0 * u), -1.0, 1.0, 2000)

def capped(n, r0, t):          # stop at the first time |B| = 1/n, i.e. X reaches n
    chance = (1 / n) / r0 * 2 * (1 - Phi((r0 - 1 / n) / math.sqrt(t)))
    return chance, n * chance, (2 * Phi((r0 - 1 / n) / math.sqrt(t)) - 1) / r0

state = 20261123               # SplitMix64 and Box-Muller, written out
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53
def normals():
    u, v = 1 - uniform(), uniform()
    r = math.sqrt(-2 * math.log(u))
    return r * math.cos(2 * math.pi * v), r * math.sin(2 * math.pi * v)
def stats(xs):                 # mean and its standard error, summed in order
    m, v = 0.0, 0.0
    for x in xs: m += x
    m /= len(xs)
    for x in xs: v += (x - m) ** 2
    return m, math.sqrt(v / (len(xs) - 1) / len(xs))

# ---- the example: one over the distance, started 1 unit out ----
exact = mean_closed(R0, T)
quad = mean_space(R0, T)
print(f"Phi(1) = {Phi(1.0):.6f}, phi(1) = {phi(1.0):.6f}")
print(f"E[X_1], road 1, closed form 2 Phi(1) - 1 = {exact:.6f}")
print(f"E[X_1], road 2, Simpson over space = {quad:.6f}")
assert abs(quad - exact) < 1e-6
print(f"mean lost by time 1 = {1 / R0 - exact:.6f}")
inside = 2 * Phi(1.0) - 1 - 2 * phi(1.0)
print(f"Newton split: P(moved <= 1) = {inside:.6f}, E[1/moved; moved > 1] = {2 * phi(1.0):.6f}")
print(f"shell averages: radius 0.3 -> {shell(0.3, R0):.6f}, radius 3 -> {shell(3.0, R0):.6f}")
assert abs(shell(0.3, R0) - 1 / R0) < 1e-6     # inside the shell: 1 / (start distance)
assert abs(shell(3.0, R0) - 1 / 3.0) < 1e-6    # outside: 1 / (shell radius)
print(f"E[X_4] = {mean_closed(R0, 4.0):.6f} (Simpson {mean_space(R0, 4.0):.6f})")
assert abs(mean_space(R0, 4.0) - mean_closed(R0, 4.0)) < 1e-6

# ---- road 3: exact draws of B_T = start + sqrt(T) times three standard normals ----
xs = []
for i in range(100000):
    a, b = normals()
    c, _ = normals()
    q = math.sqrt(T)
    xs.append(1 / math.sqrt((R0 + q * a) ** 2 + (q * b) ** 2 + (q * c) ** 2))
m, se = stats(xs)
print(f"E[X_1], road 3, 100000 exact draws = {m:.6f} +- {se:.6f}")
assert abs(m - exact) < 4 * se

# ---- localisation: caps at X = n, read at time 1 ----
for n in [2, 5, CAP, 100, 1000]:
    ch, mass, rest = capped(n, R0, T)
    print(f"cap {n}: P(reach cap by 1) = {ch:.6f}, mean on capped paths = {mass:.6f}, mean on the rest = {rest:.6f}")
print(f"cap {CAP}: frozen reading's average = {capped(CAP, R0, T)[1] + capped(CAP, R0, T)[2]:.6f}")
assert abs(capped(10 ** 6, R0, T)[2] - exact) < 1e-5

# ---- road 4: 4000 whole paths, 200 steps; frozen at the cap X = 4, and not ----
paths, steps, ncap = 4000, 200, 4
free, frozen = [], []
for p in range(paths):
    x, y, z, stop = R0, 0.0, 0.0, None
    for k in range(steps):
        a, b = normals()
        c, _ = normals()
        s = math.sqrt(T / steps)
        x, y, z = x + s * a, y + s * b, z + s * c
        if stop is None and math.sqrt(x * x + y * y + z * z) <= 1 / ncap:
            stop = 1 / math.sqrt(x * x + y * y + z * z)
    free.append(1 / math.sqrt(x * x + y * y + z * z))
    frozen.append(stop if stop is not None else free[-1])
mf, sf = stats(free)
mz, sz = stats(frozen)
print(f"paths: unfrozen mean at 1 = {mf:.6f} +- {sf:.6f}")
print(f"paths: frozen at cap {ncap}, mean = {mz:.6f} +- {sz:.6f}")
assert abs(mf - exact) < 4 * sf
assert abs(mz - 1 / R0) < 4 * sz + 0.02        # the grid freezes a little late

# ---- the chance of reaching the cap, by another road: the radial heat equation on a grid ----
a, dr, ds = 1 / CAP, 0.025, 0.00025            # u[i] = P(reach radius a by now | start at a + i dr)
u = [1.0] + [0.0] * 320
for _ in range(round(T / ds)):
    u = [1.0] + [u[i] + ds * ((u[i + 1] - 2 * u[i] + u[i - 1]) / (2 * dr * dr) + (u[i + 1] - u[i - 1]) / (2 * dr) / (a + i * dr)) for i in range(1, 320)] + [0.0]
print(f"cap {CAP}: P(reach cap by 1) on a heat-equation grid = {u[round((R0 - a) / dr)]:.6f}")
assert abs(u[round((R0 - a) / dr)] - capped(CAP, R0, T)[0]) < 1e-4

# ---- the house example M_t = (W_t^2 - t)/2, a true martingale ----
msq = simpson(lambda w: ((w * w - 1) / 2) ** 2 * phi(w), -12.0, 12.0, 4000)
clock = simpson(lambda s: s, 0.0, 1.0, 2)
print(f"house: E[M_1^2] by Simpson = {msq:.6f}; isometry, E[clock at 1] = {clock:.6f}")
assert abs(msq - clock) < 1e-6
series = 0.0
for k in range(200000): series += (-1) ** k / (2 * k + 1) ** 3
series *= 32 / math.pi ** 3
print(f"house: exit time of (-1, 1), E[tau] by series = {series:.6f}; optional stopping gives 1")
assert abs(series - 1.0) < 1e-6

# ---- what breaks ----
print(f"break: martingale assumed, E[X_1] = {1 / R0:.6f}; true {exact:.6f}")
print(f"break: lost mean read as a chance = {1 / R0 - exact:.6f}; P(reach cap {CAP} by 1) = {capped(CAP, R0, T)[0]:.6f}")
print(f"break: t for sqrt t at time 4 = {(2 * Phi(R0 / 4) - 1) / R0:.6f}; true {mean_closed(R0, 4.0):.6f}")
print("ALL CHECKS PASS")
