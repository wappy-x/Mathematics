# Stationarity and autocorrelation -- the check behind the card; only math is imported.
# Monthly airline passengers, thousands, Jan 1949 to Dec 1960 (Box and Jenkins, Series G).
# Roads: r(h) by lag products and via the spectrum; exact covariances of three small
# models by listing every outcome; 2,000 seeded pure-noise series for the band.
import math

DATA = [112, 118, 132, 129, 121, 135, 148, 148, 136, 119, 104, 118,
        115, 126, 141, 135, 125, 149, 170, 170, 158, 133, 114, 140,
        145, 150, 178, 163, 172, 178, 199, 199, 184, 162, 146, 166,
        171, 180, 193, 181, 183, 218, 230, 242, 209, 191, 172, 194,
        196, 196, 236, 235, 229, 243, 264, 272, 237, 211, 180, 201,
        204, 188, 235, 227, 234, 264, 302, 293, 259, 229, 203, 229,
        242, 233, 267, 269, 270, 315, 364, 347, 312, 274, 237, 278,
        284, 277, 317, 313, 318, 374, 413, 405, 355, 306, 271, 306,
        315, 301, 356, 348, 355, 422, 465, 467, 404, 347, 305, 336,
        340, 318, 362, 348, 363, 435, 491, 505, 404, 359, 310, 337,
        360, 342, 406, 396, 420, 472, 548, 559, 463, 407, 362, 405,
        417, 391, 419, 461, 472, 535, 622, 606, 508, 461, 390, 432]
N, LAGS, SERIES, SEED, M64 = len(DATA), 24, 2000, 20260929, 0xFFFFFFFFFFFFFFFF
BAND = 1.96 / math.sqrt(N)
def acov(xs, h, divisor=None):              # c(h): lag products about the mean, over n
    n = len(xs); m = sum(xs) / n
    return sum((xs[t] - m) * (xs[t + h] - m) for t in range(n - h)) / (divisor or n)
def acf(xs, lags):                          # road 1: r(h) = c(h) / c(0)
    return [acov(xs, h) / acov(xs, 0) for h in range(lags + 1)]
def acf_spectral(xs, lags):                 # road 2: periodogram, then back again
    n = len(xs); m = sum(xs) / n; big = 2 * n   # zero padding stops the wrap-round
    power = []
    for k in range(big):
        re = im = 0.0
        for t in range(n):
            re += (xs[t] - m) * math.cos(2 * math.pi * k * t / big)
            im -= (xs[t] - m) * math.sin(2 * math.pi * k * t / big)
        power.append(re * re + im * im)
    c = [sum(power[k] * math.cos(2 * math.pi * k * h / big) for k in range(big)) / big
         for h in range(lags + 1)]
    return [v / c[0] for v in c]
def sd(xs): return math.sqrt(acov(xs, 0))
def splitmix64(s):                          # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
def row(label, vals, f="{:.4f}"):
    print(label + " " + " ".join(f.format(v) for v in vals))
# ---- the raw series: does it keep its character? ----
for yr in (1949, 1954, 1960):
    row(f"figure, {yr} by month:", DATA[12 * (yr - 1949):12 * (yr - 1948)], "{:d}")
years = [DATA[12 * k:12 * k + 12] for k in range(12)]
row("year mean, 1949 and 1960:", [sum(years[0]) / 12, sum(years[11]) / 12], "{:.2f}")
row("year sd, 1949 and 1960:", [sd(years[0]), sd(years[11])], "{:.2f}")
y49 = years[0]; m49 = sum(y49) / 12
row("hand, 1949: mean, sum sq dev, sum lag-1 products, r(1):",
    [m49, sum((v - m49) ** 2 for v in y49),
     sum((y49[t] - m49) * (y49[t + 1] - m49) for t in range(11)), acf(y49, 1)[1]])

# ---- trend, season and noise, on logs: y = level(month) + b t + noise ----
y = [math.log(v) for v in DATA]
tbar = [m + 66.0 for m in range(12)]        # average month index for each calendar month
ybar = [sum(y[12 * k + m] for k in range(12)) / 12 for m in range(12)]
sxx = sum((t - tbar[t % 12]) ** 2 for t in range(N))
b = sum((t - tbar[t % 12]) * (y[t] - ybar[t % 12]) for t in range(N)) / sxx    # each month compared with itself
lev = [ybar[m] - b * tbar[m] for m in range(12)]
noise = [y[t] - lev[t % 12] - b * t for t in range(N)]
avg = sum(lev) / 12
row("trend: growth per year, July factor, November factor:",
    [math.exp(12 * b) - 1, math.exp(lev[6] - avg), math.exp(lev[10] - avg)])
normal_eq = max([abs(sum(noise[m::12])) for m in range(12)] + [abs(sum(t * noise[t] for t in range(N)))])
row("noise sd, 1949-54 and 1955-60:", [sd(noise[:72]), sd(noise[72:])])
cn = [acov(noise, h) for h in range(LAGS + 1)]     # standard errors: Var(sum a_t noise_t) from c(h), lags to 24
def se_of(a): return math.sqrt(sum(a[i] * a[j] * cn[abs(i - j)] for i in range(N) for j in range(N) if abs(i - j) <= LAGS))
wb = [(t - tbar[t % 12]) / sxx for t in range(N)]                         # error of b = sum of wb_t noise_t
sea = [[(t % 12 == m) / 12 - 1 / N - (tbar[m] - 71.5) * wb[t] for t in range(N)] for m in (6, 10)]
g, fjul, fnov = 12 * math.exp(12 * b), math.exp(lev[6] - avg), math.exp(lev[10] - avg)   # growth's slope, factors
row("trend se with memory: growth, July, November; growth se if independent:",
    [g * se_of(wb), fjul * se_of(sea[0]), fnov * se_of(sea[1]), g * math.sqrt(cn[0] / sxx)])

# ---- the correlograms, two roads each ----
raw1, raw2 = acf(DATA, LAGS), acf_spectral(DATA, LAGS)
noi1, noi2 = acf(noise, LAGS), acf_spectral(noise, LAGS)
for name, r1, r2 in (("raw", raw1, raw2), ("noise", noi1, noi2)):
    row(f"{name} r(h), h = 1 2 3 6 12 24, lag products:", [r1[h] for h in (1, 2, 3, 6, 12, 24)])
    row(f"{name} r(h), h = 1 2 3 6 12 24, spectrum and back:", [r2[h] for h in (1, 2, 3, 6, 12, 24)])
    row(f"figure, {name} r(h) for h = 1..24:", r1[1:], "{:.2f}")
row("band, +-1.96/sqrt(144):", [BAND, -BAND])
row("figure, band:", [BAND, -BAND], "{:.2f}")
last_out = max(h for h in range(1, LAGS + 1) if abs(noi1[h]) > BAND)

# ---- three small models, every outcome listed: 64 equally likely sign patterns ----
models = {"lingering shock": lambda c, z: [z[t] + 0.5 * z[t - 1] for t in range(1, 5)],
          "shared offset":   lambda c, z: [c + z[t] for t in range(1, 5)],
          "random walk":     lambda c, z: [sum(z[1:t + 1]) for t in range(1, 5)]}
paths = {k: [] for k in models}
for code in range(64):
    s = [1.0 if code >> i & 1 else -1.0 for i in range(6)]
    for k, f in models.items():
        paths[k].append(f(s[0], s[1:]))
cov = {k: [[sum(p[i] * p[j] for p in ps) / 64 for j in range(4)] for i in range(4)] for k, ps in paths.items()}
for k in models:
    row(f"{k}: Cov at gap 0, 1, 2 from t = 1:", [cov[k][t][t + g] for g in range(3) for t in range(4 - g)], "{:.2f}")
avg4 = sum(sum(p) ** 2 for p in paths["shared offset"]) / 64 / 16
row("shared offset, variance of the average of 4, and if independent:", [avg4, 2 / 4], "{:.2f}")

# ---- 2,000 pure-noise series of 144, uniform on (-1, 1) ----
s, r1s, any_out = SEED, [], 0
for _ in range(SERIES):
    xs = []
    for _ in range(N):
        s, z = splitmix64(s)
        xs.append((z >> 11) * 2.0 ** -52 - 1.0)
    r = acf(xs, LAGS)
    r1s.append(r[1])
    any_out += any(abs(v) > BAND for v in r[1:])
mean_r1 = sum(r1s) / SERIES
sd_r1 = math.sqrt(sum((v - mean_r1) ** 2 for v in r1s) / (SERIES - 1))
out1, anyf = sum(abs(v) > BAND for v in r1s) / SERIES, any_out / SERIES
row("pure noise: mean r(1), its se; theory -1/n:", [mean_r1, sd_r1 / math.sqrt(SERIES), -1 / N])
row("pure noise: sd of r(1); theory 1/sqrt(n):", [sd_r1, 1 / math.sqrt(N)])
row("pure noise: share with r(1) outside band, its se:", [out1, math.sqrt(out1 * (1 - out1) / SERIES)])
row("pure noise: share with any of 24 lags outside, its se:", [anyf, math.sqrt(anyf * (1 - anyf) / SERIES)])
s, z = splitmix64(s); off = [(z >> 63) * 2.0 - 1.0]    # one shared-offset record: c, then c + e_t
for _ in range(10 * N): s, z = splitmix64(s); off.append(off[0] + (z >> 63) * 2.0 - 1.0)
one = acf(off[1:], 12); row("shared offset, one record of 1,440: r(1), r(12); true rho:", [one[1], one[12], 0.5])
# ---- what breaks, and try changing ----
row("wrong: divide by n - h, raw r(h) at h = 100 and 120:",
    [acov(DATA, h, N - h) / acov(DATA, 0) for h in (100, 120)])
line = [y[t] - (sum(y) / N + (t - 71.5) * sum((u - 71.5) * y[u] for u in range(N))
        / sum((u - 71.5) ** 2 for u in range(N))) for t in range(N)]
row("try: trend only removed, r(h) at h = 1 6 12:", [acf(line, 12)[h] for h in (1, 6, 12)])
row("band for 12 months, 36 and 1,440:", [1.96 / math.sqrt(12), 1.96 / 6, 1.96 / math.sqrt(1440)])
print(f"noise: last lag of 24 outside the band: {last_out}")

assert max(abs(p - q) for p, q in zip(raw1 + noi1, raw2 + noi2)) < 1e-9     # two roads, one correlogram
assert normal_eq < 1e-9                                                     # noise is least-squares residual
assert cov["lingering shock"][0][:3] == [1.25, 0.5, 0.0] and cov["lingering shock"][2][3] == 0.5
assert cov["shared offset"][1][3] == 1.0 and cov["random walk"][3][3] == 4.0 and avg4 == 1.25
assert abs(sd_r1 - 1 / math.sqrt(N)) < 0.004 and abs(out1 - 0.05) < 4 * math.sqrt(0.05 * 0.95 / SERIES)
assert all(abs(v) <= 1 for v in raw1 + noi1) and acov(DATA, 100, N - 100) / acov(DATA, 0) < -1
assert max(abs(one[1]), abs(one[12])) < 4 / math.sqrt(10 * N)   # one record cannot see its offset
print("ALL CHECKS PASS")
