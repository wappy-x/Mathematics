# Attention and transformers -- the check behind the card.  Standard library only.
# Sentence "the cat sat on the mat", width d = 2.  Every number on the card is printed here.
from math import exp, sqrt, sin, cos, log

WORDS = ["the", "cat", "sat", "on", "the", "mat"]
EMB = {"the": (1.0, 0.0), "cat": (0.0, 2.0), "sat": (1.0, 1.0), "on": (1.0, -1.0), "mat": (0.0, 1.0)}
WQ = [[1.0, 0.0], [0.0, 1.0]]               # query matrix: keep x
WK = [[0.0, 1.0], [1.0, 0.0]]               # key matrix: swap the two numbers
WV = [[1.0, 0.0], [0.0, 1.0]]               # value matrix: keep x
COUNT = [0]                                  # multiplications done inside matrix products

def matmul(A, B):                            # row by column, counting every multiplication
    COUNT[0] += len(A) * len(B) * len(B[0])
    return [[sum(A[i][t] * B[t][j] for t in range(len(B))) for j in range(len(B[0]))] for i in range(len(A))]

def softmax(row):                            # shift by the largest score, exponentiate, divide by the total
    m = max(row); e = [exp(s - m) for s in row]; z = sum(e)
    return [t / z for t in e]

def attention(X, wq=WQ, wk=WK, wv=WV):       # road 1: softmax(Q K^T / sqrt d) V, as matrices
    Q, K, V = matmul(X, wq), matmul(X, wk), matmul(X, wv)
    d = len(Q[0]); KT = [list(c) for c in zip(*K)]
    A = [softmax([s / sqrt(d) for s in row]) for row in matmul(Q, KT)]
    return A, matmul(A, V)

def attention_online(X):                     # road 2: one pass over the keys, running max and running sum
    Q, K, V = matmul(X, WQ), matmul(X, WK), matmul(X, WV); d = len(Q[0]); out = []
    for q in Q:
        m, z, acc = -1e300, 0.0, [0.0] * d
        for k, v in zip(K, V):
            s = sum(a * b for a, b in zip(q, k)) / sqrt(d); m2 = max(m, s); c = exp(m - m2); w = exp(s - m2)
            z = z * c + w; acc = [a * c + w * vi for a, vi in zip(acc, v)]; m = m2
        out.append([a / z for a in acc])
    return out

def pos(t): return (sin(t), cos(t))         # the sine-and-cosine position code, width 2
def embed(words, with_pos):
    return [[EMB[w][0] + (pos(t)[0] if with_pos else 0.0), EMB[w][1] + (pos(t)[1] if with_pos else 0.0)] for t, w in enumerate(words)]
def show(label, v): print(f"{label:<30}" + " ".join(f"{x:8.4f}" for x in v))
def gap(P, R): return max(abs(a - b) for p, r in zip(P, R) for a, b in zip(p, r))

X = embed(WORDS, False)
A, Z = attention(X)
print("weights: row = the word looking, columns = the six words it looks at")
for w, row in zip(WORDS, A): show(f"  {w:<4} (row sum {sum(row):.4f})", row)
for w, z in zip(WORDS, Z): show(f"output {w}", z)
# worked row by hand: "sat", query (1, 1)
s = [sum(a * b for a, b in zip((1.0, 1.0), (k[1], k[0]))) for k in X]
show("sat: dot products q.k", s); show("sat: divided by sqrt 2", [t / sqrt(2) for t in s])
e = [exp(t / sqrt(2)) for t in s]; show("sat: e to each", e); show("sat: total of e", [sum(e)])
hand = exp(sqrt(2)) / (3 * exp(1 / sqrt(2)) + 2 * exp(sqrt(2)) + 1)     # closed form, weight of sat on cat
show("sat on cat: closed form", [hand])
show("sat: weight x value, first", [A[2][j] * X[j][0] for j in range(6)])
show("sat: weight x value, second", [A[2][j] * X[j][1] for j in range(6)])
Zo = attention_online(X); show("road 2 online, largest gap", [gap(Z, Zo)])

def permute(L, p): return [L[i] for i in p]
def perms(L):
    if len(L) <= 1: yield list(L); return
    for i in range(len(L)):
        for rest in perms(L[:i] + L[i + 1:]): yield [L[i]] + rest
swap = [0, 5, 2, 3, 4, 1]                    # "the mat sat on the cat"
_, Zs = attention(embed(permute(WORDS, swap), False))
show("swapped: output at slot 2 (mat)", Zs[1]); show("swapped: output at slot 6 (cat)", Zs[5])
show("swapped vs reordered, gap", [gap(Zs, permute(Z, swap))])
ok_plain = ok_pos = 0
_, Zp = attention(embed(WORDS, True))
for p in perms(list(range(6))):              # road 3: all 720 orders
    ok_plain += gap(attention(embed(permute(WORDS, p), False))[1], permute(Z, p)) < 1e-12
    ok_pos += gap(attention(embed(permute(WORDS, p), True))[1], permute(Zp, p)) < 1e-12
print(f"orders tested 720; equivariant without positions {ok_plain}; with positions {ok_pos}")
show("positions: output the (slot 1)", Zp[0]); show("positions: output the (slot 5)", Zp[4])
_, Zps = attention(embed(permute(WORDS, swap), True))
show("positions: swap gap", [gap(Zps, permute(Zp, swap))])

def block(n, d, h):                          # road 4: one transformer block, counting multiplications
    COUNT[0] = 0; X = [[0.01 * (i + j) for j in range(d)] for i in range(n)]
    I = [[1.0 if i == j else 0.0 for j in range(d)] for i in range(d)]
    Q, K, V = matmul(X, I), matmul(X, I), matmul(X, I); w = d // h; heads = []
    for g in range(h):                       # each head sees its own w = d/h columns
        q = [r[g * w:(g + 1) * w] for r in Q]; k = [r[g * w:(g + 1) * w] for r in K]; v = [r[g * w:(g + 1) * w] for r in V]
        A = [softmax([x / sqrt(w) for x in row]) for row in matmul(q, [list(c) for c in zip(*k)])]
        heads.append(matmul(A, v))
    H = [sum((hd[i] for hd in heads), []) for i in range(n)]
    Y = matmul(H, I)                                             # output matrix W_O
    F = [[max(0.0, x) for x in r] for r in matmul(Y, [[0.1] * (4 * d) for _ in range(d)])]
    matmul(F, [[0.1] * d for _ in range(4 * d)])                 # feed-forward d -> 4d -> d
    return COUNT[0]
def formula(n, d): return 12 * n * d * d + 2 * n * n * d
print(f"house block n=6 d=2: projections {3*6*4}, scores {36*2}, mixing {36*2}, output {6*4}, feed-forward {8*6*4}")
for n, d, h in ((6, 2, 1), (6, 2, 2), (12, 4, 2), (24, 4, 2), (48, 4, 4), (96, 8, 2)):
    c = block(n, d, h); print(f"block n={n:<3} d={d} heads={h}: counted {c:>7}, 12nd^2 + 2n^2d = {formula(n, d):>7}")
    assert c == formula(n, d), "counted multiplications must meet the formula"
print(f"attention part overtakes the rest at n = 6d = {6 * 768} for d = 768, at n = 6d = {6 * 2} for d = 2")
print(f"block total n=1024 d=768: {formula(1024, 768) / 1e9:.2f}e9; sqrt 512 = {sqrt(512):.4f}")
for n in (512, 1024, 2048, 4096, 8192, 16384):
    print(f"chart, d=768 n={n:<5}  attention 2n^2d {2*n*n*768/1e9:6.2f}e9  rest 12nd^2 {12*n*768*768/1e9:6.2f}e9")

def splitmix(s):                             # SplitMix64, written out
    s = (s + 0x9E3779B97F4A7C15) & (2**64 - 1); z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1); z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
    return s, (z ^ (z >> 31)) / 2**64
seed = 2026
for d in (2, 64, 512):                       # what breaks: drop the 1/sqrt d
    tot = [0.0, 0.0]
    for _ in range(1000):
        vals = []
        for _ in range(7 * d): seed, u = splitmix(seed); vals.append(sqrt(3) * (2 * u - 1))   # mean 0, variance 1
        q, ks = vals[:d], [vals[d * (j + 1):d * (j + 2)] for j in range(6)]
        raw = [sum(a * b for a, b in zip(q, k)) for k in ks]
        tot[0] += max(softmax([r / sqrt(d) for r in raw])); tot[1] += max(softmax(raw))
    print(f"d={d:<4} average largest weight: scaled {tot[0]/1000:.4f}  unscaled {tot[1]/1000:.4f}")
    if d == 512: assert tot[1] / 1000 > 0.95 and tot[0] / 1000 < 0.6, "unscaled softmax should saturate"
S = matmul(matmul(X, WQ), [list(c) for c in zip(*matmul(X, WK))])
cols = [softmax([S[i][j] / sqrt(2) for i in range(6)]) for j in range(6)]   # wrong axis: down each column
show("wrong axis: row sums", [sum(cols[j][i] for j in range(6)) for i in range(6)])
print(f"causal mask: scores kept {sum(i + 1 for i in range(6))} of 36")

assert all(abs(sum(r) - 1) < 1e-12 for r in A), "each row of weights sums to 1"
assert abs(A[2][1] - hand) < 1e-12, "sat's weight on cat meets the closed form"
assert gap(Z, Zo) < 1e-12, "online road meets the matrix road"
assert ok_plain == 720 and ok_pos < 720, "equivariant in every order, until positions are added"
assert gap(Zs, permute(Z, swap)) < 1e-12 and gap(Zps, permute(Zp, swap)) > 0.01, "the swap test"
print("ALL CHECKS PASS")
