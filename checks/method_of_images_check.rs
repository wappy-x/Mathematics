// Method of images -- the same check as method_of_images_check.py, in Rust.  std only, no crates.
// A 1 nC charge 5 cm above a grounded metal sheet; the same charge 5 cm from the centre
// of a grounded metal sphere of radius 10 cm.  Roads: the image formulas; quadrature of
// the induced charge, the force and the Poisson integral; centred differences; a random walk.
use std::f64::consts::PI;

const EPS0: f64 = 8.8541878188e-12; // F/m, vacuum permittivity (CODATA 2022)
const Q: f64 = 1e-9; const H: f64 = 0.05; const R: f64 = 0.10; const A: f64 = 0.05; // C, m, m, m

fn kc() -> f64 { 1.0 / (4.0 * PI * EPS0) }
fn area(d: i32) -> f64 { if d == 2 { 2.0 * PI } else { 4.0 * PI } }
fn dist(p: &[f64], s: &[f64]) -> f64 { p.iter().zip(s).map(|(u, v)| (u - v) * (u - v)).sum::<f64>().sqrt() }
fn v_plane(y: &[f64]) -> f64 { kc() * Q * (1.0 / dist(y, &[0.0, 0.0, H]) - 1.0 / dist(y, &[0.0, 0.0, -H])) }
const XB: [f64; 3] = [A, 0.0, 0.0];
fn xt() -> [f64; 3] { [R * R / A, 0.0, 0.0] }
fn qt() -> f64 { -Q * R / A }
fn v_ball(y: &[f64]) -> f64 { kc() * Q / dist(y, &XB) + kc() * qt() / dist(y, &xt()) }
fn k_half(x: &[f64], y: &[f64], d: i32) -> f64 { 2.0 * x[x.len() - 1] / (area(d) * dist(x, y).powi(d)) }
fn k_ball(x: &[f64], y: &[f64], d: i32, r: f64) -> f64 { (r * r - x.iter().map(|c| c * c).sum::<f64>()) / (area(d) * r * dist(x, y).powi(d)) }

fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let w = (hi - lo) / n as f64;
    w / 3.0 * (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * w)).sum::<f64>()
}

// f(y) dA over the sheet, polar about x's foot, rho = x3 tan(th)
fn over_plane(x: [f64; 3], f: &dyn Fn(&[f64]) -> f64, top: f64) -> f64 {
    let ring = |th: f64| {
        let rho = x[2] * th.tan();
        let jac = rho * x[2] / th.cos().powi(2);
        jac * simpson(&|ph: f64| f(&[x[0] + rho * ph.cos(), x[1] + rho * ph.sin(), 0.0]), 0.0, 2.0 * PI, 200)
    };
    simpson(&ring, 0.0, top, 200)
}

fn over_sphere(f: &dyn Fn(&[f64]) -> f64) -> f64 {
    let ring = |th: f64| R * R * th.sin() * simpson(&|ph: f64| f(&[R * th.cos(), R * th.sin() * ph.cos(), R * th.sin() * ph.sin()]), 0.0, 2.0 * PI, 200);
    simpson(&ring, 0.0, PI, 200)
}

fn laplacian(v: &dyn Fn(&[f64]) -> f64, y: [f64; 3], s: f64) -> f64 {
    (0..3).map(|i| { let (mut up, mut dn) = (y, y); up[i] += s; dn[i] -= s; (v(&up) - 2.0 * v(&y) + v(&dn)) / (s * s) }).sum()
}

struct SplitMix(u64);
impl SplitMix {
    fn rnd(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (k, q, h) = (kc(), Q, H);
    let x = [0.0, 0.0, h];
    println!("Coulomb constant k = 1/(4 pi eps0) = {:.6}e9 N m^2/C^2; kq = {:.4} V m", k / 1e9, k * q);
    let mid = k * q * (1.0 / 0.025 - 1.0 / 0.075);
    println!("V halfway down, 2.5 cm: {:.2} V - {:.2} V = {:.2} V", k * q / 0.025, k * q / 0.075, mid);
    let vs = [0.0, 0.03, 0.2].iter().flat_map(|&u| [0.0, 0.07].map(|w| v_plane(&[u, w, 0.0]).abs())).fold(0.0, f64::max);
    println!("V on the sheet, 6 points out to 20 cm: {:.2} V", vs);
    assert!(vs < 1e-12);
    let (s0, s5) = (-q * k_half(&x, &[0.0, 0.0, 0.0], 3), -q * k_half(&x, &[0.05, 0.0, 0.0], 3));
    println!("induced charge density at the foot {:.2} nC/m^2, at 5 cm out {:.2} nC/m^2", s0 * 1e9, s5 * 1e9);
    assert!((s0 + q / (2.0 * PI * h * h)).abs() < 1e-15);
    let full = PI / 2.0 - 1e-9; let tot = over_plane(x, &|y| -q * k_half(&x, y, 3), full);
    println!("total induced charge on the sheet, by quadrature: {:.6} nC", tot * 1e9);
    assert!((tot + q).abs() < 1e-15);
    let half = over_plane(x, &|y| -q * k_half(&x, y, 3), PI / 3.0); // tan(60 deg) = sqrt(3)
    println!("induced charge within h*sqrt(3) = {:.2} cm: {:.3} nC", 100.0 * h * 3f64.sqrt(), half * 1e9);
    assert!((half + q / 2.0).abs() < 1e-15);
    let f_img = k * q * q / (2.0 * h).powi(2);
    let f_int = over_plane(x, &|y| -k * q * (-q * k_half(&x, y, 3)) * h / dist(&x, y).powi(3), full);
    println!("pull on the charge: image {:.4} uN, summed over the sheet {:.4} uN", f_img * 1e6, f_int * 1e6);
    assert!((f_int - f_img).abs() < 1e-6 * f_img);
    println!("work to pull the charge from 5 cm out to far away: {:.2} nJ; charge-image pair at 10 cm: {:.2} nJ", f_img * h * 1e9, k * q * q / (2.0 * h) * 1e9);
    let (xp, pp) = ([0.03, 0.0, 0.04], [0.0, 0.0, -0.05]);
    let u_p = over_plane(xp, &|y| k_half(&xp, y, 3) / dist(y, &pp), full);
    println!("Poisson integral, sheet data 1/|y-p|: {:.6} per m, exact 1/|x-p| = {:.6} per m", u_p, 1.0 / dist(&xp, &pp));
    assert!((u_p - 1.0 / dist(&xp, &pp)).abs() < 1e-6);
    let yy = [0.02, 0.01, 0.03];
    let (r1, r2) = (laplacian(&v_plane, yy, 1e-3), laplacian(&v_plane, yy, 5e-4));
    let scale = v_plane(&yy) / 0.03f64.powi(2);
    println!("Laplacian of V at (2,1,3) cm, centred differences: step 1 mm {:.1}, 0.5 mm {:.1} V/m^2; V/r^2 = {:.0} V/m^2", r1, r2, scale);
    assert!((r1 / r2 - 4.0).abs() < 0.2 && r2.abs() < 1e-3 * scale);

    println!("ball: R = 10 cm, charge at 5 cm, image point {:.1} cm, image charge {:.1} nC", 100.0 * xt()[0], qt() * 1e9);
    let mut pts: Vec<[f64; 3]> = [0.1f64, 0.9, 1.7, 2.5, 3.0].iter().flat_map(|&t| [0.0f64, 1.0, 2.0, 4.0].map(|f| [R * t.sin() * f.cos(), R * t.sin() * f.sin(), R * t.cos()])).collect();
    pts.extend([[R, 0.0, 0.0], [-R, 0.0, 0.0]]);
    let vmax = pts.iter().map(|y| v_ball(y).abs()).fold(0.0, f64::max);
    println!("max |V| at 22 points of the sphere below 1e-9 V: {}", yn(vmax < 1e-9));
    assert!(vmax < 1e-9);
    for (lab, y) in [("nearest", [R, 0.0, 0.0]), ("farthest", [-R, 0.0, 0.0])] {
        println!("  {} point: induced density {:.3} nC/m^2", lab, -q * k_ball(&XB, &y, 3, R) * 1e9);
    }
    let tb = over_sphere(&|y| -q * k_ball(&XB, y, 3, R));
    println!("total induced charge on the sphere, by quadrature: {:.6} nC", tb * 1e9);
    assert!((tb + q).abs() < 1e-14);
    let pb = [0.0, 0.25, 0.0];
    let u_b = over_sphere(&|y| k_ball(&XB, y, 3, R) / dist(y, &pb));
    println!("Poisson integral, sphere data 1/|y-p|: {:.6} per m, exact {:.6} per m", u_b, 1.0 / dist(&XB, &pb));
    assert!((u_b - 1.0 / dist(&XB, &pb)).abs() < 1e-6);
    let (b1, b2) = (laplacian(&v_ball, [0.0, 0.03, 0.02], 1e-3), laplacian(&v_ball, [0.0, 0.03, 0.02], 5e-4));
    println!("Laplacian of V inside the ball: step 1 mm {:.2}, 0.5 mm {:.2} V/m^2", b1, b2);
    assert!((b1 / b2 - 4.0).abs() < 0.2);

    println!("plane (d = 2): kernels times 2 pi against the complex-analysis card");
    let pr = |r: f64, t: f64| (1.0 - r * r) / (1.0 - 2.0 * r * t.cos() + r * r);
    let dd = (0..16).map(|i| { let t = i as f64 * 0.4; (2.0 * PI * k_ball(&[0.5, 0.0], &[t.cos(), t.sin()], 2, 1.0) - pr(0.5, t)).abs() }).fold(0.0, f64::max);
    println!("  disc r = 1/2: nearest {:.6}, farthest {:.6}; gap to P_r below 1e-12: {}",
             2.0 * PI * k_ball(&[0.5, 0.0], &[1.0, 0.0], 2, 1.0), 2.0 * PI * k_ball(&[0.5, 0.0], &[-1.0, 0.0], 2, 1.0), yn(dd < 1e-12));
    let dh = (-10..=10).map(|i| { let t = i as f64; (k_half(&[0.0, 3.0], &[t, 0.0], 2) - 3.0 / (PI * (t * t + 9.0))).abs() }).fold(0.0, f64::max);
    println!("  half-plane at 3i: gap to y/(pi((x-t)^2+y^2)) below 1e-12: {}", yn(dh < 1e-12));
    assert!(dd < 1e-12 && dh < 1e-12);

    let (mut g, n, mut near, mut mid_n) = (SplitMix(0x2026111505), 20000, 0, 0);
    for _ in 0..n {
        let (mut x, mut y, mut z) = (0.0f64, 0.0f64, h);
        while z > 1e-5 {
            let (c, ph) = (2.0 * g.rnd() - 1.0, 2.0 * PI * g.rnd());
            let sn = (1.0 - c * c).max(0.0).sqrt();
            (x, y, z) = (x + z * sn * ph.cos(), y + z * sn * ph.sin(), z + z * c);
        }
        let rr = x.hypot(y);
        near += (rr < h) as i32; mid_n += (rr < h * 3f64.sqrt()) as i32;
    }
    for (lab, cnt, ex) in [("5 cm", near, 1.0 - 1.0 / 2f64.sqrt()), ("8.66 cm", mid_n, 0.5)] {
        let se = (ex * (1.0 - ex) / n as f64).sqrt();
        let fr = cnt as f64 / n as f64;
        println!("random walk, {} walkers from the charge: within {} {} = {:.4}, kernel says {:.4} (s.e. {:.4})", n, lab, cnt, fr, ex, se);
        assert!((fr - ex).abs() < 4.0 * se);
    }

    let l = 0.10;
    let slab = |m: i64| k * q * (-m..=m).map(|j| (if j % 2 == 0 { 1.0 } else { -1.0 }) / (0.025 - (l / 2.0 + j as f64 * l)).abs()).sum::<f64>();
    let exact = 4.0 * k * q / l * (1.0 + 2f64.sqrt()).ln() / 2f64.sqrt();
    println!("two sheets 10 cm apart, V at 2.5 cm: one image {:.2} V (top sheet then at {:.2} V)", mid, k * q * (1.0 / 0.05 - 1.0 / 0.15));
    for m in [1, 10, 100, 1000] {
        println!("  images out to round {:4}: {:7.2} V, first omitted round {:.2} V", m, slab(m), (slab(m + 1) - slab(m)).abs());
    }
    println!("  full sum {:.2} V", exact);
    assert!((slab(1000) - exact).abs() < (slab(1001) - slab(1000)).abs());

    let (kap, t, y0) = (1.11e-4, 10.0, 0.05);
    let gk = |x: f64| (-x * x / (4.0 * kap * t)).exp() / (4.0 * PI * kap * t).sqrt();
    println!("heat: 1 K m spot 5 cm from the rod's end, after 10 s: free {:.4} K, end held at room temperature {:.4} K, end insulated {:.4} K",
             gk(0.0), gk(0.0) - gk(2.0 * y0), gk(0.0) + gk(2.0 * y0));
    let kept = simpson(&|x| gk(x - y0) - gk(x + y0), 0.0, 1.0, 2000);
    let (zz, mut ser, mut fact) = (y0 / (4.0 * kap * t).sqrt(), 0.0, 1.0);
    for i in 0..40 {
        if i > 0 { fact *= i as f64; }
        ser += (if i % 2 == 0 { 1.0 } else { -1.0 }) * zz.powi(2 * i + 1) / (fact * (2 * i + 1) as f64);
    }
    ser *= 2.0 / PI.sqrt();
    println!("  fraction of the heat still in the rod, end held: {:.6} by quadrature, {:.6} by the erf series", kept, ser);
    assert!((kept - ser).abs() < 1e-9);

    println!("bad images: no image V at the foot {:.2} V; same-sign image {:.2} V; source half only {:.2} nC/m^2",
             k * q / h, 2.0 * k * q / h, -q / (4.0 * PI * h * h) * 1e9);
    println!("bad images: sphere image -1 nC: nearest {:.2} V, farthest {:.2} V", k * q * (1.0 / 0.05 - 1.0 / 0.10), k * q * (1.0 / 0.15 - 1.0 / 0.30));
    let mk = 20.0 * 100.0 * h * 3f64.sqrt();
    println!("figure, 20 px per cm: charge (240, 50), image (240, 250), sheet at y = 150, sheet point (340, 150), half-charge marks x = {:.1} and {:.1}, slant {:.2} cm", 240.0 - mk, 240.0 + mk, 100.0 * dist(&[h, 0.0, 0.0], &x));
    println!("ALL CHECKS PASS");
}
