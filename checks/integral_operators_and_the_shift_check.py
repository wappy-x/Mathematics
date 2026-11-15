# Three model operators: the check behind the card.  Standard library only.
# A blur (weights 1/4, 1/2, 1/4), a fade-in volume mask g(x) = x, a running
# total and a one-sample delay line, each held as a matrix on N samples: the
# finite rehearsal.  Nothing imported knows a norm: power iteration, row sums
# and a sign-pattern search are written out.  Roads: closed forms against
# power iteration; brute force against row sums; exact window integrals
# against midpoint sums; the endless delay line against its cut.
import math

def l2(x): return math.sqrt(sum(v * v for v in x))
def blur(x, w=(0.25, 0.5, 0.25)):              # zero beyond both ends
    n = len(x)
    return [w[0] * (x[i - 1] if i else 0.0) + w[1] * x[i] + w[2] * (x[i + 1] if i < n - 1 else 0.0)
            for i in range(n)]
def power(apply, n, it):                        # largest |Ax|/|x| of a symmetric map, from all ones
    x = [1.0] * n
    for _ in range(it):
        y = apply(x); s = l2(y); x = [v / s for v in y]
    return l2(apply(x)), x
def blur_exact(N): c = math.cos(math.pi / (2 * N + 2)); return c * c
def mask_gain(N): return max((i + 0.5) / N for i in range(N))
def fmt(xs, d=2): return " ".join(f"{v:.{d}f}" for v in xs)

print("1. blur, N = 5 samples: weights 1/4, 1/2, 1/4, zero beyond the ends")
click = [0.0, 0.0, 4.0, 0.0, 0.0]; out = blur(click)
print(f"   click {fmt(click, 1)} -> {fmt(out, 1)}")
print(f"   sum {sum(click):.1f} -> {sum(out):.1f}; 2-norm {l2(click):.4f} -> {l2(out):.4f}, gain {l2(out) / l2(click):.4f}")
assert out == [0.0, 1.0, 2.0, 1.0, 0.0] and abs(l2(out) ** 2 - 6) < 1e-12
rows = [sum(abs(v) for v in blur([1.0 if j == i else 0.0 for j in range(5)])) for i in range(5)]
print(f"   row sums {fmt(rows)}; peak gain = largest row sum {max(rows):.4f}")
best = max(max(abs(v) for v in blur([1.0 if (k >> j) & 1 else -1.0 for j in range(5)])) for k in range(32))
print(f"   peak gain, brute force over all 32 sign patterns: {best:.4f}")
assert abs(best - max(rows)) < 1e-15                                    # road 2: brute force
g5, v5 = power(blur, 5, 6000)
print(f"   2-norm gain: power iteration {g5:.6f}; cos^2(pi/12) {blur_exact(5):.6f}; Schur bound 1")
print(f"   best input, scaled to peak 1: {fmt([v / max(v5) for v in v5], 4)}")
assert abs(g5 - blur_exact(5)) < 1e-12 and g5 < 1

print("2. as N grows: the gain creeps up to 1 and never reaches it")
for N in (5, 20, 80):
    g, _ = power(blur, N, 6000)
    print(f"   N {N:3d}: blur power iteration {g:.6f}, closed form {blur_exact(N):.6f}, gap {1 - g:.6f}")
    assert abs(g - blur_exact(N)) < 1e-10 and g < 1                     # road 1: closed form
CH = (1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 40)
print("   chart N    " + " ".join(f"{n:5d}" for n in CH))
print("   chart blur " + " ".join(f"{blur_exact(n):.3f}" for n in CH))
print("   chart mask " + " ".join(f"{mask_gain(n):.3f}" for n in CH))

print("3. fade-in mask g(x) = x on a 1 s clip, N midpoint samples")
print(f"   N = 5: diagonal {fmt([(i + 0.5) / 5 for i in range(5)], 1)}; gain {mask_gain(5):.4f}")
for N in (5, 50, 500):
    print(f"   N {N:3d}: gain {mask_gain(N):.6f}; inverse mask gain {1 / min((i + 0.5) / N for i in range(N)):.0f}")
M = 100000
def window(lo, hi, f):                          # midpoint sums of f(t)^2 and 1 over [lo, hi]
    h = (hi - lo) / M; a = b = 0.0
    for i in range(M):
        t = lo + (i + 0.5) * h; a += f(t) * f(t) * h; b += h
    return math.sqrt(a / b)
for e in (0.1, 0.01, 0.001):
    exact = math.sqrt((1 - (1 - e) ** 3) / (3 * e)); q = window(1 - e, 1.0, lambda t: t)
    res = window(0.5 - e / 2, 0.5 + e / 2, lambda t: t - 0.5)
    print(f"   e {e:5.3f}: end window gain {exact:.6f} (midpoint {q:.6f}); "
          f"bump at 0.5 residual {e / math.sqrt(12):.7f} (midpoint {res:.7f})")
    assert abs(exact - q) < 1e-9 and exact < 1                          # road 3: exact integral
    assert abs(res - e / math.sqrt(12)) < 1e-9

print("4. running total (Volterra), N-point midpoint grid on [0, 1]")
def volt(x, L=1.0):                             # (Vx)_i = h(x_1 + ... + x_(i-1) + x_i/2)
    h = L / len(x); y = []; s = 0.0
    for v in x: y.append(h * (s + v / 2)); s += v
    return y
def volt_t(y, L=1.0): return volt(y[::-1], L)[::-1]
for N in (10, 40, 160, 640):
    s2, x = power(lambda x: volt_t(volt(x)), N, 40)
    g = l2(volt(x))
    print(f"   N {N:3d}: gain {g:.9f}; gap x N^2 {(2 / math.pi - g) * N * N:.4f}; every eigenvalue 1/(2N) = {1 / (2 * N):.6f}")
    assert abs(g - 2 / math.pi) < 0.2 / N ** 2 and abs(g * g - s2) < 1e-12
print(f"   2/pi = {2 / math.pi:.6f}; Schur bound = 1.0000")

print("5. delay line S, one sample per step")
x = [3.0, 1.0, 4.0, 1.0, 5.0]
def cut_delay(x): return [0.0] + x[:-1]          # S on 5 samples: last one falls off
def delay(x): return [0.0] + x                   # S on an endless list
def advance(x): return x[1:]                     # the advance: drop the first sample
def cut_pow(v, m):
    for _ in range(m): v = cut_delay(v)
    return v
y = cut_pow(x, 5)
print(f"   cut at N = 5: Sx = {fmt(cut_delay(x), 0)}, energy {l2(x) ** 2:.0f} -> {l2(cut_delay(x)) ** 2:.0f}; S^5 x = {fmt(y, 0)}")
z = x
for m in range(12000): z = delay(z)
print(f"   endless: Sx = {fmt(delay(x), 0)}, energy {l2(delay(x)) ** 2:.0f}; S^12000 x (0.25 s at 48 kHz) energy {l2(z) ** 2:.0f}")
assert y == [0.0] * 5 and l2(z) == l2(x) and z[12000:] == x               # road 4: cut against endless
assert abs(l2(cut_delay(x)) ** 2 - (l2(x) ** 2 - x[-1] ** 2)) < 1e-12    # only the last sample is lost
print(f"   advance after delay {fmt(advance(delay(x)), 0)}; delay after advance {fmt(delay(advance(x)), 0)}")
assert advance(delay(x)) == x and delay(advance(x)) != x
gains = [max(l2(cut_pow([1.0 if j == k else 0.0 for j in range(5)], m)) for k in range(5)) for m in range(1, 7)]
print(f"   cut S^m, m = 1..6, gain {fmt(gains, 0)}; endless S^m gain 1 for every m")
geo = [0.5 ** n for n in range(60)]
print(f"   advance of (1, 0.5, 0.25, ...) = 0.5 x the list; its 2-norm {l2(geo):.4f}, sqrt(4/3) {math.sqrt(4 / 3):.4f}")

print("6. what breaks")
print(f"   largest single blur weight as the peak gain: 0.5000 (true {max(rows):.4f})")
print(f"   the cut delay S^5 as the delay's gain: {gains[4]:.0f} (endless list: 1)")
print(f"   Schur bound as the running total's gain: 1.0000 (true {2 / math.pi:.4f})")
print(f"   the N = 5 mask's gain as the mask's norm: {mask_gain(5):.4f} (true 1)")

print("7. try changing")
box = lambda x: blur(x, (1 / 3, 1 / 3, 1 / 3)); gb, _ = power(box, 5, 6000)
print(f"   box blur 1/3 each, N = 5: peak gain {max(abs(v) for v in box([1.0] * 5)):.4f}, 2-norm gain {gb:.6f}")
assert abs(gb - (1 + 2 * math.cos(math.pi / 6)) / 3) < 1e-12
gm = [0.5 + 0.5 * (i + 0.5) / 500 for i in range(500)]
print(f"   mask 0.5 + 0.5x, N = 500: gain {max(gm):.6f}, inverse mask gain {1 / min(gm):.6f}")
s2, x = power(lambda x: volt_t(volt(x, 2.0), 2.0), 160, 40)
print(f"   running total over 2 s, N = 160: gain {l2(volt(x, 2.0)):.6f}; 4/pi {4 / math.pi:.6f}")
print(f"   blur at N = 1000: 2-norm gain {blur_exact(1000):.8f}")
print("ALL CHECKS PASS")
