# Lebesgue decomposition -- the check behind the card.  Standard library only:
# exact fractions for the die, and a hand-written exponential, Cantor function
# and Simpson rule for the line.  Waits in minutes, probabilities as decimals.
from fractions import Fraction as Fr
from itertools import product

def exp_pos(x):                               # e^x for x >= 0, summed term by term
    total, term, k = 1.0, 1.0, 0
    while term > 1e-17 * total:
        k += 1
        term *= x / k
        total += term
    return total

def e_neg(x): return 1.0 / exp_pos(x)         # e^(-x)

def cantor(p, q, digits=40):                  # Cantor function at p/q in [0, 1], base-3 digits
    if p >= q: return 1.0
    value, half = 0.0, 0.5
    for _ in range(digits):
        p *= 3
        d, p = p // q, p % q
        if d == 1: return value + half        # inside a removed middle third: flat
        value += half if d == 2 else 0.0
        half /= 2
    return value

def simpson(g, a, b, m=6000):                 # Simpson's rule, m even
    h = (b - a) / m
    s = g(a) + g(b) + sum((4 if i % 2 else 2) * g(a + i * h) for i in range(1, m))
    return s * h / 3

# ---- Road 0: the proof's construction on a die, every set listed ----
sets = [[i for i in range(6) if m >> i & 1] for m in range(64)]
def decompose(mu, nu):                        # largest mu-null set in nu's eyes, then split
    null_sets = [A for A in sets if sum(mu[i] for i in A) == 0]
    N = max(null_sets, key=lambda A: sum(nu[i] for i in A))
    nu_s = [nu[i] if i in N else Fr(0) for i in range(6)]
    nu_ac = [nu[i] - nu_s[i] for i in range(6)]
    return null_sets, N, nu_s, nu_ac, [nu_ac[i] / mu[i] if mu[i] else Fr(0) for i in range(6)]
mu = [Fr(1, 4)] * 4 + [Fr(0)] * 2             # reference die: faces 5 and 6 never come up
nu = [Fr(1, 10)] * 4 + [Fr(2, 10), Fr(4, 10)] # the loaded die
null_sets, N, nu_s, nu_ac, f = decompose(mu, nu)
fmt = lambda v: ", ".join(str(float(x)) for x in v)
print(f"die: mu = ({fmt(mu)}); nu = ({fmt(nu)})")
print(f"die: {len(null_sets)} of 64 sets are mu-null; the one nu weighs most is faces "
      f"{[i + 1 for i in N]}, nu mass {float(sum(nu[i] for i in N))}")
print(f"die: nu_s = ({fmt(nu_s)}); nu_ac = ({fmt(nu_ac)}); density f = ({fmt(f)})")
for A in sets:                                # nu(A) = integral of f over A against mu + nu_s(A)
    assert sum(nu[i] for i in A) == sum(f[i] * mu[i] for i in A) + sum(nu_s[i] for i in A)
grid = [[Fr(k, 10) for k in range(int(10 * v) + 1)] for v in nu]
splits = [a for a in product(*grid)
          if all(a[i] == 0 for i in range(6) if mu[i] == 0)                  # a << mu
          and all(nu[i] - a[i] == 0 for i in range(6) if mu[i] > 0)]         # nu - a lives on a null set
print(f"die: splits of nu into tenths checked: {len(list(product(*grid)))}, valid: {len(splits)}")
assert splits == [tuple(nu_ac)]               # uniqueness, found by search
_, N2, s2, _, f2 = decompose([Fr(1, 6)] * 6, nu)
print(f"die against the fair die instead: largest null set {N2}, nu_s = ({fmt(s2)}); density ({fmt(f2)})")

# ---- Road 1: the bus, pieces from the story ----
F_ac = lambda x: 0.7 * (1 - e_neg(x)) if x > 0 else 0.0
F_d = lambda x: 0.3 if x >= 0 else 0.0
F = lambda x: F_ac(x) + F_d(x)
xs = [-1, None, 0, 0.5, 1, 1.5, 2, 3, 4, 5]
for name, G in (("F", F), ("F_ac", F_ac), ("F_d", F_d)):
    print(f"chart, bus {name} at -1, just below 0, 0, 0.5, 1, 1.5, 2, 3, 4, 5: "
          + ", ".join(f"{G(-1e-9 if x is None else x):.2f}" for x in xs))
print(f"bus: F(1) = {F(1):.6f} = F_ac(1) {F_ac(1):.6f} + F_d(1) {F_d(1):.1f}; "
      f"P(0 < X <= 2) = {F(2) - F(0):.6f}")
dens = simpson(lambda x: 0.7 * e_neg(x), 0.0, 40.0)            # second road: integrate the density
mean = simpson(lambda x: x * 0.7 * e_neg(x), 0.0, 40.0)             # the atom at 0 adds 0.3 x 0
print(f"bus, second road: integral of 0.7 e^(-x) over (0, 40] = {dens:.6f}; jump 0.3; "
      f"left for a staircase {round(1 - dens - 0.3, 6) + 0.0:.6f}; mean wait {mean:.6f}")
assert abs(dens - F_ac(40)) < 1e-9 and abs(1 - dens - 0.3) < 1e-9 and abs(mean - 0.7) < 1e-9

# ---- Road 2: the three-piece law read from F alone, cell by cell ----
F3 = lambda j, n: 0.3 + 0.5 * (1 - e_neg(j / 3**n)) + 0.2 * cantor(j, 3**n)   # F at j / 3^n >= 0
print("three-piece law: 0.3 at zero, 0.5 exponential at rate 1, 0.2 Cantor on [0, 1]")
print("chart, three-piece at 0, 1/9, ..., 1: F " + ", ".join(f"{F3(k, 2):.2f}" for k in range(10)))
print("chart, three-piece at 0, 1/9, ..., 1: staircase piece "
      + ", ".join(f"{0.2 * cantor(k, 9):.2f}" for k in range(10)))
print(f"three-piece: F(1/3) = {F3(3, 2):.6f}; C(1/3) = {cantor(1, 3)}")
def census(n, wj, we, wc):                   # cells of width 3^-n on (-1, 2]: rise sorted three ways
    jump, steep, flat = 0.0, 0.0, we * e_neg(2.0)                    # mass beyond 2 minutes: density
    prev = 0.0
    for j in range(-3**n + 1, 2 * 3**n + 1):
        cur = 0.0 if j < 0 else wj + we * (1 - e_neg(j / 3**n)) + wc * cantor(j, 3**n)
        rise, prev = cur - prev, cur
        if rise >= 0.05: jump += rise
        elif rise * 3**n > 1: steep += rise
        else: flat += rise
    return jump, steep, flat
print("census of cells of width 3^-n on (-1, 2]: jump (rise >= 0.05), steep (slope > 1), flat")
for n in (2, 4, 6, 8, 10):
    jump, steep, flat = census(n, 0.3, 0.5, 0.2)
    print(f"  n = {n:2d}: jump {jump:.6f}, steep {steep:.6f}, flat {flat:.6f}; bound 0.5(2/3)^n = {0.5 * (2/3)**n:.6f}")
assert abs(jump - 0.3) < 1e-12 and abs(steep - 0.2) <= 0.5 * (2/3)**n and abs(flat - 0.5) <= 0.5 * (2/3)**n
cj, cs, cf = census(10, 0.0, 0.0, 1.0)
m = 3**9                                      # layer cake: mean = integral of P(X > x)
cake = sum(0.2 * (1 - cantor(2 * k + 1, 2 * m)) + 0.5 * e_neg((2 * k + 1) / (2 * m)) for k in range(m)) / m
cake += simpson(lambda x: 0.5 * e_neg(x), 1.0, 40.0)
print(f"three-piece mean: pieces 0.3 x 0 + 0.5 x 1 + 0.2 x 0.5 = {0.3 * 0 + 0.5 * 1 + 0.2 * 0.5:.6f}; "
      f"layer cake {cake:.6f}")
assert abs(cake - 0.6) < 1e-6

# ---- What breaks ----
print(f"mistake 1, density only on the bus: total {dens:.6f}, missing {1 - dens:.6f}")
print(f"mistake 2, jumps plus density on the Cantor law alone, n = 10: jump {cj:.6f}, flat {cf:.6f}, "
      f"steep {cs:.6f}")
assert cj == 0 and cf == 0 and abs(cs - 1) < 1e-12
print(f"mistake 3, the loaded die against the fair die: singular part {float(sum(s2))}, not 0.6")
def split_count(N, E):                        # counting measure split on N: (would-be nu_ac(E), nu_s(E))
    return sum(1 for x in E if x not in N), sum(1 for x in E if x in N)
for name, N in (("dyadic", {Fr(k, 2**12) for k in range(2**12 + 1)}),
                ("triadic", {Fr(k, 3**8) for k in range(3**8 + 1)})):    # two length-zero candidates for N
    x = next(Fr(1, m) for m in range(1, 10**6) if Fr(1, m) not in N)     # search: a point of [0, 1] off N
    ac, sing = split_count(N, {x})
    print(f"mistake 4, counting measure on [0, 1]: N = {len(N)} {name} points, counting mass {len(N)}, "
          f"length 0; first 1/m off N: {x}; nu_ac({{{x}}}) = {ac}, nu_s({{{x}}}) = {sing}, length 0")
    assert ac == 1                            # the would-be density part charges a set of length 0
print("ALL CHECKS PASS")
