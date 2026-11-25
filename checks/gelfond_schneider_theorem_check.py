# Gelfond-Schneider -- the check behind the card.  Standard library only, no imports.
# Road 1: a^b = exp(b ln a), from series written here.  Road 2: a^b from the binary
# digits of b, one square root per digit.  Siegel's lemma: a pigeonhole collision,
# checked against a brute-force search for the smallest whole solution.

def sqrt(x):                          # Newton's method from above, stops when it stops falling
    r = x if x > 1 else 1.0
    while True:
        n = 0.5 * (r + x / r)
        if n >= r: return r
        r = n

def series(t, sign):                 # t + sign t^3/3 + t^5/5 + ...: atanh (sign 1), atan (sign -1)
    s, p = 0.0, t
    for k in range(1, 120, 2):
        s += (p if k % 4 == 1 or sign == 1 else -p) / k; p *= t * t
    return s

LN2 = 2 * series(1 / 3, 1)
PI = 16 * series(1 / 5, -1) - 4 * series(1 / 239, -1)    # Machin's formula
E, term = 1.0, 1.0                   # e = 1 + 1/1! + 1/2! + ...
for n in range(1, 25):
    term /= n; E += term

def ln(x):                            # x = m 2^e with 1 <= m < 2; ln m = 2 atanh((m-1)/(m+1))
    e = 0
    while x >= 2: x /= 2; e += 1
    while x < 1: x *= 2; e -= 1
    return e * LN2 + 2 * series((x - 1) / (x + 1), 1)

def exp(x):                           # halve until small, Taylor series, square back
    k = 0
    while abs(x) > 1 / 1024: x /= 2; k += 1
    s, term = 1.0, 1.0
    for n in range(1, 20):
        term *= x / n; s += term
    for _ in range(k): s *= s
    return s

def pow_bits(a, b):                   # road 2: a^floor(b), times a^(1/2^k) for each 1 bit of b
    n = int(b); f = b - n
    out = 1.0
    for _ in range(n): out *= a
    r = a
    for _ in range(60):
        r = sqrt(r); f *= 2
        if f >= 1: f -= 1; out *= r
    return out

R2 = sqrt(2.0)
print(f"sqrt 2 = {R2:.11f}, ln 2 = {LN2:.11f}, pi = {PI:.11f}, e = {E:.11f}")
print("a^b | road 1: exp(b ln a) | road 2: binary digits of b")
rows = [("2^sqrt2", 2.0, R2), ("sqrt2^sqrt2", R2, R2), ("e^pi", E, PI)]
vals = {}
for name, a, b in rows:
    v1, v2 = exp(b * ln(a)), pow_bits(a, b)
    assert abs(v1 - v2) < 1e-11 * v1           # two roads agree
    vals[name] = v1
    print(f"{name} | {v1:.9f} | {v2:.9f}")
# (-1)^(-i) and i^(-2i): b times the principal log, as complex pairs (re, im)
def cmul(u, v): return (u[0] * v[0] - u[1] * v[1], u[0] * v[1] + u[1] * v[0])
w1, w2 = cmul((0.0, -1.0), (0.0, PI)), cmul((0.0, -2.0), (0.0, PI / 2))
assert w1 == (PI, 0.0) and w2 == (PI, 0.0)
print(f"(-1)^(-i) = exp(-i * i pi) = exp({w1[0]:.9f}) = {exp(w1[0]):.9f}; i^(-2i) = {exp(w2[0]):.9f}")
back = pow_bits(vals["sqrt2^sqrt2"], R2)
assert abs(back - 2) < 1e-11                   # (sqrt2^sqrt2)^sqrt2 = sqrt2^2 = 2
print(f"(sqrt2^sqrt2)^sqrt2 = {back:.9f}")
L23 = ln(3.0) / LN2
print(f"b = log2 3 = {L23:.9f} (b not algebraic): 2^b = {pow_bits(2.0, L23):.9f}")
print(f"b = 1/2 (rational b): 2^b = {pow_bits(2.0, 0.5):.9f}, squared {pow_bits(2.0, 0.5) ** 2:.9f}")
print(f"a = 1: 1^sqrt2 = {pow_bits(1.0, R2):.9f}")
assert abs(pow_bits(2.0, L23) - 3) < 1e-11 and abs(exp(PI) - vals["e^pi"]) < 1e-11 * 24

# Siegel's lemma: M equations, N unknowns, coefficients at most A in size
A = [[10, 7, 1, 7], [7, 6, 8, -10]]
M, N, AMAX = 2, 4, 10
H = 0
while (H + 1) ** (N - M) <= (N * AMAX) ** M: H += 1    # largest H with H^(N-M) <= (NA)^M
assert H == int((N * AMAX) ** (M / (N - M)) + 1e-9)     # the power, taken a second way
print(f"Siegel bound (N A)^(M/(N-M)) = ({N} x {AMAX})^({M}/{N - M}) = {H}")
def image(x): return tuple(sum(a * v for a, v in zip(row, x)) for row in A)
boxes, images = (H + 1) ** N, (N * AMAX * H + 1) ** M
print(f"vectors with entries 0..{H}: {boxes:,}; possible images at most {images:,}")
assert boxes > images
seen, hit = {}, None
for i in range((H + 1) ** N):
    x = (i // (H + 1) ** 3, i // (H + 1) ** 2 % (H + 1), i // (H + 1) % (H + 1), i % (H + 1))
    y = image(x)
    if y in seen: hit = (seen[y], x); break
    seen[y] = x
d = tuple(b - a for a, b in zip(*hit))
assert image(d) == (0, 0) and any(d) and max(map(abs, d)) <= H
print(f"first collision: {hit[0]} and {hit[1]}, image {image(hit[0])}, after {len(seen):,} vectors")
print(f"difference {d}: solves both equations, height {max(map(abs, d))}")

def solve_last_two(cols, rhs):        # Cramer's rule on a 2 x 2 block; None if not whole
    (a, b), (c, e) = cols
    det = a * e - b * c
    n1, n2 = rhs[0] * e - b * rhs[1], a * rhs[1] - c * rhs[0]
    return None if n1 % det or n2 % det else (n1 // det, n2 // det)
sols = []
for x1 in range(-H, H + 1):           # road 2: every (x1, x2), then x3, x4 forced
    for x2 in range(-H, H + 1):
        if x1 == 0 and x2 == 0: continue
        r = solve_last_two(((A[0][2], A[0][3]), (A[1][2], A[1][3])),
                           (-(A[0][0] * x1 + A[0][1] * x2), -(A[1][0] * x1 + A[1][1] * x2)))
        if r and max(abs(r[0]), abs(r[1])) <= H: sols.append((x1, x2) + r)
small = min(sols, key=lambda s: (max(map(abs, s)), s))
assert all(image(s) == (0, 0) for s in sols) and d in sols
print(f"brute force: {len(sols)} nonzero solutions of height <= {H}; smallest {small}, "
      f"height {max(map(abs, small))}")
sq = [(x1, x2) for x1 in range(-H, H + 1) for x2 in range(-H, H + 1)
      if (x1 or x2) and A[0][0] * x1 + A[0][1] * x2 == 0 and A[1][0] * x1 + A[1][1] * x2 == 0]
print(f"square system (first 2 unknowns): det {A[0][0] * A[1][1] - A[0][1] * A[1][0]}, "
      f"nonzero solutions {len(sq)}")
assert sq == []
H3 = (3 * AMAX) ** 2                  # N = 3, M = 2: exponent 2/(3-2) = 2
t3 = next((x3, r) for x3 in range(1, H3 + 1)
          for r in [solve_last_two(((A[0][0], A[0][1]), (A[1][0], A[1][1])),
                                   (-A[0][2] * x3, -A[1][2] * x3))] if r)
v3 = (t3[1][0], t3[1][1], t3[0])
cross = (7 * 8 - 1 * 6, 1 * 7 - 10 * 8, 10 * 6 - 7 * 7)
assert v3 == cross or v3 == tuple(-c for c in cross)
print(f"three unknowns: bound 30^2 = {H3}; smallest solution {v3}, height {max(map(abs, v3))}")

# The squeeze in miniature: x - y sqrt2 is small (pigeonhole) but not too small (norm >= 1)
HQ, best = 1000, (9.0, 0, 0)
for y in range(1, HQ + 1):
    x = int(y * R2 + 0.5)
    v = abs(x * x - 2 * y * y) / (x + y * R2)     # |x - y sqrt2| through the norm x^2 - 2y^2
    assert v >= 1 / (2 * R2 * y + 0.5)            # lower bound from |norm| >= 1
    best = min(best, (v, y, x))
print(f"y <= {HQ}: smallest |x - y sqrt2| = {best[0]:.9f} at x = {best[2]}, y = {best[1]}")
print(f"lower bound 1/(2 sqrt2 H + 1/2) = {1 / (2 * R2 * HQ + 0.5):.9f}; "
      f"upper bound 1/H = {1 / HQ:.9f}")
assert 1 / (2 * R2 * HQ + 0.5) <= best[0] < 1 / HQ
print("ALL CHECKS PASS")
