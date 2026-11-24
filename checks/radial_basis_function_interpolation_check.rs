// Radial basis functions -- the check behind the card.  Standard library only.
// Hand example: nodes 0, 1, 2 with values 1, 2, 0 and the Gaussian exp(-r^2).
// Surface: 30 rate quotes at scattered (maturity, date) points on an illustrative model.
// Roads: Cholesky; Cramer's rule and elimination; Jacobi eigenvalues checked by trace and
// determinant; in 1-D the cubic kernel |r|^3 with a linear tail is the natural cubic spline.
type Mat = Vec<Vec<f64>>; type P2 = (f64, f64);
fn add<I: IntoIterator<Item = f64>>(xs: I) -> f64 { let mut s = 0.0; for v in xs { s += v; } s }
fn sci(v: f64) -> String { // Python's {:.3e}: mantissa, sign, two-digit exponent
    let s = format!("{:.3e}", v); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn cube(r: f64) -> f64 { r.abs() * r.abs() * r.abs() } fn maxf<I: IntoIterator<Item = f64>>(xs: I) -> f64 { xs.into_iter().fold(f64::NEG_INFINITY, f64::max) }
fn cholesky(a: &Mat) -> Result<Mat, (usize, f64)> { // A = L L^T; stops at a pivot <= 0
    let n = a.len(); let mut l = vec![vec![0.0; n]; n]; for j in 0..n {
        let p = a[j][j] - add((0..j).map(|k| l[j][k] * l[j][k]));
        if p <= 0.0 { return Err((j, p)); }
        l[j][j] = p.sqrt();
        for i in j + 1..n { l[i][j] = (a[i][j] - add((0..j).map(|k| l[i][k] * l[j][k]))) / l[j][j]; }
    } Ok(l) }
fn chol_solve(l: &Mat, b: &[f64]) -> (Vec<f64>, Vec<f64>) { // forward sweep, then back sweep
    let n = b.len(); let mut y = vec![0.0; n]; let mut c = vec![0.0; n];
    for i in 0..n { y[i] = (b[i] - add((0..i).map(|k| l[i][k] * y[k]))) / l[i][i]; }
    for i in (0..n).rev() { c[i] = (y[i] - add((i + 1..n).map(|k| l[k][i] * c[k]))) / l[i][i]; }
    (y, c)
}
fn gauss(a: &Mat, b: &[f64]) -> Vec<f64> { // elimination with partial pivoting
    let n = b.len(); let mut m: Mat = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect(); let mut x = vec![0.0; n];
    for k in 0..n {
        let mut p = k; for i in k + 1..n { if m[i][k].abs() > m[p][k].abs() { p = i; } } m.swap(k, p);
        for i in k + 1..n { let f = m[i][k] / m[k][k]; for j in k..n + 1 { m[i][j] -= f * m[k][j]; } }
    }
    for i in (0..n).rev() { x[i] = (m[i][n] - add((i + 1..n).map(|j| m[i][j] * x[j]))) / m[i][i]; } x }
fn jacobi(a0: &Mat) -> Vec<f64> { // all eigenvalues of a symmetric matrix, by rotations
    let mut a = a0.clone(); let n = a.len(); for _sweep in 0..60 {
        if add((0..n).flat_map(|i| (0..n).map(move |j| (i, j))).filter(|&(i, j)| i != j).map(|(i, j)| a[i][j] * a[i][j])) < 1e-40 { break; }
        for p in 0..n { for q in p + 1..n {
            if a[p][q] == 0.0 { continue; }
            let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
            let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt()); let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
            for k in 0..n { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
            for k in 0..n { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
        } }
    }
    let mut d: Vec<f64> = (0..n).map(|i| a[i][i]).collect(); d.sort_by(|x, y| x.partial_cmp(y).unwrap()); d
}
fn det3(m: &Mat) -> f64 { m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]) } fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
struct Rng(u64); impl Rng { fn u01(&mut self) -> f64 { // SplitMix64, seed 20261124, then a uniform in [0, 1)
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 } }
fn rr(t: f64, d: f64) -> f64 { 3.6 + 0.9 * (1.0 - (-t / 7.0).exp()) - 0.3 * d / 250.0 + 0.2 * (std::f64::consts::PI * d / 250.0).sin() * t / 30.0 }
fn quotes(g: &mut Rng, k: usize) -> (Vec<P2>, Vec<P2>, Vec<f64>) {
    let td: Vec<P2> = (0..k).map(|_| { let t = 0.25 + 29.75 * g.u01(); let d = 250.0 * g.u01(); (t, d) }).collect();
    (td.clone(), td.iter().map(|&(t, d)| (t / 30.0, d / 250.0)).collect(), td.iter().map(|&(t, d)| rr(t, d)).collect())
}
fn d2(a: P2, b: P2) -> f64 { (a.0 - b.0) * (a.0 - b.0) + (a.1 - b.1) * (a.1 - b.1) } fn grid() -> Vec<P2> { (1..10).flat_map(|i| (1..10).map(move |j| (i as f64 / 10.0, j as f64 / 10.0))).collect() }
fn worst(f: &dyn Fn(P2) -> f64) -> f64 { maxf(grid().into_iter().map(|q| (f(q) - rr(30.0 * q.0, 250.0 * q.1)).abs())) * 100.0 }
struct Fit { x: Vec<P2>, c: Vec<f64>, ybar: f64, eps: f64 } impl Fit { fn at(&self, q: P2) -> f64 { self.ybar + add(self.c.iter().zip(&self.x).map(|(cj, &x)| cj * (-self.eps * self.eps * d2(q, x)).exp())) } }
fn gauss_rbf(x: &[P2], y: &[f64], eps: f64) -> (Result<(Fit, Mat, f64, Vec<f64>), (usize, f64)>, Mat) { // interpolate the gap from the average quote
    let ybar = add(y.iter().copied()) / y.len() as f64;
    let k: Mat = x.iter().map(|&a| x.iter().map(|&b| (-eps * eps * d2(a, b)).exp()).collect()).collect();
    match cholesky(&k) {
        Err(e) => (Err(e), k),
        Ok(l) => { let cg = chol_solve(&l, &y.iter().map(|v| v - ybar).collect::<Vec<_>>()).1; let big = maxf(cg.iter().map(|v| v.abs()));
                   let loo: Vec<f64> = (0..x.len()).map(|k| cg[k] / add(chol_solve(&l, &(0..x.len()).map(|i| if i == k { 1.0 } else { 0.0 }).collect::<Vec<_>>()).0.iter().map(|t| t * t))).collect(); // Rippa: c_k / (A^-1)_kk
                   (Ok((Fit { x: x.to_vec(), c: cg, ybar, eps }, l, big, loo)), k) }
    }
}
fn tp(r2: f64) -> f64 { if r2 == 0.0 { 0.0 } else { 0.5 * r2 * r2.ln() } } fn z(t: f64) -> f64 { let x = t / 2.0; let l1 = (1.0 - (-x).exp()) / x; 4.5 - 0.2 * l1 - 2.0 * (l1 - (-x).exp()) }
fn main() {
    // --- the hand example ---
    let xs: [f64; 3] = [0.0, 1.0, 2.0]; let ys = [1.0, 2.0, 0.0];
    let a: Mat = xs.iter().map(|&p| xs.iter().map(|&q| (-(p - q) * (p - q)).exp()).collect()).collect();
    let l = cholesky(&a).unwrap(); let (y, c) = chol_solve(&l, &ys);
    println!("hand: e^-1 = {:.9}, e^-4 = {:.9}", a[0][1], a[0][2]);
    for i in 0..3 { println!("hand: L row {}: {}", i + 1, join(&l[i][..i + 1], 9)); }
    println!("hand: forward sweep v = {}; coefficients c = {}", join(&y, 9), join(&c, 9));
    let dd = det3(&a); let ll = l[0][0] * l[1][1] * l[2][2] * l[0][0] * l[1][1] * l[2][2];
    let cr: Vec<f64> = (0..3).map(|j| det3(&(0..3).map(|i| (0..3).map(|k| if k == j { ys[i] } else { a[i][k] }).collect()).collect()) / dd).collect();
    let gap = maxf(c.iter().zip(&cr).map(|(p, q)| (p - q).abs()));
    println!("hand: determinant {:.9} = (L11 L22 L33)^2 = {:.9}; Cramer max gap {}", dd, ll, sci(gap));
    assert!(gap < 1e-14 && (dd - ll).abs() < 1e-14);
    let s = |x: f64| add(c.iter().zip(&xs).map(|(cj, xj)| cj * (-(x - xj) * (x - xj)).exp()));
    let miss = maxf(xs.iter().zip(&ys).map(|(&x, v)| (s(x) - v).abs()));
    println!("hand: s(0.5) = {:.9}; s(1.5) = {:.9}; worst miss at the nodes {}", s(0.5), s(1.5), sci(miss));
    let ev3 = jacobi(&a);
    println!("hand: eigenvalues {}; product {:.9}", join(&ev3, 9), ev3[0] * ev3[1] * ev3[2]);
    assert!(miss < 1e-14 && ev3[0] > 0.0 && (ev3[0] * ev3[1] * ev3[2] - dd).abs() < 1e-14);
    let dup: [f64; 3] = [0.0, 1.0, 1.0];
    let (j, p) = cholesky(&dup.iter().map(|&p| dup.iter().map(|&q| (-(p - q) * (p - q)).exp()).collect()).collect()).unwrap_err();
    println!("break: node 1 quoted twice -> Cholesky stops at row {}, pivot {}", j + 1, sci(p));
    assert!(j == 2 && p.abs() < 1e-15);
    // --- the surface: 30 scattered quotes ---
    let mut g = Rng(20261124);
    let (td, x, yv) = quotes(&mut g, 30); let n = x.len();
    let (t0, true0) = ((0.5, 0.5), rr(15.0, 125.0));
    println!("surface: first 3 quotes (maturity yrs, day, rate %): {}", (0..3).map(|i| format!("{:.2}, {:.1}, {:.4}", td[i].0, td[i].1, yv[i])).collect::<Vec<_>>().join("; "));
    println!("surface: average quote {:.6}%; target 15y on day 125, true {:.6}%", add(yv.iter().copied()) / n as f64, true0);
    println!("   eps    kappa       lam_min    node resid bp  worst err bp  err at target bp  largest |c|  LOO worst bp");
    let mut tab: Vec<(f64, f64, f64, f64, f64, Vec<f64>, Mat, Mat, f64, Vec<f64>)> = vec![]; // eps, kappa, resid, worst, target err, ev, K, L, LOO worst, LOO errors
    for eps in [8.0, 4.0, 2.0, 1.0, 0.7, 0.5, 0.3] { // 0.3 is the break
        let (r, k) = gauss_rbf(&x, &yv, eps); let ev = jacobi(&k);
        match r {
            Err((j, p)) => { println!("break: eps {:.1}, Cholesky stops at row {}, pivot {}; Jacobi lam_min {}", eps, j + 1, sci(p), sci(ev[0])); break; }
            Ok((f, l, big, loo)) => {
                let res = maxf(x.iter().zip(&yv).map(|(&q, v)| (f.at(q) - v).abs())) * 100.0;
                let w = worst(&|q| f.at(q)); let te = (f.at(t0) - true0) * 100.0; let kap = ev[ev.len() - 1] / ev[0]; let lm = maxf(loo.iter().map(|e| e.abs())) * 100.0;
                println!("{:6.1}  {}  {}   {}      {:9.4}     {:9.4}       {}     {:7.4}", eps, sci(kap), sci(ev[0]), sci(res), w, te, sci(big), lm);
                tab.push((eps, kap, res, w, te, ev, k, l, lm, loo));
            }
        }
    }
    let row = |e: f64| tab.iter().find(|t| t.0 == e).unwrap();
    let (ev, k, l) = (&row(2.0).5, &row(2.0).6, &row(2.0).7); let mut v = vec![1.0; n]; let mut lam = 1.0;
    for _ in 0..200 { let w: Vec<f64> = (0..n).map(|i| add((0..n).map(|j| k[i][j] * v[j]))).collect(); lam = add(w.iter().map(|t| t * t)).sqrt(); v = w.iter().map(|t| t / lam).collect(); }
    let ld = add(ev.iter().map(|t| t.ln())); let lc = 2.0 * add((0..n).map(|i| l[i][i].ln()));
    println!("eps 2 check: trace {:.9} (n = 30); log det by eigenvalues {:.6}, by Cholesky {:.6}; lam_max by power {:.9}, by Jacobi {:.9}", add(ev.iter().copied()), ld, lc, lam, ev[n - 1]);
    assert!((add(ev.iter().copied()) - n as f64).abs() < 1e-9 && (ld - lc).abs() < 1e-6 && (lam - ev[n - 1]).abs() < 1e-9 && [8.0, 4.0, 2.0, 1.0].iter().all(|&e| row(e).5[0] > 0.0));
    assert!(row(1.0).1 > 1e11 && row(0.7).1 > 1e12 && row(0.7).3 < row(2.0).3 / 10.0 && row(0.5).2 > 1e6 * row(2.0).2 && tab.iter().all(|t| t.0 != 0.3));
    let z2: Vec<f64> = yv.iter().map(|v| v - add(yv.iter().copied()) / n as f64).collect(); let k2 = &row(2.0).6; // eps 2: leave quote 1 out and refit by brute force
    let e1 = z2[0] - add(gauss(&k2[1..].iter().map(|r| r[1..].to_vec()).collect(), &z2[1..]).iter().enumerate().map(|(j, cj)| cj * k2[0][j + 1]));
    let pk = tab.iter().fold(&tab[0], |b, t| if t.8 < b.8 { t } else { b }); let bst = tab.iter().fold(&tab[0], |b, t| if t.3 < b.3 { t } else { b });
    println!("leave-one-out, eps 2, quote 1: Rippa {:.6} bp, refit {:.6} bp; LOO picks eps {:.1}, worst err {:.4} bp; best {:.4} bp at eps {:.1}", row(2.0).9[0] * 100.0, e1 * 100.0, pk.0, pk.3, bst.3, bst.0);
    let f5 = Fit { x: x.clone(), c: gauss(&row(0.5).6, &z2), ybar: add(yv.iter().copied()) / n as f64, eps: 0.5 }; let w5 = worst(&|q| f5.at(q));
    println!("eps 0.5 by elimination with row swaps: worst err {:.4} bp (Cholesky {:.4} bp; eps 0.7 {:.4} bp)", w5, row(0.5).3, row(0.7).3);
    assert!((row(2.0).9[0] - e1).abs() < 1e-12 && pk.3 < 1.5 * bst.3 && w5 > row(0.7).3 && (w5 - row(0.5).3).abs() < row(0.5).3 - row(0.7).3);
    // --- thin-plate spline: r^2 log r with the tail b0 + b1 x1 + b2 x2 ---
    let phi: Mat = x.iter().map(|&a| x.iter().map(|&b| tp(d2(a, b))).collect()).collect();
    let mut sm: Mat = (0..n).map(|i| { let mut r = phi[i].clone(); r.extend([1.0, x[i].0, x[i].1]); r }).collect();
    for col in 0..3 { let mut r: Vec<f64> = x.iter().map(|q| [1.0, q.0, q.1][col]).collect(); r.extend([0.0; 3]); sm.push(r); }
    let mut rhs = yv.clone(); rhs.extend([0.0; 3]); let sol = gauss(&sm, &rhs); let (ct, tl) = (&sol[..n], &sol[n..]);
    let gt = |q: P2| tl[0] + tl[1] * q.0 + tl[2] * q.1 + add(ct.iter().zip(&x).map(|(cj, &p)| cj * tp(d2(q, p))));
    let evp = jacobi(&phi); let qf = add((0..n).map(|i| ct[i] * add((0..n).map(|j| phi[i][j] * ct[j])))); let wt = worst(&gt);
    let pos = |e: &[f64]| e.iter().filter(|&&t| t > 0.0).count(); let neg = |e: &[f64]| e.iter().filter(|&&t| t < 0.0).count();
    println!("thin plate: trace of r^2 log r matrix {:.1}; eigenvalues {} positive, {} negative", add((0..n).map(|i| phi[i][i])), pos(&evp), neg(&evp));
    println!("thin plate: side sums of c {}, {}; c^T Phi c = {:.9} > 0", sci(add(ct.iter().copied()).abs()), sci(add(ct.iter().zip(&x).map(|(cj, p)| cj * p.0)).abs()), qf);
    let tres = maxf(x.iter().zip(&yv).map(|(&q, v)| (gt(q) - v).abs())) * 100.0;
    println!("thin plate: target {:.6}%, error {:.4} bp; worst on grid {:.4} bp; node resid {} bp", gt(t0), (gt(t0) - true0) * 100.0, wt, sci(tres));
    assert!(evp[0] < 0.0 && 0.0 < evp[n - 1] && qf > 0.0 && wt < 10.0 && (gt(t0) - true0).abs() * 100.0 < 1.0);
    let (j, p) = cholesky(&phi).unwrap_err(); let nt = gauss(&phi, &yv);
    let hn = |q: P2| add(nt.iter().zip(&x).map(|(cj, &p)| cj * tp(d2(q, p)))); let wn = worst(&hn);
    println!("break: Cholesky on the thin-plate matrix stops at row {}, pivot {:.1}", j + 1, p);
    println!("break: thin plate with no tail, target {:.6}%, error {:.4} bp; worst on grid {:.4} bp", hn(t0), (hn(t0) - true0) * 100.0, wn);
    let mq = jacobi(&x.iter().map(|&a| x.iter().map(|&b| (1.0 + 4.0 * d2(a, b)).sqrt()).collect()).collect());
    let im = jacobi(&x.iter().map(|&a| x.iter().map(|&b| 1.0 / (1.0 + 4.0 * d2(a, b)).sqrt()).collect()).collect());
    println!("multiquadric eps 2: {} positive, {} negative eigenvalues; inverse multiquadric smallest {}", pos(&mq), neg(&mq), sci(im[0]));
    assert!(j == 0 && wn > 3.0 * wt && pos(&mq) == 1 && im[0] > 0.0);
    let (_, x2, y2) = quotes(&mut g, 30); let x60 = [x.clone(), x2].concat(); let y60 = [yv.clone(), y2].concat(); // try: 60 quotes
    let (r60, k60) = gauss_rbf(&x60, &y60, 2.0); let f60 = r60.ok().unwrap().0; let e60 = jacobi(&k60); let w60 = worst(&|q| f60.at(q));
    println!("try: 60 quotes, eps 2: kappa {}, worst err {:.4} bp (30 quotes: {}, {:.4} bp)", sci(e60[59] / e60[0]), w60, sci(row(2.0).1), row(2.0).3);
    assert!(e60[59] / e60[0] > 10.0 * row(2.0).1 && w60 < row(2.0).3);
    // --- 1-D: the cubic kernel |r|^3 + linear tail is the natural cubic spline ---
    let tq = [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 30.0]; let zq: Vec<f64> = tq.iter().map(|&t| z(t)).collect(); let m = tq.len();
    let mut cm: Mat = tq.iter().map(|&a| { let mut r: Vec<f64> = tq.iter().map(|&b| cube(a - b)).collect(); r.extend([1.0, a]); r }).collect();
    let mut r1 = vec![1.0; m]; r1.extend([0.0, 0.0]); let mut r2 = tq.to_vec(); r2.extend([0.0, 0.0]); cm.push(r1); cm.push(r2); let mut rz = zq.clone(); rz.extend([0.0, 0.0]);
    let cc = gauss(&cm, &rz);
    let r15 = cc[m] + cc[m + 1] * 15.0 + add(cc.iter().zip(&tq).map(|(cj, &t)| cj * cube(15.0 - t)));
    let h: Vec<f64> = (0..m - 1).map(|i| tq[i + 1] - tq[i]).collect(); // natural spline: moments M, with M = 0 at both ends
    let tm: Mat = (0..m - 2).map(|i| (0..m - 2).map(|k| if k == i { 2.0 * (h[i] + h[i + 1]) } else if i.abs_diff(k) == 1 { h[i.max(k)] } else { 0.0 }).collect()).collect();
    let mut mm = vec![0.0]; mm.extend(gauss(&tm, &(0..m - 2).map(|i| 6.0 * ((zq[i + 2] - zq[i + 1]) / h[i + 1] - (zq[i + 1] - zq[i]) / h[i])).collect::<Vec<_>>())); mm.push(0.0);
    let (a5, b5) = (tq[6] - 15.0, 15.0 - tq[5]);
    let sp = (mm[5] * cube(a5) + mm[6] * cube(b5)) / (6.0 * h[5]) + (zq[5] / h[5] - mm[5] * h[5] / 6.0) * a5 + (zq[6] / h[5] - mm[6] * h[5] / 6.0) * b5;
    println!("1-D yield curve, 15y: cubic kernel {:.6}%, natural spline {:.6}%, true {:.6}%", r15, sp, z(15.0));
    assert!((r15 - sp).abs() < 1e-9 && (sp - 4.211993).abs() < 1e-6);
    println!("cost, n = 30: Cholesky about n^3/3 = {} flops; thin-plate system n + 3 = 33, about 2(33)^3/3 = {} flops", n * n * n / 3, 2 * 33 * 33 * 33 / 3);
    println!("chart, eps: {}", join(&tab.iter().map(|t| t.0).collect::<Vec<_>>(), 1));
    println!("chart, log10 kappa: {}", join(&tab.iter().map(|t| t.1.log10()).collect::<Vec<_>>(), 2));
    println!("chart, log10 worst err bp: {}", join(&tab.iter().map(|t| t.3.log10()).collect::<Vec<_>>(), 2));
    println!("ALL CHECKS PASS");
}
