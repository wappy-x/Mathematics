// Riesz potentials and Hardy-Littlewood-Sobolev -- the check behind the card.  Rust std only.
// Space has n = 3 dimensions and I2 f(x) = integral of f(y) / |x - y| dy, so the Newtonian
// potential is I2 f / (4 pi).  Example: f = 1 on a ball of radius R.  The same roads as the
// Python twin: closed forms against the defining integral by midpoint sums, exact norms
// against Simpson sums, the scaling law, Lieb's Gamma formula against the bell, and
// Hedberg's near-far split against the true values.  Both print the same lines.
use std::f64::consts::PI;
fn gam(x: f64) -> f64 { // Gamma at a whole or half-whole number, from Gamma(x + 1) = x Gamma(x)
    let (mut g, mut y) = if x == x.round() { (1.0, 1.0) } else { (PI.sqrt(), 0.5) };
    while y < x - 1e-9 { g *= y; y += 1.0; }
    g
}
fn add(v: impl Iterator<Item = f64>) -> f64 { let mut t = 0.0; for x in v { t += x; } t }
fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let m = 2000; let h = (b - a) / m as f64;
    h / 3.0 * add((0..=m).map(|k| {
        let w = if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        w * f(a + k as f64 * h) }))
}
fn pot(r: f64, rr: f64) -> f64 { // I2 of the ball of radius rr, from the shell theorem
    if r <= rr { 2.0 * PI / 3.0 * (3.0 * rr * rr - r * r) } else { 4.0 * PI * rr.powf(3.0) / (3.0 * r) }
}
fn kernel(r: f64, nodes: &[(f64, f64)]) -> f64 { // defining integral, x at distance r
    let n = 400; let mut tot = 0.0;
    for &(s, w) in nodes {
        for j in 0..n {
            let c = -1.0 + (j as f64 + 0.5) * 2.0 / n as f64;
            tot += w / (r * r + s * s - 2.0 * r * s * c).sqrt();
        }
    }
    tot * 2.0 * PI * 2.0 / n as f64
}
fn comb(n: i64, k: i64) -> i64 { (0..k).fold(1, |a, i| a * (n - i) / (i + 1)) }
fn exact_qq(q: i64) -> (f64, f64) { // ||I2 f||_q^q for the unit ball, exactly
    let j = add((0..=q).map(|k| (comb(q, k) * 3i64.pow((q - k) as u32) * if k % 2 == 0 { 1 } else { -1 }) as f64 / (2 * k + 3) as f64));
    let qf = q as f64;
    ((2.0 * PI / 3.0).powf(qf) * 4.0 * PI * j + (4.0 * PI / 3.0).powf(qf) * 4.0 * PI / (qf - 3.0), j)
}
fn ratio(q: f64, rr: f64) -> f64 { // ||I2 f_R||_q / ||f_R||_(6/5) by Simpson sums; outside r = R / t
    let inner = simpson(|r| pot(r, rr).powf(q) * 4.0 * PI * r * r, 0.0, rr);
    let outer = simpson(|t| (4.0 * PI * rr * rr / 3.0).powf(q) * 4.0 * PI * rr.powf(3.0) * t.powf(q - 4.0), 0.0, 1.0);
    (inner + outer).powf(1.0 / q) / (4.0 * PI * rr.powf(3.0) / 3.0).powf(5.0 / 6.0)
}
fn lens(d: f64, s: f64) -> f64 { // volume shared by the unit ball and a ball of radius s
    if d >= 1.0 + s { return 0.0; }
    if d <= (1.0 - s).abs() { return 4.0 * PI / 3.0 * 1f64.min(s).powf(3.0); }
    PI * (1.0 + s - d).powf(2.0) * (d * d + 2.0 * d * (1.0 + s) - 3.0 * (1.0 - s).powf(2.0)) / (12.0 * d)
}
fn maxf(r: f64) -> f64 {
    if r < 1.0 { return 1.0; }
    let kk = 20000;
    (1..=kk).map(|k| { let s = r - 1.0 + (2 * k) as f64 / kk as f64; lens(r, s) / (4.0 * PI * s.powf(3.0) / 3.0) }).fold(f64::MIN, f64::max)
}
fn main() {
    let n0 = 400usize; let n0f = n0 as f64;
    let ball: Vec<(f64, f64)> = (0..n0).map(|i| { let s = (i as f64 + 0.5) / n0f; (s, s.powf(2.0) / n0f) }).collect();
    for r in [0.0, 0.5, 1.0, 2.0] {
        let (a, b) = (kernel(r, &ball), pot(r, 1.0));
        println!("ball potential I2f({:.1}): defining integral {:.6}, closed form {:.6}", r, a, b);
        assert!((a - b).abs() < 2e-3 * b);
    }
    let (q6, j6) = exact_qq(6);
    let nf = (4.0 * PI / 3.0).powf(5.0 / 6.0);
    let rb = q6.powf(1.0 / 6.0) / nf;
    println!("J = {:.6}; ||I2f||_6^6 = {:.4}; ||I2f||_6 = {:.6}; ||f||_6/5 = {:.6}", j6, q6, q6.powf(1.0 / 6.0), nf);
    println!("inner part {:.4}, outer part {:.4}", (2.0 * PI / 3.0).powf(6.0) * 4.0 * PI * j6, (4.0 * PI / 3.0).powf(6.0) * 4.0 * PI / 3.0);
    println!("ball ratio ||I2f||_6 / ||f||_6/5 = {:.6}; Newtonian u = I2f/(4 pi): {:.6}", rb, rb / (4.0 * PI));
    assert!((ratio(6.0, 1.0) - rb).abs() < 1e-9 * rb);
    for q in [4i64, 6, 8] {
        let qf = q as f64; let e = 2.0 + 3.0 / qf - 5.0 / 2.0;
        let row: Vec<f64> = (0..9).map(|k| ratio(qf, 10f64.powf(k as f64 / 2.0 - 2.0))).collect();
        let s: Vec<String> = row.iter().map(|v| format!("{:.4}", v)).collect();
        println!("chart,q={},exponent {:+.3},{}", q, e, s.join(","));
        assert!((row[8] / row[4] - 100f64.powf(e)).abs() < 1e-9 * row[8] / row[4]);
        assert!((row[4] - exact_qq(q).0.powf(1.0 / qf) / nf).abs() < 1e-9 * row[4]);
    }
    let lieb = PI.powf(0.5) * gam(1.0) / gam(2.5) * (gam(1.5) / gam(3.0)).powf(-2.0 / 3.0);
    let bell = 4.0 * PI / 3.0 * (4.0 / PI.powf(2.0)).powf(2.0 / 3.0);
    println!("Lieb's sharp constant {:.6}; bell ratio {:.6}; ball / sharp {:.6}", lieb, bell, rb / lieb);
    assert!((lieb - bell).abs() < 1e-12 && rb < lieb);
    let ph = |i: usize| (i as f64 + 0.5) * PI / 2.0 / n0f;
    let bn: Vec<(f64, f64)> = (0..n0).map(|i| { let p = ph(i); (p.tan(), p.sin().powf(2.0) * p.cos() * PI / 2.0 / n0f) }).collect();
    let (a, b) = (kernel(1.0, &bn), 4.0 * PI / 3.0 / 2f64.sqrt());
    println!("bell potential I2h(1): defining integral {:.6}, closed form {:.6}", a, b);
    assert!((a - b).abs() < 2e-3 * b);
    let d = simpson(|r| pot(r, 1.0) * 4.0 * PI * r * r, 0.0, 1.0);
    println!("self-energy D = {:.6} (32 pi^2/15 = {:.6}); D/||f||^2 = {:.6}", d, 32.0 * PI.powf(2.0) / 15.0, d / nf.powf(2.0));
    assert!((d - 32.0 * PI.powf(2.0) / 15.0).abs() < 1e-9 && d / nf.powf(2.0) < lieb);
    let (aa, bc) = (2.0 * PI, (4.0 * PI / 3.0).powf(1.0 / 6.0));
    println!("Hedberg constants: A = 2 pi = {:.6}, B = (4 pi/3)^(1/6) = {:.6}", aa, bc);
    let mut dc = 0.0;
    for r in [0.0, 1.5, 2.0, 3.0] {
        let m = maxf(r);
        let dl = (bc * nf / (4.0 * aa * m)).powf(0.4);
        let bnd = aa * dl * dl * m + bc * nf / dl.sqrt();
        let scan = (1..5000).map(|k| { let x = k as f64 / 1000.0; aa * x * x * m + bc * nf / x.sqrt() }).fold(f64::MAX, f64::min);
        println!("Hedberg at r = {:.1}: Mf {:.6}, delta {:.6}, bound {:.6}, true {:.6}, ratio {:.6}", r, m, dl, bnd, pot(r, 1.0), pot(r, 1.0) / bnd);
        assert!(pot(r, 1.0) <= bnd && bnd <= scan + 1e-9 && scan - bnd < 1e-4);
        if r == 0.0 { dc = dl; }
    }
    let (near, far) = (simpson(|s| 4.0 * PI * s * s / s, 1e-12, dc), simpson(|s| 4.0 * PI * s * s / s, dc, 1.0)); // shells 4 pi s^2, kernel 1/s
    println!("centre split: near {:.6} <= {:.6}; far {:.6} <= {:.6}", near, aa * dc * dc, far, bc * nf / dc.sqrt());
    assert!((near - aa * dc * dc).abs() < 1e-9 && far <= bc * nf / dc.sqrt() && (near + far - pot(0.0, 1.0)).abs() < 1e-9);
    let g2 = simpson(|r| (r / 3.0).powf(2.0) * 4.0 * PI * r * r, 0.0, 1.0) + simpson(|_t| 4.0 * PI / 9.0, 0.0, 1.0);
    println!("field energy ||grad u||_2^2: integral {:.6}, D/(4 pi) {:.6}", g2, d / (4.0 * PI));
    assert!((g2 - d / (4.0 * PI)).abs() < 1e-9);
    let tal = 1.0 / (3.0 * PI).sqrt() * (gam(3.0) / gam(1.5)).powf(1.0 / 3.0);
    let m6 = add((0..n0).map(|i| ph(i).sin().powf(2.0) * ph(i).cos().powf(2.0))) * PI / 2.0 / n0f;
    let m2 = add((0..n0).map(|i| ph(i).sin().powf(4.0))) * PI / 2.0 / n0f;
    let (sb, sbell) = (q6.powf(1.0 / 6.0) / (4.0 * PI) / g2.sqrt(), (4.0 * PI * m6).powf(1.0 / 6.0) / (4.0 * PI * m2).sqrt());
    println!("Sobolev ||u||_6/||grad u||_2: ball {:.6}, bell {:.6}, sharp {:.6}, ball / sharp {:.6}", sb, sbell, tal, sb / tal);
    assert!(sb < tal && (sbell - tal).abs() < 1e-12);
    let (n5, r2) = (100000usize, 2.0f64);
    let inn = simpson(|s| s / 3.0 * s * s * 2.0 * PI / (r2 * s) * ((r2 + s) / (r2 - s)).ln(), 1e-12, 1.0);
    let out = add((0..n5).map(|k| { let t = (k as f64 + 0.5) / n5 as f64; 2.0 * PI / (3.0 * r2 * t) * ((1.0 + r2 * t) / (1.0 - r2 * t).abs()).ln() })) / n5 as f64;
    let c0 = (simpson(|r| 4.0 * PI * r / 3.0, 0.0, 1.0) + simpson(|_t| 4.0 * PI / 3.0, 0.0, 1.0)) / (4.0 * PI);
    println!("u <= I1|grad u|/(4 pi): centre {:.6} <= {:.6}; r = 2: {:.6} <= {:.6}", pot(0.0, 1.0) / (4.0 * PI), c0, pot(2.0, 1.0) / (4.0 * PI), (inn + out) / (4.0 * PI));
    assert!((c0 - pot(0.0, 1.0) / (4.0 * PI)).abs() < 1e-9 && pot(2.0, 1.0) / (4.0 * PI) < (inn + out) / (4.0 * PI));
    let c1 = simpson(|r| ((3.0 - r * r) / 2.0).powf(3.0) * 4.0 * PI * r * r, 0.0, 1.0);
    let s: Vec<String> = [10.0f64, 1e3, 1e6].iter().map(|l| format!("{:.6}", (c1 + 4.0 * PI * l.ln()).powf(1.0 / 3.0))).collect();
    println!("p = 1, unit mass ball, ||I2f||_3 out to L = 10, 1e3, 1e6: {}", s.join(", "));
    for k in [2.0f64, 8.0, 32.0] {
        let v = k * 10f64.ln();
        let num = 4.0 * PI * add((0..10000).map(|j| 1.0 / (1.0 + (j as f64 + 0.5) * v / 10000.0))) * v / 10000.0;
        println!("p = 3/2, cut at 10^-{}: I2f(0) = {:.6} (sum {:.6})", k, 4.0 * PI * (1.0 + v).ln(), num);
        assert!((num - 4.0 * PI * (1.0 + v).ln()).abs() < 1e-4);
    }
    println!("ALL CHECKS PASS");
}
