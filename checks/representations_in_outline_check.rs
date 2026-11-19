// Representation in outline -- the same check as the Python, in Rust.  No
// crates.  The snowflake's twelve moves (wing 05's 2-by-2 turns and flips) act
// on its six arms: each move shuffles a list of six arm lengths, and that
// shuffle is a 6-by-6 matrix.  The list then splits into pieces no move mixes.
type M = Vec<Vec<f64>>;
const X: [f64; 6] = [1.12, 0.96, 1.08, 0.92, 1.04, 0.88]; // one crystal's arm lengths, mm

fn rad(d: f64) -> f64 { d.to_radians() }
fn arm(i: usize) -> f64 { 30.0 + 60.0 * i as f64 }            // arm i points this way, degrees
fn tip(i: usize) -> (f64, f64) { (rad(arm(i)).cos(), rad(arm(i)).sin()) }
fn turn(t: f64) -> M { let (c, s) = (rad(t).cos(), rad(t).sin()); vec![vec![c, -s], vec![s, c]] }
fn flip(p: f64) -> M { let (c, s) = (rad(2.0 * p).cos(), rad(2.0 * p).sin()); vec![vec![c, s], vec![s, -c]] }

fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn close(a: &M, b: &M) -> bool {
    a.iter().zip(b).all(|(ra, rb)| ra.iter().zip(rb).all(|(x, y)| (x - y).abs() < 1e-9))
}
fn f(v: f64) -> String { format!("{:.4}", if v.abs() < 5e-5 { 0.0 } else { v }) } // never "-0.0000"
fn fl(vs: &[f64]) -> String { format!("[{}]", vs.iter().map(|&v| f(v)).collect::<Vec<_>>().join(", ")) }
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(p, q)| p * q).sum() }
fn size(v: &[f64]) -> f64 { dot(v, v).sqrt() }
fn apply(a: &M, v: &[f64]) -> Vec<f64> { a.iter().map(|r| dot(r, v)).collect() }

fn lands(m: &M, i: usize) -> usize {                          // which tip does arm i's tip land on?
    let (x, y) = tip(i);
    let (u, v) = (m[0][0] * x + m[0][1] * y, m[1][0] * x + m[1][1] * y);
    let d = |j: usize| (tip(j).0 - u).powi(2) + (tip(j).1 - v).powi(2);
    (0..6).fold(0, |b, j| if d(j) < d(b) { j } else { b })
}

fn main() {
    let name: Vec<String> = (0..6).map(|k| format!("R{}", 60 * k)).chain((0..6).map(|m| format!("F{}", 30 * m))).collect();
    let m2: Vec<M> = (0..6).map(|k| turn(60.0 * k as f64)).chain((0..6).map(|m| flip(30.0 * m as f64))).collect();
    let m2x2: Vec<M> = (0..6).map(|k| turn(120.0 * k as f64)).chain((0..6).map(|m| flip(60.0 * m as f64))).collect();
    let perm: Vec<Vec<usize>> = m2.iter().map(|m| (0..6).map(|i| lands(m, i)).collect()).collect();
    let rho: Vec<M> = perm.iter().map(|p| (0..6).map(|i| (0..6).map(|j| if p[j] == i { 1.0 } else { 0.0 }).collect()).collect()).collect();
    let wrong: Vec<M> = perm.iter().map(|p| (0..6).map(|i| (0..6).map(|j| if p[i] == j { 1.0 } else { 0.0 }).collect()).collect()).collect();
    let which = |m: &M| (0..12).find(|&k| close(&m2[k], m)).unwrap();
    let (mut good, mut bad) = (0, 0);
    for g in 0..12 {
        for h in 0..12 {
            let gh = which(&mul(&m2[g], &m2[h]));             // the group's own product, in 2x2
            if close(&rho[gh], &mul(&rho[g], &rho[h])) { good += 1 }
            if !close(&wrong[gh], &mul(&wrong[g], &wrong[h])) { bad += 1 }
        }
    }
    let chi: Vec<f64> = rho.iter().map(|r| (0..6).map(|i| r[i][i]).sum()).collect(); // arms left in place
    let chi_int: Vec<i64> = chi.iter().map(|&c| c as i64).collect();
    let n_pieces = chi.iter().map(|c| c * c).sum::<f64>() / 12.0;
    println!("moves: {}", name.join(" "));
    println!("arm i goes to, under R60: {:?}; under F30: {:?}; under F0: {:?}", perm[1], perm[7], perm[6]);
    println!("pairs (g, h) with rho(gh) = rho(g) rho(h): {} of 144", good);
    println!("trace of rho(g), arms left in place: {:?}", chi_int);
    println!("copies of the all-equal piece, sum of traces / 12: {}", f(chi.iter().sum::<f64>() / 12.0));
    println!("pieces counted by traces, sum of squares {} / 12 = {}", (n_pieces * 12.0).round() as i64, f(n_pieces));

    // Road 1: projectors built by averaging over the group, weighted by a trace.
    let alt: Vec<f64> = perm.iter().map(|p| {
        let mut t = vec![p[0], p[2], p[4]]; t.sort(); if t == vec![0, 2, 4] { 1.0 } else { -1.0 } }).collect();
    let tr = |m: &M| m[0][0] + m[1][1];
    let names = ["all equal", "alternating", "tilt (once round)", "three-wave (twice round)"];
    let chars: Vec<(Vec<f64>, f64)> = vec![(vec![1.0; 12], 1.0), (alt, 1.0),
        (m2.iter().map(|m| tr(m)).collect(), 2.0), (m2x2.iter().map(|m| tr(m)).collect(), 2.0)];
    let proj: Vec<M> = chars.iter().map(|(ch, d)| (0..6).map(|i| (0..6).map(|j|
        d / 12.0 * (0..12).map(|g| ch[g] * rho[g][i][j]).sum::<f64>()).collect()).collect()).collect();
    let road1: Vec<Vec<f64>> = proj.iter().map(|p| apply(p, &X)).collect();

    // Road 2: an explicit basis of waves round the arms, and dot products.
    let wave = |cosine: bool, m: f64| -> Vec<f64> { (0..6).map(|i| { let a = rad(m * arm(i)); if cosine { a.cos() } else { a.sin() } }).collect() };
    let basis: Vec<Vec<Vec<f64>>> = vec![vec![vec![1.0; 6]], vec![(0..6).map(|i| if i % 2 == 0 { 1.0 } else { -1.0 }).collect()],
        vec![wave(true, 1.0), wave(false, 1.0)], vec![wave(true, 2.0), wave(false, 2.0)]];
    let alt_sum: f64 = (0..6).map(|i| if i % 2 == 0 { X[i] } else { -X[i] }).sum();
    let total: f64 = X.iter().sum();
    println!("arm lengths x, mm: {}", fl(&X));
    println!("sum {}, mean {}; alternating sum {}, / 6 = {}", f(total), f(total / 6.0), f(alt_sum), f(alt_sum / 6.0));
    println!("x minus the mean: {}", fl(&X.iter().map(|v| v - total / 6.0).collect::<Vec<f64>>()));
    for n in 0..4 {
        let coeff: Vec<f64> = basis[n].iter().map(|v| dot(&X, v) / dot(v, v)).collect();
        let road2: Vec<f64> = (0..6).map(|i| coeff.iter().zip(&basis[n]).map(|(c, v)| c * v[i]).sum()).collect();
        let sizes: Vec<f64> = (0..12).map(|g| size(&apply(&proj[n], &apply(&rho[g], &X)))).collect();
        let spread = sizes.iter().cloned().fold(f64::MIN, f64::max) - sizes.iter().cloned().fold(f64::MAX, f64::min);
        println!("{}: {}  size {} mm, same after all 12 relabellings: {}", names[n], fl(&road1[n]), f(size(&road1[n])),
                 if spread < 1e-12 { "yes" } else { "no" });
        assert!(road1[n].iter().zip(&road2).all(|(a, b)| (a - b).abs() < 1e-12)); // two roads agree
        assert!(spread < 1e-12);                                  // size ignores the labels
    }
    let dev = size(&X.iter().map(|v| v - total / 6.0).collect::<Vec<f64>>());
    let parts: Vec<f64> = (1..4).map(|n| size(&road1[n])).collect();
    let pyth = parts.iter().map(|p| p * p).sum::<f64>().sqrt();
    println!("squared sizes: {} = {}", parts.iter().map(|p| f(p * p)).collect::<Vec<_>>().join(" + "), f(pyth * pyth));
    println!("deviation from the mean, mm: {}; from the pieces by Pythagoras: {}", f(dev), f(pyth));

    // Change of basis: every rho(g) becomes blocks of size 1, 1, 2, 2.
    let cols: Vec<Vec<f64>> = basis.iter().flatten().map(|v| v.iter().map(|c| c / size(v)).collect()).collect();
    let b: M = (0..6).map(|i| (0..6).map(|j| cols[j][i]).collect()).collect();
    let bt: M = cols.clone();
    let block = [0, 1, 2, 2, 3, 3];
    let mut leak: f64 = 0.0;
    for g in 0..12 {
        let t = mul(&mul(&bt, &rho[g]), &b);
        for i in 0..6 { for j in 0..6 { if block[i] != block[j] { leak = leak.max(t[i][j].abs()) } } }
    }
    let t = mul(&mul(&bt, &rho[1]), &b);
    println!("largest entry outside the 1,1,2,2 blocks, over all 12 moves: {}", f(leak));
    println!("R60 on the tilt plane: [[{}, {}], [{}, {}]]", f(t[2][2]), f(t[2][3]), f(t[3][2]), f(t[3][3]));
    println!("R60 on the three-wave plane: [[{}, {}], [{}, {}]]", f(t[4][4]), f(t[4][5]), f(t[5][4]), f(t[5][5]));

    // What breaks.
    let arm0: Vec<f64> = (0..12).map(|g| dot(&rho[g][0], &X) - total / 6.0).collect();
    let disc = |a: usize| (t[a][a] + t[a + 1][a + 1]).powi(2) - 4.0 * (t[a][a] * t[a + 1][a + 1] - t[a][a + 1] * t[a + 1][a]);
    let s: M = vec![vec![1.0, 1.0], vec![0.0, 1.0]];          // a shear: the group of all S^t, t real
    let on_line = |v: &M| { let w = mul(&s, v); (v[0][0] * w[1][0] - v[1][0] * w[0][0]).abs() < 1e-12 };
    let kept = (-100..=100).filter(|&a| on_line(&vec![vec![a as f64 / 10.0], vec![1.0]])).count();
    println!("mistake 1, indices read backwards: rho(gh) = rho(g) rho(h) fails for {} of 144 pairs", bad);
    println!("mistake 2, arm 0's own excess over relabellings: from {} to {} mm",
             f(arm0.iter().cloned().fold(f64::MAX, f64::min)), f(arm0.iter().cloned().fold(f64::MIN, f64::max)));
    println!("mistake 3, R60 on the tilt plane: tr^2 - 4 det = {}; on the three-wave plane: {}; no real axis", f(disc(2)), f(disc(4)));
    println!("mistake 4, shear [[1, 1], [0, 1]]: x-axis kept: {}; lines through (a, 1) kept: {} of 201",
             if on_line(&vec![vec![1.0], vec![0.0]]) { "yes" } else { "no" }, kept);
    assert!(good == 144 && bad == 72 && kept == 0);           // a representation; its mirror and the shear fail
    assert!(chi_int == vec![6, 0, 0, 0, 0, 0, 0, 2, 0, 2, 0, 2]); // independent count of fixed arms
    assert!((n_pieces - 4.0).abs() < 1e-12 && leak < 1e-12);
    assert!((alt_sum / 6.0 - road1[1][0]).abs() < 1e-12 && (disc(2) + 3.0).abs().max((disc(4) + 3.0).abs()) < 1e-12);
    assert!((dev - pyth).abs() < 1e-12 && (parts[0] - 0.08 * 6f64.sqrt()).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
