# Adding a million numbers without losing the small ones -- the check behind the card.
# Standard library only.  A tracker adds 0.1 m per tick, ten million ticks.  Plain, pairwise
# and Kahan sums meet the exact total of the stored 0.1 (fractions) and a range-by-range walk.
# Then a barometer stream: textbook one-pass variance against two-pass and Welford.
import struct
from fractions import Fraction as F
from math import log10, ceil, log2, frexp, sqrt

def sci(x, p):                          # 1.610e-4, the same digits in Rust
    m, e = f"{x:.{p}e}".split("e")
    return f"{m}e{int(e)}"
P32 = struct.Struct("<f")
def f32(x):                             # round a double to the nearest single (32-bit) number;
    return P32.unpack(P32.pack(x))[0]   # a + or - of two singles, done in double, rounds right
U = 2.0 ** -53                          # unit roundoff of a double
U32 = 2.0 ** -24                        # unit roundoff of a single
N = 10 ** 7

def plain(xs, r):                       # left to right, one rounding per addition
    t = 0.0
    for x in xs:
        t = r(t + x)
    return t
def kahan(xs, r):                       # carry c, minus the part of each term that fell off
    t, c = 0.0, 0.0
    for x in xs:
        y = r(x - c)
        s = r(t + y)
        c = r(r(s - t) - y)             # (s - t) is what got in; minus y leaves minus the loss
        t = s
    return t
def pairwise(xs, r):                    # add neighbours, then neighbours of those, and so on
    a = list(xs)
    while len(a) > 1:
        b = [r(a[i] + a[i + 1]) for i in range(0, len(a) - 1, 2)]
        if len(a) % 2:
            b.append(a[-1])
        a = b
    return a[0]
def walk(x, n, p, r):                   # second road to the plain total, no long loop: inside
    k, t, E = 1, x, frexp(x)[1] - 1     # [2^E, 2^(E+1)) the gap is 2^(E-p), and every step
    while True:                         # adds x rounded to a whole number of gaps
        a = round(x / 2.0 ** (E - p)) * 2.0 ** (E - p)
        steps = ceil((2.0 ** (E + 1) - t) / a)
        if k + steps > n:
            return t + (n - k) * a
        k, t, E = k + steps, r(t + (steps - 1) * a + x), E + 1   # the step into the next range rounds there
def err(t, x, n):                       # true error: computed total minus the exact n * x
    return float(F(t) - n * F(x))

# ---- the tracker in double precision: ten million steps of 0.1 ----
x = 0.1
xs = [x] * N
tp, tk, tw = plain(xs, float), kahan(xs, float), pairwise(xs, float)
ep, ek, ew = err(tp, x, N), err(tk, x, N), err(tw, x, N)
total = N * x                           # sum of |x_i|: 1e6 to 3 digits
L = ceil(log2(N))
b_partial = U * x * (N * (N + 1) / 2 - 1)            # u times the sum of partial totals
b_plain = (N - 1) * U / (1 - (N - 1) * U) * total    # gamma_(n-1) times sum |x_i|
b_pair = L * U / (1 - L * U) * total                 # gamma_L times sum |x_i|
b_kahan = 2 * U * total                              # 2u sum |x_i|, plus a part of order n u^2
gap = 2.0 ** -33                                     # gap between doubles from 2^19 to 2^20
print(f"stored 0.1 minus 0.1,{sci(float(F(x) - F(1, 10)), 3)}")
print(f"exact total of stored values minus 1e6,{sci(float(N * F(x) - 1000000), 3)}")
print(f"plain,{tp:.10f},error,{sci(ep, 3)},range walk,{walk(x, N, 52, float):.10f}")
print(f"  bound u x sum of partial totals,{sci(b_partial, 3)},ratio,{abs(ep) / b_partial:.3f}")
print(f"  bound gamma_(n-1) x sum|x|,{sci(b_plain, 3)},ratio,{abs(ep) / b_plain:.3f}")
print(f"  each step from 524288 on adds 0.1 minus,{sci(x - ((2.0 ** 19 + x) - 2.0 ** 19), 3)}")
print(f"pairwise,{tw:.10f},error,{sci(ew, 3)},levels,{L}")
print(f"  bound gamma_{L} x sum|x|,{sci(b_pair, 3)},ratio,{abs(ew) / b_pair:.3f}")
print(f"kahan,{tk:.10f},error,{sci(ek, 3)}")
print(f"  bound 2u x sum|x|,{sci(b_kahan, 3)},ratio,{abs(ek) / b_kahan:.3f},n u^2 x sum|x|,{sci(N * U * U * total, 1)}")
print(f"gap near 1e6,{sci(gap, 3)},half gap,{sci(gap / 2, 3)},u,{sci(U, 3)},u single,{sci(U32, 3)}")
assert walk(x, N, 52, float) == tp                   # two roads to the plain total, same bits
assert abs(F(tk) - N * F(x)) <= F(gap) / 2           # Kahan = exact total, rounded once
assert abs(ep) < b_partial and abs(ew) < b_pair and abs(ek) < b_kahan
assert abs(ep) > 1e5 * abs(ek)                       # plain is far worse than Kahan

# ---- error against the number of ticks: the chart ----
for k in range(1, 8):
    n = 10 ** k
    ys = xs[:n]
    rel = [abs(err(f(ys, float), x, n)) / float(n * F(x)) for f in (plain, pairwise, kahan)]
    print(f"chart,log10 n,{k},log10 rel error plain,{log10(rel[0]):.2f},pairwise,"
          f"{log10(rel[1]):.2f},kahan,{log10(rel[2]):.2f},log10 (n-1)u,{log10((n - 1) * U):.2f}")
    assert rel[2] <= U and rel[1] <= L * U and rel[0] <= (n - 1) * U / (1 - (n - 1) * U)

# ---- the same tracker on a chip with 32-bit numbers ----
x32 = f32(0.1)
xs32 = [x32] * N
sp, sk, sw = plain(xs32, f32), kahan(xs32, f32), pairwise(xs32, f32)
e32 = err(sp, x32, N)
print(f"single 0.1,{x32:.12f},exact total,{float(N * F(x32)):.4f}")
print(f"single plain,{sp:.1f},error,{e32:.4f},percent,{100 * e32 / 1e6:.2f},range walk,{walk(x32, N, 23, f32):.4f}")
print(f"single pairwise,{sw:.1f},error,{err(sw, x32, N):.4f}")
print(f"single kahan,{sk:.1f},error,{err(sk, x32, N):.4f}")
for E in range(15, 21):                 # inside [2^E, 2^(E+1)) each step adds the same amount
    a = f32(2.0 ** E + x32) - 2.0 ** E
    print(f"range,2^{E},{2 ** E},gap,{2.0 ** (E - 23)},step adds,{a},off by,{100 * (a - x32) / x32:+.2f}%")
assert walk(x32, N, 23, f32) == sp and abs(err(sk, x32, N)) <= 0.0625 / 2
assert abs(err(sw, x32, N)) <= L * U32 * 1e6 and 80000 < e32 < (N - 1) * U32 * 1.1e6

# ---- what breaks ----
bad = [1.0, 1e100, 1.0, -1e100]
print(f"kahan on 1 1e100 1 -1e100,{kahan(bad, float):.1f},true sum,2,bound 2u x sum|x|,{sci(2 * U * 2e100, 3)}")
print("flops per term,plain,1,pairwise,1,kahan,4,textbook,3,two-pass,4,welford,6")
assert kahan(bad, float) == 0.0                     # Kahan's bound is relative to sum |x|

# ---- a mean and variance in one pass: barometer readings, 101325 Pa plus quarter steps ----
def reading(k):                         # cycles 101322, 101322.25, ..., 101328 Pa: all exact
    return 101325.0 + ((k % 25) - 12) * 0.25
s1 = s2 = 0.0                           # textbook: sum x and sum x^2 in one pass
mu = M = 0.0                            # Welford: running mean, running squared distances
for k in range(N):
    v = reading(k)
    s1 += v; s2 += v * v
    d = v - mu
    mu += d / (k + 1)
    M += d * (v - mu)
m2, q = s1 / N, 0.0                     # two-pass: the mean first, then squared distances
for k in range(N):
    d = reading(k) - m2
    q += d * d
exact_mean = sum(F(reading(k)) for k in range(25)) / 25          # one full cycle, exactly
exact_var = sum((F(reading(k)) - exact_mean) ** 2 for k in range(25)) / 25
closed = F(2 * sum(j * j for j in range(1, 13)), 25 * 16)        # (1/16) x mean of j^2
kappa = sqrt(1 + float(exact_mean) ** 2 / float(exact_var))   # condition number of the variance
var_tb = (s2 - s1 * s1 / N) / N
print(f"exact mean,{float(exact_mean):.4f},exact variance,{float(exact_var):.4f},closed form,{float(closed):.4f}")
print(f"kappa,{kappa:.0f},kappa^2,{sci(kappa ** 2, 3)}")
for name, val, b in (("textbook", var_tb, N * U * kappa ** 2), ("two-pass", q / N, N * U + (N * U * kappa) ** 2),
                     ("welford", M / N, N * U * kappa)):
    e = float((F(val) - exact_var) / exact_var)       # true relative error, from exact fractions
    print(f"{name},{val:.12f},rel error,{sci(e, 3)},bound of order,{sci(b, 3)},ratio,{sci(abs(e) / b, 2)}")
print(f"welford mean error,{sci(float(F(mu) - exact_mean), 3)},sample variance n-1,{M / (N - 1):.10f}")
assert exact_var == closed == F(13, 4)
assert abs(var_tb - 3.25) > 0.1                     # textbook: wrong in the first digit
assert abs(M / N - 3.25) < 3.25 * N * U * kappa     # Welford: inside its bound
assert abs(q / N - 3.25) < 1e-9 and abs(M / N - q / N) < 1e-9
print("ALL CHECKS PASS")
