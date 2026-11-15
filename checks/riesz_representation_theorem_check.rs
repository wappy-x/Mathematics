// Riesz representation -- the same check as the Python, in Rust.  No crates.
// A one-second audio clip is a list of N pressure samples (Pa), dt = 1/N s
// apart, with overlap <y, x> = dt * sum(conj(y_k) * x_k).  A smoothing meter
// with half-life 0.25 s turns the clip into one reading.  The card's claim:
// that reading is the overlap with one fixed shape y, and |reading| <= |y| |x|.
const H: f64 = 0.25; // the meter's half-life, in seconds

fn meter(x: &[f64], n: usize) -> f64 { // road 1: run the meter sample by sample
    let a = 2f64.powf(-(1.0 / n as f64) / H);
    let mut m = 0.0;
    for &xk in x { m = a * m + (1.0 - a) * xk }
    m
}

fn last_only(x: &[f64], _n: usize) -> f64 { x[x.len() - 1] }

fn dot(y: &[f64], x: &[f64], n: usize) -> f64 { // the overlap, real samples
    y.iter().zip(x).map(|(a, b)| a * b).sum::<f64>() / n as f64
}

fn length(y: &[f64], n: usize) -> f64 { dot(y, y, n).sqrt() }

fn unit(k: usize, n: usize) -> Vec<f64> { (0..n).map(|j| if j == k { 1.0 } else { 0.0 }).collect() }

fn probe(rule: fn(&[f64], usize) -> f64, n: usize) -> Vec<f64> { // road 2: each lone sample
    (0..n).map(|k| rule(&unit(k, n), n) * n as f64).collect()
}

fn by_kernel(rule: fn(&[f64], usize) -> f64, n: usize) -> (Vec<f64>, Vec<f64>) { // road 3: the proof
    let last = unit(n - 1, n);
    let r_last = rule(&last, n);
    let mut basis: Vec<Vec<f64>> = Vec::new(); // silent clips, made perpendicular
    for k in 0..n - 1 {
        let mut v = unit(k, n);
        let c = rule(&v, n) / r_last;
        v = v.iter().zip(&last).map(|(vj, lj)| vj - c * lj).collect();
        for b in &basis {
            let p = dot(b, &v, n);
            v = v.iter().zip(b).map(|(vj, bj)| vj - p * bj).collect();
        }
        let s = length(&v, n);
        basis.push(v.iter().map(|vj| vj / s).collect());
    }
    let mut z = last.clone(); // drop the last sample onto the kernel
    for b in &basis {
        let p = dot(b, &last, n);
        z = z.iter().zip(b).map(|(zj, bj)| zj - p * bj).collect();
    }
    let c = rule(&z, n) / dot(&z, &z, n);
    let y = z.iter().map(|zj| c * zj).collect();
    (z, y)
}

struct Rng(u64); // SplitMix64, written out
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53) * 2.0 - 1.0
    }
}

fn f(v: &[f64]) -> String { format!("[{}]", v.iter().map(|t| format!("{:.4}", t)).collect::<Vec<_>>().join(", ")) }

type C = (f64, f64); // a complex number as (real, imaginary)
fn cdot(y: &[C], x: &[f64]) -> C { // conjugate the first slot
    let (mut re, mut im) = (0.0, 0.0);
    for (a, &b) in y.iter().zip(x) { re += a.0 * b; im -= a.1 * b }
    (re / 4.0, im / 4.0)
}
fn cf(z: C) -> String { format!("{:.4} {} {:.4}i", z.0, if z.1 >= 0.0 { "+" } else { "-" }, z.1.abs()) }

fn main() {
    let (clip, n) = (vec![2.0, -1.0, 3.0, 1.0], 4usize);
    let (y_probe, (z, y_kernel)) = (probe(meter, n), by_kernel(meter, n));
    let reading = meter(&clip, n);
    let norm = length(&y_probe, n);
    let mut rng = Rng(20261115);
    let mut best: f64 = 0.0;
    for _ in 0..2000 {
        let x: Vec<f64> = (0..n).map(|_| rng.next()).collect();
        best = best.max(meter(&x, n).abs() / length(&x, n));
    }
    println!("clip {} Pa, N = {}, dt = {:.4} s", f(&clip), n, 1.0 / n as f64);
    let trail: Vec<f64> = (0..n).map(|k| meter(&clip[..k + 1], n)).collect();
    println!("road 1, meter run: {}, reading = {:.4} Pa", f(&trail), reading);
    println!("lone-sample readings: {}", f(&y_probe.iter().map(|t| t / n as f64).collect::<Vec<f64>>()));
    println!("road 2, probe each sample: y = {}", f(&y_probe));
    println!("road 3, miss z = {}, meter(z) = {:.4}, |z|^2 = {:.4}", f(&z), meter(&z, n), dot(&z, &z, n));
    println!("road 3, drop onto the silent clips: y = {}", f(&y_kernel));
    println!("overlap <y, clip> = {:.4} Pa", dot(&y_probe, &clip, n));
    println!("meter size |y| = sqrt(85/64) = {:.6}; best of 2000 random clips {:.6}; at x = y {:.6}", norm, best, meter(&y_probe, n) / norm);
    let plain: f64 = y_probe.iter().zip(&clip).map(|(a, b)| a * b).sum();
    println!("mistake, plain sum without dt: {:.4} Pa, not {:.4}", plain, reading);
    let limit = ((2f64).ln() / (2.0 * H) * (1.0 - 2f64.powf(-2.0 / H))).sqrt();
    println!("closed-form length of the limit shape: {:.6}", limit);
    let mut errs: Vec<f64> = Vec::new();
    for &m in &[4usize, 16, 64, 256, 1024, 4096] {
        let ym: Vec<f64> = if m <= 256 { probe(meter, m) } else {
            (0..m).map(|k| (1.0 - 2f64.powf(-1.0 / (m as f64 * H))) * 2f64.powf(-((m - 1 - k) as f64) / (m as f64 * H)) * m as f64).collect()
        };
        errs.push((length(&ym, m) - limit).abs());
        println!("N = {:4}: |y| = {:.6}, error {:.9}", m, length(&ym, m), errs[errs.len() - 1]);
    }
    let y8 = probe(meter, 8);
    println!("chart, N = 8 shape: {}", y8.iter().map(|t| format!("{:.3}", t)).collect::<Vec<_>>().join(", "));
    println!("chart, limit shape at each cell's middle: {}", (0..8).map(|k| format!("{:.3}",
        (2f64).ln() / H * 2f64.powf(-(1.0 - (k as f64 + 0.5) / 8.0) / H))).collect::<Vec<_>>().join(", "));
    let point: Vec<f64> = [4usize, 16, 64, 256, 1024].iter().map(|&m| length(&probe(last_only, m), m)).collect();
    println!("mistake, reading one instant: |y| at N = 4, 16, 64, 256, 1024: {}", point.iter().map(|t| format!("{:.1}", t)).collect::<Vec<_>>().join(", "));
    let saw = 2f64.sqrt() * std::f64::consts::PI * (0.5 - 0.25);
    let (mut tone_len, mut s) = (0.0, 0.0);
    for &m in &[10usize, 100, 1000] {
        tone_len = (1..=m).map(|k| 1.0 / (k * k) as f64).sum::<f64>().sqrt();
        s = (1..=m).map(|k| 2f64.sqrt() * (2.0 * std::f64::consts::PI * k as f64 * 0.25).sin() / k as f64).sum::<f64>();
        println!("tones up to {:4}: |y| = {:.6}, y(0.25 s) = {:.6}", m, tone_len, s);
    }
    println!("limit: |y| = pi/sqrt(6) = {:.6}, sawtooth y(0.25 s) = {:.6}, no finite mixture", std::f64::consts::PI / 6f64.sqrt(), saw);
    let tau = 2.0 * std::f64::consts::PI;
    let f1: Vec<C> = (0..4).map(|k| ((tau * k as f64 / 4.0).cos(), (tau * k as f64 / 4.0).sin())).collect();
    let c1 = cdot(&f1, &clip);
    let ic1 = (-c1.1, c1.0); // i times c1
    let right = cdot(&f1.iter().map(|e| (e.1, -e.0)).collect::<Vec<C>>(), &clip); // -i f1
    let wrong = cdot(&f1.iter().map(|e| (-e.1, e.0)).collect::<Vec<C>>(), &clip); // i f1
    println!("c1(clip) = {}; the rule i*c1 gives {}", cf(c1), cf(ic1));
    println!("shape -i*f1 gives {}; mistake, shape i*f1 gives {}", cf(right), cf(wrong));
    assert!(y_probe.iter().zip(&y_kernel).all(|(p, q)| (p - q).abs() < 1e-12)); // roads 2 and 3
    assert!((dot(&y_probe, &clip, 4) - reading).abs() < 1e-12); // road 1 = overlap
    assert!(best <= norm + 1e-12 && (norm - (85.0f64 / 64.0).sqrt()).abs() < 1e-12); // Cauchy-Schwarz
    assert!((0..errs.len() - 1).all(|i| errs[i + 1] < errs[i] / 3.0)); // truncation closes
    let tail = std::f64::consts::PI.powi(2) / 6.0 - tone_len * tone_len;
    assert!(1.0 / 1001.0 < tail && tail < 1.0 / 1000.0); // tail of 1/n^2: 1/(N+1) to 1/N
    assert!((s - saw).abs() < 2f64.sqrt() / 1001.0); // alternating tail < first term
    assert!((point[point.len() - 1] - 32.0).abs() < 1e-9);
    assert!(((right.0 - ic1.0).powi(2) + (right.1 - ic1.1).powi(2)).sqrt() < 1e-12);
    assert!(((wrong.0 - ic1.0).powi(2) + (wrong.1 - ic1.1).powi(2)).sqrt() > 0.5);
    println!("ALL CHECKS PASS");
}
