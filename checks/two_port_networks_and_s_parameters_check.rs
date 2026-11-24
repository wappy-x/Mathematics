// Two-port networks and S-parameters -- the check behind the card.  std only, no crates.
// A 3 dB pi attenuator for a 50 ohm system, then two of them in a row.  Every number on
// the card is printed here.  Road 1: the design formulas.  Road 2: multiply the three
// element ABCD matrices and convert to S.  Road 3: solve the circuit by Kirchhoff's node
// equations with a 50 ohm source and load.  Road 4: Z from open-circuit node solves,
// then S = (Z - Z0)(Z + Z0)^-1.  The cascade is checked by ABCD, by S algebra and by nodes.
type M = [[f64; 2]; 2];
type S4 = (f64, f64, f64, f64); // (S11, S21, S12, S22)
const Z0: f64 = 50.0; // ohms
const DB: f64 = 3.0; // attenuation in decibels

fn design(db: f64, z0: f64) -> (f64, f64, f64) {
    let k = 10f64.powf(db / 20.0); // voltage ratio for db decibels
    (k, z0 * (k + 1.0) / (k - 1.0), z0 * (k * k - 1.0) / (2.0 * k))
}
fn mul(p: M, q: M) -> M {
    let mut r = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { r[i][j] = p[i][0] * q[0][j] + p[i][1] * q[1][j]; } }
    r
}
fn inv(m: M) -> M {
    let d = m[0][0] * m[1][1] - m[0][1] * m[1][0];
    [[m[1][1] / d, -m[0][1] / d], [-m[1][0] / d, m[0][0] / d]]
}
fn series(z: f64) -> M { [[1.0, z], [0.0, 1.0]] }
fn shunt(r: f64) -> M { [[1.0, 0.0], [1.0 / r, 1.0]] }
fn pad_abcd(rp: f64, rs: f64) -> M { mul(mul(shunt(rp), series(rs)), shunt(rp)) }
fn abcd_to_s(m: M, z0: f64) -> S4 {
    let (a, b, c, d) = (m[0][0], m[0][1], m[1][0], m[1][1]);
    let den = a + b / z0 + c * z0 + d;
    ((a + b / z0 - c * z0 - d) / den, 2.0 / den, 2.0 * (a * d - b * c) / den,
     (-a + b / z0 - c * z0 + d) / den)
}
fn z_to_s(z: M, z0: f64) -> S4 {
    let s = mul([[z[0][0] - z0, z[0][1]], [z[1][0], z[1][1] - z0]],
                inv([[z[0][0] + z0, z[0][1]], [z[1][0], z[1][1] + z0]]));
    (s[0][0], s[1][0], s[0][1], s[1][1])
}
fn solve(mut g: Vec<Vec<f64>>, mut rhs: Vec<f64>) -> Vec<f64> { // Gaussian elimination
    let n = rhs.len();
    for c in 0..n {
        for r in c + 1..n {
            let f = g[r][c] / g[c][c];
            for j in 0..n { g[r][j] -= f * g[c][j]; }
            rhs[r] -= f * rhs[c];
        }
    }
    let mut v = vec![0.0; n];
    for r in (0..n).rev() {
        let s: f64 = (r + 1..n).map(|j| g[r][j] * v[j]).sum();
        v[r] = (rhs[r] - s) / g[r][r];
    }
    v
}
fn nodes(sh: &[f64], se: &[f64], g_src: f64, g_load: f64, inj: f64) -> Vec<f64> {
    let n = sh.len();
    let mut g = vec![vec![0.0; n]; n];
    for (i, r) in sh.iter().enumerate() { g[i][i] += 1.0 / r; }
    for (i, r) in se.iter().enumerate() {
        g[i][i] += 1.0 / r; g[i + 1][i + 1] += 1.0 / r; g[i][i + 1] -= 1.0 / r; g[i + 1][i] -= 1.0 / r;
    }
    g[0][0] += g_src; g[n - 1][n - 1] += g_load;
    let mut rhs = vec![0.0; n]; rhs[0] = inj;
    solve(g, rhs)
}
fn s_by_nodes(sh: &[f64], se: &[f64], z0: f64) -> (f64, f64, Vec<f64>) { // EMF 2 V: incident 1 V
    let v = nodes(sh, se, 1.0 / z0, 1.0 / z0, 2.0 / z0);
    (v[0] - 1.0, v[v.len() - 1], v)
}
fn z_by_nodes(sh: &[f64], se: &[f64]) -> M { // 1 A in at a port, other port open
    let (shr, ser): (Vec<f64>, Vec<f64>) = (sh.iter().rev().cloned().collect(), se.iter().rev().cloned().collect());
    let (a, b) = (nodes(sh, se, 0.0, 0.0, 1.0), nodes(&shr, &ser, 0.0, 0.0, 1.0));
    [[a[0], b[b.len() - 1]], [a[a.len() - 1], b[0]]]
}
fn cascade_s(p: S4, q: S4) -> (f64, f64) { // S algebra with the echo between
    let e = 1.0 - p.3 * q.0;
    (p.0 + p.2 * p.1 * q.0 / e, p.1 * q.1 / e)
}
fn f(x: f64) -> String { format!("{:.4}", if x.abs() < 5e-9 { 0.0 } else { x }) } // no "-0.0000"
fn row(xs: &[String]) { println!("{}", xs.join(", ")); }
macro_rules! r { ($($x:expr),*) => { row(&[$($x.to_string()),*]) }; }

fn main() {
    let (k, rp, rs) = design(DB, Z0);
    r!("design", format!("K {}", f(k)), format!("shunt {:.2} ohm", rp), format!("series {:.2} ohm", rs));
    let m = pad_abcd(rp, rs);
    r!("ABCD", f(m[0][0]), f(m[0][1]), f(m[1][0] * 1000.0), f(m[1][1]), format!("AD-BC {}", f(m[0][0] * m[1][1] - m[0][1] * m[1][0])));
    let s_abcd = abcd_to_s(m, Z0);
    let (s11_n, s21_n, v) = s_by_nodes(&[rp, rp], &[rs], Z0);
    let z = z_by_nodes(&[rp, rp], &[rs]);
    let s_z = z_to_s(z, Z0);
    let y = inv(z);
    r!("Z ohm", f(z[0][0]), f(z[0][1]), f(z[1][0]), f(z[1][1]));
    r!("Y mS", f(1000.0 * y[0][0]), f(1000.0 * y[0][1]), f(1000.0 * y[1][0]), f(1000.0 * y[1][1]));
    r!("Y from ABCD mS", f(1000.0 * m[1][1] / m[0][1]), f(-1000.0 / m[0][1]));
    r!("even odd ohm", f(z[0][0] + z[0][1]), f(z[0][0] - z[0][1]));
    let (ze, zo) = (z[0][0] + z[0][1], z[0][0] - z[0][1]); // both ports driven alike, or opposite
    r!("even odd reflections", f((ze - Z0) / (ze + Z0)), f((zo - Z0) / (zo + Z0)), format!("Ze Zo {} ohm^2", f(ze * zo)));
    r!("ABCD to S", format!("A+B/Z0 {}", f(m[0][0] + m[0][1] / Z0)), format!("C Z0+D {}", f(m[1][0] * Z0 + m[1][1])),
       format!("sum {}", f(m[0][0] + m[0][1] / Z0 + m[1][0] * Z0 + m[1][1])));
    r!("S road 1", "S11 0.0000", format!("S21 {}", f(1.0 / k)));
    for (name, s) in [("S road 2 ABCD", s_abcd), ("S road 4 Z", s_z)] {
        r!(name, format!("S11 {}", f(s.0)), format!("S21 {}", f(s.1)), format!("S12 {}", f(s.2)), format!("S22 {}", f(s.3)));
    }
    r!("S road 3 nodes", format!("S11 {}", f(s11_n)), format!("S21 {}", f(s21_n)), format!("V1 {} V", f(v[0])), format!("V2 {} V", f(v[1])));
    let p_res = (v[0] * v[0] + v[1] * v[1]) / rp + (v[0] - v[1]).powi(2) / rs;
    let p_inc = 1.0 / Z0; // reference power of the 1 V wave; only ratios are printed
    r!("power share", format!("to load {}", f(s21_n * s21_n)), format!("in resistors {}", f(p_res / p_inc)),
       format!("from S {}", f(1.0 - s11_n * s11_n - s21_n * s21_n)));
    r!("0 dBm in, mW", format!("to load {}", f(s21_n * s21_n)), format!("shunt in {}", f(v[0] * v[0] / rp / p_inc)),
       format!("series {}", f((v[0] - v[1]).powi(2) / rs / p_inc)), format!("shunt out {}", f(v[1] * v[1] / rp / p_inc)));
    let m2 = mul(m, m);
    let (c_abcd, c_alg) = (abcd_to_s(m2, Z0), cascade_s(s_abcd, s_abcd));
    let c_n = s_by_nodes(&[rp, rp / 2.0, rp], &[rs, rs], Z0);
    r!("two pads ABCD", f(m2[0][0]), f(m2[0][1]), f(m2[1][0] * 1000.0), f(m2[1][1]));
    r!("two pads S21", format!("ABCD {}", f(c_abcd.1)), format!("S algebra {}", f(c_alg.1)), format!("nodes {}", f(c_n.1)),
       format!("loss {:.4} dB", -20.0 * c_abcd.1.log10()));
    r!("two pads S11", format!("ABCD {}", f(c_abcd.0)), format!("S algebra {}", f(c_alg.0)), format!("nodes {}", f(c_n.0)));
    // ---- what breaks ----
    let (_, rp6, rs6) = design(2.0 * DB, Z0); // 10 log used for a voltage ratio
    r!("wrong: 10 log", format!("shunt {:.2} ohm", rp6), format!("series {:.2} ohm", rs6), format!("S21 {}", f(abcd_to_s(pad_abcd(rp6, rs6), Z0).1)));
    let sm = [[s_abcd.0, s_abcd.2], [s_abcd.1, s_abcd.3]];
    let ss = mul(sm, sm);
    r!("wrong: S times S", format!("S11 {}", f(ss[0][0])), format!("S21 {}", f(ss[1][0])));
    let zz = z_to_s(mul(z, z), Z0);
    r!("wrong: Z times Z", format!("S11 {}", f(zz.0)), format!("S21 {}", f(zz.1)));
    let (_, rp75, rs75) = design(DB, 75.0);
    let s75 = abcd_to_s(pad_abcd(rp75, rs75), Z0);
    let c75 = abcd_to_s(mul(pad_abcd(rp75, rs75), pad_abcd(rp75, rs75)), Z0);
    let c75a = cascade_s(s75, s75);
    r!("75 ohm pads in 50", format!("S11 {}", f(s75.0)), format!("S21 {}", f(s75.1)), format!("product {}", f(s75.1 * s75.1)),
       format!("true {}", f(c75.1)), format!("S algebra {}", f(c75a.1)), format!("loss {:.4} dB", -20.0 * c75.1.log10()));
    let gl = (75.0 - Z0) / (75.0 + Z0);
    let gin = s_abcd.0 + s_abcd.2 * s_abcd.1 * gl / (1.0 - s_abcd.3 * gl);
    let (a, b) = (m[0][0] * 75.0 + m[0][1], m[1][0] * 75.0 + m[1][1]); // (A RL + B)/(C RL + D)
    r!("75 ohm load", format!("bare {}", f(gl)), format!("through pad {}", f(gin)), format!("Zin {} ohm", f(a / b)),
       format!("from Zin {}", f((a / b - Z0) / (a / b + Z0))));
    for d in [6.0, 10.0, 20.0] {
        let (kk, p1, p2) = design(d, Z0);
        r!(format!("try {:.0} dB", d), format!("shunt {:.2} ohm", p1), format!("series {:.2} ohm", p2), format!("S21 {}", f(1.0 / kk)));
    }
    let (_, p1, p2) = design(DB, 75.0);
    r!("try 75 ohm", format!("shunt {:.2} ohm", p1), format!("series {:.2} ohm", p2));
    let t3 = abcd_to_s(mul(m2, m), Z0).1;
    r!("try three pads", format!("S21 {}", f(t3)), format!("loss {:.4} dB", -20.0 * t3.log10()));
    let rr = abcd_to_s(pad_abcd(292.4, 17.6), Z0);
    r!("rounded 292.4 and 17.6", format!("S11 {:.6}", rr.0), format!("S21 {}", f(rr.1)));
    r!("figure", "pad x 120 to 300", "shunts at x 140 and 280", "ports at x 40 and 380");
    assert!(s11_n.abs() < 1e-12 && s_z.0.abs() < 1e-12 && s_abcd.0.abs() < 1e-12);
    assert!((s21_n - 1.0 / k).abs() < 1e-12 && (s_z.1 - s_abcd.1).abs() < 1e-12 && (s_abcd.2 - s21_n).abs() < 1e-12);
    assert!((y[0][0] - m[1][1] / m[0][1]).abs() < 1e-12 && (y[1][0] + 1.0 / m[0][1]).abs() < 1e-12);
    assert!((p_res / p_inc - (1.0 - s21_n * s21_n)).abs() < 1e-12);
    assert!((c_abcd.1 - c_n.1).abs() < 1e-12 && (c_alg.1 - c_n.1).abs() < 1e-12 && (c_abcd.1 - 10f64.powf(-6.0 / 20.0)).abs() < 1e-12);
    assert!((c75.1 - c75a.1).abs() < 1e-12 && (c75.1 - s75.1 * s75.1).abs() > 1e-4);
    assert!((gin - (a / b - Z0) / (a / b + Z0)).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
