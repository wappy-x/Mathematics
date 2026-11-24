# Two-port networks and S-parameters -- the check behind the card.  Standard library only.
# A 3 dB pi attenuator for a 50 ohm system, then two of them in a row.  Every number on
# the card is printed here.  Road 1: the design formulas.  Road 2: multiply the three
# element ABCD matrices and convert to S.  Road 3: solve the circuit by Kirchhoff's node
# equations with a 50 ohm source and load.  Road 4: Z from open-circuit node solves,
# then S = (Z - Z0)(Z + Z0)^-1.  The cascade is checked by ABCD, by S algebra and by nodes.
from math import log10
Z0, DB = 50.0, 3.0                                   # ohms; attenuation in decibels

def design(db, z0):                                  # matched pi pad: shunt, series
    k = 10 ** (db / 20)                              # voltage ratio for db decibels
    return k, z0 * (k + 1) / (k - 1), z0 * (k * k - 1) / (2 * k)

def mul(p, q): return [[sum(p[i][k] * q[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
def inv(m):
    d = m[0][0] * m[1][1] - m[0][1] * m[1][0]
    return [[m[1][1] / d, -m[0][1] / d], [-m[1][0] / d, m[0][0] / d]]
def series(z): return [[1.0, z], [0.0, 1.0]]
def shunt(r): return [[1.0, 0.0], [1.0 / r, 1.0]]
def pad_abcd(rp, rs): return mul(mul(shunt(rp), series(rs)), shunt(rp))
def abcd_to_s(m, z0):                                # (S11, S21, S12, S22) from (A, B, C, D)
    (a, b), (c, d) = m
    den = a + b / z0 + c * z0 + d
    return ((a + b / z0 - c * z0 - d) / den, 2 / den, 2 * (a * d - b * c) / den,
            (-a + b / z0 - c * z0 + d) / den)
def z_to_s(z, z0):
    s = mul([[z[0][0] - z0, z[0][1]], [z[1][0], z[1][1] - z0]],
            inv([[z[0][0] + z0, z[0][1]], [z[1][0], z[1][1] + z0]]))
    return s[0][0], s[1][0], s[0][1], s[1][1]
def solve(g, rhs):                                   # Gaussian elimination, any size
    n = len(rhs); m = [row[:] + [rhs[i]] for i, row in enumerate(g)]
    for c in range(n):
        for r in range(c + 1, n):
            f = m[r][c] / m[c][c]
            m[r] = [x - f * y for x, y in zip(m[r], m[c])]
    v = [0.0] * n
    for r in reversed(range(n)):
        v[r] = (m[r][n] - sum(m[r][j] * v[j] for j in range(r + 1, n))) / m[r][r]
    return v
def nodes(shunts, serie, g_src, g_load, inj):        # ladder: shunt R at each node
    n = len(shunts); g = [[0.0] * n for _ in range(n)]
    for i, r in enumerate(shunts): g[i][i] += 1 / r
    for i, r in enumerate(serie):
        g[i][i] += 1 / r; g[i + 1][i + 1] += 1 / r; g[i][i + 1] -= 1 / r; g[i + 1][i] -= 1 / r
    g[0][0] += g_src; g[-1][-1] += g_load
    return solve(g, [inj] + [0.0] * (n - 1))
def s_by_nodes(shunts, serie, z0):                   # source EMF 2 V: incident wave 1 V
    v = nodes(shunts, serie, 1 / z0, 1 / z0, 2.0 / z0)
    return v[0] - 1.0, v[-1], v
def z_by_nodes(shunts, serie):                       # 1 A in at a port, other port open
    a, b = nodes(shunts, serie, 0, 0, 1.0), nodes(shunts[::-1], serie[::-1], 0, 0, 1.0)
    return [[a[0], b[-1]], [a[-1], b[0]]]
def cascade_s(p, q):                                 # S algebra with the echo between
    e = 1 - p[3] * q[0]
    return p[0] + p[2] * p[1] * q[0] / e, p[1] * q[1] / e
def f(x): return f"{(0.0 if abs(x) < 5e-9 else x):.4f}"    # no "-0.0000"
def row(*xs): print(", ".join(xs))

k, rp, rs = design(DB, Z0)
row("design", f"K {f(k)}", f"shunt {rp:.2f} ohm", f"series {rs:.2f} ohm")
m = pad_abcd(rp, rs)
row("ABCD", *[f(x) for x in (m[0][0], m[0][1], m[1][0] * 1000, m[1][1])], f"AD-BC {f(m[0][0] * m[1][1] - m[0][1] * m[1][0])}")
s_abcd = abcd_to_s(m, Z0)
s11_n, s21_n, v = s_by_nodes([rp, rp], [rs], Z0)
z = z_by_nodes([rp, rp], [rs]); s_z = z_to_s(z, Z0); y = inv(z)
row("Z ohm", *[f(x) for x in (z[0][0], z[0][1], z[1][0], z[1][1])])
row("Y mS", *[f(1000 * x) for x in (y[0][0], y[0][1], y[1][0], y[1][1])])
row("Y from ABCD mS", f(1000 * m[1][1] / m[0][1]), f(-1000 / m[0][1]))
row("even odd ohm", f(z[0][0] + z[0][1]), f(z[0][0] - z[0][1]))
ze, zo = z[0][0] + z[0][1], z[0][0] - z[0][1]       # both ports driven alike, or opposite
row("even odd reflections", f((ze - Z0) / (ze + Z0)), f((zo - Z0) / (zo + Z0)), f"Ze Zo {f(ze * zo)} ohm^2")
row("ABCD to S", f"A+B/Z0 {f(m[0][0] + m[0][1] / Z0)}", f"C Z0+D {f(m[1][0] * Z0 + m[1][1])}",
    f"sum {f(m[0][0] + m[0][1] / Z0 + m[1][0] * Z0 + m[1][1])}")
row("S road 1", "S11 0.0000", f"S21 {f(1 / k)}")
for name, s in (("S road 2 ABCD", s_abcd), ("S road 4 Z", s_z)):
    row(name, *[f"{lab} {f(x)}" for lab, x in zip(("S11", "S21", "S12", "S22"), s)])
row("S road 3 nodes", f"S11 {f(s11_n)}", f"S21 {f(s21_n)}", f"V1 {f(v[0])} V", f"V2 {f(v[1])} V")
p_res = (v[0] ** 2 + v[1] ** 2) / rp + (v[0] - v[1]) ** 2 / rs
p_inc = 1.0 / Z0                                     # reference power of the 1 V wave; only ratios are printed
row("power share", f"to load {f(s21_n ** 2)}", f"in resistors {f(p_res / p_inc)}", f"from S {f(1 - s11_n ** 2 - s21_n ** 2)}")
row("0 dBm in, mW", f"to load {f(s21_n ** 2)}", f"shunt in {f(v[0] ** 2 / rp / p_inc)}",
    f"series {f((v[0] - v[1]) ** 2 / rs / p_inc)}", f"shunt out {f(v[1] ** 2 / rp / p_inc)}")
m2 = mul(m, m); c_abcd = abcd_to_s(m2, Z0); c_alg = cascade_s(s_abcd, s_abcd)
c_n = s_by_nodes([rp, rp / 2, rp], [rs, rs], Z0)
row("two pads ABCD", *[f(x) for x in (m2[0][0], m2[0][1], m2[1][0] * 1000, m2[1][1])])
row("two pads S21", f"ABCD {f(c_abcd[1])}", f"S algebra {f(c_alg[1])}", f"nodes {f(c_n[1])}", f"loss {-20 * log10(c_abcd[1]):.4f} dB")
row("two pads S11", f"ABCD {f(c_abcd[0])}", f"S algebra {f(c_alg[0])}", f"nodes {f(c_n[0])}")
# ---- what breaks ----
k6, rp6, rs6 = design(2 * DB, Z0)                    # 10 log used for a voltage ratio
row("wrong: 10 log", f"shunt {rp6:.2f} ohm", f"series {rs6:.2f} ohm", f"S21 {f(abcd_to_s(pad_abcd(rp6, rs6), Z0)[1])}")
ss = mul([[s_abcd[0], s_abcd[2]], [s_abcd[1], s_abcd[3]]], [[s_abcd[0], s_abcd[2]], [s_abcd[1], s_abcd[3]]])
row("wrong: S times S", f"S11 {f(ss[0][0])}", f"S21 {f(ss[1][0])}")
zz = z_to_s(mul(z, z), Z0)
row("wrong: Z times Z", f"S11 {f(zz[0])}", f"S21 {f(zz[1])}")
_, rp75, rs75 = design(DB, 75.0); s75 = abcd_to_s(pad_abcd(rp75, rs75), Z0)
c75 = abcd_to_s(mul(pad_abcd(rp75, rs75), pad_abcd(rp75, rs75)), Z0); c75a = cascade_s(s75, s75)
row("75 ohm pads in 50", f"S11 {f(s75[0])}", f"S21 {f(s75[1])}", f"product {f(s75[1] ** 2)}",
    f"true {f(c75[1])}", f"S algebra {f(c75a[1])}", f"loss {-20 * log10(c75[1]):.4f} dB")
gl = (75 - Z0) / (75 + Z0); gin = s_abcd[0] + s_abcd[2] * s_abcd[1] * gl / (1 - s_abcd[3] * gl)
a, b = m[0][0] * 75 + m[0][1], m[1][0] * 75 + m[1][1]   # input impedance by ABCD: (A RL + B)/(C RL + D)
row("75 ohm load", f"bare {f(gl)}", f"through pad {f(gin)}", f"Zin {f(a / b)} ohm", f"from Zin {f((a / b - Z0) / (a / b + Z0))}")
for d in (6.0, 10.0, 20.0):
    kk, p1, p2 = design(d, Z0); row(f"try {d:.0f} dB", f"shunt {p1:.2f} ohm", f"series {p2:.2f} ohm", f"S21 {f(1 / kk)}")
_, p1, p2 = design(DB, 75.0); row("try 75 ohm", f"shunt {p1:.2f} ohm", f"series {p2:.2f} ohm")
row("try three pads", f"S21 {f(abcd_to_s(mul(m2, m), Z0)[1])}", f"loss {-20 * log10(abcd_to_s(mul(m2, m), Z0)[1]):.4f} dB")
rr = abcd_to_s(pad_abcd(292.4, 17.6), Z0)
row("rounded 292.4 and 17.6", f"S11 {rr[0]:.6f}", f"S21 {f(rr[1])}")
row("figure", "pad x 120 to 300", "shunts at x 140 and 280", "ports at x 40 and 380")
assert abs(s11_n) < 1e-12 and abs(s_z[0]) < 1e-12 and abs(s_abcd[0]) < 1e-12
assert abs(s21_n - 1 / k) < 1e-12 and abs(s_z[1] - s_abcd[1]) < 1e-12 and abs(s_abcd[2] - s21_n) < 1e-12
assert abs(y[0][0] - m[1][1] / m[0][1]) < 1e-12 and abs(y[1][0] + 1 / m[0][1]) < 1e-12
assert abs(p_res / p_inc - (1 - s21_n ** 2)) < 1e-12
assert abs(c_abcd[1] - c_n[1]) < 1e-12 and abs(c_alg[1] - c_n[1]) < 1e-12 and abs(c_abcd[1] - 10 ** (-6 / 20)) < 1e-12
assert abs(c75[1] - c75a[1]) < 1e-12 and abs(c75[1] - s75[1] ** 2) > 1e-4
assert abs(gin - (a / b - Z0) / (a / b + Z0)) < 1e-12
print("ALL CHECKS PASS")
