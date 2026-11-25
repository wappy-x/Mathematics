# Hilbert's sixth problem -- the check behind the card.  Standard library only.
# Roads: the mean free path from the formula and from a hard-sphere gas run by
# Newton's laws (written out); the root 2 from Maxwell pairs drawn at random.
import math
K, T, P, U = 1.380649e-23, 293.15, 101325.0, 1.66053906660e-27  # SI, exact or CODATA
D, MASS, ROOM = 3.64e-10, 28.97 * U, 4.0   # sphere diameter (illustrative), air's mass, room size
def mfp(n, d): return 1.0 / (math.sqrt(2.0) * math.pi * d * d * n)   # Boltzmann's mean free path
n = P / (K * T)
lam, vbar = mfp(n, D), math.sqrt(8.0 * K * T / (math.pi * MASS))
tau, phi = lam / vbar, n * math.pi * D * D * D / 6.0
print("air at 20 C, 1 atm; hard spheres of diameter 0.364 nm")
print(f"n from p/(kT)                {n:.4e} per m^3")
print(f"mean free path               {lam * 1e9:.2f} nm  (target area {math.pi * D * D:.3e} m^2)")
print(f"mean speed                   {vbar:.1f} m/s")
print(f"mean free time               {tau * 1e12:.1f} ps")
print(f"collisions per second each   {1.0 / tau:.3e}  (= mean free times in 1 s)")
print(f"volume fraction of spheres   {phi:.3e}")
print(f"Knudsen number, 4 m room     {lam / ROOM:.3e}")
print(f"periodic 4 m box: eps = d/L  {D / ROOM:.2e}  rate N eps^2 = {n * ROOM * D * D:.3e}"
      f"  (log|log eps|)^(1/2) = {math.sqrt(math.log(-math.log(D / ROOM))):.3f}")
assert abs(lam * 1e9 - 68.0) < 1.0          # quoted: about 68 nm
print("Boltzmann-Grad limit in 1 m^3: shrink d, keep N d^2 fixed")
for k in range(4):
    d, nk = D / 2 ** k, n * 4 ** k
    print(f"  d = {d * 1e9:.4f} nm  N = {nk:.3e}  N d^2 = {nk * d * d:.4e} m^2"
          f"  path = {mfp(nk, d) * 1e9:.2f} nm  fraction = {nk * math.pi * d * d * d / 6.0:.3e}")
print("what breaks")
print(f"  drop sqrt 2                 {lam * math.sqrt(2.0) * 1e9:.2f} nm")
print(f"  radius for diameter         {mfp(n, D / 2) * 1e9:.2f} nm")
print(f"  keep N d^3 fixed, d/8       {mfp(n * 8 ** 3, D / 8) * 1e9:.2f} nm")
# ---- random numbers (SplitMix64); Maxwell pairs; Newton's laws for hard spheres in a box ----
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return s, (z ^ (z >> 31)) >> 11

s, rel, spd, PAIRS = 7, 0.0, 0.0, 100000    # Maxwell pairs: normal components by Box-Muller
for _ in range(PAIRS):
    z = []
    while len(z) < 6:
        s, a = splitmix(s); s, b = splitmix(s)
        r, th = math.sqrt(-2.0 * math.log((a + 1) / 2.0 ** 53)), 2.0 * math.pi * b / 2.0 ** 53
        z += [r * math.cos(th), r * math.sin(th)]
    w = [z[0] - z[3], z[1] - z[4], z[2] - z[5]]
    rel += math.sqrt(w[0] * w[0] + w[1] * w[1] + w[2] * w[2]); spd += math.sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2])
print(f"Maxwell pairs, {PAIRS} drawn: mean |v - v1| / mean |v| = {rel / spd:.4f}  (sqrt 2 = {math.sqrt(2.0):.4f})")
assert abs(rel / spd - math.sqrt(2.0)) < 0.01

NP, BOX, REPS = 64, 18.85, 48              # spheres of diameter 1, box side, independent gases
VOL = BOX * BOX * BOX; PACK = NP * math.pi / 6.0 / VOL   # box volume; share the spheres fill
LAM = mfp((NP - 1) / VOL, 1.0)             # Boltzmann's mean free path, in diameters
VMAX = math.sqrt(8.0 / (3.0 * math.pi))    # Maxwell mean speed when every start speed is 1
TAU = LAM / VMAX
GRID = [float(k) for k in range(11)]       # times, in mean free times

def predict(i, x, v, now):
    best, who = math.inf, -1
    for a in range(3):
        if v[i][a] != 0.0:
            t = ((BOX if v[i][a] > 0.0 else 0.0) - x[i][a]) / v[i][a]
            if t < best: best, who = t, -1 - a
    for j in range(NP):
        if j == i: continue
        dr, dv = [x[i][a] - x[j][a] for a in range(3)], [v[i][a] - v[j][a] for a in range(3)]
        b = dr[0] * dv[0] + dr[1] * dv[1] + dr[2] * dv[2]
        if b >= 0.0: continue
        vv = dv[0] * dv[0] + dv[1] * dv[1] + dv[2] * dv[2]
        disc = b * b - vv * (dr[0] * dr[0] + dr[1] * dr[1] + dr[2] * dr[2] - 1.0)
        if disc < 0.0: continue
        t = max((-b - math.sqrt(disc)) / vv, 0.0)
        if t < best: best, who = t, j
    return (now + best, who)

def inside(p, w, dt):                      # path inside the core, one diameter from every wall
    t0, t1 = 0.0, dt
    for a in range(3):
        if w[a] == 0.0:
            if not 1.0 <= p[a] <= BOX - 1.0: return 0.0
            continue
        ta, tb = (1.0 - p[a]) / w[a], (BOX - 1.0 - p[a]) / w[a]
        t0, t1 = max(t0, min(ta, tb)), min(t1, max(ta, tb))
    if dt == 0.0: return 1 if t0 <= t1 else 0
    return max(t1 - t0, 0.0) * math.sqrt(w[0] * w[0] + w[1] * w[1] + w[2] * w[2])

def gas(seed, speed_sum, counts):
    s, x, v = seed, [], []
    while len(x) < NP:
        p = []
        for a in range(3):
            s, r = splitmix(s); p.append(BOX * r / 2.0 ** 53)
        if all((p[0] - q[0]) * (p[0] - q[0]) + (p[1] - q[1]) * (p[1] - q[1])
               + (p[2] - q[2]) * (p[2] - q[2]) > 1.0 for q in x): x.append(p)
    while len(v) < NP:
        w = []
        for a in range(3):
            s, r = splitmix(s); w.append(2.0 * r / 2.0 ** 53 - 1.0)
        r2 = w[0] * w[0] + w[1] * w[1] + w[2] * w[2]
        if 0.01 < r2 < 1.0: v.append([c / math.sqrt(r2) for c in w])
    ev, now, g, end = [predict(i, x, v, 0.0) for i in range(NP)], 0.0, 0, GRID[-1] * TAU
    while True:
        i = min(range(NP), key=lambda k: ev[k][0])
        te = min(ev[i][0], end)
        while g < len(GRID) and GRID[g] * TAU <= te:
            speed_sum[g] += sum(math.sqrt(w[0] * w[0] + w[1] * w[1] + w[2] * w[2]) for w in v); g += 1
        dt = te - now
        if now >= 2.0 * TAU:
            for k in range(NP): counts[1] += inside(x[k], v[k], dt)
        for k in range(NP): x[k] = [x[k][a] + v[k][a] * dt for a in range(3)]
        now = te
        if te >= end: return sum(w[0] * w[0] + w[1] * w[1] + w[2] * w[2] for w in v)   # energy, x2
        j = ev[i][1]
        if j < 0:
            v[i][-1 - j] = -v[i][-1 - j]; moved = [i]
        else:
            moved, dr, dv = [i, j], [x[i][a] - x[j][a] for a in range(3)], [v[i][a] - v[j][a] for a in range(3)]
            f = (dr[0] * dv[0] + dr[1] * dv[1] + dr[2] * dv[2]) / (dr[0] * dr[0] + dr[1] * dr[1] + dr[2] * dr[2])
            for a in range(3): v[i][a] -= f * dr[a]; v[j][a] += f * dr[a]
            if now >= 2.0 * TAU: counts[0] += inside(x[i], v[i], 0.0) + inside(x[j], v[j], 0.0)
        for k in moved: ev[k] = predict(k, x, v, now)
        for k in range(NP):
            if k not in moved and ev[k][1] in moved: ev[k] = predict(k, x, v, now)

speed_sum, counts = [0.0] * len(GRID), [0, 0.0]
energy = [gas(1000 + r, speed_sum, counts) for r in range(REPS)]
mean_speed, lam_sim = [s / (NP * REPS) for s in speed_sum], counts[1] / counts[0]
print(f"hard-sphere gas: {REPS} boxes of {NP} = {REPS * NP} spheres, packing {PACK:.4f}")
print(f"sum of v^2 in each box       {NP} at the start, {min(energy):.9f} to {max(energy):.9f} at the end")
print(f"Boltzmann mean free path     {LAM:.2f} diameters")
print(f"Newton, measured             {lam_sim:.2f} diameters from {counts[0]} free paths")
print(f"ratio Boltzmann/measured     {LAM / lam_sim:.4f}  (own-volume factor"
      f" {(1.0 - PACK / 2.0) / ((1.0 - PACK) * (1.0 - PACK) * (1.0 - PACK)):.4f})")
print(f"ratio without sqrt 2         {LAM * math.sqrt(2.0) / lam_sim:.4f}  (path {LAM * math.sqrt(2.0):.2f})")
print(f"Maxwell mean speed           {VMAX:.4f}")
for g in range(len(GRID)):
    print(f"t = {GRID[g]:4.1f} mean free times  mean speed {mean_speed[g]:.4f}")
assert abs(LAM / lam_sim - 1.0) < 0.04      # Boltzmann's formula against the Newton gas
assert abs(mean_speed[-1] - VMAX) < 0.02    # Maxwell's mean speed against the Newton gas
assert max(abs(e - NP) for e in energy) < 1e-9   # collisions keep the energy
print("ALL CHECKS PASS")
