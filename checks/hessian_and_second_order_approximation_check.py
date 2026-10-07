# Hessian check, nothing imported.  Heat loss Q in watts through 100 m^2 of wall:
# insulation t cm thick, window area A m^2, 20 degrees inside to out.  Road 1:
# hand-derived gradient and Hessian.  Road 2: difference quotients of Q alone.
# Road 3: Q along the straight path to the new design, as one variable.

def Q(t, A):
    return 20 * ((100 - A) / (0.5 + t / 4) + 2.8 * A)

t0, A0, ht, hA = 10.0, 20.0, 1.0, 2.0              # current design, and the step
R = 0.5 + t0 / 4                                   # wall resistance, 3
g = (-20 * (100 - A0) / (4 * R * R), 20 * (2.8 - 1 / R))         # road 1: Q_t, Q_A
H = ((40 * (100 - A0) / (16 * R ** 3), 5 / (R * R)), (5 / (R * R), 0.0))

def model(s, order, half=0.5, mixed=1):            # tangent plane or quadratic at s*step
    a, b = s * ht, s * hA
    lin = Q(t0, A0) + g[0] * a + g[1] * b
    quad = H[0][0] * a * a + mixed * 2 * H[0][1] * a * b + H[1][1] * b * b
    return lin + (half * quad if order == 2 else 0)

def rect(h, k):                                    # double difference over an h-by-k rectangle
    return (Q(t0 + h, A0 + k) - Q(t0 + h, A0) - Q(t0, A0 + k) + Q(t0, A0)) / (h * k)

e = 0.01                                           # road 2: centred differences, step e
Qtt = (Q(t0 + e, A0) - 2 * Q(t0, A0) + Q(t0 - e, A0)) / e ** 2
QAA = round((Q(t0, A0 + e) - 2 * Q(t0, A0) + Q(t0, A0 - e)) / e ** 2, 4) + 0.0
QtA = (Q(t0 + e, A0 + e) - Q(t0 + e, A0 - e) - Q(t0 - e, A0 + e) + Q(t0 - e, A0 - e)) / (4 * e * e)
phi = lambda s: Q(t0 + s * ht, A0 + s * hA)        # road 3: the path as one variable
phi2 = (phi(e) - 2 * phi(0) + phi(-e)) / e ** 2
hHh = H[0][0] * ht * ht + 2 * H[0][1] * ht * hA + H[1][1] * hA * hA
rem = phi(1) - model(1, 2)
win = tuple(-20 * (100 - A0 + 4 * hA * R / ht) * (ht / 4) ** 3 / u ** 4 for u in (R, R + ht / 4))  # phi'''/6, u from 3 to 3.25
e1 = [abs(phi(s) - model(s, 1)) for s in (1, 0.5, 0.25)]
e2 = [abs(phi(s) - model(s, 2)) for s in (1, 0.5, 0.25)]
f = lambda x, y: 0.0 if x == y == 0 else x * y * (x * x - y * y) / (x * x + y * y)
d = 1e-7
fx = lambda y: (f(d, y) - f(-d, y)) / (2 * d)      # slope in x, on the line x = 0
fy = lambda x: (f(x, d) - f(x, -d)) / (2 * d)      # slope in y, on the line y = 0
print(f"current design: Q(10, 20) = {Q(t0, A0):.3f} W")
print(f"road 1 gradient: Q_t = {g[0]:.3f} W per cm, Q_A = {g[1]:.3f} W per m^2")
print(f"road 1 Hessian: Q_tt = {H[0][0]:.4f}, Q_tA = Q_At = {H[0][1]:.4f}, Q_AA = {H[1][1]:.4f}")
print(f"road 2 differences: Q_tt = {Qtt:.4f}, Q_tA = {QtA:.4f}, Q_AA = {QAA:.4f}")
print("rectangle quotient, 1 x 2, 0.1 x 0.2, 0.01 x 0.02: " + ", ".join(f"{rect(k, 2 * k):.4f}" for k in (1, 0.1, 0.01)))
print(f"step (1 cm, 2 m^2): exact {phi(1):.3f}, tangent plane {model(1, 1):.3f}, quadratic {model(1, 2):.3f}")
print(f"correction {model(1, 2) - model(1, 1):.3f} = {0.5 * H[0][0]:.3f} thickness + {2 * H[0][1]:.3f} mixed + {2 * H[1][1]:.3f} windows")
print(f"road 3, along the path: phi''(0) = {phi2:.4f}, h^T H h = {hHh:.4f}")
print(f"remainder {rem:.4f}, Lagrange window [{win[0]:.4f}, {win[1]:.4f}]")
print("error at s = 1, 0.5, 0.25: tangent " + ", ".join(f"{x:.4f}" for x in e1) + "; quadratic " + ", ".join(f"{x:.4f}" for x in e2))
print(f"halving s divides them by {e1[0] / e1[1]:.2f}, {e1[1] / e1[2]:.2f} and {e2[0] / e2[1]:.2f}, {e2[1] / e2[2]:.2f}")
xs = range(-4, 5)
print("chart s: " + ", ".join(str(s) for s in xs))
print("chart exact: " + ", ".join(f"{phi(s):.0f}" for s in xs))
print("chart tangent: " + ", ".join(f"{model(s, 1):.0f}" for s in xs))
print("chart quadratic: " + ", ".join(f"{model(s, 2):.0f}" for s in xs))
print(f"mistakes: no one-half {model(1, 2, half=1):.3f}, no mixed term {model(1, 2, mixed=0):.3f}")
print(f"xy(x^2 - y^2)/(x^2 + y^2) at 0: x then y {(fx(1e-3) - fx(-1e-3)) / 2e-3:.3f}, y then x {(fy(1e-3) - fy(-1e-3)) / 2e-3:.3f}")
assert all(abs(a - b) < 1e-3 for a, b in ((Qtt, H[0][0]), (QtA, H[0][1]), (QAA, H[1][1])))
assert abs(phi2 - hHh) < 1e-3                      # the path's bend is h^T H h
assert win[0] < rem < win[1]                       # the true remainder obeys Lagrange
assert all(abs(e1[i] / e1[i + 1] - 4) < 0.5 and abs(e2[i] / e2[i + 1] - 8) < 0.5 for i in range(2))
print("ALL CHECKS PASS")
