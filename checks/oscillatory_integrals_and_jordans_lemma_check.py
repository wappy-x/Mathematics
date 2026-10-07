# Jordan's lemma -- the check behind the card.  Standard library only.
# The Cauchy pulse 1/(1+x^2): its frequency content at a is the integral of
# cos(ax)/(1+x^2) over the real line, claimed to be pi e^(-|a|).
# Road 1: 2 pi i x residue at i.  Road 2: the real line only, Simpson plus a tail.
# Road 3: segment plus upper arc at finite R, each a trapezoid sum.
import math

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def cexp(w): return math.exp(w.real) * complex(math.cos(w.imag), math.sin(w.imag))
def trap(g, lo, hi, n=40000):                 # trapezoid sum of g from lo to hi
    h = (hi - lo) / n
    return h * (sum(g(lo + j * h) for j in range(1, n)) + (g(lo) + g(hi)) / 2)
def arc(g, R):                                # z = R e^(it), dz = i z dt, t from 0 to pi
    return trap(lambda t: g(R * cexp(1j * t)) * 1j * R * cexp(1j * t), 0, math.pi)
def real_line(a, L=400.0, n=40000):           # road 2: 2 x (Simpson on [0, L] + tail by parts)
    h = L / n
    s = sum((1 if j in (0, n) else 4 if j % 2 else 2) * math.cos(a * j * h) / (1 + (j * h) ** 2) for j in range(n + 1))
    tail = -math.sin(a * L) / (a * (1 + L * L)) + 2 * L * math.cos(a * L) / (a * a * (1 + L * L) ** 2)
    return 2 * (s * h / 3 + tail)

a = 1.0
pulse = lambda z: cexp(1j * a * z) / (1 + z * z)        # e^(iaz)/(1+z^2)
tilted = lambda z: z * cexp(1j * a * z) / (1 + z * z)   # degree gap 1: needs Jordan
res = cexp(1j * a * 1j) / (2j)                          # (z - i) x pulse, at z = i
road1 = 2j * math.pi * res
print(f"pulse, a = {a:g}: residue at i {show(res)}; road 1, 2 pi i x residue: {show(road1)}")
r2 = {L: real_line(a, L, int(100 * L)) for L in (25, 100, 400)}
print("road 2, real line to L plus tail: " + "; ".join(f"L = {L}: {v:.6f} (off {abs(v - road1.real):.1e})" for L, v in r2.items()))
seg, arc4 = trap(lambda x: pulse(complex(x, 0)), -4, 4), arc(pulse, 4)
print(f"road 3, R = 4: segment {show(seg)} + arc {show(arc4)} = {show(seg + arc4)}")
for R in (2, 4, 8, 16):
    J, ta = trap(lambda t: math.exp(-a * R * math.sin(t)), 0, math.pi), abs(arc(tilted, R))
    ml, jb = math.pi * R * R / (R * R - 1), math.pi * R / (a * (R * R - 1))
    print(f"R = {R}: e^(-aR sin t) summed {J:.6f} < pi/(aR) {math.pi / (a * R):.6f}; tilted arc {ta:.6f}, ML {ml:.6f}, Jordan {jb:.6f}")
    assert J < math.pi / (a * R) and ta <= jb
res_t = 1j * cexp(1j * a * 1j) / (2j)                   # (z - i) x tilted, at z = i
closed16 = trap(lambda x: tilted(complex(x, 0)), -16, 16) + arc(tilted, 16)
print(f"tilted, x e^(iax)/(1+x^2): 2 pi i x residue {show(2j * math.pi * res_t)}; R = 16 closed {show(closed16)}")
freqs = [k / 2 for k in range(-6, 7)]
print("chart, pi e^(-|a|) at a = -3 to 3 by 0.5: " + ", ".join(f"{math.pi * math.exp(-abs(f)):.2f}" for f in freqs))
ts = [k * math.pi / 12 for k in range(7)]
print("chart, t = k pi/12: sin t " + ", ".join(f"{math.sin(t):.2f}" for t in ts) + "; 2t/pi " + ", ".join(f"{2 * t / math.pi:.2f}" for t in ts))
cosk = lambda z: (cexp(1j * z) + cexp(-1j * z)) / 2 / (1 + z * z)
print(f"mistake, cos(az) kept: loop gives {show(2j * math.pi * (cexp(-1) + cexp(1)) / 2 / 2j)}; its arc at R = 8 {show(arc(cosk, 8))}")
neg = lambda z: cexp(-1j * z) / (1 + z * z)
print(f"mistake, a = -1 closed upward: 2 pi i x residue {show(2j * math.pi * cexp(1) / 2j)}; arc at R = 8 {show(arc(neg, 8))}")
flat = lambda z: cexp(1j * a * z)
print(f"mistake, g = 1 does not shrink: arc at R = 8 {show(arc(flat, 8))}, at R = 16 {show(arc(flat, 16))}")
print(f"mistake, real part taken for the sine integral: {(2j * math.pi * res_t).real:.6f}")
assert all(abs(real_line(f) - math.pi * math.exp(-abs(f))) < 1e-7 for f in freqs if f != 0)
assert abs(seg + arc4 - road1) < 1e-7 and abs(closed16 - 2j * math.pi * res_t) < 1e-6
assert all(math.sin(k * math.pi / 2000) >= k / 1000 - 1e-15 for k in range(1001))
print("ALL CHECKS PASS")
