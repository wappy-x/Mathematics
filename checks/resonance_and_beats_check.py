# Resonance and beats -- the check behind the card.  Standard library only.
# A footbridge deck, natural frequency 1 Hz, pushed from rest by F cos(wt)
# per kg, F = 0.1 m/s^2:  y'' + b y' + w0^2 y = F cos(wt).  Road one is the
# closed form; road two steps the equation with Euler's rule, which never
# uses a sine formula, and the error halves as the step halves.
import math
F, w0, w = 0.1, 2 * math.pi, 2 * math.pi * 0.9
b = 2 * 0.01 * w0                          # damping ratio 1%

def euler(w, b, t_end, h, tail=0.0):       # new = old + step x rate; tail: max |y| at the end
    y = v = t = top = 0.0
    for _ in range(round(t_end / h)):
        y, v, t = y + h * v, v + h * (F * math.cos(w * t) - b * v - w0 * w0 * y), t + h
        top = max(top, abs(y)) if t > t_end - tail else top
    return top if tail else y

def beat(w, t): return F * (math.cos(w * t) - math.cos(w0 * t)) / (w0 * w0 - w * w)
def res(t): return F * t * math.sin(w0 * t) / (2 * w0)
def amp(f, b): return F / math.sqrt((w0 * w0 - (2 * math.pi * f) ** 2) ** 2 + (b * 2 * math.pi * f) ** 2)

mm = lambda x: f"{1000 * x:.2f}"
row = lambda xs: " ".join(xs)
hs, D = (1e-4, 5e-5), w0 * w0 - w * w
eb = [abs(euler(w, 0, 5, h) - beat(w, 5)) for h in hs]
er = [abs(euler(w0, 0, 10.25, h) - res(10.25)) for h in hs]
pk = [euler(w0, b, 150, h, 2) for h in hs]
ed = [abs(p - amp(1, b)) for p in pk]
near = beat(w0 * (1 - 1e-6), 10.25)
prod = 2 * F / D * math.sin((w0 - w) * 5 / 2) * math.sin((w0 + w) * 5 / 2)
fs = [0.8, 0.85, 0.9, 0.95, 0.98, 1.0, 1.02, 1.05, 1.1, 1.15, 1.2]
print(f"w0 = {w0:.4f} rad/s; w at 0.9 Hz = {w:.4f} rad/s; w0^2 - w^2 = {D:.4f} per s^2")
print(f"0.9 Hz from rest: y(5) = {mm(beat(w, 5))} mm; product form {mm(prod)} mm; y(10) = {mm(beat(w, 10))} mm")
print(f"steady part alone peaks at {mm(F / D)} mm; beats peak at 2F/(w0^2 - w^2) = {mm(2 * F / D)} mm")
print(f"1 Hz from rest: envelope grows {mm(F / (2 * w0))} mm/s; y(10.25) = {mm(res(10.25))} mm")
print(f"beat formula at w = w0(1 - 1e-6), t = 10.25: {mm(near)} mm")
print(f"Euler errors, h = 1e-4, 5e-5: beats {eb[0] * 1000:.4f} {eb[1] * 1000:.4f} mm; resonance {mm(er[0])} {mm(er[1])} mm")
print(f"envelopes cross at 4 w0/(w0^2 - w^2) = {4 * w0 / D:.2f} s")
print("t (s):                 " + row(f"{t}" for t in range(0, 21, 2)))
print("resonance envelope mm: " + row(mm(F * t / (2 * w0)) for t in range(0, 21, 2)))
print("beat envelope mm:      " + row(mm(2 * F / D * abs(math.sin((w0 - w) * t / 2))) for t in range(0, 21, 2)))
print(f"damped: zeta = {b / (2 * w0):.2f}, b = {b:.4f} per s; static F/w0^2 = {mm(F / w0 ** 2)} mm; peak F/(b w0) = {mm(F / (b * w0))} mm; ratio {F / (b * w0) / (F / w0 ** 2):.1f}")
print(f"damped peak by Euler to t = 150 s, h = 1e-4, 5e-5: {mm(pk[0])} {mm(pk[1])} mm; errors {mm(ed[0])} {mm(ed[1])} mm")
print("forcing f (Hz):   " + row(f"{f}" for f in fs))
print("steady amp (mm):  " + row(mm(amp(f, b)) for f in fs))
print(f"mistake, plain guess C cos(w0 t) at 1 Hz: coefficient w0^2 - w0^2 = {w0 * w0 - w0 * w0:.1f}, so 0 x C = F")
print(f"mistake, beat period read as 2/(f0 - f) = {2 / (1 - 0.9):.0f} s; loud peaks come every 1/(f0 - f) = {1 / (1 - 0.9):.0f} s")
print(f"mistake, damping ignored at 0.99 Hz: {mm(amp(0.99, 0))} mm, true {mm(amp(0.99, b))} mm")
assert eb[1] < 1e-4 and 1.8 < eb[0] / eb[1] < 2.2           # Euler meets the beat formula, order one
assert er[1] < 1e-3 and 1.8 < er[0] / er[1] < 2.2           # Euler meets t sin t, order one
assert abs(near - res(10.25)) < 1e-6                        # beats tend to resonance as w -> w0
assert ed[1] < 3e-3 and 1.8 < ed[0] / ed[1] < 2.2           # long run settles to F/(b w0)
print("ALL CHECKS PASS")
