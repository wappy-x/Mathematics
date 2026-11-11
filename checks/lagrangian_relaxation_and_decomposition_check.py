# Lagrangian relaxation of a festival's shared sound crew.  Standard library only.
# Maximise profit (£k).  Each stage has a 6-hour evening; all acts share 16 crew-hours of rigging.
from fractions import Fraction as Fr
from itertools import product

C = 16
STAGES = [  # (act, stage hours, crew-hours, profit in £k)
    [("M1", 3, 2, 12), ("M2", 2, 6, 12), ("M3", 4, 6, 5)],
    [("T1", 4, 5, 8), ("T2", 3, 3, 7), ("T3", 3, 2, 9)],
    [("A1", 2, 6, 10), ("A2", 3, 4, 12), ("A3", 4, 2, 8)]]

def size(a, by_count): return 1 if by_count else a[1]
def cap(by_count): return 2 if by_count else 6   # variant: "at most two acts a stage"

def plans(acts, bc):                    # every booking of one stage that fits its evening
    out = []
    for m in range(8):
        pick = [a for i, a in enumerate(acts) if m >> i & 1]
        if sum(size(a, bc) for a in pick) <= cap(bc):
            out.append(("+".join(a[0] for a in pick) or "none", sum(a[3] for a in pick), sum(a[2] for a in pick)))
    return out

def choice(ps, lam, low=True):          # a stage's best plan at crew price lam; ties go to less crew
    return max(ps, key=lambda p: (p[1] - lam * p[2], -p[2] if low else p[2]))

def q(P, lam):                          # the dual function: an upper bound for every lam >= 0
    return lam * C + sum(choice(ps, lam)[1] - lam * choice(ps, lam)[2] for ps in P)

def q_lp(st, bc, lam):                  # the same price on the LP relaxation: fractional knapsacks
    v = lam * C
    for s in st:
        room = Fr(cap(bc))
        for a in sorted(s, key=lambda a: -(a[3] - lam * a[2]) / size(a, bc)):
            if a[3] - lam * a[2] > 0 and room > 0:
                t = min(Fr(1), room / size(a, bc)); v += t * (a[3] - lam * a[2]); room -= t * size(a, bc)
    return v

def stage_corners(s, lam):              # check road: the best corner of one stage's LP region (hours rule)
    hrs = lambda p: sum(a[1] * x for a, x in zip(s, p))
    pts = [[Fr(m >> i & 1) for i in range(3)] for m in range(8)]
    pts += [p[:j] + [(6 - hrs(p[:j] + [0] + p[j + 1:])) / s[j][1]] + p[j + 1:] for p in pts for j in range(3)]
    return max(sum((a[3] - lam * a[2]) * x for a, x in zip(s, p)) for p in pts if all(0 <= x <= 1 for x in p) and hrs(p) <= 6)

def kinks(st, P, bc):                   # every price where a ranking or a sign can change
    out = {Fr(0)}
    for ps in P:
        out |= {Fr(a[1] - b[1], a[2] - b[2]) for a, b in product(ps, ps) if a[2] != b[2]}
    for a, b in product([a for s in st for a in s], repeat=2):
        d = a[2] * size(b, bc) - b[2] * size(a, bc)
        out |= {Fr(a[3], a[2])} | ({Fr(a[3] * size(b, bc) - b[3] * size(a, bc), d)} if d else set())
    return sorted(l for l in out if l >= 0)

def bounds(st, bc):
    P = [plans(s, bc) for s in st]
    feas = [t for t in product(*P) if sum(p[2] for p in t) <= C]
    lam_d = min(kinks(st, P, bc), key=lambda l: (q(P, l), l))
    lam_lp = min(kinks(st, P, bc), key=lambda l: (q_lp(st, bc, l), l))
    return P, feas, max(sum(p[1] for p in t) for t in feas), lam_d, q(P, lam_d), lam_lp, q_lp(st, bc, lam_lp)

P, feas, z_ip, lam_d, z_ld, lam_lp, z_lp = bounds(STAGES, False)
print("plans per stage", [len(ps) for ps in P], "; whole bookings within crew", len(feas))
for ps in P: print("  ", " ".join(f"{n}:{p}/{c}" for n, p, c in ps))
best = max(feas, key=lambda t: sum(p[1] for p in t))
print("road 1, enumeration: best", [p[0] for p in best], "profit", z_ip, "crew", sum(p[2] for p in best))
print("road 2, kinks of q: price", lam_d, "bound", z_ld)
dw, mix = Fr(z_ip), ""                  # road 3: master LP over whole plans, corner by corner
for t in product(*P):
    for s in range(3):
        for alt in P[s]:
            if alt[2] != t[s][2]:
                th = Fr(C - sum(p[2] for p in t), alt[2] - t[s][2])   # weight on alt using crew exactly
                v = sum(p[1] for p in t) + th * (alt[1] - t[s][1])      # ties: the last one found is kept
                if 0 < th < 1 and v >= dw: dw, mix = v, f"{[p[0] for p in t]} with {th} of {t[s][0]} swapped for {alt[0]}"
print("road 3, master LP over whole plans:", dw, "; one best blend", mix)

def subgradient(step, n=30):            # road 4: price steps from lam_0 = 0
    lam, top, rows = 0.0, float("inf"), []
    for k in range(n):
        x = [choice(ps, lam) for ps in P]
        crew = sum(p[2] for p in x); val = lam * C + sum(p[1] - lam * p[2] for p in x)
        top = min(top, val); rows.append((k, lam, crew, val, top))
        lam = max(0.0, lam - step(k) * (C - crew))
    return rows
rows = subgradient(lambda k: 0.5 / (k + 1))
for k, lam, crew, val, top in rows[:7] + rows[-1:]:
    print(f"road 4, k={k:2d} price {lam:.4f} crew {crew:2d} q {val:.4f} best bound {top:.4f}")
print("LP bound: price", lam_lp, "bound", z_lp)
qs, ls = [choice(ps, lam_d)[1] - lam_d * choice(ps, lam_d)[2] for ps in P], [stage_corners(s, lam_d) for s in STAGES]
print(f"at price {lam_d}, stage by stage: q {lam_d * C} + {' + '.join(map(str, qs))} = {lam_d * C + sum(qs)};",
      f"LP corners {lam_d * C} + {' + '.join(map(str, ls))} = {lam_d * C + sum(ls)}")
x_lp = {"M1": 1, "M2": Fr(7, 12), "T2": 1, "T3": 1, "A2": 1, "A3": Fr(3, 4)}   # a fractional booking
acts = {a[0]: a for s in STAGES for a in s}
lp_val = sum(t * acts[n][3] for n, t in x_lp.items()); lp_crew = sum(t * acts[n][2] for n, t in x_lp.items())
lp_hours = [sum(t * acts[n][1] for n, t in x_lp.items() if n[0] == s[0][0][0]) for s in STAGES]
print("LP certificate: profit", lp_val, "crew", lp_crew, "stage hours", " ".join(str(h) for h in lp_hours))
hi = [choice(ps, lam_d, False) for ps in P]
lo = [choice(ps, lam_d) for ps in P]
print("priced choice at", lam_d, ": high-crew ties", [p[0] for p in hi], sum(p[1] for p in hi), "crew",
      sum(p[2] for p in hi), "; low-crew ties", sum(p[1] for p in lo), "crew", sum(p[2] for p in lo))
fixes = [hi[:s] + [p] + hi[s + 1:] for s in range(3) for p in P[s]]
fix = max((t for t in fixes if sum(p[2] for p in t) <= C), key=lambda t: sum(p[1] for p in t))
print("repair, change one stage:", [p[0] for p in fix], "profit", sum(p[1] for p in fix), "crew", sum(p[2] for p in fix))
print(f"gaps over {z_ip}: Lagrangian {z_ld - z_ip} = {100.0 * float(z_ld - z_ip) / z_ip:.1f}%,",
      f"LP {z_lp - z_ip} = {100.0 * float(z_lp - z_ip) / z_ip:.1f}%")
print("drop the lam*C term:", z_ld - lam_d * C, "; constant step 0.5, bound after 30:", f"{subgradient(lambda k: 0.5)[-1][4]:.4f}")
_, _, ip1, l1, ld1, ll1, lp1 = bounds(STAGES, True)
print("variant, at most two acts a stage: best", ip1, "Lagrangian", ld1, "at", l1, "LP", lp1, "at", ll1)
for i in range(9):
    print(f"chart, price {i / 2:.1f}: q {float(q(P, Fr(i, 2))):.2f} LP {float(q_lp(STAGES, False, Fr(i, 2))):.2f}")
brute = [(sum(a[3] for s, m in zip(STAGES, ms) for i, a in enumerate(s) if m >> i & 1), ms) for ms in product(range(8), repeat=3)
         if sum(a[2] for s, m in zip(STAGES, ms) for i, a in enumerate(s) if m >> i & 1) <= C
         and all(sum(a[1] for i, a in enumerate(s) if m >> i & 1) <= 6 for s, m in zip(STAGES, ms))]
assert z_ip == max(brute)[0] and len(brute) == len(feas)     # 512 raw bit patterns agree
assert dw == z_ld                       # the dual meets the master LP over whole plans
assert lp_val == z_lp and lp_crew <= C and max(lp_hours) <= 6   # LP bound met by a feasible point
assert float(z_ld) <= rows[-1][4] < float(z_ld) + 0.01
assert z_ip < z_ld < z_lp and ld1 == lp1 and sum(p[1] for p in fix) == z_ip
assert all(q(P, l) >= z_ld for l in [Fr(k, 7) for k in range(50)])
assert all(q_lp(STAGES, False, Fr(i, 2)) == Fr(i, 2) * C + sum(stage_corners(s, Fr(i, 2)) for s in STAGES) for i in range(9))
print("try step 1/(k+1): best bound after 30", f"{subgradient(lambda k: 1.0 / (k + 1))[-1][4]:.4f}")
r3 = subgradient(lambda k: 0.3)
print(f"try constant step 0.3: prices visited {' '.join(sorted({f'{x[1]:.4f}' for x in r3}))}; best bound {r3[-1][4]:.4f}")
rf = subgradient(lambda k: -0.5 / (k + 1))   # the sign flipped: lam + step * (C - crew)
print(f"try flipped sign: highest price in 30 steps {max(x[1] for x in rf):.4f}; best bound {rf[-1][4]:.4f}")
a9 = [s if s[0][0] != "A1" else s[:2] + [("A3", 4, 2, 9)] for s in STAGES]   # A3 pays 9
_, _, ip2, l2, ld2, _, lp2 = bounds(a9, False)
print(f"try A3 pays 9: best {ip2}, price {l2}, Lagrangian {ld2} = {float(ld2):.2f}, LP {lp2} = {float(lp2):.2f}")
print("ALL CHECKS PASS")
