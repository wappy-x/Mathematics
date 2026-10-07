# Normal distribution -- the check behind the card.  Standard library only.
# A share's daily return is modelled as normal: centre MU = 0.05 percent,
# spread SIGMA = 1.2 percent.  The standard normal's cumulative area Phi is
# built twice, by a power series and by Simpson's rule, and the answers are
# met a third way by a seeded simulation.  Nothing imported holds the answer.
from math import exp, log, sqrt, pi

MU, SIGMA, DAYS = 0.05, 1.2, 252            # percent per day; trading days a year
LOSS = -2.0                                  # the loss threshold, percent

def phi(z):                                  # standard normal density
    return exp(-z * z / 2) / sqrt(2 * pi)

def f(x):                                    # the return's own density, per percent
    return phi((x - MU) / SIGMA) / SIGMA

def Phi_series(z):                           # road 1: Taylor series, integrated term by term
    term, total = z, z                       # term = (-1)^n z^(2n+1) / (2^n n!)
    for n in range(1, 200):
        term *= -z * z / (2 * n)
        total += term / (2 * n + 1)
    return 0.5 + total / sqrt(2 * pi)

def simpson(g, a, b, n=4000):                # road 2: Simpson's rule, n even
    h = (b - a) / n
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))
    return s * h / 3

def Phi_simpson(z):                          # area under phi from far left (-12) to z
    return simpson(phi, -12.0, z)

MASK = (1 << 64) - 1
state = 20260928                             # road 3: SplitMix64, seed 20260928

def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)

def uniform():                               # strictly between 0 and 1
    return ((splitmix() >> 11) + 0.5) / 2.0 ** 53

def normal_pair():                           # Marsaglia's polar method
    while True:
        u, v = 2 * uniform() - 1, 2 * uniform() - 1
        s = u * u + v * v
        if 0 < s < 1:
            k = sqrt(-2 * log(s) / s)
            return u * k, v * k

# the parameters mean what they say: area 1, centre MU, spread SIGMA
lo, hi = MU - 12 * SIGMA, MU + 12 * SIGMA
area = simpson(f, lo, hi)
mean = simpson(lambda x: x * f(x), lo, hi)
var = simpson(lambda x: (x - mean) ** 2 * f(x), lo, hi)
print(f"model: centre {MU:.2f}%, spread {SIGMA:.2f}%, variance {SIGMA ** 2:.2f} (percent squared)")
print(f"by Simpson on the return's density: area {area:.9f}, mean {mean:.6f}, sd {sqrt(var):.6f}")
print(f"peak height 1/sqrt(2 pi) = {phi(0):.6f}; divided by the spread = {f(MU):.6f} per percent")

# Phi by two roads
print("z, Phi by series, Phi by Simpson")
for z in (-2.0, -1.0, 0.0, 1.0, 1.7083, 2.0, 3.0):
    print(f"{z:7.4f}  {Phi_series(z):.6f}  {Phi_simpson(z):.6f}")
for k in (1, 2, 3):
    inside = 2 * Phi_series(k) - 1
    print(f"within {k} spread(s), {MU - k * SIGMA:.2f}% to {MU + k * SIGMA:.2f}%: {inside:.6f}; beyond: {1 - inside:.6f}")

# the card's example: a day beyond two spreads, and a loss worse than 2 percent
beyond2 = 2 * (1 - Phi_series(2.0))
print(f"beyond two spreads: {beyond2:.4f}, one day in {1 / beyond2:.1f}, {beyond2 * DAYS:.1f} days a year")
print(f"one tail only, above the mean + 2 spreads: {1 - Phi_series(2.0):.4f}")
z_loss = (LOSS - MU) / SIGMA
p_loss = Phi_series(z_loss)
p_loss_direct = simpson(f, lo, LOSS)         # no standardising: the return's own density
print(f"loss worse than 2%: z = ({LOSS:.2f} - {MU:.2f}) / {SIGMA:.2f} = {z_loss:.4f}")
print(f"  Phi(z) by series {p_loss:.4f}; area under f by Simpson {p_loss_direct:.4f}")
print(f"  one day in {1 / p_loss:.1f}, {p_loss * DAYS:.1f} days a year")
tail5 = 2 * simpson(phi, 5.0, 12.0)          # both tails beyond five spreads
print(f"beyond five spreads, as the model says: {tail5:.9f}, once in {1 / tail5 / DAYS:.0f} years")

# what breaks
print(f"mistake 1, mean not subtracted: Phi({LOSS / SIGMA:.4f}) = {Phi_series(LOSS / SIGMA):.4f}")
print(f"mistake 2, variance used as spread: Phi({(LOSS - MU) / SIGMA ** 2:.4f}) = "
      f"{Phi_series((LOSS - MU) / SIGMA ** 2):.4f}")
print(f"mistake 3, Phi(+z) read for the loss tail: {Phi_series(-z_loss):.4f}")

# road 3: simulate 200,000 days
N = 200_000
cnt = {1: 0, 2: 0, 3: 0}
lost = 0
for _ in range(N // 2):
    for z in normal_pair():
        for k in cnt:
            if abs(z) > k:
                cnt[k] += 1
        if MU + SIGMA * z < LOSS:
            lost += 1
print(f"simulated {N} days, seed 20260928; estimate (standard error)")
sim = {}
for k in cnt:
    p = cnt[k] / N
    sim[k] = (p, sqrt(p * (1 - p) / N))
    print(f"  beyond {k} spread(s): {p:.4f} ({sim[k][1]:.4f})")
p_sim, se_sim = lost / N, sqrt(lost / N * (1 - lost / N) / N)
print(f"  loss worse than 2%: {p_sim:.4f} ({se_sim:.4f})")

# figures: density and cumulative area at half-spread steps
zs = [k / 2 for k in range(-6, 7)]
print("figure, return %: " + ", ".join(f"{MU + z * SIGMA:.2f}" for z in zs))
print("figure, density: " + ", ".join(f"{f(MU + z * SIGMA):.2f}" for z in zs))
print("figure, cumulative: " + ", ".join(f"{Phi_series(z):.3f}" for z in zs))

assert abs(area - 1) < 1e-9 and abs(mean - MU) < 1e-9 and abs(var - SIGMA ** 2) < 1e-9
for z in (-3.0, -1.7083, 0.5, 2.0, 4.0):     # two roads to Phi agree
    assert abs(Phi_series(z) - Phi_simpson(z)) < 1e-10
assert abs(p_loss - p_loss_direct) < 1e-10   # standardising = integrating f itself
assert abs(tail5 - 2 * (1 - Phi_series(5.0))) < 1e-9
for k in cnt:                                # simulation within 4 standard errors
    assert abs(sim[k][0] - (2 - 2 * Phi_series(k))) < 4 * sim[k][1]
assert abs(p_sim - p_loss) < 4 * se_sim
print("ALL CHECKS PASS")
