# Ruler and compass -- the check behind the card.  Nothing is imported.  cos(360/17 deg) by four square
# roots and by bisection on the cosine sum; the cubics that block the 7-gon hunted for rational roots.
def sqrt(a):                              # Newton's method, written out here
    x = max(a, 1.0)
    for _ in range(80): x = (x + a / x) / 2
    return x
def cheb(c, k):                           # cos(k t) from c = cos t: cos((k+1)t) = 2c cos(kt) - cos((k-1)t)
    lo, hi = 1.0, c
    for _ in range(k - 1): lo, hi = hi, 2 * c * hi - lo
    return hi if k else 1.0
def bisect(f, lo, hi):                    # a root between lo and hi, where f changes sign
    for _ in range(200): lo, hi = (m, hi) if (f(lo) > 0) == (f(m := (lo + hi) / 2) > 0) else (lo, m)
    return (lo + hi) / 2
def rational_roots(a):                    # a = [a0, a1, a2, a3], a0 not 0: every p/q with p | a0, q | a3
    ds = lambda m: [d for d in range(1, abs(m) + 1) if m % d == 0]
    return [f"{s * p}" if q == 1 else f"{s * p}/{q}" for p in ds(a[0]) for q in ds(a[3]) for s in (-1, 1)
            if sum(a[i] * (s * p) ** i * q ** (3 - i) for i in range(4)) == 0 and all(p % d or q % d for d in range(2, q + 1))]
def buildable(n):                         # 2^k times distinct primes p with p - 1 a power of 2
    while n % 2 == 0: n //= 2
    for p in range(3, n + 1):
        if n % p == 0 and all(p % d for d in range(2, p)):
            n //= p
            if n % p == 0 or (p - 1) & (p - 2): return False
    return True

r17 = sqrt(17)
A, B = (-1 + r17) / 2, (-1 - r17) / 2                            # t^2 + t - 4 = 0
A1, B1 = (A + sqrt(A * A + 4)) / 2, (B + sqrt(B * B + 4)) / 2    # t^2 - A t - 1 = 0 and t^2 - B t - 1 = 0
tower, small = (A1 + sqrt(A1 * A1 - 4 * B1)) / 4, (A1 - sqrt(A1 * A1 - 4 * B1)) / 4   # t^2 - A1 t + B1 = 0, t = 2c
c17, c7 = [bisect(lambda c: 1 + 2 * sum(cheb(c, k) for k in range(1, m)), lo, 0.99) for m, lo in ((9, 0.8), (4, 0.3))]
ck = [cheb(c17, k) for k in range(9)]
A2, B2 = 2 * (ck[1] + ck[2] + ck[4] + ck[8]), 2 * (ck[3] + ck[5] + ck[6] + ck[7])
cubics = [("8c^3 + 4c^2 - 4c - 1 (7-gon)", [-1, -4, 4, 8]), ("8x^3 - 6x - 1 (trisect 60 deg)", [-1, -6, 0, 8]),
          ("x^3 - 2 (double the cube)", [-2, 0, 0, 1]), ("4x^3 - 3x + 1 (trisect 180 deg)", [1, -3, 0, 4])]
c20, cube2 = bisect(lambda x: 8 * x ** 3 - 6 * x - 1, 0.5, 1.0), bisect(lambda x: x ** 3 - 2, 1.0, 2.0)
s = 1.0                                   # Archimedes: side of a 6 x 2^k-gon in a unit circle
for _ in range(30): s = s / sqrt(2 + sqrt(4 - s * s))
pi, fact = 3 * 2 ** 30 * s, lambda m: 1 if m < 2 else m * fact(m - 1)
cosd = lambda d: sum((-1) ** j * (d * pi / 180) ** (2 * j) / fact(2 * j) for j in range(30))   # own cosine
t1, t2 = [bisect(lambda d: cosd(d) - x / sqrt(x * x + y * y), 0.0, 90.0) for x, y in ((5 / 6, sqrt(3) / 6), (2 / 3, sqrt(3) / 3))]
print(f"17-gon, road one, four square roots: cos(360/17 deg) = {tower:.12f}")
print(f"17-gon, road two, bisection on the cosine sum: {c17:.12f}")
print(f"tower: sqrt 17 = {r17:.6f}, A = {A:.6f}, B = {B:.6f}, A1 = {A1:.6f}, B1 = {B1:.6f}")
print(f"road two's cosines: A + B = {A2 + B2:.6f}, A x B = {A2 * B2:.6f}, 17 turns give cos = {cheb(c17, 17):.6f}")
print(f"7-gon: cos(360/7 deg) = {c7:.12f}, 7 turns give cos = {cheb(c7, 7):.6f}")
for name, a in cubics: print(f"rational roots of {name}: {', '.join(rational_roots(a)) or 'none'}")
print(f"cos 20 deg = {c20:.6f}, own cosine of 20 deg = {cosd(20):.6f}, cube root of 2 = {cube2:.6f}, "
      f"pi by Archimedes = {pi:.6f}, square side for a unit circle sqrt(pi) = {sqrt(pi):.6f}")
print(f"buildable n-gons, n = 3 to 20: {[n for n in range(3, 21) if buildable(n)]}; "
      f"not buildable: {[n for n in range(3, 21) if not buildable(n)]}")
print(f"mistake, smaller root at the last step: {small:.6f} = cos(4 x 360/17 deg) = {ck[4]:.6f}")
print(f"mistake, chord of 60 deg cut in three: angles {t1:.3f}, {t2 - t1:.3f}, {60 - t2:.3f} deg")
print(f"mistake, near-miss 7-gon side sqrt(3)/2 = {sqrt(3) / 2:.6f}, true {sqrt(2 - 2 * c7):.6f}, short by {100 * (1 - sqrt(3) / 2 / sqrt(2 - 2 * c7)):.2f}%")
print(f"figure, 17-gon: centre (180, 120), radius 100, P1 ({180 + 100 * c17:.1f}, {120 - 100 * sqrt(1 - c17 * c17):.1f})")
print(f"figure, root: base (20, 200) to (340, 200), foot x {20 + 320 / 18:.1f}, top y {200 - 320 / 18 * r17:.1f}")
assert abs(tower - c17) < 1e-12 and abs(small - ck[4]) < 1e-12            # two roads, both roots
assert abs(A2 + B2 + 1) < 1e-9 and abs(A2 * B2 + 4) < 1e-9                 # the first pairing, checked by road two
assert [rational_roots(a) for _, a in cubics] == [[], [], [], ["-1", "1/2"]]  # the control finds its roots
assert abs(cheb(c7, 7) - 1) < 1e-9 and abs(cosd(20) - c20) < 1e-9          # 7 turns close; the cubic gives cos 20
print("ALL CHECKS PASS")
