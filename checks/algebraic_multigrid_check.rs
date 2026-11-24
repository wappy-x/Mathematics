// Algebraic multigrid -- the check behind the card.  Rust std only.  A Ruge-Stuben hierarchy
// from the matrix alone, on a pipe network and an anisotropic plate, against geometric MG, IC(0) and CG.
use std::{cmp::Reverse, collections::{BTreeMap, BinaryHeap}, f64::consts::PI};
type Row = Vec<(usize, f64)>; type Mat = Vec<Row>; type Map = BTreeMap<usize, f64>;
type Lv = Vec<(Mat, Option<Mat>)>; type Ic = Vec<(Map, f64)>; type Hier = (Lv, Ic, usize);
fn nxt(st: &mut u64) -> u64 { // SplitMix64, written out
    *st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = (*st ^ (*st >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31)
}
fn sci(v: f64) -> String { format!("{:.3e}", v) }
fn commas(v: usize) -> String {
    let d = v.to_string(); d.chars().enumerate().map(|(i, ch)| if i > 0 && (d.len() - i) % 3 == 0 { format!(",{}", ch) } else { ch.to_string() }).collect()
}
fn rdot(r: &[(usize, f64)], x: &[f64]) -> f64 { let mut acc = 0.0; for &(j, a) in r { acc += a * x[j]; } acc }
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut acc = 0.0; for j in 0..u.len() { acc += u[j] * v[j]; } acc }
fn mv(a: &Mat, x: &[f64]) -> Vec<f64> { a.iter().map(|r| rdot(r, x)).collect() }
fn nnz(a: &Mat) -> usize { a.iter().map(|r| r.len()).sum() }
fn rows(d: Vec<Map>) -> Mat { d.into_iter().map(|r| r.into_iter().collect()).collect() }
fn get(r: &Row, i: usize) -> f64 { r.iter().find(|e| e.0 == i).map_or(0.0, |e| e.1) }
fn sub(b: &[f64], a: &[f64]) -> Vec<f64> { b.iter().zip(a).map(|(u, v)| u - v).collect() }
fn fmax(v: impl Iterator<Item = f64>) -> f64 { v.fold(f64::MIN, f64::max) }
fn strong(a: &Mat, th: f64) -> Vec<Vec<usize>> { // j is strong for i if -a_ij >= th * (largest -a_ik)
    a.iter().enumerate().map(|(i, r)| { let big = fmax(r.iter().filter(|e| e.0 != i).map(|e| -e.1));
        r.iter().filter(|e| e.0 != i && big > 0.0 && -e.1 >= th * big).map(|e| e.0).collect() }).collect()
}
fn split(s: &[Vec<usize>]) -> Vec<usize> { // Ruge-Stuben first pass: 1 = C point, 0 = F point, 2 = undecided
    let n = s.len(); let (mut st, mut cf) = (vec![vec![]; n], vec![2usize; n]);
    for i in 0..n { for &j in &s[i] { st[j].push(i); } } // st[j]: depend strongly on j
    let mut lam: Vec<i64> = st.iter().map(|t| t.len() as i64).collect();
    let mut heap: BinaryHeap<Reverse<(i64, usize)>> = (0..n).map(|i| Reverse((-lam[i], i))).collect();
    let bump = |k: usize, d: i64, lam: &mut Vec<i64>, heap: &mut BinaryHeap<_>| { lam[k] += d; heap.push(Reverse((-lam[k], k))); };
    while let Some(Reverse((l, i))) = heap.pop() {
        if cf[i] != 2 || -l != lam[i] { continue; } cf[i] = 1;
        for j in st[i].iter().copied().filter(|&j| cf[j] == 2).collect::<Vec<_>>() {
            cf[j] = 0; for &k in &s[j] { if cf[k] == 2 { bump(k, 1, &mut lam, &mut heap); } } }
        for &k in &s[i] { if cf[k] == 2 { bump(k, -1, &mut lam, &mut heap); } }
    }
    cf
}
fn interp(a: &Mat, s: &[Vec<usize>], cf: &[usize], scale: bool) -> (Mat, usize) { // direct interpolation, Stuben (2001)
    let ci: Vec<usize> = (0..cf.len()).scan(0, |c, i| { *c += cf[i]; Some(*c - cf[i]) }).collect();
    let p = a.iter().enumerate().map(|(i, r)| { if cf[i] == 1 { return vec![(ci[i], 1.0)]; }
        let pi: Vec<usize> = s[i].iter().copied().filter(|&j| cf[j] == 1).collect(); let (mut neg, mut negp, mut dg) = (0.0, 0.0, 0.0);
        for &(j, v) in r { if j == i || v > 0.0 { dg += v; } else { neg += v; if pi.contains(&j) { negp += v; } } } // positive: diagonal
        let al = if scale { neg / negp } else { 1.0 };
        r.iter().filter(|e| pi.contains(&e.0)).map(|&(j, v)| (ci[j], -al * v / dg)).collect() }).collect();
    (p, cf.iter().sum())
}
fn rap(a: &Mat, p: &Mat, nc: usize) -> (Mat, usize) { // Galerkin coarse matrix P^T A P, and its flops
    let (mut ac, mut fl) = (vec![Map::new(); nc], 0usize);
    for (i, r) in a.iter().enumerate() { let mut d = Map::new();
        for &(j, v) in r { for &(jj, w) in &p[j] { *d.entry(jj).or_insert(0.0) += v * w; fl += 2; } }
        for &(ii, q) in &p[i] { for (&jj, &v) in &d { *ac[ii].entry(jj).or_insert(0.0) += q * v; fl += 2; } } }
    (rows(ac), fl)
}
fn setup(a: Mat, ps: Option<&Vec<(Mat, usize)>>, th: f64, scale: bool) -> Hier { // ps given: geometric coarsening
    let (mut lv, mut fl): (Lv, usize) = (vec![(a, None)], 0);
    while lv.last().unwrap().0.len() > 50 && ps.map_or(true, |q| lv.len() <= q.len()) {
        let a = &lv.last().unwrap().0; let s = strong(a, th);
        let (p, nc) = match ps { Some(q) => q[lv.len() - 1].clone(), None => interp(a, &s, &split(&s), scale) };
        let (ac, f) = rap(a, &p, nc); fl += f; lv.last_mut().unwrap().1 = Some(p); lv.push((ac, None)); }
    let last = &lv.last().unwrap().0; let full: Mat = last.iter().map(|r| (0..last.len()).map(|j| (j, get(r, j))).collect()).collect();
    let l = ic0(&full); (lv, l, fl) // IC(0) of a full matrix: exact
}
fn ic0(a: &Mat) -> Ic { // incomplete Cholesky: keep A's own nonzeros only
    let mut l: Ic = vec![];
    for (i, r) in a.iter().enumerate() { let mut row = Map::new();
        for &(k, v) in r.iter().filter(|e| e.0 < i) {
            let mut acc = 0.0; for (j, w) in &row { if let Some(x) = l[k].0.get(j) { acc += w * x; } } row.insert(k, (v - acc) / l[k].1); }
        let mut acc = 0.0; for (_, w) in &row { acc += w * w; } l.push((row, (get(r, i) - acc).sqrt())); }
    l
}
fn icsolve(l: &Ic, r: &[f64]) -> Vec<f64> { // L y = r, then L^T z = y
    let mut y = r.to_vec();
    for i in 0..r.len() { let mut acc = 0.0; for (&j, &w) in &l[i].0 { acc += w * y[j]; } y[i] = (y[i] - acc) / l[i].1; }
    for i in (0..r.len()).rev() { y[i] /= l[i].1; for (&k, &w) in &l[i].0 { y[k] -= w * y[i]; } } y
}
fn gs(a: &Mat, x: &mut [f64], b: &[f64], fwd: bool) { // one Gauss-Seidel sweep
    for t in 0..a.len() { let i = if fwd { t } else { a.len() - 1 - t };
        let mut acc = 0.0; for &(j, v) in &a[i] { if j != i { acc += v * x[j]; } } x[i] = (b[i] - acc) / get(&a[i], i); }
}
fn vcyc(h: &Hier, b: &[f64], l: usize) -> Vec<f64> { // one V-cycle, starting from x = 0
    let (a, p) = (&h.0[l].0, match &h.0[l].1 { None => return icsolve(&h.1, b), Some(p) => p }); // coarsest: exact
    let mut x = vec![0.0; a.len()]; gs(a, &mut x, b, true); let r = sub(b, &mv(a, &x)); let mut rc = vec![0.0; h.0[l + 1].0.len()];
    for i in 0..a.len() { for &(ii, w) in &p[i] { rc[ii] += w * r[i]; } }
    let ec = vcyc(h, &rc, l + 1); for i in 0..a.len() { x[i] += rdot(&p[i], &ec); }
    gs(a, &mut x, b, false); x
}
fn pcg(a: &Mat, b: &[f64], m: &dyn Fn(&[f64]) -> Vec<f64>) -> (Vec<f64>, Vec<f64>) { // preconditioned conjugate gradient
    let (mut x, mut r) = (vec![0.0; b.len()], b.to_vec()); let z = m(&r); let mut p = z.clone(); let (mut rz, nb, mut h) = (dot(&r, &z), dot(b, b).sqrt(), vec![1.0]);
    while h[h.len() - 1] >= 1e-8 && h.len() <= 2 * b.len() { // CG needs at most n steps without rounding; allow 2n
        let q = mv(a, &p); let al = rz / dot(&p, &q); x = x.iter().zip(&p).map(|(u, v)| u + al * v).collect(); r = r.iter().zip(&q).map(|(u, v)| u - al * v).collect();
        let z = m(&r); let rz2 = dot(&r, &z); let be = rz2 / rz; p = z.iter().zip(&p).map(|(u, v)| u + be * v).collect(); rz = rz2;
        h.push(dot(&r, &r).sqrt() / nb); }
    assert!(h[h.len() - 1] < 1e-8, "CG did not converge"); (x, h)
}
fn vfactor(a: &Mat, b: &[f64], h: &Hier) -> f64 { // V-cycles alone: residual factor per cycle
    let (mut x, mut r) = (vec![0.0; b.len()], vec![]);
    for _ in 0..11 { r = sub(b, &mv(a, &x)); let e = vcyc(h, &r, 0); x = x.iter().zip(&e).map(|(u, v)| u + v).collect(); }
    (dot(&r, &r).sqrt() / dot(b, b).sqrt()).powf(1.0 / 10.0)
}
fn vflops(lv: &Lv) -> usize { lv[..lv.len() - 1].iter().map(|(a, p)| 6 * nnz(a) + 4 * nnz(p.as_ref().unwrap()) + 2 * a.len()).sum::<usize>() + 2 * lv[lv.len() - 1].0.len().pow(2) }
fn levels(lv: &Lv) -> String { lv.iter().map(|l| l.0.len().to_string()).collect::<Vec<_>>().join("/") }
fn network(st: &mut u64) -> (Mat, Vec<f64>) { // 10 rows of 25 junctions, 465 + 35 pipes
    let (mut d, mut b): (Vec<Map>, Vec<f64>) = ((0..250).map(|i| Map::from([(i, 0.1)])).collect(), vec![0.0; 250]); // customers: 0.1 L/s per metre
    for i in 0..250usize {
        let mut js: Vec<usize> = [(i + 1, i % 25 < 24), (i + 25, i < 225)].iter().filter(|e| e.1).map(|e| e.0).collect();
        js.extend(vec![usize::MAX; (i < 25) as usize + (i % 25 == 0) as usize]);
        for j in js { let g = [0.5, 1.0, 2.0, 4.0][(nxt(st) % 4) as usize]; *d[i].get_mut(&i).unwrap() += g; // pipe sizes, L/s per metre
            if j == usize::MAX { b[i] += 50.0 * g; } else { *d[j].get_mut(&j).unwrap() += g; d[i].insert(j, -g); d[j].insert(i, -g); } } // feed: 50 m main
    }
    (rows(d), b)
}
fn plate(n: usize, e: f64) -> (Mat, Vec<f64>) { // conductivity 1 along x, e along y; heater at centre
    let mut d: Vec<Map> = (0..n * n).map(|k| Map::from([(k, 2.0 + 2.0 * e)])).collect(); let mut b = vec![0.0; n * n]; b[n * n / 2] = 1.0;
    for k in 0..n * n { for (m, c, ok) in [(k.wrapping_sub(1), 1.0, k % n > 0), (k + 1, 1.0, k % n < n - 1), (k.wrapping_sub(n), e, k >= n), (k + n, e, k < n * n - n)] {
        if ok { d[k].insert(m, -c); } } }
    (rows(d), b)
}
fn geo(mut nn: usize) -> Vec<(Mat, usize)> { // bilinear interpolation, every other point both ways
    let mut ps = vec![];
    while nn * nn > 50 { let n = (nn - 1) / 2;
        let w1 = |i: usize| -> Row { if i % 2 == 1 { vec![((i - 1) / 2, 1.0)] } else { [i / 2, i / 2 + 1].iter().filter(|&&k| k >= 1 && k <= n).map(|&k| (k - 1, 0.5)).collect() } };
        ps.push(((0..nn * nn).map(|k| { let mut r: Row = w1(k / nn).iter().flat_map(|&(jj, a)| w1(k % nn).into_iter().map(move |(ii, c)| (jj * n + ii, a * c))).collect();
            r.sort_by(|u, v| u.0.cmp(&v.0)); r }).collect(), n * n)); nn = n; }
    ps
}
fn mu(e: f64) -> f64 { // Gauss-Seidel smoothing factor over high frequencies
    let cs: Vec<(f64, f64, bool)> = (-128i32..128).map(|p| ((p as f64 * PI / 128.0).cos(), (p as f64 * PI / 128.0).sin(), p.abs() >= 64)).collect();
    fmax(cs.iter().flat_map(|&(c1, s1, h1)| cs.iter().filter(move |c| h1 || c.2).map(move |&(c2, s2, _)|
        (((c1 + e * c2).powi(2) + (s1 + e * s2).powi(2)) / ((2.0 + 2.0 * e - c1 - e * c2).powi(2) + (s1 + e * s2).powi(2))).sqrt())))
}
fn three(a: &Mat, b: &[f64], h: &Hier) -> Vec<(Vec<f64>, Vec<f64>)> { // plain CG, IC(0)-CG, AMG-CG
    let l = ic0(a); vec![pcg(a, b, &|r: &[f64]| r.to_vec()), pcg(a, b, &|r: &[f64]| icsolve(&l, r)), pcg(a, b, &|r: &[f64]| vcyc(h, r, 0))]
}
fn main() {
    let (mut st, a3): (u64, Mat) = (20261124, vec![vec![(0, 4.6), (1, -4.0), (2, -0.5)], vec![(0, -4.0), (1, 4.1)], vec![(0, -0.5), (2, 0.6)]]);
    let s3 = strong(&a3, 0.25); let (p3, _) = interp(&a3, &s3, &[0, 1, 1], true); let w = (4.5 / 4.0) * 4.0 / 4.6;
    println!("hand,cut={:.2},junction1_strong_to={},alpha={:.4},weight={:.6},code={:.6}", 0.25 * 4.0, s3[0].iter().map(|j| (j + 1).to_string()).collect::<Vec<_>>().join("+"), 4.5 / 4.0, w, p3[0][0].1);
    let ms: Vec<f64> = [1.0, 0.1, 0.01, 0.001].iter().map(|&e| mu(e)).collect();
    println!("smoothing,eps=1/0.1/0.01/0.001,gauss_seidel_mu={}", ms.iter().map(|m| format!("{:.4}", m)).collect::<Vec<_>>().join("/"));
    assert!(s3[0] == vec![1] && (p3[0][0].1 - w).abs() < 1e-15 && (ms[0] - 0.5).abs() < 1e-3 && ms[2..].iter().zip([0.01, 0.001]).all(|(m, e)| (m - (1.0 - 2.0 * e)).abs() < 5.0 * e * e));
    let (a, b) = network(&mut st); let h = setup(a.clone(), None, 0.25, true); let runs = three(&a, &b, &h); let x = &runs[2].0; // no grid used
    let r = sub(&b, &mv(&a, x)); let tr = (dot(&r, &r) / dot(&b, &b)).sqrt(); let gap = fmax(runs[..2].iter().flat_map(|(y, _)| y.iter().zip(x).map(|(u, v)| (u - v).abs())));
    println!("network,junctions={},nonzeros={},levels={},operator_complexity={:.3},vcycle_factor={:.4}", a.len(), nnz(&a), levels(&h.0),
             h.0.iter().map(|l| nnz(&l.0)).sum::<usize>() as f64 / nnz(&a) as f64, vfactor(&a, &b, &h));
    println!("network,cg_steps_plain/ic0/amg={}/{}/{},true_residual={},max_gap_m={},heads_m={:.4}..{:.4}", runs[0].1.len() - 1, runs[1].1.len() - 1, runs[2].1.len() - 1,
             sci(tr), sci(gap), fmax(x.iter().cloned()), -fmax(x.iter().map(|v| -v)));
    assert!(tr < 1.01e-8 && gap < 1e-4 && runs[2].1.len() < runs[1].1.len() && runs[1].1.len() < runs[0].1.len());
    let g63 = geo(63); let mut fac = BTreeMap::new();
    for (e, name, ps, th, sc) in [("0.01", "amg", None, 0.25, true), ("0.01", "geometric", Some(&g63), 0.25, true), ("0.01", "theta_0", None, 0.0, true),
                                  ("0.01", "no_alpha", None, 0.25, false), ("1", "amg", None, 0.25, true), ("1", "geometric", Some(&g63), 0.25, true)] {
        let (a, b) = plate(63, e.parse().unwrap()); let h = setup(a.clone(), ps, th, sc); let f = vfactor(&a, &b, &h);
        fac.insert((e, name), f); println!("plate63,eps={},{},levels={},vcycle_factor={:.4}", e, name, levels(&h.0), f); }
    assert!(fac[&("0.01", "amg")] < 0.3 && 0.3 < fac[&("0.01", "geometric")] && fac[&("1", "amg")].max(fac[&("1", "geometric")]) < 0.3 && fac[&("0.01", "theta_0")] > 2.0 * fac[&("0.01", "amg")]);
    let (a, _) = plate(63, 0.01); let h = setup(a.clone(), None, 0.25, true); let s = strong(&a, 0.25); let cf = split(&s); let (p, _) = interp(&a, &s, &cf, true);
    let (one, ncf, ns) = (vec![1.0; a.len()], cf.iter().sum::<usize>(), s.iter().map(|v| v.len()).sum::<usize>());
    let ones: Vec<f64> = (0..a.len()).filter(|&i| cf[i] == 0 && rdot(&a[i], &one).abs() < 1e-12).map(|i| (rdot(&p[i], &one) - 1.0).abs()).collect(); let mo = fmax(ones.iter().cloned());
    let asym = fmax(h.0.iter().flat_map(|(ac, _)| (0..ac.len()).flat_map(move |i| ac[i].iter().map(move |&(j, v)| (get(&ac[j], i) - v).abs()))));
    println!("plate63,first_level,C={},F={},strong_per_row={:.3},zero_sum_F_rows={},max_weight_sum_minus_1={},coarse_asymmetry={}", ncf, a.len() - ncf, ns as f64 / s.len() as f64, ones.len(), sci(mo), sci(asym));
    assert!(mo < 1e-12 && asym < 1e-12 && ns == 2 * 63 * 62);
    for nn in [31usize, 63, 127] {
        let (a, b) = plate(nn, 0.01); let h = setup(a.clone(), None, 0.25, true); let runs = three(&a, &b, &h); let (n, z) = (a.len(), nnz(&a));
        let k: Vec<usize> = runs.iter().map(|r| r.1.len() - 1).collect(); let (base, vf) = (2 * z + 10 * n, vflops(&h.0));
        let fl: Vec<f64> = [k[0] * base, k[1] * (base + 2 * z), k[2] * (base + vf) + h.2].iter().map(|&f| f as f64 / n as f64).collect();
        println!("plate,N={},unknowns={},cg_steps={}/{}/{},flops_per_unknown={:.0}/{:.0}/{:.0},amg_setup={},vcycle={}", nn, n, k[0], k[1], k[2], fl[0], fl[1], fl[2], commas(h.2), commas(vf));
        let xm = fmax(runs[2].0.iter().cloned()); assert!(k[2] <= 10 && 10 < k[1] && k[1] < k[0] && runs[1].0.iter().zip(&runs[2].0).all(|(u, v)| (u - v).abs() < 1e-6 * xm)); }
    println!("ALL CHECKS PASS");
}
