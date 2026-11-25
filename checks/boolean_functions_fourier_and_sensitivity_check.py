# Boolean functions: decision trees, Fourier coefficients and Huang's sensitivity theorem -- the check.
# Standard library only.  An input is a bit mask: bit i set means voter i+1 says yes (+1), clear means no (-1).
from itertools import combinations
from math import sqrt
def table(n, rule):                  # f as a list of +1/-1 over all 2^n inputs
    return [rule([1 if x >> i & 1 else -1 for i in range(n)]) for x in range(2 ** n)]
pc = lambda x: bin(x).count("1")
show = lambda x, n: "".join("+" if x >> i & 1 else "-" for i in range(n))
def fourier(f):                      # 2^n times each coefficient, by fast butterflies
    v, h = f[:], 1
    while h < len(v):
        for x in [x for x in range(len(v)) if not x & h]:
            v[x], v[x | h] = v[x] + v[x | h], v[x | h] - v[x]
        h *= 2
    return v
fourier_slow = lambda f, n: [sum(f[x] * (-1) ** pc(S & ~x) for x in range(2 ** n)) for S in range(2 ** n)]
degree = lambda f: max(pc(S) for S, c in enumerate(fourier(f)) if c)
sens = lambda f, n, x: sum(f[x] != f[x ^ 1 << i] for i in range(n))     # votes whose single change flips f
def bsens(f, n, x, used=0, last=0):  # most disjoint blocks of votes, each flipping the answer
    return max([1 + bsens(f, n, x, used | B, B) for B in range(last + 1, 2 ** n)
                if not B & used and f[x ^ B] != f[x]] + [0])
def cert(f, n, x):                   # fewest votes that, once seen, fix the answer
    return min(pc(S) for S in range(2 ** n) if all(f[y] == f[x] for y in range(2 ** n) if (y ^ x) & S == 0))
def depth(f, n, mask=0, val=0):      # fewest questions in the worst case, best tree, by brute force
    pts = [f[y] for y in range(2 ** n) if y & mask == val]
    if min(pts) == max(pts): return 0
    return min(1 + max(depth(f, n, mask | 1 << i, val), depth(f, n, mask | 1 << i, val | 1 << i))
               for i in range(n) if not mask >> i & 1)
measures = lambda f, n: [max(m(f, n, x) for x in range(2 ** n)) for m in (sens, bsens, cert)] + [depth(f, n), degree(f)]
def infl(f, n):                      # chance that changing vote i alone flips the answer, two roads
    flip = [sum(f[x] != f[x ^ 1 << i] for x in range(2 ** n)) / 2 ** n for i in range(n)]
    c = fourier(f)
    return flip, [sum(c[S] ** 2 for S in range(2 ** n) if S >> i & 1) / 4 ** n for i in range(n)]
fl = lambda xs: "[" + ", ".join(f"{v:.4f}" for v in xs) + "]"
maj = table(3, lambda v: 1 if sum(v) > 0 else -1)
print("Majority of 3 supervisors (+ yes, - no); voter 1 first")
for x in range(8):
    S = min(S for S in range(8) if pc(S) == cert(maj, 3, x) and all(maj[y] == maj[x] for y in range(8) if (y ^ x) & S == 0))
    print(f"  {show(x, 3)} -> {'+' if maj[x] > 0 else '-'}  sensitive votes {sens(maj, 3, x)}"
          f"  certificate: voters {[i + 1 for i in range(3) if S >> i & 1]}")
c, cs = fourier(maj), fourier_slow(maj, 3)
print("  coefficients x 8, sets {} {1} {2} {1,2} {3} {1,3} {2,3} {1,2,3}:", c)
m = measures(maj, 3)
print(f"  s {m[0]}  bs {m[1]}  C {m[2]}  D {m[3]}  deg {m[4]}")
reads = [2 if (x & 1) == (x >> 1 & 1) else 3 for x in range(8)]
print(f"  tree 'ask 1, ask 2, ask 3 only on a split': worst {max(reads)} questions, average {sum(reads) / 8:.4f}")
a, b = infl(maj, 3)
print(f"  influence by flipping {fl(a)}; from coefficients {fl(b)}; total {sum(a):.4f}")
w = [sum(c[S] ** 2 for S in range(8) if pc(S) == d) / 64 for d in range(4)]   # Fourier weight at each degree
print(f"  weights by degree {fl(w)}; total influence = 1 x {w[1]:.4f} + 3 x {w[3]:.4f} = {w[1] + 3 * w[3]:.4f}")
orf = table(4, lambda v: 1 if max(v) > 0 else -1)
mo, (ao, bo), co = measures(orf, 4), infl(orf, 4), fourier(orf)
print("OR of 4 relief staff: the gap is covered if anyone says yes")
print(f"  s {mo[0]} (at {show(max(range(16), key=lambda x: sens(orf, 4, x)), 4)})  bs {mo[1]}  C {mo[2]}  D {mo[3]}  deg {mo[4]}")
print(f"  coefficients: empty set {co[0] / 16:.4f}, all four {co[15] / 16:.4f}; influence each {ao[0]:.4f}"
      f" ({bo[0]:.4f} from coefficients); average sensitivity {sum(sens(orf, 4, x) for x in range(16)) / 16:.4f}")
ok3, gap = True, [0, 0]
for k in range(256):                 # every Boolean function of 3 votes
    f = [1 - 2 * (k >> x & 1) for x in range(8)]
    if min(f) == max(f): continue
    s, bs, C, D, d = measures(f, 3)
    ok3 &= s <= bs <= C <= D and d <= D and d <= s * s and bs <= 2 * d * d
    gap[0] += s < bs; gap[1] += C < D
print(f"all 254 non-constant functions of 3 votes: s <= bs <= C <= D, deg <= D, deg <= s^2, bs <= 2 deg^2: {ok3}")
print(f"  functions with s < bs: {gap[0]}; with C < D: {gap[1]}")
ok4, tight = True, 0
for k in range(1, 65535):            # every non-constant function of 4 votes
    f = [1 - 2 * (k >> x & 1) for x in range(16)]
    s, d = max(sens(f, 4, x) for x in range(16)), degree(f)
    ok4 &= d <= s * s; tight += d == 4 and s == 2
print(f"all 65534 non-constant functions of 4 votes: deg <= s^2 (Huang): {ok4}; degree 4 with s only 2: {tight}")
def huang(n):                        # A_1 = [[0,1],[1,0]];  A_n = [[A, I], [I, -A]]
    if n == 0: return [[0]]
    A = huang(n - 1); m = len(A)
    return [A[r] + [int(r == c) for c in range(m)] for r in range(m)] + \
           [[int(r == c) for c in range(m)] + [-v for v in A[r]] for r in range(m)]
by_formula = lambda n: [[                          # edge x -- x with vote i changed: -1 per yes vote above i
          (-1) ** pc(x >> (x ^ y).bit_length()) if pc(x ^ y) == 1 else 0 for y in range(2 ** n)] for x in range(2 ** n)]
mul = lambda A, B: [[sum(A[r][k] * B[k][c] for k in range(len(B))) for c in range(len(B))] for r in range(len(A))]
A = huang(3)
print("Huang's signed matrix for 3 votes, rows and columns in mask order 0..7:")
for r in A: print("  " + " ".join(f"{v:>2}" for v in r))
sq = all(mul(huang(n), huang(n)) == [[n * (r == c) for c in range(2 ** n)] for r in range(2 ** n)] for n in range(1, 7))
same = all(huang(n) == by_formula(n) for n in range(1, 7))
print(f"  A^2 = nI for n = 1..6: {sq}; recursion = sign formula: {same}; trace {sum(A[i][i] for i in range(8))}")
md = lambda H, n: max(sum((x ^ 1 << i) in H for i in range(n)) for x in H)
mins = [min(md(set(H), 3) for H in combinations(range(8), k)) for k in (4, 5)]
min9 = min(md(set(H), 4) for H in combinations(range(16), 9))
print(f"any 5 of 8 corners: fewest chosen neighbours at the busiest corner {mins[1]} (sqrt 3 = {sqrt(3):.4f});"
      f" 4 corners: {mins[0]}; any 9 of 16: {min9}")
H, r3 = [1, 2, 3, 4, 5], sqrt(3)
Bm = [[A[r][c] + r3 * (r == c) for c in range(8)] for r in range(8)]   # its columns lie in the +sqrt3 space
M = [[Bm[k][j] for j in range(4)] for k in range(8) if k not in H]
def null_vector(M):                  # one nonzero solution of M c = 0, by elimination
    M, piv, r = [row[:] for row in M], [], 0
    for col in range(len(M[0])):
        p = max(range(r, len(M)), key=lambda i: abs(M[i][col]))
        if abs(M[p][col]) < 1e-9: continue
        M[r], M[p] = M[p], M[r]
        M[r] = [v / M[r][col] for v in M[r]]
        for i in range(len(M)):
            if i != r: M[i] = [a - M[i][col] * b for a, b in zip(M[i], M[r])]
        piv.append(col); r += 1
        if r == len(M): break
    free = next(c for c in range(len(M[0])) if c not in piv)
    cvec = [0.0] * len(M[0]); cvec[free] = 1.0
    for i, col in enumerate(piv): cvec[col] = -M[i][free]
    return cvec
cv = null_vector(M)
v = [sum(cv[j] * Bm[k][j] for j in range(4)) for k in range(8)]
top = max(range(8), key=lambda k: abs(v[k]))
v = [w / v[top] + 0.0 if abs(w) > 1e-9 else 0.0 for w in v]
res = max(abs(sum(A[k][j] * v[j] for j in range(8)) - r3 * v[k]) for k in range(8))
nb = [x for x in H if pc(x ^ top) == 1]
print(f"chosen 5 corners {[show(x, 3) for x in H]}; vector with A v = sqrt3 v, zero off them:")
print("  v = " + " ".join(f"{show(k, 3)}:{v[k]:.4f}" for k in range(8)) + f"  (largest error {res:.1e})")
print(f"  biggest entry at {show(top, 3)}: sqrt3 x 1 = |{' + '.join(f'({A[top][y]})({v[y]:.4f})' for y in nb)}|"
      f" <= {len(nb)} chosen neighbours")
g = [maj[x] * (-1) ** pc(7 & ~x) for x in range(8)]
Hg = [x for x in range(8) if g[x] == -1]
print(f"Majority times the triple product: average {sum(g) / 8:.4f}; it is -1 on {len(Hg)} corners {[show(x, 3) for x in Hg]}")
print(f"  each has {md(set(Hg), 3)} neighbours inside, where Majority differs: sensitivity {min(sens(maj, 3, x) for x in Hg)}")
U, eig = [[int(pc(x ^ y) == 1) for y in range(8)] for x in range(8)], [3 - 2 * pc(S) for S in range(8)]
okU = all(sum(U[x][y] * (-1) ** pc(S & y) for y in range(8)) == eig[S] * (-1) ** pc(S & x) for S in range(8) for x in range(8))
print("what breaks:\n"
      f"  unsigned cube matrix: A^2 entries {sorted(set(v for row in mul(U, U) for v in row))}; stretch factors"
      f" {sorted(eig, reverse=True)} (checked on all 8 products: {okU}); only {sum(e > 1.5 for e in eig)} is >= sqrt3")
print(f"  exactly half, the 4 corners with an even count of yes votes: busiest has {md({0, 3, 5, 6}, 3)} neighbours inside")
print(f"  Majority: s {m[0]} < deg {m[4]}, so s >= deg fails; s >= sqrt(deg) = {sqrt(3):.4f} holds")
print(f"  Majority: certificate {m[2]} < depth {m[3]}: two agreeing votes prove the answer, but finding them can take 3")
P = {x: (80 + 200 * (x & 1) + 90 * (x >> 2 & 1), 330 - 200 * (x >> 1 & 1) - 70 * (x >> 2 & 1)) for x in range(8)}
neg = [f"{show(x, 3)}/{show(x ^ 1 << i, 3)}" for x in range(8) for i in range(3) if x >> i & 1 == 0 and A[x][x ^ 1 << i] < 0]
print("figure, corners " + " ".join(f"{show(x, 3)}=({P[x][0]},{P[x][1]})" for x in range(8)) + " minus edges " + " ".join(neg))
assert c == cs and c == [0, 4, 4, 0, 4, 0, 0, -4]                       # fast = slow = (1/2, 1/2, 1/2, -1/2)
assert m == [2, 2, 2, 3, 3] and mo == [4, 4, 4, 4, 4] and max(reads) == m[3]  # brute force = known values
assert a == b == [0.5] * 3 and ao == bo == [0.125] * 4 and sum(a) == w[1] + 3 * w[3]   # flipping = weights
assert ok3 and ok4 and sq and same and okU                             # chains, Huang, matrix two roads
assert mins == [0, 2] and min9 == 2 and res < 1e-9 and len(nb) >= r3 and v[top] == 1.0
assert [v[k] for k in range(8) if k not in H] == [0.0] * 3 and sum(g) == c[7]
print("ALL CHECKS PASS")
