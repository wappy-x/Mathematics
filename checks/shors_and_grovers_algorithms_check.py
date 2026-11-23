# Shor and Grover -- the check behind the card.  Standard library only: math
# supplies sin, cos, asin, sqrt and pi.  The state-vector idea (a list of
# complex amplitudes, one per basis state, rewritten by each gate) is the one
# the Qubits card explains.  Toy sizes: 15 and 21 are insecure on purpose.
from math import asin, cos, pi, sin, sqrt

def gcd(a, b):                            # Euclid's algorithm, written out
    while b:
        a, b = b, a % b
    return a

def powmod(a, e, n):                      # a multiplied in e times, wrapped at n
    out = 1
    for _ in range(e):
        out = out * a % n
    return out

def order(a, n):                          # road one: multiply until the powers return to 1
    r, p = 1, a % n
    while p != 1:
        p, r = p * a % n, r + 1
    return r

def qft(v, t):                            # road two: the QFT as a circuit of gates
    q = 1 << t
    for j in range(t - 1, -1, -1):        # top qubit first
        for x in range(q):                # Hadamard on qubit j
            if not x >> j & 1:
                a0, a1 = v[x], v[x | 1 << j]
                v[x], v[x | 1 << j] = (a0 + a1) / sqrt(2), (a0 - a1) / sqrt(2)
        for k in range(j - 1, -1, -1):    # controlled phase: angle pi / 2^(j-k)
            ang = pi / (1 << (j - k))
            ph = complex(cos(ang), sin(ang))
            for x in range(q):
                if x >> j & 1 and x >> k & 1:
                    v[x] *= ph
    out = [0j] * q                        # swap the qubit order end for end
    for x in range(q):
        rev = 0
        for b in range(t):
            rev |= (x >> b & 1) << (t - 1 - b)
        out[rev] = v[x]
    return out

def dft(v, q):                            # the same transform as the direct sum over x
    roots = [complex(cos(2 * pi * m / q), sin(2 * pi * m / q)) for m in range(q)]
    return [sum(v[x] * roots[x * y % q] for x in range(q)) / sqrt(q) for y in range(q)]

def shor_probs(n, a, t):                  # counting register after Hadamards, U_f and QFT
    q, rows, p = 1 << t, {}, 1
    for x in range(q):                    # the state x, a^x mod n, written straight down
        rows.setdefault(p, [0j] * q)[x] = 1 / sqrt(q)
        p = p * a % n
    probs = [0.0] * q
    for w in rows:
        f = qft(rows[w][:], t)
        for y in range(q):
            probs[y] += abs(f[y]) ** 2
    return probs, rows

def convergents(y, q):                    # Euclid on y/q: each convergent's denominator
    dens, d0, d1 = [], 1, 0
    while q:
        c = y // q
        y, q = q, y - c * q
        d0, d1 = d1, c * d1 + d0
        dens.append(d1)
    return dens

def read_period(y, q, a, n):              # first small denominator d with a^d = 1 mod n
    for d in convergents(y, q):
        if d < n and powmod(a, d, n) == 1:
            return d
    return 0

def shor(n, a, t):
    q, r = 1 << t, order(a, n)
    probs, rows = shor_probs(n, a, t)
    print(f"Shor, N = {n}, a = {a}: powers {[powmod(a, e, n) for e in range(1, r + 1)]}, period by multiplying {r}")
    print(f"counting register {t} qubits, Q = {q}; work values {sorted(rows)}; total probability {sum(probs):.4f}")
    peaks = sorted(sorted(range(q), key=lambda y: -probs[y])[:r])
    for y in peaks:
        print(f"  y = {y:3}    {'█' * round(100 * probs[y]):<25} {probs[y]:.4f}  denominators {convergents(y, q)}  period read {read_period(y, q, a, n) or 'none'}")
    out = 1 - sum(probs[y] for y in peaks)          # every other y, as one more bar; one block = 0.01
    print(f"  other {q - r:3}  {'█' * round(100 * out):<25} {out:.4f}")
    win, h = sum(probs[y] for y in range(q) if read_period(y, q, a, n) == r), powmod(a, r // 2, n)
    print(f"chance one run reads the period: {win:.4f}; outside the {r} peaks: {out:.4f}")
    print(f"{a}^{r // 2} mod {n} = {h}; gcd({h - 1}, {n}) = {gcd(h - 1, n)}; gcd({h + 1}, {n}) = {gcd(h + 1, n)}")
    return probs, rows, r, win, h

p15, rows15, r15, win15, h15 = shor(15, 7, 8)
direct, circuit = dft(rows15[7], 256), qft(rows15[7][:], 8)
gap = max(abs(direct[y] - circuit[y]) for y in range(256))
print(f"QFT circuit, {8} Hadamards and {8 * 7 // 2} phase gates, against the direct sum, gap below 1e-9: {'yes' if gap < 1e-9 else 'no'}")
good = 0
for a in range(2, 15):
    if gcd(a, 15) == 1:
        r = order(a, 15)
        h = powmod(a, r // 2, 15)
        f1, f2 = gcd(h - 1, 15), gcd(h + 1, 15)
        ok = r % 2 == 0 and h != 14
        good += ok
        print(f"  a = {a:2}: period {r}, a^(r/2) mod 15 = {h:2}, gcds {f1} and {f2}{'' if ok else '  (fails)'}")
print(f"bases that split 15: {good} of 7")
p21, rows21, r21, win21, h21 = shor(21, 2, 9)
w64 = sum(pr for y, pr in enumerate(shor_probs(21, 2, 6)[0]) if read_period(y, 64, 2, 21) == 6)
print(f"register too small, N = 21, Q = 64: chance one run reads the period {w64:.4f}")

M, KEY = 1024, 700
theta = asin(1 / sqrt(M))
best = int(pi / (4 * theta))
v, sim = [1 / sqrt(M)] * M, []
for k in range(51):
    sim.append(v[KEY] ** 2)
    v[KEY] = -v[KEY]                      # oracle U_f: flip the key's sign
    mean = sum(v) / M
    v = [2 * mean - x for x in v]         # diffusion: reflect every amplitude about the mean
form = [sin((2 * k + 1) * theta) ** 2 for k in range(51)]
u = [1 / sqrt(M)] * M
for k in range(25):
    u[KEY] = -u[KEY]                      # mistake 4: the oracle alone, no diffusion
print(f"Grover, M = {M}, key {KEY}: theta = asin(1/32) = {theta:.6f}, best rounds floor(pi/(4 theta)) = {best}")
for k in range(0, 51, 5):
    print(f"  rounds {k:2}: simulated {sim[k]:.4f}  formula {form[k]:.4f}")
print(f"rounds 25: {sim[25]:.4f}; rounds 32: {sim[32]:.4f}; oracle only, 25 rounds: {u[KEY] ** 2:.6f}")
print(f"classical, one look at a time: average {(M + 1) / 2:.1f} looks; looks for 0.9995: {-(-0.9995 * M // 1):.0f}")
print(f"two qubits, M = 4: best rounds {int(pi / (4 * asin(0.5)))}, success {sin(3 * asin(0.5)) ** 2:.4f}")
for s in (10, 20, 30, 40):
    th = asin(2.0 ** (-s / 2))
    print(f"  M = 2^{s}: Grover rounds {int(pi / (4 * th))}, classical average {((1 << s) + 1) / 2:.1f}")
print(f"mistake 1, a = 14: 14^1 mod 15 = 14 = 15 - 1, gcds {gcd(13, 15)} and {gcd(15, 15)}")
print(f"mistake 2, y = 128 read as 1/2: 7^2 mod 15 = {powmod(7, 2, 15)}, not 1")
print(f"mistake 3, {32} rounds instead of {best}: success {sim[32]:.4f}")
assert all(abs(sim[k] - form[k]) < 1e-9 for k in range(51))        # simulation against closed form
assert gap < 1e-9                                                  # circuit against direct sum
assert read_period(64, 256, 7, 15) == order(7, 15) == 4            # quantum road against multiplying
assert gcd(h15 - 1, 15) * gcd(h15 + 1, 15) == 15 and gcd(h15 - 1, 15) not in (1, 15)
assert abs(win15 - 0.5) < 1e-9 and best == 25 and good == 6
assert read_period(85, 512, 2, 21) == r21 == 6 and win21 > 0.3 > w64 and abs(sum(p21) - 1) < 1e-9
print("ALL CHECKS PASS")
