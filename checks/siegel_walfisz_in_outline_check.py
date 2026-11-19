# Siegel-Walfisz -- the check behind the card.  Standard library only.  Primes below a million
# split into the classes mod 7 by a sieve and by trial division; li(x) by its series and by
# Simpson's rule; L(s, chi) for the quadratic character mod 7 by Euler-Maclaurin and, at s = 1,
# by a closed form; then what an exceptional zero would cost and why the modulus must stay small.
import math
X, Q = 10**6, 7
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0          # road 1: sieve of Eratosthenes
for p in range(2, 1001):
    if flag[p]: flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(X + 1) if flag[p]]
small = [p for p in range(2, 1001) if all(p % d for d in range(2, math.isqrt(p) + 1))]
def is_prime_td(n):                                              # road 2: trial division
    for d in small:
        if d * d > n: return True
        if n % d == 0: return False
    return True
td = [n for n in range(2, X + 1) if is_prime_td(n)]
def classes(ps, q):
    c = [0] * q
    for p in ps: c[p % q] += 1
    return c
c7, t7 = classes(primes, Q), classes(td, Q)
print(f"primes below 10^6: sieve {len(primes)}; trial division {len(td)}")
print("mod 7, sieve: " + "; ".join(f"class {a} {c7[a]}" for a in range(Q)))
print("mod 7, trial division: " + "; ".join(f"class {a} {t7[a]}" for a in range(Q)))
GAMMA, L = 0.5772156649015329, math.log(X)                       # Euler's constant, quoted
def li_series(x):                                                # li(x) = gamma + ln ln x + sum (ln x)^n / (n n!)
    u, term, s, n = math.log(x), 1.0, 0.0, 0
    while True:
        n += 1; term *= u / n; s += term / n
        if term / n < 1e-17 * s: return GAMMA + math.log(u) + s
def simpson(f, a, b, m=20000):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, m)))
Li = simpson(lambda u: math.exp(u) / u, math.log(2), L)          # offset Li(x): integral from 2 to x of dt / ln t
li_a, li_b = li_series(X), Li + li_series(2)
print(f"li(10^6): series {li_a:.2f}; Simpson from 2 plus li(2) {li_b:.2f}; offset Li(10^6) {Li:.2f}; li minus pi {li_a - len(primes):.2f}")
six = c7[1:]; pred = li_a / 6; mean = (len(primes) - 1) / 6
print(f"prediction li(x)/6 = {pred:.2f}; mean of the six classes {mean:.2f}; smallest {min(six)}, largest {max(six)}")
print(f"spread {max(six) - min(six)} primes = {100 * (max(six) - min(six)) / mean:.2f} percent of the mean; "
      f"class / prediction from {min(six) / pred:.5f} to {max(six) / pred:.5f}")
chi = [0] + [1 if pow(a, 3, Q) == 1 else -1 for a in range(1, Q)]   # Euler's criterion: a^3 mod 7
res = sum(c7[a] for a in range(1, Q) if chi[a] == 1); non = sum(c7[a] for a in range(1, Q) if chi[a] == -1)
print(f"squares mod 7: {[a for a in range(1, Q) if chi[a] == 1]}; their classes {res}; the other three {non}; "
      f"lead {non - res}; sqrt(x)/ln x = {math.sqrt(X) / L:.2f}")
phi = lambda q: sum(1 for a in range(1, q + 1) if math.gcd(a, q) == 1)
worst = {}
for q in list(range(3, 14)) + [101, 1009, 9973]:
    c = classes(primes, q); k = [c[a] for a in range(q) if math.gcd(a, q) == 1]; m = sum(k) / len(k)
    worst[q] = max(abs(v / m - 1) for v in k)
    print(f"q = {q}: phi {phi(q)}; mean per class {m:.2f}; smallest {min(k)}; largest {max(k)}; "
          f"worst miss {100 * worst[q]:.2f} percent")
k = classes(primes, 9973)[1:]; m = sum(k) / len(k)               # q = 9973: the scatter of small counts
sd = math.sqrt(sum((v - m) ** 2 for v in k) / len(k))
print(f"q = 9973: mean {m:.2f}; standard deviation {sd:.2f}, {100 * sd / m:.0f} percent of the mean; "
      f"(ln x)^4 = {L ** 4:.0f}, so q = 9973 is inside the range for A = 4")
def Lchi(s, N=40):                                               # sum of chi(n) n^-s: head plus Euler-Maclaurin tail
    tot = 0.0
    for a in range(1, Q):
        y = Q * N + a
        head = sum((Q * n + a) ** -s for n in range(N))
        integ = -math.log(y) / Q if abs(s - 1) < 1e-12 else y ** (1 - s) / (Q * (s - 1))
        tail = y ** -s / 2 + Q * s / 12 * y ** (-s - 1) - Q ** 3 * s * (s + 1) * (s + 2) / 720 * y ** (-s - 3)
        tot += chi[a] * (head + integ + tail)
    return tot
grid = [(Lchi(0.5 + k / 100), 0.5 + k / 100) for k in range(51)]
print("L(sigma, chi) mod 7: " + "; ".join(f"sigma {s:.1f} {v:.6f}" for v, s in grid[::10]))
print(f"smallest on 51 points from 0.5 to 1: {min(grid)[0]:.6f} at sigma {min(grid)[1]:.2f}")
closed = -math.pi / Q ** 1.5 * sum(a * chi[a] for a in range(1, Q))
direct = sum(chi[n % Q] / n for n in range(1, 7 * 10**5 + 1))
print(f"L(1, chi): Euler-Maclaurin {Lchi(1):.6f}; closed form pi/sqrt(7) {closed:.6f}; "
      f"partial sum to 700000 {direct:.6f}")
cost = [(b, li_series(X ** b) / 6) for b in (0.99, 0.9, 0.75, 0.6)]
print("a real zero at beta: primes moved per class li(x^beta)/6, squares minus the rest: "
      + "; ".join(f"beta {b} {v:.0f}, {-6 * v:.0f}" for b, v in cost))
for e in (6, 12, 100):
    lx = e * math.log(10); qs = lx ** 2
    print(f"x = 10^{e}: ln x {lx:.2f}; q up to (ln x)^2 = {qs:.2f}; exponent ln x / q^(1/4) there {lx / qs ** 0.25:.2f} "
          f"= sqrt(ln x) {math.sqrt(lx):.2f}; at q = x^0.1 {lx / 10 ** (e * 0.1 / 4):.4f}")
print(f"breaks: class 0 holds {c7[0]}; divide by 7 not 6: {len(primes) / 7:.2f} "
      f"({100 * (1 - len(primes) / 7 / mean):.1f} percent low); x/ln x over 6: {X / L / 6:.2f} "
      f"({100 * (1 - X / L / 6 / mean):.1f} percent low)")
assert len(primes) == len(td) == 78498 and c7 == t7                     # two roads to every class count
assert abs(li_a - li_b) < 1e-4 and abs(li_a - 78627.55) < 0.006 and abs(Li - 78626.50) < 0.006  # house table
assert (max(six) - min(six)) / mean < 0.004 and c7[0] == 1              # six classes agree; 7 alone in class 0
assert abs(Lchi(1) - closed) < 1e-9 and abs(direct - closed) < 1e-5     # L(1, chi) three ways
assert min(grid)[0] > 0.5                                               # no real zero on the grid
assert max(worst[q] for q in range(3, 14)) < 0.005 < worst[101] < worst[1009] < worst[9973]
print("ALL CHECKS PASS")
