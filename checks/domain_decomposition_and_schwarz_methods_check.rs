// Domain decomposition and Schwarz methods -- the check behind the card.  Rust std
// only.  Part 1: -u'' = 0 on [0, 1] split into [0, 0.6] and [0.4, 1], grid
// step 0.01.  Part 2: the hot plate on a 63-by-63 grid, conjugate gradient with
// one-level and two-level additive Schwarz, checked against a banded Cholesky.
const NS: usize = 63;
const NN: usize = NS * NS;
type Mat = Vec<Vec<f64>>;
fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn piece(u: &[f64], lo: usize, hi: usize) -> Vec<f64> { // -u'' = 0 inside (lo, hi), Thomas
    let n = hi - lo - 1; let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);
    for k in 0..n {
        let rhs = (if k == 0 { u[lo] } else { 0.0 }) + (if k == n - 1 { u[hi] } else { 0.0 });
        let den = 2.0 + if k > 0 { c[k - 1] } else { 0.0 };
        c[k] = -1.0 / den; d[k] = (rhs + if k > 0 { d[k - 1] } else { 0.0 }) / den;
    }
    let mut v = u.to_vec(); v[hi - 1] = d[n - 1];
    for k in (0..n - 1).rev() { v[lo + 1 + k] = d[k] - c[k] * v[lo + 2 + k]; } v
}
fn err(u: &[f64]) -> f64 { (0..101).map(|j| (u[j] - j as f64 / 100.0).abs()).fold(0.0, f64::max) }
fn matvec(x: &[f64]) -> Vec<f64> {
    let mut y: Vec<f64> = x.iter().map(|v| 4.0 * v).collect();
    for k in 0..NN {
        let (i, j) = (k / NS, k % NS);
        if i > 0 { y[k] -= x[k - NS]; } if i < NS - 1 { y[k] -= x[k + NS]; }
        if j > 0 { y[k] -= x[k - 1]; } if j < NS - 1 { y[k] -= x[k + 1]; }
    } y
}
fn dot(x: &[f64], y: &[f64]) -> f64 { let mut s = 0.0; for (a, c) in x.iter().zip(y) { s += a * c; } s }
fn chol(m: usize, w: usize, ent: &dyn Fn(usize, usize) -> f64) -> Mat { // L[r][t] = L(r, r - w + t)
    let mut l = vec![vec![0.0; w + 1]; m];
    for r in 0..m {
        for d in (0..=w.min(r)).rev() {
            let mut s = ent(r, r - d);
            for t in 0..w - d { s -= l[r][t] * l[r - d][t + d]; }
            l[r][w - d] = if d == 0 { s.sqrt() } else { s / l[r - d][w] };
        }
    } l
}
fn csolve(l: &Mat, m: usize, w: usize, rhs: &[f64]) -> Vec<f64> {
    let mut y = rhs.to_vec();
    for r in 0..m {
        for t in w.saturating_sub(r)..w { y[r] -= l[r][t] * y[r + t - w]; } y[r] /= l[r][w];
    }
    for r in (0..m).rev() { y[r] /= l[r][w]; for t in w.saturating_sub(r)..w { y[r + t - w] -= l[r][t] * y[r]; } } y
}
fn grid_ent(ny: usize) -> impl Fn(usize, usize) -> f64 {
    move |r, c| if r == c { 4.0 } else if (c + 1 == r && r % ny != 0) || c + ny == r { -1.0 } else { 0.0 }
}
struct Prec { sub: Vec<(Vec<usize>, usize, Mat)>, ph: Vec<Vec<(usize, f64)>>, l0: Mat }
fn make_prec(p: usize, ext: usize, two: bool) -> (Prec, usize, usize) { // P x P squares, grown ext a side
    let (hh, mut sub, mut ph) = (64 / p, vec![], vec![]);
    for s in 0..p * p {
        let (a, c) = (s / p, s % p);
        let ii = ((a * hh + 1).saturating_sub(ext).max(1), ((a + 1) * hh + ext - 1).min(NS));
        let jj = ((c * hh + 1).saturating_sub(ext).max(1), ((c + 1) * hh + ext - 1).min(NS));
        let (mut idx, w) = (vec![], jj.1 - jj.0 + 1);
        for i in ii.0..=ii.1 { for j in jj.0..=jj.1 { idx.push((i - 1) * NS + j - 1); } }
        let l = chol(idx.len(), w, &grid_ent(w)); sub.push((idx, w, l));
    }
    for a in 1..(if two { p } else { 1 }) {
        for c in 1..p { let mut f = vec![];
            for i in a * hh - hh + 1..a * hh + hh { for j in c * hh - hh + 1..c * hh + hh {
                    let wi = 1.0 - ((i as f64 - (a * hh) as f64).abs()) / hh as f64;
                    let wj = 1.0 - ((j as f64 - (c * hh) as f64).abs()) / hh as f64;
                    f.push(((i - 1) * NS + j - 1, wi * wj));
            } }
            ph.push(f);
    } }
    let m = ph.len();
    let wts: Vec<Vec<f64>> = ph.iter().map(|f| f.iter().map(|q| q.1).collect()).collect();
    let cols: Vec<Vec<f64>> = ph.iter().map(|f| { let mut x = vec![0.0; NN]; for &(k, w) in f { x[k] = w; } matvec(&x) }).collect();
    let a0: Mat = (0..m).map(|r| (0..m).map(|c| dot(&wts[r], &ph[r].iter().map(|q| cols[c][q.0]).collect::<Vec<_>>())).collect()).collect();
    let l0 = if m > 0 { chol(m, m - 1, &|r, c| a0[r][c]) } else { vec![] };
    let big = sub.iter().map(|s| s.0.len()).max().unwrap(); (Prec { sub, ph, l0 }, big, m)
}
fn apply(pr: &Prec, r: &[f64]) -> Vec<f64> {
    let mut z = vec![0.0; NN];
    for (idx, w, l) in &pr.sub {
        let y = csolve(l, idx.len(), *w, &idx.iter().map(|&k| r[k]).collect::<Vec<_>>());
        for (k, v) in idx.iter().zip(y) { z[*k] += v; }
    } let m = pr.ph.len();
    if m > 0 {
        let rc: Vec<f64> = pr.ph.iter().map(|f| { let w: Vec<f64> = f.iter().map(|q| q.1).collect(); dot(&w, &f.iter().map(|q| r[q.0]).collect::<Vec<_>>()) }).collect();
        let y = csolve(&pr.l0, m, m - 1, &rc);
        for (f, v) in pr.ph.iter().zip(y) { for &(k, wt) in f { z[k] += wt * v; } }
    } z
}
fn pcg(b: &[f64], prec: &dyn Fn(&[f64]) -> Vec<f64>) -> (Vec<f64>, usize, f64, f64) {
    let (mut x, mut r) = (vec![0.0; NN], b.to_vec()); let z = prec(&r);
    let (mut p, mut rz, bn) = (z.clone(), dot(&r, &z), dot(b, b).sqrt());
    let (mut al, mut be): (Vec<f64>, Vec<f64>) = (vec![], vec![]);
    while dot(&r, &r).sqrt() > 1e-8 * bn {
        let ap = matvec(&p); let a = rz / dot(&p, &ap); al.push(a);
        for k in 0..NN { x[k] += a * p[k]; r[k] -= a * ap[k]; }
        let z = prec(&r); let rz2 = dot(&r, &z); be.push(rz2 / rz);
        for k in 0..NN { p[k] = z[k] + be[be.len() - 1] * p[k]; } rz = rz2;
    }
    let (m, mut dg) = (al.len(), vec![1.0 / al[0]]);
    for k in 1..m { dg.push(1.0 / al[k] + be[k - 1] / al[k - 1]); }
    let o2: Vec<f64> = (0..m - 1).map(|k| be[k] / (al[k] * al[k])).collect();
    let below = |t: f64| { // Sturm count: eigenvalues of the Lanczos table below t
        let mut q = dg[0] - t; let mut c = if q < 0.0 { 1 } else { 0 };
        for k in 1..m { q = dg[k] - t - o2[k - 1] / q; if q < 0.0 { c += 1; } } c
    };
    let eig = |i: usize| {
        let (mut lo, mut hi) = (0.0, 8.0);
        for _ in 0..80 { if below((lo + hi) / 2.0) > i { hi = (lo + hi) / 2.0 } else { lo = (lo + hi) / 2.0 } } lo
    };
    (x, m, eig(0), eig(m - 1))
}
fn e3(x: f64) -> String { format!("{:.3e}", x) }
fn main() {
    let (mut u0, mut first) = (vec![0.0; 101], vec![]); u0[100] = 1.0;
    for (ia, ib) in [(40usize, 60usize), (45, 55), (49, 51), (50, 50)] {
        let (mut u, mut es) = (u0.clone(), vec![err(&u0)]);
        for _ in 0..20 { u = piece(&piece(&u, 0, ib), ia, 100); es.push(err(&u)); }
        let (nu, de) = (ia * (100 - ib), ib * (100 - ia)); let (g, rho) = (gcd(nu, de), nu as f64 / de as f64);
        assert!((es[10] / es[9] - rho).abs() < 1e-9); // the proved factor against the run
        println!("1d,overlap={:.2},factor={}/{}={:.6},observed={:.6},err_after_20={}", (ib - ia) as f64 / 100.0, nu / g, de / g, rho, es[10] / es[9], e3(es[20]));
        if ia == 40 { first = es[..5].to_vec(); }
    }
    println!("1d,max_error_after_sweeps_0_to_4,{}", first.iter().map(|e| format!("{:.6}", e)).collect::<Vec<_>>().join(","));
    assert!((first[1] - 0.4).abs() < 1e-12 && (first[4] - 0.4 * (4.0f64 / 9.0).powi(3)).abs() < 1e-12);
    let (mut u, mut fig) = (u0.clone(), vec![]);
    for _ in 0..2 { u = piece(&u, 0, 60); fig.push(u[40]); u = piece(&u, 40, 100); fig.push(u[60]); }
    println!("figure,u(0.4)_then_u(0.6)_after_each_half_sweep,{}", fig.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(","));
    let additive = |mut u: Vec<f64>, k: usize| { // additive form as a plain iteration: both pieces at once, k steps
        for _ in 0..k { let (v1, v2) = (piece(&u, 0, 60), piece(&u, 40, 100)); u = (0..101).map(|j| u[j] + (v1[j] - u[j]) + (v2[j] - u[j])).collect(); } u };
    let ea: Vec<f64> = (1..21).map(|k| err(&additive(u0.clone(), k))).collect(); // from u = 0 the error stays a straight line across the overlap
    let sp: Vec<f64> = (0..101).map(|j| j as f64 / 100.0 + if j == 50 { 1.0 } else { 0.0 }).collect(); // exact line + spike at x = 0.5
    let (s1, s20) = (additive(sp.clone(), 1)[50] - 0.5, additive(sp, 20)[50] - 0.5);
    println!("1d,additive_iteration,err_after_20={},observed_factor={:.6},spike_at_0.5_after_1_and_20={:.6},{:.6}", e3(ea[19]), ea[10] / ea[9], s1, s20);
    assert!((ea[10] / ea[9] - 2.0 / 3.0).abs() < 1e-9 && (s1 + 1.0).abs() < 1e-12 && (s20 - 1.0).abs() < 1e-12); // 2/3 on a straight line; -1 inside the overlap
    let mut e = vec![0.0; 101]; e[50] = 1.0; // Schur complement: unit push at the interface x = 0.5
    let (s, gr) = (2.0 - piece(&e, 0, 50)[49] - piece(&e, 50, 100)[51], piece(&u0, 50, 100)[51]);
    println!("1d,schur,S={:.6},g={:.6},u(0.5)={:.6}", s, gr, gr / s);
    assert!((s - 2.0 / 50.0).abs() < 1e-12 && (gr / s - 0.5).abs() < 1e-12);
    let (f, h) = (3200.0, 1.0 / 64.0);
    let b: Vec<f64> = (0..NN).map(|k| if (24..=40).contains(&(k / NS + 1)) && (24..=40).contains(&(k % NS + 1)) { h * h * f } else { 0.0 }).collect();
    let lf = chol(NN, NS, &grid_ent(NS)); let (xd, mid) = (csolve(&lf, NN, NS, &b), 31 * NS + 31);
    let rd: Vec<f64> = b.iter().zip(matvec(&xd)).map(|(a, c)| a - c).collect();
    println!("plate,unknowns={},direct_centre_K={:.4},direct_rel_residual={}", NN, xd[mid], e3((dot(&rd, &rd) / dot(&b, &b)).sqrt()));
    let (_, k, lo, hi) = pcg(&b, &|r: &[f64]| r.to_vec());
    let ex = 1.0 / (std::f64::consts::PI / 128.0).tan().powi(2); // exact kappa: cot^2(pi h / 2)
    println!("plate,plain_cg,steps={},kappa_est={:.1},closed_form={:.1}", k, hi / lo, ex); assert!((hi / lo - ex).abs() < 1.0);
    let (mut st, mut kap) = (std::collections::HashMap::new(), std::collections::HashMap::new());
    for (lev, p, ext) in [(1, 2, 4), (1, 4, 2), (1, 8, 1), (2, 2, 4), (2, 4, 2), (2, 8, 1), (2, 2, 1), (2, 4, 1)] {
        let (pr, big, m) = make_prec(p, ext, lev == 2);
        let (x, k, lo, hi) = pcg(&b, &|r: &[f64]| apply(&pr, r));
        st.insert((lev, p, ext), k); kap.insert((lev, p, ext), hi / lo);
        let gap = x.iter().zip(&xd).map(|(a, c)| (a - c).abs()).fold(0.0, f64::max);
        println!("plate,levels={},squares={},H/delta={:.0},largest_piece={},coarse={},steps={},lmin={:.3},lmax={:.3},kappa_est={:.1},centre_K={:.4},gap={}",
            lev, p * p, (64 / p) as f64 / (2 * ext) as f64, big, m, k, lo, hi, hi / lo, x[mid], e3(gap));
        assert!(gap < 1e-7 * xd[mid]); // Schwarz-CG against the direct solve
    }
    assert!(kap[&(1, 8, 1)] > 10.0 * kap[&(1, 2, 4)] && kap[&(2, 8, 1)] < 1.5 * kap[&(2, 2, 4)] && st[&(1, 8, 1)] > 3 * st[&(1, 2, 4)]);
    assert!(kap[&(2, 2, 1)] > kap[&(2, 4, 1)] && kap[&(2, 4, 1)] > kap[&(2, 8, 1)]); // thinner overlap, worse
    let (pr, _, _) = make_prec(4, 2, false); // additive Schwarz as a plain iteration
    let (mut xr, mut rel) = (vec![0.0; NN], 0.0);
    for k in 0..=20 {
        let rr: Vec<f64> = b.iter().zip(matvec(&xr)).map(|(a, c)| a - c).collect();
        let z = apply(&pr, &rr); for i in 0..NN { xr[i] += z[i]; }
        rel = (dot(&rr, &rr) / dot(&b, &b)).sqrt();
        if k % 10 == 0 { println!("plate,additive_iteration,squares=16,step={},rel_residual={}", k, e3(rel)); }
    }
    assert!(rel > 1e6);
    println!("ALL CHECKS PASS");
}
