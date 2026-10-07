# The matrix exponential -- the check behind the card.  Standard library only.
# Two rooms share a wall, heating off: T' = A T, T(0) = (30, 10) C above outside.
# Roads: the power series summed term by term, the eigenvector formula, Euler steps.
# Second case: a heater warming a room, J = [[-1, 1], [0, -1]], one eigenvector.
import math

A, J, T0, R0 = [[-2.0, 1.0], [1.0, -2.0]], [[-1.0, 1.0], [0.0, -1.0]], [30.0, 10.0], [0.0, 10.0]
P, Q = [[0.0, 1.0], [0.0, 0.0]], [[0.0, 0.0], [1.0, 0.0]]   # the wall's two one-way flows

def mul(X, Y):
    return [[X[i][0] * Y[0][j] + X[i][1] * Y[1][j] for j in range(2)] for i in range(2)]

def expm(M, t, terms=60):                     # I + Mt + (Mt)^2/2! + ... term by term
    S, term = [[1.0, 0.0], [0.0, 1.0]], [[1.0, 0.0], [0.0, 1.0]]
    for k in range(1, terms):
        term = [[v * t / k for v in row] for row in mul(term, M)]   # (Mt)^k / k!
        S = [[S[i][j] + term[i][j] for j in range(2)] for i in range(2)]
    return S

def eig_form(t):                              # 0.5 [[e^-t + e^-3t, e^-t - e^-3t], ...]
    p, m = (math.exp(-t) + math.exp(-3 * t)) / 2, (math.exp(-t) - math.exp(-3 * t)) / 2
    return [[p, m], [m, p]]

def euler(M, v, t_end, h):                    # new state = old state + h x rate
    for _ in range(round(t_end / h)):
        d = app(M, v)
        v = [v[0] + h * d[0], v[1] + h * d[1]]
    return v

app = lambda M, v: [M[0][0] * v[0] + M[0][1] * v[1], M[1][0] * v[0] + M[1][1] * v[1]]
gap = lambda X, Y: max(abs(X[i][j] - Y[i][j]) for i in range(2) for j in range(2))
yn = lambda c: "yes" if c else "no"
fm = lambda X: "[[" + "], [".join(", ".join(f"{v:.6f}" for v in r) for r in X) + "]]"
E1, times = expm(A, 1.0), [0.5 * k for k in range(7)]
semi, err = mul(expm(A, 0.5), expm(A, 1.0)), [abs(euler(A, T0, 1, h)[0] - app(eig_form(1), T0)[0]) for h in (0.01, 0.005, 0.0025)]
EJ, heat = expm(J, 1.0), [app(expm(J, 0.5 * k), R0)[0] for k in range(9)]
split = [math.exp(-2) * v for v in app(mul(expm(P, 1), expm(Q, 1)), T0)]
print(f"series e^(A*1):      {fm(E1)}")
print(f"eigenvectors e^(A*1): {fm(eig_form(1.0))}; agree to 1e-12: {yn(gap(E1, eig_form(1.0)) < 1e-12)}")
print(f"rooms at t = 1 h: T1 = {app(E1, T0)[0]:.4f} C, T2 = {app(E1, T0)[1]:.4f} C; 20e^-1 + 10e^-3 = {20 * math.exp(-1) + 10 * math.exp(-3):.4f}")
print("t (h)  ", " ".join(f"{t:5.1f}" for t in times))
print("T1 (C) ", " ".join(f"{app(expm(A, t), T0)[0]:5.2f}" for t in times))
print("T2 (C) ", " ".join(f"{app(expm(A, t), T0)[1]:5.2f}" for t in times))
print(f"e^(A*0.5) e^(A*1) = {fm(semi)}")
print(f"e^(A*1.5), eigen  = {fm(eig_form(1.5))}; agree: {yn(gap(semi, eig_form(1.5)) < 1e-12)}")
print("Euler T1(1) error, h = 0.01, 0.005, 0.0025:", " ".join(f"{e:.5f}" for e in err), f"ratios {err[0] / err[1]:.2f} {err[1] / err[2]:.2f}")
print(f"series e^(J*1) = {fm(EJ)}; equals e^-1 [[1, 1], [0, 1]]: {yn(gap(EJ, [[math.exp(-1)] * 2, [0.0, math.exp(-1)]]) < 1e-12)}")
print("heater case t (h)  ", " ".join(f"{0.5 * k:4.1f}" for k in range(9)))
print("room R = 10te^-t (C)", " ".join(f"{r:4.2f}" for r in heat))
print(f"room peak: t = 1 h, R = {heat[2]:.4f} C = 10/e = {10 / math.e:.4f}")
print(f"mistake, e^ entry by entry: T1(1) = {30 * math.exp(-2) + 10 * math.exp(1):.2f} C, not {app(E1, T0)[0]:.2f}")
print(f"mistake, e^-2 e^P e^Q for e^(A*1): T1(1) = {split[0]:.2f} C")
print(f"mistake, J's start times e^-t: R(1) = {0 * math.exp(-1):.2f} C, not {heat[2]:.2f}")
print(f"mistake, three terms at t = 3 h: T1 = {app(expm(A, 3, 3), T0)[0]:.2f} C, not {app(eig_form(3), T0)[0]:.4f}")
assert gap(E1, eig_form(1.0)) < 1e-12                               # series = eigenvectors
assert gap(semi, eig_form(1.5)) < 1e-12                             # e^(As) e^(At) = e^(A(s+t))
assert all(abs(heat[k] - 5 * k * math.exp(-0.5 * k)) < 1e-12 for k in range(9))   # J by hand
assert 1.9 < err[0] / err[1] < 2.1 and 1.9 < err[1] / err[2] < 2.1  # Euler converges, order one
print("ALL CHECKS PASS")
