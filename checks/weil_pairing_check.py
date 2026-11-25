# The Weil pairing -- the check behind the card.  Standard library only;
# nothing imported adds points or computes pairings.  The curve is
# y^2 = x^3 - x.  Its 2-torsion gives e_2.  Over F_43 (43 = 3 mod 4) it has
# 44 = 4 x 11 points, and e_11 moves a discrete log into F_(43^2) = F_43(i).
p = 43
ONE, ZERO, I = (1, 0), (0, 0), (0, 1)
def fa(u, v): return ((u[0] + v[0]) % p, (u[1] + v[1]) % p)
def fs(u, v): return ((u[0] - v[0]) % p, (u[1] - v[1]) % p)
def fm(u, v): return ((u[0] * v[0] - u[1] * v[1]) % p, (u[0] * v[1] + u[1] * v[0]) % p)
def fi(u):                               # 1/(a + bi) = (a - bi)/(a^2 + b^2)
    n = (u[0] * u[0] + u[1] * u[1]) % p
    assert n != 0, "division by zero"
    k = pow(n, p - 2, p)
    return (u[0] * k % p, -u[1] * k % p)
def fpow(u, k):
    r = ONE
    for _ in range(k): r = fm(r, u)
    return r
def c(n): return (n % p, 0)
def show(u):                             # an element a + bi of F_(43^2)
    if u[1] == 0: return str(u[0])
    return f"{u[1]}i" if u[0] == 0 else f"{u[0]} + {u[1]}i"
def pt(P): return "O" if P is None else f"({show(P[0])}, {show(P[1])})"
def pm(u): return {ONE: "+1", c(-1): "-1"}.get(u, show(u))
def slope(T, U):                         # tangent slope if T = U, chord slope otherwise
    if T == U: return fm(fs(fm(c(3), fm(T[0], T[0])), ONE), fi(fm(c(2), T[1])))
    return fm(fs(U[1], T[1]), fi(fs(U[0], T[0])))
def add(P, Q):                           # chord and tangent on y^2 = x^3 - x
    if P is None: return Q
    if Q is None: return P
    if P[0] == Q[0] and fa(P[1], Q[1]) == ZERO: return None
    lam = slope(P, Q)
    x = fs(fs(fm(lam, lam), P[0]), Q[0])
    return (x, fs(fm(lam, fs(P[0], x)), P[1]))
def mul(k, P):
    R = None
    for _ in range(k): R = add(R, P)
    return R
def iota(P): return None if P is None else (fs(ZERO, P[0]), fm(I, P[1]))  # (x, y) -> (-x, iy)
def g(T, U, X):                          # line through T and U, over the vertical at T + U, at X
    V = add(T, U)
    if V is None: num, den = fs(X[0], T[0]), ONE
    else:
        num = fs(fs(X[1], T[1]), fm(slope(T, U), fs(X[0], T[0])))
        den = fs(X[0], V[0])
    assert num != ZERO and den != ZERO, "X sits on a zero or pole"
    return fm(num, fi(den)), V
def miller(m, P, X, log=None):            # f_(m,P)(X): divisor m(P) - m(O) when mP = O
    f, T, n, steps = ONE, P, 1, 0
    for bit in bin(m)[3:]:               # double, then add when the bit is 1
        v, T = g(T, T, X); f = fm(fm(f, f), v); n, steps = 2 * n, steps + 1
        if log is not None: log.append(f"  double to {n}P = {pt(T)}: f = {show(f)}")
        if bit == "1":
            v, T = g(T, P, X); f = fm(f, v); n, steps = n + 1, steps + 1
            if log is not None: log.append(f"  add P to {n}P = {pt(T)}: f = {show(f)}")
    return f, steps
def road1(m, P, Q):                      # (-1)^m f_P(Q) / f_Q(P)
    r = fm(miller(m, P, Q)[0], fi(miller(m, Q, P)[0]))
    return r if m % 2 == 0 else fs(ZERO, r)
def road2(m, P, Q, R, S):                # f_P(D_Q) / f_Q(D_P), D_P = (P+R) - (R), D_Q = (Q+S) - (S)
    def F(A, B, X): return fm(miller(m, A, X)[0], fi(fpow(g(A, B, X)[0], m)))
    top = fm(F(P, R, add(Q, S)), fi(F(P, R, S)))
    return fm(top, fi(fm(F(Q, S, add(P, R)), fi(F(Q, S, R)))))

pts = [(c(x), c(y)) for x in range(p) for y in range(p) if (y * y - x ** 3 + x) % p == 0]
euler = p + 1 + sum(1 if pow(x ** 3 - x, (p - 1) // 2, p) == 1 else -1
                    for x in range(p) if (x ** 3 - x) % p)
order = lambda P: next(k for k in range(1, 45) if mul(k, P) is None)
G = next(P for P in pts if order(P) == 22)
R, S = G, iota(G)
print(f"y^2 = x^3 - x over F_{p}: {len(pts) + 1} points by listing, {euler} by Euler's test, p + 1 = {p + 1}")
print(f"G = {pt(G)}, order {order(G)}; shifts R = G, S = iota(G) = {pt(S)}")
assert len(pts) + 1 == euler == p + 1
sq = [x for x in range(p) if (x ** 3 - x) % p and pow(x ** 3 - x, (p - 1) // 2, p) == 1]
split = all((x in sq) != (p - x in sq) for x in range(p) if (x ** 3 - x) % p)
print(f"x with x^3 - x a nonzero square: {len(sq)}, one from each pair x, -x: {'yes' if split else 'no'}")
assert split and 2 * len(sq) + 4 == len(pts) + 1
T2 = [P for P in pts if P[1] == ZERO]
print("e_2 on the 2-torsion, road 1 (Miller) / road 2 (divisors):")
for A in T2:
    row = [(road1(2, A, B) if A != B else None, road2(2, A, B, R, S)) for B in T2]
    print(f"  {pt(A):8} " + "  ".join(f"{'n/a' if a is None else pm(a)} / {pm(b)}" for a, b in row))
    assert all(b == (ONE if A == B else c(-1)) and a in (None, b) for (a, b), B in zip(row, T2))
P = mul(2, G); Qd = iota(P)
trace = []
fP, nsteps = miller(11, P, Qd, trace)
alpha = road1(11, P, Qd)
print(f"P = 2G = {pt(P)}, order {order(P)}; iota(P) = {pt(Qd)}")
print(f"Miller, m = 11 = 1011 in binary: {nsteps} line steps; f_P(iota P) = {show(fP)}, "
      f"f_iotaP(P) = {show(miller(11, Qd, P)[0])}")
print("\n".join(trace))
print(f"alpha = e_11(P, iota P) = {show(alpha)} by road 1, {show(road2(11, P, Qd, R, S))} by road 2")
print(f"alpha^11 = {show(fpow(alpha, 11))}; alpha = 1? {'yes' if alpha == ONE else 'no'}")
assert road2(11, P, Qd, R, S) == alpha and alpha != ONE and fpow(alpha, 11) == ONE
E11 = {(a, b): add(mul(a, P), mul(b, Qd)) for a in range(11) for b in range(11)}
bad = 0
for (a, b), A in E11.items():
    for (cc, d), B in E11.items():
        if A is not None and B is not None:
            bad += road2(11, A, B, R, S) != fpow(alpha, (a * d - b * cc) % 11)
print(f"e_11(aP + b iotaP, cP + d iotaP) = alpha^(ad - bc), all 120 x 120 pairs: {bad} failures")
assert bad == 0
d = 7; Q = mul(d, P); beta = road1(11, Q, Qd)
mov = next(k for k in range(11) if fpow(alpha, k) == beta)
brute = next(k for k in range(11) if mul(k, P) == Q)
print(f"secret d = {d}: Q = dP = {pt(Q)}; beta = e_11(Q, iota P) = {show(beta)}")
print(f"MOV: alpha^k = beta in F_43^2 at k = {mov}; brute force on the curve: k = {brute}")
assert mov == brute == d
kap = next(k for k in range(1, 12) if pow(p, k, 11) == 1)
print(f"embedding degree of 11 over F_43: {kap} (43 mod 11 = {p % 11}); the field F_43^{kap} has {p ** kap} elements")
assert kap == 2
a1, b1, c1 = 2, 5, 9
keys = [fpow(road1(11, mul(b1, P), iota(mul(c1, P))), a1),
        fpow(road1(11, mul(a1, P), iota(mul(c1, P))), b1),
        fpow(road1(11, mul(a1, P), iota(mul(b1, P))), c1)]
print(f"three-party key, secrets {a1}, {b1}, {c1}: {', '.join(show(k) for k in keys)}; "
      f"alpha^{a1 * b1 * c1} = {show(fpow(alpha, a1 * b1 * c1))}")
assert keys[0] == keys[1] == keys[2] == fpow(alpha, a1 * b1 * c1)
same = [road2(11, P, mul(k, P), R, S) for k in range(1, 11)]
print(f"mistake 1, no distortion map: e_11(P, kP) for k = 1..10 takes the values {', '.join(sorted(set(show(v) for v in same)))}")
neg = fs(ZERO, alpha)
print(f"mistake 2, sign (-1)^11 dropped: {show(neg)}, whose 11th power is {pm(fpow(neg, 11))}")
wrong = road1(11, G, Qd)
print(f"mistake 3, G of order 22 put into e_11: {show(wrong)}, whose 11th power is {show(fpow(wrong, 11))}")
hn = 1 + sum(1 for x in range(13) for y in range(13) if (y * y - x ** 3 + 2) % 13 == 0)
kh = next(k for k in range(1, 19) if pow(13, k, 19) == 1)
print(f"mistake 4, house curve y^2 = x^3 - 2 mod 13: {hn} points, embedding degree {kh}, "
      f"field of 13^{kh} = {13 ** kh} elements")
assert all(v == ONE for v in same) and fpow(wrong, 11) != ONE
assert hn == 19 and kh == 18
print("ALL CHECKS PASS")
