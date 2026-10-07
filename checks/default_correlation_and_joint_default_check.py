# Default correlation -- the check behind the card.  Standard library only.
# Two bakeries, each 5% likely to fail within five years; then a pool of 100
# such loans.  Normal curve, inverse, integrator and random numbers are written
# out here; nothing imported already knows the answer.
from math import exp, sqrt, pi, comb

def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)      # bell-curve height
def simpson(f, a, b, n):                                     # area under f, n even
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0
def N(x): return 0.5 + simpson(phi, 0.0, x, 400)            # bell-curve area left of x
def N_inv(prob):                                              # bisection on N
    lo, hi = -10.0, 10.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        if N(mid) < prob: lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def joint(p1, p2, rho): return p1 * p2 + rho * sqrt(p1 * (1 - p1) * p2 * (1 - p2))
def rho_of(p1, p2, j):  return (j - p1 * p2) / sqrt(p1 * (1 - p1) * p2 * (1 - p2))
def pmf_formula(n, q): return [comb(n, k) * q**k * (1 - q)**(n - k) for k in range(n + 1)]
def pmf_by_adding(n, q):              # road 2: add one loan at a time, no binomial formula
    d = [1.0]
    for _ in range(n):
        d = [(d[k] if k < len(d) else 0.0) * (1 - q) + (d[k - 1] * q if k > 0 else 0.0)
             for k in range(len(d) + 1)]
    return d
def mix(parts): return [sum(w * d[k] for w, d in parts) for k in range(len(parts[0][1]))]
def tail(d, m): return sum(d[m:])
def mean_var(d):
    m = sum(k * x for k, x in enumerate(d))
    return m, sum(k * k * x for k, x in enumerate(d)) - m * m

p, n, loan, recovery = 0.05, 100, 100_000.0, 0.40
loss_each = loan * (1 - recovery)

# ---- the pair: from default correlation to joint default and back ----
rho_d = 11 / 190
j_ind = joint(p, p, 0.0)
j = joint(p, p, rho_d)
j_058 = joint(p, p, 0.058)
cells = (j, p - j, p - j, 1 - 2 * p + j)
rho_lo, rho_hi = rho_of(p, p, max(0.0, 2 * p - 1)), rho_of(p, p, min(p, p))

# ---- the town model: a bad spell (prob 11/51, 15% each) or not (2.25% each) ----
w, p_bad, p_good = 11 / 51, 0.15, 0.0225
p_town = w * p_bad + (1 - w) * p_good
j_town = w * p_bad**2 + (1 - w) * p_good**2              # two loans, same spell
assert abs(j_town - j) < 1e-15                           # town model meets the pair formula
indep = pmf_formula(n, p)
town = mix([(w, pmf_formula(n, p_bad)), (1 - w, pmf_formula(n, p_good))])
town2 = mix([(w, pmf_by_adding(n, p_bad)), (1 - w, pmf_by_adding(n, p_good))])
assert max(abs(a - b) for a, b in zip(town, town2)) < 1e-14
assert abs(tail(indep, 10) - tail(pmf_by_adding(n, p), 10)) < 1e-14
m_i, v_i = mean_var(indep)
m_t, v_t = mean_var(town)
v_formula = n * p * (1 - p) * (1 + (n - 1) * rho_of(p, p, j_town))
assert abs(v_t - v_formula) < 1e-9                        # full law agrees with pair formula

# ---- copy model: same p, same pair, different tail ----
copy_tail = rho_d * p + (1 - rho_d) * tail(indep, 10)

# ---- asset correlation 20% through the one-factor Gaussian model ----
rho_a = 0.20
c = N_inv(p)
def cond(z, ra): return N((c - sqrt(ra) * z) / sqrt(1 - ra))   # default chance given the economy z
def j_factor(ra): return simpson(lambda z: cond(z, ra)**2 * phi(z), -8.0, 8.0, 400)
def j_plackett(ra):                                            # road 2: grow correlation from 0
    return p * p + simpson(lambda r: exp(-c * c / (1 + r)) / (2 * pi * sqrt(1 - r * r)), 0.0, ra, 200)
j_g, j_g2 = j_factor(rho_a), j_plackett(rho_a)
assert abs(j_g - j_g2) < 1e-12
gauss = [simpson(lambda z: pmf_formula(n, cond(z, rho_a))[k] * phi(z), -8.0, 8.0, 400) for k in range(n + 1)]
assert abs(mean_var(gauss)[1] - n * p * (1 - p) * (1 + (n - 1) * rho_of(p, p, j_g))) < 1e-6

# ---- road 3: simulate 20,000 pools of the town model ----
MASK = (1 << 64) - 1
state = 20260928
def uniform():                                    # splitmix64, top 53 bits
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
pools, hits, pairs = 20_000, 0, 0
for _ in range(pools):
    q = p_bad if uniform() < w else p_good
    s = sum(1 for _ in range(n) if uniform() < q)
    hits += s >= 10
    pairs += s * (s - 1)
mc_tail = hits / pools
mc_joint = pairs / (pools * n * (n - 1))
se = sqrt(tail(town, 10) * (1 - tail(town, 10)) / pools)
assert abs(mc_tail - tail(town, 10)) < 4 * se
assert abs(mc_joint - j) < 0.0004

rows = [
    ("pair: both fail, independent", j_ind), ("pair: scale, sqrt of p(1-p)p(1-p)", joint(p, p, 1.0) - j_ind),
    ("pair: extra from rho_D", j - j_ind), ("pair: both fail, rho_D = 11/190", j),
    ("pair: both fail, rho_D = 0.058", j_058), ("pair: rho_D back from 0.525%", rho_of(p, p, 0.00525)),
    ("cells: one fails, other survives", cells[1]), ("cells: neither fails", cells[3]),
    ("bounds: lowest rho_D", rho_lo), ("bounds: highest rho_D", rho_hi),
    ("town: bad-spell chance", w), ("town: default chance", p_town), ("town: both fail", j_town),
    ("pool: mean defaults, independent", m_i), ("pool: mean defaults, town", m_t),
    ("pool: variance, independent", v_i), ("pool: bracket 1 + 99 rho_D", 1 + (n - 1) * rho_d),
    ("pool: variance, pair formula", v_formula), ("pool: variance, town model", v_t),
    ("pool: sd defaults, independent", sqrt(v_i)), ("pool: sd defaults, town", sqrt(v_t)),
    ("pool: sd ratio, town / indep", sqrt(v_t / v_i)),
    ("pool: expected loss $", m_i * loss_each), ("pool: sd loss $, independent", sqrt(v_i) * loss_each),
    ("pool: sd loss $, town", sqrt(v_t) * loss_each),
    ("tail: 10+ fail, independent", tail(indep, 10)), ("tail: 10+ fail, town", tail(town, 10)),
    ("tail: 10+ fail, copy model", copy_tail), ("tail: 10+ fail, asset corr 20%", tail(gauss, 10)),
    ("tail: town / independent", tail(town, 10) / tail(indep, 10)),
    ("tail: asset 20% / independent", tail(gauss, 10) / tail(indep, 10)),
    ("tail: town / copy", tail(town, 10) / copy_tail),
    ("tail: one spell in, independent", 1 / tail(indep, 10)), ("tail: one spell in, town", 1 / tail(town, 10)),
    ("sim: 10+ fail, 20,000 pools", mc_tail), ("sim: both fail, all pairs", mc_joint),
    ("asset: threshold c = N_inv(0.05)", c), ("asset: both fail, factor road", j_g),
    ("asset: both fail, Plackett road", j_g2), ("asset: rho_D implied by 20%", rho_of(p, p, j_g)),
    ("wrong: asset 0.20 used as rho_D", joint(p, p, rho_a)), ("wrong: rho_D times p1*p2", j_ind * (1 + rho_d)),
    ("try: rho_D implied by asset 40%", rho_of(p, p, j_factor(0.40))),
    ("try: sd ratio, 1,000 loans", sqrt(1 + 999 * rho_d)),
]
for name, v in rows:
    print(f"{name:<34} {v:>16.6f}")
print("dist: k, P(S=k) in %: independent, town, asset 20%; twice per line")
for k in range(8):
    a, b = k, k + 8
    print(f"dist {a:>2} {100 * indep[a]:>6.2f} {100 * town[a]:>6.2f} {100 * gauss[a]:>6.2f}"
          f"  | {b:>2} {100 * indep[b]:>6.2f} {100 * town[b]:>6.2f} {100 * gauss[b]:>6.2f}")
