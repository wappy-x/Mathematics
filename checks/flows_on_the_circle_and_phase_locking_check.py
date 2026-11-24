# Phase locking -- the check behind the card.  Two fireflies, free rhythms 6.0 and
# 6.5 rad/s, nudge each other with strength K/2, so the phase gap obeys phi' = 0.5 - K sin phi.
# Three roads: the formula, phi' summed round the circle, both fireflies stepped by RK4.
import math
W1, W2 = 6.0, 6.5; W, DT, TAU = W2 - W1, 0.001, 2 * math.pi   # free rhythms, rad/s

def rate(a, b, K):                    # each firefly nudged toward the other
    return W1 + K / 2 * math.sin(b - a), W2 + K / 2 * math.sin(a - b)

def run(K, t_end):                    # road 3: step both phases by RK4
    a = b = 0.0; gaps, slip = [0.0], None
    for n in range(1, round(t_end / DT) + 1):
        k1 = rate(a, b, K); k2 = rate(a + DT / 2 * k1[0], b + DT / 2 * k1[1], K)
        k3 = rate(a + DT / 2 * k2[0], b + DT / 2 * k2[1], K)
        k4 = rate(a + DT * k3[0], b + DT * k3[1], K)
        a0, g0 = a, b - a
        a += DT / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        b += DT / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
        if slip is None and b - a >= TAU:          # first full lap, interpolated
            f = (TAU - g0) / (b - a - g0)
            slip, a_slip = (n - 1 + f) * DT, a0 + f * (a - a0)
        if n % 2000 == 0: gaps.append(math.degrees(b - a))
    return gaps, slip, (a_slip / slip if slip else None), rate(a, b, K)

def summed(K, lo=0.0, hi=TAU, n=20000):          # road 2: add up dphi / phi'
    h = (hi - lo) / n
    return sum(h / (W - K * math.sin(lo + (i + 0.5) * h)) for i in range(n))

formula = lambda K: TAU / math.sqrt(W * W - K * K)  # road 1: the slip period
exact = lambda K, p: 2 * math.atan((W * math.tan(p / 2) - K) / math.sqrt(W * W - K * K)) / math.sqrt(W * W - K * K)
row = lambda xs, d: ", ".join(f"{x:.{d}f}" for x in xs)
lock, _, _, (ra, rb) = run(1.0, 42); slips = {}; lag = math.degrees(math.asin(W / 1.0))
print(f"K = 1: lag arcsin(0.5) = {lag:.3f} deg, simulated {lock[-1]:.3f} deg; other rest {180 - lag:.3f} deg")
print(f"K = 1: pull-back rate K cos(lag) = {W / math.tan(math.radians(lag)):.3f} per s; "
      f"both run at {ra:.3f} and {rb:.3f} rad/s; B leads by {math.radians(lag) / rb:.4f} s")
for K in (0.4, 0.49):
    g, s, ma, _ = run(K, 70)
    slips[K] = (formula(K), summed(K), s, ma, g)
    print(f"K = {K}: slip every {formula(K):.3f} s (formula), {summed(K):.3f} s (summed), {s:.3f} s (two fireflies)")
    print(f"K = {K}: share of each slip spent between 60 and 120 deg {summed(K, TAU / 6, TAU / 3) / formula(K):.3f}")
print(f"K = 0.49: edge estimate 2 pi/sqrt(2 w (w - K)) = {TAU / math.sqrt(2 * W * (W - 0.49)):.3f} s")
ma = slips[0.4][3]; print(f"K = 0.4: A averages {ma:.3f} rad/s, B {ma + TAU / slips[0.4][2]:.3f}, beat {TAU / slips[0.4][2]:.3f} rad/s")
print(f"worked: w^2 - K^2 = {W * W - 0.16:.4f} and {W * W - 0.49 ** 2:.4f}, roots "
      f"{math.sqrt(W * W - 0.16):.4f} and {math.sqrt(W * W - 0.49 ** 2):.4f}; even share {1 / 6:.3f}")
print(f"flash every {TAU / W1:.3f} s (A alone), {TAU / W2:.3f} s (B alone), {TAU / ra:.3f} s (locked)")
edge, s51, _, _ = run(0.51, 200)
print(f"K = 0.51: locks at {edge[-1]:.3f} deg (arcsin {math.degrees(math.asin(W / 0.51)):.3f})")
print(f"chart, gap every 2 s, K = 1: {row(lock[:22], 1)}")
print(f"chart, gap every 2 s, K = 0.4: {row(slips[0.4][4][:22], 1)}")
print(f"chart, slip period at K = 0, 0.04 .. 0.48: {row([formula(0.04 * i) for i in range(13)], 2)}")
print(f"bars, phi' at 0, 30 .. 330 deg, K = 0.4: {row([W - 0.4 * math.sin(math.radians(30 * i)) for i in range(12)], 3)}")
print(f"mistakes: lag 0.5 rad = {math.degrees(W):.3f} deg; 2 pi/w = {TAU / W:.3f} s; "
      f"2 pi/(w - K) at K = 0.4: {TAU / (W - 0.4):.3f} s")
for K, (f, q, s, _, _) in slips.items():
    assert abs(f - q) < 1e-6 and abs(f - s) < 1e-6             # three roads agree
assert abs(lock[-1] - lag) < 1e-6 and abs(ra - (W1 + W2) / 2) < 1e-6 and abs(rb - ra) < 1e-6
assert abs(edge[-1] - math.degrees(math.asin(W / 0.51))) < 1e-3 and s51 is None
assert abs(ma - (W1 + 0.2 * (W - TAU / formula(0.4)) / 0.4)) < 1e-3  # mean of sin phi
assert all(abs(summed(K, TAU / 6, TAU / 3) - exact(K, TAU / 3) + exact(K, TAU / 6)) < 1e-6 for K in slips)
print("ALL CHECKS PASS")
