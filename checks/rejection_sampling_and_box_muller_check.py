# Rejection sampling and Box-Muller -- the check behind the card.  Only math primitives
# are imported.  Every draw comes from SplitMix64, seed 20260929, written out so Python
# and Rust draw the same numbers.  Phi is Simpson's rule on the bell, never a sampler.
from math import sqrt, log, exp, cos, sin, pi, e
MASK, state = (1 << 64) - 1, 20260929

def uniform():                                 # SplitMix64, 53 bits, in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 1) / 2.0 ** 53

def simpson(f, a, b, n=20000):
    h, inner = (b - a) / n, 0.0
    for i in range(1, n):
        inner += (4 if i % 2 else 2) * f(a + i * h)
    return (f(a) + f(b) + inner) * h / 3

def bell(z): return exp(-z * z / 2) / sqrt(2 * pi)
def Phi(x): return 0.5 + simpson(bell, 0.0, x)
def half_normal(y): return 2 * bell(y)          # target f: the size of a normal
def lognormal_call(s, m=log(100.0) + 0.01):     # e^-r E[(e^X - 100)+], X ~ N(m, s^2)
    d = (m - log(100.0)) / s
    return exp(-0.05) * (exp(m + s * s / 2) * Phi(d + s) - 100.0 * Phi(d))

M = sqrt(2 * e / pi)                           # envelope: f(y) <= M e^-y for y >= 0
def rejection(ceiling):                        # returns a signed draw and the tries used
    tries = 0
    while True:
        tries += 1
        y = -log(uniform())                    # exponential proposal, by inverse transform
        if uniform() <= min(1.0, half_normal(y) / (ceiling * exp(-y))):
            return (y if uniform() < 0.5 else -y), tries

def box_muller(k=2.0, root=True):
    u1, u2 = uniform(), uniform()
    rad = sqrt(-k * log(u1)) if root else -k * log(u1)
    return rad * cos(2 * pi * u2), rad * sin(2 * pi * u2)

def polar():                                   # dart in the square, kept if inside the disc
    tries = 0
    while True:
        tries += 1
        x, y = 2 * uniform() - 1, 2 * uniform() - 1
        s = x * x + y * y
        if 0 < s <= 1:
            return x * sqrt(-2 * log(s) / s), y * sqrt(-2 * log(s) / s), tries
def summary(zs):
    n = len(zs)
    mean = sum(zs) / n
    var = sum((z - mean) * (z - mean) for z in zs) / n
    p = sum(1 for z in zs if z <= 1.0) / n
    return mean, var, p, sqrt(p * (1 - p) / n)
def show(label, zs):
    mean, var, p, se = summary(zs)
    print(f"{label}: mean {mean:.4f}, variance {var:.4f}, P(Z <= 1) {p:.4f} +/- {se:.4f}")
    return p, se

N, phi1 = 200000, Phi(1.0)
print(f"SplitMix64 seed 20260929; {N} normal draws per method; Phi(1) by Simpson {phi1:.6f}; "
      f"largest R from 53-bit uniforms {sqrt(-2 * log(2.0 ** -53)):.4f}")
accept_int = simpson(lambda y: exp(-y) * exp(-(y - 1) * (y - 1) / 2), 0.0, 12.0)
print(f"rejection: M = sqrt(2e/pi) = {M:.6f}; acceptance 1/M = {1 / M:.6f}, by integral {accept_int:.6f}")
draws = [rejection(M) for _ in range(N)]
rej, rej_tries = [z for z, _ in draws], sum(t for _, t in draws)
acc = N / rej_tries
acc_se = sqrt(acc * (1 - acc) / rej_tries)
print(f"rejection: {rej_tries} proposals, acceptance {acc:.4f} +/- {acc_se:.4f}, tries per draw {rej_tries / N:.4f}")
p_rej, se_rej = show("rejection draws", rej)
u1, u2, r_hand, y_hand = 0.3, 0.8, sqrt(-2 * log(0.3)), -log(0.3)
print(f"by hand, rejection: Y = -ln 0.3 = {y_hand:.6f}, keep chance exp(-(Y - 1)^2 / 2) = "
      f"{exp(-(y_hand - 1) * (y_hand - 1) / 2):.6f}, test U = 0.8: kept {'yes' if 0.8 <= exp(-(y_hand - 1) * (y_hand - 1) / 2) else 'no'}")
z1, z2 = r_hand * cos(2 * pi * u2), r_hand * sin(2 * pi * u2)
print(f"by hand: U1 = 0.3, U2 = 0.8 -> -2 ln U1 = {-2 * log(u1):.6f}, R = {r_hand:.6f}, angle = {2 * pi * u2:.6f}, "
      f"cos {cos(2 * pi * u2):.6f}, sin {sin(2 * pi * u2):.6f}")
print(f"by hand: Z1 = {z1:.6f}, Z2 = {z2:.6f}; stock in a year 100 exp(0.01 + 0.2 Z1) = {100 * exp(0.01 + 0.2 * z1):.2f}")
m, below, both = 1000, 0, 0
for i in range(m):
    rad = sqrt(-2 * log((i + 0.5) / m))
    for j in range(m):
        a, b = rad * cos(2 * pi * (j + 0.5) / m), rad * sin(2 * pi * (j + 0.5) / m)
        below += a <= 1.0
        both += a <= 1.0 and b <= 1.0
print(f"grid of {m * m} uniform pairs, no randomness: P(Z1 <= 1) {below / m / m:.6f}, "
      f"P(Z1 <= 1 and Z2 <= 1) {both / m / m:.6f}, Phi(1)^2 {phi1 * phi1:.6f}")
bm = [z for _ in range(N // 2) for z in box_muller()]
p_bm, se_bm = show("Box-Muller draws", bm)
pairs = list(zip(bm[0::2], bm[1::2]))
corr = sum(a * b for a, b in pairs) / len(pairs)
p_both = sum(1 for a, b in pairs if a <= 1.0 and b <= 1.0) / len(pairs)
print(f"Box-Muller pairs: average Z1 Z2 {corr:.4f}, P(Z1 <= 1 and Z2 <= 1) {p_both:.4f} +/- {sqrt(p_both * (1 - p_both) / len(pairs)):.4f}")
darts = [polar() for _ in range(N // 2)]
pol, pol_tries = [z for a, b, _ in darts for z in (a, b)], sum(t for _, _, t in darts)
pi_hat = 4 * (N // 2) / pol_tries
pi_se = 4 * sqrt((pi_hat / 4) * (1 - pi_hat / 4) / pol_tries)
print(f"polar: acceptance pi/4 = {pi / 4:.6f}; darts {pol_tries}, 4 x kept share {pi_hat:.4f} +/- {pi_se:.4f}")
p_pol, se_pol = show("polar draws", pol)
stock = [100 * exp(0.01 + 0.2 * z) for z in bm]
up = sum(1 for s in stock if s > 100) / N
pay = [exp(-0.05) * max(s - 100, 0.0) for s in stock]
call = sum(pay) / N
call_se = sqrt(sum((p - call) * (p - call) for p in pay) / N / N)
print(f"stock: P(price > 100) {up:.4f} +/- {sqrt(up * (1 - up) / N):.4f}; exact Phi(0.05) = {Phi(0.05):.6f}")
avg = sum(stock) / N
print(f"stock: average price {avg:.4f} +/- {sqrt(sum((s - avg) * (s - avg) for s in stock) / N / N):.4f}; exact 100 e^0.03 = {100 * exp(0.03):.4f}")
exact_call = lognormal_call(0.2)
print(f"stock: call by simulation {call:.4f} +/- {call_se:.4f}; by formula {exact_call:.6f}")
half = [box_muller(k=1.0)[0] for _ in range(N)]
wide = [box_muller(root=False)[0] for _ in range(N)]
clip = [rejection(1.0)[0] for _ in range(N)]
floor = lambda y: min(half_normal(y), exp(-y))           # clipped: the accepted weight
clip_tail = simpson(floor, 2.0, 12.0) / simpson(floor, 0.0, 12.0)
tail_sim = sum(1 for z in clip if abs(z) > 2) / N
print(f"break, -ln U1 without the 2: variance {summary(half)[1]:.4f} (exact 0.5); call {lognormal_call(0.2 / sqrt(2)):.4f}")
print(f"break, R = -2 ln U1 with no root: variance {summary(wide)[1]:.4f} (exact 4)")
print(f"break, envelope M = 1, clipped: P(|Z| > 2) {tail_sim:.4f} +/- {sqrt(tail_sim * (1 - tail_sim) / N):.4f}; "
      f"by integral {clip_tail:.4f}; true {2 * (1 - Phi(2.0)):.4f}; mean {summary(clip)[0]:.4f}, variance {summary(clip)[1]:.4f}")
ys = [0.25 * k for k in range(17)]
print("chart, y:", ", ".join(f"{y:.2f}" for y in ys))
print("chart, target f(y), percent:", ", ".join(f"{100 * half_normal(y):.2f}" for y in ys))
print("chart, envelope M g(y), percent:", ", ".join(f"{100 * M * exp(-y):.2f}" for y in ys))
edges = [-3 + 0.5 * k for k in range(13)]
print("chart, bin centres:", ", ".join(f"{a + 0.25:.2f}" for a in edges[:-1]))
print("chart, Box-Muller percent per unit:", ", ".join(
    f"{100 * sum(1 for z in bm if a < z <= a + 0.5) / N / 0.5:.2f}" for a in edges[:-1]))
print("chart, exact bell percent per unit:", ", ".join(f"{100 * (Phi(a + 0.5) - Phi(a)) / 0.5:.2f}" for a in edges[:-1]))
assert abs(accept_int - sqrt(pi / (2 * e))) < 1e-9          # integral against closed form
assert abs(acc - 1 / M) < 4 * acc_se                          # simulated acceptance
assert abs(below / m / m - phi1) < 1e-3 and abs(both / m / m - phi1 * phi1) < 1e-3
for p, se in ((p_rej, se_rej), (p_bm, se_bm), (p_pol, se_pol)):
    assert abs(p - phi1) < 4 * se                             # three samplers, one bell
assert abs(p_both - phi1 * phi1) < 4 * sqrt(p_both * (1 - p_both) / len(pairs))   # independent pair
assert abs(call - exact_call) < 4 * call_se and abs(exact_call - 9.227005508154) < 1e-6
assert abs(tail_sim - clip_tail) < 4 * sqrt(clip_tail * (1 - clip_tail) / N)
assert abs(summary(half)[1] - 0.5) < 0.01 and abs(summary(wide)[1] - 4) < 0.1
assert clip_tail - 2 * (1 - Phi(2.0)) > 0.005                # the clipped sampler is wrong
print("ALL CHECKS PASS")
