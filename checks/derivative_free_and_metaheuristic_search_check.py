# Search without derivatives -- the check behind the card.  Standard library only.
# Minimise a rough 10-D surface using only its values: Nelder-Mead, annealing, differential
# evolution, random search; 20,000 evaluations per run, 10 seeded runs each (SplitMix64 written out).
# Roads: every result against the proved floor f >= 0; a fixed-temperature walk against Simpson's
# rule on exp(-g/T); Nelder-Mead on McKinnon's function against its calculus minimum; a smooth bowl.
import math
M64 = (1 << 64) - 1
class Rng:
    def __init__(s, seed): s.s = seed & M64
    def u(s):
        s.s = (s.s + 0x9E3779B97F4A7C15) & M64; z = s.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 2.0**53
    def g(s):
        u1 = s.u(); u2 = s.u(); return math.sqrt(-2.0 * math.log(1.0 - u1)) * math.cos(2.0 * math.pi * u2)
def tot(v):  # plain left-to-right sum, as Rust does (Python's sum() compensates)
    s = 0.0
    for t in v: s += t
    return s
N, BOX, BUD, RUNS, T0, TEND = 10, 5.12, 20000, 10, 30.0, 0.1
def ripple(t): return t * t - 10.0 * math.cos(2.0 * math.pi * t) + 10.0
rq, Q = Rng(2026), []          # a fixed random rotation, by Gram-Schmidt
for i in range(N):
    v = [rq.g() for _ in range(N)]
    for w in Q:
        d = tot(a * b for a, b in zip(v, w)); v = [a - d * b for a, b in zip(v, w)]
    nv = math.sqrt(tot(a * a for a in v)); Q.append([a / nv for a in v])
def rough(x): return tot(ripple(tot(Q[i][j] * x[j] for j in range(N))) for i in range(N))
def mck(x): return (360.0 if x[0] <= 0 else 6.0) * x[0] * x[0] + x[1] + x[1] * x[1]
def bowl(x): return tot(t * t for t in x)
st = {}
def reset(): st.update(n=0, best=math.inf, hist=[])
def ev(fn, x):                 # every evaluation goes through here: count it, track the best so far
    v = fn(x); st['n'] += 1; st['best'] = min(st['best'], v)
    if st['n'] % 2000 == 0: st['hist'].append(st['best'])
    return v
def simplex(x, step): return [list(x)] + [[x[j] + (step if j == i else 0.0) for j in range(len(x))] for i in range(len(x))]
def nelder_mead(fn, P, budget):
    n = len(P) - 1; V = [ev(fn, p) for p in P]
    while st['n'] + n + 2 <= budget:
        o = sorted(range(n + 1), key=lambda i: V[i]); P = [P[i] for i in o]; V = [V[i] for i in o]
        if V[n] - V[0] <= 1e-8 and max(abs(p[j] - P[0][j]) for p in P for j in range(n)) <= 1e-6: break
        c = [tot(P[i][j] for i in range(n)) / n for j in range(n)]
        pt = lambda t: [c[j] + t * (P[n][j] - c[j]) for j in range(n)]
        xr = pt(-1.0); fr = ev(fn, xr)
        if fr < V[0]:
            xe = pt(-2.0); fe = ev(fn, xe); P[n], V[n] = (xe, fe) if fe < fr else (xr, fr)
        elif fr < V[n - 1]: P[n], V[n] = xr, fr
        else:
            xc = pt(-0.5 if fr < V[n] else 0.5); fc = ev(fn, xc)
            if fc < min(fr, V[n]): P[n], V[n] = xc, fc
            else:
                for i in range(1, n + 1):
                    P[i] = [P[0][j] + 0.5 * (P[i][j] - P[0][j]) for j in range(n)]; V[i] = ev(fn, P[i])
    i = min(range(n + 1), key=lambda i: V[i]); return P[i], V[i]
def anneal(x, temp, r):        # one coordinate moves by a normal step of spread 1; Metropolis test
    fx = ev(rough, x)
    while st['n'] < BUD:
        T = temp(st['n']); y = list(x); i = int(r.u() * N); y[i] += r.g()
        fy = ev(rough, y); d = fy - fx
        if d <= 0 or (T > 0 and r.u() < math.exp(-d / T)): x, fx = y, fy
    return fx
def evolve(r, NP=40, F=0.5, CR=0.9):  # differential evolution, rand/1/bin
    P = [[BOX * (2 * r.u() - 1) for _ in range(N)] for _ in range(NP)]; V = [ev(rough, p) for p in P]
    while st['n'] + NP <= BUD:
        for i in range(NP):
            a = b = c = i
            while a == i: a = int(r.u() * NP)
            while b in (i, a): b = int(r.u() * NP)
            while c in (i, a, b): c = int(r.u() * NP)
            jr = int(r.u() * N)
            y = [P[a][j] + F * (P[b][j] - P[c][j]) if (r.u() < CR or j == jr) else P[i][j] for j in range(N)]
            fy = ev(rough, y)
            if fy <= V[i]: P[i], V[i] = y, fy
q = (TEND / T0) ** (1.0 / BUD)
temps = {'anneal': lambda k: T0 * q ** k, 'cold, T = 0': lambda k: 0.0,
         'hot, T = 30 held': lambda k: T0, 'log cooling': lambda k: T0 / math.log(k + 2.0)}
res = {m: [] for m in ['random search', 'Nelder-Mead, one run', 'Nelder-Mead, multistart', 'anneal',
                       'cold, T = 0', 'hot, T = 30 held', 'log cooling', 'differential evolution']}
one_evals, starts, ends, hists, x01 = [], [], {}, {}, None
for seed in range(1, RUNS + 1):
    r = Rng(seed); reset(); x0 = [BOX * (2 * r.u() - 1) for _ in range(N)]; x = x0; x01 = x01 or x0
    while st['n'] + 2 * N + 3 <= BUD:   # multistart: fresh random start each time a simplex collapses
        x, v = nelder_mead(rough, simplex(x, 1.0), BUD)
        if len(one_evals) < seed: res['Nelder-Mead, one run'].append(v); one_evals.append(st['n'])
        x = [BOX * (2 * r.u() - 1) for _ in range(N)]
    st['hist'] += [st['best']] * (BUD // 2000 - len(st['hist'])); res['Nelder-Mead, multistart'].append(st['best']); hists.setdefault('nm', st['hist'])
    for m, temp in temps.items():
        reset(); fend = anneal(list(x0), temp, Rng(1000 + seed)); res[m].append(st['best'])
        ends.setdefault(m, []).append(fend); hists.setdefault(m, st['hist'])
    reset(); evolve(Rng(2000 + seed)); res['differential evolution'].append(st['best']); hists.setdefault('de', st['hist'])
    reset(); r = Rng(3000 + seed); [ev(rough, [BOX * (2 * r.u() - 1) for _ in range(N)]) for _ in range(BUD)]
    res['random search'].append(st['best']); starts.append(rough(x0))
mean = lambda v: tot(v) / len(v)
print(f"n = {N}, budget {BUD}, {RUNS} runs, f(origin) = {rough([0.0] * N):.2f}; start, run 1: f = {starts[0]:.2f}; mean start {mean(starts):.2f}")
for m, v in res.items(): print(f"{m:26s} mean {mean(v):6.2f}  best {min(v):6.2f}  worst {max(v):6.2f}")
print(f"one Nelder-Mead run stops after {mean(one_evals):.1f} evaluations on average")
for m in ['anneal', 'hot, T = 30 held', 'log cooling']: print(f"{m}: mean value where the walk ends {mean(ends[m]):.2f}")
print(f"cooling factor q = {q:.6f}; T at 10000 = {T0 * q ** 10000:.4f}; log cooling T at 20000 = {T0 / math.log(BUD + 2.0):.4f}")
for k in range(0, BUD + 1, 4000):
    T = T0 * q ** k; b = hists['anneal'][k // 2000 - 1] if k else starts[0]
    print(f"trace k = {k:5d}: T = {T:8.4f}, accept +10 with {math.exp(-10 / T):.6f}, best so far {b:.2f}")
for m in ['nm', 'anneal', 'de']: print(f"chart {m}: " + ", ".join(f"{v:.2f}" for v in [starts[0]] + hists[m]))
print("chart ripple: " + ", ".join(f"{ripple(-3 + 0.25 * k):.2f}" for k in range(25)))
s33 = math.sqrt(33.0); P = [[0.0, 0.0], [1.0, 1.0], [(1 + s33) / 8, (1 - s33) / 8]]
c = [(P[0][j] + P[2][j]) / 2 for j in range(2)]; xr = [2 * c[j] - P[1][j] for j in range(2)]
xcc = [c[j] + 0.5 * (P[1][j] - c[j]) for j in range(2)]
print("McKinnon start: f = " + ", ".join(f"{mck(p):.4f}" for p in P) + f"; third vertex ({P[2][0]:.4f}, {P[2][1]:.4f})")
print(f"McKinnon step: c = ({c[0]:.4f}, {c[1]:.4f}), reflect ({xr[0]:.4f}, {xr[1]:.4f}) f = {mck(xr):.4f}, "
      f"inside ({xcc[0]:.4f}, {xcc[1]:.4f}) f = {mck(xcc):.4f}")
reset(); xs, vs = nelder_mead(mck, P, 5000); n1 = st['n']
xm, vm = nelder_mead(mck, simplex(xs, 1.0), 5000)
print(f"McKinnon stall: ({xs[0]:.6f}, {xs[1]:.6f}) f = {vs:.6f} after {n1}; restart: ({xm[0]:.6f}, {xm[1]:.6f}) "
      f"f = {vm:.6f} after {st['n']}; true minimum f(0, -0.5) = {mck([0.0, -0.5]):.6f}")
reset(); xb, vb = nelder_mead(bowl, simplex(x01, 1.0), BUD)
print(f"smooth bowl, same start: Nelder-Mead reaches f = {vb:.2e} after {st['n']} evaluations")
r, y, fy, inside, T, batch = Rng(4000), 0.0, ripple(0.0), [0] * 20, 5.0, 10000   # walk at a fixed T
for k in range(20 * batch):
    z = y + r.g(); fz = ripple(z)
    if fz <= fy or r.u() < math.exp(-(fz - fy) / T): y, fy = z, fz
    if abs(y) < 0.5: inside[k // batch] += 1
def simpson(a, b, m=2000):
    h = (b - a) / m; w = lambda k: 1 if k in (0, m) else (4 if k % 2 else 2)
    return tot(w(k) * math.exp(-ripple(a + k * h) / T) for k in range(m + 1)) * h / 3
share = [i / batch for i in inside]; walk = mean(share)
se = math.sqrt(tot((s - walk) * (s - walk) for s in share) / (19 * 20)); exact = simpson(-0.5, 0.5) / simpson(-10.0, 10.0)
print(f"fixed T = 5, one ripple: walk spends {walk:.4f} of its time in |y| < 0.5 (se {se:.4f}); exp(-g/T) gives {exact:.4f}")
L = 2 * BOX * math.sqrt(N) + 20 * math.pi * math.sqrt(N); h = 2 * 1.0 / (L * math.sqrt(N)); m = math.ceil(2 * BOX / h) + 1
print(f"certificate by grid: L = {L:.2f}, spacing {h:.6f}, {m} points per axis, 10^{N * math.log10(m):.2f} points")
p = math.pi ** 5 / 120 * 0.5 ** N / (2 * BOX) ** N; print(f"random search: one draw lands within 0.5 of the origin with chance {p * 1e13:.4f} in 10^13; "
      f"expected draws {1 / p / 1e12:.2f} million million")
orth = max(abs(tot(Q[i][k] * Q[j][k] for k in range(N)) - (i == j)) for i in range(N) for j in range(N))
assert orth < 1e-12, "the rotation is not orthogonal"
assert min(min(v) for v in res.values()) >= 0.0, "a best found below the proved floor f >= 0"
assert vs > mck([0.0, -0.5]) + 0.2 and abs(vm - mck([0.0, -0.5])) < 1e-6, "McKinnon: stall, then restart"
assert mck(xr) >= mck(P[1]) and mck(xcc) < mck(P[1]), "McKinnon's first step is an inside contraction"
assert vb < 1e-8, "Nelder-Mead on a smooth bowl must reach 0"; assert abs(walk - exact) < 4 * se, "fixed-temperature walk must match exp(-g/T)"
assert mean(res['anneal']) < mean(res['cold, T = 0']) and mean(res['anneal']) < mean(res['Nelder-Mead, multistart'])
print("ALL CHECKS PASS")
