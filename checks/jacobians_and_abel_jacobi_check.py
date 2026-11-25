# The Jacobian of the genus-2 curve y^2 = x^5 + x + 1 over F_5 -- the check behind the card.
# Nothing imported.  F_25 is F_5 with a new element t, t^2 = 2; the number a + 5b stands for
# a + b t, so 0..4 are F_5 itself.  A polynomial is a list of coefficients, lowest power first.
def add25(a, b): return (a + b) % 5 + 5 * ((a // 5 + b // 5) % 5)
def mul25(a, b): return (a % 5 * (b % 5) + 2 * (a // 5) * (b // 5)) % 5 + 5 * ((a % 5 * (b // 5) + a // 5 * (b % 5)) % 5)
ADD = [[add25(a, b) for b in range(25)] for a in range(25)]
MUL = [[mul25(a, b) for b in range(25)] for a in range(25)]
NEG = [ADD[a].index(0) for a in range(25)]
INV = {a: MUL[a].index(1) for a in range(1, 25)}

def trim(a):
    while a and a[-1] == 0: a = a[:-1]
    return a
def padd(a, b):
    n = max(len(a), len(b))
    return trim([ADD[x][y] for x, y in zip(a + [0] * (n - len(a)), b + [0] * (n - len(b)))])
def pneg(a): return [NEG[x] for x in a]
def scale(c, a): return trim([MUL[c][x] for x in a])
def pmul(a, b):
    r = [0] * max(len(a) + len(b) - 1, 0)
    for i, x in enumerate(a):
        for j, y in enumerate(b): r[i + j] = ADD[r[i + j]][MUL[x][y]]
    return trim(r)
def pdivmod(a, b):                        # long division by a nonzero b
    a, qt = trim(a[:]), [0] * max(len(a) - len(b) + 1, 0)
    while len(a) >= len(b):
        c, s = MUL[a[-1]][INV[b[-1]]], len(a) - len(b)
        qt[s] = c
        a = padd(a, pneg([0] * s + scale(c, b)))
    return trim(qt), a
def xgcd(a, b):                           # Euclid, keeping d = s a + t b, d monic
    r0, r1, s0, s1, t0, t1 = a, b, [1], [], [], [1]
    while r1:
        qt, r = pdivmod(r0, r1)
        r0, r1, s0, s1, t0, t1 = r1, r, s1, padd(s0, pneg(pmul(qt, s1))), t1, padd(t0, pneg(pmul(qt, t1)))
    c = INV[r0[-1]]
    return scale(c, r0), scale(c, s0), scale(c, t0)
def ev(a, x):
    out = 0
    for c in reversed(a): out = ADD[MUL[out][x]][c]
    return out

def cantor(D1, D2, f, g, keep=None):      # add two classes (u, v); reduce until deg u <= g
    (u1, v1), (u2, v2) = D1, D2
    d1, e1, e2 = xgcd(u1, u2)
    d, c1, c2 = xgcd(d1, padd(v1, v2))
    u = pdivmod(pmul(u1, u2), pmul(d, d))[0]
    w = padd(padd(pmul(pmul(c1, e1), pmul(u1, v2)), pmul(pmul(c1, e2), pmul(u2, v1))), pmul(c2, padd(pmul(v1, v2), f)))
    v = pdivmod(pdivmod(w, d)[0], u)[1]
    if keep is not None: keep.append((u, v))
    while len(u) - 1 > g:
        u = pdivmod(padd(f, pneg(pmul(v, v))), u)[0]
        v = pdivmod(pneg(v), u)[1]
    return scale(INV[u[-1]], u), v

def pairs(f, q, top):                     # every (u, v): u monic, deg v < deg u <= top, u | v^2 - f
    out = []
    for d in range(top + 1):
        for k in range(q ** d):
            u = [k // q ** i % q for i in range(d)] + [1]
            for m in range(q ** d):
                v = trim([m // q ** i % q for i in range(d)])
                if not pdivmod(padd(f, pneg(pmul(v, v))), u)[1]: out.append((u, v))
    return out
def npoints(f, q): return 1 + sum(1 for x in range(q) for y in range(q) if MUL[y][y] == ev(f, x))
def px(a): return " + ".join((str(c) if c != 1 or i == 0 else "") + ("", "x", f"x^{i}")[min(i, 2)]
                            for i, c in reversed(list(enumerate(a))) if c) or "0"
def yn(b): return "yes" if b else "no"
def show(D): return "(" + ", ".join(px(a) for a in D) + ")"

f, q, g = [1, 1, 0, 0, 0, 1], 5, 2
deriv = trim([i * c % 5 for i, c in enumerate(f)][1:])
print(f"curve y^2 = x^5 + x + 1 over F_5; gcd(f, f') = {px(xgcd(f, deriv)[0])}, so smooth; genus {g}")
pts = [(x, y) for x in range(q) for y in range(q) if MUL[y][y] == ev(f, x)]
N1, N2 = npoints(f, 5), npoints(f, 25)
print(f"affine points over F_5: {pts}; with the point at infinity N1 = {N1}")
print(f"f(x) at x = 0..4: {[ev(f, x) for x in range(5)]}; monic u of degree <= 2: {1 + 5 + 25} over F_5, {1 + 25 + 625} over F_25")
print(f"points over F_25: N2 = {N2}")
a1 = N1 - q - 1
a2 = (N2 - q * q - 1 + a1 * a1) // 2
L1, Lm1 = 1 + a1 + a2 + q * a1 + q * q, 1 - a1 + a2 - q * a1 + q * q
print(f"L-polynomial: 1 + {a1}T + {a2}T^2 + {q * a1}T^3 + {q * q}T^4; L(1) = {L1}, L(-1) = {Lm1}")
sym2 = (N1 * N1 + N2) // 2
print(f"effective degree-2 divisors: {N1 * (N1 + 1) // 2} rational pairs + {(N2 - N1) // 2} conjugate pairs = {sym2}")
print(f"formula (N1^2 + N2)/2 - q = {sym2} - {q} = {sym2 - q}")
J = pairs(f, q, g)
by_deg = [sum(1 for u, v in J if len(u) - 1 == d) for d in range(3)]
print(f"reduced pairs (u, v) by deg u = 0, 1, 2: {by_deg}; total #Jac(F_5) = {len(J)}")
print(f"the {sym2} split as {by_deg[2]} + {by_deg[1]} + {q + 1}: one class each, and q + 1 = 6 on the canonical class")
J25 = len(pairs(f, 25, g))
print(f"#Jac(F_25) by enumeration = {J25}; L(1) L(-1) = {L1 * Lm1}")
lo, hi = (5 ** 0.5 - 1) ** 4, (5 ** 0.5 + 1) ** 4
print(f"Weil window for #Jac(F_5): {lo:.2f} to {hi:.2f}; q^g = {q ** g}")
D1, D2, D3 = ([0, 1], [1]), ([1, 1], [2]), ([3, 1], [])
print(f"D1 = (0, 1) - oo is {show(D1)}; D2 = (4, 2) - oo is {show(D2)}; D3 = (2, 0) - oo is {show(D3)}")
print(f"D1 + D2 = {show(cantor(D1, D2, f, g))}")
two = cantor(D1, D1, f, g)
raw = []
three = cantor(two, D1, f, g, raw)
print(f"2 D1 = {show(two)}; 3 D1 before reduction {show(raw[0])}, after {show(three)}")
print(f"u = x^2 + x + 2 has no root in F_5: {yn(all(ev(three[0], x) for x in range(5)))}; f = (x - 2)(x^2 + x + 2)(x^2 + x + 1): {yn(pmul(pmul([3, 1], [2, 1, 1]), [1, 1, 1]) == f)}")
key = {show(D) for D in J}
closed = all(show(cantor(A, B, f, g)) in key for A in J for B in J)
orders = []
for A in J:
    k, B = 1, A
    while B != ([1], []): k, B = k + 1, cantor(B, A, f, g)
    orders.append(k)
print(f"every sum of two of the 36 is one of the 36: {yn(closed)}")
print(f"orders: " + ", ".join(f"{k}: {orders.count(k)}" for k in sorted(set(orders))) + f"; exponent {max(orders)}, so (Z/6)^2; D1 has order {orders[J.index(D1)]}")
semi = len(pairs(f, q, 3))
print(f"mistake 1, drop the - q: {sym2}; mistake 2, drop infinity: ({(N1 - 1) ** 2} + {N2 - 1})/2 - 5 = {((N1 - 1) ** 2 + N2 - 1) // 2 - 5}")
print(f"mistake 3, stop before reducing: pairs with deg u <= 3 number {semi}, not {len(J)}")
fE = [1, 0, 1, 1]
JE = pairs(fE, q, 1)
def chord(P, Q):                          # the chord-and-tangent law on y^2 = x^3 + x^2 + 1
    if P is None or Q is None: return Q if P is None else P
    if P[0] == Q[0] and ADD[P[1]][Q[1]] == 0: return None
    m = MUL[ADD[P[1]][NEG[Q[1]]]][INV[ADD[P[0]][NEG[Q[0]]]]] if P != Q else MUL[ADD[MUL[3][MUL[P[0]][P[0]]]][MUL[2][P[0]]]][INV[MUL[2][P[1]]]]
    x = ADD[ADD[MUL[m][m]][NEG[1]]][NEG[ADD[P[0]][Q[0]]]]
    return x, NEG[ADD[P[1]][MUL[m][ADD[x][NEG[P[0]]]]]]
def aj(P): return ([1], []) if P is None else ([NEG[P[0]], 1], trim([P[1]]))   # P -> class of P - O
ptsE = [None] + [(x, y) for x in range(q) for y in range(q) if MUL[y][y] == ev(fE, x)]
agree = all(cantor(aj(P), aj(Q), fE, 1) == aj(chord(P, Q)) for P in ptsE for Q in ptsE)
print(f"genus 1, y^2 = x^3 + x^2 + 1: {len(ptsE)} points, {len(JE)} classes; Cantor = chord-and-tangent on all 25 pairs: {yn(agree)}")
print(f"(0, 1) + (4, 4) = {chord((0, 1), (4, 4))}; Cantor gives {show(cantor(aj((0, 1)), aj((4, 4)), fE, 1))}")
fH = [0, 0, 1, 1]
smooth = [([1], [])] + [aj((x, y)) for x in range(1, q) for y in range(q) if MUL[y][y] == ev(fH, x)]
sk = {show(D) for D in smooth}
okH = all(show(cantor(A, B, fH, 1)) in sk for A in smooth for B in smooth)
print(f"mistake 4, nodal y^2 = x^3 + x^2: {npoints(fH, 5)} points, but the smooth ones give a group of {len(smooth)} (closed: {yn(okH)})")
assert len(J) == sym2 - q == 36                 # enumeration = divisor count
assert J25 == L1 * Lm1 == 1296                  # over F_25, enumeration = L(1) L(-1)
assert by_deg[2] + by_deg[1] + q + 1 == sym2    # the fibres of Sym^2 over the Jacobian
assert closed and max(orders) == 6 and three == ([2, 1, 1], [])
assert agree and len(JE) == len(ptsE) == 5      # genus 1: Jacobian = curve
assert okH and len(smooth) == 4 != npoints(fH, 5)
print("ALL CHECKS PASS")
