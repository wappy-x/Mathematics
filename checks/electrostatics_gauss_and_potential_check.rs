// Electric fields, Gauss's law and voltage -- the check behind the card.  std only, no crates.
// A radio's tuning capacitor: two square plates 10 cm across, 1 mm of air apart, +1 nC and -1 nC.
// Road 1: Gauss's law in closed form.  Road 2: Coulomb's law summed piece by piece over the charge,
// then the field integrated along a path to get the voltage.  A closed-form square-sheet field is a third.
use std::f64::consts::PI;

const EPS0: f64 = 8.8541878188e-12; // F/m, NIST CODATA 2022
const Q: f64 = 1e-9; // C, charge on each plate (+Q on top, -Q below)
const SIDE: f64 = 0.10; // m, plate side
const GAP: f64 = 0.001; // m, gap
const R_BALL: f64 = 0.01; // m, radius of the charged sphere
const L_COIL: f64 = 250e-6; // H, tuning coil

fn k() -> f64 { 1.0 / (4.0 * PI * EPS0) } // Coulomb's constant, N m^2/C^2

fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h); }
    h / 3.0 * (f(lo) + f(hi) + s)
}

fn coulomb_e(q: f64, src: [f64; 3], at: [f64; 3]) -> [f64; 3] {
    let d = [at[0] - src[0], at[1] - src[1], at[2] - src[2]];
    let r = (d[0] * d[0] + d[1] * d[1] + d[2] * d[2]).sqrt();
    [k() * q * d[0] / r.powi(3), k() * q * d[1] / r.powi(3), k() * q * d[2] / r.powi(3)]
}

fn cube_flux(src: [f64; 3]) -> f64 { // flux out of a 2 cm cube centred at 0, midpoint rule, 6 faces
    let (half, n) = (0.01, 60usize);
    let h = 2.0 * half / n as f64;
    let mut total = 0.0;
    for axis in 0..3 {
        for sign in [1.0, -1.0] {
            for i in 0..n {
                for j in 0..n {
                    let mut p = [0.0; 3];
                    p[axis] = sign * half;
                    p[(axis + 1) % 3] = -half + (i as f64 + 0.5) * h;
                    p[(axis + 2) % 3] = -half + (j as f64 + 0.5) * h;
                    total += sign * coulomb_e(Q, src, p)[axis] * h * h;
                }
            }
        }
    }
    total
}

fn shell_e(r: f64) -> f64 { // charge Q spread evenly on a sphere: add rings, field along the axis
    let ring = |th: f64| {
        let (dz, rho) = (r - R_BALL * th.cos(), R_BALL * th.sin());
        k() * (Q * th.sin() / 2.0) * dz / (dz * dz + rho * rho).powf(1.5)
    };
    simpson(&ring, 0.0, PI, 2000)
}

fn sheet_e(z: f64, sigma: f64) -> f64 { // uniform square sheet: Coulomb summed in polar angles
    let rho = |p: f64| (SIDE / 2.0) / p.cos();
    let inner = |p: f64| simpson(&|t: f64| t.sin(), 0.0, rho(p).atan2(z), 32);
    8.0 * k() * sigma * simpson(&inner, 0.0, PI / 4.0, 32)
}

fn sheet_closed(z: f64, sigma: f64) -> f64 {
    sigma / (PI * EPS0) * (SIDE.powi(2) / (4.0 * z * (z * z + SIDE.powi(2) / 2.0).sqrt())).atan()
}

fn plates(gap: f64) -> (f64, f64) { // road 2 for the plates: field midway, voltage along the axis
    let s = Q / SIDE.powi(2);
    let e_mid = 2.0 * sheet_e(gap / 2.0, s);
    let v = simpson(&|z: f64| sheet_e(z, s) + sheet_e(gap - z, s), 0.0, gap, 40);
    (e_mid, v)
}

fn line(label: &str, value: String) { println!("{:<52}{}", label, value); }

fn main() {
    let kk = k();
    // ---- Coulomb and Gauss: the flux through a closed surface counts the charge inside ----
    line("k = 1/(4 pi eps0), N m^2/C^2", format!("{:.6} x 10^9", kk / 1e9));
    let e1 = kk * Q / R_BALL.powi(2);
    line("Coulomb field of 1 nC at 1 cm, V/m", format!("{:.1}", e1));
    let gauss_flux = Q / EPS0;
    let (f_in, f_out) = (cube_flux([0.002, 0.001, -0.003]), cube_flux([0.03, 0.0, 0.0]));
    line("Gauss: flux = Q/eps0, V m", format!("{:.4}", gauss_flux));
    line("Coulomb summed over a cube, charge inside, V m", format!("{:.4}", f_in));
    line("Coulomb summed over a cube, charge outside, V m", format!("{:.4}", f_out.abs()));
    assert!((f_in / gauss_flux - 1.0).abs() < 1e-4 && f_out.abs() < 1e-4 * gauss_flux);

    // ---- the charged sphere ----
    for r in [0.02, 0.005] {
        let gauss = if r > R_BALL { kk * Q / (r * r) } else { 0.0 };
        line(&format!("sphere, field at {:.1} cm: Gauss | rings, V/m", r * 100.0),
             format!("{:.1} | {:.1}", gauss, shell_e(r).abs()));
        assert!((shell_e(r) - gauss).abs() < 1e-6 * e1);
    }
    let v_ball = kk * Q / R_BALL;
    let (n, top) = (40usize, 1.0 / R_BALL);
    let mut v_ball_num = 0.0;
    for i in 0..n {
        let u = (i as f64 + 0.5) * top / n as f64;
        v_ball_num += shell_e(1.0 / u) / (u * u) * top / n as f64;
    }
    line("sphere potential: kQ/R | ring field integrated, V", format!("{:.2} | {:.2}", v_ball, v_ball_num));
    assert!((v_ball_num - v_ball).abs() < 1e-5 * v_ball);

    // ---- the plates ----
    let sigma = Q / SIDE.powi(2);
    let e_gauss = sigma / EPS0;
    let v_gauss = e_gauss * GAP;
    line("plates: sigma, nC/m^2", format!("{:.1}", sigma * 1e9));
    line("plates: E = sigma/eps0, V/m", format!("{:.1}", e_gauss));
    line("plates: V = E d, V", format!("{:.3}", v_gauss));
    let (e_num, v_num) = plates(GAP);
    line("Coulomb over finite plates: E at centre, V/m", format!("{:.1}", e_num));
    line("Coulomb over finite plates: V along the axis, V", format!("{:.3}", v_num));
    line("finite plates against Gauss, field shortfall, %", format!("{:.2}", 100.0 * (1.0 - e_num / e_gauss)));
    assert!((e_num / e_gauss - 1.0).abs() < 0.015 && (v_num / v_gauss - 1.0).abs() < 0.015);
    assert!((sheet_e(GAP / 2.0, sigma) - sheet_closed(GAP / 2.0, sigma)).abs() < 1e-6 * e_gauss);
    let c = Q / v_gauss;
    line("capacitance C = Q/V = eps0 A/d, pF", format!("{:.2} | {:.2}", c * 1e12, EPS0 * SIDE.powi(2) / GAP * 1e12));
    let f_tune = 1.0 / (2.0 * PI * (L_COIL * c).sqrt());
    line("tunes with 250 uH to, kHz", format!("{:.1}", f_tune / 1e3));
    line("same 1 nC: plate voltage | sphere voltage, V", format!("{:.3} | {:.2}", v_gauss, v_ball));

    // ---- what breaks ----
    line("mistake 1, one sheet's field sigma/(2 eps0): V", format!("{:.3}", v_gauss / 2.0));
    line("mistake 2, point-charge kQ/d^2 across the gap: V", format!("{:.1}", kk * Q / GAP.powi(2) * GAP));
    line("mistake 3, kQ/r^2 inside the sphere at 0.5 cm: V/m", format!("{:.1}", kk * Q / 0.005f64.powi(2)));
    line("sign slip, minus dropped: top minus bottom, V", format!("{:.3}", -v_gauss));
    let (e50, v50) = plates(0.05);
    line("mistake 4, 50 mm gap: Gauss V | finite plates V", format!("{:.1} | {:.1}", e_gauss * 0.05, v50));
    line("50 mm gap: field at centre, % of Gauss", format!("{:.1}", 100.0 * e50 / e_gauss));
    assert!(e50 < 0.7 * e_gauss && (sheet_e(0.025, sigma) - sheet_closed(0.025, sigma)).abs() < 1e-6 * e_gauss);

    // ---- try changing ----
    let c2 = EPS0 * SIDE.powi(2) / 0.002;
    line("try: gap 2 mm, C pF | tuning kHz", format!("{:.2} | {:.1}", c2 * 1e12, 1.0 / (2.0 * PI * (L_COIL * c2).sqrt()) / 1e3));
    line("try: 3 nC on the plates, V", format!("{:.3}", 3.0 * v_gauss));
    line("try: sphere radius 2 cm, V", format!("{:.2}", kk * Q / 0.02));

    // ---- figure: sphere at 40 px per cm, arrows 0.8 px per kV/m; plates at 50 px per mm ----
    line("figure, px: sphere r | Gauss r | arrows 1 cm, 2 cm",
         format!("{:.0} | {:.0} | {:.0}, {:.0}", R_BALL * 4000.0, 0.02 * 4000.0, e1 / 1e3 * 0.8, kk * Q / 0.02f64.powi(2) / 1e3 * 0.8));
    line("figure, plate gap px", format!("{:.0}", GAP * 50000.0));
    println!("ALL CHECKS PASS");
}
