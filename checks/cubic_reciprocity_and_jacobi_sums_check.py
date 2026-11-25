# Cubic reciprocity and Jacobi sums: the check behind the card.  Standard library only.
# A pair (a, b) is the Eisenstein integer a + b*omega, with omega^2 = -1 - omega.
# Road 1 adds up the Jacobi sum J directly.  Road 2 cubes the Gauss sum exactly in Z[zeta_3p]
# and in floating point.  Road 3 decides "is 2 a cube mod p" three ways: every cube by brute
# force, J mod 2, and a search for p = x^2 + 27y^2.  Reciprocity and Gauss's quartic rule are counts.
import math

def primes(n):
    s = [1] * n; s[0] = s[1] = 0
    for i in range(2, int(n ** 0.5) + 1):
        if s[i]: s[i * i::i] = [0] * len(s[i * i::i])
    return [i for i in range(n) if s[i]]
def mul(x, y, m=0):                      # (a + b w)(c + d w), w^2 = -1 - w; reduced mod m if m
    a, b = x; c, d = y; r = (a * c - b * d, a * d + b * c - b * d)
    return (r[0] % m, r[1] % m) if m else r
def wpow(x, e, m):
    r = (1, 0)
    while e:
        if e & 1: r = mul(r, x, m)
        x, e = mul(x, x, m), e >> 1
    return r
def rep(p, k):                           # every (x, y), y >= 1, with p = x^2 + k y^2
    return [(math.isqrt(p - k * y * y), y) for y in range(1, math.isqrt(p // k) + 1) if math.isqrt(p - k * y * y) ** 2 == p - k * y * y]
def norm(x): return x[0] ** 2 - x[0] * x[1] + x[1] ** 2
def gen(p):                              # smallest primitive root mod p
    qs = [q for q in primes(p) if (p - 1) % q == 0]
    return next(g for g in range(2, p) if all(pow(g, (p - 1) // q, p) != 1 for q in qs))
def index(p):                            # discrete logs to the smallest primitive root
    g, ind, x = gen(p), [0] * p, 1
    for k in range(p - 1): ind[x] = k; x = x * g % p
    return g, ind
def jacobi(p, n=3):                      # J(chi, chi) as counts of each power of the n-th root
    g, ind = index(p); c = [0] * n
    for a in range(2, p): c[(ind[a] + ind[(1 - a) % p]) % n] += 1
    return c, g, ind
def jac3(p):
    c = jacobi(p)[0]; return (c[0] - c[2], c[1] - c[2])
W = [(1, 0), (0, 1), (-1, -1)]                       # 1, omega, omega^2
mod2 = lambda x: [((w[0] - x[0]) % 2, (w[1] - x[1]) % 2) for w in W].index((0, 0))   # J mod 2 as a power of omega
fmt = lambda x: f"{x[0]} + {x[1]} omega" if x[1] >= 0 else f"{x[0]} - {-x[1]} omega"

c, g7, ind7 = jacobi(7)
print(f"cubic character mod 7, generator {g7}: power of omega for a = 1..6:", [ind7[a] % 3 for a in range(1, 7)])
print("cubes mod 7:", sorted({x ** 3 % 7 for x in range(1, 7)}), " terms a = 2..6:", [(ind7[a] + ind7[(1 - a) % 7]) % 3 for a in range(2, 7)])
J7 = jac3(7); print(f"J(chi, chi) mod 7 = {fmt(J7)}, norm {norm(J7)}, a mod 3 = {J7[0] % 3}, b mod 3 = {J7[1] % 3}")
assert J7 == (-1, -3) and norm(J7) == 7

def gauss_cubed_exact(p):                # grid c[i][j] = coefficient of omega^i zeta^j
    _, ind = index(p); g = [[0] * p for _ in range(3)]
    for a in range(1, p): g[ind[a] % 3][a] += 1
    def times(x, y):
        z = [[0] * p for _ in range(3)]
        for i in range(3):
            for j in range(p):
                if x[i][j]:
                    for k in range(3):
                        for l in range(p): z[(i + k) % 3][(j + l) % p] += x[i][j] * y[k][l]
        return z
    z = times(times(g, g), g)
    for j in range(p): z[0][j] -= z[2][j]; z[1][j] -= z[2][j]; z[2][j] = 0
    for i in range(2): v = z[i][p - 1]; z[i] = [t - v for t in z[i]]
    return z
def gauss_float(p):
    _, ind = index(p)
    return sum(complex(math.cos(2 * math.pi * (ind[a] / 3 + a / p)), math.sin(2 * math.pi * (ind[a] / 3 + a / p))) for a in range(1, p))
cz = lambda x: complex(x[0] - x[1] / 2, x[1] * math.sqrt(3) / 2)
fc = lambda z: f"{z.real:.9f} {'+' if z.imag >= 0 else '-'} {abs(z.imag):.9f}i"
g = gauss_float(7)
print(f"g(chi) mod 7 = {fc(g)}, |g|^2 = {abs(g) ** 2:.9f}")
print(f"g^3 = {fc(g ** 3)}, 7J = {fc(7 * cz(J7))}")
assert abs(abs(g) ** 2 - 7) < 1e-9 and abs(g ** 3 - 7 * cz(J7)) < 1e-9
small, pts = [p for p in primes(100) if p % 3 == 1], {}
for p in small:
    z, J = gauss_cubed_exact(p), jac3(p)
    pts[p] = sum((x ** 3 + y ** 3) % p == 1 for x in range(p) for y in range(p))   # points on x^3 + y^3 = 1
    assert pts[p] == p - 2 + 2 * J[0] - J[1]
    assert z[0] == [p * J[0]] + [0] * (p - 1) and z[1] == [p * J[1]] + [0] * (p - 1) and not any(z[2])
print(f"exact: g^3 = pJ in Z[zeta_3p] for all {len(small)} primes p = 1 mod 3 below 100")
print(f"points on x^3 + y^3 = 1 mod p = p - 2 + 2a - b for all {len(small)}: p = 7: {pts[7]}, p = 31: {pts[31]}")
for p in (7, 13, 31):
    J, ind = jac3(p), index(p)[1]; L, M = abs(2 * J[0] - J[1]), abs(J[1]) // 3
    cubes = sorted({x ** 3 % p for x in range(1, p)})
    print(f"p = {p}: J = {fmt(J)}, 4p = {4 * p} = {L}^2 + 27*{M}^2, chi(2) = omega^{ind[2] % 3}, J mod 2 = omega^{mod2(J)}, 2 a cube: {2 in cubes}")
print(f"4^3 mod 31 = {4 ** 3 % 31}; x^3 = 2 mod 31 at x = {[x for x in range(31) if x ** 3 % 31 == 2]}; 31 = x^2 + 27y^2 at {rep(31, 27)}")
N = 10000; split = [p for p in primes(N) if p % 3 == 1]; agree = cube = 0
for p in split:
    J, ind = jac3(p), index(p)[1]; a, b = J
    reps = [(L, M) for M in range(1, math.isqrt(4 * p // 27) + 1) for L in range(1, math.isqrt(4 * p) + 1) if L * L + 27 * M * M == 4 * p]
    brute = 2 in {x ** 3 % p for x in range(1, p)}
    by_j = mod2(J) == ind[2] % 3                 # J = chi(2) mod 2
    form = bool(rep(p, 27))
    assert norm(J) == p and a % 3 == 2 and b % 3 == 0 and reps == [(abs(2 * a - b), abs(b) // 3)]
    agree += by_j and brute == (b % 2 == 0) == form == (ind[2] % 3 == 0); cube += brute
print(f"primes p = 1 mod 3 below {N}: {len(split)}; norm J = p, one 4p = L^2 + 27M^2, three tests agree: {agree}; 2 a cube: {cube}")
assert agree == len(split)

def chi(pi, alpha):                      # cubic residue character of alpha mod primary pi, as 0, 1, 2
    n = norm(pi); m = n if pi[1] else pi[0]
    v = wpow(alpha, (n - 1) // 3, m)
    if pi[1] == 0: return [((w[0] - v[0]) % m, (w[1] - v[1]) % m) for w in W].index((0, 0))
    r = -pi[0] * pow(pi[1], -1, m) % m   # omega -> r sends pi to 0 mod p
    return [(w[0] + w[1] * r - v[0] - v[1] * r) % m for w in W].index(0)
prim = [x for p in primes(200) if p % 3 == 1 for x in (jac3(p), (jac3(p)[0] - jac3(p)[1], -jac3(p)[1]))]
prim += [(q, 0) for q in primes(30) if q % 3 == 2]
pairs = [(s, t) for s in prim for t in prim if s < t and norm(s) != norm(t) and (s[1] or t[1])]   # skip two ordinary primes
same = sum(chi(s, t) == chi(t, s) for s, t in pairs)
print(f"cubic reciprocity, pi = J mod 7 and 2: chi_pi(2) = omega^{chi(J7, (2, 0))}, chi_2(pi) = omega^{chi((2, 0), J7)}")
print(f"cubic reciprocity on {len(pairs)} pairs of primary primes: {same} agree")
assert same == len(pairs) == 1092 and chi(J7, (2, 0)) == chi((2, 0), J7) == 2
c4, g73, _ = jacobi(73, 4); J4 = (c4[0] - c4[2], c4[1] - c4[3])
print(f"quartic J mod 73, generator {g73}: {J4[0]} + {J4[1]}i, norm {J4[0] ** 2 + J4[1] ** 2}; 73 = 3^2 + 64*1^2; x^4 = 2 mod 73 at x =", [x for x in range(1, 73) if pow(x, 4, 73) == 2])
q4 = [p for p in primes(N) if p % 4 == 1]
four = [2 in {pow(x, 4, p) for x in range(1, p)} for p in q4]
form4 = [bool(rep(p, 64)) for p in q4]
print(f"primes p = 1 mod 4 below {N}: {len(q4)}; 2 a fourth power: {sum(four)}; p = x^2 + 64y^2: {sum(form4)}; agree: {sum(map(lambda u, v: u == v, four, form4))}")
assert four == form4
if N == 10000: assert (len(split), cube, len(q4), sum(four)) == (611, 200, 609, 143)   # the counts on the card
def jsum(p, f, g):                       # sum over t = 0..p-1 of f(t) g(1 - t); f, g give a power of omega, or None for 0
    ws = [W[(f(t) + g((1 - t) % p)) % 3] for t in range(p) if f(t) is not None and g((1 - t) % p) is not None]
    return (sum(w[0] for w in ws), sum(w[1] for w in ws))
chi7, chibar = (lambda t: ind7[t] % 3 if t else None), (lambda t: 2 * ind7[t] % 3 if t else None)
triv, chi1 = (lambda t: 0 if t else None), (lambda t: ind7[t] % 3 if t else 0)   # chi1 counts chi(0) as 1
Jt, Jbar, J0 = jsum(7, triv, triv), jsum(7, chi7, chibar), jsum(7, chi1, chi1)
print(f"break: trivial character mod 7, J = {Jt[0]}, norm {norm(Jt)}; J(chi, chi-bar) = {fmt(Jbar)}, norm {norm(Jbar)}")
print(f"break: chi(0) = 1 counted, J + 2 = {fmt(J0)}, norm {norm(J0)}")
assert jsum(7, chi7, chi7) == J7 and Jt == (7 - 2, 0) and Jbar == (-1, 0) and J0 == (J7[0] + 2, J7[1])
x3 = rep(7, 3)
c11 = {x ** 3 % 11 for x in range(1, 11)}; f17 = sorted({pow(x, 4, 17) for x in range(1, 17)})
print(f"break: 7 = x^2 + 3y^2 at {x3}, yet 2 is no cube mod 7; mod 11 every one of {len(c11)} is a cube, 7^3 mod 11 = {7 ** 3 % 11}")
print(f"break: 17 = 1^2 + 16*1^2, fourth powers mod 17: {f17}")
k1, k2 = chi(J7, (5, 0)), chi((5, 0), mul((0, 1), J7))
print(f"break: non-primary omega*pi mod 7 and 5: chi_pi(5) = omega^{k1}, chi_5(omega pi) = omega^{k2}")
assert x3 == [(2, 1)] and len(c11) == 10 and 2 not in f17 and k1 != k2 == (k1 + 2) % 3
print("figure, norm 7:", " ".join(f"({cz(x).real:.3f},{cz(x).imag:.3f})" for x in sorted((a, b) for a in range(-4, 5) for b in range(-4, 5) if norm((a, b)) == 7)))
print("ALL CHECKS PASS")
