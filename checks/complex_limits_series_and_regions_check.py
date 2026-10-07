# Limits and regions in the plane -- the check behind the card.  Standard library only.
# The staircase seen from above: first step 1 m east, each next step 0.8 as long, turned 30 degrees.
# Road one: walk it, adding step after step.  Road two: the closed form 1/(1 - q), divided
# through the conjugate.  Road three: the real and imaginary parts as two real series.
import math

R, TH = 0.8, math.pi / 6
q = complex(R * math.cos(TH), R * math.sin(TH))    # the ratio: turn 30 degrees, shrink to 0.8

def walk(ratio, n_steps):                          # position after n_steps steps, and every stop
    pos, step, stops = 0j, 1 + 0j, [0j]
    for _ in range(n_steps):
        pos, step = pos + step, step * ratio
        stops.append(pos)
    return stops

def show(w):                                       # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

d = 1 - q
closed = complex(d.real, -d.imag) / (d.real ** 2 + d.imag ** 2)    # 1/d = conj(d)/|d|^2
stops = walk(q, 200)
re_sum = sum(R ** n * math.cos(n * TH) for n in range(200))       # road three: two real series
im_sum = sum(R ** n * math.sin(n * TH) for n in range(200))
print(f"ratio q = {show(q)}, |q| = {abs(q):.6f}, turn {TH:.6f} rad")
print(f"1 - q = {show(d)}, |1 - q|^2 = {d.real ** 2 + d.imag ** 2:.6f}, |1 - q| = {abs(d):.6f}")
gaps, bounds = [], []
for n in (5, 10, 20):
    gaps.append(abs(closed - stops[n]))
    bounds.append(R ** n / abs(d))
    print(f"after {n} steps: {show(stops[n])}, distance to limit {gaps[-1]:.6f}, |q|^N/|1 - q| = {bounds[-1]:.6f}")
print(f"after 200 steps:    {show(stops[200])}")
print(f"closed form 1/(1 - q): {show(closed)}, straight-line distance {abs(closed):.6f} m")
print(f"two real series: Re {re_sum:.6f}, Im {im_sum:.6f}")
lengths = sum(abs(stops[k + 1] - stops[k]) for k in range(200))
print(f"total length walked {lengths:.6f} m = 1/(1 - 0.8) = {1 / (1 - R):.6f}; farthest stop {max(abs(s) for s in stops):.6f} m")
print(f"q sits {1 - abs(q):.6f} inside the unit circle: the disc of that radius round q is inside too")
edge = walk(complex(math.cos(TH), math.sin(TH)), 48)
print(f"boundary, q = e^(i pi/6): after 12 steps {show(edge[12])}; |S| over 48 steps from "
      f"{min(abs(s) for s in edge[1:]):.6f} to {max(abs(s) for s in edge):.6f}, no limit")
far = walk(1.25 * complex(math.cos(TH), math.sin(TH)), 40)
fake = 1 / (1 - 1.25 * complex(math.cos(TH), math.sin(TH)))
print(f"outside, q = 1.25 e^(i pi/6): after 40 steps |S| = {abs(far[40]):.1f} m; 1/(1 - q) says {show(fake)}")
deg = 1 / (1 - complex(R * math.cos(30), R * math.sin(30)))
print(f"mistake, 30 read as radians: 1/(1 - 0.8 e^(30i)) = {show(deg)}")
print("figure, stops " + " ".join(f"({70 + 100 * s.real:.1f},{220 - 100 * s.imag:.1f})" for s in stops[:16]))
print(f"figure, limit ({70 + 100 * closed.real:.2f}, {220 - 100 * closed.imag:.2f}); ratio plane q ({180 + 80 * q.real:.2f}, "
      f"{120 - 80 * q.imag:.2f}), edge ({180 + 80 * math.cos(TH):.2f}, {120 - 80 * math.sin(TH):.2f}), "
      f"outside ({180 + 100 * math.cos(TH):.2f}, {120 - 100 * math.sin(TH):.2f})")
assert abs(stops[200] - closed) < 1e-12                                 # walking agrees with 1/(1 - q)
assert abs(re_sum - closed.real) < 1e-12 and abs(im_sum - closed.imag) < 1e-12   # two real limits
assert all(abs(g - b) < 1e-12 for g, b in zip(gaps, bounds)) and abs(lengths - 1 / (1 - R)) < 1e-9
assert abs(edge[12]) < 1e-12 and max(abs(s) for s in edge) > 3 and abs(far[40]) > 1000
print("ALL CHECKS PASS")
