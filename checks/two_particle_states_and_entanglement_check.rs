// Two particles -- the check behind the card.  Rust std only, no crates.
// Two spin-one-half electrons.  Four-entry states come from the Kronecker
// product.  The singlet fails the product test three ways (the test number,
// the reduced state, the best product fit); spin addition comes from the 4x4
// matrix S^2; the exchange rule is run on two electrons in a 1 nm box (formula
// against a grid); CHSH comes from 4x4 matrices, from -cos(a - b), and from the
// largest eigenvalue of the CHSH matrix, against every local strategy.
use std::f64::consts::PI;
type M = Vec<Vec<f64>>;

fn kron(a: &M, b: &M) -> M {
    let (p, q) = (b.len(), b[0].len());
    (0..a.len() * p).map(|i| (0..a[0].len() * q).map(|j| a[i / p][j / q] * b[i % p][j % q]).collect()).collect()
}
fn lin(x: f64, a: &M, y: f64, b: &M) -> M { a.iter().zip(b).map(|(r, s)| r.iter().zip(s).map(|(u, v)| x * u + y * v).collect()).collect() }
fn mv(m: &M, v: &[f64]) -> Vec<f64> { m.iter().map(|row| row.iter().zip(v).map(|(a, b)| a * b).sum()).collect() }
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn gap(a: &M, b: &M) -> f64 { a.iter().zip(b).flat_map(|(r, s)| r.iter().zip(s).map(|(x, y)| (x - y).abs())).fold(0.0, f64::max) }
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn m2(a: f64, b: f64, c: f64, d: f64) -> M { vec![vec![a, b], vec![c, d]] }
fn sig(deg: f64) -> M { let t = deg * PI / 180.0; m2(t.cos(), t.sin(), t.sin(), -t.cos()) } // tilted deg from z towards x
fn test(c: &[f64]) -> f64 { c[0] * c[3] - c[1] * c[2] }                                 // c00 c11 - c01 c10
fn z(x: f64) -> f64 { if x.abs() < 5e-13 { 0.0 } else { x } }                         // print rounding noise as 0
fn psi(n: f64, x: f64) -> f64 { 2f64.sqrt() * (n * PI * x).sin() }
fn e_q(st: &[f64], x: f64, y: f64) -> f64 { dot(st, &mv(&kron(&sig(x), &sig(y)), st)) }
fn e_lhv(x: f64, y: f64) -> f64 { let d = ((x - y + 180.0).rem_euclid(360.0) - 180.0).abs(); -1.0 + 2.0 * d / 180.0 }

struct SplitMix64 { s: u64 }    // a small seeded generator, written out
impl SplitMix64 {
    fn next(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let (i2, sx, sz) = (eye(2), m2(0.0, 1.0, 1.0, 0.0), m2(1.0, 0.0, 0.0, -1.0));
    let jj = m2(0.0, 1.0, -1.0, 0.0);   // sigma_y = -i J, so sigma_y (x) sigma_y = -J (x) J: all real
    // ---- 1. the product test: entries ordered (up-up, up-down, down-up, down-down) ----
    let r = 1.0 / 2f64.sqrt();
    let (singlet, t_plus, t_zero, t_minus) = (vec![0.0, r, -r, 0.0], vec![1.0, 0.0, 0.0, 0.0], vec![0.0, r, r, 0.0], vec![0.0, 0.0, 0.0, 1.0]);
    let prod: Vec<f64> = kron(&vec![vec![1.0], vec![0.0]], &vec![vec![(PI / 6.0).cos()], vec![(PI / 6.0).sin()]]).iter().map(|x| x[0]).collect();
    println!("product state  ({:.4}, {:.4}, {:.4}, {:.4})  test {:.4}", prod[0], prod[1], prod[2], prod[3], test(&prod));
    println!("singlet        ({:.4}, {:.4}, {:.4}, {:.4})  test {:.4}", singlet[0], singlet[1], singlet[2], singlet[3], test(&singlet));
    assert!(test(&prod).abs() < 1e-15 && (test(&singlet) - 0.5).abs() < 1e-15);
    let c = [[singlet[0], singlet[1]], [singlet[2], singlet[3]]];            // road 2: electron 1's own state, C C^T
    let rho: M = (0..2).map(|i| (0..2).map(|j| dot(&c[i], &c[j])).collect()).collect();
    let purity: f64 = rho.iter().flatten().map(|x| x * x).sum();
    println!("electron 1 alone: [[{:.4}, {:.4}], [{:.4}, {:.4}]], purity {:.4} = 1 - 2 test^2 = {:.4}", rho[0][0], rho[0][1], rho[1][0], rho[1][1], purity, 1.0 - 2.0 * test(&singlet).powi(2));
    assert!((purity - (1.0 - 2.0 * test(&singlet).powi(2))).abs() < 1e-12 && gap(&rho, &lin(0.5, &i2, 0.0, &i2)) < 1e-15);
    let mut best = 0.0f64;              // road 3: closest product state, scanned every degree
    for a in 0..180 {
        for b in 0..180 {
            let (u0, u1) = ((a as f64 * PI / 180.0).cos(), (a as f64 * PI / 180.0).sin());
            let (v0, v1) = ((b as f64 * PI / 180.0).cos(), (b as f64 * PI / 180.0).sin());
            best = best.max(dot(&[u0 * v0, u0 * v1, u1 * v0, u1 * v1], &singlet).powi(2));
        }
    }
    println!("best product overlap^2 {:.4}  formula (1 + sqrt(1 - 4 test^2))/2 = {:.4}", best, (1.0 + (1.0 - 4.0 * test(&singlet).powi(2)).sqrt()) / 2.0);
    assert!((best - 0.5).abs() < 1e-12);

    // ---- 2. adding two spins: S^2 = (3/2) I + (1/2) sum_k sigma_k (x) sigma_k, in units of hbar^2 ----
    let ss = lin(1.0, &lin(1.0, &kron(&sx, &sx), -1.0, &kron(&jj, &jj)), 1.0, &kron(&sz, &sz));
    let s2m = lin(1.5, &eye(4), 0.5, &ss);
    let szm = lin(0.5, &kron(&sz, &i2), 0.5, &kron(&i2, &sz));
    for (name, v, s) in [("triplet up-up    ", &t_plus, 1.0), ("triplet (ud+du)  ", &t_zero, 1.0), ("triplet down-down", &t_minus, 1.0), ("singlet (ud-du)  ", &singlet, 0.0)] {
        let (s2, szv) = (dot(v, &mv(&s2m, v)), dot(v, &mv(&szm, v)));
        assert!(mv(&s2m, v).iter().zip(v.iter()).all(|(x, y)| (x - s * (s + 1.0) * y).abs() < 1e-12)); // eigenvector, eigenvalue s(s+1)
        println!("{}  S^2 = {:.4} hbar^2  s = {:.0}  S_z = {:+.0} hbar", name, s2, ((1.0 + 4.0 * s2).sqrt() - 1.0) / 2.0, z(szv));
    }
    let swap: M = vec![vec![1.0, 0.0, 0.0, 0.0], vec![0.0, 0.0, 1.0, 0.0], vec![0.0, 1.0, 0.0, 0.0], vec![0.0, 0.0, 0.0, 1.0]];
    assert!(gap(&lin(0.5, &eye(4), 0.5, &ss), &swap) < 1e-15);                  // swap = (I + sum sigma.sigma)/2
    println!("swap: triplet {:+.0}, singlet {:+.0};  trace S^2 = {:.0} = 3 x 2 + 0", dot(&t_zero, &mv(&swap, &t_zero)), dot(&singlet, &mv(&swap, &singlet)), (0..4).map(|i| s2m[i][i]).sum::<f64>());
    let rr = m2((PI / 6.0).cos(), -(PI / 6.0).sin(), (PI / 6.0).sin(), (PI / 6.0).cos()); // turn both spins 60 deg about y
    let ov = dot(&singlet, &mv(&kron(&rr, &rr), &singlet));
    println!("singlet after turning both spins 60 deg: overlap {:.4}", ov);
    assert!((ov - 1.0).abs() < 1e-12);

    // ---- 3. identical electrons in a 1 nm box ----
    let (h, me, ev, eps0) = (6.62607015e-34, 9.1093837139e-31, 1.602176634e-19, 8.8541878188e-12); // CODATA 2022
    let l = 1e-9;
    let e1 = h * h / (8.0 * me * l * l) / ev;
    println!("E1 = h^2/(8 m L^2) = {:.6} eV;  singlet, both n=1: {:.6} eV;  triplet, n=1 and 2: {:.6} eV;  gap {:.6} eV", e1, 2.0 * e1, 5.0 * e1, 3.0 * e1);
    let n = 200usize;
    let xs: Vec<f64> = (0..n).map(|k| (k as f64 + 0.5) / n as f64).collect();   // box in units of L
    let anti_norm = |n1: f64, n2: f64| -> f64 {  // grid norm^2 of psi_n1(x1) psi_n2(x2) - psi_n2(x1) psi_n1(x2), over 2
        let mut s = 0.0; for &x in &xs { for &y in &xs { s += (psi(n1, x) * psi(n2, y) - psi(n2, x) * psi(n1, y)).powi(2); } }
        s / (2.0 * (n * n) as f64)
    };
    let mut pairs: Vec<(i32, i32, i32)> = Vec::new();
    for n1 in 1..4 { for n2 in n1..4 { pairs.push((n1 * n1 + n2 * n2, n1, n2)); } }
    pairs.sort();
    let low = *pairs.iter().find(|p| anti_norm(p.1 as f64, p.2 as f64) > 0.5).unwrap();
    println!("antisymmetric norm^2: (1,1) {:.4}, (1,2) {:.4};  lowest allowed pair ({},{}) at {:.6} eV", anti_norm(1.0, 1.0), anti_norm(1.0, 2.0), low.1, low.2, low.0 as f64 * e1);
    assert!((low.1, low.2) == (1, 2));
    let a12 = 4.0 / (3.0 * PI);         // overlap of psi_1 and psi_2 over the left half
    for (sgn, name) in [(1.0, "symmetric (singlet)"), (-1.0, "antisymmetric (triplet)")] {
        let cf = 0.5 + sgn * 2.0 * a12 * a12;
        let mut grid = 0.0;
        for &x in &xs { for &y in &xs { if (x < 0.5) == (y < 0.5) { grid += (psi(1.0, x) * psi(2.0, y) + sgn * psi(2.0, x) * psi(1.0, y)).powi(2) / 2.0; } } }
        grid /= (n * n) as f64;
        println!("P(same half) {}  formula {:.4}  grid {:.4}", name, cf, grid);
        assert!((grid - cf).abs() < 1e-4);
    }
    println!("P(same half) told-apart electrons  {:.4}", 0.5);

    // ---- 4. CHSH: S = E(a,b) + E(a,b') + E(a',b) - E(a',b') ----
    let (a, a2, b, b2) = (0.0, 90.0, -135.0, 135.0);
    let pairs4 = [(a, b, 1.0), (a, b2, 1.0), (a2, b, 1.0), (a2, b2, -1.0)];
    for &(x, y, _) in &pairs4 {
        println!("E({:4.0},{:5.0})  matrices {:+.4}  -cos(a-b) {:+.4}", x, y, e_q(&singlet, x, y), -((x - y) * PI / 180.0).cos());
        assert!((e_q(&singlet, x, y) + ((x - y) * PI / 180.0).cos()).abs() < 1e-12);
    }
    let s_q: f64 = pairs4.iter().map(|&(x, y, s)| s * e_q(&singlet, x, y)).sum();
    let mut w: M = vec![vec![0.0; 4]; 4];   // road 3: the CHSH matrix; its largest eigenvalue by power iteration on W^2
    for &(x, y, s) in &pairs4 { w = lin(1.0, &w, s, &kron(&sig(x), &sig(y))); }
    let mut v = vec![1.0, 0.3, -0.7, 0.2];
    for _ in 0..200 { v = mv(&w, &mv(&w, &v)); let nv = dot(&v, &v).sqrt(); v = v.iter().map(|t| t / nv).collect(); }
    let lam = dot(&v, &mv(&w, &mv(&w, &v))).sqrt();
    println!("CHSH singlet {:.6};  2 sqrt 2 = {:.6};  largest eigenvalue of the CHSH matrix {:.6}", s_q, 2.0 * 2f64.sqrt(), lam);
    assert!((s_q - 2.0 * 2f64.sqrt()).abs() < 1e-12 && (lam - 2.0 * 2f64.sqrt()).abs() < 1e-9);
    let mut local: Vec<i32> = Vec::new();
    for a0 in [1, -1] { for a1 in [1, -1] { for b0 in [1, -1] { for b1 in [1, -1] { local.push(a0 * b0 + a0 * b1 + a1 * b0 - a1 * b1); } } } }
    let mut set = local.clone(); set.sort(); set.dedup();
    println!("all 16 local strategies: S in [{}], largest {}", set.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(", "), local.iter().max().unwrap());
    assert!(local.iter().map(|t| t.abs()).max().unwrap() == 2);
    let (mut rng, m) = (SplitMix64 { s: 2026 }, 100000usize);
    let (mut s_lhv, mut s_sim_l, mut s_sim_q) = (0.0, 0.0, 0.0);
    for &(x, y, s) in &pairs4 {
        s_lhv += s * e_lhv(x, y);
        let (mut tot_l, mut tot_q) = (0i64, 0i64);
        let p_same = (1.0 + e_q(&singlet, x, y)) / 2.0;
        for _ in 0..m {
            let lmb = 360.0 * rng.next();
            let aa = if ((x - lmb) * PI / 180.0).cos() >= 0.0 { 1 } else { -1 };
            let bb = if ((y - lmb) * PI / 180.0).cos() >= 0.0 { -1 } else { 1 };
            tot_l += aa * bb;
            tot_q += if rng.next() < p_same { 1 } else { -1 };                  // +1: same readings
        }
        s_sim_l += s * tot_l as f64 / m as f64; s_sim_q += s * tot_q as f64 / m as f64;
    }
    println!("hidden-direction model S {:.4}, simulated {:.4};  quantum simulated {:.4}  ({} pairs per setting)", s_lhv, s_sim_l, s_sim_q, m);
    let mf = m as f64;
    assert!((s_sim_l - s_lhv).abs() < 4.0 * (4.0 * 0.75 / mf).sqrt() && (s_sim_q - s_q).abs() < 4.0 * (4.0 * 0.5 / mf).sqrt());
    let th: Vec<f64> = (0..9).map(|k| 22.5 * k as f64).collect();
    let row = |f: &dyn Fn(f64) -> String| th.iter().map(|&t| f(t)).collect::<Vec<_>>().join(" ");
    println!("chart, angle (deg)   {}", row(&|t| format!("{:6.1}", t)));
    println!("chart, quantum E     {}", row(&|t| format!("{:+.3}", z(e_q(&singlet, 0.0, t)))));
    println!("chart, hidden-dir E  {}", row(&|t| format!("{:+.3}", e_lhv(0.0, t))));

    // ---- what breaks ----
    println!("wrong: two separate 50/50 spins  P(both up along z) {:.4}   (singlet {:.4})", rho[0][0] * rho[0][0], singlet[0].powi(2));
    let swapped = [(a, b2, 1.0), (a, b, 1.0), (a2, b2, 1.0), (a2, b, -1.0)];
    let plus_same: f64 = pairs4.iter().map(|&(x, y, s)| s * e_q(&t_zero, x, y)).sum();
    let plus_swap: f64 = swapped.iter().map(|&(x, y, s)| s * e_q(&t_zero, x, y)).sum();
    println!("wrong: plus sign (ud+du)  test {:.4}, CHSH same directions {:.4}, B's two swapped {:.4}", test(&t_zero), z(plus_same), plus_swap);
    println!("wrong: same-spin pair both in n=1  {:.6} eV   (allowed lowest {:.6} eV)", 2.0 * e1, 5.0 * e1);
    println!("outside the model: repulsion at 1 nm {:.6} eV  vs  Pauli gap {:.6} eV", ev / (4.0 * PI * eps0 * l), 3.0 * e1);
    println!("ALL CHECKS PASS");
}
