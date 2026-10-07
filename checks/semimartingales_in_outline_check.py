# Semimartingales -- the check behind the card.  Only math is imported.
# A share starts at $100.  dS = S_-(mu dt + sigma dW + j (dN - lam dt)):
# average growth mu, wobble sigma, crashes of j = -20% at rate lam = 1 a year.
# Roads: (A) formulas; (B) one path, grid sums at five step sizes;
# (D) 400 grid paths; (C) 20000 exact draws at t = 1.  Plain-loop additions.
import math

S0, MU, SIG, LAM, J, T, SEED = 100.0, 0.05, 0.20, 1.0, -0.20, 1.0, 20260930
G = MU - LAM * J - 0.5 * SIG * SIG           # log-drift between crashes: 0.23
NF, MASK, state = 4096, (1 << 64) - 1, SEED

def uniform():                               # SplitMix64, top 53 bits
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def normal():                                # Box-Muller, cosine half only
    u1 = 1.0 - uniform(); u2 = uniform()
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

def expo(): return -math.log(1.0 - uniform()) / LAM

def mean_se(xs):
    m, v = 0.0, 0.0
    for x in xs: m += x
    m /= len(xs)
    for x in xs: v += (x - m) * (x - m)
    return m, math.sqrt(v / (len(xs) - 1) / len(xs))

def path():                                  # fine grid; crash times exact, then put on the grid
    dt, w, ws = T / NF, 0.0, [0.0]
    for k in range(NF):
        w += math.sqrt(dt) * normal(); ws.append(w)
    jk, t = [], expo()
    while t < T:
        jk.append(int(t * NF) + 1); t = t + expo()
    s, m, p, jsq, comp, cont = [], 1.0, 0, 0.0, 0.0, 0.0
    for k in range(NF + 1):
        while p < len(jk) and jk[p] == k:    # crash at grid time k: pre-crash price times j
            pre = S0 * math.exp(G * k * dt + SIG * ws[k]) * m
            jsq += (J * pre) * (J * pre); comp += math.log(1.0 + J) - J
            m *= 1.0 + J; p += 1
        s.append(S0 * math.exp(G * k * dt + SIG * ws[k]) * m)
        if k < NF: cont += SIG * SIG * s[k] * s[k] * dt   # sigma^2 * integral of S^2 dt
    return s, jk, jsq, cont, comp

def grid(s, n):                              # sum (dS)^2, left sum S dS, left sum dS/S
    p = s[::NF // n]
    qv, left, ret = 0.0, 0.0, 0.0
    for k in range(n):
        ds = p[k + 1] - p[k]
        qv += ds * ds; left += p[k] * ds; ret += ds / p[k]
    return qv, left, ret

def row(label, v): print(f"{label:<44}{v:>12.4f}")
def row_se(label, m, se): print(f"{label:<44}{m:>12.4f}  se {se:.4f}")

print("A  formulas")
c = 2.0 * MU + SIG * SIG + LAM * J * J
ints2 = S0 * S0 * (math.exp(c * T) - 1.0) / c        # integral of E[S_t^2] dt
fs1, fs2 = S0 * math.exp(MU * T), S0 * S0 * math.exp(c * T)
fbr, ford = S0 * S0 * math.exp((2.0 * MU + SIG * SIG) * T), S0 * S0 * math.exp(2.0 * MU * T)
fqc, fqj = SIG * SIG * ints2, LAM * J * J * ints2
fl_a, fl_b = MU * ints2, 0.5 * (fs2 - S0 * S0 - fqc - fqj)
flog_a = math.log(S0) + G * T + LAM * T * math.log(1.0 + J)
flog_b = math.log(S0) + MU * T - 0.5 * SIG * SIG * T + LAM * T * (math.log(1.0 + J) - J)
for lab, v in (("E[S_1]", fs1), ("E[S_1^2], semimartingale Ito", fs2),
               ("E[S_1^2], jumps left out of [S]", fbr), ("E[S_1^2], ordinary chain rule", ford),
               ("E[[S]_1], continuous part", fqc), ("E[[S]_1], jump part", fqj),
               ("E[int S_- dS], as mu * int E[S^2] dt", fl_a), ("E[int S_- dS], by parts", fl_b),
               ("E[log S_1], solved path", flog_a), ("E[log S_1], Ito with jump sum", flog_b),
               ("jump term per crash, log(1+j) - j", math.log(1.0 + J) - J),
               ("try: E[S_1^2], lam = 4, j = -0.10", S0 * S0 * math.exp(2 * MU + SIG * SIG + 4 * 0.01))):
    row(lab, v)
print(f"hand: G {G:.4f}, mu - lam j {MU - LAM * J:.4f}, [S] rate {SIG * SIG + LAM * J * J:.4f}, c {c:.4f}")
print(f"hand: e^c {math.exp(c):.6f}, (e^c - 1)/c {(math.exp(c) - 1) / c:.6f}, int E[S^2] dt {ints2:.2f}")

s, jk, jsq, cont, comp = path()
qs = cont + jsq
print("B  one path, 4096 steps: crashes at", " ".join(f"{k / NF:.4f}" for k in jk))
row("   S_1 on this path", s[NF])
row("   [S]_1 = continuous part + jump part", qs)
row("   jump part, sum of squared crashes", jsq)
lim_left = 0.5 * (s[NF] * s[NF] - S0 * S0 - qs)
row("   left-sum limit (S_1^2 - S_0^2 - [S]_1)/2", lim_left)
row("   integrand S_t, not S_t-: limit", lim_left + jsq)
print("   steps     sum (dS)^2     left sum S dS     identity gap")
for n in (16, 64, 256, 1024, 4096):
    qv, left, ret = grid(s, n)
    gap = abs((s[NF] * s[NF] - S0 * S0) - (2.0 * left + qv))
    print(f"   n {n:>5}   {qv:>11.4f}   {left:>14.4f}   {gap:.9f}")
qv_b, left_b, ret_b = grid(s, NF)
log_ito, log_ex = math.log(S0) + ret_b - 0.5 * SIG * SIG * T + comp, math.log(s[NF])
row("   log S_1, exact", log_ex)
row("   log S_1, Ito formula, 4096-step integral", log_ito)
row("   log S_1, jump sum dropped", log_ito - comp)
print("chart, path " + " ".join(f"{s[k]:.2f}" for k in range(0, NF + 1, 256)))

D_N, ns = 400, (16, 64, 256, 1024, 4096)
err, qsl, jsl, lsl = [0.0] * 5, [], [], []
for i in range(D_N):
    sd, jd, jsd, cd, compd = path()
    for a, n in enumerate(ns):
        err[a] += abs(grid(sd, n)[0] - (cd + jsd)) / D_N
    qsl.append(cd + jsd); jsl.append(jsd); lsl.append(grid(sd, NF)[1])
print("D  400 paths: mean |sum (dS)^2 - [S]_1| by steps")
for a, n in enumerate(ns): print(f"   n {n:>5}   {err[a]:9.4f}")
print("chart, error " + " ".join(f"{e:.2f}" for e in err))
mq, mj, ml = mean_se(qsl), mean_se(jsl), mean_se(lsl)
for lab, v in (("   mean [S]_1", mq), ("   mean jump part", mj), ("   mean left sum S dS, 4096 steps", ml)):
    row_se(lab, *v)
NP = 20000
s1l, s2l, lgl, nl = [], [], [], []
for i in range(NP):
    w, nj, t = normal(), 0, expo()
    while t < T:
        nj += 1; t = t + expo()
    m = 1.0
    for q in range(nj): m *= 1.0 + J
    x = S0 * math.exp(G * T + SIG * w) * m
    s1l.append(x); s2l.append(x * x); lgl.append(math.log(x)); nl.append(float(nj))
m1, m2, mlg, mn = mean_se(s1l), mean_se(s2l), mean_se(lgl), mean_se(nl)
print("C  20000 exact draws at t = 1")
for lab, v in (("   mean S_1", m1), ("   mean S_1^2", m2), ("   mean log S_1", mlg), ("   mean number of crashes", mn)):
    row_se(lab, *v)
assert abs(m2[0] - fs2) < 4 * m2[1], "E[S^2] needs the jump part of [S]"
assert m2[0] - fbr > 4 * m2[1], "the Brownian-only Ito formula is too low"
assert abs(mlg[0] - flog_b) < 4 * mlg[1], "Ito with jump sum gives E[log S]"
assert abs(m1[0] - fs1) < 4 * m1[1], "mean grows at mu"
assert abs(qv_b - qs) < 0.05 * qs, "(dS)^2 sums to [S] on the 4096-step grid"
assert abs(log_ito - log_ex) < 0.01 < abs(log_ito - comp - log_ex), "log needs the jump sum"
assert err[4] < err[0] / 4, "grid error shrinks"
assert abs(mq[0] - fqc - fqj) < 4 * mq[1] and abs(mj[0] - fqj) < 4 * mj[1], "[S] and its jump part"
assert abs(ml[0] - fl_b) < 4 * ml[1], "left sums average to the by-parts value"
print("ALL CHECKS PASS")
