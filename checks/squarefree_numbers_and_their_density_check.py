# Squarefree numbers -- the check behind the card.  Standard library only.
# A number is squarefree when no square bigger than 1 divides it.  The count
# Q(x) of squarefree numbers up to x is made three ways: by striking out the
# multiples of every square, by the Mobius sieve sum of mu(d) * floor(x / d^2),
# and by the split of every number into a square times a squarefree part.
import math

N = 10**6
DENS = 6 / (math.pi * math.pi)                    # 1 / zeta(2), proved on the zeta card

spf = list(range(N + 1))                  # smallest prime factor of each n
for p in range(2, math.isqrt(N) + 1):
    if spf[p] == p:
        for m in range(p * p, N + 1, p):
            if spf[m] == m:
                spf[m] = p
mu, lam = [0, 1] + [0] * (N - 1), [0, 1] + [0] * (N - 1)
for n in range(2, N + 1):                 # mu and Liouville's lambda from spf
    p, m = spf[n], n // spf[n]
    lam[n] = -lam[m]
    mu[n] = 0 if m % p == 0 else -mu[m]

free = [True] * (N + 1)                   # road 1: strike multiples of d^2
free[0] = False
for d in range(2, math.isqrt(N) + 1):
    for m in range(d * d, N + 1, d * d):
        free[m] = False
Q = [0] * (N + 1)                         # Q[x] = squarefree numbers up to x
for n in range(1, N + 1):
    Q[n] = Q[n - 1] + free[n]

def mobius_count(x):                      # road 2: the Mobius sieve over d^2
    return sum(mu[d] * (x // (d * d)) for d in range(1, math.isqrt(x) + 1))

def split_total(x):                       # road 3: n = a^2 * (squarefree part)
    return sum(Q[x // (a * a)] for a in range(1, math.isqrt(x) + 1))

print("first 30 numbers, squarefree ones:", [n for n in range(1, 31) if free[n]])
yn = lambda claim: "yes" if claim else "no"
print(f"720720 = 144 x 5005; 5005 squarefree: {yn(free[5005])}; 720720 squarefree: {yn(free[720720])}")
terms = [(d, mu[d], 1000 // (d * d)) for d in range(1, 32) if mu[d] != 0]
print("Mobius sieve at 1000, terms (d, mu(d), floor(1000/d^2)):")
for i in range(0, len(terms), 5):
    print("  " + "  ".join(f"({d}, {m:+d}, {f})" for d, m, f in terms[i:i + 5]))
omega = lambda d: sum(1 for p in range(2, d + 1) if d % p == 0 and spf[p] == p)
groups = [sum(m * f for d, m, f in terms if omega(d) == k) for k in (1, 2, 3)]
print(f"grouped by primes in d: one prime {groups[0]:+d}, two primes {groups[1]:+d}, three primes {groups[2]:+d}")
q = mobius_count(1000)
print(f"numbers 1 to 1000: struck-out count {Q[1000]}, Mobius sum {q}, split total {split_total(1000)}")
assert Q[1000] == q == 608 and split_total(1000) == 1000
blocks = [Q[k + 100] - Q[k] for k in range(0, 1000, 100)]
print(f"squarefree per block of 100, 1-100 to 901-1000: {blocks}; predicted {100 * DENS:.2f} each")
partial = sum(mu[d] / (d * d) for d in range(1, 32))
euler = 1.0
for p in range(2, 32):
    if spf[p] == p:
        euler *= 1 - 1 / (p * p)
print(f"6/pi^2 = {DENS:.9f}; sum mu(d)/d^2 to 31 = {partial:.9f}; product over primes to 31 = {euler:.9f}")
print(f"predicted at 1000: 6/pi^2 x 1000 = {1000 * DENS:.3f}; primes-to-31 product x 1000 = {1000 * euler:.3f}")
print("x | Q(x) | 6x/pi^2 | E = Q - 6x/pi^2 | E/sqrt(x) | Q/(6x/pi^2) | proved bound D + x/D")
for x in (10**3, 10**4, 10**5, 10**6):
    pred, D = x * DENS, math.isqrt(x)
    e = Q[x] - pred
    print(f"{x} | {Q[x]} | {pred:.3f} | {e:.3f} | {e / math.sqrt(x):.5f} | {Q[x] / pred:.7f} | {D + x / D:.1f}")
    assert Q[x] == mobius_count(x) and split_total(x) == x       # three roads agree
    assert abs(e) <= D + x / D                                   # the proved bound
worst, at = 0.0, 0
for x in range(1, N + 1):
    r = abs(Q[x] - x * DENS) / math.sqrt(x)
    if r > worst:
        worst, at = r, x
print(f"largest |E(x)|/sqrt(x) for x from 1 to {N}: {worst:.5f}, at x = {at}")
print("partial summation: S(x) = sum of 1/n over squarefree n <= x, against (6/pi^2) log x")
s, marks = 0.0, {10**3, 10**4, 10**5, 10**6}
for n in range(1, N + 1):
    if free[n]:
        s += 1 / n
    if n in marks:
        print(f"  x = {n}: S = {s:.6f}, (6/pi^2) log x = {DENS * math.log(n):.6f}, difference {s - DENS * math.log(n):.6f}")
same = all(lam[n] == mu[n] for n in range(1, N + 1) if free[n])
sq = all((sum(lam[d] for d in range(1, n + 1) if n % d == 0) == 1) == (math.isqrt(n) ** 2 == n)
         for n in range(1, 1001))
print(f"lambda = mu on every squarefree n <= {N}: {yn(same)}; lambda summed over divisors is 1 exactly on squares to 1000: {yn(sq)}")
assert same and sq
rad = math.prod(p for p in range(2, 14) if spf[p] == p and 720720 % p == 0)
print(f"lambda(12) = {lam[12]:+d}, mu(12) = {mu[12]}; lambda(720720) = {lam[720720]:+d}, mu(720720) = {mu[720720]}; radical of 720720 = {rad}")
assert lam[12] == -1 and lam[720720] == 1 and rad * 24 == 720720
L, top, zeros = 0, -10**9, 0
for n in range(1, N + 1):
    L += lam[n]
    if n >= 2:
        top, zeros = max(top, L), zeros + (L == 0)
    if n == 1000:
        print(f"L(1000) = sum of lambda(n) to 1000 = {L}")
print(f"Polya's L(x) <= 0 for 2 <= x <= {N}: largest L(x) = {top}, reached {zeros} times; L({N}) = {L}")
assert top <= 0
nosign = 1000 - sum(1000 // (d * d) for d in range(2, 32))
primes_only = 1000 - sum(1000 // (p * p) for p in range(2, 32) if spf[p] == p)
print(f"mistake 1, strike every square's multiples with no add-back: {nosign}")
print(f"mistake 2, prime squares only, no add-back: {primes_only}")
def first_run(k):                         # first k consecutive non-squarefree numbers
    return next(n for n in range(1, N) if not any(free[n + i] for i in range(k)))
r3, r4 = first_run(3), first_run(4)
print(f"mistake 3, density read on a short window: {r3}-{r3 + 2} has 0 of 3; {r4}-{r4 + 3} has 0 of 4")
assert (r3, r4) == (48, 242) and nosign < 608 and primes_only < 608
print("ALL CHECKS PASS")
