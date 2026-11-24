# TARF and knock-out accumulator on the house FX market: Monte Carlo against a grid.
# Standard library only. Every number on the card is printed here.
import math
S0, RD, RF, SIG, N, DT = 1.10, 0.05, 0.03, 0.10, 12, 1 / 12
K0, LEV, TGT, H, NOT = 1.08, 2.0, 0.10, 1.13, 1_000_000   # strike, leverage, target, wall, euros
MU, SD = (RD - RF - 0.5 * SIG * SIG) * DT, SIG * math.sqrt(DT)
DF = [math.exp(-RD * DT * (i + 1)) for i in range(N)]
FWD = [S0 * math.exp((RD - RF) * DT * (i + 1)) for i in range(N)]
def ncdf(x):                                  # bell-curve area left of x (erfc, 1.2e-7)
    z = abs(x) / math.sqrt(2); t = 1 / (1 + 0.5 * z)
    p = t * math.exp(-z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (0.09678418
        + t * (-0.18628806 + t * (0.27886807 + t * (-1.13520398 + t * (1.48851587
        + t * (-0.82215223 + t * 0.17087277)))))))))
    return 1 - 0.5 * p if x >= 0 else 0.5 * p
st = 0x2545F4914F6CDD1D                       # xorshift64 random bits, same in Rust
def unif():
    global st
    st ^= (st << 13) & 0xFFFFFFFFFFFFFFFF; st ^= st >> 7; st ^= (st << 17) & 0xFFFFFFFFFFFFFFFF
    return ((st >> 11) + 0.5) / 9007199254740992.0
PATHS, GROW = 100000, []                      # each path: spot / today's spot at the 12 fixings
for p in range(PATHS):
    g, row = 1.0, []
    for i in range(0, N, 2):
        u1, u2 = unif(), unif(); r = math.sqrt(-2 * math.log(u1))
        for z in (r * math.cos(2 * math.pi * u2), r * math.sin(2 * math.pi * u2)):
            g *= math.exp(MU + SD * z); row.append(g)
    GROW.append(row)
def tarf_path(row, S, K, rem, lev, full):     # client's dollars per euro, and gain actually paid
    v, paid = 0.0, 0.0
    for i in range(N):
        s = S * row[i]
        if s > K:
            g = s - K
            if g >= rem: pay = g if full else rem; return v + DF[i] * pay, paid + pay
            v += DF[i] * g; rem -= g; paid += g
        else: v -= lev * DF[i] * (K - s)
    return v, paid
def accum_path(row, S, K):
    v = 0.0
    for i in range(N):
        s = S * row[i]
        if s >= H: return v                   # knocked out: this fixing does not trade
        v += DF[i] * ((s - K) if s > K else -LEV * (K - s))
    return v
def mc(fn, rows):
    m = 0.0; q = 0.0
    for r in rows: x = fn(r); m += x; q += x * x
    m /= len(rows); return m, math.sqrt((q / len(rows) - m * m) / (len(rows) - 1))
def tarf(S=S0, K=K0, rem=TGT, lev=LEV, rows=GROW, full=False):
    return mc(lambda r: tarf_path(r, S, K, rem, lev, full)[0], rows)
def strip(K, lev):                            # no target: 12 forwards minus (lev-1) x 12 puts
    out = 0.0
    for i in range(N):
        t = DT * (i + 1); d1 = (math.log(FWD[i] / K) + 0.5 * SIG * SIG * t) / (SIG * math.sqrt(t))
        put = DF[i] * (K * ncdf(-(d1 - SIG * math.sqrt(t))) - FWD[i] * ncdf(-d1))
        out += DF[i] * (FWD[i] - K) - (lev - 1) * put
    return out
# ---- road 2: backward induction on a grid of log-spot and remaining target ----
HX, M, L, DR = SD / 8, 167, 48, 0.000625
NR = round(TGT / DR) + 1
W = [ncdf(((o + 0.5) * HX - MU) / SD) - ncdf(((o - 0.5) * HX - MU) / SD) for o in range(-L, L + 1)]
SP = [S0 * math.exp(j * HX) for j in range(-M, M + 1)]
def grid(K, acc):
    n, nr = len(SP), (1 if acc else NR); V = [[0.0] * nr for _ in SP]
    for i in reversed(range(N)):
        C = [[0.0] * nr for _ in SP]
        for k, s in enumerate(SP):
            for m in range(nr):
                if acc: C[k][m] = 0.0 if s >= H else DF[i] * ((s - K) if s > K else -LEV * (K - s)) + V[k][m]
                elif m == 0: C[k][m] = 0.0
                elif s <= K: C[k][m] = -LEV * DF[i] * (K - s) + V[k][m]
                elif s - K >= m * DR: C[k][m] = DF[i] * m * DR
                else:
                    q = (m * DR - (s - K)) / DR; a = int(q); f = q - a
                    C[k][m] = DF[i] * (s - K) + (1 - f) * V[k][a] + f * V[k][min(a + 1, nr - 1)]
        V = [[0.0] * nr for _ in SP]
        for j in range(n):
            for m in range(nr):
                acc_v = 0.0
                for o in range(2 * L + 1): acc_v += W[o] * C[min(max(j + o - L, 0), n - 1)][m]
                V[j][m] = acc_v
    return V
def d(x): return f"{x * NOT:.0f}"
print(f"house: spot {S0:.2f}, rates {RD:.2f}/{RF:.2f}, vol {SIG:.2f}, {N} fixings, strike {K0:.2f}, "
      f"leverage {LEV:.0f}x, target {TGT:.2f}, {PATHS} paths")
print(f"forwards: first fixing {FWD[0]:.6f}, last {FWD[-1]:.6f}; most the client can gain: {d(TGT)}")
print(f"grid: {len(SP)} spot levels, {NR} remaining-target levels, {len(W)} weights per step")
fw1, fw2 = strip(K0, 1.0), strip(K0, 2.0)
s1, s2 = tarf(rem=1e9, lev=1.0), tarf(rem=1e9)
print(f"no target, 1x: strip of forwards {d(fw1)}  MC {d(s1[0])} +- {d(s1[1])}")
print(f"no target, 2x: {d(fw1)} - 12 puts {d(fw1 - fw2)} = {d(fw2)}  MC {d(s2[0])} +- {d(s2[1])}")
t0 = tarf(); V = grid(K0, False); i5, i1 = round(0.05 / DR), round(0.01 / DR)
print(f"TARF, client view: MC {d(t0[0])} +- {d(t0[1])}  grid {d(V[M][NR - 1])}")
print(f"what the target takes away: {d(fw2)} - ({d(V[M][NR - 1])}) = {d(fw2 - V[M][NR - 1])}")
runs = [tarf_path(r, S0, K0, TGT, LEV, False) for r in GROW]
hit = sum(1 for v, p in runs if p >= TGT - 1e-12) / PATHS; top = max(p for v, p in runs)
print(f"chance the target is hit: {hit:.4f}  largest total gain paid on a path: {top:.6f}")
lo, hi, mids = 1.00, 1.10, []
for it in range(40):                          # bisection on the same draws every time
    mid = 0.5 * (lo + hi); v = tarf(K=mid)[0]
    if it < 5: mids.append(f"{mid:.6f} -> {d(v)}")
    lo, hi = (mid, hi) if v > 0 else (lo, mid)
Kz = 0.5 * (lo + hi); Vz = grid(Kz, False)[M][NR - 1]; sez = tarf(K=Kz)[1]
slope = (tarf(K=Kz + 0.001)[0] - tarf(K=Kz - 0.001)[0]) / 0.002   # value per unit of strike, same draws
print("bisection:", "; ".join(mids))
print(f"zero-cost strike {Kz:.6f}  grid value there {d(Vz)}  MC SE {d(sez)}, so strike SE {sez / -slope:.4f}")
kfwd = sum(DF[i] * FWD[i] for i in range(N)) / sum(DF)
print(f"zero-cost strike of the plain strip of forwards: {kfwd:.6f}  gap {kfwd - Kz:.6f}")
h, deltas, vals = 0.001, [], []
for name, m, rem in (("0.00", NR - 1, TGT), ("0.05", i5, 0.05), ("0.09", i1, 0.01)):
    dm = (tarf(S0 + h, rem=rem)[0] - tarf(S0 - h, rem=rem)[0]) / (2 * h)
    dg = (V[M + 1][m] - V[M - 1][m]) / (SP[M + 1] - SP[M - 1]); deltas.append((dm, dg))
    vm = tarf(rem=rem); vals.append((vm, V[M][m]))
    print(f"accrued {name}: value MC {d(vm[0])} grid {d(V[M][m])}  delta EUR MC {d(dm)} grid {d(dg)}")
pend = ncdf((math.log(FWD[0] / (K0 + 0.01)) - 0.5 * SD * SD) / SD)
mend = sum(1 for r in GROW if S0 * r[0] >= K0 + 0.01) / PATHS
print(f"accrued 0.09: chance the first fixing ends the trade: formula {pend:.4f}  MC {mend:.4f}")
a0 = mc(lambda r: accum_path(r, S0, K0), GROW); va = grid(K0, True)[M][0]
print(f"accumulator, wall {H:.2f}: MC {d(a0[0])} +- {d(a0[1])}  grid {d(va)}")
half = PATHS // 2
dfresh = (tarf(S0 + h, rows=GROW[:half])[0] - tarf(S0 - h, rows=GROW[half:])[0]) / (2 * h)
print(f"mistake, ignore the target: {d(fw2)}")
print(f"mistake, ignore the doubling: {d(tarf(lev=1.0)[0])}")
print(f"mistake, pay the full last gain: {d(tarf(full=True)[0])}")
print(f"mistake, fresh draws for the bump: delta {d(dfresh)}")
xs = [1.00, 1.02, 1.04, 1.06, 1.08, 1.10]
print("chart, thousands of dollars, strikes 1.00 to 1.10:")
print("  TARF ", " ".join(f"{tarf(K=x)[0] * 1000:.0f}" for x in xs))
print("  strip", " ".join(f"{strip(x, 2.0) * 1000:.0f}" for x in xs))
assert abs(s1[0] - fw1) < 4 * s1[1] and abs(s2[0] - fw2) < 4 * s2[1]
assert all(abs(vm[0] - vg) < 4 * vm[1] for vm, vg in vals)
assert abs(Vz) < 4 * sez
assert all(abs(dm - dg) < 0.03 * dg for dm, dg in deltas)
assert abs(a0[0] - va) < 4 * a0[1]
assert top <= TGT + 1e-12
assert abs(pend - mend) < 0.005
print("ALL CHECKS PASS")
