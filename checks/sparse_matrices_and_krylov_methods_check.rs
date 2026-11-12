// Sparse storage and Krylov methods -- the check behind the card.  Rust std
// only.  50,000 road links on a 250-by-200 torus, six neighbours each.
// Steady traffic is a nonsymmetric system A x = s, stored in compressed rows,
// solved by GMRES, and checked by Jacobi, link lists, a known answer and balance.

fn nxt(st: &mut u64) -> u64 { // SplitMix64, written out
    *st = st.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*st ^ (*st >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn unif(st: &mut u64) -> f64 { (nxt(st) >> 11) as f64 / 9007199254740992.0 }
fn sci(v: f64) -> String { format!("{:.3e}", v) }
fn commas(v: u128) -> String {
    let (d, mut out) = (v.to_string(), String::new());
    for (i, ch) in d.chars().enumerate() { if i > 0 && (d.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut acc = 0.0; for (a, b) in u.iter().zip(v) { acc += a * b; } acc }
fn maxf(v: impl Iterator<Item = f64>) -> f64 { v.fold(f64::MIN, f64::max) }

struct Net { n: usize, nb: Vec<[usize; 6]>, t: Vec<f64>, e: Vec<f64>, w: Vec<[f64; 6]>,
             ptr: Vec<usize>, col: Vec<usize>, val: Vec<f64> }
impl Net {
    fn csr(&self, x: &[f64]) -> Vec<f64> { // y = A x, touching nonzeros only
        (0..self.n).map(|i| { let mut acc = 0.0;
            for p in self.ptr[i]..self.ptr[i + 1] { acc += self.val[p] * x[self.col[p]]; } acc }).collect()
    }
    fn by_links(&self, x: &[f64], ex: bool) -> Vec<f64> { // y = A x again, link by link;
        let mut y: Vec<f64> = (0..self.n).map(|i| x[i] / self.t[i]).collect(); // ex = false: nobody exits
        for j in 0..self.n { for k in 0..6 {
            let w = if ex { self.w[j][k] } else { self.w[j][k] / (1.0 - self.e[j]) };
            y[self.nb[j][k]] -= w * (x[j] / self.t[j]); } }
        y
    }
    fn scaled(&self, v: &[f64]) -> Vec<f64> { self.t.iter().zip(v).map(|(a, c)| a * c).collect() }
}

fn gmres(op: &dyn Fn(&[f64]) -> Vec<f64>, b: &[f64], tol: f64, kmax: usize) -> (Vec<f64>, Vec<f64>) {
    let bnorm = dot(b, b).sqrt(); // Arnoldi + Givens rotations
    let mut q: Vec<Vec<f64>> = vec![b.iter().map(|v| v / bnorm).collect()];
    let (mut hh, mut cs, mut sn): (Vec<Vec<f64>>, Vec<f64>, Vec<f64>) = (vec![], vec![], vec![]);
    let (mut g, mut hist) = (vec![bnorm], vec![1.0]);
    for k in 0..kmax {
        let (mut w, mut h) = (op(&q[k]), vec![]);
        for qj in &q { // modified Gram-Schmidt
            let hj = dot(&w, qj); h.push(hj);
            w = w.iter().zip(qj).map(|(a, c)| a - hj * c).collect();
        }
        h.push(dot(&w, &w).sqrt());
        for j in 0..k { // old rotations, then a new one
            let (a, c) = (h[j], h[j + 1]);
            h[j] = cs[j] * a + sn[j] * c; h[j + 1] = -sn[j] * a + cs[j] * c;
        }
        let r = (h[k] * h[k] + h[k + 1] * h[k + 1]).sqrt();
        cs.push(h[k] / r); sn.push(h[k + 1] / r);
        q.push(w.iter().map(|v| v / h[k + 1]).collect()); h[k] = r;
        g.push(-sn[k] * g[k]); g[k] = cs[k] * g[k];
        hh.push(h); hist.push(g[k + 1].abs() / bnorm);
        if hist[k + 1] < tol { break; }
    }
    let (m, mut u) = (hh.len(), vec![0.0; b.len()]);
    let mut y = vec![0.0; m];
    for i in (0..m).rev() { // back-substitute the small system
        let mut acc = g[i];
        for j in i + 1..m { acc -= hh[j][i] * y[j]; }
        y[i] = acc / hh[i][i];
    }
    for j in 0..m { u = u.iter().zip(&q[j]).map(|(a, c)| a + y[j] * c).collect(); }
    (u, hist)
}

fn main() {
    let (rr, cc, mut st) = (250i64, 200i64, 20261111u64);
    let n = (rr * cc) as usize;
    let off = [(0i64, 1i64), (0, -1), (1, 0), (-1, 0), (1, -1), (-1, 1)]; // k ^ 1 reverses k
    let nb: Vec<[usize; 6]> = (0..n as i64).map(|i| { let mut a = [0usize; 6];
        for (k, (dr, dc)) in off.iter().enumerate() {
            a[k] = (((i / cc + dr).rem_euclid(rr)) * cc + (i % cc + dc).rem_euclid(cc)) as usize; } a }).collect();
    let (mut t, mut e, mut w, mut s) = (vec![0.0; n], vec![0.0; n], vec![[0.0; 6]; n], vec![0.0; n]);
    for j in 0..n { // illustrative traffic numbers
        t[j] = [1.0, 2.0, 5.0, 10.0, 30.0][(nxt(&mut st) % 5) as usize]; // minutes to drive link j
        e[j] = 0.3 + 0.2 * unif(&mut st); // share of its cars that exit
        let g: Vec<f64> = (0..6).map(|_| 0.5 + unif(&mut st)).collect();
        let tot = dot(&g, &[1.0; 6]); // a plain left-to-right sum
        for k in 0..6 { w[j][k] = (1.0 - e[j]) * g[k] / tot; } // share turning onto nb[j][k]
        s[j] = 0.5 + unif(&mut st); // cars a minute from side streets
    }
    let (mut ptr, mut col, mut val) = (vec![0usize], vec![], vec![]); // compressed sparse row (CSR)
    for i in 0..n {
        col.push(i); val.push(1.0 / t[i]);
        for k in 0..6 { let j = nb[i][k]; col.push(j); val.push(-w[j][k ^ 1] / t[j]); }
        ptr.push(col.len());
    }
    let net = Net { n, nb, t, e, w, ptr, col, val };
    let (t, e, one) = (&net.t, &net.e, vec![1.0; n]);
    let nnz = net.val.len();
    let (dense, crs) = (8 * (n * n) as u128, (8 * nnz + 4 * nnz + 4 * (n + 1)) as u128);
    println!("network,links={},nonzeros={},share={:.3}%", commas(n as u128), commas(nnz as u128),
             (100 * nnz) as f64 / n as f64 / n as f64);
    println!("storage,dense_entries={},dense_bytes={},csr_bytes={},triplet_bytes={}", commas((n * n) as u128), commas(dense), commas(crs), commas(16 * nnz as u128));
    println!("storage,saving={:.1},product_flops_dense={},csr={}", dense as f64 / crs as f64,
             commas(2 * (n * n) as u128), commas(2 * nnz as u128));
    println!("row0,ptr={:?},col={:?}", &net.ptr[..2], &net.col[..7]);
    let v0: Vec<String> = net.val[..7].iter().map(|v| format!("{:.4}", v)).collect();
    println!("row0,val={}", v0.join(", "));
    let z: Vec<f64> = (0..n).map(|_| unif(&mut st)).collect();
    let gap = maxf(net.csr(&z).iter().zip(net.by_links(&z, true)).map(|(a, c)| (a - c).abs()));
    assert!(gap < 1e-13); println!("product,csr_vs_link_lists_max_gap={}", sci(gap));

    let pre = |v: &[f64]| net.csr(&net.scaled(v)); // B = A M^-1, M = diag(A)
    let (nb2, bs) = (dot(&s, &s).sqrt(), pre(&s));
    let al = dot(&s, &bs) / dot(&bs, &bs); let r1 = (dot(&s, &s) - al * dot(&s, &bs)).sqrt() / nb2;
    let (u, hist) = gmres(&pre, &s, 1e-10, 60); let x = net.scaled(&u); // x = M^-1 u
    assert!((hist[1] - r1).abs() < 1e-12);
    println!("step1,norm_s={:.4},s.Bs={:.4},Bs.Bs={:.4},alpha={:.6}", nb2, dot(&s, &bs), dot(&bs, &bs), al);
    println!("step1,residual={:.6},gmres={:.6}", r1, hist[1]);
    let (mut xj, mut jh) = (vec![0.0; n], vec![]); // plain Jacobi: x += M^-1 (s - A x)
    loop {
        let r: Vec<f64> = s.iter().zip(net.csr(&xj)).map(|(a, c)| a - c).collect();
        jh.push(dot(&r, &r).sqrt() / nb2);
        if jh[jh.len() - 1] < 1e-10 { break; }
        xj = (0..n).map(|i| xj[i] + t[i] * r[i]).collect();
    }
    let ninf = maxf(net.by_links(t, true).iter().map(|v| 1.0 - v)); // shares turning into each link
    let n1 = maxf(e.iter().map(|v| 1.0 - v)); let beta = (n1 * ninf).sqrt();
    println!("bound,norm1={:.6},norm_inf={:.6},beta={:.6},jacobi_factor_per_step_over_20={:.4}", n1, ninf, beta, jh[20].powf(0.05));
    println!("step,gmres,jacobi,bound,gmres/bound");
    for k in (0..hist.len()).step_by(4) {
        let b = beta.powf(k as f64);
        assert!(hist[k] <= jh[k] * (1.0 + 1e-9) && jh[k] <= b * (1.0 + 1e-9));
        println!("{},{},{},{},{}", k, sci(hist[k]), sci(jh[k]), sci(b), sci(hist[k] / b));
    }
    let (x0, hist0) = gmres(&|v: &[f64]| net.csr(v), &s, 1e-10, 150); // no preconditioner
    let tr: Vec<f64> = s.iter().zip(net.by_links(&x, true)).map(|(a, c)| a - c).collect();
    let tru = dot(&tr, &tr).sqrt() / nb2;
    let gapf = |y: &[f64]| maxf(y.iter().zip(&x).map(|(a, c)| (a - c).abs() / c));
    let (gj, g0, kk) = (gapf(&xj), gapf(&x0), hist.len() - 1);
    assert!(tru < 2e-10 && gj < 1e-8 && g0 < 1e-8 && hist0.len() > 3 * hist.len());
    println!("solve,steps={},estimate={},true_residual={}", kk, sci(hist[kk]), sci(tru));
    println!("solve,jacobi_steps={},max_rel_gap={}", jh.len() - 1, sci(gj));
    println!("solve,plain_steps={},at_step_{}={},max_rel_gap={}", hist0.len() - 1, kk, sci(hist0[kk]), sci(g0));
    for (st, pc) in [(kk, 1usize), (hist0.len() - 1, 0)] {
        let fl: usize = (0..st).map(|k| 2 * nnz + pc * n + 4 * n * (k + 1) + 3 * n).sum();
        println!("cost,steps={},flops={},basis_bytes={}", st, commas(fl as u128), commas((8 * n * (st + 1)) as u128));
    }
    println!("cost,dense_lu_flops={}", commas(2 * (n as u128).pow(3) / 3));
    let bm = net.by_links(&one, true); let (um, hm) = gmres(&pre, &bm, 1e-10, 60); // answer: all ones
    let xm = net.scaled(&um); let rm: Vec<f64> = bm.iter().zip(net.by_links(&xm, true)).map(|(a, c)| a - c).collect();
    let dm: Vec<f64> = xm.iter().map(|v| v - 1.0).collect(); let (er, rr) = ((dot(&dm, &dm) / n as f64).sqrt(), (dot(&rm, &rm) / dot(&bm, &bm)).sqrt());
    let kb = (1.0 + beta) * maxf(t.iter().copied()) / -maxf(t.iter().map(|v| -v)) / (1.0 - beta); assert!(er < 1e-8 && (beta >= 1.0 || er <= kb * rr)); // kappa_2 bound, Step 5
    println!("manufactured,steps={},rel_residual={},rel_error={},ratio={:.1},kappa2_bound={:.1},error_bound={},bound/true={:.1}", hm.len() - 1, sci(rr), sci(er), er / rr, kb, sci(kb * rr), kb * rr / er);
    let xt: Vec<f64> = x.iter().zip(t).map(|(a, c)| a / c).collect();
    let (cin, cars, cout) = (dot(&s, &one), dot(&x, &one), dot(e, &xt));
    assert!((cin - cout).abs() < 1e-9 * cin);
    println!("balance,cars_in_per_min={:.4},cars_out_per_min={:.4}", cin, cout);
    println!("answer,cars_on_network={:.1},link0_cars={:.4},link0_minutes={:.0}", cars, x[0], t[0]);
    let closed = |v: &[f64]| net.by_links(&net.scaled(v), false); // e = 0
    let (_, hc) = gmres(&closed, &s, 1e-10, kk);
    let (floor, last) = (cin / (n as f64).sqrt() / nb2, hc[hc.len() - 1]); // proven floor
    assert!(floor <= last && last < 1.01 * floor && hc[10] - last < 1e-5);
    println!("closed,residual_at_step_10={:.6},at_step_{}={:.6},floor={:.6}", hc[10], kk, last, floor);
    let ks: Vec<String> = (0..21).step_by(2).map(|k: usize| k.to_string()).collect();
    println!("chart,step,{}", ks.join(","));
    for (name, hs) in [("gmres_jacobi", &hist), ("jacobi", &jh), ("gmres_plain", &hist0)] {
        let p: Vec<String> = (0..21).step_by(2).map(|k: usize| format!("{:.2}", hs[k].log10())).collect();
        println!("chart,{},{}", name, p.join(","));
    }
    println!("ALL CHECKS PASS");
}
