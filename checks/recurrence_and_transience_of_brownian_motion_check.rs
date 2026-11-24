// Recurrence and transience of Brownian motion -- the same check in Rust.
// Standard library only, no crates. Three roads to each hitting chance: the
// harmonic formula, a walk-on-spheres simulation with its own random numbers,
// and a finite-difference solution of the radial Laplace equation. Then Polya.
use std::f64::consts::PI;
const INF: f64 = f64::INFINITY;

fn phi(d: i32, rho: f64) -> f64 { // log in the plane, rho^(2-d) above
    if d == 2 { rho.ln() } else { rho.powf((2 - d) as f64) }
}
fn p_small(d: i32, r: f64, s: f64, big_r: f64) -> f64 { // r before R, from s
    if big_r == INF {
        return if d == 2 { 1.0 } else { (r / s).powf((d - 2) as f64) };
    }
    (phi(d, big_r) - phi(d, s)) / (phi(d, big_r) - phi(d, r))
}
fn norm(x: &[f64]) -> f64 {
    let mut t = 0.0;
    for c in x { t += c * c; }
    t.sqrt()
}
fn laplacian(f: &dyn Fn(&[f64]) -> f64, x: &[f64], h: f64) -> f64 {
    let mut tot = 0.0;
    for i in 0..x.len() {
        let (mut up, mut dn) = (x.to_vec(), x.to_vec());
        up[i] += h; dn[i] -= h;
        tot += (f(&up) - 2.0 * f(x) + f(&dn)) / h.powf(2.0);
    }
    tot
}
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn direction(rng: &mut SplitMix64, d: i32) -> Vec<f64> { // uniform on circle or sphere
    let a = 2.0 * PI * rng.uniform();
    if d == 2 { return vec![a.cos(), a.sin()]; }
    let z = 2.0 * rng.uniform() - 1.0;
    let w = (1.0 - z * z).sqrt();
    vec![w * a.cos(), w * a.sin(), z]
}
fn walk_on_spheres(d: i32, r: f64, s: f64, big_r: f64, paths: usize, seed: u64) -> (f64, f64, f64) {
    let eps = 1e-6;
    let mut rng = SplitMix64 { s: seed };
    let (mut hits, mut steps) = (0usize, 0usize);
    for _ in 0..paths {
        let mut x = vec![0.0; d as usize];
        x[0] = s;
        loop {
            let rho = norm(&x);
            if rho - r < eps { hits += 1; break; }
            if big_r - rho < eps * big_r { break; }
            let jump = (rho - r).min(big_r - rho);
            let u = direction(&mut rng, d);
            steps += 1;
            x = x.iter().zip(u.iter()).map(|(c, e)| c + jump * e).collect();
        }
    }
    let p = hits as f64 / paths as f64;
    (p, (p * (1.0 - p) / paths as f64).sqrt(), steps as f64 / paths as f64)
}
fn radial_fd(d: i32, r: f64, s: f64, big_r: f64, n: usize) -> f64 { // Thomas sweep
    let h = (big_r - r) / n as f64;
    let (mut a, mut b, mut c, mut rhs) = (vec![], vec![], vec![], vec![]);
    for i in 1..n {
        let rho = r + i as f64 * h;
        let k = (d - 1) as f64 * h / (2.0 * rho);
        a.push(1.0 - k); b.push(-2.0); c.push(1.0 + k); rhs.push(0.0);
    }
    rhs[0] -= a[0] * 1.0;
    for i in 1..n - 1 {
        let m = a[i] / b[i - 1];
        b[i] -= m * c[i - 1];
        rhs[i] -= m * rhs[i - 1];
    }
    let mut u = vec![0.0; n - 1];
    u[n - 2] = rhs[n - 2] / b[n - 2];
    for i in (0..n - 2).rev() { u[i] = (rhs[i] - c[i] * u[i + 1]) / b[i]; }
    u[((s - r) / h).round() as usize - 1]
}

fn main() {
    println!("harmonic test: numerical Laplacian at a point 1.39 from the centre");
    for (d, x) in [(2, vec![1.2, 0.7]), (3, vec![1.2, 0.7, 0.0])] {
        let rho = norm(&x);
        for p in [2 - d, if d == 2 { -1 } else { 1 }] {
            let f = move |y: &[f64]| if p == 0 { norm(y).ln() } else { norm(y).powf(p as f64) };
            let lab = if p == 0 { "log|x|".to_string() } else { format!("|x|^{}", p) };
            let mut num = laplacian(&f, &x, 1e-3);
            let exact = (p * (p + d - 2)) as f64 * rho.powf((p - 2) as f64);
            if num.abs() < 5e-7 { num = 0.0; }
            println!("  d={}  {:8} Laplacian {:+.6}  (p(p+d-2)rho^(p-2) = {:+.6})", d, lab, num, exact);
            assert!((num - exact).abs() < 1e-5);
        }
    }
    let pl = p_small(2, 1.0, 2.0, 100.0);
    let sp = p_small(3, 1.0, 2.0, INF);
    println!("plane, from 2: radius 1 before radius 100 = ln(50)/ln(100) = {:.4}", pl);
    println!("space, from 2: ever hit radius 1 = (1/2)^1 = {:.4}", sp);
    println!("worked: ln 100 = {:.4}, ln 2 = {:.4}, ln 50 = {:.4}", 100f64.ln(), 2f64.ln(), 50f64.ln());
    println!("worked: ln 500,000 = {:.3}, ln 10^6 = {:.3}", 5e5f64.ln(), 1e6f64.ln());
    assert!((pl - 50f64.ln() / 100f64.ln()).abs() < 1e-12 && (sp - 0.5).abs() < 1e-12);

    println!("road 2, walk on spheres (20,000 paths each, seed 20260930)");
    for (d, big_r, lab) in [(2, 100.0, "100"), (3, 1e6, "10^6")] {
        let (est, se, st) = walk_on_spheres(d, 1.0, 2.0, big_r, 20000, 20260930);
        let ex = p_small(d, 1.0, 2.0, big_r);
        println!("  d={} R={}: simulated {:.4} +- {:.4}, formula {:.4}, mean jumps {:.1}", d, lab, est, se, ex, st);
        assert!((est - ex).abs() < 4.0 * se);
    }
    println!("road 3, finite differences on the radial equation, step 0.005");
    for d in [2, 3] {
        let fd = radial_fd(d, 1.0, 2.0, 100.0, 19800);
        let ex = p_small(d, 1.0, 2.0, 100.0);
        println!("  d={} R=100: grid {:.6}, formula {:.6}", d, fd, ex);
        assert!((fd - ex).abs() < 1e-5);
    }

    println!("chance of radius 1 before radius R, from 2   (chart)");
    println!("  R        d=2      d=3      d=4");
    for big_r in [10.0, 100.0, 1000.0, 1e4, 1e5, 1e6, INF] {
        let lab = if big_r == INF { "inf".to_string() } else { format!("10^{}", big_r.log10().round() as i32) };
        let row: Vec<String> = [2, 3, 4].iter().map(|&d| format!("{:8.4}", p_small(d, 1.0, 2.0, big_r))).collect();
        println!("  {:6} {}", lab, row.join(" "));
    }
    println!("plane, from 2, before radius 100: shrink the target towards a point");
    for (lab, r) in [("0.1", 0.1), ("0.01", 0.01), ("10^-6", 1e-6), ("10^-100", 1e-100)] {
        println!("  r = {}: {:.4}", lab, p_small(2, r, 2.0, 100.0));
    }
    println!("space, start at 10: ever hit radius 1 = {:.4}", p_small(3, 1.0, 10.0, INF));

    println!("what breaks (plane from 2, R = 100, right answer 0.8495)");
    let lin = (100.0 - 2.0) / (100.0 - 1.0);
    let inv = p_small(3, 1.0, 2.0, 100.0);
    println!("  radius treated as a 1-D Brownian motion: {:.4}", lin);
    println!("  space's 1/|x| used in the plane: {:.4}", inv);
    println!("  far wall instead of near ball: {:.4}", 1.0 - pl);
    println!("  plane's log used in space, R = 10^6: {:.4} (right {:.4})", p_small(2, 1.0, 2.0, 1e6), p_small(3, 1.0, 2.0, 1e6));
    assert!(lin > pl && pl > inv);

    println!("Polya: expected visits to the start in 2N steps of the grid walk");
    let big_n = 200usize;
    let (mut a, mut s1, mut s2, mut s3) = (1.0f64, 0.0f64, 0.0f64, 0.0f64);
    let mut lf = vec![0.0f64];
    for k in 1..=big_n { let last = lf[k - 1]; lf.push(last + (k as f64).ln()); }
    for n in 0..=big_n {
        if n > 0 { a *= (2 * n - 1) as f64 / (2 * n) as f64; }
        let mut t3 = 0.0; // chance the three axes each net to zero, given n steps on them
        for j in 0..=n {
            for k in 0..=(n - j) {
                t3 += (2.0 * (lf[n] - lf[j] - lf[k] - lf[n - j - k]) - (2 * n) as f64 * 3f64.ln()).exp();
            }
        }
        s1 += a; s2 += a * a; s3 += a * t3;
        if n == 10 || n == 100 || n == 200 {
            println!("  N={:3}: line {:7.3}   plane {:6.3}   space {:6.4}", n, s1, s2, s3);
        }
    }
    let u3 = s3 + 2.0 * (3.0 / (4.0 * PI)).powf(1.5) * 2.0 / (big_n as f64 + 0.5).sqrt();
    println!("  space with tail added: {:.4}; chance of ever returning 1 - 1/u = {:.4}", u3, 1.0 - 1.0 / u3);
    assert!((1.0 - 1.0 / u3 - 0.340537).abs() < 1e-3 && s2 > (big_n as f64).ln() / PI);
    println!("ALL CHECKS PASS");
}
