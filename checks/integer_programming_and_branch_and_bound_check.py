# Integer programs and branch and bound -- the check behind the card.  Standard library only.
# Choose 3 depot sites out of 12 to save the most van costs inside a lease budget.
NAMES = "ABCDEFGHIJKL"
LEASE = [60, 40, 110, 70, 60, 40, 60, 50, 90, 60, 110, 70]           # a_i, £k a year (synthetic)
SAVE = [145, 40, 240, 140, 115, 70, 70, 80, 125, 115, 110, 125]      # s_i, £k a year (synthetic)
N, P, EPS = 12, 3, 1e-9

def relax(fix, budget=200):
    """Best fractional plan, by checking every corner. fix maps a site to 0 or 1."""
    free = [i for i in range(N) if i not in fix]
    ones = [i for i in fix if fix[i] == 1]
    best, corners = None, 0
    for mask in range(1 << len(free)):                    # which free sites sit at 1
        on = [free[k] for k in range(len(free)) if mask >> k & 1]
        r = P - len(ones) - len(on)                       # depots still to place
        if r < 0:
            continue
        rest = [i for i in free if i not in on]
        left = budget - sum(LEASE[i] for i in ones + on)
        base = sum(SAVE[i] for i in ones + on)
        pts = [[]] if r == 0 and left >= 0 else []
        for u in range(len(rest)):                        # two sites share the last r depots
            for w in range(u + 1, len(rest)):
                i, j = rest[u], rest[w]
                if r > 0 and LEASE[i] != LEASE[j]:
                    xi = (left - LEASE[j] * r) / (LEASE[i] - LEASE[j])
                    if -EPS < xi < 1 + EPS and -EPS < r - xi < 1 + EPS:
                        pts.append([(i, xi), (j, r - xi)])
        for pt in pts:
            corners += 1
            v = base + sum(SAVE[i] * x for i, x in pt)
            if best is None or v > best[0] + EPS:
                best = (v, {i: 1.0 for i in ones + on} | {i: x for i, x in pt if x > EPS})
    return best[0] if best else None, best[1] if best else None, corners

def frac(x):                                              # most fractional site, or None
    f = [i for i in sorted(x) if EPS < x[i] < 1 - EPS]
    return max(f, key=lambda i: min(x[i], 1 - x[i])) if f else None

def show(x):
    return " ".join(f"{NAMES[i]}={x[i]:g}" for i in sorted(x))

def search(order, log):
    """Branch and bound. order 'best' opens the highest bound first; 'depth' dives, open-the-site first."""
    open_, inc, lps = [({}, float("inf"))], (-1.0, None), 0
    while open_:
        k = max(range(len(open_)), key=lambda t: open_[t][1]) if order == "best" else len(open_) - 1
        fix, _ = open_.pop(k)
        v, x, _ = relax(fix); lps += 1
        tag = " ".join(f"{NAMES[i]}={fix[i]}" for i in fix) or "root"
        if v is None:
            log.append(f"{order:<5} {tag:<8} no plan fits: pruned"); continue
        if v <= inc[0] + EPS:
            log.append(f"{order:<5} {tag:<8} bound {v:.1f} <= best {inc[0]:.0f}: pruned"); continue
        i = frac(x)
        if i is None:
            inc = (v, x); log.append(f"{order:<5} {tag:<8} bound {v:.1f} all whole: new best {show(x)}"); continue
        log.append(f"{order:<5} {tag:<8} bound {v:.1f} {show(x)} -> branch on {NAMES[i]}")
        open_ += [(fix | {i: 0}, v), (fix | {i: 1}, v)]
    return inc, lps

def brute(budget=200, pair_loss=0):
    best, fits = (-1, ""), 0
    for i in range(N):
        for j in range(i + 1, N):
            for k in range(j + 1, N):
                if LEASE[i] + LEASE[j] + LEASE[k] <= budget:
                    fits += 1
                    v = SAVE[i] + SAVE[j] + SAVE[k] - pair_loss * (i == 0 and j == 3)
                    best = max(best, (v, NAMES[i] + NAMES[j] + NAMES[k]))
    return best, fits

def terms(x, row):
    return " + ".join(f"{row[i] * x[i]:g}" for i in sorted(x)) + f" = {sum(row[i] * x[i] for i in x):g}"

print("site  ", " ".join(f"{c:>3}" for c in NAMES))
print("lease ", " ".join(f"{a:>3}" for a in LEASE))
print("saving", " ".join(f"{s:>3}" for s in SAVE))
# ---- road 1: the relaxation, every corner checked ----
z_lp, x_lp, corners = relax({})
print(f"relaxation: {corners} corners checked, best {z_lp:.1f} at {show(x_lp)}")
for tag, fix in (("root", {}), ("C=0", {2: 0}), ("C=1", {2: 1})):
    x = relax(fix)[1]
    print(f"{tag:<4} lease {terms(x, LEASE)}; saving {terms(x, SAVE)}")
# ---- road 2: a price certificate, y1 per depot and y2 per £k of lease (weak duality) ----
c, d = [i for i in sorted(x_lp) if EPS < x_lp[i] < 1 - EPS]        # the two split sites
y2 = (SAVE[c] - SAVE[d]) / (LEASE[c] - LEASE[d]); y1 = SAVE[c] - y2 * LEASE[c]
extra = [(i, SAVE[i] - y1 - y2 * LEASE[i]) for i in range(N) if SAVE[i] - y1 - y2 * LEASE[i] > EPS]
cert = P * y1 + 200 * y2 + sum(e for _, e in extra)
left = " ".join(f"{NAMES[i]} {e:g}" for i, e in extra)
print(f"price certificate: y1 = {y1:g}, y2 = {y2:g}; 3*y1 = {P * y1:g}, 200*y2 = {200 * y2:g}, leftovers {left}; bound {cert:.1f}")
# ---- road 3: every triple, against two search orders ----
(z_ip, trio), fits = brute()
log = []
(z_bb, x_bb), lps = search("best", log)
(z_df, x_df), lps_df = search("depth", log)
for line in log:
    print(line)
print(f"relaxations solved: best-first {lps}, depth-first {lps_df}")
print(f"brute force: {fits} of {N * (N - 1) * (N - 2) // 6} triples fit the budget, best {trio} = {z_ip}")
gap = z_lp - z_ip
print(f"integrality gap: {z_lp:.0f} - {z_ip} = {gap:.0f}, {100 * gap / z_ip:.2f}% of the integer best")
# ---- what breaks ----
near = [i for i in sorted(x_lp) if x_lp[i] >= 0.5]
down = [i for i in sorted(x_lp) if x_lp[i] > 1 - EPS]
print("round to nearest:", "".join(NAMES[i] for i in near), "lease", sum(LEASE[i] for i in near),
      "save", sum(SAVE[i] for i in near))
print("round down:", "".join(NAMES[i] for i in down), "depots", len(down), "save", sum(SAVE[i] for i in down))
greedy, spent = [], 0
for i in sorted(range(N), key=lambda i: -SAVE[i] / LEASE[i]):
    if len(greedy) < P and spent + LEASE[i] <= 200:
        greedy.append(i); spent += LEASE[i]
print("greedy by saving per £:", "".join(NAMES[i] for i in greedy), "lease", spent,
      "save", sum(SAVE[i] for i in greedy))
(z_ov, trio_ov), _ = brute(pair_loss=50)
print(f"A and D overlap (-50): ADL really {z_ip - 50}, true best {trio_ov} = {z_ov}")
# ---- try changing ----
for bud in (190, 210, 240):
    (zb, tb), _ = brute(bud)
    print(f"budget {bud}: relaxation {relax({}, bud)[0]:.1f}, integer best {tb} = {zb}")

assert y2 >= 0                                   # a negative budget price gives no ceiling
assert abs(z_lp - cert) < 1e-9                   # corners and prices agree on the bound
assert z_ip == z_bb == z_df                      # tree search meets brute force
assert z_lp >= z_ip and gap > 0                  # relaxation bounds the integer best from above
assert sum(LEASE[i] for i in near) > 200 and len(down) < P   # both roundings break a rule
assert lps < fits                                # the tree solved fewer problems than brute force checked
print("ALL CHECKS PASS")
