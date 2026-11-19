# The curve mod p and Hasse's bound -- the check behind the card.  Nothing is
# imported.  The curve is y^2 = x^3 - 2, with the rational point (3, 5).  Its
# points mod p are counted three ways: by trying every pair (x, y), by Euler's
# square test on each x, and over the 49-element field, where Frobenius
# predicts the count.  Bad primes come from the discriminant and, separately,
# from a hunt for singular points.
B = -2                                       # the curve is y^2 = x^3 + B

def f(x, p):                                 # the right-hand side, mod p
    return (x * x * x + B) % p

def power(a, k, p):                          # square-and-multiply, mod p
    out, a = 1, a % p
    while k:
        if k & 1:
            out = out * a % p
        a, k = a * a % p, k >> 1
    return out

def euler(v, p):                             # Euler's test: +1, -1 or 0
    t = power(v, (p - 1) // 2, p)
    return -1 if t == p - 1 else t

def count_pairs(p):                          # road 1: every pair, plus O
    return 1 + sum(1 for x in range(p) for y in range(p) if (y * y - f(x, p)) % p == 0)

def count_euler(p):                          # road 2: 1 + (f(x)/p) points per x
    return p + 1 + sum(euler(f(x, p), p) for x in range(p))

def yn(claim):
    return "yes" if claim else "no"

def primes(n):
    return [q for q in range(2, n) if all(q % d for d in range(2, q) if d * d <= q)]

def add(P, Q, p):                            # chord and tangent, mod p; None is O
    if P is None or Q is None:
        return Q if P is None else P
    (x1, y1), (x2, y2) = P, Q
    if x1 == x2 and (y1 + y2) % p == 0:
        return None
    if P == Q:
        m = 3 * x1 * x1 * power(2 * y1, p - 2, p) % p
    else:
        m = (y2 - y1) * power(x2 - x1, p - 2, p) % p
    x3 = (m * m - x1 - x2) % p
    return (x3, (m * (x1 - x3) - y1) % p)

def fadd(a, b):                              # exact fractions as (top, bottom)
    t, d = a[0] * b[1] + b[0] * a[1], a[1] * b[1]
    g = gcd(t, d)
    return (t // g, d // g)

def fmul(a, b):
    t, d = a[0] * b[0], a[1] * b[1]
    g = gcd(t, d)
    return (t // g, d // g)

def gcd(a, b):
    a, b = abs(a), abs(b)
    while b:
        a, b = b, a % b
    return a

def qadd(P, Q):                              # chord and tangent over the rationals
    (x1, y1), (x2, y2) = P, Q
    if P == Q:
        top, bot = fmul((3, 1), fmul(x1, x1)), fmul((2, 1), y1)
    else:
        top, bot = fadd(y2, (-y1[0], y1[1])), fadd(x2, (-x1[0], x1[1]))
    m = fmul(top, (bot[1] * (1 if bot[0] > 0 else -1), abs(bot[0])))
    x3 = fadd(fmul(m, m), (-(x1[0] * x2[1] + x2[0] * x1[1]), x1[1] * x2[1]))
    y3 = fadd(fmul(m, fadd(x1, (-x3[0], x3[1]))), (-y1[0], y1[1]))
    return (x3, y3)

def fq(a, p):                                # a fraction read mod p
    return a[0] * power(a[1], p - 2, p) % p

def m49(a, b):                               # the 49-element field: c + d*i, i^2 = -1
    return ((a[0] * b[0] - a[1] * b[1]) % 7, (a[0] * b[1] + a[1] * b[0]) % 7)

p = 7
print(f"curve y^2 = x^3 - 2 over F_{p}; Euler's test raises to the power {(p - 1) // 2}")
for x in range(p):
    v = f(x, p)
    print(f"x = {x}: f = {v}, f^3 = {power(v, 3, p)}, symbol {euler(v, p):+d}, points {1 + euler(v, p)}")
pts = [(x, y) for x in range(p) for y in range(p) if (y * y - f(x, p)) % p == 0]
n7, a7 = count_euler(p), p + 1 - count_euler(p)
print(f"points: {pts} and O")
print(f"count by every pair {count_pairs(p)}; by Euler's test {n7}; a_7 = {a7}")
print(f"Hasse window: {p + 1} - {2 * p ** 0.5:.4f} to {p + 1} + {2 * p ** 0.5:.4f}; inside: {yn(a7 * a7 <= 4 * p)}")
P, mults = (3, 5), [(3, 5)]
while mults[-1] is not None:
    mults.append(add(mults[-1], P, p))
print(f"multiples of (3, 5) mod 7: {mults[:-1]}, then O at {len(mults)}P")
P2 = qadd(((3, 1), (5, 1)), ((3, 1), (5, 1)))
P3 = qadd(P2, ((3, 1), (5, 1)))
for name, Q, R in (("2P", P2, mults[1]), ("3P", P3, mults[2])):
    print(f"{name} over Q = ({Q[0][0]}/{Q[0][1]}, {Q[1][0]}/{Q[1][1]}) reads mod 7 as ({fq(Q[0], 7)}, {fq(Q[1], 7)}); mod-7 sum {R}")
F49 = [(c, d) for c in range(7) for d in range(7)]
roots = {}
for y in F49:
    s = m49(y, y)
    roots[s] = roots.get(s, 0) + 1
n49 = 1 + sum(roots.get(((m49(m49(x, x), x)[0] + B) % 7, m49(m49(x, x), x)[1]), 0) for x in F49)
print(f"over F_49: counted {n49}; Frobenius predicts 49 + 1 - (a_7^2 - 14) = {50 - (a7 * a7 - 14)}")
disc, rest, bad = -16 * 27 * B * B, 16 * 27 * B * B, []
for q in primes(100):
    while rest % q == 0:
        bad, rest = bad + [q], rest // q
singular = [q for q in primes(100) if any((y * y - f(x, q)) % q == 0 and 2 * y % q == 0
            and 3 * x * x % q == 0 for x in range(q) for y in range(q))]
print(f"discriminant {disc} = -({' x '.join(f'{q}^{bad.count(q)}' for q in sorted(set(bad)))}); bad primes {sorted(set(bad))}")
print(f"primes below 100 with a singular point mod p: {singular}")
for q in (2, 3):
    cusp = [(x, y) for x in range(q) for y in range(q) if (y * y - f(x, q)) % q == 0
            and 2 * y % q == 0 and 3 * x * x % q == 0]
    print(f"mod {q}: {count_pairs(q)} points with O; singular point {cusp[0]}")
sweep = primes(1000)[2:]
counts = {q: count_euler(q) for q in sweep}
worst = max(sweep, key=lambda q: abs(q + 1 - counts[q]) / q ** 0.5)
ss = [q for q in sweep if q % 3 == 2]
print(f"primes {sweep[0]} to {sweep[-1]}: {len(sweep)}; all inside Hasse's window: {yn(all((q + 1 - counts[q]) ** 2 <= 4 * q for q in sweep))}")
print(f"closest to the edge: p = {worst}, a_p = {worst + 1 - counts[worst]}, |a_p|/(2 sqrt p) = {abs(worst + 1 - counts[worst]) / (2 * worst ** 0.5):.4f}")
print(f"primes 2 mod 3: {len(ss)}; all with exactly p + 1 points: {yn(all(counts[q] == q + 1 for q in ss))}")
for q in primes(62)[2:]:
    print(f"chart, p = {q}, count {counts[q]}, low {q + 1 - 2 * q ** 0.5:.2f}, high {q + 1 + 2 * q ** 0.5:.2f}")
print(f"mistake 1, O left out: {n7 - 1}")
print(f"mistake 2, one point per square x: {1 + sum(1 for x in range(p) if euler(f(x, p), p) == 1)}")
print(f"mistake 3, exponent p - 1 for (p - 1)/2: {1 + sum(1 + power(f(x, p), p - 1, p) for x in range(p))}")
print(f"figure, F_7 points: {' '.join(f'({x},{y})' for x, y in pts)}")
assert count_pairs(p) == n7 == 7 and len(mults) == n7                   # three roads to 7
assert all(count_pairs(q) == counts[q] for q in sweep if q < 200)       # pairs against Euler
assert n49 == 50 - (a7 * a7 - 14) == 63                                 # Frobenius over F_49
assert all((fq(Q[0], 7), fq(Q[1], 7)) == R for Q, R in ((P2, mults[1]), (P3, mults[2])))
assert sorted(set(bad)) == singular == [2, 3]                           # two roads to bad primes
assert all((q + 1 - counts[q]) ** 2 <= 4 * q for q in sweep)            # Hasse, exactly
assert all(counts[q] == q + 1 for q in ss)                              # cubing permutes F_p
print("ALL CHECKS PASS")
