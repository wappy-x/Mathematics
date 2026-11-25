# Free resolutions and Tor -- the check behind the card.  Nothing is imported.  Over Z,
# tensoring a free resolution with N = Z/n turns each Z^k into (Z/n)^k and keeps the
# integer matrices, so every kernel and image is found by listing all vectors.  Over
# Q[x], multiplication by f on Q[x]/(g) is an integer matrix with an exact rank.

def vectors(k, n):                          # every vector of (Z/n)^k
    return [[]] if k == 0 else [v + [a] for v in vectors(k - 1, n) for a in range(n)]

def apply(mat, v, n):                       # a matrix (list of rows) times v, mod n
    return tuple(sum(a * b for a, b in zip(row, v)) % n for row in mat)

def kernel(mat, k, n):                      # the vectors a matrix sends to 0, and all it hits
    return [v for v in vectors(k, n) if not any(apply(mat, v, n))]
def image(mat, k, n):
    return {apply(mat, v, n) for v in vectors(k, n)}

def matmul(a, b):
    return [[sum(x * y for x, y in zip(row, col)) for col in zip(*b)] for row in a]

def tor(ranks, ds, n):                      # sizes of Tor_0, Tor_1, ... against Z/n
    sizes = []
    for i, k in enumerate(ranks):
        d_out = ds[i - 1] if i > 0 else []                    # d_i : F_i -> F_(i-1)
        d_in, k_in = (ds[i], ranks[i + 1]) if i < len(ds) else ([[]] * k, 0)
        sizes.append(len(kernel(d_out, k, n)) // len(image(d_in, k_in, n)))
    return sizes

def gcd(*xs):                               # Euclid's algorithm, over a whole list
    a = 0
    for b in xs:
        while b:
            a, b = b, a % b
    return abs(a)

def pmul(a, b):                             # polynomials: coefficient lists, constant first
    return [sum(a[i] * b[k - i] for i in range(len(a)) if 0 <= k - i < len(b))
            for k in range(len(a) + len(b) - 1)]

def pmod(a, g):                             # remainder on dividing by the monic g
    a = a[:]
    while len(a) >= len(g):
        c = a.pop()
        for i in range(len(g) - 1):
            a[len(a) - len(g) + 1 + i] -= c * g[i]
    return a + [0] * (len(g) - 1 - len(a))

def mulmat(f, g):                           # multiplication by f on Q[x]/(g), basis 1, x, ...
    cols = [pmod(pmul([0] * j + [1], f), g) for j in range(len(g) - 1)]
    return [[c[i] for c in cols] for i in range(len(g) - 1)]

def rank(m):                                # fraction-free elimination over the integers
    m, r = [row[:] for row in m], 0
    for c in range(len(m[0])):
        p = next((i for i in range(r, len(m)) if m[i][c]), None)
        if p is None: continue
        m[r], m[p] = m[p], m[r]
        for i in range(r + 1, len(m)):
            m[i] = [m[r][c] * x - m[i][c] * y for x, y in zip(m[i], m[r])]
        r += 1
    return r

def prim(a):                                # drop top zeros and the content; lead positive
    while a and a[-1] == 0:
        a.pop()
    return [x // gcd(*a) * (1 if a[-1] > 0 else -1) for x in a] if a else []

def pgcd(a, b):                             # Euclid with pseudo-remainders
    a, b = prim(a[:]), prim(b[:])
    while b:
        r = a[:]
        while len(r) >= len(b):
            k, lr = len(r) - len(b), r[-1]
            r = prim([b[-1] * x - lr * (b[j - k] if j >= k else 0) for j, x in enumerate(r)])
        a, b = b, r
    return a

def show(p):                                # a polynomial, leading term first
    s = ""
    for e in range(len(p) - 1, -1, -1):
        if p[e]:
            body = (str(abs(p[e])) if abs(p[e]) != 1 or e == 0 else "") + ("x" * (e > 0)) + (f"^{e}" * (e > 1))
            s += ((" - " if p[e] < 0 else " + ") if s else "-" * (p[e] < 0)) + body
    return s

dA, dB1, dB2 = [[4]], [[4, 4]], [[1], [-1]]
tA, tB, tN = tor([1, 1], [dA], 6), tor([1, 2, 1], [dB1, dB2], 6), tor([1, 1], [[[6]]], 4)
lost = [v[0] for v in kernel(dA, 1, 6)]
exactB = matmul(dB1, dB2) == [[0]] and all(b == -a for a in range(-12, 13) for b in range(-12, 13) if 4 * a + 4 * b == 0)
PHI1, PSI1, H1 = [[1], [0]], [[1, 1]], [[0, -1]]
one_minus_phipsi = [[int(i == j) - x for j, x in enumerate(row)] for i, row in enumerate(matmul(PHI1, PSI1))]
chain = [matmul(dB1, PHI1) == dA, matmul(dA, PSI1) == dB1, matmul(PSI1, PHI1) == [[1]]]
homotopy = [one_minus_phipsi == matmul(dB2, H1), matmul(H1, dB2) == [[1]]]
cls = apply(PHI1, [3], 6)
sweep = all(len(kernel([[m]], 1, n)) == gcd(m, n) == len(kernel([[n]], 1, m)) == n // len(image([[m]], 1, n))
            for m in range(1, 13) for n in range(1, 13))
D2 = [[1, 1], [1, -1], [-1, -1]]            # Klein bottle: rows edges a, b, c; columns triangles U, L
minors = [D2[i][0] * D2[j][1] - D2[i][1] * D2[j][0] for i in range(3) for j in range(i + 1, 3)]
g1, g2 = gcd(*sum(D2, [])), gcd(*minors)
klein_mod2, klein_tor, klein_tensor = len(kernel(D2, 2, 2)), len(kernel([[2]], 1, 2)), 2 ** (2 - rank(D2))  # H_2(Z) = Z^(2 - rank)
f, g = [-1, 0, 1], [2, -3, 1]
Mf, Mg = mulmat(f, g), mulmat(g, f)
dim1, dim1_other, h = 2 - rank(Mf), 2 - rank(Mg), pgcd(f, g)
v = [-2, 1]
kills, acts_as_1 = pmod(pmul(v, f), g) == [0, 0], pmod(pmul([0, 1], v), g) == v
wrong1 = [a for a in range(3) if 4 * a % 6 == 0]                   # Z/3 --x4--> Z/6
exact_wrong = sorted({4 * a % 12 for a in range(3)}) == [b for b in range(12) if b % 4 == 0]
wrong2 = len([a for a in range(6) if a % 2 == 0]) // len({4 * a % 6 for a in range(6)})
yn, name = lambda c: "yes" if c else "no", lambda size: "0" if size == 1 else f"Z/{size}"
print("M = Z/4, N = Z/6, over Z")
print(f"resolution A, 0 -> Z --x4--> Z: Tor_0 = {name(tA[0])}, Tor_1 = {name(tA[1])}")
print(f"  Tor_1 is the kernel of x4 on Z/6: {lost}; its image is {sorted(t[0] for t in image(dA, 1, 6))}")
print(f"resolution B, 0 -> Z --(1, -1)--> Z^2 --(4 4)--> Z: d1 d2 = 0 and exact on |a|, |b| <= 12: {yn(exactB)}")
print(f"  tensored with Z/6: kernel of (4 4) has {len(kernel(dB1, 2, 6))} elements, image of (1, -1) has {len(image(dB2, 1, 6))}")
print(f"  Tor_0 = {name(tB[0])}, Tor_1 = {name(tB[1])}, Tor_2 = {name(tB[2])}")
print(f"resolve Z/6 instead, tensor with Z/4: kernel of x6 on Z/4 {[v[0] for v in kernel([[6]], 1, 4)]}; Tor_0 = {name(tN[0])}, Tor_1 = {name(tN[1])}")
print(f"gcd(4, 6) = {gcd(4, 6)}")
print(f"comparison maps phi1 = (1, 0), psi1 = (1, 1): chain maps {yn(chain[0])}, {yn(chain[1])}; psi1 phi1 = 1: {yn(chain[2])}")
print(f"  1 - phi1 psi1 = d2 h1 and 1 - phi2 psi2 = h1 d2, with h1 = (0, -1): {yn(homotopy[0])}, {yn(homotopy[1])}")
print(f"  phi1 sends the Tor_1 class 3 to {cls}, outside the image of (1, -1): {yn(cls not in image(dB2, 1, 6))}")
print(f"sweep m, n = 1 to 12: kernel = other side = cokernel = gcd(m, n), all 144 pairs: {yn(sweep)}")
print(f"Klein bottle: d2 = {D2}; 2 by 2 minors {minors}")
print(f"  invariant factors {g1}, {g2 // g1}, so H_1 = Z + Z/2; a minor is nonzero, so H_2 over Z = 0")
print(f"  H_2 with Z/2 coefficients, by listing chains: {klein_mod2} elements, so {name(klein_mod2)}")
print(f"  universal coefficients: 0 + Tor_1(Z/2, Z/2), and Tor_1(Z/2, Z/2) has {klein_tor} elements")
print(f"over Q[x]: f = {show(f)}, g = {show(g)}")
print(f"  multiplication by f on Q[x]/(g), basis 1, x: {Mf}, rank {rank(Mf)}")
print(f"  Tor_1 dimension {dim1}, Tor_0 dimension {2 - rank(Mf)}; resolving the other side: {dim1_other}")
print(f"  gcd(f, g) by Euclid: {show(h)}, degree {len(h) - 1}")
print(f"  {show(v)} spans the kernel: f({show(v)}) = 0 mod g: {yn(kills)}; x acts on it as 1: {yn(acts_as_1)}")
print(f"mistake 1, non-free 0 -> Z/3 --x4--> Z/12 (exact: {yn(exact_wrong)}) tensored with Z/6: kernel {wrong1}, Tor_1 reads 0")
print(f"mistake 2, keeping Z/4 in the tensored sequence: Tor_0 reads {name(wrong2)}, truth {name(tA[0])}")
print(f"mistake 3, Z/4 x Z/6 taken as Z/24: {4 * 6} elements, truth {tA[0]}")
print(f"mistake 4, Klein H_2 mod 2 by tensoring only: {name(klein_tensor)}, truth {name(klein_mod2)}")
assert tA[1] == tB[1] == tN[1] == gcd(4, 6) and tA[0] == tB[0] == tN[0] == gcd(4, 6)   # three resolutions, one Tor
assert tB[2] == 1 and lost == [0, 3] and exactB                                       # Tor_2 = 0; kernel {0, 3}
assert all(chain) and all(homotopy) and cls not in image(dB2, 1, 6)                    # comparison is an isomorphism
assert sweep and klein_mod2 == klein_tor == g2 // g1 == 2                               # gcd rule; universal coefficients
assert dim1 == dim1_other == len(h) - 1 == 1 and kills and acts_as_1                   # Q[x]: matrix, other side, Euclid
assert wrong1 == [0] and exact_wrong and wrong2 == 1 and klein_tensor == 1           # the mistakes really differ
print("ALL CHECKS PASS")
