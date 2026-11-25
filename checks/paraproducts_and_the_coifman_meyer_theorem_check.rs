// Paraproducts and the Coifman-Meyer theorem -- the check behind the card.
// std only.  Signals last 1 s, so every frequency is a whole number of hertz.
// Octave band j holds 2^j <= |xi| < 2^(j+1) Hz; band -1 holds xi = 0.
use std::collections::BTreeMap;
use std::f64::consts::PI;

#[derive(Clone, Copy, PartialEq)]
struct Q(i64, i64); // an exact fraction, always in lowest terms with a positive denominator
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 }; Q(s * n / g, s * d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn qs(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn qf(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }
type Spec = BTreeMap<i64, Q>;

fn tones(p: &[(Q, i64)]) -> Spec { // amplitude A at a Hz is A/2 at +a and at -a
    let mut c = Spec::new(); for &(amp, a) in p { for x in [a, -a] { let v = *c.get(&x).unwrap_or(&Q(0, 1)); c.insert(x, add(v, mul(amp, Q(1, 2)))); } } c
}
fn band(x: i64) -> i64 { if x == 0 { -1 } else { 63 - x.abs().leading_zeros() as i64 } }
fn key(j: i64, k: i64) -> usize { if k >= j + 2 { 0 } else if j >= k + 2 { 1 } else { 2 } } // Bony's rule on two band numbers
fn clean(h: Spec) -> Spec { h.into_iter().filter(|(_, v)| v.0 != 0).collect() }
fn pieces(f: &Spec, g: &Spec) -> (Spec, [Spec; 3]) { // whole product, then low-high, high-low, high-high
    let (mut h, mut out) = (Spec::new(), [Spec::new(), Spec::new(), Spec::new()]);
    for (&x, &a) in f { for (&y, &b) in g {
        let e = h.entry(x + y).or_insert(Q(0, 1)); *e = add(*e, mul(a, b));
        let e = out[key(band(x), band(y))].entry(x + y).or_insert(Q(0, 1)); *e = add(*e, mul(a, b));
    } }
    let [a, b, c] = out;
    (clean(h), [clean(a), clean(b), clean(c)])
}

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn cm(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn fft(a0: &[C], inv: bool) -> Vec<C> { // iterative radix-2 transform, length a power of 2
    let (mut a, n, mut j) = (a0.to_vec(), a0.len(), 0usize);
    for i in 1..n {
        let mut bit = n >> 1; while j & bit != 0 { j ^= bit; bit >>= 1; }
        j |= bit; if i < j { a.swap(i, j); }
    }
    let mut m = 2;
    while m <= n {
        let w = C { re: (2.0 * PI / m as f64).cos(), im: (if inv { 1.0 } else { -1.0 }) * (2.0 * PI / m as f64).sin() };
        for s in (0..n).step_by(m) {
            let mut z = C { re: 1.0, im: 0.0 };
            for k in 0..m / 2 {
                let (u, v) = (a[s + k], cm(a[s + k + m / 2], z));
                a[s + k] = C { re: u.re + v.re, im: u.im + v.im }; a[s + k + m / 2] = C { re: u.re - v.re, im: u.im - v.im }; z = cm(z, w);
            }
        }
        m *= 2;
    }
    if inv { a.iter().map(|x| C { re: x.re / n as f64, im: x.im / n as f64 }).collect() } else { a }
}

const N: usize = 16384; // samples in the 1 s window
fn ms(c: &Spec) -> Q { c.values().fold(Q(0, 1), |s, &v| add(s, mul(v, v))) }
fn samples(c: &Spec) -> Vec<f64> {
    (0..N).map(|k| c.iter().map(|(&x, &v)| qf(v) * (2.0 * PI * x as f64 * k as f64 / N as f64).cos()).sum()).collect()
}
fn show(k: usize, p: &Spec) -> String { format!("{} piece: mean square {}; lines [{}]", ["LH", "HL", "HH"][k], qs(ms(p)),
    p.iter().filter(|(&x, _)| x > 0).map(|(x, &v)| format!("('{} Hz', '{}')", x, qs(mul(Q(2, 1), mul(v, v))))).collect::<Vec<_>>().join(", ")) }
fn lines(c: &Spec) -> String { format!("[{}]", c.keys().filter(|&&x| x > 0).map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn cx(v: &[f64]) -> Vec<C> { v.iter().map(|&x| C { re: x, im: 0.0 }).collect() }
fn bandpart(s: &[C], j: i64) -> Vec<f64> { // cut the sampled transform to one octave band
    let m: Vec<C> = (0..N).map(|i| { let x = if i < N / 2 { i as i64 } else { i as i64 - N as i64 };
        if band(x) == j { s[i] } else { C { re: 0.0, im: 0.0 } } }).collect();
    fft(&m, true).iter().map(|z| z.re).collect()
}
fn h1(c: &Spec) -> f64 { c.iter().map(|(&x, &v)| (1.0 + (x * x) as f64) * qf(mul(v, v))).sum::<f64>().sqrt() }
fn deriv(c: &Spec) -> Vec<f64> {
    (0..N).map(|k| c.iter().map(|(&x, &v)| -2.0 * PI * x as f64 * qf(v) * (2.0 * PI * x as f64 * k as f64 / N as f64).sin()).sum()).collect()
}
fn sup(c: &Spec) -> f64 { samples(c).iter().fold(0.0, |m: f64, v| m.max(v.abs())) }

fn dyadic(b: &[f64], n: u32) -> (f64, f64, f64, f64, f64) { // the dyadic paraproduct on 2^n points
    let mm = 1usize << n; let mut is = vec![];
    for m in 0..n { let l = mm >> m; for s in (0..mm).step_by(l) { is.push((s, l)); } }
    let sum = |v: &[f64]| v.iter().sum::<f64>();
    let coef: Vec<f64> = is.iter().map(|&(s, l)| (sum(&b[s..s + l / 2]) - sum(&b[s + l / 2..s + l])) / ((l * mm) as f64).sqrt()).collect();
    let op = |f: &[f64]| { let mut out = vec![0.0; mm];
        for (t, &(s, l)) in is.iter().enumerate() { let (a, h) = (coef[t] * sum(&f[s..s + l]) / l as f64, (mm as f64 / l as f64).sqrt());
            for i in s..s + l { out[i] += if i < s + l / 2 { a * h } else { -a * h }; } }
        out };
    let adj = |g: &[f64]| { let mut out = vec![0.0; mm];
        for (t, &(s, l)) in is.iter().enumerate() {
            let a = coef[t] * (mm as f64 / l as f64).sqrt() * (sum(&g[s..s + l / 2]) - sum(&g[s + l / 2..s + l])) / mm as f64 * mm as f64 / l as f64; for i in s..s + l { out[i] += a; } }
        out };
    let (mut car, mut s0, mut l0) = (-1.0, 0, 0);
    for &(s, l) in &is { let c: f64 = is.iter().zip(&coef).filter(|(&(s2, l2), _)| s <= s2 && s2 + l2 <= s + l).map(|(_, c)| c * c).sum::<f64>() * mm as f64 / l as f64;
        if c > car { car = c; s0 = s; l0 = l; } }
    let osc = is.iter().map(|&(s, l)| { let a = sum(&b[s..s + l]) / l as f64; b[s..s + l].iter().map(|v| (v - a).powi(2)).sum::<f64>() / l as f64 }).fold(0.0, f64::max);
    let mut x: Vec<f64> = (0..mm).map(|i| if s0 <= i && i < s0 + l0 { 1.0 } else { 0.0 }).collect();
    for _ in 0..300 { let y = adj(&op(&x)); let r = y.iter().map(|v| v * v).sum::<f64>().sqrt(); x = y.iter().map(|v| v / r).collect(); }
    let qq = op(&x).iter().map(|v| v * v).sum::<f64>() / x.iter().map(|v| v * v).sum::<f64>();
    let haar = mm as f64 * is.iter().zip(&coef).map(|(&(s, l), c)| c * c * (sum(&x[s..s + l]) / l as f64).powi(2)).sum::<f64>() / x.iter().map(|v| v * v).sum::<f64>();
    let ip = [op(b).iter().zip(&x).map(|(u, v)| u * v).sum::<f64>(), b.iter().zip(&adj(&x)).map(|(u, v)| u * v).sum::<f64>()];
    assert!((haar - qq).abs() < 1e-9 * qq && (ip[0] - ip[1]).abs() < 1e-9 * ip[0].abs()); // sum b_I^2 <x>_I^2; <pi b, x> = <b, pi* x>
    let mut lam = 0.0; if n == 6 { // second road: the explicit 64 x 64 matrix A, its transpose, top eigenvalue of A^T A
        let a: Vec<Vec<f64>> = (0..mm).map(|k| op(&(0..mm).map(|i| if i == k { 1.0 } else { 0.0 }).collect::<Vec<_>>())).collect();
        let gm: Vec<Vec<f64>> = (0..mm).map(|r| (0..mm).map(|c| a[r].iter().zip(&a[c]).map(|(u, v)| u * v).sum()).collect()).collect(); let mut z = vec![1.0; mm];
        for _ in 0..300 { let y: Vec<f64> = gm.iter().map(|row| row.iter().zip(&z).map(|(u, v)| u * v).sum()).collect(); let r = y.iter().map(|v| v * v).sum::<f64>().sqrt(); z = y.iter().map(|v| v / r).collect(); }
        lam = gm.iter().map(|row| row.iter().zip(&z).map(|(u, v)| u * v).sum::<f64>()).zip(&z).map(|(u, v)| u * v).sum();
    }
    (car, osc, qq, b.iter().fold(0.0, |m: f64, v| m.max(v.abs())), lam)
}

fn main() {
    let pairs: [(&str, Vec<(Q, i64)>, Vec<(Q, i64)>); 4] = [("bass x whistle", vec![(Q(1, 2), 3500)], vec![(Q(1, 1), 55)]),
                 ("two tracks", vec![(Q(1, 1), 55), (Q(1, 2), 3500)], vec![(Q(3, 5), 440), (Q(2, 5), 3000)]),
                 ("440 Hz x (1000 Hz + 1500 Hz)", vec![(Q(1, 1), 440)], vec![(Q(1, 1), 1000), (Q(1, 1), 1500)]), ("(1000 Hz + 1500 Hz) x 440 Hz", vec![(Q(1, 1), 1000), (Q(1, 1), 1500)], vec![(Q(1, 1), 440)])];
    for (name, ft, gt) in &pairs {
        let (f, g) = (tones(ft), tones(gt)); let (fg, p) = pieces(&f, &g);
        let mut tot = Spec::new();
        for pc in &p { for (&x, &v) in pc { let e = tot.entry(x).or_insert(Q(0, 1)); *e = add(*e, v); } }
        let direct: Spec = { let mut h = Spec::new(); for (&x, &a) in &f { for (&y, &b) in &g { let e = h.entry(x + y).or_insert(Q(0, 1)); *e = add(*e, mul(a, b)); } } clean(h) };
        assert!(clean(tot) == direct && direct == fg); // road 1: exact fractions
        let mut e = [Spec::new(), Spec::new(), Spec::new()]; // each pile rebuilt from which tone meets which, bands by logarithm
        for &(u, a) in ft { for &(v, c) in gt {
            let k = if c as f64 >= 4.0 * 2f64.powf((a as f64).log2().floor()) { 0 } else if a as f64 >= 4.0 * 2f64.powf((c as f64).log2().floor()) { 1 } else { 2 };
            for (x, y) in pieces(&tones(&[(u, a)]), &tones(&[(v, c)])).0 { let s = e[k].entry(x).or_insert(Q(0, 1)); *s = add(*s, y); } } }
        assert!(e.map(clean) == p);
        assert!(f.keys().all(|&x| g.keys().all(|&y| key(band(x), band(y)) == 2 || (band(x + y) - band(x).max(band(y))).abs() <= 1))); // Step 2
        println!("{}: product lines at {} Hz, mean square {} V^4", name, lines(&fg), qs(ms(&fg)));
        for k in 0..3 { println!("  {}", show(k, &p[k])); }
        let (sf, sg) = (samples(&f), samples(&g)); let (ff, gg) = (fft(&cx(&sf), false), fft(&cx(&sg), false));
        let mut t = vec![vec![0.0; N]; 3];
        let (mut jf, mut jg): (Vec<i64>, Vec<i64>) = (f.keys().map(|&x| band(x)).collect(), g.keys().map(|&x| band(x)).collect());
        jf.sort(); jf.dedup(); jg.sort(); jg.dedup();
        for &j in &jf { let dj = bandpart(&ff, j); for &k in &jg { let dk = bandpart(&gg, k);
            for i in 0..N { t[key(j, k)][i] += dj[i] * dk[i]; } } }
        let err = (0..N).map(|i| (sf[i] * sg[i] - t[0][i] - t[1][i] - t[2][i]).abs()).fold(0.0, f64::max);
        let mut gap: f64 = 0.0;
        for k in 0..3 { let s = fft(&cx(&t[k]), false);
            for x in -(N as i64) / 2..(N as i64) / 2 { let z = s[x.rem_euclid(N as i64) as usize]; let e = p[k].get(&x).map(|&v| qf(v)).unwrap_or(0.0);
                gap = gap.max(((z.re / N as f64 - e).powi(2) + (z.im / N as f64).powi(2)).sqrt()); } }
        assert!(err < 1e-9 && gap < 1e-9);
        println!("  time road: LH + HL + HH = f g at all {} samples, gap below 1e-9; piece spectra match, gap below 1e-9", N);
    }
    assert!((1..9000i64).all(|x| (1i64 << band(x)) <= x && x < (1i64 << (band(x) + 1))));
    println!("bands: {}", [55i64, 440, 500, 1000, 1500, 3000, 3500].iter().map(|&x| format!("{} Hz in {} ({} to {} Hz)", x, band(x), 1i64 << band(x), (1i64 << (band(x) + 1)) - 1)).collect::<Vec<_>>().join(", "));
    for (label, gt) in [("bass at 1500 Hz", [(Q(1, 1), 1500)]), ("bass doubled", [(Q(2, 1), 55)])] {
        let (_, p) = pieces(&tones(&pairs[0].1), &tones(&gt)); println!("try: bass x whistle, {}: {}", label, (0..3).filter(|&k| !p[k].is_empty()).map(|k| show(k, &p[k])).collect::<Vec<_>>().join("; ")); }
    let (f, g) = (tones(&pairs[1].1), tones(&pairs[1].2)); let (fg, p) = pieces(&f, &g);
    println!("drop HH: LH + HL keep mean square {} of {}; 3500 - 3000 = 500 Hz lands in band {}, from two lines in band {}",
             qs(add(ms(&p[0]), ms(&p[1]))), qs(ms(&fg)), band(500), band(3500));
    let (lhs, rhs) = (h1(&fg), sup(&f) * h1(&g) + h1(&f) * sup(&g));
    println!("product rule s = 1: ||fg||_H1 = {:.3}, ||f||_sup = {:.3}, ||g||_H1 = {:.3}, ||f||_H1 = {:.3}, ||g||_sup = {:.3}",
             lhs, sup(&f), h1(&g), h1(&f), sup(&g));
    let (sf, sg, df, dg) = (samples(&f), samples(&g), deriv(&f), deriv(&g)); // time road: ||h||_H1^2 = mean h^2 + mean (h'/2 pi)^2
    let h1t = ((0..N).map(|i| (sf[i] * sg[i]).powi(2) + ((df[i] * sg[i] + sf[i] * dg[i]) / (2.0 * PI)).powi(2)).sum::<f64>() / N as f64).sqrt();
    println!("  time road: ||fg||_H1 from samples of fg and (fg)' = f'g + fg' = {:.3}", h1t);
    println!("  bound ||f||_sup ||g||_H1 + ||f||_H1 ||g||_sup = {:.3}, ratio {:.4}", rhs, lhs / rhs);
    for k in 0..3 { println!("  {} piece: ||.||_H1 = {:.3}", ["LH", "HL", "HH"][k], h1(&p[k])); }
    assert!(lhs <= rhs && (lhs * lhs - p.iter().map(|c| h1(c).powi(2)).sum::<f64>()).abs() < 1e-6 * lhs * lhs && (h1t - lhs).abs() < 1e-6 * lhs);

    for (label, pw) in [("log2(1/x)", 1), ("log2(1/x)^2", 2)] {
        for n in [6u32, 8, 10, 12] {
            let b: Vec<f64> = (0..1usize << n).map(|i| ((1u64 << n) as f64 / (i as f64 + 0.5)).log2().powi(pw)).collect();
            let (c, osc, qq, top, lam) = dyadic(&b, n);
            println!("{}b = {}, {:4} points: Carleson {:.4}, oscillation {:.4}, ||pi_b||^2 {:.4}, 4C {:.4}, ||pi_b|| {:.4}, max|b| {:.4}",
                     if n == 12 { "try: " } else { "" }, label, 1u32 << n, c, osc, qq, 4.0 * c, qq.sqrt(), top);
            if lam > 0.0 { println!("  explicit {} x {} matrix: top eigenvalue of its transpose times it {:.4}", 1u32 << n, 1u32 << n, lam); }
            assert!((c - osc).abs() < 1e-9 && c - 1e-9 <= qq && qq <= 4.0 * c && (pw == 2 || c < 1.0 / 2f64.ln().powi(2)) && (n > 6 || (lam - qq).abs() < 1e-9 * qq));
        }
    }
    println!("mean oscillation of log2(1/x) on any (0, a), unsampled: variance 1/(ln 2)^2 = {:.4}, so ||pi_b|| <= 2/ln 2 = {:.4}", 1.0 / 2f64.ln().powi(2), 2.0 / 2f64.ln());
    println!("ALL CHECKS PASS");
}
