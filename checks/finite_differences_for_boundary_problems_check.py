# Finite differences for a boundary problem -- the check behind the card.
# Standard library only.  The shelf: y'' = -1 on [0, 1] m, y(0) = y(1) = 0,
# exact sag x(1 - x)/2.  Road one: the Thomas sweep.  Road two: closed forms.
from math import sin, pi, log

def sweep(f, n, h):                     # solve y[i-1] - 2 y[i] + y[i+1] = h^2 f(x_i)
    p, r = [-2.0], [h * h * f(h)]
    for i in range(2, n + 1):           # forward: clear the 1 below each pivot
        q = p[-1]
        p.append(-2.0 - 1.0 / q); r.append(h * h * f(i * h) - r[-1] / q)
    y = [r[-1] / p[-1]]
    for i in range(n - 2, -1, -1):      # back: last unknown first
        y.insert(0, (r[i] - y[0]) / p[i])
    return p, r, y

def row(v, d): return " ".join(f"{a:.{d}f}" for a in v)
uni = lambda x: -1.0                     # even load: w/T = 1 per metre
N, h = 9, 0.1
p, r, y = sweep(uni, N, h)
ex = [(i * h) * (1 - i * h) / 2 for i in range(1, N + 1)]
print(f"shelf: tension 200 N, load 200 N/m, y'' = -1.0 per m; N = {N}, h = {h:.1f} m")
print("pivots p1..p9:", row(p, 4))
print("right sides r1..r9:", row(r, 4))
print("grid y1..y9:", row(y, 6))
print("exact x(1-x)/2:", row(ex, 6))
eu = max(abs(a - b) for a, b in zip(y, ex))
print(f"largest node error, even load: {eu:.10f}; midpoint {y[4]:.6f} m")
heap = lambda x: -(pi / 2) * sin(pi * x)  # same total load, heaped in the middle
M = pi ** 3 / 2                          # largest size of y'''' for sin(pi x)/(2 pi)
errs, gap = [], 0.0
for n in (9, 19, 39):
    hh = 1 / (n + 1); _, _, yh = sweep(heap, n, hh)
    eig = [(pi / 2) * sin(pi * i * hh) * hh * hh / (4 * sin(pi * hh / 2) ** 2) for i in range(1, n + 1)]
    gap = max(gap, max(abs(a - b) for a, b in zip(yh, eig)))
    m = n // 2; exm = 1 / (2 * pi); errs.append(yh[m] - exm)
    print(f"heaped N = {n}, h = {hh:.4f}: grid {yh[m]:.6f}, eigen formula {eig[m]:.6f}, "
          f"exact {exm:.6f}, error {errs[-1]:.8f}, bound {hh * hh * M / 96:.8f}")
    assert 0.7 * hh * hh * M / 96 < errs[-1] < hh * hh * M / 96   # max-principle bound
rat = [errs[0] / errs[1], errs[1] / errs[2]]
print(f"error ratios per halving: {rat[0]:.2f}, {rat[1]:.2f}; orders {log(rat[0], 2):.2f}, {log(rat[1], 2):.2f}")
print(f"chart, heaped midpoint error x 10^4 at h = 0.025, 0.05, 0.1: "
      f"{errs[2] * 1e4:.2f}, {errs[1] * 1e4:.2f}, {errs[0] * 1e4:.2f}")
print(f"mistake 1, h = 1/9 for nine points: midpoint {sweep(uni, 9, 1 / 9)[2][4]:.6f} m")
print(f"mistake 2, divide by h not h^2: midpoint {sweep(lambda x: -1.0 / h, 9, h)[2][4]:.6f} m")
e19 = max(abs(a - (i + 1) / 20 * (1 - (i + 1) / 20) / 2) for i, a in enumerate(sweep(uni, 19, 0.05)[2]))
print(f"mistake 3, order read off the even load: errors {eu:.10f} (h = 0.1), {e19:.10f} (h = 0.05)")
pts = [(40 + 28 * i, 50 + 1120 * v) for i, v in enumerate([0.0] + y + [0.0])]
print("figure, 280 px/m across, 1120 px/m down; nodes (px):", " ".join(f"({a},{b:.1f})" for a, b in pts))
assert eu < 1e-12 and e19 < 1e-12      # even load: grid equals the parabola
assert gap < 1e-12                      # heaped load: sweep equals eigenvector formula
assert all(3.9 < q < 4.1 for q in rat)  # error falls with h^2
print("ALL CHECKS PASS")
