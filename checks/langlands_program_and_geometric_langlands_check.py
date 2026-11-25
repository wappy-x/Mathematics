# The Langlands program: the check behind the card.  Standard library only.
# Road A: primes in Q(sqrt 5), by roots mod p, by Euler's test and by p mod 5.
# Road B: points on y^2 + y = x^3 - x^2 mod p, against the coefficients of
#         q * prod (1 - q^n)^2 (1 - q^(11n))^2, multiplied out here.
# Road C: Langlands dual root systems by transposing Cartan matrices.
from itertools import permutations
from math import sqrt

def primes_below(n):
    s = [True] * n; s[0] = s[1] = False
    for i in range(2, n):
        if s[i]:
            for j in range(i * i, n, i): s[j] = False
    return [i for i in range(n) if s[i]]
def roots_mod(f, p): return sum(1 for x in range(p) if f(x) % p == 0)

print("== Road A: which primes split in Q(sqrt 5) ==")
splits, agree, total = 0, 0, 0
for p in primes_below(1000):
    if p == 5: continue
    r = roots_mod(lambda x: x * x - x - 1, p)            # x^2 - x - 1 has roots (1 +- sqrt 5)/2
    rule = 2 if p % 5 in (1, 4) else 0
    e = 1 if p == 2 else pow(5, (p - 1) // 2, p)      # Euler: 1 if 5 is a square mod p, else p - 1
    euler = 2 if e == 1 else 0
    if p in (7, 11, 13, 19):
        rts = [x for x in range(p) if (x * x - x - 1) % p == 0]
        print(f"p={p}: p mod 5 = {p % 5}, roots of x^2 - x - 1 mod p: {rts}, "
              f"5^((p-1)/2) mod p = {1 if e == 1 else -1}, {'splits' if r == 2 else 'stays prime'}")
    total += 1; splits += r == 2
    agree += r == rule and (p == 2 or euler == r)
assert agree == total == 167                        # three roads agree at every prime below 1000
print(f"primes below 1000 except 5: {total}; the tests agree at {agree} (three at the {total - 1} odd primes, two at p=2)")
print(f"split: {splits} of {total}, stay prime: {total - splits}, share split {splits / total:.3f} (Chebotarev predicts 1/2)")
bad7 = [p for p in primes_below(1000) if p not in (2, 7)
        and (roots_mod(lambda x: x * x - 7, p) == 2) != (p % 7 in (1, 2, 4))]
assert bad7[0] == 3
print(f"wrong rule 'p splits in Q(sqrt 7) iff p is a square mod 7': fails first at p={bad7[0]}, "
      f"fails at {len(bad7)} of {len(primes_below(1000)) - 2} primes below 1000")

print("== Road B: y^2 + y = x^3 - x^2 against a modular form of level 11 ==")
N = 130
def mul(a, b):
    c = [0] * N
    for i, x in enumerate(a):
        if x:
            for j in range(N - i): c[i + j] += x * b[j]
    return c
form = [0] * N; form[1] = 1                          # q
for n in range(1, N):
    for step in (n, 11 * n):
        if step < N:
            fac = [0] * N; fac[0] = 1; fac[step] = -1
            form = mul(mul(form, fac), fac)          # times (1 - q^step)^2
print("form coefficients a_1..a_12:", " ".join(str(form[n]) for n in range(1, 13)))
def a_count(p):                                      # p minus the affine solutions mod p
    return p - sum(1 for x in range(p) for y in range(p) if (y * y + y - x ** 3 + x * x) % p == 0)
ps = primes_below(100)
by_x = [sum(1 for y in range(3) if (y * y + y - x ** 3 + x * x) % 3 == 0) for x in range(3)]
print("p=3 by hand: solutions with x = 0, 1, 2:", " ".join(map(str, by_x)))
for p in (2, 3, 5, 7, 11, 13):
    print(f"p={p}: solutions mod p = {p - a_count(p)}, a_p = p - solutions = {a_count(p)}, "
          f"coefficient of q^{p} = {form[p]}")
match = sum(1 for p in ps if a_count(p) == form[p])
assert match == len(ps) == 25                        # point counts equal the coefficients
print(f"primes below 100: {len(ps)}; point count equals coefficient at {match} (checked for p < 100)")
ratio = max(abs(form[p]) / (2 * sqrt(p)) for p in ps)
assert ratio <= 1                                    # Hasse: |a_p| <= 2 sqrt p
print(f"Hasse bound: largest |a_p| / (2 sqrt p) for p < 100 = {ratio:.6f}")
for p in (2, 3, 7):
    assert form[p * p] == form[p] ** 2 - p           # Hecke relation at a good prime
    print(f"a_{p * p} = {form[p * p]}, a_{p}^2 - {p} = {form[p] ** 2 - p}")
assert form[6] == form[2] * form[3] and form[10] == form[2] * form[5]
print(f"a_6 = {form[6]} = a_2 a_3; a_10 = {form[10]} = a_2 a_5")
assert form[121] == form[11] ** 2 == 1                # bad prime: a_121 = a_11^2, not a_11^2 - 11
print(f"bad prime 11: a_121 = {form[121]}; the good-prime rule would give {form[11] ** 2 - 11}")
print(f"forget the point at infinity at p=2: p + 1 - solutions = {2 + 1 - (2 - a_count(2))}, not {a_count(2)}")
a3_32 = 3 - sum(1 for x in range(3) for y in range(3) if (y * y - x ** 3 + x) % 3 == 0)
print(f"wrong curve y^2 = x^3 - x (level 32): a_3 = {a3_32}, not {form[3]}")
print("chart, p:", " ".join(str(p) for p in ps))
print("chart, a_p:", " ".join(str(form[p]) for p in ps))
print("chart, 2 sqrt p:", " ".join(f"{2 * sqrt(p):.2f}" for p in ps))
print("chart, -2 sqrt p:", " ".join(f"{-2 * sqrt(p):.2f}" for p in ps))

print("== Road C: the Langlands dual swaps roots and coroots ==")
CARTAN = {"A2": [[2, -1], [-1, 2]], "G2": [[2, -1], [-3, 2]],  # row i, column j: 2(a_i, a_j)/(a_j, a_j)
          "B3": [[2, -1, 0], [-1, 2, -2], [0, -1, 2]], "C3": [[2, -1, 0], [-1, 2, -1], [0, -2, 2]]}
def transpose(m): return [list(r) for r in zip(*m)]
def det(m):
    if len(m) == 1: return m[0][0]
    return sum((-1) ** j * m[0][j] * det([r[:j] + r[j + 1:] for r in m[1:]]) for j in range(len(m)))
def roots(m):                                        # orbit of simple roots under reflections
    k = len(m); seen = {tuple(int(i == j) for j in range(k)) for i in range(k)}; todo = list(seen)
    while todo:
        b = todo.pop()
        for i in range(k):
            c = sum(b[j] * m[j][i] for j in range(k))       # 2(beta, a_i)/(a_i, a_i)
            nb = tuple(b[j] - c * (j == i) for j in range(k))
            if nb not in seen: seen.add(nb); todo.append(nb)
    return seen
def short_long(m):                                   # squared lengths from m[i][j] l_j = m[j][i] l_i
    k = len(m); l = [0] * k; l[0] = 6
    while 0 in l:
        for i in range(k):
            for j in range(k):
                if l[i] and not l[j] and m[i][j]: l[j] = m[j][i] * l[i] // m[i][j]
    sq = [sum(b[i] * b[j] * m[i][j] * l[j] // 2 for i in range(k) for j in range(k)) for b in roots(m)]
    return sum(1 for x in sq if x == min(sq)), sum(1 for x in sq if x > min(sq))
def same_up_to_order(a, b):
    k = len(a)
    return k == len(b) and any(all(a[s[i]][s[j]] == b[i][j] for i in range(k) for j in range(k))
                               for s in permutations(range(k)))
for name, m in CARTAN.items():
    t = transpose(m)
    dual = next(n for n, x in CARTAN.items() if same_up_to_order(x, t))
    (s, lg), (ds, dl) = short_long(m), short_long(t)
    print(f"{name}: Cartan {m}, det {det(m)}, roots {len(roots(m))} ({s} short, {lg} long); "
          f"dual {dual}: {ds} short, {dl} long")
    assert len(roots(m)) == len(roots(t))               # a root system and its dual have equally many roots
    assert (s, lg) == ((dl, ds) if lg else (ds, dl))  # the dual swaps short and long roots
b3, c3 = CARTAN["B3"], CARTAN["C3"]
assert next(n for n, x in CARTAN.items() if same_up_to_order(x, transpose(b3))) == "C3" and not same_up_to_order(b3, c3)
assert len(roots(CARTAN["B3"])) == 18 and short_long(CARTAN["B3"]) == (6, 12)
print(f"B3 equals C3 in some node order: {same_up_to_order(CARTAN['B3'], CARTAN['C3'])}")
print("ALL CHECKS PASS")
