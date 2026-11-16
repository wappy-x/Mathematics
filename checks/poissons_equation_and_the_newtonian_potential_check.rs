// Poisson's equation -Laplacian(V) = rho/eps0 for a uranium-238 nucleus, modelled as a
// uniformly charged ball.  std only.  Distances in fm, potentials in MV, energies in MeV.
// Roads: (1) the closed form from Newton's shell theorem; (2) the convolution integral
// done along lines of sight from the field point (Simpson's rule); (3) the convolution
// as a sum over small cubes, each a point charge; (4) the equation's residual.
use std::f64::consts::PI;

struct Ball { r: f64, vr: f64, s: f64 }

impl Ball {
    fn v(&self, r: f64) -> f64 { // road 1: closed form
        if r < self.r { self.vr * (3.0 - r * r / (self.r * self.r)) / 2.0 } else { self.vr * self.r / r }
    }
    fn v3(&self, x: f64, y: f64, z: f64) -> f64 { self.v((x * x + y * y + z * z).sqrt()) }
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * s
}

fn v_sight(s: f64, r: f64, rad: f64) -> f64 { // road 2: field point at r inside a ball of radius rad
    let l = |th: f64| -r * th.cos() + (rad * rad - (r * th.sin()).powi(2)).sqrt();
    s / 4.0 * simpson(&|th: f64| l(th).powi(2) * th.sin(), 0.0, PI, 400)
}

fn v_cubes(b: &Ball, m: i32, pts: &[[f64; 3]]) -> (Vec<f64>, usize) { // road 3
    let a = b.r / m as f64;
    let mut tot = vec![0.0; pts.len()];
    let mut cells = 0;
    for i in -m..m { for j in -m..m { for k in -m..m {
        let c = [(i as f64 + 0.5) * a, (j as f64 + 0.5) * a, (k as f64 + 0.5) * a];
        if c[0] * c[0] + c[1] * c[1] + c[2] * c[2] > b.r * b.r { continue; }
        cells += 1;
        for (n, p) in pts.iter().enumerate() {
            let d = ((p[0] - c[0]).powi(2) + (p[1] - c[1]).powi(2) + (p[2] - c[2]).powi(2)).sqrt();
            tot[n] += 1.0 / d;
        }
    }}}
    (tot.iter().map(|t| b.s / (4.0 * PI) * a.powi(3) * t).collect(), cells)
}

fn lap(f: &dyn Fn(f64, f64, f64) -> f64, x: f64, y: f64, z: f64, h: f64) -> f64 { // 7-point -Laplacian
    -(f(x + h, y, z) + f(x - h, y, z) + f(x, y + h, z) + f(x, y - h, z)
        + f(x, y, z + h) + f(x, y, z - h) - 6.0 * f(x, y, z)) / (h * h)
}

fn main() {
    let eps0 = 8.8541878188e-12; // F/m, CODATA 2022
    let e = 1.602176634e-19; // C, exact
    let ke = e / (4.0 * PI * eps0) / 1e-15 / 1e6; // MV fm
    let (z, a, r0) = (92.0_f64, 238.0_f64, 1.2_f64);
    let rr = r0 * a.powf(1.0 / 3.0);
    let vr = z * ke / rr;
    let b = Ball { r: rr, vr, s: 3.0 * vr / (rr * rr) };
    let s = b.s;
    let v3 = |x: f64, y: f64, zz: f64| b.v3(x, y, zz);

    println!("ball: Z = {}, R = {:.4} fm, ke = {:.6} MV fm", z, rr, ke);
    println!("source rho/eps0 = {:.6} MV/fm^2", s);
    println!("surface V = kQ/R = {:.4} MV", vr);
    for r in [0.0, rr / 2.0] {
        let vs = v_sight(s, r, rr);
        println!("r = {:.4} fm: closed form {:.4} MV, line-of-sight integral {:.4} MV", r, b.v(r), vs);
        assert!((b.v(r) - vs).abs() < 1e-8);
    }
    let pts = [[0.0, 0.0, 0.0], [rr / 2.0, 0.0, 0.0], [2.0 * rr, 0.0, 0.0]];
    let exact: Vec<f64> = pts.iter().map(|p| b.v(p[0])).collect();
    println!("cube sum, centre / half radius / twice radius (MV):");
    let mut errs = vec![];
    for m in [10, 20, 40] {
        let (vals, cells) = v_cubes(&b, m, &pts);
        errs.push(vals.iter().zip(&exact).map(|(v, x)| (v - x).abs()).fold(0.0, f64::max));
        println!("  side R/{}, {} cubes: {:.4}, {:.4}, {:.4}; worst error {:.4}", m, cells, vals[0], vals[1], vals[2], errs[errs.len() - 1]);
    }
    println!("  exact:                  {:.4}, {:.4}, {:.4}", exact[0], exact[1], exact[2]);
    assert!(errs[2] < errs[0] / 4.0 && errs[2] < 0.05);

    // road 4: the equation's residual, and the seam at the surface
    let ri = lap(&v3, 2.0, 1.0, 1.0, 0.25);
    println!("-Lap V inside at (2,1,1) fm, h = 0.25: {:.6} MV/fm^2 (source {:.6})", ri, s);
    assert!((ri - s).abs() < 1e-6);
    for h in [0.5, 0.25] {
        println!("-Lap V outside at (12,5,3) fm, h = {}: {:.6} MV/fm^2", h, lap(&v3, 12.0, 5.0, 3.0, h));
    }
    assert!(lap(&v3, 12.0, 5.0, 3.0, 0.25).abs() < 1e-3);
    for h in [0.1, 0.01] {
        println!("-Lap V on the surface at (R,0,0), h = {}: {:.4} MV/fm^2", h, lap(&v3, rr, 0.0, 0.0, h));
    }
    let h = 1e-3;
    let (d_in, d_out) = ((b.v(rr) - b.v(rr - h)) / h, (b.v(rr + h) - b.v(rr)) / h);
    let s_in = (b.v(rr) - 2.0 * b.v(rr - h) + b.v(rr - 2.0 * h)) / (h * h);
    let s_out = (b.v(rr + 2.0 * h) - 2.0 * b.v(rr + h) + b.v(rr)) / (h * h);
    println!("slope V' at R: inside {:.4}, outside {:.4} MV/fm (Gauss: -kQ/R^2 = {:.4})", d_in, d_out, -vr / rr);
    println!("V'' at R: inside {:.4}, outside {:.4} MV/fm^2, jump {:.4}", s_in, s_out, s_out - s_in);
    assert!((d_in - d_out).abs() < 1e-2 && (s_out - s_in - s).abs() < 1e-2);

    // the energy: U = (1/2) * integral of charge density times potential
    let n = z / (4.0 / 3.0 * PI * rr.powi(3));
    let u = 0.5 * simpson(&|r: f64| n * b.v(r) * 4.0 * PI * r * r, 0.0, rr, 200);
    println!("Coulomb energy: integral {:.2} MeV, (3/5) Z^2 ke/R = {:.2} MeV", u, 0.6 * z * vr);
    assert!((u - 0.6 * z * vr).abs() < 1e-6);
    println!("liquid-drop coefficient (3/5) ke/r0 = {:.5} MeV", 0.6 * ke / r0);

    println!("what breaks:");
    println!("  charge on the surface only: U = {:.2} MeV", 0.5 * z * vr);
    let upt = 0.5 * simpson(&|r: f64| n * z * ke * 4.0 * PI * r, 0.0, rr, 200);
    println!("  kQ/r used inside too: U = {:.2} MeV, centre infinite", upt);
    println!("  inner charge only, at R/2: {:.4} MV", vr * 0.5f64.powi(3) / 0.5);
    println!("  forget the 1/2: U = {:.2} MeV", 2.0 * u);
    println!("  kernel 1/r without 4 pi: centre {:.2} MV", 4.0 * PI * b.v(0.0));
    let grow: Vec<f64> = [1.0, 2.0, 4.0, 8.0].iter().map(|l| v_sight(s, 0.0, l * rr)).collect();
    let gs: Vec<String> = grow.iter().map(|g| format!("{:.2}", g)).collect();
    println!("  source that does not fade, centre potential (MV): {}", gs.join(" "));
    assert!((grow[3] / grow[2] - 4.0).abs() < 1e-9);
    println!("  f continuous, not Hoelder: u = (x^2-y^2) log(-log r), scaled");
    for (sv, lab) in [(1e-2, "1e-02"), (1e-6, "1e-06"), (1e-12, "1e-12")] {
        let lg = -f64::ln(sv);
        let uf = |x: f64, y: f64, zz: f64| (x * x - y * y) * (-0.5 * (x * x + y * y + zz * zz).ln()).ln();
        let hh = sv / 1000.0;
        let uxx = (uf(sv + hh, 0.0, 0.0) - 2.0 * uf(sv, 0.0, 0.0) + uf(sv - hh, 0.0, 0.0)) / (hh * hh);
        let form = 2.0 * lg.ln() - 3.0 / lg - 1.0 / (lg * lg);
        let (f_num, f_form) = (lap(&uf, sv, 0.0, 0.0, hh), 5.0 / lg + 1.0 / (lg * lg));
        println!("    r = {}: f = {:.4} (grid {:.4}), u_xx = {:.4} (grid {:.4})", lab, f_form, f_num, form, uxx);
        assert!((uxx - form).abs() < 1e-3 && (f_num - f_form).abs() < 1e-3);
    }

    println!("try changing:");
    let rpb = 1.2 * 208.0_f64.powf(1.0 / 3.0);
    println!("  lead-208: R = {:.4} fm, centre {:.4} MV, U = {:.2} MeV", rpb, 1.5 * 82.0 * ke / rpb, 0.6 * 82.0 * 82.0 * ke / rpb);
    let rh = 1.2 * 119.0_f64.powf(1.0 / 3.0);
    let uh = 0.6 * 46.0 * 46.0 * ke / rh;
    println!("  two halves Z = 46, A = 119: R = {:.4} fm, U = {:.2} MeV each, Coulomb release {:.2} MeV", rh, uh, u - 2.0 * uh);
    println!("chart, r (fm), solid ball (MV), surface charge (MV):");
    for r in (0..24).step_by(2) {
        let rf = r as f64;
        println!("  {}, {:.2}, {:.2}", r, b.v(rf), if rf < rr { vr } else { vr * rr / rf });
    }
    println!("ALL CHECKS PASS");
}
