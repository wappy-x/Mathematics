# Warrants and employee stock options -- the check behind the card.  Standard library
# only.  The bell-curve area is its own power series, the averages are Simpson's rule
# written out, the tree and the simulation are loops, the random numbers come from
# a 64-bit generator written here.  House market: r = 5%, q = 2%, sigma = 20%.
import math
R, Q, VOL, K = 0.05, 0.02, 0.20, 100.0
N_SH, M_W = 1_000_000, 100_000              # Acme's shares, the warrants it writes

def Phi(x):                                  # 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    term, total, n = x, x, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        n += 1; term *= x * x / (2 * n + 1); total += term
    return 0.5 + total * math.exp(-x * x / 2) / math.sqrt(2 * math.pi)

def bs_call(s, k, t, vol=VOL):
    if t <= 0: return max(s - k, 0.0)
    d1 = (math.log(s / k) + (R - Q + vol * vol / 2) * t) / (vol * math.sqrt(t))
    return s * math.exp(-Q * t) * Phi(d1) - k * math.exp(-R * t) * Phi(d1 - vol * math.sqrt(t))

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))

def warrant_by_average(v0, t=1.0):           # payoff from the diluted share price itself
    mu, sd = (R - Q - VOL * VOL / 2) * t, VOL * math.sqrt(t)
    def pay(z):
        v_t = v0 * math.exp(mu + sd * z)     # equity per old share at expiry
        price_after = (N_SH * v_t + M_W * K) / (N_SH + M_W)
        return max(price_after - K, 0.0) * math.exp(-z * z / 2) / math.sqrt(2 * math.pi)
    z_k = (math.log(K / v0) - mu) / sd       # below this the warrants lapse
    return math.exp(-R * t) * simpson(pay, z_k, 10.0)

def warrant_from_share_price(s, vol=VOL):    # W = N/(N+M) C(S + (M/N) W), by iteration
    w = 0.0
    for _ in range(60): w = N_SH / (N_SH + M_W) * bs_call(s + M_W / N_SH * w, K, 1.0, vol)
    return w

def eso_tree(steps, vest=3.0, mult=2.0, leave=0.05, t=10.0, forfeit=True):  # False: nobody leaves before vesting
    dt = t / steps; u = math.exp(VOL * math.sqrt(dt)); d = 1 / u
    p = (math.exp((R - Q) * dt) - d) / (u - d); df = math.exp(-R * dt)
    lv = 1 - math.exp(-leave * dt)           # chance of leaving in one step
    val = [max(100.0 * u ** (2 * j - steps) - K, 0.0) for j in range(steps + 1)]
    for i in range(steps - 1, -1, -1):
        vested = i * dt >= vest - 1e-9; li = lv if vested or forfeit else 0.0
        for j in range(i + 1):
            s = 100.0 * u ** (2 * j - i); x = max(s - K, 0.0)
            hold = df * (p * val[j + 1] + (1 - p) * val[j])
            if vested and s >= mult * K: val[j] = x                     # exercise at the multiple
            else: val[j] = (1 - li) * hold + li * (x if vested else 0.0)  # leave: exercise or forfeit
    return val[0]

def leave_sum(steps, vest=3.0, leave=0.05, t=10.0):  # no multiple: a sum of plain calls
    dt = t / steps; lv = 1 - math.exp(-leave * dt)
    tot = sum((1 - lv) ** i * lv * bs_call(100.0, K, i * dt) for i in range(steps) if i * dt >= vest - 1e-9)
    return tot + (1 - lv) ** steps * bs_call(100.0, K, t)

def eso_sim(pairs, steps=500, vest=3.0, mult=2.0, leave=0.05, t=10.0, seed=20261123):
    dt = t / steps; lv = 1 - math.exp(-leave * dt); vs = round(vest / dt)
    drift, sd, g = (R - Q - VOL * VOL / 2) * dt, VOL * math.sqrt(dt), math.exp(-R * dt)
    st, tot, tot2, mask = seed, 0.0, 0.0, (1 << 64) - 1
    for _ in range(pairs):
        z = []
        for _ in range(steps // 2):          # Box-Muller: two uniforms give two normals
            st = (st * 6364136223846793005 + 1442695040888963407) & mask; u1 = ((st >> 11) + 0.5) / 9007199254740992
            st = (st * 6364136223846793005 + 1442695040888963407) & mask; u2 = (st >> 11) / 9007199254740992
            rad = math.sqrt(-2 * math.log(u1)); z += [rad * math.cos(2 * math.pi * u2), rad * math.sin(2 * math.pi * u2)]
        pv = 0.0
        for sign in (1.0, -1.0):             # each path and its mirror image
            s, alive, disc, v, done = 100.0, 1.0, 1.0, 0.0, False
            for i in range(steps):
                x = max(s - K, 0.0)
                if i >= vs:
                    if s >= mult * K: v += alive * disc * x; done = True; break
                    v += alive * lv * disc * x
                alive *= 1 - lv; s *= math.exp(drift + sign * sd * z[i]); disc *= g
            if not done: v += alive * disc * max(s - K, 0.0)
            pv += v / 2
        tot += pv; tot2 += pv * pv
    mean = tot / pairs
    return mean, math.sqrt((tot2 / pairs - mean * mean) / pairs)

def out(label, x): print(f"{label:<44}{x:>12.6f}")

print("part 1: the warrant, one year, strike 100")
call = bs_call(100.0, K, 1.0); f = N_SH / (N_SH + M_W)
out("plain call on a share at 100", call)
out("dilution factor N/(N+M)", f)
w_free = f * call; out("warrant, equity per old share 100", w_free)
w_free_avg = warrant_by_average(100.0); out("  same, diluted payoff averaged", w_free_avg)
s_after = 100.0 - M_W / N_SH * w_free; out("  share price after a free grant", s_after)
out("  warrant solved from that share price", warrant_from_share_price(s_after))
w_cash = warrant_from_share_price(100.0); out("warrant, share trading at 100", w_cash)
v_c = 100.0 + M_W / N_SH * w_cash; out("  equity per old share behind it", v_c)
w_cash_avg = warrant_by_average(v_c); out("  same, diluted payoff averaged", w_cash_avg)
d1 = (math.log(v_c / K) + R - Q + VOL * VOL / 2) / VOL        # one year
shrink = M_W / (N_SH + M_W) * math.exp(-Q) * Phi(d1); out("  each round shrinks the error by", shrink)
share = lambda v: v - M_W / (N_SH + M_W) * bs_call(v, K, 1.0)   # share price behind equity v
vol_sh = VOL * v_c / share(v_c) * (share(v_c + 1e-4) - share(v_c - 1e-4)) / 2e-4
out("  the share's own volatility, %", 100 * vol_sh)
w_shvol = warrant_from_share_price(100.0, vol_sh); out("  warrant priced at the share's volatility", w_shvol)
after = (N_SH * 120.0 + M_W * K) / (N_SH + M_W); out("expiry at 120: each share after exercise", after)
out("expiry at 120: plain call pays", 20.0)
out("expiry at 120: warrant pays", after - K)
out("plain call overstates the warrant by", call - w_cash)
assert abs(w_free_avg - w_free) < 1e-6 and abs(w_cash_avg - w_cash) < 1e-6
assert abs(warrant_from_share_price(s_after) - w_free) < 1e-9
assert abs(vol_sh - VOL * v_c / 100.0 * (1 - shrink)) < 1e-6 and w_shvol < w_cash
assert abs(call - 9.227006) < 1e-6 and abs(w_free - 8.388187) < 1e-6   # the spec's anchors

print("part 2: the employee option, ten years, strike 100, 500-step tree")
bs10 = bs_call(100.0, K, 10.0); out("Black-Scholes, ten years", bs10)
plain = eso_tree(500, vest=0.0, mult=1e9, leave=0.0); out("tree, no employee features", plain)
only_mult = eso_tree(500, mult=2.0, leave=0.0); out("tree, exercise at 2.0 times strike only", only_mult)
no_vest = eso_tree(500, vest=0.0, mult=1e9); out("tree, 5% leaving, no vesting", no_vest)
lv_vest = eso_tree(500, mult=1e9); out("tree, 5% leaving, 3-year vesting", lv_vest)
lv_sum = leave_sum(500); out("  same, as a sum of plain calls", lv_sum)
eso = eso_tree(500); out("tree, all three features", eso)
for n in (250, 1000): out(f"  same on a {n}-step tree", eso_tree(n))
m3 = eso_tree(500, mult=3.0); out("  same, exercise at 3.0 times strike", m3)
sim, se = eso_sim(50000); out("simulation, 100,000 paths", sim); out("  its standard error", se)
out("ESO as a share of Black-Scholes, %", 100 * eso / bs10)
out("Black-Scholes overstates the ESO by", bs10 - eso)
short = bs_call(100.0, K, 6.5); out("accounting shortcut: Black-Scholes, 6.5 years", short)
out("  minus the tree, forfeiture counted twice", short - eso)
stay = math.exp(-0.05 * 3.0); out("chance of staying to vesting", stay)
per_vest = eso_tree(500, forfeit=False); out("tree, per vested option", per_vest)
out("  shortcut falls short per vested option by", per_vest - short)
assert abs(plain - bs10) < 0.02 and abs(lv_vest - lv_sum) < 0.02
assert abs(sim - eso) < 3 * se and eso < lv_vest < no_vest < bs10
assert abs(stay * per_vest - eso) < 1e-9 and eso < lv_vest < m3
rates = [0.0, 0.025, 0.05, 0.075, 0.10, 0.125, 0.15]
print("chart leaving %   " + "".join(f"{100 * e:>7.1f}" for e in rates))
print("chart multiple 2  " + "".join(f"{eso_tree(500, leave=e):>7.2f}" for e in rates))
print("chart no multiple " + "".join(f"{eso_tree(500, mult=1e9, leave=e):>7.2f}" for e in rates))
print("ALL CHECKS PASS")
