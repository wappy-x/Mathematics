# HJB and verification -- the check behind the card.  Standard library only.
# A car must cover x km with tau hours left before a deadline, burning least fuel.
# Fuel burn rate at speed u km/h: F(u) = a + c u + b u^3 litres per hour
# (illustrative: idling, rolling, air drag).  Roads to the least fuel V(tau, x):
# the guessed value W; a scan over arrival times (Hopf-Lax); Bellman's backward
# recursion over every schedule on a grid of speeds; the HJB residual by centred
# differences with the Hamiltonian found by a search; and the dynamic programming
# principle over a whole 30-minute first stretch.
A, C, B = 1.08, 0.02, 2.5e-6         # L/h idling, L/km rolling, L h^2/km^3 drag

def F(u, a=A, b=B): return a + C * u + b * u ** 3
def eco(a=A, b=B):                   # speed of least fuel per km, and that fuel per km
    u = (a / (2 * b)) ** (1 / 3)
    return u, F(u, a, b) / u

def W(tau, x, a=A, b=B):             # the guessed value: two pieces, glued on x = u_eco tau
    u, ce = eco(a, b)
    if x <= 0.0: return 0.0
    if x <= u * tau: return ce * x
    return tau * F(x / tau, a, b)

def H(p):                            # Hamiltonian max_u (p u - F(u)), by ternary search
    lo, hi = 0.0, 400.0
    for _ in range(200):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        if p * m1 - F(m1) < p * m2 - F(m2): lo = m1
        else: hi = m2
    u = (lo + hi) / 2
    return p * u - F(u), u

def hopf_lax(tau, x):                # least over arrival times theta <= tau of theta F(x/theta)
    lo, hi = 1e-6, tau
    for _ in range(200):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        if m1 * F(x / m1) < m2 * F(x / m2): hi = m2
        else: lo = m1
    t = (lo + hi) / 2
    return t * F(x / t), t

def bellman(steps, dt=0.05, dx=0.25, nx=401, kmax=40):
    # speeds u = k dx/dt = 5k km/h; arriving mid-step costs distance times fuel per km
    INF = float("inf")
    V = [0.0] + [INF] * (nx - 1)
    out = [V]
    for _ in range(steps):
        new = [0.0] * nx
        for i in range(1, nx):
            best = dt * A + V[i]
            for k in range(1, kmax + 1):
                u = k * dx / dt
                cost = i * dx * F(u) / u if k >= i else dt * F(u) + V[i - k]
                if cost < best: best = cost
            new[i] = best
        V = new
        out.append(V)
    return out

U, CE = eco()
print(f"economy speed u_eco (km/h)              {U:.4f}")
print(f"fuel per km at u_eco (L/km)             {CE:.6f}")
print(f"F(60), F(80) (L/h)                      {F(60.0):.4f} {F(80.0):.4f}")
v_main, v_free = W(1.25, 100.0), W(2.0, 100.0)
print(f"W(1.25 h, 100 km), needs 80 km/h (L)    {v_main:.4f}")
print(f"W(2 h, 100 km), drives 60 km/h (L)      {v_free:.4f}")
print(f"80 km/h parts: idle, rolling, drag (L)  {1.25 * A:.4f} {100 * C:.4f} {1.25 * B * 80.0 ** 3:.4f}")
hl, th = hopf_lax(1.25, 100.0)
hl2, th2 = hopf_lax(2.0, 100.0)
print(f"Hopf-Lax 1.25 h: fuel, arrival (h)      {hl:.4f} {th:.4f}")
print(f"Hopf-Lax 2 h: fuel, arrival (h)         {hl2:.4f} {th2:.4f}")
G = bellman(40)
g125, g2, g90 = G[25][400], G[40][400], G[25][360]
print(f"Bellman grid 1.25 h, 100 km (L)         {g125:.4f}")
print(f"Bellman grid 2 h, 100 km (L)            {g2:.4f}")
print(f"Bellman grid 1.25 h, 90 km; W (L)       {g90:.4f} {W(1.25, 90.0):.4f}")
beat = max(W(n * 0.05, i * 0.25) - G[n][i] for n in range(1, 41) for i in range(401) if G[n][i] < 1e9)
print(f"most any grid schedule beats W by (L)   {max(beat, 0.0):.9f}")
dpp, arg = min((0.5 * F(k / 100) + W(0.75, 100.0 - 0.5 * k / 100), k / 100) for k in range(20001))
print(f"DPP over first 0.5 h: min, at u (km/h)  {dpp:.4f} {arg:.2f}")
pts = [(1.25, 100.0), (1.25, 50.0), (2.0, 100.0), (1.0, 30.0), (0.5, 45.0)]
res = []
for d in (1e-2, 1e-3, 1e-4):
    r = 0.0
    for tau, x in pts:
        Wt = (W(tau + d, x) - W(tau - d, x)) / (2 * d)
        Wx = (W(tau, x + d) - W(tau, x - d)) / (2 * d)
        r = max(r, abs(Wt + H(Wx)[0]))
    res.append(r)
    print(f"max HJB residual, step {d:.4f}           {r:.9f}")
Wt = (W(1.25 + 1e-4, 100.0) - W(1.25 - 1e-4, 100.0)) / 2e-4
Wx = (W(1.25, 100.0 + 1e-4) - W(1.25, 100.0 - 1e-4)) / 2e-4
print(f"V_tau, V_x at 1.25 h, 100 km            {Wt:.4f} {Wx:.4f}")
print(f"best speed for that V_x (km/h)          {H(Wx)[1]:.4f}")
print(f"slack: fuel saved per extra minute (L)  {-Wt / 60:.4f}")
e = 1e-6                             # the seam x = 60 tau, at tau = 1.25 h, x = 75 km
s1 = (W(1.25, 75.0) - W(1.25, 75.0 - e)) / e
s2 = (W(1.25, 75.0 + e) - W(1.25, 75.0)) / e
print(f"seam 75 km: W; slope left, right        {W(1.25, 75.0):.4f} {s1:.4f} {s2:.4f}")
print(f"seam: W_xx left, right (L/km^2)         {0.0:.6f} {6 * B * 75.0 / 1.25 ** 2:.6f}")
print("trip at 1.25 h: clock (min), km left, fuel used, W left, sum")
for m in range(0, 76, 15):
    x = 100.0 - 80.0 * m / 60
    used = F(80.0) * m / 60
    print(f"  {m:3d} {x:6.1f} {used:7.4f} {W(1.25 - m / 60, x):7.4f} {used + W(1.25 - m / 60, x):7.4f}")
jam = F(80.0) * 0.5 + A / 6
tl = 1.25 - 0.5 - 1 / 6
print(f"10-min jam at 30 min: new speed, total  {60.0 / tl:.4f} {jam + W(tl, 60.0):.4f}")
print("value at 1.25 h, x = 0..120 km step 10 (L):")
print("  W      " + " ".join(f"{W(1.25, 10.0 * j):.2f}" for j in range(13)))
print("  0.047x " + " ".join(f"{CE * 10.0 * j:.2f}" for j in range(13)))
late = 100.0 / U - 1.25
exact = 2.0 * F(50.0)
sprint = 45.0 * CE + 0.5 * F(110.0)
P = v_main / 100.0 ** 2
print(f"wrong: drop deadline: fuel, late (min)  {CE * 100:.4f} {late * 60:.4f}")
print(f"wrong: arrive exactly at 2 h (L)        {exact:.4f}")
print(f"wrong: 45 min at 60, then 110 (L)       {sprint:.4f}")
print(f"wrong: square P x^2 at 50 km; W (L)     {P * 2500:.4f} {W(1.25, 50.0):.4f}")
print(f"try: deadline 1 h, 1.5 h (L)            {W(1.0, 100.0):.4f} {W(1.5, 100.0):.4f}")
u2, _ = eco(b=2 * B)
print(f"try: double drag: u_eco, W(1.25,100)    {u2:.4f} {W(1.25, 100.0, b=2 * B):.4f}")
assert abs(v_main - 4.95) < 1e-9     # 1.25 h x 3.96 L/h, by hand
assert abs(hl - v_main) < 1e-6 and abs(hl2 - v_free) < 1e-6   # Hopf-Lax road agrees
assert abs(g125 - v_main) < 1e-9 and abs(g2 - v_free) < 1e-9  # grid schedules reach W
assert beat < 1e-9                   # verification: no schedule on the grid beats W
assert g90 >= W(1.25, 90.0)          # off the grid's speeds, the grid can only lose
assert abs(dpp - v_main) < 1e-6 and abs(arg - 80.0) < 0.02    # DPP over 30 minutes
assert res[2] < 1e-6 and res[1] < 0.02 * res[0]   # HJB holds; residual falls as step^2
assert abs(H(Wx)[1] - 80.0) < 1e-3   # the Hamiltonian's best speed is the trip's speed
assert abs(s1 - s2) < 1e-4           # the glued value has one slope across the seam
assert exact > v_free and sprint > v_main   # the two wrong plans cost more
print("ALL CHECKS PASS")
