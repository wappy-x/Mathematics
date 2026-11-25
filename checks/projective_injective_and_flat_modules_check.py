# Projective, injective and flat modules -- the check behind the card.  Nothing is
# imported.  Part 1: over each ring Z/n, n = 2 to 30, every module Z/m (m > 1, m
# dividing n) is tested by finite search: projective two ways (a section, a summand),
# injective by Baer's criterion, flat by the ideal test, all against gcd(m, n/m) = 1.
# Part 2: over Z, the sequence 0 -> Z -> Z -> Z/2 -> 0 (first map times 2) is fed to
# Hom(P, -), Hom(-, I) and - tensor F, with exact fractions for Q and Q/Z.

def gcd(a, b):
    a, b = abs(a), abs(b)
    while b:
        a, b = b, a % b
    return a

def yn(c):
    return "yes" if c else "no"

# Part 1.  The ring Z/n acts on the module Z/m by r.x = r*x mod m.
def section(n, m):      # the onto map Z/n -> Z/m, 1 -> 1, has a module map back with s(1) = r
    return [r for r in range(n) if m * r % n == 0 and r % m == 1]

def summand(n, m):      # an idempotent e (e*e = e) with e(Z/n) of size m: Z/n = eZ/n + (1-e)Z/n
    return any(e * e % n == e and n // gcd(e, n) == m for e in range(n))

def baer(n, m, ideals):  # every map from an ideal dZ/n to Z/m extends to all of Z/n
    for d in ideals:
        for x in range(m):                   # d -> x is a well-defined map when (n/d) x = 0
            if (n // d) * x % m == 0 and not any(d * y % m == x for y in range(m)):
                return False
    return True

def ideal_test(n, m):   # dZ/n tensor Z/m = Z/m over (n/d)Z/m, sent into Z/m by x -> d x
    for d in range(1, n + 1):
        if n % d == 0:
            killed = {x for x in range(m) if d * x % m == 0}
            if not killed <= {(n // d) * z % m for z in range(m)}:
                return False
    return True

def verdicts(n, m):
    divs = [d for d in range(1, n + 1) if n % d == 0]
    return [bool(section(n, m)), summand(n, m), baer(n, m, divs), ideal_test(n, m)]

print("ring  module  section  summand  Baer  flat  gcd(m, n/m)")
for n, m in [(6, 2), (6, 3), (6, 6), (4, 2), (4, 4), (12, 2), (12, 4), (12, 6)]:
    v = verdicts(n, m)
    print(f"Z/{n:<3} Z/{m:<4} {yn(v[0]):<8} {yn(v[1]):<8} {yn(v[2]):<5} {yn(v[3]):<5} {gcd(m, n // m)}")
pairs = [(n, m) for n in range(2, 31) for m in range(2, n + 1) if n % m == 0]
agree = all(verdicts(n, m) == [gcd(m, n // m) == 1] * 4 for n, m in pairs)
good = sum(1 for n, m in pairs if verdicts(n, m)[0])
whole_ring_only = sum(1 for n, m in pairs if baer(n, m, [1]))
crt = sorted({(x % 2, x % 3) for x in range(6)})
idem = [e for e in range(6) if e * e % 6 == e]
print(f"Z/6 -> Z/2 x Z/3, x -> (x mod 2, x mod 3), hits {len(crt)} of 6 pairs")
print(f"idempotents of Z/6: {idem}; 3Z/6 = {sorted({3 * r % 6 for r in range(6)})}, "
      f"4Z/6 = {sorted({4 * r % 6 for r in range(6)})}, 3 + 4 = {(3 + 4) % 6} mod 6")
print(f"sections of Z/6 -> Z/2: s(1) in {section(6, 2)}; of Z/4 -> Z/2: s(1) in {section(4, 2)}")
print(f"free Z/6-modules have {[6 ** k for k in range(4)]} members; Z/2 has 2")
print(f"Z/4 on Z/2, ideal 2Z/4, map 2 -> 1: solutions of 2y = 1 in Z/2: {[y for y in range(2) if 2 * y % 2 == 1]}")
print(f"pairs (n, m) checked: {len(pairs)}; all four tests match gcd(m, n/m) = 1: {yn(agree)}; all three hold: {good}")
print(f"Baer tested on the ideal Z/n alone passes {whole_ring_only} of {len(pairs)}")

# Part 2.  Fractions p/q in lowest terms, q > 0; in Q/Z the top is taken mod q.
def frac(p, q, mod1=False):
    if q < 0:
        p, q = -p, -q
    g = gcd(p, q)
    p, q = p // g, q // g
    return (p % q, q) if mod1 else (p, q)

def show(f):
    return str(f[0]) if f[1] == 1 else f"{f[0]}/{f[1]}"

QZ = sorted({frac(c, d, True) for d in range(1, 13) for c in range(d)})       # Q/Z, bottoms <= 12
QS = sorted({frac(c, d) for d in range(1, 13) for c in range(-12, 13)})      # a window of Q
ZW = range(-1000, 1001)                                                     # a window of Z
hom_z2_z = [k for k in ZW if 2 * k == 0]
ext_z = [y for y in ZW if 2 * y == 1]
ext_qz = [show(y) for y in QZ if frac(2 * y[0], y[1], True) == frac(1, 3)]
ker_zz = [x for x in ZW if 2 * x == 0]
ker_z2 = [x for x in range(2) if 2 * x % 2 == 0]
ext_z2 = [y for y in range(2) if 2 * y % 2 == 1]
ker_q = [show(x) for x in QS if frac(2 * x[0], x[1]) == (0, 1)]
ker_qz = [show(x) for x in QZ if frac(2 * x[0], x[1], True) == (0, 1)]
roots = {len([c for c in range(n * x[1]) if frac(n * c, n * x[1], True) == x])
         for x in QZ for n in range(2, 13)}
roots_ok = all(len([c for c in range(n * x[1]) if frac(n * c, n * x[1], True) == x]) == n
               for x in QZ for n in range(2, 13))
lcm = 1
for k in range(1, 21):
    lcm = lcm * k // gcd(lcm, k)
hom_q_z = [k for k in ZW if all(k % N == 0 for N in range(1, 21))]
lift_z = all(any(b % 2 == t for b in ZW) for t in range(2))          # each map Z -> Z/2, 1 -> t, lifts to 1 -> b
div_q = all(frac(n * y[0], y[1]) == x for x in QS for n in range(2, 13) for y in [frac(x[0], n * x[1])])
print("the sequence 0 -> Z -> Z -> Z/2 -> 0, first map times 2")
print(f"Hom(Z/2, -): maps Z/2 -> Z have f(1) in {hom_z2_z}, so the identity of Z/2 does not lift")
print(f"Hom(-, Z): extend 2 -> 1 from 2Z to Z: solutions of 2y = 1 in -1000..1000: {ext_z}")
print(f"Hom(-, Q/Z): extend 2 -> 1/3 from 2Z to Z: solutions of 2y = 1/3: [{", ".join(ext_qz)}]")
print(f"tensor Z: times 2 on Z, kernel in -1000..1000: {ker_zz}")
print(f"tensor Z/2: times 2 on Z/2, kernel {ker_z2}")
print(f"tensor Q: times 2 on Q, kernel in the window of {len(QS)} fractions: [{", ".join(ker_q)}]")
print(f"tensor Q/Z: times 2 on Q/Z, kernel [{", ".join(ker_qz)}]")
print(f"Q/Z, {len(QZ)} classes, n = 2..12: n y = x has exactly n solutions every time: {yn(roots_ok)}")
print(f"a map Q -> Z sends 1 to a multiple of 1..20; lcm(1..20) = {lcm}; such f(1) in -1000..1000: {hom_q_z}")
print("module  projective  injective  flat")
table = [("Z", lift_z, bool(ext_z), ker_zz == [0]), ("Q", hom_q_z != [0], div_q, ker_q == ["0"]),   # Z lifts; Q divides
         ("Q/Z", len(ker_qz) == 1, roots_ok, len(ker_qz) == 1),    # not flat, so not projective
         ("Z/2", hom_z2_z != [0], bool(ext_z2), len(ker_z2) == 1)]
for name, p, i, f in table:
    print(f"{name:<7} {yn(p):<11} {yn(i):<10} {yn(f)}")
tor = [x for x in range(6) if 4 * x % 6 == 0]
ext = len(range(6)) // len({4 * x % 6 for x in range(6)})
print(f"house example: times 4 on Z/6 has kernel {tor} (Tor) and {ext} classes left over (Ext)")
assert agree and len(pairs) == 81 and good == 59                 # four roads, one rule
assert section(6, 2) == [3] and section(4, 2) == [] and crt == [(a, b) for a in range(2) for b in range(3)]
assert hom_z2_z == [0] and ext_z == [] and ext_qz == ["1/6", "2/3"]   # Z/2 and Z fail
assert ker_z2 == [0, 1] and ker_q == ["0"] and ker_qz == ["0", "1/2"]
assert roots_ok and roots == set(range(2, 13)) and hom_q_z == [0] and lcm == 232792560
assert whole_ring_only == len(pairs) and tor == [0, 3] and ext == 2 and ker_zz == [0]
assert [r[1:] for r in table] == [(1, 0, 1), (0, 1, 1), (0, 1, 0), (0, 0, 0)]   # the verdict table
print("ALL CHECKS PASS")
