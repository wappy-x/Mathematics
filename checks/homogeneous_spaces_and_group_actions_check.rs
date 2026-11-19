// Group action and homogeneous space -- the same check as the Python, in Rust.
// No crates.  The rotation group SO(3) turns a globe of radius 6371 km.  Any
// point can be carried to any other, and the turns that fix the North Pole are
// the spins about the polar axis, so the globe is SO(3) / SO(2).  Roads: a
// formula against a scan, a rank against a chart, random turns against area,
// and orbit times stabiliser against fixed points.
use std::f64::consts::PI;
type M3 = [[f64; 3]; 3];
type V3 = [f64; 3];
const D: f64 = PI / 180.0;
const RAD: f64 = 6371.0;
const N: V3 = [0.0, 0.0, 1.0];

fn mul(a: &M3, b: &M3) -> M3 {
    let mut c = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { let mut s = 0.0; for k in 0..3 { s += a[i][k] * b[k][j] } c[i][j] = s } }
    c
}
fn tp(a: &M3) -> M3 { let mut c = [[0.0; 3]; 3]; for i in 0..3 { for j in 0..3 { c[i][j] = a[j][i] } } c }
fn act(a: &M3, v: &V3) -> V3 { let mut o = [0.0; 3]; for i in 0..3 { o[i] = dot(&a[i], v) } o }
fn turn(a: f64, i: usize, j: usize) -> M3 {       // turn by a in the plane of axes i and j
    let mut m = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
    (m[i][i], m[j][j], m[i][j], m[j][i]) = (a.cos(), a.cos(), -a.sin(), a.sin());
    m
}
fn zt(a: f64) -> M3 { turn(a, 0, 1) }               // spin about the polar axis (or the drone's down axis)
fn yt(a: f64) -> M3 { turn(a, 2, 0) }               // tip about the axis through 90 deg east (or the right wing)
fn dot(u: &V3, v: &V3) -> f64 { let mut s = 0.0; for k in 0..3 { s += u[k] * v[k] } s }
fn cross(u: &V3, v: &V3) -> V3 { [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]] }
fn gap(u: &V3, v: &V3) -> f64 { (0..3).map(|k| (u[k] - v[k]).abs()).fold(0.0, f64::max) }
fn arc(u: &V3, v: &V3) -> f64 { dot(u, v).max(-1.0).min(1.0).acos() }
fn angle(a: &M3) -> f64 { ((a[0][0] + a[1][1] + a[2][2] - 1.0) / 2.0).max(-1.0).min(1.0).acos() }
fn point(lat: f64, lon: f64) -> V3 {                // unit vector from latitude and longitude in degrees
    let (p, t) = ((90.0 - lat) * D, lon * D);
    [p.sin() * t.cos(), p.sin() * t.sin(), p.cos()]
}
fn to_pole(v: &V3) -> M3 { mul(&zt(v[1].atan2(v[0])), &yt(v[2].acos())) }   // the chosen turn Z(theta) Y(phi)
fn col0(a: &M3) -> V3 { [a[0][0], a[1][0], a[2][0]] }
fn rank(rows: &[V3], tol: f64) -> usize {           // Gaussian elimination with row swaps
    let (mut m, mut r): (Vec<V3>, usize) = (rows.to_vec(), 0);
    for c in 0..3 {
        if r == m.len() { break }
        let mut piv = r;
        for i in r..m.len() { if m[i][c].abs() > m[piv][c].abs() { piv = i } }
        if m[piv][c].abs() < tol { continue }
        m.swap(r, piv);
        for i in r + 1..m.len() { let f = m[i][c] / m[r][c]; for k in 0..3 { m[i][k] -= f * m[r][k] } }
        r += 1;
    }
    r
}
struct Rng(u64);
impl Rng {                                          // SplitMix64, seed 2026, uniform in [0, 1)
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn turn(&mut self) -> M3 {                      // a fair random turn, from a uniform unit quaternion
        let (u1, u2, u3) = (self.next(), self.next(), self.next());
        let (a, b) = ((1.0 - u1).sqrt(), u1.sqrt());
        let (x, y, z, w) = (a * (2.0 * PI * u2).sin(), a * (2.0 * PI * u2).cos(), b * (2.0 * PI * u3).sin(), b * (2.0 * PI * u3).cos());
        [[1.0 - 2.0 * (y * y + z * z), 2.0 * (x * y - w * z), 2.0 * (x * z + w * y)],
         [2.0 * (x * y + w * z), 1.0 - 2.0 * (x * x + z * z), 2.0 * (y * z - w * x)],
         [2.0 * (x * z - w * y), 2.0 * (y * z + w * x), 1.0 - 2.0 * (x * x + y * y)]]
    }
}
type I3 = [[i64; 3]; 3];
fn imul(a: &I3, b: &I3) -> I3 { let mut c = [[0; 3]; 3]; for i in 0..3 { for j in 0..3 { for k in 0..3 { c[i][j] += a[i][k] * b[k][j] } } } c }
fn iact(a: &I3, v: &[i64; 3]) -> [i64; 3] { let mut o = [0; 3]; for i in 0..3 { for k in 0..3 { o[i] += a[i][k] * v[k] } } o }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let (l, ny, pa) = (point(51.5074, -0.1278), point(40.7128, -74.0060), point(48.8566, 2.3522));
    let (gl, gy) = (to_pole(&l), to_pole(&ny));
    println!("globe radius {:.0} km; London colatitude {:.4} deg, longitude {:.4} deg", RAD, l[2].acos() / D, l[1].atan2(l[0]) / D);
    let fib = (0..360).map(|a| gap(&act(&mul(&gl, &zt(a as f64 * D)), &N), &l)).fold(0.0, f64::max);
    println!("g_L = Z(theta) Y(phi) and all 360 turns g_L Z(alpha), alpha = 0..359 deg, land on London: {}", yn(fib < 1e-12));
    let mut rng = Rng(2026);
    let mut worst: f64 = 0.0;
    for _ in 0..1000 {                              // every turn = (chosen turn to its point) x (a spin)
        let g = rng.turn();
        let s = mul(&tp(&to_pole(&act(&g, &N))), &g);
        worst = worst.max(gap(&act(&s, &N), &N)).max(s[0][2].abs()).max(s[1][2].abs());
    }
    println!("1000 random turns g: g_v^T g is a spin about the pole, worst miss below 1e-12: {}", yn(worst < 1e-12));
    let (mut best, mut bk) = (f64::INFINITY, 0);
    for k in 0..36000 {
        let a = angle(&mul(&mul(&gy, &zt(k as f64 * D / 100.0)), &tp(&gl)));
        if a < best { (best, bk) = (a, k) }
    }
    let t = mul(&mul(&gy, &zt(bk as f64 * D / 100.0)), &tp(&gl));
    let c = arc(&l, &ny);
    println!("smallest turn carrying London to New York, by scanning the circle of them: {:.4} deg", best / D);
    println!("central angle London-New York, acos of {:.4}: {:.4} deg = {:.4} rad = {:.1} km", dot(&l, &ny), c / D, c, c * RAD);
    println!("London-Paris {:.1} km; New York to the turned Paris {:.1} km", arc(&l, &pa) * RAD, arc(&ny, &act(&t, &pa)) * RAD);
    let orbit_rows = [cross(&[1.0, 0.0, 0.0], &l), cross(&[0.0, 1.0, 0.0], &l), cross(&[0.0, 0.0, 1.0], &l)];
    let h = 1e-6;
    let diff = |p: V3, q: V3| -> V3 { [(p[0] - q[0]) / (2.0 * h), (p[1] - q[1]) / (2.0 * h), (p[2] - q[2]) / (2.0 * h)] };
    let chart_rows = [diff(point(51.5074 + h, -0.1278), point(51.5074 - h, -0.1278)),
                      diff(point(51.5074, -0.1278 + h), point(51.5074, -0.1278 - h))];
    let (ro, rc) = (rank(&orbit_rows, 1e-9), rank(&chart_rows, 1e-6));
    println!("rank of omega -> omega x London: {}; |London x London| = {:.4}", ro, dot(&cross(&l, &l), &cross(&l, &l)).sqrt());
    println!("rank of the latitude-longitude chart at London: {}; stabiliser dimension 3 - {} = {}", rc, ro, 3 - ro);
    let (rho, m) = (2000.0 / RAD, 200000usize);
    let share = (1.0 - rho.cos()) / 2.0;
    let mut hits = [0usize; 2];
    for _ in 0..m {
        let v = act(&rng.turn(), &N);
        if arc(&v, &l) <= rho { hits[0] += 1 }
        if arc(&v, &ny) <= rho { hits[1] += 1 }
    }
    let se = (m as f64 * share * (1.0 - share)).sqrt();
    println!("cap of 2000 km = {:.4} rad: area {:.0} km^2, share of globe {:.6}", rho, 2.0 * PI * RAD * RAD * (1.0 - rho.cos()), share);
    println!("{} fair random turns of the pole: within 2000 km of London {}, of New York {}", m, hits[0], hits[1]);
    println!("expected from area {:.1}, standard error {:.1}", m as f64 * share, se);
    let r0 = mul(&mul(&zt(30.0 * D), &yt(10.0 * D)), &turn(5.0 * D, 1, 2));
    let cam = mul(&r0, &yt(-30.0 * D));
    let (dep, head) = (cam[2][0].asin() / D, cam[1][0].atan2(cam[0][0]) / D);
    let pan = mul(&zt(head * D), &yt(-dep * D));
    let roll = mul(&tp(&pan), &cam);
    println!("camera axis {:.4} deg below the horizon, heading {:.4} deg", dep, head);
    println!("pan {:.4} deg, tilt {:.4} deg aims the same way: {}", head, -dep, yn(gap(&col0(&pan), &col0(&cam)) < 1e-12));
    println!("what is left is a roll about the camera axis: {}, of {:.4} deg", yn(gap(&col0(&roll), &[1.0, 0.0, 0.0]) < 1e-12), roll[2][1].atan2(roll[1][1]) / D);
    let (s1, s2) = (point(-89.99, 0.0), point(-89.99, 90.0));
    println!("chosen turns near the South Pole: points {:.2} km apart, turns {:.4} deg apart", arc(&s1, &s2) * RAD, angle(&mul(&tp(&to_pole(&s1)), &to_pole(&s2))) / D);
    let id: I3 = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
    let gens: [I3; 2] = [[[0, -1, 0], [1, 0, 0], [0, 0, 1]], [[1, 0, 0], [0, 0, -1], [0, 1, 0]]];
    let (mut cube, mut todo) = (vec![id], vec![id]);
    while let Some(a) = todo.pop() {
        for g in &gens {
            let b = imul(g, &a);
            if !cube.contains(&b) { cube.push(b); todo.push(b) }
        }
    }
    println!("turns of a cube, built from two quarter turns: {}", cube.len());
    let (mut special, mut prods, mut sizes): (Vec<([i64; 3], usize)>, Vec<usize>, Vec<usize>) = (vec![], vec![], vec![]);
    for (name, v) in [("face centre", [0, 0, 1]), ("corner", [1, 1, 1]), ("edge midpoint", [1, 1, 0]), ("general point", [1, 2, 3])] {
        let mut orb: Vec<[i64; 3]> = cube.iter().map(|g| iact(g, &v)).collect();
        orb.sort(); orb.dedup();
        let stab = cube.iter().filter(|g| iact(g, &v) == v).count();
        prods.push(orb.len() * stab);
        sizes.push(orb.len());
        if stab > 1 { for p in &orb { special.push((*p, stab)) } }
        println!("{} {:?}: orbit {} x stabiliser {} = {}", name, v, orb.len(), stab, orb.len() * stab);
    }
    let by_points: usize = special.iter().map(|(_, s)| s - 1).sum();
    let per_turn: Vec<usize> = cube.iter().filter(|g| **g != id).map(|g| special.iter().filter(|(p, _)| iact(g, p) == *p).count()).collect();
    println!("turn-and-fixed-point pairs: by points {}, by turns {} x 2 = {}", by_points, per_turn.len(), per_turn.iter().sum::<usize>());
    println!("mistake 1, spin on the wrong side: Z(90 deg) g_L sends the pole {:.1} km from London", arc(&l, &act(&zt(90.0 * D), &l)) * RAD);
    println!("mistake 2, orbit dimension taken as 3: the orbit map has rank {}, the globe dimension 2", ro);
    println!("mistake 3, spins only: London's orbit is a circle of {:.1} km; New York is {:.1} km off it",
             2.0 * PI * RAD * (1.0 - l[2] * l[2]).sqrt(), (l[2].acos() - ny[2].acos()).abs() * RAD);
    println!("mistake 4, images counted without the stabiliser: {} images of a face centre, {} distinct", cube.len(), sizes[0]);
    assert!((best - c).abs() < 1e-6 && gap(&act(&t, &l), &ny) < 1e-12);       // scan against acos
    assert!((arc(&l, &pa) - arc(&ny, &act(&t, &pa))).abs() < 1e-12);           // distances kept
    assert!(ro == 2 && rc == 2 && fib < 1e-12 && worst < 1e-12);                // 3 = 2 + 1, two roads
    assert!(hits.iter().all(|&k| (k as f64 - m as f64 * share).abs() < 4.0 * se)); // random turns against area
    assert!(cube.len() == 24 && prods == vec![24; 4]);                          // orbit x stabiliser
    assert!(by_points == 46 && per_turn.iter().sum::<usize>() == 46 && per_turn.iter().all(|&k| k == 2));
    assert!(gap(&col0(&roll), &[1.0, 0.0, 0.0]) < 1e-12);
    println!("ALL CHECKS PASS");
}
