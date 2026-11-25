# Fourier analysis on a finite abelian group -- the check behind the card.
# Standard library only: math gives cos, sin, pi, gcd and prod.  Every
# character, transform, convolution and count is written out here.  Two
# groups: the 12-hour clock Z/12, and three votes in {-1, 1}^3.
import math

def cis(t):                                   # the point at angle t on the unit circle
    return complex(math.cos(t), math.sin(t))

def fmt(z):                                   # a+bi, 6 decimals, rounding dust dropped
    re = 0.0 if abs(z.real) < 1e-9 else z.real
    im = 0.0 if abs(z.imag) < 1e-9 else z.imag
    return f"{re:.6f}{'+' if im >= 0 else '-'}{abs(im):.6f}i"

close = lambda a, b: abs(a - b) < 1e-9
yn = lambda claim: "yes" if claim else "no"
fl = lambda v: "[" + ", ".join(f"{x:.2f}" for x in v) + "]"  # a list of reals, 2 decimals

N = 12
chars = [[cis(2 * math.pi * j * k / N) for k in range(N)] for j in range(N)]
hom = all(close(c[(a + b) % N], c[a] * c[b]) for c in chars for a in range(N) for b in range(N))
gram = all(close(sum(chars[j][k] * chars[l][k].conjugate() for k in range(N)) / N, j == l)
           for j in range(N) for l in range(N))
order = [next(m for m in range(1, N + 1) if close(chars[j][1] ** m, 1)) for j in range(N)]
print(f"Z/12: 12 characters, each turns sums into products on all 144 pairs: {yn(hom)}")
print(f"the 144 averages <chi_j, chi_l> are 1 when j = l and 0 otherwise: {yn(gram)}")
print(f"orders of chi_0..chi_11: {order}; of order 12: {order.count(12)}, so {order.count(12)} ways to match Z/12 with its dual")
assert hom and gram and order.count(12) == sum(1 for j in range(N) if math.gcd(j, N) == 1)

pairs = [(k % 4, k % 3) for k in range(N)]                       # Chinese remainder split
back = {p: k for k, p in enumerate(pairs)}
match = {}
for j in range(N):                                               # search for (a, b) per character
    for a in range(4):
        for b in range(3):
            if all(close(chars[j][k], cis(2 * math.pi * a * (k % 4) / 4) * cis(2 * math.pi * b * (k % 3) / 3)) for k in range(N)):
                match[j] = (a, b)
print(f"k -> (k mod 4, k mod 3) hits all 12 pairs: {yn(len(back) == 12)}; back again: k = (9 k1 + 4 k2) mod 12: {yn(all(back[(x, y)] == (9 * x + 4 * y) % N for x, y in pairs))}")
print("character j as (a on Z/4, b on Z/3): " + ", ".join(f"{j}:({a},{b})" for j, (a, b) in sorted(match.items())))
print(f"j = (3a + 4b) mod 12 for all twelve: {yn(all((3 * a + 4 * b) % N == j for j, (a, b) in match.items()))}")
assert len(match) == 12 and all((3 * a + 4 * b) % N == j for j, (a, b) in match.items())

count = [0, 0]                                # products used: direct sum, Chinese remainder split

def hat(f):                                   # f^(j) = (1/12) sum_k f(k) conj chi_j(k)
    count[0] += N * N
    return [sum(f[k] * chars[j][k].conjugate() for k in range(N)) / N for j in range(N)]

def hat_crt(f):                               # the same through Z/4 x Z/3, 3 then 4 at a time
    count[1] += 4 * 3 * 3 + 4 * 3 * 4
    inner = {(k1, b): sum(f[back[(k1, k2)]] * cis(-2 * math.pi * b * k2 / 3) for k2 in range(3))
             for k1 in range(4) for b in range(3)}
    out = [0] * N
    for a in range(4):
        for b in range(3):
            out[(3 * a + 4 * b) % N] = sum(inner[(k1, b)] * cis(-2 * math.pi * a * k1 / 4) for k1 in range(4)) / N
    return out

f = [1 if k % 3 == 0 else 0 for k in range(N)]                   # the quarter marks 0, 3, 6, 9
g = [1 if k in (0, 1) else 0 for k in range(N)]                  # a two-hour window
fh, gh = hat(f), hat(g)
supp = lambda v: sum(1 for z in v if abs(z) > 1e-9)
print(f"f = quarter marks: f^ nonzero at j = {[j for j in range(N) if abs(fh[j]) > 1e-9]}, each {fmt(fh[0])}")
print(f"g = window 0, 1: g^(1) = {fmt(gh[1])}, g^(4) = {fmt(gh[4])}, g^(6) = {fmt(gh[6])}")
crt_ok = all(close(x, y) for x, y in zip(hat_crt(f) + hat_crt(g), fh + gh))
print(f"transform through Z/4 x Z/3 equals the direct sum: {yn(crt_ok)}; products {count[1] // 2} against {count[0] // 2}")
inv_ok = all(close(sum(h[j] * chars[j][k] for j in range(N)), v[k]) for v, h in ((f, fh), (g, gh)) for k in range(N))
print(f"sum of f^(j) chi_j rebuilds f and g at all 12 hours: {yn(inv_ok)}")
for name, v, h in (("f", f, fh), ("g", g, gh)):
    print(f"Plancherel for {name}: mean |{name}|^2 = {sum(abs(x) ** 2 for x in v) / N:.6f}, sum |{name}^|^2 = {sum(abs(z) ** 2 for z in h):.6f}")
conv = [sum(f[y] * g[(x - y) % N] for y in range(N)) / N for x in range(N)]
ch = hat(conv)
print(f"(f*g)(x) times 12, x = 0..11: {[round(12 * c) for c in conv]}")
print(f"(f*g)^(4) = {fmt(ch[4])}; f^(4) g^(4) = {fmt(fh[4] * gh[4])}; all 12 agree: {yn(all(close(ch[j], fh[j] * gh[j]) for j in range(N)))}")
assert crt_ok and inv_ok and all(close(ch[j], fh[j] * gh[j]) for j in range(N))
delta = [1 if k == 0 else 0 for k in range(N)]
print(f"support sizes: f {supp(f)} x {supp(fh)} = {supp(f) * supp(fh)}; g {supp(g)} x {supp(gh)} = {supp(g) * supp(gh)}; one hour {supp(delta)} x {supp(hat(delta))} = {supp(hat(delta))}")
prods = {s: bin(s).count("1") * supp(hat([(s >> k) & 1 for k in range(N)])) for s in range(1, 2 ** N)}
best = min(prods.values())
reach = {s for s, p in prods.items() if p == best}
cosets = {sum(1 << ((c + h * d) % N) for h in range(N // d)) for d in range(1, N + 1) if N % d == 0 for c in range(N)}
print(f"all 4095 nonempty sets of hours: smallest product {best}, reached by {len(reach)} sets; cosets of the 6 subgroups: {len(cosets)}, the same sets: {yn(reach == cosets)}")
assert best == N and reach == cosets

n = 3
xs = [tuple(1 - 2 * ((b >> (n - 1 - i)) & 1) for i in range(n)) for b in range(2 ** n)]
maj = [1 if sum(x) > 0 else -1 for x in xs]
chiS = lambda S, x: math.prod(x[i] for i in range(n) if (S >> (n - 1 - i)) & 1)
brute = [sum(maj[t] * chiS(S, xs[t]) for t in range(8)) / 8 for S in range(8)]
v, h, ops = maj[:], 1, 0                                         # fast Walsh-Hadamard butterflies
while h < 8:
    for i in range(0, 8, 2 * h):
        for j in range(i, i + h):
            v[j], v[j + h], ops = v[j] + v[j + h], v[j] - v[j + h], ops + 2
    h *= 2
fast = [x / 8 for x in v]
name = lambda S: "".join(f"x{i + 1}" for i in range(n) if (S >> (n - 1 - i)) & 1)
print(f"Maj on the 8 inputs from (1,1,1) to (-1,-1,-1): {maj}")
print(f"coefficients by averaging equal the butterflies: {yn(brute == fast)}; operations {ops} against {8 * 8}")
terms = sorted((bin(S).count("1"), name(S), c) for S, c in enumerate(brute) if c != 0)
print("Maj = " + " ".join(f"{'+' if c > 0 else '-'} {abs(c):.1f} {nm}" for _, nm, c in terms).lstrip("+ "))
print(f"sum of Maj^(S) chi_S rebuilds Maj on all 8 inputs: {yn(all(sum(brute[S] * chiS(S, x) for S in range(8)) == m for x, m in zip(xs, maj)))}")
deg = [sum(brute[S] ** 2 for S in range(8) if bin(S).count("1") == d) for d in range(n + 1)]
print(f"Fourier weight at degree 0..3: {fl(deg)}; total {sum(deg):.2f}; mean Maj^2 {sum(m * m for m in maj) / 8:.2f}")
flip = lambda x, i: tuple(-c if k == i else c for k, c in enumerate(x))
infl = [sum(1 for t, x in enumerate(xs) if maj[xs.index(flip(x, i))] != maj[t]) / 8 for i in range(n)]
infl_w = [sum(brute[S] ** 2 for S in range(8) if (S >> (n - 1 - i)) & 1) for i in range(n)]
print(f"influence of each voter: by flipping {fl(infl)}; from weights {fl(infl_w)}")
p = 0.1
noisy = sum((p ** sum(e)) * ((1 - p) ** (n - sum(e))) / 8 * (maj[t] != maj[xs.index(tuple(c * (1 - 2 * s) for c, s in zip(x, e)))])
            for t, x in enumerate(xs) for e in [((b >> 2) & 1, (b >> 1) & 1, b & 1) for b in range(8)])
stab = 0.5 - 0.5 * sum((1 - 2 * p) ** bin(S).count("1") * brute[S] ** 2 for S in range(8))
print(f"each vote misread with chance {p}: winner changes, counted {noisy:.6f}, from weights {stab:.6f}; one voter alone {p:.6f}")
mul = lambda x, y: tuple(a * b for a, b in zip(x, y))
blr = sum(1 for x in xs for y in xs if maj[xs.index(x)] * maj[xs.index(y)] == maj[xs.index(mul(x, y))]) / 64
print(f"linearity test f(x)f(y) = f(xy) passes: counted {blr:.6f}, from weights {0.5 + 0.5 * sum(c ** 3 for c in brute):.6f}")
cube = min(bin(s).count("1") * sum(1 for S in range(8) if sum(((s >> t) & 1) * chiS(S, xs[t]) for t in range(8)) != 0) for s in range(1, 256))
print(f"uncertainty on the cube: Maj {len(maj)} x {sum(1 for c in brute if c)} = {8 * sum(1 for c in brute if c)}; smallest over 255 sets of inputs: {cube}")
assert brute == fast and deg == [0, 0.75, 0, 0.25] and infl == [0.5] * 3 == infl_w and cube == 8
assert close(noisy, stab) and close(blr, 0.5 + 0.5 * sum(c ** 3 for c in brute))

S3 = [(0, 1, 2), (1, 0, 2), (0, 2, 1), (2, 1, 0), (1, 2, 0), (2, 0, 1)]  # shuffles of 3 things
comp, homs = lambda p, q: tuple(p[q[i]] for i in range(3)), []
for c in range(6 ** 6):                                          # every map to sixth roots of 1
    e = [(c // 6 ** i) % 6 for i in range(6)]
    if all(e[S3.index(comp(a, b))] == (e[S3.index(a)] + e[S3.index(b)]) % 6 for a in S3 for b in S3):
        homs.append(e)
swap = [1 if s == (1, 0, 2) else 0 for s in S3]
kept = sum(abs(sum(swap[t] * cis(-2 * math.pi * e[t] / 6) for t in range(6)) / 6) ** 2 for e in homs)
print(f"break 1, S3 is not abelian: {len(homs)} characters for 6 members; they keep {kept / (1 / 6):.6f} of a swap's energy")
o62 = max(next(m for m in range(1, 13) if all(close(cis(2 * math.pi * m * (a * x / 6 + b * y / 2)), 1) for x in range(6) for y in range(2)))
          for a in range(6) for b in range(2))
print(f"break 2, Z/6 x Z/2 (6 and 2 share a factor): highest character order {o62}, not 12")
print(f"break 3, Maj coefficients added unsquared: {sum(abs(c) for c in brute):.2f}, not 1")
print(f"break 4, sums on both sides for f: sum |f|^2 = {sum(f)}, sum |12 f^|^2 = {sum(abs(12 * z) ** 2 for z in fh):.6f}")
assert len(homs) == 2 and close(kept * 6, 1 / 3) and o62 == 6
print("ALL CHECKS PASS")
