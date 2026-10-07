# Linearisation and the Jacobian -- the check behind the card.  Standard library
# only.  The swing: theta'' + 0.5 theta' + sin theta = 0, written as the pair
# theta' = w, w' = -sin(theta) - 0.5 w; time in units of 0.5 s.  An optional
# air drag k w|w| makes the centre case.  Runge-Kutta 4 is written out here.
from math import sin, cos, sqrt, pi, exp, log
def rate(s, c=0.5, k=0.0):
    return (s[1], -sin(s[0]) - c * s[1] - k * s[1] * abs(s[1]))
def rk4(s, t, c=0.5, k=0.0, h=0.01):              # returns every state along the way
    path = [s]
    for _ in range(round(t / h)):
        a = rate(s, c, k); b = rate((s[0] + h/2*a[0], s[1] + h/2*a[1]), c, k)
        d = rate((s[0] + h/2*b[0], s[1] + h/2*b[1]), c, k); e = rate((s[0] + h*d[0], s[1] + h*d[1]), c, k)
        s = (s[0] + h/6*(a[0] + 2*b[0] + 2*d[0] + e[0]), s[1] + h/6*(a[1] + 2*b[1] + 2*d[1] + e[1]))
        path.append(s)
    return path
def nudged(p, e=1e-5):                            # road two: slopes by nudging each variable
    col = lambda j: [(rate((p[0] + e*(j == 0), p[1] + e*(j == 1)))[i]
                      - rate((p[0] - e*(j == 0), p[1] - e*(j == 1)))[i]) / (2*e) for i in (0, 1)]
    c0, c1 = col(0), col(1)
    return [[c0[0], c1[0]], [c0[1], c1[1]]]
def classify(J):                                  # road one: trace, determinant, eigenvalues
    tr, det = J[0][0] + J[1][1], J[0][0]*J[1][1] - J[0][1]*J[1][0]
    disc = tr*tr - 4*det
    return tr, det, disc, (tr/2, sqrt(-disc)/2) if disc < 0 else ((tr + sqrt(disc))/2, (tr - sqrt(disc))/2)
energy = lambda s: s[1]**2/2 + 1 - cos(s[0])
fmt = lambda J: "[[%g, %g], [%g, %g]]" % (J[0][0], J[0][1], J[1][0], J[1][1])
print("swing theta'' + 0.5 theta' + sin theta = 0, time unit 0.5 s; rests where w = 0 and sin theta = 0")
for name, th in (("hanging (0, 0)", 0.0), ("inverted (pi, 0)", pi)):
    J = [[0.0, 1.0], [-cos(th), -0.5]]                        # the partial derivatives, by hand
    tr, det, disc, (l1, l2) = classify(J)
    err = max(abs(J[i][j] - nudged((th, 0.0))[i][j]) for i in (0, 1) for j in (0, 1))
    assert err < 1e-8                                         # the two roads to J agree
    kind = "%.6f +/- %.6fi: stable spiral" % (l1, l2) if disc < 0 else "%.6f and %.6f: %s" % (l1, l2, "saddle" if det < 0 else "node")
    print(f"{name}: J = {fmt(J)}, trace {tr:g}, det {det:g}, disc {disc:g}; eigenvalues {kind}")
b = classify([[0.0, 1.0], [-1.0, -0.5]])[3][1]                # road one's eigenvalues, tested below
print(f"hanging: one swing {2*pi/b:.4f} units = {pi/b:.4f} s; amplitude kept per swing {exp(-0.25*2*pi/b):.4f}")
lin = 0.01*exp(-2.5)*(cos(10*b) + 0.25/b*sin(10*b))           # the linear model's exact answer
non = rk4((0.01, 0.0), 10)[-1][0]                             # the true swing, stepped
assert abs(non - lin) < 1e-3*abs(lin)
print(f"road two, hanging: released at 0.01 rad, theta at t = 10 in 1e-4 rad: swing {non*1e4:.6f}, linear {lin*1e4:.6f}")
lu = classify([[0.0, 1.0], [1.0, -0.5]])[3][0]
end = rk4((pi + 1e-6, 1e-6*lu), 10)[-1]
grow = log(sqrt((end[0] - pi)**2 + end[1]**2) / (1e-6*sqrt(1 + lu*lu))) / 10
assert abs(grow - lu) < 1e-3                                  # measured escape rate = eigenvalue
print(f"road two, inverted: nudged 1e-6 along the out-direction, escape rate {grow:.6f} per unit; "
      f"doubling time {log(2)/lu:.4f} units")
print("centre case, air drag k w|w|: its slope at w = 0 is 0, so J = [[0, 1], [-1, 0]], trace 0, det 1")
e0, ef = energy((0.5, 0.0)), energy(rk4((0.5, 0.0), 60, 0.0, 0.0)[-1])
ed, A = energy(rk4((0.5, 0.0), 60, 0.0, 0.5)[-1]), 0.5/(1 + 4*0.5*0.5*60/(3*pi))
assert abs(ed - (1 - cos(A))) < 0.01*ed                       # stepped drag swing vs averaged loss
print(f"released at 0.5 rad, energy {e0:.6f}; at t = 60: no drag {ef:.6f}, drag 0.5 {ed:.6f}, averaged estimate {1 - cos(A):.6f}")
print(f"mistake 1, cos(pi) read as +1: det {classify([[0, 1], [-1, -0.5]])[1]:g}, disc {classify([[0, 1], [-1, -0.5]])[2]:g}, a spiral, not the saddle")
print(f"mistake 2, linearising at (pi/2, 0): rates there are {rate((pi/2, 0.0))[0]:g} and {rate((pi/2, 0.0))[1]:g}, not a rest")
px = lambda p: "%.1f,%.1f" % (95 + 55*p[0], 95 - 55*p[1])
pts = rk4((2.0, 0.0), 12)[::25]
print("figure, rests " + px((0, 0)) + " " + px((pi, 0)) + "; out-line " + px((pi - 0.6, -0.6*lu)) + " " + px((pi + 0.6, 0.6*lu))
      + "; in-line " + px((pi - 0.5, 0.5*(lu + 0.5))) + " " + px((pi + 0.5, -0.5*(lu + 0.5))))
print("figure, path released at (2, 0), every 0.25 up to t = 12: " + " ".join(px(p) for p in pts))
print("ALL CHECKS PASS")
