# Partial derivatives -- the check behind the card.  Nothing is imported.
# A house loses heat through walls and windows: Q(t, g) = DT ((A - g) / R(t) + U g)
# watts, where t is cm of insulation, g is square metres of glass (glass replaces
# wall), and R(t) = 0.5 + t / 4 is the wall's resistance.  Each rate is reached by
# two roads: raw difference quotients over shrinking steps, and the hand formula.
A, DT, U, T0, G0 = 120.0, 20.0, 2.5, 6.0, 20.0

def R(t): return 0.5 + t / 4                          # wall resistance, m2 K per W
def Q(t, g): return DT * ((A - g) / R(t) + U * g)     # heat loss, watts
def qt(t, g, h): return (Q(t + h, g) - Q(t, g)) / h   # freeze glass, step insulation
def qg(t, g, k): return (Q(t, g + k) - Q(t, g)) / k   # freeze insulation, step glass
def Qt(t, g): return -DT * (A - g) / (4 * R(t) ** 2)  # hand formula, W per cm
def Qg(t, g): return DT * (U - 1 / R(t))              # hand formula, W per m2
def box(t, g, h, k): return (Q(t + h, g + k) - Q(t + h, g) - Q(t, g + k) + Q(t, g)) / (h * k)
def G(x, y): return 0.0 if x == y == 0 else x * y * (x * x - y * y) / (x * x + y * y)

print(f"model: {A:.0f} m2 of wall in all, {DT:.0f} C warmer inside, glass {U} W per m2 per C, "
      f"wall resistance {R(0)} + {R(1) - R(0)} per cm (0.01 m / 0.04)")
print(f"heat loss at t = 6 cm, g = 20 m2: {Q(T0, G0):.2f} W (wall resistance {R(T0):.2f}, "
      f"walls {DT * (A - G0) / R(T0):.2f}, glass {DT * U * G0:.2f})")
for h in [1, 0.1, 0.01, 0.001]:
    q = qt(T0, G0, h)
    print(f"insulation step {h} cm: quotient {q:.4f} W per cm, algebra {-1000 / (8 + h):.4f}, off by {abs(q - Qt(T0, G0)):.4f}")
    assert abs(q - (-1000 / (8 + h))) < 1e-8              # raw road == hand algebra
print(f"glass steps 1, 0.1, 0.01 m2: quotients {', '.join(f'{qg(T0, G0, k):.4f}' for k in [1, 0.1, 0.01])}; "
      f"formula {Qg(T0, G0):.4f} W per m2")
assert abs(qg(T0, G0, 0.01) - Qg(T0, G0)) < 1e-8 and abs(qt(T0, G0, 1e-6) - Qt(T0, G0)) < 1e-3
lo, hi = 0.0, 1.0                                         # halve to the widest step within 0.1
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if abs(qt(T0, G0, mid) - Qt(T0, G0)) <= 0.1 else (lo, mid)
print(f"to land within 0.1 W per cm of -125: widest step by halving {lo:.6f} cm; algebra 0.8/124.9 = {0.8 / 124.9:.6f}")
for s in [1, 0.1, 0.001]:
    print(f"mixed, four corners {s} cm by {s} m2: {box(T0, G0, s, s):.6f} W per cm per m2")
tg = (Qt(T0, G0 + 1e-6) - Qt(T0, G0)) / 1e-6              # insulation rate, stepped in glass
gt = (Qg(T0 + 1e-6, G0) - Qg(T0, G0)) / 1e-6              # glass rate, stepped in insulation
print(f"mixed, insulation then glass {tg:.4f}; glass then insulation {gt:.4f}; hand {DT / (4 * R(T0) ** 2):.4f}")
assert abs(tg - 1.25) < 1e-4 and abs(gt - 1.25) < 1e-4 and abs(box(T0, G0, 1e-3, 1e-3) - 1.25) < 1e-3
print(f"one more cm: exact change {Q(7, G0) - Q(T0, G0):.2f} W, the rate predicts {Qt(T0, G0):.2f} W")
print(f"second case, t = 14 cm: insulation {Qt(14, G0):.4f} (step 0.001: {qt(14, G0, 0.001):.4f}) W per cm; glass {Qg(14, G0):.4f} W per m2")
e, n = 1e-7, 1e-3                                         # inner step far below outer step
xy = ((G(e, n) - G(0, n)) / e - (G(e, 0) - G(0, 0)) / e) / n    # x first, then y
yx = ((G(n, e) - G(n, 0)) / e - (G(0, e) - G(0, 0)) / e) / n    # y first, then x
print(f"counterexample G at the origin: x then y {xy:.6f}, y then x {yx:.6f}")
assert abs(xy + 1) < 1e-4 and abs(yx - 1) < 1e-4              # hand limits: -1 and +1
Qw = lambda t, g: DT * (A / R(t) + U * g)                 # mistake: glass added on top of 120 m2 of wall
print(f"mistake, walls kept at 120 m2: glass rate {(Qw(T0, G0 + 1) - Qw(T0, G0)):.2f} W per m2, mixed "
      f"{(Qw(T0 + 1, G0 + 1) - Qw(T0 + 1, G0) - Qw(T0, G0 + 1) + Qw(T0, G0)):.2f}")
for g in [20, 40]:
    print(f"chart, g = {g}: " + " ".join(f"{Q(t, g):.2f}" for t in range(0, 17, 2)) + f"; slope at 6 cm {Qt(T0, g):.2f}")
print("ALL CHECKS PASS")
