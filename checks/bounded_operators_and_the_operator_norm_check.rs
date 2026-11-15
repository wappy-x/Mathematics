// Bounded operators -- the check behind the card.  std only.
// An audio blur: the RC smoother y[n] = (1 - a) x[n] + a y[n-1], starting from silence.
// At 8 kHz, a = 1/2: tau = 1/(8000 ln 2) s.  Sizes are peak sizes (sup norms), full scale 1.
// Code holds a truncation: clips of N samples.  Roads: closed form, max row sum of the
// matrix built from impulses, brute force over every sign pattern, and random clips.

fn blur(x: &[f64], a: f64) -> Vec<f64> {
    let mut prev = 0.0;
    x.iter().map(|v| { prev = (1.0 - a) * v + a * prev; prev }).collect()
}

fn unblur(y: &[f64], a: f64) -> Vec<f64> {
    (0..y.len()).map(|n| (y[n] - a * if n > 0 { y[n - 1] } else { 0.0 }) / (1.0 - a)).collect()
}

fn matrix(op: fn(&[f64], f64) -> Vec<f64>, n: usize, a: f64) -> Vec<Vec<f64>> {
    let cols: Vec<Vec<f64>> = (0..n)
        .map(|j| op(&(0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>(), a))
        .collect();
    (0..n).map(|i| (0..n).map(|j| cols[j][i]).collect()).collect()
}

fn inverse_lower(m: &[Vec<f64>]) -> Vec<Vec<f64>> {
    let n = m.len();
    let mut inv = vec![vec![0.0; n]; n];
    for j in 0..n {
        for i in 0..n {
            let s: f64 = (0..i).map(|k| m[i][k] * inv[k][j]).sum();
            inv[i][j] = ((if i == j { 1.0 } else { 0.0 }) - s) / m[i][i];
        }
    }
    inv
}

fn row_sum_norm(m: &[Vec<f64>]) -> f64 {
    m.iter().map(|r| r.iter().map(|v| v.abs()).sum::<f64>()).fold(0.0, f64::max)
}

fn brute(op: fn(&[f64], f64) -> Vec<f64>, n: usize, a: f64) -> f64 {
    let mut best: f64 = 0.0;
    for mask in 0..(1u32 << n) {
        let x: Vec<f64> = (0..n).map(|i| if mask >> i & 1 == 1 { 1.0 } else { -1.0 }).collect();
        best = best.max(peak(&op(&x, a)));
    }
    best
}

fn peak(x: &[f64]) -> f64 {
    x.iter().map(|v| v.abs()).fold(0.0, f64::max)
}

fn show(x: &[f64], d: usize) -> String {
    format!("({})", x.iter().map(|v| format!("{:.*}", d, v)).collect::<Vec<_>>().join(", "))
}

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53) * 2.0 - 1.0
    }
}

fn main() {
    println!("blur, a = 1/2: N, closed 1 - 2^-N, max row sum, brute force");
    for n in [1usize, 2, 4, 8, 16, 32] {
        let closed = 1.0 - 2f64.powi(-(n as i32));
        let rows = row_sum_norm(&matrix(blur, n, 0.5));
        let b = if n <= 10 { brute(blur, n, 0.5) } else { rows };
        assert!((rows - closed).abs() < 1e-12 && (b - closed).abs() < 1e-12);
        println!("  {:2}  {:.10}  {:.10}  {:.10}", n, closed, rows, b);
    }
    let x = [0.8, -0.5, 0.3, 0.6];
    let y = blur(&x, 0.5);
    println!("clip {} -> blurred {} peak {:.4} <= 0.9375 x 0.8 = {:.4}", show(&x, 1), show(&y, 4), peak(&y), 0.9375 * 0.8);
    assert!(peak(&y) <= 0.9375 * peak(&x) + 1e-12);
    let w = blur(&[0.8; 4], 0.5);
    println!("worst clip 0.8 held -> {} peak {:.4}", show(&w, 4), peak(&w));
    assert!((peak(&w) - 0.75).abs() < 1e-12);

    println!("unblur, a = 1/2: N, closed (1+a)/(1-a), max row sum, brute force, max |entry|");
    for n in [2usize, 4, 8] {
        let m = matrix(unblur, n, 0.5);
        let (rows, b) = (row_sum_norm(&m), brute(unblur, n, 0.5));
        let ent = m.iter().flatten().map(|v| v.abs()).fold(0.0, f64::max);
        assert!((rows - 3.0).abs() < 1e-12 && (b - 3.0).abs() < 1e-12);
        println!("  {}  3.0000000000  {:.10}  {:.10}  {:.1}", n, rows, b, ent);
    }
    let c = [0.3, -0.2, 0.5, 0.1];
    let back = blur(&unblur(&c, 0.5), 0.5);
    assert!(back.iter().zip(c.iter()).all(|(p, q)| (p - q).abs() < 1e-12));
    let z = unblur(&[0.4, -0.4, 0.4, -0.4], 0.5);
    println!("blurred clip +-0.4 -> unblurred {} peak {:.1}; headroom 20 log10 3 = {:.2} dB", show(&z, 1), peak(&z), 20.0 * 3f64.log10());
    assert!((peak(&z) - 1.2).abs() < 1e-12);

    println!("same smoother, finer sampling: rate (Hz), a, blur gain on 1 s, unblur gain, N=64 inverse rows, 2 tau/h");
    let tau = 1.0 / (8000.0 * 2f64.ln());
    let mut pts = vec![];
    for fs in [8000u32, 16000, 48000, 96000, 192000] {
        let f = fs as f64;
        let a = (-1.0 / (f * tau)).exp();
        let g = (1.0 + a) / (1.0 - a);
        let rows = row_sum_norm(&inverse_lower(&matrix(blur, 64, a)));
        assert!((rows - g).abs() < 1e-9 * g && 2.0 * tau * f < g && g < 2.0 * tau * f + 1.0);
        let bg = 1.0 - a.powf(f);
        pts.push((f.log10(), g.log10(), bg.log10()));
        println!("  {:6}  {:.6}  {:.6}  {:.6}  {:.6}  {:.6}", fs, a, bg, g, rows, 2.0 * tau * f);
    }
    let j = |k: usize| pts.iter().map(|p| format!("{:.3}", [p.0, p.1, p.2.abs()][k])).collect::<Vec<_>>().join(", ");
    println!("chart log10 rate: {}", j(0));
    println!("chart log10 unblur gain: {} ; log10 blur gain: {}", j(1), j(2));
    println!("tau = {:.2} us, analog corner 1/(2 pi tau) = {:.1} Hz", tau * 1e6, 1.0 / (2.0 * std::f64::consts::PI * tau));

    // continuous blur K: kernel k(t, s) = exp(-(t - s)/tau)/tau for s <= t; on C[0, T], ||K|| = int_0^T k(T, s) ds
    let (t, m) = (0.001, 100000);
    let mid = (0..m).map(|i| (-(t - (i as f64 + 0.5) * t / m as f64) / tau).exp() / tau).sum::<f64>() * t / m as f64;
    let ns = t * 8000.0; // the same clip as samples at 8 kHz
    println!("K on a {:.1} ms clip: closed 1 - exp(-T/tau) = {:.8}, midpoint {:.8}, sampled 1 - 2^-{:.0} = {:.8}", t * 1000.0, 1.0 - (-t / tau).exp(), mid, ns, 1.0 - 2f64.powf(-ns));
    assert!((mid - (1.0 - (-t / tau).exp())).abs() < 1e-8 && (mid - (1.0 - 2f64.powf(-ns))).abs() < 1e-8);

    // continuous unblur g + tau g': a tone of peak 0.001/n at n kHz
    let lim = 0.001 * 2.0 * std::f64::consts::PI * 1000.0 * tau;
    for n in [1u32, 4, 16] {
        let nf = n as f64;
        let out = 0.001 / nf * (1.0 + (2.0 * std::f64::consts::PI * 1000.0 * nf * tau).powi(2)).sqrt();
        println!("tone 0.001/{} at {} kHz -> unblurred peak {:.6}", n, n, out);
        assert!(out > lim * 0.999);
    }
    println!("limit as n grows: 0.001 x 2 pi x 1000 x tau = {:.6}", lim);

    // completeness: FIR truncations R_m keep the first m taps 2^-(k+1)
    println!("m, ||R - R_m|| closed 2^-m, tail rows on a 60-sample clip, in dB");
    for m in [1i32, 2, 5, 10, 20] {
        let tail = row_sum_norm(&(0..60i32).map(|i| (0..60i32).map(|j| if i - j >= m { 0.5f64.powi(i - j + 1) } else { 0.0 }).collect()).collect::<Vec<Vec<f64>>>());
        assert!((tail - (2f64.powi(-m) - 2f64.powi(-60))).abs() < 1e-15);
        println!("  {:2}  {:.9}  {:.9}  {:.1}", m, 2f64.powi(-m), tail, 20.0 * 2f64.powi(-m).log10());
    }
    println!("||R_5 - R_10|| = 2^-5 - 2^-10 = {:.9}", 2f64.powi(-5) - 2f64.powi(-10));
    let mut click = vec![0.0; 60];
    click[0] = 1.0;
    let r = blur(&click, 0.5);
    let r10: Vec<f64> = (0..60i32).map(|i| (0..60i32).map(|j| if (0..10).contains(&(i - j)) { 0.5f64.powi(i - j + 1) * click[j as usize] } else { 0.0 }).sum()).collect(); // the 10-tap FIR
    let last = (0..60).filter(|&i| r10[i] != 0.0).max().unwrap() + 1;
    assert!(last == 10 && (0..10).all(|i| (r10[i] - r[i]).abs() < 1e-15) && r.iter().all(|&v| v != 0.0));
    println!("click through R_10: silent after sample {}; through R: sample 60 is still {:.3e}, never silent", last, r[59]);

    // drop linearity: squaring each sample is continuous but has no finite gain
    for c in [1.0f64, 10.0, 100.0] {
        println!("squarer on a clip of peak {:.1}: gain {:.1}", c, c * c / c);
    }

    // random clips never beat the gain (SplitMix64, seed 2026)
    let mut rng = SplitMix(2026);
    let mut worst = [0.0f64, 0.0];
    for _ in 0..2000 {
        let x: Vec<f64> = (0..16).map(|_| rng.next()).collect();
        worst[0] = worst[0].max(peak(&blur(&x, 0.5)) / peak(&x));
        worst[1] = worst[1].max(peak(&unblur(&x, 0.5)) / peak(&x));
    }
    assert!(worst[0] <= 1.0 - 2f64.powi(-16) + 1e-12 && worst[1] <= 3.0 + 1e-12 && worst[1] > 2.5);
    println!("2000 random 16-sample clips: worst blur ratio {:.6} <= {:.6}, worst unblur ratio {:.6} <= 3", worst[0], 1.0 - 2f64.powi(-16), worst[1]);
    println!("ALL CHECKS PASS");
}
