# Units and dimensions -- the check behind the card.  Python standard library only.
# Road 1: exponent arithmetic.  Road 2: change the units and see whether the answer moves.
# Road 3: rebuild the pressure drop from a force balance on rings of water, step by step.
from math import pi

BASE = ("M", "L", "T", "I", "Θ", "N", "J")      # mass, length, time, current, temperature, amount, luminous intensity
def dim(M=0, L=0, T=0): return (M, L, T, 0, 0, 0, 0)    # this card needs only the first three
def mul(*ds): return tuple(sum(c) for c in zip(*ds))
def pw(d, p): return tuple(p * c for c in d)
def show(d):
    s = " ".join(b if c == 1 else f"{b}^{c}" for b, c in zip(BASE, d) if c != 0)
    return s or "1 (pure number)"

ONE, MASS, LEN, TIME = dim(), dim(M=1), dim(L=1), dim(T=1)
accel    = mul(LEN, pw(TIME, -2))
force    = mul(MASS, accel)                       # newton = kg m s^-2
pressure = mul(force, pw(LEN, -2))                # pascal = newton per square metre
visc     = mul(pressure, TIME)                    # Pa s
flow     = mul(pw(LEN, 3), pw(TIME, -1))          # m^3 per s
speed    = mul(LEN, pw(TIME, -1))
density  = mul(MASS, pw(LEN, -3))
for name, d in (("force N", force), ("pressure Pa", pressure), ("viscosity Pa s", visc),
                ("flow rate m^3/s", flow), ("density kg/m^3", density)):
    print(f"dims {name:<22}{show(d)}")

# the drip tube: water at 20 C (NIST WebBook), 2 mm bore, 1 m long, 1 mL/s
mu, rho, ell, Q, D, gn = 1.0016e-3, 998.21, 1.0, 1.0e-6, 2.0e-3, 9.80665
RE_LAM, BL_LO, BL_HI = 2300.0, 4000.0, 1.0e5      # laminar limit; Blasius range (White)
print(f"inputs mu {1000 * mu:.4f} mPa s, rho {rho:.2f} kg/m^3, l {ell:.1f} m, D {1000 * D:.1f} mm, Q {1e6 * Q:.1f} mL/s, g_n {gn:.5f} m/s^2")
print(f"limits laminar below Re {RE_LAM:.0f}; Blasius for Re {BL_LO:.0f} to {BL_HI:.0f}")
ins = {"mu": visc, "l": LEN, "Q": flow, "D": LEN}
FORMULAS = {   # name: (number, {input: power})
    "128 mu l Q / (pi D^4)": (128 / pi, {"mu": 1, "l": 1, "Q": 1, "D": -4}),
    "32 mu l Q / D^2":       (32.0,     {"mu": 1, "l": 1, "Q": 1, "D": -2}),
    "128 mu l Q / (pi D^3)": (128 / pi, {"mu": 1, "l": 1, "Q": 1, "D": -3}),
}
def evaluate(f, vals):
    c, pows = FORMULAS[f]
    out = c
    for k, p in pows.items(): out *= vals[k] ** p
    return out

# road 1's forecast of the drift: other unit systems (metres, kilograms, seconds per new unit)
SYSTEMS = {"cm g s": (0.01, 0.001, 1.0), "ft lb min": (0.3048, 0.45359237, 60.0)}
def in_units(d, sysf): return sysf[0] ** d[1] * sysf[1] ** d[0] * sysf[2] ** d[2]   # SI size of one new unit
# road 2: each input's own unit, its SI size written out by hand; no exponent list is used
LB, FT, MIN = 0.45359237, 0.3048, 60.0
HAND = {"cm g s":    {"mu": 0.1, "l": 0.01, "Q": 1.0e-6, "D": 0.01, "p": 0.1},   # poise, cm, cm^3/s, cm, barye
        "ft lb min": {"mu": LB / (FT * MIN), "l": FT, "Q": FT * FT * FT / MIN, "D": FT, "p": LB / (FT * MIN * MIN)}}
si_vals = {"mu": mu, "l": ell, "Q": Q, "D": D}
for s, (a, b, c) in SYSTEMS.items(): print(f"system {s:<10} one unit = {a:.4f} m, {b:.8f} kg, {c:.0f} s")
ratios, verdicts = {}, []
for f in FORMULAS:
    c, pows = FORMULAS[f]
    d = mul(*[pw(ins[k], p) for k, p in pows.items()])
    p_si = evaluate(f, si_vals)
    verdict = "PASS" if d == pressure else "REJECT"
    verdicts.append(verdict)
    print(f"check {f:<23}{show(d):<14}vs {show(pressure)}  {verdict}")
    print(f"  SI answer read as Pa       {p_si:14.6f}")
    for s, sysf in SYSTEMS.items():
        h = HAND[s]
        back = evaluate(f, {k: v / h[k] for k, v in si_vals.items()}) * h["p"]   # read as a pressure, convert to Pa
        diff = mul(d, pw(pressure, -1))
        predicted = 1.0 / in_units(diff, sysf)                            # road 1's forecast of the drift
        ratios[(f, s)] = (back / p_si, predicted)
        print(f"  in {s:<10} back in Pa {back:14.6f}  ratio {back / p_si:12.6f}  forecast {predicted:12.6f}")

dp = evaluate("128 mu l Q / (pi D^4)", si_vals)
area = pi * D * D / 4
v = Q / area
Re = rho * v * D / mu
print(f"bore area mm^2               {1e6 * area:14.6f}")
print(f"mean speed v = Q/area m/s    {v:14.6f}")
print(f"mu l Q / D^4 Pa              {mu * ell * Q / D ** 4:14.6f}  times 128/pi = {128 / pi:.6f}")
print(f"Reynolds rho v D / mu        {Re:14.4f}  dims {show(mul(density, speed, LEN, pw(visc, -1)))}")
print(f"32 mu l v / D^2 Pa           {32 * mu * ell * v / D ** 2:14.6f}")
print(f"head dp/(rho g) cm           {100 * dp / (rho * gn):14.4f}")
print(f"exit head 2 v^2/(2 g) cm     {100 * v * v / gn:14.4f}  entry length 0.06 Re D {100 * 0.06 * Re * D:.4f} cm")

# road 3: force balance on a cylinder of water of radius r gives shear tau = (dp/l) r / 2;
# du/dr = -tau/mu, stepped in from the wall (u = 0); flow = sum of 2 pi r u dr.  Linear in dp.
def flow_for(dp_try, n=20000):
    R, h = D / 2, D / 2 / n
    u = [0.0] * (n + 1)
    for i in range(n, 0, -1):                     # trapezoid step from r_i to r_(i-1)
        t1, t0 = dp_try / ell * (i * h) / 2, dp_try / ell * ((i - 1) * h) / 2
        u[i - 1] = u[i] + h * (t1 + t0) / 2 / mu
    g = [2 * pi * (i * h) * u[i] for i in range(n + 1)]
    return h / 3 * (g[0] + g[n] + 4 * sum(g[1:n:2]) + 2 * sum(g[2:n:2])), u
q1, u1 = flow_for(1.0)
dp_road3 = Q / q1
_, prof = flow_for(dp_road3)
print(f"dp closed form Pa            {dp:14.6f}")
print(f"dp force balance Pa          {dp_road3:14.6f}")
print("chart, r (mm)          " + " ".join(f"{x:6.2f}" for x in (-1, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1)))
print("chart, u (mm/s)        " + " ".join(f"{1000 * prof[abs(k) * 5000]:6.0f}" for k in (-4, -3, -2, -1, 0, 1, 2, 3, 4)))

# what breaks: a mixed-unit version, and the laminar formula outside its range
K = evaluate("128 mu l Q / (pi D^4)", {"mu": 1e-3, "l": 1.0, "Q": 1e-6, "D": 1e-3}) / 1000
mixed_ok = K * (1000 * mu) * ell * (1e6 * Q) / (1000 * D) ** 4   # fed its own units
mixed_bad = K * mu * ell * Q / D ** 4
print(f"mixed-unit constant K        {K:14.6f}  (kPa, with mPa s, m, mL/s, mm)")
print(f"mixed form, own units kPa   {mixed_ok:14.6f}")
print(f"mixed form, SI numbers kPa   {mixed_bad:14.6f}")
print(f"mixed form, SI over own      {mixed_bad / mixed_ok:14.6f}")
Q10 = 1.0e-5
v10 = Q10 / area
Re10 = rho * v10 * D / mu
lam10 = evaluate("128 mu l Q / (pi D^4)", {"mu": mu, "l": ell, "Q": Q10, "D": D})
f_bl = 0.316 / Re10 ** 0.25                       # Blasius, smooth tube, 4000 < Re < 1e5 (White)
turb10 = f_bl * (ell / D) * rho * v10 ** 2 / 2
print(f"at 10 mL/s: Re               {Re10:14.4f}")
print(f"at 10 mL/s: laminar Pa       {lam10:14.4f}")
print(f"at 10 mL/s: Blasius Pa       {turb10:14.4f}  friction factor {f_bl:.6f}")

assert verdicts == ["PASS", "REJECT", "REJECT"], "road 1: exponent check on the three quoted formulas"
assert all(abs(ratios[("128 mu l Q / (pi D^4)", s)][0] - 1) < 1e-12 for s in SYSTEMS), "road 2: right formula ignores units"
assert all(abs(r / p - 1) < 1e-9 for (f, s), (r, p) in ratios.items()), "road 2 drift equals road 1 forecast"
assert abs(dp_road3 / dp - 1) < 1e-9, "road 3: force balance lands on the closed form"
assert abs(mixed_ok * 1000 / dp_road3 - 1) < 1e-9, "mixed-unit form, fed its own units, meets the force balance"
assert Re < RE_LAM, "laminar at 1 mL/s"
assert BL_LO < Re10 < BL_HI, "turbulent, inside the Blasius range, at 10 mL/s"
assert turb10 > 3 * lam10, "outside its range the laminar formula is off by more than 3x"
print("ALL CHECKS PASS")
