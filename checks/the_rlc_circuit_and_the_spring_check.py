# The RLC circuit and the spring -- the check behind the card.  Standard library
# only.  A 10 V battery is switched onto L = 1 H, R = 2 ohm, C = 0.2 F in series,
# capacitor empty, no current.  Road one: the closed form from the roots of
# L r^2 + R r + 1/C = 0.  Road two: Euler steps on Kirchhoff's loop rule itself,
# q' = i and L i' = V - R i - q/C, which never solves anything.  Road three: the
# heat R i^2 summed step by step, against the energy the battery leaves unstored.
import math

L, R, C, V = 1.0, 2.0, 0.2, 10.0
a, b = -R / (2 * L), math.sqrt(1 / (L * C) - (R / (2 * L)) ** 2)   # roots a +/- bi
A, B = -C * V, -C * V * (-a) / b          # q(0) = 0 and i(0) = 0 fix the constants
def q(t): return C * V + math.exp(a * t) * (A * math.cos(b * t) + B * math.sin(b * t))
def house(t): return math.exp(-t) * (math.cos(2 * t) + 0.5 * math.sin(2 * t))

def euler(res, h, T, qq=0.0, i=0.0):       # plain small steps along the slope
    top, t_top, imax, t_imax, heat, marks = -1.0, 0.0, -1.0, 0.0, 0.0, []
    for n in range(round(T / h) + 1):
        t = n * h
        if n % round(0.5 / h) == 0: marks.append(qq)
        if qq > top: top, t_top = qq, t
        if i > imax: imax, t_imax = i, t
        heat += res * i * i * h
        qq, i = qq + h * i, i + h * (V - res * i - qq / C) / L
    return qq, top, t_top, imax, t_imax, heat, marks

rc = 2 * math.sqrt(L / C)                  # critical resistance
errs = [abs(euler(R, h, 5)[0] - q(5)) for h in (0.001, 0.0005, 0.00025)]
_, top, t_top, imax, t_imax, heat, marks = euler(R, 1e-4, 20)
crit, over = euler(rc, 1e-4, 20), euler(6.0, 1e-4, 20)
tp, ti = math.pi / b, math.atan2(b, -a) / b          # where i = 0, where i' = 0
i_at = lambda t: (a * a + b * b) * C * V / b * math.exp(a * t) * math.sin(b * t)
gap = max(abs(q(t / 10) - C * V * (1 - house(t / 10))) for t in range(51))
row = lambda xs: ", ".join(f"{x:.2f}" for x in xs[:11])
print(f"roots: {a:.4f} +/- {b:.4f}i; natural rate 1/sqrt(LC) = {1 / math.sqrt(L * C):.4f} rad/s; damping ratio {R / 2 * math.sqrt(C / L):.4f}")
print(f"constants from q(0) = 0, i(0) = 0: A = {A:.4f}, B = {B:.4f}; final charge CV = {C * V:.4f} C")
print("t (s)          " + ", ".join(f"{t / 2:.1f}" for t in range(11)))
print("R = 2 ohm      " + row([q(t / 2) for t in range(11)]))
print(f"R = {rc:.2f} ohm   " + row(crit[6]))
print("R = 6 ohm      " + row(over[6]))
print(f"closed form equals CV(1 - house y) every 0.1 s to 5 s, within 1e-12: {'yes' if gap < 1e-12 else 'no'}")
print(f"peak, closed form: {q(tp):.4f} C at {tp:.4f} s; capacitor voltage {q(tp) / C:.4f} V")
print(f"peak, Euler h = 0.0001: {top:.4f} C at {t_top:.4f} s")
print(f"largest current: closed {i_at(ti):.4f} A at {ti:.4f} s; Euler {imax:.4f} A at {t_imax:.4f} s")
print("Euler error in q at t = 5, h = 0.001, 0.0005, 0.00025: " + " ".join(f"{e:.6f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"energy: battery V CV = {V * C * V:.4f} J; stored (CV)^2/2C = {(C * V) ** 2 / (2 * C):.4f} J; heat summed by Euler {heat:.4f} J")
print(f"overshoot fraction e^(pi a/b) = {math.exp(math.pi * a / b):.4f}; critical R = 2 sqrt(L/C) = {rc:.4f} ohm")
print(f"highest charge at R = {rc:.4f} and 6 ohm: {crit[1]:.4f}, {over[1]:.4f} C")
print(f"mistake, q times C for q/C: steady charge V/C = {V / C:.2f} C, not {C * V:.2f}")
print(f"mistake, inductor dropped: q = CV(1 - e^(-t/RC)) at {tp:.2f} s is {C * V * (1 - math.exp(-tp / (R * C))):.2f} C, never above {C * V:.2f}")
print(f"mistake, all battery energy stored: {V * C * V:.2f} J claimed, {(C * V) ** 2 / (2 * C):.2f} J in the capacitor")
assert 1.9 < errs[0] / errs[1] < 2.1 and 1.9 < errs[1] / errs[2] < 2.1 and errs[2] < 0.01   # Euler meets the closed form
assert abs(top - q(tp)) < 1e-3 and abs(t_top - tp) < 1e-3 and abs(imax - i_at(ti)) < 1e-3 # peaks agree
assert gap < 1e-12                                          # the circuit is the shock absorber, scaled
assert abs(heat / (V * C * V - (C * V) ** 2 / (2 * C)) - 1) < 1e-3 and crit[1] < C * V + 1e-9
print("ALL CHECKS PASS")
