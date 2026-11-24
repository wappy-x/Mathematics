// Stress in 3D -- the same check as the Python, in Rust.  No crates.
// One point in the web of a steel footbridge girder, in plane stress:
// sigma_x = 80 MPa, sigma_y = -40 MPa, tau_xy = 30 MPa.  The principal stresses
// and the largest shear, reached three independent ways, then Hooke's law in 3D.
use std::f64::consts::PI;
const SX: f64 = 80.0; const SY: f64 = -40.0; const TXY: f64 = 30.0;   // MPa
const E: f64 = 200e3; const NU: f64 = 0.3; const SIGMA_Y: f64 = 275.0; // MPa, no unit, MPa (S275 yield)
const DEG: f64 = 180.0 / PI;
type M3 = [[f64; 3]; 3];

fn g() -> f64 { E / (2.0 * (1.0 + NU)) }       // shear modulus, MPa
fn tensor(sx: f64, sy: f64, txy: f64, sz: f64, txz: f64, tyz: f64) -> M3 {
    [[sx, txy, txz], [txy, sy, tyz], [txz, tyz, sz]]
}
fn matmul(a: &M3, b: &M3) -> M3 {
    let mut c = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { for k in 0..3 { c[i][j] += a[i][k] * b[k][j]; } } }
    c
}
fn transpose(a: &M3) -> M3 {
    let mut t = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { t[i][j] = a[j][i]; } }
    t
}
fn ident() -> M3 { [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]] }
fn rotate(t: &M3, th: f64) -> M3 {             // the same stress, read on axes turned by th about z
    let (c, s) = (th.cos(), th.sin());
    let q = [[c, s, 0.0], [-s, c, 0.0], [0.0, 0.0, 1.0]];   // rows: the new x', y', z axes
    matmul(&matmul(&q, t), &transpose(&q))
}
fn invariants(t: &M3) -> [f64; 3] {            // trace, sum of 2x2 minors, determinant
    let i1 = t[0][0] + t[1][1] + t[2][2];
    let i2 = t[0][0] * t[1][1] + t[1][1] * t[2][2] + t[2][2] * t[0][0]
        - t[0][1].powi(2) - t[1][2].powi(2) - t[0][2].powi(2);
    let i3 = t[0][0] * (t[1][1] * t[2][2] - t[1][2].powi(2)) - t[0][1] * (t[0][1] * t[2][2] - t[1][2] * t[0][2])
        + t[0][2] * (t[0][1] * t[1][2] - t[1][1] * t[0][2]);
    [i1, i2, i3]
}
fn jacobi(t: &M3) -> ([f64; 3], [[f64; 3]; 3]) { // road 3: eigenvalues of a symmetric 3x3 by plane rotations
    let (mut a, mut v) = (*t, ident());
    for _ in 0..30 {
        for &(p, q) in &[(0usize, 1usize), (0, 2), (1, 2)] {
            if a[p][q].abs() < 1e-15 { continue; }
            let phi = 0.5 * (2.0 * a[p][q]).atan2(a[q][q] - a[p][p]);
            let mut j = ident();
            j[p][p] = phi.cos(); j[q][q] = phi.cos(); j[p][q] = phi.sin(); j[q][p] = -phi.sin();
            a = matmul(&matmul(&transpose(&j), &a), &j);
            v = matmul(&v, &j);
        }
    }
    let mut order = [0usize, 1, 2];
    order.sort_by(|&x, &y| a[y][y].partial_cmp(&a[x][x]).unwrap());
    let lam = [a[order[0]][order[0]], a[order[1]][order[1]], a[order[2]][order[2]]];
    let mut vec = [[0.0; 3]; 3];
    for (n, &k) in order.iter().enumerate() { for i in 0..3 { vec[n][i] = v[i][k]; } }
    (lam, vec)
}
fn mohr(sx: f64, sy: f64, txy: f64) -> (f64, f64, f64, f64, f64) { // road 1: centre, radius, principals, angle
    let (c, r) = ((sx + sy) / 2.0, ((sx - sy) / 2.0).hypot(txy));
    (c, r, c + r, c - r, 0.5 * (2.0 * txy).atan2(sx - sy))
}
fn hooke(t: &M3) -> [f64; 6] {                 // generalised Hooke's law, gamma = engineering shear
    let (sx, sy, sz) = (t[0][0], t[1][1], t[2][2]);
    [(sx - NU * (sy + sz)) / E, (sy - NU * (sz + sx)) / E, (sz - NU * (sx + sy)) / E, t[0][1] / g(), t[1][2] / g(), t[0][2] / g()]
}
fn z(v: f64) -> f64 { if v.abs() < 1e-9 { 0.0 } else { v } } // a rounding speck prints as 0.00
fn fmt(t: &M3) -> String {
    let rows: Vec<String> = t.iter().map(|r| format!("[{:.2}, {:.2}, {:.2}]", z(r[0]), z(r[1]), z(r[2]))).collect();
    format!("[{}]", rows.join(", "))
}
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", z(*x))).collect::<Vec<_>>().join(", ") }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let s = tensor(SX, SY, TXY, 0.0, 0.0, 0.0);
    let (c, r, s1, s2, thp) = mohr(SX, SY, TXY);
    println!("web point: sigma_x = {:.2} MPa, sigma_y = {:.2} MPa, tau_xy = {:.2} MPa, sigma_z = 0 (plane stress)", SX, SY, TXY);
    println!("stress tensor, MPa: {}", fmt(&s));
    println!("road 1, Mohr's circle: centre {:.2} MPa, radius sqrt({:.2}^2 + {:.2}^2) = {:.4} MPa", c, (SX - SY) / 2.0, TXY, r);
    println!("road 1: C + R = {:.2} MPa, C - R = {:.2} MPa, theta_p = {:.2} deg = {:.4} rad, tan 2theta_p = {:.2}",
        s1, s2, thp * DEG, thp, (2.0 * thp).tan());
    let (mut hi, mut lo, mut thi, mut tlo, mut worst) = ((-1e9, 0), (1e9, 0), (-1e9, 0), (1e9, 0), 0.0f64);
    for k in 0..18000 {                        // road 2: turn the axes in 0.01 deg steps, 0 to 180 deg
        let t = rotate(&s, k as f64 * 0.01 / DEG);
        if t[0][0] > hi.0 { hi = (t[0][0], k); }
        if t[0][0] < lo.0 { lo = (t[0][0], k); }
        if t[0][1] > thi.0 { thi = (t[0][1], k); }
        if t[0][1] < tlo.0 { tlo = (t[0][1], k); }
        worst = worst.max(((t[0][0] - c).hypot(t[0][1]) - r).abs()); // Mohr: every turn lands on the circle
    }
    println!("road 2, axes turned in 0.01 deg steps: largest normal {:.2} MPa at {:.2} deg, smallest {:.2} MPa at {:.2} deg",
        hi.0, hi.1 as f64 / 100.0, lo.0, lo.1 as f64 / 100.0);
    println!("road 2: shear peaks {:.2} MPa at {:.2} deg and {:.2} MPa at {:.2} deg; normal there {:.2} MPa",
        tlo.0, tlo.1 as f64 / 100.0, thi.0, thi.1 as f64 / 100.0, rotate(&s, thp + PI / 4.0)[0][0]);
    println!("road 2: every turned point on the circle, worst miss under 1e-9 MPa: {}", yn(worst < 1e-9));
    let (lam, vec) = jacobi(&s);
    println!("road 3, Jacobi on the 3x3 tensor: eigenvalues {:.2}, {:.2}, {:.2} MPa; sigma_1 axis ({:.4}, {:.4}, {:.4}) at {:.2} deg",
        lam[0], lam[1], lam[2], vec[0][0], vec[0][1], vec[0][2], vec[0][1].atan2(vec[0][0]) * DEG);
    assert!((hi.0 - s1).abs() < 1e-6 && (lo.0 - s2).abs() < 1e-6 && hi.1 == (thp * DEG * 100.0).round() as i32);
    assert!((lam[0] - s1).abs() < 1e-9 && (lam[2] - s2).abs() < 1e-9 && lam[1].abs() < 1e-9);
    assert!((thi.0 - r).abs() < 1e-6 && worst < 1e-9);
    let tau_max = (lam[0] - lam[2]) / 2.0;
    println!("largest shear in 3D, (sigma_max - sigma_min) / 2 = {:.2} MPa, on planes 45 deg from the principal axes", tau_max);
    let tp = rotate(&s, thp);
    println!("tensor on the principal axes, MPa: {}", fmt(&tp));
    let (inv0, inv1) = (invariants(&s), invariants(&rotate(&s, 0.7)));
    println!("invariants I1, I2, I3 before turning: {}; after turning 0.7 rad: {}", join(&inv0), join(&inv1));
    assert!((0..3).map(|i| (inv0[i] - inv1[i]).abs()).fold(0.0, f64::max) < 1e-9 && tp[0][1].abs() < 1e-9);
    let cubic = lam.iter().map(|x| (x.powi(3) - inv0[0] * x * x + inv0[1] * x - inv0[2]).abs()).fold(0.0, f64::max);
    println!("eigenvalues solve lambda^3 - I1 lambda^2 + I2 lambda - I3 = 0 to 1e-6: {}", yn(cubic < 1e-6));
    assert!(cubic < 1e-6);
    let [ex, ey, ez, gxy, gyz, gxz] = hooke(&s);
    println!("Hooke: E = {:.0} GPa, nu = {:.2}, G = E / (2(1 + nu)) = {:.2} GPa", E / 1e3, NU, g() / 1e3);
    println!("strains, microstrain: eps_x = {:.2}, eps_y = {:.2}, eps_z = {:.2}, gamma_xy = {:.2}, gamma_yz = {:.2}, gamma_xz = {:.2}",
        ex * 1e6, ey * 1e6, ez * 1e6, gxy * 1e6, gyz * 1e6, gxz * 1e6);
    let (ce, re, e1, e2, the) = mohr(ex * 1e6, ey * 1e6, gxy * 1e6 / 2.0);
    println!("strain circle, microstrain: centre {:.2}, half-difference {:.2}, gamma_xy/2 {:.2}, radius {:.2}",
        ce, (ex - ey) * 1e6 / 2.0, gxy * 1e6 / 2.0, re);
    println!("principal strains {:.2} and {:.2} microstrain at {:.2} deg: the same axes as the stresses", e1, e2, the * DEG);
    let lame = E * NU / ((1.0 + NU) * (1.0 - 2.0 * NU));
    let back = [lame * (ex + ey + ez) + 2.0 * g() * ex, lame * (ex + ey + ez) + 2.0 * g() * ey,
        lame * (ex + ey + ez) + 2.0 * g() * ez, g() * gxy];
    println!("back from strain to stress, inverse Hooke: {} MPa", join(&back));
    let want = [SX, SY, 0.0, TXY];
    assert!((the - thp).abs() < 1e-12 && (0..4).map(|i| (back[i] - want[i]).abs()).fold(0.0, f64::max) < 1e-9);
    println!("chart, theta deg  {}", (0..13).map(|k| format!("{:7}", 15 * k)).collect::<Vec<_>>().join(" "));
    println!("chart, sigma_x'   {}", (0..13).map(|k| format!("{:7.2}", rotate(&s, 15.0 * k as f64 / DEG)[0][0])).collect::<Vec<_>>().join(" "));
    println!("chart, tau_x'y'   {}", (0..13).map(|k| format!("{:7.2}", rotate(&s, 15.0 * k as f64 / DEG)[0][1])).collect::<Vec<_>>().join(" "));
    let w = rotate(&s, 2.0 * thp);
    println!("wrong: biggest entry read as sigma_1 = {:.2} MPa (true {:.2}), tau_xy as largest shear {:.2} MPa (true {:.2})",
        SX.max(SY), s1, TXY, tau_max);
    println!("wrong: axes turned by 2theta_p = {:.2} deg: sigma_x' = {:.2} MPa, tau = {:.2} MPa", 2.0 * thp * DEG, w[0][0], w[0][1]);
    let (_, rs, a1, a2, _) = mohr(80.0, 40.0, 30.0);
    println!("wrong: sigma_y = +40 MPa, in-plane shear {:.2} MPa, but principal {:.2}, {:.2}, 0.00 give {:.2} MPa out of plane",
        rs, a1, a2, a1 / 2.0);
    println!("wrong: one-way Hooke, eps_x = sigma_x / E = {:.2} microstrain (true {:.2}, {:.0}% low), eps_y {:.2} (true {:.2}), eps_z {:.2} (true {:.2})",
        SX / E * 1e6, ex * 1e6, 100.0 * (1.0 - SX / E / ex), SY / E * 1e6, ey * 1e6, s[2][2] / E * 1e6, ez * 1e6);
    assert!((w[0][0] - SX).abs() < 1e-9 && a1 / 2.0 > rs && SX / E < ex);
    let s4 = mohr(4.0 * SX, 4.0 * SY, 4.0 * TXY).2;
    let vm1 = (((lam[0] - lam[1]).powi(2) + (lam[1] - lam[2]).powi(2) + (lam[2] - lam[0]).powi(2)) / 2.0).sqrt(); // von Mises, card 11
    assert!((vm1 - (SX * SX - SX * SY + SY * SY + 3.0 * TXY * TXY).sqrt()).abs() < 1e-9);
    println!("outside the model: load x4, stresses {:.2}, {:.2}, {:.2} MPa: sigma_1 = {:.2} MPa, but von Mises {:.2} MPa > {:.0} MPa yield",
        4.0 * SX, 4.0 * SY, 4.0 * TXY, s4, 4.0 * vm1, SIGMA_Y);
    println!("outside the model: first yield at x{:.2} the load (Tresca x{:.2}); past that neither the scaled stresses nor Hooke's eps_x = {:.2} microstrain are real",
        SIGMA_Y / vm1, SIGMA_Y / (2.0 * tau_max), 4.0 * ex * 1e6);
    let (_, _, b1, b2, bth) = mohr(SX, SX, TXY);
    let (l3, _) = jacobi(&tensor(SX, SY, TXY, 0.0, 20.0, 0.0));
    println!("try: tau_xy = 0 gives {:.2}, {:.2} MPa, largest shear {:.2} MPa; sigma_y = 80 gives {:.2}, {:.2} MPa at {:.2} deg, largest shear {:.2} MPa",
        SX, SY, (SX - SY) / 2.0, b1, b2, bth * DEG, b1 / 2.0);
    println!("try: tau_xz = 20 MPa gives {} MPa, largest shear {:.2} MPa; nu = 0 gives eps_x = {:.2} microstrain",
        join(&l3), (l3[0] - l3[2]) / 2.0, SX / E * 1e6);
    let px = |v: f64| 240.0 + 3.0 * v;         // figure: 3 px per MPa, tau drawn positive downward
    let py = |t: f64| 250.0 + 3.0 * t;
    println!("figure, 3 px/MPa: centre ({:.1}, {:.1}), radius {:.1}, X ({:.1}, {:.1}), Y ({:.1}, {:.1})",
        px(c), py(0.0), 3.0 * r, px(SX), py(TXY), px(SY), py(-TXY));
    println!("figure: sigma_1 ({:.1}, 250.0), sigma_3 ({:.1}, 250.0), origin = sigma_2 ({:.1}, 250.0), top ({:.1}, {:.1}), bottom ({:.1}, {:.1}), small circles radius {:.1} and {:.1}",
        px(s1), px(s2), px(0.0), px(c), py(-r), px(c), py(r), 3.0 * s1 / 2.0, -3.0 * s2 / 2.0);
    println!("ALL CHECKS PASS");
}
