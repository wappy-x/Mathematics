# Dirichlet L-functions: the check behind the card.  Standard library only.
# Roads to L(1, chi_4) = pi/4: the series with its proved error bracket, pi from
# Machin's arctangent formula, and lattice points in a circle.  Primes: a sieve.
import math

def chi4(n): return 0 if n % 2 == 0 else (1 if n % 4 == 1 else -1)
def f(x, k=6): return f"{x:.{k}f}"

def atan_series(x):  # arctan x = x - x^3/3 + x^5/5 - ..., 40 terms, |x| <= 1/5
    total, power = 0.0, x
    for k in range(40):
        total += (1.0 if k % 2 == 0 else -1.0) * power / (2 * k + 1)
        power *= x * x
    return total

def avg_tail(chi, q, s, M):  # sum chi(n)/n^s, averaged over the partial sums
    total, acc = 0.0, 0.0    # at N = M .. M+q-1: the 1/M error term cancels
    for n in range(1, M + q):
        total += chi(n) / float(n ** s)
        if n >= M: acc += total
    return acc / q

PI = 16 * atan_series(1 / 5) - 4 * atan_series(1 / 239)
Q = PI / 4
print("pi by Machin", f(PI, 11), "| pi/4", f(Q, 12))

# ---- the series L(1, chi_4) = 1 - 1/3 + 1/5 - ..., error bracket from Step 3 ----
s, part = 0.0, []
for k in range(12):
    s += (1.0 if k % 2 == 0 else -1.0) / (2 * k + 1); part.append(s)
print("chart, partial sums, 1 to 12 terms:", ", ".join(f(x, 4) for x in part))
print("terms N, partial sum, error, bracket 1/(2(2N+1)) to 1/(2N+1)")
s, k = 0.0, 0
for N in [10, 100, 1000, 10 ** 6]:
    while k < N:
        s += (1.0 if k % 2 == 0 else -1.0) / (2 * k + 1); k += 1
    err = abs(s - Q)
    assert 1 / (2 * (2 * N + 1)) < err < 1 / (2 * N + 1)   # Step 3's bracket
    dp = 14 if N == 10 ** 6 else 9               # at 10^6, nine decimals would hide the gap to the low end
    print(N, f(s, 9), f(err, dp), f(1 / (2 * (2 * N + 1)), dp), f(1 / (2 * N + 1), dp))

# ---- primes below a million, and the Euler product at s = 2 ----
X = 10 ** 6
sv = bytearray([1]) * X; sv[0] = sv[1] = 0
for i in range(2, 1001):
    if sv[i]: sv[i * i::i] = bytearray(len(range(i * i, X, i)))
primes = [p for p in range(X) if sv[p]]
G = avg_tail(chi4, 4, 2, X)                      # Catalan's constant, by the series
E = 1.0
for p in primes: E /= 1 - chi4(p) / (p * p)
E3 = []
for p in (3, 5, 7): E3.append((E3[-1] if E3 else 1.0) / (1 - chi4(p) / (p * p)))
print("Euler product at s=2, primes 3; 3, 5; 3, 5, 7:", ", ".join(f(v) for v in E3))
print("L(2,chi4) series", f(G, 9), "| Euler product, primes below 10^6", f(E, 9), "| gap", f(abs(G - E), 9))
assert abs(G - E) < 1e-6                         # Step 2: gap below 1/1,000,000
alt = lambda n: 1 if n % 2 == 1 else -1          # periodic, but not multiplicative
Ealt = 1.0
for p in primes: Ealt /= 1 - alt(p) / (p * p)
Salt = avg_tail(alt, 2, 2, X)
assert abs(Salt - PI * PI / 12) < 1e-9 and abs(Ealt - Salt) > 0.1
print("weight (-1)^(n+1) at s=2: series", f(Salt), "= pi^2/12", f(PI * PI / 12), "| fake product", f(Ealt))
h = []
for N in (10 ** 3, 10 ** 6):
    t = 0.0
    for n in range(1, N + 1, 2): t += 1 / n
    h.append(t)
print("principal chi0 mod 4 at s=1: odd n to 10^3", f(h[0]), "| to 10^6", f(h[1]))
r3, i, j = 0.0, 0, 0                             # rearranged: two plus terms, one minus
for b in range(300000):
    r3 += 1 / (4 * i + 1) + 1 / (4 * i + 5) - 1 / (4 * j + 3); i += 2; j += 1
print("rearranged 1 + 1/5 - 1/3 + ...:", f(r3), "| pi/4 + (log 2)/4", f(Q + math.log(2) / 4))
assert abs(r3 - (Q + math.log(2) / 4)) < 1e-5

# ---- lattice points: sum of r(n) = sum chi4(d) floor(N/d) = (points in circle)/4 ----
def lattice(N):  # points (a, b) with 0 < a^2 + b^2 <= N
    R = math.isqrt(N)
    return sum(2 * math.isqrt(N - a * a) + 1 for a in range(-R, R + 1)) - 1
for N in (10, X):
    D = sum(chi4(d) * (N // d) for d in range(1, N + 1))
    assert lattice(N) == 4 * D                   # Jacobi's two-squares count, checked
    print("N", N, "| lattice points", lattice(N), "| divisor sum", D, "| sum/N", f(D / N))
assert abs(D / X - Q) < 2 / math.sqrt(X)
r = [0] * (X + 1)                                # r(n) = sum of chi4(d) over d | n
for d in range(1, X + 1, 2):
    c = chi4(d)
    for m in range(d, X + 1, d): r[m] += c
assert min(r[1:]) >= 0 and min(r[m * m] for m in range(1, 1001)) >= 1
print("r(n) for n <= 10^6: smallest", min(r[1:]), "| smallest at a square", min(r[m * m] for m in range(1, 1001)))
print("x, A(x) = sum r(n)/sqrt(n), 2 sqrt(x) pi/4, difference, floor (log x)/2")
A, n = 0.0, 0
for x in (10 ** 2, 10 ** 4, 10 ** 6):
    while n < x:
        n += 1; A += r[n] / math.sqrt(n)
    main = 2 * math.sqrt(x) * Q
    assert A >= math.log(x) / 2 and abs(A - main) < 2
    print(x, f(A), f(main), f(A - main), f(math.log(x) / 2))

# ---- primes in the two classes mod 4: the sum of chi4(p)/p against its predicted limit ----
print("primes below 10^6: 1 mod 4", sum(1 for p in primes if p % 4 == 1), "| 3 mod 4", sum(1 for p in primes if p % 4 == 3))
Sd = corr = 0.0                                  # sum of chi4(p)/p; prime powers p^k, k >= 2, in log L
for p in primes:
    t = chi4(p) / p; tk = t; Sd += t
    for k in range(2, 41):
        tk *= t; corr += tk / k
pred = math.log(Q) - corr
assert abs(Sd - pred) < 0.001
print("sum chi4(p)/p, p below 10^6", f(Sd, 4), "| log(pi/4)", f(math.log(Q)), "| minus prime powers: predicted limit", f(pred), "| gap", f(Sd - pred))

# ---- last digits: the characters mod 10, chi(3) = i^j ----
print("last digit 1, 3, 7, 9:", ", ".join(str(sum(1 for p in primes if p % 10 == a)) for a in (1, 3, 7, 9)))
pos, I4 = {1: 0, 3: 1, 9: 2, 7: 3}, (1, 1j, -1, -1j)    # 3^k mod 10 is 1, 3, 9, 7
for jj in (1, 2, 3):
    ch = lambda n: I4[jj * pos[n % 10] % 4] if n % 10 in pos else 0
    L = avg_tail(ch, 10, 1, X)
    assert abs(L) > 0.3                            # nonzero, as the theorem needs
    print("mod 10, chi(3) = i^%d: L(1,chi) = %s %s %si | size %s" % (jj, f(L.real), "+" if L.imag >= 0 else "-", f(abs(L.imag)), f(abs(L))))
    if jj == 2:
        L10, cf = L.real, 3 * math.log((1 + math.sqrt(5)) / 2) / math.sqrt(5)
        assert abs(L.real - cf) < 1e-9
        print("closed form 3 log((1 + sqrt 5)/2)/sqrt 5", f(cf))

# ---- two more values with closed forms ----
L3 = avg_tail(chi4, 4, 3, X)
print("L(3,chi4)", f(L3), "| pi^3/32", f(PI * PI * PI / 32))
assert abs(L3 - PI * PI * PI / 32) < 1e-12
chi5 = lambda n: (0, 1, -1, -1, 1)[n % 5]        # the real character mod 5, (n/5)
L15, cf5 = avg_tail(chi5, 5, 1, X), 2 * math.log((1 + math.sqrt(5)) / 2) / math.sqrt(5)
print("mod 5, L(1,chi5)", f(L15), "| 2 log((1 + sqrt 5)/2)/sqrt 5", f(cf5), "| mod-10 value / mod-5 value", f(L10 / L15))
assert abs(L15 - cf5) < 1e-9 and abs(L10 / L15 - 1.5) < 1e-9   # the mod-10 value drops the factor at 2
print("ALL CHECKS PASS")
