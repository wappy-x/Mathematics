# Abel's limit theorem -- the check behind the card.  Nothing is imported.
# Road one sums each power series term by term just inside the edge, x < 1.
# Road two shares no arithmetic with it: Simpson areas under 1/(1+t) and
# 1/(1+t^2), which are ln(1+x) and arctan x.  Road three is the averaging
# identity f(x) - s = (1 - x) times the sum of (s_n - s) x^n.  Abel's lemma,
# the summation-by-parts bound, is tested at 101 inputs from 0 to 1.
def series(coef, x):                   # coef(0) + coef(1) x + ... until x^n < 1e-16
    total, n, p = 0.0, 0, 1.0
    while p > 1e-16:
        total, n, p = total + coef(n) * p, n + 1, p * x
    return total
def simpson(g, b, m=4000):             # area under g from 0 to b, parabola strips
    h = b / m
    return h / 3 * (g(0) + g(b) + sum((4 if k % 2 else 2) * g(k * h) for k in range(1, m)))
def partial(coef, N):                  # edge partial sums s_0, ..., s_N at x = 1
    out, s = [], 0.0
    for n in range(N + 1):
        s += coef(n)
        out.append(s)
    return out
ln_c = lambda n: 0.0 if n == 0 else (-1) ** (n + 1) / n          # x - x^2/2 + x^3/3 - ...
at_c = lambda n: 0.0 if n % 2 == 0 else (-1) ** (n // 2) / n     # x - x^3/3 + x^5/5 - ...
geo_c = lambda n: float((-1) ** n)                                # 1 - x + x^2 - ...
row = lambda v, d=6: ", ".join(f"{t:.{d}f}" for t in v)
xs = [0.9, 0.99, 0.999]
ln2, pi4 = simpson(lambda t: 1 / (1 + t), 1.0), simpson(lambda t: 1 / (1 + t * t), 1.0)
for name, c, g, s, last in (("ln(1+x)", ln_c, lambda t: 1 / (1 + t), ln2, 1000),
                            ("arctan x", at_c, lambda t: 1 / (1 + t * t), pi4, 1999)):
    inside, areas, edge = [series(c, x) for x in xs], [simpson(g, x) for x in xs], partial(c, last)[-1]
    print(f"{name} series at x = 0.9, 0.99, 0.999: {row(inside)}; areas {row(areas)}")
    print(f"  edge value {s:.6f}; gaps {row(s - v for v in inside)}; 1000 edge terms {edge:.6f}")
    assert all(abs(v - a) < 1e-9 for v, a in zip(inside, areas))      # road one = road two
    assert s - inside[2] < s - inside[1] < s - inside[0] and s - inside[2] < 0.001
    assert abs(edge - s) < 1 / (last + 2)                             # alternating-series bound
N, M, grid = 10, 60, [k / 100 for k in range(101)]
cap = max(abs(sum(ln_c(n) for n in range(N + 1, m + 1))) for m in range(N + 1, M + 1))
tails = [abs(sum(ln_c(n) * x ** n for n in range(N + 1, M + 1))) for x in grid]
ok = all(t <= cap * x ** (N + 1) + 1e-15 for t, x in zip(tails, grid))
print(f"Abel's lemma, terms 11 to 60 of ln(1+x), 101 inputs: worst tail {max(tails):.6f}; "
      f"cap {cap:.6f} x^11 never beaten: {'yes' if ok else 'no'}")
assert ok
f9, sn = series(ln_c, 0.9), partial(ln_c, 400)
avg = (1 - 0.9) * sum((v - ln2) * 0.9 ** n for n, v in enumerate(sn))
print(f"average road at x = 0.9: f(x) - s = {f9 - ln2:.6f}; (1 - x) sum (s_n - s) x^n = {avg:.6f}")
assert abs((f9 - ln2) - avg) < 1e-9
g3, gs = [series(geo_c, x) for x in xs], partial(geo_c, 1000)
print(f"1 - x + x^2 - ... at 0.9, 0.99, 0.999: {row(g3)}; 1/(1+x): {row(1 / (1 + x) for x in xs)}")
print(f"  edge partial sums of 1 - 1 + 1 - ...: {row(gs[:6], 0)}, ...; values taken: {sorted(set(gs))}")
assert all(abs(v - 1 / (1 + x)) < 1e-9 for v, x in zip(g3, xs)) and sorted(set(gs)) == [0.0, 1.0]
e3 = series(lambda n: (-1) ** n * (n + 1.0), 0.999)
print(f"mistake, 1 - 2x + 3x^2 - ... at 0.999: {e3:.6f}, 1/(1+x)^2 = {1 / 1.999 ** 2:.6f}; "
      f"edge sums {row(partial(lambda n: (-1) ** n * (n + 1.0), 5), 0)}")
print(f"mistake, past the edge: term 1000 of the ln series at x = 1.01 is {ln_c(1000) * 1.01 ** 1000:.2f}")
cx = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99, 0.999]
print(f"chart, x: {row(cx, 3)}")
for name, c in (("ln(1+x)", ln_c), ("arctan x", at_c), ("1/(1+x)", geo_c)):
    print(f"chart, {name} by its series: {row((series(c, x) for x in cx), 2)}")
print("ALL CHECKS PASS")
