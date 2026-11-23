# Proof against evidence -- the check behind the card.  Standard library only.
# Polya's claim: L(n) <= 0 for every n >= 2, where lambda(k) is +1 when k has an
# even number of prime factors (counted with repeats), -1 when odd, and L(n) is
# their running sum.  It holds for every n below 906,150,257 and fails there.
from math import isqrt, log, exp

U = 1_000_000                                  # road 1: sieve every n up to here
omega = [0] * (U + 1)                          # prime factors of n, with repeats
for p in range(2, U + 1):
    if omega[p] == 0:                          # nothing divided p: p is prime
        q = p
        while q <= U:
            for m in range(q, U + 1, q):
                omega[m] += 1
            q *= p
lam = [0] + [1 if omega[k] % 2 == 0 else -1 for k in range(1, U + 1)]
L = [0] * (U + 1)
for k in range(1, U + 1):
    L[k] = L[k - 1] + lam[k]

def L_far(x, table, memo):
    # road 2: sum over d of L(x // d) counts the squares up to x, so
    # L(x) = isqrt(x) - (L(x // 2) + L(x // 3) + ... + L(x // x)), grouped by quotient
    if x < len(table):
        return table[x]
    if x not in memo:
        r, d = isqrt(x), 2
        while d <= x:
            qt = x // d
            last = x // qt
            r -= (last - d + 1) * L_far(qt, table, memo)
            d = last + 1
        memo[x] = r
    return memo[x]

def factor(n):                                 # trial division, smallest first
    f, p = [], 2
    while p * p <= n:
        while n % p == 0:
            f.append(p)
            n //= p
        p += 1
    return f + ([n] if n > 1 else [])

def sgn(v): return f"{v:+d}"
print("lambda(1..10):", " ".join(sgn(lam[k]) for k in range(1, 11)))
print("L(1..10):", " ".join(str(L[k]) for k in range(1, 11)))
print("L(10^k) for k = 0..6:", " ".join(str(L[10 ** k]) for k in range(7)))
top = max(L[2:])
zeros = [n for n in range(2, U + 1) if L[n] == 0]
print(f"road 1, sieve: largest L(n) for 2 <= n <= {U} is {top}")
print("road 1, sieve: n with L(n) = 0:", " ".join(map(str, zeros)))
squares = sum(L[U // d] for d in range(1, U + 1))
print(f"identity at n = {U}: sum of L(n // d) = {squares}, squares up to n = {isqrt(U)}")
small = L[:10_001]                             # road 2 sees only L up to 10,000
far_1e6 = L_far(U, small, {})
print(f"road 2, identity from L up to 10000: L({U}) = {far_1e6}")
N = 906_150_257
before, at = L_far(N - 1, L, {}), L_far(N, L, {})
print(f"road 2, identity: L({N - 1}) = {before}, L({N}) = {at}")
fN = factor(N)
lamN = 1 if len(fN) % 2 == 0 else -1
print(f"road 3, trial division: {N} = {' x '.join(map(str, fN))}, "
      f"{len(fN)} prime factors, lambda = {sgn(lamN)}")

lo, hi = 906_100_000, 906_600_000              # road 4: sieve a window by itself
W = hi - lo + 1
rem, cnt = list(range(lo, hi + 1)), [0] * W
for p in range(2, isqrt(hi) + 1):
    if omega[p] == 1:                          # p is prime
        q = p
        while q <= hi:
            for i in range((-lo) % q, W, q):
                cnt[i] += 1
                rem[i] //= p
            q *= p
run, win = L_far(lo - 1, L, {}), []
for i in range(W):
    run += 1 if (cnt[i] + (rem[i] > 1)) % 2 == 0 else -1
    win.append(run)
pos = [lo + i for i in range(W) if win[i] > 0]
peak = max(win)
LEH = 906_180_359                              # Lehman's 1960 failure, inside the window
print(f"road 4, window {lo}..{hi}: L({N}) = {win[N - lo]}, L({LEH}) = {win[LEH - lo]}")
print(f"road 4: first n in the window with L(n) > 0 is {pos[0]}, last is {pos[-1]}")
print(f"road 4: {len(pos)} of {W} n in the window have L(n) > 0; "
      f"largest L = {peak} at n = {lo + win.index(peak)}")
print("chart, n then L(n), every 25000:")
for j in range(0, 21, 4):
    print("  " + "  ".join(f"{lo + 25000 * k} {win[25000 * k]}" for k in range(j, min(j + 4, 21))))

w = [0] * (U + 1)                              # mistake: count each prime once
for p in range(2, U + 1):
    if omega[p] == 1:
        for m in range(p, U + 1, p):
            w[m] += 1
run, first_w = 1, None
for k in range(2, U + 1):
    run += 1 if w[k] % 2 == 0 else -1
    if run > 0 and first_w is None:
        first_w = (k, run)
print(f"mistake, n = 1 allowed: L(1) = {L[1]}")
print(f"mistake, each prime counted once: running sum first above 0 at n = {first_w[0]}, value {first_w[1]}")
f41 = [n * n + n + 41 for n in range(41)]
first_comp = next(n for n in range(41) if len(factor(f41[n])) > 1)
print(f"mistake, n^2 + n + 41 prime for n = 0..{first_comp - 1}; "
      f"n = {first_comp} gives {f41[first_comp]} = {' x '.join(map(str, factor(f41[first_comp])))}")

pi = sum(1 for k in range(2, U + 1) if omega[k] == 1)
x = log(U)                                     # li(x) = gamma + log log x + sum x^k/(k k!)
term, total, k = 1.0, 0.5772156649015329 + log(x), 1
while k < 200:
    term *= x / k
    total += term / k
    k += 1
def simpson(f, a, b, n):                       # li by a second road: an area, Simpson's rule
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))
def g(t):                                      # 1/log t - 1/(t - 1): the spike at t = 1 removed
    return 1.0 if t == 0 else 0.5 if abs(t - 1) < 1e-6 else 1 / log(t) - 1 / (t - 1)
li2 = simpson(g, 0.0, 2.0, 2000)               # li(2); the removed 1/(t - 1) adds 0 over 0..2
li_area = li2 + simpson(lambda u: exp(u) / u, log(2), log(U), 20000)   # t = e^u, 2 to U
print(f"pi({U}) = {pi}, li({U}) = {total:.1f}, li - pi = {total - pi:.1f}")
print(f"li by area: li(2) = {li2:.3f}, li(2) + area under 1/log t from 2 to {U} = {li_area:.1f}")
print("quoted, not computed: Polya 1919; Haselgrove 1958; Lehman 1960; Tanaka 1980, first failure 906150257;")
print("  li(x) - pi(x) > 0 for 2 <= x <= 1e19 (Buthe 2018); Littlewood 1914;")
print("  four colours: Appel and Haken 1976 (over 300 rules), 633 configurations (1997),")
print("  Coq proof (2005, published 2008); Goldbach checked to 4e18 (linked card)")

assert far_1e6 == L[U] == -530                 # road 2 against road 1
assert squares == isqrt(U)                     # the identity behind road 2
assert at == win[N - lo] == 1 and before == 0  # road 2 against road 4
assert at - before == lamN                     # step = lambda(N), by trial division
assert top == 0 and pos[0] == N                # the slice: L(n) <= 0 below N
assert win[LEH - lo] == 1                      # Lehman's failure, from the window sieve
assert f41[40] == 41 * 41 and first_comp == 40
assert pi == 78498 and total - pi > 0
assert abs(total - li_area) < 0.01             # li: series against area
print("ALL CHECKS PASS")
