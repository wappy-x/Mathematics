// Lift, drag and boundary layers -- the check behind the card.  Rust std only.
// A model wing (a Joukowski aerofoil, chord 0.30 m) in a wind tunnel at 40 m/s.
// Lift two ways: circulation (Kutta-Joukowski) and summed surface pressure.  Drag and
// separation from the boundary layer: Thwaites (laminar) to the suction peak, then Head's
// turbulent method.  Stall from Kirchhoff's rule: lift shrinks as the layer lets go.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
fn cx(re: f64, im: f64) -> Cx { Cx { re, im } }
fn add(a: Cx, b: Cx) -> Cx { cx(a.re + b.re, a.im + b.im) }
fn sub(a: Cx, b: Cx) -> Cx { cx(a.re - b.re, a.im - b.im) }
fn mul(a: Cx, b: Cx) -> Cx { cx(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn inv(b: Cx) -> Cx { // 1 / b, the same steps as Python's complex division
    if b.re.abs() >= b.im.abs() { let r = b.im / b.re; let d = b.re + b.im * r; cx(1.0 / d, -r / d) }
    else { let r = b.re / b.im; let d = b.re * r + b.im; cx(r / d, -1.0 / d) }
}
fn abs(a: Cx) -> f64 { a.re.hypot(a.im) }

const R: f64 = 8.314462618; const M_AIR: f64 = 0.0289644; const P0: f64 = 101325.0;
const T0: f64 = 293.15; const MU: f64 = 1.82e-5;
const C: f64 = 0.30; const SPAN: f64 = 0.80; const N: usize = 3000;
fn rho() -> f64 { P0 * M_AIR / (R * T0) }
fn nu() -> f64 { MU / rho() } // air at 20 C, 1 atm

struct Wing { m: Cx, a: f64, beta: f64, ch: f64, t: f64, f: f64, k: f64 }
fn wing(ex: f64, ey: f64) -> Wing { // circle centre (-ex, ey) through z = 1
    let m = cx(-ex, ey); let a = abs(sub(cx(1.0, 0.0), m)); let beta = (ey / a).asin();
    let zs: Vec<Cx> = (0..4000).map(|k| { let t = 2.0 * PI * k as f64 / 4000.0;
        let p = add(m, cx(a * t.cos(), a * t.sin())); add(p, inv(p)) }).collect();
    let xle = zs.iter().map(|z| z.re).fold(f64::INFINITY, f64::min); let ch = 2.0 - xle;
    let (mut up, mut lo) = (vec![-9.0f64; 200], vec![9.0f64; 200]); // thickness and camber by x-bins
    for z in &zs { let i = 199.min(((z.re - xle) / ch * 200.0) as usize); up[i] = up[i].max(z.im); lo[i] = lo[i].min(z.im); }
    let t = (0..200).map(|i| up[i] - lo[i]).fold(f64::NEG_INFINITY, f64::max) / ch;
    let f = (0..200).map(|i| (up[i] + lo[i]) / 2.0).fold(f64::NEG_INFINITY, f64::max) / ch;
    Wing { m, a, beta, ch, t, f, k: 8.0 * PI * a / ch }
}
fn circ(w: &Wing, th: f64) -> Cx { add(w.m, cx(w.a * th.cos(), w.a * th.sin())) }
fn pos(w: &Wing, th: f64) -> Cx { let p = circ(w, th); add(p, inv(p)) }
fn speed(w: &Wing, th: f64, al: f64) -> f64 { // speed / U on the aerofoil at circle angle th
    let p = circ(w, th);
    (-2.0 * (th - al).sin() - 2.0 * (al + w.beta).sin()).abs() / abs(sub(cx(1.0, 0.0), inv(mul(p, p))))
}
fn cl_by_pressure(w: &Wing, al: f64, n: usize) -> f64 { // road 2: add up -Cp n ds round the surface
    let (mut fl, mut z0) = (0.0, cx(2.0, 0.0));
    for k in 1..=n {
        let th = -w.beta + 2.0 * PI * k as f64 / n as f64; let z1 = if k < n { pos(w, th) } else { cx(2.0, 0.0) };
        let q = speed(w, th - PI / n as f64, al); let dz = sub(z1, z0); let cp = 1.0 - q * q;
        fl += -cp * (dz.im * -al.sin() + -dz.re * al.cos()); z0 = z1;
    }
    fl / w.ch
}
fn h_of(h1: f64) -> f64 { if h1 >= 5.3 { 1.1 + 0.86 * (h1 - 3.3).powf(-0.777) } else { 0.6778 + 1.1536 * (h1 - 3.3).powf(-0.326) } }
fn h1_of(h: f64) -> f64 { if h <= 1.6 { 3.3 + 0.8234 * (h - 1.1).powf(-1.287) } else { 3.3 + 1.5501 * (h - 0.6778).powf(-3.064) } }

fn thwaites(s: &[f64], ue: &[f64], k0: usize) -> f64 { // laminar momentum thickness at s[k0]
    let mut i = 0.0; for k in 1..=k0 { i += 0.5 * (ue[k].powf(5.0) + ue[k - 1].powf(5.0)) * (s[k] - s[k - 1]); }
    (0.45 * nu() * i / ue[k0].powf(6.0)).sqrt()
}
fn march(s: &[f64], ue: &mut Vec<f64>, hsep: f64, u: f64) -> (Option<usize>, f64, f64) { // Thwaites, then Head
    let mut k0 = 0; for k in 0..ue.len() { if ue[k] > ue[k0] { k0 = k; } }
    let mut th = thwaites(s, ue, k0); let mut h = 1.4;
    let mut y = ue[k0] * th * h1_of(h); let mut ksep: Option<usize> = None;
    for k in k0..s.len() - 1 {
        let ds = s[k + 1] - s[k]; let due = if ksep.is_some() { 0.0 } else { (ue[k + 1] - ue[k]) / ds };
        let cf = 0.246 * 10f64.powf(-0.678 * h) * (ue[k] * th / nu()).powf(-0.268);
        let h1 = y / (ue[k] * th);
        th += ds * (cf / 2.0 - (h + 2.0) * th / ue[k] * due); y += ds * ue[k] * 0.0306 * (h1 - 3.0).powf(-0.6169);
        if ksep.is_some() { ue[k + 1] = ue[k]; } // past separation: pressure stays constant
        let h1 = y / (ue[k + 1] * th); h = if h1 > 3.3 + 1e-9 { h_of(h1) } else { 3.5 };
        if ksep.is_none() && h > hsep { ksep = Some(k + 1); }
        h = h.min(hsep);
    }
    let ul = ue[ue.len() - 1]; // last: thickness at the back edge
    (ksep, 2.0 * th / C * (ul / u).powf((h + 5.0) / 2.0), y / ul + h * th)
}
type Up = (f64, f64, f64, f64); // upper surface: separation x/c, C_D, y/c, thickness at the back edge
fn section(w: &Wing, adeg: f64, hsep: f64, u: f64, n: usize) -> (f64, f64, f64, f64, f64, Up) { // lift, separation, drag
    let al = adeg.to_radians(); let ths = PI + 2.0 * al + w.beta; let sc = C / w.ch; let mut out: Vec<Up> = vec![];
    for tte in [-w.beta, 2.0 * PI - w.beta] { // upper surface, then lower
        let thv: Vec<f64> = (0..=n).map(|k| ths + (tte - ths) * k as f64 / n as f64).collect();
        let mut ue = vec![0.0]; for t in &thv[1..n] { ue.push(u * speed(w, *t, al)); } ue.push(ue[ue.len() - 1]);
        let mut zz: Vec<Cx> = thv[..n].iter().map(|t| pos(w, *t)).collect(); zz.push(cx(2.0, 0.0));
        let mut s = vec![0.0]; for k in 1..=n { s.push(s[k - 1] + abs(sub(zz[k], zz[k - 1])) * sc); }
        let (ks, cd, dl) = march(&s, &mut ue, hsep, u);
        let (xs, ys) = match ks { Some(k) => ((zz[k].re - (2.0 - w.ch)) / w.ch, zz[k].im / w.ch), None => (1.0, 0.0) };
        out.push((xs, cd, ys, dl));
    }
    let (fs, ae) = (out[0].0, al + w.beta); let f = w.k * ae.sin(); let g = ((1.0 + fs.sqrt()) / 2.0).powf(2.0);
    let cl = f * (g * ae.cos().powf(2.0) + fs.sqrt() * ae.sin().powf(2.0)); // Kirchhoff: normal x g, suction x sqrt f
    let cdp = f * ae.sin() * ae.cos() * (g - fs.sqrt());
    (f, fs, cl, out[0].1 + out[1].1 + cdp, cdp, out[0])
}
fn stall(w: &Wing, hsep: f64, u: f64, n: usize) -> (f64, f64) { // scan, then golden-section on the peak
    let mut best = 0; let mut bv = f64::NEG_INFINITY;
    for d in 0..26 { let v = section(w, d as f64, hsep, u, n).2; if v > bv { bv = v; best = d; } }
    let (mut lo, mut hi) = (best as f64 - 1.0, best as f64 + 1.0); let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..25 {
        let (x1, x2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if section(w, x1, hsep, u, n).2 > section(w, x2, hsep, u, n).2 { hi = x2 } else { lo = x1 }
    }
    let a = (lo + hi) / 2.0; (a, section(w, a, hsep, u, n).2)
}
fn p(label: &str, v: String) { println!("{:<46}{}", label, v); }
fn commas(v: f64) -> String { let s = format!("{:.0}", v); let b = s.as_bytes(); let mut o = String::new();
    for (i, c) in b.iter().enumerate() { if i > 0 && (b.len() - i) % 3 == 0 { o.push(','); } o.push(*c as char); } o }

fn main() {
    let u: f64 = 40.0; let w = wing(0.10, 0.06); let qd = 0.5 * rho() * u.powf(2.0); let re = u * C / nu(); let al = 8f64.to_radians();
    p("air density, kg/m^3", format!("{:.4}", rho())); p("kinematic viscosity, mm^2/s", format!("{:.4}", nu() * 1e6));
    p("Reynolds number U c / nu", commas(re)); p("Mach number U / sqrt(1.4 R T / M)", format!("{:.4}", u / (1.4 * R * T0 / M_AIR).sqrt()));
    p("dynamic pressure 1/2 rho U^2, Pa", format!("{:.2}", qd)); p("wing area c x span, m^2", format!("{:.3}", C * SPAN));
    p("thickness, fraction of chord", format!("{:.4}", w.t)); p("camber, fraction of chord", format!("{:.4}", w.f));
    p("zero-lift angle, deg", format!("{:.4}", -w.beta.to_degrees()));
    p("zero-lift angle, thin aerofoil -2 f/c, deg", format!("{:.4}", -(2.0 * w.f).to_degrees()));
    p("lift slope k, per rad (thin aerofoil 2 pi)", format!("{:.4}", w.k));
    let (f8, s8, cl8, cd8, cdp8, up8) = section(&w, 8.0, 2.0, u, N); let clp = cl_by_pressure(&w, al, 20000);
    let gam = 4.0 * PI * u * w.a * C / w.ch * (al + w.beta).sin();
    p("8 deg: circulation Gamma, m^2/s", format!("{:.4}", gam)); p("8 deg: lift per metre rho U Gamma, N/m", format!("{:.3}", rho() * u * gam));
    p("8 deg: C_L by circulation, no layer", format!("{:.4}", f8)); p("8 deg: C_L by summed pressure, no layer", format!("{:.4}", clp));
    p("8 deg: C_L slope 2 pi, exact a0", format!("{:.4}", 2.0 * PI * (al + w.beta)));
    let ae = al + w.beta; println!("{:<46}{:.4}  {:.4}  {:.4}  {:.4}", "8 deg: a - a0 deg, sin, g, sqrt f", ae.to_degrees(), ae.sin(), ((1.0 + s8.sqrt()) / 2.0).powf(2.0), s8.sqrt());
    p("8 deg: separation point x/c, upper", format!("{:.4}", s8)); p("8 deg: C_L with the layer", format!("{:.4}", cl8));
    p("8 deg: C_D, wake plus separation", format!("{:.5}", cd8)); p("8 deg: of which separation pressure", format!("{:.5}", cdp8));
    p("8 deg: upper layer thickness, back edge, mm", format!("{:.1}", 1000.0 * up8.3));
    let (l8, d8) = (cl8 * qd * C * SPAN, cd8 * qd * C * SPAN);
    p("8 deg: lift N, drag N, lift / drag", format!("{:.2}  {:.3}  {:.2}", l8, d8, l8 / d8));
    let (sa, clm) = stall(&w, 2.0, u, N); let (s18, c18) = stall(&w, 1.8, u, N); let (s24, c24) = stall(&w, 2.4, u, N);
    p("stall deg, margin deg, maximum C_L (H = 2.0)", format!("{:.2}  {:.2}  {:.4}", sa, sa - 8.0, clm));
    p("H = 1.8: stall angle deg, maximum C_L", format!("{:.2}  {:.4}", s18, c18));
    p("H = 2.4: stall angle deg, maximum C_L", format!("{:.2}  {:.4}", s24, c24));
    println!("angle  C_L no layer  sep x/c   C_L      C_D"); let mut rows = vec![];
    for d in (0..21).step_by(2) {
        let r = section(&w, d as f64, 2.0, u, N); rows.push(r);
        println!("{:>5} {:>10.4} {:>10.3} {:>8.4} {:>8.5}", d, r.0, r.1, r.2, r.3);
    }
    let s: Vec<f64> = (0..=N).map(|k| C * k as f64 / N as f64).collect(); // road 4: a flat plate, turbulent from the front edge
    let mut ue = vec![u; N + 1]; ue[0] = 0.0; let fp = march(&s, &mut ue, 2.0, u).1;
    p("plate C_f one side: march, 0.074 Re^-0.2", format!("{:.5}  {:.5}", fp, 0.074 * re.powf(-0.2)));
    let th_lam = thwaites(&s, &vec![u; N + 1], N); // road 5: Thwaites on a laminar plate, against Blasius
    p("laminar plate theta mm: Thwaites, Blasius", format!("{:.4}  {:.4}", 1000.0 * th_lam, 664.0 * C / re.sqrt()));
    let (_, f8f, cl8f, cd8f, _, _) = section(&w, 8.0, 2.0, u, 4 * N); let saf = stall(&w, 2.0, u, 4 * N).0; // road 6: 4 x the steps
    p("4 x steps: 8 deg x/c, C_D, lift N; stall deg", format!("{:.4}  {:.5}  {:.2}  {:.2}", f8f, cd8f, cl8f * qd * C * SPAN, saf));
    p("wrong: degrees in 2 pi (a - a0)", format!("{:.2}", 2.0 * PI * (8.0 + w.beta.to_degrees())));
    p("wrong: camber left out, k sin a", format!("{:.4}", w.k * al.sin()));
    p("wrong: straight line at 20 deg", format!("{:.4}", rows[10].0));
    p("wrong: laminar friction, both sides", format!("{:.5}", 2.0 * 1.328 / re.sqrt()));
    p("wrong: no 1/2 in dynamic pressure, lift N", format!("{:.2}", 2.0 * l8));
    let sx = |f: f64| 40.0 + 480.0 * f; // figure: 480 px of chord
    let sy = |y: f64| 130.0 - 480.0 * y; // chord line at y = 130 px, up is smaller y
    println!("figure, leading edge x {:.1}, trailing edge x {:.1}, separation at 8 deg ({:.1}, {:.1}), at 14 deg ({:.1}, {:.1})",
        sx(0.0), sx(1.0), sx(s8), sy(up8.2), sx(rows[7].1), sy(rows[7].5 .2));
    p("try: tunnel at 20 m/s, stall angle deg", format!("{:.2}", stall(&w, 2.0, 20.0, N).0));
    let wt = wing(0.06, 0.06);
    p("try: thinner wing, thickness, stall angle deg", format!("{:.4}  {:.2}", wt.t, stall(&wt, 2.0, u, N).0));
    p("try: no camber, stall angle deg", format!("{:.2}", stall(&wing(0.10, 0.0), 2.0, u, N).0));
    assert!((f8 - clp).abs() < 1e-3); // circulation and pressure agree
    assert!((fp - 0.074 * re.powf(-0.2)).abs() < 0.15 * 0.074 * re.powf(-0.2)); // within the flat-plate fits' spread
    assert!((w.beta - 2.0 * w.f).abs() < 0.01 * w.beta); // camber read off the shape predicts the zero-lift angle
    assert!(13.0 < sa && sa < 17.0 && s18 < sa && sa < s24); // stall near fifteen degrees, later if separation is judged later
    assert!([1.3, 1.5, 2.0, 2.4].iter().all(|h| (h_of(h1_of(*h)) - h).abs() < 0.005)); // Head's two fits invert each other
    assert!(rows.windows(2).all(|r| r[0].1 >= r[1].1)); // separation creeps forward as angle grows
    assert!(2.0 * fp < rows[0].3 && rows[0].3 < 1.3 * 2.0 * fp); // profile drag a little above flat-plate friction
    assert!((th_lam / (0.664 * C / re.sqrt()) - 1.0).abs() < 0.02); // Thwaites within 2% of the exact Blasius plate
    assert!((f8f - s8).abs() < 0.002 && (cd8f / cd8 - 1.0).abs() < 0.01 && (saf - sa).abs() < 0.2); // step size settled
    println!("ALL CHECKS PASS");
}
