# The fast Fourier transform -- the check behind the card.  Standard library only.
# A handclap convolved with a room's echo, 4096 samples each, illustrative 16-bit integers.
# Road 1: the sum written out, in exact integers.  Road 2: the recursive radix-2 FFT, three
# transforms.  Road 3: the in-place FFT with bit reversal, both signals packed into one transform.
import math, functools
M64 = (1 << 64) - 1
def signal(seed, n, power):                           # SplitMix64 noise fading to nothing over n samples
    s, out = seed, []
    for k in range(n):
        s = (s + 0x9E3779B97F4A7C15) & M64
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        r = z ^ (z >> 31)
        mag = (r >> 1) % 32768 * (n - k) ** power // n ** power
        out.append(-mag if r & 1 else mag)
    return out
flops = [0]
def cmul(a, b): return complex(a.real * b.real - a.imag * b.imag, a.real * b.imag + a.imag * b.real)
def total(g): return functools.reduce(lambda s, v: s + v, g, 0.0)   # plain left-to-right sum
def turn(k, n, sign): return complex(                 # the twiddle w^k, straight from cos and sin
    math.cos(2 * math.pi * k / n), sign * math.sin(2 * math.pi * k / n))
def fft(x, sign=-1, repeated=False):                  # road 2: halve, recurse, recombine
    n = len(x)
    if n == 1:
        return [x[0]]
    ev, od = fft(x[0::2], sign, repeated), fft(x[1::2], sign, repeated)
    out, w, w1 = [0j] * n, 1 + 0j, turn(1, n, sign)
    for k in range(n // 2):
        if not repeated: w = turn(k, n, sign)
        t = cmul(w, od[k])
        out[k], out[k + n // 2] = ev[k] + t, ev[k] - t
        flops[0] += 10                                # one complex multiply (6), two complex adds (4)
        if repeated:
            w = cmul(w, w1)                                # the mistake: w^(k+1) from w^k, error piles up
    return out
def fft_inplace(x, sign=-1):                          # road 3: the library's loop, no recursion
    n, a, bits = len(x), list(x), len(x).bit_length() - 1
    for i in range(n):                                # move each sample to its bit-reversed slot
        j = 0
        for b in range(bits):
            j = (j << 1) | ((i >> b) & 1)
        if i < j:
            a[i], a[j] = a[j], a[i]
    tw, m = [turn(k, n, sign) for k in range(n // 2)], 2
    while m <= n:
        for s in range(0, n, m):
            for k in range(m // 2):
                t = cmul(tw[k * (n // m)], a[s + k + m // 2])
                a[s + k], a[s + k + m // 2] = a[s + k] + t, a[s + k] - t
                flops[0] += 10
        m *= 2
    return a
def pad(x, N): return [complex(v, 0) for v in x] + [0j] * (N - len(x))
def conv_plain(a, b, N, repeated=False):              # three transforms and N products
    A, B = fft(pad(a, N), -1, repeated), fft(pad(b, N), -1, repeated)
    flops[0] += 6 * N + N                             # N complex products, then N divisions
    return [v.real / N for v in fft([cmul(A[k], B[k]) for k in range(N)], 1, repeated)]
def conv_packed(a, b, N):                             # a in the real part, b in the imaginary part
    Z, P = fft_inplace([complex(v, w) for v, w in zip(a + [0] * (N - len(a)), b + [0] * (N - len(b)))]), []
    for k in range(N):
        pr, pi, qr, qi = Z[k].real, Z[k].imag, Z[-k % N].real, -Z[-k % N].imag
        A = complex((pr + qr) * 0.5, (pi + qi) * 0.5)          # a's transform: 4 flops
        H = complex((pi - qi) * 0.5, (qr - pr) * 0.5)          # b's transform: 4 flops
        P.append(cmul(A, H))                                        # their product: 6 flops
    flops[0] += 14 * N + N
    return [v.real / N for v in fft_inplace(P, 1)]
def direct(a, b):                                     # road 1: the sum written out, exact integers
    c, mul, add, top = [0] * (len(a) + len(b) - 1), 0, 0, -1
    for i, ai in enumerate(a):
        for j, bj in enumerate(b):
            c[i + j] += ai * bj
        mul, add, top = mul + len(b), add + max(0, top - i + 1), i + len(b) - 1   # outputs i..top held a term: adds
    return c, mul, add
def route(n): return 15 * 2 * n * ((2 * n).bit_length() - 1) + 7 * 2 * n   # three transforms, N = 2n
def plain_sum(n): return n * n + (n - 1) * (n - 1)
n = 4096; N = 2 * n; lg = N.bit_length() - 1             # lg = log2 N, 13 here
clap, room = signal(2026, n, 4), signal(1111, n, 2)
c, mul, add = direct(clap, room)
flops[0] = 0; c2 = conv_plain(clap, room, N); f_plain = flops[0]
flops[0] = 0; c3 = conv_packed(clap, room, N); f_packed = flops[0]
e2, e3 = max(abs(c2[j] - c[j]) for j in range(2 * n - 1)), max(abs(c3[j] - c[j]) for j in range(2 * n - 1))
exact = all(round(c2[j]) == c[j] == round(c3[j]) for j in range(len(c)))
big = max(abs(v) for v in c)
print(f"signals: n = {n}, padded N = {N}; output {len(c)} samples, largest |c| = {big}")
print(f"road 1, the sum: {mul} multiplications ({n} x {n}) + {add} additions ({n - 1} x {n - 1}) = {mul + add} flops")
print(f"road 2, three transforms: {f_plain} flops counted; 15 N log2 N + 7N = {3 * 5 * N * lg} + {7 * N} = {route(n)}")
print(f"road 3, packed: {f_packed} flops counted; 10 N log2 N + 15N = {10 * N * lg + 15 * N}")
print(f"saving in flops: {(mul + add) / f_plain:.2f} times (three transforms), {(mul + add) / f_packed:.2f} (packed)")
print(f"largest rounding error: road 2 {e2:.2e}, road 3 {e3:.2e}, rounding allows 0.5; exact: {'yes' if exact else 'no'}")
def counted(L): flops[0] = 0; fft([0j] * (1 << L)); return flops[0]
ok_count = all(counted(L) == 5 * (1 << L) * L for L in range(1, 14))
print(f"one transform counted at N = 2 .. 8192 equals 5 N log2 N: {'yes' if ok_count else 'no'}")
print(f"per transform at N = {N}: radix-2 {5 * N * lg}; skipping the {N - 1} multiplications by w^0 = 1: "
      f"{5 * N * lg - 6 * (N - 1)}; split-radix 4 N log2 N - 6N + 8: {4 * N * lg - 6 * N + 8}")
# ---- by hand: (1 + 2x + 3x^2)(4 + 5x) through a 4-point transform ----
ha, hb = fft(pad([1, 2, 3], 4)), fft(pad([4, 5], 4))
hp = [cmul(ha[k], hb[k]) for k in range(4)]
hc = [round(v.real / 4) for v in fft(hp, 1)]
show = lambda v: " ".join(f"{round(z.real):+d}{round(z.imag):+d}i" for z in v)
print(f"by hand: A = {show(ha)}; B = {show(hb)}; A*B = {show(hp)}")
print(f"by hand: c = {hc}, the sum gives {direct([1, 2, 3, 0], [4, 5, 0, 0])[0][:4]}")
# ---- rounding: there and back, against the first-order bound 2 log2 N eta ----
u = 2.0 ** -53; mu = 2 * u; eta = mu + 4 * u / (1 - 4 * u) * (math.sqrt(2) + mu); rows = []
for L in (5, 7, 9, 11, 13):
    x, errs = pad(signal(7, 1 << L, 0), 1 << L), []
    nx = math.sqrt(total(v.real * v.real for v in x))
    for rep in (False, True):
        y = [complex(v.real / (1 << L), v.imag / (1 << L)) for v in fft(fft(x, -1, rep), 1, rep)]
        errs.append(math.sqrt(total((y[j].real - x[j].real) ** 2 + y[j].imag ** 2 for j in range(1 << L))) / nx)
    rows.append((errs[0], errs[1], 2 * L * eta))
    print(f"there and back, N = {1 << L:>4}: error {errs[0]:.2e}, bound {2 * L * eta:.2e}, "
          f"ratio {errs[0] / (2 * L * eta):.3f}; repeated twiddles {errs[1]:.2e}")
# ---- what breaks ----
c4 = conv_plain(clap, room, n)                        # no padding: N = 4096, the tail wraps round
wrap = max(abs(c4[j] - c[j]) for j in range(n))
wrap_ok = all(round(c4[j]) == c[j] + (c[j + n] if j + n < len(c) else 0) for j in range(n))
c5 = conv_plain(clap, room, N, True)                  # twiddles by repeated multiplication
e5 = max(abs(c5[j] - c[j]) for j in range(2 * n - 1))
cm = 3 * N // 2 * lg + N                              # complex multiplications in road 2
print(f"break, no padding: largest error {wrap:.0f}; it is the tail wrapped onto the head: {'yes' if wrap_ok else 'no'}")
print(f"break, no 1/N: largest output {big * N} instead of {big}, {N} times too big")
print(f"break, repeated twiddles: largest error {e5:.2e} instead of {e2:.2e}, {e5 / e2:.0f} times worse")
print(f"break, complex multiplications counted as flops: {cm} against {n * n}, claims {n * n / cm:.1f} times")
# ---- the cost curve, and where the route wins ----
xs = list(range(4, 21, 2))
print("chart, log2 n:", xs)
print("chart, log10 flops, the sum:", ", ".join(f"{math.log10(plain_sum(1 << L)):.2f}" for L in xs))
print("chart, log10 flops, three transforms:", ", ".join(f"{math.log10(route(1 << L)):.2f}" for L in xs))
cross = next(1 << L for L in range(1, 30) if route(1 << L) < plain_sum(1 << L))
two_h = next(1 << L for L in range(1, 30) if plain_sum(1 << L) >= 200 * route(1 << L))
print(f"route first beats the sum at n = {cross}: {route(cross)} against {plain_sum(cross)}")
print(f"saving first reaches 200 at n = {two_h}: {plain_sum(two_h) / route(two_h):.1f}; at n = 8192: {plain_sum(8192) / route(8192):.2f}")
assert mul + add == plain_sum(n) and f_plain == route(n)          # counted flops against the formulas
assert ok_count and f_packed == 10 * N * lg + 15 * N
assert e2 < 0.5 and e3 < 0.5 and exact                             # both transform roads hit the exact sum
assert hc == [4, 13, 22, 15]
assert max(abs(z - w) for z, w in zip(ha + hb, [6, -2 - 2j, 2, -2 + 2j, 9, 4 - 5j, -1, 4 + 5j])) < 1e-12   # the hand spectra
assert all(r[0] < r[2] for r in rows) and rows[-1][1] > 10 * rows[-1][0]
assert wrap_ok and wrap > 1e6 and e5 > 10 * e2
print("ALL CHECKS PASS")
