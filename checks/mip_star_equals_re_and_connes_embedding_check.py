# MIP* = RE and Connes' embedding -- the check behind the card.  Standard library only.
# Part 1: the CHSH game, squeezed from below (strategy search) and above (an exact
# sum of squares).  Part 2: primality three ways, and Huang's theorem on small cubes.
from math import cos, sin, pi, sqrt, gcd, isqrt
from itertools import product
# ---- part 1a: classical strategies, all 16 answer tables a[x], b[y]
tables = [sum((t[x] ^ t[2 + y]) == (x & y) for x in (0, 1) for y in (0, 1))
          for t in product((0, 1), repeat=4)]  # win when a XOR b = x AND y
classical = max(tables) / 4
print(f"classical: 16 answer tables, {tables.count(3)} win 3 of 4, best {classical:.6f}")
# ---- part 1b: entangled lower bounds, state vector of (|00> + |11>)/sqrt2
def basis(t, a):  # outcome a of a measurement at angle t, as a real 2-vector
    return (cos(t), sin(t)) if a == 0 else (-sin(t), cos(t))
def win(al, be):  # al[x], be[y] are the measuring angles; returns the win chance
    tot = 0.0
    for x, y, a, b in product((0, 1), repeat=4):
        u, v = basis(al[x], a), basis(be[y], b)
        amp = (u[0] * v[0] + u[1] * v[1]) / sqrt(2)
        tot += amp * amp * ((a ^ b) == (x & y)) / 4
    return tot
lower = {}
for m in (2, 4, 8, 16):  # try every angle k*pi/m for each of the four settings
    g = [k * pi / m for k in range(m)]
    lower[m] = max(win((p, q), (r, s)) for p, q, r, s in product(g, repeat=4))
    print(f"lower bound, angles in steps of pi/{m:<2}: best win {lower[m]:.6f}")
best = win((0, pi / 4), (pi / 8, -pi / 8))
print(f"strategy A at 0 or pi/4, B at pi/8 or -pi/8: win {best:.12f}")
print(f"<W> = 8 x (win - 1/2) = {8 * (best - 0.5):.6f}; 2*sqrt2 = {2 * sqrt(2):.6f}")
print(f"cos^2(pi/8) = {cos(pi / 8) ** 2:.12f}, (2 + sqrt2)/4 = {(2 + sqrt(2)) / 4:.12f}")
# ---- part 1c: upper bound.  A coefficient (p, q) means (p + q*sqrt2)/4
def red(w, commute):  # each observable squares to I; A's pass B's if they commute
    parts = [[t for t in w if t[0] == s] for s in "AB"] if commute else [list(w)]
    out = []
    for part in parts:
        st = []
        for t in part:
            st.pop() if st and st[-1] == t else st.append(t)
        out += st
    return tuple(out)
def mul(P, Q, commute=True):
    R = {}
    for (w1, (p1, q1)), (w2, (p2, q2)) in product(P.items(), Q.items()):
        p, q = p1 * p2 + 2 * q1 * q2, p1 * q2 + q1 * p2
        assert p % 4 == 0 and q % 4 == 0
        w = red(w1 + w2, commute); o = R.get(w, (0, 0)); R[w] = (o[0] + p // 4, o[1] + q // 4)
    return {w: c for w, c in R.items() if c != (0, 0)}
def add(P, Q):
    R = dict(P)
    for w, (p, q) in Q.items(): o = R.get(w, (0, 0)); R[w] = (o[0] + p, o[1] + q)
    return {w: c for w, c in R.items() if c != (0, 0)}
X0 = {("A0",): (4, 0), ("B0",): (0, -2), ("B1",): (0, -2)}  # A0 - (B0 + B1)/sqrt2
X1 = {("A1",): (4, 0), ("B0",): (0, -2), ("B1",): (0, 2)}   # A1 - (B0 - B1)/sqrt2
def sos(c):  # (1/sqrt2) (X0^2 + X1^2)
    return mul({(): (0, 2)}, add(mul(X0, X0, c), mul(X1, X1, c)), c)
lhs = {(): (0, 8), ("A0", "B0"): (-4, 0), ("A0", "B1"): (-4, 0),
       ("A1", "B0"): (-4, 0), ("A1", "B1"): (4, 0)}         # 2 sqrt2 I - W
yn = lambda c: "yes" if c else "no"
print(f"sum of squares equals 2*sqrt2 - W, exactly: {yn(sos(True) == lhs)}")
upper = 0.5 + 2 * sqrt(2) / 8
print(f"upper bound for commuting operators: 1/2 + 2*sqrt2/8 = {upper:.12f}")
print(f"CHSH squeeze: |upper - lower| = {abs(upper - lower[16]):.12f}")
print(f"same identity if A's need not commute with B's: {yn(sos(False) == lhs)}, "
      f"{len(sos(False))} terms against {len(lhs)}")
# ---- part 2a: primality, by trial division, Miller-Rabin and AKS
trial = lambda n: n > 1 and all(n % d for d in range(2, isqrt(n) + 1))
def strong(n, a):  # a passes the Miller-Rabin round for odd n
    d, s = n - 1, 0
    while d % 2 == 0:
        d, s = d // 2, s + 1
    x = pow(a, d, n)
    for _ in range(s):
        if x == 1 or x == n - 1:
            return x == n - 1 or _ == 0
        x = x * x % n
    return False
mr = lambda n: n in (2, 3) or (n > 3 and n % 2 == 1 and strong(n, 2) and strong(n, 3))  # exact below 1,373,653
def mulp(f, g, n, r):  # product modulo x^r - 1 and modulo n
    h = [0] * r
    for i, j in product(range(r), range(r)):
        h[(i + j) % r] = (h[(i + j) % r] + f[i] * g[j]) % n
    return h
def congruent(n, r, a):  # (x + a)^n = x^n + a modulo x^r - 1 and n? by repeated squaring
    res, base, e = [1] + [0] * (r - 1), [a % n, 1] + [0] * (r - 2), n
    while e: res, base, e = (mulp(res, base, n, r) if e & 1 else res), mulp(base, base, n, r), e >> 1
    want = [0] * r; want[n % r] = 1; want[0] = (want[0] + a) % n
    return res == want
def aks(n):  # log2 n is replaced by n's bit length l, which only adds work
    l = n.bit_length()
    if n < 2 or any(c ** b == n for b in range(2, l + 1) for c in range(2, isqrt(n) + 1)):
        return False, 0, "below 2 or a perfect power"
    r = 2  # the least r with n's order modulo r above l^2
    while gcd(r, n) != 1 or any(pow(n, k, r) == 1 for k in range(1, l * l + 1)):
        r += 1
    for a in range(2, min(r, n - 1) + 1):
        if 1 < gcd(a, n) < n:
            return False, r, f"factor {gcd(a, n)} found"
    if n <= r:
        return True, r, "n <= r"
    lim = (isqrt(sum(gcd(k, r) == 1 for k in range(1, r))) + 1) * l
    for a in range(1, lim + 1):
        if not congruent(n, r, a): return False, r, f"(x + {a})^n test failed"
    return True, r, f"{lim} polynomial tests passed"
N = 100
agree = all(trial(n) == mr(n) == aks(n)[0] for n in range(1, N + 1))
print(f"n = 1 to {N}: trial division, Miller-Rabin and AKS agree: {yn(agree)}; "
      f"{sum(map(trial, range(N + 1)))} primes")
for n in (31, 561):
    v, r, why = aks(n)
    print(f"AKS on {n}: r = {r}, {why}, verdict {'prime' if v else 'composite'}")
alone = [a for a in range(1, 4) if not congruent(561, aks(561)[1], a)]  # the factor step skipped
print(f"AKS on 561, factor step skipped: r = {aks(561)[1]}, the (x + a)^561 test fails for a = {alone}")
liars = [a for a in range(1, 561) if strong(561, a)]
print(f"561 = 3 x 11 x 17: Fermat base 2 gives 2^560 mod 561 = {pow(2, 560, 561)}; "
      f"Miller-Rabin base 2 passes: {yn(strong(561, 2))}")
print(f"561: strong liars {len(liars)} of 560 bases, share {len(liars) / 560:.6f} (bound 1/4)")
# ---- part 2b: Huang's signed cube matrix, and induced subgraphs of the n-cube
for n in (3, 4):
    A = [[0]]
    for _ in range(n):  # A_n = [[A, I], [I, -A]]
        k = len(A)
        A = [[A[i][j] if i < k and j < k else -A[i - k][j - k] if i >= k and j >= k
              else int(i % k == j % k) for j in range(2 * k)] for i in range(2 * k)]
    k = len(A)
    sq = all(sum(A[i][t] * A[t][j] for t in range(k)) == n * (i == j)
             for i in range(k) for j in range(k))
    def maxdeg(mask):  # the most neighbours any chosen corner has among the chosen
        return max(sum(mask >> (v ^ (1 << b)) & 1 for b in range(n))
                   for v in range(k) if mask >> v & 1)
    h1, h0 = [min(maxdeg(m) for m in range(1 << k) if bin(m).count("1") == size)
              for size in (k // 2 + 1, k // 2)]
    print(f"{n}-cube: A^2 = {n} I: {yn(sq)}; any {k // 2 + 1} corners have "
          f"max degree >= {h1} (sqrt {n} = {sqrt(n):.6f}); {k // 2} corners can have {h0}")
    assert sq and h1 >= sqrt(n) and h0 == 0
assert classical == 0.75 and tables.count(3) == 8
assert abs(lower[8] - (2 + sqrt(2)) / 4) < 1e-12 and abs(best - cos(pi / 8) ** 2) < 1e-12
assert lower[4] < lower[8]
assert sos(True) == lhs and sos(False) != lhs and abs(upper - lower[16]) < 1e-12
assert agree and not aks(561)[0] and aks(31) == (True, 29, "30 polynomial tests passed") and 1 in alone
assert pow(2, 560, 561) == 1 and len(liars) <= 560 // 4
print("ALL CHECKS PASS")
