// Intervals for a proportion: 45 of 100 recovered.  Wald, Wilson and exact intervals,
// each end by two roads; coverage enumerated and simulated (SplitMix64, seed 20260928).
use std::f64::consts::PI;
const N: usize = 100; const ALPHA: f64 = 0.05;
type Iv = (f64, f64);

fn phi_area(z: f64) -> f64 {                     // bell area left of z, Taylor series
    let (mut term, mut total, mut j) = (z, z, 0.0_f64);
    while term.abs() > 1e-17 * total.abs().max(1.0) {
        j += 1.0;
        term *= -z * z * (2.0 * j - 1.0) / (2.0 * j * (2.0 * j + 1.0));
        total += term;
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn bisect(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64, steps: usize) -> f64 {
    let mut fa = f(a);                           // a root of f between a and b
    for _ in 0..steps {
        let m = 0.5 * (a + b);
        if (f(m) > 0.0) == (fa > 0.0) { a = m; fa = f(m); } else { b = m; }
    }
    0.5 * (a + b)
}

fn pmf(n: usize, p: f64) -> Vec<f64> {           // binomial chances by the ratio rule
    let q = 1.0 - p;
    let mut law = vec![1.0];
    for _ in 0..n { law[0] *= q; }
    for k in 0..n { let last = law[k]; law.push(last * (n - k) as f64 / (k + 1) as f64 * p / q); }
    law
}

fn wald(z: f64, k: usize, n: usize) -> Iv {      // the estimate plus or minus z spreads
    let ph = k as f64 / n as f64;
    let h = z * (ph * (1.0 - ph) / n as f64).sqrt();
    (ph - h, ph + h)
}

fn wilson(z: f64, k: usize, n: usize) -> Iv {    // road one: the quadratic's two roots
    let (ph, nf) = (k as f64 / n as f64, n as f64);
    let s = z * z / nf;
    let c = (ph + s / 2.0) / (1.0 + s);
    let h = z * (ph * (1.0 - ph) / nf + s / (4.0 * nf)).sqrt() / (1.0 + s);
    (c - h, c + h)
}

fn wilson_bisect(z: f64, k: usize, n: usize) -> Iv { // road two: where distance = z spreads
    let (ph, nf) = (k as f64 / n as f64, n as f64);
    let g = |p: f64| nf * (ph - p).powi(2) - z * z * p * (1.0 - p);
    let lo = if k == 0 { 0.0 } else { bisect(&g, 0.0, ph, 200) };
    (lo, bisect(&g, ph, 1.0, 200))
}

fn exact_tails(k: usize, n: usize) -> Iv {       // road one: sum the binomial tails
    let up = |p: f64| pmf(n, p)[k..].iter().sum::<f64>() - ALPHA / 2.0;
    let dn = |p: f64| pmf(n, p)[..k + 1].iter().sum::<f64>() - ALPHA / 2.0;
    (if k == 0 { 0.0 } else { bisect(&up, 1e-12, 1.0 - 1e-12, 200) },
     if k == n { 1.0 } else { bisect(&dn, 1e-12, 1.0 - 1e-12, 200) })
}

fn upper_area(k: usize, n: usize, p: f64) -> f64 { // P(K >= k) as an area, Simpson's rule
    let m = 2000;
    let lc = (0..k).map(|i| ((n - i) as f64 / (i + 1) as f64).ln()).sum::<f64>() + (k as f64).ln();
    let f = |t: f64| if t > 0.0 { (lc + (k as f64 - 1.0) * t.ln() + (n - k) as f64 * (1.0 - t).ln()).exp() } else { 0.0 };
    let h = p / m as f64;
    let inner: f64 = (1..m).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * h)).sum();
    h / 3.0 * (f(0.0) + f(p) + inner)
}
fn exact_area(k: usize, n: usize) -> Iv {        // road two: the same ends by integration
    (bisect(&|p| upper_area(k, n, p) - ALPHA / 2.0, 1e-9, 1.0 - 1e-9, 60),
     bisect(&|p| 1.0 - upper_area(k + 1, n, p) - ALPHA / 2.0, 1e-9, 1.0 - 1e-9, 60))
}

fn coverage(m: &dyn Fn(usize) -> Iv, p: f64) -> f64 { // enumerate all 101 counts
    pmf(N, p).iter().enumerate().filter(|(k, _)| { let iv = m(*k); iv.0 <= p && p <= iv.1 }).map(|(_, w)| w).sum()
}
fn next64(state: &mut u64) -> u64 {              // SplitMix64, the same stream as the Python
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut x = *state;
    x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
    x ^ (x >> 31)
}
fn pair(label: &str, iv: Iv) { println!("{:<34}{:>10.6}{:>10.6}", label, iv.0, iv.1); }
fn row(label: &str, v: f64, d: usize) { println!("{:<34}{:>10.*}", label, d, v); }
fn main() {
    let z = bisect(&|x| phi_area(x) - (1.0 - ALPHA / 2.0), 0.0, 5.0, 200);
    let exact: Vec<Iv> = (0..=N).map(|k| exact_tails(k, N)).collect();
    let nf = N as f64;
    row("z, the 0.975 point of the bell", z, 6);
    row("  Phi(z), series", phi_area(z), 6);
    row("p-hat, 45 of 100", 45.0 / nf, 6);
    row("  p-hat (1 - p-hat) / n", 0.45 * 0.55 / nf, 6);
    row("  estimated spread", (0.45 * 0.55 / nf).sqrt(), 6);
    row("  Wald margin, z x spread", z * (0.45 * 0.55 / nf).sqrt(), 6);
    row(&format!("  z^2 / n, z^2 = {:.4}", z * z), z * z / nf, 6);
    let (w45, wb45, e45, a45) = (wilson(z, 45, N), wilson_bisect(z, 45, N), exact_tails(45, N), exact_area(45, N));
    row("  Wilson centre", (w45.0 + w45.1) / 2.0, 6);
    row("  Wilson half-width", (w45.1 - w45.0) / 2.0, 6);
    pair("Wald 45/100", wald(z, 45, N));
    pair("Wilson 45/100, formula", w45);
    pair("Wilson 45/100, bisection", wb45);
    pair("exact 45/100, tail sums", e45);
    pair("exact 45/100, Simpson area", a45);
    pair("placebo 35/100, Wald", wald(z, 35, N));
    pair("placebo 35/100, Wilson", wilson(z, 35, N));
    pair("placebo 35/100, exact", exact[35]);
    pair("rash 0/100, Wald", wald(z, 0, N));
    pair("rash 0/100, Wilson, formula", wilson(z, 0, N));
    pair("rash 0/100, Wilson, bisection", wilson_bisect(z, 0, N));
    pair("rash 0/100, exact, tail sums", exact[0]);
    row("rash 0/100, 1 - 0.025^(1/100)", 1.0 - ((ALPHA / 2.0).ln() / nf).exp(), 6);
    pair("rash 1/100, Wald", wald(z, 1, N));
    println!("coverage, n = 100:   p     Wald  Wilson   exact");
    let grid = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.10, 0.20, 0.30, 0.40, 0.45, 0.50];
    let methods: [Box<dyn Fn(usize) -> Iv>; 3] =
        [Box::new(|k| wald(z, k, N)), Box::new(|k| wilson(z, k, N)), Box::new(|k| exact[k])];
    let names = ["Wald", "Wilson", "exact"];
    let cov: Vec<Vec<f64>> = grid.iter().map(|&p| methods.iter().map(|m| coverage(m.as_ref(), p)).collect()).collect();
    for (p, c) in grid.iter().zip(&cov) { println!("{:<16}{:>9.2}{:>9.4}{:>8.4}{:>8.4}", "", p, c[0], c[1], c[2]); }
    for i in 0..3 { println!("chart, {:<11}{}", names[i], cov.iter().map(|c| format!("{:.2}", c[i])).collect::<Vec<_>>().join(" ")); }
    let mirror: Vec<f64> = methods.iter().map(|m| coverage(m.as_ref(), 0.98)).collect();
    println!("{:<25}{:>9.4}{:>8.4}{:>8.4}", "mirror, p = 0.98", mirror[0], mirror[1], mirror[2]);
    let mut lows = Vec::new();
    for (m, name) in methods.iter().zip(names) {
        let mut best = (f64::INFINITY, 0.0);
        for i in 1..1000 {
            let p = i as f64 / 1000.0;
            let c = coverage(m.as_ref(), p);
            if c < best.0 { best = (c, p); }
        }
        println!("lowest coverage, {:<17}{:>10.4} at p = {:.3}", name, best.0, best.1);
        lows.push(best.0);
    }
    let low_w = (1..1000).map(|i| (coverage(methods[1].as_ref(), i as f64 / 1e5), i as f64 / 1e5))
        .fold((f64::INFINITY, 0.0), |b, c| if c.0 < b.0 { c } else { b });
    println!("{:<34}{:>10.4} at p = {:.5}", "lowest coverage, Wilson, p < 0.01", low_w.0, low_w.1);
    let (runs, p0, mut state) = (20000, 0.02, 20260928_u64);
    let mut hits = [0usize; 3];
    for _ in 0..runs {                           // one run = one trial of 100 patients
        let k = (0..N).filter(|_| ((next64(&mut state) >> 11) as f64 / 9007199254740992.0) < p0).count();
        for (i, m) in methods.iter().enumerate() {
            let iv = m(k);
            if iv.0 <= p0 && p0 <= iv.1 { hits[i] += 1; }
        }
    }
    let sims: Vec<f64> = hits.iter().map(|&h| h as f64 / runs as f64).collect();
    for i in 0..3 {
        let se = (sims[i] * (1.0 - sims[i]) / runs as f64).sqrt();
        println!("simulated, p = 0.02, {:<7}{:>10.4}  se {:.4}  (sim - enumerated)/se {:>5.2}", names[i], sims[i], se, (sims[i] - cov[1][i]) / se);
    }
    let paired: f64 = pmf(50, 0.45).iter().enumerate()
        .filter(|(j, _)| { let iv = wilson(z, 2 * j, N); iv.0 <= 0.45 && 0.45 <= iv.1 }).map(|(_, w)| w).sum();
    row("patients in identical pairs, Wilson", paired, 4);
    let ps: Vec<f64> = (0..13).map(|i| 0.005 * i as f64).collect();   // the score picture for 0 of 100
    println!("chart, p          {}", ps.iter().map(|p| format!("{:.3}", p)).collect::<Vec<_>>().join(" "));
    println!("chart, Wilson     {}", ps.iter().map(|p| format!("{:.3}", z * (p * (1.0 - p) / nf).sqrt())).collect::<Vec<_>>().join(" "));
    let (wz, wbz) = (wilson(z, 0, N), wilson_bisect(z, 0, N));
    assert!((z - 1.95996398).abs() < 1e-7);                                   // printed tables
    assert!([w45.0 - wb45.0, w45.1 - wb45.1, wz.0 - wbz.0, wz.1 - wbz.1].iter().all(|d| d.abs() < 1e-9));
    assert!((e45.0 - a45.0).abs().max((e45.1 - a45.1).abs()) < 1e-6);          // sums vs area
    assert!((exact[0].1 - (1.0 - (ALPHA / 2.0).powf(1.0 / nf))).abs() < 1e-9); // closed form
    assert!(lows[2] >= 1.0 - ALPHA && lows[0] < 0.7);                          // guarantee, failure
    assert!((0..3).all(|i| (mirror[i] - cov[1][i]).abs() < 1e-9));            // p and 1 - p
    assert!((0..3).all(|i| (sims[i] - cov[1][i]).abs() < 4.0 * (cov[1][i] * (1.0 - cov[1][i]) / runs as f64).sqrt()));
    assert!(low_w.0 < 1.0 - ALPHA);                                            // Wilson is approximate
    assert!((wald(z, 45, N).1 - bisect(&|p| nf * (0.45 - p).powi(2) - z * z * 0.45 * 0.55, 0.45, 1.0, 200)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
