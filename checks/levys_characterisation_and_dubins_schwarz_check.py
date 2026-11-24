# Levy's characterisation and Dubins-Schwarz: four roads, standard library only.
import math

MASK = (1 << 64) - 1
class Rng:  # SplitMix64 uniforms, Box-Muller normals (one per call)
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def n(self):
        u1 = 1.0 - self.u()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * self.u())

def simpson(f, a, b, m=2000):
    h = (b - a) / m
    s = f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, m))
    return s * h / 3
phi = lambda z: math.exp(-z * z / 2) / math.sqrt(2 * math.pi)
def Phi(x): return 0.5 + simpson(phi, 0.0, x)
def Phi_series(x):  # 0.5 + sum of the Taylor series of the integral of phi
    s, k, term = 0.0, 0, x
    while abs(term) > 1e-17:
        s += term / (2 * k + 1); k += 1; term *= -x * x / (2 * k)
    return 0.5 + s / math.sqrt(2 * math.pi)
def mean(v): return sum(v) / len(v)
def se(v):
    m = mean(v); return math.sqrt(sum((x - m) ** 2 for x in v) / (len(v) - 1) / len(v))
def corr(x, y):
    mx, my = mean(x), mean(y)
    c = sum((a - mx) * (b - my) for a, b in zip(x, y))
    return c / math.sqrt(sum((a - mx) ** 2 for a in x) * sum((b - my) ** 2 for b in y))

# Road 1: formulas
p1, p2w, pneg = 1 - Phi(1.0), 1 - Phi(2 / math.sqrt(2)), Phi(-0.5 / math.sqrt(0.5))
kurt = simpson(lambda z: ((z * z - 1) / 2) ** 4 * phi(z), -12, 12, 4000) / 0.25
print(f"formula   P(N(0,1) > 1) = {p1:.6f}   series {Phi_series(-1.0):.6f}   E[cos W_1] = e^-1/2 = {math.exp(-0.5):.6f}")
print(f"formula   twice-as-fast P(W_2 > 2) = {p2w:.6f}   P(N(0,0.5) < -0.5) = {pneg:.6f}   Poisson P(N_1 - 4 = -4) = e^-4 = {math.exp(-4):.6f}")
print(f"formula   house X_1 = (W_1^2 - 1)/2: E[X_1^2] = 0.5, E[X_1^4]/E[X_1^2]^2 = {kurt:.4f} (normal: 3)")
mom = [simpson(lambda z, j=j: z ** j * phi(z), -12, 12, 4000) for j in (8, 6, 4, 2)]
print(f"formula   E[(W_1^2 - 1)^4] = {mom[0]:.4f} - {4 * mom[1]:.4f} + {6 * mom[2]:.4f} - {4 * mom[3]:.4f} + 1; over 16, E[X_1^4] = {kurt / 4:.4f}")
assert abs(Phi(1.0) - Phi_series(1.0)) < 1e-10 and abs(kurt - 15) < 1e-6
assert all(abs(m - math.prod(range(j - 1, 0, -2))) < 1e-6 for m, j in zip(mom, (8, 6, 4, 2)))  # 7!!, 5!!, 3!!, 1!!

# Road 2: coin flips, every one of the 4096 paths of 12 steps
n = 12; lawS, lawM, differ = {}, {}, 0
for code in range(1 << n):
    S = M = H = 0
    for k in range(n):
        x = 1 if (code >> k) & 1 else -1
        M += (1 if S >= 0 else -1) * x; H += S * x; S += x
    assert 2 * H == S * S - n
    lawS[S] = lawS.get(S, 0) + 1; lawM[M] = lawM.get(M, 0) + 1; differ += M != S
assert lawS == lawM
print(f"coins     12 steps: sign-strategy total has the walk's law exactly; totals differ on {differ} of 4096 paths")
print("coins     counts at -12..12 step 2:", " ".join(str(lawM[v]) for v in range(-12, 13, 2)))
print(f"coins     P(total >= 4) = {sum(c for v, c in lawM.items() if v >= 4)}/4096 = {sum(c for v, c in lawM.items() if v >= 4)/4096:.6f}")

# Road 3: simulate M_t = int sgn(W) dW and Y_t = int 2 dW on [0, 1]
rng = Rng(20261123); P, steps = 40000, 200; dt = 1.0 / steps
Mh, M1, W1 = [], [], []
for _ in range(P):
    W = M = 0.0
    for k in range(steps):
        dW = math.sqrt(dt) * rng.n(); M += (1.0 if W >= 0 else -1.0) * dW; W += dW
        if k == steps // 2 - 1: Mh.append(M)
    M1.append(M); W1.append(W)
sq = [m * m for m in M1]; q4 = [m ** 4 for m in M1]; big = [1.0 if m > 1 else 0.0 for m in M1]
cs = [math.cos(m) for m in M1]; sn = [math.sin(m) for m in M1]
N1 = [2 * b for b in W1]; bigN = [1.0 if v > 2 else 0.0 for v in N1]
print(f"simulate  sign integral, {P} paths, dt {dt}, bracket = steps x dt, since sgn^2 = 1: {steps * dt:.4f}")
print(f"  E[M_1] {mean(M1):.4f} se {se(M1):.4f}   E[M_1^2] {mean(sq):.4f} se {se(sq):.4f}   E[M_1^4] {mean(q4):.4f} se {se(q4):.4f}")
print(f"  P(M_1 > 1) {mean(big):.4f} se {se(big):.4f}   E[cos M_1] {mean(cs):.4f} se {se(cs):.4f}   E[sin M_1] {mean(sn):.4f}")
print(f"  E[Z_1] = E[cos M_1] e^(1/2) = {mean(cs) * math.exp(0.5):.4f}")
inc = [b - a for a, b in zip(Mh, M1)]
print(f"  corr(M_0.5^2, (M_1 - M_0.5)^2) {corr([a * a for a in Mh], [b * b for b in inc]):.4f}   corr(M_1, W_1) {corr(M1, W1):.4f}   corr(M_1, |W_1|) {corr(M1, [abs(b) for b in W1]):.4f} (continuous time {0.5 / math.sqrt(1 - 2 / math.pi):.4f})")
print(f"  constant 2, Y = 2W: E[Y_1^2] {mean([v * v for v in N1]):.4f}   P(Y_1 > 2) {mean(bigN):.4f} se {se(bigN):.4f}")
assert abs(mean(sq) - 1) < 4 * se(sq) and abs(mean(big) - p1) < 4 * se(big)
assert abs(mean(cs) - math.exp(-0.5)) < 4 * se(cs) and abs(mean(bigN) - p1) < 4 * se(bigN)

# Road 4: Dubins-Schwarz on the house example X = int W dW, clock A = int W^2 dt
rng = Rng(20261124); P2, s, cap = 40000, 0.5, 4000
beta, Atau, tau, Mfix, Afix = [], [], [], [], []
for _ in range(P2):
    W = M = A = 0.0; k = 0; done = False
    while k < cap and (not done or k < steps):
        if not done and A >= s: beta.append(M); Atau.append(A); tau.append(k * dt); done = True
        dW = math.sqrt(dt) * rng.n(); M += W * dW; A += W * W * dt; W += dW; k += 1
        if k == steps: Mfix.append((W * W - 1.0) / 2); Afix.append(A)
b2 = [b * b for b in beta]; b4 = [b ** 4 for b in beta]
up = [1.0 if b > math.sqrt(s) else 0.0 for b in beta]; dn = [1.0 if b < -0.5 else 0.0 for b in beta]
f2 = [m * m for m in Mfix]; zr = [m / math.sqrt(a) for m, a in zip(Mfix, Afix)]; lo = [1.0 if z < -1 else 0.0 for z in zr]
etau = math.sqrt(2 * s / math.pi) * simpson(lambda u: 1 / math.sqrt(math.cosh(u)), 0.0, 60.0, 4000)  # sqrt(s) E[A_1^(-1/2)]
print(f"time change  house example, {P2} paths, stop when the clock A reaches s = {s}: reached on {len(beta)}")
print(f"  mean stopping time {mean(tau):.4f} years (exact {etau:.4f})   mean clock at the stop {mean(Atau):.4f}")
print(f"  E[beta_s^2] {mean(b2):.4f} se {se(b2):.4f}   E[beta^4]/E[beta^2]^2 {mean(b4) / mean(b2) ** 2:.4f}   P(beta_s > sqrt s) {mean(up):.4f} se {se(up):.4f}")
print(f"  P(beta_s < -0.5) {mean(dn):.4f} se {se(dn):.4f}")
print(f"  fixed time 1: E[X_1^2] {mean(f2):.4f}  E[X_1^4]/E[X_1^2]^2 {mean([m ** 4 for m in Mfix]) / mean(f2) ** 2:.4f}  P(X_1 < -0.5) {mean([1.0 if m < -0.5 else 0.0 for m in Mfix]):.4f}")
assert len(beta) == P2 and abs(mean(b2) - mean(Atau)) < 4 * se(b2)
assert abs(mean(up) - p1) < 4 * se(up) and abs(mean(dn) - pneg) < 4 * se(dn)
print(f"  X_1/sqrt(A_1): mean square {mean([z * z for z in zr]):.4f}   P(< -1) {mean(lo):.4f} se {se(lo):.4f}   P(> 1) {mean([1.0 if z > 1 else 0.0 for z in zr]):.4f}   normal: 1, {p1:.6f}")
assert mean(lo) - p1 > 4 * se(lo)  # dividing by a random clock does not give a normal law

# the chart: one path's clock A_t against the clocks t and 4t
rng = Rng(20261125); W = A = 0.0; pts = ["0.00"]
for k in range(1, 401):
    dW = math.sqrt(dt) * rng.n(); A += W * W * dt; W += dW
    if k % 20 == 0: pts.append(f"{A:.2f}")
print("chart, A_t at t = 0, 0.1, ..., 2:", " ".join(pts))
print("chart, clock t:                ", " ".join(f"{j / 10:.2f}" for j in range(21)))
print("chart, clock 4t:               ", " ".join(f"{4 * j / 10:.2f}" for j in range(21)))
print("chart, t^2/2 at the same times:  ", " ".join(f"{(j / 10) ** 2 / 2:.2f}" for j in range(21)))
print("ALL CHECKS PASS")
