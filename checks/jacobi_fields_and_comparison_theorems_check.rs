// Jacobi fields and comparison theorems -- the same check as the Python, in
// Rust.  No crates: sin, cos, sinh, asin and sqrt from std, nothing more.
// Two aircraft leave London Heathrow on great circles, headings 290 and 291
// degrees.  Their gap is found three ways: the Jacobi field alpha R sin(s/R),
// Runge-Kutta 4 on f'' + K f = 0, and 3D positions on the sphere.  Then the
// flattened Earth (WGS 84) is trapped between two comparison spheres.
use std::f64::consts::PI;

const R: f64 = 6371.0; // km, the spherical Earth model
const A_E: f64 = 6378.137; // WGS 84 equator radius, km
const F_E: f64 = 1.0 / 298.257223563; // WGS 84 flattening

fn sn(k: f64, s: f64) -> f64 {
    // model-space gap per radian, curvature k
    if k > 0.0 {
        (k.sqrt() * s).sin() / k.sqrt()
    } else if k < 0.0 {
        ((-k).sqrt() * s).sinh() / (-k).sqrt()
    } else {
        s
    }
}

// f'' + sign K f = 0 in arc length s, stepped in a parameter u
fn rk4(al: f64, speed: &dyn Fn(f64) -> f64, curv: &dyn Fn(f64) -> f64, u_end: f64, n: usize, sign: f64) -> (f64, f64) {
    let (h, mut u, mut f, mut g, mut s) = (u_end / n as f64, 0.0, 0.0, al, 0.0);
    let rhs = |u: f64, f: f64, g: f64| -> [f64; 3] {
        let v = speed(u);
        [g * v, -sign * curv(u) * f * v, v]
    };
    for _ in 0..n {
        let k1 = rhs(u, f, g);
        let k2 = rhs(u + h / 2.0, f + h / 2.0 * k1[0], g + h / 2.0 * k1[1]);
        let k3 = rhs(u + h / 2.0, f + h / 2.0 * k2[0], g + h / 2.0 * k2[1]);
        let k4 = rhs(u + h, f + h * k3[0], g + h * k3[1]);
        f += h / 6.0 * (k1[0] + 2.0 * k2[0] + 2.0 * k3[0] + k4[0]);
        g += h / 6.0 * (k1[1] + 2.0 * k2[1] + 2.0 * k3[1] + k4[1]);
        s += h / 6.0 * (k1[2] + 2.0 * k2[2] + 2.0 * k3[2] + k4[2]);
        u += h;
    }
    (f, s)
}

// great-circle distance between the two aircraft, from 3D positions
fn gap3d(s: f64, head_deg: f64, spread: f64) -> f64 {
    let (la, lo) = (51.47f64.to_radians(), (-0.4543f64).to_radians()); // Heathrow
    let e0 = [la.cos() * lo.cos(), la.cos() * lo.sin(), la.sin()];
    let no = [-la.sin() * lo.cos(), -la.sin() * lo.sin(), la.cos()]; // due north
    let ea = [-lo.sin(), lo.cos(), 0.0]; // due east
    let mut pts = [[0.0f64; 3]; 2];
    for (j, hd) in [head_deg, head_deg + spread.to_degrees()].iter().enumerate() {
        let hr = hd.to_radians();
        for i in 0..3 {
            let t = hr.cos() * no[i] + hr.sin() * ea[i];
            pts[j][i] = (s / R).cos() * e0[i] + (s / R).sin() * t;
        }
    }
    let chord = (0..3).map(|i| (pts[0][i] - pts[1][i]).powi(2)).sum::<f64>().sqrt();
    2.0 * R * (chord / 2.0).min(1.0).asin()
}

fn main() {
    let al = 1.0f64.to_radians(); // the 1 degree spread, in radians
    let b_e = A_E * (1.0 - F_E); // polar semi-axis, km
    let k = 1.0 / (R * R);
    let (qs, half) = (PI * R / 2.0, PI * R);
    println!("Heathrow 51.47 N 0.4543 W; headings 290 and 291 deg; WGS 84 inverse flattening {:.9}", 1.0 / F_E);
    println!("spread {:.9} rad; sphere R = {:.1} km, K = 1/R^2; antipode at pi R = {:.2} km", al, R, half);
    println!("    s km | flat a s | a R sin(s/R) |  3D gap | saddle a R sinh(s/R)");
    for &s in [500.0, 1000.0, 2000.0, 5000.0, qs, 15000.0, half].iter() {
        let (jac, ex) = (al * sn(k, s), gap3d(s, 290.0, al));
        println!("{:8.1} | {:8.3} | {:12.3} | {:7.3} | {:9.3}", s, al * s, jac, ex, al * sn(-k, s));
        let trig = 2.0 * R * ((s / R).sin() * (al / 2.0).sin()).asin(); // spherical trig
        assert!((trig - ex).abs() < 1e-9); // 3D gap = exact formula
        assert!((jac - ex).abs() <= al.powi(3) * R / 40.0); // Jacobi = gap to third order
    }
    let one = |_u: f64| 1.0;
    let kon = |_u: f64| k;
    let (f5, _) = rk4(al, &one, &kon, 5000.0, 5, 1.0);
    let (f10, _) = rk4(al, &one, &kon, 5000.0, 10, 1.0);
    let (j_5, j_q) = (al * sn(k, 5000.0), al * sn(k, qs));
    println!("RK4 at 5000 km, 5 steps {:.9}, 10 steps {:.9}, closed form {:.9} km", f5, f10, j_5);
    println!("RK4 error ratio 5 -> 10 steps: {:.2} (fourth order: about 16)", (f5 - j_5) / (f10 - j_5));
    assert!((f10 - j_5).abs() < 1e-4 && 12.0 < (f5 - j_5) / (f10 - j_5) && (f5 - j_5) / (f10 - j_5) < 20.0);
    let (fpi, _) = rk4(al, &one, &kon, half, 400, 1.0);
    println!("conjugate point: RK4 gap at pi R = {:.6} km, exact 3D gap {:.6} km", fpi, gap3d(half, 290.0, al));
    assert!(fpi.abs() < 1e-6);
    let pts: Vec<f64> = (0..=10).map(|i| 2000.0 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> f64| pts.iter().map(|&s| format!("{:.1}", f(s))).collect::<Vec<_>>().join(" ");
    println!("chart, s in 1000 km: {}", (0..=10).map(|i| (2 * i).to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, plane: {}", line(&|s| al * s));
    println!("chart, sphere: {}", line(&|s| al * sn(k, s)));
    println!("chart, saddle: {}", line(&|s| al * sn(-k, s)));
    // ---- the flattened Earth: meridians from the North Pole, 1 degree of longitude apart ----
    let w = move |u: f64| A_E * A_E * u.cos().powi(2) + b_e * b_e * u.sin().powi(2);
    let spd = move |u: f64| w(u).sqrt(); // ds/du along the meridian
    let kel = move |u: f64| b_e * b_e / w(u).powi(2); // Gaussian curvature there
    let (r_hi, r_lo) = (b_e, A_E * A_E / b_e); // radii of the comparison spheres
    println!("WGS 84: a = {:.3} km, b = {:.3} km; K from 1/{:.3}^2 (pole) to 1/{:.3}^2 (equator)", A_E, b_e, r_lo, r_hi);
    let (e8, q8) = rk4(al, &spd, &kel, PI / 2.0, 8, 1.0);
    let (e16, q16) = rk4(al, &spd, &kel, PI / 2.0, 16, 1.0);
    let exact = al * A_E; // symmetry: 1 degree of longitude at the equator
    let (lo, hi) = (al * sn(1.0 / (r_hi * r_hi), q16), al * sn(1.0 / (r_lo * r_lo), q16));
    println!("pole to equator along a meridian: {:.3} km (8 steps), {:.3} km (16 steps)", q8, q16);
    println!("gap at the equator: RK4 {:.6} (8 steps), {:.6} (16 steps); symmetry alpha a = {:.6} km", e8, e16, exact);
    println!("comparison: {:.3} (sphere radius b) <= {:.3} <= {:.3} (sphere radius a^2/b) km", lo, exact, hi);
    println!("house sphere R = 6371 km at the same distance: {:.3} km", al * sn(k, q16));
    assert!((e16 - exact).abs() < 1e-4 && (e8 - exact).abs() > (e16 - exact).abs());
    assert!(lo < exact && exact < hi);
    // ---- what breaks ----
    let big = 60.0f64.to_radians();
    println!("mistake 1, flat gap at the quarter: {:.3} km, not {:.3}", al * qs, j_q);
    println!("mistake 2, sign flipped f'' - K f = 0 at the quarter: {:.3} km", rk4(al, &one, &kon, qs, 20, -1.0).0);
    println!("mistake 3, spread 60 deg at 2000 km: Jacobi {:.1} km, exact {:.1} km", big * sn(k, 2000.0), gap3d(2000.0, 290.0, big));
    println!("mistake 4, upper bound from the wrong sphere: {:.3} km, but the gap is {:.3}", lo, exact);
    println!("ALL CHECKS PASS");
}
