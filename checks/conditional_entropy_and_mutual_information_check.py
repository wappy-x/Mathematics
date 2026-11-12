# Conditional entropy and mutual information -- the check behind the card.
# Standard library only: math supplies log2 and nothing else.  X is this
# morning's barometer (falling, steady, rising), Y is rain tomorrow (rain, dry).
# The table is 100 synthetic mornings.  Road 1: reading by reading.  Road 2:
# the chain rule on the joint table.  Road 3: the direct sum over cells.
# Road 4: 200,000 mornings drawn with SplitMix64, seed 2026, and counted.
from math import log, log2

READ = ["falling", "steady", "rising"]
COUNTS = [[16, 9], [11, 34], [3, 27]]          # rows: barometer; columns: rain, dry
MASK = (1 << 64) - 1

def H(ps):                                     # entropy in bits of a list of chances
    return -sum(p * log2(p) for p in ps if p > 0)

def measures(c):                               # c: a table of counts or chances
    n = sum(sum(r) for r in c)
    p = [[v / n for v in r] for r in c]
    px = [sum(r) for r in p]
    py = [sum(r[j] for r in p) for j in range(len(p[0]))]
    hx, hy, hxy = H(px), H(py), H([v for r in p for v in r])
    hy_x = sum(px[i] * H([v / px[i] for v in p[i]]) for i in range(len(p)) if px[i] > 0)
    hx_y = sum(py[j] * H([r[j] / py[j] for r in p]) for j in range(len(py)) if py[j] > 0)
    direct = sum(p[i][j] * log2(p[i][j] / (px[i] * py[j]))
                 for i in range(len(p)) for j in range(len(py)) if p[i][j] > 0)
    return px, py, hx, hy, hxy, hy_x, direct, hx_y

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def unif(self): return (self.next() >> 11) / 9007199254740992.0

def draw(rng, p, days):                        # count `days` mornings drawn from table p
    cells = [v for r in p for v in r]
    out = [0] * len(cells)
    for _ in range(days):
        u, k = rng.unif(), 0
        while k < len(cells) - 1 and u >= cells[k]:
            u -= cells[k]; k += 1
        out[k] += 1
    return [out[0:2], out[2:4], out[4:6]]

def radio(c, keep):                            # the reading as received over a noisy link
    q = [[keep if z == x else (1 - keep) / 2 for z in range(3)] for x in range(3)]
    return [[sum(c[x][y] * q[x][z] for x in range(3)) for y in range(2)] for z in range(3)]

px, py, hx, hy, hxy, hy_x, direct, hx_y = measures(COUNTS)
per = [H([v / sum(r) for v in r]) for r in COUNTS]
i1 = hy - hy_x                                 # road 1: what the reading removes
i2 = hx + hy - hxy                             # road 2: chain rule, overlap of the two
i_sym = hx - hx_y                              # the same overlap, seen from the barometer
rng = SplitMix64(2026)
p = [[v / 100 for v in r] for r in COUNTS]
sim = measures(draw(rng, p, 200000))
i4 = sim[3] - sim[5]
indep = [[px[i] * py[j] for j in range(2)] for i in range(3)]
short = []
for _ in range(2000):                          # 20-day records of a useless barometer
    m = measures(draw(rng, indep, 20))
    short.append(m[3] - m[5])
bias = sum(short) / len(short)
se = (sum((s - bias) ** 2 for s in short) / (len(short) - 1) / len(short)) ** 0.5
worst, raised = 1.0, 0
for _ in range(10000):                         # random 3-by-2 tables: does knowing ever hurt on average?
    t = [[rng.unif() for _ in range(2)] for _ in range(3)]
    m = measures(t)
    worst = min(worst, m[3] - m[5])
    raised += sum(1 for r in t if H([v / sum(r) for v in r]) > m[3])
rad = measures(radio(COUNTS, 0.9))

print("reading   days  rain  P(x)    P(x,rain)  P(rain|x)  H(Y|X=x)  P(x) x H(Y|X=x)")
for i, r in enumerate(COUNTS):
    print(f"{READ[i]:<8}  {sum(r):>4}  {r[0]:>4}  {px[i]:.4f}  {r[0] / 100:.4f}     {r[0] / sum(r):.4f}     {per[i]:.4f}    {px[i] * per[i]:.4f}")
print(f"H(Y)    rain tomorrow, nothing known      {hy:.4f}")
print(f"H(X)    the barometer                     {hx:.4f}")
print(f"H(X,Y)  the pair                          {hxy:.4f}")
print(f"H(Y|X)  rain once the barometer is read   {hy_x:.4f}")
print(f"H(X|Y)  barometer once the rain is known  {hx_y:.4f}")
print(f"1 I = H(Y) - H(Y|X)                       {i1:.4f}")
print(f"2 I = H(X) + H(Y) - H(X,Y)                {i2:.4f}")
print(f"3 I = sum P(x,y) log2 P(x,y)/(P(x)P(y))   {direct:.4f}")
print(f"  I = H(X) - H(X|Y)                       {i_sym:.4f}")
print(f"4 I from 200,000 simulated mornings       {i4:.4f}")
print(f"chain: H(X) + H(Y|X)                      {hx + hy_x:.4f}")
print(f"share of rain uncertainty removed         {i1 / hy:.4f}")
print(f"I in nats (ln, not log2)                  {i1 * log(2):.4f}")
print(f"wrong: H(X) + H(Y) taken as H(X,Y)        {hx + hy:.4f}")
print(f"wrong: one reading, H(Y|X=falling)        {per[0]:.4f}")
print(f"short record: mean I, useless barometer   {bias:.4f}")
print(f"  standard error of that mean             {se:.4f}")
print(f"  first-order bias 2/(2 x 20 x ln 2)      {2 / (40 * log(2)):.4f}")
print(f"random tables: smallest H(Y) - H(Y|X)     {worst:.4f}")
print(f"  single readings that raised H: {raised} of 30000")
print(f"radio, 90% kept: I(Z;Y) received          {rad[3] - rad[5]:.4f}")
t1, t2, t3 = measures([[6, 14], [15, 35], [9, 21]]), measures([[30, 0], [0, 45], [0, 25]]), measures(radio(COUNTS, 0.4))
print(f"try: useless barometer, I                 {t1[3] - t1[5]:.4f}")
print(f"try: barometer settles rain, I            {t2[3] - t2[5]:.4f}")
print(f"try: radio keeps only 40%, I(Z;Y)         {t3[3] - t3[5]:.4f}")
print("bars: H(Y|X=x) " + " ".join(f"{v:.2f}" for v in per) + f"; H(Y) {hy:.2f}; H(Y|X) {hy_x:.2f}")
bar = lambda a, b: "█" * int(20 * a + 0.5) + "▒" * int(20 * b + 0.5)
print(f"the pair, {hxy:.4f} bits, split two ways (█ first reading, ▒ what is left)")
print(f"barometer, then rain   {bar(hx, hy_x)}   {hx:.4f} + {hy_x:.4f}")
print(f"rain, then barometer   {bar(hy, hx_y)}   {hy:.4f} + {hx_y:.4f}")
assert abs(i1 - 0.143862) < 1e-6                         # pinned to the worked table
assert abs(i1 - i2) < 1e-12 and abs(i1 - direct) < 1e-12  # three roads agree
assert abs(i_sym - i1) < 1e-12                           # symmetric: I(X;Y) = I(Y;X)
assert abs(hx_y - (hxy - hy)) < 1e-12                    # chain rule, rain first
assert abs(i4 - i1) < 0.005                              # simulation within a few standard errors
assert worst > -1e-12 and hy_x < hy                       # conditioning never raises entropy on average
assert per[0] > hy and raised > 0                         # but one reading can
assert bias > 0.03 and bias > 10 * se                     # short records invent information
assert rad[3] - rad[5] < i1                              # the radio cannot add information
assert abs(rad[3] - rad[5] - 0.099289) < 1e-6             # pinned: Bayes through the radio, by hand
print("ALL CHECKS PASS")
