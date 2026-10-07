# Buckingham Pi on cyclist drag -- the check behind the card. Standard library only.
# Road 1: exact elimination on the dimension matrix gives the rank and the groups.
# Road 2: brute force over every half-step exponent finds the dimensionless products.
# Road 3: a change of units leaves the groups unchanged. Road 4: nine setups collapse.
from fractions import Fraction as Q
from math import sqrt

NAMES = ["rho", "V", "A", "F", "mu"]          # repeating variables rho, V, A first
DIMS = [[1, 0, 0, 1, 1],                      # M exponents
        [-3, 1, 2, 1, -1],                    # L exponents
        [0, -1, 0, -2, -1]]                   # T exponents

def rref(rows):
    m = [[Q(x) for x in r] for r in rows]
    piv, r = [], 0
    for c in range(len(m[0]) if m else 0):
        p = next((i for i in range(r, len(m)) if m[i][c] != 0), None)
        if p is None: continue
        m[r], m[p] = m[p], m[r]
        m[r] = [x / m[r][c] for x in m[r]]
        for i in range(len(m)):
            if i != r and m[i][c] != 0:
                f = m[i][c]; m[i] = [a - f * b for a, b in zip(m[i], m[r])]
        piv.append(c); r += 1
        if r == len(m): break
    return m, piv

def kernel(rows):
    m, piv = rref(rows)
    n = len(rows[0]); out = []
    for fc in [c for c in range(n) if c not in piv]:
        v = [Q(0)] * n; v[fc] = Q(1)
        for i, pc in enumerate(piv): v[pc] = -m[i][fc]
        out.append(v)
    return out, len(piv)

def show(v): return " ".join(f"{str(x):>4}" for x in v)

print("dimension matrix, columns " + " ".join(f"{s:>4}" for s in NAMES))
for lab, r in zip("MLT", DIMS): print(f"  {lab}  " + " " * 21 + show(r))
basis, k = kernel(DIMS)
print(f"variables n = {len(NAMES)}, rank k = {k}, groups n - k = {len(basis)}")
for name, v in zip(["Pi_F ", "Pi_mu"], basis): print(f"{name} exponents rho V A F mu: {show(v)}")

# Road 2: every product with exponents -2, -1.5, ..., 2 (doubled: -4..4), tested for zero dimension
found = []
for code in range(9 ** 5):
    e = [(code // 9 ** j) % 9 - 4 for j in range(5)]
    if all(sum(d * x for d, x in zip(r, e)) == 0 for r in DIMS): found.append(e)
from_basis = 0
for a in range(-4, 5):                        # doubled exponent of F
    for b in range(-4, 5):                    # doubled exponent of mu
        if b % 2: continue                    # A would get a quarter power
        v = [-a - b, -2 * a - b, -a - b // 2, a, b]
        from_basis += all(-4 <= x <= 4 for x in v)
_, brute_rank = rref(found) if found else (None, [])
print(f"brute force: {len(found)} dimensionless products in the box, {from_basis} predicted from the two groups")
print(f"brute force: those products span {len(brute_rank)} independent directions")

# Road 3: same rider in grams, centimetres, minutes
rho, mu, A, V = 1.225, 1.7894e-5, 0.40, 12.0  # US Standard Atmosphere 1976 at sea level; full-size rider
def law(rho, mu, A, V):                       # stand-in experiment, written without any group in it
    return 0.5 * 0.65 * rho * V * V * A + 17.5 * sqrt(rho * mu) * V ** 1.5 * A ** 0.75
def groups(rho, V, A, F, mu): return F / (rho * V * V * A), mu / (rho * V * sqrt(A))
F = law(rho, mu, A, V)
g = 1000.0; cm = 100.0; mn = 1 / 60.0         # new units per old unit: kg->g, m->cm, s->min
conv = [g / cm ** 3, cm / mn, cm * cm, g * cm / mn ** 2, g / (cm * mn)]
new = [x * c for x, c in zip([rho, V, A, F, mu], conv)]
p_si, p_new = groups(rho, V, A, F, mu), groups(*new)
bad_si, bad_new = F / (rho * V * A), new[3] / (new[0] * new[1] * new[2])
print(f"units: F = {F:.4f} N in SI, {new[3] / 1e9:.6f} x 10^9 g cm/min^2 in the new units")
print(f"units: Pi_F  SI {p_si[0]:.6f}  new {p_new[0]:.6f}")
print(f"units: Pi_mu x 10^6 SI {p_si[1] * 1e6:.6f}  new {p_new[1] * 1e6:.6f}")
print(f"units: wrong F/(rho V A) SI {bad_si:.6f}  new {bad_new:.6f}")

# The cyclist, read back
L = sqrt(A); Re = rho * V * L / mu; CD = F / (0.5 * rho * V * V * A)
print(f"cyclist: sqrt(A) = {L:.4f} m, Re = {Re:.0f}, C_D = {CD:.4f}, Pi_F = {CD / 2:.4f}")
print(f"cyclist: sqrt(Re) = {sqrt(Re):.1f}, 35/sqrt(Re) = {35 / sqrt(Re):.4f}, 0.5 rho V^2 A = {0.5 * rho * V * V * A:.2f} N")
print(f"cyclist: drag F = {F:.2f} N, power F V = {F * V:.1f} W")

def atmos(h):                                 # US Standard Atmosphere 1976, troposphere
    T = 288.15 - 0.0065 * h
    p = 101325.0 * (T / 288.15) ** 5.255877
    return p / (287.05287 * T), 1.458e-6 * T ** 1.5 / (T + 110.4), sqrt(1.4 * 287.05287 * T)
def master(Re): return 0.65 + 35.0 / sqrt(Re)  # C_D the stand-in law implies, derived on the card

# Road 4: nine setups (three sizes x three altitudes), each at the speed that gives a target Re
setups = [(h, a) for h in (0.0, 2000.0, 4000.0) for a in (0.40, 0.10, 0.025)]
spread_ok = True
for target in (2e4, 5e4, 1e5, 2e5, 5e5, 1e6):
    cs, fs = [], []
    for h, a in setups:
        r, m, _ = atmos(h); v = target * m / (r * sqrt(a)); f = law(r, m, a, v)
        cs.append(f / (0.5 * r * v * v * a)); fs.append(f)
    spread_ok &= max(cs) - min(cs) < 1e-12 and abs(cs[0] - master(target)) < 1e-12
    print(f"collapse Re {target:>9.0f}: C_D {cs[0]:.4f} in all 9 setups; raw F {min(fs):.4f} N to {max(fs):.4f} N")
print(f"collapse: one curve, spread below 1e-12: {'yes' if spread_ok else 'no'}")

print("figure, C_D at Re 2e4 5e4 1e5 2e5 5e5 1e6: " + " ".join(f"{master(x):.2f}" for x in (2e4, 5e4, 1e5, 2e5, 5e5, 1e6)))
print(f"figure, C_D if viscosity is left off (one constant): {CD:.2f}")
print("figure, raw drag in N at V = 4 8 12 16 20 24 m/s")
for lab, h, a in (("full size, sea level", 0.0, 0.40), ("full size, 4000 m", 4000.0, 0.40), ("half scale, sea level", 0.0, 0.10)):
    r, m, _ = atmos(h)
    print(f"  {lab:<22}" + " ".join(f"{law(r, m, a, v):.2f}" for v in (4, 8, 12, 16, 20, 24)))

# What breaks
q_a = 0.025; q_re = rho * V * sqrt(q_a) / mu; q_cd = law(rho, mu, q_a, V) / (0.5 * rho * V * V * q_a)
print(f"no viscosity: quarter-scale model at 12 m/s, Re = {q_re:.0f}, C_D = {q_cd:.4f}")
print(f"no viscosity: full-size drag predicted {0.5 * rho * V * V * A * q_cd:.2f} N, true {F:.2f} N")
h_v = 2 * V; h_f = law(rho, mu, 0.10, h_v)
print(f"similar model: half scale at {h_v:.0f} m/s, Re = {rho * h_v * sqrt(0.10) / mu:.0f}, drag {h_f:.2f} N")
with_theta = DIMS + [[0, 0, 0, 0, 0]]
_, k4 = kernel(with_theta)
print(f"names vs rank: 4 dimension names, rank {k4}, groups {5 - k4} (not {5 - 4})")
with_c = [r + [c] for r, c in zip(DIMS, (0, 1, -1))]
bc, kc = kernel(with_c)
r0, m0, c0 = atmos(0.0)
print(f"add sound speed c = {c0:.2f} m/s: n = 6, rank {kc}, groups {len(bc)}")
print(f"Mach V/c: cyclist {V / c0:.4f}, at 150 m/s {150 / c0:.4f}")
print(f"try: C_D at Re 1e7 {master(1e7):.4f}, at Re 1000 {master(1e3):.4f}")

assert len(basis) == len(brute_rank)                           # elimination vs brute force
assert k == 3 and len(basis) == 2 and k4 == 3 and len(bc) == 3  # the counts the card states
assert abs(0.5 * rho * V * V * A * q_cd / F - 1) > 0.05        # dropping viscosity mispredicts
via = [1.0, 1.0]                                               # the elimination's exponents, applied
for i, v in enumerate(basis):
    for x, e in zip([rho, V, A, F, mu], v): via[i] *= x ** float(e)
assert all(abs(a / b - 1) < 1e-12 for a, b in zip(via, p_si))  # match the groups written out by hand
assert len(found) == from_basis                                # brute count vs count built from the groups
assert all(abs(x / y - 1) < 1e-12 for x, y in zip(p_si, p_new))  # groups survive the unit change
assert abs(bad_new / bad_si - 1) > 0.1                         # a non-group does not
assert spread_ok                                               # raw law at nine setups vs the master curve
assert abs(h_f - F) < 1e-9 * F                                 # half-scale run of the law equals full size
assert abs(r0 - 1.225) < 1e-3 and abs(m0 - 1.7894e-5) < 1e-8 and abs(atmos(4000.0)[0] - 0.8194) < 1e-3  # the standard's table, 0 m and 4000 m
print("all checks passed")
