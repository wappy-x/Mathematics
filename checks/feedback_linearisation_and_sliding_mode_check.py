# Feedback linearisation and sliding mode on the cart pendulum -- the check behind the card.
# Standard library only.  Pole: g/l = 16 per s^2; cart moved by a force F; true cart mass M unknown.
import math

G, L, MH = 9.81, 0.613125, 2.0          # gravity m/s^2, pole length m, assumed cart mass kg
LAM, ETA, PHI = 2.0, 2.0, 0.1           # surface slope 1/s, reaching rate rad/s^2, boundary layer rad/s
TH0, DT = 0.5, 0.001                    # start lean rad; RK4 step and control period s
W2 = G / L                              # 16 per s^2

def lean_acc(th, om, F, M):             # true pole: theta'' = 16 sin(theta) - cos(theta) F / (M l)
    return W2 * math.sin(th) - math.cos(th) * F / (M * L)

def gain(th, om, eta):                  # switching gain sized to +-20 %: K = 0.2|16 sin + 2 om| + 1.2 eta
    return 0.2 * abs(W2 * math.sin(th) + LAM * om) + 1.2 * eta

def law(kind, th, om, k, eta, phi):
    pre = MH * L / math.cos(th)
    if kind == "fl":                    # cancel 16 sin(theta), then impose theta'' = -k theta - k omega
        return pre * (W2 * math.sin(th) + k * th + k * om)
    s = om + LAM * th
    sw = (1.0 if s > 0 else -1.0) if kind == "smc" else max(-1.0, min(1.0, s / phi))
    kk = gain(th, om, eta) if k is None else k
    return pre * (W2 * math.sin(th) + LAM * om + kk * sw)

def run(kind, M, k=None, tend=4.0, eta=ETA, phi=PHI, th0=TH0):   # RK4; force held over each 1 ms step
    th, om, v, out = th0, 0.0, 0.0, []
    for n in range(int(round(tend / DT))):
        F = law(kind, th, om, k, eta, phi)
        out.append((n * DT, th, om, F, v))
        f = lambda a, b: (b, lean_acc(a, b, F, M))
        k1 = f(th, om); k2 = f(th + DT/2*k1[0], om + DT/2*k1[1])
        k3 = f(th + DT/2*k2[0], om + DT/2*k2[1]); k4 = f(th + DT*k3[0], om + DT*k3[1])
        th += DT/6*(k1[0] + 2*k2[0] + 2*k3[0] + k4[0]); om += DT/6*(k1[1] + 2*k2[1] + 2*k3[1] + k4[1])
        v += F / M * DT
    out.append((tend, th, om, law(kind, th, om, k, eta, phi), v))
    return out

def settle(tr):                         # last time |theta| was above 0.01 rad
    return max([t for (t, th, *_ ) in tr if abs(th) > 0.01], default=0.0)

def reach(tr, band=0.0):                # first index where |s| <= band (band 0: s changes sign)
    return next(i for i, (t, th, om, *_ ) in enumerate(tr) if (om + LAM * th <= 0 if band == 0 else abs(om + LAM * th) <= band))

def svals(tr): return [abs(o + LAM * th) for (t, th, o, *_ ) in tr]
def jumps(tr): return sum(1 for a, b in zip(tr, tr[1:]) if abs(a[3] - b[3]) > 1.0)

print(f"pole: g/l = {W2:.4f} per s^2; assumed cart mass {MH} kg, true 1.6 to 2.4 kg (+-20 %)")
s0, G0 = LAM * TH0, W2 * math.sin(TH0); K0 = gain(TH0, 0.0, ETA); pre0 = MH * L / math.cos(TH0)
print(f"hand: s0 = 0 + 2 x 0.5 = {s0:.4f} rad/s; 16 sin 0.5 = {G0:.4f}; K0 = 0.2 x {G0:.4f} + 2.4 = {K0:.4f} rad/s^2")
print(f"hand: Mhat l / cos 0.5 = {pre0:.4f} kg m; F0 linearising {pre0*(G0+4*TH0):.4f} N, sliding {pre0*(G0+K0):.4f} N")
r = MH / 2.4
print(f"hand: heavy cart r = 2/2.4 = {r:.4f}; s'(0) = {1-r:.4f} x {G0:.4f} - {r:.4f} x {K0:.4f} = {(1-r)*G0 - r*K0:.4f} rad/s^2")
print(f"reaching-time bound |s0|/eta = {s0/ETA:.4f} s")
print(f"start lean {TH0} rad = {math.degrees(TH0):.2f} deg; linearising loses upright when r < 16/(16+4) = {W2/(W2+4):.4f}, "
      f"M > {MH*(W2+4)/W2:.4f} kg; layer lean bound Phi/lambda = {PHI/LAM:.4f} rad")

# Road A for the gain: bisection on the true plant over a grid of states and masses, against the formula.
worst = 0.0
for i in range(-12, 13):
    for j in range(-10, 11):
        th, om, need = 0.1 * i, 0.5 * j, 0.0
        for M in [1.6 + 0.04 * q for q in range(21)]:
            for sg in (1.0, -1.0):
                lo, hi = 0.0, 50.0
                for _ in range(60):
                    kk = (lo + hi) / 2
                    sdot = lean_acc(th, om, MH * L / math.cos(th) * (W2 * math.sin(th) + LAM * om + kk * sg), M) + LAM * om
                    lo, hi = (kk, hi) if sg * sdot > -ETA else (lo, kk)
                need = max(need, hi)
        worst = max(worst, abs(need - gain(th, om, ETA)))
print(f"gain road: bisection on the plant, 525 states x 21 masses, largest gap to formula {worst:.2e} rad/s^2")
assert worst < 1e-6

print("linearising law (k = 4), lean after 1 s and settle time to 0.01 rad:")
exact = run("fl", 2.0, 4.0); th1 = exact[1000][1]; pred = TH0 * (1 + 2 * 1.0) * math.exp(-2.0)
tc = next(t for t in (k * 1e-4 for k in range(100000)) if TH0 * (1 + 2 * t) * math.exp(-2 * t) < 0.01)   # continuous design
print(f"  M 2.0 kg: theta(1 s) {th1:.4f} rad, target 0.5 x 3 x e^-2 = {pred:.4f}; settles {settle(exact):.3f} s (continuous design {tc:.3f} s)")
assert abs(th1 - pred) < 2e-3 and abs(settle(exact) - tc) < 0.02
for M in (1.6, 2.4, 2.6):
    rr = MH / M; b, c = 4 * rr, 4 * rr - W2 * (1 - rr); disc = b * b - 4 * c
    roots = f"{(-b - math.sqrt(disc))/2:.4f}, {(-b + math.sqrt(disc))/2:.4f}" if disc >= 0 else \
            f"{-b/2:.4f} +- {math.sqrt(-disc)/2:.4f}j"
    tr = run("fl", M, 4.0, tend=30.0)
    fate = f"never returns: leans {tr[-1][1]:.4f} rad at 30 s" if abs(tr[-1][1]) > 0.01 else f"settles {settle(tr):.3f} s"
    print(f"  M {M} kg: r {rr:.4f}, linear roots {roots} 1/s; {fate}")
    if disc >= 0 and (-b + math.sqrt(disc)) / 2 > 0: assert abs(tr[-1][1]) > 0.1
    if M == 2.4: assert settle(tr) > 5 * settle(exact)

print("sliding law, sign switch (s0 = 1 rad/s, bound 0.5 s):")
for M in (1.6, 2.0, 2.4):
    tr = run("smc", M); n = reach(tr); tr_ = tr[n][0]
    assert tr_ <= s0 / ETA + DT                                              # road B: the bound ...
    assert all(sv <= s0 - ETA * t + 1e-3 for sv, (t, *_ ) in zip(svals(tr[:n]), tr))  # ... all along the path
    p = tr[n][1] * math.exp(-LAM * 1.0)
    print(f"  M {M} kg: reaches {tr_:.3f} s at theta {tr[n][1]:.4f} rad; 1 s later {tr[n+1000][1]:.4f}, surface says "
          f"{p:.4f}; |s| after <= {max(svals(tr[n:])):.4f}; force jumps >1 N in next 1 s: {jumps(tr[n:n+1001])}; settles {settle(tr):.3f} s")
    assert abs(tr[n + 1000][1] - p) < 2e-3
    if M == 2.4: heavy = tr; assert tr_ >= s0 / ETA - 0.01   # the heavy cart uses the whole budget
lay = run("bl", 2.4); nb = reach(lay, PHI)
print(f"boundary layer Phi {PHI} rad/s, M 2.4 kg: enters layer {lay[nb][0]:.3f} s (bound (1 - 0.1)/2 = 0.450 s); "
      f"|s| after <= {max(svals(lay[nb:])):.4f}; force jumps >1 N: {jumps(lay[nb:])}; settles {settle(lay):.3f} s")
assert (s0 - PHI) / ETA - 0.01 <= lay[nb][0] <= (s0 - PHI) / ETA + DT and max(svals(lay[nb:])) <= PHI and jumps(lay[nb:]) == 0
print(f"cart speed at 4 s, sliding run, M 2.0 kg: {run('smc', 2.0)[-1][4]:.4f} m/s")
peak = lambda tr: max(abs(x[3]) for x in tr)
print(f"peak force, M 2.4 kg: linearising {peak(run('fl', 2.4, 4.0)):.4f} N, sliding {peak(heavy):.4f} N")

for M, k, lab in ((2.6, None, "gain sized to 20 %, true mass +30 %"), (2.4, ETA, "K = eta only, no uncertainty term")):
    tb = run("smc", M, k)[reach(run("smc", M, k))][0]
    print(f"break, {lab}: M {M} kg reaches at {tb:.3f} s, bound 0.5000 s")
    assert tb > s0 / ETA
tr = run("smc", 2.4, eta=4.0); print(f"try eta 4, M 2.4 kg: reaches {tr[reach(tr)][0]:.3f} s (bound 0.25), peak force {peak(tr):.4f} N")
tr = run("bl", 2.4, phi=0.5); print(f"try Phi 0.5, M 2.4 kg: settles {settle(tr):.3f} s, force jumps >1 N: {jumps(tr[1:])}")
tr = run("fl", 2.4, 8.0, tend=30.0); print(f"try linearising k 8, M 2.4 kg: settles {settle(tr):.3f} s")
tr = run("smc", 2.4, th0=1.0); print(f"try start 1.0 rad, sliding M 2.4 kg: reaches {tr[reach(tr)][0]:.3f} s (bound 1.0)")
print("chart, time s     " + " ".join(f"{i*0.25:6.2f}" for i in range(17)))
heavyfl = run("fl", 2.4, 4.0)
for lab, tr in (("FL 2.0 kg ", exact), ("FL 2.4 kg ", heavyfl), ("SMC 2.4 kg", heavy)):
    print(f"chart, {lab} " + " ".join(f"{tr[i*250][1]:6.3f}" for i in range(17)))
print("chart2, time ms " + " ".join(f"{1000+i:5d}" for i in range(21)))
print("chart2, sign N  " + " ".join(f"{heavy[1000+i][3]:5.1f}" for i in range(21)))
print("chart2, layer N " + " ".join(f"{lay[1000+i][3]:5.1f}" for i in range(21)))
print("ALL CHECKS PASS")
