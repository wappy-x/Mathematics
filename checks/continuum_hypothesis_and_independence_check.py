# The continuum hypothesis -- the check behind the card.  Nothing is imported.
# CH itself is independent of the axioms, so no program can test it.  What the
# code checks are the finite shadows of the two proofs: Cohen's forcing (a new
# real built by meeting dense sets, dodging a ground list of reals) and Godel's
# levels (finite levels of the constructible universe are the full tower).
L, K = 40, 4                     # binary digits kept per real; new reals added

def isqrt(m):                    # floor square root by bisection, written out
    lo, hi = 0, 1
    while hi * hi <= m:
        hi *= 2
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if mid * mid <= m else (lo, mid)
    return lo

def frac_bits(p, q):             # first L binary digits of p/q, by long division
    out = ""
    for _ in range(L):
        p *= 2
        out += str(p // q)
        p %= q
    return out

def sqrt_bits(m):                # first L binary digits of sqrt(m) - 1
    s = isqrt(m * 4 ** L)
    assert s * s <= m * 4 ** L < (s + 1) * (s + 1)
    return format(s - 2 ** L, "b").zfill(L)

def yn(claim):
    return "yes" if claim else "no"

def flip(bit):
    return "1" if bit == "0" else "0"

def meet(p, r):                  # extend condition p into "disagrees with r somewhere"
    if not r.startswith(p):
        return p, "met for free"
    return p + flip(r[len(p)]), "extended by one digit"

def differ(a, b):                # road two: look for a digit where both are defined
    return any(x != y for x, y in zip(a, b))

def dodgers(n, reals):           # conditions of length n that agree with no listed real
    count = 0
    for v in range(2 ** n):
        s = format(v, "b").zfill(n)
        if all(differ(s, r) for r in reals):
            count += 1
    return count

GROUND = [("0", "0" * L), ("1/3", frac_bits(1, 3)), ("1/7", frac_bits(1, 7)),
          ("2/5", frac_bits(2, 5)), ("sqrt2-1", sqrt_bits(2)), ("sqrt3-1", sqrt_bits(3))]
reals = [r for _, r in GROUND]

between = [sum(1 for k in range(n + 1, 2 ** n)) for n in range(7)]
print(f"finite sizes strictly between n and 2^n, n = 0..6: {between}")
print(f"the same by 2^n - n - 1:                         {[2 ** n - n - 1 for n in range(7)]}")
print("ground list, first 12 binary digits:")
for name, r in GROUND:
    print(f"  {name:<8} 0.{r[:12]}...")
print("conditions that already dodge all six (counted / by formula):")
lengths = (1, 2, 3, 4, 6, 8, 12)
brute = [dodgers(n, reals) for n in lengths]
formula = [2 ** n - len({r[:n] for r in reals}) for n in lengths]
for n, b, f in zip(lengths, brute, formula):
    print(f"  length {n:>2}: {b:>4} / {f:>4} of {2 ** n}")
g = ""
print("one Cohen real, meeting one dense set per listed real:")
for name, r in GROUND:
    g, how = meet(g, r)
    print(f"  dodge {name:<8} {how:<22} condition now {g}")
diag = "".join(flip(r[i]) for i, r in enumerate(reals))
print(f"Cantor's diagonal for comparison: {diag}")
print(f"generic differs from every listed real: {yn(all(differ(g, r) for r in reals))}")
cols, steps = [""] * K, {"free": 0, "extended": 0}
for c in range(K):
    for r in reals:
        cols[c], how = meet(cols[c], r)
        steps["free" if how == "met for free" else "extended"] += 1
    for d in range(c):
        a, b = cols[c], cols[d]
        if differ(a, b):
            steps["free"] += 1
            continue
        steps["extended"] += 1
        if len(a) < len(b):
            cols[c] = a + flip(b[len(a)])
        elif len(a) > len(b):
            cols[d] = b + flip(a[len(b)])
        else:
            cols[c], cols[d] = a + "0", b + "1"
print(f"{K} Cohen reals added side by side:")
for c in range(K):
    print(f"  column {c}: {cols[c]}")
dense = K * len(reals) + K * (K - 1) // 2
pairs = sum(1 for c in range(K) for d in range(c) if differ(cols[c], cols[d]))
print(f"dense sets met: {steps['free'] + steps['extended']} of {dense}; "
      f"free {steps['free']}, extended {steps['extended']}")
print(f"pairs of new reals that differ: {pairs} of {K * (K - 1) // 2}")
only = []
for c in range(K):               # the same columns, dodging the list but not each other
    p = ""
    for r in reals:
        p, _ = meet(p, r)
    only.append(p)
same = sum(1 for c in range(K) for d in range(c) if differ(only[c], only[d]))
print(f"columns dodging only the list: {' '.join(only)}; pairs that differ {same} of {K * (K - 1) // 2}")
every = [format(v, "b").zfill(4) for v in range(16)]
print(f"ground list holding all 16 strings of length 4: dodgers {dodgers(4, every)}")
level, tower, sizes, codes_ok = [], 0, [(0, 0)], True
for n in range(5):
    picks = [0]
    for x in level:              # every subset of the level, as its Ackermann code
        picks = picks + [p + 2 ** x for p in picks]
    codes_ok = codes_ok and sorted(picks) == list(range(2 ** len(level)))
    level, tower = sorted(picks), 2 ** tower
    sizes.append((len(level), tower))
print(f"tower V_0..V_5 built / by 2^previous: {[s for s, _ in sizes]} / {[t for _, t in sizes]}")
assert between == [2 ** n - n - 1 for n in range(7)]               # two roads, finite gap
assert brute == formula and brute[0] == 0 and brute[-1] == 4096 - 6  # two roads, density
assert [r[:12] for r in reals[1:4]] == [format(p * 4096 // q, "b").zfill(12) for p, q in ((1, 3), (1, 7), (2, 5))]
assert all(n * n <= m * 4 ** 12 < (n + 1) ** 2      # road two for the roots: square the 12-digit prefix
           for m, n in ((2, 4096 + int(reals[4][:12], 2)), (3, 4096 + int(reals[5][:12], 2))))
assert g == "11" and diag == "100101"                               # the worked table, by hand
assert all(differ(g, r) for r in reals) and all(differ(diag, r) for r in reals)
assert pairs == K * (K - 1) // 2
assert dodgers(4, every) == 0 and codes_ok and same == 0
assert [s for s, _ in sizes] == [t for _, t in sizes] == [0, 1, 2, 4, 16, 65536]
print("ALL CHECKS PASS")
