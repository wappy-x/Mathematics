# Bloom filters and a distinct-count sketch -- the check behind the card.
# Standard library only. Hashes and random numbers are written out below.
import math

M = (1 << 64) - 1
def mix64(z):                           # SplitMix64's scrambler: 64 bits in, 64 well-mixed bits out
    z = (z + 0x9E3779B97F4A7C15) & M
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return z ^ (z >> 31)

def url_hash(s):                        # FNV-1a over the bytes, then scrambled
    h = 0xCBF29CE484222325
    for b in s.encode():
        h = ((h ^ b) * 0x100000001B3) & M
    return mix64(h)

def positions(s, k, m):                 # k bit positions from two hashes (double hashing)
    h1 = url_hash(s); h2 = mix64(h1) | 1
    return [((h1 + i * h2) & M) % m for i in range(k)]

def fp_formula(n, m, k): return (1 - math.exp(-k * n / m)) ** k
def url(i): return f"https://shop.example/item/{i}"

print("== sizing: 10 million URLs, 1 in 100 false alarms ==")
n, p = 10_000_000, 0.01
bpi = math.log(1 / p) / math.log(2) ** 2
print(f"bits per URL ln(1/p)/(ln 2)^2 = {bpi:.4f}   m = {n * bpi:,.0f} bits = {n * bpi / 8e6:.2f} MB")
print(f"best k = (m/n) ln 2 = {bpi * math.log(2):.4f}   floor log2(1/p) = {math.log2(1 / p):.4f} bits per URL")
m, k = 96_000_000, 7
print(f"12 MB = {m:,} bits, {m / n:.1f} per URL; k = {k}: kn/m = {k * n / m:.6f}"
      f"   zeros e^-kn/m = {math.exp(-k * n / m):.6f}   false alarms = {fp_formula(n, m, k):.6f}")
print(f"one 8-byte fingerprint per URL = {8 * n / 1e6:.0f} MB   filter bytes per URL = {m / 8 / n:.1f}"
      f"   filter over floor = 1/ln 2 = {1 / math.log(2):.4f}")
print("chart1 (n = 0..20M)," + ",".join(f"{100 * fp_formula(2e6 * j, m, k):.2f}" for j in range(11)))
print("chart2 (k = 1..12)," + ",".join(f"{100 * fp_formula(n, m, j):.2f}" for j in range(1, 13)))
assert abs(fp_formula(n, m, k) - 0.01) < 0.0005, "12 MB with 7 hashes should give about 1 in 100"
assert min(range(1, 13), key=lambda j: fp_formula(n, m, j)) == round(m / n * math.log(2)), "best k is (m/n) ln 2"

print("== road 2: every arrangement of a tiny filter, m = 8, k = 2, n = 3 ==")
tm, tk, tn = 8, 2, 3
tot_fp = tot_set = 0
for c in range(tm ** (tk * tn)):        # every choice of 6 bit positions
    bits = 0
    for _ in range(tk * tn):
        bits |= 1 << (c % tm); c //= tm
    s = bin(bits).count("1"); tot_set += s; tot_fp += (s / tm) ** tk
ex_fp, ex_set = tot_fp / tm ** (tk * tn), tot_set / tm ** (tk * tn)
q0 = (1 - 1 / tm) ** (tk * tn)
print(f"exact false alarms {ex_fp:.6f}   (1-(1-1/m)^kn)^k {(1 - q0) ** tk:.6f}   (1-e^-kn/m)^k {fp_formula(tn, tm, tk):.6f}")
print(f"average bits set: counted {ex_set:.6f}   m(1-(1-1/m)^kn) {tm * (1 - q0):.6f}")
assert abs(ex_set - tm * (1 - q0)) < 1e-12, "each bit stays 0 with chance (1-1/m)^kn"
assert ex_fp > (1 - q0) ** tk, "the exact rate sits just above the textbook product"

print("== road 3: a real filter at 1/1000 scale: 10,000 URLs in 96,000 bits ==")
sn, sm, tests = 10_000, 96_000, 100_000
bits = bytearray(sm)
for i in range(sn):
    for q in positions(url(i), k, sm): bits[q] = 1
filled = sum(bits)
print(f"bits set {filled} of {sm} = {filled / sm:.6f}   predicted {1 - math.exp(-k * sn / sm):.6f}")
def false_alarms(bits, mm):
    return sum(all(bits[q] for q in positions(url(10**7 + j), k, mm)) for j in range(tests))
fa = false_alarms(bits, sm); rate = fa / tests
se = math.sqrt(fp_formula(sn, sm, k) * (1 - fp_formula(sn, sm, k)) / tests)
print(f"unseen URLs tested {tests}: false alarms {fa} = {rate:.6f}   formula {fp_formula(sn, sm, k):.6f}"
      f"   (set fraction)^{k} {(filled / sm) ** k:.6f}   standard error {se:.6f}")
assert abs(rate - fp_formula(sn, sm, k)) < 4 * se, "measured false alarms disagree with the formula"
assert all(all(bits[q] for q in positions(url(i), k, sm)) for i in range(sn)), "a stored URL was missed"
kept = bytearray(bits)
for q in positions(url(0), k, sm): kept[q] = 0
lost = sum(not all(kept[q] for q in positions(url(i), k, sm)) for i in range(1, sn))
print(f"delete URL 0 by clearing its {k} bits: other stored URLs now missed = {lost}")
for i in range(sn, 2 * sn):
    for q in positions(url(i), k, sm): bits[q] = 1
fa2 = false_alarms(bits, sm)
print(f"overfilled with 20,000 URLs: false alarms {fa2 / tests:.6f}   formula {fp_formula(2 * sn, sm, k):.6f}")
assert abs(fa2 / tests - fp_formula(2 * sn, sm, k)) < 0.005, "overfilled rate disagrees with the formula"

print("== what breaks (full size, formula) ==")
print(f"20 million URLs, same filter: {fp_formula(2 * n, m, k):.6f}")
print(f"one hash, k = 1: {fp_formula(n, m, 1):.6f}   twenty hashes: {fp_formula(n, m, 20):.6f}")
print(f"12 MB read as 12 million bits, k = 7: {fp_formula(n, 12_000_000, k):.6f}")
fm = round(n * math.log2(1 / p)); fk = round(fm / n * math.log(2))
print(f"only log2(1/p) bits per URL ({fm:,} bits), best k = {fk}: {fp_formula(n, fm, fk):.6f}")

print("== distinct visitors: keep the t smallest hash values ==")
def kmv(hashes, t):                     # the t smallest different values seen, smallest first
    low = []
    for h in hashes:
        if len(low) == t and h >= low[-1] or h in low: continue
        j = len(low)
        while j > 0 and low[j - 1] > h: j -= 1
        low.insert(j, h)
        if len(low) > t: low.pop()
    return low
def estimate(low, t): return (t - 1) / (low[t - 1] / 2.0 ** 64)
t, pool, reqs, salt = 1024, 500_000, 1_000_000, 0x5EED
seen = bytearray(pool); stream = []; rng = 2026
for _ in range(reqs):                   # synthetic: a few visitors return often, most rarely
    rng = (rng + 0x9E3779B97F4A7C15) & M
    x = (mix64(rng) >> 11) / 2.0 ** 53
    v = int(pool * x * x); seen[v] = 1; stream.append(mix64(v ^ salt))
true_d = sum(seen); low = kmv(stream, t); est = estimate(low, t)
print(f"requests {reqs:,}   true distinct visitors {true_d:,}   sketch {t} values = {8 * t:,} bytes")
print(f"exact list of visitors at 8 bytes each = {8 * true_d:,} bytes")
print(f"t-th smallest / 2^64 = {low[t - 1] / 2.0 ** 64:.8f}   estimate (t-1)/U = {est:,.0f}"
      f"   error {100 * (est / true_d - 1):+.2f}%   promised spread 1/sqrt(t-2) = {100 / math.sqrt(t - 2):.2f}%")
print(f"wrong: t/U = {t / (low[t - 1] / 2.0 ** 64):,.0f}   wrong: one smallest only, 1/U = {1 / (low[0] / 2.0 ** 64):,.0f}")
e256 = estimate(kmv(stream, 256), 256)
print(f"try: p = 0.001: {math.log(1000) / math.log(2) ** 2:.4f} bits per URL = {n * (math.log(1000) / math.log(2) ** 2) / 8e6:.2f} MB"
      f"   t = 256: estimate {e256:,.0f}, error {100 * (e256 / true_d - 1):+.2f}%, promised spread {100 / math.sqrt(254):.2f}%")
assert abs(est / true_d - 1) < 4 / math.sqrt(t - 2), "estimate outside four promised spreads"

print("== road 2 for the sketch: 100 independent hashes of 10,000 visitors, t = 64 ==")
d2, t2, runs = 10_000, 64, 100
ests = [estimate(kmv([mix64(v ^ (s * 0xA24BAED4963EE407 & M)) for v in range(d2)], t2), t2) for s in range(1, runs + 1)]
mean = sum(ests) / runs; rms = math.sqrt(sum((e / d2 - 1) ** 2 for e in ests) / runs)
theory = math.sqrt((d2 - 1) * (t2 - 1) / (d2 * (t2 - 2)) - 1)
print(f"mean estimate {mean:,.1f}   rms error {100 * rms:.2f}%   exact theory {100 * theory:.2f}%   1/sqrt(t-2) {100 / math.sqrt(t2 - 2):.2f}%")
assert abs(mean - d2) < 4 * d2 * theory / math.sqrt(runs), "estimator looks biased"
assert abs(rms / theory - 1) < 0.3, "spread disagrees with theory"

print("== road 3 for the sketch: the average, 400 more hashes of 10,000 visitors, t = 4 ==")
t4, runs4 = 4, 400                      # few marks: dropping the -1 would show as a 1/(t-1) = 33% bias
e4 = [estimate(kmv([mix64(v ^ (s * 0xA24BAED4963EE407 & M)) for v in range(d2)], t4), t4) for s in range(runs + 1, runs + runs4 + 1)]
m4, tol4 = sum(e4) / runs4, 4 * d2 * math.sqrt((d2 - 1) * (t4 - 1) / (d2 * (t4 - 2)) - 1) / math.sqrt(runs4)
print(f"mean (t-1)/U {m4:,.1f}   allowed {d2:,} +/- {tol4:,.1f}   wrong: mean t/U {m4 * t4 / (t4 - 1):,.1f}, {100 / (t4 - 1):.0f}% high")
assert abs(m4 - d2) < tol4 < abs(m4 * t4 / (t4 - 1) - d2), "estimator biased, or the test cannot see a bias of 1/(t-1)"
print("ALL CHECKS PASS")
