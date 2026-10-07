# Measurable functions -- the check behind the card.  Standard library only;
# fractions keeps every weight exact.  Four parcels on a belt scale weigh 1.3,
# 1.8, 2.2 and 3.6 kg.  Part 1 lists every sigma-algebra on four parcels and
# tests measurability three ways against a count by formula.  Part 2 asks the
# weight questions of the full record and of a log of rounded readings.  Part 3
# checks the preimage formulas on the line at exact rational points.
from fractions import Fraction as Fr
from math import floor, ceil

N, FULL = 4, 15
W = [Fr(13, 10), Fr(18, 10), Fr(22, 10), Fr(36, 10)]

def show(m): return "{" + ", ".join(f"p{i + 1}" for i in range(N) if m >> i & 1) + "}"
def kg(x): return f"{float(x):.3f}".rstrip("0").rstrip(".")
def yn(c): return "yes" if c else "no"
def pre(f, test): return sum(1 << i for i in range(N) if test(f[i]))    # preimage, as a bit mask
def rnd(x): return floor(x + Fr(1, 2))              # nearest whole kg, halves round up
def mem(fam): return [a for a in range(16) if fam >> a & 1]

def is_sigma(fam):                                  # fam: 16 bits, bit a set when set a is in
    ms = mem(fam)
    return fam & 1 and all(fam >> (FULL ^ a) & 1 for a in ms) and all(fam >> (a | b) & 1 for a in ms for b in ms)

def close(gens):                                    # complements and unions until nothing changes
    fam = {0, FULL} | set(gens)
    while True:
        new = fam | {FULL ^ a for a in fam} | {a | b for a in fam for b in fam}
        if new == fam: return sum(1 << a for a in fam)
        fam = new

def atoms(fam):                                     # the smallest member holding each parcel
    out = []
    for i in range(N):
        at = FULL
        for a in mem(fam):
            if a >> i & 1: at &= a
        if at not in out: out.append(at)
    return out

def by_definition(f, fam):                          # every set of values: 8 of them for 3 values
    vals = sorted(set(f))
    return all(fam >> pre(f, lambda v: v in [vals[j] for j in range(len(vals)) if s >> j & 1]) & 1
               for s in range(1 << len(vals)))
def by_threshold(f, fam, grid):                     # only the questions "below a?"
    return all(fam >> pre(f, lambda v: v < a) & 1 for a in grid)
def by_atoms(f, fam):                               # constant on every atom
    return all(len({f[i] for i in range(N) if at >> i & 1}) == 1 for at in atoms(fam))

# ---- part 1: every sigma-algebra on four parcels, every map to 1, 2 or 3 kg ----
sigmas = [fam for fam in range(1 << 16) if is_sigma(fam)]
maps = [(a, b, c, d) for a in (1, 2, 3) for b in (1, 2, 3) for c in (1, 2, 3) for d in (1, 2, 3)]
grid = [Fr(k, 4) for k in range(-2, 18)]
c_def = sum(by_definition(f, s) for s in sigmas for f in maps)
c_thr = sum(by_threshold(f, s, grid) for s in sigmas for f in maps)
c_atm = sum(by_atoms(f, s) for s in sigmas for f in maps)
S = [[1]]                                           # Stirling numbers: S(n, k) = k S(n-1, k) + S(n-1, k-1)
for n in range(1, N + 1):
    S.append([0] + [k * (S[n - 1][k] if k < n else 0) + S[n - 1][k - 1] for k in range(1, n + 1)])
by_k = {k: [s for s in sigmas if len(atoms(s)) == k] for k in range(1, N + 1)}
print(f"four parcels: {1 << 16} families searched, sigma-algebras {len(sigmas)}, Stirling sum {sum(S[N])}, maps {len(maps)}")
print("atoms k | sigma-algebras | Stirling S(4,k) | measurable maps to {1,2,3} in each")
for k in range(1, N + 1):
    per = sorted({sum(by_definition(f, s) for f in maps) for s in by_k[k]})
    print(f"      {k} | {len(by_k[k]):14} | {S[N][k]:15} | {per} (3^{k} = {3 ** k})")
stir = sum(S[N][k] * 3 ** k for k in range(1, N + 1))
print(f"measurable (sigma-algebra, map) pairs: definition {c_def}, threshold {c_thr}, atoms {c_atm}, formula {stir}")

# ---- part 2: the belt scale, the full record and the rounded log ----
R = [rnd(w) for w in W]
log = close([pre(R, lambda v, a=a: v < a) for a in range(0, 6)])
flog = close([pre([floor(w) for w in W], lambda v, a=a: v < a) for a in range(0, 6)])
full = (1 << 16) - 1
print(f"full record: {len(mem(full))} sets; ", end="")
print("weights " + ", ".join(f"p{i + 1} {kg(w)}" for i, w in enumerate(W)) + " kg; rounded readings " + str(R))
print(f"rounded log: {len(mem(log))} sets, atoms " + " | ".join(show(a) for a in atoms(log)) + f"; a sigma-algebra: {yn(log in sigmas)}")
for a in (Fr(3, 2), Fr(2), Fr(5, 2)):
    q = pre(W, lambda v: v < a)
    print(f"question 'under {kg(a)} kg': parcels {show(q)}; full record {yn(full >> q & 1)}; rounded log {yn(log >> q & 1)}")
print(f"W measurable for the full record: {yn(by_threshold(W, full, grid))}; for the rounded log: {yn(by_threshold(W, log, grid))}")
print(f"R measurable for the full record: {yn(by_threshold(R, full, grid))}; for the rounded log: {yn(by_threshold(R, log, grid))}")
agree = sum(pre(R, lambda v: v < a) == pre(W, lambda v: v < ceil(a) - Fr(1, 2)) for a in grid)
print(f"{{R < 2}} = {show(pre(R, lambda v: v < 2))}, and {{W < 1.5}} = {show(pre(W, lambda v: v < Fr(3, 2)))}; "
      f"{{R < a}} = {{W < ceil(a) - 0.5}} at {agree} of {len(grid)} thresholds")
st = [show(pre(W, lambda v: v < Fr(11, 5) + Fr(1, n))) for n in (1, 10, 1000)]
eq = pre(W, lambda v: v <= Fr(11, 5)) & (FULL ^ pre(W, lambda v: v < Fr(11, 5)))
print(f"{{W < 2.2 + 1/n}} at n = 1, 10, 1000: {', '.join(st)}; {{W = 2.2}} = {show(eq)}")
ind = sum(by_threshold([A >> i & 1 for i in range(N)], log, grid) == bool(log >> A & 1) for A in range(16))
print(f"indicator of A measurable for the log exactly when A is in it: {ind} of 16 sets, {len(mem(log))} measurable")

# ---- part 3: preimages on the line, at exact rational points ----
xs = [Fr(k, 16) for k in range(-16, 81)] + [Fr(2 * k + 1, 2) + e for k in range(-1, 5) for e in (Fr(-1, 1000), Fr(1, 1000))]
ts = [Fr(k, 8) for k in range(-8, 33)]
r_ok = sum((rnd(x) < a) == (x < ceil(a) - Fr(1, 2)) for x in xs for a in ts)
d_ok = sum((abs(x - 2) < a) == (a > 0 and 2 - a < x < 2 + a) for x in xs for a in ts)
print(f"line: {len(xs)} points x {len(ts)} thresholds = {len(xs) * len(ts)} pairs")
print(f"  round(x) < a  iff  x < ceil(a) - 0.5          : {r_ok} pairs agree")
print(f"  |x - 2| < a   iff  2 - a < x < 2 + a (a > 0)  : {d_ok} pairs agree")
print(f"  round jumps at 1.5: {rnd(Fr(3, 2) - Fr(1, 1000))} at 1.499, {rnd(Fr(3, 2))} at 1.5; still {{round < 2}} = (-inf, 1.5)")

# ---- what breaks ----
fl = [pre(W, lambda v, a=a: v < a) for a in range(1, 5)]
print(f"break 1, floor log, whole thresholds only: {{W < 1}}..{{W < 4}} all in it: {yn(all(flog >> q & 1 for q in fl))}; "
      f"{{W < 1.5}} = {show(pre(W, lambda v: v < Fr(3, 2)))} in it: {yn(flog >> pre(W, lambda v: v < Fr(3, 2)) & 1)}")
print(f"break 2, W against the rounded log: {{W < 2}} = {show(pre(W, lambda v: v < 2))} settled: {yn(log >> pre(W, lambda v: v < 2) & 1)}")
print(f"break 3, 'jumps, so not measurable': {{round < 2}} is the ray below {kg(ceil(Fr(2)) - Fr(1, 2))}, a Borel set")
print("figure, x = 40 + 70 w, y = 200 - 40 v; step ends " + ", ".join(str(40 + 70 * Fr(2 * k + 1, 2)) for k in range(4))
      + "; levels 1-4 at " + ", ".join(str(200 - 40 * v) for v in range(1, 5)) + "; parcels at " + ", ".join(str(40 + 70 * w) for w in W))
assert len(sigmas) == sum(S[N]) == 15                           # search against Stirling/Bell
assert c_def == c_thr == c_atm == stir == 309                    # three tests and a formula agree
assert r_ok == d_ok == len(xs) * len(ts) and agree == len(grid)  # preimage formulas on the line
assert not log >> pre(W, lambda v: v < 2) & 1 and log >> pre(W, lambda v: v < Fr(5, 2)) & 1 and ind == 16
assert by_threshold(R, log, grid) and not by_threshold(W, log, grid)  # R settled by the log, W not
print("ALL CHECKS PASS")
