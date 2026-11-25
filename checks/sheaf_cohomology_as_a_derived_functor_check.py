# Sheaf cohomology as a derived functor -- the check behind the card.  Nothing
# is imported; every number is an exact integer, and ranks are taken mod the
# prime P = 1000003.  Road 1: H^i(P^n, O(k)) by the Cech complex of the charts
# x_i != 0, one Laurent monomial at a time, in the exponent box [-B, B].
# Road 2: the closed forms h^0 = C(k + n, n) and h^n = C(-k - 1, n).
# Road 3: the Hilbert function of S/(F), by the rank of multiplication by F,
# and points counted by brute force.  The long exact sequence joins them.
P, B = 1000003, 8

def rank(rows):                                  # Gaussian elimination mod P
    rows, r = [[v % P for v in row] for row in rows], 0
    for c in range(len(rows[0]) if rows else 0):
        piv = next((i for i in range(r, len(rows)) if rows[i][c]), None)
        if piv is None:
            continue
        rows[r], rows[piv] = rows[piv], rows[r]
        inv = pow(rows[r][c], P - 2, P)
        rows[r] = [v * inv % P for v in rows[r]]
        for i in range(len(rows)):
            if i != r and rows[i][c]:
                f = rows[i][c]
                rows[i] = [(a - f * b) % P for a, b in zip(rows[i], rows[r])]
        r += 1
    return r

def binom(m, r):
    if m < r or m < 0:
        return 0
    out = 1
    for i in range(r):
        out = out * (m - i) // (i + 1)
    return out

def monomials(n, k, box):                        # exponents of x_0..x_n adding to k
    if n == 0:
        return [(k,)] if -box <= k <= box else []
    return [(a,) + t for a in range(-box, box + 1) for t in monomials(n - 1, k - a, box)]

def cech(n, k, charts, box):                     # dims of Cech H^0..H^n of O(k) on P^n
    h = [0] * (n + 1)
    for e in monomials(n, k, box):
        neg = {i for i in range(n + 1) if e[i] < 0}  # a section on U_I needs neg inside I
        cells = [[] for _ in charts]
        for mask in range(1, 1 << len(charts)):
            I = tuple(c for t, c in enumerate(charts) if mask >> t & 1)
            if neg <= set(I):
                cells[len(I) - 1].append(I)
        R = [0]
        for p in range(len(charts) - 1):         # (dc)_J = sum_j (-1)^j c_(J minus j-th)
            rows = [[0] * len(cells[p]) for _ in cells[p + 1]]
            for a, J in enumerate(cells[p + 1]):
                for j in range(len(J)):
                    if J[:j] + J[j + 1:] in cells[p]:
                        rows[a][cells[p].index(J[:j] + J[j + 1:])] = (-1) ** j
            R.append(rank(rows))
        R.append(0)
        for p in range(len(charts)):
            h[p] += len(cells[p]) - R[p] - R[p + 1]
    return h

def forms(nv, n):                                # exponents of the degree-n forms
    if n < 0:
        return []
    if nv == 1:
        return [(n,)]
    return [(a,) + t for a in range(n, -1, -1) for t in forms(nv - 1, n - a)]

def hilbert(Fs, nv, d, n):                       # dim (S/(Fs))_n = dim S_n - rank of Fs times
    rows_m, cols_m = forms(nv, n), forms(nv, n - d)
    M = [[F.get(tuple(r[i] - c[i] for i in range(nv)), 0) for F in Fs for c in cols_m] for r in rows_m]
    return len(rows_m) - rank(M)

# ---- P^1 and two points: global sections lose one function, H^1 finds it ----
h1 = {k: cech(1, k, [0, 1], B) for k in range(-3, 4)}
print("P^1, (h0, h1) of O(k) for k = -3..1:", " ".join(f"({h1[k][0]}, {h1[k][1]})" for k in range(-3, 2)))
XY = {(1, 1): 1}                                 # Z = {xy = 0}: the points (1:0) and (0:1)
pts = sum(1 for p in [(1, t) for t in range(7)] + [(0, 1)] if p[0] * p[1] % 7 == 0)
les_Z = [h1[n][0] - h1[n - 2][0] + h1[n - 2][1] - h1[n][1] for n in range(4)]
hf_Z = [hilbert([XY], 2, 2, n) for n in range(4)]
print(f"two points Z = {{xy = 0}}: points over F_7 {pts}; h0(O_Z(n)), n = 0..3, by the sequence {les_Z}")
print(f"  the same from the quotient ring (S/xy)_n: {hf_Z}; the gap at n = 0 is h1(O(-2)) = {h1[-2][1]}")

# ---- P^2: Cech against the closed forms, and the curve's genus ----
h2 = {k: cech(2, k, [0, 1, 2], B) for k in range(-8, 6)}
big = all(cech(2, k, [0, 1, 2], B + 2) == h2[k] for k in (-6, 0, 2))
print(f"P^2, h0 h1 h2 of O(k) by Cech in box {B} (box {B + 2} agrees: {'yes' if big else 'no'}):")
for k in range(-6, 3):
    closed = [binom(k + 2, 2), 0, binom(-k - 1, 2)]
    print(f"  k = {k:2}: {h2[k][0]:2} {h2[k][1]} {h2[k][2]:2}   closed forms {closed[0]:2} 0 {closed[2]:2}"
          f"   chi {h2[k][0] - h2[k][1] + h2[k][2]:2}")
    assert h2[k] == closed and h2[k][0] - h2[k][1] + h2[k][2] == (k + 1) * (k + 2) // 2
print("plane curve C of degree d: h1(O_C) = h2(O(-d)), against (d - 1)(d - 2)/2")
for d in range(1, 7):
    g = h2[-d][2] - h2[0][2]                     # 0 -> H1(O_C) -> H2(O(-d)) -> H2(O) = 0
    print(f"  degree {d}: {g:2} {(d - 1) * (d - 2) // 2:2}  {'#' * (2 * g)}".rstrip())
    assert g == (d - 1) * (d - 2) // 2

# ---- two named curves: the long exact sequence against the quotient ring ----
for name, F, d in [("Fermat cubic x^3 + y^3 + z^3", {(3, 0, 0): 1, (0, 3, 0): 1, (0, 0, 3): 1}, 3),
                   ("Klein quartic x^3y + y^3z + z^3x", {(3, 1, 0): 1, (0, 3, 1): 1, (1, 0, 3): 1}, 4)]:
    print(f"{name}: n, HF(n) by rank, h0(O_C(n)) and h1(O_C(n)) by the sequence, dn + 1 - g")
    g = (d - 1) * (d - 2) // 2
    for n in range(-1, 6):
        hf = hilbert([F], 3, d, n)
        h0 = h2[n][0] - h2[n - d][0]             # H1(O(n - d)) = 0 makes this exact
        hh1 = h2[n - d][2] - h2[n][2]            # H2(O_C(n)) = 0: C has dimension 1
        print(f"  n = {n:2}: {hf:2} {h0:2} {hh1} {d * n + 1 - g:3}")
        assert hf == h0 and h0 - hh1 == d * n + 1 - g
    slope = hilbert([F], 3, d, d + 1) - hilbert([F], 3, d, d)
    hp0 = hilbert([F], 3, d, d) - d * slope        # the Hilbert polynomial at n = 0
    print(f"  Hilbert polynomial {slope}n + ({hp0}), so 1 - HP(0) = {1 - hp0}, genus by the sequence {g}")
    grads = [{e[:i] + (e[i] - 1,) + e[i + 1:]: c * e[i] for e, c in F.items() if e[i]} for i in range(3)]
    sing = hilbert(grads, 3, d - 1, 3 * d - 5)   # 0: the partials share no zero, so C is smooth
    print(f"  smooth: forms of degree {3 * d - 5} modulo the three partials of F leave {sing}")
    assert slope == d and 1 - hp0 == g == h2[-d][2] and sing == 0

# ---- what breaks ----
print(f"mistake 1, sections of the quotient ring as functions on Z: {hf_Z[0]}, not {pts}")
print(f"mistake 2, h1(O(-4)) for the quartic's genus: {h2[-4][1]}, not {h2[-4][2]}")
print(f"mistake 3, the twist taken as O(+4): h2(O(4)) = {h2[4][2]}, not {h2[-4][2]}")
two = [cech(2, -3, [0, 1], b)[1] for b in (B, B + 2)]
print(f"mistake 4, charts x != 0 and y != 0 only, h1(O(-3)) in box {B} and {B + 2}: {two[0]} and {two[1]}, not 0")
assert les_Z == [pts] * 4 and hf_Z[0] == 1 and h1[-2] == [0, 1]
assert all(h1[k] == [binom(k + 1, 1), binom(-k - 1, 1)] for k in range(-3, 4))
assert two[1] > two[0] > 0 and h2[-4][1] == 0 and h2[4][2] == 0 and big
print("ALL CHECKS PASS")
