// Quantum limits -- the same check as the Python, in Rust.  No crates.  Amplitudes are a
// classical simulation (the Qubits card explains the state vector); every matrix is real.
use std::f64::consts::PI;
type Mat = Vec<Vec<f64>>;
fn rnd(s: &mut u64) -> f64 { // SplitMix64: a float in [-1, 1)
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(52) - 1.0
}
fn fmt(v: f64) -> String { if v.abs() < 1e-12 { "below 1e-12".to_string() } else { format!("{:.6}", v) } }
fn diffs(q: &[f64], k: usize) -> f64 { // k-th finite difference of a list
    let mut q = q.to_vec();
    for _ in 0..k { q = q.windows(2).map(|w| w[1] - w[0]).collect(); }
    q.iter().fold(0.0, |m: f64, a| m.max(a.abs()))
}
const N_BITS: usize = 6; const W: usize = 2; const D: usize = N_BITS * 2 * W; // registers (i, b, w)
fn orth(rng: &mut u64) -> Mat { // a random rotation, by Gram-Schmidt
    let mut rows: Mat = Vec::new();
    while rows.len() < D {
        let mut v: Vec<f64> = (0..D).map(|_| rnd(rng)).collect();
        for r in &rows {
            let p: f64 = v.iter().zip(r).map(|(a, b)| a * b).sum();
            v = v.iter().zip(r).map(|(a, b)| a - p * b).collect();
        }
        let l = v.iter().map(|b| b * b).sum::<f64>().sqrt();
        rows.push(v.iter().map(|a| a / l).collect());
    }
    rows
}
fn run(u: &[Mat], x: usize) -> f64 { // U0, query, U1, query, ..., UT
    let mut v = vec![0.0; D]; v[0] = 1.0;
    for (t, m) in u.iter().enumerate() {
        if t > 0 { v = (0..D).map(|j| v[j ^ (((x >> (j / (2 * W))) & 1) * W)]).collect(); } // query: b xor x_i
        v = m.iter().map(|r| r.iter().zip(&v).map(|(a, b)| a * b).sum()).collect();
    }
    (0..D).filter(|j| j % W == 1).map(|j| v[j] * v[j]).sum() // accept: w reads 1
}
fn grover(marked: &[usize], g: usize, t: usize) -> Vec<f64> { // T rounds
    let mut v = vec![0.25; g];
    for _ in 0..t {
        for &j in marked { v[j] = -v[j]; }
        let s: f64 = v.iter().sum();
        v = v.iter().map(|a| 2.0 * s / g as f64 - a).collect(); // twice the mean minus each
    }
    v
}
fn kron(a: &Mat, b: &Mat) -> Mat {
    let (k, n) = (b.len(), a.len() * b.len());
    (0..n).map(|i| (0..n).map(|j| a[i / k][j / k] * b[i % k][j % k]).collect()).collect()
}
fn below(a: &Mat, lam: f64) -> usize { // eigenvalues below lam, from pivot signs
    let n = a.len();
    let mut b: Mat = (0..n).map(|i| (0..n).map(|j| a[i][j] - if i == j { lam } else { 0.0 }).collect()).collect();
    let mut neg = 0;
    for i in 0..n {
        let piv = if b[i][i].abs() > 1e-300 { b[i][i] } else { 1e-300 };
        if piv < 0.0 { neg += 1; }
        for r in i + 1..n { let f = b[r][i] / piv; for c in 0..n { b[r][c] -= f * b[i][c]; } }
    }
    neg
}
fn lowest(a: &Mat) -> f64 { // bisection on that count
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if below(a, mid) >= 1 { hi = mid } else { lo = mid } }
    (lo + hi) / 2.0
}
fn energy(a: &Mat, v: &[f64]) -> f64 { (0..v.len()).map(|i| (0..v.len()).map(|j| v[i] * a[i][j] * v[j]).sum::<f64>()).sum() }
fn main() {
    // ---- 1. the example: one marked entry in N = 1,000,000 ----
    let n = 1_000_000f64;
    let th = (1.0 / n.sqrt()).asin();
    let kb = (PI / (4.0 * th)).floor() as usize;
    let (mut s, mut c) = (th.sin(), th.cos()); // road one: two reflections in the plane
    for _ in 0..kb {
        s = -s; // oracle: flip the key's sign
        let d = 2.0 * (s * th.sin() + c * th.cos()); // diffusion: reflect across the start
        (s, c) = (d * th.sin() - s, d * th.cos() - c);
    }
    let pk = ((2 * kb + 1) as f64 * th).sin().powi(2); // road two: the angle formula
    assert!((s * s - pk).abs() < 1e-9);
    println!("N = {}, sqrt N = {:.0}: theta = {:.10}, Grover rounds floor(pi/(4 theta)) = {}, success {:.8}", n as u64, n.sqrt(), th, kb, pk);
    let t23 = (0..kb).find(|&t| ((2 * t + 1) as f64 * th).sin().powi(2) >= 2.0 / 3.0).unwrap();
    println!("error 1/3: {} rounds + 1 checking query = {} queries; classical: {} looks", t23, t23 + 1, (2.0 * n / 3.0).ceil());
    let poly = n.sqrt() / 4.0; // polynomial method: 2T >= sqrt(N/4)
    let dist = (2.0 - 4.0 * (2.0f64 / 9.0).sqrt()).sqrt();
    let hyb = dist / 2.0 * n.sqrt(); // hybrid argument
    println!("lower bounds: polynomial method T >= {:.1}; hybrid: distance {:.4}, T >= {:.4} sqrt N = {:.1}", poly, dist, dist / 2.0, hyb);
    assert!(poly <= (t23 + 1) as f64);
    for e in 2..7 { // chart points
        let e = e as f64;
        println!("chart N = 10^{}: Grover {}, bound {:.1}, classical {}", e,
                 (PI / (4.0 * 10f64.powf(-e / 2.0).asin())).floor(), 10f64.powf(e / 2.0) / 4.0, (2.0 * 10f64.powf(e) / 3.0).ceil());
    }
    // ---- 2. any T-query algorithm: acceptance is a polynomial of degree <= 2T ----
    let mut rng = 0x2026u64; // SplitMix64 seed
    let wt: Vec<usize> = (0..1usize << N_BITS).map(|x| x.count_ones() as usize).collect();
    for t in [1usize, 2] {
        let u: Vec<Mat> = (0..t + 1).map(|_| orth(&mut rng)).collect();
        let p: Vec<f64> = (0..1 << N_BITS).map(|x| run(&u, x)).collect();
        let mut co = p.clone(); // Moebius inversion: multilinear coefficients
        for i in 0..N_BITS { for x in (0..1usize << N_BITS).filter(|x| (x >> i) & 1 == 1) { co[x] -= co[x ^ (1 << i)]; } }
        let big: Vec<f64> = (0..=N_BITS).map(|k| (0..1 << N_BITS).filter(|&x| wt[x] == k)
            .fold(0.0, |m: f64, x| m.max(co[x].abs()))).collect();
        println!("T = {}: largest coefficient by degree 0..6: {}", t,
                 big.iter().map(|&b| fmt(b)).collect::<Vec<_>>().join(", "));
        assert!(big[2 * t + 1..].iter().all(|&b| b < 1e-9) && big[2 * t] > 1e-3);
        let q: Vec<f64> = (0..=N_BITS).map(|k| {
            let xs: Vec<usize> = (0..1 << N_BITS).filter(|&x| wt[x] == k).collect();
            xs.iter().map(|&x| p[x]).sum::<f64>() / xs.len() as f64
        }).collect();
        println!("T = {}: symmetrised q(k), difference of order {}: largest {}", t, 2 * t + 1, fmt(diffs(&q, 2 * t + 1)));
        assert!(diffs(&q, 2 * t + 1) < 1e-9);
    }
    // ---- 3. Grover on 16 entries: its polynomial, and the hybrid sum ----
    let (g, t) = (16usize, 3usize);
    let q: Vec<f64> = (0..=g).map(|k| {
        let v = grover(&(0..k).collect::<Vec<_>>(), g, t);
        (0..k).fold(0.0, |s, j| s + v[j] * v[j])
    }).collect();
    assert!((0..=g).all(|k| (q[k] - (7.0 * (k as f64 / g as f64).sqrt().asin()).sin().powi(2)).abs() < 1e-12));
    println!("Grover, 16 entries, 3 rounds + check: q(0) = {:.4}, q(1) = {:.4}, q(2) = {:.4}, q(4) = {:.4}; difference of order 8: largest {}",
             q[0], q[1], q[2], q[4], fmt(diffs(&q, 8)));
    assert!(diffs(&q, 8) < 1e-9 && diffs(&q, 7) > 1e-3);
    let hs: f64 = (0..g).map(|i| grover(&[i], g, t).iter().map(|a| (a - 0.25).powi(2)).sum::<f64>().sqrt()).sum();
    println!("hybrid sum of distances: {:.4} <= 2 T sqrt(16) = {}", hs, 2 * t * 4);
    assert!((hs - 32.0 * (3.0 * 0.25f64.asin()).sin()).abs() < 1e-9); assert!(hs <= (2 * t * 4) as f64); // 16 x 2 sin(3 theta)
    // ---- 4. local Hamiltonians on 2 qubits: basis 00, 01, 10, 11 ----
    let (z, x): (Mat, Mat) = (vec![vec![1.0, 0.0], vec![0.0, -1.0]], vec![vec![0.0, 1.0], vec![1.0, 0.0]]);
    let zz = kron(&z, &z);
    println!("H = Z x Z: diagonal {}; lowest by bisection {:.4}; eigenvalues below -0.5: {}, below 0.5: {}",
             (0..4).map(|i| format!("{}", zz[i][i] as i64)).collect::<Vec<_>>().join(", "),
             lowest(&zz), below(&zz, -0.5), below(&zz, 0.5));
    assert!((lowest(&zz) + 1.0).abs() < 1e-9 && below(&zz, -0.5) == 2);
    for (name, v) in [("|01>", [0.0, 1.0, 0.0, 0.0]), ("|00>", [1.0, 0.0, 0.0, 0.0]), ("|++>", [0.5; 4])] {
        let e = energy(&zz, &v);
        println!("witness {}: energy {:.4}, verifier accepts with probability (1 - energy)/2 = {:.4}", name, e, (1.0 - e) / 2.0);
    }
    let xx = kron(&x, &x);
    let h2: Mat = (0..4).map(|i| (0..4).map(|j| zz[i][j] + xx[i][j]).collect()).collect();
    let mut best = f64::INFINITY; // product states (cos a, sin a) x (cos b, sin b), 2.5 degree steps
    for k in 0..72 * 72 { let (a, b) = (PI * (k / 72) as f64 / 72.0, PI * (k % 72) as f64 / 72.0);
        best = best.min(energy(&h2, &[a.cos() * b.cos(), a.cos() * b.sin(), a.sin() * b.cos(), a.sin() * b.sin()])); }
    let sing = energy(&h2, &[0.0, 0.5f64.sqrt(), -(0.5f64.sqrt()), 0.0]);
    println!("H = ZxZ + XxX: lowest by bisection {:.4}; (|01> - |10>)/sqrt 2 has energy {:.4}; best product state {:.4}", lowest(&h2), sing, best);
    assert!((lowest(&h2) + 2.0).abs() < 1e-9 && (sing + 2.0).abs() < 1e-12);
    assert!((best + 1.0).abs() < 1e-9); assert!(best > lowest(&h2) + 0.5); // no product state gets near the ground energy
    // ---- 5. Kitaev's construction on a one-gate circuit: witness w, work q, clock c ----
    for deg in [0, 30, 60, 90] { // gate: if w = 1, turn q by deg degrees
        let f = deg as f64 * PI / 180.0;
        let u = [[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, f.cos(), -f.sin()], [0.0, 0.0, f.sin(), f.cos()]];
        let mut h: Mat = vec![vec![0.0; 8]; 8]; // index 2 (2w + q) + c
        for a in 0..4 {
            h[2 * a][2 * a] += 0.5; h[2 * a + 1][2 * a + 1] += 0.5; // propagation term
            for b in 0..4 { h[2 * a + 1][2 * b] -= 0.5 * u[a][b]; h[2 * b][2 * a + 1] -= 0.5 * u[a][b]; }
            h[2 * a + 1 - a % 2][2 * a + 1 - a % 2] += 1.0; // q = 1 at c = 0, or q = 0 at c = 1
        }
        let acc = f.sin().powi(2); // best witness w = 1
        let (e0, e1) = (lowest(&h), 1.0 - ((1.0 + acc.sqrt()) / 2.0).sqrt()); // bisection; closed form
        println!("gate {:2} deg: best acceptance {:.4}; ground energy {:.6} (formula {:.6}); history state (1 - acceptance)/2 = {:.6}",
                 deg, acc, e0.abs(), e1, (1.0 - acc) / 2.0);
        assert!((e0 - e1).abs() < 1e-9 && e0 <= (1.0 - acc) / 2.0 + 1e-12);
    }
    // ---- 6. what breaks ----
    println!("mistake 1, degree T not 2T: bound sqrt(N)/2 = {:.0} > {} queries Grover uses", n.sqrt() / 2.0, t23 + 1);
    println!("mistake 2, q(k) = (1 + k)/3 has degree 1 but q(N) = {:.2}, not a probability", (1.0 + n) / 3.0);
    println!("mistake 3, a sorted list: binary search needs {} classical looks", n.log2().ceil());
    println!("mistake 4, classical witness for ZxZ + XxX: energy {:.4}, not {:.4}", best, sing);
    println!("ALL CHECKS PASS");
}
