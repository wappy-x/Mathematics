# Random walks as circuits -- the check behind the card.  Standard library only.
# Six bike stations, seven two-way links.  A bike's trips are a random walk:
# each rider takes it to a neighbouring station picked at random.  Road 1 solves
# the circuit (every link a 1-ohm resistor) by Gaussian elimination; road 2
# reduces it by series and parallel rules; road 3 solves the first-step
# equations of the walk itself; road 4 rides the bike with a seeded generator.
NAMES = ["Market", "Park", "Library", "Hospital", "University", "Docks"]
LINKS = [(0, 1), (1, 5), (0, 2), (2, 3), (3, 5), (1, 4), (4, 5)]
M, D = 0, 5                                       # start station a, target b

def neighbours(n, links):
    nb = [[] for _ in range(n)]
    for x, y in links:
        nb[x].append(y); nb[y].append(x)
    return nb

def solve(A, rhs):                                # Gaussian elimination, partial pivoting
    k = len(rhs); A = [row[:] + [rhs[i]] for i, row in enumerate(A)]
    for c in range(k):
        p = max(range(c, k), key=lambda r: abs(A[r][c])); A[c], A[p] = A[p], A[c]
        for r in range(k):
            if r != c:
                f = A[r][c] / A[c][c]
                A[r] = [u - f * v for u, v in zip(A[r], A[c])]
    return [A[i][k] / A[i][i] for i in range(k)]

def voltages(nb, inject, ground):
    # Kirchhoff's current law at every node but the grounded one:
    # sum over links of (v_x - v_y) = current fed in at x.  Each link is 1 ohm.
    idx = [x for x in range(len(nb)) if x != ground]
    A = [[0.0] * len(idx) for _ in idx]
    for r, x in enumerate(idx):
        A[r][r] = float(len(nb[x]))
        for y in nb[x]:
            if y != ground: A[r][idx.index(y)] -= 1.0
    v = solve(A, [float(inject[x]) for x in idx])
    out = [0.0] * len(nb)
    for r, x in enumerate(idx): out[x] = v[r]
    return out

def r_eff(nb, a, b):                              # road 1: 1 amp in at a, out at b
    inject = [0] * len(nb); inject[a] = 1
    return voltages(nb, inject, b)[a]

def first_step(out, target):                      # road 3: t_x = 1 + average of t_y
    idx = [x for x in range(len(out)) if x != target]
    A = [[0.0] * len(idx) for _ in idx]
    for r, x in enumerate(idx):
        A[r][r] = 1.0
        for y in out[x]:
            if y != target: A[r][idx.index(y)] -= 1.0 / len(out[x])
    t = solve(A, [1.0] * len(idx))
    res = [0.0] * len(out)
    for r, x in enumerate(idx): res[x] = t[r]
    return res

MASK = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)

def ride(nb, rng, start, target):                 # trips until the bike first reaches target
    x, trips = start, 0
    while x != target:
        x = nb[x][rng.next() % len(nb[x])]; trips += 1
    return trips

nb = neighbours(6, LINKS)
m = len(LINKS)
R = r_eff(nb, M, D)
par = lambda r1, r2: r1 * r2 / (r1 + r2)
R_sp = par(1 + par(1, 1 + 1), 1 + 1 + 1)         # road 2: Park side, then Library side
deg = [len(z) for z in nb]
v_hit = voltages(nb, [deg[x] for x in range(6)], D)   # feed d(x) amps in everywhere, ground Docks
t_to_D = first_step(nb, D)
t_to_M = first_step(nb, M)
commute = t_to_D[M] + t_to_M[D]

N = 20000
rng = SplitMix64(2026)
s1 = s2 = q = 0
for _ in range(N):
    a = ride(nb, rng, M, D); b = ride(nb, rng, D, M)
    s1 += a; s2 += b; q += (a + b) ** 2
sim_go, sim_back, sim_c = s1 / N, s2 / N, (s1 + s2) / N
se = ((q / N - sim_c ** 2) / N) ** 0.5

# what breaks: a one-way lane, Market to Park only (no rider may go Park -> Market)
oneway = [z[:] for z in nb]; oneway[1].remove(M)
ow_go, ow_back = first_step(oneway, D)[M], first_step(oneway, M)[D]
# try changing: a dead-end station off Park; a direct Market-Docks link; no University-Docks link
spur = LINKS + [(1, 6)]
direct = LINKS + [(0, 5)]
cut = [e for e in LINKS if e != (4, 5)]

assert abs(R - 15 / 14) < 1e-12, "circuit solve vs the hand fraction 15/14"
assert abs(R_sp - R) < 1e-12, "series and parallel vs circuit solve"
assert abs(commute - 2 * m * R) < 1e-9, "walk commute time vs 2 m R_eff"
assert all(abs(v_hit[x] - t_to_D[x]) < 1e-9 for x in range(6)), "voltages vs hitting times"
assert abs(sim_c - commute) < 4 * se, "simulated round trip vs exact commute time"
assert abs((ow_go + ow_back) - 2 * m * R) > 10, "a one-way lane should break the identity"

f4 = lambda x: f"{x:.4f}"
print("stations n", 6, " links m", m)
print("degrees d(x)", " ".join(f"{NAMES[x]}={deg[x]}" for x in range(6)))
print("1 R_eff Market-Docks, circuit solve  ", f4(R))
print("2 R_eff by series and parallel       ", f4(R_sp), " (= 15/14 ohm)")
print("3 trips Market->Docks, first step    ", f4(t_to_D[M]))
print("3 trips Docks->Market, first step    ", f4(t_to_M[D]))
print("  commute time, sum of the two       ", f4(commute))
print("  commute time, 2 m R_eff            ", f4(2 * m * R))
print("voltages, d(x) amps in, Docks at 0 V:", " ".join(f"{NAMES[x][:3]} {v_hit[x]:.4f}" for x in range(6)))
print("hitting times to Docks, first step:  ", " ".join(f"{NAMES[x][:3]} {t_to_D[x]:.4f}" for x in range(6)))
print("hitting times to Market, first step: ", " ".join(f"{NAMES[x][:3]} {t_to_M[x]:.4f}" for x in range(6)))
print(f"4 simulated, {N} round trips, seed 2026")
print("  mean trips Market->Docks           ", f4(sim_go))
print("  mean trips Docks->Market           ", f4(sim_back))
print("  mean round trip                    ", f4(sim_c), " standard error", f4(se))
print("wrong: n stations for m links, 2nR   ", f4(2 * 6 * R))
print("wrong: drop the 2, m R               ", f4(m * R))
print("wrong: shortest route 2 links, 2m*2  ", f4(2 * m * 2))
print("wrong: twice Market->Docks           ", f4(2 * t_to_D[M]))
print("wrong: twice Docks->Market           ", f4(2 * t_to_M[D]))
print("broken: one-way lane, Market->Docks  ", f4(ow_go))
print("broken: one-way lane, Docks->Market  ", f4(ow_back))
print("broken: one-way lane, commute        ", f4(ow_go + ow_back), " circuit still says", f4(2 * m * R))
for label, (L, n) in zip(["dead-end station off Park", "direct Market-Docks link ", "no University-Docks link "],
                           [(spur, 7), (direct, 6), (cut, 6)]):
    nbt = neighbours(n, L); Rt = r_eff(nbt, M, D)
    c = first_step(nbt, D)[M] + first_step(nbt, M)[D]
    assert abs(c - 2 * len(L) * Rt) < 1e-9, "try network: walk commute time vs 2 m R_eff"
    print("try:", label, " m", len(L), " R_eff", f4(Rt), " commute", f4(c))
print("figure, Market 40 120, Park 150 70, University 250 40, Docks 320 120, Library 120 190, Hospital 240 190")
print("ALL CHECKS PASS")
