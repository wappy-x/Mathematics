# Ceva and Menelaus -- the check behind the card.  Triangle A (0, 0), B (6, 0), C (2, 4), exact fractions.
# Roads: multiply three signed side ratios; meet the lines and test the third directly; areas at the meeting point.
from fractions import Fraction as Q
def sub(p, q): return (p[0] - q[0], p[1] - q[1])
def cross(u, v): return u[0] * v[1] - u[1] * v[0]
def at(P, R, t): return (P[0] + t * (R[0] - P[0]), P[1] + t * (R[1] - P[1]))
def ratio(P, X, R):                       # signed PX/XR: negative when X lies outside P-R
    d = sub(R, P); t = (sub(X, P)[0] * d[0] + sub(X, P)[1] * d[1]) / (d[0] ** 2 + d[1] ** 2)
    return t / (1 - t)
def meet(P, R, S, T):                     # where line PR crosses line ST
    return at(P, R, cross(sub(S, P), sub(T, S)) / cross(sub(R, P), sub(T, S)))
def area(P, R, S): return abs(cross(sub(R, P), sub(S, P))) / 2
def pt(p): return f"({p[0]}, {p[1]})"
A, B, C = (Q(0), Q(0)), (Q(6), Q(0)), (Q(2), Q(4))
def ceva(D, E, F, name):                  # D on BC, E on CA, F on AB
    r = [ratio(A, F, B), ratio(B, D, C), ratio(C, E, A)]
    P = meet(A, D, B, E)                  # two lines meet at P; does the third pass?
    miss = cross(sub(F, C), sub(P, C))   # 0 exactly when P lies on line CF
    gap = abs(miss) / ((F[0] - C[0]) ** 2 + (F[1] - C[1]) ** 2) ** 0.5
    print(f"{name}: feet F {pt(F)}, D {pt(D)}, E {pt(E)}; AF/FB {r[0]}, BD/DC {r[1]}, "
          f"CE/EA {r[2]}; product {r[0] * r[1] * r[2]}; AD and BE meet at {pt(P)}; P is {gap:.2f} off CF")
    return r[0] * r[1] * r[2], P, miss
print(f"triangle A {pt(A)}, B {pt(B)}, C {pt(C)}; area {area(A, B, C)}")
pm, G, mm = ceva(at(B, C, Q(1, 2)), at(C, A, Q(1, 2)), at(A, B, Q(1, 2)), "medians")
foot = lambda P, R, S: at(R, S, ((P[0] - R[0]) * (S[0] - R[0]) + (P[1] - R[1]) * (S[1] - R[1]))
                         / ((S[0] - R[0]) ** 2 + (S[1] - R[1]) ** 2))
Da, Eb, Fc = foot(A, B, C), foot(B, C, A), foot(C, A, B)
ph, H, mh = ceva(Da, Eb, Fc, "altitudes")
ar = [area(A, B, H), area(B, C, H), area(C, A, H)]
print(f"areas at H: ABH {ar[0]}, BCH {ar[1]}, CAH {ar[2]}; CAH/BCH {ar[2] / ar[1]}, "
      f"ABH/CAH {ar[0] / ar[2]}, BCH/ABH {ar[1] / ar[0]}")
px, _, mx = ceva(at(B, C, Q(1, 2)), at(C, A, Q(1, 2)), Fc, "mixed")
N, L, M = (Q(9), Q(0)), at(B, C, Q(1, 4)), at(C, A, Q(1, 2))   # one straight line
mr = [ratio(A, N, B), ratio(B, L, C), ratio(C, M, A)]
K = meet(A, B, C, (C[0] + N[0] - M[0], C[1] + N[1] - M[1]))   # through C, parallel to the line
print(f"transversal: N {pt(N)}, L {pt(L)}, M {pt(M)}; AN/NB {mr[0]}, BL/LC {mr[1]}, CM/MA {mr[2]}; "
      f"product {mr[0] * mr[1] * mr[2]}; off-line by {cross(sub(L, N), sub(M, N))}")
print(f"slips: altitudes with BD/DC flipped {ratio(A, Fc, B) / ratio(B, Da, C) * ratio(C, Eb, A)}; "
      f"transversal with signs dropped {abs(mr[0]) * abs(mr[1]) * abs(mr[2])}")
print(f"parallel through C meets AB at K {pt(K)}; BN/NK {ratio(B, N, K)}, KN/NA {ratio(K, N, A)}")
cv = mn = bad = 0
for i, j, k in (T := [(i, j, k) for i in range(1, 6) for j in range(1, 6) for k in range(1, 6)]):   # every cevian triple on the sixths of the sides
    D, E, F = at(B, C, Q(i, 6)), at(C, A, Q(j, 6)), at(A, B, Q(k, 6))
    one = ratio(A, F, B) * ratio(B, D, C) * ratio(C, E, A) == 1
    P = meet(A, D, B, E); cv += one; bad += one != (cross(sub(F, C), sub(P, C)) == 0)
S = [Q(-1), Q(-1, 2), Q(1, 3), Q(1, 2), Q(2, 3), Q(3, 2), Q(2), Q(3)]
for i, j, k in [(i, j, k) for i in S for j in S for k in S]:            # points on the three side-lines, inside or out
    L2, M2, N2 = at(B, C, i), at(C, A, j), at(A, B, k)
    one = ratio(A, N2, B) * ratio(B, L2, C) * ratio(C, M2, A) == -1
    mn += one; bad += one != (cross(sub(L2, N2), sub(M2, N2)) == 0)
print(f"sweep: Ceva product 1 for {cv} of {len(T)} triples, Menelaus -1 for {mn} of {len(S) ** 3}; mismatches {bad}")
sv = lambda p: f"({float(24 + 34 * p[0]):.1f}, {float(172 - 34 * p[1]):.1f})"
print("figure, 1 unit = 34:", ", ".join(f"{n} {sv(p)}" for n, p in zip("ABCHDEFLMN", (A, B, C, H, Da, Eb, Fc, L, M, N))))
assert pm == 1 and mm == 0 and G == (Q(8, 3), Q(4, 3))   # medians: product 1, they meet
assert ph == 1 and mh == 0 and H == (Q(2), Q(2))         # altitudes: product 1, they meet
assert [ar[2] / ar[1], ar[0] / ar[2], ar[1] / ar[0]] == [ratio(A, Fc, B), ratio(B, Da, C), ratio(C, Eb, A)]
assert px != 1 and mx != 0                               # product off 1: the lines miss
assert mr[0] * mr[1] * mr[2] == -1 and cross(sub(L, N), sub(M, N)) == 0
assert ratio(B, N, K) == mr[1] and ratio(K, N, A) == mr[2] and bad == 0
print("ALL CHECKS PASS")
