// Manifold learning check: Isomap on 600 photos of one guitar under changing light.
// Rust std only. Random numbers come from SplitMix64, written out below.
use std::cmp::Reverse;
use std::collections::BinaryHeap;
use std::f64::consts::PI;

const T0: f64 = 1.5 * PI; const T1: f64 = 4.5 * PI; const HMAX: f64 = 12.0; // lamp 270-810 deg; fill 0-12

struct Rng(u64);
impl Rng {
    fn rand(&mut self) -> f64 { // SplitMix64: a float in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { // Box-Muller: one standard normal draw
        let (u1, u2) = (self.rand(), self.rand());
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}
// Compensated (Neumaier) sum, the rule Python's built-in sum() uses for floats.
fn ns<I: IntoIterator<Item = f64>>(it: I) -> f64 {
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it {
        let t = s + x;
        if s.abs() >= x.abs() { c += (s - t) + x; } else { c += (x - t) + s; }
        s = t;
    }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn dot(a: &[f64], b: &[f64]) -> f64 { ns(a.iter().zip(b).map(|(x, y)| x * y)) }
type Data = (Vec<(f64, f64)>, Vec<Vec<f64>>);
fn make(n: usize, sigma: f64) -> Data { // 13 probe photos (fill 6), then random knob settings
    let mut g = Rng(2026);
    let px: Vec<f64> = (0..24).map(|i| ((i % 6) as f64 - 2.5) / 70f64.sqrt()).collect();
    let py: Vec<f64> = (0..24).map(|i| (1.5 - (i / 6) as f64) / 30f64.sqrt()).collect();
    let pz = 1.0 / 24f64.sqrt();
    let mut knobs: Vec<(f64, f64)> = (0..13).map(|j| (T0 + j as f64 * PI / 4.0, HMAX / 2.0)).collect();
    while knobs.len() < n {
        let t = (T0 * T0 + (T1 * T1 - T0 * T0) * g.rand()).sqrt(); knobs.push((t, HMAX * g.rand()));
    }
    let ph = knobs.iter().map(|&(t, h)| (0..24).map(|i| 128.0 + t * t.cos() * px[i] + t * t.sin() * py[i]
        + h * pz + sigma * g.gauss()).collect()).collect();
    (knobs, ph)
}
fn sheet_s(t: f64) -> f64 { // length of the spiral (t cos t, t sin t) from angle 0 to t, closed form
    let w = (t * t + 1.0).sqrt(); 0.5 * (t * w + (t + w).ln())
}
fn simpson(a: f64, b: f64, m: usize) -> f64 { // the same length by Simpson's rule
    let f = |t: f64| (t * t + 1.0).sqrt();
    let hh = (b - a) / m as f64;
    (f(a) + f(b) + ns((1..m).map(|j| (if j % 2 == 1 { 4.0 } else { 2.0 }) * f(a + j as f64 * hh)))) * hh / 3.0
}
fn graph(e: &[Vec<f64>], order: &[Vec<usize>], k: usize) -> Vec<Vec<f64>> { // k-NN graph + Dijkstra
    let n = e.len();
    let mut adj: Vec<Vec<(usize, f64)>> = vec![Vec::new(); n];
    for i in 0..n {
        for &j in &order[i][1..k + 1] { adj[i].push((j, e[i][j])); adj[j].push((i, e[i][j])); }
    }
    (0..n).map(|s| {
        let mut d = vec![f64::INFINITY; n]; d[s] = 0.0;
        let mut heap = BinaryHeap::new();
        heap.push(Reverse((0f64.to_bits(), s)));
        while let Some(Reverse((bits, u))) = heap.pop() {
            let du = f64::from_bits(bits); if du > d[u] { continue; }
            for &(v, w) in &adj[u] {
                if du + w < d[v] { d[v] = du + w; heap.push(Reverse((d[v].to_bits(), v))); }
            }
        }
        d
    }).collect()
}
fn eigen(a: &[Vec<f64>], r: usize, iters: usize, shift: f64) -> (Vec<f64>, Vec<Vec<f64>>) { // power iteration on A + shift I
    let (mut vals, mut vecs): (Vec<f64>, Vec<Vec<f64>>) = (vec![], vec![]);
    for c in 0..r {
        let mut v: Vec<f64> = (0..a.len()).map(|i| 1.0 + ((i * 7 + c * 3) % 11) as f64 / 10.0).collect();
        for _ in 0..iters {
            for u in &vecs { let d = dot(&v, u); v = v.iter().zip(u).map(|(x, y)| x - d * y).collect(); }
            let w: Vec<f64> = a.iter().zip(&v).map(|(row, x)| dot(row, &v) + shift * x).collect();
            let nrm = ns(w.iter().map(|x| x * x)).sqrt();
            v = w.iter().map(|x| x / nrm).collect();
        }
        vals.push(ns(v.iter().zip(a).map(|(x, row)| x * dot(row, &v))));
        vecs.push(v);
    }
    (vals, vecs)
}
fn mds(g: &[Vec<f64>], r: usize, shift: f64) -> (Vec<f64>, Vec<Vec<f64>>) { // classical scaling
    let n = g.len();
    let d2: Vec<Vec<f64>> = g.iter().map(|row| row.iter().map(|x| x * x).collect()).collect();
    let rm: Vec<f64> = d2.iter().map(|row| ns(row.iter().copied()) / n as f64).collect();
    let gm = ns(rm.iter().copied()) / n as f64;
    let b: Vec<Vec<f64>> = (0..n).map(|i| (0..n).map(|j| -0.5 * (d2[i][j] - rm[i] - rm[j] + gm)).collect()).collect();
    let (vals, vecs) = eigen(&b, r, 60, shift);
    let y = (0..n).map(|i| vals.iter().zip(&vecs).map(|(l, v)| v[i] * l.max(0.0).sqrt()).collect()).collect();
    (vals, y)
}
fn corr(a: &[f64], b: &[f64]) -> f64 {
    let (ma, mb) = (ns(a.iter().copied()) / a.len() as f64, ns(b.iter().copied()) / b.len() as f64);
    let sab = ns(a.iter().zip(b).map(|(x, y)| (x - ma) * (y - mb)));
    sab / (ns(a.iter().map(|x| (x - ma) * (x - ma))) * ns(b.iter().map(|y| (y - mb) * (y - mb)))).sqrt()
}
fn col(y: &[Vec<f64>], c: usize) -> Vec<f64> { y.iter().map(|r| r[c]).collect() }
type Iso = (Vec<Vec<f64>>, Vec<Vec<f64>>, Vec<f64>, f64, f64);
fn isomap(e: &[Vec<f64>], order: &[Vec<usize>], k: usize, s: &[f64], hs: &[f64]) -> Iso {
    let g = graph(e, order, k);
    let (vals, mut y) = mds(&g, 3, 0.0);
    if y[0][0] > 0.0 { for r in y.iter_mut() { r[0] = -r[0]; } } // first probe photo at the left
    if corr(&col(&y, 1), hs) < 0.0 { for r in y.iter_mut() { r[1] = -r[1]; } } // fill points up
    let (c1, c2) = (corr(&col(&y, 0), s), corr(&col(&y, 1), hs));
    (g, y, vals, c1, c2)
}
type Run = (Vec<Vec<f64>>, Vec<Vec<f64>>, Vec<Vec<usize>>, Vec<f64>, Vec<f64>);
fn run(n: usize, sigma: f64) -> Run {
    let (knobs, ph) = make(n, sigma);
    let e: Vec<Vec<f64>> = ph.iter().map(|p| ph.iter().map(|q| ns(p.iter().zip(q).map(|(x, y)| (x - y) * (x - y))).sqrt()).collect()).collect();
    let order = (0..n).map(|i| { let mut o: Vec<usize> = (0..n).collect(); o.sort_by(|&a, &b| e[i][a].partial_cmp(&e[i][b]).unwrap()); o }).collect();
    let s = knobs.iter().map(|&(t, _)| sheet_s(t) - sheet_s(T0)).collect();
    (ph, e, order, s, knobs.iter().map(|&(_, h)| h).collect())
}
fn main() {
    let (ph, e, order, s, hs) = run(600, 0.05);
    println!("photos 600, pixels 24, neighbours k = 10, sensor noise 0.05 grey levels");
    let (s_ab, sim_ab) = (sheet_s(T0 + 2.0 * PI) - sheet_s(T0), simpson(T0, T0 + 2.0 * PI, 200));
    let (g, y, vals, c1, c2) = isomap(&e, &order, 10, &s, &hs);
    println!("A at 270 deg, B at 630 deg, fill 6: radii {:.3} and {:.3}, gap 2 pi = {:.3}", T0, T0 + 2.0 * PI, 2.0 * PI);
    println!("A-B straight line {:.3}; s(A) {:.3}, s(B) {:.3}, along the sheet {:.3} (Simpson {:.3})", e[0][8], sheet_s(T0), sheet_s(T0 + 2.0 * PI), s_ab, sim_ab);
    println!("A-B through the graph {:.3}, {:.1}% long; on the Isomap map {:.3} apart", g[0][8], 100.0 * (g[0][8] / s_ab - 1.0), y[8][0] - y[0][0]);
    println!("whole roll along the sheet {:.3} (Simpson {:.3})", s[12], simpson(T0, T1, 200));
    println!("angle_deg, straight, sheet, graph, isomap_1, pca_1");
    let n = 600;
    let mean: Vec<f64> = (0..24).map(|i| ns(ph.iter().map(|p| p[i])) / n as f64).collect();
    let x: Vec<Vec<f64>> = ph.iter().map(|p| (0..24).map(|i| p[i] - mean[i]).collect()).collect();
    let c: Vec<Vec<f64>> = (0..24).map(|i| (0..24).map(|j| ns(x.iter().map(|r| r[i] * r[j])) / (n - 1) as f64).collect()).collect();
    let (pv, pvec) = eigen(&c, 3, 300, 0.0);
    let mut z: Vec<Vec<f64>> = x.iter().map(|r| pvec.iter().map(|v| dot(r, v)).collect()).collect();
    if z[0][0] > 0.0 { for r in z.iter_mut() { r[0] = -r[0]; } }
    for j in 0..13 { println!("{}, {:.2}, {:.2}, {:.2}, {:.2}, {:.2}", 270 + 45 * j, e[0][j], s[j], g[0][j], y[j][0], z[j][0]); }
    let top = mds(&g, 3, (-vals[2]).max(0.0)).0; // shifted by the most negative eigenvalue's size: the largest positive ones
    println!("isomap eigenvalues, largest in size {:.0}, {:.0}, then {:.0}; largest three {:.0}, {:.0}, {:.0}", vals[0], vals[1], vals[2], top[0], top[1], top[2]);
    println!("isomap: corr(coord 1, sheet length) {:.5}, corr(coord 2, fill) {:.4}", c1, c2);
    let tr = ns((0..24).map(|i| c[i][i]));
    println!("pca shares {:.4}, {:.4}, {:.4}; top three {:.5}", pv[0] / tr, pv[1] / tr, pv[2] / tr, (pv[0] + pv[1] + pv[2]) / tr);
    let (p1, p2) = (corr(&col(&z, 0), &s), corr(&col(&z, 1), &s));
    println!("pca: corr(pc 1, sheet length) {:.4}, corr(pc 2, sheet length) {:.4}, corr(pc 3, fill) {:.4}", p1, p2, corr(&col(&z, 2), &hs).abs());
    let (gb, _, _, b1, _) = isomap(&e, &order, 20, &s, &hs);
    println!("break, k = 20: start to end through the graph {:.2} against {:.2} along the sheet; corr {:.4}", gb[0][12], s[12], b1);
    println!("break, k = 2: photos unreachable from the first {}", graph(&e, &order, 2)[0].iter().filter(|x| x.is_infinite()).count());
    for (lab, nn, sg, kk) in [("k = 6", 600, 0.05, 6), ("k = 14", 600, 0.05, 14), ("noise 0.5", 600, 0.5, 10), ("300 photos", 300, 0.05, 10)] {
        let (_, et, ot, st, ht) = run(nn, sg);
        let (gt, _, _, t1, t2) = isomap(&et, &ot, kk, &st, &ht);
        println!("try {}: end to end {:.2}, corr {:.4}, {:.4}", lab, gt[0][12], t1, t2);
    }
    assert!((s_ab - sim_ab).abs() < 1e-6 && (s[12] - simpson(T0, T1, 200)).abs() < 1e-6); // closed form v Simpson
    assert!((e[0][8] - 2.0 * PI).abs() < 0.3); // neighbouring turns sit one gap of 2 pi apart
    assert!(g[0][8] / s_ab > 1.0 && g[0][8] / s_ab < 1.06); // the graph follows the sheet, a little long
    assert!(c1 > 0.999); // Isomap's first coordinate is the sheet length
    assert!(c2 > 0.95); // and its second is the fill dimmer
    assert!(p1.abs().max(p2.abs()) < 0.5); // PCA's flat view does not unroll
    assert!(gb[0][12] < 0.5 * s[12]); // too many neighbours: a short cut
    assert!(0.0 < top[2] && top[2] < 0.25 * top[1] && top[2] < -vals[2]); // a third direction, smaller than the distortion
    println!("ALL CHECKS PASS");
}
