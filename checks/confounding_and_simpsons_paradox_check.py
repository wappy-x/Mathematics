# Confounding and Simpson's paradox -- the check behind the card.  Standard
# library only.  Data: Berkeley graduate admissions, autumn 1973, the six
# largest departments (Bickel, Hammel and O'Connell, Science, 1975).
# Roads: counting against mix-weighted averages; the standardised gap by
# formula against reweighting all 4,526 applicant records; the bias formula
# against a seeded simulation of a world where sex has no effect at all.
from math import sqrt

DEPTS = [("A", 512, 825, 89, 108), ("B", 353, 560, 17, 25), ("C", 120, 325, 202, 593),
         ("D", 138, 417, 131, 375), ("E", 53, 191, 94, 393), ("F", 22, 373, 24, 341)]
KINDS = {"open": "AB", "selective": "CDEF"}      # admit over 0.6, and under 0.4

def se(p, n, q, m):                              # standard error of a gap in two rates
    return sqrt(p * (1 - p) / n + q * (1 - q) / m)

def table(groups):                               # counts per stratum: [am, nm, aw, nw]
    return {k: [sum(r[i] for r in DEPTS if r[0] in v) for i in range(1, 5)] for k, v in groups.items()}

six = table({r[0]: r[0] for r in DEPTS})
two = table(KINDS)
pool = table({"all six": "ABCDEF"})["all six"]
N = pool[1] + pool[3]
print("stratum     men admitted/applied  women admitted/applied  gap w-m, points (SE)  share of pool")
for k, (am, nm, aw, nw) in list(six.items()) + list(two.items()) + [("all six", pool)]:
    rm, rw = am / nm, aw / nw
    print(f"{k:<10} {am:>5}/{nm:<5} {rm:.4f}   {aw:>5}/{nw:<5} {rw:.4f}   "
          f"{100 * (rw - rm):+6.1f} ({100 * se(rw, nw, rm, nm):.1f})         {(nm + nw) / N:.4f}")

# Road 1 against road 2: the pooled rate, counted, and as a mix-weighted average
p_m, p_w = pool[0] / pool[1], pool[2] / pool[3]
mix_m = {k: c[1] / pool[1] for k, c in two.items()}
mix_w = {k: c[3] / pool[3] for k, c in two.items()}
avg_m = sum(mix_m[k] * c[0] / c[1] for k, c in two.items())
avg_w = sum(mix_w[k] * c[2] / c[3] for k, c in two.items())
print(f"pooled rate by counting: men {p_m:.4f}, women {p_w:.4f}; by mix-weighted average: men {avg_m:.4f}, women {avg_w:.4f}")
bars = [100 * c[i] / c[i + 1] for c in two.values() for i in (0, 2)] + [100 * p_m, 100 * p_w]
print("bars, percent admitted:", ", ".join(f"{b:.1f}" for b in bars))
print(f"applicants {N}; share applying to open departments: men {mix_m['open']:.4f}, women {mix_w['open']:.4f}; "
      f"to selective: men {mix_m['selective']:.4f}, women {mix_w['selective']:.4f}")

# The pooled gap split into a part inside departments and a part from the mix
inside = sum(mix_w[k] * (c[2] / c[3] - c[0] / c[1]) for k, c in two.items())
mixpart = sum((mix_w[k] - mix_m[k]) * c[0] / c[1] for k, c in two.items())
print(f"pooled gap, points: {100 * (p_w - p_m):+.2f} = inside departments {100 * inside:+.2f} + mix {100 * mixpart:+.2f}")

def standardised(strata):                        # road one: the formula, pool's mix for both
    s = [sum((c[1] + c[3]) / N * c[2 * g] / c[2 * g + 1] for c in strata.values()) for g in (0, 1)]
    v = sum(((c[1] + c[3]) / N) ** 2 * se(c[2] / c[3], c[3], c[0] / c[1], c[1]) ** 2 for c in strata.values())
    return s[0], s[1], sqrt(v)

def reweighted(strata):                          # road two: every applicant record, weighted
    recs = []                                    # (sex 0 men / 1 women, stratum, admitted)
    for k, (am, nm, aw, nw) in strata.items():
        recs += [(0, k, 1)] * am + [(0, k, 0)] * (nm - am) + [(1, k, 1)] * aw + [(1, k, 0)] * (nw - aw)
    n_sex = [sum(1 for r in recs if r[0] == g) for g in (0, 1)]
    n_k = {k: sum(1 for r in recs if r[1] == k) for k in strata}
    n_gk = {(g, k): sum(1 for r in recs if r[0] == g and r[1] == k) for g in (0, 1) for k in strata}
    out = []
    for g in (0, 1):                             # weight = P(stratum) / P(stratum | sex)
        wts = [(n_k[r[1]] / len(recs)) / (n_gk[(g, r[1])] / n_sex[g]) for r in recs if r[0] == g]
        adm = [r[2] for r in recs if r[0] == g]
        out.append(sum(w * a for w, a in zip(wts, adm)) / sum(wts))
    return out

for name, strata in (("two kinds", two), ("six departments", six)):
    sm, sw, sd = standardised(strata)
    rm, rw = reweighted(strata)
    print(f"standardised, {name}: men {sm:.4f}, women {sw:.4f}, gap {100 * (sw - sm):+.1f} points (SE {100 * sd:.1f}); "
          f"reweighted records: men {rm:.4f}, women {rw:.4f}")
    assert abs(sm - rm) < 1e-12 and abs(sw - rw) < 1e-12        # formula against records
s2m, s2w, _ = standardised(two)
s6m, s6w, s6se = standardised(six)

# A world where sex has no effect: admission depends on the department kind only
r_open = (two["open"][0] + two["open"][2]) / (two["open"][1] + two["open"][3])
r_sel = (two["selective"][0] + two["selective"][2]) / (two["selective"][1] + two["selective"][3])
w_pool = (two["selective"][1] + two["selective"][3]) / N
bias = (mix_w["selective"] - mix_m["selective"]) * (r_sel - r_open)
print(f"department rates, both sexes: open {r_open:.4f}, selective {r_sel:.4f}; pool's selective share {w_pool:.4f}")
print(f"bias formula, no-sex-effect world: ({mix_w['selective']:.4f} - {mix_m['selective']:.4f}) x "
      f"({r_sel:.4f} - {r_open:.4f}) = {100 * bias:+.2f} points")

M64 = (1 << 64) - 1
state = 20260929                                 # SplitMix64, seed stated
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def world(sel_share, n):                         # returns [adm, n] per (sex, kind)
    c = {(g, k): [0, 0] for g in (0, 1) for k in (0, 1)}
    for g in (0, 1):
        for _ in range(n):
            k = 1 if uniform() < sel_share[g] else 0
            c[(g, k)][1] += 1
            c[(g, k)][0] += 1 if uniform() < (r_sel if k else r_open) else 0
    return c

def gap(c, kinds):                               # women minus men, and its SE
    a = [sum(c[(g, k)][0] for k in kinds) for g in (0, 1)]
    n = [sum(c[(g, k)][1] for k in kinds) for g in (0, 1)]
    return a[1] / n[1] - a[0] / n[0], se(a[1] / n[1], n[1], a[0] / n[0], n[0])

NSIM = 100000
print(f"simulation: SplitMix64, seed {state}, {NSIM} applicants of each sex per world")
chosen = world((mix_m["selective"], mix_w["selective"]), NSIM)
coin = world((w_pool, w_pool), NSIM)
for label, c in (("sexes choose as at Berkeley", chosen), ("department by lottery", coin)):
    g_all, s_all = gap(c, (0, 1)); g_o, s_o = gap(c, (0,)); g_s, s_s = gap(c, (1,))
    print(f"  {label}: pooled gap {100 * g_all:+.2f} (SE {100 * s_all:.2f}); inside open {100 * g_o:+.2f} "
          f"(SE {100 * s_o:.2f}); inside selective {100 * g_s:+.2f} (SE {100 * s_s:.2f})")
    assert abs(g_o) < 4 * s_o and abs(g_s) < 4 * s_s            # no sex effect inside
    assert abs(g_all - (bias if c is chosen else 0.0)) < 4 * s_all

# A second world with the same pooled table and the opposite story inside
alt = {"open": [865, 1385, 400, 800], "selective": [333, 1306, 157, 1035]}
alt_pool = [sum(c[i] for c in alt.values()) for i in range(4)]
print(f"second world: women open 400/800 {400 / 800:.4f}, selective 157/1035 {157 / 1035:.4f}; "
      f"pooled women {alt_pool[2]}/{alt_pool[3]}, men {alt_pool[0]}/{alt_pool[1]}")
print("  gaps inside, points: " + ", ".join(f"{k} {100 * (c[2] / c[3] - c[0] / c[1]):+.1f}" for k, c in alt.items()))
assert alt_pool == pool and all(c[2] / c[3] < c[0] / c[1] for c in alt.values())
assert all(c[2] / c[3] > c[0] / c[1] for c in two.values()) and p_w < p_m   # the reversal

unweighted = sum(c[2] / c[3] - c[0] / c[1] for c in six.values()) / 6
print(f"what breaks, points: pooled gap read as bias {100 * (p_w - p_m):+.1f} (SE {100 * se(p_w, pool[3], p_m, pool[1]):.1f}); "
      f"two kinds {100 * (s2w - s2m):+.1f}; unweighted mean of six gaps {100 * unweighted:+.1f}; "
      f"six departments {100 * (s6w - s6m):+.1f}")
assert abs(inside + mixpart - (p_w - p_m)) < 1e-12 and abs(avg_m - p_m) < 1e-12 and abs(avg_w - p_w) < 1e-12

X = lambda s: 50 + 280 * s                         # figure: x = share applying to selective
Y = lambda r: 190 - 170 * r                        # y = admission rate, 0 at 190, 1 at 20
rates = {g: [two[k][2 * g] / two[k][2 * g + 1] for k in ("open", "selective")] for g in (0, 1)}
print(f"figure, men line ({X(0):.1f},{Y(rates[0][0]):.1f})-({X(1):.1f},{Y(rates[0][1]):.1f}); "
      f"women line ({X(0):.1f},{Y(rates[1][0]):.1f})-({X(1):.1f},{Y(rates[1][1]):.1f}); "
      f"men pooled ({X(mix_m['selective']):.1f},{Y(p_m):.1f}); women pooled ({X(mix_w['selective']):.1f},{Y(p_w):.1f})")
print("ALL CHECKS PASS")
