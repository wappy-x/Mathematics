# The convolution theorem -- the check behind the card.  A box blur b, 1 mm
# wide, is smeared with itself.  Road one: the convolution integral as a sum.
# Road two: Fourier transforms by Simpson's rule, against b-hat squared.
import math
H = 1 / 400                                    # grid step, in mm

def box(t): return 1.0 if -0.5 <= t < 0.5 else 0.0
def shutter(t): return 1.0 if 0 <= t < 1 else 0.0

def conv(f, g, t, lo, hi):                     # midpoint sum of f(s) g(t - s) ds
    return sum(f(lo + (k + 0.5) * H) * g(t - lo - (k + 0.5) * H) for k in range(round((hi - lo) / H))) * H

def fourier(vals, lo, w):                      # Simpson's rule for v(t) e^(-iwt) dt, nodes lo + kH
    tot, last = 0, len(vals) - 1
    for k, v in enumerate(vals):
        c = 1 if k in (0, last) else (4 if k % 2 else 2)
        tot += c * v * complex(math.cos(w * (lo + k * H)), -math.sin(w * (lo + k * H)))
    return tot * H / 3

def bhat(w): return 1.0 if w == 0 else math.sin(w / 2) / (w / 2)      # by hand, the box
def phat(w): return (1 - complex(math.cos(w), -math.sin(w))) / (1j * w)  # by hand, the shutter
def show(z): return f"{round(z.real, 6) + 0.0:.6f} {'-' if round(z.imag, 6) < 0 else '+'} {abs(z.imag):.6f}i"
def row(xs, d=6): return ", ".join(f"{round(x, d) + 0.0:.{d}f}" for x in xs)
def sci(x): e = math.floor(math.log10(x)); return f"{x / 10 ** e:.1f}e{e}"

nodes = [-1 + k * H for k in range(801)]
tent = [conv(box, box, t, -0.5, 0.5) for t in nodes]
quarter = [0, 0.25, 0.5, 0.75, 1]
print(f"b * b by the sliding sum at t = 0, 0.25, 0.5, 0.75, 1 mm: {row(conv(box, box, t, -0.5, 0.5) for t in quarter)}")
print(f"the tent 1 - |t| at the same points: {row(1 - abs(t) for t in quarter)}")
print(f"chart, b * b at t = -1.5 to 1.5 in steps of 0.25: {row((conv(box, box, k / 4, -0.5, 0.5) for k in range(-6, 7)), 2)}")
bnum = fourier([1.0] * 401, -0.5, math.pi)
print(f"w = pi (stripes 2 mm apart): b-hat by Simpson {bnum.real:.6f}; by hand sin(w/2)/(w/2) {bhat(math.pi):.6f}")
tnum = fourier(tent, -1, math.pi)
print(f"w = pi: transform of b * b by Simpson {tnum.real:.6f}; b-hat squared {bhat(math.pi) ** 2:.6f}")
ws = range(17)
gap = max(abs(fourier(tent, -1, w) - bhat(w) ** 2) for w in ws)
print(f"largest gap, transform of b * b against b-hat squared, w = 0 to 16: {sci(gap)}")
print(f"chart, b-hat at w = 0 to 16: {row((fourier([1.0] * 401, -0.5, w).real for w in ws), 2)}")
print(f"chart, transform of b * b at w = 0 to 16: {row((fourier(tent, -1, w).real for w in ws), 2)}")
ptri = [conv(shutter, shutter, t, 0, 1) for t in [k * H for k in range(801)]]
pgap = max(abs(fourier(ptri, 0, w) - phat(w) ** 2) for w in (math.pi, 2))
print(f"motion blur p on 0 to 1 mm: p-hat(pi) = {show(phat(math.pi))}; p-hat(pi)^2 = {show(phat(math.pi) ** 2)}")
print(f"transform of p * p by Simpson: at pi {show(fourier(ptri, 0, math.pi))}; at 2 {show(fourier(ptri, 0, 2))}")
print(f"p-hat(2)^2 by hand: {show(phat(2) ** 2)}; largest gap {sci(pgap)}")
print(f"mistake, pointwise product b x b = b: transform at pi {bnum.real:.6f}, not {tnum.real:.6f}")
corr = fourier([conv(shutter, lambda u: shutter(-u), t, 0, 1) for t in nodes], -1, math.pi)
print(f"mistake, no flip, p(s) p(s - t): transform at pi {show(corr)}; |p-hat(pi)|^2 = {abs(phat(math.pi)) ** 2:.6f}")
print(f"break, f = g = 1 (not integrable): sum over |s| < L at L = 10, 100, 1000: "
      f"{row((conv(lambda s: 1.0, lambda s: 1.0, 0, -L, L) for L in (10, 100, 1000)), 1)}")
dconv = lambda a, c: [sum(a[j] * c[k - j] for j in range(len(a)) if 0 <= k - j < len(c)) for k in range(len(a) + len(c) - 1)]
print(f"3-pixel box blur applied twice, weights over 9: {dconv([1, 1, 1], [1, 1, 1])}")
dice = [sum(1 for x in range(1, 7) for y in range(1, 7) if x + y == n) for n in range(2, 13)]
print(f"two dice, ways to make 2 to 12: {dconv([1] * 6, [1] * 6)}; by listing all 36 rolls: {dice}")
assert max(abs(v - (1 - abs(t))) for v, t in zip(tent, nodes)) < 1e-12   # road one: the sum is the tent
assert gap < 1e-6                                                          # road two: transform of b * b = b-hat^2
assert pgap < 1e-6                                                         # off-centre, complex: p-hat^2, phase and all
assert abs(corr - abs(phat(math.pi)) ** 2) < 1e-6                           # no flip: |p-hat|^2, phase lost
print("ALL CHECKS PASS")
