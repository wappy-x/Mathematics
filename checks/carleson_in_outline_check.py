# Carleson's theorem in outline -- the check behind the card. Standard library only.
# Signal 1, the octave stack: f(x) = sum over k >= 1 of cos(2^(k-1) x) / k volts,
# x = 2*pi*220*t. Square-integrable; it diverges at x = 0 and x = 2*pi/3.
# Signal 2, Fejer's continuous signal: sum over k of Q(x; 2n, n) / k^2, n = 2^(k^3).
# Signal 3, the +-1 V siren square wave, for the Gibbs row.
import math

KMAX, POINTS, SEED, EPS = 1024, 2000, 2026, 0.2
MASK64 = (1 << 64) - 1

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & MASK64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK64
    return state, z ^ (z >> 31)

def harmonic_direct(n):
    return sum(1.0 / j for j in range(n, 0, -1))

# Euler's constant from one long sum, then the asymptotic harmonic number
NG = 100000
GAMMA = harmonic_direct(NG) - math.log(NG) - 1 / (2 * NG) + 1 / (12 * NG**2) - 1 / (120 * NG**4)
def harmonic_asym(log_n, n):
    return log_n + GAMMA + 1 / (2 * n) - 1 / (12 * n * n)

def simpson(fn, a, b, m):
    h = (b - a) / m
    s = fn(a) + fn(b) + sum((4 if i % 2 else 2) * fn(a + i * h) for i in range(1, m))
    return s * h / 3

SI_PI = simpson(lambda u: 1.0 if u == 0 else math.sin(u) / u, 0.0, math.pi, 1000)

# ---- the octave stack: energy, and the two bad points (exact phases by integer arithmetic)
energy = 0.5 * sum(1 / k**2 for k in range(1, 200001)) + 0.5 / 200000
print(f"octave stack energy, mean square volts^2: series {energy:.6f}  exact pi^2/12 {math.pi**2 / 12:.6f}")
print(f"octave stack rms volts: {math.sqrt(math.pi**2 / 12):.4f}")
tail_rms = math.sqrt(0.5 * sum(1 / k**2 for k in range(KMAX + 1, 2000001)))
print(f"rms of the part beyond octave {KMAX}: {tail_rms:.4f} V")
assert abs(energy - math.pi**2 / 12) < 1e-9

def bad_point_sums(p, q):  # x = 2*pi*p/q, phase of term k is 2^(k-1) p mod q, exactly
    s, out = 0.0, []
    for k in range(1, KMAX + 1):
        s += math.cos(2 * math.pi * ((pow(2, k - 1, q) * p) % q) / q) / k
        out.append(s)
    return out

CHART_K = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024]
at0, at23 = bad_point_sums(0, 1), bad_point_sums(1, 3)
for K in CHART_K:
    assert abs(at0[K - 1] - harmonic_asym(math.log(K), K)) < 1 / (60 * K**4) + 1e-9  # road 2
    assert abs(at23[K - 1] + 0.5 * harmonic_direct(K)) < 1e-9             # every term is -1/(2k)
print("chart, octaves K        " + "".join(f"{K:>8d}" for K in CHART_K))
print("chart, at t = 0         " + "".join(f"{at0[K - 1]:8.4f}" for K in CHART_K))
print("chart, at t = 1/660 s   " + "".join(f"{at23[K - 1]:8.4f}" for K in CHART_K))

# ---- random instants: their binary digits are fair coin flips (SplitMix64, seed 2026)
state, osc_K0 = SEED, [4, 16, 64, 256]
still_moving, diff_sq, diff_sq2, first_point = [0] * 4, 0.0, 0.0, None
for pt in range(POINTS):
    words = []
    for _ in range(17):
        state, w = splitmix(state)
        words.append(w)
    bits = [(words[i // 64] >> (63 - i % 64)) & 1 for i in range(17 * 64)]
    win = 0
    for i in range(53):
        win = (win << 1) | bits[i]
    s, sums = 0.0, []
    for k in range(1, KMAX + 1):  # phase of term k = 2*pi * 0.b_k b_(k+1) ... b_(k+52)
        s += math.cos(2 * math.pi * win / 2**53) / k
        sums.append(s)
        win = ((win << 1) & ((1 << 53) - 1)) | bits[k + 52]
    if pt == 0:
        first_point = sums
    for i, K0 in enumerate(osc_K0):
        if max(abs(sums[K - 1] - sums[-1]) for K in range(K0, KMAX + 1)) > EPS:
            still_moving[i] += 1
    d = sums[-1] - sums[15]
    diff_sq += d * d
    diff_sq2 += d**4
print("chart, a random instant " + "".join(f"{first_point[K - 1]:8.4f}" for K in CHART_K))
mean_sq = diff_sq / POINTS
se = math.sqrt((diff_sq2 / POINTS - mean_sq**2) / POINTS)
exact_sq = 0.5 * sum(1 / k**2 for k in range(17, KMAX + 1))
print(f"energy between octaves 16 and {KMAX}: simulated {mean_sq:.5f}  exact {exact_sq:.5f}  std error {se:.5f}")
assert abs(mean_sq - exact_sq) < 4 * se
fracs = [c / POINTS for c in still_moving]
for K0, c, fr in zip(osc_K0, still_moving, fracs):
    print(f"bars, after octave {K0:>3d}: {c:>4d} of {POINTS} instants still move by more than {EPS} V  ({fr:.4f})")
assert fracs[0] > fracs[1] > fracs[2] > fracs[3] and fracs[0] > 0.5 and fracs[3] < 0.02

# ---- Step 1: convergence in energy gives a fast subsequence, not the whole sequence
def tail(K):
    return 0.5 * (math.pi**2 / 6 - sum(1 / k**2 for k in range(1, K + 1)))
along_squares = sum(tail(j * j) for j in range(1, 33))
along_all = sum(tail(K) for K in range(1, KMAX + 1))
print(f"sum of tail energies, K = 1, 4, 9, ..., 1024: {along_squares:.4f};  every K up to 1024: {along_all:.4f}")
assert along_squares < 1.0 and along_all > 3.0

# ---- Fejer's continuous signal: bounded, yet its partial sums at x = 0 grow without bound
bound = 2 * SI_PI * math.pi**2 / 6
print(f"Si(pi) = {SI_PI:.6f};  bound on |f|: 2 Si(pi) pi^2/6 = {bound:.4f}")
xs = [math.pi * (i + 0.5) / 4000 for i in range(4000)]
peak = max(abs(sum(math.sin(j * x) / j for j in range(1, 257))) for x in xs[:200])
print(f"largest |sum of sin(jx)/j, j <= 256| on the grid: {peak:.4f}")
assert 1.84 < peak < SI_PI
coef = {}  # direct road: write blocks 1 and 2 as cosine coefficients
for k, n in [(1, 2), (2, 256)]:
    for j in range(1, n + 1):
        coef[2 * n - j] = coef.get(2 * n - j, 0) + 1 / (j * k * k)
        coef[2 * n + j] = coef.get(2 * n + j, 0) - 1 / (j * k * k)
direct = [sum(c for fr, c in coef.items() if fr <= N) for N in (4, 512)]
assert abs(direct[0] - harmonic_direct(2)) < 1e-12 and abs(direct[1] - harmonic_direct(256) / 4) < 1e-12
assert abs(harmonic_direct(256) - harmonic_asym(math.log(256), 256)) < 1e-6
f_at_0 = sum(coef.values())
prod = sum(2 * math.sin(2 * n) * sum(math.sin(j) / j for j in range(1, n + 1)) / k**2 for k, n in [(1, 2), (2, 256)])
assert abs(sum(c * math.cos(fr) for fr, c in coef.items()) - prod) < 1e-12  # cosine form = product form, x = 1
print(f"f at x = 0, blocks 1 and 2: {abs(f_at_0):.4f}")
fej = []
for k in range(1, 10):
    e = k**3
    h = harmonic_direct(2**e) if e <= 20 else harmonic_asym(e * math.log(2), 2.0**e)
    fej.append(h / k**2)
print("bars, Fejer block k      " + "".join(f"{k:>8d}" for k in range(1, 10)))
print("bars, partial sum at 0   " + "".join(f"{v:8.4f}" for v in fej))
assert abs(fej[1] - direct[1]) < 1e-12 and fej[8] > bound > fej[7]

# ---- the siren square wave: converges at every non-switch instant, never uniformly
N = 1001
top = max((4 / math.pi) * sum(math.sin(k * x) / k for k in range(1, N + 1, 2))
          for x in [3 * math.pi / (N + 1) * i / 600 for i in range(1, 600)])
print(f"siren, N = {N}: largest partial sum {top:.4f} V, overshoot {top - 1:.4f} V;  limit (2/pi) Si(pi) = {2 / math.pi * SI_PI:.4f} V")
assert abs(top - 2 / math.pi * SI_PI) < 1e-3
print("ALL CHECKS PASS")
