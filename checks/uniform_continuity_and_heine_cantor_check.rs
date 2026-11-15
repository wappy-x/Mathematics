// Uniform continuity and Heine-Cantor -- the check behind the card.  std only.
// Example: an office floor 24 m by 12 m, distance = walking distance along the
// aisles, |dx| + |dy|.  A radiator in the corner (0, 0); temperature
// T = 16 + 6 u^2 deg C, u = 1 - s/36, s = x + y.
const W: f64 = 24.0;
const H: f64 = 12.0;
const S: f64 = 36.0;
const EPS: f64 = 0.5;

fn temp(x: f64, y: f64) -> f64 { let u = 1.0 - (x + y) / S; 16.0 + 6.0 * u * u }

fn vent(x: f64, y: f64) -> f64 { // test field: depends on direction from (12, 6)
    20.0 + 2.0 * (x - 12.0) / ((x - 12.0).powi(2) + (y - 6.0).powi(2)).sqrt()
}

fn walk(p: (f64, f64), q: (f64, f64)) -> f64 { (p.0 - q.0).abs() + (p.1 - q.1).abs() }
fn line(p: (f64, f64), q: (f64, f64)) -> f64 { ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt() }

fn ok(f: fn(f64, f64) -> f64, x: f64, y: f64, d: f64) -> bool { // every sampled desk within walking d
    let n = 16i32;
    let t = f(x, y);
    for i in -n..=n {
        for j in (i.abs() - n)..=(n - i.abs()) {
            let (qx, qy) = (x + d * i as f64 / n as f64, y + d * j as f64 / n as f64);
            if 0.0 <= qx && qx <= W && 0.0 <= qy && qy <= H && (qx, qy) != (12.0, 6.0) {
                if (f(qx, qy) - t).abs() > EPS + 1e-12 { return false; }
            }
        }
    }
    true
}

fn tol(f: fn(f64, f64) -> f64, x: f64, y: f64) -> f64 { // bisection: the largest d that passes, no roots
    let (mut lo, mut hi) = (0.0, 40.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if ok(f, x, y, mid) { lo = mid } else { hi = mid }
    }
    lo
}

fn tol_formula(s: f64) -> f64 { // same tolerance from the algebra, c = EPS / 6
    let (u, c) = (1.0 - s / S, EPS / 6.0);
    let toward = S * ((u * u + c).sqrt() - u);
    if s >= toward { toward } else { S * (u - (u * u - c).sqrt()) }
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }

fn exit_cm(x: i64, a: i64, b: i64) -> i64 { // walk needed to leave the zone
    if !((a == 0 || a < x) && (b == 2400 || x < b)) { return 0; }
    let mut m = i64::MAX;
    if a > 0 { m = m.min(x - a) }
    if b < 2400 { m = m.min(b - x) }
    m
}

fn main() {
    // Road 1: the Lipschitz constant.  |T(p) - T(q)| <= d(p, q) / 3, proved on the card.
    let k = 12.0 / S;
    let mut g = Vec::new();
    for x in 0..25 { for y in 0..13 { g.push((x as f64, y as f64)); } }
    let (mut steep, mut steep2) = (0.0f64, 0.0f64);
    for i in 0..g.len() {
        for j in i + 1..g.len() {
            let gap = (temp(g[i].0, g[i].1) - temp(g[j].0, g[j].1)).abs();
            steep = steep.max(gap / walk(g[i], g[j]));
            steep2 = steep2.max(gap / line(g[i], g[j]));
        }
    }
    println!("K = 12/36 = {:.6} deg C per metre walked; steepest on the 1 m grid: {:.6}", k, steep);
    println!("steepest per straight-line metre on the grid: {:.6}", steep2);
    println!("temperatures: radiator {:.6}, halfway {:.6}, far corner {:.6}; test field {:.6} east, {:.6} west",
        temp(0.0, 0.0), temp(12.0, 6.0), temp(24.0, 12.0), vent(13.0, 6.0), vent(11.0, 6.0));
    let lip = EPS / k;
    let (num, den) = (6 * (72 * 72 - 69 * 69), 72 * 72i64); // 6 (1 - (34.5/36)^2) as a fraction
    let c = gcd(num, den);
    println!("Lipschitz tolerance 0.5 / K: {:.6} m; radiator to 1.5 m away: {}/{} = {:.6} deg C",
        lip, num / c, den / c, num as f64 / den as f64);
    // Road 2: each desk's own tolerance, by formula and by bisection, along the diagonal.
    let ss = [0, 6, 12, 18, 24, 30, 36];
    let pts: Vec<f64> = ss.iter().map(|&s| tol(temp, 2.0 * s as f64 / 3.0, s as f64 / 3.0)).collect();
    for (s, p) in ss.iter().zip(&pts) {
        assert!((p - tol_formula(*s as f64)).abs() < 1e-9); // bisection against the algebra
    }
    let best = S * (1.0 - (1.0 - EPS / 6.0).sqrt());
    println!("own tolerance at the radiator {:.6} m, halfway (s = 18) {:.6} m, far corner {:.6} m", pts[0], pts[3], pts[6]);
    let mut grid_min = f64::MAX;
    for x in (0..25).step_by(2) { for y in (0..13).step_by(2) { grid_min = grid_min.min(tol(temp, x as f64, y as f64)); } }
    assert!((grid_min - best).abs() < 1e-9); // smallest own tolerance = formula
    println!("best single tolerance: formula 36(1 - sqrt(11/12)) = {:.6} m; smallest of 91 desks' own: {:.6} m", best, grid_min);
    for (name, d) in [("halfway", pts[3]), ("far corner", pts[6])] {
        println!("{} tolerance {:.6} m used at the radiator: gap {:.6} deg C", name, d, temp(0.0, 0.0) - temp(d, 0.0));
    }
    let t = lip / 2f64.sqrt(); // 1.5 m by tape measure, diagonally
    println!("1.5 m by tape from the radiator to ({:.4}, {:.4}): walk {:.6} m, gap {:.6} deg C", t, t, 2.0 * t, temp(0.0, 0.0) - temp(t, t));
    // Road 3: the Lebesgue number of three heating zones, by brute force over desks.
    let zones = [(0i64, 900i64), (700, 1700), (1500, 2400)]; // in centimetres: [0, 9), (7, 17), (15, 24]
    let lam = (0..=2400i64).map(|x| zones.iter().map(|&(a, b)| exit_cm(x, a, b)).max().unwrap()).min().unwrap();
    let half = (zones[0].1 - zones[1].0).min(zones[1].1 - zones[2].0) as f64 / 2.0;
    assert!(lam as f64 == half); // brute force against half the overlap
    println!("zones [0, 9) (7, 17) (15, 24]: Lebesgue number {:.2} m by brute force, half the overlap {:.2} m", lam as f64 / 100.0, half / 100.0);
    // What breaks: the floor with one point (12, 6) missing, and a field that tears there.
    for r in [1.0f64, 0.1, 0.01, 0.001] {
        let gap = vent(12.0 + r, 6.0) - vent(12.0 - r, 6.0);
        println!("missing point, desks {:.3} m either side: walk {:.3} m, gap {:.6} deg C", r, 2.0 * r, gap);
        assert!((gap - 4.0).abs() < 1e-9);
    }
    let tan0 = (1.0f64 - 0.75 * 0.75).sqrt() / 0.75; // cos = 0.75 is 21.5 deg C
    for r in [1.0f64, 0.1, 0.01] {
        let d = tol(vent, 12.0 + r, 6.0);
        assert!((d - r * tan0).abs() < 1e-9); // bisection against the geometry
        println!("missing point, own tolerance at {:.3} m from it: {:.6} m (geometry {:.6})", r, d, r * tan0);
    }
    println!("try: EPS 0.25 gives {:.6} m Lipschitz, {:.6} m best; amp 12 gives K {:.6}, {:.6} m",
        0.25 / k, S * (1.0 - (1.0f64 - 0.25 / 6.0).sqrt()), 24.0 / S, EPS / (24.0 / S));
    let sv: Vec<String> = ss.iter().map(|s| s.to_string()).collect();
    let pv: Vec<String> = pts.iter().map(|p| format!("{:.2}", p)).collect();
    println!("figure, s m: {}", sv.join(" "));
    println!("figure, own tolerance m: {}", pv.join(" "));
    assert!(k - steep >= 0.0 && k - steep < 0.005 && steep2 > k); // grid chords against K = 1/3
    println!("ALL CHECKS PASS");
}
