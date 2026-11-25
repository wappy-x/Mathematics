// Moving sofa and Rupert's problem: the check behind the card. Standard library only.
use std::f64::consts::PI;
const INF: f64 = f64::INFINITY;
type V3 = [f64; 3];
fn fsum<I: IntoIterator<Item = f64>>(it: I) -> f64 { let (mut hi, mut lo) = (0.0f64, 0.0f64); // compensated, as Python's sum()
    for x in it { let t = hi + x; if hi.abs() >= x.abs() { lo += (hi - t) + x } else { lo += (x - t) + hi } hi = t; }
    if lo != 0.0 && lo.is_finite() { hi + lo } else { hi }
}
fn pmax(a: f64, b: f64) -> f64 { if b > a { b } else { a } } fn pmin(a: f64, b: f64) -> f64 { if b < a { b } else { a } }
// Part 1. A path x(t) carries the hallway's inner corner as the hallway turns by t.
fn cut(s: &[(f64, f64)], a: f64, b: f64, lo: f64, hi: f64) -> Vec<(f64, f64)> { // keep x with lo <= a*x + b <= hi
    if a.abs() < 1e-15 { return if lo <= b && b <= hi { s.to_vec() } else { vec![] }; }
    let (mut u, mut v) = ((lo - b) / a, (hi - b) / a);
    if v < u { std::mem::swap(&mut u, &mut v); }
    s.iter().filter_map(|&(p, q)| { let (l, r) = (pmax(p, u), pmin(q, v)); if l < r { Some((l, r)) } else { None } }).collect()
}
fn merge(mut s: Vec<(f64, f64)>) -> Vec<(f64, f64)> {
    s.sort_by(|x, y| x.partial_cmp(y).unwrap()); let mut m: Vec<(f64, f64)> = vec![];
    for iv in s { if let Some(last) = m.last_mut() { if iv.0 <= last.1 { last.1 = pmax(last.1, iv.1); continue; } } m.push(iv); }
    m
}
fn area_from_motion(path: &dyn Fn(f64) -> (f64, f64), n: usize) -> f64 { // n hallway angles, n rows of the sofa
    let pre: Vec<(f64, f64, f64, f64)> = (0..=n).map(|k| { let t = PI / 2.0 * k as f64 / n as f64; let (x1, x2) = path(t); (t.cos(), t.sin(), x1, x2) }).collect();
    let mut total = 0.0;
    for j in 0..n {
        let (y, mut s) = ((j as f64 + 0.5) / n as f64, vec![(-INF, 1.0)]);
        for (i, &(c, sn, x1, x2)) in pre.iter().enumerate() { // q1 = c*x + k1 and q2 = -s*x + k2
            let (k1, k2) = (-c * x1 + sn * (y - x2), sn * x1 + c * (y - x2));
            let mut arm = if i == n { vec![] } else { cut(&cut(&s, c, k1, -INF, 1.0), -sn, k2, 0.0, 1.0) };
            arm.extend(cut(&cut(&s, -sn, k2, -INF, 1.0), c, k1, 0.0, 1.0));
            s = merge(arm);
        }
        total += fsum(s.iter().map(|&(p, q)| q - p)) / n as f64;
    } total
}
fn extrapolate(path: &dyn Fn(f64) -> (f64, f64), label: &str) -> f64 {
    let (a1, a2) = (area_from_motion(path, 800), area_from_motion(path, 1600));
    println!("{label}: n=800 {a1:.6}  n=1600 {a2:.6}  extrapolated {:.5}", 2.0 * a2 - a1); 2.0 * a2 - a1
}
fn f(r: f64) -> f64 { PI / 2.0 + 2.0 * r - PI / 2.0 * r * r } // Hammersley's family, hole radius r
fn gerver_eqs(v: &[f64; 4]) -> [f64; 4] { // Gerver's four equations (1992), as written by Romik (2018)
    let (a, b, p, t) = (v[0], v[1], v[2], v[3]);
    [a * (t.cos() - p.cos()) - 2.0 * b * p.sin() + (t - p - 1.0) * t.cos() - t.sin() + p.cos() + p.sin(),
     a * (3.0 * t.sin() + p.sin()) - 2.0 * b * p.cos() + 3.0 * (t - p - 1.0) * t.sin() + 3.0 * t.cos() - p.sin() + p.cos(),
     a * p.cos() - (p.sin() + 0.5 - 0.5 * p.cos() + b * p.sin()),
     (a + PI / 2.0 - p - t) - (b - 0.5 * (t - p) * (1.0 + a) - 0.25 * ((t - p) * (t - p)))]
}
fn turn(t: f64, u: f64, w: f64, k: (f64, f64)) -> (f64, f64) { (t.cos() * u - t.sin() * w + k.0, t.sin() * u + t.cos() * w + k.1) }
const A1: f64 = 1.210322422072688751;
const KAP: [(f64, f64); 5] = [(-0.210322422072688751, 0.25), (-0.919179292771593322, 0.472406619750805465),
    (-0.613763229430251668, 0.889626479003221860), (-0.308347166088910014, 0.472406619750805465), (-1.017204036787814585, 0.25)];
const B1: f64 = -0.527624598026784624; const B2: f64 = 0.920258385160637622; const C1: f64 = 0.626045522848465867; const C2: f64 = -0.944750803946430751; const D1: f64 = 1.313022761424232933; const D2: f64 = -0.525382670414554437;
fn phase(i: usize, t: f64) -> (f64, f64) { match i {
        0 => turn(t, A1 * t.cos() - 0.25 * t.sin() - 1.0, 0.25 * t.cos() + A1 * t.sin() - 0.5, KAP[0]),
        1 => turn(t, -t * t / 4.0 + B1 * t + B2, t / 2.0 - B1 - 1.0, KAP[1]),
        2 => turn(t, C1 - t, C2 + t, KAP[2]),
        3 => turn(t, -t / 2.0 + D1 - 1.0, -t * t / 4.0 + D1 * t + D2, KAP[3]),
        _ => turn(t, A1 * t.cos() + 0.25 * t.sin() - 0.5, -0.25 * t.cos() + A1 * t.sin() - 1.0, KAP[4]) }
}
fn dist(p: (f64, f64), q: (f64, f64)) -> f64 { ((p.0 - q.0) * (p.0 - q.0) + (p.1 - q.1) * (p.1 - q.1)).sqrt() }
// Part 2. The cube's shadow along u has edge normals u x e_i; test the square on each.
fn cross(u: V3, e: V3) -> V3 { [u[1] * e[2] - u[2] * e[1], u[2] * e[0] - u[0] * e[2], u[0] * e[1] - u[1] * e[0]] }
fn dot(p: V3, q: V3) -> f64 { fsum((0..3).map(|i| p[i] * q[i])) }
const E: [V3; 3] = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
fn face_on(u: V3, al: f64) -> f64 { // largest square side, square turned by al in the shadow plane
    let n = dot(u, u).sqrt(); let u = [u[0] / n, u[1] / n, u[2] / n];
    let a0 = cross(u, if u[2].abs() < 0.9 { [0.0, 0.0, 1.0] } else { [1.0, 0.0, 0.0] });
    let n = dot(a0, a0).sqrt(); let a0 = [a0[0] / n, a0[1] / n, a0[2] / n]; let b0 = cross(u, a0);
    let a: V3 = std::array::from_fn(|i| al.cos() * a0[i] + al.sin() * b0[i]);
    let b: V3 = std::array::from_fn(|i| -al.sin() * a0[i] + al.cos() * b0[i]);
    E.iter().map(|&e| { let w = cross(u, e); fsum(w.iter().map(|x| x.abs())) / (dot(w, a).abs() + dot(w, b).abs()) }).fold(INF, pmin)
}
fn sph(th: f64, ph: f64) -> V3 { [th.cos() * ph.sin(), th.sin() * ph.sin(), ph.cos()] }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } } fn frac(n: i64, d: i64) -> (i64, i64) { let g = gcd(n, d); (n / g, d / g) }
// Random search (Steininger and Yurkevich 2023): is one turned shadow strictly inside another?
struct SplitMix64(u64);
impl SplitMix64 { fn unit(&mut self) -> f64 {
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
} }
fn shadow(v: &[V3], th: f64, ph: f64) -> Vec<(f64, f64)> { // the projection M(theta, phi) of the 2025 paper, then the convex hull
    let mut pts: Vec<(f64, f64)> = v.iter().map(|&[x, y, z]| (-th.sin() * x + th.cos() * y, -th.cos() * ph.cos() * x - th.sin() * ph.cos() * y + ph.sin() * z)).collect();
    pts.sort_by(|a, b| a.partial_cmp(b).unwrap()); pts.dedup();
    let half = |seq: &mut dyn Iterator<Item = (f64, f64)>| { // Andrew's monotone chain: keep only left turns
        let mut h: Vec<(f64, f64)> = vec![]; for p in seq {
            while h.len() >= 2 { let (a, b) = (h[h.len() - 2], h[h.len() - 1]); if (b.0 - a.0) * (p.1 - a.1) - (b.1 - a.1) * (p.0 - a.0) <= 0.0 { h.pop(); } else { break; } }
            h.push(p);
        }
        h.pop(); h
    };
    let mut hull = half(&mut pts.iter().copied()); hull.extend(half(&mut pts.iter().rev().copied())); hull
}
fn passes(v: &[V3], rng: &mut SplitMix64) -> bool {
    let r: Vec<f64> = [2.0 * PI, PI, 2.0 * PI, PI, 2.0 * PI].iter().map(|m| rng.unit() * m).collect(); let al = r[4];
    let (inner, h): (Vec<(f64, f64)>, _) = (shadow(v, r[0], r[1]).iter().map(|&(x, y)| (al.cos() * x - al.sin() * y, al.sin() * x + al.cos() * y)).collect(), shadow(v, r[2], r[3]));
    (0..h.len()).all(|i| { let (a, b) = (h[i], h[(i + 1) % h.len()]); inner.iter().all(|q| (b.0 - a.0) * (q.1 - a.1) - (b.1 - a.1) * (q.0 - a.0) > 1e-12) })
}
fn main() {
    println!("Part 1. Sofas in a hallway of width 1");
    for (name, r) in [("semicircle", 0.0), ("half-size hole", 0.5), ("Hammersley 2/pi", 2.0 / PI), ("full-width hole", 1.0)] { println!("r = {r:.6} ({name}): area {:.6}", f(r)); }
    let mut kbest = 0; for k in 0..=10000 { if f(k as f64 / 10000.0) > f(kbest as f64 / 10000.0) { kbest = k; } }
    let best = kbest as f64 / 10000.0;
    println!("best r by search over 10,001 steps: {best:.4}, area {:.6}", f(best));
    assert!((best - 2.0 / PI).abs() < 1e-4 && (f(best) - (PI / 2.0 + 2.0 / PI)).abs() < 1e-8);
    let semi = extrapolate(&|_t| (0.0, 0.0), "semicircle from its motion");
    let ham = extrapolate(&|t: f64| (2.0 / PI * ((2.0 * t).cos() - 1.0), 2.0 / PI * (2.0 * t).sin()), "Hammersley from its motion");
    assert!((semi - PI / 2.0).abs() < 1e-4 && (ham - f(2.0 / PI)).abs() < 1e-4);
    let mut v = [0.1, 1.4, 0.04, 0.7];
    for _ in 0..30 { // Newton's method with a finite-difference Jacobian
        let (f0, mut jm) = (gerver_eqs(&v), [[0.0f64; 5]; 4]);
        for i in 0..4 { for j in 0..4 { let mut w = v; w[j] = v[j] + 1e-7; jm[i][j] = (gerver_eqs(&w)[i] - f0[i]) / 1e-7; } jm[i][4] = -f0[i]; }
        for c in 0..4 { // Gaussian elimination with partial pivoting
            let mut p = c; for r in c..4 { if jm[r][c].abs() > jm[p][c].abs() { p = r; } } jm.swap(c, p);
            for r in c + 1..4 { let m = jm[r][c] / jm[c][c]; for k in 0..5 { jm[r][k] = jm[r][k] - m * jm[c][k]; } } }
        let mut d = [0.0f64; 4]; for c in (0..4).rev() { d[c] = (jm[c][4] - fsum((c + 1..4).map(|k| jm[c][k] * d[k]))) / jm[c][c]; }
        for k in 0..4 { v[k] += d[k]; }
    }
    let (a, b, phi, th) = (v[0], v[1], v[2], v[3]);
    println!("Gerver's equations by Newton: A {a:.10}  B {b:.10}  phi {phi:.10}  theta {th:.10}");
    assert!((phi - 0.039177364790083641).abs() < 1e-12 && (th - 0.681301509382724894).abs() < 1e-12); // Romik's table
    let cuts = [phi, th, PI / 2.0 - th, PI / 2.0 - phi];
    let gap = (0..4).map(|i| dist(phase(i, cuts[i]), phase(i + 1, cuts[i]))).fold(0.0, pmax);
    assert!(gap < 1e-12 && dist(phase(0, 0.0), (0.0, 0.0)) < 1e-12); // the five pieces join up
    let gerver = extrapolate(&|t: f64| phase(cuts.iter().filter(|&&c| t >= c).count(), t), "Gerver from its motion");
    println!("Gerver published 2.21953166; gain over Hammersley {:.4}; upper bound 2 sqrt 2 = {:.6}", gerver - ham, 2.0 * 2f64.sqrt());
    assert!((gerver - 2.21953166).abs() < 1e-4 && gerver > ham + 0.01);
    let p4: [[i64; 3]; 4] = [[3, 0, 0], [0, 3, 0], [1, 4, 4], [4, 1, 4]]; // Nieuwland's square, in quarters
    let sides: Vec<[i64; 3]> = (0..4).map(|i| std::array::from_fn(|k| p4[(i + 1) % 4][k] - p4[i][k])).collect();
    let idot = |p: [i64; 3], q: [i64; 3]| p[0] * q[0] + p[1] * q[1] + p[2] * q[2];
    assert!(p4.iter().all(|p| p.iter().filter(|&&c| c == 0 || c == 4).count() == 2) && sides.iter().all(|&s| idot(s, s) == 18) && (0..4).all(|i| idot(sides[i], sides[(i + 1) % 4]) == 0));
    let (u, av, bv) = ([2i64, 2, -1], [-1i64, 1, 0], [1i64, 1, 4]); // normal, and the square's two directions (lengths sqrt2, 3 sqrt2)
    let icross = |u: [i64; 3], e: [i64; 3]| [u[1] * e[2] - u[2] * e[1], u[2] * e[0] - u[0] * e[2], u[0] * e[1] - u[1] * e[0]];
    let ratios: Vec<(i64, i64)> = [[1i64, 0, 0], [0, 1, 0], [0, 0, 1]].iter().map(|&e| { let w = icross(u, e); frac(w.iter().map(|x| x.abs()).sum(), 3 * idot(w, av).abs() + idot(w, bv).abs()) }).collect();
    let m = *ratios.iter().min_by(|x, y| (x.0 * y.1).cmp(&(y.0 * x.1))).unwrap();
    let s2 = frac(18 * m.0 * m.0, m.1 * m.1);
    let rs: Vec<String> = ratios.iter().map(|r| format!("'{}/{}'", r.0, r.1)).collect(); println!("Part 2. A cube through a cube");
    println!("Nieuwland's square: corners on cube edges, sides^2 = 9/8, right angles; edge ratios [{}]; s^2 = {}/{}", rs.join(", "), s2.0, s2.1);
    let diag = (0..20000).map(|k| face_on([1.0, 1.0, 1.0], PI / 2.0 * k as f64 / 20000.0)).fold(-INF, pmax);
    println!("along the main diagonal: best side {diag:.6}; sqrt 6 - sqrt 2 = {:.6}", 6f64.sqrt() - 2f64.sqrt());
    assert!((diag - (6f64.sqrt() - 2f64.sqrt())).abs() < 1e-6);
    let mut g = (-INF, 0.0, 0.0, 0.0); for i in 0..25 { for j in 1..24 { for k in 0..24 {
        let (t1, p1, a1) = (PI / 2.0 * i as f64 / 24.0, PI * j as f64 / 24.0, PI / 2.0 * k as f64 / 24.0);
        let c = (face_on(sph(t1, p1), a1), t1, p1, a1); if c > g { g = c; }
    } } }
    let ((mut s, mut th1, mut ph1, mut al1), mut step) = (g, PI / 48.0);
    while step > 1e-9 { // pattern search from the best grid point
        let moves = [(th1 + step, ph1, al1), (th1 - step, ph1, al1), (th1, ph1 + step, al1), (th1, ph1 - step, al1), (th1, ph1, al1 + step), (th1, ph1, al1 - step)];
        let mut cand = (-INF, 0.0, 0.0, 0.0); for (p, q, r) in moves { let c = (face_on(sph(p, q), r), p, q, r); if c > cand { cand = c; } }
        if cand.0 > s { (s, th1, ph1, al1) = cand; } else { step /= 2.0; }
    }
    println!("search over all directions and turns: best side {s:.6}; exact 3 sqrt 2 / 4 = {:.6}", 3.0 * 2f64.sqrt() / 4.0);
    assert!(s2 == (9, 8) && (s - (9.0f64 / 8.0).sqrt()).abs() < 1e-6);
    let mut cube: Vec<V3> = vec![]; for x in [-0.5, 0.5] { for y in [-0.5, 0.5] { for z in [-0.5, 0.5] { cube.push([x, y, z]); } } }
    let cc: [V3; 3] = [[152024884, 0, 210152163].map(|v: i64| v as f64 / 259375205.0), [0.6632738028, 0.6106948881, 0.3980949609], [0.8193990033, 0.5298215096, 0.1230614493]];
    let mut nop: Vec<V3> = vec![]; for [x, y, z] in cc { for k in 0..15 { for sg in [1.0, -1.0] {
        let ang = 2.0 * PI * k as f64 / 15.0; nop.push([sg * (ang.cos() * x - ang.sin() * y), sg * (ang.sin() * x + ang.cos() * y), sg * z]);
    } } }
    let norm = |p: V3| dot(p, p).sqrt();
    assert!(cc[0].iter().map(|v| { let n = (v * 259375205.0).round() as i64; n * n }).sum::<i64>() == 259375205i64 * 259375205 && cc[1..].iter().all(|&c| 0.98 < norm(c) && norm(c) < 0.99));
    assert!((0..90).all(|i| (0..i).all(|j| (0..3).any(|k| (nop[i][k] - nop[j][k]).abs() > 1e-9))) && nop.len() == 90);
    println!("Noperthedron: 90 distinct vertices; |C1| = 1 exactly; |C2| {:.6}  |C3| {:.6}", norm(cc[1]), norm(cc[2]));
    for (name, vs) in [("cube", &cube), ("Noperthedron", &nop)] {
        let mut rng = SplitMix64(2025); let hits: Vec<usize> = (1..=20000).filter(|_| passes(vs, &mut rng)).collect();
        let first = hits.first().map_or("none".to_string(), |h| h.to_string()); println!("random tries, {name}: {} passages in 20,000; first at try {first}", hits.len());
        assert!((!hits.is_empty()) == (name == "cube"));
    }
    println!("figure, hole radius {:.4}, outer width {:.4}, quarter-disc centres x = -{:.4} and {:.4}", 2.0 / PI, 2.0 + 4.0 / PI, 2.0 / PI, 2.0 / PI);
    println!("ALL CHECKS PASS");
}
