# Point arithmetic and double-and-add -- the check behind the card.  Standard library only;
# Fraction is exact fraction arithmetic, nothing more.  Curve y^2 = x^3 - 2, point P = (3, 5).
# Over Q the fractions explode, so 1000P is found modulo the prime p = 1087: in plain (affine)
# coordinates, one division per step, and in Jacobian coordinates, one division at the end.
from fractions import Fraction as Fr
from math import log10, sqrt
p, b, P, N = 1087, -2, (3, 5), 1000
cnt = {"mul": 0, "inv": 0, "invmul": 0}    # multiplications mod p (squarings too); inversions

def fm(u, v, md=p):                        # one counted multiplication; md = 0 means plain integers
    cnt["mul"] += 1
    return u * v % md if md else u * v

def inv(u):                                # Fermat: u^(p-2) mod p by square-and-multiply
    if u % p == 0: raise ZeroDivisionError("no inverse of 0 mod 1087")
    cnt["inv"] += 1; r = u
    for bit in bin(p - 2)[3:]:
        r = r * r % p; cnt["invmul"] += 1
        if bit == "1": r = r * u % p; cnt["invmul"] += 1
    return r

def aff_add(A, C, three=3):                # chord-and-tangent rule mod p; O is None
    if A is None or C is None: return C if A is None else A
    (x1, y1), (x2, y2) = A, C
    if x1 == x2 and (y1 + y2) % p == 0: return None                  # vertical line
    if A == C: m = fm(three * fm(x1, x1), inv(2 * y1))                 # tangent slope
    else: m = fm(y2 - y1, inv(x2 - x1))                               # chord slope
    x3 = (fm(m, m) - x1 - x2) % p
    return (x3, (fm(m, x1 - x3) - y1) % p)

def jac_dbl(J, md=p):                      # tangent rule with the denominator kept as Z
    X, Y, Z = J
    YY = fm(Y, Y, md); S = 4 * fm(X, YY, md); T = 3 * fm(X, X, md)
    X3 = fm(T, T, md) - 2 * S
    J3 = (X3, fm(T, S - X3, md) - 8 * fm(YY, YY, md), 2 * fm(Y, Z, md))
    return tuple(v % md for v in J3) if md else J3
def jac_add(J, A, md=p):                   # chord rule: J in Jacobian, A = (x, y) plain
    X, Y, Z = J
    ZZ = fm(Z, Z, md); H = fm(A[0], ZZ, md) - X; R = fm(A[1], fm(Z, ZZ, md), md) - Y
    HH = fm(H, H, md); HHH = fm(H, HH, md); V = fm(X, HH, md)
    X3 = fm(R, R, md) - HHH - 2 * V
    J3 = (X3, fm(R, V - X3, md) - fm(Y, HHH, md), fm(Z, H, md))
    return tuple(v % md for v in J3) if md else J3
def to_affine(J):                          # the one division: x = X/Z^2, y = Y/Z^3
    if J[2] == 0: return None
    zi = inv(J[2]); zz = fm(zi, zi)
    return (fm(J[0], zz), fm(J[1], fm(zz, zi)))
def times(n, A, dbl, add, acc):            # left-to-right double-and-add on the bits of n
    ops = [0, 0]
    for bit in bin(n)[3:]:
        acc = dbl(acc); ops[0] += 1
        if bit == "1": acc = add(acc, A); ops[1] += 1
    return acc, ops
def run(f):                                # run f with fresh counters; report what it cost
    for k in cnt: cnt[k] = 0
    out = f()
    return out, cnt["inv"], cnt["mul"]
show = lambda A: "O" if A is None else f"({A[0]}, {A[1]})"
aff_times = lambda n, A: times(n, A, lambda Q: aff_add(Q, Q), aff_add, A)
jac_times = lambda n, A: times(n, A, jac_dbl, jac_add, (A[0], A[1], 1))
# ---- over Q: exact fractions, and the denominators' own integer recursion ----
def q_add(A, C):
    m = 3 * A[0] ** 2 / (2 * A[1]) if A == C else (C[1] - A[1]) / (C[0] - A[0])
    x3 = m * m - A[0] - C[0]
    return (x3, m * (A[0] - x3) - A[1])
x, y = P
psi = [0, 1, 2 * y, 3 * x ** 4 + 12 * b * x, 4 * y * (x ** 6 + 20 * b * x ** 3 - 8 * b * b)]
for n in range(5, 11):                     # division polynomials at P; exact integer steps
    m = n // 2
    psi.append(psi[m + 2] * psi[m] ** 3 - psi[m - 1] * psi[m + 1] ** 3 if n % 2 else
               psi[m] * (psi[m + 2] * psi[m - 1] ** 2 - psi[m - 2] * psi[m + 1] ** 2) // (2 * y))
mults, digits = [(Fr(3), Fr(5))], []
for n in range(2, 11): mults.append(q_add(mults[-1], mults[0]))
for n in range(1, 11):
    d = mults[n - 1][0].denominator
    assert d == psi[n] ** 2                                     # two roads to every denominator
    digits.append(int(2 * log10(abs(psi[n]))) + 1)
    assert digits[-1] == len(str(d))
two = mults[1]; J2 = jac_dbl((3, 5, 1), 0); J3 = jac_add(J2, P, 0)
for k, Jk in ((1, J2), (2, J3)):          # chord-tangent = Jacobian, over Q, for 2P and 3P
    assert mults[k] == (Fr(Jk[0], Jk[2] ** 2), Fr(Jk[1], Jk[2] ** 3))
rate = 2 * log10(abs(psi[10])) / 100
print(f"curve y^2 = x^3 - 2, P = (3, 5): 5^2 = 25 = 3^3 - 2")
print(f"over Q, tangent slope at P: 3*3^2/(2*5) = {Fr(27, 10)}; 2P = ({two[0]}, {two[1]})")
print(f"Jacobian doubling of (3 : 5 : 1), integers only: S = {4 * x * y * y}, T = {3 * x * x}, 8Y^4 = {8 * y ** 4} -> ({J2[0]} : {J2[1]} : {J2[2]})")
H, R = x * J2[2] ** 2 - J2[0], y * J2[2] ** 3 - J2[1]          # x2 Z^2 - X and y2 Z^3 - Y
print(f"Jacobian addition 2P + P: H = {H}, R = {R}, R^2 = {R * R}, H^3 = {H ** 3}, 2XH^2 = {2 * J2[0] * H * H}")
print(f"  3P = ({J3[0]} : {J3[1]} : {J3[2]}) -> x = {mults[2][0]}, y = {mults[2][1]}")
print("digits in the denominator of x(nP), n = 1..10:", *digits)
print(f"log10(denominator) / n^2 at n = 10: {rate:.4f}; estimate for x(1000P): about {round(rate * 1e6, -4):.0f} digits")
# ---- modulo p = 1087 ----
sq = [sum(1 for v in range(p) if v * v % p == r) for r in range(p)]   # square roots of each r
order = 1 + sum(sq[(u ** 3 + b) % p] for u in range(p))      # count the points, O included
print(f"mod {p}: points on the curve, counted x by x: {order}; Hasse window {p + 1} +- {2 * sqrt(p):.2f}")
bits = bin(N)[2:]; chain = [1]
for bit in bits[1:]: chain += [2 * chain[-1]] + ([2 * chain[-1] + 1] if bit == "1" else [])
print(f"{N} in binary: {bits}; chain:", *chain)
(A1, ops), i1, m1 = run(lambda: aff_times(N, P))
(J, _), i2, m2 = run(lambda: jac_times(N, P)); A2, i3, m3 = run(lambda: to_affine(J))
I = cnt["invmul"]; e = p - 2; Ie = len(bin(e)) - 3 + bin(e).count("1") - 1
P2, J2p = aff_add(P, P), jac_dbl((3, 5, 1))
ad, aa = run(lambda: aff_add(P, P))[2], run(lambda: aff_add(P2, P))[2]
jd, ja = run(lambda: jac_dbl(J2p))[2], run(lambda: jac_add(J2p, P))[2]
print(f"{ops[0]} doublings + {ops[1]} additions = {sum(ops)} curve operations, not {len(bits) - 1 + bits.count('1')}: the top bit is the start")
print(f"multiplications per step, I = one inversion: affine doubling {ad} + I, addition {aa} + I;"
      f" Jacobian doubling {jd}, addition {ja}, back to affine {m3} + I")
print(f"affine:   {N}P = {show(A1)}; {i1} inversions, {m1} other multiplications")
print(f"Jacobian: ({J[0]} : {J[1]} : {J[2]}) -> {N}P = {show(A2)}; {i2 + i3} inversion, {m2 + m3} other multiplications")
print(f"one inversion: p - 2 = {e} = {bin(e)[2:]}: {len(bin(e)) - 3} squarings + {bin(e).count('1') - 1} multiplications = {Ie}")
print(f"total multiplications at p = {p}: affine {m1 + i1 * Ie}, Jacobian {m2 + m3 + Ie}, ratio {(m1 + i1 * Ie) / (m2 + m3 + Ie):.1f}")
A3, i4 = P, 0
for _ in range(N - 1): A3, i4 = aff_add(A3, P), i4 + 1
print(f"{N - 1} additions one at a time: {N}P = {show(A3)}; {i4} inversions")
Jo = jac_times(order, P)[0]; A33 = P
for _ in range(32): A33 = aff_add(A33, P)
print(f"{order}P by double-and-add: Z = {Jo[2]}, so {order}P = O; 33P = {show(A33)}; -33P = {show((A33[0], -A33[1] % p))}")
red = lambda q: q.numerator * inv(q.denominator) % p
print(f"2P mod {p}: by the tangent rule {show(P2)}; 129/100 and -383/1000 reduced {show((red(two[0]), red(two[1])))}")
big = 2 ** 256 - 2 ** 32 - 977 - 2; Ib = len(bin(big)) - 3 + bin(big).count("1") - 1
print(f"secp256k1 prime 2^256 - 2^32 - 977: one inversion = {Ib} multiplications")
print(f"  {N}P there: affine {m1 + i1 * Ib}, Jacobian {m2 + m3 + Ib}, ratio {(m1 + i1 * Ib) / (m2 + m3 + Ib):.1f}")
ka, kj = 255 * (ad + Ib) + 128 * (aa + Ib), 255 * jd + 128 * ja + m3 + Ib
print(f"  key with 255 doublings, 128 additions: affine {ka}, Jacobian {kj}, ratio {ka / kj:.1f}")
try: aff_add(P, (3, 5 + p))
except ZeroDivisionError as err: print(f"mistake, chord slope used to double P: x2 - x1 = 0, {err}")
Jbad = jac_add((3, 5, 1), P)
print(f"mistake, Jacobian addition used to double P: ({Jbad[0]} : {Jbad[1]} : {Jbad[2]}), not a point")
W = aff_add(P, P, 1); on = lambda A: (A[1] ** 2 - A[0] ** 3 - b) % p == 0
print(f"mistake, tangent slope without the 3: 2P = {show(W)}, on the curve: {'yes' if on(W) else 'no'}")
Wz = (fm(J[0], inv(J[2])), fm(J[1], inv(J[2])))
print(f"mistake, Jacobian read as x = X/Z, y = Y/Z: {show(Wz)}, on the curve: {'yes' if on(Wz) else 'no'}")
print(f"mistake, bits read right to left: {bits[::-1]} = {(rev := int(bits[::-1], 2))}, gives {rev}P = {show(aff_times(rev, P)[0])}")
for n in (1023, 1024): print(f"try: {n} = {bin(n)[2:]}: {aff_times(n, P)[1][0]} doublings + {aff_times(n, P)[1][1]} additions")
print(f"try: {N} times (3, -5) = {show(aff_times(N, (3, p - 5))[0])}")
assert abs(order - p - 1) <= 2 * sqrt(p) and Jo[2] == 0       # count in Hasse's window; 1033P = O
assert A1 == A2 == A3 == (A33[0], -A33[1] % p) == (498, 929)  # four roads to 1000P
assert I == Ie and sum(ops) == bits.count("1") - 1 + len(bits) - 1   # counted costs vs bit counts
assert P2 == (red(two[0]), red(two[1]))                       # mod p agrees with the exact answer
assert not on(W) and not on(Wz)                               # the two wrong points are off the curve
print("ALL CHECKS PASS")
