# Gauss sums: the quadratic Gauss sum mod 7 has size root seven -- the check behind the card.
# Nothing is imported: cos and sin are written out, so no library holds the answer.
# Road 1 adds the weighted roots of unity directly, two ways.  Road 2 squares the sum
# exactly in Z[zeta_p], with integer lists.  Road 3 is Parseval on the Legendre list.
# Road 4 deduces the sign from eigenvalue counts and a determinant (Schur), then
# compares it with the direct sum for every odd prime below 10,000.
PI = 3.14159265358979323846

def cs(t):                                      # (cos t, sin t) by Taylor series after reduction
    t = t - 2 * PI * ((t / (2 * PI) + 0.5) // 1)
    c, s, term, k = 0.0, 0.0, 1.0, 0
    while abs(term) > 1e-18:
        if k % 4 == 0: c += term
        elif k % 4 == 1: s += term
        elif k % 4 == 2: c -= term
        else: s -= term
        k += 1
        term = term * t / k
    return c, s

def sqrt(x):                                    # square root by Newton's method
    r = x if x > 1 else 1.0
    for _ in range(60): r = 0.5 * (r + x / r)
    return r

def f(x): return f"{x + 0.0:.9f}" if abs(x) > 5e-10 else "0.000000000"
def cx(z): return f"{f(z[0])} {'+' if z[1] >= -5e-10 else '-'} {f(abs(z[1]))}i"
def isprime(n): return n > 1 and all(n % d for d in range(2, int(n ** 0.5) + 1))
def leg(a, p): r = pow(a, (p - 1) // 2, p); return 0 if r == 0 else (1 if r == 1 else -1)
ROOTS = {}
def zeta(k, n):                                 # zeta_n^k = e^(2 pi i k / n), from a table built by
    if n not in ROOTS:                          # turning one step at a time, re-aimed every 64 steps
        t, c1, s1 = [], *cs(2 * PI / n)
        for j in range(n):
            if j % 64 == 0: c, s = cs(2 * PI * j / n)
            else: c, s = c * c1 - s * s1, c * s1 + s * c1
            t.append((c, s))
        ROOTS[n] = t
    return ROOTS[n][k % n]
def wsum(w, n, turn=1):                         # sum of w[a] zeta_n^(turn a), a = 0..n-1
    re = im = 0.0
    for a in range(n):
        if w[a]: c, s = zeta(turn * a, n); re += w[a] * c; im += w[a] * s
    return (re, im)
def sq_sum(n, skip0=False):                     # sum of zeta_n^(x^2), x = 0..n-1
    w = [0] * n
    for x in range(1 if skip0 else 0, n): w[x * x % n] += 1
    return wsum(w, n)
def size(z): return sqrt(z[0] ** 2 + z[1] ** 2)

p = 7
L = [leg(a, p) for a in range(p)]
print("Legendre symbol mod 7 by Euler's criterion, a = 1..6: " + " ".join("+" if v > 0 else "-" for v in L[1:]))
print("x^2 mod 7 for x = 0..6: " + " ".join(str(x * x % p) for x in range(p)))
for a in range(1, p): print(f"  a = {a}  zeta_7^a = {cx(zeta(a, p))}  weight {'+' if L[a] > 0 else '-'}1")
R = wsum([1 if v > 0 else 0 for v in L], p); N = wsum([1 if v < 0 else 0 for v in L], p)
g = wsum(L, p); g2 = sq_sum(p); r7 = sqrt(7.0)
print(f"sum over residues 1, 2, 4: {cx(R)};  over non-residues 3, 5, 6: {cx(N)}")
print(f"g = residues - non-residues: {cx(g)};  as sum of zeta^(x^2): {cx(g2)}")
print(f"sqrt 7 = {f(r7)};  |g|^2 = {f(g[0] ** 2 + g[1] ** 2)}")
assert abs(g[0]) < 1e-12 and abs(g[1] - r7) < 1e-12 and abs(g2[1] - g[1]) < 1e-12

def zmul(u, v, n):                              # exact product in Z[zeta_n], as lists mod x^n - 1
    w = [0] * n
    for i in range(n):
        if u[i]:
            for j in range(n): w[(i + j) % n] += u[i] * v[j]
    return w
def as_int(w):                                  # an element is an integer iff coefficients 1..n-1 agree
    return w[0] - w[1] if len(set(w[1:])) == 1 else None
print(f"exact in Z[zeta_7]: g^2 = {as_int(zmul(L, L, p))};  g times conj g = {as_int(zmul(L, [L[-a % p] for a in range(p)], p))}")
ok, cnt = True, 0
for q in range(3, 200):
    if isprime(q):
        Lq = [leg(a, q) for a in range(q)]; cnt += 1
        ok = ok and as_int(zmul(Lq, Lq, q)) == leg(q - 1, q) * q
print(f"exact g^2 = (-1/p) p for all {cnt} odd primes below 200: {'yes' if ok else 'no'}")
assert ok and as_int(zmul(L, L, p)) == -7

X = [wsum(L, p, k) for k in range(p)]           # Parseval road: transform of the Legendre list
ratio = [round(x[1] / g[1]) for x in X]
print("transform X_k over g, k = 0..6: " + " ".join(str(v) for v in ratio) + ";  (k/7): " + " ".join(str(v) for v in L))
e_in, e_out = sum(v * v for v in L), sum(x[0] ** 2 + x[1] ** 2 for x in X) / p
print(f"Parseval: sum (a/7)^2 = {e_in};  (1/7) sum |X_k|^2 = {f(e_out)};  so |g|^2 = 7 x {e_in} / {e_in}")
assert ratio == L and all(abs(x[0]) < 1e-12 for x in X) and abs(e_out - 6) < 1e-9
ind = {pow(3, k, p): k for k in range(6)}       # all six characters mod 7, from the primitive root 3
for j in range(6):
    re = im = 0.0
    for a in range(1, p): c1, s1 = cs(2 * PI * j * ind[a] / 6); c2, s2 = zeta(a, p); re += c1 * c2 - s1 * s2; im += c1 * s2 + s1 * c2
    print(f"  chi_{j} mod 7: g = {cx((re, im))},  |g|^2 = {f(re * re + im * im)}")
    assert abs(re * re + im * im - (1 if j == 0 else 7)) < 1e-9

def schur(q):                                   # the one (a, b, c, d) allowed by trace, size and determinant
    ab, cd, ph, out = (q + 1) // 2, (q - 1) // 2, (q * (q - 1) // 2) % 4, []
    for s in (-1, 0, 1):
        for t in (-1, 0, 1):
            if s * s + t * t == 1 and (ab + s) % 2 == 0 and (cd + t) % 2 == 0:
                a, b, c, d = (ab + s) // 2, (ab - s) // 2, (cd + t) // 2, (cd - t) // 2
                if (2 * (b + d) + c + d) % 4 == ph: out.append((a, b, c, d))
    return out
F2 = all(abs(sum(complex(*zeta(j * k, p)) * complex(*zeta(k * l, p)) for k in range(p)) - (p if (j + l) % p == 0 else 0)) < 1e-9 for j in range(p) for l in range(p))
print(f"Schur, mod 7: F^2 = 7 x reversal: {'yes' if F2 else 'no'};  det phase i^21 = i;  (m1, m2, m3, m4) = {schur(7)[0]};  g = i sqrt 7")
vok, vn = True, 0
for q in range(3, 50):
    if isprime(q):
        z = complex(1, 0); vn += 1
        for j in range(q):
            for k in range(j + 1, q): d = complex(*zeta(k, q)) - complex(*zeta(j, q)); z *= d / abs(d)
        vok = vok and abs(z - [1, 1j, -1, -1j][(q * (q - 1) // 2) % 4]) < 1e-9
print(f"Vandermonde det of F has phase i^(p(p-1)/2) for all {vn} odd primes below 50: {'yes' if vok else 'no'}")
assert F2 and vok and len(schur(7)) == 1
n1 = n3 = 0; ok = True
for q in range(3, 10000):
    if isprime(q):
        a, b, c, d = schur(q)[0]; z = sq_sum(q); rq = sqrt(float(q))
        ok = ok and len(schur(q)) == 1 and abs(z[0] - (a - b) * rq) < 1e-9 and abs(z[1] - (c - d) * rq) < 1e-9
        if q % 4 == 1: n1 += 1
        else: n3 += 1
print(f"odd primes below 10,000: {n1 + n3}; p = 1 mod 4: {n1}, p = 3 mod 4: {n3}; direct sum = Schur's sign every time: {'yes' if ok else 'no'}")
print(f"mod 5: g = {cx(sq_sum(5))};  sqrt 5 = {f(sqrt(5.0))}")
assert ok and n1 + n3 == 1228

bad = [("clockwise root e^(-2 pi i/7)", wsum(L, p, -1)), ("root zeta_7^3, 3 a non-residue", wsum(L, p, 3)),
       ("root zeta_7^2, 2 a residue", wsum(L, p, 2)), ("drop x = 0 from sum of zeta^(x^2)", sq_sum(p, True)),
       ("trivial character mod 7", wsum([0] + [1] * 6, p)), ("sum of zeta_6^(x^2), modulus 6", sq_sum(6)),
       ("sum of zeta_4^(x^2), modulus 4", sq_sum(4)),
       ("chi_2 mod 10, conductor 5", wsum([0, 1, 0, -1, 0, 0, 0, -1, 0, 1], 10)),
       ("mod 8 lifted from mod 4", wsum([0, 1, 0, -1, 0, 1, 0, -1], 8)),
       ("primitive (2/n) mod 8", wsum([0, 1, 0, -1, 0, -1, 0, 1], 8))]
for name, z in bad: print(f"  {name:<36} {cx(z):>28}  size {f(size(z))}")
assert abs(bad[0][1][1] + r7) < 1e-12 and abs(size(bad[3][1]) - sqrt(8.0)) < 1e-12 and size(bad[5][1]) < 1e-9
assert abs(size(bad[7][1]) - sqrt(5.0)) < 1e-9 and size(bad[8][1]) < 1e-9 and abs(size(bad[9][1]) - sqrt(8.0)) < 1e-9
print(f"sqrt 6 = {f(sqrt(6.0))};  sqrt 8 = {f(sqrt(8.0))};  sqrt 10 = {f(sqrt(10.0))}")
for q in (11, 13, 101): print(f"try: mod {q}, g = {cx(sq_sum(q))},  sqrt {q} = {f(sqrt(float(q)))}")

pts, z = [(0.0, 0.0)], (0.0, 0.0)
for a in range(1, p): c, s = zeta(a, p); z = (z[0] + L[a] * c, z[1] + L[a] * s); pts.append(z)
print("figure, walk " + " ".join(f"({x + 0.0:.3f},{y + 0.0:.3f})" for x, y in pts))
print("ALL CHECKS PASS")
