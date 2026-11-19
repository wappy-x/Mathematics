# The Jacobi symbol -- the check behind the card.  Standard library only, nothing imported.
# (1001/9907) by reciprocity alone, in six rounds and with no factoring; then three more
# roads to the same -1; then Euler's criterion as the Solovay-Strassen test, against the
# Fermat and Miller-Rabin tests, on every base of every odd composite below 2,000.
def gcd(a, b): return a if b == 0 else gcd(b, a % b)
def modpow(b, e, n):                       # square and multiply on the n clock
    r, b = 1, b % n
    while e:
        if e & 1: r = r * b % n
        b, e = b * b % n, e >> 1
    return r
def jacobi(a, n, log=None, two_rule=True, flip_rule=True):   # road one: reciprocity only
    a, s, r = a % n, 1, 0
    while a:
        r, k, start = r + 1, 0, (a, n)
        while a % 2 == 0:                  # pull out the twos: (2/n) = -1 when n is 3 or 5 mod 8
            a, k = a // 2, k + 1
            if two_rule and n % 8 in (3, 5): s = -s
        two = -1 if n % 8 in (3, 5) else 1
        if a == 1:
            if log is not None: log.append(f"round {r}: ({start[0]}/{start[1]})  twos out: {k}, each (2/{n}) = {two:+d}  top is 1, so the sign is the answer: {s:+d}")
            return s, r
        flip = -1 if a % 4 == 3 and n % 4 == 3 else 1
        if flip_rule: s *= flip            # reciprocity: flip, and change sign if both are 3 mod 4
        a, n = n % a, a
        if log is not None: log.append(f"round {r}: ({start[0]}/{start[1]})  twos out: {k}{f', (2/{start[1]}) = {two:+d}' if k else ''}  flip: ({start[1]}/{n}), sign {flip:+d}  reduce: ({a}/{n})  sign so far {s:+d}")
    return (s if n == 1 else 0), r
def is_prime(n): return n > 1 and all(n % d for d in range(2, int(n ** 0.5) + 1))
def euler(a, p):                           # a^((p-1)/2) on the p clock, read as -1, 0 or +1
    v = modpow(a, (p - 1) // 2, p)
    return -1 if v == p - 1 else v
def jacobi_def(a, n):                      # road three: the definition, factor n and multiply Legendre symbols
    s, m, p = 1, n, 3
    while m > 1:
        while m % p == 0: s, m = s * euler(a, p), m // p
        p += 2
    return s
log = []
J, rounds = jacobi(1001, 9907, log)
for line in log: print(line)
print(f"(1001/9907) = {J:+d} after {rounds} rounds; 9907 prime by trial division: {is_prime(9907)}")
e = modpow(1001, 4953, 9907)
print(f"road two, Euler's criterion: 1001^4953 on the 9907 clock = {e}, which is 9907 - 1, so {euler(1001, 9907):+d}")
print(f"road three, factor 1001 = 7 x 11 x 13 = {7 * 11 * 13}: (7/9907) = {euler(7, 9907):+d}, (11/9907) = {euler(11, 9907):+d}, (13/9907) = {euler(13, 9907):+d}, product {jacobi_def(1001, 9907):+d}")
sq = sum(1 for x in range(9907) if x * x % 9907 == 1001)
print(f"road four, brute force: x with x^2 = 1001 on the 9907 clock: {sq} of 9907 tried; residues mod 9907: {len({x * x % 9907 for x in range(1, 9907)})}")
pairs = bad = 0
for n in range(3, 1000, 2):
    for a in range(n):
        pairs += 1; bad += jacobi(a, n)[0] != jacobi_def(a, n)
print(f"reciprocity algorithm against the definition, odd n below 1,000, every a below n: {pairs} pairs, {bad} disagree")
recip = sum(1 for m in range(3, 300, 2) for n in range(3, 300, 2) if gcd(m, n) == 1 and jacobi_def(m, n) * jacobi_def(n, m) != (-1) ** ((m - 1) // 2 * ((n - 1) // 2)))
print(f"reciprocity for every coprime odd m, n below 300, from the definition: {recip} failures")
P = 2 ** 61 - 1; A = 10 ** 18 + 9
JP, RP = jacobi(A, P)
print(f"a 19-digit case: ({A}/{P}) = {JP:+d} in {RP} rounds; Euler's criterion gives {euler(A, P):+d}")
sq15 = sorted({x * x % 15 for x in range(15)})
print(f"(2/15) = {jacobi(2, 15)[0]:+d}, yet the squares mod 15 are {sq15}: 2 is not one; (2/3) = {euler(2, 3):+d}, (2/5) = {euler(2, 5):+d}")
def census(n):                             # coprime bases; Fermat, Euler (Solovay-Strassen) and strong liars
    d, s = n - 1, 0
    while d % 2 == 0: d, s = d // 2, s + 1
    co = f = eu = st = 0; subset = True
    for a in range(1, n):
        if gcd(a, n) != 1: continue
        co += 1; f += modpow(a, n - 1, n) == 1
        e_ok = modpow(a, (n - 1) // 2, n) == jacobi(a, n)[0] % n
        x = modpow(a, d, n); s_ok = x == 1 or x == n - 1
        for _ in range(s - 1):
            x = x * x % n; s_ok = s_ok or x == n - 1
        eu += e_ok; st += s_ok; subset = subset and (e_ok or not s_ok)
    return co, f, eu, st, subset
for n in (221, 561, 1105, 1729):
    co, f, eu, st, _ = census(n)
    print(f"{n}: coprime bases {co}, Fermat liars {f}, Euler liars {eu}, strong liars {st}")
for a in (2, 5, 13):
    x, j = modpow(a, 280, 561), jacobi(a, 561)[0]
    print(f"561, base {a:>2}: a^280 = {x:>3}, (a/561) = {j:+d} -> {'liar, says prime' if x == j % 561 else 'witness, proves composite'}; Fermat's a^560 = {modpow(a, 560, 561)}")
worst, arg, comps, sub_ok, half_ok = 0, [], 0, True, True
for n in range(9, 2000, 2):
    if is_prime(n): continue
    co, f, eu, st, sub = census(n); comps += 1
    sub_ok, half_ok, pm = sub_ok and sub, half_ok and 2 * eu <= co, eu * 1000 // co
    if pm > worst: worst, arg = pm, [n]
    elif pm == worst: arg.append(n)
print(f"odd composites below 2,000: {comps}; none has Euler liars above half its coprime bases: {half_ok}; most, per thousand: {worst}, at {arg}")
print(f"every strong liar of every one of them is an Euler liar: {sub_ok}")
print(f"20 rounds: Solovay-Strassen leaves at most 1 in {2 ** 20}, Miller-Rabin at most 1 in {4 ** 20}")
print(f"what breaks: drop the 2 rule, (1001/9907) = {jacobi(1001, 9907, two_rule=False)[0]:+d}; drop the reciprocity sign, (3/7) = {jacobi(3, 7, flip_rule=False)[0]:+d} against {euler(3, 7):+d}")
assert J == -1 and rounds == 6 and e == 9906 and jacobi_def(1001, 9907) == -1 and sq == 0
assert bad == 0 and recip == 0 and JP == euler(A, P) and jacobi(2, 15)[0] == 1 and 2 not in sq15
assert census(561)[1:4] == (320, 80, 10) and census(1729)[2] * 2 == census(1729)[0] and worst == 500 and half_ok and sub_ok
assert modpow(13, 280, 561) == 1 and jacobi(13, 561)[0] == -1 and modpow(5, 280, 561) == 67
assert jacobi(1001, 9907, two_rule=False)[0] == 1 and jacobi(3, 7, flip_rule=False)[0] == 1 and euler(3, 7) == -1
print("ALL CHECKS PASS")
