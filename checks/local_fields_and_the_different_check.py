# Local fields and the different -- the check behind the card.  Nothing is
# imported.  Part 1 completes Q(i) at 5, 3 and 2 by searching roots of
# x^2 + 1 modulo prime powers.  Part 2 reaches the norm of the different two
# ways for four fields with O_K = Z[alpha], the trace-form determinant and the
# norm of f'(alpha); a count of the dual lattice checks the index.  Part 3 reads
# each ramified prime's share of the different off an Eisenstein polynomial.
def ev(f, x):                            # f(x); coefficients lowest first
    return sum(c * x ** k for k, c in enumerate(f))

def roots(f, m):                         # every r mod m with f(r) = 0 mod m, by search
    return [r for r in range(m) if ev(f, r) % m == 0]

def lift(f, df, a, p, k):                # Hensel: one new p-adic digit per step
    out, q = [a], p
    for _ in range(k - 1):
        t = next(t for t in range(p) if (ev(f, a) // q + t * ev(df, a)) % p == 0)
        a, q = a + t * q, q * p
        out.append(a)
    return out

def mulmat(h, f):                        # matrix of "multiply by h(alpha)" on 1, alpha, ...
    n, cols, cur = len(f) - 1, [], h[:] + [0] * len(f)
    for _ in range(n):
        for d in range(len(cur) - 1, n - 1, -1):     # reduce by the monic f
            c, cur[d] = cur[d], 0
            for i in range(n):
                cur[d - n + i] -= c * f[i]
        cols.append(cur[:n])
        cur = [0] + cur[:-1]
    return [[cols[j][i] for j in range(n)] for i in range(n)]

def det(a):                              # Bareiss: exact integer determinant
    a, n, sign, prev = [row[:] for row in a], len(a), 1, 1
    for k in range(n - 1):
        if a[k][k] == 0:
            s = next(i for i in range(k + 1, n) if a[i][k] != 0)
            a[k], a[s], sign = a[s], a[k], -sign
        for i in range(k + 1, n):
            for j in range(k + 1, n):
                a[i][j] = (a[i][j] * a[k][k] - a[i][k] * a[k][j]) // prev
        prev = a[k][k]
    return sign * a[n - 1][n - 1]

def vp(x, p):                            # how many times p divides x
    v = 0
    while x % p == 0:
        x, v = x // p, v + 1
    return v

def dual_count(T, m):                    # a/m, a mod m, with Tr(a/m * alpha^j) whole for all j
    n, hits, a = len(T), 0, [0] * len(T)
    while True:
        hits += all(sum(a[i] * T[i][j] for i in range(n)) % m == 0 for j in range(n))
        i = 0
        while i < n and a[i] == m - 1:
            a[i], i = 0, i + 1
        if i == n:
            return hits
        a[i] += 1

def shift(f, r):                         # coefficients of f(x + r), by Taylor shift
    g, n = f[:], len(f) - 1
    for i in range(n):
        for j in range(n - 1, i - 1, -1):
            g[j] += r * g[j + 1]
    return g

def tform(f):                            # the trace form: Tr(alpha^(i + j)), a matrix trace
    n = len(f) - 1
    return [[sum(mulmat([0] * (i + j) + [1], f)[t][t] for t in range(n)) for j in range(n)] for i in range(n)]

def eisenstein(g, p):
    return g[-1] == 1 and all(c % p == 0 for c in g[:-1]) and g[0] % (p * p) != 0

def yn(claim):
    return "yes" if claim else "no"

def gmul(u, v, m):                       # (a + bi)(c + di) mod m
    return ((u[0] * v[0] - u[1] * v[1]) % m, (u[0] * v[1] + u[1] * v[0]) % m)

def order(u, m):
    x, k = u, 1
    while x != (1, 0):
        x, k = gmul(x, u, m), k + 1
    return k

f = [1, 0, 1]                            # x^2 + 1
counts = {p: [len(roots(f, p ** k)) for k in range(1, 7)] for p in (5, 3, 2)}
for p in (5, 3, 2):
    print(f"roots of x^2 + 1 mod {p}^k, k = 1..6: {counts[p]}")
chain = lift(f, [0, 2], 2, 5, 6)
print(f"i in Q_5, lifted from 2: {chain}")
nonzero = [(a, b) for a in range(3) for b in range(3) if (a, b) != (0, 0)]
inv = [u for u in nonzero if any(gmul(u, v, 3) == (1, 0) for v in nonzero)]
print(f"Z[i]/3: 9 members, {len(inv)} of 8 nonzero invertible; order of i {order((0, 1), 3)}, "
      f"of 1 + i {order((1, 1), 3)}")
sq = gmul((1, 1), (1, 1), 10 ** 6)
pi_poly = shift(f, -1)                   # x^2 + 1 at x - 1: the polynomial of 1 + i
print(f"1 + i: norm 2; (1 + i)^2 = {sq[0]} + {sq[1]}i; its polynomial {pi_poly} "
      f"(lowest first) Eisenstein at 2: {yn(eisenstein(pi_poly, 2))}")
names = {2: "split, two completions Q_5", 1: "ramified, e = 2", 0: "inert, f = 2"}
print("; ".join(f"p = {p}: {names[len(roots(f, p))]}" for p in (5, 3, 2)))

fields = [("Q(i)", "x^2 + 1", [1, 0, 1]), ("Q(sqrt-5)", "x^2 + 5", [5, 0, 1]),
          ("Q(sqrt5)", "x^2 - x - 1", [-1, -1, 1]), ("Q(2^(1/3))", "x^3 - 2", [-2, 0, 0, 1])]
table = []
for name, shown, h in fields:
    n, T = len(h) - 1, tform(h)
    dk, nd = det(T), det(mulmat([k * h[k] for k in range(1, n + 1)], h))
    cnt = dual_count(T, abs(dk))
    print(f"{name:11} {shown:12} d_K by trace form {dk:5}; N(f'(alpha)) {nd:5}; dual lattice index {cnt:4}")
    print(f"  trace form {T}")
    prod = 1
    for p in (q for q in (2, 3, 5) if dk % q == 0):
        r = next(r for r in range(p) if eisenstein(shift(h, r), p))
        g = shift(h, r)                  # pi = alpha - r is a uniformiser; e = n, f = 1
        v = min(n * vp(j * g[j], p) + j - 1 for j in range(1, n + 1) if g[j])
        kind = "tame" if n % p else "wild"
        print(f"  at {p}: pi = alpha - {r}, e = {n}; v(different) {v} by Eisenstein, "
              f"{vp(abs(nd), p)} from the norm; tame rule e - 1 = {n - 1}: {kind}")
        table.append((name, p, n, v, vp(abs(nd), p), kind))
        prod *= p ** v
    assert prod == abs(nd) == abs(dk) == cnt                  # three roads and the index count
    assert dk == (-1) ** (n * (n - 1) // 2) * nd
print(f"mistake 1, tame rule at 2 in Q(i): norm 2^1 = {2 ** 1}, not {2 ** table[0][3]}")
z5 = [-5, 0, 1]
nz, d5 = det(mulmat([0, 2], z5)), dual_count(tform(z5), 20)
print(f"mistake 2, Z[sqrt5] for Q(sqrt5): N(2 sqrt5) = {nz}, dual index {d5}, "
      f"roots of x^2 - 5 mod 2: {len(roots(z5, 2))} (a double root), not d_K = 5")
print(f"mistake 3, lifting the root 1 of x^2 + 1 mod 2: roots mod 4 = {len(roots(f, 4))}")
print(f"mistake 4, 5 read as one completion of degree 2: {len(roots(f, 5))} roots mod 5, "
      f"so {len(roots(f, 5))} completions of degree 1")
assert counts == {5: [2] * 6, 3: [0] * 6, 2: [1, 0, 0, 0, 0, 0]}
assert all((a * a + 1) % 5 ** (k + 1) == 0 for k, a in enumerate(chain))
assert len(inv) == 8 and order((1, 1), 3) == 8 and sq == (0, 2)
assert all(v == e - 1 if kind == "tame" else v >= e for _, _, e, v, w, kind in table)
assert all(v == w for _, _, _, v, w, _ in table)          # Eisenstein road against the norm road
assert nz == -20 and d5 == 20 and len(roots(z5, 2)) == 1
assert not any(eisenstein(shift([3, 0, 1], r), 2) for r in range(2))   # x^2 + 2x + 4 fails only the p^2 test
print("ALL CHECKS PASS")
