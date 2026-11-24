# Euler line and nine-point circle -- the check behind the card.  Nothing is imported.  Triangle
# A (0, 0), B (6, 0), C (2, 4).  H twice: 3G - 2O, and two altitudes crossing.  The nine-point circle
# twice: half-size about the midpoint of OH, and the circle through the three side midpoints.
def sub(p, q): return (p[0] - q[0], p[1] - q[1])
def dot(p, q): return p[0] * q[0] + p[1] * q[1]
def mid(p, q): return ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2)
def dist(p, q): return dot(sub(p, q), sub(p, q)) ** 0.5
def solve(r1, r2):                        # Cramer's rule for two lines a x + b y = k
    (a1, b1, k1), (a2, b2, k2) = r1, r2; det = a1 * b2 - b1 * a2
    return ((k1 * b2 - b1 * k2) / det, (a1 * k2 - k1 * a2) / det)
def circum(A, B, C):                      # perpendicular bisectors: |P - A|^2 = |P - Q|^2
    row = lambda Q: (2 * (Q[0] - A[0]), 2 * (Q[1] - A[1]), dot(Q, Q) - dot(A, A))
    return solve(row(B), row(C))
def altitudes(A, B, C):                   # (P - A).(B - C) = 0 and (P - B).(C - A) = 0
    return solve((*sub(B, C), dot(A, sub(B, C))), (*sub(C, A), dot(B, sub(C, A))))
def foot(P, U, V):                        # foot of the drop from P onto the line UV
    d = sub(V, U); t = dot(sub(P, U), d) / dot(d, d)
    return (U[0] + t * d[0], U[1] + t * d[1])
def centres(A, B, C):                     # route one: O by bisectors, then H = 3G - 2O
    O = circum(A, B, C); G = ((A[0] + B[0] + C[0]) / 3, (A[1] + B[1] + C[1]) / 3)
    H = (3 * G[0] - 2 * O[0], 3 * G[1] - 2 * O[1]); return O, G, H, mid(O, H), dist(O, A)
def nine(A, B, C, H): return [mid(B, C), mid(C, A), mid(A, B), foot(A, B, C), foot(B, C, A),
                              foot(C, A, B), mid(A, H), mid(B, H), mid(C, H)]
def pt(p): return f"({p[0]:.2f}, {p[1]:.2f})"
def fig(p): return pt((60 + 40 * p[0], 200 - 40 * p[1]))   # figure: 1 unit = 40, y flipped
A, B, C = (0.0, 0.0), (6.0, 0.0), (2.0, 4.0)
O, G, H, N, R = centres(A, B, C); H2 = altitudes(A, B, C)  # route two for H
N2 = circum(mid(B, C), mid(C, A), mid(A, B)); P9 = nine(A, B, C, H); d9 = [dist(N, p) for p in P9]  # route two for N
print(f"triangle A {pt(A)}, B {pt(B)}, C {pt(C)}; circumcentre O {pt(O)}, R = {R:.4f}")
print(f"centroid G ({G[0]:.4f}, {G[1]:.4f}); H = 3G - 2O {pt(H)}; H by two altitudes {pt(H2)}")
print(f"x + y at O, G, N, H: {', '.join(f'{p[0] + p[1]:.2f}' for p in (O, G, N, H))}")
print(f"HG = {dist(H, G):.4f}, GO = {dist(G, O):.4f}, ratio {dist(H, G) / dist(G, O):.2f}")
print(f"nine-point centre N = midpoint of OH {pt(N)}, radius R/2 = {R / 2:.4f}")
print(f"circle through the side midpoints: centre {pt(N2)}, radius {dist(N2, P9[0]):.4f}")
print("side midpoints " + ", ".join(pt(p) for p in P9[:3]))
print("altitude feet " + ", ".join(pt(p) for p in P9[3:6]))
print("midpoints to H " + ", ".join(pt(p) for p in P9[6:]))
print("N to the nine points: " + ", ".join(f"{d:.4f}" for d in d9))
W1, W2 = (3 * G[0] - O[0], 3 * G[1] - O[1]), (2 * G[0] - O[0], 2 * G[1] - O[1])
print(f"wrong: 3G - O {pt(W1)}, 2G - O ({W2[0]:.4f}, {W2[1]:.4f}); off x = 2 by {W1[0] - 2:.2f}, {W2[0] - 2:.2f}")
print(f"wrong: G to the side midpoints {', '.join(f'{dist(G, p):.2f}' for p in P9[:3])}")
cam = [dot(sub(U, H), sub(V, H)) for U, V in ((A, B), (B, C), (C, A))]
print(f"camera: (U - H).(V - H) for AB, BC, CA: {', '.join(f'{c:.2f}' for c in cam)}; "
      f"focal length {format((-cam[0]) ** 0.5, '.2f') if cam[0] < 0 else 'none: the triangle is not acute'}")
s, good = 2026, 0                         # 200 triangles from a fixed pseudo-random sequence
for _ in range(200):
    v = []
    for _ in range(6): s = (s * 1103515245 + 12345) % 2 ** 31; v.append(s / 2 ** 31 * 10)
    T = [(v[0], v[1]), (v[2], v[3]), (v[4], v[5])]
    o, g, h, n, r = centres(*T); tol = 1e-9 * (1 + r) ** 2
    good += dist(h, altitudes(*T)) < tol and abs(dot(sub(h, T[2]), sub(T[0], T[1]))) < tol and max(abs(dist(n, p) - r / 2) for p in nine(*T, h)) < tol
print(f"random triangles: {good} of 200 have H = 3G - 2O on all altitudes and nine points on the circle")
print(f"figure, 1 unit = 40: A {fig(A)}, B {fig(B)}, C {fig(C)}, O {fig(O)}, G {fig(G)}, H {fig(H)}, N {fig(N)}, "
      f"R {40 * R:.2f}, R/2 {20 * R:.2f}")
assert dist(H, H2) < 1e-12 and dist(N, N2) < 1e-12        # two roads to H, two to N
assert max(abs(d - R / 2) for d in d9) < 1e-12            # all nine points on one circle
assert abs(dist(H2, G) - 2 * dist(G, O)) < 1e-12          # HG = 2 GO, with H from the altitudes
assert abs(cam[0] - cam[1]) + abs(cam[1] - cam[2]) < 1e-12  # the three camera products agree
assert good == 200
print("ALL CHECKS PASS")
