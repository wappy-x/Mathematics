# Stochastic heat equation u_t = u_xx + xi on a rod (0, pi), ends held at 0, noise strength 1.
# Road 1: mode sums (each mode an OU process). Road 2: closed forms (Basel sum, Green's function).
# Road 3: Euler-Maruyama simulation on a grid, seeded SplitMix64 + Box-Muller.
import math

PI = math.pi
MASK = (1 << 64) - 1
state = 20261123

def next_u():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    z ^= z >> 31
    return ((z >> 11) + 0.5) / 9007199254740992.0

def normal_pair():
    r = math.sqrt(-2.0 * math.log(next_u()))
    a = 2.0 * PI * next_u()
    return r * math.cos(a), r * math.sin(a)

print("rod (0, pi), ends at 0, noise strength 1; mode k: pull k^2, stationary variance 1/(2k^2)")
for k in range(1, 6):
    v = 1.0 / (2 * k * k)
    print(f"mode {k}: pull {k*k:2d}  variance {v:.4f}  share of total {100 * v / (PI**2 / 12):5.2f}%  at t = 3: {v * (1 - math.exp(-6 * k * k)):.5f}")
total = PI ** 2 / 12
print(f"total, closed form pi^2/12 = {total:.6f}")
s, partial = 0.0, {}
for k in range(1, 100001):
    s += 1.0 / (2 * k * k)
    if k in (1, 2, 5, 10, 100, 1000, 100000):
        partial[k] = s
        print(f"1D partial sum to K = {k:6d}: {s:.6f}  gap to pi^2/12 {total - s:.6f}  tail bound 1/(2K) {1 / (2 * k):.6f}")
assert abs(partial[100000] - total) < 1e-5
assert total - partial[1000] < 1 / 2000 and total - partial[1000] > 1 / 2002

def point_var_modes(x, K):
    return sum(math.sin(k * x) ** 2 / (k * k) for k in range(1, K + 1)) / PI

for x, name in ((PI / 2, "pi/2"), (PI / 4, "pi/4")):
    mv, cf = point_var_modes(x, 200000), x * (PI - x) / (2 * PI)
    print(f"variance at x = {name}: mode sum {mv:.6f}  closed form x(pi-x)/(2pi) {cf:.6f}")
    assert abs(mv - cf) < 1e-5
print(f"hand: pi^2/12 {PI**2/12:.4f}, pi/8 {PI/8:.4f}, 3pi/32 {3*PI/32:.4f}, (pi/4) ln 2 {PI/4*math.log(2):.4f}")

def square_sum(R):
    return sum(1.0 / (2 * (j * j + k * k)) for j in range(1, R + 1) for k in range(1, R + 1) if j * j + k * k <= R * R)

prev = None
for R in (10, 20, 40, 80, 160, 320):
    s2 = square_sum(R)
    print(f"2D square sum over j^2+k^2 <= {R:3d}^2: {s2:.4f}" + (f"  rise since last {s2 - prev:.4f}" if prev else ""))
    if R == 320:
        assert abs((s2 - prev) - PI / 4 * math.log(2)) < 0.01
    prev = s2

def grid1d(N):
    h = PI / (N + 1)
    m = (N + 1) // 2
    v = sum((2 / (N + 1)) * math.sin(j * m * PI / (N + 1)) ** 2 / ((4 / h**2) * math.sin(j * h / 2) ** 2) for j in range(1, N + 1))
    return v / (2 * h)

def grid2d(N):
    h = PI / (N + 1)
    lam = [(4 / h**2) * math.sin(j * h / 2) ** 2 for j in range(N + 1)]
    v = sum((2 / (N + 1)) ** 2 / (lam[j] + lam[k]) for j in range(1, N + 1, 2) for k in range(1, N + 1, 2))
    return v / (2 * h * h)

g1, g2 = [], []
for N in (7, 15, 31, 63, 127):
    g1.append(grid1d(N)); g2.append(grid2d(N))
    print(f"grid N = {N:3d}, h = pi/{N+1}: midpoint variance, rod {g1[-1]:.4f}  square {g2[-1]:.4f}")
    assert abs(g1[-1] - PI / 8) < 1e-12
print(f"square: rise per halving of h {g2[-1] - g2[-2]:.4f}, continuum rate ln 2/(4 pi) {math.log(2) / (4 * PI):.4f}")
assert abs((g2[-1] - g2[-2]) - math.log(2) / (4 * PI)) < 0.002
print(f"chart, rod    {' '.join(f'{v:.3f}' for v in g1)}")
print(f"chart, square {' '.join(f'{v:.3f}' for v in g2)}")

N, T, M = 15, 3.0, 1000
h = PI / (N + 1)
dt = h * h / 4
n = round(T / dt)
dt = T / n
xs = [(i + 1) * h for i in range(N)]
vk = [[math.sqrt(2 / (N + 1)) * math.sin(k * (i + 1) * PI / (N + 1)) for i in range(N)] for k in range(1, N + 1)]
lk = [(4 / h**2) * math.sin(k * h / 2) ** 2 for k in range(1, N + 1)]
assert 1 - lk[N - 1] * dt >= -1                  # stable: the fastest grid mode does not flip and grow

def mode_var(k, step=dt, scale=dt / h):
    rho = 1 - lk[k] * step
    return scale * (1 - rho ** (2 * round(T / step))) / (1 - rho * rho)

mid = N // 2
ex_mid = sum(vk[k][mid] ** 2 * mode_var(k) for k in range(N))
ex_energy = h * sum(mode_var(k) for k in range(N))
ex_a1 = h * mode_var(0)
print(f"simulation: N = {N} interior points, h = pi/{N + 1}, dt = {dt:.6f}, {n} steps to t = {T:.0f}, {M} paths, seed 20261123")
mids, energies, a1s, snap = [], [], [], None
for p in range(M):
    u = [0.0] * N
    c = math.sqrt(dt / h)
    for _ in range(n):
        z = []
        while len(z) < N:
            z.extend(normal_pair())
        u = [u[i] + dt * ((u[i - 1] if i > 0 else 0.0) - 2 * u[i] + (u[i + 1] if i < N - 1 else 0.0)) / (h * h) + c * z[i] for i in range(N)]
    if p == 0:
        snap = [0.0] + u + [0.0]
    mids.append(u[mid] ** 2)
    energies.append(h * sum(w * w for w in u))
    a1s.append((h * sum(math.sqrt(2 / PI) * math.sin(xs[i]) * u[i] for i in range(N))) ** 2)

def report(label, vals, exact, cont):
    mean = sum(vals) / M
    se = math.sqrt(sum((w - mean) ** 2 for w in vals) / (M - 1) / M)
    print(f"{label:22s} sim {mean:.4f} +- {se:.4f}  grid exact {exact:.4f}  continuum {cont:.4f}")
    assert abs(mean - exact) < 4 * se

cont_mid = PI / 8 - sum(math.exp(-6 * k * k) / (k * k) for k in range(1, 50, 2)) / PI
report("midpoint variance", mids, ex_mid, cont_mid)
report("energy, integral u^2", energies, ex_energy, PI ** 2 / 12 - sum(math.exp(-6 * k * k) / (2 * k * k) for k in range(1, 50)))
report("mode 1 variance", a1s, ex_a1, 0.5 * (1 - math.exp(-6)))
print(f"chart, x      {' '.join(f'{(i * h):.2f}' for i in range(N + 2))}")
print(f"chart, path   {' '.join(f'{w:.2f}' for w in snap)}")
sd = [math.sqrt(i * h * (PI - i * h) / (2 * PI)) for i in range(N + 2)]
print(f"chart, +1 sd  {' '.join(f'{w:.2f}' for w in sd)}")
print(f"chart, -1 sd  {' '.join(f'{(-w if w > 0.005 else 0.0):.2f}' for w in sd)}")
wrong_noise = sum(vk[k][mid] ** 2 * mode_var(k, scale=dt) for k in range(N))
big = 0.6 * h * h
amp = round(T / big) * math.log10(abs(1 - lk[N - 1] * big))
print(f"mistake, variance 1/k^2 (drop the 2): total {PI ** 2 / 6:.4f}")
print(f"mistake, noise sqrt(dt) not sqrt(dt/h): midpoint variance {wrong_noise:.4f}, true {ex_mid:.4f}")
print(f"mistake, dt = 0.6 h^2: top mode factor {1 - lk[N-1] * big:.4f} per step, grows by 10^{amp:.1f} by t = 3")
r, direct = [float(i == mid) for i in range(N)], 0.0      # the same variance with no modes: step the scheme directly
for _ in range(n): direct, r = direct + dt * sum(w * w for w in r), [r[i] + dt * ((r[i - 1] if i > 0 else 0.0) - 2 * r[i] + (r[i + 1] if i < N - 1 else 0.0)) / (h * h) for i in range(N)]
assert abs(direct - wrong_noise) < 1e-9
assert 1 - lk[N - 1] * big < -1
print("ALL CHECKS PASS")
