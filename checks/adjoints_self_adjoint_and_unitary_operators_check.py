# Adjoints -- the check behind the card.  Standard library only.
# An 8-speaker ring: turn R, causal blur A, binomial blur B, box blur C.
# Each adjoint is built from the swapped-kernel formula, never by transposing,
# then tested against <Tf, g> = <f, T*g>.  Eigenvalues come from a closed form
# and are checked by residuals and by the trace and size sums.
from math import cos, sin, pi, sqrt

def clean(x): return 0.0 if abs(x) < 5e-13 else x
def ring(n, taps):          # kernel k(j, l) = taps[(j - l) mod n]
    return [[taps.get((j - l) % n, 0.0) for l in range(n)] for j in range(n)]
def adj_taps(n, taps):      # swapped kernel: k*(j, l) = k(l, j), real entries
    return {(-d) % n: v for d, v in taps.items()}
def apply(T, f): return [sum(T[j][l] * f[l] for l in range(len(f))) for j in range(len(T))]
def ip(f, g): return sum(a.conjugate() * b for a, b in zip(f, g))   # conjugates the first slot
def mul(S, T): return [[sum(S[j][k] * T[k][l] for k in range(len(T))) for l in range(len(T))] for j in range(len(S))]
def tr(T): return [[T[l][j] for l in range(len(T))] for j in range(len(T))]
def same(S, T): return max(abs(S[j][l] - T[j][l]) for j in range(len(S)) for l in range(len(S))) < 1e-12
def eig(n, taps, m):        # closed form: the Fourier mode m is an eigenvector of every ring operator
    return sum(v * complex(cos(2 * pi * m * d / n), -sin(2 * pi * m * d / n)) for d, v in taps.items())

N = 8
I = ring(N, {0: 1.0})
ops = {"turn R": {1: 1.0}, "causal blur A": {0: 0.5, 1: 0.5},
       "binomial blur B": {0: 0.5, 1: 0.25, N - 1: 0.25}, "box blur C": {0: 1 / 3, 1: 1 / 3, N - 1: 1 / 3}}
f = [4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]
g = [0.0, 1.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0]
print(f"ring N = {N}; f = 4 2 0 0 0 0 0 1; g = 0 1 3 0 0 0 0 0")
print("operator            <Tf,g>   <f,T*g>    <f,Tg>  T*=T  unitary  normal    min eig  max |eig|")
for name, t in ops.items():
    T, Ts = ring(N, t), ring(N, adj_taps(N, t))
    for j in range(N):      # the defining identity on every pair of basis vectors pins T* down
        for l in range(N):
            e, h = [float(k == j) for k in range(N)], [float(k == l) for k in range(N)]
            assert abs(ip(apply(T, e), h) - ip(e, apply(Ts, h))) < 1e-15
    assert same(Ts, tr(T))  # road 2: the swapped kernel is the transpose
    lam = [eig(N, t, m) for m in range(N)]
    for m in range(N):      # road 3: residual |T v - lam v| for each Fourier mode
        v = [complex(cos(2 * pi * m * k / N), sin(2 * pi * m * k / N)) for k in range(N)]
        assert max(abs(a - lam[m] * b) for a, b in zip(apply(T, v), v)) < 1e-12
    assert abs(sum(lam) - sum(T[k][k] for k in range(N))) < 1e-12          # trace
    assert abs(sum(abs(z) ** 2 for z in lam) - sum(x * x for r in T for x in r)) < 1e-12  # normal: sizes match
    sa, un = same(Ts, T), same(mul(Ts, T), I) and same(mul(T, Ts), I)
    nm = same(mul(Ts, T), mul(T, Ts))
    mn = f"{clean(min(z.real for z in lam)):9.6f}" if sa else "    -    "
    print(f"{name:<16}{ip(apply(T, f), g):10.6f}{ip(f, apply(Ts, g)):10.6f}{ip(f, apply(T, g)):10.6f}"
          f"  {'yes' if sa else 'no '}   {'yes' if un else 'no '}      {'yes' if nm else 'no '} {mn}  {max(abs(z) for z in lam):8.6f}")
    assert nm and sa == (name[-1] in "BC") and un == (name[-1] == "R")

R, A, B, C = (ring(N, t) for t in ops.values())
As = ring(N, adj_taps(N, ops["causal blur A"]))
assert same(mul(As, A), B)                       # B = A*A, so <f, Bf> = |Af|^2 >= 0
Bf, Af, Rf = apply(B, f), apply(A, f), apply(R, f)
print("Bf =", " ".join(f"{x:g}" for x in Bf), "; Af =", " ".join(f"{x:g}" for x in Af))
print("Rf =", " ".join(f"{x:g}" for x in Rf), "; R*g =", " ".join(f"{x:g}" for x in apply(tr(R), g)),
      "; A*g =", " ".join(f"{x:g}" for x in apply(As, g)))
print(f"<f,Bf> = {ip(f, Bf):.6f}; |Af|^2 = {ip(Af, Af):.6f}; |f|^2 = {ip(f, f):.6f}; |Rf|^2 = {ip(Rf, Rf):.6f}")
assert abs(ip(f, Bf) - ip(Af, Af)) < 1e-12 and abs(ip(Rf, Rf) - ip(f, f)) < 1e-12
alt = [(-1.0) ** k for k in range(N)]          # neighboring speakers in opposite phase
print(f"alternating h: <h,Ch> = {ip(alt, apply(C, alt)):.6f}; <h,Bh> = {clean(ip(alt, apply(B, alt))):.6f}; |h|^2 = {ip(alt, alt):.6f}")
assert abs(ip(alt, apply(C, alt)) + 8 / 3) < 1e-12

# the positive square root of B: keep B's Fourier modes, take square roots of its eigenvalues
p = {k: sum(abs(cos(pi * m / N)) * cos(2 * pi * m * k / N) for m in range(N)) / N for k in range(N)}
P = ring(N, p)
assert same(mul(P, P), B) and same(P, tr(P)) and min(eig(N, p, m).real for m in range(N)) > -1e-12
assert not same(P, A)                          # A*A = B too, but A is not self-adjoint
print("square root P of B, taps k = 0..4:", " ".join(f"{clean(p[k]):.6f}" for k in range(5)))

# infinite dimensions: the delay S on an endless signal, cut to its first N samples
print("N    |S*Sf - f|   |SS*f - f|   sum|eig|^2   sum|entry|^2   (f = 1, 1/2, 1/4, ...)")
for n in (4, 8, 16, 32, 64):
    S = [[float(j == l + 1) for l in range(n)] for j in range(n)]
    fn = [0.5 ** k for k in range(n)]
    d1 = sqrt(sum(x * x for x in (a - b for a, b in zip(apply(tr(S), apply(S, fn)), fn))))
    d2 = sqrt(sum(x * x for x in (a - b for a, b in zip(apply(S, apply(tr(S), fn)), fn))))
    fro, eigs = sum(x * x for r in S for x in r), sum(S[k][k] ** 2 for k in range(n))  # triangular: eigs on diagonal
    print(f"{n:<4} 2^-{n - 1:<9} {d2:10.6f}   {eigs:10.6f}   {fro:12.6f}")
    assert d1 == 0.5 ** (n - 1) and abs(d2 - 1.0) < 1e-15 and fro == n - 1

# what breaks, and the try-changing box
print(f"wrong: R* = R gives <f,Rg> = {ip(f, apply(R, g)):.6f}; wrong: A* = A gives <f,Ag> = {ip(f, apply(A, g)):.6f}")
for n in (8, 9):
    print(f"N = {n}: min eig box C = {min((1 + 2 * cos(2 * pi * m / n)) / 3 for m in range(n)):.6f}; "
          f"binomial B = {clean(min(cos(pi * m / n) ** 2 for m in range(n))):.6f}")
print(f"weights 0.3 0.4 0.3: min eig = {min(eig(N, {0: 0.4, 1: 0.3, N - 1: 0.3}, m).real for m in range(N)):.6f}")
print(f"turn by 2 speakers: eigenvalues of R^2 have |eig| = {max(abs(eig(N, {2: 1.0}, m)) for m in range(N)):.6f}")
lamA = [eig(N, ops["causal blur A"], m) for m in range(N)]
assert max(abs(abs(z - 0.5) - 0.5) for z in lamA) < 1e-12   # A's eigenvalues sit on a circle
print("figure, R on |z| = 1; A on |z - 0.5| = 0.5; B in [0, 1]; C in [-0.333333, 1]; A at m = 2:",
      f"{lamA[2].real:.6f} {lamA[2].imag:.6f}")
print("ALL CHECKS PASS")
