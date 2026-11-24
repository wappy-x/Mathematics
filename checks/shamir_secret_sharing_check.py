# Shamir secret sharing -- the check behind the card.  Standard library only.
# Toy sizes: a field of 7919 elements holds under 13 bits, so this is INSECURE
# as a key store.  Real systems split a 256-bit key byte by byte in GF(256).
from math import log2, floor

P = 7919                       # a prime, so the clock mod P is a field
COEF = [1234, 166, 94]         # f(x) = 1234 + 166x + 94x^2; in use 166, 94 are random
SECRET, K, N = COEF[0], 3, 5   # the secret, the threshold, the number of shares

def inv(a, p=P):               # extended Euclid: a * inv(a) = 1 mod p
    r0, r1, t0, t1 = p, a % p, 0, 1
    while r1:
        q = r0 // r1
        r0, r1, t0, t1 = r1, r0 - q * r1, t1, t0 - q * t1
    return t0 % p if r0 == 1 else None     # None: no inverse exists

def f_at(coef, x, p=P):        # Horner's rule, mod p
    y = 0
    for c in reversed(coef):
        y = (y * x + c) % p
    return y

def weights(xs, at=0, p=P):    # Lagrange weights l_j(at) = prod (at - x_m) / (x_j - x_m)
    w = []
    for j, xj in enumerate(xs):
        num = den = 1
        for m, xm in enumerate(xs):
            if m != j:
                num, den = num * (at - xm) % p, den * (xj - xm) % p
        w.append(num * inv(den, p) % p)
    return w

def lagrange(pts, at=0, p=P):  # road 1: the weighted sum of the share values
    return sum(w * y for w, (_, y) in zip(weights([x for x, _ in pts], at, p), pts)) % p

def gauss(pts, p=P):           # road 2: solve for every coefficient, row by row
    k = len(pts)
    A = [[x ** e % p for e in range(k)] + [y % p] for x, y in pts]
    for c in range(k):
        piv = next(r for r in range(c, k) if A[r][c])
        A[c], A[piv] = A[piv], A[c]
        iv = inv(A[c][c], p)
        A[c] = [v * iv % p for v in A[c]]
        for r in range(k):
            fac = A[r][c]
            if r != c and fac:
                A[r] = [(a - fac * b) % p for a, b in zip(A[r], A[c])]
    return [A[r][k] for r in range(k)]

def subsets(items, size):      # every choice of `size` items, in order
    if size == 0: return [[]]
    return [[items[i]] + rest for i in range(len(items)) for rest in subsets(items[i + 1:], size - 1)]

# ---- deal the shares ----
print(f"field GF({P}), toy size: {log2(P):.2f} bits per share, insecure; real: a 256-bit key, byte by byte in GF(256)")
shares = [(x, f_at(COEF, x)) for x in range(1, N + 1)]
print("shares:", " ".join(f"({x}, {y})" for x, y in shares))
assert [y for _, y in shares] == [1494, 1942, 2578, 3402, 4414]   # worked by hand
assert f_at(COEF, 0) == SECRET

# ---- rebuild from three shares, two ways ----
w123 = weights([1, 2, 3])
print(f"shares 1,2,3: weights {w123[0]}, {w123[1]}, {w123[2]} (3, -3, 1); secret {lagrange(shares[:3])}")
assert w123 == [3, P - 3, 1] and lagrange(shares[:3]) == SECRET
t = [shares[1], shares[3], shares[4]]
w245 = weights([2, 4, 5])
terms = [w * y % P for w, (_, y) in zip(w245, t)]
print(f"inverses mod {P}: 1/2 = {inv(2)}, 1/3 = {inv(3)}, 1/6 = {inv(6)}")
print(f"shares 2,4,5: weights {w245[0]}, {w245[1]}, {w245[2]}; terms {terms[0]} + {terms[1]} + {terms[2]} = {sum(terms)} -> secret {sum(terms) % P}")
assert 3 * inv(3) % P == 1 and sum(w245) % P == 1 and sum(terms) % P == SECRET
raw = ", ".join(f"{w * y:,}" for w, (_, y) in zip(w245, t))
print(f"by hand: 20/6 = 20 x {inv(6)} = {20 * inv(6):,}; 10/(-2) = {10 // -2}; 8/3 = 8 x {inv(3)} = {8 * inv(3):,}; products before wrapping {raw}")
ok_l = ok_g = total = 0
for size in (3, 4, 5):
    for sub in subsets(shares, size):
        total += 1
        ok_l += lagrange(sub) == SECRET
        ok_g += gauss(sub) == COEF + [0] * (size - K)
print(f"every set of 3, 4 or 5 shares: {total} sets; Lagrange gives 1234 in {ok_l}, row solving gives 1234 + 166x + 94x^2 in {ok_g}")
assert total == 16 and ok_l == 16 and ok_g == 16

# ---- two shares: every secret fits, each by exactly one polynomial ----
y1, y2 = shares[0][1], shares[1][1]
for guess in (0, 4321):
    c = gauss([(0, guess), (1, y1), (2, y2)])
    print(f"secret {guess} fits shares 1, 2 with f(x) = {c[0]} + {c[1]}x + {c[2]}x^2")
    assert f_at(c, 1) == y1 and f_at(c, 2) == y2 and c[0] == guess
for p, label in ((P, "prime 7919"), (P + 1, "7920, not prime")):
    cnt = [0] * p              # share 1 fixes a1 from a2, so count the a2 that also fit share 2
    for a2 in range(p):
        cnt[(2 * a2) % p] += 1
    per = [cnt[(y2 - 2 * y1 + s) % p] for s in range(p)]
    print(f"mod {label}: secrets fitting shares 1, 2 = {sum(1 for v in per if v)} of {p}; polynomials per secret {min(per)} to {max(per)}")
    assert (min(per), max(per)) == ((1, 1) if p == P else (0, 2))
print(f"chance of these two shares, for every secret: 1 in {P}^2 = {P * P:,}")
p = 11                         # road 3: every polynomial over GF(11), every pair of x
tally = {}
for s in range(p):
    for a1 in range(p):
        for a2 in range(p):
            for u, v in subsets([1, 2, 3, 4, 5], 2):
                key = (u, v, f_at([s, a1, a2], u, p), f_at([s, a1, a2], v, p), s)
                tally[key] = tally.get(key, 0) + 1
print(f"clock of {p}, exhaustive: {p ** 3} polynomials, 10 pairs, {len(tally)} cells, hits per cell {min(tally.values())} to {max(tally.values())}")
assert len(tally) == 10 * p ** 3 and set(tally.values()) == {1}

# ---- what breaks ----
bad = [shares[0], (2, 1943), shares[2]]
s_bad, f4 = lagrange(bad), lagrange(bad, 4)
print(f"share 2 typed as 1943: rebuilt secret {s_bad}; predicted share 4 {f4}, held {shares[3][1]}")
assert s_bad == SECRET - 3 and f4 != shares[3][1]
cands = sorted({1494 - a1 - a2 for a1 in range(1495) for a2 in range(1495 - a1)   # share 1 fixes s
                if (1494 - a1 - a2) + 2 * a1 + 4 * a2 == 1942})                    # does share 2 fit?
print(f"integers, coefficients >= 0: shares 1, 2 leave {len(cands)} secrets, {cands[0]} to {cands[-1]}, all even: {all(c % 2 == 0 for c in cands)}")
assert SECRET in cands and len(cands) == 150
print(f"mod 7920: 1/2 exists? {inv(2, P + 1) is not None}")
print("share at x = 0 hands out f(0) =", f_at(COEF, 0))

# ---- chart: curves through shares 1, 2 over ordinary numbers ----
def real_at(pts, x):           # the same Lagrange sum, in ordinary decimals
    total = 0.0
    for j, (xj, yj) in enumerate(pts):
        r = 1.0
        for m, (xm, _) in enumerate(pts):
            if m != j: r *= (x - xm) / (xj - xm)
        total += yj * r
    return total
xs = [i / 4 for i in range(13)]
for h in (0, 1234, 2500):
    ys = [floor(real_at([(0, h), (1, 1494), (2, 1942)], x) + 0.5) for x in xs]
    print(f"chart, secret {h}:", ", ".join(map(str, ys)))
    assert ys[4] == 1494 and ys[8] == 1942 and ys[0] == h
print("ALL CHECKS PASS")
