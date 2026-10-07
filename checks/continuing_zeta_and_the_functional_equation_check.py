# Continuing zeta -- the check behind the card.  Standard library only.
# Road one: the alternating series eta, divided by 1 - 2^(1-s).  Road two: sum
# the first N - 1 terms, swap the tail for its integral, correct the swap at
# the join (Euler-Maclaurin).  Road three: the mirror, fed by road one at s > 1.
import math

def eta(s, N=4000, K=12):          # 1 - 1/2^s + 1/3^s - ..., last partial sums averaged
    sums, total = [], 0j
    for n in range(1, N + K + 1):
        total += (-1) ** (n - 1) * n ** (-s)
        if n >= N:
            sums.append(total)
    for _ in range(K):
        sums = [(a + b) / 2 for a, b in zip(sums, sums[1:])]
    return sums[0]
def road1(s):
    return eta(s) / (1 - 2 ** (1 - s))

def road2(s, N=30):                # head sum + tail integral + end corrections
    head = sum(n ** -s for n in range(1, N))
    return (head + N ** (1 - s) / (s - 1) + N ** -s / 2 + s * N ** (-s - 1) / 12
            - s * (s + 1) * (s + 2) * N ** (-s - 3) / 720
            + s * (s + 1) * (s + 2) * (s + 3) * (s + 4) * N ** (-s - 5) / 30240)
GAMMA = {2: 1, 3: 2, 4: 6, 5: 24, 1.5: math.sqrt(math.pi) / 2}   # (n-1)!, and sqrt(pi)/2
def mirror(s):                     # Riemann 1859: zeta(s) from zeta(1 - s)
    return (2 ** s * math.pi ** (s - 1) * math.sin(math.pi * s / 2)
            * GAMMA[1 - s] * road1(1 - s).real)

f = lambda x: f"{round(x, 6) + 0.0:.6f}"   # six decimals, no -0.000000

H = lambda n: sum(1 / k for k in range(1, n + 1))
print(f"Jenga: 54 blocks overhang {H(54) / 2:.4f} block lengths = {7.5 * H(54) / 2:.2f} cm; "
      f"3 lengths needs {next(n for n in range(1, 10**5) if H(n) > 6)} blocks")
print("chart, overhang for n = 1, 2, 4, ..., 512: " + ", ".join(f"{H(2**j) / 2:.2f}" for j in range(10)))
print(f"plain sums: 1 + 2 + ... + 100 = {sum(range(101))}; 1 + 1/sqrt(2) + ... to 10^4 terms = "
      f"{sum(n ** -0.5 for n in range(1, 10001)):.2f}")
print(f"s = 0.5: eta = {f(eta(0.5).real)}; road one zeta = {f(road1(0.5).real)}; road two = {f(road2(0.5).real)}")
print(f"s = 0: eta = {f(eta(0).real)}; road one zeta = {f(road1(0).real)}; road two = {f(road2(0).real)}")
print(f"pole: eta(1) = {f(eta(1).real)}, ln 2 = {f(math.log(2))}; (s - 1) zeta(s) at s = 1.01: "
      f"{f(0.01 * road1(1.01).real)}, at s = 1.001: {f(0.001 * road1(1.001).real)}")
gz, gj = (road1(1.001) + road1(0.999)).real / 2, H(10**6) - math.log(10**6)
print(f"constant: (zeta(1.001) + zeta(0.999))/2 = {gz:.5f}; Jenga H(10^6) - ln 10^6 = {gj:.5f}")
s_star = 1 + 2j * math.pi / math.log(2)
z1, z2 = road1(s_star + 1e-7), road2(s_star)
print(f"removable point s* = 1 + {s_star.imag:.6f}i: |1 - 2^(1-s*)| = {abs(1 - 2 ** (1 - s_star)):.6f}, "
      f"|eta(s*)| = {abs(eta(s_star)):.6f}")
print(f"  zeta near s*, road one: {f(z1.real)} + {f(z1.imag)}i; at s*, road two: {f(z2.real)} + {f(z2.imag)}i")
hd = sum(range(1, 30))
print(f"road two at s = -1, N = 30: head {hd}, tail integral {-30**2 // 2}, half term {30 // 2}, end term {f(-1 / 12)}")
print(f"zeta(2) by road one = {f(road1(2).real)}; pi^2/6 = {f(math.pi ** 2 / 6)}")
for s in (-1, -3, -0.5, -2, -4):
    print(f"zeta({s}): mirror from zeta({1 - s}), {f(mirror(s))}; road two, {f(road2(s).real)}")
print("figure, origin (220,120), 12 per unit: pole (232,120); mirror x 226; -1 and 2 at x 208, 244; zeros x " +
      " ".join(f"{220 + 12 * s}" for s in (-2, -4, -6, -8, -10)) + f"; s* y {120 - 12 * s_star.imag:.1f}, {120 + 12 * s_star.imag:.1f}")
assert abs(road1(0.5) - road2(0.5)) < 1e-9                    # two roads through the strip
assert abs(mirror(-1) - road2(-1)) < 1e-9 and abs(mirror(-0.5) - road2(-0.5)) < 1e-8
assert abs(0.001 * road1(1.001).real - 1) < 1e-3 and abs(gz - gj) < 1e-5   # residue 1; constant
assert abs(z1 - z2) < 1e-5                                    # the removable point is finite
print("ALL CHECKS PASS")
