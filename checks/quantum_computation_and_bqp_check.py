# BQP -- the check behind the card.  Standard library only: math gives sqrt and
# exp.  The state-vector simulator is the one the Qubits card explains: a list
# of 2^q amplitudes for q qubits, each gate an update of that list.  Every gate
# here has real entries, so the amplitudes stay real numbers.
import math
R = 1 / math.sqrt(2)

def h(s, k, q):                  # Hadamard on qubit k of q (qubit 0 is the leftmost bit)
    b, t = 1 << (q - 1 - k), s[:]
    for i in range(len(s)):
        if not i & b:
            t[i], t[i | b] = R * (s[i] + s[i | b]), R * (s[i] - s[i | b])
    return t
def xg(s, k, q):                 # X, the NOT gate, on qubit k
    return [s[i ^ (1 << (q - 1 - k))] for i in range(len(s))]
def oracle(s, f):                # U_f: (inputs, y) -> (inputs, y xor f(inputs)); y is the last qubit
    return [s[i ^ f[i >> 1]] for i in range(len(s))]
def bad_oracle(s, f):            # (inputs, y) -> (inputs, f(inputs)): overwrites y, not reversible
    t = [0.0] * len(s)
    for i in range(len(s)):
        t[(i >> 1 << 1) | f[i >> 1]] += s[i]
    return t
def run(f, n, flip=True, last_h=True):    # n input qubits, one answer qubit; returns Pr[inputs read 0]
    q = n + 1
    s = [0.0] * (1 << q); s[0] = 1.0
    if flip: s = xg(s, n, q)
    for k in range(q): s = h(s, k, q)
    s = oracle(s, f)
    if last_h:
        for k in range(n): s = h(s, k, q)
    return s[0] ** 2 + s[1] ** 2
def sign_sum(f):                 # the closed form: (average of (-1)^f(x)) squared
    return (sum((-1) ** v for v in f) / len(f)) ** 2

def kron(a, b): return [[x * y for x in ra for y in rb] for ra in a for rb in b]
def mul(a, b): return [[sum(a[i][k] * b[k][j] for k in range(len(b))) for j in range(len(b[0]))] for i in range(len(a))]
def perm(f): return [[1.0 if i == j ^ f[j >> 1] else 0.0 for j in range(4)] for i in range(4)]
I2, X2, H2 = [[1, 0], [0, 1]], [[0, 1], [1, 0]], [[R, R], [R, -R]]

DEUTSCH = {"constant 0": (0, 0), "constant 1": (1, 1), "copy, the adder's sum bit": (0, 1), "negate": (1, 0)}
print("Deutsch's test, one query: Pr[first qubit reads 1] for each one-bit function")
for name, f in DEUTSCH.items():
    p1, formula = 1 - run(f, 1), 1 - sign_sum(f)
    U = mul(kron(H2, I2), mul(perm(f), mul(kron(H2, H2), kron(I2, X2))))     # whole circuit as one matrix
    UtU = mul([list(r) for r in zip(*U)], U)
    unitary = all(abs(UtU[i][j] - (i == j)) < 1e-12 for i in range(4) for j in range(4))
    matrix_p1 = U[2][0] ** 2 + U[3][0] ** 2
    print(f"  f = {name:<26} {p1:.6f}  {'#' * round(20 * p1):<20}  formula {formula:.6f}  matrix {matrix_p1:.6f}  unitary {'yes' if unitary else 'no'}")
    assert abs(p1 - formula) < 1e-12 and abs(p1 - matrix_p1) < 1e-12 and unitary
    assert round(p1) == (f[0] != f[1])
s, cp = [1.0, 0.0, 0.0, 0.0], (0, 1)            # the copy function, traced step by step
print("trace for f = copy, amplitudes of 00 01 10 11:")
for label, step in [("after X on the answer qubit", lambda s: xg(s, 1, 2)), ("after H on both", lambda s: h(h(s, 0, 2), 1, 2)),
                    ("after U_f", lambda s: oracle(s, cp)), ("after H on the first", lambda s: h(s, 0, 2))]:
    s = step(s)
    print(f"  {label:<30}" + " ".join(f"{a:+.4f}" for a in s))
one_query = [sum((ans[f[b]] == (f[0] != f[1])) for f in DEUTSCH.values())
             for b in (0, 1) for ans in ((0, 0), (0, 1), (1, 0), (1, 1))]
print(f"best classical one-query strategy: right on {max(one_query)} of 4 functions")
assert max(one_query) == 2

tables = [tuple((m >> (3 - j)) & 1 for j in range(4)) for m in range(16)]
const = [t for t in tables if len(set(t)) == 1]
bal = [t for t in tables if sum(t) == 2]
dj = [run(f, 2) for f in const + bal]
print(f"Deutsch-Jozsa on two-bit inputs: {len(const)} constant, {len(bal)} balanced; Pr[inputs read 00]: "
      + " ".join(f"{p:.6f}" for p in dj))
assert all(abs(p - sign_sum(f)) < 1e-12 for p, f in zip(dj, const + bal)) and dj == sorted(dj, reverse=True)
off = run((0, 0, 0, 1), 2)                       # outside the promise: one 1 in four
print(f"no promise, f = 0001: Pr[inputs read 00] {off:.6f}")
assert abs(off - sign_sum((0, 0, 0, 1))) < 1e-12 and abs(off - 0.25) < 1e-12
pairs = [(a, b) for a in range(4) for b in range(a + 1, 4)]
fooled = sum(any(c[a] == g[a] and c[b] == g[b] for c in const for g in bal) for a, b in pairs)
triples = [(a, b, c) for a in range(4) for b in range(a + 1, 4) for c in range(b + 1, 4)]
fooled3 = sum(any(all(k[i] == g[i] for i in t) for k in const for g in bal) for t in triples)
err2 = sum(f[a] == f[b] for f in bal for a, b in pairs) / (len(bal) * len(pairs))
print(f"two classical queries: {fooled} of {len(pairs)} pairs fit a constant and a balanced function; "
      f"three queries: {fooled3} of {len(triples)} triples")
print(f"two random distinct queries call a balanced function constant with probability {err2:.6f}")
assert fooled == 6 and fooled3 == 0 and abs(err2 - 1 / 3) < 1e-12
print("exact classical queries for n input bits, against 1 quantum query:")
for n in (2, 10, 20, 40):
    print(f"  n = {n:<3} {2 ** (n - 1) + 1}")
err10 = max(sum((f.count(v) / 4) ** 10 for v in (0, 1)) for f in bal)   # all ten see one value
print(f"ten random queries with repeats call a balanced function constant with probability {err10:.6f}")
assert abs(err10 - 2 ** (1 - 10)) < 1e-15

def majority_error(p, k):        # exact chance that at least half of k runs are wrong
    return sum(math.comb(k, j) * p ** j * (1 - p) ** (k - j) for j in range((k + 1) // 2, k + 1))
print("majority of k runs, each wrong with probability 1/3: exact error, then the bound exp(-k/18)")
for k in (1, 5, 15, 25, 51):
    e, bound = majority_error(1 / 3, k), math.exp(-k / 18)
    print(f"  k = {k:<3} {e:.6f}  {bound:.6f}")
    assert e <= bound
assert majority_error(1 / 3, 15) < majority_error(1 / 3, 5) < 1 / 3
print("amplitudes a classical simulator stores, 16 bytes each:")
for q in (10, 20, 30, 40, 50):
    print(f"  {q} qubits  {2 ** q} amplitudes  {16 * 2 ** q} bytes")
print("what breaks, for constant 0, constant 1, copy, negate:")
print("  answer qubit left at 0: Pr[reads 1] " + " ".join(f"{1 - run(f, 1, flip=False):.6f}" for f in DEUTSCH.values()))
print("  no final H: Pr[reads 1] " + " ".join(f"{1 - run(f, 1, last_h=False):.6f}" for f in DEUTSCH.values()))
lost = sum(a * a for a in bad_oracle(h(h([0.0, 1.0, 0.0, 0.0], 0, 2), 1, 2), (0, 0)))
print(f"  oracle that overwrites y, f = constant 0: total probability {lost:.6f}")
print(f"  each run wrong with probability 1/2: majority of 15 runs wrong with probability {majority_error(0.5, 15):.6f}")
assert lost < 1e-12 and abs(majority_error(0.5, 15) - 0.5) < 1e-12
print("figure, wires y=70,150; X x=90; H x=170; U_f x=260; H x=350; meter x=430")
print("ALL CHECKS PASS")
