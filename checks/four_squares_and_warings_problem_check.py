# Four squares and beyond -- the check behind the card.  Standard library only.
# Road 1 searches: fewest squares for every n to 100,000, fewest cubes to 10,000.
# Road 2 runs Lagrange's proof as an algorithm (pigeonhole, descent, Euler's
# identity) and builds four squares for every n to 10,000.  Road 3 is Legendre's
# test 4^e(8t+7).  Euler's identity is checked on every quadruple from -1 to 2.
N, NB, NC = 100_000, 10_000, 10_000

def euler(a, w):                         # right side of Euler's four-square identity
    (a1, a2, a3, a4), (b1, b2, b3, b4) = a, w
    return (a1*b1 + a2*b2 + a3*b3 + a4*b4, a1*b2 - a2*b1 + a3*b4 - a4*b3,
            a1*b3 - a2*b4 - a3*b1 + a4*b2, a1*b4 + a2*b3 - a3*b2 - a4*b1)

def sq(q): return sum(x * x for x in q)
def show(q): return "(" + ", ".join(str(x) for x in q) + ")"

def prime_rep(p, log):                   # road 2: four squares for a prime p
    if p == 2:
        return (1, 1, 0, 0)
    seen = {(-1 - v * v) % p: v for v in range((p + 1) // 2)}
    u = next(u for u in range((p + 1) // 2) if (u * u) % p in seen)
    q = (u, seen[(u * u) % p], 1, 0)     # pigeonhole: u^2 + v^2 + 1 = m p
    m = sq(q) // p
    while m > 1:
        if m % 2 == 0:                   # pair equal parities, then halve
            s = sorted(q, key=lambda x: x % 2)
            new = ((s[0] + s[1]) // 2, (s[0] - s[1]) // 2, (s[2] + s[3]) // 2, (s[2] - s[3]) // 2)
            log.append(f"m = {m} at {show(q)} = {m} x {p}: halve to {show(new)}")
            q, m = new, m // 2
        else:                            # nearest remainders, multiply, divide by m
            y = tuple((x + m // 2) % m - m // 2 for x in q)
            r = sq(y) // m
            mix = euler(q, y); new = tuple(z // m for z in mix)
            log.append(f"m = {m} at {show(q)} = {m} x {p}: remainders {show(y)} = {m} x {r}, "
                       f"mixtures {show(mix)} = {sq(mix)}, / {m} = {show(new)}")
            q, m = new, r
    return q

def lowest_count(n_max, powers):         # road 1: fewest powers by dynamic programming
    f = [0] + [n_max + 1] * n_max
    for n in range(1, n_max + 1):
        f[n] = 1 + min(f[n - c] for c in powers if c <= n)
    return f

def legendre(n):                         # road 3: n = 4^e (8t + 7)?
    while n % 4 == 0:
        n //= 4
    return n % 8 == 7

print("-- 7 and three squares --")
small = [i * i for i in range(3)]
reach = sorted({x + y + z for x in small for y in small for z in small})
print(f"squares up to 7: {small}; three of them reach {reach}")
assert 7 not in reach
print(f"7 mod 8 = {7 % 8}; squares mod 8 are {sorted({x * x % 8 for x in range(8)})}")
fewest = lowest_count(N, [b ** 2 for b in range(1, 400) if b ** 2 <= N])   # no cap at four
print(f"-- fewest squares, n = 1 to {N:,} (search) --")
for k in range(1, 6):
    print(f"need {k}: {fewest[1:].count(k):,}")
assert max(fewest) == 4                  # nothing up to N needs five or more
four = [n for n in range(1, N + 1) if fewest[n] == 4]
assert four == [n for n in range(1, N + 1) if legendre(n)]
print(f"need four = numbers of the form 4^e(8t+7): {four == [n for n in range(1, N + 1) if legendre(n)]}")
print(f"need four but not 7 mod 8: {sum(1 for n in four if n % 8 != 7):,}, first {next(n for n in four if n % 8 != 7)}")
for M in (1_000, 10_000, 100_000):
    c = sum(1 for n in four if n <= M)
    print(f"share needing four up to {M:,}: {c:,} = {c / M:.6f} (1/6 = {1 / 6:.6f})")
assert abs(len(four) / N - 1 / 6) < 0.001
r4 = [0] * 101                           # r4(n): ways to write n as four squares, n <= 100
for code in range(21 ** 4):              # every (a, b, c, d) from -10 to 10
    s = sq([code // 21 ** i % 21 - 10 for i in range(4)])
    if s <= 100: r4[s] += 1
jac = [8 * sum(d for d in range(1, n + 1) if n % d == 0 and d % 4) for n in range(101)]
assert r4[1:] == jac[1:]                 # Jacobi: 8 x (sum of divisors not divisible by 4)
print(f"r4(7) by search {r4[7]}, by Jacobi 8 x {jac[7] // 8} = {jac[7]}; agree for n = 1 to 100: {r4[1:] == jac[1:]}")
print("-- Lagrange's proof run as an algorithm --")
for p in (7, 23):
    log = []
    q = prime_rep(p, log)
    print(f"p = {p}: " + "; ".join(log) + f"; {show(q)} sums to {sq(q)}")
    assert sq(q) == p
spf = list(range(NB + 1))
for i in range(2, int(NB ** 0.5) + 1):
    if spf[i] == i:
        for j in range(i * i, NB + 1, i):
            if spf[j] == j:
                spf[j] = i
reps, steps = {}, 0
for p in [i for i in range(2, NB + 1) if spf[i] == i]:
    log = []
    reps[p] = prime_rep(p, log)
    steps = max(steps, len(log))
built = 0
for n in range(1, NB + 1):
    q, k = (1, 0, 0, 0), n
    while k > 1:
        q, k = euler(q, reps[spf[k]]), k // spf[k]
    assert sq(q) == n
    built += 1
print(f"four squares built and summed for n = 1 to {NB:,}: {built:,}; primes {len(reps):,}; most descent steps {steps}")
bad = 0
for code in range(4 ** 8):
    v = [(code >> (2 * i) & 3) - 1 for i in range(8)]
    bad += sq(euler(v[:4], v[4:])) != sq(v[:4]) * sq(v[4:])
assert bad == 0
print(f"Euler's identity on all {4 ** 8:,} pairs of quadruples from -1 to 2: failures {bad}")
a, w = (2, 1, 1, 1), (1, 1, 1, 0)
e = euler(a, w)
flip = (e[0], a[0]*w[1] + a[1]*w[0] + a[2]*w[3] - a[3]*w[2], e[2], e[3])
print(f"7 x 3: {show(e)} sums to {sq(e)}; one sign flipped {show(flip)} sums to {sq(flip)}")
plain = tuple(x % 3 for x in (2, 8, 1, 0))
print(f"descent with plain remainders at p = 23, m = 3: {show(plain)} = 3 x {sq(plain) // 3}, no smaller m")
print(f"-- fewest cubes, n = 1 to {NC:,} (search) --")
fc = lowest_count(NC, [b ** 3 for b in range(1, 100) if b ** 3 <= NC])
print("need " + ", ".join(f"{k}: {fc[1:].count(k):,}" for k in range(1, 10)))
nine, eight = [n for n in range(1, NC + 1) if fc[n] == 9], [n for n in range(1, NC + 1) if fc[n] == 8]
assert nine == [23, 239] and max(eight) == 454
print(f"need nine: {nine}; need eight: {len(eight)}, largest {max(eight)}; 23 = 8 + 8 + 7 x 1")
print(f"cubes mod 9: {sorted({b ** 3 % 9 for b in range(9)})}; three of them miss",
      sorted(set(range(9)) - {(x + y + z) % 9 for x in (0, 1, 8) for y in (0, 1, 8) for z in (0, 1, 8)}))
signed = [(x, y, z, t) for x in range(-3, 4) for y in range(x, 4) for z in range(y, 4) for t in range(z, 4)
          if x ** 3 + y ** 3 + z ** 3 + t ** 3 == 23]
print(f"23 with negative cubes allowed, four cubes from -3 to 3: {signed}")
print("-- Waring: the lower bound witness n = 2^k floor(1.5^k) - 1 --")
for k in range(2, 7):
    q = 3 ** k // 2 ** k
    n, g = 2 ** k * q - 1, 2 ** k + q - 2
    f = lowest_count(n, [b ** k for b in range(1, n + 1) if b ** k <= n])[n]
    print(f"k = {k}: n = {n}, fewest by search {f}, 2^k + floor(1.5^k) - 2 = {g}")
    assert f == g
ok = [k for k in range(2, 81) if 3 ** k % 2 ** k + 3 ** k // 2 ** k <= 2 ** k]
assert len(ok) == 79
print(f"condition for g(k) = 2^k + floor(1.5^k) - 2 holds for k = 2 to 80: {len(ok)} of 79")
print("ALL CHECKS PASS")
