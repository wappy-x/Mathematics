// Hodge Laplacian and harmonic forms -- the check behind the card.  std only, no crates.
// A flat torus 40,000 km by 20,000 km.  Roads to its hole count b = (1, 2, 1):
//   road 1: zero modes of the Hodge Laplacian's Fourier spectrum
//   road 2: exact kernel of a grid Hodge Laplacian (rank mod a prime, plus kernel vectors)
//   road 3: the Euler count V - E + F against b0 - b1 + b2
// A cube stands in for the globe: b = (1, 0, 1).  Then the example's split, by sampling.
use std::collections::HashMap;
use std::f64::consts::PI;

const L1: f64 = 40000.0; // the torus's two circles, km
const L2: f64 = 20000.0;
const P: i64 = 1_000_000_007; // a prime: ranks mod P bound the true ranks
type Mat = Vec<Vec<i64>>;

fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }

fn pow_mod(b: i64, e: i64) -> i64 { if e == 0 { 1 } else { let h = pow_mod(b * b % P, e / 2); if e % 2 == 1 { h * b % P } else { h } } }

fn rank_mod_p(m: &Mat) -> usize { // row reduction with arithmetic mod P
    let mut a: Mat = m.iter().map(|row| row.iter().map(|x| x.rem_euclid(P)).collect()).collect();
    let mut r = 0;
    for c in 0..a[0].len() {
        let piv = match (r..a.len()).find(|&i| a[i][c] != 0) { Some(p) => p, None => continue };
        a.swap(r, piv);
        let inv = pow_mod(a[r][c], P - 2);
        for x in a[r].iter_mut() { *x = *x * inv % P; }
        for i in r + 1..a.len() {
            let f = a[i][c];
            if f != 0 { for j in 0..a[i].len() { a[i][j] = (a[i][j] - f * a[r][j]).rem_euclid(P); } }
        }
        r += 1;
    }
    r
}

fn mul(a: &Mat, b: &Mat) -> Mat {
    a.iter().map(|row| (0..b[0].len()).map(|j| row.iter().zip(b).map(|(x, br)| x * br[j]).sum()).collect()).collect()
}
fn tr(a: &Mat) -> Mat { (0..a[0].len()).map(|j| a.iter().map(|r| r[j]).collect()).collect() }

struct Cx { nv: usize, e: Vec<(usize, usize)>, f: Vec<Vec<usize>> }

fn build(c: &Cx) -> (Mat, Mat) { // d0: functions -> 1-forms, d1: 1-forms -> 2-forms
    let mut look = HashMap::new();
    for (k, &(a, b)) in c.e.iter().enumerate() { look.insert((a, b), (k, 1)); look.insert((b, a), (k, -1)); }
    let mut d0 = vec![vec![0i64; c.nv]; c.e.len()];
    for (k, &(a, b)) in c.e.iter().enumerate() { d0[k][a] -= 1; d0[k][b] += 1; }
    let mut d1 = vec![vec![0i64; c.e.len()]; c.f.len()];
    for (fi, cyc) in c.f.iter().enumerate() {
        for t in 0..cyc.len() { let (k, s) = look[&(cyc[t], cyc[(t + 1) % cyc.len()])]; d1[fi][k] += s; }
    }
    (d0, d1)
}

fn grid(n1: usize, n2: usize) -> Cx { // n1 x n2 square cells, opposite edges glued
    let v = |i: usize, j: usize| i % n1 + n1 * (j % n2);
    let cells: Vec<(usize, usize)> = (0..n2).flat_map(|j| (0..n1).map(move |i| (i, j))).collect();
    let mut e: Vec<(usize, usize)> = cells.iter().map(|&(i, j)| (v(i, j), v(i + 1, j))).collect();
    e.extend(cells.iter().map(|&(i, j)| (v(i, j), v(i, j + 1))));
    let f = cells.iter().map(|&(i, j)| vec![v(i, j), v(i + 1, j), v(i + 1, j + 1), v(i, j + 1)]).collect();
    Cx { nv: n1 * n2, e, f }
}

fn cube() -> Cx { // the globe, flattened onto a cube's six faces
    let mut e = vec![];
    for t in 0..3 { for a in 0..8usize { if (a >> t) & 1 == 0 { e.push((a, a | 1 << t)); } } }
    let mut f = vec![];
    for t in 0..3 {
        let uw: Vec<usize> = (0..3).filter(|&s| s != t).map(|s| 1 << s).collect();
        let (u, w) = (uw[0], uw[1]);
        for side in 0..2usize { let b = side << t; f.push(vec![b, b ^ u, b ^ u ^ w, b ^ w]); }
    }
    Cx { nv: 8, e, f }
}

fn hodge_counts(c: &Cx) -> (Vec<usize>, (usize, usize), Mat) { // nullities of the three Laplacians
    let (d0, d1) = build(c);
    assert!(mul(&d1, &d0).iter().all(|r| r.iter().all(|&x| x == 0))); // d after d is zero
    let (up, down) = (mul(&d0, &tr(&d0)), mul(&tr(&d1), &d1)); // d delta and delta d
    let l1: Mat = up.iter().zip(&down).map(|(r, s)| r.iter().zip(s).map(|(a, b)| a + b).collect()).collect();
    let (l0, l2) = (mul(&tr(&d0), &d0), mul(&d1, &tr(&d1)));
    let null = [&l0, &l1, &l2].iter().map(|m| m.len() - rank_mod_p(m)).collect();
    (null, (up.len() - rank_mod_p(&up), down.len() - rank_mod_p(&down)), l1)
}

fn apply(m: &Mat, v: &[f64]) -> Vec<f64> { m.iter().map(|r| r.iter().zip(v).map(|(&a, b)| a as f64 * b).sum()).collect() }
fn lam(m: i64, n: i64) -> f64 { (2.0 * PI * m as f64 / L1).powi(2) + (2.0 * PI * n as f64 / L2).powi(2) }
fn join(v: &[usize]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }

fn eig_check(n1: usize, n2: usize) -> f64 { // grid Laplacian on the cochain of cos(kx) dx
    let (_, _, l) = hodge_counts(&grid(n1, n2));
    let (h, k) = (L1 / n1 as f64, 2.0 * PI / L1);
    let mut c: Vec<f64> = (0..n1 * n2).map(|t| ((k * (t % n1 + 1) as f64 * h).sin() - (k * (t % n1) as f64 * h).sin()) / k).collect();
    c.extend(vec![0.0; n1 * n2]);
    let ratios: Vec<f64> = apply(&l, &c).iter().zip(&c).filter(|(_, b)| b.abs() > 1e-6).map(|(a, b)| a / b).collect();
    let (mx, mn) = ratios.iter().fold((f64::MIN, f64::MAX), |(x, y), &r| (x.max(r), y.min(r)));
    assert!(mx - mn < 1e-9); // an eigenvector of the grid
    assert!((ratios[0] - 4.0 * (k * h / 2.0).sin().powi(2)).abs() < 1e-12); // discrete Fourier formula
    ratios[0] / (h * h)
}

fn main() {
    println!("torus {:.0} km by {:.0} km, area {:.0} km^2", L1, L2, L1 * L2);
    // road 1: Fourier.  e^{2 pi i (m x/L1 + n y/L2)} times a basis form has eigenvalue lam(m, n)
    let zero_modes = (-4..5).flat_map(|m| (-4..5).map(move |n| lam(m, n))).filter(|&l| l == 0.0).count();
    let fourier: Vec<usize> = [1, 2, 1].iter().map(|c| zero_modes * c).collect();
    println!("road 1 Fourier zero modes in degrees 0 1 2: {}", join(&fourier));
    println!("lowest nonzero eigenvalues x 1e8 per km^2: {} (east-west), {} (north-south)", f6(lam(1, 0) * 1e8), f6(lam(0, 1) * 1e8));
    // road 2: grid Hodge Laplacian on 8 x 4 cells of 5000 km
    let g = grid(8, 4);
    let (null, drop, l1g) = hodge_counts(&g);
    let dx: Vec<f64> = (0..64).map(|i| if i < 32 { 1.0 } else { 0.0 }).collect(); // the two constant 1-forms
    let dy: Vec<f64> = (0..64).map(|i| if i < 32 { 0.0 } else { 1.0 }).collect();
    assert!(apply(&l1g, &dx).iter().chain(apply(&l1g, &dy).iter()).all(|&x| x == 0.0)); // kernel >= 2
    assert_eq!(null, fourier); // so mod-P nullity 2 is exact
    println!("road 2 grid 8 x 4 of {:.0} km: V E F = {} {} {}, harmonic counts {}", L1 / 8.0, g.nv, g.e.len(), g.f.len(), join(&null));
    println!("dropping delta d leaves {}; dropping d delta leaves {}", drop.0, drop.1);
    assert_eq!(drop, (g.e.len() - (g.nv - 1), g.e.len() - (g.f.len() - 1))); // closed or coclosed cochains
    let chi = g.nv as i64 - g.e.len() as i64 + g.f.len() as i64;
    assert_eq!(chi, null[0] as i64 - null[1] as i64 + null[2] as i64);
    println!("road 3 Euler count V - E + F = {} = b0 - b1 + b2", chi);
    let cb = cube(); let (cnull, _, _) = hodge_counts(&cb);
    assert_eq!(cnull, vec![1, 0, 1]);
    assert_eq!(cb.nv as i64 - cb.e.len() as i64 + cb.f.len() as i64, cnull[0] as i64 - cnull[1] as i64 + cnull[2] as i64);
    println!("cube (globe): V E F = {} {} {}, harmonic counts {}", cb.nv, cb.e.len(), cb.f.len(), join(&cnull));
    let (tnull, tdrop, _) = hodge_counts(&grid(12, 6)); assert_eq!(tnull, null);
    println!("try grid 12 x 6: harmonic counts {} | dropping delta d leaves {}", join(&tnull), tdrop.0);
    let (e8, e16, ex) = (eig_check(8, 4), eig_check(16, 8), lam(1, 0)); assert!((ex - e8) / (ex - e16) > 3.9);
    println!("grid eigenvalue x 1e8: 8x4 {}, 16x8 {}, smooth {}; error ratio {:.2}",
             f6(e8 * 1e8), f6(e16 * 1e8), f6(ex * 1e8), (ex - e8) / (ex - e16));

    // the example: wind form (1 + sin(2 pi x / L1)) dx, sampled at 64 points round the long loop
    let (k, mf) = (2.0 * PI / L1, 64.0);
    let xs: Vec<f64> = (0..64).map(|i| L1 * i as f64 / mf).collect();
    let u: Vec<f64> = xs.iter().map(|x| 1.0 + (k * x).sin()).collect();
    let a = u.iter().sum::<f64>() / mf; // harmonic part: the average coefficient
    let s1 = 2.0 * u.iter().zip(&xs).map(|(ui, x)| ui * (k * x).sin()).sum::<f64>() / mf;
    let amp = s1 / k; // exact part = d(-amp cos(kx))
    let pot = |x: f64| -amp * (k * x).cos();
    let x0 = 5000.0; let slope = (pot(x0 + 0.5) - pot(x0 - 0.5)) / 1.0;
    assert!((a - 1.0).abs() < 1e-12 && (amp - L1 / (2.0 * PI)).abs() < 1e-8 && (slope - (k * x0).sin()).abs() < 1e-6);
    println!("harmonic part {} dx + {} dy; sine share {}; potential amplitude L1/2pi {} km", f6(a), f6(0.0), f6(s1), f6(amp));
    println!("at x = 5000 km: wind {} = harmonic {} + exact {} (slope of potential)", f6(1.0 + (k * x0).sin()), f6(a), f6(slope));
    let lp = u.iter().sum::<f64>() * L1 / mf; // the short loop's integral is 0: no dy part
    println!("long loop integral {} km m/s, average tailwind {} m/s", f6(lp), f6(lp / L1));
    let ms = [u.iter().map(|v| v * v).sum::<f64>() / mf, a * a,
              xs.iter().map(|x| (s1 * (k * x).sin()).powi(2)).sum::<f64>() / mf, xs.iter().map(|x| a * s1 * (k * x).sin()).sum::<f64>() / mf];
    assert!((ms[0] - 1.5).abs() < 1e-12 && (ms[2] - 0.5).abs() < 1e-12 && ms[3].abs() < 1e-12 && (ms[0] - ms[1] - ms[2]).abs() < 1e-12);
    println!("mean squares: form {} = harmonic {} + exact {}; cross term {}", f6(ms[0]), f6(ms[1]), f6(ms[2]), f6(ms[3]));
    println!("wrong: harmonic part read at x = 10000 km gives {}", f6(1.0 + (k * 10000.0).sin()));
    // a crosswind cos(2 pi y / L2) dx is coexact: delta of b dx^dy, b = (L2/2pi) sin(2 pi y/L2)
    let q = 2.0 * PI / L2; let b = |y: f64| (q * y).sin() / q;
    let y0 = 2500.0; let dbdy = (b(y0 + 0.5) - b(y0 - 0.5)) / 1.0;
    assert!((dbdy - (q * y0).cos()).abs() < 1e-6);
    println!("coexact: L2/2pi {} km; delta(beta) at y = 2500 km {}; curl x 1000 km {}", f6(1.0 / q), f6(dbdy), f6(q * (q * 5000.0).sin() * 1000.0));
    println!("plane: dx = d(x) is harmonic and exact; torus: dx round the long loop {} km, not exact",
             f6(dx[..8].iter().sum::<f64>() * L1 / 8.0));
    let u3: Vec<f64> = xs.iter().map(|x| 1.0 + 3.0 * (k * x).sin()).collect();
    println!("try 1 + 3 sin: harmonic {}, potential amplitude {} km, mean square {}", f6(u3.iter().sum::<f64>() / mf),
             f6(2.0 * u3.iter().zip(&xs).map(|(v, x)| v * (k * x).sin()).sum::<f64>() / mf / k),
             f6(u3.iter().map(|v| v * v).sum::<f64>() / mf));
    let cx: Vec<f64> = (0..9).map(|i| 5000.0 * i as f64).collect();
    let charts: [(&str, Box<dyn Fn(f64) -> f64>); 2] = [("wind", Box::new(move |x| 1.0 + (k * x).sin())), ("exact", Box::new(move |x| (k * x).sin()))];
    for (name, g) in charts.iter() {
        let s: Vec<String> = cx.iter().map(|&x| { let v = g(x); format!("{:.2}", if v.abs() < 5e-3 { 0.0 } else { v }) }).collect();
        println!("chart {}: {}", name, s.join(" "));
    }
    println!("ALL CHECKS PASS");
}
