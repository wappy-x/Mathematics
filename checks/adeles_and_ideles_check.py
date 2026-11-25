# Adeles and ideles of Q: the product formula, A = Q + ([0,1) x Z-hat), and the idele class group.
# Every number is an exact fraction; nothing imported knows the answer.
from fractions import Fraction as F

def primes_upto(n):
    s = [True] * (n + 1)
    s[0] = s[1] = False
    for i in range(2, int(n ** 0.5) + 1):
        if s[i]:
            s[i * i::i] = [False] * len(s[i * i::i])
    return [i for i in range(n + 1) if s[i]]

def vp(x, p):                       # how many times p divides the nonzero fraction x
    n, d, v = x.numerator, x.denominator, 0
    while n % p == 0: n, v = n // p, v + 1
    while d % p == 0: d, v = d // p, v - 1
    return v

def size(x, v):                     # |x|_v, with v = 0 standing for the real place
    return abs(x) if v == 0 else F(v) ** (-vp(x, v))

def mod_of(x, pk):                  # a fraction with no p in its denominator, read mod p^k
    return x.numerator * pow(x.denominator, -1, pk) % pk

def principal_part(a, p):           # r in Z[1/p] with a - r a p-adic integer
    k = -vp(a, p)
    if k <= 0: return F(0)
    return F(mod_of(a * p ** k, p ** k), p ** k)

PR = primes_upto(10000)
print("== product formula ==")
x = F(7, 12)
sz = {v: size(x, v) for v in [2, 3, 7, 0]}
print("7/12:", ", ".join(f"|x|_{'inf' if v == 0 else v} = {s}" for v, s in sz.items()))
prod = sz[2] * sz[3] * sz[7] * sz[0]
fin = sz[2] * sz[3] * sz[7]
print(f"product over all places = {prod}; finite places only = {fin}")
assert prod == 1 and fin == 1 / x and sz[2] == 4 and sz[3] == 3
count, bad = 0, 0
for a in range(-60, 61):
    for b in range(1, 61):
        y = F(a, b)
        if a == 0 or y.denominator != b: continue
        count += 1
        pr = size(y, 0)
        for p in [p for p in PR if p <= 60]: pr *= size(y, p)
        bad += pr != 1
print(f"fractions a/b with 1 <= |a|, b <= 60 in lowest terms: {count}, product not 1: {bad}")
assert count > 2000 and bad == 0

print("== an adele split as rational + ([0,1) x Z-hat) ==")
a_inf, a_fin = F(53, 10), {2: F(1, 4), 3: F(2, 3)}       # every other entry is 0
r = sum(principal_part(a_fin[p], p) for p in a_fin)
n = (a_inf - r).numerator // (a_inf - r).denominator
q = r + n
b_inf = a_inf - q
b = {p: a_fin[p] - q for p in a_fin}
print(f"principal parts sum r = {r}; floor(a_inf - r) = {n}; rational q = {q}")
print(f"remainder: real {b_inf}, at 2 {b[2]}, at 3 {b[3]}, at p >= 5 {-q}")
assert 0 <= b_inf < 1 and all(vp(b[p], p) >= 0 for p in b) and vp(-q, 5) >= 0
found = set()
for d in range(1, 73):
    for k in range(-1000, 1000):
        c = F(k, d)
        ok = 0 <= a_inf - c < 1
        ok = ok and all(v == 0 or vp(v, p) >= 0 for p in PR[:20] for v in [a_fin.get(p, F(0)) - c])
        if ok: found.add(c)
print(f"brute force over k/d, d <= 72, |k| < 1000: rationals that work: {", ".join(str(c) for c in sorted(found))}")
assert found == {q}

print("== Q is discrete in the adeles ==")
real_only = [F(a, b) for b in range(1, 101) for a in range(-50, 51) if F(a, b).denominator == b and abs(F(a, b)) < F(1, 2)]
adelic = [y for y in real_only if y.denominator == 1]
print(f"fractions with denominator <= 100 in (-1/2, 1/2): {len(real_only)}; also in Z_p for every p: {", ".join(str(y) for y in adelic)}")
assert len(adelic) == 1 and adelic[0] == 0 and len(real_only) > 1000
L = 2 ** 8 * 3 ** 4 * 5 ** 2 * 7
near0 = [k * L for k in range(-300, 301) if abs(k * L) <= 10 ** 9]
print(f"no real place: multiples of 10! = {L} within real size 10^9, all p-adically as small as 10!: {len(near0)}")
assert L == 3628800 and len(near0) == 551
pp = sum(principal_part(F(1, p), p) for p in PR if p <= 29)
print(f"full product: 1/p at every p needs sum of 1/p; by p = 29 its denominator is {pp.denominator}")
assert pp.denominator == 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29

print("== ideles: rational times (positive real, unit at every prime) ==")
def idele_class(a_inf, listed, other, m):
    q = F(1 if a_inf > 0 else -1)
    for p, y in listed.items(): q *= F(p) ** vp(y, p)
    unit = lambda p: listed.get(p, other) / q
    assert all(vp(unit(p), p) == 0 for p in list(listed) + [5])
    res = {pk: mod_of(unit(p), pk) for p, pk in [(2, 4), (5, 5)]}     # m = 20 = 4 x 5
    u = [z for z in range(m) if z % 4 == res[4] and z % 5 == res[5]][0]
    norm = abs(a_inf)
    for p, y in listed.items(): norm *= size(y, p)
    return q, a_inf / q, norm, u
for name, idl in [("principal 7/12", (F(7, 12), {2: F(7, 12), 3: F(7, 12), 7: F(7, 12)}, F(7, 12))),
                  ("(5; 12 at 2, 1/3 at 3)", (F(5), {2: F(12), 3: F(1, 3)}, F(1)))]:
    q, real, norm, u = idele_class(*idl, 20)
    print(f"{name}: q = {q}, real part {real}, idele norm {norm}, unit part mod 20 = {u}")
    assert real == norm and real > 0
fro = []
for p in [3, 7, 11, 13, 17, 19]:
    q, real, norm, u = idele_class(F(1), {p: F(p)}, F(1), 20)
    assert u * p % 20 == 1 and real == F(1, p)
    fro.append(f"{p}->{u}")
print("p in the p-slot, class mod 20 (Frob_p raises roots of one to the p):", ", ".join(fro))

print("== house: p = x^2 + 5y^2 and the open subgroup {1, 9} of (Z/20)^x ==")
N = 10000
f1 = {x * x + 5 * y * y for x in range(101) for y in range(46)}
f2 = {2 * x * x + 2 * x * y + 3 * y * y for x in range(-100, 101) for y in range(-100, 101)}
ps = [p for p in PR if p not in (2, 5)]
euler = lambda a, p: pow(a % p, (p - 1) // 2, p) == 1
A = [p for p in ps if p in f1]
B = [p for p in ps if euler(-1, p) and euler(-5, p)]
C = [p for p in ps if p % 20 in (1, 9)]
D = [p for p in ps if p in f2]
splitK = sorted({p % 20 for p in ps if euler(-5, p)})
print(f"odd primes below {N} other than 5: {len(ps)}")
print(f"x^2 + 5y^2: {len(A)}; -1 and -5 both squares: {len(B)}; p = 1 or 9 mod 20: {len(C)}")
print(f"2x^2 + 2xy + 3y^2: {len(D)}, residues {sorted({p % 20 for p in D})}; -5 a square: residues {splitK}")
units = [u for u in range(1, 20) if u % 2 and u % 5]
resA = sorted({p % 20 for p in A})
print(f"units mod 20: {len(units)}; residues of x^2 + 5y^2 primes {resA}, index {len(units) // len(resA)}; share {len(A) / len(ps):.4f}")
assert A == B == C and resA == [1, 9] and len(units) // len(resA) == 4 and splitK == [1, 3, 7, 9] and sorted({p % 20 for p in D}) == [3, 7]
print("ALL CHECKS PASS")
