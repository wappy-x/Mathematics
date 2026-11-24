# Burkholder-Davis-Gundy -- the check behind the card.  Standard library only.
# House example: M_t = int_0^t B dB = (B_t^2 - t)/2 on [0, 1], a fair game whose
# clock is <M>_t = int_0^t B_s^2 ds.  Roads: exact Gaussian moments by algebra and
# by Simpson's rule; 10,000 simulated paths of left-point Ito sums; the closed
# form (B_t^2 - t)/2 along the same paths; the clock as M's summed squared steps.
# The same paths read every 4th step show how low the grid reads the peak.
import math
PATHS, STEPS, SEED, PS = 10000, 1000, 20261123, (0.5, 1, 2, 3, 4)
MASK, DT = (1 << 64) - 1, 1.0 / STEPS
state, spare = SEED, []
def uniform():  # SplitMix64, a uniform number strictly between 0 and 1
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
def normal():  # Box-Muller, both outputs used
    if spare: return spare.pop()
    r, a = math.sqrt(-2.0 * math.log(uniform())), 2.0 * math.pi * uniform()
    spare.append(r * math.sin(a)); return r * math.cos(a)
def simpson(f, lo, hi, n=4000):
    h = (hi - lo) / n
    return h / 3 * sum((1 if k in (0, n) else 4 if k % 2 else 2) * f(lo + k * h) for k in range(n + 1))
def gauss_moment(f): return simpson(lambda z: f(z) * math.exp(-z * z / 2) / math.sqrt(2 * math.pi), -12, 12)
def bdg_upper(p): return (p * (p - 1) / 2 * (p / (p - 1)) ** p) ** (p / 2)  # Ito + Doob + Hoelder
def mean_se(xs):
    m = sum(xs) / len(xs)
    return m, math.sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / len(xs))

# ---- road 1: exact moments ----
EC1, EC2 = 0.5, 0.25 + 2 * (1 / 6)            # E<M>_1 = int s ds; E<M>_1^2 = int int (su + 2 min^2)
EM2, EM4 = (3 - 2 + 1) / 4, (105 - 60 + 18 - 4 + 1) / 16   # E((Z^2-1)/2)^k from normal moments
sm2, sm4 = gauss_moment(lambda z: ((z * z - 1) / 2) ** 2), gauss_moment(lambda z: ((z * z - 1) / 2) ** 4)
print(f"exact  E<M>_1 = {EC1:.6f}   E<M>_1^2 = {EC2:.6f}   E M_1^2 = {EM2:.6f}   E M_1^4 = {EM4:.6f}")
print(f"Simpson over the bell curve:          E M_1^2 = {sm2:.6f}   E M_1^4 = {sm4:.6f}")
assert abs(sm2 - EM2) < 1e-9 and abs(sm4 - EM4) < 1e-9

# ---- road 2: 10,000 paths, Ito sums on 1,000 steps ----
peak, clock, end, gap, qvgap, atpeak, ends4, peakc, peak4 = [], [], [], [], [], [], [], [], []
for _ in range(PATHS):
    b = m = c = qv = top = topc = top4 = c_at = 0.0
    for k in range(STEPS):
        db = normal() * math.sqrt(DT)
        dm = b * db                            # holding b, chosen before the step
        c += b * b * DT; qv += dm * dm; b += db; m += dm
        if abs(m) > top: top, c_at = abs(m), c
        if k % 4 == 3: top4 = max(top4, abs(m))   # the same path, read every 4th step
        topc = max(topc, abs((b * b - (k + 1) * DT) / 2))
    peak.append(top); clock.append(c); end.append(m); gap.append(abs(topc - top))
    qvgap.append(abs(qv - c)); atpeak.append((top * top, c_at)); ends4.append(m ** 4)
    peakc.append(topc); peak4.append(top4)
sc, sc_se = mean_se(clock); se2, se2_se = mean_se([x * x for x in end])
sp2, sp2_se = mean_se([x * x for x in peak]); sp4, sp4_se = mean_se([x ** 4 for x in peak])
sc2, sc2_se = mean_se([x * x for x in clock]); spc = sum(x * x for x in peakc) / PATHS
sp2q = sum(x * x for x in peak4) / PATHS       # the peak read every 4th step: a coarser grid
ext, ext_se = mean_se([2 * x * x - y * y for x, y in zip(peak, peak4)])   # grid error ~ sqrt(step)
print(f"simulated E<M>_1  = {sc:.4f} +- {sc_se:.4f}   (exact 0.5)")
print(f"simulated E<M>_1^2 = {sc2:.4f} +- {sc2_se:.4f}   (exact 7/12)")
print(f"simulated E M_1^2 = {se2:.4f} +- {se2_se:.4f}   (exact 0.5)")
print(f"simulated E M_1^4 = {mean_se(ends4)[0]:.4f} +- {mean_se(ends4)[1]:.4f}   (exact 3.75)")
print(f"mean |sum of squared steps of M - clock| = {sum(qvgap) / PATHS:.5f}")
print(f"mean |peak from (B^2-t)/2 - peak from Ito sums| = {sum(gap) / PATHS:.5f}")
print(f"E sup M^2 from (B^2-t)/2 = {spc:.4f}, from Ito sums = {sp2:.4f}")
print(f"p = 2:  lower bound E<M>_1 = {EC1:.4f}   E sup M^2 = {sp2:.4f} +- {sp2_se:.4f}   upper bound 4 x 0.5 = {4 * EC1:.4f}")
print(f"        ratio E sup M^2 / E<M>_1 = {sp2 / EC1:.4f}")
print(f"grid: E sup M^2 read every 4th step = {sp2q:.4f}; continuous, 2 x {sp2:.4f} - {sp2q:.4f} = {ext:.4f} +- {ext_se:.4f}")
assert abs(sc - EC1) < 4 * sc_se and abs(se2 - EM2) < 4 * se2_se and abs(sc2 - EC2) < 4 * sc2_se
assert sum(qvgap) / PATHS < 2 * math.sqrt(DT) and sum(gap) / PATHS < 2 * math.sqrt(DT)
assert abs(spc - sp2) < math.sqrt(DT)          # same paths: the two forms differ by the grid's rounding
assert EC1 < sp2 - 4 * sp2_se and sp2 + 4 * sp2_se < 4 * EC1

# ---- every p: the peak against the clock ----
print("    p   E sup|M|^p   E <M>_1^(p/2)   ratio")
ratios = []
for p in PS:
    a = sum(x ** p for x in peak) / PATHS; c = sum(x ** (p / 2) for x in clock) / PATHS
    ratios.append(a / c); print(f"{p:5}   {a:10.4f}   {c:13.4f}   {a / c:5.3f}")
for p in (2, 3, 4): print(f"upper constant from the proof, p = {p}: C_p = {bdg_upper(p):.4f}")
print(f"p = 4:  E sup M^4 = {sp4:.4f} +- {sp4_se:.4f}   bound C_4 x 7/12 = {bdg_upper(4) * EC2:.4f}   Doob (4/3)^4 x 3.75 = {(4 / 3) ** 4 * EM4:.4f}")
print(f"chart, ratio by p: " + ", ".join(f"{r:.3f}" for r in ratios))
assert abs(bdg_upper(2) - 4) < 1e-12 and abs(bdg_upper(3) - (81 / 8) ** 1.5) < 1e-9   # hand forms
assert 1 < ratios[2] < 4 and ratios[3] < bdg_upper(3) and ratios[4] < bdg_upper(4) and sp4 < (4 / 3) ** 4 * EM4

# ---- what breaks ----
peak_at = sum(x for x, _ in atpeak) / PATHS; clock_at = sum(c for _, c in atpeak) / PATHS
print(f"mistake, endpoint for peak: E M_1^2 = {se2:.4f} against E sup M^2 = {sp2:.4f}")
print(f"mistake, isometry at the time of the peak: E M^2 = {peak_at:.4f} but E<M> = {clock_at:.4f}")
drift = EM2 + 2.0 ** 2                          # X = M + 2t: same clock, E X_1^2 = 0.5 + 4
print(f"mistake, a drift 2t added, same clock: E X_1^2 = {drift:.4f}, above the bound {4 * EC1:.4f}")
bad = [(x * x, c) for x, c in zip(peak, clock) if x * x > 4 * c]
print(f"mistake, path by path: {len(bad)} of {PATHS} paths have sup M^2 > 4 <M>_1")
assert peak_at > clock_at + 0.1 and se2 < sp2 - 0.1 and len(bad) > 0
print("ALL CHECKS PASS")
