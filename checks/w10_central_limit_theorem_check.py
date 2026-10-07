# The central limit theorem, proved -- the check behind the card.
# Standard library only.  One fair die, faces 1 to 6.  S is the total of
# 100 independent rolls: mean 350, standard deviation 17.08.  Roads: exact
# convolution in whole numbers, inclusion-exclusion, the normal CDF from its
# own series, Lindeberg's swap with a smooth step, the characteristic function.
from fractions import Fraction as Q
from math import comb, cos, exp, pi, sqrt

N, CUT, DELTA, C_SHEV = 100, 330, 0.5, 0.4748
MU, VAR, P61 = Q(7, 2), Q(35, 12), 2 ** 61 - 1
SIG = sqrt(VAR)

def Phi(z):                              # 1/2 + phi(z) * sum z^(2k+1) / (1*3*...*(2k+1))
    if abs(z) > 8:                       # beyond 8 the tail is below 1e-15
        return 0.0 if z < 0 else 1.0
    term = total = z
    k = 0
    while abs(term) > 1e-17 * abs(total):
        k += 1
        term *= z * z / (2 * k + 1)
        total += term
    return 0.5 + exp(-z * z / 2) / sqrt(2 * pi) * total

def simpson(f, a, b, m):                 # Simpson's rule on m (even) slices
    h = (b - a) / m
    return h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(a + i * h) for i in range(m + 1))

# ---- one roll, exactly ----
rho = sum(abs(k - MU) ** 3 for k in range(1, 7)) / 6
m4 = sum((k - MU) ** 4 for k in range(1, 7)) / 6
ratio, kurt = float(rho) / SIG ** 3, float(m4 / VAR ** 2)
print(f"one roll: mean {MU}, variance {VAR}, E|X - 3.5|^3 = {rho}, E(X - 3.5)^4 = {m4}")
print(f"sigma = {SIG:.4f}; rho/sigma^3 = {ratio:.4f}; E[Y^4] = {kurt:.4f}")

# ---- road 1: the law of S by convolution, every k from 1 to 100 kept ----
counts, probs = [1], [[1.0]]             # counts[s] = roll sequences with total s
for k in range(1, N + 1):
    new = [0] * (len(counts) + 6)
    for s, c in enumerate(counts):
        for f in range(1, 7):
            new[s + f] += c
    counts = new
    probs.append([c / 6 ** k for c in counts])
two = sum(1 for a in range(1, 7) for b in range(1, 7) if a + b <= 7)
print(f"two rolls: {two} of 36 totals <= 7, P(Z_2 <= 0) = {Q(two, 36)} against Phi(0) = {Phi(0.0)}")
sd = sqrt(N * VAR)
print(f"total of {N} rolls: mean {N * MU}, variance {N * VAR}, standard deviation {sd:.4f}")
below = sum(counts[:CUT + 1])
incl_excl = sum((-1) ** j * comb(N, j) * comb(CUT - 6 * j, N) for j in range((CUT - N) // 6 + 1))
assert below == incl_excl                                   # road 2: inclusion-exclusion
print(f"roll sequences with total <= {CUT}, mod 2^61 - 1: {below % P61} by convolution, "
      f"{incl_excl % P61} by inclusion-exclusion")
exact = below / 6 ** N
z, zc = (CUT - 350) / sd, (CUT + 0.5 - 350) / sd
print(f"P(S <= {CUT}) exact = {exact:.6f}")
print(f"normal: z = {z:.4f}, Phi(z) = {Phi(z):.6f}; half-step z = {zc:.4f}, Phi = {Phi(zc):.6f}")
print(f"gaps: exact - Phi(z) = {exact - Phi(z):.6f}; exact - half-step = {exact - Phi(zc):.6f}")
be = C_SHEV * ratio / sqrt(N)
print(f"Berry-Esseen: {C_SHEV} x {ratio:.4f} / sqrt({N}) = {be:.4f}")
assert abs(exact - Phi(z)) <= be

# ---- figure 1: mass of S against the normal density, times 1000 ----
xs = list(range(300, 401, 10))
print("figure, s: " + ", ".join(map(str, xs)))
print("figure, P(S = s) x 1000: " + ", ".join(f"{1000 * probs[N][s]:.2f}" for s in xs))
print("figure, normal density x 1000: " + ", ".join(
    f"{1000 * exp(-((s - 350) / sd) ** 2 / 2) / (sd * sqrt(2 * pi)):.2f}" for s in xs))

# ---- the largest CDF gap over every threshold, against Berry-Esseen ----
gap_fig, bound_fig = [], []
for n in (1, 2, 5, 10, 20, 50, 100):
    F, worst, s_n = 0.0, 0.0, sqrt(n * VAR)
    for s in range(n, 6 * n + 1):
        ph = Phi((s - 3.5 * n) / s_n)
        worst = max(worst, abs(F - ph))
        F += probs[n][s]
        worst = max(worst, abs(F - ph))
    bound = min(1.0, C_SHEV * ratio / sqrt(n))
    print(f"n = {n}: largest gap {worst:.4f}, Berry-Esseen bound {bound:.4f}, sqrt(n) x gap {sqrt(n) * worst:.4f}")
    assert worst <= bound
    gap_fig.append(f"{1000 * worst:.2f}")
    bound_fig.append(f"{1000 * bound:.2f}")
print("figure, largest gap x 1000: " + ", ".join(gap_fig))
print("figure, Berry-Esseen bound x 1000: " + ", ".join(bound_fig))

# ---- Lindeberg's swap: replace rolls by normals one at a time ----
g3 = 2 * sqrt(2 / pi)
g3_num = simpson(lambda g: abs(g) ** 3 * exp(-g * g / 2) / sqrt(2 * pi), -12, 12, 2400)
print(f"E|G|^3 = 2 sqrt(2/pi) = {g3:.6f}; by Simpson {g3_num:.6f}")
assert abs(g3 - g3_num) < 1e-8
def hybrid(k):                           # E h(W_k): k standardized rolls, N - k normals
    b = sqrt(DELTA ** 2 + (N - k) / N)
    return sum(p * Phi((z - (s - 3.5 * k) / sd) / b) for s, p in enumerate(probs[k]) if p > 0)
H = [hybrid(k) for k in range(N + 1)]
eh_simpson = simpson(lambda g: Phi((z - g) / DELTA) * exp(-g * g / 2) / sqrt(2 * pi), -12, 12, 2400)
print(f"smooth step h(u) = Phi((a - u)/{DELTA}), a = {z:.4f}: E h(Z_100) = {H[N]:.6f}, "
      f"E h(G) = {H[0]:.6f}, by Simpson {eh_simpson:.6f}")
assert abs(H[0] - eh_simpson) < 1e-7
h3 = 1 / sqrt(2 * pi) / DELTA ** 3      # sup |h'''|: phi''(x) = (x^2 - 1) phi(x) peaks at x = 0
per_swap = h3 * (ratio + g3) / (6 * N ** 1.5)
steps = [abs(H[k] - H[k - 1]) for k in range(1, N + 1)]
print(f"swap bound per roll {per_swap:.6f}, over {N} rolls {N * per_swap:.4f}; "
      f"largest actual swap {max(steps):.2e}, all {N} together {abs(H[N] - H[0]):.2e}")
assert max(steps) <= per_swap                               # every swap within Step 3's bound

# ---- road 3: the characteristic function of Z_n against exp(-t^2/2) ----
def chf(t, n):                           # [average of cos((k - 3.5) s / sigma)]^n, s = t / sqrt(n)
    return (sum(cos((k - 3.5) * t / (SIG * sqrt(n))) for k in range(1, 7)) / 6) ** n
for t in (1.0, 2.0):
    row = [chf(t, n) for n in (1, 10, 100, 1000)]
    print(f"t = {t:.0f}: phi_Zn at n = 1, 10, 100, 1000: {', '.join(f'{v:.6f}' for v in row)}; "
          f"limit {exp(-t * t / 2):.6f}")
    for n, v in zip((10, 100, 1000), row[1:]):
        assert abs(v - exp(-t * t / 2)) <= (kurt / 24 + 1 / 8) * t ** 4 / n
print(f"bound at t = 1, n = 100: (E[Y^4]/24 + 1/8)/100 = {(kurt / 24 + 1 / 8) / 100:.6f}")

# ---- what breaks ----
cau = [exp(-1 / sqrt(n)) ** n for n in (1, 4, 100)]  # Cauchy phi(s) = exp(-|s|), s = 1/sqrt(n)
print(f"Cauchy steps, phi at t = 1 after dividing by sqrt(n): n = 1, 4, 100: "
      f"{cau[0]:.4f}, {cau[1]:.4f}, {cau[2]:.6f}")
low = sum(N * k <= CUT for k in range(1, 7))             # faces k with 100 k <= 330
print(f"one roll copied {N} times: P(S <= {CUT}) = {low}/6 = {low / 6}")
print(f"standard deviation taken as {N} x sigma = {N * SIG:.2f}: Phi = {Phi((CUT - 350) / (N * SIG)):.4f}")
p = 1 / 10000
print(f"rare event p = 1/10000, {N} trials: P(count <= np) = P(count = 0) = {(1 - p) ** N:.4f}")
print("ALL CHECKS PASS")
