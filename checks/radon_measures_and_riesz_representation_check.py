# Radon measures and the Riesz representation theorem -- the check behind the card.
# Standard library only. The rule is Lambda(f) = f(0) + (integral of f over [0, 1]).
# The code treats Lambda as a black box: it builds the measure mu from Lambda alone,
# with bumps that fit inside open sets and tents that sit over compact sets, then checks
# that integrating against mu gives Lambda back, by a layer-cake road and a Stieltjes road.
N, D = 120000, 1e-4           # Simpson pieces on [0, 1]; ramp width of bumps and tents

def simpson(f, a, b, n):      # Simpson's rule with n (even) pieces, written out here
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

def lam(f):                   # the positive rule: reading at 0 plus area over [0, 1]
    return f(0.0) + simpson(f, 0.0, 1.0, N)

def lam_signed(f):            # linear, but not positive: reading at 0 minus the area
    return f(0.0) - simpson(f, 0.0, 1.0, N)

def clamp(v):
    return max(0.0, min(1.0, v))

def bump(p, q, d):            # 0 outside (p + d, q - d), 1 on [p + 2d, q - 2d]
    return lambda x: clamp(min(x - p - d, q - d - x) / d)

def tent(p, q, d):            # 1 on [p, q], falling to 0 at distance d outside it
    return lambda x: clamp(1 - max(p - x, x - q, 0.0) / d)

def mu_formula(p, q, kind):   # the answer to test: point mass at 0 plus length on [0, 1]
    holds_0 = p <= 0 <= q if kind == "c" else p < 0 < q
    return (1.0 if holds_0 else 0.0) + max(0.0, min(q, 1) - max(p, 0))

def f(x):                     # a test function: (1 - x^2) on [-1, 1], 0 outside
    return max(0.0, 1 - x * x)

def row(label, vals, fmt):
    print(label + " ".join(format(v, fmt) for v in vals))

def norm_test(e):             # 1 at 0, -1 on [e, 1], 0 outside (-e, 1 + e), straight between
    def g(x):
        if x < 0: return clamp(1 + x / e)
        if x <= e: return 1 - 2 * x / e
        if x <= 1: return -1.0
        return min(0.0, -1 + (x - 1) / e)
    return g

print("rule: Lambda(f) = f(0) + integral of f over [0, 1]; ramps of width d = 0.0001")
xs = [-0.5 + 0.125 * i for i in range(17)]
row("chart x: ", xs, ".3f")
row("chart tent, 1 on [0, 1], ramps 0.25: ", [tent(0, 1, 0.25)(x) for x in xs], ".2f")
row("chart bump, 0 outside (0.125, 0.875): ", [bump(0, 1, 0.125)(x) for x in xs], ".2f")
tents = [lam(tent(0, 1, 1 / k)) for k in (1, 10, 100)]
bumps = [lam(bump(0, 1, 1 / k)) for k in (4, 8, 100, 1000)]
spikes = [lam(tent(0, 0, 1 / k)) for k in (4, 100)]
row("tents over [0, 1], k = 1, 10, 100: Lambda = ", tents, ".6f")
row("bumps inside (0, 1), k = 4, 8, 100, 1000: Lambda = ", bumps, ".6f")
row("spikes over {0}, k = 4, 100: Lambda = ", spikes, ".6f")
sets = [("[0, 1]", 0, 1, "c"), ("(0, 1)", 0, 1, "o"), ("{0}", 0, 0, "c"),
        ("(-1, 0)", -1, 0, "o"), ("(-1, 0.5)", -1, 0.5, "o"), ("[-2, 2]", -2, 2, "c")]
for name, p, q, kind in sets:
    built = lam(bump(p, q, D)) if kind == "o" else lam(tent(p, q, D))
    exact = mu_formula(p, q, kind)
    print(f"mu{name} built from Lambda: {built:.3f}; point mass plus length: {exact:.3f}")
    assert abs(built - exact) < 1e-3                       # Lambda's measure is delta_0 + length
Fx = [-0.5 + 0.25 * i for i in range(9)]
row("F(x) = mu((-inf, x]) at x = -0.5, -0.25, ..., 1.5: ", [lam(tent(-2, x, D)) for x in Fx], ".3f")
exact = 1 + 2 / 3
road1 = lam(f)
M = 200                                                     # layer cake: mu({f > t}) by bumps
road2 = sum(lam(bump(-(1 - t) ** 0.5, (1 - t) ** 0.5, D)) for t in
            [(j + 0.5) / M for j in range(M)]) / M
n = 300                                                     # Stieltjes sums on (-1.5, 1.5]
grid = [-1.5 + 3 * i / n for i in range(n + 1)]
F = [lam(tent(-2, x, D)) for x in grid]
road3 = sum(f((grid[i] + grid[i + 1]) / 2) * (F[i + 1] - F[i]) for i in range(n))
print(f"test function (1 - x^2) on [-1, 1]: exact 1 + 2/3 = {exact:.6f}")
print(f"road 1, Lambda(f) directly: {road1:.6f}")
print(f"road 2, layer cake, {M} levels of mu(f > t) built from bumps: {road2:.6f}")
print(f"road 3, Stieltjes sum of f against F, {n} pieces: {road3:.7f}")
bound = lam(tent(-1, 1, 1))
print(f"bound on [-1, 1]: |Lambda(f)| <= Lambda(phi) x max|f| = {bound:.3f} x 1; "
      f"Lambda(f) = {road1:.3f}")
print("signed rule: Lambda_s(f) = f(0) - integral of f over [0, 1]")
sb = [lam_signed(bump(0, 1, 1 / k)) for k in (4, 8, 100)]
row("bumps inside (0, 1), k = 4, 8, 100: Lambda_s = ", sb, ".3f")
print(f"sup over 0 <= g <= 1 inside (0, 1), g = 0 included: {max(sb + [0.0]):.3f}; "
      f"signed mass of (0, 1): -1.000")
nt = [lam_signed(norm_test(e)) for e in (0.1, 0.01)]
row("norm test, |g| <= 1, e = 0.1, 0.01: Lambda_s(g) = ", nt, ".4f")
mass = lam_signed(tent(-2, 2, 1))
print(f"signed mass of R: {mass:.3f}; total variation |mu|(R) = 1 + 1 = 2")
ups = [lam_signed(tent(0, 0, 1 / k)) for k in (10, 100, 1000)]
row("positive part at the tent over [0, 1], spikes k = 10, 100, 1000: ", ups, ".4f")
lebesgue = [simpson(tent(-R, R, 1), -R - 1, R + 1, 4 * (R + 1)) for R in (10, 100)]
row("length rule on plateaus of height 1 over [-R, R], R = 10, 100: ", lebesgue, ".1f")
print("mistakes:")
print(f"  mu((0, 1)) from outside, by tents over [0, 1]: {tents[2]:.3f} (true 1.000)")
print(f"  length only, integral of f over [0, 1]: {simpson(f, 0, 1, N):.3f} "
      f"(true {exact:.3f})")
print(f"  norm of Lambda_s read as |mu(R)|: {abs(mass):.3f} (true 2.000)")
print(f"  sup over bumps for Lambda_s on (0, 1): {max(sb + [0.0]):.3f} (true -1.000)")
assert abs(road1 - exact) < 1e-12                           # Simpson is exact on a quadratic
assert abs(road2 - exact) < 1e-3 and abs(road3 - exact) < 1e-3   # three roads agree
assert all(abs(b - (1 - 3 / k)) < 1e-9 for b, k in zip(bumps, (4, 8, 100, 1000)))
assert all(abs(v - (2 - e)) < 1e-9 for v, e in zip(nt, (0.1, 0.01)))
assert all(abs(v - (1 - 1 / (2 * k))) < 1e-9 for v, k in zip(ups, (10, 100, 1000)))
assert abs(lebesgue[1] - 201) < 1e-9 and abs(mass) < 1e-9
print("ALL CHECKS PASS")
