// Symmetry and conservation -- the check behind the card.  Rust std only.
// The same four roads as the Python: classical spin moved by its Poisson bracket (RK4),
// quantum spin by Schrodinger's equation (RK4), the closed form, and Noether's test.
use std::f64::consts::PI;
const HBAR: f64 = H_PL / (2.0 * PI); // J s, h / 2 pi
const H_PL: f64 = 6.62607015e-34; // J s, exact
const GAMMA: f64 = 1.76085962784e11; // electron gyromagnetic ratio, rad/(s T), CODATA 2022
const MU_B: f64 = 9.2740100657e-24; // Bohr magneton, J/T, CODATA 2022
const M_E: f64 = 9.1093837139e-31; // kg
const EV: f64 = 1.602176634e-19; // J per eV
const B0: f64 = 0.34; // T
const DT: f64 = 1e-13; // 0.1 ps step
type V3 = [f64; 3];
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn sc(k: f64, a: C) -> C { c(k * a.re, k * a.im) }
fn abs(a: C) -> f64 { (a.re * a.re + a.im * a.im).sqrt() }
fn cross(a: V3, b: V3) -> V3 { [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]] }
fn dot(a: V3, b: V3) -> f64 { a[0]*b[0] + a[1]*b[1] + a[2]*b[2] }
fn sci(x: f64) -> String { format!("{:.1e}", x) } // 1.2e-12
fn bracket_rate(s: V3, b: V3) -> V3 { let k = cross(b, s); [GAMMA*k[0], GAMMA*k[1], GAMMA*k[2]] }
fn tilt() -> f64 { 60f64.to_radians() }
fn classical(bt: &dyn Fn(f64) -> V3, n: usize) -> Vec<V3> {
    let mut s = [0.5 * tilt().sin(), 0.0, 0.5 * tilt().cos()];
    let mut path = Vec::new();
    for k in 0..=n {
        path.push(s);
        let b = bt(k as f64 * DT); // field held over one step
        let f = |y: V3| bracket_rate(y, b);
        let st = |y: V3, k: V3, h: f64| [y[0] + h*k[0], y[1] + h*k[1], y[2] + h*k[2]];
        let k1 = f(s); let k2 = f(st(s, k1, DT/2.0)); let k3 = f(st(s, k2, DT/2.0)); let k4 = f(st(s, k3, DT));
        for i in 0..3 { s[i] = s[i] + DT/6.0*(k1[i] + 2.0*k2[i] + 2.0*k3[i] + k4[i]); }
    }
    path
}
fn quantum(b: V3, n: usize) -> V3 { // i hbar dpsi/dt = H psi, H = gamma B.(hbar/2 sigma)
    let mi = c(0.0, -0.5 * GAMMA);
    let f = |p: [C; 2]| [mul(mi, add(sc(b[2], p[0]), mul(c(b[0], -b[1]), p[1]))),
                         mul(mi, sub(mul(c(b[0], b[1]), p[0]), sc(b[2], p[1])))];
    let st = |p: [C; 2], k: [C; 2], h: f64| [add(p[0], sc(h, k[0])), add(p[1], sc(h, k[1]))];
    let mut p = [c((tilt() / 2.0).cos(), 0.0), c((tilt() / 2.0).sin(), 0.0)];
    for _ in 0..n {
        let k1 = f(p); let k2 = f(st(p, k1, DT/2.0)); let k3 = f(st(p, k2, DT/2.0)); let k4 = f(st(p, k3, DT));
        for i in 0..2 {
            let s = add(add(k1[i], sc(2.0, k2[i])), add(sc(2.0, k3[i]), k4[i]));
            p[i] = add(p[i], sc(DT / 6.0, s));
        }
    }
    let ab = mul(c(p[0].re, -p[0].im), p[1]);
    [ab.re, ab.im, 0.5 * (abs(p[0]).powi(2) - abs(p[1]).powi(2))]
}
fn turn(s: V3, ax: V3, a: f64) -> V3 { // rotate s by angle a about a unit axis (Rodrigues)
    let cr = cross(ax, s); let d = dot(ax, s);
    [0, 1, 2].map(|i| s[i]*a.cos() + cr[i]*a.sin() + ax[i]*d*(1.0 - a.cos()))
}
type M2 = [[C; 2]; 2];
fn mm(a: M2, b: M2) -> M2 {
    let mut r = [[c(0.0, 0.0); 2]; 2];
    for i in 0..2 { for j in 0..2 { r[i][j] = add(mul(a[i][0], b[0][j]), mul(a[i][1], b[1][j])); } }
    r
}
fn comm(a: M2, b: M2) -> M2 { let (x, y) = (mm(a, b), mm(b, a)); [0, 1].map(|i| [0, 1].map(|j| sub(x[i][j], y[i][j]))) }
fn minus(a: M2, b: M2, z: C) -> M2 { [0, 1].map(|i| [0, 1].map(|j| sub(a[i][j], mul(z, b[i][j])))) }
fn big(m: M2) -> f64 { m.iter().flatten().map(|&x| abs(x)).fold(0.0, f64::max) }
fn main() {
    let bz = [0.0, 0.0, B0];
    let w = GAMMA * B0; let f_formula = w / (2.0 * PI);
    let path = classical(&|_t| bz, 10000); // 1 ns
    let up: Vec<f64> = (0..10000).filter(|&k| path[k][1] < 0.0 && 0.0 <= path[k+1][1])
        .map(|k| k as f64 * DT - path[k][1] * DT / (path[k+1][1] - path[k][1])).collect(); // Sy upward
    let f_sim = (up.len() - 1) as f64 / (up[up.len() - 1] - up[0]);
    let sq = quantum(bz, 10000);
    let sx_exact = 0.5 * tilt().sin() * (w * 1e-9).cos();
    let sz_drift = path.iter().map(|s| (s[2] - path[0][2]).abs()).fold(0.0, f64::max);
    let h0 = GAMMA * dot(bz, path[0]) * HBAR;
    let size_drift = path.iter().map(|s| (dot(*s, *s).sqrt() - 0.5).abs()).fold(0.0, f64::max);
    let last = path[10000];
    println!("ESR magnet {:.2} T, spin starts 60 deg from the field", B0);
    println!("w = gamma B = {:.5} x 10^10 rad/s", w / 1e10);
    println!("f closed form       {:.4} GHz", f_formula / 1e9);
    println!("f from the bracket  {:.4} GHz  (zero crossings, 1 ns of RK4)", f_sim / 1e9);
    println!("period {:.5} ns; level splitting hbar w = {:.2} ueV", 1e9 / f_formula, HBAR * w / EV * 1e6);
    println!("energy H = gamma B Sz = {:.3} ueV, Sz = {:.4} hbar", h0 / EV * 1e6, path[0][2]);
    println!("1 ns:  Sx classical {:.6}  quantum {:.6}  closed form {:.6} hbar", last[0], sq[0], sx_exact);
    println!("1 ns:  Sz classical {:.6}  quantum {:.6} hbar", last[2], sq[2]);
    println!("largest drift over 1 ns: Sz {}, |S| {} hbar", sci(sz_drift), sci(size_drift));
    println!("chart t (ns):  {}", (0..11).map(|k| format!("{:.2}", k as f64 / 100.0)).collect::<Vec<_>>().join(" "));
    for (i, name) in ["Sx", "Sy", "Sz"].iter().enumerate() {
        println!("chart {} (hbar): {}", name, (0..11).map(|k| format!("{:.3}", path[100*k][i] + 0.0)).collect::<Vec<_>>().join(" "));
    }
    // Road 4: Noether's test, and the bracket that measures it
    let (eps, s0) = (1e-6, path[200]); // the spin at t = 0.02 ns
    for (i, name, ax) in [(2, "z", [0.0, 0.0, 1.0]), (0, "x", [1.0, 0.0, 0.0])] {
        let dh = (dot(bz, turn(s0, ax, eps)) - dot(bz, turn(s0, ax, -eps))) / (2.0 * eps) * GAMMA;
        let rate = bracket_rate(s0, bz)[i]; // dS/dt = {S, H}, from the bracket
        println!("turn about {}: dH/dangle = {:.4} ueV/rad;  -hbar {{S{}, H}} = {:.4} ueV",
                 name, dh * HBAR / EV * 1e6 + 0.0, name, -rate * HBAR / EV * 1e6 + 0.0);
        assert!((dh + rate).abs() < 1e-6 * w);
    }
    // quantum: commutators of 2 x 2 matrices, hbar = 1
    let z = c(0.0, 0.0);
    let sx: M2 = [[z, c(0.5, 0.0)], [c(0.5, 0.0), z]];
    let sy: M2 = [[z, c(0.0, -0.5)], [c(0.0, 0.5), z]];
    let szm: M2 = [[c(0.5, 0.0), z], [z, c(-0.5, 0.0)]];
    let hm: M2 = [0, 1].map(|i| [0, 1].map(|j| sc(GAMMA * B0, szm[i][j])));
    let (c_xy, c_zh, c_xh) = (big(minus(comm(sx, sy), szm, c(0.0, 1.0))), big(comm(szm, hm)), comm(sx, hm));
    let c_rule = big(minus(c_xh, sy, c(0.0, -w))); // Dirac: [Sx, H] = i hbar {Sx, H} = i hbar (-w Sy)
    println!("[Sx,Sy] - i Sz: {};  [Sz,H]: {};  [Sx,H] - i(-w Sy): {};  |[Sx,H]|: {:.4} x 10^10 /s",
             sci(c_xy), sci(c_zh), sci(c_rule), big(c_xh) / 1e10);
    // what breaks: tilt the field, ramp the field, f mixed with w, g taken as exactly 2
    let ftilt = 10.0f64; // field tilt from z, degrees (the check below holds up to 30)
    let rt = ftilt.to_radians();
    let bt = [B0 * rt.sin(), 0.0, B0 * rt.cos()];
    let tp = classical(&|_t| bt, 10000);
    let along_drift = tp.iter().map(|s| (dot(*s, bt) - dot(tp[0], bt)).abs()).fold(0.0, f64::max) / B0;
    let ramp = |t: f64| [0.0, 0.0, B0 + 0.02 * t / 1e-9]; // 0.34 -> 0.36 T over 1 ns
    let rp = classical(&ramp, 10000);
    let e_end = GAMMA * dot(ramp(1e-9), rp[10000]) * HBAR;
    let f_g2 = 2.0 * MU_B * B0 / H_PL;
    let tmin = tp.iter().map(|s| s[2]).fold(f64::INFINITY, f64::min);
    let tmax = tp.iter().map(|s| s[2]).fold(f64::NEG_INFINITY, f64::max);
    println!("field tilted {:.0} deg: Sz swings {:.4} to {:.4} hbar; S along B drifts {}", ftilt, tmin, tmax, sci(along_drift));
    println!("field ramped 0.34 -> 0.36 T in 1 ns: H {:.3} -> {:.3} ueV, Sz {:.4} -> {:.4} hbar",
             h0 / EV * 1e6, e_end / EV * 1e6, rp[0][2], rp[10000][2]);
    println!("w read as hertz: {:.4} GHz;  g = 2 exactly: {:.4} GHz (off by {:.1} MHz)",
             w / 1e9, f_g2 / 1e9, (f_formula - f_g2) / 1e6);
    // the house example: an electron in a 1 nm box (time shift kept, space shift broken)
    let l = 1e-9; let e1 = H_PL * H_PL / (8.0 * M_E * l * l); let p1 = H_PL / (2.0 * l); let v1 = p1 / M_E;
    let p1s = format!("{:.4e}", p1);
    println!("1 nm box: E1 = {:.4} eV, |p| = {} kg m/s, v = {:.0} m/s, wall to wall {:.3} fs",
             e1 / EV, p1s, v1, l / v1 * 1e15);
    println!("1 nm box: each bounce hands the walls 2|p| = {:.4e} kg m/s, given back at the other wall", 2.0 * p1);
    assert!((f_sim / f_formula - 1.0).abs() < 1e-6); // road 1 against road 3
    assert!((sq[0] - last[0]).abs() < 1e-6 && (sq[0] - sx_exact).abs() < 1e-6); // road 2 against 1 and 3
    assert!((sq[1] - last[1]).abs() < 1e-6 && (sq[2] - last[2]).abs() < 1e-6);
    assert!(sz_drift < 1e-9 && size_drift < 1e-9); // rotation about the field: Sz kept
    assert!((tmax - 0.5 * (tilt() - 2.0 * rt).cos()).abs() < 1e-4 && along_drift < 1e-9);
    assert!((e_end / h0 - (B0 + 0.02) / B0).abs() < 1e-9 && (rp[10000][2] - rp[0][2]).abs() < 1e-9);
    assert!(c_zh == 0.0 && big(c_xh) > 0.1 * w && c_rule < 1e-6 * w); // Sz kept, Sx not
    assert!(c_xy < 1e-15); // the spin algebra itself
    assert!((e1 / EV - 0.376).abs() < 5e-4 && (f_formula / 1e9 - 9.5285).abs() < 1e-4);
    println!("ALL CHECKS PASS");
}
