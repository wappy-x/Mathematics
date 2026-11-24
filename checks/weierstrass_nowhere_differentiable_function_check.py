# Weierstrass's monster -- the check behind the card.  Standard library only.
# f(x) = sum over n >= 0 of (3/4)^n phi(4^n x), phi = distance to the nearest
# integer.  Every quotient is reached two ways, and the slope bound is tested.

def phi(t):                                 # distance from t to the nearest integer
    return abs(t - round(t))

def f(x, layers, a=0.75):                   # the first `layers` sawtooth layers
    return sum(a ** n * phi(4 ** n * x) for n in range(layers))

for N in (1, 3, 12):
    print(f"chart {N} layers:", " ".join(f"{f(i / 20, N) + 1e-12:.2f}" for i in range(21)))  # ties like 0.625 round up
tail = lambda N: 2 * 0.75 ** N              # caps 0.5 (3/4)^n left after N layers
N = next(k for k in range(100) if tail(k) < 0.001)
print(f"M-test: caps add to {tail(0):.6f}; first N with leftover below 0.001: N={N}, leftover {tail(N):.6f}")
third = sum(0.75 ** n * min(4 ** n % 3, 3 - 4 ** n % 3) / 3 for n in range(N))
gap = 4 / 3 - third                         # closed form: phi(4^n / 3) = 1/3 always
assert 0 < gap <= tail(N)
print(f"f(1/3): closed form {4 / 3:.6f}, {N} layers {third:.6f}, gap {gap:.6f}")
by_layers = [(f(4.0 ** -m, 60) - f(0, 60)) / 4.0 ** -m for m in range(1, 9)]
closed = [(3 ** m - 1) // 2 for m in range(1, 9)]
assert by_layers == closed                  # exact: powers of 4 are exact in binary
print("x=0, h=4^-m, m=1..8, by layers:", [int(q) for q in by_layers])
print("x=0, the formula (3^m - 1)/2:  ", closed)
shares = [0.75 ** n * phi(4 ** n / 64) * 64 for n in range(6)]  # exact in binary
print("h=1/64, layer shares in 64ths:", [int(v) for v in shares], "total", int(sum(shares)))
cut = [(f(4.0 ** -m, 5) - f(0, 5)) / 4.0 ** -m for m in range(1, 9)]
print("only 5 layers:", [int(q) for q in cut])
slow = [(f(4.0 ** -m, 60, 0.125) - f(0, 60, 0.125)) / 4.0 ** -m for m in range(1, 9)]
print("heights (1/8)^n, x=0, step to the right:", " ".join(f"{q:.4f}" for q in slow))
for s, c in ((1, 5 / 3), (-1, 1)):          # x = 1/3, heights (1/8)^n: by hand, 2 - c / 2^(m-1)
    q = [(f(1 / 3 + s * 4.0 ** -m, 60, 0.125) - f(1 / 3, 60, 0.125)) / (s * 4.0 ** -m) for m in range(1, 9)]
    assert all(abs(v - (2 - c / 2 ** (m - 1))) < 1e-9 for m, v in enumerate(q, 1))
    print(f"heights (1/8)^n, x=1/3, step to the {'right' if s > 0 else 'left'}:", " ".join(f"{v:.4f}" for v in q))
signs, exact, roads, bound = [], [], [], []
for m in range(1, 9):                       # x = 3/10, exact, in units of 1/Q
    Q, P = 10 * 4 ** (m + 1), 3 * 4 ** (m + 1)
    t = (P * 4 ** m) % Q % (Q // 2)         # where 4^m x sits on its straight piece
    s = 1 if 4 * t <= Q else -1             # step right or left by 4^-(m+1)
    d = lambda p, n: min(p * 4 ** n % Q, Q - p * 4 ** n % Q)
    D = [d(P + 10 * s, n) - d(P, n) for n in range(m + 25)]
    assert all(v == 0 for v in D[m + 1:])   # deeper layers move by a whole number
    num = s * sum(3 ** n * 4 ** (m + 1 - n) * D[n] for n in range(m + 1))
    assert num % Q == 0
    sig = []                                # road two: the slope of phi at each layer
    for n in range(m + 1):
        r = 3 * 4 ** n % 10                 # 4^n x = (3 * 4^n)/10, its tenths digit
        sig.append(1 if (r < 5 if s > 0 else 0 < r <= 5) else -1)
    signs.append(s); exact.append(num // Q)
    h = s * 4.0 ** -(m + 1)                 # road three: the float sum itself
    assert abs((f(0.3 + h, m + 2) - f(0.3, m + 2)) / h - exact[-1]) < 1e-6
    roads.append(sum(3 ** n * g for n, g in enumerate(sig)))
    bound.append((3 ** m + 1) // 2)
    assert abs(exact[-1]) >= bound[-1]
assert exact == roads
print("x=0.3, step sign by m:", signs)
print("x=0.3, quotient by exact layers:", exact)
print("x=0.3, quotient by slope signs: ", roads)
print("x=0.3, proof's floor (3^m + 1)/2:", bound)
print("ALL CHECKS PASS")
