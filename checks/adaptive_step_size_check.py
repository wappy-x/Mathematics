# Adaptive steps on the skydiver v' = 9.8 - 0.2v, v(0) = 0, exact v = 49(1 - e^(-0.2t)).
# Road A: the Dormand-Prince 5(4) pair, stage by stage, with the step controller.
# Road B: closed forms. On this equation every step multiplies the gap 49 - v by a
# polynomial in z = -0.2h, and the exact answer multiplies it by e^z.
from math import exp
A = [[], [1/5], [3/40, 9/40], [44/45, -56/15, 32/9],
     [19372/6561, -25360/2187, 64448/6561, -212/729],
     [9017/3168, -355/33, 46732/5247, 49/176, -5103/18656],
     [35/384, 0, 500/1113, 125/192, -2187/6784, 11/84]]
B4 = [5179/57600, 0, 7571/16695, 393/640, -92097/339200, 187/2100, 1/40]
f = lambda v: 9.8 - 0.2 * v
def comb(v, h, w, k):                            # v + h times the weighted stage rates
    s = 0.0
    for a, q in zip(w, k): s += a * q
    return v + h * s
def pair(v, h):                                  # one Dormand-Prince step: fifth, fourth
    k = []
    for row in A: k.append(f(comb(v, h, row, k)))
    return comb(v, h, A[6], k), comb(v, h, B4, k)
def sci(x, d=4): m, e = f"{x:.{d}e}".split("e"); return f"{m}e{int(e)}"
def allowed(v, w): return 1e-6 * (1 + max(abs(v), abs(w)))
def solve(T, h, safety):
    t, v, ends, lens, rejected = 0.0, 0.0, [], [], 0
    while t < T - 1e-12:
        h = min(h, T - t)
        v5, v4 = pair(v, h)
        est, tol = abs(v5 - v4), allowed(v, v5)
        if est <= tol: t, v = t + h, v5; ends.append(t); lens.append(h)
        else: rejected += 1
        h *= min(5.0, max(0.2, safety * (tol / est) ** 0.2))
    return v, ends, lens, rejected
exact = lambda t: 49 * (1 - exp(-0.2 * t))
poly = lambda z, c: sum(ci * z ** i for i, ci in enumerate(c))
R5 = [1, 1, 1/2, 1/6, 1/24, 1/120, 1/600]
D = [0, 0, 0, 0, 0, -97/120000, 39/120000, -5/120000]   # fifth minus fourth
v5, v4 = pair(0.0, 1.0); est = abs(v5 - v4)
print(f"try h=1.000: fifth {v5:.9f}, fourth {v4:.9f}, estimate {sci(v4 - v5)}, allowed {sci(allowed(0, v5))}")
assert abs(v5 - 49 * (1 - poly(-0.2, R5))) < 1e-12 and abs(v4 - v5 - 49 * poly(-0.2, D)) < 1e-12
print(f"by hand: R5(-0.2) = {poly(-0.2, R5):.9f}, D(-0.2) = {sci(poly(-0.2, D))}")
print(f"road B, estimate 49 D(-0.2) = {sci(49 * poly(-0.2, D))}")
print(f"true error, computed minus exact: fourth {sci(v4 - exact(1))}, fifth {sci(v5 - exact(1))}")
assert abs((v4 - v5) / (v4 - exact(1)) - 1) < 0.1
h1 = 0.9 * (allowed(0, v5) / est) ** 0.2
w5, w4 = pair(0.0, h1); ok = "accepted" if abs(w5 - w4) <= allowed(0, w5) else "rejected"
print(f"retry h={h1:.3f}: estimate {sci(abs(w5 - w4))}, allowed {sci(allowed(0, w5))}, {ok}")
print(f"halve h=1: estimate shrinks by {est / abs(pair(0.0, 0.5)[0] - pair(0.0, 0.5)[1]):.2f} (2^5 = 32)")
rk4 = lambda v, h: 49 - (49 - v) * poly(-0.2 * h, R5[:5])
yc, yf = rk4(0.0, 1.0), rk4(rk4(0.0, 0.5), 0.5)
print(f"step doubling, RK4 h=1: estimate {sci((yc - yf) / 15)}, true fine error {sci(yf - exact(1))}")
assert abs((yc - yf) / 15 / (yf - exact(1)) - 1) < 0.1
v, ends, lens, rej = solve(25.0, 1.0, 0.9)
early = sum(1 for e in ends if e <= 5)
print(f"accepted {len(ends)}, rejected {rej}; first 5 s: {early}, after: {len(ends) - early}")
print("figure, step ends t:", ", ".join(f"{e:.2f}" for e in ends))
print("figure, step lengths h:", ", ".join(f"{x:.2f}" for x in lens))
print(f"v(25): adaptive {v:.9f}, exact {exact(25):.9f}, global error {sci(v - exact(25), 3)}")
assert abs(v - exact(25)) < 1e-5
print(f"breaks: no safety factor rejects {solve(25.0, 1.0, 1.0)[3]}; uniform at smallest h needs {int(25 / min(lens[:-1])) + 1} steps")
print(f"breaks: step doubling divided by 31, not 15: {sci((yc - yf) / 31)}")
print("PASS")
