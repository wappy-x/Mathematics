// Galerkin and finite elements -- the same check as the Python, in Rust.  No crates.  An L-shaped
// floor slab, 6 m x 5 m less the corner x > 4 m, y > 2.5 m; a mat puts in p = 2 W/m^2 through
// b = 0.1 m of concrete with k = 2 W/(m K) (illustrative).  The rise u above the 5 C edges solves
// -Laplacian(u) = f = p/(k b), u = 0 on the edges.  Nothing imported solves anything.
use std::f64::consts::PI;
const F: f64 = 2.0 / (2.0 * 0.1);                   // f = 10 K/m^2
const HS: [f64; 5] = [0.5, 0.25, 0.125, 0.0625, 0.03125];
const SIDES: [(i64, i64); 6] = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1)];
type Tri = [(i64, i64); 3];
type Mat = Vec<Vec<(usize, f64)>>;
struct Level { h: f64, nx: i64, ny: i64, nodes: Vec<(i64, i64)>, idx: Vec<i64>, inner: Vec<(i64, i64)>, tris: Vec<Tri>, a: f64 }
impl Level {
    fn id(&self, i: i64, j: i64) -> Option<usize> { if i < 0 || j < 0 || i > self.nx || j > self.ny { None } else { Some((i * (self.ny + 1) + j) as usize) } }
    fn get(&self, v: &[f64], i: i64, j: i64) -> f64 { self.id(i, j).map_or(0.0, |k| v[k]) }
    fn grid(&self) -> Vec<f64> { vec![0.0; ((self.nx + 1) * (self.ny + 1)) as usize] }
}
fn psum<I: Iterator<Item = f64>>(it: I) -> f64 {   // compensated sum, the rule Python's sum() uses
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; c += if s.abs() >= x.abs() { (s - t) + x } else { (x - t) + s }; s = t }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn level(h: f64, notch: bool) -> Level {           // the mesh: nodes, numbered unknowns, triangles
    let (nx, ny) = ((6.0 / h).round() as i64, (5.0 / h).round() as i64);
    let cell = |i: i64, j: i64| 0 <= i && i < nx && 0 <= j && j < ny && !(notch && i as f64 * h >= 4.0 && j as f64 * h >= 2.5);
    let (mut nodes, mut inner, mut tris, mut idx) = (vec![], vec![], vec![], vec![-1i64; ((nx + 1) * (ny + 1)) as usize]);
    for i in 0..=nx { for j in 0..=ny {
        let c = [cell(i, j), cell(i, j - 1), cell(i - 1, j), cell(i - 1, j - 1)];
        if c.iter().any(|&x| x) { nodes.push((i, j)) }
        if c.iter().all(|&x| x) { idx[(i * (ny + 1) + j) as usize] = inner.len() as i64; inner.push((i, j)) }
    } }
    for i in 0..nx { for j in (0..ny).filter(|&j| cell(i, j)) { tris.extend([[(i, j), (i + 1, j), (i + 1, j + 1)], [(i, j), (i + 1, j + 1), (i, j + 1)]]) } }
    Level { h, nx, ny, nodes, idx, inner, a: h * h * tris.len() as f64 / 2.0, tris }
}
fn element(h: f64, t: &Tri) -> ([[f64; 3]; 3], f64) {   // one triangle's stiffness, from its corners
    let x: Vec<(f64, f64)> = t.iter().map(|&(a, b)| (a as f64 * h, b as f64 * h)).collect();
    let a2 = (x[1].0 - x[0].0) * (x[2].1 - x[0].1) - (x[2].0 - x[0].0) * (x[1].1 - x[0].1);
    let g: Vec<(f64, f64)> = (0..3).map(|k| ((x[(k + 1) % 3].1 - x[(k + 2) % 3].1) / a2, (x[(k + 2) % 3].0 - x[(k + 1) % 3].0) / a2)).collect();
    (std::array::from_fn(|p| std::array::from_fn(|q| a2 / 2.0 * (g[p].0 * g[q].0 + g[p].1 * g[q].1))), a2 / 2.0)
}
fn assemble(l: &Level, idx: &[i64], n: usize, share: f64, scale: f64) -> (Mat, Vec<f64>) {  // road 1
    let (mut k, mut b): (Mat, Vec<f64>) = (vec![vec![]; n], vec![0.0; n]);
    for t in &l.tris {
        let (ke, area) = element(l.h, t);
        let ix: Vec<i64> = t.iter().map(|&(i, j)| idx[l.id(i, j).unwrap()]).collect();
        for p in (0..3).filter(|&p| ix[p] >= 0) {
            let r = ix[p] as usize;
            b[r] += F * area / share;
            for (q, c) in (0..3).filter(|&q| ix[q] >= 0).map(|q| (q, ix[q] as usize)) {
                match k[r].iter_mut().find(|e| e.0 == c) { Some(e) => e.1 += ke[p][q] * scale, None => k[r].push((c, ke[p][q] * scale)) }
    } } }
    (k, b)
}
fn stencil(l: &Level, r: usize, c: usize) -> f64 {  // road 2: the 5-point stencil, written directly
    let ((i, j), (a, b)) = (l.inner[r], l.inner[c]);
    if r == c { 4.0 } else if (i - a).abs() + (j - b).abs() == 1 { -1.0 } else { 0.0 }
}
fn cg(k: &Mat, b: &[f64]) -> (Vec<f64>, usize) {     // conjugate gradients, written out
    let (n, stop) = (b.len(), psum(b.iter().map(|v| v * v)));
    let (mut x, mut r, mut p, mut it, mut rr) = (vec![0.0; n], b.to_vec(), b.to_vec(), 0, stop);
    while rr > 1e-26 * stop {
        let ap: Vec<f64> = k.iter().map(|row| psum(row.iter().map(|&(c, v)| v * p[c]))).collect();
        let al = rr / psum((0..n).map(|q| p[q] * ap[q]));
        for q in 0..n { x[q] += al * p[q]; r[q] -= al * ap[q] }
        let rn = psum(r.iter().map(|v| v * v));
        for q in 0..n { p[q] = r[q] + rn / rr * p[q] }
        (rr, it) = (rn, it + 1);
    }
    (x, it)
}
fn prolong(c: &Level, v: &[f64], f: &Level) -> Vec<f64> {   // a coarse broken surface on the halved mesh
    let mut out = f.grid();
    for &(i, j) in &f.nodes { out[f.id(i, j).unwrap()] = (c.get(v, i / 2, j / 2) + c.get(v, (i + 1) / 2, (j + 1) / 2)) / 2.0 }
    out
}
fn restrict(f: &Level, r: &[f64], c: &Level) -> Vec<f64> {   // its transpose, onto the coarse hats
    let mut out = c.grid();
    for &(i, j) in &c.inner {
        out[c.id(i, j).unwrap()] = f.get(r, 2 * i, 2 * j) + psum(SIDES.iter().map(|&(a, b)| f.get(r, 2 * i + a, 2 * j + b))) / 2.0;
    }
    out
}
fn edge_energy(l: &Level, v: &[f64], present: &[bool]) -> f64 {  // a(w, w) = sum of squared edge jumps
    psum(l.nodes.iter().flat_map(|&(i, j)| [(1, 0), (0, 1)].into_iter().filter_map(move |(a, b)| l.id(i + a, j + b)
        .filter(|&q| present[q]).map(|q| (v[q] - v[l.id(i, j).unwrap()]).powi(2)))))
}
fn series(a: f64, b: f64, n: i64) -> (f64, f64) {   // exact energy of the a x b rectangle: sine series
    let e = psum((1..=n).step_by(2).flat_map(|m| (1..=n).step_by(2).map(move |k| { let (m, k) = (m as f64, k as f64);
        64.0 * F * F * a * b / (PI.powi(6) * m * m * k * k * (m * m / (a * a) + k * k / (b * b))) })));
    (e, 64.0 * F * F * a * b / PI.powi(4) / 8.0 * (a * a + b * b) / (6.0 * ((n - 1) as f64).powi(3)))
}
fn peak(u: &[f64]) -> usize { (0..u.len()).fold(0, |m, q| if u[q] > u[m] { q } else { m }) }
fn j(v: Vec<String>) -> String { v.join(", ") }
fn main() {
    let l0 = level(0.5, true); let (ke, area) = element(0.5, &l0.tris[0]);
    println!("slab area {:.1} m^2, f = p/(k b) = {:.1} K/m^2", l0.a, F);
    let rows: Vec<String> = ke.iter().map(|r| r.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(" ")).collect();
    println!("element, legs 0.5 m: {} ; load per corner {:.5} K", rows.join(" / "), F * area / 3.0);
    let n0 = l0.inner.len(); let (k0, b0) = assemble(&l0, &l0.idx, n0, 3.0, 1.0);
    let entry = |r: usize, c: usize| k0[r].iter().find(|e| e.0 == c).map_or(0.0, |e| e.1);
    let gap = (0..n0 * n0).map(|q| (entry(q / n0, q % n0) - stencil(&l0, q / n0, q % n0)).abs()).fold(0.0, f64::max);
    let lgap = b0.iter().map(|v| (v - F * 0.25).abs()).fold(0.0, f64::max);
    println!("200 triangles: {} nodes, {} unknowns; row 40: diagonal {:.1}, side {:.1}, load {:.2} K; gap to the stencil {:.1}, load gap {:.1}",
             l0.nodes.len(), n0, entry(40, 40), entry(40, 41), b0[40], gap, lgap);
    let mut runs: Vec<(Level, Mat, Vec<f64>, f64, usize)> = vec![];
    for (name, notch) in [("L", true), ("rect", false)] { for &h in HS.iter() {
        let l = level(h, notch); let (k, b) = assemble(&l, &l.idx, l.inner.len(), 3.0, 1.0);
        let (u, it) = cg(&k, &b); let (m, e) = (peak(&u), psum((0..b.len()).map(|q| b[q] * u[q])));
        println!("{:4} {:5} triangles, h {:.5} m: {:5} unknowns, CG {:3} steps, energy {:.4} K^2, mean rise {:.4} K, peak {:.4} K at ({:.4}, {:.4}) m",
                 name, l.tris.len(), h, b.len(), it, e, e / (F * l.a), u[m], l.inner[m].0 as f64 * h, l.inner[m].1 as f64 * h);
        runs.push((l, k, u, e, m));
    } }
    let (ex, tail) = series(6.0, 5.0, 399);
    println!("rect by sine series: energy {:.4} K^2, tail below {:.6} K^2; true errors {} K", ex, tail,
             j((5..10).map(|q| format!("{:.4}", (ex - runs[q].3).sqrt())).collect()));
    let mut order = vec![]; for (s, name) in [(0, "L"), (5, "rect")] {
        let d: Vec<f64> = (0..4).map(|q| runs[s + q + 1].3 - runs[s + q].3).collect();
        let o: Vec<f64> = (0..3).map(|q| 0.5 * (d[q] / d[q + 1]).log2()).collect();
        println!("{:4} step norms sqrt(dE): {} K; observed orders {}", name, j(d.iter().map(|x| format!("{:.4}", x.sqrt())).collect()),
                 j(o.iter().map(|x| format!("{:.3}", x)).collect()));
        println!("chart, {}, log10 h: {}; log10 step norm: {}", name, j(HS[..4].iter().map(|h| format!("{:.2}", h.log10())).collect()),
                 j(d.iter().map(|x| format!("{:.2}", x.sqrt().log10())).collect()));
        order.push(o[2]);
    }
    let ext = |s: usize, p: f64| runs[s + 4].3 + (runs[s + 4].3 - runs[s + 3].3) / (2f64.powf(2.0 * p) - 1.0);
    let (ext_l, ext_r) = (ext(0, 2.0 / 3.0), ext(5, 1.0));
    println!("extrapolated energy: rect {:.4} K^2 (series {:.4}), L {:.3} K^2", ext_r, ex, ext_l);
    let ((lc, uc, ec, mc), (lf, kf, uf, ef)) = ((&runs[0].0, &runs[0].2, runs[0].3, runs[0].4), (&runs[4].0, &runs[4].1, &runs[4].2, runs[4].3));
    let full = |l: &Level, u: &[f64]| { let mut v = l.grid(); for (q, &(i, j)) in l.inner.iter().enumerate() { v[l.id(i, j).unwrap()] = u[q] } v };
    let (vf, vc) = (full(lf, uf), full(lc, uc));
    let (mut present, mut interp) = (vec![false; vf.len()], lc.grid());
    for &(i, j) in &lf.nodes { present[lf.id(i, j).unwrap()] = true }
    for &(i, j) in &lc.nodes { interp[lc.id(i, j).unwrap()] = lf.get(&vf, 16 * i, 16 * j) }
    let mut res = vec![];
    for mut v in [vc.clone(), interp] {
        for q in 1..5 { v = prolong(&runs[q - 1].0, &v, &runs[q].0) }
        let w: Vec<f64> = (0..vf.len()).map(|q| vf[q] - v[q]).collect();
        let mut r = lf.grid();
        for (q, &(i, j)) in lf.inner.iter().enumerate() { r[lf.id(i, j).unwrap()] = psum(kf[q].iter().map(|&(c, x)| x * w[lf.id(lf.inner[c].0, lf.inner[c].1).unwrap()])) }
        for q in (0..4).rev() { r = restrict(&runs[q + 1].0, &r, &runs[q].0) }
        res.push((edge_energy(lf, &w, &present).sqrt(), r.iter().map(|x| x.abs()).fold(0.0, f64::max)));
    }
    println!("Cea at 200 triangles, against 51200: Galerkin error {:.4} K (sqrt(E_f - E_h) = {:.4} K), interpolant error {:.4} K",
             res[0].0, (ef - ec).sqrt(), res[1].0);
    let (i, jj) = lc.inner[mc];
    let nb = [(i - 1, jj), (i + 1, jj), (i, jj - 1), (i, jj + 1)].map(|(a, b)| lc.get(&vc, a, b));
    println!("hottest node row: 4 x {:.4} - ({}) = {:.4} K", uc[mc], nb.map(|x| format!("{:.4}", x)).join(" + "), 4.0 * uc[mc] - psum(nb.into_iter()));
    println!("orthogonality, largest a(error, coarse hat): Galerkin {:.4} K, interpolant {:.4} K", res[0].1, res[1].1);
    let ng = lc.inner.iter().map(|&(a, b)| (lc.get(&vc, a, b) - lf.get(&vf, 16 * a, 16 * b)).abs()).fold(0.0, f64::max);
    println!("node values not exact: largest gap at the 79 nodes {:.4} K", ng);
    println!("estimated true error at 200 triangles {:.3} K, {:.1} % of {:.3} K", (ext_l - ec).sqrt(), 100.0 * ((ext_l - ec) / ext_l).sqrt(), ext_l.sqrt());
    let lam = PI.powi(2) * (1.0 / 36.0 + 1.0 / 25.0);
    println!("Lax-Milgram: lambda1 of the 6 m x 5 m box {:.5} /m^2, C_P^2 <= {:.4} m^2, M = 1, alpha >= {:.4}, Cea factor M/alpha <= {:.4}",
             lam, 1.0 / lam, 1.0 / (1.0 + 1.0 / lam), 1.0 + 1.0 / lam);
    let mut all = vec![-1i64; lc.idx.len()];
    for (q, &(i, j)) in lc.nodes.iter().enumerate() { all[lc.id(i, j).unwrap()] = q as i64 }
    let (ka, ba) = assemble(lc, &all, lc.nodes.len(), 3.0, 1.0);
    let rs = ka.iter().map(|r| psum(r.iter().map(|e| e.1)).abs()).fold(0.0, f64::max);
    println!("mistake, edges not held: largest row sum {:.1}, load sum {:.1} K", rs, psum(ba.into_iter()));
    let solve = |l: &Level, share: f64, scale: f64| { let (k, b) = assemble(l, &l.idx, l.inner.len(), share, scale); let u = cg(&k, &b).0; u[peak(&u)] };
    for h in [0.5, 0.25] { let l = level(h, true);
        println!("mistake, 1/h scaling from the cable card: peak {:.4} K at {} triangles", solve(&l, 3.0, 1.0 / h), l.tris.len()) }
    println!("mistake, whole triangle load on each corner: peak {:.4} K", solve(lc, 1.0, 1.0));
    println!("figure, corner (4.00, 2.50) m, hottest node at 200 triangles ({:.2}, {:.2}) m, {:.2} C", i as f64 * 0.5, jj as f64 * 0.5, 5.0 + uc[mc]);
    assert!(gap < 1e-12 && lgap < 1e-12);                                    // road 1 = road 2
    assert!((res[0].0.powi(2) - (ef - ec)).abs() < 1e-6 * (ef - ec));       // edge sum = Pythagoras
    assert!(res[0].0 < res[1].0 && res[0].1 < 1e-8 && 1e-8 < res[1].1);      // Cea and orthogonality
    assert!((5..10).all(|q| ex - runs[q].3 > 0.0) && (ext_r - ex).abs() < 1e-3);   // series road
    assert!(0.6 < order[0] && order[0] < 0.9 && (order[1] - 1.0).abs() < 0.01);    // the corner costs order
    println!("ALL CHECKS PASS");
}
