// Neumann series -- the same check as the Python, in Rust.  No crates.
// A sheet with a weak circular reference: three support departments whose
// full costs depend on each other, x = b + Kx, in pounds a month.
// Road 1 repeats K and adds up (the Neumann series).  Road 2 solves
// (I - K)x = b by elimination.  Road 3 is an invariant: every pound of
// direct cost is charged out exactly once.  Then the same series on a blur.
type Mat = Vec<Vec<f64>>;

fn matvec(a: &Mat, v: &[f64]) -> Vec<f64> {
    a.iter().map(|row| row.iter().zip(v).fold(0.0, |s, (x, t)| s + x * t)).collect()
}

fn size(v: &[f64]) -> f64 { v.iter().fold(0.0, |m: f64, t| m.max(t.abs())) } // worst-case size

fn opnorm(a: &Mat) -> f64 {                     // largest row sum: the most K can stretch
    a.iter().map(|row| row.iter().fold(0.0, |s, x| s + x.abs())).fold(0.0, f64::max)
}

fn neumann(a: &Mat, b: &[f64], n: usize) -> Vec<f64> { // b + Ab + ... + A^(n-1) b
    let (mut s, mut term) = (vec![0.0; b.len()], b.to_vec());
    for _ in 0..n {
        s = s.iter().zip(&term).map(|(t, u)| t + u).collect();
        term = matvec(a, &term);
    }
    s
}

fn solve(a: &Mat, b: &[f64]) -> Vec<f64> {     // (I - A)x = b by elimination, row swaps
    let n = b.len();
    let mut m: Mat = (0..n).map(|i| {
        let mut row: Vec<f64> = (0..n).map(|j| (if i == j { 1.0 } else { 0.0 }) - a[i][j]).collect();
        row.push(b[i]);
        row
    }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c + 1..n { if m[r][c].abs() > m[p][c].abs() { p = r } }
        m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            for k in c..n + 1 { let v = m[c][k]; m[r][k] -= f * v }
        }
    }
    let mut x = vec![0.0; n];
    for r in (0..n).rev() {
        let s = (r + 1..n).fold(0.0, |s, k| s + m[r][k] * x[k]);
        x[r] = (m[r][n] - s) / m[r][r];
    }
    x
}

fn rounds_for(q: f64, nb: f64, tol: f64) -> usize { // first n with q^n / (1 - q) * |b| <= tol
    let mut n = 0;
    while q.powf(n as f64) / (1.0 - q) * nb > tol { n += 1 }
    n
}

fn fmt(v: &[f64], d: usize) -> String {
    v.iter().map(|t| format!("{:.*}", d, t)).collect::<Vec<_>>().join(", ")
}
fn f2(v: &[f64]) -> String { fmt(v, 2) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn gap(a: &[f64], b: &[f64]) -> f64 { size(&a.iter().zip(b).map(|(s, t)| s - t).collect::<Vec<_>>()) }

fn blur(c: f64, n: usize) -> Mat {             // c * G(s, t) / N on the midpoint grid
    let s: Vec<f64> = (0..n).map(|i| (i as f64 + 0.5) / n as f64).collect();
    s.iter().map(|&u| s.iter().map(|&v| c * u.min(v) * (1.0 - u.max(v)) / n as f64).collect()).collect()
}

fn main() {
    let k: Mat = vec![vec![0.0, 0.10, 0.20], vec![0.15, 0.0, 0.10], vec![0.05, 0.10, 0.0]];
    let b = vec![40000.0, 20000.0, 30000.0];
    let (q, nb) = (opnorm(&k), size(&b));
    let x = solve(&k, &b);
    let rows: Vec<f64> = k.iter().map(|r| r.iter().fold(0.0, |s, a| s + a)).collect();
    println!("sheet: row sums {}; q = {:.2}; |b| = {:.2}", f2(&rows), q, nb);
    println!("road 2, elimination: IT {:.2}, HR {:.2}, Facilities {:.2}", x[0], x[1], x[2]);
    let kb = matvec(&k, &b);
    println!("Kb = {}; K^2 b = {}", f2(&kb), f2(&matvec(&k, &kb)));
    let errs: Vec<f64> = (0..13).map(|n| gap(&neumann(&k, &b, n), &x)).collect();
    let bnds: Vec<f64> = (0..13).map(|n| q.powf(n as f64) / (1.0 - q) * nb).collect();
    println!("S_3 = {}; true error {:.2}; bound {:.2}", f2(&neumann(&k, &b, 3)), errs[3], bnds[3]);
    let lg = |v: &Vec<f64>| fmt(&v.iter().map(|e| e.log10()).collect::<Vec<_>>(), 2);
    println!("chart n = 0..12, log10 true error: {}", lg(&errs));
    println!("chart n = 0..12, log10 bound:      {}", lg(&bnds));
    let first_true = (0..13).find(|&n| errs[n] < 1.0).unwrap();
    println!("rounds for 1 pound: promised by the bound {}; needed in fact {}", rounds_for(q, nb, 1.0), first_true);
    let (mut v, mut ip) = (vec![0.0; 3], vec![size(&x)]); // a sheet updating its cells in place, top to bottom
    for _ in 0..12 {
        for i in 0..3 { v[i] = b[i] + (0..3).fold(0.0, |s, j| s + k[i][j] * v[j]); }
        ip.push(gap(&v, &x));
    }
    println!("in place (Gauss-Seidel): worst error after rounds 1-5 {}; first under 1 pound at round {}",
             f2(&ip[1..6]), (0..13).find(|&n| ip[n] < 1.0).unwrap());
    let s30 = neumann(&k, &b, 30);
    println!("road 1, 30 rounds: {}; gap to road 2 below 1e-6: {}", f2(&s30), yn(gap(&s30, &x) < 1e-6));
    let charged = (0..3).fold(0.0, |s, j| s + (1.0 - (0..3).fold(0.0, |c, i| c + k[i][j])) * x[j]);
    let total = b.iter().fold(0.0, |s, t| s + t);
    println!("road 3, charged out to the earning departments: {:.2} of {:.2}", charged, total);
    let kx = matvec(&k, &x);
    let res: Vec<f64> = (0..3).map(|i| x[i] - b[i] - kx[i]).collect();
    println!("residual |x - b - Kx| below 1e-9: {}", yn(size(&res) < 1e-9));
    println!("size of the answer {:.2}; inverse bound |b| / (1 - q) = {:.2}", size(&x), nb / (1.0 - q));
    let k2: Mat = vec![vec![0.0, 2.0], vec![0.1, 0.0]]; // norm 2, yet K2 squared = 0.2 I
    let (y2, s2) = (solve(&k2, &[1.0, 1.0]), neumann(&k2, &[1.0, 1.0], 60));
    println!("norm above 1, series still converges: q = {:.2}; 60 rounds {}; elimination {}",
             opnorm(&k2), fmt(&s2, 4), fmt(&y2, 4));
    let l: Mat = vec![vec![0.0, 1.25], vec![0.9, 0.0]]; // A = 100 + 1.25 B, B = 0.9 A
    let (a20, al) = (neumann(&l, &[100.0, 0.0], 20)[0], solve(&l, &[100.0, 0.0])[0]);
    println!("mistake 1, loop gain {:.3}: A after 10 rounds {:.2}, after 20 {:.2}; elimination gives A = {:.2}",
             l[0][1] * l[1][0], neumann(&l, &[100.0, 0.0], 10)[0], a20, al);
    let one: Mat = vec![vec![0.9]];               // x = 100 + 0.9x, truth 1000
    let mut n = 1;
    while 100.0 * 0.9f64.powf((n - 1) as f64) >= 1.0 { n += 1 } // stop once a round changes x by under 1 pound
    let err9 = 1000.0 - neumann(&one, &[100.0], n)[0];
    let naive = 0.9f64.powf(n as f64) * 100.0;
    println!("mistake 2, q = 0.9, stop when the change is under 1 pound: round {}, true error {:.2}", n, err9);
    println!("mistake 3, bound without 1/(1 - q): {:.2}, below the true error {:.2}", naive, err9);
    println!("mistake 4, q = 0.99, the sheet's 100-round cap: {:.2} of 10000.00", neumann(&vec![vec![0.99]], &[100.0], 100)[0]);
    let kd: Mat = k.iter().map(|r| r.iter().map(|a| 2.0 * a).collect()).collect();
    let xd = solve(&kd, &b);
    println!("try: shares doubled, q = {:.2}; rounds for 1 pound by the bound {}; IT {:.2}", 2.0 * q, rounds_for(2.0 * q, nb, 1.0), xd[0]);
    let exact = 1.0 / 1f64.cos();                 // blur: x(s) = 1 + 4 * integral of G(s, t) x(t) dt
    let mut mids: Vec<f64> = Vec::new();
    for &nn in &[3usize, 9, 27, 81, 243] {
        let a = blur(4.0, nn);
        let ones = vec![1.0; nn];
        let (ser, el) = (neumann(&a, &ones, 40)[nn / 2], solve(&a, &ones)[nn / 2]);
        mids.push(ser);
        println!("blur N = {:3}: q_N = {:.6}; rounds for 1e-6 {}; x(1/2) {:.8}; minus 1/cos 1 = {:.8}; series = elimination: {}",
                 nn, opnorm(&a), rounds_for(opnorm(&a), 1.0, 1e-6), ser, ser - exact, yn((ser - el).abs() < 1e-9));
    }
    println!("library: 1/cos 1 = {:.8}", exact);
    let pi = std::f64::consts::PI;
    println!("limits: q = 4 x 1/8 = {:.6}; c = 8 gives 8 / pi^2 = {:.4}, below 1", 4.0 / 8.0, 8.0 / (pi * pi));
    let a8 = blur(8.0, 81);
    println!("try: c = 8, N = 81: q_N = {:.4}; x(1/2) after 300 rounds {:.6}; elimination {:.6}",
             opnorm(&a8), neumann(&a8, &vec![1.0; 81], 300)[40], solve(&a8, &vec![1.0; 81])[40]);
    assert!(gap(&s30, &x) < 1e-6);                                   // road 1 meets road 2
    assert!((charged - total).abs() < 1e-6);                         // road 3: 90000 charged out
    assert!((0..13).all(|n| errs[n] <= bnds[n]));                    // the bound holds every round
    assert!((0..13).all(|n| ip[n] <= bnds[n]));                      // and for the in-place sheet
    assert!(gap(&v, &x) < 1e-6);                                     // which settles on road 2 too
    assert!(gap(&s2, &y2) < 1e-9);                                   // series meets elimination
    assert!(opnorm(&k2) > 1.0);                                      // though the norm test fails
    assert!(a20.abs() > 1000.0 && (al + 800.0).abs() < 1e-9);
    assert!(n == (1.0 + 0.01f64.ln() / 0.9f64.ln()).ceil() as usize); // stop round, closed form
    assert!((err9 - 1000.0 * 0.9f64.powf(n as f64)).abs() < 1e-9);   // true error 1000 x 0.9^n
    assert!((mids[4] - exact).abs() < 3e-5);                         // grid meets 1/cos 1
    assert!((0..4).all(|i| { let r = (mids[i] - exact) / (mids[i + 1] - exact); 8.0 < r && r < 10.0 }));
    println!("ALL CHECKS PASS");
}
