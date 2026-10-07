# Bayesian updating -- the check behind the card.  Standard library only.
# A new coin shows h = 7 heads in n = 10 flips.  theta is its unknown chance of
# heads.  Roads to the posterior: 11 candidate coins (Bayes' rule on a list),
# the exact integral by expanding the polynomial, a 4,000-cell grid, and a
# seeded simulation that keeps only the imaginary coins that also show 7 of 10.
from fractions import Fraction as Fr
from math import comb, log, exp, sqrt
N, H = 10, 7
T = N - H
LIK = lambda th, h=H, t=T: comb(h + t, h) * th ** h * (1 - th) ** t

M64 = (1 << 64) - 1
class SplitMix64:                               # small generator, same in Rust
    def __init__(self, seed): self.s = seed
    def unif(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

# road 1: eleven candidate coins, prior 1/11 each, Bayes' rule on a list
cand = [i / 10 for i in range(11)]
joint = [LIK(c) / 11 for c in cand]
ev11 = sum(joint)
post11 = [j / ev11 for j in joint]
print(f"coin: h = {H} heads in n = {N} flips; candidates 0.0 to 1.0, prior 1/11 each")
for c, j, p in zip(cand, joint, post11):
    print(f"list  theta={c:.1f}  likelihood={LIK(c):.6f}  prior*lik={j:.6f}  posterior={p:.4f}")
m11 = sum(c * p for c, p in zip(cand, post11))
g11 = sum(p for c, p in zip(cand, post11) if c > 0.5)
print(f"list  evidence={ev11:.6f}  mean={m11:.4f}  P(theta>0.5)={g11:.4f}")

# road 2: exact, expanding theta^7 (1-theta)^3 and integrating term by term
def poly(h, t):                                 # coefficients of theta^h (1-theta)^t
    return {h + k: Fr(comb(t, k) * (-1) ** k) for k in range(t + 1)}
def integ(cs, a, b, shift=0):                   # exact integral of theta^shift * poly
    return sum(c * (Fr(b) ** (p + shift + 1) - Fr(a) ** (p + shift + 1)) / (p + shift + 1)
               for p, c in cs.items())
cs = poly(H, T)
area = integ(cs, 0, 1)
ev_exact = comb(N, H) * area                    # flat prior f = 1
mean_exact = integ(cs, 0, 1, 1) / area
gt_exact = integ(cs, Fr(1, 2), 1) / area
sq_exact = integ(cs, 0, 1, 2) / area
sd_exact = sqrt(sq_exact - mean_exact ** 2)
print(f"exact area of theta^7(1-theta)^3 = {area}; evidence = {ev_exact} = {float(ev_exact):.6f}")
print(f"exact posterior = {1 / area} theta^7 (1-theta)^3; mean = {mean_exact} = {float(mean_exact):.4f}; "
      f"sd = {sd_exact:.4f}; P(theta>0.5) = {gt_exact} = {float(gt_exact):.4f}")
fair = sum(comb(N, j) for j in range(H, N + 1))
print(f"exact I(8,3) = {integ(cs, 0, 1, 1)}; a fair coin shows 7 or more heads in 10 with chance {fair}/1024 = {fair / 1024:.4f}")

# road 3: a fine grid, any prior, log scale so 1,000 flips do not underflow
def grid(logprior, h, t, cells=4000, lo=0.0, hi=1.0):
    w = (hi - lo) / cells
    th = [lo + (i + 0.5) * w for i in range(cells)]
    lw = [logprior(x) + h * log(x) + t * log(1 - x) for x in th]
    top = max(lw)
    wt = [exp(v - top) for v in lw]
    z = sum(wt)
    mean = sum(x * v for x, v in zip(th, wt)) / z
    sd = sqrt(sum((x - mean) ** 2 * v for x, v in zip(th, wt)) / z)
    gt = sum(v for x, v in zip(th, wt) if x > 0.5) / z
    return mean, sd, gt, z * w * exp(top)
flat = lambda x: 0.0
gm, gsd, ggt, garea = grid(flat, H, T)
print(f"grid  4000 cells: area = {garea:.8f} (1/1320 = {1 / 1320:.8f}); mean = {gm:.4f}; sd = {gsd:.4f}; P(theta>0.5) = {ggt:.4f}")

# road 4: simulate. Draw a coin theta from the flat prior, flip it 10 times,
# keep theta only when the flips show 7 heads.  Kept thetas follow the posterior.
rng, draws, kept = SplitMix64(20260929), 200000, []
for _ in range(draws):
    th = rng.unif()
    if sum(rng.unif() < th for _ in range(N)) == H:
        kept.append(th)
k = len(kept)
acc, acc_se = k / draws, sqrt(k / draws * (1 - k / draws) / draws)
sm = sum(kept) / k
ssd = sqrt(sum((x - sm) ** 2 for x in kept) / (k - 1))
sg = sum(x > 0.5 for x in kept) / k
print(f"sim   seed 20260929, {draws} coins, {k} show 7 heads: evidence {acc:.4f} (se {acc_se:.4f})")
print(f"sim   mean {sm:.4f} (se {ssd / sqrt(k):.4f}); sd {ssd:.4f}; P(theta>0.5) {sg:.4f} (se {sqrt(sg * (1 - sg) / k):.4f})")

# staged: 7 heads first then 3 tails, 3 tails first then 7 heads, one flip at a time
seqs = {"heads first": [1] * 7 + [0] * 3, "tails first": [0] * 3 + [1] * 7}
th, st = [(i + 0.5) / 4000 for i in range(4000)], []
for name, seq in seqs.items():
    wt = [1.0] * 4000
    for f in seq:
        wt = [v * (x if f else 1 - x) for v, x in zip(wt, th)]
        z = sum(wt)
        wt = [v / z for v in wt]                # today's posterior is tomorrow's prior
    st.append(sum(x * v for x, v in zip(th, wt)))
    print(f"staged {name}, renormalised after every flip: mean = {st[-1]:.4f}")

# figure: flat prior and posterior density at theta = 0, 0.1, ..., 1
print("figure, flat prior density 1.00 at every theta; posterior density 1320 theta^7 (1-theta)^3: " +
      ", ".join(f"{float(1 / area) * (i / 10) ** 7 * (1 - i / 10) ** 3:.2f}" for i in range(11)))

# the prior washes out: flat versus a sceptic, f proportional to (theta(1-theta))^10
lnf = lambda m: sum(log(j) for j in range(2, m + 1))
def exact_mean(a, h, t):                        # ratio of two integrals a!b!/(a+b+1)!
    return exp(lnf(a + h + 1) + lnf(a + t) - lnf(2 * a + h + t + 2)
               - lnf(a + h) - lnf(a + t) + lnf(2 * a + h + t + 1))
sceptic = lambda x: 10 * log(x * (1 - x))
print(f"sceptic prior density at 0.5: {21 * comb(20, 10) * 0.25 ** 10:.2f}; prior sd {sqrt(0.25 / 23):.4f}")
fl_row, sc_row = [], []
for n in (0, 10, 30, 100, 300, 1000):
    h = 7 * n // 10
    ef, es = exact_mean(0, h, n - h), exact_mean(10, h, n - h)
    gf, gs = grid(flat, h, n - h)[0], grid(sceptic, h, n - h)[0]
    fl_row.append(gf); sc_row.append(gs)
    print(f"washout n={n:4d} h={h:3d}: flat exact {ef:.4f} grid {gf:.4f}; sceptic exact {es:.4f} grid {gs:.4f}; gap {abs(ef - es):.4f}")
print("figure, washout means flat: " + ", ".join(f"{v:.2f}" for v in fl_row))
print("figure, washout means sceptic: " + ", ".join(f"{v:.2f}" for v in sc_row))

# what breaks
print(f"break 1, no division by the evidence: area under prior*lik = {float(ev_exact):.4f}; "
      f"P(theta>0.5) read off it = {float(ev_exact * gt_exact):.4f}, not {float(gt_exact):.4f}")
tm = grid(lambda x: 0.0, 700, 300, cells=4000, lo=0.4, hi=0.6)[0]
print(f"break 2, prior zero outside 0.4 to 0.6, then 700 heads in 1000: mean = {tm:.4f}, not {grid(flat, 700, 300)[0]:.4f}")
dm, dsd = grid(flat, 2 * H, 2 * T)[:2]
print(f"break 3, the same 10 flips fed in twice: mean = {dm:.4f}, sd = {dsd:.4f}; honest sd = {gsd:.4f}")
print(f"break 4, likelihood at 0.7 read as a chance: {LIK(0.7):.4f}; its area over theta = {float(ev_exact):.4f}, not 1")

# try changing
am, _, ag, _ = grid(flat, 10, 0)
print(f"try: 10 heads in 10, mean = {am:.4f}, P(theta>0.5) = {ag:.4f}; 70 of 100, sd = {grid(flat, 70, 30)[1]:.4f}; "
      f"prior 0.4 to 0.6 with 10 flips, mean = {grid(flat, H, T, 4000, 0.4, 0.6)[0]:.4f}")

assert area == Fr(1, 1320) and abs(garea - float(area)) < 1e-9        # exact; grid area vs exact
assert abs(gm - float(mean_exact)) < 1e-6 and abs(ggt - float(gt_exact)) < 1e-6   # grid vs exact
assert abs(sm - float(mean_exact)) < 4 * ssd / sqrt(k) and abs(acc - 1 / 11) < 4 * acc_se  # sim
assert abs(m11 - float(mean_exact)) < 0.01                            # 11 coins already close
assert all(abs(exact_mean(0, 7 * n // 10, n - 7 * n // 10) - f) < 1e-6 for n, f in zip((0, 10, 30, 100, 300, 1000), fl_row))
assert abs(dm - exact_mean(0, 2 * H, 2 * T)) < 1e-6                    # double count
assert abs(tm - (0.6 - 1 / (700 / 0.6 - 300 / 0.4))) < 5e-4 and all(abs(s - gm) < 1e-9 for s in st)  # fence; order
assert abs(sc_row[1] - exact_mean(10, H, T)) < 1e-6 and abs(sc_row[-1] - exact_mean(10, 700, 300)) < 1e-6
print("ALL CHECKS PASS")
