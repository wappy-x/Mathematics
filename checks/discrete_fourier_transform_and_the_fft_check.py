# The DFT and the FFT -- the check behind the card.  Standard library only.  A model guitar chord
# (open E major: six steady pure tones, one per string) sampled at 44.1 kHz.  Road one: the DFT sum
# written out, N x N products.  Road two: the FFT, halving again and again, with every product counted.
import math
FS = 44100.0                                             # sampling rate, Hz
NOTES = [("E2", 82.4069, 0.30), ("B2", 123.4708, 0.25), ("E3", 164.8138, 0.22),
         ("G#3", 207.6523, 0.20), ("B3", 246.9417, 0.18), ("E4", 329.6276, 0.15)]
count = [0]
tw = lambda m, n: complex(math.cos(2 * math.pi * m / n), -math.sin(2 * math.pi * m / n))   # w^m, w = e^(-2 pi j/n)

def tone_block(n, tones):                                # x[n]: a sum of sines, n samples from t = 0
    return [sum(a * math.sin(2 * math.pi * f * i / FS) for _, f, a in tones) for i in range(n)]

def dft(x):                                              # road one: the definition, N x N products
    N = len(x)
    table = [tw(m, N) for m in range(N)]
    count[0] += N * N
    return [sum(x[i] * table[k * i % N] for i in range(N)) for k in range(N)]

def one_bin(x, k):                                       # one output by the definition, for spot checks
    N = len(x)
    return sum(x[i] * tw(k * i % N, N) for i in range(N))

def fft(a, sign=-1.0, mode="right"):                     # road two: even half, odd half, stitch
    n = len(a)
    if n == 1: return [complex(a[0])]
    ev, od, out = fft(a[0::2], sign, mode), fft(a[1::2], sign, mode), [0j] * n
    for k in range(n // 2):
        w = complex(math.cos(2 * math.pi * k / n), sign * math.sin(2 * math.pi * k / n))
        t = od[k] if mode == "no turn" else w * od[k]
        count[0] += 1
        out[k] = ev[k] + t
        out[k + n // 2] = ev[k] + t if mode == "same sign" else ev[k] - t
    return out

def amps(X, n_real):                                     # 2|X[k]|/N: a tone's height, bins 0 to N/2
    return [2 * math.sqrt(z.real ** 2 + z.imag ** 2) / n_real for z in X[:len(X) // 2 + 1]]

def peaks(a, floor):                                     # local maxima above the floor
    return [k for k in range(1, len(a) - 1) if a[k] > floor and a[k] > a[k - 1] and a[k] >= a[k + 1]]

gap = lambda A, B: max(math.sqrt((p - q).real ** 2 + (p - q).imag ** 2) for p, q in zip(A, B))
N, NL, FLOOR = 1024, 16384, 0.08
x = tone_block(N, NOTES)
count[0] = 0; Xd = dft(x); m_dft = count[0]
count[0] = 0; X = fft(x); m_fft = count[0]
count[0] = 0; E, O = dft(x[0::2]), dft(x[1::2]); m_one = count[0] + N // 2   # one split by hand
H, w8 = N // 2, tw(8, N)
split = [E[k % H] + (1 if k < H else -1) * tw(k % H, N) * O[k % H] for k in range(N)]
back = [z / N for z in fft(X, +1.0)]
e_t, e_f = sum(v * v for v in x), sum(z.real ** 2 + z.imag ** 2 for z in X) / N
df, rec = FS / N, N / FS
print(f"block: N = {N} samples at {FS / 1000:.1f} kHz; record {1000 * rec:.2f} ms; bin width fs/N = {df:.2f} Hz = 1/record")
print(f"top bin N/2 = {N // 2}: {N // 2 * df:.2f} Hz, the Nyquist frequency")
print(f"multiplications: DFT sum {m_dft}; FFT {m_fft}; (N/2) log2 N = {N // 2 * int(math.log2(N))}; speed-up {m_dft / m_fft:.1f}")
print(f"one split: two 512-point sums {m_one - N // 2} products + {N // 2} turns = {m_one}; split against DFT sum: {'below 1e-9' if gap(split, Xd) < 1e-9 else 'TOO BIG'}")
c4 = lambda z: f"{z.real:.4f} {'-' if z.imag < 0 else '+'} {abs(z.imag):.4f}j"
print(f"bin 8: E[8] = {c4(E[8])}; O[8] = {c4(O[8])}; w^8 = {c4(w8)}")
print(f"bin 8: X[8] = E[8] + w^8 O[8] = {c4(E[8] + w8 * O[8])}; X[520] = E[8] - w^8 O[8] = {c4(E[8] - w8 * O[8])}")
print(f"FFT against DFT sum, largest gap: {'below 1e-9' if gap(X, Xd) < 1e-9 else 'TOO BIG'}")
print(f"inverse FFT returns the samples: {'yes' if gap(back, x) < 1e-12 else 'no'}; energy sum x^2 {e_t:.6f}, sum |X|^2 / N {e_f:.6f}")
for nm, f, a in NOTES:
    print(f"  {nm:<3} {f:8.2f} Hz  amplitude {a:.2f}  sits at bin {f / df:5.2f}; nearest bin {round(f / df)} = {round(f / df) * df:6.2f} Hz")
a1 = amps(X, N)
pk1 = peaks(a1, FLOOR)
print(f"1024 block, peaks above {FLOOR:.2f}: {len(pk1)} at bins {pk1} = {', '.join(f'{k * df:.2f}' for k in pk1)} Hz")
print("chart, 1024 block, bin " + " ".join(f"{k}" for k in range(1, 13)))
print("chart, 1024 block, Hz " + " ".join(f"{k * df:.0f}" for k in range(1, 13)))
print("chart, 1024 block, height " + " ".join(f"{v:.3f}" for v in a1[1:13]))
gaps = [NOTES[i + 1][1] - NOTES[i][1] for i in range(5)]
print(f"gaps between strings: {', '.join(f'{g:.2f}' for g in gaps)} Hz; E2 and B2 drift {gaps[0] * rec:.2f} cycles apart in {1000 * rec:.2f} ms, {gaps[0] * NL / FS:.2f} in {NL / FS:.4f} s")
e4 = round(329.6276 / df) * df
print(f"E4 read from the 1024 block: {e4:.2f} Hz, {e4 - 329.6276:.2f} Hz sharp, {1200 * math.log2(e4 / 329.6276):.1f} cents")
xl = tone_block(NL, NOTES)
count[0] = 0; XL = fft(xl); m_long = count[0]
dfl, aL = FS / NL, amps(XL, NL)
pkL = peaks(aL, FLOOR)
print(f"long block: N = {NL}, record {NL / FS:.4f} s, bin width {dfl:.4f} Hz; FFT {NL // 2} x {round(math.log(NL, 2))} = {m_long} products; DFT sum would need {NL * NL}, speed-up {NL * NL / m_long:.0f}")
spot = gap([XL[k] for k in pkL], [one_bin(xl, k) for k in pkL])
print(f"E4 sits at long-block bin {329.6276 / dfl:.2f}")
print(f"long block, peaks above {FLOOR:.2f}: {len(pkL)}; FFT at those bins against the DFT sum: {'below 1e-8' if spot < 1e-8 else 'TOO BIG'}")
for (nm, f, a), k in zip(NOTES, pkL):
    print(f"  {nm:<3} bin {k:3d} = {k * dfl:6.2f} Hz  (true {f:6.2f}, off {k * dfl - f:+.2f})  height {aL[k]:.3f}  {'#' * round(100 * aL[k])}")
pad = fft(x + [0.0] * (NL - N))
pkP = peaks(amps(pad, N), FLOOR)
print(f"1024 samples padded with zeros to {NL}: bins {dfl:.4f} Hz apart, peaks above {FLOOR:.2f}: {len(pkP)} at {', '.join(f'{k * dfl:.2f}' for k in pkP)} Hz")
on = amps(fft(tone_block(N, [("", 10 * df, 1.0)])), N)
half = amps(fft(tone_block(N, [("", 10.5 * df, 1.0)])), N)
print(f"tone of height 1 on bin 10 ({10 * df:.2f} Hz): bin 10 reads {on[10]:.6f}, bin 11 reads {on[11]:.6f}")
print(f"tone of height 1 at bin 10.5 ({10.5 * df:.2f} Hz): bins 10 and 11 read {half[10]:.3f} and {half[11]:.3f}; bin 20 still {half[20]:.3f}")
count[0] = 0; ss = fft(x, mode="same sign"); nt = fft(x, mode="no turn")
print(f"mistake, top half stitched with + not -: largest error {gap(ss, Xd):.2f}; no turn w^k on the odd half: {gap(nt, Xd):.2f}")
print(f"mistake, bin 1016 of 1024 read as {1016 * df:.2f} Hz; it is the mirror of bin 8, {8 * df:.2f} Hz")
print(f"10 s recording: {int(10 * FS)} samples, resolution 1/10 s = {1 / 10:.2f} Hz; padded to 2^19 = {2 ** 19}: DFT sum {2 ** 38}, FFT {2 ** 18 * 19}, speed-up {2 ** 38 / (2 ** 18 * 19):.0f}")
pk4 = peaks(amps(fft(tone_block(4096, NOTES)), 4096), FLOOR)
print(f"try: N 2048 -> {FS / 2048:.2f} Hz, record {2048 / FS * 1000:.2f} ms; fs 48 kHz, N 1024 -> {48000 / 1024:.2f} Hz; N 4096 -> {FS / 4096:.2f} Hz, {len(pk4)} peaks; Wi-Fi 20 MHz / 64 -> {20e6 / 64 / 1000:.1f} kHz")
assert gap(X, Xd) < 1e-9                                 # road two against road one
assert gap(split, Xd) < 1e-9                             # one even/odd split against road one
assert m_fft == N // 2 * round(math.log(N, 2))           # products counted against (N/2) log2 N
assert gap(back, x) < 1e-12                              # the inverse returns the samples
assert abs(e_t - e_f) < 1e-9                             # energy, time side against frequency side
assert len(pkL) == 6 and all(abs(k * dfl - f) <= dfl / 2 for (_, f, _), k in zip(NOTES, pkL))
assert spot < 1e-8                                       # long-block FFT against single-bin sums
assert abs(on[10] - 1.0) < 1e-9                          # an on-bin tone reads its own height
assert len(pk1) < 6                                      # 43 Hz bins cannot name six strings
assert len(pk4) == 6 and all(abs(k * FS / 4096 - f) <= FS / 8192 for (_, f, _), k in zip(NOTES, pk4))   # 10.77 Hz bins can
print("ALL CHECKS PASS")
