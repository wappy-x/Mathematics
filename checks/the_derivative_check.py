# The derivative -- the check behind the card.  Nothing is imported.
# The car's odometer reads s(t) = 2 t^2 metres at t seconds.  The speed at
# a = 5 s is reached by two roads: raw average speeds over shrinking windows,
# and the hand algebra 4a + 2h.  Whole-second odometer readings give a third.
A, TOL = 5.0, 0.001

def s(t): return 2 * t * t                      # the odometer, metres
def corner(t): return s(t) if t <= A else s(A)  # stops dead against a barrier at 5 s
def jump(t): return s(t) - (s(A) if t >= A else 0)  # trip meter reset to 0 at 5 s
def avg(f, a, h): return (f(a + h) - f(a)) / h  # average speed over the window

print(f"odometer at a = {A:.0f} s: {s(A):.3f} m")
windows = [1, 0.1, 0.01, 0.001, 0.0001, -0.0001, -1]
for h in windows:
    q = avg(s, A, h)
    print(f"window {h:+.4f} s: average {q:.6f} m/s, off by {abs(q - 4 * A):.6f}")
    assert abs(q - (4 * A + 2 * h)) < 1e-7          # raw road == algebra road
readings = [s(t) for t in range(7)]
per_second = [readings[k + 1] - readings[k] for k in range(6)]
odo = (per_second[4] + per_second[5]) / 2
print(f"odometer, seconds 0 to 6: {[int(r) for r in readings]} m")
print(f"metres in each second: {[int(p) for p in per_second]}; mean of the two around 5 s: {odo:.3f} m/s")
assert abs(odo - avg(s, A, 1e-6)) < 1e-5            # whole seconds == shrinking window
lo, hi = 0.0, 1.0                                    # halve to the widest window within TOL
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if abs(avg(s, A, mid) - 4 * A) <= TOL else (lo, mid)
print(f"to land within {TOL} m/s of 20: widest window by halving {lo:.6f} s; algebra {TOL / 2:.6f} s")
assert abs(lo - TOL / 2) < 1e-9
for h in [0.1, 0.01, 0.001]:
    print(f"continuity, window {h}: gap {s(A + h) - s(A):.6f} m = {h} x {avg(s, A, h):.6f}")
left, right = avg(corner, A, -0.001), avg(corner, A, 0.001)
print(f"corner: left average {left:.6f}, right {right:.6f} m/s; gaps "
      f"{abs(corner(A - 0.001) - corner(A)):.6f} and {abs(corner(A + 0.001) - corner(A)):.6f} m")
assert left - right > 19                             # two one-sided rates: no derivative
print(f"jump: left average {avg(jump, A, -0.001):.4f} at -0.001 s, {avg(jump, A, -0.0001):.4f} at -0.0001 s")
print(f"second case, a = 2 s: window 0.0001 gives {avg(s, 2, 0.0001):.6f}; algebra 4a = {4 * 2} m/s")
print(f"mistakes: whole trip {s(A) / A:.3f} m/s; one-second window {avg(s, A, 1):.3f} m/s; answer 20 m/s = {20 * 3.6:.0f} km/h")
X = lambda t: 40 + 140 * (t - 4)                     # figure: 1 s = 140 units
Y = lambda m: 220 - 4 * (m - 30)                     # 1 m = 4 units, y points down
pts = [(4, s(4)), (5.1, s(4) + 16 * 1.1), (6.2, s(6.2)), (5, 50), (6, 72),
       (4.2, 50 - 20 * 0.8), (6.2, 50 + 20 * 1.2), (4.4, 50 - 22 * 0.6), (6.2, 50 + 22 * 1.2)]
print("figure, " + " ".join(f"({X(t):.1f},{Y(m):.2f})" for t, m in pts))
print("ALL CHECKS PASS")
