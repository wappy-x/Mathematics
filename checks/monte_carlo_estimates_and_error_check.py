# Monte Carlo estimates and error -- the check behind the card.  Standard library only.
# Pi from 10,000 darts thrown at a unit square, with its standard error.
# Road 1: exact values: pi from Machin's arctangent series, sigma from p = pi / 4.
# Road 2: a deterministic grid, every cell centre of the square counted.
# Road 3: seeded simulation from a SplitMix64 generator written out below.
from math import sqrt, exp
SEED, N, R = 1946, 10000, 200                   # darts per run, repeated runs
CHECK = (100, 400, 1600, 6400, 10000, 25600)    # dart counts watched inside each repeated run
MASK, state = (1 << 64) - 1, SEED

def u():                                        # one uniform number in [0, 1), from SplitMix64
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def atan_series(x):                             # x - x^3/3 + x^5/5 - ...
    term, total, k = x, 0.0, 0
    while abs(term) > 1e-18:
        total += term / (2 * k + 1)
        term *= -x * x
        k += 1
    return total

def Phi(z):                                     # standard normal area left of z, by series
    term, total = z, z
    for k in range(1, 300):
        term *= -z * z / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2 * 3.141592653589793)

def quantile(q):                                # Phi^(-1)(q) by bisection
    lo, hi = 0.0, 8.0
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if Phi(mid) < q else (lo, mid)
    return (lo + hi) / 2

PI = 16 * atan_series(1 / 5) - 4 * atan_series(1 / 239)
p, z = PI / 4, quantile(0.975)
sigma = 4 * sqrt(p * (1 - p))                   # spread of one dart's score, 4 or 0
print(f"road 1, exact: pi {PI:.6f}, p = pi/4 {p:.6f}, sigma = 4 sqrt(p(1-p)) {sigma:.6f}")
print(f"  z for 95% {z:.6f}; true standard error at {N} darts {sigma / sqrt(N):.6f}")

for m in (100, 1000):
    inside = sum(1 for i in range(m) for j in range(m)
                 if (2 * i + 1) ** 2 + (2 * j + 1) ** 2 <= 4 * m * m)
    grid = 4 * inside / m / m
    print(f"road 2, grid of {m}x{m} cell centres: {inside} inside, 4 x fraction {grid:.6f}")

darts, K = [], 0
for i in range(N):
    x, y = u(), u()
    K += x * x + y * y <= 1.0
    if i < 20:
        darts.append((x, y))
p_hat, pi_hat = K / N, 4 * K / N
s = sqrt(16 * p_hat * (1 - p_hat) * N / (N - 1)); se = s / sqrt(N)
print(f"road 3, {N} darts, seed {SEED}: {K} inside, fraction {p_hat:.4f}, estimate {pi_hat:.4f}")
print(f"  sample spread s {s:.6f}, standard error s/root n {se:.6f}")
print(f"  95% interval {pi_hat - z * se:.4f} to {pi_hat + z * se:.4f}; miss from pi {pi_hat - PI:.4f}"
      f" = {(pi_hat - PI) / se:.2f} standard errors")
for a in (0, 10):
    print(f"figure, darts {a + 1}-{a + 10} (x, y, 1 = inside): " + " ".join(
        f"({40 + 200 * x:.0f},{220 - 200 * y:.0f},{int(x * x + y * y <= 1.0)})" for x, y in darts[a:a + 10]))
h20 = sum(1 for x, y in darts if x * x + y * y <= 1.0)
print(f"figure, first 20 darts: {h20} inside, estimate 4 x {h20}/20 = {4 * h20 / 20:.2f}")

g1 = g2 = 0.0
for _ in range(N):
    g = 4 * sqrt(1 - u() ** 2)                  # height of the curve at a random x
    g1, g2 = g1 + g, g2 + g * g
semi, s_semi = g1 / N, sqrt((g2 - g1 * g1 / N) / (N - 1))
sig_semi = sqrt(32 / 3 - PI * PI)          # spread of one height: E[16(1 - x^2)] = 32/3
print(f"curve heights 4 sqrt(1 - x^2), {N} draws: estimate {semi:.4f}, s {s_semi:.6f} (exact {sig_semi:.6f}),"
      f" standard error {s_semi / sqrt(N):.6f}")

est, cover, cover_n = {c: [] for c in CHECK}, 0, 0
for _ in range(R):
    k = 0
    for i in range(1, CHECK[-1] + 1):
        x, y = u(), u()
        k += x * x + y * y <= 1.0
        if i in est:
            est[i].append(4 * k / i)
            if i == N:
                q = k / N
                sr = sqrt(16 * q * (1 - q) * N / (N - 1))
                cover += abs(4 * q - PI) <= z * sr / sqrt(N)
                cover_n += abs(4 * q - PI) <= z * sr / N
print(f"{R} repeated runs: n, true standard error sigma/root n, observed root-mean-square miss")
rms = {c: sqrt(sum((e - PI) * (e - PI) for e in est[c]) / R) for c in CHECK}
for c in CHECK:
    print(f"  {c:>5}  {sigma / sqrt(c):.4f}  {rms[c]:.4f}")
mean10 = sum(est[N]) / R
spread10 = sqrt(sum((e - mean10) * (e - mean10) for e in est[N]) / (R - 1))
print(f"  at {N}: mean of estimates {mean10:.4f}, their spread {spread10:.6f}")
print(f"  95% intervals covering pi: {cover} of {R} = {cover / R:.3f}")
clt_n = (z * sigma / 0.01) * (z * sigma / 0.01)
print(f"darts for +/- 0.01 at 95%: CLT (z sigma / 0.01)^2 = {clt_n:.0f};"
      f" Chebyshev sigma^2 / (0.05 x 0.01^2) = {sigma * sigma / (0.05 * 0.0001):.0f}")

print(f"what breaks, the right answer is {pi_hat:.4f} +/- {se:.4f}")
kb = 0
for _ in range(N):
    w = u()
    kb += w * w + w * w <= 1.0                  # one random number used for both coordinates
qb = kb / N
print(f"  same number for x and y: {4 * qb:.4f} +/- {4 * sqrt(qb * (1 - qb) / N):.4f};"
      f" exact 4/root 2 = {4 / sqrt(2):.4f}")
print(f"  error bar s/n, not s/root n: +/- {s / N:.6f}; covers pi in {cover_n} of {R} runs")
print(f"  forgetting the 4: {p_hat:.4f}")
heavy = 0
for _ in range(R):
    h1 = h2 = 0.0
    for _ in range(N):
        h = 0.2 * (1 - u()) ** -0.8             # integral over [0, 1] is 1, variance infinite
        h1, h2 = h1 + h, h2 + h * h
    hs = sqrt((h2 - h1 * h1 / N) / (N - 1))
    heavy += abs(h1 / N - 1) <= z * hs / sqrt(N)
print(f"  infinite variance, 0.2 x^-0.8 on [0, 1]: 95% intervals cover 1 in {heavy} of {R} runs")
print(f"try: 40000 darts, standard error {sigma / sqrt(40000):.4f}; 1000000 darts {sigma / sqrt(1000000):.4f};"
      f" curve heights at 10000 {sig_semi / sqrt(N):.4f}")
assert abs(grid - PI) < 1e-3, "grid count vs Machin's series"
assert abs(sum((1 if k in (0, 1000) else 4 if k % 2 else 2) * exp(-(k * z / 1000) ** 2 / 2) for k in range(1001))
           * z / 3000 / sqrt(2 * PI) - 0.475) < 1e-9, "z: bell area 0 to z by Simpson's rule is 0.475"
assert abs(mean10 - PI) < 4 * sigma / sqrt(N * R), "estimates average to pi: no bias"
assert abs(pi_hat - PI) < 4 * se, "simulation vs exact pi"
assert abs(s - sigma) < 4 * 2 * (2 * p - 1) / sqrt(N), "sample spread vs 4 sqrt(p(1-p)): s has se 2(2p-1)/root n"
assert abs(spread10 - sigma / sqrt(N)) < 4 * sigma / sqrt(N) / sqrt(2 * R), "spread of runs vs sigma/root n"
for c in CHECK:
    assert abs(rms[c] / (sigma / sqrt(c)) - 1) < 4 / sqrt(2 * R), "miss shrinks as 1/root n"
assert abs(cover / R - 0.95) < 4 * sqrt(0.95 * 0.05 / R), "coverage vs 95%"
assert abs(semi - PI) < 4 * s_semi / sqrt(N), "curve heights vs exact pi"
assert abs(s_semi - sig_semi) < 0.02, "curve heights' spread vs sqrt(32/3 - pi^2)"
assert abs(4 * qb - 4 / sqrt(2)) < 4 * 4 * sqrt(qb * (1 - qb) / N), "shared number lands on 4/root 2"
assert heavy / R < 0.95 - 4 * sqrt(0.95 * 0.05 / R), "infinite variance breaks the interval"
print("ALL CHECKS PASS")
