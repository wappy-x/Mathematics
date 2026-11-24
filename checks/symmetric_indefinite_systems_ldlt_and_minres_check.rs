// Saddle-point systems -- the check behind the card.  std only; nothing used holds an answer.  Water flows q (L/s)
// and heads h (m) solve [[R, E^T], [E, 0]] (q, h) = (g, d): symmetric, indefinite.  Several roads, compared.
type M = Vec<Vec<f64>>; const H: f64 = 60.0;
fn alpha() -> f64 { (1.0 + 17f64.sqrt()) / 8.0 }
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).fold(0.0, |s, (a, b)| s + a * b) } // left to right
struct Bk { perm: Vec<usize>, l: M, blocks: Vec<Vec<f64>>, growth: f64 }
fn bk(a0: &M, plain: bool) -> Bk { // Bunch-Kaufman: P A P^T = L D L^T, D made of 1x1 and 2x2 blocks
    let (n, mut a, mut k, al, big0) = (a0.len(), a0.clone(), 0usize, alpha(), a0.iter().flatten().fold(0.0f64, |m, v| m.max(v.abs())));
    let (mut big, mut l): (f64, M) = (big0, (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect());
    let (mut perm, mut blocks): (Vec<usize>, Vec<Vec<f64>>) = ((0..n).collect(), vec![]);
    let swap = |a: &mut M, l: &mut M, perm: &mut Vec<usize>, k: usize, i: usize, j: usize| { // rows AND columns, so A stays symmetric
        a.swap(i, j); perm.swap(i, j); for r in a.iter_mut() { r.swap(i, j); }
        for c in 0..k { let t = l[i][c]; l[i][c] = l[j][c]; l[j][c] = t; }
    };
    while k < n {
        let (mut lam, mut r, mut s) = (0.0f64, k, 1usize);
        for i in k + 1..n { if a[i][k].abs() > lam { lam = a[i][k].abs(); r = i; } }
        if !plain && a[k][k].abs() < al * lam {
            let sig = (k..n).filter(|&i| i != r).fold(f64::MIN, |m, i| m.max(a[i][r].abs()));
            if a[k][k].abs() * sig >= al * lam * lam {} // keep the 1x1 pivot
            else if a[r][r].abs() >= al * sig { swap(&mut a, &mut l, &mut perm, k, k, r); } // 1x1 pivot from row r
            else { s = 2; swap(&mut a, &mut l, &mut perm, k, k + 1, r); } // 2x2 pivot on rows k, r
        }
        if s == 1 { for i in k + 1..n { l[i][k] = a[i][k] / a[k][k]; } blocks.push(vec![a[k][k]]); } else {
            let (p, q, t) = (a[k][k], a[k + 1][k], a[k + 1][k + 1]); let det = p * t - q * q;
            for i in k + 2..n { l[i][k] = (a[i][k] * t - a[i][k + 1] * q) / det; l[i][k + 1] = (a[i][k + 1] * p - a[i][k] * q) / det; }
            blocks.push(vec![p, q, t]);
        }
        for i in k + s..n { for j in k + s..n { for c in k..k + s { a[i][j] -= l[i][c] * a[c][j]; } big = big.max(a[i][j].abs()); } }
        k += s;
    }
    Bk { perm, l, blocks, growth: big / big0 }
}
fn bk_solve(f: &Bk, b: &[f64]) -> Vec<f64> { // forward with L, then the blocks of D, back with L^T, undo P
    let n = b.len(); let mut y: Vec<f64> = f.perm.iter().map(|&p| b[p]).collect(); let mut k = 0;
    for i in 0..n { let s = dot(&f.l[i][..i], &y[..i]); y[i] -= s; }
    for d in &f.blocks {
        if d.len() == 1 { y[k] /= d[0]; k += 1; } else {
            let (det, y0, y1) = (d[0] * d[2] - d[1] * d[1], y[k], y[k + 1]); y[k] = (d[2] * y0 - d[1] * y1) / det; y[k + 1] = (d[0] * y1 - d[1] * y0) / det; k += 2;
        }
    }
    for i in (0..n).rev() { let col: Vec<f64> = (i + 1..n).map(|j| f.l[j][i]).collect(); let s = dot(&col, &y[i + 1..]); y[i] -= s; }
    (0..n).map(|i| y[f.perm.iter().position(|&p| p == i).unwrap()]).collect()
}
fn inertia(d: &[Vec<f64>]) -> Vec<usize> { // a 2x2 block: one of each
    [1.0, -1.0].iter().map(|sg| d.iter().filter(|b| b.len() == 3 || b[0] * sg > 0.0).count()).collect()
}
fn minres(mv: &dyn Fn(&[f64]) -> Vec<f64>, b: &[f64], tol: f64, kmax: usize, full: bool) -> (Vec<f64>, Vec<f64>, Vec<f64>) { // Lanczos + one rotation a step
    let (n, b1) = (b.len(), dot(b, b).sqrt()); let (mut vs, mut tr): (Vec<Vec<f64>>, Vec<f64>) = (vec![], vec![1.0]); // all vectors, if full
    let (mut bet, mut cs, mut sn, mut dbar, mut eps, mut phib) = (0.0, -1.0, 0.0, 0.0, 0.0, b1);
    let (mut v, mut vp, mut w, mut w2, mut x, mut hist): (Vec<f64>, _, _, _, _, _) = (b.iter().map(|t| t / b1).collect(), vec![0.0; n], vec![0.0; n], vec![0.0; n], vec![0.0; n], vec![1.0]);
    for _ in 0..kmax {
        let mut p = mv(&v); let al = dot(&v, &p);
        for i in 0..n { p[i] = p[i] - al * v[i] - bet * vp[i]; } if full { vs.push(v.clone()); }
        for u in vs.iter().chain(vs.iter()) { let c = dot(u, &p); for i in 0..n { p[i] = p[i] - c * u[i]; } } // full: orthogonal to all, as in exact arithmetic
        let bn = dot(&p, &p).sqrt(); let (oeps, delta, gbar) = (eps, cs * dbar + sn * al, sn * dbar - cs * al);
        eps = sn * bn; dbar = -cs * bn; let gam = (gbar * gbar + bn * bn).sqrt();
        cs = gbar / gam; sn = bn / gam; let phi = cs * phib; phib = sn * phib;
        let w1 = std::mem::replace(&mut w2, w.clone());
        w = (0..n).map(|i| (v[i] - oeps * w1[i] - delta * w2[i]) / gam).collect();
        for i in 0..n { x[i] = x[i] + phi * w[i]; } hist.push(phib.abs() / b1);
        let r: Vec<f64> = mv(&x).iter().zip(b).map(|(s, t)| s - t).collect(); tr.push(dot(&r, &r).sqrt() / b1); // b - A x recomputed
        if *hist.last().unwrap() < tol || bn == 0.0 { return (x, hist, tr); }
        vp = v; v = p.iter().map(|t| t / bn).collect(); bet = bn;
    }
    (x, hist, tr)
}
fn cg(mv: &dyn Fn(&[f64]) -> Vec<f64>, b: &[f64], tol: f64, kmax: usize) -> (Vec<f64>, Vec<f64>, usize, usize) { // no guarantee here
    let n = b.len(); let (mut x, mut r, mut p, mut neg, mut hist, mut rr) = (vec![0.0; n], b.to_vec(), b.to_vec(), 0, vec![1.0], dot(b, b));
    for k in 0..kmax {
        let ap = mv(&p); let pap = dot(&p, &ap);
        if pap == 0.0 { return (x, hist, neg, k + 1); } // breakdown: the step length divides by zero
        neg += (pap < 0.0) as usize; let al = rr / pap;
        for i in 0..n { x[i] = x[i] + al * p[i]; r[i] = r[i] - al * ap[i]; }
        let rn = dot(&r, &r); hist.push((rn / dot(b, b)).sqrt());
        if *hist.last().unwrap() < tol { break; }
        for i in 0..n { p[i] = r[i] + rn / rr * p[i]; } rr = rn;
    }
    (x, hist, neg, 0)
}
fn chol_solve(a: &M, b: &[f64]) -> (Option<Vec<f64>>, Vec<f64>) { // Cholesky, as on the Cholesky card
    let n = a.len(); let (mut l, mut piv, mut y) = (vec![vec![0.0; n]; n], vec![], b.to_vec());
    for j in 0..n {
        piv.push(a[j][j] - dot(&l[j][..j], &l[j][..j]));
        if piv[j] <= 0.0 { return (None, piv); }
        l[j][j] = piv[j].sqrt(); for i in j + 1..n { l[i][j] = (a[i][j] - dot(&l[i][..j], &l[j][..j])) / l[j][j]; }
    }
    for i in 0..n { y[i] = (y[i] - dot(&l[i][..i], &y[..i])) / l[i][i]; }
    for i in (0..n).rev() { let col: Vec<f64> = (i + 1..n).map(|j| l[j][i]).collect(); y[i] = (y[i] - dot(&col, &y[i + 1..])) / l[i][i]; }
    (Some(y), piv)
}
struct Net { pp: Vec<(i64, usize, f64)>, d: Vec<f64>, m: usize, n: usize, rhs: Vec<f64> } // pipe (a, b, r); a = -1: reservoir at H
impl Net {
    fn new(pp: Vec<(i64, usize, f64)>, d: Vec<f64>) -> Net {
        Net { m: pp.len(), n: pp.len() + d.len(), rhs: pp.iter().map(|&(a, _, _)| if a < 0 { H } else { 0.0 }).chain(d.iter().cloned()).collect(), pp, d }
    }
    fn mv(&self, v: &[f64]) -> Vec<f64> { // (R q + E^T h, E q), one pass over the pipes
        let (mut y, m) = (vec![0.0; self.n], self.m);
        for (p, &(a, b, r)) in self.pp.iter().enumerate() {
            y[p] += r * v[p] + v[m + b]; y[m + b] += v[p];
            if a >= 0 { let a = a as usize; y[p] -= v[m + a]; y[m + a] -= v[p]; }
        }
        y
    }
    fn dense(&self) -> M { (0..self.n).map(|j| self.mv(&(0..self.n).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<_>>())).collect() }
    fn nodal(&self) -> (Vec<f64>, Vec<f64>) { // S h = E R^-1 g - d, S = E R^-1 E^T; then q = R^-1 (g - E^T h)
        let nj = self.d.len(); let (mut s, mut t) = (vec![vec![0.0; nj]; nj], self.d.iter().map(|v| -v).collect::<Vec<f64>>());
        for &(a, b, r) in &self.pp {
            s[b][b] += 1.0 / r; t[b] += if a < 0 { H / r } else { 0.0 };
            if a >= 0 { let a = a as usize; s[a][a] += 1.0 / r; s[a][b] -= 1.0 / r; s[b][a] -= 1.0 / r; }
        }
        let (h, piv) = chol_solve(&s, &t); let h = h.unwrap();
        (self.pp.iter().map(|&(a, b, r)| ((if a < 0 { H } else { h[a as usize] }) - h[b]) / r).chain(h.iter().cloned()).collect(), piv)
    }
}
fn grid(rows: usize, cols: usize) -> Net { // feeders into column 0, pipes along each row, then down each column
    let mut ends: Vec<(i64, usize)> = (0..rows).map(|i| (-1, i * cols)).collect();
    for i in 0..rows { for j in 0..cols - 1 { ends.push(((i * cols + j) as i64, i * cols + j + 1)); } }
    for i in 0..rows - 1 { for j in 0..cols { ends.push(((i * cols + j) as i64, i * cols + cols + j)); } }
    let u: Vec<f64> = (1..=ends.len() + rows * cols).map(|k| (k as f64 * 0.6180339887498949) % 1.0).collect(); // golden-ratio spread
    let pipes = ends.iter().enumerate().map(|(p, &(a, b))| (a, b, if a < 0 { 0.01 + 0.01 * u[p] } else { 0.02 + 0.06 * u[p] })).collect();
    Net::new(pipes, u[ends.len()..].iter().map(|v| 0.5 + v).collect())
}
fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn gap(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).fold(f64::MIN, |m, (a, b)| m.max((a - b).abs())) }
fn row(label: &str, vals: &[f64]) { println!("{:<38}{}", label, vals.iter().map(|v| format!("{:>11.6}", v)).collect::<String>()); }
fn comma(k: u64) -> String { let s = k.to_string(); s.chars().enumerate().map(|(i, ch)| if i > 0 && (s.len() - i) % 3 == 0 { format!(",{}", ch) } else { ch.to_string() }).collect() }
fn main() {
    let al = alpha(); let (g1, g2) = (1.0 + 1.0 / al, 1.0 + 2.0 / (1.0 - al)); row("alpha; growth: 1x1 step, 2x2 step, g1^2", &[al, g1, g2, g1 * g1]);
    let one = Net::new(vec![(-1, 0, 0.0)], vec![20.0]); let s2 = one.dense(); let b1 = bk(&s2, false); // [[0, 1], [1, 0]]
    let c1 = chol_solve(&s2, &one.rhs); let x1 = bk_solve(&b1, &one.rhs); let d0 = &b1.blocks[0];
    println!("one pipe: Cholesky pivot 1 = {:.6}; BK 2x2 det {:.6}, inertia {:?}, q, h = {:.6}, {:.6}", c1.1[0], d0[0] * d0[2] - d0[1] * d0[1], inertia(&b1.blocks), x1[0], x1[1]);
    let brk = cg(&|v| one.mv(v), &[H, 0.0], 1e-12, 5).3; let (xm1, hm1, _) = minres(&|v| one.mv(v), &[H, 0.0], 1e-12, 5, false);
    println!("one pipe, demand 0: CG stops at step {}, p^T A p = 0; MINRES {} steps to q, h = {:.6}, {:.6}", brk, hm1.len() - 1, xm1[0], xm1[1]);
    let lp = Net::new(vec![(-1, 0, 0.1), (0, 1, 0.3), (-1, 1, 0.4)], vec![20.0, 30.0]); // the LU card's loop, morning demand
    let a5 = lp.dense(); let f5 = bk(&a5, false); let x5 = bk_solve(&f5, &lp.rhs); let c5 = chol_solve(&a5, &lp.rhs);
    row("loop: Cholesky pivots, then it stops", &c5.1); let names = ["q1", "q2", "q3", "h1", "h2"];
    let blk: Vec<String> = f5.blocks.iter().map(|d| format!("[{}]", d.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(" "))).collect();
    println!("loop: order {} | D blocks {}", f5.perm.iter().map(|&p| names[p]).collect::<Vec<_>>().join(" "), blk.join(" "));
    let mut lrow = f5.l[4].clone(); lrow.push(f5.growth); row("loop: last row of L; growth", &lrow); row("loop: Bunch-Kaufman q1 q2 q3 h1 h2", &x5);
    let q2 = (30.0 * 0.4 - 20.0 * 0.1) / (0.1 + 0.3 + 0.4); println!("loop: inertia {:?}; loop rule q2 = {:.6}", inertia(&f5.blocks), q2);
    let (xm5, hm5, _) = minres(&|v| lp.mv(v), &lp.rhs, 1e-12, 10, false);
    println!("loop: MINRES residual by step {} | gap to BK {}", hm5.iter().map(|&v| sci(v)).collect::<Vec<_>>().join(" "), sci(gap(&xm5, &x5)));
    let tiny = Net::new(vec![(-1, 0, 1e-13), (0, 1, 0.3), (-1, 1, 0.4)], vec![20.0, 30.0]); let qt = (12.0 - 20e-13) / (1e-13 + 0.7) + 20.0; // r1 = 1e-13
    let xp = bk_solve(&bk(&tiny.dense(), true), &tiny.rhs); let xb = bk_solve(&bk(&tiny.dense(), false), &tiny.rhs);
    row("tiny r1: q1 by 1x1 order, BK, loop rule", &[xp[0], xb[0], qt]);
    let dis = grid(3, 20); let pd = bk(&dis.dense(), false); let xd = bk_solve(&pd, &dis.rhs); let xdm = minres(&|v| dis.mv(v), &dis.rhs, 1e-10, 2000, false).0;
    let bound = g1.powf((dis.n - 1) as f64); println!("district: {} pipes, n = {}; 2x2 pivots {}, inertia {:?}; growth {}, bound {}; gap to MINRES {}", dis.m, dis.n,
        pd.blocks.iter().filter(|d| d.len() == 3).count(), inertia(&pd.blocks), sci(pd.growth), sci(bound), sci(gap(&xd, &xdm)));
    let net = grid(13, 20); let (xn, pn) = net.nodal(); let nnz = net.m + 2 * (2 * net.m - 13); let ones = vec![1.0; net.n]; let step = 2 * nnz + 16 * net.n;
    println!("network: {} pipes, n = {}, stored entries {}; demand {:.6} L/s", net.m, net.n, nnz, dot(&net.d, &ones));
    let (pmin, pmax) = (pn.iter().fold(f64::MAX, |m, &v| m.min(v)), pn.iter().fold(f64::MIN, |m, &v| m.max(v)));
    row("network: nodal pivots: smallest, largest", &[pmin, pmax]); println!("network: inertia {:?}", [net.m, pn.len()]);
    let (xm, hm, tm) = minres(&|v| net.mv(v), &net.rhs, 1e-10, 3000, false); let (xc, hc, negc, _) = cg(&|v| net.mv(v), &net.rhs, 1e-10, 3000);
    let res: Vec<f64> = net.mv(&xm).iter().zip(&net.rhs).map(|(a, b)| a - b).collect(); let rel = (dot(&res, &res) / dot(&net.rhs, &net.rhs)).sqrt();
    println!("network: MINRES {} steps, residual {}, recomputed {}; gap to nodal {}, CG's {}", hm.len() - 1, sci(hm[hm.len() - 1]), sci(rel), sci(gap(&xm, &xn)), sci(gap(&xc, &xn)));
    let heads = &xm[net.m..]; row("network: heads min, max; reservoir L/s", &[heads.iter().fold(f64::MAX, |m, &v| m.min(v)), heads.iter().fold(f64::MIN, |m, &v| m.max(v)), dot(&xm[..13], &ones)]);
    let worst = hc.iter().fold(f64::MIN, |m, &v| m.max(v)); println!("network: CG {} steps, {} negative p^T A p, worst residual {:.3} times the start", hc.len() - 1, negc, worst);
    let hf = minres(&|v| net.mv(v), &net.rhs, 1e-10, 3000, true).1; println!("network: recomputed residual rises {} times; with full reorthogonalisation MINRES needs {} steps, {} fewer", tm.windows(2).filter(|w| w[1] > w[0]).count(), hf.len() - 1, hm.len() - hf.len());
    let nn = net.n as u64; println!("flops at n = {}: dense BK {}, LU {}; MINRES {} a step, {} in all", nn, comma(nn * nn * nn / 3), comma(2 * nn * nn * nn / 3), comma(step as u64), comma((step * (hm.len() - 1)) as u64));
    for k in (0..hm.len()).step_by(40) { println!("figure, step {}, MINRES {:.2}, CG {:.2}", k, hm[k].log10(), hc[k].log10()); }
    let near = |u: &[f64], v: &[f64], t: f64| gap(u, v) < t;
    assert!((g1 * g1 - g2).abs() < 1e-12 && (4.0 * al * al - al - 1.0).abs() < 1e-15 && c1.0.is_none() && c5.0.is_none() && brk == 1);
    assert!(near(&x5, &[32.5, 12.5, 17.5, 56.75, 53.0], 1e-12) && (x5[1] - q2).abs() < 1e-12 && (xp[0] - qt).abs() > 0.01 && (xb[0] - qt).abs() < 1e-9);
    assert!(inertia(&f5.blocks) == vec![3, 2] && inertia(&pd.blocks) == vec![dis.m, dis.n - dis.m] && pmin > 0.0 && pd.growth <= bound);
    assert!(f5.blocks.iter().chain(&pd.blocks).filter(|d| d.len() == 3).all(|d| d[0] * d[2] - d[1] * d[1] < 0.0)); // every 2x2 pivot: one + and one -
    assert!(near(&xm5, &x5, 1e-10) && near(&xdm, &xd, 1e-7) && near(&xm, &xn, 1e-6) && (rel - hm[hm.len() - 1]).abs() < 1e-12 && worst > 1.0);
    assert!(tm.windows(2).all(|w| w[1] <= w[0] * (1.0 + 1e-12)) && (dot(&xm[..13], &ones) - dot(&net.d, &ones)).abs() < 1e-6 && hf[hf.len() - 1] < 1e-10 && 1e-10 < hf[hf.len() - 2] && hf.len() < hm.len());
    println!("ALL CHECKS PASS");
}
