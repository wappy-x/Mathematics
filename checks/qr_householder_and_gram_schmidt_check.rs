// QR two ways: the check behind the card.  Rust std only.
// 200 fuel readings (illustrative, simulated), one every 50 km.  Fit a line by
// Householder reflections and by Gram-Schmidt, test R against its closed form,
// measure lost orthogonality as the fitted degree rises, and count the flops.
use std::sync::atomic::{AtomicU64, Ordering::Relaxed};
type M = Vec<Vec<f64>>;
type Refl = Vec<(Vec<f64>, f64)>;
const U: f64 = 1.0 / 9007199254740992.0; // unit roundoff of a double, 2^-53
static FL: AtomicU64 = AtomicU64::new(0); // flop counter for vector work
fn sci(v: f64) -> String { format!("{:.2e}", v) } // 1.23e-10, as Python prints it here
fn rng(s: &mut u64) -> f64 { // SplitMix64, uniform in [0, 1)
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 * U
}
fn dot(u: &[f64], v: &[f64]) -> f64 {
    let mut s = 0.0;
    for (a, b) in u.iter().zip(v) { s += a * b; }
    FL.fetch_add(2 * u.len() as u64 - 1, Relaxed); s
}
fn axpy(f: f64, v: &[f64], w: &[f64]) -> Vec<f64> { // w - f v
    FL.fetch_add(2 * v.len() as u64, Relaxed);
    v.iter().zip(w).map(|(a, b)| b - f * a).collect()
}
fn unit(n: usize, j: usize) -> Vec<f64> { (0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect() }
fn gram_schmidt(a: &M, modified: bool, passes: usize) -> (M, M) { // a, q: lists of columns
    let n = a.len(); let (mut q, mut r): (M, M) = (vec![], vec![vec![0.0; n]; n]);
    for j in 0..n {
        let mut v = a[j].clone();
        for _ in 0..passes {
            let base = v.clone(); // classical projects this, modified the running v
            for k in 0..j {
                let rk = dot(&q[k], if modified { &v } else { &base });
                v = axpy(rk, &q[k], &v);
                r[k][j] += rk;
            }
        }
        r[j][j] = dot(&v, &v).sqrt(); FL.fetch_add(v.len() as u64, Relaxed);
        q.push(v.iter().map(|b| b / r[j][j]).collect());
    }
    (q, r)
}
fn householder(a: &M) -> (Refl, M) { // the reflectors and R; Q is never formed
    let (mut w, mut vs, n) = (a.clone(), vec![], a.len());
    for k in 0..n {
        let x = w[k][k..].to_vec(); let nx = dot(&x, &x).sqrt();
        let s = if x[0] >= 0.0 { 1.0 } else { -1.0 }; // sign that avoids cancellation
        let mut v = x.clone(); v[0] += s * nx;
        let vv = 2.0 * nx * (nx + x[0].abs()); // = v.v, without a second dot product
        for i in k..w[k].len() { w[k][i] = if i == k { -s * nx } else { 0.0 }; }
        for j in k + 1..n {
            let t = axpy(2.0 * dot(&v, &w[j][k..]) / vv, &v, &w[j][k..]);
            w[j].splice(k.., t);
        }
        vs.push((v, vv));
    }
    let r = (0..n).map(|i| (0..n).map(|j| if i <= j { w[j][i] } else { 0.0 }).collect()).collect();
    (vs, r)
}
fn reflect(vs: &Refl, y: &[f64], back: bool) -> Vec<f64> { // H_n...H_1 y, or H_1...H_n y
    let mut y = y.to_vec();
    let order: Vec<usize> = if back { (0..vs.len()).rev().collect() } else { (0..vs.len()).collect() };
    for k in order {
        let t = axpy(2.0 * dot(&vs[k].0, &y[k..]) / vs[k].1, &vs[k].0, &y[k..]);
        y.splice(k.., t);
    }
    y
}
fn thin_q(vs: &Refl, m: usize) -> M { (0..vs.len()).map(|j| reflect(vs, &unit(m, j), true)).collect() }
fn loss(q: &M) -> f64 { // largest entry of Q^T Q - I, in size
    let mut l: f64 = 0.0;
    for i in 0..q.len() { for j in 0..q.len() { l = l.max((dot(&q[i], &q[j]) - unit(q.len(), j)[i]).abs()); } }
    l
}
fn solve_r(r: &M, z: &[f64]) -> Vec<f64> { // back substitution
    let mut c = vec![0.0; z.len()];
    for i in (0..z.len()).rev() {
        let mut s = z[i]; for j in i + 1..z.len() { s -= r[i][j] * c[j]; }
        c[i] = s / r[i][i];
    }
    c
}
fn smax(t: &M) -> f64 { // largest stretch, by power iteration on T^T T
    let (n, mut s) = (t.len(), 0.0); let mut v = vec![1.0; n];
    for _ in 0..400 {
        let w: Vec<f64> = t.iter().map(|row| dot(row, &v)).collect();
        let w: Vec<f64> = (0..n).map(|j| dot(&t.iter().map(|row| row[j]).collect::<Vec<_>>(), &w)).collect();
        s = dot(&w, &w).sqrt(); v = w.iter().map(|a| a / s).collect();
    }
    s.sqrt()
}
fn kappa(r: &M) -> f64 { // condition number with columns scaled to length 1
    let n = r.len();
    let c: Vec<f64> = (0..n).map(|j| { let col: Vec<f64> = (0..n).map(|i| r[i][j]).collect(); dot(&col, &col).sqrt() }).collect();
    let s: M = (0..n).map(|i| (0..n).map(|j| r[i][j] / c[j]).collect()).collect();
    let inv: M = (0..n).map(|j| solve_r(&s, &unit(n, j))).collect(); // columns
    smax(&s) * smax(&(0..n).map(|i| (0..n).map(|j| inv[j][i]).collect()).collect())
}
fn main() {
    let (mut g, m) = (2026u64, 200);
    let d: Vec<f64> = (0..m).map(|i| 0.05 * i as f64).collect(); // thousands of km on the trip meter
    let mut noise = || dot(&(0..12).map(|_| rng(&mut g)).collect::<Vec<_>>(), &[1.0; 12]) - 6.0; // mean 0, spread 1
    let y: Vec<f64> = d.iter().map(|di| 7.2 + 0.03 * di + 0.25 * noise()).collect(); // litres per 100 km, illustrative
    let ones = vec![1.0; m]; let mean = dot(&ones, &d) / m as f64;
    let dc: Vec<f64> = d.iter().map(|di| di - mean).collect(); let ss = dot(&dc, &dc); // centred distances
    let closed = [(m as f64).sqrt(), (m as f64).sqrt() * mean, ss.sqrt()];
    println!("data,n={},d from 0.00 to {:.2} thousand km,mean d={:.4},sum d={:.2},sum (d-mean)^2={:.6}", m, d[m - 1], mean, mean * m as f64, ss);
    println!("R closed form,r11={:.6},r12={:.6},r22={:.6}", closed[0], closed[1], closed[2]);
    let (vs, rh) = householder(&vec![ones.clone(), d.clone()]);
    let (qg, rg) = gram_schmidt(&vec![ones.clone(), d.clone()], false, 1);
    for (name, r) in [("householder", &rh), ("gram-schmidt", &rg)] {
        println!("R {},r11={:.6},r12={:.6},r22={:.6}", name, r[0][0], r[0][1], r[1][1]);
        for (got, want) in [r[0][0].abs(), r[0][1].abs(), r[1][1].abs()].iter().zip(closed) {
            assert!((got - want).abs() < 1e-12 * want, "{} {} {}", name, got, want);
        }
    }
    let (v0, vv) = (vs[0].0[0], vs[0].1); let f = 2.0 * mean * m as f64 / vv;
    println!("first reflector,v1={:.6},v.v={:.6},f={:.6},new top of d=-f*v1={:.6}", v0, vv, f, -f * v0);
    assert!((-f * v0 + closed[1]).abs() < 1e-12 * closed[1]); // the hand route to r12 against the closed form
    let yb = dot(&ones, &y) / m as f64; let sxy = dot(&dc, &y.iter().map(|yi| yi - yb).collect::<Vec<_>>());
    let cf = vec![yb - sxy / ss * mean, sxy / ss]; let ch = solve_r(&rh, &reflect(&vs, &y, false)[..2]);
    let cg = solve_r(&rg, &qg.iter().map(|q| dot(q, &y)).collect::<Vec<_>>());
    for (name, c) in [("centred formula", &cf), ("householder", &ch), ("gram-schmidt", &cg)] {
        println!("fit {},intercept={:.6} L/100km,slope={:.6} L/100km per 1000 km", name, c[0], c[1]);
    }
    assert!([&ch, &cg].iter().all(|c| (c[0] - cf[0]).abs() < 1e-12 && (c[1] - cf[1]).abs() < 1e-12)); // both QR fits = formula
    println!("line fit loss of orthogonality,householder={},gram-schmidt={}", sci(loss(&thin_q(&vs, m))), sci(loss(&qg)));
    println!("degree,kappa,classical,modified,householder,classical/(u kappa^2),modified/(u kappa)");
    let (mut cols, mut pts): (M, Vec<Vec<String>>) = (vec![ones.clone()], vec![vec![]; 3]);
    for p in 1..=10 {
        let next: Vec<f64> = cols[cols.len() - 1].iter().zip(&d).map(|(a, b)| a * b).collect(); cols.push(next);
        let (vs, r) = householder(&cols);
        let k = kappa(&r);
        let (lc, lm, lh) = (loss(&gram_schmidt(&cols, false, 1).0), loss(&gram_schmidt(&cols, true, 1).0), loss(&thin_q(&vs, m)));
        println!("{},{},{},{},{},{:.3},{:.3}", p, sci(k), sci(lc), sci(lm), sci(lh), lc / (U * k * k), lm / (U * k));
        for (lst, val) in pts.iter_mut().zip([lc, lm, lh]) { lst.push(format!("{:.2}", val.log10())); }
        assert!(lh < 1e-14); // Householder: orthogonal to rounding, any kappa
        assert!(0.1 < lm / (U * k) && lm / (U * k) < 10.0); // modified: near u kappa (lower limit: this code, this table)
        if p >= 3 { assert!(lc > 10.0 * lm && lc > 0.1 * U * k * k); } // classical: near u kappa^2, as run here
    }
    for (name, lst) in ["classical", "modified", "householder"].iter().zip(&pts) { println!("chart log10 loss {},{}", name, lst.join(",")); }
    let ((qc, rc), mut res) = (gram_schmidt(&cols, false, 1), 0.0f64);
    for j in 0..11 { // each column's worst miss over its largest entry
        for i in 0..m {
            let (a, b): (Vec<f64>, Vec<f64>) = ((0..=j).map(|k| qc[k][i]).collect(), (0..=j).map(|k| rc[k][j]).collect());
            res = res.max((cols[j][i] - dot(&a, &b)).abs() / cols[j][m - 1]);
        }
    }
    let l2 = loss(&gram_schmidt(&cols, false, 2).0);
    println!("degree 10,classical twice loss={},classical A-QR relative residual={}", sci(l2), sci(res));
    assert!(l2 < 1e-14 && res < 1e-13);
    println!("cost,m,n,gram-schmidt,2mn^2,householder R,2mn^2-2n^3/3,householder thin Q extra");
    for n in [2usize, 11, 50] {
        let a: M = (0..n).map(|_| (0..m).map(|_| rng(&mut g)).collect()).collect();
        FL.store(0, Relaxed); gram_schmidt(&a, false, 1); let fg = FL.load(Relaxed) as usize; // count each road
        FL.store(0, Relaxed); let (vs, _) = householder(&a); let fh = FL.load(Relaxed) as usize;
        FL.store(0, Relaxed); thin_q(&vs, m); let fq = FL.load(Relaxed);
        let (mf, nf) = (m as f64, n as f64); // the leading terms, as reals
        println!("cost,{},{},{},{},{},{:.1},{}", m, n, fg, 2 * m * n * n, fh, 2.0 * mf * nf * nf - 2.0 * nf * nf * nf / 3.0, fq);
        assert_eq!(fg, n * (n - 1) / 2 * (4 * m - 1) + n * (3 * m - 1));
        assert_eq!(fh, (0..n).map(|k| (2 * (m - k) - 1) + (n - k - 1) * (4 * (m - k) - 1)).sum::<usize>());
    }
    let x = vec![1.0, 1.0]; // the figure: two readings, both ones
    let v = householder(&vec![x.clone()]).0[0].0.clone();
    let hx = axpy(2.0 * dot(&v, &x) / dot(&v, &v), &v, &x); // reflect x in full, with v.v by dot product
    println!("figure,x=(1,1),Hx=({:.6},{:.6}),v=({:.6},{:.6}),midpoint=({:.6},{:.6})", hx[0], hx[1], v[0], v[1], (x[0] + hx[0]) / 2.0, (x[1] + hx[1]) / 2.0);
    assert!((hx[0] + 2.0f64.sqrt()).abs() < 1e-15 && hx[1].abs() < 1e-15);
    println!("ALL CHECKS PASS");
}
