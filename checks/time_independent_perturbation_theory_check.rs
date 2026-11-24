// Time-independent perturbation theory -- the same check in Rust, no crates.  A 1 nm box with a 0.1 eV
// step over its right half, by three roads: the perturbation series, a 50-state Jacobi diagonalisation,
// and shooting the equation (RK4 plus bisection).  Then a degenerate pair in a square 1 nm box.
use std::f64::consts::PI;

const H: f64 = 6.62607015e-34;      // Planck constant, J s (exact in SI)
const ME: f64 = 9.1093837139e-31;   // electron mass, kg (CODATA 2022)
const EV: f64 = 1.602176634e-19;    // one electronvolt, J (exact in SI)
const V0: f64 = 0.1;                // step height, eV
const N: usize = 50;                // basis size

fn e1() -> f64 { H * H / (8.0 * ME * 1e-18) / EV }                    // ground level, eV
fn kk() -> f64 { let hb = H / (2.0 * PI); 2.0 * ME * EV * 1e-18 / (hb * hb) } // per eV per nm^2
fn hc() -> f64 { H * 299792458.0 / EV * 1e9 }                         // h c in eV nm

fn ii(m: i64, n: i64) -> f64 {      // integral over the right half of phi_m phi_n
    if m == n { return 0.5; }
    if (m - n) % 2 == 0 { return 0.0; }
    ((((m + n) as f64) * PI / 2.0).sin() / (m + n) as f64 - (((m - n) as f64) * PI / 2.0).sin() / (m - n) as f64) / PI
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let (n, mut s) = (2000, 0.0);
    let h = (b - a) / n as f64;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    (f(a) + f(b) + s) * h / 3.0
}

fn phi(n: i64, x: f64) -> f64 { 2.0f64.sqrt() * (n as f64 * PI * x).sin() }

fn rotate(m: &mut Vec<Vec<f64>>, p: usize, q: usize, c: f64, s: f64, cols: bool) {
    for k in 0..m.len() {
        if cols { let (a, b) = (m[k][p], m[k][q]); m[k][p] = c * a - s * b; m[k][q] = s * a + c * b; }
        else { let (a, b) = (m[p][k], m[q][k]); m[p][k] = c * a - s * b; m[q][k] = s * a + c * b; }
    }
}

fn jacobi(a0: &Vec<Vec<f64>>) -> (Vec<f64>, Vec<Vec<f64>>) {   // eigenvalues, eigenvectors
    let (n, mut a) = (a0.len(), a0.clone());
    let mut q: Vec<Vec<f64>> = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..30 {
        let off: f64 = (0..n).map(|i| (0..n).filter(|&j| j != i).map(|j| a[i][j] * a[i][j]).sum::<f64>()).sum();
        if off < 1e-26 { break; }
        for p in 0..n - 1 {
            for r in p + 1..n {
                if a[p][r] == 0.0 { continue; }
                let th = (a[r][r] - a[p][p]) / (2.0 * a[p][r]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
                rotate(&mut a, p, r, c, s, true);
                rotate(&mut q, p, r, c, s, true);
                rotate(&mut a, p, r, c, s, false);
            }
        }
    }
    let mut order: Vec<usize> = (0..n).collect();
    order.sort_by(|&i, &j| a[i][i].partial_cmp(&a[j][j]).unwrap());
    (order.iter().map(|&i| a[i][i]).collect(), order.iter().map(|&i| (0..n).map(|k| q[k][i]).collect()).collect())
}

fn shoot(e: f64, v: f64) -> f64 {   // phi(0)=0, phi'(0)=1, RK4 across 1 nm with the step
    let (dx, mut y, mut w) = (1.0 / 2000.0, 0.0f64, 1.0f64);
    for i in 0..2000 {
        let k = -kk() * (e - if (i as f64 + 0.5) * dx > 0.5 { v } else { 0.0 });
        let (k1y, k1v) = (w, k * y);
        let (k2y, k2v) = (w + dx / 2.0 * k1v, k * (y + dx / 2.0 * k1y));
        let (k3y, k3v) = (w + dx / 2.0 * k2v, k * (y + dx / 2.0 * k2y));
        let (k4y, k4v) = (w + dx * k3v, k * (y + dx * k3y));
        y += dx / 6.0 * (k1y + 2.0 * k2y + 2.0 * k3y + k4y); w += dx / 6.0 * (k1v + 2.0 * k2v + 2.0 * k3v + k4v);
    }
    y
}

fn root_from(v: f64, mut e: f64) -> f64 {   // first sign change above e, then bisect
    while (shoot(e, v) < 0.0) == (shoot(e + 0.02, v) < 0.0) { e += 0.02; }
    let (mut a, mut b, mut fa) = (e, e + 0.02, shoot(e, v)); // bisection
    for _ in 0..60 {
        let (m, fm) = ((a + b) / 2.0, shoot((a + b) / 2.0, v));
        if (fm < 0.0) == (fa < 0.0) { a = m; fa = fm; } else { b = m; }
    }
    (a + b) / 2.0
}

fn series(n: i64, v: f64) -> [f64; 3] {     // unperturbed, first order, second order
    let e0 = e1() * (n * n) as f64;
    let mut e2 = 0.0;
    for m in 1..=N as i64 { if m != n { e2 += (v * ii(n, m)).powi(2) / (e0 - e1() * (m * m) as f64); } }
    [e0, e0 + v * ii(n, n), e0 + v * ii(n, n) + e2]
}

fn exact(v: f64, size: usize) -> (Vec<f64>, Vec<Vec<f64>>) {
    jacobi(&(0..size).map(|i| (0..size).map(|j| (if i == j { e1() * ((i + 1) * (i + 1)) as f64 } else { 0.0 })
        + v * ii(i as i64 + 1, j as i64 + 1)).collect()).collect())
}

fn join(v: &[f64], f: impl Fn(f64) -> String) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let e1 = e1();
    println!("box 1 nm: E_1 = h^2/(8 m_e L^2) = {:.5} eV; K = {:.4} per eV per nm^2; step V0 = {:.3} eV on 0.5-1 nm", e1, kk(), V0);
    let half: Vec<f64> = (1..6).map(|n| simpson(|x| phi(n, x).powi(2), 0.5, 1.0)).collect();
    println!("chance in right half, levels 1-5 (Simpson): {}", join(&half, |h| format!("{:.6}", h)));
    let pairs = [(1, 1), (1, 2), (1, 4), (2, 3), (3, 4), (1, 6)];
    let num: Vec<f64> = pairs.iter().map(|&(a, b)| V0 * simpson(|x| phi(a, x) * phi(b, x), 0.5, 1.0)).collect();
    let pv: Vec<String> = pairs.iter().zip(&num).map(|(&(a, b), u)| format!("V_{}{} {:.6}/{:.6}", a, b, V0 * ii(a, b), u)).collect();
    println!("V_mn closed form / Simpson, eV: {}", pv.join(", "));
    let t: Vec<f64> = [2i64, 4, 6].iter().map(|&m| (V0 * ii(1, m)).powi(2) / (e1 - e1 * (m * m) as f64)).collect();
    println!("ground, second order: V_12^2 {:.7} eV^2 / (E_1 - E_2) {:.5} eV; V_14^2 {:.7} eV^2 / (E_1 - E_4) {:.5} eV",
             (V0 * ii(1, 2)).powi(2), e1 - 4.0 * e1, (V0 * ii(1, 4)).powi(2), e1 - 16.0 * e1);
    let s1 = series(1, V0); println!("ground, second order: m=2 {:.7}, m=4 {:.7}, m=6 {:.7}, all m to 50 {:.7} eV", t[0], t[1], t[2], s1[2] - s1[1]);
    let (ev, vec) = exact(V0, N);
    let shot: Vec<f64> = (1..6).map(|n| root_from(V0, e1 * (n * n) as f64)).collect();
    println!("n  unperturbed  first order  second order  50-state exact  shooting  (eV)");
    for n in 1..6usize {
        let s = series(n as i64, V0);
        println!("{}  {:10.5}  {:11.5}  {:12.5}  {:14.5}  {:8.5}", n, s[0], s[1], s[2], ev[n - 1], shot[n - 1]);
    }
    for (lab, col) in [("first order", 1usize), ("second order", 2)] {
        let sh: Vec<f64> = (1..9).map(|n| 1000.0 * (series(n, V0)[col] - e1 * (n * n) as f64)).collect();
        println!("chart, shift {}, levels 1-8, meV: {}", lab, join(&sh, |x| format!("{:.2}", x)));
    }
    let sh: Vec<f64> = (1..9).map(|n: usize| 1000.0 * (ev[n - 1] - e1 * (n * n) as f64)).collect();
    println!("chart, shift exact, levels 1-8, meV: {}", join(&sh, |x| format!("{:.2}", x)));
    let c: Vec<f64> = (0..=N as i64).map(|m| if m < 2 { 0.0 } else { V0 * ii(1, m) / (e1 - e1 * (m * m) as f64) }).collect();
    println!("ground state mix, amount per unit of phi_1: c_2 first order {:.5}, exact {:.5}; c_4 first order {:.5}, exact {:.5}",
             c[2], vec[0][1] / vec[0][0], c[4], vec[0][3] / vec[0][0]);
    let p1 = 0.5 + 2.0 * (2..=N as i64).map(|m| c[m as usize] * ii(1, m)).sum::<f64>();
    let mut pex = 0.0;
    for i in 0..N { for j in 0..N { pex += vec[0][i] * vec[0][j] * ii(i as i64 + 1, j as i64 + 1); } }
    println!("ground, chance in right half: unperturbed 0.5000, first order {:.4}, exact {:.4}", p1, pex);
    let (s2, eps) = (series(2, V0), (V0 * ii(1, 2)).abs() / (3.0 * e1)); let gaps = [e1 * 3.0, s2[1] - s1[1], s2[2] - s1[2], ev[1] - ev[0], shot[1] - shot[0]];
    let gs: Vec<String> = gaps.iter().map(|g| format!("{:.5}/{:.2}", g, hc() / g)).collect();
    println!("light 2->1, eV / nm: unperturbed, first, second, exact, shooting: {}", gs.join(", "));
    println!("small number eps = |V_12|/(E_2 - E_1) = {:.4}", eps);
    let st: Vec<(i64, i64)> = (1..9).flat_map(|a| (1..9).map(move |b| (a, b))).collect();
    let h2: Vec<Vec<f64>> = st.iter().map(|&(a, b)| st.iter().map(|&(p, q)|
        (if (a, b) == (p, q) { e1 * (a * a + b * b) as f64 } else { 0.0 }) + V0 * ii(a, p) * ii(b, q)).collect()).collect();
    let (ev2, vec2) = jacobi(&h2);
    let (vaa, vab) = (V0 * ii(1, 1) * ii(2, 2), V0 * ii(1, 2) * ii(2, 1));
    let deg = [5.0 * e1 + vaa + vab, 5.0 * e1 + vaa - vab]; // degenerate theory: diagonalise the 2x2 block
    let (i12, i21) = (st.iter().position(|&x| x == (1, 2)).unwrap(), st.iter().position(|&x| x == (2, 1)).unwrap());
    println!("square 1 nm x 1 nm, bump {:.1} eV on corner x,y > 0.5 nm: pair (1,2),(2,1) at {:.5} eV", V0, 5.0 * e1);
    println!("pair block [[{:.6}, {:.6}], [{:.6}, {:.6}]] eV; eigenvalues {:.6}, {:.6} eV", vaa, vab, vab, vaa, vaa + vab, vaa - vab);
    let (su, sl) = (vec2[2][i12].signum(), vec2[1][i12].signum());
    println!("exact good states on (1,2),(2,1): upper {:.4} {:.4}, lower {:.4} {:.4}",
             su * vec2[2][i12], su * vec2[2][i21], sl * vec2[1][i12], sl * vec2[1][i21]);
    println!("pair levels: degenerate theory {:.5}, {:.5} eV; 64-state exact {:.5}, {:.5} eV; split {:.5} vs {:.5} eV",
             deg[0], deg[1], ev2[2], ev2[1], 2.0 * vab, ev2[2] - ev2[1]);
    println!("mistake, nondegenerate formula on the pair: c = {:.6} / {:.6}, division by zero", vab, 5.0 * e1 - 5.0 * e1);
    println!("mistake, first order only: light 2->1 at {:.2} nm, exact {:.2} nm, {:.2} nm shorter", hc() / gaps[1], hc() / gaps[3], hc() / gaps[1] - hc() / gaps[3]);
    let flip = s1[1] - (s1[2] - s1[1]);
    println!("mistake, denominator flipped: ground {:.5} eV, exact {:.5} eV", flip, ev[0]);
    let big: Vec<(f64, f64, f64)> = [0.5, 1.0, 2.0, 4.0].iter().map(|&v| (v, series(1, v)[2], root_from(v, 0.01))).collect();
    let bs: Vec<String> = big.iter().map(|&(v, s, x)| format!("V0 {:.1} eps {:.2}: {:.4}/{:.4}", v, v * eps / V0, s, x)).collect();
    println!("step not small, ground second order / exact, eV: {}", bs.join(", "));
    let s02 = series(1, 0.2);
    println!("try: V0 0.2 eV ground first order {:.5}, second-order term {:.7} eV; 10-state ground {:.5} eV",
             s02[1], s02[2] - s02[1], exact(V0, 10).0[0]);

    assert!(half.iter().all(|h| (h - 0.5).abs() < 1e-9));                               // half the chance under the step
    assert!(pairs.iter().zip(&num).all(|(&(a, b), u)| (V0 * ii(a, b) - u).abs() < 1e-9)); // matrix elements by Simpson
    assert!((1..6).all(|n| (series(n, V0)[2] - ev[n as usize - 1]).abs() < 1e-5));       // second order meets 50 states
    assert!((0..5).all(|n| (shot[n] - ev[n]).abs() / ev[n] < 1e-6));                     // shooting meets 50 states
    assert!((c[2] / (vec[0][1] / vec[0][0]) - 1.0).abs() < 0.01 && (p1 - pex).abs() < 1e-3);    // state correction
    assert!((deg[0] - ev2[2]).abs() < 5e-4 && (deg[1] - ev2[1]).abs() < 5e-4);           // degenerate pair
    assert!((2.0 * vab / (ev2[2] - ev2[1]) - 1.0).abs() < 0.01);
    assert!(big[3].2 - big[3].1 > 1.0 && (big[0].1 - big[0].2).abs() < 0.002);           // series fails when eps ~ 1
    println!("ALL CHECKS PASS");
}
