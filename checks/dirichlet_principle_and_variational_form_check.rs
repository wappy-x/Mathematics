// Dirichlet's principle -- the check behind the card.  Rust std only, no crates.
// A soap film spans a circular wire loop of radius R = 5 cm whose rim is bent to
// the height g = a cos(2 theta), a = 1 cm.  Lengths in cm, energies in cm^2.
use std::f64::consts::PI;
const R: f64 = 5.0;
const A: f64 = 1.0;

fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let w = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for k in 1..n {
        s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(lo + k as f64 * w);
    }
    s * w / 3.0
}
// integral of f(x, y) over the disc, in polar form
fn disc(f: &dyn Fn(f64, f64) -> f64, n: usize) -> f64 {
    simpson(&|r| r * simpson(&|t| f(r * t.cos(), r * t.sin()), 0.0, 2.0 * PI, n), 0.0, R, n)
}
// Dirichlet energy E = 1/2 * integral of |grad w|^2
fn energy(g: &dyn Fn(f64, f64) -> (f64, f64)) -> f64 {
    0.5 * disc(&|x, y| { let (p, q) = g(x, y); p * p + q * q }, 120)
}
fn u(x: f64, y: f64) -> f64 { A * (x * x - y * y) / R.powf(2.0) }  // the harmonic film
fn gu(x: f64, y: f64) -> (f64, f64) { (2.0 * A * x / R.powf(2.0), -2.0 * A * y / R.powf(2.0)) }
fn w(x: f64, y: f64) -> f64 { A * (x.powf(4.0) - y.powf(4.0)) / R.powf(4.0) } // a rival, same rim
fn gw(x: f64, y: f64) -> (f64, f64) { (4.0 * A * x.powf(3.0) / R.powf(4.0), -4.0 * A * y.powf(3.0) / R.powf(4.0)) }
fn gv(x: f64, y: f64) -> (f64, f64) { let (a, b) = gw(x, y); let (c, d) = gu(x, y); (a - c, b - d) }
fn emix(e: f64) -> f64 { energy(&|x, y| { let (a, b) = gu(x, y); let (c, d) = gv(x, y); (a + e * c, b + e * d) }) }
fn lap(f: fn(f64, f64) -> f64, x: f64, y: f64, s: f64) -> f64 {
    (f(x + s, y) + f(x - s, y) + f(x, y + s) + f(x, y - s) - 4.0 * f(x, y)) / (s * s)
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }

// direct method: lower a grid energy one node at a time
fn direct(n: usize) -> (f64, f64, bool, usize) {
    let (m, ht) = (2 * n, PI / n as f64);
    let mut wg = vec![vec![0.0f64; m]; n + 1];
    for j in 0..m { wg[n][j] = A * (2.0 * j as f64 * ht).cos(); }
    let rad: Vec<f64> = (0..n).map(|i| (i as f64 + 0.5) * ht).collect();
    let mut ang = vec![0.0f64; n + 1];
    for i in 1..n { ang[i] = 1.0 / (i as f64 * ht); }
    ang[n] = 0.5 / (n as f64 * ht);
    let en = |wg: &Vec<Vec<f64>>| -> f64 {
        let mut s = 0.0;
        for i in 0..n { for j in 0..m {
            let lo = wg[i][if i == 0 { 0 } else { j }];
            s += rad[i] * (wg[i + 1][j] - lo).powf(2.0);
        } }
        for i in 1..=n { for j in 0..m { s += ang[i] * (wg[i][(j + 1) % m] - wg[i][j]).powf(2.0); } }
        0.5 * s
    };
    let om = 2.0 / (1.0 + (PI / n as f64).sin());
    let mut hist = vec![en(&wg)];
    let mut sweep = 0;
    for sw in 1..=5000 {
        sweep = sw;
        let mut c = 0.0;
        for j in 0..m { c += wg[1][j]; }
        let mut big = (om * (c / m as f64 - wg[0][0])).abs();
        let c0 = wg[0][0] + om * (c / m as f64 - wg[0][0]);
        for j in 0..m { wg[0][j] = c0; }
        for i in 1..n { for j in 0..m {
            let jm = (j + m - 1) % m;
            let nb = rad[i - 1] * wg[i - 1][if i == 1 { 0 } else { j }] + rad[i] * wg[i + 1][j]
                + ang[i] * (wg[i][jm] + wg[i][(j + 1) % m]);
            let step = om * (nb / (rad[i - 1] + rad[i] + 2.0 * ang[i]) - wg[i][j]);
            wg[i][j] += step;
            big = big.max(step.abs());
        } }
        hist.push(en(&wg));
        if big < 1e-13 { break; }
    }
    let falls = (0..hist.len() - 1).all(|k| hist[k + 1] <= hist[k] + 1e-12);
    (hist[hist.len() - 1], wg[n / 2][0], falls, sweep)
}

fn main() {
    let row = |f: &dyn Fn(f64) -> f64| (-5..=5).map(|k| format!("{:.2}", f(R * k as f64 / 5.0))).collect::<Vec<_>>().join(", ");
    println!("film height along y = 0, x = -R..R in 11 steps: {} cm", row(&|x| u(x, 0.0)));
    println!("film height along x = 0, y = -R..R in 11 steps: {} cm", row(&|y| u(0.0, y)));
    let (eu, ew, ev) = (energy(&gu), energy(&gw), energy(&gv));
    println!("E(u), harmonic film: quadrature {:.6}, exact pi a^2 = {:.6} cm^2", eu, PI * A * A);
    println!("E(w), rival film:    quadrature {:.6}, exact 5 pi a^2/4 = {:.6} cm^2", ew, 5.0 * PI * A * A / 4.0);
    println!("gap E(w) - E(u) = {:.6}, E(w - u) = {:.6}, exact pi a^2/4 = {:.6} cm^2", ew - eu, ev, PI * A * A / 4.0);
    assert!((eu - PI * A * A).abs() < 1e-6 && (ew - 5.0 * PI * A * A / 4.0).abs() < 1e-6);
    assert!(((ew - eu) - ev).abs() < 1e-6);                 // Pythagoras: two separate integrals agree
    let es = [-1.0, -0.5, 0.0, 0.5, 1.0];
    let fam: Vec<f64> = es.iter().map(|&e| emix(e)).collect();
    println!("E(u + e v), e = -1, -0.5, 0, 0.5, 1: {} cm^2", fam.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(", "));
    for (e, v) in es.iter().zip(fam.iter()) { assert!((v - PI * A * A * (1.0 + e * e / 4.0)).abs() < 1e-6); }
    let h = 1e-4;                                           // first variation: nudge both ways, then by parts
    let dq_u = (emix(h) - emix(-h)) / (2.0 * h);
    let dq_w = (emix(1.0 + h) - emix(1.0 - h)) / (2.0 * h);
    let ibp_w = disc(&|x, y| -(w(x, y) - u(x, y)) * 12.0 * A * (x * x - y * y) / R.powf(4.0), 120);
    println!("first variation along v at u: quotient {:.6} cm^2", dq_u.abs());
    println!("first variation along v at w: quotient {:.6}, minus integral of v times Laplacian(w) {:.6}, exact pi a^2/2 = {:.6} cm^2", dq_w, ibp_w, PI * A * A / 2.0);
    assert!(dq_u.abs() < 1e-6 && (dq_w - PI * A * A / 2.0).abs() < 1e-5 && (ibp_w - PI * A * A / 2.0).abs() < 1e-6);
    for s in [0.2, 0.1] {
        println!("Laplacian by centred differences at (3, 1) cm, step {:.1} cm: u {:.6}, w {:.6} per cm", s, lap(u, 3.0, 1.0, s).abs(), lap(w, 3.0, 1.0, s));
    }
    assert!(lap(u, 3.0, 1.0, 0.1).abs() < 1e-9 && (lap(w, 3.0, 1.0, 0.1) - 96.0 * A / R.powf(4.0)).abs() < 1e-6);

    let (mut errs, mut herrs) = (vec![], vec![]);
    for n in [8usize, 16, 32] {
        let (en, mid, falls, sw) = direct(n);
        errs.push(en - PI * A * A); herrs.push(mid - A / 4.0);
        println!("grid of {} rings x {} angles: energy {:.6} cm^2 (error {:.6}), height at ({:.1}, 0) {:.6} cm, {} sweeps, energy fell every sweep: {}", n, 2 * n, en, en - PI * A * A, R / 2.0, mid, sw, tf(falls));
        assert!(falls);
    }
    println!("exact height at ({:.1}, 0) {:.2} cm; observed order, energy: {:.3}, {:.3}; height: {:.3}, {:.3}", R / 2.0, u(R / 2.0, 0.0), (errs[0] / errs[1]).log2(), (errs[1] / errs[2]).log2(), (herrs[0] / herrs[1]).log2(), (herrs[1] / herrs[2]).log2());
    let o = (errs[1] / errs[2]).log2();
    assert!(errs[2].abs() < 0.005 * A * A && herrs[2].abs() < 0.001 * A && 1.9 < o && o < 2.1);

    let c = A / (R * R);                                    // the real area of the harmonic film
    let area_q = disc(&|x, y| { let (p, q) = gu(x, y); (1.0 + p * p + q * q).sqrt() }, 120);
    let area_x = 2.0 * PI / (12.0 * c * c) * ((1.0 + 4.0 * c * c * R * R).powf(1.5) - 1.0);
    let flat = PI * R * R;
    println!("steepest slope of the film {:.2}; area: quadrature {:.6}, exact {:.6}, flat disc {:.6} cm^2", 2.0 * c * R, area_q, area_x, flat);
    println!("extra area: true {:.4} cm^2, small-slope model E(u) = {:.4} cm^2, model high by {:.2} %", area_x - flat, eu, 100.0 * (eu / (area_x - flat) - 1.0));
    println!("film energy at 0.025 N/m per face (illustrative), two faces: true {:.2} uJ, model {:.2} uJ", 2.0 * 0.025 * (area_x - flat) * 100.0, 2.0 * 0.025 * eu * 100.0);
    assert!((area_q - area_x).abs() < 1e-6);

    // What breaks 1 (Hadamard 1906): rim g = sum 1/n^2 cos(n! theta) cm, energy (pi/2) sum n!/n^4 cm^2
    let (mut part, mut fact, mut sums) = (0.0f64, 1.0f64, vec![]);
    for n in 1..=10 {
        fact *= n as f64;
        part += fact / (n * n * n * n) as f64;
        sums.push(PI / 2.0 * part);
    }
    println!("Hadamard rim: height at most pi^2/6 = {:.3} cm; energy with the first N terms, N = 1..10: {} cm^2", PI * PI / 6.0, sums.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(", "));
    let hgrad2 = |r: f64, t: f64| -> f64 {               // |grad|^2 of modes 1, 2 and 6
        let (mut gr, mut gt) = (0.0, 0.0);
        for (n, k) in [(1.0, 1.0f64), (2.0, 2.0), (3.0, 6.0)] {
            gr += k / (n * n) * (r / R).powf(k - 1.0) / R * (k * t).cos();
            gt -= k / (n * n) * (r / R).powf(k - 1.0) / R * (k * t).sin();
        }
        gr * gr + gt * gt
    };
    let e3 = 0.5 * simpson(&|r| r * simpson(&|t| hgrad2(r, t), 0.0, 2.0 * PI, 240), 0.0, R, 240);
    println!("Hadamard rim, first three terms by quadrature: {:.6} cm^2, by the series: {:.6} cm^2", e3, sums[2]);
    assert!((e3 - sums[2]).abs() < 1e-6 && sums[9] - sums[8] > sums[8] - sums[7] && sums[8] - sums[7] > 10.0);

    // What breaks 2 (Weierstrass 1870): J[y] = integral over [-1, 1] of x^2 y'^2, y(-1) = -1, y(1) = 1
    for e in [0.1f64, 0.01, 0.001] {
        let a = (1.0 / e).atan();
        let closed = e / a - e * e / ((1.0 + e * e) * a * a);
        let quad = simpson(&|x| x * x * (e / (e * e + x * x) / a).powf(2.0), -1.0, 1.0, 100000);
        println!("Weierstrass ramp, width {}: J = {:.6} (closed form), {:.6} (Simpson)", e, closed, quad);
        assert!((closed - quad).abs() < 1e-6);
    }
    println!("ALL CHECKS PASS");
}
