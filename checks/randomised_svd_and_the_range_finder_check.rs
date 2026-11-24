// Randomised SVD and the range finder -- the same check as the Python, in Rust.  No crates.
// A dense 2,000 by 500 matrix, singular values 0.8^(j-1).  Roads: the dense run (error by
// identity and by every residual entry), the same sketch in the singular axes, and 200 trials.
use std::f64::consts::PI;
type M = Vec<Vec<f64>>;

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {                      // SplitMix64, seed 2026
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) * 2f64.powi(-53) }
    fn gauss(&mut self) -> f64 { let a = self.unif(); let b = self.unif(); (-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos() }
    fn vec(&mut self, n: usize) -> Vec<f64> { (0..n).map(|_| self.gauss()).collect() }
}
fn tsum<I: Iterator<Item = f64>>(xs: I) -> f64 { let mut s = 0.0; for x in xs { s += x; } s }
fn dot(x: &[f64], y: &[f64]) -> f64 { let mut s = 0.0; for (a, b) in x.iter().zip(y) { s += a * b; } s }
fn axpy(w: &[f64], c: f64, q: &[f64]) -> Vec<f64> { w.iter().zip(q).map(|(a, b)| a - c * b).collect() }
fn mirror(x: &[f64], v: &[f64], vv: f64) -> Vec<f64> { let c = 2.0 * dot(x, v) / vv; axpy(x, c, v) }
fn orth(y: &M) -> M {                                // modified Gram-Schmidt, run twice per column
    let mut q: M = Vec::new();
    for col in y {
        let mut w = col.clone();
        for _ in 0..2 { for qq in &q { let c = dot(qq, &w); w = axpy(&w, c, qq); } }
        let r = dot(&w, &w).sqrt(); q.push(w.iter().map(|a| a / r).collect());
    }
    q
}
fn jeig(g0: &M) -> (Vec<f64>, M) {                  // Jacobi eigenvalues and vectors of a small symmetric G
    let n = g0.len(); let mut g = g0.clone();
    let mut w: M = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..30 {
        let off = tsum((0..n).flat_map(|i| (0..n).map(move |j| (i, j))).filter(|&(i, j)| i != j).map(|(i, j)| g[i][j] * g[i][j]));
        if off < 1e-32 { break; }
        for p in 0..n - 1 {
            for q in p + 1..n {
                if g[p][q].abs() < 1e-300 { continue; }
                let th = (g[q][q] - g[p][p]) / (2.0 * g[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (1.0 + th * th).sqrt()); let c = 1.0 / (1.0 + t * t).sqrt(); let s = c * t;
                for mm in [&mut g, &mut w] {
                    for r in mm.iter_mut() { let (a, b) = (r[p], r[q]); r[p] = c * a - s * b; r[q] = s * a + c * b; }
                }
                let (gp, gq) = (g[p].clone(), g[q].clone());
                g[p] = gp.iter().zip(&gq).map(|(a, b)| c * a - s * b).collect();
                g[q] = gp.iter().zip(&gq).map(|(a, b)| s * a + c * b).collect();
            }
        }
    }
    let mut o: Vec<usize> = (0..n).collect();
    o.sort_by(|&i, &j| g[j][j].partial_cmp(&g[i][i]).unwrap());
    (o.iter().map(|&i| g[i][i]).collect(), o.iter().map(|&i| (0..n).map(|r| w[r][i]).collect()).collect())
}
fn rsvd(mul: &dyn Fn(&M) -> M, mult: &dyn Fn(&M) -> M, om: &M, q: usize) -> (M, M, Vec<f64>, M) {
    let mut qm = orth(&mul(om));                     // range finder, q power steps, then the small SVD
    for _ in 0..q { qm = orth(&mul(&orth(&mult(&qm)))); }
    let b = mult(&qm);                               // rows of B = Q^T A, each n long
    let (ev, w) = jeig(&b.iter().map(|x| b.iter().map(|y| dot(x, y)).collect()).collect());
    (qm, b, ev, w)
}
fn tail(tot: f64, e: &[f64]) -> f64 { (tot - tsum(e.iter().cloned())).max(0.0).sqrt() }

fn main() {
    let mut rng = Rng(2026);
    let (m, n, k, p) = (2000usize, 500usize, 10usize, 5usize); let l = k + p;
    let sig: Vec<f64> = (0..n).map(|j| 0.8f64.powf(j as f64)).collect();
    let tot = tsum(sig.iter().map(|s| s * s)); let best = tsum(sig[k..].iter().map(|s| s * s)).sqrt();
    let vu: M = (0..2).map(|_| rng.vec(m)).collect(); let vv: M = (0..2).map(|_| rng.vec(n)).collect();
    let vt = |x: &[f64]| -> Vec<f64> { let mut x = x.to_vec(); for v in &vv { x = mirror(&x, v, dot(v, v)); } x };
    let mut cols: M = Vec::new();
    for j in 0..n {                                  // column j of A = U [Sigma; 0] V^T, U = G1 G2 in R^2000
        let e: Vec<f64> = (0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect();
        let mut c: Vec<f64> = sig.iter().zip(vt(&e)).map(|(s, x)| s * x).collect(); c.resize(m, 0.0);
        for v in vu.iter().rev() { c = mirror(&c, v, dot(v, v)); }
        cols.push(c);
    }
    let rows: M = (0..m).map(|r| cols.iter().map(|c| c[r]).collect()).collect();
    let fro2 = tsum(rows.iter().map(|r| dot(r, r)));
    println!("A: {} x {}, sigma_j = 0.8^(j-1); ||A||_F^2 from entries {:.10}, from sigmas {:.10}", m, n, fro2, tot);
    println!("best rank-{} error: Frobenius {:.6} = {:.1}% of ||A||_F {:.6}, spectral sigma_11 {:.6}", k, best, 100.0 * best / tot.sqrt(), tot.sqrt(), sig[k]);
    let bf: Vec<String> = [2.0, 5.0, 10.0, 20.0].iter().map(|pp: &f64| format!("{:.4}", (1.0 + k as f64 / (pp - 1.0)).sqrt())).collect();
    println!("bound factor sqrt(1 + k/(p-1)) for p = 2, 5, 10, 20: {}", bf.join(" "));
    let (b1, b2) = ((1.0 + k as f64 / (p - 1) as f64).sqrt(), (2.0 + k as f64 / (p - 1) as f64).sqrt());
    println!("expected-error bounds at p = {}: rank-{} projection {:.6}, rank-{} answer {:.6} (factor {:.4})", p, l, b1 * best, k, b2 * best, b2);
    assert!((fro2 - tot).abs() < 1e-10 * tot);

    let dmul = |x: &M| -> M { x.iter().map(|c| rows.iter().map(|r| dot(r, c)).collect()).collect() };
    let dmult = |x: &M| -> M { x.iter().map(|c| cols.iter().map(|a| dot(a, c)).collect()).collect() };
    let fmul = |x: &M| -> M { x.iter().map(|c| sig.iter().zip(c).map(|(s, a)| s * a).collect()).collect() };
    let om: M = (0..l).map(|_| rng.vec(n)).collect();
    let omf: M = om.iter().map(|w| vt(w)).collect();
    let mut res = Vec::new();
    for q in 0..2usize {
        let (qm, b, ev, w) = rsvd(&dmul, &dmult, &om, q);
        let (proj, trunc) = (tail(tot, &ev), tail(tot, &ev[..k]));
        let (_, _, evf, _) = rsvd(&fmul, &fmul, &omf, q);
        let mnl = m * n * l;
        println!("q = {}: {} products with A or A^T, m n l = {} multiplications each, {} in all", q, 2 + 2 * q, mnl, (2 + 2 * q) * mnl);
        println!("q = {}: error of QQ^T A (rank {}) {:.6}, ratio to best {:.4}; rank-{} error {:.6}, ratio {:.4}, {:.1}% of ||A||_F", q, l, proj, proj / best, k, trunc, trunc / best, 100.0 * trunc / tot.sqrt());
        println!("q = {}: same sketch in the singular axes, rank-{} error {:.6}", q, k, tail(tot, &evf[..k]));
        println!("q = {}: log10 of estimated sigma_1..15: {}", q, ev.iter().map(|e| format!("{:.2}", e.sqrt().log10())).collect::<Vec<_>>().join(" "));
        assert!((tail(tot, &evf[..k]) - trunc).abs() < 1e-10 && trunc >= best * (1.0 - 1e-12));
        res.push((qm, b, w, trunc));
    }
    println!("true log10 sigma_1..15: {}", sig[..l].iter().map(|s| format!("{:.2}", s.log10())).collect::<Vec<_>>().join(" "));
    println!("cost: m n^2 = {}, a dense SVD's leading term; ratio to the q = 0 products {:.1}", m * n * n, (m * n * n) as f64 / (2 * m * n * l) as f64);

    let (qm, b, w, trunc) = &res[0];                 // road one, second half: sum every residual entry
    let uk: M = (0..m).map(|r| { let qr: Vec<f64> = qm.iter().map(|qq| qq[r]).collect(); w[..k].iter().map(|wt| dot(wt, &qr)).collect() }).collect();
    let ck: M = w[..k].iter().map(|wt| (0..n).map(|j| { let bj: Vec<f64> = b.iter().map(|bb| bb[j]).collect(); dot(wt, &bj) }).collect()).collect();
    let mut direct = 0.0;
    for r in 0..m {
        let mut a = rows[r].clone();
        for t in 0..k { a = axpy(&a, uk[r][t], &ck[t]); }
        direct += dot(&a, &a);
    }
    println!("rank-{} error by summing all {} residual entries {:.6}; Pythagoras identity {:.6}", k, m * n, direct.sqrt(), trunc);
    assert!((direct.sqrt() - trunc).abs() < 1e-9);
    let e10 = (tot - tsum(b[..k].iter().map(|bb| dot(bb, bb)))).sqrt();   // keep Q's first k columns, skip the small SVD
    println!("first {} columns of Q, no small SVD: error {:.6}, ratio {:.4}", k, e10, e10 / best);

    let (qf, _, evf, _) = rsvd(&fmul, &fmul, &omf, 0);   // a posteriori estimate, 10 fresh vectors
    let resid = |x: &[f64]| -> Vec<f64> {            // (I - Q Q^T) Sigma x
        let mut y: Vec<f64> = sig.iter().zip(x).map(|(s, a)| s * a).collect();
        for qq in &qf { let c = dot(qq, &y); y = axpy(&y, c, qq); }
        y
    };
    let tests: Vec<f64> = (0..10).map(|_| { let y = resid(&rng.vec(n)); dot(&y, &y).sqrt() }).collect();
    let est_f = (tsum(tests.iter().map(|t| t * t)) / 10.0).sqrt();
    let bound2 = 10.0 * (2.0 / PI).sqrt() * tests.iter().cloned().fold(f64::MIN, f64::max);
    let mut x = vec![1.0; n];
    for _ in 0..300 {                                // true spectral error by power iteration
        let y = resid(&x); let z: Vec<f64> = sig.iter().zip(&y).map(|(s, a)| s * a).collect();
        let nz = dot(&z, &z).sqrt(); x = z.iter().map(|a| a / nz).collect(); }
    let (true2, true_f) = (dot(&resid(&x), &resid(&x)).sqrt(), tail(tot, &evf));
    println!("a posteriori, 10 test vectors: Frobenius estimate {:.6} vs true {:.6}, ratio {:.4}", est_f, true_f, est_f / true_f);
    println!("a posteriori, spectral: bound 10 sqrt(2/pi) max {:.6} vs true {:.6}, ratio {:.2}", bound2, true2, bound2 / true2);
    assert!(0.5 < est_f / true_f && est_f / true_f < 2.0 && bound2 >= true2);

    let t = 200usize;
    for &(ll, q) in &[(l, 0usize), (l, 1), (k, 0)] {
        let rs: Vec<(f64, f64)> = (0..t).map(|_| {     // one fresh sketch, in the singular axes
            let o: M = (0..ll).map(|_| rng.vec(n)).collect();
            let (_, _, e, _) = rsvd(&fmul, &fmul, &o, q);
            (tail(tot, &e) / best, tail(tot, &e[..k]) / best)
        }).collect();
        let names = [format!("rank-{} projection", ll), format!("rank-{} answer", k)];
        for i in (if ll == k { 1 } else { 0 })..2 {
            let v: Vec<f64> = rs.iter().map(|r| if i == 0 { r.0 } else { r.1 }).collect();
            let mu = tsum(v.iter().cloned()) / t as f64;
            let se = (tsum(v.iter().map(|a| (a - mu) * (a - mu))) / (t - 1) as f64 / t as f64).sqrt();
            let worst = v.iter().cloned().fold(f64::MIN, f64::max);
            println!("{} trials, l = {}, q = {}, {}: mean ratio {:.4} (se {:.4}), worst {:.4}", t, ll, q, names[i], mu, se, worst);
            if ll == l && q == 0 { assert!(mu + 3.0 * se <= (1.0 + k as f64 / (p - 1) as f64 + i as f64).sqrt()); }
            if q == 1 && i == 1 { assert!((mu - 1.0).abs() < 0.01); }
        }
        assert!(rs.iter().all(|r| r.1 >= 1.0 - 1e-12));
    }

    let qq = 12.0;                                   // power steps with no orthonormalising in between
    let yb: M = omf.iter().map(|w| sig.iter().zip(w).map(|(s, a)| s.powf(2.0 * qq + 1.0) * a).collect()).collect();
    let qb = orth(&yb); let bb = fmul(&qb);
    let lost = (0..l * l).map(|x| (dot(&qb[x / l], &qb[x % l]) - if x / l == x % l { 1.0 } else { 0.0 }).abs()).fold(0.0, f64::max);
    println!("break, q = {} with no re-orthonormalising: loss of orthogonality {:.4}; ||A||_F^2 - ||B||_F^2 = {:.4}", qq, lost, tot - tsum(bb.iter().map(|b| dot(b, b))));
    assert!(lost > 0.1);
    println!("ALL CHECKS PASS");
}
