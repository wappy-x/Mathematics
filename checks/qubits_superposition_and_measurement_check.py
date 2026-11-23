# Qubits -- the check behind the card.  Standard library only.  This is the
# shelf's state-vector simulator: n qubits are 2^n complex amplitudes, a gate
# is a unitary matrix, and a reading picks one outcome with chance |amplitude|^2.
# Two qubits A and B; amplitudes are listed in the order 00, 01, 10, 11, A first.
import math

R = 1 / math.sqrt(2)
I2 = [[1, 0], [0, 1]]
X = [[0, 1], [1, 0]]                           # NOT: swaps |0> and |1>
Z = [[1, 0], [0, -1]]                          # phase flip: |1> becomes -|1>
H = [[R, R], [R, -R]]                          # Hadamard: the even split
CNOT = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1], [0, 0, 1, 0]]

def kron(a, b):                                # tensor product of two vectors or two matrices
    if not isinstance(a[0], list):
        return [x * y for x in a for y in b]
    return [[x * y for x in ra for y in rb] for ra in a for rb in b]

def matvec(m, v):                              # road one: multiply by the full matrix
    return [sum(m[r][c] * v[c] for c in range(len(v))) for r in range(len(m))]

def unitary(m):                                # U* U = I, entry by entry
    n = len(m)
    return all(abs(sum(complex(m[k][r]).conjugate() * m[k][c] for k in range(n)) - (r == c)) < 1e-12
               for r in range(n) for c in range(n))

def apply_1q(g, s, k, n):                      # road two: gate g on qubit k, amplitudes in pairs
    out, bit = list(s), 1 << (n - 1 - k)
    for i in range(len(s)):
        if i & bit == 0:
            a, b = s[i], s[i | bit]
            out[i], out[i | bit] = g[0][0] * a + g[0][1] * b, g[1][0] * a + g[1][1] * b
    return out

def apply_cnot(s, c, t, n):                    # road two: where the control reads 1, swap the target
    out, cb, tb = list(s), 1 << (n - 1 - c), 1 << (n - 1 - t)
    for i in range(len(s)):
        if i & cb and not i & tb:
            out[i], out[i | tb] = s[i | tb], s[i]
    return out

def chances(s): return [abs(a) ** 2 for a in s]

def read_a(s, bit):                            # read qubit A only; keep and rescale what agrees
    keep = [a if (i >> 1) == bit else 0 for i, a in enumerate(s)]
    p = sum(chances(keep))
    return p, [a / math.sqrt(p) for a in keep]

def clean(x): return 0.0 if abs(x) < 5e-13 else x

def amp(z):
    z = complex(z)
    if abs(z.imag) < 5e-13:
        return f"{clean(z.real):.4f}"
    return f"{clean(z.real):.4f}{clean(z.imag):+.4f}i"

def row(label, xs):
    print(f"{label:<34}" + " ".join(f"{amp(x):>8}" for x in xs))

def bar(label, p):
    print(f"{label:<11}{'#' * round(50 * p):<50} {p:.4f}")

M64 = (1 << 64) - 1
def splitmix64(seed):                          # SplitMix64, written out so both languages agree
    s = seed
    while True:
        s = (s + 0x9E3779B97F4A7C15) & M64
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        yield z ^ (z >> 31)

coin, zero = [0.8, 0.6], [1, 0]                # A: the weighted coin; B: a plain |0>
tilt = 2 * math.degrees(math.acos(coin[0]))
print(f"coin qubit A = 0.8|0> + 0.6|1>: reads 0 with chance {coin[0] ** 2:.4f}, 1 with {coin[1] ** 2:.4f}")
print(f"spin tilt from up that prepares it: {tilt:.4f} degrees")
before = kron(coin, zero)
after_m = matvec(CNOT, before)
after_i = apply_cnot(before, 0, 1, 2)
print(f"{'outcome':<34}" + " ".join(f"{b:>8}" for b in ["00", "01", "10", "11"]))
row("A (x) B, before the gate", before)
row("chances before", chances(before))
row("after CNOT, by the 4 x 4 matrix", after_m)
row("after CNOT, by swapping pairs", after_i)
row("chances after", chances(after_m))
print(f"total chance before and after: {sum(chances(before)):.4f} and {sum(chances(after_m)):.4f}")
table = {(a, b): apply_cnot(kron([1 - a, a], [1 - b, b]), 0, 1, 2).index(1) for a in (0, 1) for b in (0, 1)}
print("CNOT on the four basis inputs: " + ", ".join(f"{a}{b} -> {v >> 1}{v & 1}" for (a, b), v in table.items()))
print(f"B ends as the half adder's sum bit, A xor B: {'yes' if all(v & 1 == a ^ b for (a, b), v in table.items()) else 'no'}")
test = lambda s: s[0] * s[3] - s[1] * s[2]
print(f"product test a00*a11 - a01*a10: before {test(before):.4f}, after {test(after_m):.4f}")
pa = chances(after_m)
print(f"chances test P00*P11 - P01*P10: before {test(chances(before)):.4f}, after {test(pa):.4f}")
for bit in (0, 1):
    p, s = read_a(after_m, bit)
    row(f"read A = {bit}, chance {p:.4f}; state", s)
print(f"B alone reads 0 with chance {pa[0] + pa[2]:.4f}; it agrees with A with chance {pa[0] + pa[3]:.4f}")
for when, ps in (("before", chances(before)), ("after", pa)):
    for b, p in zip(["00", "01", "10", "11"], ps): bar(f"{when} {b}", p)
SHOTS, gen = 10000, splitmix64(2026)
counts = [0, 0, 0, 0]
for _ in range(SHOTS):
    u, acc = (next(gen) >> 11) / 2.0 ** 53, 0.0
    for i, p in enumerate(pa):
        acc += p
        if u < acc or i == 3:
            counts[i] += 1
            break
se = math.sqrt(SHOTS * pa[0] * (1 - pa[0]))
print(f"{SHOTS} shots, seed 2026: 00 {counts[0]}, 01 {counts[1]}, 10 {counts[2]}, 11 {counts[3]}; "
      f"expected 00 {SHOTS * pa[0]:.0f}, standard error {se:.0f}")
bell = apply_cnot(apply_1q(H, kron(zero, zero), 0, 2), 0, 1, 2)
row("from 00: H on A, then CNOT", bell)
hi = matvec(kron(H, I2), before)
row("H on A of A (x) B, both roads", hi)
coins = {"0.8, 0.6": coin, "0.8, -0.6 (after Z)": matvec(Z, coin), "0.8, 0.6i": [0.8, 0.6j]}
for name, c in coins.items():
    print(f"coin ({name}): chances {chances(c)[0]:.4f} {chances(c)[1]:.4f}; after H {chances(matvec(H, c))[0]:.4f} {chances(matvec(H, c))[1]:.4f}")
row("H twice on |0>", matvec(H, matvec(H, zero)))
print(f"X, Z, H and CNOT each satisfy U* U = I: {'yes' if all(unitary(g) for g in (X, Z, H, CNOT)) else 'no'}")
print("amplitudes for n qubits: " + ", ".join(f"{n} -> {2 ** n}" for n in (1, 2, 10, 20, 50)))
print(f"pair updates for one gate on 50 qubits: {2 ** 49}; bytes at 16 per amplitude: {16 * 2 ** 50}")
hidden = coin[0] ** 2 * 0.5 + coin[1] ** 2 * 0.5
swapped = apply_cnot(before, 1, 0, 2)
print(f"mistake 1, amplitudes added as chances: {coin[0] + coin[1]:.4f}")
print(f"mistake 2, A and B as separate coins: P01 = {(pa[0] + pa[1]) * (pa[1] + pa[3]):.4f}, true {pa[1]:.4f}")
print(f"mistake 3, a hidden coin then H: P0 = {hidden:.4f}, true {chances(matvec(H, coin))[0]:.4f}")
print(f"mistake 4, control and target swapped: P11 = {chances(swapped)[3]:.4f}, product test {test(swapped):.4f}")
print(f"not a unit vector, (0.8, 0.8): chances add to {0.8 ** 2 + 0.8 ** 2:.4f}")
print("figure, wires y 60 and 150, gate x 210, control dot r 7, target circle r 16, meters x 330")
assert all(abs(p - q) < 1e-12 for p, q in zip(after_m, after_i))              # two roads, one state
assert all(abs(p - q) < 1e-12 for p, q in zip(hi, apply_1q(H, before, 0, 2)))
assert all(abs(p - q) < 1e-12 for p, q in zip(pa, [16 / 25, 0, 0, 9 / 25]))   # 0.8^2 and 0.6^2 by hand
assert abs(test(after_m) - 12 / 25) < 1e-12 and abs(test(before)) < 1e-12      # entangled after, not before
assert abs(chances(matvec(H, coin))[0] - 49 / 50) < 1e-12                       # (0.8 + 0.6)^2 / 2
assert abs(counts[0] - SHOTS * pa[0]) < 4 * se and counts[1] == counts[2] == 0  # sampling agrees
assert all(unitary(g) for g in (X, Z, H, CNOT)) and abs(sum(chances(after_m)) - 1) < 1e-12
assert all(v & 1 == a ^ b and v >> 1 == a for (a, b), v in table.items())       # sum bit, by xor
assert all(abs(p - q) < 1e-12 for p, q in zip(matvec(H, matvec(H, zero)), zero))  # H undoes itself
print("ALL CHECKS PASS")
