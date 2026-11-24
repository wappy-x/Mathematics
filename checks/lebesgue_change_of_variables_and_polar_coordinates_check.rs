// Change of variables for Lebesgue measure -- the same check as the Python, in Rust.  No crates.
// A = [[3, 1], [0, 2]] multiplies every area by |det A| = 6: checked by the determinant, the
// corners of the image, a stretch-then-shear factorisation and exact grid counts on three sets.
// Polar coordinates: the Gaussian over the plane and over R^n, ball volumes by three roads.
use std::f64::consts::PI;

fn in_e(name: &str, u: i64, v: i64, s: i64) -> bool {   // the point (u/(2s), v/(2s)); s = 2400, or 400 for E itself
    match name {
        "square" => 0 <= u && u < 2 * s && 0 <= v && v < 2 * s,
        "disc" => (u - s) * (u - s) + (v - s) * (v - s) < s * s,   // centre (0.5, 0.5) m, radius 0.5 m
        _ => 0 <= v && v < u && u < 2 * s,                          // triangle below the diagonal y < x
    }
}
fn midpoint(f: &dyn Fn(f64) -> f64, a: f64, b: f64, steps: usize) -> f64 {
    let h = (b - a) / steps as f64;
    h * (0..steps).fold(0.0, |s, k| s + f(a + (k as f64 + 0.5) * h))
}
fn gamma_half(m: u32, root_pi: f64) -> f64 {           // Gamma(m/2) from Gamma(1), Gamma(1/2) and the recurrence
    let (mut g, mut s) = if m % 2 == 0 { (1.0, 1.0) } else { (root_pi, 0.5) };
    while s < m as f64 / 2.0 - 1e-9 { g *= s; s += 1.0; }
    g
}
struct Rng(u64);                                       // SplitMix64
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let a = [[3i64, 1], [0, 2]];
    let det = a[0][0] * a[1][1] - a[0][1] * a[1][0];
    let img: Vec<(i64, i64)> = [(0, 0), (1, 0), (1, 1), (0, 1)].iter()
        .map(|&(x, y)| (a[0][0] * x + a[0][1] * y, a[1][0] * x + a[1][1] * y)).collect();
    let shoelace = (0..4).map(|k| img[k].0 * img[(k + 1) % 4].1 - img[(k + 1) % 4].0 * img[k].1).sum::<i64>() / 2;
    println!("det A = 3 x 2 - 1 x 0 = {}; image of the unit square has corners [{}], shoelace area {}", det,
             img.iter().map(|p| format!("({}, {})", p.0, p.1)).collect::<Vec<_>>().join(", "), shoelace);
    // stretch by 3 and 2, then shear: first += second / 2; entries kept as halves (numerator over 2)
    let (s, h) = ([[6i64, 0], [0, 4]], [[2i64, 1], [0, 2]]);
    let hs: Vec<Vec<i64>> = (0..2).map(|i| (0..2).map(|j| (0..2).map(|k| h[i][k] * s[k][j]).sum::<i64>() / 4).collect()).collect();
    let factors = [s[0][0] / 2, s[1][1] / 2, (h[0][0] * h[1][1] - h[0][1] * h[1][0]) / 4];   // the two stretches, and the shear's determinant
    println!("factorisation: shear [[1, 0.5], [0, 1]] after stretch [[3, 0], [0, 2]] = [[{}, {}], [{}, {}]]; factors {} x {} x {} = {}",
             hs[0][0], hs[0][1], hs[1][0], hs[1][1], factors[0], factors[1], factors[2], factors.iter().product::<i64>());

    let names = ["square", "disc", "triangle"];
    let exact = [1.0, PI / 4.0, 0.5];
    let mut before = [0i64; 3];
    let mut after = [0i64; 3];
    for (t, n) in names.iter().enumerate() {
        for p in 0..400 { for q in 0..400 { if in_e(n, 2 * p + 1, 2 * q + 1, 400) { before[t] += 1; } } }
    }
    for i in 0..1600i64 {
        let y1 = 2 * i + 1;
        for j in 0..800i64 {
            let y2 = 2 * j + 1;
            let (u, v) = (2 * y1 - y2, 3 * y2);              // A^{-1} y in units of 1/4800 m
            for (t, n) in names.iter().enumerate() { if in_e(n, u, v, 2400) { after[t] += 1; } }
        }
    }
    println!("set E | exact m(E) | grid m(E) | grid m(AE) | 6 m(E) | grid m(AE) / exact m(E)");
    let mut ratios = Vec::new();
    for t in 0..3 {
        let (mb, ma) = (before[t] as f64 / 160000.0, after[t] as f64 / 160000.0);
        ratios.push(ma / exact[t]);
        println!("{} | {:.6} | {:.6} | {:.6} | {:.6} | {:.4}", names[t], exact[t], mb, ma, 6.0 * exact[t], ma / exact[t]);
    }
    let dens = 1.0 / det.abs() as f64;                     // the dart lands uniformly; a camera records A x, spread at density 1/|det A|
    let (p_ell, p_grid) = (det.abs() as f64 * PI / 4.0 * dens, after[1] as f64 / 160000.0 * dens);
    println!("camera records (3x + y, 2y): density 1/{} per m^2 on the parallelogram; P(recorded point in ellipse) = {:.6} x 1/{} = {:.6} (grid {:.6}); P(dart in disc) = {:.6}",
             det.abs(), det.abs() as f64 * PI / 4.0, det.abs(), p_ell, p_grid, PI / 4.0);
    println!("break, density 1 instead of 1/{}: total probability over the parallelogram = {:.0}, not 1", det.abs(), after[0] as f64 / 160000.0);

    let polar = 2.0 * PI * midpoint(&|r: f64| (-r * r).exp() * r, 0.0, 1.0, 10000);
    let cart = midpoint(&|p: f64| (-p.sin().powf(2.0)).exp() * p.cos() * 2.0 * midpoint(&|y: f64| (-y * y).exp(), 0.0, p.cos(), 1000),
                        -PI / 2.0, PI / 2.0, 1000);
    println!("unit disc, e^(-|x|^2): polar {:.6}; Cartesian slices {:.6}; pi(1 - 1/e) = {:.6}", polar, cart, PI * (1.0 - (-1.0f64).exp()));
    let no_r = 2.0 * PI * midpoint(&|r: f64| (-r * r).exp(), 0.0, 1.0, 10000);
    println!("break, polar without the factor r: {:.6}; angle run twice round: {:.6}", no_r, 2.0 * polar);
    println!("break, signed det of [[1, 3], [2, 0]] (A's columns swapped): {}; area is |-6| = 6", 1 * 0 - 3 * 2);
    println!("break, factor on the wrong side: ellipse area as disc area / 6 = {:.6}, not {:.6}", PI / 4.0 / 6.0, 6.0 * PI / 4.0);

    let root_pi = midpoint(&|x: f64| (-x * x).exp(), -10.0, 10.0, 20000);
    println!("integral of e^(-x^2) over the line = {:.9}; sqrt(pi) = {:.9}", root_pi, PI.sqrt());
    println!("n | Gaussian over R^n | radial integral | Gamma(n/2)/2 | sphere area | ball volume | pi^(n/2)/Gamma(n/2+1)");
    let mut radial = Vec::new();
    let mut by_polar = Vec::new();
    for n in [2u32, 3, 10] {
        let rad = midpoint(&|r: f64| (-r * r).exp() * r.powf((n - 1) as f64), 0.0, 12.0, 120000);
        let gauss = root_pi.powf(n as f64);
        let sphere = gauss / rad;                          // polar: integral = sphere area x radial integral
        radial.push((n, rad));
        by_polar.push((n, sphere / n as f64));
        println!("{} | {:.6} | {:.6} | {:.6} | {:.6} | {:.6} | {:.6}", n, gauss, rad, gamma_half(n, root_pi) / 2.0,
                 sphere, sphere / n as f64, root_pi.powf(n as f64) / gamma_half(n + 2, root_pi));
    }
    println!("Gamma(5/2) = {:.6}; Gamma(6) = {:.0}", gamma_half(5, root_pi), gamma_half(12, root_pi));
    let mut slab = Vec::new();                             // slicing: V_n = V_(n-1) x integral of (1 - t^2)^((n-1)/2)
    let mut vol = 2.0;
    for n in 1..13 {
        if n > 1 { vol *= midpoint(&|t: f64| (1.0 - t * t).powf((n - 1) as f64 / 2.0), -1.0, 1.0, 200000); }
        slab.push(vol);
    }
    println!("chart, n = 1 to 12, ball volume by slicing: {}", join(&slab, 4));
    let areas: Vec<f64> = slab.iter().enumerate().map(|(k, v)| (k + 1) as f64 * v).collect();
    println!("chart, n = 1 to 12, sphere area n V_n: {}", join(&areas, 4));
    println!("share of the cube [-1, 1]^n filled by the ball: n = 3 {:.4}, n = 10 {:.5}", slab[2] / 8.0, slab[9] / 1024.0);
    println!("break, R^3 without r^(n-1): sphere area x half-line integral = {:.6}, not {:.6}; sphere area 4 pi = {:.6} taken as the volume",
             4.0 * PI * root_pi / 2.0, root_pi.powf(3.0), 4.0 * PI);

    let (mut rng, n_pts) = (Rng(2026), 200000);
    let mut hits = 0i64;
    for _ in 0..n_pts {
        let x = 2.0 * rng.uniform() - 1.0;
        let y = 2.0 * rng.uniform() - 1.0;
        let z = 2.0 * rng.uniform() - 1.0;
        if x * x + y * y + z * z < 1.0 { hits += 1; }
    }
    let mc = 8.0 * hits as f64 / n_pts as f64;
    let se = 8.0 * (slab[2] / 8.0 * (1.0 - slab[2] / 8.0) / n_pts as f64).sqrt();
    println!("simulation, {} points in [-1, 1]^3: {} inside, volume {:.4}, standard error {:.4}", n_pts, hits, mc, se);
    println!("figure, 60 px per m; square (30, 190) to (90, 130); parallelogram {}; ellipse centre ({}, {})",
             img.iter().map(|p| format!("({}, {})", 130 + 60 * p.0, 190 - 60 * p.1)).collect::<Vec<_>>().join(", "), 130 + 60 * 2, 190 - 60 * 1);

    assert!(det == 6 && shoelace.abs() == det);                       // determinant against the corners
    assert!(hs == vec![vec![3, 1], vec![0, 2]]);                      // the factorisation really gives A
    assert!(factors.iter().product::<i64>() == det);                  // the step factors multiply to det A
    assert!(ratios.iter().all(|r| (r - 6.0).abs() < 0.01));           // grid counts against |det A|
    assert!((after[1] as f64 / 160000.0 - 6.0 * PI / 4.0).abs() < 0.005);
    assert!(after[0] == 160000 * det.abs());                          // the recorded point's density totals 1
    assert!((p_grid - PI / 4.0).abs() < 0.001);                       // P(ellipse) on the camera's grid = P(dart in disc)
    assert!((polar - cart).abs() < 1e-5 && (polar - PI * (1.0 - (-1.0f64).exp())).abs() < 1e-6);
    assert!((root_pi - PI.sqrt()).abs() < 1e-12);
    assert!(radial.iter().all(|&(n, r)| (r - gamma_half(n, root_pi) / 2.0).abs() < 1e-9));
    assert!(by_polar.iter().all(|&(n, v)| (v - slab[n as usize - 1]).abs() < 1e-6));   // polar road against slicing
    assert!((slab[2] - 4.0 * PI / 3.0).abs() < 1e-6 && (slab[9] - PI.powf(5.0) / 120.0).abs() < 1e-6);
    assert!((mc - slab[2]).abs() < 4.0 * se);                         // simulation against slicing
    println!("ALL CHECKS PASS");
}
