# Baire category theorem -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  Exact arithmetic with Fraction and integers.
# Space: the metre stick [0, 1], distance |x - y| in metres.
from fractions import Fraction as F
from math import gcd

def queue(count):
    # the rationals in [0, 1] in one queue: by denominator, then numerator, lowest terms only
    out, q = [], 1
    while len(out) < count:
        for p in range(q + 1):
            if gcd(p, q) == 1 and len(out) < count:
                out.append(F(p, q))
        q += 1
    return out

def phi(n):
    # Euler's totient from the prime factors, no gcd: how many p in 1..n share no factor with n
    r, m, p = n, n, 2
    while p * p <= m:
        if m % p == 0:
            while m % p == 0:
                m //= p
            r -= r // p
        p += 1
    return r - r // m if m > 1 else r

def chase(qs, last=False):
    # Baire's proof, run: keep a closed third of the interval that misses the next rational
    a, b, rows = F(0), F(1), []
    for x in qs:
        w = (b - a) / 3
        thirds = [(a, a + w), (a + w, a + 2 * w), (a + 2 * w, b)]
        if last:
            thirds.reverse()
        a, b = next(t for t in thirds if not t[0] <= x <= t[1])
        rows.append((x, a, b))
    return rows

def inside(x, a, b):
    # membership by integer cross-multiplication, not by Fraction comparison
    p, q = x.numerator, x.denominator
    return a.numerator * q <= p * a.denominator and p * b.denominator <= b.numerator * q

def simplest(a, b):
    # the fraction with the smallest denominator in [a, b], by brute force over denominators
    q = 1
    while True:
        p = -((-a.numerator * q) // a.denominator)
        if p * b.denominator <= b.numerator * q:
            return F(p, q)
        q += 1

def dec(x, k):
    s = str(x.numerator * 10 ** k // x.denominator).zfill(k + 1)
    return s[:-k] + "." + s[-k:]

def dust(stages, cut):
    # Cantor dust: at stage n cut a middle gap of length cut(n, piece) out of every piece
    pieces, rows = [(F(0), F(1))], []
    for n in range(1, stages + 1):
        new = []
        for a, b in pieces:
            m, g = (a + b) / 2, cut(n, b - a)
            new += [(a, m - g / 2), (m + g / 2, b)]
        pieces = new
        rows.append((n, sum(b - a for a, b in pieces), max(b - a for a, b in pieces)))
    return rows

def rnd(x, k):
    return dec(x + F(1, 2 * 10 ** k), k)

qs = queue(20)
print("queue, first 12:", " ".join(str(x) for x in qs[:12]))
K = 1 + sum(phi(q) for q in range(1, 11))
print(f"queue, denominators up to 10: {K} by totients; entry {K} is {queue(K)[-1]}, entry {K + 1} is {queue(K + 1)[-1]}")
assert queue(K)[-1].denominator == 10 and queue(K + 1)[-1].denominator == 11, "count by gcd scan vs totients"

rows = chase(qs)
print("chase, step  dodge  kept interval (m)   width (m)")
for n, (x, a, b) in enumerate(rows[:6], 1):
    print(f"chase, {n:>4}  {str(x):>5}  {f'[{a}, {b}]':<18}  {b - a}")
for n, (x, a, b) in enumerate(rows, 1):
    assert b - a == F(1, 3 ** n), "width after n dodges is 1/3^n"
    assert not any(inside(y, a, b) for y in qs[:n]), "kept interval holds none of the dodged rationals"
a6, b6 = rows[5][1:]
s6 = simplest(a6, b6)
assert inside(s6, a6, b6) and s6 not in qs[:6], "simplest fraction is inside and was not dodged"
assert {F(p, q) for q in range(1, s6.denominator + 1) for p in range(q + 1) if a6 <= F(p, q) <= b6} == {s6}, "second search"
print(f"chase, after 6 steps: width {b6 - a6} m = {rnd(b6 - a6, 6)} m; simplest fraction still inside: {s6}")
a20, b20 = rows[19][1:]
print(f"chase, after 20 steps: width {b20 - a20} m; dodged rationals inside: {sum(inside(y, a20, b20) for y in qs)}")
last = chase(qs, last=True)[5]
print(f"chase, last-third rule after 6 steps: [{last[1]}, {last[2]}]")

print("dust, stage  length left (m)  longest piece (m)")
fat = lambda n, piece: F(1, 4 ** n)
for n, total, longest in dust(10, fat):
    assert total == F(1, 2) + F(1, 2 ** (n + 1)), "length left vs 1/2 + 1/2^(n+1)"
    assert longest == F(1, 2 ** (n + 1)) + F(1, 2 ** (2 * n + 1)), "longest piece vs closed form"
    if n in (1, 2, 3, 4, 10):
        print(f"dust, {n:>5}  {str(total):>15}  {str(longest):>17}  = {rnd(total, 6)}, {rnd(longest, 6)}")
thin = dust(10, lambda n, piece: piece / 3)[-1][1]
assert thin == F(2, 3) ** 10, "ordinary Cantor dust keeps 2/3 of its length each stage"
print(f"dust, ordinary middle thirds, stage 10: {thin} m = {rnd(thin, 6)} m")
half = dust(10, lambda n, piece: F(1, 2 * 4 ** n))[-1][1]
assert half == F(3, 4) + F(1, 4 * 2 ** 10), "half-size gaps leave 3/4 + 1/2^12"
print(f"dust, half-size gaps, stage 10: {half} m = {rnd(half, 6)} m")

print(f"breaks, open intervals (0, 1/3^n): the 20th is (0, {F(1, 3 ** 20)}); all of them miss 0")
for n in range(0, 5):
    a, b = (F(0), F(1)) if n == 0 else rows[n - 1][1:]
    dodge = f"next dodge {qs[n]} at {rnd(20 + 400 * qs[n], 1)}" if n < 4 else "end"
    print(f"figure, step {n}: kept {rnd(20 + 400 * a, 1)} to {rnd(20 + 400 * b, 1)} px; {dodge}")
print("ALL CHECKS PASS")
