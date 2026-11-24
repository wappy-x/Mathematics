# Donsker's theorem: the gambler's best-so-far winnings against Brownian motion's reflection answer.
import math

def Phi(x):  # standard normal CDF: 1/2 plus Simpson's rule on the bell curve from 0 to x
    if x < 0:
        return 1.0 - Phi(-x)
    x, m = min(x, 12.0), 2000
    h = x / m
    s = sum((1 if i in (0, m) else 4 if i % 2 else 2) * math.exp(-(i * h) ** 2 / 2) for i in range(m + 1))
    return 0.5 + s * h / 3 / math.sqrt(2 * math.pi)

def Phi_series(x):  # second road: Taylor series of the error function
    z, term, s, k = x / math.sqrt(2), x / math.sqrt(2), 0.0, 0
    while abs(term) > 1e-17:
        s += term / (2 * k + 1)
        k += 1
        term *= -z * z / k
    return 0.5 + s / math.sqrt(math.pi)

LNF = [0.0]
for i in range(1, 6401):
    LNF.append(LNF[-1] + math.log(i))  # ln(i!) as a running sum of logs

def bin_tail(n, p, k):  # P(Bin(n, p) >= k), each term from ln(n choose j)
    return sum(math.exp(LNF[n] - LNF[j] - LNF[n - j] + j * math.log(p) + (n - j) * math.log(1 - p))
               for j in range(k, n + 1))

def touch(n, up, down, p, L, every=1):
    # chance a walk (+up with chance p, -down otherwise, from 0) stands at L or above
    # at some checked round; rounds are checked every `every` rounds. No mirror used.
    base = down * n
    W = base + L + up * every
    old = [0.0] * W
    old[base] = 1.0
    hit = 0.0
    for k in range(1, n + 1):
        new = [0.0] * W
        for i, v in enumerate(old):
            if v:
                if i + up < W:
                    new[i + up] += p * v
                if i - down >= 0:
                    new[i - down] += (1 - p) * v
        if k % every == 0:
            hit += sum(new[base + L:])
            new[base + L:] = [0.0] * (W - base - L)
        old = new
    return hit

def two_sided_walk(m, lam):  # P(coin walk reaches +lam or -lam within m rounds)
    old, hit = {0: 1.0}, 0.0
    for _ in range(m):
        new = {}
        for x, v in old.items():
            for y in (x + 1, x - 1):
                if abs(y) >= lam:
                    hit += v / 2
                else:
                    new[y] = new.get(y, 0.0) + v / 2
        old = new
    return hit

def two_sided_bm(d, e):  # P(max over [0, d] of |W| >= e), mirrors in both walls
    stay = sum((-1) ** k * (Phi((2 * k + 1) * e / math.sqrt(d)) - Phi((2 * k - 1) * e / math.sqrt(d)))
               for k in range(-20, 21))
    return 1.0 - stay

f4 = lambda x: f"{x:.4f}"
bm = 2 * (1 - Phi(1.5))
assert abs(Phi(1.5) - Phi_series(1.5)) < 1e-10
print("Gambler: fair coin, +1 or -1 chip a round, 100 rounds, level 15 chips")
print("1 spread = sqrt(100) = 10 chips, so the level is", 15 / 10, "spreads")
end = bin_tail(100, 0.5, 58)
refl = 2 * end
dp = touch(100, 1, 1, 0.5, 15)
print("P(end >= 15) = P(Bin(100,1/2) >= 58) =", f4(end))
print("walk reflection 2 P(Bin >= 58)       =", f4(refl))
print("step-by-step, no mirror              =", f4(dp))
print("Phi(1.5) by Simpson =", f"{Phi(1.5):.6f}", "by series =", f"{Phi_series(1.5):.6f}")
print("Brownian 2(1 - Phi(1.5))             =", f4(bm))
print("gap walk - Brownian                  =", f"{refl - bm:+.4f}")
assert abs(refl - dp) < 1e-12 and abs(refl - bm) < 0.001
print("joined-up minus step path, at most 1/sqrt(n) =", f4(1 / math.sqrt(100)))
print("convergence, level 1.5 sqrt(n) chips:")
print("n | coin exact | long-shot exact | Brownian")
gaps = []
for n in (100, 400, 1600, 6400):
    r = math.isqrt(n)
    a = 3 * r // 2
    coin = bin_tail(n, 0.5, (n + a) // 2 + 1) * 2 if a % 2 else bin_tail(n, 0.5, (n + a) // 2) + bin_tail(n, 0.5, (n + a) // 2 + 1)
    coin_dp = touch(n, 1, 1, 0.5, a)
    shot = touch(n, 4, 1, 0.2, 3 * r)  # half-chip units: +2 chips = +4, -1/2 chip = -1
    assert abs(coin - coin_dp) < 1e-10
    gaps.append((abs(coin - bm), abs(shot - bm)))
    print(n, "|", f4(coin), "|", f4(shot), "|", f4(bm))
assert gaps[-1][0] < gaps[0][0] and gaps[-1][1] < gaps[0][1] / 3 and gaps[-1][1] < 0.01
print("mistakes, 100 rounds:")
print("end position only, P(end >= 15)      =", f4(end))
print("normal tail only, 1 - Phi(1.5)       =", f4(1 - Phi(1.5)))
chk = touch(100, 1, 1, 0.5, 15, every=10)
print("checked every 10 rounds only         =", f4(chk))
shot_end = bin_tail(100, 0.2, 26)  # 2.5 wins - 50 >= 15 needs 26 wins
shot100 = touch(100, 4, 1, 0.2, 30)
print("long-shot, doubled end tail          =", f4(2 * shot_end))
print("long-shot, exact                     =", f4(shot100))
spike = 0.5 * (0.1 + 2 >= 1.5) + 0.5 * (-0.1 + 2 >= 1.5)
print("walk plus a spike of 2 at t=1/n, P(max >= 1.5) =", f4(spike))
assert chk < dp and abs(2 * shot_end - shot100) > 0.02
print("tightness: P(some block of length d has |swing from its start| >= 1)")
print("d | n | blocks x walk block chance | Brownian limit | bound 3d")
for d in (0.2, 0.1):
    lim = two_sided_bm(d, 1.0) / d
    for n in (100, 400, 1600, 6400):
        m = round(d * n)
        u = two_sided_walk(m, math.isqrt(n)) / d
        assert u <= 3 * d
        print(d, "|", n, "|", f4(u), "|", f4(lim), "|", f4(3 * d))
    assert abs(u - lim) < 0.1 * lim
print("0.05 | Brownian limit only |", f"{two_sided_bm(0.05, 1.0) / 0.05:.6f}")
print("try: level 2 spreads, Brownian =", f4(2 * (1 - Phi(2.0))), "coin n=100 =", f4(bin_tail(100, 0.5, 60) + bin_tail(100, 0.5, 61)))
print("try: 400 rounds, level 15 chips, coin =", f4(2 * bin_tail(400, 0.5, 208)), "Brownian =", f4(2 * (1 - Phi(0.75))))
print("ALL CHECKS PASS")
