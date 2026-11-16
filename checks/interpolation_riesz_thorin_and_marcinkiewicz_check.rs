// Interpolation: Riesz-Thorin, Marcinkiewicz, Hausdorff-Young -- the same check in Rust.
// No crates.  A shutter gate, 1 V for W = 0.001 s.  Roads: closed forms against integrals done
// here, the spectrum's 4th-power area against the triangle's energy, a 16-point DFT on random
// signals, the maximal function by brute-force window search against its closed form.
use std::f64::consts::PI;
const W: f64 = 0.001; // gate open time, seconds; height 1 V

#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } }

fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }

fn s_area(q: f64) -> (f64, f64) { // area under |sinc u|^q over the line, Simpson per lobe
    let (lobes, m, mut tot) = (2000usize, 32usize, 0.0);
    for k in 0..lobes {
        let (h, mut s) = (1.0 / m as f64, 0.0);
        for j in 0..=m {
            let c = if j == 0 || j == m { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
            s += c * sinc(k as f64 + j as f64 * h).abs().powf(q);
        }
        tot += s * h / 3.0;
    }
    (2.0 * tot, 2.0 * (lobes as f64).powf(1.0 - q) / (PI.powf(q) * (q - 1.0)))
}

fn ft_gate(xi: f64) -> f64 { // the transform integral itself, midpoint rule
    let (n, mut re, mut im) = (2000, 0.0, 0.0);
    for k in 0..n {
        let t = (k as f64 + 0.5) * W / n as f64;
        re += (2.0 * PI * xi * t).cos() * W / n as f64; im -= (2.0 * PI * xi * t).sin() * W / n as f64;
    }
    (re * re + im * im).sqrt()
}

fn e_fmt(x: f64, d: usize) -> String { // Python's e-format: two-digit signed exponent
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap(); let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}

fn gauss_ratio(p: f64) -> f64 {
    if p == 1.0 { return 1.0; } let pp = p / (p - 1.0); (p.powf(1.0 / p) / pp.powf(1.0 / pp)).powf(0.5)
}

fn gnorm(p: f64) -> f64 { // ||e^(-pi t^2)||_p by midpoint sum on [-6, 6]
    let (n, mut s) = (12000, 0.0);
    for k in 0..n { let t = (k as f64 + 0.5) * 12.0 / n as f64 - 6.0; s += (-p * PI * t * t).exp(); }
    (s * 12.0 / n as f64).powf(1.0 / p)
}

struct Rng(u64); // SplitMix64, so Python and Rust draw the same signals
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 * 2.0 - 1.0
    }
}
const N: usize = 16;
fn dft(x: &[C]) -> Vec<C> {
    (0..N).map(|k| {
        let mut s = C { re: 0.0, im: 0.0 };
        for n in 0..N {
            let a = 2.0 * PI * (k * n) as f64 / N as f64; let (c, sn) = (a.cos(), -a.sin());
            s.re += x[n].re * c - x[n].im * sn; s.im += x[n].re * sn + x[n].im * c;
        }
        s
    }).collect()
}
fn norm(v: &[C], r: f64) -> f64 { v.iter().map(|c| c.abs().powf(r)).sum::<f64>().powf(1.0 / r) }

fn mf(d: f64) -> f64 { if d < 0.0 { 1.0 } else { 0.5 / (d / W + 1.0) } } // d = distance outside, s
fn mbrute(x: f64) -> f64 { // try windows (x - h, x + h), h = W/1000 ... 20 W
    (1..=20000).map(|k| k as f64 * W / 1000.0)
        .fold(0.0f64, |b, h| b.max(0.0f64.max((x + h).min(W) - (x - h).max(0.0)) / (2.0 * h)))
}
fn cp(p: f64) -> f64 { 2.0 * (3.0 * p / (p - 1.0)).powf(1.0 / p) }
fn chirp_ratio(b: f64) -> f64 { (1.0 + b * b).powf(1.0 / 8.0) * (4.0f64 / 3.0).powf(-3.0 / 8.0) / 4.0f64.powf(-1.0 / 8.0) }
fn chirp_ft(b: f64, xi: f64) -> f64 { // the transform integral itself, on [-6, 6] s
    let (n, mut re, mut im) = (40000, 0.0, 0.0);
    for k in 0..n {
        let t = (k as f64 + 0.5) * 12.0 / n as f64 - 6.0;
        let (ph, a) = (-PI * b * t * t - 2.0 * PI * xi * t, (-PI * t * t).exp() * 12.0 / n as f64);
        re += a * ph.cos(); im += a * ph.sin();
    }
    (re * re + im * im).sqrt()
}

fn main() {
    println!("gate: mass ||f||_1 {:.6} V s; |f^(0)| integral {:.6}; |f^(300)| integral {:.6}, closed form {:.6}", W, ft_gate(0.0), ft_gate(300.0), W * sinc(W * 300.0).abs());
    assert!((ft_gate(300.0) - W * sinc(W * 300.0).abs()).abs() < 1e-9);
    let ((s2, t2), (s4, _), (s6, _)) = (s_area(2.0), s_area(4.0), s_area(6.0));
    assert!((s2 - 1.0).abs() < 2e-4 && (s4 - 2.0 / 3.0).abs() < 1e-8 && (s6 - 0.55).abs() < 1e-8);
    println!("energy: ||f||_2^2 {:.6}; area of |f^|^2 {:.6} (cut-off 2000 lobes, tail below {})", W, W * s2, e_fmt(W * t2, 1));
    let (n, mut tri) = (20000, 0.0);
    for k in 0..n { let t = (k as f64 + 0.5) * 2.0 * W / n as f64; tri += t.min(2.0 * W - t).powi(2); } tri *= 2.0 * W / n as f64;
    println!("area of |f^|^4: frequency side {}; time side, energy of f*f {}; exact 2w^3/3 {}", e_fmt(W.powi(3) * s4, 6), e_fmt(tri, 6), e_fmt(2.0 * W.powi(3) / 3.0, 6));
    assert!((tri - W.powi(3) * s4).abs() < 1e-14);
    let (lhs, rhs) = ((W.powi(3) * s4).powf(0.25), W.powf(0.75));
    println!("halfway: ||f^||_4 {:.6}; ||f||_4/3 {:.6}; ratio {:.6}; Riesz-Thorin bound 1^(1/2) x 1^(1/2) = 1", lhs, rhs, lhs / rhs);
    assert!(lhs < rhs);
    for pt in [4.0 / 3.0, 1.5f64] { assert!((gnorm(pt / (pt - 1.0)) / gnorm(pt) - gauss_ratio(pt)).abs() < 1e-9); }
    println!("bell at p 4/3: ratio by sums {:.6}; closed form {:.6}", gnorm(4.0) / gnorm(4.0 / 3.0), gauss_ratio(4.0 / 3.0));
    let inv = [1.0, 0.9, 0.8, 0.75, 0.7, 0.6, 0.5];
    let (mut gr, mut br) = (vec![], vec![]);
    for &a in &inv {
        if a == 1.0 || a == 0.5 { gr.push(1.0); } // the ends: tallest point of |sinc| is 1; Plancherel
        else { let pp = 1.0 / (1.0 - a); let (sq, tq) = s_area(pp); assert!(tq < 1e-5); gr.push(sq.powf(1.0 / pp)); }
        br.push(gauss_ratio(1.0 / a));
        assert!(gr[gr.len() - 1] <= br[br.len() - 1] + 1e-6 && br[br.len() - 1] + 1e-6 <= 1.0 + 2e-6);
    }
    let j = |v: &[f64], d: usize| v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ");
    println!("chart, 1/p: {}", j(&inv, 2));
    println!("chart, gate ratio: {}", j(&gr, 4));
    println!("chart, bell ratio: {}", j(&br, 4));

    let (mut rng, mut worst) = (Rng(2026), 0.0f64);
    for _ in 0..500 {
        let x: Vec<C> = (0..N).map(|_| { let re = rng.next(); let im = rng.next(); C { re, im } }).collect();
        let xx = dft(&x);        let top = xx.iter().map(|c| c.abs()).fold(0.0, f64::max);
        assert!((norm(&xx, 2.0) - 4.0 * norm(&x, 2.0)).abs() < 1e-9 && top <= norm(&x, 1.0));
        worst = worst.max(norm(&xx, 4.0) / norm(&x, 4.0 / 3.0));
    }
    let mut spike = vec![C { re: 0.0, im: 0.0 }; N]; spike[0].re = 1.0; let d = dft(&spike);
    let flat = vec![C { re: 1.0, im: 0.0 }; N]; let fr = norm(&dft(&flat), 4.0) / norm(&flat, 4.0 / 3.0);
    assert!(worst < 2.0 && (norm(&d, 4.0) - 2.0).abs() < 1e-12 && (fr - 2.0).abs() < 1e-12);
    println!("16-point DFT: M0 1, M1 sqrt(16) = 4, bound sqrt(1 x 4) = 2; worst of 500 random {:.4}; spike {:.4}; flat {:.4}", worst, norm(&d, 4.0), fr);

    for (r, lab) in [(0.5, "0.5"), (1.0, "1"), (4.0, "4")] {
        assert!((mbrute(W + r * W) - mf(r * W)).abs() < 1e-12);
        println!("Mf at {} w outside: window search {:.6} V; closed form {:.6} V", lab, mbrute(W + r * W), mf(r * W));
    }
    for (al, lab) in [(0.1, "0.1"), (0.25, "0.25"), (0.5, "0.5")] {
        let (lam, n, mut cnt) = (W * (1.0 / al - 1.0), 200000, 0.0);
        let step = 40.0 * W / n as f64;
        for k in 0..n { if mf(((k as f64 + 0.5) * step - 20.0 * W + W / 2.0).abs() - W / 2.0) > al { cnt += 1.0; } } let samp = step * cnt;
        assert!((samp - lam).abs() < 2.0 * step && lam <= 3.0 * W / al);
        println!("level {} V: length of Mf > level {:.4} ms, sampled {:.4} ms; weak bound 3||f||_1/level {:.4} ms", lab, lam * 1e3, samp * 1e3, 3.0 * W / al * 1e3);
    }
    let (n, mut cake) = (100000, 0.0);
    for k in 0..n { let a = (k as f64 + 0.5) / n as f64; cake += 2.0 * a * if a < 0.5 { W * (1.0 / a - 1.0) } else { W }; }
    cake /= n as f64; assert!((cake - 1.5 * W).abs() < 1e-9);
    let mtrue = |p: f64| (1.0 + 2.0f64.powf(1.0 - p) / (p - 1.0)).powf(1.0 / p); // ||Mf||_p/||f||_p, closed form
    assert!((mtrue(2.0).powi(2) - cake / W).abs() < 1e-6); assert!((cp(4.0 / 3.0) - (4.0 / 3.0 * 6.0 * 2.0f64.powf(1.0 / 3.0) * 3.0).powf(0.75)).abs() < 1e-12);
    println!("p 2: ||Mf||_2^2 layer cake {:.6}, closed form w(1 + 1/2) {:.6} (x 1e-3 V^2 s)", cake * 1e3, 1.5 * W * 1e3);
    println!("p 2: ||Mf||_2/||f||_2 {:.4}; Marcinkiewicz C_2 = 2 sqrt(6) {:.4}", 1.5f64.sqrt(), cp(2.0));
    for pt in [4.0 / 3.0, 1.1, 1.01] {
        let tr = mtrue(pt);
        assert!(3f64.powf(1.0 / pt) < tr && tr < cp(pt)); // the bare geometric mean is too small
        println!("p {:.2}: ||Mf||_p/||f||_p {:.4}; C_p {:.4}; geometric mean 3^(1/p) {:.4}", pt, tr, cp(pt), 3f64.powf(1.0 / pt));
    }

    let mm: Vec<f64> = [1e-3, 1.0, 1e3, 1e6].iter().map(|w: &f64| (w.powi(3) * s4).powf(0.25) / w.powf(2.0 / 3.0)).collect();
    assert!((mm[0] - (2.0f64 / 3.0).powf(0.25) * W.powf(1.0 / 12.0)).abs() < 1e-9 && mm[3] > 2.5); // ||f^||_4 / ||f||_3/2; exact s4 = 2/3
    println!("breaks, p = 3/2 with q = 4: ratio ||f^||_4/||f||_3/2 at w = 1 ms, 1 s, 1000 s, 1e6 s: {}", j(&mm, 4));
    assert!((chirp_ft(10.0, 3.0) - 101.0f64.powf(-0.25) * (-PI * 9.0 / 101.0).exp()).abs() < 1e-9);
    let ch: Vec<f64> = [0.0, 10.0, 100.0, 1000.0].iter().map(|&b| chirp_ratio(b)).collect();
    println!("breaks, p = 4 > 2: chirp ratio ||f^||_4/3/||f||_4 at sweep 0, 10, 100, 1000: {}", j(&ch, 4));
    let fh = |b: f64, p: f64| ((0..12000).map(|k| ((1.0 + b * b).powf(-0.25) * (-PI * ((k as f64 + 0.5) * 0.01 - 60.0).powi(2) / (1.0 + b * b)).exp()).powf(p)).sum::<f64>() * 0.01).powf(1.0 / p);
    assert!(chirp_ratio(1000.0) > 5.0 && (fh(10.0, 4.0 / 3.0) / gnorm(4.0) - chirp_ratio(10.0)).abs() < 1e-9); // |f^| summed on [-60, 60]
    let grid = (0..100000).map(|k| mf((k as f64 + 0.5) * 1e-5)).sum::<f64>() * 1e-5; // one side, 0 to 1 s
    assert!((W + 2.0 * grid - (W + W * ((1.0 + W) / W).ln())).abs() < 1e-8);
    for (dd, lab) in [(1.0, "1"), (1000.0, "1000")] {
        println!("breaks, p = 1: area under Mf over {} s each side {:.6} V s; ||f||_1 {:.6} V s", lab, W + W * ((dd + W) / W).ln(), W);
    }
    println!("try: 1/p 0.85: gate ratio {:.4}, bell ratio {:.4}; W 0.004 s: ||f^||_4 {:.6}, ||f||_4/3 {:.6}", s_area(1.0 / (1.0 - 0.85)).0.powf(1.0 - 0.85), gauss_ratio(1.0 / 0.85), (0.004f64.powi(3) * s4).powf(0.25), 0.004f64.powf(0.75));
    println!("try: level 0.05 V: length of Mf > level {:.4} ms, weak bound {:.4} ms; chirp ratio at sweep 10000 {:.4}", W * (1.0 / 0.05 - 1.0) * 1e3, 3.0 * W / 0.05 * 1e3, chirp_ratio(10000.0));
    println!("ALL CHECKS PASS");
}
