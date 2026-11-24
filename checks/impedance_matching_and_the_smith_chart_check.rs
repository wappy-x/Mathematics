// Impedance matching and the Smith chart -- the check behind the card.  std only, no crates.
// A 75-ohm antenna onto 50-ohm coax at 100 MHz by a quarter-wave section, then a
// 25 + j25 ohm load matched by one short-circuited stub.  Roads: closed forms; a walk
// round the Smith chart (rotate, then bisect); and a ladder of tiny coils and capacitors.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                       // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
impl C {
    fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: C) -> C {                       // times the conjugate, over |o| squared
        let d = o.re * o.re + o.im * o.im;
        c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d)
    }
    fn inv(self) -> C { c(1.0, 0.0).div(self) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}

const C0: f64 = 299792458.0; const VF: f64 = 0.66; const F0: f64 = 100e6; const Z0: f64 = 50.0;
const ZA: f64 = 75.0;                               // the antenna, ohm

fn zin(zl: C, zc: f64, turns: f64) -> C {           // line of zc ohms, length in wavelengths
    let t = (2.0 * PI * turns).tan();
    c(zc, 0.0).mul(zl.add(c(0.0, zc * t))).div(c(zc, 0.0).add(zl.mul(c(0.0, t))))
}
fn gam(z: C) -> C { z.sub(c(Z0, 0.0)).div(z.add(c(Z0, 0.0))) }
fn vswr(g: C) -> f64 { (1.0 + g.abs()) / (1.0 - g.abs()) }
fn ladder(zl: C, zc: f64, metres: f64, f: f64) -> C {   // road 3: n T-cells of L' dx and C' dx
    let n = 4000; let v = VF * C0; let dx = metres / n as f64; let w = 2.0 * PI * f;
    let (xl, bc) = (w * (zc / v) * dx, w * dx / (zc * v));   // L' = zc/v, C' = 1/(zc v)
    let mut z = zl;
    for _ in 0..n {
        z = z.add(c(0.0, 0.5 * xl));
        z = z.inv().add(c(0.0, bc)).inv().add(c(0.0, 0.5 * xl));
    }
    z
}
fn root<Fn1: Fn(f64) -> f64>(f: Fn1, mut lo: f64, mut hi: f64) -> f64 {   // bisection
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if (f(lo) < 0.0) == (f(mid) < 0.0) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn stub_match(zl: C, r: f64, d: f64, s: f64) -> C { // line d, shorted stub s (wavelengths at F0)
    let y = zin(zl, Z0, d * r).inv().add(zin(c(0.0, 0.0), Z0, s * r).inv());
    gam(y.inv())
}
fn turn(g: C, d: f64) -> C { g.mul(c((4.0 * PI * d).cos(), -(4.0 * PI * d).sin())) }
fn gy(g: C) -> C { c(1.0, 0.0).sub(g).div(c(1.0, 0.0).add(g)) }   // admittance read off Gamma
fn bw_qw(zl: f64, gm: f64) -> f64 {
    2.0 - 4.0 / PI * (gm / (1.0 - gm * gm).sqrt() * 2.0 * (Z0 * zl).sqrt() / (zl - Z0).abs()).acos()
}

fn main() {
    let lam = VF * C0 / F0;
    // ---- part 1: quarter-wave transformer, 75 ohm antenna to 50 ohm coax ----
    let za = c(ZA, 0.0);
    let z1 = (Z0 * ZA).sqrt();
    let q_len = lam / 4.0;
    let z_q = zin(za, z1, 0.25);
    let z_q_lad = ladder(za, z1, q_len, F0);
    let g_raw = gam(za);
    // ---- part 2: single shorted stub for 25 + j25 ohm ----
    let zl = c(25.0, 25.0);
    let (gl, yl) = (gam(zl), c(Z0, 0.0).div(zl));
    let (rl, xl) = (zl.re, zl.im);                  // road 1: tan(beta d), then cot(beta l)
    let disc = (rl * ((Z0 - rl).powi(2) + xl * xl) / Z0).sqrt();
    let mut sols: Vec<(f64, f64, f64)> = Vec::new();
    for t in [(xl + disc) / (rl - Z0), (xl - disc) / (rl - Z0)] {
        let bd = t.atan().rem_euclid(PI);
        let b = zin(zl, Z0, bd / (2.0 * PI)).inv().im * Z0;
        sols.push((bd / (2.0 * PI), (1.0 / b).atan().rem_euclid(PI) / (2.0 * PI), b));
    }
    sols.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap());
    // road 2: walk round the chart.  Moving d wavelengths to the generator turns Gamma by -4 pi d.
    let d_walk = root(|d| gy(turn(gl, d)).re - 1.0, 0.25, 0.45);
    let b_walk = gy(turn(gl, d_walk)).im;
    let s_walk = root(|s| gy(turn(c(-1.0, 0.0), s)).im + b_walk, 0.01, 0.24);   // short is Gamma = -1
    let g_lad = gam(ladder(zl, Z0, d_walk * lam, F0).inv().add(ladder(c(0.0, 0.0), Z0, s_walk * lam, F0).inv()).inv());
    let (db, sb) = (sols[1].0, sols[1].1);
    // ---- bandwidth: |Gamma| <= 0.1 (return loss 20 dB) ----
    let gm = 0.1;
    let bw_formula = bw_qw(ZA, gm);
    let qw = |r: f64| gam(zin(za, z1, 0.25 * r)).abs() - gm;
    let bw_sweep = root(qw, 1.0, 1.99) - root(qw, 0.01, 1.0);
    let sw = |d: f64, s: f64| move |r: f64| stub_match(zl, r, d, s).abs() - gm;
    let bw_b = root(sw(db, sb), 1.0, 1.3) - root(sw(db, sb), 0.7, 1.0);
    let bw_a = root(sw(0.0, sols[0].1), 1.0, 1.3) - root(sw(0.0, sols[0].1), 0.7, 1.0);
    let open = zin(zl, Z0, db).inv().add(c(0.0, (2.0 * PI * sb).tan() / Z0)).inv();

    let rows: Vec<(&str, f64)> = vec![
        ("cable wavelength at 100 MHz, m", lam), ("quarter-wave section Z1, ohm", z1),
        ("quarter-wave length, m", q_len), ("antenna on bare coax |Gamma|", g_raw.abs()),
        ("antenna on bare coax VSWR", vswr(g_raw)), ("  return loss, dB", -20.0 * g_raw.abs().log10()),
        ("1 formula: Zin real, ohm", z_q.re), ("1 formula: Zin imag, ohm", z_q.im),
        ("3 ladder: Zin real, ohm", z_q_lad.re), ("3 ladder: Zin imag, ohm", z_q_lad.im),
        ("load 25+j25: Gamma real", gl.re), ("load 25+j25: Gamma imag", gl.im),
        ("  |Gamma|", gl.abs()), ("  angle, deg", gl.im.atan2(gl.re).to_degrees()),
        ("  VSWR", vswr(gl)), ("  return loss, dB", -20.0 * gl.abs().log10()),
        ("  power reflected, %", 100.0 * gl.abs().powi(2)), ("  admittance y real", yl.re),
        ("  admittance y imag", yl.im),
        ("1 sol A: d, wavelengths", sols[0].0), ("1 sol A: line b at d", sols[0].2),
        ("1 sol A: stub, wavelengths", sols[0].1), ("1 sol A: stub, m", sols[0].1 * lam),
        ("1 sol B: d, wavelengths", db), ("1 sol B: d, m", db * lam),
        ("1 sol B: line b at d", sols[1].2), ("1 sol B: stub, wavelengths", sb),
        ("1 sol B: stub, m", sb * lam), ("2 chart walk: d, wavelengths", d_walk),
        ("2 chart walk: turn, deg", 720.0 * d_walk), ("2 chart walk: b at d", b_walk),
        ("2 chart walk: stub, wavelengths", s_walk), ("3 ladder: |Gamma| after match", g_lad.abs()),
        ("bandwidth QW formula, % of 100 MHz", 100.0 * bw_formula),
        ("bandwidth QW sweep, % of 100 MHz", 100.0 * bw_sweep),
        ("bandwidth stub B, % of 100 MHz", 100.0 * bw_b), ("bandwidth stub A, % of 100 MHz", 100.0 * bw_a),
        ("outside: QW at 200 MHz |Gamma|", gam(zin(za, z1, 0.5)).abs()),
        ("wrong: mean 62.5 ohm section |Gamma|", gam(zin(za, 62.5, 0.25)).abs()),
        ("wrong: free-space quarter, cut m", C0 / F0 / 4.0),
        ("wrong: free-space quarter |Gamma|", gam(zin(za, z1, 0.25 / VF)).abs()),
        ("wrong: QW sqrt(50x25) on 25+j25 |Gamma|", gam(zin(zl, (Z0 * 25.0).sqrt(), 0.25)).abs()),
        ("  its Zin real, ohm", zin(zl, (Z0 * 25.0).sqrt(), 0.25).re), ("  its Zin imag, ohm", zin(zl, (Z0 * 25.0).sqrt(), 0.25).im),
        ("wrong: open stub for short |Gamma|", gam(open).abs()),
        ("wrong: walk toward load |Gamma|", stub_match(zl, 1.0, 0.5 - db, sb).abs()),
        ("try: 100 ohm load, Z1 ohm", (Z0 * 100.0).sqrt()), ("try: foam VF 0.85, quarter m", 0.85 * C0 / F0 / 4.0),
        ("try: 300 ohm load, QW bandwidth %", 100.0 * bw_qw(300.0, gm)),
    ];
    for (name, v) in &rows {
        println!("{:<40} {:>10.4}", name, (v * 1e9).round() / 1e9 + 0.0);
    }
    let fs: Vec<i32> = (0..11).map(|k| 50 + 10 * k).collect();
    let line = |v: Vec<String>| v.join(" ");
    println!("chart, MHz         {}", line(fs.iter().map(|f| format!("{:>5}", f)).collect()));
    println!("chart, QW |Gamma|  {}", line(fs.iter().map(|&f| format!("{:>5.3}", gam(zin(za, z1, 0.25 * f as f64 / 100.0)).abs())).collect()));
    println!("chart, stub B      {}", line(fs.iter().map(|&f| format!("{:>5.3}", stub_match(zl, f as f64 / 100.0, db, sb).abs())).collect()));
    let p = |g: C| format!("({:.1}, {:.1})", 210.0 + 180.0 * g.re, 210.0 - 180.0 * g.im);
    println!("figure, L {} B {} Q {} S {} rG {:.1}", p(gl), p(turn(gl, db)), p(g_raw), p(c(gl.abs(), 0.0)), 180.0 * gl.abs());

    assert!(z_q.sub(c(Z0, 0.0)).abs() < 1e-9, "quarter-wave formula: Zin = Z0 at a quarter wave");
    assert!(z_q_lad.sub(c(Z0, 0.0)).abs() < 1e-3, "coil-and-capacitor ladder agrees with the formula");
    assert!((d_walk - db).abs() < 1e-9 && (s_walk - sb).abs() < 1e-9, "chart walk agrees with the tan/cot formulas");
    assert!(g_lad.abs() < 1e-4, "ladder model of the stub design reflects nothing");
    assert!((bw_sweep - bw_formula).abs() < 1e-9, "bandwidth sweep agrees with the closed form");
    assert!((vswr(gl) - (1.0 + 5f64.sqrt()).powi(2) / 4.0).abs() < 1e-9, "hand value: VSWR = golden ratio squared");
    println!("ALL CHECKS PASS");
}
