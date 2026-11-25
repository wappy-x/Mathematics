// Roth's theorem on three-term progressions -- the same check as the Python, in
// Rust.  No crates.  Road one finds r3(N), the largest progression-free set in
// 1..N, by trying every subset and by a pruned exhaustive search.  Road two
// counts progressions of A = {1, 2, 4, 8, 9} modulo M = 19 directly and by the
// Fourier sum.  Then it runs the density-increment step on A and on the base-3
// set in 1..729, and the iteration that gives 72 N / log log N.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                       // a small complex number
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn sc(self, k: f64) -> C { C { re: self.re * k, im: self.im * k } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn e(t: f64) -> C { C { re: (2.0 * PI * t).cos(), im: (2.0 * PI * t).sin() } }   // the arrow e(t)
fn fx(v: f64) -> String { let s = format!("{:.6}", v); if s == "-0.000000" { "0.000000".into() } else { s } }
fn has3(s: &[usize]) -> bool {                      // x, y, z in s with x + z = 2y, x < z?
    s.iter().any(|&x| s.iter().any(|&z| x < z && (x + z) % 2 == 0 && s.contains(&((x + z) / 2))))
}
fn go(pos: usize, n: usize, ch: &mut Vec<usize>, best: &mut (usize, Vec<Vec<usize>>)) {
    if ch.len() + n + 1 - pos < best.0 { return; }
    if pos > n {
        if ch.len() > best.0 { *best = (ch.len(), Vec::new()); }
        best.1.push(ch.clone()); return;
    }
    if ch.iter().all(|&y| { let z = 2 * y as i64 - pos as i64; z <= 0 || !ch.contains(&(z as usize)) }) {
        ch.push(pos); go(pos + 1, n, ch, best); ch.pop();
    }
    go(pos + 1, n, ch, best);
}
fn tw(g1: &[f64], g2: &[f64], g3: &[f64], m: usize) -> f64 {   // weighted count of x, x+d, x+2d mod m
    let mut s = 0.0;
    for x in 0..m { for d in 0..m { s += g1[x] * g2[(x + d) % m] * g3[(x + 2 * d) % m]; } }
    s
}
fn steps(d0: f64) -> usize { let (mut u, mut k) = (d0, 0); while u <= 1.0 { u += u * u / 48.0; k += 1; } k }
fn threshold(d0: f64) -> f64 { (steps(d0) - 1) as f64 * 2f64.ln() + (4.0 * (96.0 * PI / (d0 * d0)).ln()).ln() }
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let brute: Vec<u32> = (1..=12usize).map(|n| (0..1usize << n).filter(|m| {
        let s: Vec<usize> = (0..n).filter(|i| m >> i & 1 == 1).map(|i| i + 1).collect(); !has3(&s)
    }).map(|m| m.count_ones()).max().unwrap()).collect();
    let rr: Vec<(usize, Vec<Vec<usize>>)> = (1..=20).map(|n| {
        let mut b = (0, Vec::new()); go(1, n, &mut Vec::new(), &mut b); b }).collect();
    let r3: Vec<usize> = rr.iter().map(|r| r.0).collect();
    println!("r3(N) by trying every subset, N = 1..12: {:?}", brute);
    println!("r3(N) by pruned exhaustive search, N = 1..20: {:?}", r3);
    println!("largest progression-free sets in 1..9: {:?}", rr[8].1);
    println!("largest in 1..20: size {}, {} such sets, first {:?}", r3[19], rr[19].1.len(), rr[19].1[0]);
    let share: Vec<f64> = (1..=20).map(|n| r3[n - 1] as f64 / n as f64).collect();
    println!("chart, share r3(N)/N: {}", join(&share, 3));
    assert!(brute.iter().zip(&r3).all(|(b, r)| *b as usize == *r) && r3[8] == 5 && r3[19] == 9 && rr[8].1.contains(&vec![1, 2, 4, 8, 9]));
    let mut b9: Vec<Vec<usize>> = (0..1usize << 9).filter(|m| m.count_ones() == 5)       // the largest sets in 1..9 again,
        .map(|m| (0..9).filter(|i| m >> i & 1 == 1).map(|i| i + 1).collect::<Vec<usize>>()).filter(|s| !has3(s)).collect();
    let mut r9 = rr[8].1.clone(); r9.sort(); b9.sort();                                    // by trying every subset
    assert!(b9 == r9 && b9.len() == 4 && rr[19].1.len() == 2);

    let a = [1usize, 2, 4, 8, 9]; let n = 9usize;
    let (m, dens) = (2 * n + 1, a.len() as f64 / n as f64);
    let ind: Vec<f64> = (0..m).map(|x| if a.contains(&x) { 1.0 } else { 0.0 }).collect();
    let hat = |g: &[f64], xi: usize| (0..m).fold(C { re: 0.0, im: 0.0 },
        |s, x| s.add(e(-((x * xi % m) as f64) / m as f64).sc(g[x]))).sc(1.0 / m as f64);
    let h: Vec<C> = (0..m).map(|xi| hat(&ind, xi)).collect();
    let terms: Vec<C> = (0..m).map(|xi| h[xi].mul(h[xi]).mul(h[(2 * m - 2 * xi) % m]).sc((m * m) as f64)).collect();
    let tot = terms.iter().fold(C { re: 0.0, im: 0.0 }, |s, t| s.add(*t));
    let rest = terms[1..].iter().fold(C { re: 0.0, im: 0.0 }, |s, t| s.add(*t));
    let direct = tw(&ind, &ind, &ind, m).round() as i64;
    let pars: f64 = h.iter().map(|z| z.abs().powi(2)).sum();
    println!("A = {:?}, N = {}, modulus M = {}, density in 1..{} = {:.6}", a, n, m, n, dens);
    println!("pairs (x, d) mod {} with x, x+d, x+2d in A, counted directly: {}", m, direct);
    println!("the same by the Fourier sum: {:.6}; xi = 0 term {:.6}; other {} terms {:.6}", tot.re, terms[0].re, m - 1, rest.re);
    println!("sizes |hat A(xi)|, xi = 0..9: {}", join(&h[..10].iter().map(|z| z.abs()).collect::<Vec<_>>(), 4));
    println!("Parseval: sum of |hat A|^2 = {:.6}, |A|/M = {:.6}", pars, a.len() as f64 / m as f64);
    let hmax = h[1..].iter().map(|z| z.abs()).fold(0.0, f64::max); let cap = m as f64 * hmax * a.len() as f64;
    println!("largest |hat A(xi)| with xi != 0: {:.4}; Parseval caps the other terms at {:.6}", hmax, cap);
    assert!(direct == a.len() as i64 && (tot.re - direct as f64).abs() < 1e-9 && tot.im.abs() < 1e-9 && rest.abs() <= cap);
    assert!((pars - a.len() as f64 / m as f64).abs() < 1e-12);

    let mut tp = 0usize;
    for x in 1..=n { for y in 1..=n { for z in 1..=n { if x + z == 2 * y { tp += 1; } } } }
    let p: Vec<f64> = (0..m).map(|x| if 1 <= x && x <= n { 1.0 } else { 0.0 }).collect();
    let f: Vec<f64> = (0..m).map(|x| ind[x] - dens * p[x]).collect();      // the balanced function
    let dp: Vec<f64> = p.iter().map(|q| dens * q).collect();
    let corr: Vec<f64> = (0..m).map(|xi| (0..m).fold(C { re: 0.0, im: 0.0 },
        |s, x| s.add(e(-((x * xi % m) as f64) / m as f64).sc(f[x]))).abs()).collect();
    let mut big = 1; for xi in 1..(m + 1) / 2 { if corr[xi] > corr[big] { big = xi; } }
    let c3 = [tw(&f, &ind, &ind, m), tw(&dp, &f, &ind, m), tw(&dp, &dp, &f, m)];
    let promise = (dens * dens * tp as f64 / n as f64 - 1.0) / 3.0;
    let csum: f64 = c3.iter().sum();
    println!("integer solutions of x + z = 2y in 1..{}: T(P) = {} (formula {}^2 + {}^2); density^3 T(P) = {:.6}",
             n, tp, (n + 1) / 2, n / 2, dens.powi(3) * tp as f64);
    println!("three correction terms: {} ; sum {:.6}", c3.iter().map(|&c| fx(c)).collect::<Vec<_>>().join(", "), csum);
    println!("largest |sum f(x) e(-x xi/{})|: {:.6} at xi = {}; the proof promises at least {:.6}", m, corr[big], big, promise);
    assert!(tp == ((n + 1) / 2).pow(2) + (n / 2).pow(2) && (csum - (direct as f64 - dens.powi(3) * tp as f64)).abs() < 1e-9);
    assert!(c3.iter().all(|c| c.abs() <= dens * n as f64 * corr[big] + 1e-9) && corr[big] >= promise && promise > 0.0);

    let (xi, qq) = (9usize, 3usize);                // the step: wave xi, Dirichlet with q <= sqrt N
    let dist = |q: usize| { let r = q * xi % m; r.min(m - r) as f64 / m as f64 };
    let q = (1..=qq).find(|&q| dist(q) <= 1.0 / (qq + 1) as f64).unwrap();
    println!("wave xi = {}: correlation {:.6}; Dirichlet gives q = {}, ||q theta|| = {:.6}", xi, corr[xi], q, dist(q));
    let pieces: Vec<Vec<usize>> = (1..=q).map(|s| (s..=n).step_by(q).collect()).collect();
    let cnt = |pc: &Vec<usize>| pc.iter().filter(|x| a.contains(x)).count();
    for pc in &pieces {
        let k = cnt(pc);
        println!("piece {:?}: {} of {} in A, density {:.6}, surplus {:.6}", pc, k, pc.len(), k as f64 / pc.len() as f64, k as f64 - dens * pc.len() as f64);
    }
    let mut top = &pieces[0];
    for pc in &pieces { if cnt(pc) as f64 / pc.len() as f64 > cnt(top) as f64 / top.len() as f64 { top = pc; } }
    let new: Vec<usize> = top.iter().filter(|x| a.contains(x)).map(|x| (x - top[0]) / q + 1).collect();
    let nd = new.len() as f64 / top.len() as f64;
    println!("rescaled: {:?} inside 1..{}, density {:.6}, progression-free: {}", new, top.len(), nd, if has3(&new) { "no" } else { "yes" });
    assert!(!has3(&new) && nd - dens >= corr[xi] / n as f64 / 4.0);

    let (n3, m3) = (729usize, 1459usize);           // the base-3 set: digits 0 and 1, plus one
    let b: Vec<usize> = (0..n3).filter(|&v| (0..6).all(|j| v / 3usize.pow(j) % 3 < 2)).map(|v| v + 1).collect();
    let d3 = b.len() as f64 / n3 as f64;
    let mut inb = vec![false; n3 + 1]; for &x in &b { inb[x] = true; }
    let c3x: Vec<f64> = (1..=n3).map(|k| (1..=n3).fold(C { re: 0.0, im: 0.0 }, |s, x|
        s.add(e(-((x * k % m3) as f64) / m3 as f64).sc(if inb[x] { 1.0 } else { 0.0 } - d3))).abs()).collect();
    let mut k3 = 0; for k in 0..n3 { if c3x[k] > c3x[k3] { k3 = k; } }
    let thirds: Vec<usize> = (0..3).map(|j| b.iter().filter(|&&x| 243 * j < x && x <= 243 * (j + 1)).count()).collect();
    println!("base-3 set in 1..{}: {} members, density {:.6}, progression-free: {}", n3, b.len(), d3, if has3(&b) { "no" } else { "yes" });
    println!("  promise {:.6} (N >= 4/density^2 = {:.1}); largest {:.6} at xi = {}", d3 * d3 * n3 as f64 / 12.0, 4.0 / (d3 * d3), c3x[k3], k3 + 1);
    println!("  thirds of 1..{}: {:?} members, densities {}", n3, thirds, join(&thirds.iter().map(|&t| t as f64 / 243.0).collect::<Vec<_>>(), 6));
    assert!(!has3(&b) && c3x[k3] >= d3 * d3 * n3 as f64 / 12.0 && n3 as f64 >= 4.0 / (d3 * d3) && *thirds.iter().max().unwrap() as f64 / 243.0 > d3);

    println!("density | steps K | log log N must stay below | 72/density | digits of N, about 10^");
    for d0 in [0.5f64, 0.1, 0.01] {
        let t = threshold(d0);
        println!("{} | {} | {:.3} | {:.1} | {:.1}", d0, steps(d0), t, 72.0 / d0, t / 10f64.ln() - 10f64.ln().log10());
    }
    let worst = (1..=100).map(|j| threshold(j as f64 / 100.0) * j as f64 / 100.0).fold(f64::MIN, f64::max);
    println!("largest density x threshold over density 0.01..1.00: {:.3} (the card's constant is 72)", worst);
    let (a96, l2) = ((96.0 * PI).ln(), 2f64.ln()); let b96 = (4.0 * a96).ln();   // the fold's constants
    println!("constant: log(96 pi) = {:.3}, 4 x that = {:.2}, its log = {:.3}, 98 log 2 = {:.2}, sum {:.2}", a96, 4.0 * a96, b96, 98.0 * l2, 98.0 * l2 + b96);
    assert!((1..=100).all(|j| (steps(j as f64 / 100.0) - 1) as f64 <= 98.0 * 100.0 / j as f64) && worst < 72.0);
    assert!(98.0 * l2 + b96 < 72.0);

    let w: Vec<f64> = (0..n).map(|x| if a.iter().any(|&v| v % n == x) { 1.0 } else { 0.0 }).collect();
    let wrap = tw(&w, &w, &w, n).round() as i64;    // A read modulo 9: 9 becomes 0
    println!("mistake, modulus {} instead of {}: {} pairs, not {}; 8, 9, 10 wraps to 8, 0, 1", n, m, wrap, direct);
    println!("mistake, largest |hat A| of A itself: {:.4} at xi = 0, which is |A|/M = {:.4}", h[0].abs(), a.len() as f64 / m as f64);
    println!("mistake, the bound at N = 10^6: 72 / log log N = {:.2}, above 1", 72.0 / (1e6f64).ln().ln());
    assert!(wrap == 13 && wrap > direct);
    println!("ALL CHECKS PASS");
}
