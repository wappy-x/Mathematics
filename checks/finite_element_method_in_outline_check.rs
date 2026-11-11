// Finite elements in outline -- the same check as the Python, in Rust.  No crates.
// A 3 m steel cantilever (the 120 mm I) holds 1 kN at its tip.  Cut it into three
// 1 m beam elements, assemble one stiffness matrix, fix the wall, solve K u = F.
const L: f64 = 3.0; const NE: usize = 3; const P: f64 = 1000.0; const E: f64 = 200e9;
const G: f64 = 9.80665; const RHO: f64 = 7850.0; const SIGMA_Y: f64 = 275e6;
const H: f64 = 120.0; const B: f64 = 64.0; const TF: f64 = 6.3; const TW: f64 = 4.4; // mm

fn ei() -> f64 {
    let i = 2.0 * (B * TF.powi(3) / 12.0 + B * TF * ((H - TF) / 2.0).powi(2)) + TW * (H - 2.0 * TF).powi(3) / 12.0;
    E * i * 1e-12
}
fn k_formula(le: f64) -> Vec<Vec<f64>> {     // element stiffness, unknowns (v1, th1, v2, th2): road 1
    let (a, l) = (ei() / le.powi(3), le);
    vec![vec![12.0*a, 6.0*l*a, -12.0*a, 6.0*l*a], vec![6.0*l*a, 4.0*l*l*a, -6.0*l*a, 2.0*l*l*a],
         vec![-12.0*a, -6.0*l*a, 12.0*a, -6.0*l*a], vec![6.0*l*a, 2.0*l*l*a, -6.0*l*a, 4.0*l*l*a]]
}
fn curv(s: f64, le: f64) -> [f64; 4] {        // second derivatives of the four cubic shape functions
    [(-6.0 + 12.0*s) / le.powi(2), (-4.0 + 6.0*s) / le, (6.0 - 12.0*s) / le.powi(2), (-2.0 + 6.0*s) / le]
}
fn simpson_w(m: usize, n: usize) -> f64 { if m == 0 || m == n { 1.0 } else if m % 2 == 1 { 4.0 } else { 2.0 } }
fn k_energy(le: f64, n: usize) -> Vec<Vec<f64>> { // road 2: k_ij = integral of EI N_i'' N_j'' dx
    let mut k = vec![vec![0.0; 4]; 4];
    for m in 0..=n {
        let (wt, c) = (simpson_w(m, n) * le / n as f64 / 3.0, curv(m as f64 / n as f64, le));
        for i in 0..4 { for j in 0..4 { k[i][j] += wt * ei() * c[i] * c[j]; } }
    }
    k
}
fn assemble(ne: usize, le: f64, add: bool) -> Vec<Vec<f64>> { // each element adds its 4x4 block
    let n = 2 * (ne + 1);
    let (mut k, ke) = (vec![vec![0.0; n]; n], k_formula(le));
    for e in 0..ne { for i in 0..4 { for j in 0..4 {
        k[2*e+i][2*e+j] = (if add { k[2*e+i][2*e+j] } else { 0.0 }) + ke[i][j];
    } } }
    k
}
fn solve(a: &Vec<Vec<f64>>, rhs: &[f64]) -> Vec<f64> { // Gaussian elimination with row swaps
    let n = rhs.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(rhs[i]); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            m[r] = (0..=n).map(|k| m[r][k] - f * m[c][k]).collect();
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let mut s = 0.0;
        for k in i + 1..n { s += m[i][k] * x[k]; }
        x[i] = (m[i][n] - s) / m[i][i];
    }
    x
}
fn fem(ne: usize, loads: &[f64], add: bool) -> (Vec<f64>, Vec<Vec<f64>>) { // fix the wall, solve
    let k = assemble(ne, L / ne as f64, add);
    let free: Vec<Vec<f64>> = k[2..].iter().map(|r| r[2..].to_vec()).collect();
    let mut u = vec![0.0, 0.0];
    u.extend(solve(&free, &loads[2..]));
    (u, k)
}
fn fd_tip(n: usize) -> f64 {                  // finite differences on v'' = P(L - x)/EI, ghost point
    let hh = L / n as f64;
    let mut v = vec![0.0, hh * hh * P * L / ei() / 2.0];
    for i in 1..n { let nv = 2.0 * v[i] - v[i - 1] + hh * hh * P * (L - i as f64 * hh) / ei(); v.push(nv); }
    v[n]
}
fn exact(x: f64) -> f64 { P * x * x * (3.0 * L - x) / (6.0 * ei()) }
fn tip_load(ne: usize) -> Vec<f64> { let mut f = vec![0.0; 2 * ne + 2]; f[2 * ne] = P; f }

fn main() {
    let ei = ei();
    let i_m4 = ei / E;
    let w = i_m4 / (H / 2.0 * 1e-3);
    let w_self = (2.0 * B * TF + (H - 2.0 * TF) * TW) * 1e-6 * RHO * G;
    println!("cantilever: {:.0} m, 120 mm I, I = {:.2} cm^4, EI = {:.0} N m^2, tip load {:.0} N = {:.1} kg", L, i_m4 * 1e8, ei, P, P / G);
    let (ke, k2) = (k_formula(1.0), k_energy(1.0, 100));
    let r0: Vec<String> = (0..4).map(|j| format!("{:.0}", ke[0][j] / ei)).collect();
    let r1: Vec<String> = (0..4).map(|j| format!("{:.0}", ke[1][j] / ei)).collect();
    println!("element k for 1 m, in units of EI/m^3: {} | {}", r0.join(" "), r1.join(" "));
    let mut dk: f64 = 0.0;
    for i in 0..4 { for j in 0..4 { dk = dk.max((ke[i][j] - k2[i][j]).abs()); } }
    assert!(dk < 1e-9 * ei);
    let (u, k) = fem(NE, &tip_load(NE), true);
    println!("assembled K, free rows, units EI/m^3:");
    for row in &k[2..] { println!("  {}", row[2..].iter().map(|x| format!("{:6.0}", x / ei)).collect::<String>()); }
    println!("u in units of P m^3/EI = {:.4} mm: {}", P / ei * 1e3, u[2..].iter().map(|x| format!("{:.4}", x * ei / P)).collect::<Vec<_>>().join(" "));
    for r in [2, 6] {                          // two rows of K u = F, term by term
        let terms: Vec<String> = (2..u.len()).filter(|&c| k[r][c] != 0.0).map(|c| format!("{:+.0}", k[r][c] * u[c] / P)).collect();
        let mut s = 0.0;
        for c in 0..u.len() { s += k[r][c] * u[c]; }
        println!("row {} of K u: {} = {} P", r - 1, terms.join(" "), (s / P).round() as i64);
    }
    for i in 1..=NE {
        let x = i as f64 * L / NE as f64;
        println!("node {} at {:.2} m: sag {:6.3} mm, slope {:.6} rad, exact {:6.3} mm", i, x, u[2*i] * 1e3, u[2*i+1], exact(x) * 1e3);
    }
    let tip = u[2 * NE];
    let (mut d_energy, nn) = (0.0, 300);       // road 3: unit-load integral
    for m in 0..=nn {
        let x = m as f64 * L / nn as f64;
        d_energy += simpson_w(m, nn) * P * (L - x).powi(2) / ei * L / nn as f64 / 3.0;
    }
    println!("tip sag: elements {:.4} mm, PL^3/3EI {:.4} mm, energy {:.4} mm", tip * 1e3, P * L.powi(3) / (3.0 * ei) * 1e3, d_energy * 1e3);
    assert!((tip - P * L.powi(3) / (3.0 * ei)).abs() < 1e-9 && (d_energy - tip).abs() < 1e-9);
    assert!((0..=NE).all(|i| (u[2*i] - exact(i as f64 * L / NE as f64)).abs() < 1e-12));
    let fw: Vec<f64> = (0..2).map(|r| { let mut s = 0.0; for c in 0..u.len() { s += k[r][c] * u[c]; } s }).collect();
    println!("wall reaction from K u: {:.1} N up, {:.1} N m; W = {:.2} cm^3, stress at wall {:.2} MPa", -fw[0], -fw[1], w * 1e6, -fw[1] / w / 1e6);
    assert!((-fw[0] - P).abs() < 1e-6 && (-fw[1] - P * L).abs() < 1e-6);
    for ne in [1, 2, 6] { println!("elements: {}, tip {:.4} mm", ne, fem(ne, &tip_load(ne), true).0[2 * ne] * 1e3); }
    for n in [3, 30, 300] { println!("finite differences, {} steps: tip {:.4} mm", n, fd_tip(n) * 1e3); }
    assert!((fd_tip(300) - tip).abs() / tip < 1e-4 && 0.01 < (fd_tip(3) - tip).abs() / tip);
    let weight_tips = |ne: usize| -> (f64, f64) { // own weight: consistent loads, and nodal forces only
        let le = L / ne as f64;
        let (mut fq, mut fl) = (vec![0.0; 2 * ne + 2], vec![0.0; 2 * ne + 2]);
        for e in 0..ne {
            let parts = [w_self * le / 2.0, w_self * le * le / 12.0, w_self * le / 2.0, -w_self * le * le / 12.0];
            for i in 0..4 { fq[2 * e + i] += parts[i]; }
            fl[2 * e] += w_self * le / 2.0;
            fl[2 * e + 2] += w_self * le / 2.0;
        }
        (fem(ne, &fq, true).0[2 * ne], fem(ne, &fl, true).0[2 * ne])
    };
    let (le, (uw, ul)) = (L / NE as f64, weight_tips(NE));
    let uw_exact = w_self * L.powi(4) / (8.0 * ei);
    println!("own weight {:.2} N/m: tip {:.3} mm (consistent loads), exact wL^4/8EI {:.3} mm", w_self, uw * 1e3, uw_exact * 1e3);
    assert!((uw - uw_exact).abs() < 1e-12);
    println!("total tip {:.2} mm against limit L/180 = {:.2} mm", (tip + uw) * 1e3, L / 180.0 * 1e3);
    let rigid: Vec<f64> = (0..=NE).flat_map(|_| [1.0, 0.0]).collect();
    let spin: Vec<f64> = (0..=NE).flat_map(|i| [i as f64 * le, 1.0]).collect();
    for (name, z) in [("lift", &rigid), ("spin", &spin)] {
        let mut worst: f64 = 0.0;
        for r in &k { let mut s = 0.0; for c in 0..z.len() { s += r[c] * z[c]; } worst = worst.max(s.abs()); }
        println!("wrong: no supports, K times rigid {} = {:.1} N", name, worst);
    }
    let u_over = fem(NE, &tip_load(NE), false).0[2 * NE];
    println!("wrong: assembled by overwriting, not adding: tip {:.2} mm", u_over * 1e3);
    println!("wrong: own weight lumped as nodal forces only: tip {:.3} mm against {:.3} mm", ul * 1e3, uw_exact * 1e3);
    println!("wrong: finite differences on the same 3 pieces: tip {:.2} mm", fd_tip(3) * 1e3);
    assert!(u_over < 0.0 && 0.0 < tip && (ul - uw_exact).abs() > 0.02 * uw_exact);
    let p_y = SIGMA_Y * w / L;
    println!("outside the model: yield at P = {:.0} N; at 10000 N it says {:.1} mm, {:.0} MPa", p_y, 10000.0 * L.powi(3) / (3.0 * ei) * 1e3, 10000.0 * L / w / 1e6);
    println!("try: 5000 N tip {:.2} mm, {:.0} MPa; L = 4 m tip {:.2} mm against {:.2} mm; 6 elements, own weight lumped {:.3} mm",
             5.0 * tip * 1e3, 5000.0 * L / w / 1e6, P * 64.0 / (3.0 * ei) * 1e3, 4.0 / 180.0 * 1e3, weight_tips(6).1 * 1e3);
    println!("figure, 120 px/m, 6 px/mm, sag px at 0.25 m steps: {}", (0..13).map(|k| format!("{:.1}", exact(0.25 * k as f64) * 6e3)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
