# Torsion and yield -- the check behind the card.  Standard library only.
# A 40 mm solid steel shaft carries 1 kN m of torque and 100 MPa of bending
# stress.  Shear stress, twist, then the von Mises and Tresca yield checks.
from math import pi, sqrt, cos, sin, radians, degrees

d, T, G = 0.040, 1000.0, 79e9          # diameter m, torque N m, shear modulus Pa
sb, sy = 100e6, 275e6                   # bending stress Pa, yield stress Pa (S275)
r = d / 2
N = 20000                               # thin rings for the numerical roads
MPa = 1e-6

def rings(f):                           # sum f(radius) * ring area, midpoint rule
    dr = r / N
    return sum(f((k + 0.5) * dr) * 2 * pi * (k + 0.5) * dr * dr for k in range(N))
def ratio(a, b): return a / b if b else float("inf")   # as Rust's float division gives

# Road 1: closed forms.  Road 2: add up thin rings.
J = pi * d**4 / 32
J_rings = rings(lambda q: q * q)
tau = T * r / J
rate = T / (G * J)                      # twist per metre, rad/m
T_back = rings(lambda q: (tau * q / r) * q)       # turning effect of the stresses
U = rings(lambda q: (tau * q / r)**2 / (2 * G))  # stored energy per metre, J/m
rate_energy = 2 * U / T                 # work T*phi/2 equals stored energy
assert abs(J_rings - J) / J < 1e-8 and abs(T_back - T) < 1e-4
assert abs(rate_energy - rate) / rate < 1e-8
W = pi * d**3 / 32
print(f"J = pi d^4/32: {J:.4e} m^4; by {N} rings {J_rings:.4e} m^4")
print(f"surface shear stress T r / J: {tau*MPa:.2f} MPa")
print(f"torque carried by the ring stresses: {T_back:.2f} N m")
print(f"twist rate T/(G J): {rate:.4f} rad/m = {degrees(rate):.3f} deg/m")
print(f"twist rate from stored energy {U:.2f} J/m: {rate_energy:.4f} rad/m")
print(f"bending: W = pi d^3/32 = {W:.4e} m^3, moment for 100 MPa {sb*W:.1f} N m")
print(f"G from E = 200 GPa, nu = 0.30: {200e9/2.6/1e9:.2f} GPa; 79 GPa matches E = {G*2.6/1e9:.1f} GPa; twist at 76.92 GPa: {T/(200e9/2.6*J):.4f} rad/m")

# The surface point: sigma along the axis, tau round it, nothing else.
def vm(s, t): return sqrt(s * s + 3 * t * t)
def tr(s, t): return sqrt(s * s + 4 * t * t)
c, R = sb / 2, sqrt((sb / 2)**2 + tau**2)
s1, s2, s3 = c + R, 0.0, c - R          # 3D order, largest first
print(f"surface shear strain tau/G: {tau/G:.5f} rad; Mohr centre {c*MPa:.2f} MPa, radius {R*MPa:.2f} MPa")
print(f"principal stresses: {s1*MPa:.2f}, {s2*MPa:.2f}, {s3*MPa:.2f} MPa")
# Road 3: turn a cutting plane through 180 degrees in 0.001 degree steps.
smax = smin = shmax = 0.0
for k in range(180000):
    a = radians(k / 1000)
    sn = sb * cos(a)**2 + tau * sin(2 * a)
    sh = -sb * sin(a) * cos(a) + tau * cos(2 * a)
    smax, smin, shmax = max(smax, sn), min(smin, sn), max(shmax, abs(sh))
print(f"plane scan: largest {smax*MPa:.2f}, smallest {smin*MPa:.2f}, largest shear {shmax*MPa:.2f} MPa")
assert abs(smax - s1) < 1e3 and abs(smin - s3) < 1e3
vm_f, tr_f = vm(sb, tau), tr(sb, tau)
vm_p = sqrt(((s1 - s2)**2 + (s2 - s3)**2 + (s3 - s1)**2) / 2)
tr_p = max(s1, s2, s3) - min(s1, s2, s3)
# Road 4 for von Mises: distortion energy, from the stress tensor minus its mean.
S = [[sb, tau, 0.0], [tau, 0.0, 0.0], [0.0, 0.0, 0.0]]
m = sum(S[i][i] for i in range(3)) / 3
ud = sum((S[i][j] - (m if i == j else 0))**2 for i in range(3) for j in range(3)) / (4 * G)
ud_y = sy * sy / (6 * G)                # the same energy at yield in a tension test
vm_e = sy * sqrt(ud / ud_y)
assert abs(vm_p - vm_f) < 1e-3 and abs(vm_e - vm_f) < 1e-3
assert abs(tr_p - tr_f) < 1e-3 and abs(2 * shmax - tr_f) < 1e3
print(f"von Mises: formula {vm_f*MPa:.2f}, principals {vm_p*MPa:.2f}, energy {vm_e*MPa:.2f} MPa")
print(f"distortion energy {ud/1e3:.2f} kJ/m^3 against {ud_y/1e3:.2f} kJ/m^3 at yield")
print(f"Tresca: formula {tr_f*MPa:.2f}, principals {tr_p*MPa:.2f}, 2 x scan {2*shmax*MPa:.2f} MPa")
print(f"safety factors: von Mises {sy/vm_f:.2f}, Tresca {sy/tr_f:.2f}")

# Shear yield and the torque the shaft can take with the bending held.
ty_vm, ty_tr = sy / sqrt(3), sy / 2
print(f"pure twist yields at {ty_vm*MPa:.2f} MPa (von Mises), {ty_tr*MPa:.2f} MPa (Tresca)")
print(f"yield torque, no bending: {ty_vm*J/r:.1f} N m (von Mises), {ty_tr*J/r:.1f} N m (Tresca)")
def bisect(f, lo, hi):
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if f(mid) < 0 else (lo, mid)
    return (lo + hi) / 2
for name, f, k in (("von Mises", vm, 3), ("Tresca", tr, 4)):
    Tb = bisect(lambda x: f(sb, x * r / J) - sy, 0, 1e6)
    Tc = sqrt((sy * sy - sb * sb) / k) * J / r
    Tg = bisect(lambda x: f(sb * x / T, x * r / J) - sy, 0, 1e6)   # bending grows with the torque
    assert abs(Tb - Tc) < 1e-6 and abs(Tg - T * sy / f(sb, tau)) < 1e-6
    print(f"torque to yield, {name}: bending held at 100 MPa {Tc:.1f} N m (bisection {Tb:.1f}); bending growing with it {Tg:.1f} N m")
lo_hi = [tr(1.0, q / 100) / vm(1.0, q / 100) for q in range(0, 100001)]
assert 1.0 <= min(lo_hi) and max(lo_hi) <= 2 / sqrt(3) + 1e-12
print(f"Tresca/von Mises: here (k = tau/sigma = {ratio(tau, sb):.4f}) {tr_f/vm_f:.4f}; over tau/sigma 0 to 1000 from {min(lo_hi):.4f} to {max(lo_hi):.4f}, gap at most {100*(2/sqrt(3)-1):.1f}%")

# Outside the model: 2.5 kN m of pure twist.
T2 = 2500.0
t_el = T2 * r / J
def core_torque(re):                    # elastic core radius re, yielded ring outside
    return rings(lambda q: ty_vm * min(q / re, 1.0) * q)
Tp = 2 * pi * r**3 * ty_vm / 3
if t_el > ty_vm:                        # an elastic core exists only once the surface has yielded
    re_b = bisect(lambda x: T2 - core_torque(x), 1e-6, r)
    re_c = (4 * (r**3 - 3 * T2 / (2 * pi * ty_vm)))**(1 / 3)
    assert abs(re_b - re_c) < 2e-6
    print(f"2.5 kN m: formula says {t_el*MPa:.2f} MPa > {ty_vm*MPa:.2f}; elastic core {re_c*1e3:.2f} mm (bisection {re_b*1e3:.2f}); fully plastic at {Tp:.1f} N m")
else:
    print(f"2.5 kN m: {t_el*MPa:.2f} MPa, below {ty_vm*MPa:.2f}: still elastic; fully plastic at {Tp:.1f} N m")

# What breaks.
I_bend = pi * d**4 / 64
print(f"break: shear judged against 275 MPa: safety factor {sy/tau:.2f}")
print(f"break: checks one at a time: bending {ratio(sy, sb):.2f}, twist {ty_vm/tau:.2f}")
print(f"break: bending I = pi d^4/64 used for J: {T*r/I_bend*MPa:.2f} MPa, {T/(G*I_bend):.4f} rad/m")
print(f"break: d used for r: {T*d/J*MPa:.2f} MPa")

# Try changing.
Jh = pi * (0.040**4 - 0.030**4) / 32
print(f"try: tube 40/30 mm: J {Jh:.4e} m^4, shear {T*r/Jh*MPa:.1f} MPa, area down {100*0.75**2:.0f}%"
      f"; d 80 mm: {T*0.04/(pi*0.08**4/32)*MPa:.2f} MPa, {T/(G*pi*0.08**4/32):.4f} rad/m")
print(f"try: G 26 GPa: {T/(26e9*J):.4f} rad/m; no bending: safety factors {sy/vm(0, tau):.2f} and {sy/tr(0, tau):.2f}")

# Figure: the sigma-tau plane at 0.8 px per MPa, origin at (260, 200).
def px(s, t): return f"({260 + 0.8*s*MPa:.2f}, {200 - 0.8*t*MPa:.2f})"
nv, nt = sy / vm_f, sy / tr_f
print(f"figure, origin {px(0, 0)}, point {px(sb, tau)}, von Mises hit {px(nv*sb, nv*tau)}, Tresca hit {px(nt*sb, nt*tau)}")
print(f"figure, axis ends {px(-sy, 0)} {px(sy, 0)}, tau tops {px(0, ty_vm)} {px(0, ty_tr)}")
for lab, v in (("bending alone", sb), ("von Mises", vm_f), ("Tresca", tr_f), ("yield S275", sy)):
    print(f"bar {lab:<14}|{'#' * round(v * MPa / 10):<28}| {v*MPa:.1f} MPa")
print("ALL CHECKS PASS")
