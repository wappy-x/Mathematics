# Gyroscopes and precession -- the check behind the card.  Standard library only.
# A bicycle wheel hangs from a string tied to its axle and spins once a second.
# Roads to the precession rate: the formula tau/L; a full rigid-body simulation (RK4);
# the axle turned by many small sideways kicks.  Then a release from rest, where the
# formula holds only on average and only once the spin is fast.
from math import pi, atan2, asin, degrees, sqrt, cos, sin

G = 9.80665                      # standard gravity, m/s^2 (NIST CODATA g_n, exact)
M, R, D = 2.0, 0.30, 0.10        # wheel mass kg, rim radius m, string-to-hub distance m
I3 = M * R * R                   # spin inertia, all mass at the rim (a hoop), kg m^2
I1 = M * R * R / 2 + M * D * D   # inertia about a diameter, moved out to the string, kg m^2
W = 2 * pi * 1.0                 # once a second, in rad/s

def add(a, b, k=1.0): return [x + k * y for x, y in zip(a, b)]
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]]

def rates(s):                    # s = axle direction a (3), then angular momentum H about the string (3)
    a, H = s[:3], s[3:]
    along = dot(H, a)            # spin part of H; the rest turns the axle, with inertia I1
    w = add([along / I3 * x for x in a], [(h - along * x) / I1 for h, x in zip(H, a)])
    return cross(w, a) + cross([D * x for x in a], [0.0, 0.0, -M * G])   # da/dt, then dH/dt = torque

def run(H0, t_end, dt=1e-4):     # RK4 from a level axle pointing east; a sample every 0.04 s, lowest axle
    s, path, low = [1.0, 0.0, 0.0] + H0, [], 0.0
    for n in range(round(t_end / dt) + 1):
        if n % 400 == 0: path.append(s)
        low = min(low, s[2])
        k1 = rates(s); k2 = rates(add(s, k1, dt/2)); k3 = rates(add(s, k2, dt/2)); k4 = rates(add(s, k3, dt))
        s = [x + dt / 6 * (p + 2*q + 2*u + v) for x, p, q, u, v in zip(s, k1, k2, k3, k4)]
    return path, -degrees(asin(low))

def energy(s):
    along = dot(s[3:], s[:3])
    return along**2 / (2 * I3) + (dot(s[3:], s[3:]) - along**2) / (2 * I1) + M * G * D * s[2]

def tilt(s): return degrees(asin(s[2]))                      # axle angle above level, degrees
def turned(path):                                            # angle swept round the string, unwrapped, rad
    tot, prev = 0.0, 0.0
    for s in path:
        ang = atan2(s[1], s[0]); d = ang - prev
        tot += d - 2 * pi * round(d / (2 * pi)); prev = ang
    return tot

L, tau = I3 * W, M * G * D
om = tau / L                                                 # road 1
steady, _ = run([L, 0.0, I1 * om], 2.0)                      # launched already turning at om
om_sim = turned(steady) / 2.0                                # road 2
Lv, n = [L, 0.0, 0.0], 10000                                 # road 3: kicks of tau*dt, side-on to L
for _ in range(n):
    Lv = add(Lv, cross([0.0, 0.0, 1.0], [x / sqrt(dot(Lv, Lv)) for x in Lv]), tau * 0.5 / n)
om_kick = atan2(Lv[1], Lv[0]) / 0.5                          # angle turned in 0.5 s, per second
print(f"wheel {M:.1f} kg, rim radius {R:.2f} m, string to hub {D:.2f} m, g {G} m/s^2")
print(f"weight m g                       {M*G:9.4f} N")
print(f"spin inertia I3 = m R^2          {I3:9.4f} kg m^2")
print(f"tilt inertia I1, about the string{I1:9.4f} kg m^2")
print(f"spin, once a second              {W:9.4f} rad/s")
print(f"angular momentum L = I3 w        {L:9.4f} kg m^2/s")
print(f"gravity torque tau = m g d       {tau:9.4f} N m")
print(f"road 1  formula tau / L          {om:9.4f} rad/s")
print(f"road 2  rigid-body simulation    {om_sim:9.4f} rad/s")
print(f"road 3  10000 kicks in 0.5 s     {om_kick:9.4f} rad/s")
print(f"precession period 2 pi / Omega   {2*pi/om:9.4f} s")
print(f"hub speed round the string       {om*D:9.4f} m/s")
print(f"string lean, m d Omega^2 vs m g  {degrees(atan2(om*om*D, G)):9.4f} degrees")
level = max(abs(tilt(s)) for s in steady) < 1e-6
print(f"axle level to 1e-6 deg for 2 s   {'yes' if level else 'no':>9}")

# ---- the stubborn wheel: hands 0.30 m apart turn the axle a quarter turn in 0.5 s ----
Wt, h = (pi / 2) / 0.5, 1e-6
def Lvec(t):                     # spin part along the turning axle, plus the slow turn about a diameter
    return [I3 * W * cos(Wt * t), I3 * W * sin(Wt * t), M * R * R / 2 * Wt]
need = [(p - q) / (2 * h) for p, q in zip(Lvec(h), Lvec(-h))]
print(f"turn rate, quarter turn in 0.5 s {Wt:9.4f} rad/s")
print(f"torque needed, L times turn rate {L*Wt:9.4f} N m")
print(f"  same, by differencing L(t)     {sqrt(dot(need, need)):9.4f} N m")
print(f"  force at each hand, 0.30 m     {L*Wt/0.30:9.4f} N")
print(f"  the same at 5 rev/s            {5*L*Wt/0.30:9.4f} N")

# ---- release from rest, axle level: the formula only on average, only at fast spin ----
print("time s      " + " ".join(f"{0.04*k:5.2f}" for k in range(31)))
out = {}
for rps in (1, 4):
    Ls = I3 * 2 * pi * rps
    out[rps] = run([Ls, 0.0, 0.0], 3.0) + (Ls,)
    print(f"tilt {rps} rev/s  " + " ".join(f"{tilt(s):5.1f}" for s in out[rps][0][:31]))
for rps, (p, dip, Ls) in out.items():
    print(f"{rps} rev/s: deepest dip {dip:6.2f} deg, estimate 2 tau I1/L^2"
          f" {degrees(2*tau*I1/Ls**2):6.2f} deg; mean turn {turned(p)/3.0:.4f} rad/s vs tau/L {tau/Ls:.4f},"
          f" {100*(turned(p)/3.0*Ls/tau-1):+.1f}%")
drift = max(abs(energy(s) - energy(out[1][0][0])) for s in out[1][0])

# ---- what breaks ----
print(f"wrong: spin 1 rev/s as w = 1     {tau / (I3 * 1.0):9.4f} rad/s")
print(f"wrong: disc inertia m R^2 / 2    {tau / (I3 / 2 * W):9.4f} rad/s")
print(f"wrong: rim radius as lever arm   {M*G*R / L:9.4f} rad/s")
print(f"wrong: period as 1 / Omega       {1/om:9.4f} s")
x, top = 110 + 400 * D, 470 + 400 * D
print(f"figure, 400 units per m: side pivot (110,150) hub ({x:.0f},150) rim ({x:.0f},{150-400*R:.0f})"
      f" to ({x:.0f},{150+400*R:.0f}); top pivot (470,150) hub ({top:.0f},150) path radius {400*D:.0f}")

p1, dip1, L1 = out[1]
p4, dip4, L4 = out[4]
assert abs(om_sim - om) < 1e-6 * om and level                # simulation against the formula
assert abs(om_kick - om) < 1e-3 * om                         # kicks against the formula
assert abs(sqrt(dot(need, need)) - L * Wt) < 1e-6            # torque by differencing against L times rate
assert abs(turned(p4) / 3.0 - tau / L4) < 0.02 * tau / L4    # fast spin: the formula holds on average
assert abs(dip4 - degrees(2*tau*I1/L4**2)) < 0.05 * degrees(2*tau*I1/L4**2)
assert abs(turned(p1) / 3.0 - tau / L1) > 0.05 * tau / L1    # slow spin: off by more than 5%
assert drift < 1e-9                                          # energy kept by the simulation
print("ALL CHECKS PASS")
