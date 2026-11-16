# The transform rulebook -- the check behind the card.  Standard library only.
# Units: time t in ms, frequency xi in kHz, so xi*t is a pure number and every
# transform comes out in ms.  Every transform is computed here: road one uses
# the rules on the plain shutter's closed form; road two is the defining
# integral by Simpson's rule; road three, where it exists, is an exact
# antiderivative or another card's result.
import math

T, T0, S = 1.0, 3.0, 2.0  # plain exposure 1 ms; new pulse: delay 3 ms, stretch 2
def sinc(u): return 1.0 if u == 0 else math.sin(math.pi * u) / (math.pi * u)
def arrow(x): return complex(math.cos(x), math.sin(x))  # e^(ix), written out
def gate(t): return 1.0 if abs(t) <= T / 2 else 0.0  # plain shutter, centred on 0
def ghat(xi): return T * sinc(T * xi)  # its transform, from the L1-transform card
def h(t): return gate((t - T0) / S)  # the new pulse: open from 2 ms to 4 ms
def hhat(xi): return abs(S) * ghat(S * xi) * arrow(-2 * math.pi * xi * T0)  # rules
LO, HI = T0 - abs(S) * T / 2, T0 + abs(S) * T / 2  # where h is open

def simpson(f, a, b, n):  # n even
    w = (b - a) / n
    tot = f(a) + f(b)
    for k in range(1, n):
        tot += (4 if k % 2 else 2) * f(a + k * w)
    return tot * w / 3
def ft(f, xi, a, b, n=400):  # the defining integral, f zero outside [a, b]
    return simpson(lambda t: f(t) * arrow(-2 * math.pi * xi * t), a, b, n)
def box_exact(a, b, xi):  # integral of e^(-2 pi i xi t) from a to b, by hand
    return (arrow(-2 * math.pi * xi * a) - arrow(-2 * math.pi * xi * b)) / (2j * math.pi * xi)
def snap(x): return 0.0 if abs(x) < 5e-10 else x
def c(z):
    re, im = snap(z.real), snap(z.imag)
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"

print("plain shutter g: open 1 ms, centred on 0")
print(f"g-hat(250 Hz) = {ghat(0.25):.6f} ms, g-hat(0) = {ghat(0):.6f} ms")
print(f"new pulse h: opens {LO:.0f} ms, closes {HI:.0f} ms, centre {T0:.0f} ms")
print("xi Hz | by the rules | defining integral, Simpson n=400 | exact antiderivative")
for xi in (0.1, 0.25, 0.5):
    r, s, e = hhat(xi), ft(h, xi, LO, HI), box_exact(LO, HI, xi)
    print(f"{xi * 1000:.0f} | {c(r)} | {c(s)} | {c(e)}")
    assert abs(r - s) < 1e-9 and abs(r - e) < 1e-12
print(f"steps for 250 Hz: 2 x g-hat(500 Hz) = {2 * ghat(0.5):.6f} ms, turns {0.25 * T0:.2f}, turn = {c(arrow(-2 * math.pi * 0.25 * T0))}")
print("flicker swing kept | 1 ms shutter | 2 ms shutter")
for xi in (0.1, 0.25, 0.5):
    print(f"{xi * 1000:.0f} Hz | {abs(ghat(xi)) / ghat(0):.6f} | {snap(abs(hhat(xi)) / abs(hhat(0))):.6f}")
# time reversal: h(-t) has transform |-1| h-hat(-xi); forgetting |s| flips the sign
rev = ft(lambda t: h(-t), 0.25, -HI, -LO)
print(f"reversed h at 250 Hz: Simpson {c(rev)}, rule {c(hhat(-0.25))}, without |s| {c(-hhat(-0.25))}")
assert abs(rev - hhat(-0.25)) < 1e-9 and abs(rev + hhat(-0.25)) > 1
# modulation: the 1 ms gate times cos(2 pi 2 kHz t), a two-cycle burst
burst = lambda t: gate(t) * math.cos(2 * math.pi * 2.0 * t)
for xi in (2.0, 2.25):
    rule = (ghat(xi - 2.0) + ghat(xi + 2.0)) / 2
    s = ft(burst, xi, -0.5, 0.5, 2000)
    print(f"burst at {xi * 1000:.0f} Hz: rule {rule:.6f} ms, Simpson {c(s)} ms")
    assert abs(s - rule) < 1e-9
# duality: the tent L(t) = max(0, 1 - |t|) has transform sinc^2, so sinc^2 in time
# must have the tent as its transform: 0.75 at 250 Hz.  Cut-off L, tail <= 2/(pi^2 L).
tent = lambda t: max(0.0, 1 - abs(t))
for L in (500, 1000):
    d = 2 * simpson(lambda t: sinc(t) ** 2 * math.cos(2 * math.pi * 0.25 * t), 0.0, L, 100 * L)
    bound = 2 / (math.pi ** 2 * L)
    print(f"sinc^2 at 250 Hz, cut-off {L} ms: {d:.6f} ms, tent value {tent(0.25):.6f}, tail bound {bound:.6f}")
    assert abs(d - tent(0.25)) < bound
# derivative rule on the tent: L' is +1 on (-1, 0) and -1 on (0, 1): two shifted gates
dhat = ghat(0.25) * (arrow(math.pi * 0.25) - arrow(-math.pi * 0.25))  # shift rule only
tent_rule = dhat / (2j * math.pi * 0.25)
tent_simp = ft(tent, 0.25, -1.0, 0.0) + ft(tent, 0.25, 0.0, 1.0)
print(f"tent at 250 Hz: derivative rule {c(tent_rule)}, g-hat^2/T {ghat(0.25) ** 2 / T:.6f}, Simpson {c(tent_simp)}")
assert abs(tent_rule - ghat(0.25) ** 2 / T) < 1e-12 and abs(tent_simp - tent_rule) < 1e-9
# the rule fails on the gate itself: its slope is 0 wherever it exists; the jumps hold it all
slope = lambda t: (gate(t + 1e-4) - gate(t - 1e-4)) / 2e-4  # difference quotient, off the jumps
flat = sum(ft(slope, 0.25, a, b) for a, b in ((-1.0, -0.501), (-0.499, 0.499), (0.501, 1.0)))
spikes = arrow(math.pi * 0.25 * T) - arrow(-math.pi * 0.25 * T)  # +1 at -T/2, -1 at +T/2
print(f"gate, 250 Hz: transform of pointwise slope {c(flat)}, 2 pi i xi g-hat = {c(2j * math.pi * 0.25 * ghat(0.25))}, jump spikes {c(spikes)}")
assert abs(flat) < 1e-12 and abs(2j * math.pi * 0.25 * ghat(0.25) - spikes) < 1e-12
# frequency-side derivative: d/dxi h-hat = transform of -2 pi i t h(t)
dq = 1e-5
cd = (hhat(0.25 + dq) - hhat(0.25 - dq)) / (2 * dq)
sd = ft(lambda t: -2j * math.pi * t * h(t), 0.25, LO, HI)
c4 = lambda z: f"{z.real:.4f} {'-' if z.imag < 0 else '+'} {abs(z.imag):.4f}i"
print(f"slope of h-hat at 250 Hz: difference quotient {c4(cd)}, transform of -2 pi i t h {c4(sd)} ms^2")
assert abs(cd - sd) < 1e-6
ph = lambda xi: math.atan2(hhat(xi).imag, hhat(xi).real)
print(f"delay read from the phase slope: {-(ph(0.25 + dq) - ph(0.25 - dq)) / (2 * dq) / (2 * math.pi):.6f} ms")
# what breaks, all at 250 Hz; right answer 0 + 1.273240i ms
print("what breaks at 250 Hz, right answer", c(hhat(0.25)))
print("stretch on the wrong side, 2 g-hat(xi/2) |", c(2 * ghat(0.125) * arrow(-2 * math.pi * 0.25 * T0)))
print("drop the factor 2 |", c(ghat(0.5) * arrow(-2 * math.pi * 0.25 * T0)))
print("delay then stretch, centre at 6 ms |", c(hhat(0.25) * arrow(-2 * math.pi * 0.25 * T0)))
print("plus sign in the turn |", c(2 * ghat(0.5) * arrow(2 * math.pi * 0.25 * T0)))
print("chart, xi Hz           ", " ".join(f"{k * 100:6d}" for k in range(21)))
print("chart, 1 ms g-hat      ", " ".join(f"{snap(ghat(k / 10)):6.3f}" for k in range(21)))
print("chart, 2 ms 2g-hat(2xi)", " ".join(f"{snap(2 * ghat(k / 5)):6.3f}" for k in range(21)))
print("ALL CHECKS PASS")
