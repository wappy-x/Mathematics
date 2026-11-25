# Hecke operators and eigenforms -- the check behind the card.  Standard library
# only.  Here q = e^(2 pi i z), never a modulus, and tau(n) is Ramanujan's.
from math import pi, exp, cos, sin, sqrt, gcd, floor, log10
L = 130                                    # every series is kept to q^L

def product(parts):                        # q * prod over n of (1 - q^(c n))^e
    P = [1] + [0] * L
    for c, e in parts:
        for n in range(1, L // c + 1):
            for _ in range(e):
                for i in range(L, c * n - 1, -1): P[i] -= P[i - c * n]
    return [0] + P[:L]

def mul(a, b): return [sum(a[i] * b[n - i] for i in range(n + 1)) for n in range(L + 1)]
def sigma(k, n): return sum(d ** k for d in range(1, n + 1) if n % d == 0)
def yn(b): return "yes" if b else "no"
def primes(n): return [p for p in range(2, n + 1) if all(p % d for d in range(2, p))]

def T(a, n, k, N=1):                       # Hecke T_n on coefficients, weight k, level N
    return [sum(d ** (k - 1) * a[m * n // (d * d)] for d in range(1, n + 1)
                if m % d == 0 and n % d == 0 and gcd(d, N) == 1) for m in range((len(a) - 1) // n + 1)]

def cexp(w): return complex(exp(w.real) * cos(w.imag), exp(w.real) * sin(w.imag))
def ev(a, z, top):                         # sum of a[n] q^n for n <= top, by Horner
    q, s = cexp(2j * pi * z), 0j
    for n in range(top, 0, -1): s = (s + a[n]) * q
    return s
def show(w): return f"{w.real:.9f} {'+' if w.imag >= 0 else '-'} {abs(w.imag):.9f}i"
def sci(x): e = floor(log10(abs(x))); return f"{x / 10 ** e:.7f}e{e}"

def matrix_average(a, n, k, z):            # road 2: average f over (a b; 0 d), ad = n, 0 <= b < d
    s = 0j
    for d in range(1, n + 1):
        if n % d == 0:
            for b in range(d): s += ev(a, ((n // d) * z + b) / d, L) * (n ** (k - 1) / d ** k)
    return s

sl2 = [(a, b, c, d) for a in range(11) for b in range(11) for c in range(11) for d in range(11) if (a * d - b * c) % 11 == 1]
g0 = [m for m in sl2 if m[2] == 0]
print(f"Gamma_0(11): {len(sl2)} matrices in SL2(Z mod 11), {len(g0)} with c = 0; index {len(sl2) // len(g0)}")
def span(v, w, n): return frozenset(((i * v[0] + j * w[0]) % n, (i * v[1] + j * w[1]) % n) for i in range(n) for j in range(n))
lat = [{S for v in range(n * n) for w in range(n * n) for S in [span(divmod(v, n), divmod(w, n), n)] if len(S) == n} for n in range(2, 7)]
reps = [{span((n // d, b), (0, d), n) for d in range(1, n + 1) if n % d == 0 for b in range(d)} for n in range(2, 7)]
print("classes of determinant-n matrices (row lattices of index n), n = 2..6:", [len(x) for x in lat],
      "; classes holding a (u b; 0 d), 0 <= b < d:", [len(x) for x in reps], "; sigma_1(n):", [sigma(1, n) for n in range(2, 7)])

tau = product([(1, 24)])
print("tau(1..12):", tau[1:13])
print("T_2 Delta starts:", T(tau, 2, 12)[1:6], "; -24 x Delta starts:", [-24 * t for t in tau[1:6]])
eig = all(T(tau, n, 12)[:21] == [tau[n] * t for t in tau[:21]] for n in range(2, 7))
print(f"T_n Delta = tau(n) Delta to q^20 for n = 2..6: {yn(eig)}")
z = complex(0.3, 1.1)
for n in (2, 3):
    print(f"z = {z.real} + {z.imag}i, n = {n}: matrix average x 1000 = {show(1000 * matrix_average(tau, n, 12, z))}; "
          f"tau(n) Delta(z) x 1000 = {show(1000 * tau[n] * ev(tau, z, L))}")

s = [(7 * m * m + 3 * m) % 13 - 6 for m in range(L + 1)]   # an arbitrary series, weight 12
print("arbitrary series s starts:", s[1:9])
print(f"T_2 T_3 s = T_6 s = T_3 T_2 s to q^20: {yn(T(T(s, 3, 12), 2, 12)[:21] == T(s, 6, 12)[:21] == T(T(s, 2, 12), 3, 12)[:21])}")
t22, t4 = T(T(s, 2, 12), 2, 12), T(s, 4, 12)
print(f"T_2 T_2 s = T_4 s + 2^11 s to q^30: {yn(all(t22[m] == t4[m] + 2048 * s[m] for m in range(31)))}; "
      f"mistake, T_2 T_2 = T_4: at q^1 {t22[1]} against {t4[1]}")

def hecke_rules(a, k, N, top):             # coprime pairs and prime-power steps up to top
    cop = pp = 0
    for m in range(2, top + 1):
        for n in range(m + 1, top // m + 1):
            if gcd(m, n) == 1: assert a[m * n] == a[m] * a[n]; cop += 1
    for p in primes(top):
        if N % p:
            r = p
            while r * p <= top: assert a[r * p] == a[p] * a[r] - p ** (k - 1) * a[r // p]; pp += 1; r *= p
    return cop, pp
print("Delta, coprime pairs and prime-power steps to q^130, all hold:", hecke_rules(tau, 12, 1, L))
print(f"tau(6) = {tau[6]} = ({tau[2]})({tau[3]});  tau(4) = {tau[2] ** 2} - {2 ** 11} = {tau[4]}")

f = product([(1, 2), (11, 2)])            # eta(z)^2 eta(11z)^2, level 11, weight 2
print("level 11, a(1..12):", f[1:13])
ps = [p for p in primes(47) if p != 11]
cnt = [p - sum(1 for x in range(p) for y in range(p) if (y * y + y - x ** 3 + x * x + 10 * x + 20) % p == 0) for p in ps]
print("a_p, p = 2..47 but 11:          ", [f[p] for p in ps])
print("p minus points of y^2 + y = x^3 - x^2 - 10x - 20 mod p:", cnt)
print(f"level 11: a6 = {f[6]} = a2 a3, a4 = {f[2] ** 2} - 2 = {f[4]}, a9 = {f[3] ** 2} - 3 = {f[9]}, a11 = {f[11]}, a121 = {f[121]}")
print("level 11, coprime pairs and prime-power steps (p not 11) to q^130, all hold:", hecke_rules(f, 2, 11, L))
print(f"mistake, a121 = a11^2 - 11 as if 11 were good: {f[11] ** 2 - 11}, against {f[121]}")
w = 2 * ev(f, 2 * z, L) + (ev(f, z / 2, L) + ev(f, (z + 1) / 2, L)) / 2
print(f"level 11 at z: 2 f(2z) + (f(z/2) + f((z+1)/2))/2 = {show(w)}; -2 f(z) = {show(-2 * ev(f, z, L))}")
h = product([(4, 2), (8, 2)])             # the house curve y^2 = x^3 - x, level 32
print(f"level 32: a3 = {h[3]}, a5 = {h[5]}, a9 = {h[9]} = a3^2 - 3, a25 = {h[25]} = a5^2 - 5, a45 = {h[45]} = a9 a5")

E4 = [1] + [240 * sigma(3, n) for n in range(1, L + 1)]
g1, g2 = mul(tau, mul(E4, mul(E4, E4)))[:41], mul(tau, tau)[:41]   # basis of S_24, to q^40
print("S_24: g1 = Delta E4^3 starts", g1[1:5], "; g2 = Delta^2 starts", g2[1:5])
def coords(g):                             # g = x g1 + y g2, checked on every coefficient
    x = g[1]; y = g[2] - x * g1[2]; assert all(g[i] == x * g1[i] + y * g2[i] for i in range(len(g))); return x, y
def mat(n): c1, c2 = coords(T(g1, n, 24)), coords(T(g2, n, 24)); return [[c1[0], c2[0]], [c1[1], c2[1]]]
def mm(A, B): return [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
A2, A3, A6 = mat(2), mat(3), mat(6)
print("T_2 on (g1, g2), columns are images:", A2, "; T_3:", A3)
print(f"T_2 T_3 = T_3 T_2 = T_6 as matrices: {yn(mm(A2, A3) == mm(A3, A2) == A6)}")
tr, det = A2[0][0] + A2[1][1], A2[0][0] * A2[1][1] - A2[0][1] * A2[1][0]
disc = tr * tr - 4 * det; D = 144169
print(f"T_2: trace {tr}, det {det}, discriminant {disc} = 24^2 x {D}; eigenvalues 540 +/- 12 r, r = sqrt({D}): "
      f"{540 + 12 * sqrt(D):.6f}, {540 - 12 * sqrt(D):.6f}")
def zm(u, v): return (u[0] * v[0] + D * u[1] * v[1], u[0] * v[1] + u[1] * v[0])   # x + y r
ef = [(g1[n] - 156 * g2[n], 12 * g2[n]) for n in range(41)]   # g1 + (-156 + 12 r) g2
print(f"eigenform a(2) = {ef[2]}, a(3) = {ef[3]}, as (x, y) meaning x + y r")
okT = all(T([e[i] for e in ef], n, 24)[:13] == [zm(ef[n], e)[i] for e in ef[:13]] for n in (2, 3) for i in (0, 1))
print(f"T_2 and T_3 fix it up to a(n), to q^12: {yn(okT)}; a(6) = a(2) a(3) = {zm(ef[2], ef[3])}: {yn(zm(ef[2], ef[3]) == ef[6])}")

NX, NT, TOP = 240, 1200, 16                # Simpson over x in [-1/2, 1/2], y = sqrt(1 - x^2) + t, t in [0, 6]
G, B = [[0.0, 0.0], [0.0, 0.0]], [[0.0, 0.0], [0.0, 0.0]]   # B: the mistake, y^20 for y^22
for i in range(NX + 1):
    x = -0.5 + i / NX; wx = 1 if i in (0, NX) else (4 if i % 2 else 2)
    for j in range(NT + 1):
        y = sqrt(1 - x * x) + 6 * j / NT; wt = 1 if j in (0, NT) else (4 if j % 2 else 2)
        u, v = ev(g1, complex(x, y), TOP), ev(g2, complex(x, y), TOP)
        for W, e in ((G, 22), (B, 20)):
            m = wx * wt * y ** e / (9 * NX * NT) * 6
            W[0][0] += m * abs(u) ** 2; W[1][1] += m * abs(v) ** 2; W[0][1] += m * (u * v.conjugate()).real
G[1][0], B[1][0] = G[0][1], B[0][1]
print(f"Petersson <g1,g1> = {sci(G[0][0])}, <g1,g2> = {sci(G[0][1])}, <g2,g2> = {sci(G[1][1])}")
def adj(W): return A2[0][0] * W[0][1] + A2[1][0] * W[1][1], A2[0][1] * W[0][0] + A2[1][1] * W[0][1]
(l, r), (lb, rb) = adj(G), adj(B)
print(f"<T_2 g1, g2> = {sci(l)}; <g1, T_2 g2> = {sci(r)}; naive coefficient pairing gives {A2[1][0]} against {A2[0][1]}")
print(f"mistake, y^20 in place of y^22: {sci(lb)} against {sci(rb)}")
vp, vm = (1, -156 + 12 * sqrt(D)), (1, -156 - 12 * sqrt(D))
def ip(a, b): return sum(a[i] * G[i][j] * b[j] for i in range(2) for j in range(2))
cosP, cosN = ip(vp, vm) / sqrt(ip(vp, vp) * ip(vm, vm)), (1 + vp[1] * vm[1]) / sqrt((1 + vp[1] ** 2) * (1 + vm[1] ** 2))
print(f"the two eigenforms: Petersson cosine below 1e-6: {yn(abs(cosP) < 1e-6)}; naive coordinate cosine {cosN:.6f}")

assert len(sl2) // len(g0) == 12
assert lat == reps and [len(x) for x in lat] == [sigma(1, n) for n in range(2, 7)]
assert eig and tau[6] == tau[2] * tau[3] == -6048 and tau[4] == tau[2] ** 2 - 2 ** 11 == -1472
assert abs(matrix_average(tau, 3, 12, z) - 252 * ev(tau, z, L)) < 1e-9 * abs(252 * ev(tau, z, L))
assert t22[1] != t4[1] and cnt == [f[p] for p in ps] and abs(w + 2 * ev(f, z, L)) < 1e-12
assert (f[6], f[4], f[9]) == (2, 2, -2) and f[121] == f[11] ** 2 and mm(A2, A3) == A6 and disc == 576 * D
assert (h[9], h[25], h[45]) == (h[3] ** 2 - 3, h[5] ** 2 - 5, h[9] * h[5]) == (-3, -1, 6)
assert okT and abs(l - r) < 1e-6 * abs(l) and abs(lb - rb) > 0.1 * abs(lb) and abs(cosP) < 1e-6
print("ALL CHECKS PASS")
