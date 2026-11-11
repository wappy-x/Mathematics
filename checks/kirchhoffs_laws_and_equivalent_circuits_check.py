# Kirchhoff's laws and equivalent circuits -- the check behind the card.  Standard library only.
# A 12 V battery, three resistors and a 6-ohm lamp.  Every number quoted on the card is printed here.
# Roads to the lamp: node voltages by elimination, loop currents by elimination, relaxation,
# and the Thevenin/Norton pair, found by open/short tests, by a test current and by hand rules.

VS, R1, R2, R3, RL = 12.0, 2.0, 6.0, 1.5, 6.0     # volts, then ohms
GND, TOP, A, B = 0, 1, 2, 3                        # ground, battery top, node A, node B (lamp top)

def solve(M, s):                                   # Gaussian elimination, partial pivoting
    n = len(s)
    M = [row[:] + [s[i]] for i, row in enumerate(M)]
    for k in range(n):
        p = max(range(k, n), key=lambda i: abs(M[i][k]))
        M[k], M[p] = M[p], M[k]
        for i in range(k + 1, n):
            m = M[i][k] / M[k][k]
            M[i] = [a - m * b for a, b in zip(M[i], M[k])]
    x = [0.0] * n
    for i in reversed(range(n)):
        x[i] = (M[i][n] - sum(M[i][j] * x[j] for j in range(i + 1, n))) / M[i][i]
    return x

def nodal(parts, fixed, inject=None):
    # parts: (node, node, ohms).  fixed: {node: volts}.  inject: {node: amps pushed in from outside}.
    inject = inject or {}
    free = sorted({n for a, b, _ in parts for n in (a, b)} - set(fixed))
    ix = {n: i for i, n in enumerate(free)}
    G = [[0.0] * len(free) for _ in free]
    s = [inject.get(n, 0.0) for n in free]
    for a, b, r in parts:                          # KCL at each free node, Ohm's law for each part
        g = 1.0 / r
        for here, there in ((a, b), (b, a)):
            if here in ix:
                G[ix[here]][ix[here]] += g
                if there in ix:
                    G[ix[here]][ix[there]] -= g
                else:
                    s[ix[here]] += g * fixed[there]
    v = dict(fixed)
    v.update(zip(free, solve(G, s)))
    return v, G, s

def circuit(vs=VS, r1=R1, r2=R2, r3=R3, rl=RL):
    parts = [(TOP, A, r1), (A, B, r3)]
    parts += [(A, GND, r2)] if r2 else []
    parts += [(B, GND, rl)] if rl else []
    return parts, {GND: 0.0, TOP: vs}

def show(name, v):
    print(f"{name:<44} {v:>11.6f}")

# ---- road 1: node voltages, G v = s, solved by elimination ----
v, G, s = nodal(*circuit())
print("conductances x 6: R1, R2, R3, lamp      " + "".join(f"{6 / r:6.1f}" for r in (R1, R2, R3, RL)))
for name, row, rhs in (("row A", G[0], s[0]), ("row B", G[1], s[1])):
    print(f"nodal matrix x 6, {name}            {6*row[0]:8.3f} {6*row[1]:8.3f} | {6*rhs:7.3f}")
m = 6 * G[1][0] / (6 * G[0][0])
print(f"after row B - ({m:.1f}) x row A               {0.0:8.3f} {6*G[1][1] - m*6*G[0][1]:8.3f} | {6*s[1] - m*6*s[0]:7.3f}")
VA, VB = v[A], v[B]
show("1 node voltages: V_A", VA); show("1 node voltages: V_B", VB)
I1, I2, I3, IL = (VS - VA) / R1, VA / R2, (VA - VB) / R3, VB / RL
show("current through R1 (the battery)", I1); show("current through R2", I2)
show("current through R3", I3); show("current through the lamp", IL)
show("KCL at A: out through R2 and R3", I2 + I3)

# ---- road 2: loop currents J1 (left loop), J2 (right loop), KVL in each ----
LOOP = [[R1 + R2, -R2], [-R2, R2 + R3 + RL]]
for name, row, rhs in (("row 1", LOOP[0], VS), ("row 2", LOOP[1], 0.0)):
    print(f"loop matrix, {name}                 {row[0]:8.3f} {row[1]:8.3f} | {rhs:7.3f}")
J1, J2 = solve(LOOP, [VS, 0.0])
show("2 loop currents: J1", J1); show("2 loop currents: J2 (the lamp)", J2)
show("KVL, left loop: drops on R1 and R2", J1 * R1 + (J1 - J2) * R2)
show("KVL, right loop: drop on R2", (J1 - J2) * R2); show("KVL, right loop: drops on R3 and lamp", J2 * (R3 + RL))

# ---- road 3: relaxation -- each node becomes the conductance-weighted average of its neighbours ----
g1, g2, g3, gl = 1 / R1, 1 / R2, 1 / R3, 1 / RL
ra, rb = 0.0, 0.0
for sweep in range(200):
    ra = (g1 * VS + g3 * rb) / (g1 + g2 + g3)
    rb = (g3 * ra) / (g3 + gl)
show("3 relaxation, 200 sweeps: V_B", rb)

# ---- power: what the battery gives equals what the parts burn ----
P_batt = VS * I1
P_parts = I1**2 * R1 + I2**2 * R2 + I3**2 * R3 + IL**2 * RL
show("battery power, watts", P_batt); show("sum of I^2 R over the four parts", P_parts)
show("lamp power, watts", IL**2 * RL)
show("power burned in the network, lamp aside", P_batt - IL**2 * RL)

# ---- the equivalent seen by the lamp, three ways ----
v_open, _, _ = nodal(*circuit(rl=0))                         # lamp unclipped
Voc = v_open[B]
parts, fixed = circuit(rl=0); fixed[B] = 0.0                 # lamp replaced by a wire
v_sc, _, _ = nodal(parts, fixed)
Isc = (v_sc[A] - 0.0) / R3
parts, fixed = circuit(vs=0.0, rl=0)                         # battery killed, 1 A pushed into B
v_test, _, _ = nodal(parts, fixed, {B: 1.0})
Vth_rule = VS * R2 / (R1 + R2)
Rth_rule = R1 * R2 / (R1 + R2) + R3
show("open-circuit voltage V_th", Voc); show("short-circuit current I_N", Isc)
show("R_th = V_th / I_N", Voc / Isc); show("R_th by 1 A test current, battery killed", v_test[B])
show("R1 || R2 = 2 x 6/(2+6)", R1 * R2 / (R1 + R2))
show("V_th by the divider 12 x 6/(2+6)", Vth_rule); show("R_th by rules (2 || 6) + 1.5", Rth_rule)
show("lamp current, Thevenin 9/(3+6)", Voc / (Rth_rule + RL))
show("lamp current, Norton 3 x 3/(3+6)", Isc * Rth_rule / (Rth_rule + RL))
show("power in the Thevenin 3 ohms at 1 A", (Voc / (Rth_rule + RL))**2 * Rth_rule)

# ---- swap the lamp: Thevenin formula against a fresh nodal solve ----
print("lamp ohms   amps, Thevenin   amps, full solve   lamp watts")
sweep_pts = []
for rl in (1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0):
    i_th = Voc / (Rth_rule + rl)
    i_full = nodal(*circuit(rl=rl))[0][B] / rl
    sweep_pts.append((i_th, i_full))
    print(f"{rl:9.1f} {i_th:16.6f} {i_full:18.6f} {i_th**2 * rl:12.6f}")

# ---- what breaks ----
bad_G = [[g1 + g2 - g3, g3], [-g3, g3 + gl]]                 # R3's current signed backwards at A
bad = solve(bad_G, [g1 * VS, 0.0])
show("wrong: R3 signed backwards at A, lamp amps", bad[1] / RL)
show("wrong: R1 + R2 taken in series, ohms", R1 + R2); show("wrong: R_th = 2 + 6 + 1.5, lamp amps", Voc / (R1 + R2 + R3 + RL))
show("wrong: R_th, battery a gap: 6 + 1.5", R2 + R3); show("wrong: battery killed as a gap, lamp amps", Voc / (R2 + R3 + RL))
show("wrong: V_th = 12 V, lamp amps", VS / (Rth_rule + RL)); show("cold lamp at switch-on, 0.6 ohm: amps", nodal(*circuit(rl=0.6))[0][B] / 0.6)

# ---- try changing ----
show("try: battery 24 V, lamp amps", nodal(*circuit(vs=24.0))[0][B] / RL)
show("try: R2 = 3 ohms, lamp amps", nodal(*circuit(r2=3.0))[0][B] / RL)
show("try: R2 removed, lamp amps", nodal(*circuit(r2=0))[0][B] / RL)
show("try: R2 removed, V_th", nodal(*circuit(r2=0, rl=0))[0][B]); show("try: R2 removed, R_th by 1 A test", nodal(*circuit(0.0, r2=0, rl=0), {B: 1.0})[0][B])

assert abs(VB - 6.0) < 1e-12 and abs(VA - 7.5) < 1e-12,  "nodal road vs the hand answer 7.5 V, 6 V"
assert abs(J2 - IL) < 1e-12 and abs(J1 - I1) < 1e-12,    "loop-current road vs node-voltage road"
assert abs(rb - VB) < 1e-9,                              "relaxation vs elimination"
assert abs(I1 - I2 - I3) < 1e-12,                        "KCL at A, on the node road"
assert abs(VS - J1 * R1 - (J1 - J2) * R2) < 1e-12,       "KVL round the left loop, on the loop road"
assert abs(P_batt - P_parts) < 1e-9,                     "power in equals power burned"
assert abs(Voc - Vth_rule) < 1e-12 and abs(Voc / Isc - Rth_rule) < 1e-12, "open/short tests vs hand rules"
assert abs(v_test[B] - Rth_rule) < 1e-12,                "test-current R_th vs hand rules"
assert all(abs(a - b) < 1e-12 for a, b in sweep_pts),    "Thevenin vs full solve for every lamp"
print("ALL CHECKS PASS")
