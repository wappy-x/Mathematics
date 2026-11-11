# Fourier's law and a layered wall -- the check behind the card.  Standard library only.
# A 300 mm filled cavity wall: plaster, aircrete block, mineral wool, brick.
# Road 1: thermal resistances in series, q = (T_in - T_out) / sum of R.
# Road 2: the transient heat equation, stepped in time from a wrong start
#         until it settles; it never uses the series formula.
# Road 3: the same time-stepper on one brick slab, against the exact
#         separation-of-variables series.
from math import exp, pi, sin

T_IN, T_OUT, AREA = 20.0, 0.0, 10.0   # room air, outside air in C; wall area in m^2
RSI, RSE = 0.13, 0.04                 # inside and outside surface films, m^2 K/W (CIBSE Guide A)
# name, thickness m, k W/(m K), density kg/m^3, c J/(kg K); inside face first
WALL = [("plaster", 0.015, 0.40, 1000, 1000), ("aircrete block", 0.085, 0.15, 600, 1000),
        ("mineral wool", 0.100, 0.035, 25, 1030), ("brick", 0.100, 0.77, 1700, 800)]
R_AIR_GAP = 0.18                      # unventilated 100 mm air cavity, m^2 K/W (CIBSE Guide A)

def flux(layers, t_in=T_IN, t_out=T_OUT, films=True):    # road 1, W/m^2
    r = sum(d / k for _, d, k, _, _ in layers) + ((RSI + RSE) if films else 0.0)
    return (t_in - t_out) / r, r

def grid(layers, dx):                 # cells of width dx, with k and heat capacity per m^2
    ks, caps = [], []
    for _, d, k, rho, c in layers:
        for _ in range(round(d / dx)):
            ks.append(k)
            caps.append(rho * c * dx)
    links = [1 / (dx / (2 * a) + dx / (2 * b)) for a, b in zip(ks, ks[1:])]
    return ks, caps, links

def step_wall(temps, ks, caps, links, dx, t_in, t_out, seconds, dt, record=None, films=(RSI, RSE)):
    g_in, g_out = 1 / (films[0] + dx / (2 * ks[0])), 1 / (films[1] + dx / (2 * ks[-1]))
    n, steps = len(temps), round(seconds / dt)
    for s in range(steps):
        q = [g * (temps[i] - temps[i + 1]) for i, g in enumerate(links)]
        q_in, q_out = g_in * (t_in - temps[0]), g_out * (temps[-1] - t_out)
        new = temps[:]
        for i in range(n):            # heat in minus heat out, over the cell's capacity
            left = q_in if i == 0 else q[i - 1]
            right = q_out if i == n - 1 else q[i]
            new[i] += dt * (left - right) / caps[i]
        temps = new
        if record is not None and (s + 1) % record[0] == 0:
            q_in = g_in * (t_in - temps[0])  # the room face sits one film below the room air
            record[1].append((q_in, g_out * (temps[-1] - t_out), t_in - films[0] * q_in))
    return temps, g_in * (t_in - temps[0]), g_out * (temps[-1] - t_out)

q, r_tot = flux(WALL)
print(f"{'total resistance R':<34}{r_tot:10.4f} m^2 K/W")
print(f"{'U = 1/R':<34}{1 / r_tot:10.4f} W/(m^2 K)")
print(f"{'1 series formula, q':<34}{q:10.4f} W/m^2")
print(f"{'  through 10 m^2 of wall':<34}{q * AREA:10.2f} W")
t, faces = T_IN - q * RSI, []
print(f"{'inside surface':<34}{t:10.3f} C")
for name, d, k, rho, c in WALL:
    drop = q * d / k
    print(f"  {name:<16}R {d / k:7.4f}  drop {drop:7.3f} K  share {100 * drop / (T_IN - T_OUT):5.1f} %")
    faces.append(t)
    t -= drop
faces.append(t)
print(f"{'outside surface':<34}{t:10.3f} C")
dx, dt = 0.005, 5.0
ks, caps, links = grid(WALL, dx)
temps, q_in, q_out = step_wall([10.0] * len(ks), ks, caps, links, dx, T_IN, T_OUT, 72 * 3600, dt)
print(f"{'2 time-stepped, 72 h, q in, q out':<34}{q_in:10.4f}{q_out:10.4f} W/m^2")
fd_wool = temps[19] - q_in * dx / (2 * 0.15)   # last block cell, half a cell on to the wool
print(f"{'  block-wool face, stepped, formula':<34}{fd_wool:10.4f}{faces[2]:10.4f} C")
diffus = [k / (rho * c) for _, d, k, rho, c in WALL]
print("diffusivity, 1e-7 m^2/s " + " ".join(f"{1e7 * a:7.3f}" for a in diffus))

def slab_fd(n, seconds, dt):          # road 3: the same stepper on a brick slab, 20 C, faces held at 0 C
    h = WALL[3][1] / n
    ks, caps, links = grid(WALL[3:], h)
    temps = step_wall([20.0] * n, ks, caps, links, h, 0.0, 0.0, seconds, dt, films=(0.0, 0.0))[0]
    return (temps[n // 2 - 1] + temps[n // 2]) / 2

def slab_series(seconds):             # sum over odd n of (80 / n pi) sin(n pi / 2) e^(-kappa n^2 pi^2 t / L^2)
    kap, d = diffus[3], WALL[3][1]
    return sum(80 / (n * pi) * sin(n * pi / 2) * exp(-kap * (n * pi / d) ** 2 * seconds) for n in range(1, 400, 2))

exact = slab_series(1800)
coarse, fine = slab_fd(20, 1800, 2.0), slab_fd(40, 1800, 0.5)
print(f"{'3 brick centre at 30 min, series':<34}{exact:10.4f} C")
print(f"{'  stepped, 20 and 40 cells':<34}{coarse:10.4f}{fine:10.4f} C")
print(f"{'  error ratio, coarse/fine':<34}{(coarse - exact) / (fine - exact):10.2f}")

rec = (120, [(q, q, T_IN - RSI * q)])  # cold snap: outside drops to -10 C; a reading every 10 min
step_wall(temps, ks, caps, links, dx, T_IN, -10.0, 24 * 3600, dt, rec)
q_new = flux(WALL, t_out=-10.0)[0]
mid = (q + q_new) / 2                # halfway flux, crossed between two 10-minute readings
i = next(i for i, r in enumerate(rec[1]) if r[0] > mid)
half = (i - 1 + (mid - rec[1][i - 1][0]) / (rec[1][i][0] - rec[1][i - 1][0])) / 6
two_h = rec[1][::12]
print(f"{'cold snap: new steady q':<34}{q_new:10.4f} W/m^2")
print(f"{'  q in passes halfway after':<34}{half:10.2f} h")
print(f"{'chart, hours':<15}" + "".join(f"{2 * i:6d}" for i in range(13)))
print(f"{'chart, q in':<15}" + "".join(f"{a:6.2f}" for a, _, _ in two_h))
print(f"{'chart, q out':<15}" + "".join(f"{b:6.2f}" for _, b, _ in two_h))
print(f"{'inside surface at 24 h':<34}{two_h[-1][2]:10.3f} C")

avg_k = sum(d * k for _, d, k, _, _ in WALL) / sum(d for _, d, _, _, _ in WALL)
wrong_avg = flux([("mean", 0.3, avg_k, 0, 0)])[0]
wrong_films = flux(WALL, films=False)[0]
empty = WALL[:2] + [("air gap", 0.1, 0.1 / R_AIR_GAP, 1.2, 1005)] + WALL[3:]
q_empty = flux(empty)[0]
q_still = flux(WALL[:2] + [("still air", 0.1, 0.026, 1.2, 1005)] + WALL[3:])[0]
print(f"{'wrong: thickness-averaged k':<34}{wrong_avg:10.4f} W/m^2")
print(f"{'wrong: surface films left out':<34}{wrong_films:10.4f} W/m^2")
print(f"{'empty cavity, real R 0.18':<34}{q_empty:10.4f} W/m^2{q_empty * AREA:9.2f} W")
print(f"{'wrong: empty cavity as still air':<34}{q_still:10.4f} W/m^2")
try_wool = flux(WALL[:2] + [("wool", 0.2, 0.035, 25, 1030)] + WALL[3:])[0]
try_dense = flux(WALL[:1] + [("dense block", 0.085, 1.13, 2000, 1000)] + WALL[2:])[0]
print(f"{'try: 200 mm of wool':<34}{try_wool:10.4f} W/m^2")
print(f"{'try: dense block, k 1.13':<34}{try_dense:10.4f} W/m^2")
xs = [0.0] + [sum(w[1] for w in WALL[:i + 1]) for i in range(4)]
print("figure, x px " + " ".join(f"{60 + 1100 * x:.1f}" for x in xs)
      + " | y px " + " ".join(f"{250 - 10 * f:.1f}" for f in faces))

assert abs(q_in - q) < 1e-4 and abs(q_out - q) < 1e-4, "stepped wall must settle on the series flux"
assert abs(fd_wool - faces[2]) < 1e-3, "interface temperature, stepped against formula"
assert abs(fine - exact) < 0.02, "time-stepper against the separation-of-variables series"
assert 3.0 < (coarse - exact) / (fine - exact) < 5.0, "halving the cells cuts the error about four times"
assert abs(rec[1][-1][0] - q_new) < abs(q - q_new), "after the cold snap the flux heads to the new steady value"
assert q_still < q < q_empty, "still air would beat the wool; the real gap loses far more"
print("ALL CHECKS PASS")
