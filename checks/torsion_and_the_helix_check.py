# Torsion and the helix -- the check behind the card.  Standard library only.
# A spiral staircase handrail: radius 0.8 m, rising 2.8 m per full turn.
# Torsion comes three ways: the closed form, finite differences of the binormal,
# and a polygon through the rail's posts.  A fourth road rebuilds the rail from
# curvature and torsion alone by RK4, and it must come out a helix of the same size.
from math import sin, cos, pi, sqrt, atan, atan2, degrees

def add(u, v): return [p + q for p, q in zip(u, v)]
def mul(k, u): return [k * p for p in u]
def sub(u, v): return add(u, mul(-1.0, v))
def dot(u, v): return u[0] * v[0] + u[1] * v[1] + u[2] * v[2]
def cross(u, v): return [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
def size(u): return sqrt(dot(u, u))
def unit(u): return mul(1.0 / size(u), u)

A, RISE = 0.8, 2.8                         # radius and rise per turn, metres
C = RISE / (2 * pi)                        # rise per radian of turning
def rail(t, a=A, c=C): return [a * cos(t), a * sin(t), c * t]

def closed_form(a, c):                     # road 1: kappa and tau of the helix
    return a / (a * a + c * c), c / (a * a + c * c)

def frame(t, k=1e-3):                      # T, N, B from finite differences in the angle t
    d1 = mul(0.5 / k, sub(rail(t + k), rail(t - k)))
    d2 = mul(1.0 / (k * k), add(sub(rail(t + k), mul(2.0, rail(t))), rail(t - k)))
    T, B = unit(d1), unit(cross(d1, d2))
    return T, cross(B, T), B, size(d1)

def tau_by_differences(t, k=1e-3):         # road 2: B' = -tau N, and d/ds = (1/speed) d/dt
    T, N, B, speed = frame(t)
    dB = mul(0.5 / k, sub(frame(t + k)[2], frame(t - k)[2]))
    return -dot(dB, N) / speed

def posts(n, a=A, c=C, flip=1.0):          # n posts per turn; flip=-1 is the mirror image
    return [[flip * a * cos(2 * pi * i / n), a * sin(2 * pi * i / n), c * 2 * pi * i / n] for i in range(4)]

def polygon(p):                            # road 3: turning and twisting angles between posts
    e = [sub(p[i + 1], p[i]) for i in range(3)]
    b1, b2 = unit(cross(e[0], e[1])), unit(cross(e[1], e[2]))
    bend = atan2(size(cross(e[0], e[1])), dot(e[0], e[1]))
    twist = atan2(dot(cross(b1, b2), unit(e[1])), dot(b1, b2))
    return bend / size(e[1]), twist / size(e[1]), degrees(twist)

def rebuild(kap, tau, length, steps):      # road 4: T'=kN, N'=-kT+tB, B'=-tN, from kappa, tau only
    def f(y): return [y[1], mul(kap, y[2]), add(mul(-kap, y[1]), mul(tau, y[3])), mul(-tau, y[2])]
    def go(y, k, h): return [add(y[j], mul(h, k[j])) for j in range(4)]
    y = [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
    h, path = length / steps, [y[0]]
    for _ in range(steps):
        k1 = f(y); k2 = f(go(y, k1, h / 2)); k3 = f(go(y, k2, h / 2)); k4 = f(go(y, k3, h))
        y = [add(y[j], mul(h / 6, add(add(k1[j], mul(2.0, k2[j])), add(mul(2.0, k3[j]), k4[j])))) for j in range(4)]
        path.append(y[0])
    m = kap * kap + tau * tau                         # the axis: along tau T + kappa B, through r + (kappa/m) N
    u, p0 = unit([tau, 0.0, kap]), [0.0, kap / m, 0.0]
    radii = [size(sub(sub(r, p0), mul(dot(sub(r, p0), u), u))) for r in path]
    return min(radii), max(radii), dot(path[-1], u)

kap, tau = closed_form(A, C)
m = kap * kap + tau * tau
speed = sqrt(A * A + C * C)
L = 2 * pi * speed                                    # rail length of one full turn
print(f"rise per radian c = 2.8 / (2 pi)       {C:.6f} m")
print(f"a^2 + c^2                              {A * A + C * C:.6f} m^2")
print(f"speed sqrt(a^2 + c^2), per radian      {speed:.6f} m")
print(f"rail length of one turn                {L:.6f} m")
print(f"pitch angle of the rail                {degrees(atan(C / A)):.4f} deg")
print(f"1 closed form: kappa                   {kap:.6f} 1/m")
print(f"1 closed form: tau                     {tau:.6f} 1/m")
print(f"  as degrees per metre: kappa, tau     {degrees(kap):.2f} {degrees(tau):.2f}")
taus = [tau_by_differences(t) for t in (0.0, 1.0, 2.0, 4.0)]
print("2 differences: tau at t = 0, 1, 2, 4   " + " ".join(f"{x:.6f}" for x in taus))
p14, p140 = polygon(posts(14)), polygon(posts(140))
print(f"3 posts, 14 per turn: kappa, tau       {p14[0]:.6f} {p14[1]:.6f}")
print(f"3 posts, 140 per turn: kappa, tau      {p140[0]:.6f} {p140[1]:.6f}")
print(f"  tau error at 14 and 140 posts        {abs(p14[1] - tau):.6f} {abs(p140[1] - tau):.6f}")
print(f"  twist between neighbouring planes    {p14[2]:.4f} deg at 14 posts")
print(f"kappa^2 + tau^2 = 1 / (a^2 + c^2)       {m:.6f} 1/m^2")
print(f"rebuilt helix from kappa, tau: a, c    {kap / m:.6f} {tau / m:.6f}")
r24, r48 = rebuild(kap, tau, L, 24), rebuild(kap, tau, L, 48)
for name, r in (("4 RK4, 24 steps", r24), ("4 RK4, 48 steps", r48)):
    print(f"{name}: radius min, max, rise   {r[0]:.6f} {r[1]:.6f} {r[2]:.6f}")
print(f"  radius error at 24 and 48 steps      {A - r24[0]:.9f} {A - r48[0]:.9f}")
print(f"reverse the direction of travel: tau   {polygon(posts(14)[::-1])[1]:.6f}")
print(f"mirror staircase (x -> -x): tau        {polygon(posts(14, flip=-1.0))[1]:.6f}")
flat = rebuild(kap, 0.0, L, 100)
print(f"wrong: tau per radian, not per metre   {C / speed:.6f}")
print(f"wrong: slope c / a read as the twist   {C / A:.6f}")
print(f"wrong: keep kappa, drop tau: radius    {flat[1]:.6f} m, rise {flat[2]:.6f} m")
line = [[0.0, 0.0, 0.3 * i] for i in range(3)]
print(f"wrong: straight landing |e1 x e2|      {size(cross(sub(line[1], line[0]), sub(line[2], line[1]))):.6f}")
for label, h in (("try: rise 4.0 m", 4.0), ("try: rise 5.026548 m (c = a)", 2 * pi * A), ("try: rise 10.0 m", 10.0)):
    print(f"{label:<38} kappa {closed_form(A, h / (2 * pi))[0]:.6f} tau {closed_form(A, h / (2 * pi))[1]:.6f}")
print(f"try: radius 1.2 m, rise 2.8 m          kappa {closed_form(1.2, C)[0]:.6f} tau {closed_form(1.2, C)[1]:.6f}")
dna = closed_form(1.0, 3.4 / (2 * pi))
print(f"DNA phosphates, 1.0 nm, 3.4 nm a turn  kappa {dna[0]:.6f} tau {dna[1]:.6f} 1/nm")
for name, t in (("far", pi / 2), ("near", 3 * pi / 2)):
    T, N, B, _ = frame(t)
    print(f"figure, {name} point at height {rail(t)[2]:.3f} m: T ({T[0]:.4f}, {T[2]:.4f}) B ({B[0]:.4f}, {B[2]:.4f})")
assert abs(kap - 0.953983) < 1e-6 and abs(tau - 0.531409) < 2e-6   # the hand-worked numbers
assert all(abs(x - tau) < 1e-6 for x in taus)                         # differences against the formula
assert abs(p140[1] - tau) < 1e-3 and abs(p140[1] - tau) < abs(p14[1] - tau)   # posts converge
assert abs(r48[0] - A) < 1e-5 and abs(r48[0] - A) < abs(r24[0] - A)   # kappa, tau alone give radius 0.8
assert abs(r48[1] - A) < 1e-5 and abs(r48[2] - RISE) < 1e-9          # ... and rise 2.8 m per turn
assert abs(polygon(posts(14, flip=-1.0))[1] + p14[1]) < 1e-12 and abs(flat[2]) < 1e-9
print("ALL CHECKS PASS")
