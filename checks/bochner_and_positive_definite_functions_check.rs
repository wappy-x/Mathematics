// Bochner's theorem -- the check behind the card.  Rust std only, no crates.  Lags tau
// are in chips of the GPS C/A code (1.023 million chips a second); frequencies xi in
// cycles per chip.  Prints exactly what the Python check prints.
use std::f64::consts::PI;
const RATE: f64 = 1.023; // chip rate in MHz
fn tri(t: f64) -> f64 { (1.0 - t.abs()).max(0.0) } // the triangle: the code's correlation shape
fn gate(t: f64) -> f64 { if t.abs() < 1.0 { 1.0 } else { 0.0 } } // the candidate that fails
fn bowl(t: f64) -> f64 { 1.0 / (1.0 + t.abs()) } // Polya's bowl shape
fn spike(t: f64) -> f64 { if t == 0.0 { 1.0 } else { 0.0 } }
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }
fn z(x: f64) -> f64 { if x.abs() < 5e-10 { 0.0 } else { x } } // print a rounding-level number as 0
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h); }
    s * h / 3.0
}
fn eigs(a0: &Vec<Vec<f64>>) -> Vec<f64> { // Jacobi rotations: all eigenvalues of a symmetric matrix
    let mut a = a0.clone();
    let n = a.len();
    for _ in 0..60 {
        let mut off = 0.0;
        for i in 0..n { for j in 0..n { if i != j { off += a[i][j] * a[i][j]; } } }
        if off < 1e-22 { break; }
        for p in 0..n - 1 {
            for q in p + 1..n {
                if a[p][q].abs() < 1e-300 { continue; }
                let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt();
                let s = t * c;
                for k in 0..n {
                    let (akp, akq) = (a[k][p], a[k][q]);
                    a[k][p] = c * akp - s * akq; a[k][q] = s * akp + c * akq;
                }
                for k in 0..n {
                    let (apk, aqk) = (a[p][k], a[q][k]);
                    a[p][k] = c * apk - s * aqk; a[q][k] = s * apk + c * aqk;
                }
            }
        }
    }
    let mut d: Vec<f64> = (0..n).map(|i| a[i][i]).collect();
    d.sort_by(|x, y| x.partial_cmp(y).unwrap());
    d
}
fn gram(g: fn(f64) -> f64, lags: &[f64]) -> Vec<Vec<f64>> {
    lags.iter().map(|&a| lags.iter().map(|&b| g(a - b)).collect()).collect()
}
fn j0(x: f64) -> f64 { // the Bessel series, written out
    let (mut s, mut term, mut m) = (0.0f64, 1.0f64, 0.0f64);
    while term.abs() > 1e-17 || m < 5.0 {
        s += term; m += 1.0; term *= -(x / 2.0) * (x / 2.0) / (m * m);
    }
    s
}
fn cone(rho: f64) -> f64 { 2.0 * PI * simpson(|q| (1.0 - q) * q * j0(2.0 * PI * rho * q), 0.0, 1.0, 2000) }
fn f_sum(th: f64) -> f64 { (-3..4).map(|k: i32| tri(k as f64 / 4.0) * (k as f64 * th).cos()).sum() }
fn fejer(th: f64) -> f64 { if th == 0.0 { 4.0 } else { ((2.0 * th).sin() / (th / 2.0).sin()).powi(2) / 4.0 } }
struct Mix { state: u64 } // SplitMix64
impl Mix {
    fn bit(&mut self) -> i32 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.state;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        if (x ^ (x >> 31)) >> 63 == 1 { 1 } else { -1 }
    }
}
fn main() {
    println!("1 chip = {:.6} us = {:.3} m of light travel", 1.0 / RATE, 299792458.0 / 1.023e6);
    // Road one: the spectrum in closed form.  Road two: the transform integral of the triangle.
    println!("spectrum of the triangle, S(xi) = sinc(xi)^2");
    println!("  xi (per chip)  MHz     closed form  transform integral");
    for &xi in &[0.0, 0.25, 0.5, 0.75, 1.0, 1.5, 2.0] {
        let closed = sinc(xi).powi(2);
        let num = 2.0 * simpson(|t| tri(t) * (2.0 * PI * xi * t).cos(), 0.0, 1.0, 2000);
        println!("  {:5.2}         {:6.4}  {:9.6}  {:9.6}", xi, xi * RATE, z(closed), z(num));
        assert!(closed >= 0.0 && (closed - num).abs() < 1e-9);
    }
    let l = 200.0; // inversion cut-off; the tail is at most 2/(pi^2 L)
    for &tau in &[0.0, 0.5] {
        let back = 2.0 * simpson(|x| sinc(x).powi(2) * (2.0 * PI * x * tau).cos(), 0.0, l, 400000);
        println!("inverse transform at tau = {:.1}: {:.6} against g = {:.6}, tail bound {:.6}", tau, back, tri(tau), 2.0 / (PI * PI * l));
        assert!((back - tri(tau)).abs() < 2.0 / (PI * PI * l));
    }
    // The matrix test at lags 0, 0.8, 1.6 chips: [[1,a,b],[a,1,a],[b,a,1]].
    let lags = [0.0, 0.8, 1.6];
    println!("matrix test at lags 0, 0.8, 1.6: a = g(0.8), b = g(1.6), smallest eigenvalue closed / Jacobi");
    let cands: [(&str, fn(f64) -> f64); 3] = [("triangle", tri), ("gate", gate), ("bowl", bowl)];
    for &(name, g) in cands.iter() {
        let (a, b) = (g(0.8), g(1.6));
        let closed = (1.0 - b).min((2.0 + b - (b * b + 8.0 * a * a).sqrt()) / 2.0);
        let jac = eigs(&gram(g, &lags))[0];
        let form = 4.0 - 4.0 * 2f64.sqrt() * a + 2.0 * b; // weights (1, -sqrt 2, 1)
        println!("  {:9}{:9.6}{:9.6}{:11.6}{:11.6}   weights (1,-r2,1) give {:.6}", name, a, b, closed, jac, form);
        assert!((closed - jac).abs() < 1e-9 && (jac < 0.0) == (name == "gate"));
    }
    println!("  1 - sqrt 2 = {:.6}", 1.0 - 2f64.sqrt());
    let gs = 2.0 * simpson(|t| (2.0 * PI * 0.75 * t).cos(), 0.0, 1.0, 2000);
    println!("gate spectrum at xi = 0.75: closed 2 sinc(1.5) = {:.6}, integral {:.6}", 2.0 * sinc(1.5), gs);
    assert!(gs < 0.0 && (gs - 2.0 * sinc(1.5)).abs() < 1e-9);
    let sp = eigs(&gram(spike, &lags));
    println!("spike (1 at 0, else 0): eigenvalues {:.6} {:.6} {:.6}; positive definite, not continuous", sp[0], sp[1], sp[2]);
    // Herglotz: samples every quarter chip, r[k] = 1 - |k|/4, spectrum F_4(theta) on the circle.
    let r: Vec<f64> = (0..9).map(|k| tri(k as f64 / 4.0)).collect();
    let toep: Vec<Vec<f64>> = (0..9).map(|j: i32| (0..9).map(|k: i32| r[(j - k).unsigned_abs() as usize]).collect()).collect();
    let ev = eigs(&toep);
    println!("9 lags 0, 0.25, ..., 2 chips: smallest eigenvalue {:.6}, largest {:.6}; Herglotz range 0 to 4", ev[0], ev[8]);
    assert!(0.0 < ev[0] && ev[8] < 4.0);
    for &th in &[0.0, 1.0, PI / 2.0, PI] {
        println!("  theta = {:.4}: sum of r[k] e^(-ik theta) {:.6}, Fejer closed form {:.6}", th, z(f_sum(th)), z(fejer(th)));
        assert!((f_sum(th) - fejer(th)).abs() < 1e-12 && fejer(th) >= 0.0);
    }
    let coef = simpson(|th| fejer(th) * (2.0 * th).cos(), -PI, PI, 2000) / (2.0 * PI);
    println!("  coefficient back from the spectrum: r[2] = {:.6}, against 1 - 2/4 = 0.5", coef);
    assert!((coef - 0.5).abs() < 1e-9);
    // Polya: the bowl 1/(1+|t|) is a mixture of triangles of half-width s, weight w(s) = s g''(s).
    let w = |s: f64| 2.0 * s / (1.0 + s).powi(3);
    let m = 2000.0;
    let mass = simpson(w, 0.0, m, 400000);
    let exact = 1.0 - (2.0 * m + 1.0) / ((1.0 + m) * (1.0 + m));
    println!("Polya weights w(s) = 2s/(1+s)^3: mass on [0, {:.0}] {:.6}, exact 1 - (2M+1)/(1+M)^2 = {:.6}", m, mass, exact);
    assert!((mass - exact).abs() < 1e-6);
    println!("bowl spectrum: mixture of triangles  against  direct transform (cut-off 2000)  tail bound");
    for &xi in &[0.5, 1.0] {
        let mix = simpson(|s| w(s) * s * sinc(s * xi).powi(2), 0.0, m, 400000);
        let direct = 2.0 * simpson(|t| (2.0 * PI * xi * t).cos() / (1.0 + t), 0.0, m, 400000);
        let bound = 1.0 / (PI * xi * (1.0 + m));
        println!("  xi = {:.1}: {:.6}  {:.6}  {:.6}", xi, mix, direct, bound);
        assert!(mix > 0.0 && (mix - direct).abs() < bound + 1e-6);
    }
    let h: f64 = 1e-3;
    let bell2 = ((-h * h / 2.0).exp() - 2.0 + (-h * h / 2.0).exp()) / (h * h);
    let (bc, bs) = ((2.0 * PI).sqrt() * (-PI * PI / 2.0).exp(), 2.0 * simpson(|t| (-t * t / 2.0).exp() * (PI * t).cos(), 0.0, 12.0, 2000)); // tail past 12 below 1e-31
    println!("bell e^(-t^2/2): second derivative at 0 {:.4} (a dome, not a bowl), spectrum at xi = 0.5: closed form {:.6}, integral on [-12, 12] {:.6}", bell2, bc, bs);
    assert!(bell2 < 0.0 && (bs - bc).abs() < 1e-9);
    // The same triangle as a cone on a map: (1 - r)+ in two dimensions, r in km, rho in cycles per km.
    println!("cone (1 - r)+ on a map: spectrum at rho = 0 {:.6} (pi/3 = {:.6}), at rho = 1.1 {:.6}", cone(0.0), PI / 3.0, cone(1.1));
    assert!((cone(0.0) - PI / 3.0).abs() < 1e-9 && cone(1.1) < 0.0);
    // Road three: simulate the chip wave, 4 samples a chip, and measure its correlation.
    let mut rng = Mix { state: 20261115 }; // SplitMix64, seed 20261115
    let n = 50000usize;
    let mut wave: Vec<i32> = Vec::with_capacity(4 * n);
    for _ in 0..n { let c = rng.bit(); for _ in 0..4 { wave.push(c); } }
    println!("simulated chip wave, {} chips, 4 samples a chip: correlation at lag k quarter-chips / triangle", n);
    for k in 1..5usize {
        let tot: i64 = (0..4 * n - k).map(|i| (wave[i] * wave[i + k]) as i64).sum();
        let est = tot as f64 / (4 * n - k) as f64;
        let se = k as f64 / (4.0 * (n as f64).sqrt()); // k equal products per chip boundary
        println!("  k = {}: {:7.4}  {:7.4}  standard error {:.4}", k, est, tri(k as f64 / 4.0), se);
        assert!((est - tri(k as f64 / 4.0)).abs() < 4.0 * se);
    }
    // Try changing: samples every half chip; a gate half as wide; the cone further out.
    let r2: Vec<f64> = (0..9).map(|k| tri(k as f64 / 2.0)).collect();
    let t2: Vec<Vec<f64>> = (0..9).map(|j: i32| (0..9).map(|k: i32| r2[(j - k).unsigned_abs() as usize]).collect()).collect();
    let ev2 = eigs(&t2);
    println!("try: half-chip samples, 9 lags: eigenvalues {:.6} to {:.6}; Herglotz range 0 to 2", ev2[0], ev2[8]);
    let narrow = eigs(&gram(|t| if t.abs() < 0.5 { 1.0 } else { 0.0 }, &[0.0, 0.4, 0.8]))[0];
    println!("try: gate of half-width 0.5 at lags 0, 0.4, 0.8: smallest eigenvalue {:.6}; spectrum sinc(1.5) = {:.6}", narrow, sinc(1.5));
    println!("try: cone at rho = 2.1: {:.6}", cone(2.1));
    assert!(0.0 < ev2[0] && ev2[8] < 2.0 && narrow < 0.0 && cone(2.1) < 0.0);
    let figs: [(&str, fn(f64) -> f64); 2] = [("triangle", |x| sinc(x).powi(2)), ("gate", |x| 2.0 * sinc(2.0 * x))];
    for &(name, g) in figs.iter() {
        let pts: Vec<String> = (0..13).map(|k| format!("{:.2}", z(g(k as f64 / 4.0)))).collect();
        println!("figure, {:9}{}", name, pts.join(" "));
    }
    println!("ALL CHECKS PASS");
}
