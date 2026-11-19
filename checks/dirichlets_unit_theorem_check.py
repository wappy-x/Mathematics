# Dirichlet's unit theorem -- the check behind the card.  Standard library only.
# Members of Z[theta] are whole coordinate lists, multiplied exactly.  Road 1
# counts places by numerical roots and by the sign of the exact discriminant.
# Road 2 searches a box for every unit and proves the claimed units fundamental.
# Road 3 redoes each regulator from closed forms (square root, cube root, cosine).
from itertools import product
from math import log, exp, isqrt, prod, sqrt, cos, pi

def mul(x, y, p):                     # product in Z[theta], theta^n = -sum p[k] theta^k
    n, r = len(p), [0] * (2 * len(p) - 1)
    for i, a in enumerate(x):
        for j, b in enumerate(y):
            r[i + j] += a * b
    for d in range(2 * n - 2, n - 1, -1):
        c, r[d] = r[d], 0
        for k in range(n):
            r[d - n + k] -= c * p[k]
    return r[:n]
def det(M):                           # Laplace expansion: whole numbers or floats
    return M[0][0] if len(M) == 1 else sum((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M)))
def e(n, k): return [int(i == k) for i in range(n)]
def matrix(x, p):                     # "multiply by x": column j holds x theta^j
    return [list(r) for r in zip(*[mul(x, power(e(len(p), 1), j, p), p) for j in range(len(p))])]
def norm(x, p): return det(matrix(x, p))
def gram(p): return [[sum(matrix(mul(e(len(p), i), e(len(p), j), p), p)[k][k] for k in range(len(p)))
                      for j in range(len(p))] for i in range(len(p))]
def inverse(u, p):                    # Cramer's rule; a unit's determinant is +1 or -1
    M = matrix(u, p)
    return [det([r[:k] + [int(i == 0)] + r[k + 1:] for i, r in enumerate(M)]) // det(M) for k in range(len(p))]
def power(x, m, p):
    y, b = e(len(p), 0), (x if m >= 0 else inverse(x, p))
    for _ in range(abs(m)):
        y = mul(y, b, p)
    return y
def places(p):                        # Durand-Kerner roots; one place per real root or complex pair
    n, f = len(p), lambda x: x ** len(p) + sum(c * x ** k for k, c in enumerate(p))
    z = [(0.4 + 0.9j) ** k for k in range(n)]
    for _ in range(500):
        z = [z[i] - f(z[i]) / prod(z[i] - z[j] for j in range(n) if j != i) for i in range(n)]
    real = sorted((w.real for w in z if abs(w.imag) < 1e-9), reverse=True)
    return [(complex(t), 1) for t in real] + [(w, 2) for w in sorted((w for w in z if w.imag >= 1e-9), key=lambda w: w.real)]
def sig(x, z): return sum(c * z ** k for k, c in enumerate(x))
def logs(x, P): return [w * log(abs(sig(x, z))) for z, w in P]
def search(p, P, B):                  # every unit with |sigma_i(x)| <= B_i at each place
    n, G = len(p), gram(p)
    adj = [[(-1) ** (i + j) * det([r[:i] + r[i + 1:] for k, r in enumerate(G) if k != j])
            for j in range(n)] for i in range(n)]
    T = [sum(w * b * abs(z) ** j for (z, w), b in zip(P, B)) for j in range(n)]
    H = [int(sum(abs(adj[k][j]) * T[j] for j in range(n)) / abs(det(G))) + 1 for k in range(n)]
    return [list(x) for x in product(*[range(-h, h + 1) for h in H]) if any(x)
            and all(abs(sig(x, z)) <= b * (1 + 1e-9) for (z, w), b in zip(P, B)) and abs(norm(list(x), p)) == 1]
def rank(vs):                         # Gram-Schmidt rank of the log vectors
    bs = []
    for v in vs:
        for b in bs:
            c = sum(s * t for s, t in zip(v, b)); v = [s - c * t for s, t in zip(v, b)]
        if sqrt(sum(s * s for s in v)) > 1e-6:
            bs.append([s / sqrt(sum(t * t for t in v)) for s in v])
    return len(bs)
def study(p, eps):
    n, P = len(p), places(p)
    r1 = sum(1 for z, w in P if w == 1); r2 = len(P) - r1; r = r1 + r2 - 1; D = det(gram(p))
    assert (D > 0) == (r2 % 2 == 0)   # sign of d_K is (-1)^r2: places counted two ways
    assert len(eps) == r and all(abs(norm(u, p)) == 1 for u in eps)
    L = [logs(u, P) for u in eps]
    S = [[L[j][i] for j in range(r)] for i in range(r)]
    B = [exp(sum(abs(l[i]) for l in L) / P[i][1]) for i in range(len(P))]
    units = search(p, P, B)
    w = sum(1 for u in units if max(abs(t) for t in logs(u, P)) < 1e-9)
    for u in units:                   # each unit found = root of unity times powers of eps
        l = logs(u, P); assert abs(sum(l)) < 1e-9   # Step 2: the weighted logs add to log|N(u)| = 0
        k = [det([[l[i] if c == j else S[i][c] for c in range(r)] for i in range(r)]) / det(S) for j in range(r)]
        assert all(abs(t - round(t)) < 1e-6 for t in k)
        for v, t in zip(eps, k):
            u = mul(u, power(v, -round(t), p), p)
        assert power(u, w, p) == e(n, 0)
    return dict(P=P, r1=r1, r2=r2, r=r, D=D, R=abs(det(S)) if r else 1.0, w=w, N=len(units),
                found=rank([logs(u, P) for u in units]), units=units)
def smallest(p, B):                   # smallest unit above 1 at the first real place
    P = places(p)
    return min((sig(u, P[0][0]).real, u) for u in search(p, P, B) if sig(u, P[0][0]).real > 1 + 1e-9)
def f6(x): return f"{x:.6f}"

c2, c4 = 2 * cos(2 * pi / 7), 2 * cos(4 * pi / 7)
FIELDS = [("Q(root 2)", [-2, 0], [[1, 1]], log(1 + sqrt(2))),
          ("Q(root -5)", [5, 0], [], 1.0),
          ("Q(cbrt 2)", [-2, 0, 0], [[1, 1, 1]], log(1 + exp(log(2) / 3) + exp(2 * log(2) / 3))),
          ("x^3+x^2-2x-1", [-1, -2, 1], [[0, 1, 0], [1, 1, 0]],
           abs(log(c2) * log(abs(1 + c4)) - log(abs(c4)) * log(1 + c2))),
          ("Q(root 5)", [-1, -1], [[0, 1]], log((1 + sqrt(5)) / 2))]
info = {}
print("field            d_K  r1 r2  rank r1+r2-1  rank found  w  units in box  regulator")
for name, p, eps, Rclosed in FIELDS:
    s = info[name] = study(p, eps)
    assert s["found"] == s["r"] and abs(s["R"] - Rclosed) < 1e-9
    print(f"{name:15} {s['D']:>5} {s['r1']:>3} {s['r2']:>2} {s['r']:>8} {s['found']:>11} {s['w']:>4}"
          f" {s['N']:>9}      {f6(s['R'])}")

LIMIT, p2 = 10000, [-2, 0]            # the example: units a + b root 2 with a, b > 0
found = [(isqrt(2 * b * b + s), b, s) for b in range(1, LIMIT + 1) for s in (-1, 1)
         if isqrt(2 * b * b + s) ** 2 == 2 * b * b + s]
pows = [tuple(power([1, 1], m, p2)) + (norm(power([1, 1], m, p2), p2),) for m in range(1, 12)]
z2 = smallest(p2, [5, 5])
assert found == pows and power([1, 1], 12, p2)[1] > LIMIT and z2[1] == [1, 1]
print(f"search b = 1..{LIMIT}: {len(found)} units with a, b > 0; powers m = 1..{len(pows)} of 1 + root 2 match")
print("first five: " + ", ".join(f"{a} + {b} root 2 (norm {s:+d})" for a, b, s in found[:5]))
print(f"(1 + root 2)(root 2 - 1) = {mul([1, 1], [-1, 1], p2)}; (1 + root 2)^2 = {power([1, 1], 2, p2)}; "
      f"smallest unit above 1 by search = {f6(z2[0])}; L(1 + root 2) = {', '.join(map(f6, logs([1, 1], places(p2))))}")
P2 = places(p2)
for m in range(1, 6):
    a, b = power([1, 1], m, p2); l = logs([a, b], P2)[0]
    print(f"bar {m}: log({a} + {b} root 2) = {f6(l)}  " + "#" * round(l * 5))
p3, P3, s3 = [-2, 0, 0], places([-2, 0, 0]), smallest([-2, 0, 0], [4, 1])   # theta^3 = 2
assert s3[1] == [1, 1, 1] and mul([1, 1, 1], [-1, 1, 0], p3) == [1, 0, 0]
print(f"cubic: N(1 + t + t^2) = {norm([1, 1, 1], p3)}, 1 + 2 + 4 - 6 = {1 + 2 + 4 - 6}; "
      f"(1 + t + t^2)(t - 1) = {mul([1, 1, 1], [-1, 1, 0], p3)}; N(t - 1) = {norm([-1, 1, 0], p3)}")
print(f"cubic: real value {f6(sig([1, 1, 1], P3[0][0]).real)}, |complex value|^2 "
      f"{f6(abs(sig([1, 1, 1], P3[1][0])) ** 2)}, cbrt 2 - 1 = {f6(exp(log(2) / 3) - 1)}; "
      f"smallest unit above 1 by search {s3[1]} = {f6(s3[0])}")
P7 = info["x^3+x^2-2x-1"]["P"]; L7 = [logs(u, P7) for u in ([0, 1, 0], [1, 1, 0])]
print("x^3+x^2-2x-1: roots " + ", ".join(f6(z.real) for z, w in P7) + "; logs of t: " +
      ", ".join(map(f6, L7[0])) + "; logs of t + 1: " + ", ".join(map(f6, L7[1])))
print("regulator dropping place 3, 2, 1: " + ", ".join(
    f6(abs(L7[0][i] * L7[1][j] - L7[0][j] * L7[1][i])) for i, j in ((0, 1), (0, 2), (1, 2))))

z5, R5 = smallest([-5, 0], [5, 5]), info["Q(root 5)"]["R"]   # what breaks
assert z5[1] == [2, 1] and power([0, 1], 3, [-1, -1]) == [1, 2]
print(f"mistake 1, Z[root 5] for the ring: smallest unit {z5[1][0]} + {z5[1][1]} root 5 = {f6(z5[0])} = phi^3, "
      f"regulator {f6(log(z5[0]))}, not {f6(R5)}; ratio {f6(log(z5[0]) / R5)}")
k = logs([1, 1], P2)[0] / logs([3, 2], P2)[0]; assert abs(k - 0.5) < 1e-12
print(f"mistake 2, Pell's 3 + 2 root 2 as fundamental: regulator {f6(logs([3, 2], P2)[0])}; "
      f"1 + root 2 would be its power {f6(k)}, not whole")
s3i, l3 = info["Q(cbrt 2)"], [log(abs(sig([1, 1, 1], z))) for z in (P3[0][0], P3[1][0], P3[1][0].conjugate())]
print(f"mistake 3, Q(cbrt 2) with r2 = 2, counting complex embeddings singly: rank {s3i['r1'] + 2 - 1} predicted; logs of "
      f"1 + t + t^2 at the real and both complex embeddings {', '.join(map(f6, l3))}: the pair matches, one direction, not two")
gi = study([1, 0], []); assert gi["w"] == 4
print(f"mistake 4, units of Q(i) taken as +1, -1 only: the box holds {gi['N']}: {gi['units']}")
print("ALL CHECKS PASS")
