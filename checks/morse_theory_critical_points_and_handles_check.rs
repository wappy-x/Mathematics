// Morse theory -- the same check as the Python, in Rust.  No crates.
// A swim ring stood on edge: tube-centre circle a = 20 cm, tube radius b = 10 cm, height
// h(u, v) = 30 + (a + b cos v) cos u in cm.  Newton's method finds the critical points; each is
// classified three ways (Hessian signs, lower arcs on a small circle, a second chart).  The counts
// meet Betti numbers from exact ranks, sublevel Euler counts and a mesh count of pits and passes.
use std::f64::consts::PI;
const A: f64 = 20.0; const B: f64 = 10.0; const D: f64 = 1e-4; const TAU: f64 = 2.0 * PI;
type Fun<'a> = &'a dyn Fn(f64, f64) -> f64;
fn ring(u: f64, v: f64) -> f64 { 30.0 + (A + B * v.cos()) * u.cos() }
fn planet(e: f64) -> impl Fn(f64, f64) -> f64 { // toy planet terrain in metres, chart: polar angle, longitude
    move |p: f64, t: f64| { let (x, y) = (p.sin() * t.cos(), p.sin() * t.sin()); 1000.0 * (x.powi(3) - 3.0 * x * y * y + e * x) }
}
fn grad(f: Fun, u: f64, v: f64) -> (f64, f64) { ((f(u + D, v) - f(u - D, v)) / (2.0 * D), (f(u, v + D) - f(u, v - D)) / (2.0 * D)) }
fn hess(f: Fun, u: f64, v: f64) -> [f64; 3] {
    let (e, c) = (1e-3, f(u, v));
    let huv = (f(u + e, v + e) - f(u + e, v - e) - f(u - e, v + e) + f(u - e, v - e)) / (4.0 * e * e);
    [(f(u + e, v) - 2.0 * c + f(u - e, v)) / e.powi(2), huv, (f(u, v + e) - 2.0 * c + f(u, v - e)) / e.powi(2)]
}
fn index(h: [f64; 3]) -> Option<usize> { // negative eigenvalues of [[H0, H1], [H1, H2]]
    let det = h[0] * h[2] - h[1].powi(2);
    if det.abs() < 1e-3 { None } else if det < 0.0 { Some(1) } else if h[0] + h[2] > 0.0 { Some(0) } else { Some(2) }
}
fn arcs(f: Fun, u: f64, v: f64) -> String { // separate stretches of a small circle lying below the point
    let s: Vec<bool> = (0..72).map(|k| { let a = TAU * k as f64 / 72.0; f(u + 0.02 * a.cos(), v + 0.02 * a.sin()) < f(u, v) }).collect();
    if s.iter().all(|&x| x) { return "all".to_string() }
    (0..72).filter(|&k| s[k] && !s[(k + 71) % 72]).count().to_string()
}
fn chart2<'a>(f: Fun<'a>, u: f64, v: f64) -> impl Fn(f64, f64) -> f64 + 'a { // the same function in a bent second chart
    move |s: f64, t: f64| f(u + s + 0.4 * t + 0.3 * s * s, v + t - 0.5 * s * t)
}
fn critical(f: Fun, starts: &[(f64, f64)], ok: &dyn Fn(f64, f64) -> bool) -> Vec<(f64, f64)> {
    let mut found: Vec<([f64; 4], (f64, f64))> = Vec::new();
    for &(mut u, mut v) in starts {
        for _ in 0..40 {
            let ((gu, gv), h) = (grad(f, u, v), hess(f, u, v));
            let det = h[0] * h[2] - h[1] * h[1];
            if det.abs() < 1e-12 { break }
            (u, v) = (u - (h[2] * gu - h[1] * gv) / det, v - (h[0] * gv - h[1] * gu) / det);
        }
        let (k, (gu, gv)) = ([u.cos(), u.sin(), v.cos(), v.sin()], grad(f, u, v));
        if gu.hypot(gv) < 1e-6 && ok(u, v) && found.iter().all(|(q, _)| (0..4).map(|i| (k[i] - q[i]).abs()).fold(0.0, f64::max) > 1e-5) {
            found.push((k, (u.rem_euclid(TAU), v.rem_euclid(TAU))));
        }
    }
    let mut pts: Vec<(f64, f64)> = found.into_iter().map(|(_, p)| p).collect();
    pts.sort_by(|p, q| f(p.0, p.1).partial_cmp(&f(q.0, q.1)).unwrap());
    pts
}
fn fx(x: f64, d: usize) -> String { format!("{:.*}", d, if x.abs() >= 0.5 * 10f64.powi(-(d as i32)) { x } else { 0.0 }) }
fn deg(x: f64) -> i64 { (x.to_degrees().round() as i64).rem_euclid(360) }
type Mesh = (Vec<[usize; 3]>, Vec<(f64, f64)>);
fn mesh(n: usize, m: usize, sphere: bool) -> Mesh { // triangles of an n-by-m grid, glued into a torus or a sphere
    let vid = |i: usize, j: usize| -> usize {
        if !sphere { (i % n) * m + j % m } else if i == 0 { 0 } else if i == n { 1 + (n - 1) * m } else { 1 + (i - 1) * m + j % m }
    };
    let mut tris = Vec::new();
    for i in 0..n { for j in 0..m {
        for t in [[vid(i, j), vid(i + 1, j), vid(i, j + 1)], [vid(i + 1, j), vid(i + 1, j + 1), vid(i, j + 1)]] {
            if t[0] != t[1] && t[1] != t[2] && t[0] != t[2] { tris.push(t) }
        }
    } }
    let nv = if sphere { 2 + (n - 1) * m } else { n * m };
    let mut pos = vec![(0.0, 0.0); nv];
    for i in 0..=n { for j in 0..m { pos[vid(i, j)] = ((if sphere { PI } else { TAU }) * i as f64 / n as f64, TAU * j as f64 / m as f64) } }
    (tris, pos)
}
fn rank(mut m: Vec<Vec<i128>>) -> usize { // exact fraction-free (Bareiss) elimination in whole numbers
    let (mut r, mut prev) = (0, 1i128);
    for c in 0..m[0].len() {
        let Some(p) = (r..m.len()).find(|&i| m[i][c] != 0) else { continue };
        m.swap(r, p);
        for i in r + 1..m.len() {
            for j in 0..m[0].len() { if j != c { m[i][j] = (m[i][j] * m[r][c] - m[i][c] * m[r][j]) / prev } }
            m[i][c] = 0;
        }
        prev = m[r][c]; r += 1;
    }
    r
}
fn edges(tris: &[[usize; 3]]) -> Vec<(usize, usize)> {
    let mut e: Vec<(usize, usize)> = tris.iter().flat_map(|t| [(t[0], t[1]), (t[1], t[2]), (t[0], t[2])]).map(|(a, b)| (a.min(b), a.max(b))).collect();
    e.sort(); e.dedup(); e
}
fn betti(tris: &[[usize; 3]]) -> (Vec<i64>, [i64; 3]) {
    let mut vs: Vec<usize> = tris.iter().flatten().copied().collect(); vs.sort(); vs.dedup();
    let e = edges(tris);
    let t: Vec<[usize; 3]> = tris.iter().map(|t| { let mut s = *t; s.sort(); s }).collect();
    let d1 = vs.iter().map(|&v| e.iter().map(|&(a, b)| (v == b) as i128 - (v == a) as i128).collect()).collect();
    let d2 = e.iter().map(|&x| t.iter().map(|s| (x == (s[1], s[2])) as i128 - (x == (s[0], s[2])) as i128 + (x == (s[0], s[1])) as i128).collect()).collect();
    let (r1, r2, nv, ne, nt) = (rank(d1) as i64, rank(d2) as i64, vs.len() as i64, e.len() as i64, t.len() as i64);
    (vec![nv - r1, ne - r1 - r2, nt - r2], [nv, ne, nt])
}
fn euler_below(tris: &[[usize; 3]], val: &[f64], c: f64) -> i64 { // V - E + T of the part at or below level c
    let t: Vec<[usize; 3]> = tris.iter().filter(|t| t.iter().all(|&v| val[v] <= c)).copied().collect();
    let mut vs: Vec<usize> = t.iter().flatten().copied().collect(); vs.sort(); vs.dedup();
    vs.len() as i64 - edges(&t).len() as i64 + t.len() as i64
}
fn mesh_count(tris: &[[usize; 3]], val: &[f64]) -> Vec<i64> { // pits, passes, peaks from sign changes round each vertex
    let mut link: Vec<Vec<(usize, usize)>> = vec![Vec::new(); val.len()];
    for t in tris { for (v, x, y) in [(t[0], t[1], t[2]), (t[1], t[2], t[0]), (t[2], t[0], t[1])] { link[v].push((x, y)) } }
    let mut kinds = vec![0i64; 3];
    for v in 0..val.len() {
        let mut cyc = vec![link[v][0].0];
        loop { let nx = link[v].iter().find(|p| p.0 == *cyc.last().unwrap()).unwrap().1; if nx == cyc[0] { break } cyc.push(nx) }
        let s: Vec<bool> = cyc.iter().map(|&w| val[w] > val[v]).collect();
        let sc = (0..s.len()).filter(|&k| s[k] != s[(k + s.len() - 1) % s.len()]).count() as i64;
        if sc == 0 { kinds[if s[0] { 0 } else { 2 }] += 1 } else { kinds[1] += sc / 2 - 1 }
    }
    kinds
}
fn idx(f: Fun, p: (f64, f64)) -> usize { index(hess(f, p.0, p.1)).unwrap() }
fn main() {
    let grid: Vec<(f64, f64)> = (0..49).map(|k| (TAU * (k / 7) as f64 / 7.0 + 0.1, TAU * (k % 7) as f64 / 7.0 + 0.2)).collect();
    let crit = critical(&ring, &grid, &|_, _| true);
    let mut counts = vec![0i64; 3];
    println!("swim ring stood on edge: a = 20 cm, b = 10 cm; critical points, lowest first");
    for &(u, v) in &crit {
        let (h, k) = (hess(&ring, u, v), hess(&chart2(&ring, u, v), 0.0, 0.0));
        counts[index(h).unwrap()] += 1;
        println!("u {} deg, v {} deg, height {} cm; Hessian {}, {}, {}; index {}; lower arcs {}; chart 2: {}, {}, {}, index {}", deg(u), deg(v),
                 fx(ring(u, v), 2), fx(h[0], 2), fx(h[1], 2), fx(h[2], 2), index(h).unwrap(), arcs(&ring, u, v), fx(k[0], 2), fx(k[1], 2), fx(k[2], 2), index(k).unwrap());
    }
    let (b_t, vet) = betti(&mesh(3, 3, false).0);
    println!("counts by index c = {:?}; Betti numbers b = {:?} by exact ranks on {}-{}-{} triangles", counts, b_t, vet[0], vet[1], vet[2]);
    println!("weak: c_k >= b_k {}; strong: c1 - c0 = {} >= b1 - b0 = {}; c0 - c1 + c2 = {} = chi = {}", if (0..3).all(|k| counts[k] >= b_t[k]) { "yes" } else { "no" },
             counts[1] - counts[0], b_t[1] - b_t[0], counts[0] - counts[1] + counts[2], vet[0] - vet[1] + vet[2]);
    let (tris, pos) = mesh(60, 60, false);
    let val: Vec<f64> = pos.iter().map(|p| ring(p.0, p.1)).collect();
    let (chis, mr): (Vec<i64>, Vec<i64>) = ([10.0, 30.0, 50.0, 70.0].iter().map(|&c| euler_below(&tris, &val, c)).collect(), mesh_count(&tris, &val));
    println!("sublevel Euler counts below 10, 30, 50, 70 cm on a 60 x 60 mesh: {:?}; mesh pits, passes, peaks {:?}", chis, mr);
    let terrain = planet(0.3);
    let starts: Vec<(f64, f64)> = (0..108).map(|k| ((10.0 + 20.0 * (k / 12) as f64).to_radians(), (30.0 * (k % 12) as f64).to_radians())).collect();
    let inside = |p: f64, _t: f64| 0.02 < p && p < PI - 0.02;
    let peaks = critical(&terrain, &starts, &inside);
    let kinds: Vec<usize> = peaks.iter().map(|&p| idx(&terrain, p)).collect();
    let pl: Vec<i64> = (0..3).map(|k| kinds.iter().filter(|&&x| x == k).count() as i64).collect();
    println!("toy planet: {} pits, {} passes, {} peaks; {} - {} + {} = {}", pl[0], pl[1], pl[2], pl[0], pl[1], pl[2], pl[0] - pl[1] + pl[2]);
    println!("heights (m): {}", peaks.iter().map(|p| fx(terrain(p.0, p.1), 0)).collect::<Vec<_>>().join(", "));
    for &p in peaks.iter().take(1).chain(peaks.iter().filter(|&&p| idx(&terrain, p) == 1).take(1)) { // the deepest pit, then the first pass if any
        println!("  polar angle {:.2} deg, longitude {:.2} deg, index {}", p.0.to_degrees(), p.1.to_degrees(), idx(&terrain, p)) }
    let (tris_s, pos_s) = mesh(48, 96, true);
    let mc = mesh_count(&tris_s, &pos_s.iter().map(|p| terrain(p.0, p.1)).collect::<Vec<f64>>());
    let (b_s, ve_s) = betti(&mesh(3, 4, true).0);
    println!("planet 48 x 96 mesh count {:?}, alternating sum {}; sphere Betti {:?} by exact ranks, chi {}", mc, mc[0] - mc[1] + mc[2], b_s, ve_s[0] - ve_s[1] + ve_s[2]);
    let flat = |_u: f64, v: f64| 10.0 + B * v.sin();
    let hf = hess(&flat, 0.0, PI / 2.0);
    let slope = (0..36).map(|k| { let g = grad(&flat, TAU * k as f64 / 36.0, PI / 2.0); g.0.hypot(g.1) }).fold(0.0, f64::max);
    println!("break 1, ring lying flat: Hessian at v = 90 deg {}, {}, {}, largest slope on that circle {:.6}", fx(hf[0], 2), fx(hf[1], 2), fx(hf[2], 2), slope);
    let tilt = |u: f64, v: f64| 30.0 + (B * v.sin()) * 5f64.to_radians().cos() + (A + B * v.cos()) * u.cos() * 5f64.to_radians().sin();
    let ct = critical(&tilt, &grid, &|_, _| true);
    println!("break 2, ring tilted 5 deg from flat: {} critical points, indices {:?}", ct.len(), ct.iter().map(|&p| idx(&tilt, p)).collect::<Vec<_>>());
    let (monkey, flat_planet) = (|x: f64, y: f64| x.powi(3) - 3.0 * x * y * y, planet(0.0));
    let km: Vec<usize> = critical(&flat_planet, &starts, &inside).iter().map(|&p| idx(&flat_planet, p)).collect();
    let c = |k: usize| km.iter().filter(|&&x| x == k).count() as i64;
    let hm = hess(&monkey, 0.0, 0.0);
    println!("break 3, planet with no nudge: Newton finds {} pits, {} passes, {} peaks, sum {}; at each pole Hessian {}, {}, {}, lower arcs {}",
             c(0), c(1), c(2), c(0) - c(1) + c(2), fx(hm[0], 2), fx(hm[1], 2), fx(hm[2], 2), arcs(&monkey, 0.0, 0.0));
    println!("break 4, counting without signs: ring {} points against chi 0; planet {} against chi 2", crit.len(), peaks.len());
    println!("figure, 5 px per cm, floor y 340, centre (210, 190), outer r 150, hole r 50, critical points at y {}",
             crit.iter().map(|p| format!("{:.0}", 340.0 - 5.0 * ring(p.0, p.1))).collect::<Vec<_>>().join(", "));
    let i1: Vec<usize> = crit.iter().map(|&p| idx(&ring, p)).collect();
    let i2: Vec<usize> = crit.iter().map(|&p| index(hess(&chart2(&ring, p.0, p.1), 0.0, 0.0)).unwrap()).collect();
    assert!(i1 == i2 && i1 == vec![0, 1, 1, 2]);
    assert!(crit.iter().map(|p| arcs(&ring, p.0, p.1)).collect::<Vec<_>>() == ["0", "2", "2", "all"]); // second road to the index
    assert!(crit.iter().zip([30.0 - A - B, 30.0 - A + B, 30.0 + A - B, 30.0 + A + B]).all(|(p, h)| (ring(p.0, p.1) - h).abs() < 1e-6)); // 30 -/+ (a -/+ b)
    assert!(counts == b_t && b_t == mr && b_t == vec![1, 2, 1] && chis == vec![1, 0, -1, 0]); // Morse counts against exact ranks, sublevels, mesh
    assert!(pl == mc && pl == vec![3, 4, 3] && ve_s[0] - ve_s[1] + ve_s[2] == pl[0] - pl[1] + pl[2] && b_s == vec![1, 0, 1]);
    assert!(index(hf).is_none() && ct.len() == 4 && arcs(&monkey, 0.0, 0.0) == "3");
    println!("ALL CHECKS PASS");
}
