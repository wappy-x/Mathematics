// Stress, strain and bending -- the same check as the Python, in Rust.  No crates.
// A 4 m steel joist, pinned at both ends, 2 kN at mid-span.  Sizes it against a
// sag limit and a stress limit, then reaches the sag three independent ways.
const L: f64 = 4.0; const P: f64 = 2000.0; const E: f64 = 200e9; const G: f64 = 9.80665;
const SIGMA_Y: f64 = 275e6; const RHO: f64 = 7850.0;   // S275 yield stress Pa, steel kg/m^3
const SAG_LIM: f64 = L / 360.0; const STRESS_LIM: f64 = 0.6 * SIGMA_Y;
// depth h, flange b x tf, web tw, in mm
const SECTIONS: [(&str, [f64; 4]); 3] = [("80 mm I", [80.0, 46.0, 5.2, 3.8]),
    ("100 mm I", [100.0, 55.0, 5.7, 4.1]), ("120 mm I", [120.0, 64.0, 6.3, 4.4])];

fn i_formula(s: [f64; 4]) -> f64 {            // road 1 for I: three rectangles
    let (h, b, tf, tw) = (s[0], s[1], s[2], s[3]);
    let (hw, d) = (h - 2.0 * tf, (h - tf) / 2.0);
    2.0 * (b * tf.powi(3) / 12.0 + b * tf * d * d) + tw * hw.powi(3) / 12.0
}
fn i_strips(s: [f64; 4]) -> f64 {             // road 2 for I: add up y^2 dA, strip by strip
    let (h, b, tf, tw, dy) = (s[0], s[1], s[2], s[3], 0.05);
    let mut total = 0.0;
    for k in 0..(h / dy).round() as usize {
        let y = -h / 2.0 + (k as f64 + 0.5) * dy;
        let width = if y.abs() > h / 2.0 - tf { b } else { tw };
        total += width * dy * y * y;
    }
    total
}
fn strip_sums(s: [f64; 4], s_face: f64) -> (f64, f64, f64) { // net push, turning effect, sum |y| dA
    let (h, b, tf, tw, dy) = (s[0], s[1], s[2], s[3], 0.05);
    let (mut force, mut turn, mut z) = (0.0, 0.0, 0.0);
    for k in 0..(h / dy).round() as usize {
        let y = -h / 2.0 + (k as f64 + 0.5) * dy;
        let da = (if y.abs() > h / 2.0 - tf { b } else { tw }) * dy;
        let sig = -s_face * y / (h / 2.0);
        force += sig * da * 1e-6; turn -= sig * y * da * 1e-9; z += y.abs() * da;
    }
    (force, turn, z)
}
fn area(s: [f64; 4]) -> f64 { 2.0 * s[1] * s[2] + (s[0] - 2.0 * s[2]) * s[3] }
fn moment(x: f64) -> f64 { P * x.min(L - x) / 2.0 }
fn sag_formula(ei: f64) -> f64 { P * L.powi(3) / (48.0 * ei) }
fn sag_fd(ei: f64, n: usize, mom: &dyn Fn(f64) -> f64) -> Vec<f64> { // road 2: EI v'' = -M(x)
    let h = L / n as f64;                      // finite differences, Thomas algorithm
    let rhs: Vec<f64> = (1..n).map(|i| -h * h * mom(i as f64 * h) / ei).collect();
    let (mut c, mut d) = (vec![0.0; n - 1], vec![0.0; n - 1]);
    for i in 0..n - 1 {
        let m = -2.0 - if i > 0 { c[i - 1] } else { 0.0 };
        c[i] = 1.0 / m;
        d[i] = (rhs[i] - if i > 0 { d[i - 1] } else { 0.0 }) / m;
    }
    let mut v = vec![0.0; n + 1];
    for i in (0..n - 1).rev() { v[i + 1] = d[i] - c[i] * v[i + 2]; }
    v
}
fn sag_energy(ei: f64, n: usize) -> f64 {     // road 3: work P sag / 2 = stored energy
    let (h, mut s) = (L / n as f64, 0.0);      // the integral of M^2 / (2 EI), by Simpson
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * moment(i as f64 * h).powi(2);
    }
    2.0 * (s * h / 3.0) / (2.0 * ei) / P
}
fn shape(ei: f64, x: f64) -> f64 { let x = x.min(L - x); P * x * (3.0 * L * L - 4.0 * x * x) / (48.0 * ei) }

fn main() {
    let m = P * L / 4.0;
    println!("joist: span {:.1} m, pinned ends, {:.0} N at mid-span = {:.1} kg, E = {:.0} GPa", L, P, P / G, E / 1e9);
    println!("limits: sag L/360 = {:.2} mm, stress 0.6 x {:.0} = {:.0} MPa", SAG_LIM * 1e3, SIGMA_Y / 1e6, STRESS_LIM / 1e6);
    println!("largest bending moment PL/4 = {:.0} N m", m);
    println!("needed: I >= {:.2} cm^4 (sag), W >= {:.2} cm^3 (stress)",
             P * L.powi(3) / (48.0 * E * SAG_LIM) * 1e8, m / STRESS_LIM * 1e6);
    println!("{:<10}{:>9}{:>9}{:>8}{:>8}{:>8}{:>7}  verdict", "section", "I cm^4", "strips", "W cm^3", "sag mm", "MPa", "kg/m");
    let mut rows: Vec<(&str, f64, f64, f64, f64, f64, &str)> = vec![];
    for (name, dims) in SECTIONS {
        let (i1, i2) = (i_formula(dims), i_strips(dims));
        assert!((i1 - i2).abs() / i1 < 1e-6);   // two roads to I agree
        let (i, w) = (i1 * 1e-12, i1 / (dims[0] / 2.0) * 1e-9);
        let (sag, stress, kg) = (sag_formula(E * i), m / w, area(dims) * 1e-6 * RHO);
        let (ok_sag, ok_str) = (sag <= SAG_LIM, stress <= STRESS_LIM);
        let verdict = if ok_sag && ok_str { "passes both" } else if ok_str { "fails sag" } else { "fails stress" };
        rows.push((name, i, w, sag, stress, kg, verdict));
        println!("{:<10}{:9.2}{:9.2}{:8.2}{:8.2}{:8.2}{:7.2}  {}", name, i1 / 1e4, i2 / 1e4, w * 1e6, sag * 1e3, stress / 1e6, kg, verdict);
    }
    let r = *rows.iter().filter(|r| r.6 == "passes both").min_by(|a, b| a.5.partial_cmp(&b.5).unwrap()).unwrap();
    let (chosen, i, w, sag, stress, kg) = (r.0, r.1, r.2, r.3, r.4, r.5);
    let dims = SECTIONS.iter().find(|s| s.0 == chosen).unwrap().1;
    let (h, b, tf, tw) = (dims[0], dims[1], dims[2], dims[3]);
    let ei = E * i;
    let v = sag_fd(ei, 400, &moment);
    println!("lightest section passing both: {}, EI = {:.0} N m^2", chosen, ei);
    let i_web = tw * (h - 2.0 * tf).powi(3) / 12.0;
    println!("its I, cm^4: flanges {:.2} + web {:.2}", (i * 1e12 - i_web) / 1e4, i_web / 1e4);
    println!("sag, road 1 formula PL^3/48EI:  {:.4} mm", sag * 1e3);
    println!("sag, road 2 finite differences: {:.4} mm", v[200] * 1e3);
    println!("sag, road 3 energy integral:    {:.4} mm", sag_energy(ei, 400) * 1e3);
    assert!((v[200] - sag).abs() / sag < 1e-4 && (sag_energy(ei, 400) - sag).abs() / sag < 1e-9);
    assert!(rows[0].6 == "fails sag" && chosen == "100 mm I");
    assert!((0..9).map(|k| (v[50 * k] - shape(ei, 0.5 * k as f64)).abs()).fold(0.0, f64::max) < 1e-6);
    let (strain, slope) = (stress / E, P * L * L / (16.0 * ei));
    println!("outer-face stress {:.2} MPa, strain {:.6} = {:.3} mm per m", stress / 1e6, strain, strain * 1e3);
    let (force, turn, z_strips) = strip_sums(dims, stress);
    println!("strips at that stress: net push {:.3} N, turning effect {:.2} N m", force.abs(), turn);
    assert!(force.abs() < 1e-6 * P && (turn - m).abs() / m < 1e-6); // the stresses add up to the moment
    println!("end slope PL^2/16EI = {:.5} rad = {:.3} deg", slope, slope * 180.0 / 3.141592653589793);
    let w_self = kg * G;
    let extra = 5.0 * w_self * L.powi(4) / (384.0 * ei);
    let extra_fd = sag_fd(ei, 400, &|x: f64| w_self * x * (L - x) / 2.0)[200]; // same solver, spread load
    println!("self-weight {:.2} N/m adds {:.2} mm (finite differences {:.2}): total {:.2} mm",
             w_self, extra * 1e3, extra_fd * 1e3, (sag + extra) * 1e3);
    assert!((extra_fd - extra).abs() / extra < 1e-4);
    let xs: String = (0..9).map(|k| format!("{:7.1}", 0.5 * k as f64)).collect();
    println!("chart, x m       {}", xs);
    for row in &rows[..2] {
        let pts: String = (0..9).map(|k| format!("{:7.2}", shape(E * row.1, 0.5 * k as f64) * 1e3)).collect();
        println!("chart, {:<10}{}", row.0, pts);
    }
    let i_weak = (2.0 * tf * b.powi(3) / 12.0 + (h - 2.0 * tf) * tw.powi(3) / 12.0) * 1e-12;
    let (sag_weak, sag_clamp) = (sag_formula(E * i_weak), P * L.powi(3) / (192.0 * ei));
    println!("wrong: sized by stress only, 80 mm I sags {:.2} mm, limit {:.2} mm", rows[0].3 * 1e3, SAG_LIM * 1e3);
    println!("wrong: section on its side, I = {:.2} cm^4, sag {:.2} mm", i_weak * 1e8, sag_weak * 1e3);
    println!("wrong: ends taken as clamped, PL^3/192EI = {:.2} mm", sag_clamp * 1e3);
    println!("wrong: 2 kN spread evenly, sag 5PL^3/384EI = {:.2} mm, stress {:.2} MPa",
             5.0 * P * L.powi(3) / (384.0 * ei) * 1e3, P * L / 8.0 / w / 1e6);
    assert!(sag_weak > 5.0 * SAG_LIM && 5.0 * SAG_LIM > sag);
    let p_yield = 4.0 * w * SIGMA_Y / L;
    println!("outside the model: yield at P = {:.0} N; at 12000 N the formula says {:.0} MPa", p_yield, 12000.0 * L / 4.0 / w / 1e6);
    let z_formula = b * tf * (h - tf) + tw * (h - 2.0 * tf).powi(2) / 4.0; // mm^3, whole section yielded
    let p_fold = 4.0 * z_formula * 1e-9 * SIGMA_Y / L;
    println!("outside the model: section yielded through, Z = {:.2} cm^3 (strips {:.2}), folds at P = {:.0} N",
             z_formula / 1e3, z_strips / 1e3, p_fold);
    assert!((z_strips - z_formula).abs() / z_formula < 1e-6 && p_yield < p_fold && p_fold < 12000.0);
    println!("try: P = 3000 N sags {:.2} mm; L = 5 m sags {:.2} mm against {:.2} mm; aluminium, E = 70 GPa, sags {:.2} mm",
             sag * 1.5 * 1e3, P * 5f64.powi(3) / (48.0 * ei) * 1e3, 5.0 / 360.0 * 1e3, sag_formula(70e9 * i) * 1e3);
    let fig: Vec<String> = (0..9).map(|k| format!("{:.1}", shape(ei, 0.5 * k as f64) * 5e3)).collect();
    println!("figure, elevation 80 px/m, sag 5 px/mm, y px below beam at x = 0.5 m steps: {}", fig.join(" "));
    println!("figure, section 1 px/mm, {} x {} mm, flange {} mm, web {} mm; stress 0.5 px/MPa: {:.1} px",
             h, b, tf, tw, stress / 1e6 * 0.5);
    println!("ALL CHECKS PASS");
}
