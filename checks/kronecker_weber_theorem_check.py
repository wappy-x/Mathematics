# Kronecker-Weber -- the check behind the card.  Standard library only.
# A number in Q(zeta_m) is a list c of m whole numbers, meaning the sum of c[j] zeta^j.
# Equality is tested exactly, after reducing by the cyclotomic polynomial Phi_m, which
# is built here by division.  Splitting is tested by counting roots mod p by brute force.
import cmath
from math import gcd

def cyc(m):                                # Phi_m, low coefficient first
    a = [-1] + [0] * (m - 1) + [1]         # x^m - 1
    for d in range(1, m):
        if m % d == 0:
            b, q = cyc(d), [0] * (len(a) - len(cyc(d)) + 1)
            for i in range(len(q) - 1, -1, -1):
                q[i] = a[i + len(b) - 1]
                for j, y in enumerate(b):
                    a[i + j] -= q[i] * y
            assert not any(a)              # the division is exact
            a = q
    return a

def red(c, m, p=0):                        # remainder mod Phi_m (and mod p if p > 0)
    f, c = cyc(m), c[:]
    n = len(f) - 1
    for i in range(len(c) - 1, n - 1, -1):
        for j, y in enumerate(f):
            c[i - n + j] -= c[i] * y
    return [x % p if p else x for x in c[:n]]

def num(m, terms):                         # terms: {exponent: coefficient}
    c = [0] * m
    for e, k in terms.items():
        c[e % m] += k
    return c

def mul(a, b, m, p=0):                     # product, using zeta^m = 1
    c = [0] * m
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            c[(i + j) % m] += x * y
    return [x % p if p else x for x in c]

def sig(k, a, m):                          # the symmetry zeta -> zeta^k
    c = [0] * m
    for j, x in enumerate(a):
        c[j * k % m] += x
    return c

def val(a, m):
    return sum(x * cmath.exp(2j * cmath.pi * e / m) for e, x in enumerate(a))

def units(m):
    return [k for k in range(1, m) if gcd(k, m) == 1]

def fixer(a, m):                           # the subgroup of (Z mod m)^x fixing a
    return [k for k in units(m) if red(sig(k, a, m), m) == red(a, m)]

def cond(h, m):                            # smallest d | m with every k = 1 mod d inside h
    return min(d for d in range(1, m + 1) if m % d == 0
               and all(k in h for k in units(m) if k % d == 1 % d))

def roots(f, p):                           # f low first; its roots mod p
    return [x for x in range(p) if sum(c * x ** i for i, c in enumerate(f)) % p == 0]

def status(f, p):
    return {2: "split", 0: "inert", 1: "ramified"}[len(roots(f, p))]

def cond_data(f, bad, ps):                 # smallest m making status depend on p mod m
    for m in range(1, 100):
        seen = {}
        for p in ps:
            if p not in bad and m % p and seen.setdefault(p % m, status(f, p)) != status(f, p):
                break
        else:
            return m

def fx(a, m):
    z = val(a, m)
    return f"{round(z.real, 10) + 0.0:.10f} + {round(z.imag, 10) + 0.0:.10f}i"

ps = [p for p in range(2, 1000) if all(p % q for q in range(2, p))]
r5 = num(5, {1: 1, 2: -1, 3: -1, 4: 1})
s20 = num(20, {4: 1, 8: -1, 12: -1, 16: 1})
i20, n20 = num(20, {5: 1}), num(20, {1: 1, 9: 1, 13: -1, 17: -1})
print(f"Phi_5 = {cyc(5)}, Phi_20 = {cyc(20)} (low coefficient first)")
print(f"sqrt5 = z - z^2 - z^3 + z^4 = {fx(r5, 5)}, its square mod Phi_5 = {red(mul(r5, r5, 5), 5)}")
print(f"all plus signs, z + z^2 + z^3 + z^4 = {red(num(5, {1: 1, 2: 1, 3: 1, 4: 1}), 5)}")
print(f"sqrt(-5) = z + z^9 - z^13 - z^17 in Q(zeta_20) = {fx(n20, 20)}, square = {red(mul(n20, n20, 20), 20)}")
print("p  p mod 5  sigma_p(sqrt5)  sqrt5^p = sigma_p(sqrt5) mod p  x^2-x-1 mod p")
for p in [2, 3, 7, 11, 13, 17, 19, 23, 29]:
    sp = sig(p, r5, 5)
    sign = "+sqrt5" if red(sp, 5) == red(r5, 5) else "-sqrt5"
    pw = [1, 0, 0, 0, 0]
    for _ in range(p):
        pw = mul(pw, r5, 5, p)
    frob = red(pw, 5, p) == red(sp, 5, p)
    print(f"{p:<3}{p % 5:^9}{sign:^16}{'yes' if frob else 'no':^33}{status([-1, -1, 1], p)}")
    assert frob and (sign == "+sqrt5") == (status([-1, -1, 1], p) == "split")
h5, h20s, h20i, h20n = fixer(r5, 5), fixer(s20, 20), fixer(i20, 20), fixer(n20, 20)
hhcf = [k for k in h20s if k in h20i]
print(f"fixing sqrt5 in (Z mod 5)^x: {h5}; in (Z mod 20)^x: {h20s}")
print(f"fixing i: {h20i}; fixing sqrt(-5): {h20n}; fixing i and sqrt5: {hhcf}")
sub = {}
for mask in range(1, 256):
    s = [u for b, u in enumerate(units(20)) if mask >> b & 1]
    if 1 in s and all(x * y % 20 in s for x in s for y in s):
        sub[len(s)] = sub.get(len(s), 0) + 1
print(f"subgroups of (Z mod 20)^x by size: {sub}")
print(f"fixing zeta_5: {fixer(num(20, {4: 1}), 20)}; fixing z + 1/z: {fixer(num(20, {1: 1, 19: 1}), 20)}")
c_alg = [cond(h5, 5), cond(h20i, 20), cond(h20n, 20)]
c_dat = [cond_data([-1, -1, 1], [5], ps), cond_data([1, 0, 1], [2], ps), cond_data([5, 0, 1], [2, 5], ps)]
print(f"conductors of Q(sqrt5), Q(i), Q(sqrt(-5)) by subgroup: {c_alg}; by primes below 1000: {c_dat}")
odd = [p for p in ps if p != 5]
sp5 = [p for p in odd if status([-1, -1, 1], p) == "split"]
sp_n = [p for p in ps if p not in (2, 5) and status([5, 0, 1], p) == "split"]
rep = [p for p in ps if p != 5 and any(((p - 5 * y * y) ** 0.5).is_integer() for y in range(1, 15) if p >= 5 * y * y)]
print(f"Q(sqrt5): {len(sp5)} of the {len(odd)} primes below 1000 other than 5 split, exactly those with p mod 5 in {sorted({p % 5 for p in sp5})}")
print(f"Q(sqrt(-5)): {len(sp_n)} of the {len(ps) - 2} other than 2 and 5 split, exactly p mod 20 in {sorted({p % 20 for p in sp_n})}")
print(f"p = x^2 + 5y^2 below 1000, other than 5: {len(rep)} primes, exactly p mod 20 in {sorted({p % 20 for p in rep})}; first {rep[:6]}")
cube = {0: 0, 1: 0, 3: 0}
for p in ps[2:]:
    cube[len(roots([-2, 0, 0, 1], p))] += 1
print(f"x^3 - 2 mod p for {len(ps) - 2} primes 5 to 997: roots 0/1/3 in {cube[0]}/{cube[1]}/{cube[3]} primes")
print(f"mod 5: roots {roots([-2, 0, 0, 1], 5)}, cofactor x^2 + 3x + 4 has roots {roots([4, 3, 1], 5)}")
sq = [len(units(m)) // len({x * x % m for x in units(m)}) for m in (125, 64)]
print(f"local count: square classes of units mod 125 and mod 64: {sq[0]}, {sq[1]}; "
      f"quadratic extensions of Q_5 and Q_2: {2 * sq[0] - 1}, {2 * sq[1] - 1}")
print(f"inertia bound: phi(4) x phi(5) = {len(units(4))} x {len(units(5))} = {len(units(20))} = phi(20)")
print(f"mistake, conductor 5 for Q(sqrt(-5)): 3 is {status([5, 0, 1], 3)}, 13 is {status([5, 0, 1], 13)}, both 3 mod 5")
print(f"mistake, x^2 - 5 at p = 2: roots {roots([-5, 0, 1], 2)} (looks ramified); x^2 - x - 1: {status([-1, -1, 1], 2)}")
assert red(mul(r5, r5, 5), 5) == [5, 0, 0, 0] and red(mul(n20, n20, 20), 20) == [-5] + [0] * 7
assert abs(val(r5, 5) - 5 ** 0.5) < 1e-12 and abs(val(n20, 20) - 1j * 5 ** 0.5) < 1e-12
assert h5 == [1, 4] and h20n == [1, 3, 7, 9] and hhcf == [1, 9] and sub == {1: 1, 2: 3, 4: 3, 8: 1}
assert c_alg == c_dat == [5, 4, 20]
assert all((p in sp5) == (p % 5 in h5) for p in odd)
assert all((p in sp_n) == (p % 20 in h20n) for p in ps if p not in (2, 5))
assert all((p in rep) == (p % 20 in hhcf) for p in ps)
assert cube[1] > 0 and roots([4, 3, 1], 5) == []
print("ALL CHECKS PASS")
