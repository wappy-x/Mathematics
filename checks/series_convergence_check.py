# Infinite series -- the check behind the card.  Standard library only.
# A perpetuity pays 100 at the end of every year, forever, at a 5% rate.
# Its value is the sum of the discounted payments, reached by three roads:
# adding the payments one by one, the closed form, and the self-similar equation.
import math
PAY, RATE = 100.0, 0.05
r = 1 / (1 + RATE)                        # each payment is worth r times the one before
a = PAY * r                               # the first payment, discounted one year

def added(n, first=a, ratio=r):           # road one: add n discounted payments
    total, term = 0.0, first
    for _ in range(n):
        total, term = total + term, term * ratio
    return total

def formula(n):                           # road two: a(1 - r^n)/(1 - r), r^n by logs
    return a * (1 - math.exp(n * math.log(r))) / (1 - r)

limit = a / (1 - r)                       # road two, all payments
self_similar = PAY / RATE                 # road three: S = (100 + S)/1.05
by_adding = added(700)

def within(tol):                          # the tolerance game, two ways
    n = 0
    while limit - added(n) > tol:
        n += 1
    return n, math.ceil(math.log(limit / tol) / math.log(1 + RATE))

pay, disc, grow = PAY, 1.0, []            # term test: payments growing 5% a year
for k in range(100):
    disc *= 1 + RATE
    grow.append(pay / disc)
    pay *= 1 + RATE
h, bounds = 0.0, []                       # harmonic series 1 + 1/2 + 1/3 + ...
for k in range(1, 1025):
    h += 1 / k
    if k & (k - 1) == 0:                  # k is a power of 2: record (H_k, 1 + j/2)
        bounds.append((h, 1 + math.log2(k) / 2))

print(f"perpetuity 100 a year at 5%: ratio r = {r:.6f}, first term a = {a:.6f}")
print(f"first three terms {a:.6f} {a * r:.6f} {a * r * r:.6f}, S_3 = {added(3):.6f}")
print(f"limit, closed form a/(1 - r): {limit:.6f}")
print(f"limit, self-similar S = (100 + S)/1.05, so S = 100/0.05: {self_similar:.6f}")
print(f"limit, adding 700 payments: {by_adding:.6f}")
for n in range(0, 201, 25):
    print(f"chart, n = {n:3}: added {added(n):8.2f}, formula {formula(n):8.2f}, tail {limit - formula(n):8.2f}")
for tol in (1.0, 0.01):
    print(f"within {tol:.2f} of {limit:.0f}: n = {within(tol)[0]} by adding, {within(tol)[1]} by logs")
print(f"term test, payments growing 5% a year: term 1 = {grow[0]:.6f}, term 100 = {grow[99]:.6f}, S_100 = {sum(grow):.2f}")
print(f"harmonic 1 + 1/2 + ... + 1/1024: last term {1 / 1024:.6f}, sum {h:.4f}, doubling bound {bounds[-1][1]:.0f}")
print(f"mistakes: ratio 0.95 gives {95 / (1 - 0.95):.2f}; a payment today added gives {PAY + limit:.2f}; S = 1 + 2S gives {1 / (1 - 2):.0f}")
assert all(abs(added(n) - formula(n)) < 1e-9 for n in range(0, 201, 25))   # road one = road two
assert abs(by_adding - self_similar) < 1e-9 and abs(limit - self_similar) < 1e-9
assert within(1.0)[0] == within(1.0)[1] and within(0.01)[0] == within(0.01)[1]
assert all(hk >= b for hk, b in bounds) and min(grow) > 0.99 * a   # harmonic bound; growing terms never shrink
print("ALL CHECKS PASS")
