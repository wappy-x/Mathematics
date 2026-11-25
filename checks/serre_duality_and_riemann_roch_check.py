# Serre duality and Riemann-Roch -- the check behind the card.  Standard library only.
# Road 1: Cech cohomology of O(d) on P^n by exact ranks, one Laurent monomial x^a at a time.
# Road 2: closed counts of monomials.  Road 3: a curve's points over F_13, and the rank of forms on them.
from itertools import combinations, product
from math import comb, gcd

def rank(rows, p=0):                                   # exact rank: over Q (p = 0) or over F_p
    M = [r[:] for r in rows]; r = 0
    for c in range(len(M[0]) if M else 0):
        q = next((i for i in range(r, len(M)) if (M[i][c] % p if p else M[i][c])), None)
        if q is None: continue
        M[r], M[q] = M[q], M[r]
        for i in range(r + 1, len(M)):
            M[i] = [M[r][c] * x - M[i][c] * y for x, y in zip(M[i], M[r])]
            g = 0
            for x in M[i]: g = gcd(g, x)
            M[i] = [x % p if p else x // max(g, 1) for x in M[i]]
        r += 1
    return r

def face(J, I):                                        # sign of I inside J in the Cech differential
    for k in range(len(J)):
        if J[:k] + J[k + 1:] == I: return (-1) ** k
    return 0

def cech(n, d):                                        # h^0..h^n of O(d) on P^n from the n + 1 standard charts
    B, h, top = abs(d) + n + 1, [0] * (n + 1), {0: [], n: []}
    for head in product(range(-B, B + 1), repeat=n):
        a = head + (d - sum(head),)                    # the monomial x_0^a_0 ... x_n^a_n of degree d
        if abs(a[-1]) > B: continue
        neg = {j for j in range(n + 1) if a[j] < 0}    # it lives on the overlaps U_I with I containing neg
        cells = [[I for I in combinations(range(n + 1), p + 1) if neg <= set(I)] for p in range(n + 1)]
        rk = [0] * (n + 2)                             # rk[p]: rank of the Cech map C^(p-1) -> C^p
        for p in range(1, n + 1):
            if cells[p - 1] and cells[p]:
                rk[p] = rank([[face(J, I) for I in cells[p - 1]] for J in cells[p]])
        for p in range(n + 1):
            k = len(cells[p]) - rk[p] - rk[p + 1]
            h[p] += k
            if k and p in top: top[p].append(a)
    return h, top

H, RANGE = {}, {1: (-5, 3), 2: (-8, 5), 3: (-5, 1)}   # each range is symmetric under d -> -d - n - 1
for n, (lo, hi) in RANGE.items():
    for d in range(lo, hi + 1): H[n, d] = cech(n, d)
    for i in range(n + 1):
        print(f"P^{n}, h^{i}(O(d)) for d = {lo}..{hi}: {[H[n, d][0][i] for d in range(lo, hi + 1)]}")
closed = lambda n, d, i: comb(d + n, n) if i == 0 and d >= 0 else comb(-d - 1, n) if i == n and d <= -n - 1 else 0
assert all(H[n, d][0][i] == closed(n, d, i) for n, d in H for i in range(n + 1))
print(f"Cech ranks against the monomial counts C(d + n, n) and C(-d - 1, n): agree at all {len(H)} (n, d)")
ok = [H[n, d][0][i] == H[n, -d - n - 1][0][n - i] for n, d in H for i in range(n + 1)]
bad = [H[n, d][0][i] != H[n, -d - n][0][n - i] for n, d in H if (n, -d - n) in H for i in range(n + 1)]
print(f"Serre duality, K = O(-n - 1): h^i(O(d)) = h^(n-i)(O(-d - n - 1)) at {sum(ok)} of {len(ok)} (n, d, i)")
print(f"mistake, K = O(-n): {sum(bad)} of {len(bad)} (n, d, i) fail")
assert all(ok) and any(bad)
sizes = []
for n, d in H:                                         # the Cech pairing H^0(O(d)) x H^n(O(-d-n-1)) -> H^n(K)
    A, Bd = H[n, d][1][0], H[n, -d - n - 1][1][n]
    if A:
        M = [[int(all(x + y == -1 for x, y in zip(a, b))) for b in Bd] for a in A]
        assert len(A) == len(Bd) == rank(M); sizes.append(len(A))
print(f"Cech pairing, x^a times x^b lands on 1/(x_0...x_n) exactly when b = -1 - a: perfect at {len(sizes)} (n, d), sizes up to {max(sizes)} x {max(sizes)}")
A, Bd = H[1, 1][1][0], H[1, -3][1][1]
print(f"P^1: H^0(O(1)) has exponents {A}, H^1(O(-3)) has {Bd}")
print(f"P^1: pairing matrix {[[int(all(x + y == -1 for x, y in zip(a, b))) for b in Bd] for a in A]}, so h^1(O(-3)) = {len(Bd)} = h^0(O(1))")
print(f"mistake, pair H^1(O(-3)) with H^0 of the dual O(3) alone: {H[1, 3][0][0]}, not {len(Bd)}")
hP = lambda i, m: H[2, m][0][i]                        # plane curve C of degree d: 0 -> O(m - d) -> O(m) -> O_C(m) -> 0
h0C = lambda d, m: hP(0, m) - hP(0, m - d)             # the H^1 terms of P^2 are 0, as printed above
h1C = lambda d, m: hP(2, m - d) - hP(2, m)
mon = lambda d, m: sum(1 for i in range(m + 1) for j in range(m + 1 - i) if m - i - j < d)   # z-power below d
gs = [h1C(d, 0) for d in range(1, 6)]
print(f"plane curves x^d + y^d + z^d, d = 1..5: genus h^1(O_C) = h^2(O(-d)) - h^2(O) = {gs}; (d-1)(d-2)/2 = {[(d - 1) * (d - 2) // 2 for d in range(1, 6)]}")
print(f"deg K = d(d - 3) = {[d * (d - 3) for d in range(1, 6)]}; 2g - 2 = {[2 * g - 2 for g in gs]}")
assert gs == [(d - 1) * (d - 2) // 2 for d in range(1, 6)] and all(d * (d - 3) == 2 * gs[d - 1] - 2 for d in range(1, 6))
pairs = [(d, m) for d in range(1, 6) for m in range(-3, 6)]
dual = all(h1C(d, m) == h0C(d, d - 3 - m) for d, m in pairs)
chi = all(h0C(d, m) - h1C(d, m) == m * d + 1 - gs[d - 1] for d, m in pairs)
rr = all(h0C(d, m) - h0C(d, d - 3 - m) == m * d + 1 - gs[d - 1] for d, m in pairs)
mons = all(h0C(d, m) == mon(d, m) for d, m in pairs if m >= 0)
print(f"on C, D = m times a line section, m = -3..5: duality h^1(O_C(D)) = h^0(O_C(K - D)) at all {len(pairs)}: {dual}")
print(f"chi(O_C(D)) = deg D + 1 - g at all {len(pairs)}: {chi}; Riemann-Roch l(D) - l(K - D) = deg D + 1 - g: {rr}")
print(f"h^0(O_C(m)) against the monomials of degree m with z-power below d, m >= 0: {mons}")
assert dual and chi and rr and mons
p = 13
def pts(d):                                            # points of x^d + y^d + z^d = 0 over F_13, one per line through 0
    cand = [(1, y, z) for y in range(p) for z in range(p)] + [(0, 1, z) for z in range(p)] + [(0, 0, 1)]
    return [v for v in cand if sum(c ** d for c in v) % p == 0]
def evrank(d, m):                                      # rank of the degree-m forms evaluated at those points
    ms = [(i, j, m - i - j) for i in range(m + 1) for j in range(m + 1 - i)]
    return rank([[pow(x, i, p) * pow(y, j, p) * pow(z, k, p) % p for i, j, k in ms] for x, y, z in pts(d)], p)
for d, m, what in ((3, 1, "cubic, D = line section, degree 3"), (4, 1, "quartic, D = K = line section, degree 4"), (4, 2, "quartic, D = 2K, degree 8"), (4, 4, "quartic, D = 4K, degree 16")):
    g, e = gs[d - 1], h0C(d, d - 3 - m)
    print(f"{what}: h^0 = {h0C(d, m)}; monomials {mon(d, m)}; Riemann-Roch {m * d} + 1 - {g} + l(K - D) {e} = {m * d + 1 - g + e}")
    print(f"  over F_{p}: {len(pts(d))} points; the {comb(m + 2, 2)} forms of degree {m} have rank {evrank(d, m)} on them")
    assert h0C(d, m) == mon(d, m) == m * d + 1 - g + e == evrank(d, m) and len(pts(d)) > m * d
print(f"quartic: h^0(2K) = {h0C(4, 2)} = 3g - 3, the number of parameters of curves of genus 3")
print(f"mistake, Riemann-Roch without l(K - D): quartic at D = K gives {4 + 1 - 3}, not {h0C(4, 1)}; cubic at D = 0 gives {0 + 1 - 1}, not {h0C(3, 0)}")
aff = [sum(1 for a in range(N + 1)) for N in (10, 100, 1000)]   # the monomials x^a with 0 <= a <= N on the one chart
c1 = list(combinations(range(1), 2))                   # Cech 1-cells of a one-chart cover: none, so h^1 = 0
print(f"mistake, the affine line (not projective): polynomials of degree <= N number {aff}, no end; h^1(K) = {len(c1)} with one chart")
assert aff[0] < aff[1] < aff[2] and not c1
print("ALL CHECKS PASS")
