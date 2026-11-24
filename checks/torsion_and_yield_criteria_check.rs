// Torsion and yield -- the check behind the card.  Rust std only.
// A 40 mm solid steel shaft carries 1 kN m of torque and 100 MPa of bending
// stress.  Shear stress, twist, then the von Mises and Tresca yield checks.
use std::f64::consts::PI;

const D: f64 = 0.040; // diameter m
const R: f64 = D / 2.0;
const N: usize = 20000; // thin rings for the numerical roads
const MPA: f64 = 1e-6;

fn rings(f: &dyn Fn(f64) -> f64) -> f64 {
    // sum f(radius) * ring area, midpoint rule
    let dr = R / N as f64;
    (0..N).map(|k| { let q = (k as f64 + 0.5) * dr; f(q) * 2.0 * PI * q * dr }).sum()
}
fn sci(x: f64) -> String {
    // the same text as Python's {:.4e}
    let e = x.abs().log10().floor() as i32;
    let m = x / 10f64.powi(e);
    format!("{:.4}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}
fn vm(s: f64, t: f64) -> f64 { (s * s + 3.0 * t * t).sqrt() }
fn tr(s: f64, t: f64) -> f64 { (s * s + 4.0 * t * t).sqrt() }
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn px(s: f64, t: f64) -> String { format!("({:.2}, {:.2})", 260.0 + 0.8 * s * MPA, 200.0 - 0.8 * t * MPA) }

fn main() {
    let (t, g, sb, sy) = (1000.0_f64, 79e9_f64, 100e6_f64, 275e6_f64);
    // Road 1: closed forms.  Road 2: add up thin rings.
    let j = PI * D.powi(4) / 32.0;
    let j_rings = rings(&|q| q * q);
    let tau = t * R / j;
    let rate = t / (g * j); // twist per metre, rad/m
    let t_back = rings(&|q| (tau * q / R) * q);
    let u = rings(&|q| (tau * q / R).powi(2) / (2.0 * g));
    let rate_energy = 2.0 * u / t; // work T*phi/2 equals stored energy
    assert!((j_rings - j).abs() / j < 1e-8 && (t_back - t).abs() < 1e-4);
    assert!((rate_energy - rate).abs() / rate < 1e-8);
    let w = PI * D.powi(3) / 32.0;
    println!("J = pi d^4/32: {} m^4; by {} rings {} m^4", sci(j), N, sci(j_rings));
    println!("surface shear stress T r / J: {:.2} MPa", tau * MPA);
    println!("torque carried by the ring stresses: {:.2} N m", t_back);
    println!("twist rate T/(G J): {:.4} rad/m = {:.3} deg/m", rate, rate.to_degrees());
    println!("twist rate from stored energy {:.2} J/m: {:.4} rad/m", u, rate_energy);
    println!("bending: W = pi d^3/32 = {} m^3, moment for 100 MPa {:.1} N m", sci(w), sb * w);
    println!("G from E = 200 GPa, nu = 0.30: {:.2} GPa; 79 GPa matches E = {:.1} GPa; twist at 76.92 GPa: {:.4} rad/m",
        200e9 / 2.6 / 1e9, g * 2.6 / 1e9, t / (200e9 / 2.6 * j));

    // The surface point: sigma along the axis, tau round it, nothing else.
    let (c, rr) = (sb / 2.0, ((sb / 2.0).powi(2) + tau * tau).sqrt());
    let (s1, s2, s3) = (c + rr, 0.0_f64, c - rr); // 3D order, largest first
    println!("surface shear strain tau/G: {:.5} rad; Mohr centre {:.2} MPa, radius {:.2} MPa", tau / g, c * MPA, rr * MPA);
    println!("principal stresses: {:.2}, {:.2}, {:.2} MPa", s1 * MPA, s2 * MPA, s3 * MPA);
    // Road 3: turn a cutting plane through 180 degrees in 0.001 degree steps.
    let (mut smax, mut smin, mut shmax) = (0.0_f64, 0.0_f64, 0.0_f64);
    for k in 0..180000 {
        let a = (k as f64 / 1000.0).to_radians();
        let sn = sb * a.cos().powi(2) + tau * (2.0 * a).sin();
        let sh = -sb * a.sin() * a.cos() + tau * (2.0 * a).cos();
        smax = smax.max(sn); smin = smin.min(sn); shmax = shmax.max(sh.abs());
    }
    println!("plane scan: largest {:.2}, smallest {:.2}, largest shear {:.2} MPa", smax * MPA, smin * MPA, shmax * MPA);
    assert!((smax - s1).abs() < 1e3 && (smin - s3).abs() < 1e3);
    let (vm_f, tr_f) = (vm(sb, tau), tr(sb, tau));
    let vm_p = (((s1 - s2).powi(2) + (s2 - s3).powi(2) + (s3 - s1).powi(2)) / 2.0).sqrt();
    let tr_p = s1.max(s2).max(s3) - s1.min(s2).min(s3);
    // Road 4 for von Mises: distortion energy, from the stress tensor minus its mean.
    let st = [[sb, tau, 0.0], [tau, 0.0, 0.0], [0.0, 0.0, 0.0]];
    let m = (st[0][0] + st[1][1] + st[2][2]) / 3.0;
    let mut ud = 0.0;
    for i in 0..3 { for k in 0..3 { ud += (st[i][k] - if i == k { m } else { 0.0 }).powi(2); } }
    ud /= 4.0 * g;
    let ud_y = sy * sy / (6.0 * g); // the same energy at yield in a tension test
    let vm_e = sy * (ud / ud_y).sqrt();
    assert!((vm_p - vm_f).abs() < 1e-3 && (vm_e - vm_f).abs() < 1e-3);
    assert!((tr_p - tr_f).abs() < 1e-3 && (2.0 * shmax - tr_f).abs() < 1e3);
    println!("von Mises: formula {:.2}, principals {:.2}, energy {:.2} MPa", vm_f * MPA, vm_p * MPA, vm_e * MPA);
    println!("distortion energy {:.2} kJ/m^3 against {:.2} kJ/m^3 at yield", ud / 1e3, ud_y / 1e3);
    println!("Tresca: formula {:.2}, principals {:.2}, 2 x scan {:.2} MPa", tr_f * MPA, tr_p * MPA, 2.0 * shmax * MPA);
    println!("safety factors: von Mises {:.2}, Tresca {:.2}", sy / vm_f, sy / tr_f);

    // Shear yield and the torque the shaft can take with the bending held.
    let (ty_vm, ty_tr) = (sy / 3f64.sqrt(), sy / 2.0);
    println!("pure twist yields at {:.2} MPa (von Mises), {:.2} MPa (Tresca)", ty_vm * MPA, ty_tr * MPA);
    println!("yield torque, no bending: {:.1} N m (von Mises), {:.1} N m (Tresca)", ty_vm * j / R, ty_tr * j / R);
    let crit: [(&str, fn(f64, f64) -> f64, f64); 2] = [("von Mises", vm, 3.0), ("Tresca", tr, 4.0)];
    for (name, f, k) in crit {
        let tb = bisect(&|x| f(sb, x * R / j) - sy, 0.0, 1e6);
        let tc = ((sy * sy - sb * sb) / k).sqrt() * j / R;
        let tg = bisect(&|x| f(sb * x / t, x * R / j) - sy, 0.0, 1e6); // bending grows with the torque
        assert!((tb - tc).abs() < 1e-6 && (tg - t * sy / f(sb, tau)).abs() < 1e-6);
        println!("torque to yield, {}: bending held at 100 MPa {:.1} N m (bisection {:.1}); bending growing with it {:.1} N m", name, tc, tb, tg);
    }
    let ratios: Vec<f64> = (0..=100000).map(|q| tr(1.0, q as f64 / 100.0) / vm(1.0, q as f64 / 100.0)).collect();
    let (lo, hi) = ratios.iter().fold((f64::MAX, f64::MIN), |(a, b), &x| (a.min(x), b.max(x)));
    assert!(1.0 <= lo && hi <= 2.0 / 3f64.sqrt() + 1e-12);
    println!("Tresca/von Mises: here (k = tau/sigma = {:.4}) {:.4}; over tau/sigma 0 to 1000 from {:.4} to {:.4}, gap at most {:.1}%", tau / sb, tr_f / vm_f, lo, hi, 100.0 * (2.0 / 3f64.sqrt() - 1.0));

    // Outside the model: 2.5 kN m of pure twist.
    let t2 = 2500.0;
    let t_el = t2 * R / j;
    let core_torque = |re: f64| rings(&|q| ty_vm * (q / re).min(1.0) * q);
    let tp = 2.0 * PI * R.powi(3) * ty_vm / 3.0;
    if t_el > ty_vm { // an elastic core exists only once the surface has yielded
        let re_b = bisect(&|x| t2 - core_torque(x), 1e-6, R);
        let re_c = (4.0 * (R.powi(3) - 3.0 * t2 / (2.0 * PI * ty_vm))).cbrt();
        assert!((re_b - re_c).abs() < 2e-6);
        println!("2.5 kN m: formula says {:.2} MPa > {:.2}; elastic core {:.2} mm (bisection {:.2}); fully plastic at {:.1} N m",
            t_el * MPA, ty_vm * MPA, re_c * 1e3, re_b * 1e3, tp);
    } else {
        println!("2.5 kN m: {:.2} MPa, below {:.2}: still elastic; fully plastic at {:.1} N m", t_el * MPA, ty_vm * MPA, tp);
    }

    // What breaks.
    let i_bend = PI * D.powi(4) / 64.0;
    println!("break: shear judged against 275 MPa: safety factor {:.2}", sy / tau);
    println!("break: checks one at a time: bending {:.2}, twist {:.2}", sy / sb, ty_vm / tau);
    println!("break: bending I = pi d^4/64 used for J: {:.2} MPa, {:.4} rad/m", t * R / i_bend * MPA, t / (g * i_bend));
    println!("break: d used for r: {:.2} MPa", t * D / j * MPA);

    // Try changing.
    let jh = PI * (0.040f64.powi(4) - 0.030f64.powi(4)) / 32.0;
    let j8 = PI * 0.08f64.powi(4) / 32.0;
    println!("try: tube 40/30 mm: J {} m^4, shear {:.1} MPa, area down {:.0}%; d 80 mm: {:.2} MPa, {:.4} rad/m",
        sci(jh), t * R / jh * MPA, 100.0 * 0.75f64.powi(2), t * 0.04 / j8 * MPA, t / (g * j8));
    println!("try: G 26 GPa: {:.4} rad/m; no bending: safety factors {:.2} and {:.2}", t / (26e9 * j), sy / vm(0.0, tau), sy / tr(0.0, tau));

    // Figure: the sigma-tau plane at 0.8 px per MPa, origin at (260, 200).
    let (nv, nt) = (sy / vm_f, sy / tr_f);
    println!("figure, origin {}, point {}, von Mises hit {}, Tresca hit {}", px(0.0, 0.0), px(sb, tau), px(nv * sb, nv * tau), px(nt * sb, nt * tau));
    println!("figure, axis ends {} {}, tau tops {} {}", px(-sy, 0.0), px(sy, 0.0), px(0.0, ty_vm), px(0.0, ty_tr));
    for (lab, v) in [("bending alone", sb), ("von Mises", vm_f), ("Tresca", tr_f), ("yield S275", sy)] {
        let bar = "#".repeat((v * MPA / 10.0).round() as usize);
        println!("bar {:<14}|{:<28}| {:.1} MPa", lab, bar, v * MPA);
    }
    println!("ALL CHECKS PASS");
}
