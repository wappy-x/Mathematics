// Wiener and LMS -- the same check as adaptive_and_optimal_filters_check.py, in Rust.
// Standard library only, no crates.  The random numbers, the 2x2 solve and both filters
// are written out.  A cabin microphone hears a voice plus engine noise; a microphone at the
// engine hears the noise alone.  A two-tap filter turns the second signal into the first one's noise.
const FS: usize = 8000;
const SECONDS: usize = 10;
const N: usize = FS * SECONDS;
const H: (f64, f64) = (0.8, 0.4); // the path from engine to cabin microphone, unknown to the filter
const A: f64 = 0.5; // the voice: a random signal of power A*A = 0.25
const MU: f64 = 0.01; // the LMS step size

struct Rng(u64); // xorshift64, scaled to uniform on [-sqrt 3, sqrt 3]: power 1
impl Rng {
    fn next(&mut self) -> f64 {
        let mut s = self.0;
        s ^= s << 13; s ^= s >> 7; s ^= s << 17;
        self.0 = s;
        ((s >> 11) as f64 / 9007199254740992.0 * 2.0 - 1.0) * 3.0_f64.sqrt()
    }
}

// x: engine mic, d: cabin mic, s: the voice alone; index n + 1 holds sample n, x[0] is x[-1]
fn recording() -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let (mut g, mut talk) = (Rng(2026), Rng(7)); // engine and voice from separate generators
    let mut u_prev = g.next();
    let first = (u_prev + g.next()) / 2.0_f64.sqrt();
    let (mut x, mut d, mut s) = (vec![first], vec![0.0], vec![0.0]);
    u_prev = g.next();
    for _ in 0..N {
        let u = g.next();
        let xn = (u + u_prev) / 2.0_f64.sqrt(); // smooth rumble: neighbours alike
        u_prev = u;
        let sn = A * talk.next();
        let before = x[x.len() - 1];
        x.push(xn); s.push(sn); d.push(sn + H.0 * xn + H.1 * before);
    }
    (x, d, s)
}

fn solve2(a: f64, b: f64, c: f64, e: f64, f: (f64, f64)) -> (f64, f64) { // Cramer's rule
    let det = a * e - b * c;
    ((f.0 * e - b * f.1) / det, (a * f.1 - c * f.0) / det)
}

fn cost(w: (f64, f64), r0: f64, r1: f64, p: (f64, f64), sd2: f64) -> f64 { // the bowl J(w)
    sd2 - 2.0 * (p.0 * w.0 + p.1 * w.1) + r0 * (w.0 * w.0 + w.1 * w.1) + 2.0 * r1 * w.0 * w.1
}

fn steepest(mu: f64, steps: usize, r0: f64, r1: f64, p: (f64, f64)) -> (f64, f64) { // road 3
    let mut w = (0.0, 0.0);
    for _ in 0..steps {
        let g0 = p.0 - r0 * w.0 - r1 * w.1;
        let g1 = p.1 - r1 * w.0 - r0 * w.1;
        w = (w.0 + mu * g0, w.1 + mu * g1);
    }
    w
}

struct Run { end: (f64, f64), avg: (f64, f64), mse: f64, left: f64, marks: Vec<(f64, f64)> }

fn lms(x: &[f64], d: &[f64], s: &[f64], mu: f64, sign: f64, stop: usize, marks: &[usize]) -> Run {
    let (mut w0, mut w1) = (0.0_f64, 0.0_f64); // road 4: learn sample by sample
    let (mut err2, mut left2, mut avg0, mut avg1) = (0.0, 0.0, 0.0, 0.0);
    let mut out = Vec::new();
    for n in 0..stop {
        if marks.contains(&n) { out.push((w0, w1)); }
        let e = d[n + 1] - (w0 * x[n + 1] + w1 * x[n]); // the output: voice plus leftover noise
        if n >= stop.saturating_sub(FS) { // score the last second
            err2 += e * e; left2 += (e - s[n + 1]) * (e - s[n + 1]); avg0 += w0; avg1 += w1;
        }
        w0 += sign * mu * e * x[n + 1]; w1 += sign * mu * e * x[n];
    }
    let f = FS as f64;
    Run { end: (w0, w1), avg: (avg0 / f, avg1 / f), mse: err2 / f, left: left2 / f, marks: out }
}

fn main() {
    let (r0, r1, voice) = (1.0_f64, 0.5_f64, A * A); // engine noise: power 1, neighbour correlation 0.5
    let p = (H.0 * r0 + H.1 * r1, H.0 * r1 + H.1 * r0); // E[d x(n)], E[d x(n-1)]
    let noise = r0 * (H.0 * H.0 + H.1 * H.1) + 2.0 * r1 * H.0 * H.1; // h.R h
    let sd2 = voice + noise;
    let w_ex = solve2(r0, r1, r1, r0, p);
    let j_ex = cost(w_ex, r0, r1, p, sd2);
    let (x, d, s) = recording();
    let sum = |f: &dyn Fn(usize) -> f64| (0..N).fold(0.0, |acc, n| acc + f(n));
    let sxx = sum(&|n| x[n + 1] * x[n + 1]);
    let sx1 = sum(&|n| x[n + 1] * x[n]);
    let s11 = sum(&|n| x[n] * x[n]);
    let pd0 = sum(&|n| d[n + 1] * x[n + 1]);
    let pd1 = sum(&|n| d[n + 1] * x[n]);
    let w_dat = solve2(sxx, sx1, sx1, s11, (pd0, pd1)); // road 2: least squares on the recording
    let mic_noise = sum(&|n| (d[n + 1] - s[n + 1]) * (d[n + 1] - s[n + 1])) / N as f64;
    let e_true: Vec<f64> = (0..N).map(|n| d[n + 1] - (H.0 * x[n + 1] + H.1 * x[n])).collect();
    let orth0 = sum(&|n| e_true[n] * x[n + 1]) / N as f64;
    let orth1 = sum(&|n| e_true[n] * x[n]) / N as f64;
    let w_sd = steepest(0.5, 60, r0, r1, p);
    let marks = [0usize, 50, 100, 200, 400, 800, 1600];
    let run = lms(&x, &d, &s, MU, 1.0, N, &marks);
    let misadj = MU * (r0 + r0) / 2.0; // mu * trace(R) / 2
    let (fast, slow) = (r0 + r1, r0 - r1); // eigenvalues of R: along (1, 1) and along (1, -1)
    println!("setup: {} samples/s, {} s = {} samples, engine path h = ({:.1}, {:.1})", FS, SECONDS, N, H.0, H.1);
    println!("R = [[{:.4}, {:.4}], [{:.4}, {:.4}]]   eigenvalues {:.4}, {:.4}   trace {:.4}", r0, r1, r1, r0, fast, slow, r0 + r0);
    println!("p = ({:.4}, {:.4})   determinant of R {:.4}", p.0, p.1, r0 * r0 - r1 * r1);
    println!("power: voice {:.4}   engine noise at mic {:.4}   mic total {:.4}", voice, noise, sd2);
    println!("measured engine noise at mic over 10 s {:.4}", mic_noise);
    println!("hand: h.R h = {:.4} + {:.4} + {:.4}   Cramer tops {:.4}, {:.4}", r0 * H.0 * H.0, r0 * H.1 * H.1,
             2.0 * r1 * H.0 * H.1, p.0 * r0 - r1 * p.1, r0 * p.1 - r1 * p.0);
    println!("hand: p.w {:.4}   step bound 2/lmax {:.4}   decay per sample {:.4}, {:.4}   misadjustment {:.4}",
             p.0 * w_ex.0 + p.1 * w_ex.1, 2.0 / fast, 1.0 - MU * fast, 1.0 - MU * slow, misadj);
    println!("road 1 Wiener from the statistics    w = ({:.4}, {:.4})   Jmin {:.4}", w_ex.0, w_ex.1, j_ex);
    println!("road 2 Wiener from the 10 s of data  w = ({:.4}, {:.4})", w_dat.0, w_dat.1);
    println!("  orthogonality, true w: E[e x(n)] {:+.4}   E[e x(n-1)] {:+.4}", orth0, orth1);
    println!("road 3 steepest descent, mu 0.5, 60 steps  w = ({:.6}, {:.6})", w_sd.0, w_sd.1);
    println!("road 4 LMS, mu {}: last sample w = ({:.4}, {:.4})   last-second mean ({:.4}, {:.4})",
             MU, run.end.0, run.end.1, run.avg.0, run.avg.1);
    println!("  output power, last second {:.4}   predicted Jmin (1 + mu trR/2) {:.4}", run.mse, j_ex * (1.0 + misadj));
    println!("  noise left in output {:.4}   predicted {:.4}", run.left, j_ex * misadj);
    println!("  SNR at mic {:.2} dB   after LMS {:.2} dB", 10.0 * (voice / noise).log10(), 10.0 * (voice / run.left).log10());
    println!("  time constants: fast {:.2} samples = {:.2} ms   slow {:.2} samples = {:.2} ms", 1.0 / (MU * fast),
             1000.0 / (MU * fast) / FS as f64, 1.0 / (MU * slow), 1000.0 / (MU * slow) / FS as f64);
    println!("wrong: one tap, w = {:.4}   J {:.4}", p.0 / r0, cost((p.0 / r0, 0.0), r0, r1, p, sd2));
    println!("wrong: taps solved separately, w = ({:.4}, {:.4})   J {:.4}", p.0 / r0, p.1 / r0, cost((p.0 / r0, p.1 / r0), r0, r1, p, sd2));
    let w_big = steepest(1.4, 40, r0, r1, p);
    println!("wrong: mu 1.4 > 2/1.5, factor {:.2}, 40 steps   w = ({:.2}, {:.2})", 1.0 - 1.4 * fast, w_big.0, w_big.1);
    let w_flip = lms(&x, &d, &s, MU, -1.0, 1000, &[]).end;
    println!("wrong: LMS sign flipped, 1000 samples   w = ({:.0}, {:.0})", w_flip.0, w_flip.1);
    println!("learning:  sample     ms   LMS w0  LMS w1   mean w0  mean w1   fast gap  slow gap");
    for (i, &n) in marks.iter().enumerate() {
        let m = steepest(MU, n, r0, r1, p);
        let gf = (w_ex.0 + w_ex.1) * (1.0 - MU * fast).powf(n as f64);
        let gs = (w_ex.0 - w_ex.1) * (1.0 - MU * slow).powf(n as f64);
        println!("  {:>14} {:>6.2} {:>8.4} {:>7.4} {:>9.4} {:>8.4} {:>10.4} {:>9.4}",
                 n, 1000.0 * n as f64 / FS as f64, run.marks[i].0, run.marks[i].1, m.0, m.1, gf, gs);
        assert!((m.0 + m.1 + gf - 1.2).abs() < 1e-9 && (m.0 - m.1 + gs - 0.4).abs() < 1e-9, "modes");
    }
    for mu in [0.05_f64, 0.001] {
        let t = lms(&x, &d, &s, mu, 1.0, N, &[]);
        println!("try: mu {}: last-second mean w = ({:.4}, {:.4})   output power {:.4} (predicted {:.4})   slow time constant {:.2} ms",
                 mu, t.avg.0, t.avg.1, t.mse, j_ex * (1.0 + mu * r0), 1000.0 / (mu * slow) / FS as f64);
    }

    assert!((w_ex.0 - 0.8).abs() < 1e-12 && (w_ex.1 - 0.4).abs() < 1e-12, "Wiener must recover the path");
    assert!((j_ex - voice).abs() < 1e-12, "with the path matched, only the voice is left");
    assert!((mic_noise - noise).abs() < 0.03, "simulated noise power vs h.R h");
    assert!((w_dat.0 - 0.8).abs().max((w_dat.1 - 0.4).abs()) < 0.02, "data road lands on the statistics road");
    assert!((w_sd.0 - w_ex.0).abs().max((w_sd.1 - w_ex.1).abs()) < 1e-6, "steepest descent reaches the bottom");
    assert!((run.avg.0 - 0.8).abs().max((run.avg.1 - 0.4).abs()) < 0.02, "LMS learns the path");
    assert!((run.left - j_ex * misadj).abs() < 0.001, "noise left in output vs the misadjustment rule");
    assert!(w_big.0.abs() > 10.0 && w_flip.0.abs() > 1e3, "unstable steps must blow up");
    println!("ALL CHECKS PASS");
}
