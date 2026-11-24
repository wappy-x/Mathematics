# Hurwitz's theorem -- the check behind the card.  Imports: square root, pi, floor and gcd only.
from math import sqrt, pi, floor, gcd
R5, TOP = sqrt(5), 120; PHI = (1 + R5) / 2           # root 5, the search limit, the golden ratio
def eps(x, p, q): return q * q * abs(x - p / q)      # q^2 x error; under 1/c means within 1/(c q^2)
def hits(x, c=R5):                                   # road 1: try every bottom number q up to TOP
    return [f"{round(x * q)}/{q}" for q in range(1, TOP + 1) if gcd(round(x * q), q) == 1 and eps(x, round(x * q), q) < 1 / c]
def farey(x, steps):                                 # road 2: walk Farey neighbours a/b < x < c/d
    a, b, c, d, ok = floor(x), 1, floor(x) + 1, 1, 0
    for _ in range(steps):                           # count triples a/b, mediant, c/d with a hit
        ok += any(eps(x, h, k) < 1 / R5 for h, k in [(a, b), (c, d), (a + c, b + d)])
        a, b, c, d = (a + c, b + d, c, d) if (a + c) / (b + d) < x else (a, b, a + c, b + d)
    return ok
F = [(1, 1), (2, 1), (3, 2), (5, 3), (8, 5), (13, 8), (21, 13), (34, 21)]   # the golden ratio's stops
E, fib = [eps(PHI, p, q) for p, q in F], [1, 1]
while fib[-1] <= 2 * TOP: fib.append(fib[-1] + fib[-2])
print(f"root 5 = {R5:.7f}, 1/root 5 = {1 / R5:.7f}, golden ratio = {PHI:.7f}")
print(f"pi: 22/7 is off by {abs(pi - 22 / 7):.5f}, bound 1/(root 5 x 49) = {1 / (R5 * 49):.5f}")
print("pi, q^2 x error at 3/1 22/7 333/106 355/113:", *[f"{eps(pi, p, q):.4f}" for p, q in [(3, 1), (22, 7), (333, 106), (355, 113)]])
print("phi, q^2 x error at 1/1 2/1 3/2 5/3 8/5 13/8 21/13 34/21:", *[f"{e:.4f}" for e in E])
print("phi, p^2 - pq - q^2 at the same fractions:", *[p * p - p * q - q * q for p, q in F])
print(f"8/5 is off by {PHI - 8 / 5:.5f}, bound {1 / (R5 * 25):.5f} | 13/8 is off by {13 / 8 - PHI:.5f}, bound {1 / (R5 * 64):.5f}")
print(f"every q up to {TOP}, within 1/(root 5 q^2): pi", *hits(pi), "| phi", *hits(PHI))
print("phi with 2.3 for root 5:", *hits(PHI, 2.3), f"| the proof allows only q below {sqrt(1 / (2.3 * (2.3 - R5))):.2f}")
print(f"Farey triples with a hit, of 15 walked: pi {farey(pi, 15)}, phi {farey(PHI, 15)}")
print(f"mistakes: 3 for root 5 finds {len(hits(PHI, 3))} for phi | 8/5 against 1/(root 5 x 5) = {1 / (R5 * 5):.5f} | phi as 1.618 puts 13/8 at {eps(1.618, 13, 8):.4f}")
assert all(abs(p * p - p * q - q * q) == 1 and abs(e - 1 / (p / q + PHI - 1)) < 1e-12 for (p, q), e in zip(F, E))
assert [e > 1 / R5 for e in E[2:]] == [True, False] * 3 and farey(pi, 15) == farey(PHI, 15) == 15
assert hits(PHI) == [f"{p}/{q}" for q, p in zip(fib, fib[1:]) if q <= TOP and p * p - p * q - q * q == 1]
assert hits(pi) == ["3/1", "22/7", "355/113"] and all(int(h.split('/')[1]) < sqrt(1 / (2.3 * (2.3 - R5))) for h in hits(PHI, 2.3))
print("ALL CHECKS PASS")
