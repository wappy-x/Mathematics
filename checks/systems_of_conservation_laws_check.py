# Systems of conservation laws -- the check behind the card.  Standard library only.
# Dam break on a flat channel: water 2 m deep behind the gate, 1 m in front, both at
# rest, g = 9.81 m/s^2.  Unknowns per metre of channel width: depth h, flow hu, dye h*phi.
import math
G, HL, HR, T = 9.81, 2.0, 1.0, 5.0
sq = math.sqrt
def bore_u(h, h0): return (h - h0) * sq(G / 2 * (h + h0) / (h * h0))  # Hugoniot locus
def u_left(h):     # wave curve of family 1 from the reservoir: fan if h < HL, else shock
    return 2 * (sq(G * HL) - sq(G * h)) if h <= HL else -bore_u(h, HL)
def u_right(h):    # wave curve of family 3 into the still water ahead
    return bore_u(h, HR) if h >= HR else -2 * (sq(G * HR) - sq(G * h))
def bisect(f, a, b):
    for _ in range(200):
        m = 0.5 * (a + b)
        if (f(a) > 0) == (f(m) > 0): a = m
        else: b = m
    return 0.5 * (a + b)
def flux(U):
    h, m, z = U
    return [m, m * m / h + G * h * h / 2, m * z / h]
hs = bisect(lambda h: u_left(h) - u_right(h), 0.5, 3.0); us = u_right(hs)
cl, cs, cr = sq(G * HL), sq(G * hs), sq(G * HR)
s_mass, s_mom = hs * us / (hs - HR), (hs * us * us + G * (hs * hs - HR * HR) / 2) / (hs * us)
print(f"middle state: depth {hs:.4f} m, speed {us:.4f} m/s")
print(f"in short: middle {hs:.3f} m at {us:.3f} m/s; bore {hs - HR:.3f} m high at {s_mass:.3f} m/s")
print(f"hand: c_L {cl:.4f}, c_* {cs:.4f}, c_R {cr:.4f} m/s; h*u* {hs * us:.4f} m^2/s; h* - h_R {hs - HR:.4f} m;"
      f" bore factor {sq(G / 2 * (hs + HR) / (hs * HR)):.4f} per s")
print(f"bore speed from mass {s_mass:.4f} m/s, from momentum {s_mom:.4f} m/s")
# Road 1: eigenvalues by formula, against a Jacobian built by centred differences
U, e = [hs, hs * us, hs * 0.5], 1e-6
J = [[0.0] * 3 for _ in range(3)]
for j in range(3):
    Up, Um = U[:], U[:]; Up[j] += e; Um[j] -= e
    Fp, Fm = flux(Up), flux(Um)
    for i in range(3): J[i][j] = (Fp[i] - Fm[i]) / (2 * e)
lams, vecs = [us - cs, us, us + cs], [[1, us - cs, 0.5], [0, 0, 1], [1, us + cs, 0.5]]
res = max(abs(sum(J[i][k] * r[k] for k in range(3)) - l * r[i])
          for l, r in zip(lams, vecs) for i in range(3))
print(f"speeds in the middle: {lams[0]:.4f}, {lams[1]:.4f}, {lams[2]:.4f} m/s; largest |J r - lam r| {res:.6f}")
def lam(V, k): return V[1] / V[0] + (k - 2) * sq(G * V[0])
dl = [(lam([a + e * b for a, b in zip(U, r)], k) - lam([a - e * b for a, b in zip(U, r)], k)) / (2 * e)
      for k, r in zip((1, 2, 3), vecs)]
print(f"grad lam . r: family 1 {dl[0]:.4f}, family 2 {dl[1]:.4f}, family 3 {dl[2]:.4f} (per s)")
print(f"family 1 by formula {-1.5 * cs / hs:.4f}, family 3 {1.5 * cs / hs:.4f}")
# Lax entropy test on the bore, and the Riemann invariants
print(f"Lax: {us + cs:.4f} > {s_mass:.4f} > {cr:.4f}, and {s_mass:.4f} > {us:.4f} m/s")
print(f"u + 2c: reservoir {2 * cl:.4f}, middle {us + 2 * cs:.4f} m/s")
print(f"u - 2c: middle {us - 2 * cs:.4f}, ahead {-2 * cr:.4f}; change across bore {us - 2 * cs + 2 * cr:.4f} m/s")
edges = [-cl * T, (us - cs) * T, us * T, s_mass * T]
print("at 5 s: fan from {:.2f} to {:.2f} m, dye front {:.2f} m, bore {:.2f} m".format(*edges))
def exact(x, t):
    if x < -cl * t: return HL, 0.0, 1.0
    if x < (us - cs) * t:
        c = (2 * cl - x / t) / 3
        return c * c / G, x / t + c, 1.0
    if x < us * t: return hs, us, 1.0
    if x < s_mass * t: return hs, us, 0.0
    return HR, 0.0, 0.0
hf, uf, _ = exact(-15, T)
print(f"fan at -15 m, 5 s: x/t -3.0 m/s, c {(2 * cl + 3) / 3:.4f} m/s, u {uf:.4f} m/s, depth {hf:.4f} m")
# Road 2: the fan obeys both equations; centred-difference residual at x = -15 m
row = []
for d in (0.1, 0.05):
    def q(x, t): h, u, _ = exact(x, t); return h, h * u, h * u * u + G * h * h / 2
    r1 = (q(-15, T + d)[0] - q(-15, T - d)[0] + q(-15 + d, T)[1] - q(-15 - d, T)[1]) / (2 * d)
    r2 = (q(-15, T + d)[1] - q(-15, T - d)[1] + q(-15 + d, T)[2] - q(-15 - d, T)[2]) / (2 * d)
    row.append((abs(r1), abs(r2)))
print(f"fan residual at -15 m, 5 s, steps 0.1 and 0.05: mass {row[0][0]:.6f}, {row[1][0]:.6f} m/s;"
      f" momentum {row[0][1]:.6f}, {row[1][1]:.6f} m^2/s^2")
# Road 3: a grid that knows nothing of fans or bores (Rusanov's averaged flux)
def grid(n):
    dx = 100.0 / n; xs = [-50 + (i + 0.5) * dx for i in range(n)]
    W = [[HL, 0.0, HL] if x < 0 else [HR, 0.0, 0.0] for x in xs]; t = 0.0
    while t < T - 1e-12:
        sp = [abs(w[1] / w[0]) + sq(G * w[0]) for w in W]
        dt = min(0.45 * dx / max(sp), T - t); Wx = [W[0]] + W + [W[-1]]
        Fx = [flux(w) for w in Wx]; spx = [sp[0]] + sp + [sp[-1]]; Fh = []
        for i in range(n + 1):
            a = max(spx[i], spx[i + 1])
            Fh.append([0.5 * (Fx[i][k] + Fx[i + 1][k]) - 0.5 * a * (Wx[i + 1][k] - Wx[i][k]) for k in range(3)])
        W = [[W[i][k] - dt / dx * (Fh[i + 1][k] - Fh[i][k]) for k in range(3)] for i in range(n)]; t += dt
    err = sum(abs(w[0] - exact(x, T)[0]) for w, x in zip(W, xs)) * dx
    fan = sum(abs(w[0] - exact(x, T)[0]) for w, x in zip(W, xs) if x < -5) * dx
    mid = [w[0] for w, x in zip(W, xs) if -8 <= x <= 2]
    dye = next(x for w, x in zip(W, xs) if w[2] / w[0] < 0.5)
    return err, fan, sum(mid) / len(mid), dye, sum(w[0] for w in W) * dx, sum(w[2] for w in W) * dx
errs, fans = [], []
for n in (200, 400, 800):
    err, fan, mid, dye, vol, ink = grid(n); errs.append(err); fans.append(fan)
    print(f"grid {n} cells: depth error {err:.4f} m^2, middle depth {mid:.4f} m, dye front {dye:.2f} m, water {vol:.4f} m^2, dye {ink:.4f} m^2")
r1, r2 = errs[0] / errs[1], errs[1] / errs[2]
print(f"error ratio per halving: {r1:.3f} and {r2:.3f}; observed order {math.log2(r1):.2f} and {math.log2(r2):.2f}")
bores = [a - b for a, b in zip(errs, fans)]
for name, v in (("fan side, x < -5 m:", fans), ("bore side, x >= -5 m:", bores)):
    print(f"{name} depth error {v[0]:.4f}, {v[1]:.4f}, {v[2]:.4f} m^2; ratio per halving {v[0] / v[1]:.3f} and {v[1] / v[2]:.3f}")
# What breaks
h2 = bisect(lambda h: -bore_u(h, HL) - bore_u(h, HR), 0.5, 3.0); u2 = bore_u(h2, HR)
s1 = h2 * u2 / (h2 - HL)
print(f"breaks: two shocks: depth {h2:.4f} m, upstream jump at {s1:.4f} m/s, but Lax needs {-cl:.4f} > s1 > {u2 - sq(G * h2):.4f}")
def uvel(h): return (h - HR) * sq(2 * G / (h + HR))
h3 = bisect(lambda h: u_left(h) - uvel(h), 0.5, 3.0)
print(f"breaks: conserve speed, not momentum: depth {h3:.4f} m, bore {h3 * uvel(h3) / (h3 - HR):.4f} m/s")
cb = sq(G * 1.5)
print(f"breaks: linearise about 1.5 m: speed {G * 0.5 / cb:.4f} m/s, bore {cb:.4f} m/s")
print(f"breaks: dye carried at the bore speed: {s_mass * T:.2f} m at 5 s, not {us * T:.2f} m")
print(f"breaks: dry channel ahead: no middle state; front at 2 c_L = {2 * cl:.4f} m/s, where c = 0 and lam1 = lam2 = lam3")
print("chart, depth h m: " + " ".join(f"{1 + i / 10:.1f}" for i in range(11)))
print("chart, family 1:  " + " ".join(f"{u_left(1 + i / 10):.2f}" for i in range(11)))
print("chart, family 3:  " + " ".join(f"{u_right(1 + i / 10):.2f}" for i in range(11)))
print("bars, depth at 5 s: " + " ".join(f"{x}:{exact(x, T)[0]:.3f}" for x in range(-30, 31, 5)))
print("figure, x at 5 s: {:.2f} {:.2f} {:.2f} {:.2f}".format(*edges))
assert abs(hs - 1.4538) < 1e-4 and abs(us - 1.3058) < 1e-4            # the spec's numbers
assert abs(s_mass - s_mom) < 1e-9 and abs(us + 2 * cs - 2 * cl) < 1e-9  # Hugoniot, invariant
assert res < 1e-6 and abs(dl[0] + 1.5 * cs / hs) < 1e-6 and abs(dl[1]) < 1e-6 and abs(dl[2] - 1.5 * cs / hs) < 1e-6
assert us + cs > s_mass > cr and s_mass > us and s1 > -cl  # Lax fails
assert all(3.5 < row[0][k] / row[1][k] < 4.5 for k in (0, 1))   # residual falls as step^2
assert errs[0] > errs[1] > errs[2] and abs(mid - hs) < 0.01 and abs(dye - us * T) < 1.0
assert bores[0] / bores[1] > 1.85 and bores[1] / bores[2] > 1.85 and fans[0] / fans[1] < 1.7 and fans[1] / fans[2] < 1.7
assert abs(vol - 150) < 1e-9 and abs(ink - 100) < 1e-9
print("ALL CHECKS PASS")
