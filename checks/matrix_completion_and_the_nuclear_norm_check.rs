// Matrix completion by the nuclear norm -- the check behind the card; std only.
// Part 1 fills the gaps of [[1, 2, ?], [2, 4, 6], [?, 6, 9]] with the table of least nuclear norm (sum of
// singular values) by ratios, grid search, a dual certificate and singular value thresholding (SVT).
// Part 2 hides 60% of a 50 by 40 rank-2 table and recovers it by SVT.  A table is a list of its columns.
type Mat = Vec<Vec<f64>>;
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // SplitMix64: a draw in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 * 2f64.powi(-53)
    }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine half only
        let u = self.uniform();
        (-2.0 * u.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.uniform()).cos()
    }
}
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut s = 0.0; for (a, b) in u.iter().zip(v) { s += a * b; } s }
fn cl(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }
fn eye(n: usize) -> Mat { (0..n).map(|j| (0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn svd(cols: &Mat, v0: Option<&Mat>) -> (Vec<f64>, Mat, Mat) { // one-sided Jacobi
    let n = cols.len();
    let mut v = match v0 { Some(w) => w.clone(), None => eye(n) };
    let mut g: Mat = Vec::new();
    for vk in &v {
        let mut gk = vec![0.0; cols[0].len()];
        for (w, c) in vk.iter().zip(cols) {
            if *w != 0.0 { gk = gk.iter().zip(c).map(|(a, b)| a + w * b).collect(); }
        }
        g.push(gk);
    }
    for _ in 0..60 {
        let mut turns = 0;
        for i in 0..n - 1 {
            for j in i + 1..n {
                let (a, b, gg) = (dot(&g[i], &g[i]), dot(&g[j], &g[j]), dot(&g[i], &g[j]));
                if gg.abs() <= 1e-15 * (a * b).sqrt() { continue; }
                turns += 1; let z = (b - a) / (2.0 * gg);
                let t = 1f64.copysign(z) / (z.abs() + (1.0 + z * z).sqrt());
                let c = 1.0 / (1.0 + t * t).sqrt(); let s = c * t;
                for p in [&mut g, &mut v] {
                    let ni: Vec<f64> = p[i].iter().zip(&p[j]).map(|(x, y)| c * x - s * y).collect();
                    let nj: Vec<f64> = p[i].iter().zip(&p[j]).map(|(x, y)| s * x + c * y).collect();
                    p[i] = ni; p[j] = nj;
                }
            }
        }
        if turns == 0 { break; }
    }
    (g.iter().map(|x| dot(x, x).sqrt()).collect(), g, v)
}
fn desc(mut x: Vec<f64>) -> Vec<f64> { x.sort_by(|a, b| b.partial_cmp(a).unwrap()); x }
fn sv(a: &Mat) -> Vec<f64> { desc(svd(a, None).0) }
fn nuc(a: &Mat) -> f64 { let mut s = 0.0; for x in sv(a) { s += x; } s }
fn eig(a: &Mat) -> Vec<f64> { let (_, g, v) = svd(a, None); desc(g.iter().zip(&v).map(|(x, y)| dot(x, y)).collect()) }
fn f6(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.6}", cl(*x))).collect::<Vec<_>>().join(" ") }
fn hidden_err(x: &Mat, t: &Mat, mask: &Vec<Vec<u8>>) -> f64 {
    let (mut num, mut den) = (0.0, 0.0);
    for j in 0..t.len() { for i in 0..t[0].len() { if mask[j][i] == 0 { let d = x[j][i] - t[j][i]; num += d * d; } } }
    for j in 0..t.len() { for i in 0..t[0].len() { if mask[j][i] == 0 { den += t[j][i] * t[j][i]; } } }
    (num / den).sqrt()
}
fn svt(mm: &Mat, mask: &Vec<Vec<u8>>, tau: f64, delta: f64, kmax: usize, tol: f64, truth: Option<&Mat>, every: usize)
    -> (Mat, usize, usize, f64, Vec<(usize, f64, f64, usize)>) {
    let (n, m) = (mm.len(), mm[0].len());
    let (mut y, mut v, mut hist): (Mat, Option<Mat>, Vec<(usize, f64, f64, usize)>) = (vec![vec![0.0; m]; n], None, vec![]);
    let mut obs = 0.0; for j in 0..n { for i in 0..m { if mask[j][i] == 1 { obs += mm[j][i] * mm[j][i]; } } }
    let obs = f64::sqrt(obs);
    let (mut x, mut rank, mut res, mut kk) = (vec![vec![0.0; m]; n], 0, 0.0, 0);
    for k in 1..=kmax {
        kk = k; let (sig, g, vn) = svd(&y, v.as_ref());
        x = vec![vec![0.0; m]; n]; rank = 0;
        for ((s, gk), vk) in sig.iter().zip(&g).zip(&vn) {
            if *s > tau {
                rank += 1; let f = 1.0 - tau / s;
                for j in 0..n { x[j] = x[j].iter().zip(gk).map(|(a, b)| a + f * vk[j] * b).collect(); }
            }
        }
        v = Some(vn); res = 0.0;
        for j in 0..n { for i in 0..m { if mask[j][i] == 1 { let d = mm[j][i] - x[j][i]; y[j][i] += delta * d; res += d * d; } } }
        res = res.sqrt() / obs;
        if every > 0 && (k % every == 0 || res < tol) { hist.push((k, res, hidden_err(&x, truth.unwrap(), mask), rank)); }
        if res < tol { break; }
    }
    (x, kk, rank, res, hist)
}
fn table(x: f64, y: f64) -> Mat { vec![vec![1.0, 2.0, y], vec![2.0, 4.0, 6.0], vec![x, 6.0, 9.0]] }
fn main() {
    let mut rng = Rng(2026);
    let gap: Vec<Vec<u8>> = vec![vec![1, 1, 0], vec![1, 1, 1], vec![0, 1, 1]];
    let x = 2.0 * 6.0 / 4.0; // road 1: rank 1 makes row 1 half of row 2
    println!("table [[1, 2, ?], [2, 4, 6], [?, 6, 9]]; rank-1 fill by ratios: both gaps {:.6}", x);
    let (r1, s1) = (table(x, x), sv(&table(x, x)));
    println!("u = (1, 2, 3): u u^T has trace 1 + 4 + 9 = {:.6}; singular values {}; nuclear norm {:.6}", 1.0 + 4.0 + 9.0, f6(&s1), nuc(&r1));
    let mut best = (f64::INFINITY, 0.0, 0.0);
    for i in 0..121 { for j in 0..121 {
        let c = (nuc(&table(i as f64 / 20.0, j as f64 / 20.0)), i as f64 / 20.0, j as f64 / 20.0);
        if c.partial_cmp(&best) == Some(std::cmp::Ordering::Less) { best = c; }
    } }
    println!("grid search, both gaps 0 to 6 in steps of 0.05: best ({:.2}, {:.2}), nuclear norm {:.6}", best.1, best.2, best.0);
    let line: Vec<f64> = (0..13).map(|t| nuc(&table(t as f64 / 2.0, t as f64 / 2.0))).collect();
    println!("chart, gap t   {}", (0..13).map(|t| format!("{:5.1}", t as f64 / 2.0)).collect::<Vec<_>>().join(" "));
    println!("chart, norm    {}", line.iter().map(|v| format!("{:5.2}", v)).collect::<Vec<_>>().join(" "));
    let z0 = table(0.0, 0.0);
    println!("zero fill: singular values {}, nuclear norm {:.6}, rank {}", f6(&sv(&z0)), nuc(&z0), sv(&z0).iter().filter(|s| **s > 1e-9).count());
    let w: Mat = [[4.0, 5.0, 0.0], [5.0, 7.0, 3.0], [0.0, 3.0, 12.0]].iter().map(|c| c.iter().map(|e| e / 14.0).collect()).collect();
    let (sw, mut fl) = (sv(&w), 0.0);
    for j in 0..3 { for i in 0..3 { if gap[j][i] == 1 { fl += w[j][i] * r1[j][i]; } } }
    let floor = fl / sw[0];
    println!("certificate W = [[4, 5, 0], [5, 7, 3], [0, 3, 12]] / 14: zero on both gaps; singular values {}", f6(&sw));
    println!("floor <W, seen entries> / largest singular value of W = {:.6}; rank-1 fill minus floor {:.6}", floor, cl(nuc(&r1) - floor));
    let bcol: Mat = (0..3).map(|j| [r1[j].clone(), r1[j].clone()].concat()).collect();
    let b: Mat = [bcol.clone(), bcol].concat(); // [[P, X], [X^T, Q]] with P = Q = X = u u^T
    let d: Mat = (0..6).map(|j| (0..6).map(|i| (if i == j { 1.0 } else { 0.0 }) - (if (i < 3) != (j < 3) { w[j % 3][i % 3] } else { 0.0 })).collect()).collect();
    println!("SDP primal: eigenvalues of [[P, X], [X^T, Q]] {}; (tr P + tr Q) / 2 = {:.6}", f6(&eig(&b)), (14.0 + 14.0) / 2.0);
    println!("SDP dual:   eigenvalues of [[I, -W], [-W, I]] {}", f6(&eig(&d)));
    let tau = 2.0; // road 3: D_tau is the prox of tau |.|_*
    let phi = |xm: &Mat| { let mut s = 0.0; for (c, dd) in xm.iter().zip(&z0) { for (a, bb) in c.iter().zip(dd) { s += (a - bb) * (a - bb); } } tau * nuc(xm) + 0.5 * s };
    let (sig, g, v) = svd(&z0, None);
    let p: Mat = (0..3).map(|j| (0..3).map(|i| { let mut s = 0.0; for k in 0..3 { s += f64::max(sig[k] - tau, 0.0) / sig[k] * g[k][i] * v[k][j]; } s }).collect()).collect();
    let mut excess = f64::INFINITY; for _ in 0..300 {
        let q: Mat = p.iter().map(|c| c.iter().map(|a| a + 0.1 * rng.normal()).collect()).collect();
        excess = excess.min(phi(&q) - phi(&p));
    }
    println!("prox check, tau 2 on the zero fill: D_tau beats 300 random nearby tables; smallest excess {:.6}", excess);
    println!("threshold needed for the exact fill: 42 / (sqrt 65 - 3) = {:.6}", 42.0 / (65f64.sqrt() - 3.0));
    let mut runs = std::collections::HashMap::new();
    for (key, tau) in [(10, 1.0), (50, 5.0), (80, 8.0), (84, 8.4), (200, 20.0)] {
        let (xx, k, rank, res, _) = svt(&r1, &gap, tau, 1.0, 5000, 1e-10, None, 0);
        runs.insert(key, (xx[2][0], xx[0][2]));
        println!("SVT tau {:4.1}, step 1: gaps {:.6} {:.6}, rank {}, iteration {}, seen-entry miss {:.1e}", tau, xx[2][0], xx[0][2], rank, k, res);
    }
    println!("incoherence mu of u: 3 x max(u_i^2) / |u|^2 = {:.6} (range 1 to 3)", 3.0 * 9.0 / 14.0);
    let col_gap: Vec<Vec<u8>> = vec![vec![1, 1, 1], vec![1, 1, 1], vec![0, 0, 0]];
    let xc = svt(&r1, &col_gap, 20.0, 1.0, 5000, 1e-10, None, 0).0;
    println!("mistake, whole third column hidden: SVT fills {}; truth 3 6 9", f6(&xc[2]));
    let spike: Mat = vec![vec![5.0, 0.0, 0.0], vec![4.0, 0.0, 0.0], vec![3.0, 0.0, 0.0]]; // only viewer 1 rates (5, 4, 3); mu = 3
    let xs = svt(&spike, &vec![vec![1, 1, 1], vec![1, 1, 1], vec![0, 1, 1]], 20.0, 1.0, 5000, 1e-10, None, 0).0;
    println!("mistake, coherent table, viewer 1 alone rates (5, 4, 3), the 3 hidden: SVT fills {:.6}", cl(xs[2][0]));
    let (sig, g, v) = svd(&z0, None); let mut k1 = 0; for k in 1..3 { if sig[k] > sig[k1] { k1 = k; } } // the largest singular value
    println!("mistake, one SVD of the zero fill, keep rank 1: gaps {:.6} {:.6}, seen (1,1) {:.6}", g[k1][0] * v[k1][2], g[k1][2] * v[k1][0], g[k1][0] * v[k1][0]);
    let (mut rng, m, n, r) = (Rng(4), 50usize, 40usize, 2usize); // part 2, seed 4: 50 viewers, 40 films, two tastes
    let lf: Mat = (0..m).map(|_| (0..r).map(|_| rng.normal()).collect()).collect();
    let rf: Mat = (0..n).map(|_| (0..r).map(|_| rng.normal()).collect()).collect();
    let t: Mat = (0..n).map(|j| (0..m).map(|i| dot(&lf[i], &rf[j])).collect()).collect();
    let mut order: Vec<usize> = (0..m * n).collect(); for i in (1..m * n).rev() { let j = ((rng.uniform() * (i + 1) as f64) as usize) % (i + 1); order.swap(i, j); }
    let mut mask = vec![vec![0u8; m]; n]; for &c in &order[..800] { mask[c / m][c % m] = 1; }
    let (st, gt, _) = svd(&t, None); let mut top: Vec<usize> = (0..n).collect(); top.sort_by(|a, b| (-st[*a]).partial_cmp(&-st[*b]).unwrap());
    let mut mu = f64::NEG_INFINITY; for i in 0..m { let mut s = 0.0; for &k in &top[..r] { let e = gt[k][i] / st[k]; s += e * e; } mu = mu.max(s); }
    let mu_u = m as f64 / r as f64 * mu;
    println!("50 x 40 rank-2 table: 800 of 2000 seen (40%), degrees of freedom r(m + n - r) = {}, n r log n = {:.1}", r * (m + n - r), (m * r) as f64 * (m as f64).ln());
    println!("truth: singular values {}, viewer-side incoherence mu {:.3} (range 1 to 25)", f6(&sv(&t)[..3]), mu_u);
    let (x2, _k, rank, _res, hist) = svt(&t, &mask, 6.0 * m as f64, 1.2 / 0.4, 1000, 1e-4, Some(&t), 25);
    println!("SVT tau 6 x 50 = {:.0}, step 1.2 / 0.4 = {:.1}; stop when the seen-entry miss < 1e-4", 6.0 * m as f64, 1.2 / 0.4);
    println!("     k   seen-entry miss   hidden error   rank");
    for (kk, rr, hh, rk) in &hist { println!("{:6} {:17.6} {:14.6} {:6}", kk, rr, hh, rk); }
    println!("recovered: singular values {}; nuclear norm {:.3} against the truth's {:.3}", f6(&sv(&x2)[..3]), nuc(&x2), nuc(&t));
    println!("chart, k       {}", hist.iter().map(|h| format!("{:5}", h.0)).collect::<Vec<_>>().join(" "));
    println!("chart, log10   {}", hist.iter().map(|h| format!("{:5.2}", h.2.log10())).collect::<Vec<_>>().join(" "));
    assert!((best.0 - floor).abs() < 1e-9 && (best.1, best.2) == (x, x)); // grid search meets the dual floor
    assert!((sw[0] - 1.0).abs() < 1e-12); // W is a valid certificate
    assert!(eig(&d).iter().cloned().fold(f64::INFINITY, f64::min) > -1e-12 && eig(&b).iter().cloned().fold(f64::INFINITY, f64::min) > -1e-12); // PSD
    assert!(excess > 0.0); // D_tau minimises the prox target
    assert!((runs[&200].0 - 3.0).abs() < 1e-6 && (runs[&84].1 - 3.0).abs() < 1e-6); // threshold above tau0: exact
    assert!((runs[&80].0 - 3.0).abs() > 0.05 && (runs[&10].0 - 3.0).abs() > 2.0); // threshold below tau0: not exact
    assert!(xc[2].iter().all(|e| e.abs() < 1e-9) && xs[2][0].abs() < 1e-9); // the two broken hypotheses
    assert!(hist.last().unwrap().2 < 1e-3 && rank == 2); // the 50 x 40 table is recovered
    println!("ALL CHECKS PASS");
}
