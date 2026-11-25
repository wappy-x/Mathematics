# Isogenies and the dual isogeny -- the check behind the card.  Nothing is imported.
# E is y^2 = x^3 - x, E2 is Y^2 = X^3 + 4X, phi(x, y) = (y^2/x^2, -y(x^2 + 1)/x^2).  Roads: Velu's
# formula against phi; dual(phi) against doubling, point by point and as fractions; deg[m] from
# division polynomials against m-torsion counts; Hasse's form against a brute-force count over F_25.
def ecadd(P, Q, a, p):                       # chord and tangent mod p; None is O
    if P is None or Q is None:
        return Q if P is None else P
    (x1, y1), (x2, y2) = P, Q
    if x1 == x2 and (y1 + y2) % p == 0:
        return None
    m = ((3 * x1 * x1 + a) * pow(2 * y1, p - 2, p) if P == Q else (y2 - y1) * pow(x2 - x1, p - 2, p)) % p
    x3 = (m * m - x1 - x2) % p
    return (x3, (m * (x1 - x3) - y1) % p)

def mult(n, P, a, p):                        # P added to itself n times
    return None if n == 0 else ecadd(mult(n - 1, P, a, p), P, a, p)

def points(a, p):                            # every pair (x, y) on y^2 = x^3 + ax, O left out
    return [(x, y) for x in range(p) for y in range(p) if (y * y - x ** 3 - a * x) % p == 0]

def phi(P, p):                               # E -> E2; (0, 0) goes to O
    return None if P is None or P[0] == 0 else (P[1] ** 2 * pow(P[0] ** 2, p - 2, p) % p,
                                                 -P[1] * (P[0] ** 2 + 1) * pow(P[0] ** 2, p - 2, p) % p)

def dual(Q, p):                              # E2 -> E; (0, 0) goes to O
    return None if Q is None or Q[0] == 0 else (2 * Q[1] ** 2 * pow(8 * Q[0] ** 2, p - 2, p) % p,
                                                 Q[1] * (4 - Q[0] ** 2) * pow(8 * Q[0] ** 2, p - 2, p) % p)

def velu(P, p):                              # Velu's map for the kernel {O, (0, 0)}
    return None if P is None or P[0] == 0 else ((P[0] - pow(P[0], p - 2, p)) % p,
                                                 (P[1] + P[1] * pow(P[0] ** 2, p - 2, p)) % p)

def pmul(f, g):                              # polynomials: lists, constant first
    return [sum(f[i] * g[k - i] for i in range(len(f)) if 0 <= k - i < len(g)) for k in range(len(f) + len(g) - 1)]

def psub(f, g):
    out = [(f[i] if i < len(f) else 0) - (g[i] if i < len(g) else 0) for i in range(max(len(f), len(g)))]
    while len(out) > 1 and out[-1] == 0:
        out.pop()
    return out

def gcd_deg(f, g, p):                        # degree of gcd(f, g) mod p, by Euclid
    f, g = [c % p for c in f], [c % p for c in g]
    while any(g):                            # leading terms stay nonzero mod p
        while len(f) >= len(g) and any(f):
            c, s = f[-1] * pow(g[-1], p - 2, p) % p, len(f) - len(g)
            f = [(f[i] - c * (g[i - s] if i >= s else 0)) % p for i in range(len(f))]
            while f and f[-1] == 0:
                f.pop()
        f, g = g, f
    return len(f) - 1

def xmult(m, a, b):                          # x([m]P) = top / bottom, by division polynomials
    F, g = [b, a, 0, 1], {0: [0], 1: [1], 2: [2], 3: [-a * a, 12 * b, 6 * a, 0, 3],
                          4: [4 * c for c in [-8 * b * b - a ** 3, -4 * a * b, -5 * a * a, 20 * b, 5 * a, 0, 1]]}
    for n in range(5, m + 2):                # psi_n = g_n for odd n, y * g_n for even n
        k, F2 = n // 2, pmul(F, F)
        if n % 2:
            s1, s2 = (F2, [1]) if k % 2 == 0 else ([1], F2)
            g[n] = psub(pmul(s1, pmul(g[k + 2], pmul(g[k], pmul(g[k], g[k])))),
                        pmul(s2, pmul(g[k - 1], pmul(g[k + 1], pmul(g[k + 1], g[k + 1])))))
        else:
            t = psub(pmul(g[k + 2], pmul(g[k - 1], g[k - 1])), pmul(g[k - 2], pmul(g[k + 1], g[k + 1])))
            g[n] = [c // 2 for c in pmul(g[k], t)]
    sq = pmul(g[m], g[m])
    if m % 2:
        return psub(pmul([0, 1], sq), pmul(F, pmul(g[m - 1], g[m + 1]))), sq
    return psub(pmul([0, 1], pmul(F, sq)), pmul(g[m - 1], g[m + 1])), pmul(F, sq)

def show(f):                                 # leading term first: x^4 + 2x^2 + 1
    out = ""
    for i in range(len(f) - 1, -1, -1):
        if f[i]:
            term = ("" if abs(f[i]) == 1 and i else str(abs(f[i]))) + ("" if i == 0 else "x" if i == 1 else f"x^{i}")
            out += (("-" if f[i] < 0 else "") if not out else (" - " if f[i] < 0 else " + ")) + term
    return out

def count2(p, r):                            # y^2 = x^3 - x over F_(p^2) = c + d*s, s^2 = r
    mul = lambda u, w: ((u[0] * w[0] + r * u[1] * w[1]) % p, (u[0] * w[1] + u[1] * w[0]) % p)
    F = [(c, d) for c in range(p) for d in range(p)]
    rhs = {x: tuple((mul(x, mul(x, x))[i] - x[i]) % p for i in range(2)) for x in F}
    return 1 + sum(1 for x in F for y in F if mul(y, y) == rhs[x])

v = 3 * 0 * 0 - 1                            # Velu at T = (0, 0) on y^2 = x^3 - x: v = 3x_T^2 + a, w = x_T v
print(f"Velu: v = {v}, w = {0 * v}; target Y^2 = X^3 + {-1 - 5 * v}X + {0 - 7 * 0 * v}")
counts = []
for p in [5, 13, 17, 29]:
    E, E2 = points(-1, p), points(4, p)
    homo = all(phi(ecadd(P, Q, -1, p), p) == ecadd(phi(P, p), phi(Q, p), 4, p) for P in E for Q in E)
    back = all(dual(phi(P, p), p) == mult(2, P, -1, p) for P in E)
    fwd = all(phi(dual(Q, p), p) == mult(2, Q, 4, p) for Q in E2)
    neg = all(phi(P, p) == (V and (V[0], -V[1] % p)) for P in E for V in [velu(P, p)])
    assert homo and back and fwd and neg and [P for P in E if phi(P, p) is None] == [(0, 0)] and len(E) == len(E2)
    counts.append(len(E) + 1)
    print(f"F_{p}: #E = {len(E) + 1}, #E2 = {len(E2) + 1}, kernel {{O, (0, 0)}}, image {len({phi(P, p) for P in E})}"
          f" points, adds: yes, dual(phi) = [2]: yes, phi = -Velu: yes")
assert counts == [8, 8, 16, 40]
P, R = (3, 13), dual(phi((3, 13), 29), 29)
print(f"F_29: P = {P}, phi(P) = {phi(P, 29)}, dual(phi(P)) = {R}, 2P = {mult(2, P, -1, 29)}; equals P: {['no', 'yes'][R == P]}")
print(f"by hand mod 29: 13^2 = {13 * 13} -> {13 * 13 % 29}, 3^3 - 3 = {27 - 3}; 9 x 13 = {9 * 13} -> {9 * 13 % 29}, so 1/9 = {pow(9, 27, 29)};"
      f" X = 24 x 13 = {24 * 13} -> {24 * 13 % 29}; Y = -13 x {9 + 1} = {-130}, x 13 -> {-130 * 13 % 29}; 21^2 = {21 * 21} -> {21 * 21 % 29}\n"
      f"by hand mod 29: 22^3 + 4 x 22 = {22 ** 3 + 88} -> {(22 ** 3 + 88) % 29}; 4X^2 = {4 * 22 * 22} -> {4 * 22 * 22 % 29}; 22 x 4 = {88} -> {88 % 29}, so"
      f" 1/22 = {pow(22, 27, 29)}; x = 6 x 4 = {6 * 4 % 29}; 2P: slope {3 * 9 - 1}/{2 * 13} = 1, x = 1 - {2 * 3} = {1 - 6} -> {-5 % 29}")
top, bot = xmult(2, -1, 0)                   # dual after phi, as exact fractions in x
ltop, lbot = psub(pmul([-1, 0, 1], [-1, 0, 1]), [0, 0, -4]), [4 * c for c in pmul([0, 1], [-1, 0, 1])]
assert pmul(ltop, bot) == pmul(top, lbot)
print(f"x(dual(phi(P))) = ({show(ltop)}) / ({show(lbot)}); x(2P) = ({show(top)}) / ({show(bot)})")
for m in [2, 3, 4, 5]:
    top, bot = xmult(m, -1, 0)
    d = max(len(top), len(bot)) - 1
    ev = lambda h, x: sum(c * x ** i for i, c in enumerate(h)) % 61     # a point mod 61, by chord and tangent
    Q = next(Q for Q in points(-1, 61) if ev(bot, Q[0]) and None not in (mult(m - 1, Q, -1, 61), mult(m + 1, Q, -1, 61)))
    assert d == m * m and gcd_deg(top, bot, 10007) == 0 and ev(top, Q[0]) * pow(ev(bot, Q[0]), 59, 61) % 61 == mult(m, Q, -1, 61)[0]
    print(f"[{m}]: top degree {len(top) - 1}, lead {top[-1]}; bottom degree {len(bot) - 1}, lead {bot[-1]};"
          f" coprime: yes; deg = {d}")
top, bot = xmult(2, 0, -2)                   # house point (3, 5): tangent slope 27/10, x(2P) = 27^2/10^2 - 6
t3, b3 = (sum(c * 3 ** i for i, c in enumerate(h)) for h in (top, bot))
assert t3 * 100 == b3 * (27 * 27 - 6 * 100)
print(f"house curve y^2 = x^3 - 2: x(2P) = ({show(top)}) / ({show(bot)}); at x = 3: {t3}/{b3}")
for m, p in [(3, 61), (4, 17), (3, 5)]:
    tors = [P for P in points(-1, p) if mult(m, P, -1, p) is None]
    orders = [1] + [min(n for n in range(1, m + 1) if mult(n, P, -1, p) is None) for P in tors]
    assert len(orders) == (m * m if p != 5 else 1)
    print(f"points P of E(F_{p}) with {m}P = O: {len(orders)}; by order " + ", ".join(
        f"{n}: {orders.count(n)}" for n in range(1, m + 1) if orders.count(n)))
n9, (t9, b9) = count2(3, 2), ([c % 3 for c in h] for h in xmult(3, -1, 0))   # F_9: s^2 = 2 = -1; x(3P) mod 3
assert n9 == 16 and t9[-1] and b9[0] and not any(b9[1:])  # mod 3 the bottom is a constant: lowest terms
print(f"char 3: #E(F_9) = {n9}, not divisible by 3, so its only point with 3P = O is O; x(3P) mod 3 = ({show(t9)}) / ({show(b9)}), deg[3] = {len(t9) - 1}")
p, a5, n25 = 5, 5 + 1 - counts[0], count2(5, 2)     # Hasse at p = 5; F_25 with s^2 = 2
form = lambda m, n: m * m - a5 * m * n + p * n * n
assert n25 == form(1, 1) * form(1, -1)
assert all(form(m, n) >= 0 for m in range(-9, 10) for n in range(-9, 10))
print(f"p = 5: a_5 = {a5}; deg(1 - pi) = #E(F_5) = {form(1, 1)}; additive guess deg 1 + deg pi = {1 + p}")
print(f"deg(m - n pi) = m^2 - ({a5})mn + 5n^2 >= 0 on -9..9; discriminant a_5^2 - 4p = {a5 * a5 - 4 * p}")
print(f"#E(F_25) by brute force {n25}; deg(1 - pi) deg(1 + pi) = {form(1, 1)} x {form(1, -1)} = {form(1, 1) * form(1, -1)}")
assert all((q + 1 - (len(points(-1, q)) + 1)) ** 2 <= 4 * q for q in [5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47])
print("Hasse a_p^2 <= 4p at every prime from 5 to 47: yes")
print("ALL CHECKS PASS")
