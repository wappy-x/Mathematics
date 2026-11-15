// Fundamental solution of a rail on a ballast bed: EI w'''' + k w = load.
// std only.  Roads: the closed form G; the probe test (LG)(phi) = phi(0);
// the identity k * (integral of G) = 1; and a rail of N grid nodes solved
// by banded elimination, which never mentions G.
use std::f64::consts::PI;

const EI: f64 = 210e9 * 3055e-8; // N m^2: steel rail, I = 3055 cm^4 (illustrative)
const K: f64 = 40e6; // N/m per m of rail: the ballast bed (illustrative)
const P: f64 = 100e3; // N: one wheel (illustrative)
const D: f64 = 1.8; // m: spacing of the two wheels of a bogie
const MM: f64 = 1000.0;

fn beta() -> f64 { (K / (4.0 * EI)).powf(0.25) }

// sag at x, in m, from a 1 N spike at 0
fn g(x: f64) -> f64 {
    let b = beta();
    let y = b * x.abs();
    b / (2.0 * K) * (-y).exp() * (y.cos() + y.sin())
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let hh = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * hh);
    }
    s * hh / 3.0
}

struct Rail { w: Vec<f64>, length: f64, h: f64 }

impl Rail {
    fn at(&self, x: f64) -> f64 { self.w[((x + self.length / 2.0) / self.h).round() as usize - 1] }
}

// Rail from -length/2 to length/2, ends pinned (w = w'' = 0).
// A load (x, F) is a spike F/h on one node.
fn rail(eig: f64, kg: f64, length: f64, h: f64, loads: &[(f64, f64)]) -> Rail {
    let n = (length / h).round() as usize - 1;
    let mut a = vec![vec![0.0f64; n]; n];
    let mut b = vec![0.0f64; n];
    let c = eig / h.powi(4);
    for i in 0..n {
        for (off, v) in [1.0, -4.0, 6.0, -4.0, 1.0].iter().enumerate() {
            let j = i as i64 - 2 + off as i64;
            if j >= 0 && (j as usize) < n {
                a[i][j as usize] += c * v;
            }
        }
        a[i][i] += kg;
    }
    a[0][0] -= c; // ghost node beyond a pinned end: w = -w(mirror)
    a[n - 1][n - 1] -= c;
    for &(x, f) in loads {
        b[((x + length / 2.0) / h).round() as usize - 1] += f / h;
    }
    for i in 0..n {
        // elimination inside the band, no pivoting
        for r in i + 1..(i + 3).min(n) {
            let m = a[r][i] / a[i][i];
            for j in i..(i + 3).min(n) {
                a[r][j] -= m * a[i][j];
            }
            b[r] -= m * b[i];
        }
    }
    let mut w = vec![0.0f64; n];
    for i in (0..n).rev() {
        let mut s = b[i];
        for j in i + 1..(i + 3).min(n) {
            s -= a[i][j] * w[j];
        }
        w[i] = s / a[i][i];
    }
    Rail { w, length, h }
}

// (LG)(phi) for the probe phi = exp(-((x - c)/a)^2), times scale
fn probe(c: f64, a: f64, scale: f64) -> f64 {
    let lphi = move |x: f64| {
        let u = (x - c) / a;
        let e = (-u * u).exp();
        EI * (16.0 * u.powi(4) - 48.0 * u * u + 12.0) / a.powi(4) * e + K * e
    };
    simpson(&|x| scale * g(x) * lphi(x), -12.0, 12.0, 4800)
}

fn main() {
    let beta = beta();
    println!("rail: EI = {:.4} MN m^2, bed k = {:.1} MN/m^2, wheel P = {:.0} kN", EI / 1e6, K / 1e6, P / 1e3);
    println!("beta = (k/(4 EI))^(1/4) = ({:.6})^(1/4) = {:.6} per m; decay length 1/beta = {:.4} m", K / (4.0 * EI), beta, 1.0 / beta);
    println!("sag under the wheel P beta/(2k) = {:.4} mm", P * g(0.0) * MM);
    println!("first lift-off at x = 3 pi/(4 beta) = {:.4} m; greatest lift {:.4} mm at x = pi/beta = {:.4} m",
        3.0 * PI / (4.0 * beta), -P * g(PI / beta) * MM, PI / beta);
    println!("bending moment under the wheel P/(4 beta) = {:.4} kN m", P / (4.0 * beta) / 1e3);

    // road 2: the probe test
    for c in [0.0, 0.5] {
        let (got, want) = (probe(c, 0.5, 1.0), (-(c / 0.5f64).powi(2)).exp());
        println!("probe width 0.5 m centred at {:.1} m: (LG)(phi) = {:.8}, phi(0) = {:.8}", c, got, want);
        assert!((got - want).abs() < 1e-7);
    }
    // road 3: k * (integral of G) = 1
    let area = K * simpson(&g, -20.0, 20.0, 8000);
    println!("k * integral of G = {:.8}", area);
    assert!((area - 1.0).abs() < 1e-8);

    // road 4: a rail of grid nodes
    println!("h (m)   nodes  sag at wheel (mm)  error vs P G(0) (mm)  error ratio");
    let mut prev: Option<f64> = None;
    let mut s = 0.0;
    for h in [0.4, 0.2, 0.1, 0.05] {
        s = rail(EI, K, 20.0, h, &[(0.0, P)]).at(0.0) * MM;
        let err = s - P * g(0.0) * MM;
        let ratio = prev.map_or("-".to_string(), |p| format!("{:.4}", p / err));
        let nodes = (20.0 / h).round() as usize - 1;
        println!("{:<7} {:<6} {:.6}           {:+.6}             {}", h, nodes, s, err, ratio);
        prev = Some(err);
    }
    assert!((s - P * g(0.0) * MM).abs() < 2e-3);
    let w20 = rail(EI, K, 20.0, 0.05, &[(0.0, P)]);
    let w40 = rail(EI, K, 40.0, 0.05, &[(0.0, P)]);
    println!("rail 20 m against 40 m, h = 0.05: sag at wheel {:.6} vs {:.6} mm", w20.at(0.0) * MM, w40.at(0.0) * MM);
    let xs: Vec<f64> = (0..11).map(|i| 0.5 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64, p: usize| xs.iter().map(|&x| format!("{:6.*}", p, f(x))).collect::<Vec<_>>().join(" ");
    println!("x (m)        {}", row(&|x| x, 1));
    println!("P G(x) (mm)  {}", row(&|x| P * g(x) * MM, 3));
    println!("grid (mm)    {}", row(&|x| w20.at(x) * MM, 3));
    println!("bogie (mm)   {}", row(&|x| P * (g(x) + g(x - D)) * MM, 3));
    for &x in &xs { assert!((w20.at(x) - P * g(x)).abs() < 5e-6); }

    // any load: a bogie
    let two = P * (g(0.0) + g(D));
    let g2 = rail(EI, K, 20.0, 0.05, &[(0.0, P), (D, P)]);
    println!("bogie, wheels {} m apart: sag under each wheel {:.4} mm, grid {:.4} mm", D, two * MM, g2.at(0.0) * MM);
    let bd = beta * D;
    println!("  beta d = {:.4}, e^(-beta d) = {:.4}, cos + sin = {:.4}, cos - sin = {:.4}",
        bd, (-bd).exp(), bd.cos() + bd.sin(), bd.cos() - bd.sin());
    println!("  the neighbour adds P G({}) = {:.4} mm", D, P * g(D) * MM);
    let mom = P / (4.0 * beta) * (1.0 + (-beta * D).exp() * ((beta * D).cos() - (beta * D).sin()));
    println!("  bending moment under each wheel {:.4} kN m", mom / 1e3);
    assert!((g2.at(0.0) - two).abs() < 5e-6);

    // what breaks
    println!("mistake 1, no ballast (k = 0): sag at the middle, h = 0.1");
    for length in [10, 20, 40] {
        let l = length as f64;
        let s = rail(EI, 0.0, l, 0.1, &[(0.0, P)]).at(0.0);
        let want = P * l.powi(3) / (48.0 * EI);
        println!("  rail {} m: {:.4} m (beam on two supports, no bed: {:.4} m)", length, s, want);
        assert!((s / want - 1.0).abs() < 1e-3);
    }
    println!("mistake 2, no bending stiffness (EI = 0): sag at the wheel = P/(k h)");
    for h in [0.1, 0.05, 0.025] {
        let s = rail(0.0, K, 4.0, h, &[(0.0, P)]).at(0.0);
        println!("  h = {}: {:.1} mm", h, s * MM);
        assert!((s - P / (K * h)).abs() < 1e-12);
    }
    println!("mistake 3, no halving, P beta/k: {:.4} mm; probe gives {:.6}", 2.0 * P * g(0.0) * MM, probe(0.0, 0.5, 2.0));
    println!("mistake 4, two wheels' peaks added: {:.4} mm, not {:.4}", 2.0 * P * g(0.0) * MM, two * MM);
    // try changing: one setting at a time
    for (name, eit, kt) in [("bed k = 80 MN/m^2", EI, 80e6), ("bed k = 20 MN/m^2", EI, 20e6), ("rail EI doubled", 2.0 * EI, K)] {
        let bt = (kt / (4.0 * eit)).powf(0.25);
        println!("try {}: sag {:.4} mm, decay length {:.4} m", name, P * bt / (2.0 * kt) * MM, 1.0 / bt);
    }
    println!("try wheels 1.5 m apart: sag under each wheel {:.4} mm", P * (g(0.0) + g(1.5)) * MM);
    println!("try a probe of width 0.1 m: (LG)(phi) = {:.6}", probe(0.0, 0.1, 1.0));
    println!("ALL CHECKS PASS");
}
