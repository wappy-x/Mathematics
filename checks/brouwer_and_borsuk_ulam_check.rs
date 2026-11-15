// Brouwer and Borsuk-Ulam -- the check behind the card.  Standard library only.
// A stir of a coffee cup of radius 4 cm.  Roads: winding numbers and a hunt by cells, against Newton's
// method and a one-variable bisection; a cut that halves two slices, by bisection against a grid count.
use std::f64::consts::PI;
const R: f64 = 4.0; const A: f64 = 0.3; // cup radius in cm; how far the slosh pushes the middle, as a share of R
type P = (f64, f64);

fn stir(x: f64, y: f64) -> P { // twist each ring by 1.5 - 0.3 s^2 radians (s = r/R), then slosh east
    let t = 1.5 - 0.3 * ((x * x + y * y) / (R * R));
    let (u, v) = ((x * t.cos() - y * t.sin()) / R, (x * t.sin() + y * t.cos()) / R);
    let d = (1.0 + A * u) * (1.0 + A * u) + A * v * A * v;
    let (nu, nv) = ((u + A) * (1.0 + A * u) + v * A * v, v * (1.0 + A * u) - (u + A) * A * v);
    (R * nu / d, R * nv / d)
}
fn disp(x: f64, y: f64) -> P { // where a point goes minus where it was; outside the cup, use the rim point
    let r = (x * x + y * y).sqrt(); let (x, y) = if r > R { (x * R / r, y * R / r) } else { (x, y) };
    let (fx, fy) = stir(x, y); (fx - x, fy - y)
}
fn winding(g: &dyn Fn(f64, f64) -> P, pts: &[P]) -> i64 { // the lift of card 04, step by step
    let (mut tot, last) = (0.0, pts[pts.len() - 1]); let (mut px, mut py) = g(last.0, last.1);
    for p in pts {
        let (qx, qy) = g(p.0, p.1);
        tot += (px * qy - py * qx).atan2(px * qx + py * qy); px = qx; py = qy;
    }
    (tot / (2.0 * PI)).round() as i64
}
fn circle(r: f64) -> Vec<P> { (0..720).map(|k| { let a = 2.0 * PI * k as f64 / 720.0; (r * a.cos(), r * a.sin()) }).collect() }
fn square(x0: f64, y0: f64, h: f64) -> Vec<P> {
    let n = 32; let f = |k: i32| h * k as f64 / n as f64; let mut s = vec![];
    for k in 0..n { s.push((x0 + f(k), y0)); } for k in 0..n { s.push((x0 + h, y0 + f(k))); }
    for k in 0..n { s.push((x0 + h - f(k), y0 + h)); } for k in 0..n { s.push((x0, y0 + h - f(k))); } s
}
fn hunt(g: &dyn Fn(f64, f64) -> P, mut x0: f64, mut y0: f64, mut h: f64) -> P {
    for _ in 0..40 { // keep a quarter whose rim still winds; it shrinks onto a zero
        h /= 2.0;
        let c = [(x0, y0), (x0, y0 + h), (x0 + h, y0), (x0 + h, y0 + h)];
        let k = c.iter().position(|&(a, b)| winding(g, &square(a, b, h)) != 0).unwrap();
        x0 = c[k].0; y0 = c[k].1;
    }
    (x0 + h / 2.0, y0 + h / 2.0)
}
fn newton(g: &dyn Fn(f64, f64) -> P, mut x: f64, mut y: f64) -> P {
    let e = 1e-6; for _ in 0..30 {
        let ((gx, gy), (ax, ay), (bx, by)) = (g(x, y), g(x + e, y), g(x, y + e));
        let (a, b, c, d) = ((ax - gx) / e, (bx - gx) / e, (ay - gy) / e, (by - gy) / e); let det = a * d - b * c;
        let nx = x - (d * gx - b * gy) / det; y -= (a * gy - c * gx) / det; x = nx;
    }
    (x, y)
}
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn least<T>(pts: &[T], moved: impl Fn(&T) -> f64) -> f64 { pts.iter().map(moved).fold(f64::INFINITY, f64::min) } // smallest move
fn area(p: &[P]) -> f64 {
    let n = p.len(); (0..n).map(|i| { let j = (i + n - 1) % n; p[i].0 * p[j].1 - p[j].0 * p[i].1 }).sum::<f64>() / -2.0
}
fn left(p: &[P], nx: f64, ny: f64, c: f64) -> f64 { // area where nx x + ny y <= c: clip, then shoelace
    let n = p.len(); let mut out = vec![];
    for i in 0..n {
        let ((ax, ay), (bx, by)) = (p[(i + n - 1) % n], p[i]);
        let (sa, sb) = (nx * ax + ny * ay - c, nx * bx + ny * by - c);
        if sa * sb < 0.0 { out.push((ax + sa / (sa - sb) * (bx - ax), ay + sa / (sa - sb) * (by - ay))); }
        if sb <= 0.0 { out.push((bx, by)); }
    }
    if out.len() > 2 { area(&out) } else { 0.0 }
}
fn halve(p: &[P], nx: f64, ny: f64) -> f64 {
    let (mut lo, mut hi) = (-40.0, 40.0);
    for _ in 0..80 { let mid = (lo + hi) / 2.0; if left(p, nx, ny, mid) < area(p) / 2.0 { lo = mid } else { hi = mid } }
    lo
}
fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if g(lo) * g(mid) > 0.0 { lo = mid } else { hi = mid } }
    lo
}
fn main() {
    let w_rim = winding(&disp, &circle(R)); println!("stir: winding of the displacement round the rim r = 4 cm: {}", w_rim);
    assert!(w_rim == 1);
    let dv: Vec<P> = (0..4).map(|k| { let a = (2 * k) as f64 * PI / 4.0; disp(R * a.cos(), R * a.sin()) }).collect();
    let dirs: Vec<String> = dv.iter().map(|&(dx, dy)| format!("({:.4}, {:.4}), heading {:.1} deg", dx, dy, dy.atan2(dx) * 180.0 / PI)).collect();
    println!("stir: rim points at 0, 90, 180, 270 deg move by {}", dirs.join("; "));
    let hd: Vec<f64> = (0..5).map(|k| dv[k % 4].1.atan2(dv[k % 4].0) * 180.0 / PI).collect(); // the headings round the rim, back to 0 deg
    let un: Vec<f64> = (0..5).map(|k| hd[0] + (0..k).map(|j| (hd[j + 1] - hd[j] + 180.0).rem_euclid(360.0) - 180.0).sum::<f64>()).collect();
    println!("stir: headings unwrapped: {} deg; total turn {:.1} deg", un.iter().map(|u| format!("{:.1}", u)).collect::<Vec<_>>().join(" -> "), un[4] - un[0]);
    let ws: Vec<String> = [3.0, 2.0, 1.0, 0.9, 0.5].iter().map(|&r| winding(&disp, &circle(r)).to_string()).collect();
    println!("stir: winding round circles r = 3, 2, 1, 0.9, 0.5 cm: [{}]", ws.join(", "));
    let mut cells = 0;
    for i in 0..8 { for j in 0..8 { if winding(&disp, &square(-4.0 + i as f64, -4.0 + j as f64, 1.0)) != 0 { cells += 1; } } }
    println!("stir: 1 cm cells whose rim winds: {} of 64 (checked on 64 cells; proves nothing about pairs)", cells);
    let (px, py_) = hunt(&disp, -4.0, -4.0, 8.0); let (nx, ny) = newton(&disp, 0.0, 0.0);
    println!("fixed point by cell hunt: ({:.9}, {:.9}) cm; by Newton from the centre: ({:.9}, {:.9}) cm", px, py_, nx, ny);
    let (fx, fy) = stir(px, py_); let moved = ((fx - px).powi(2) + (fy - py_).powi(2)).sqrt();
    println!("it lands at ({:.9}, {:.9}); moved under 1e-9 cm: {}; {:.4} cm from the centre", fx, fy, py(moved < 1e-9), (px * px + py_ * py_).sqrt());
    assert!((px - nx).abs() < 1e-8 && (py_ - ny).abs() < 1e-8 && moved < 1e-9 && (un[4] - un[0] - 360.0 * w_rim as f64).abs() < 1e-9);
    let (mut x, mut y, mut near) = (0.0, 0.0, vec![]);
    for n in 1..=200 {
        let s = stir(x, y); x = s.0; y = s.1; near.push(((x - px).powi(2) + (y - py_).powi(2)).sqrt());
        if [1, 2, 3, 10, 100, 200].contains(&n) { println!("press {:3}: at ({:.4}, {:.4}), {:.4} cm from the fixed point", n, x, y, near[n - 1]); }
    }
    let closest = near[100..].iter().cloned().fold(f64::INFINITY, f64::min);
    println!("presses 101 to 200: closest {:.4} cm -- pressing does not find the point", closest);
    assert!(closest > 0.1);
    // the proof's retraction, built from a ring stir with no fixed point: rotate a ring 2 <= r <= 4 by 30 degrees
    let rot = |x: f64, y: f64| -> P { (x * (PI / 6.0).cos() - y * (PI / 6.0).sin(), x * (PI / 6.0).sin() + y * (PI / 6.0).cos()) };
    let retract = |x: f64, y: f64| -> P { // follow the ray from f(x) through x out to the rim
        let (fx, fy) = rot(x, y); let (ux, uy) = (x - fx, y - fy); let l = (ux * ux + uy * uy).sqrt(); let (ux, uy) = (ux / l, uy / l);
        let b = x * ux + y * uy; let t = -b + (b * b + R * R - x * x - y * y).sqrt(); (x + t * ux, y + t * uy)
    };
    let mut ring_min = f64::INFINITY;
    for r in [2.0, 3.0, 4.0] { for (x, y) in circle(r) { let q = rot(x, y); ring_min = ring_min.min(((q.0 - x).powi(2) + (q.1 - y).powi(2)).sqrt()); } }
    println!("ring stir: smallest move {:.6} cm = 2 x 2 x sin 15 deg = {:.6}; no fixed point", ring_min, 4.0 * (PI / 12.0).sin());
    let rim_err = circle(R).iter().map(|&(x, y)| { let q = retract(x, y); (q.0 - x).abs() + (q.1 - y).abs() }).fold(0.0, f64::max);
    let q = retract(3.0, 0.0);
    println!("ring stir: retraction fixes the rim to 1e-9 cm: {}; (3, 0) goes to ({:.6}, {:.6}) on the rim", py(rim_err < 1e-9), q.0, q.1);
    let cup: Vec<P> = [circle(1e-9), circle(R)].concat(); // what breaks: cup points, from almost the centre
    let ball = |r: f64| -> Vec<[f64; 3]> { (0..18).map(|k| { let (a, b) = (0.5 + (k / 6) as f64, (k % 6) as f64);
        [r * a.sin() * b.cos(), r * a.sin() * b.sin(), r * a.cos()] }).collect() };
    let apart = |p: &[f64; 3]| p.iter().map(|c| (c - -c) * (c - -c)).sum::<f64>().sqrt(); // p against its antipode -p
    let mut z = 0.0; for _ in 0..10 { z = (z + 4.0) / 2.0; } // the open cup, pressed 10 times from the centre
    let pour = least(&cup, |&(x, y)| { let l = x.hypot(y); (x + R * x / l).hypot(y + R * y / l) });
    println!("breaks: open cup, z -> (z + 4)/2: after 10 presses {:.6} cm from the wall, never there", R - z);
    println!("breaks: pour into another cup, z -> rim point opposite: every point moves at least {:.0} cm", pour);
    println!("breaks: spill, z -> z + 1 cm: every point moves {:.0} cm; the map leaves the cup", least(&cup, |&(x, y)| (x + 1.0 - x).hypot(y - y)));
    println!("breaks: sphere, p -> -p on a sphere of radius 4 cm: every point moves {:.0} cm", least(&ball(R), apart));
    println!("breaks: Borsuk-Ulam with 3 readings, g(p) = p on the unit sphere: g(p) and g(-p) always {:.0} apart", least(&ball(1.0), apart));
    assert!(rim_err < 1e-9 && (ring_min - 4.0 * (PI / 12.0).sin()).abs() < 1e-12 && (R - z - R / 1024.0).abs() < 1e-12);
    let t = |p: f64| 70.0 + 4.0 * p.cos() + 1.5 * (2.0 * p).cos() + (3.0 * p).sin(); // Borsuk-Ulam, n = 1: rim deg C, modelled
    let g1 = |p: f64| t(p) - t(p + PI);
    let lo = bisect(&g1, 0.0, PI); let flips = (0..3600).filter(|&k| g1(PI * k as f64 / 3600.0) * g1(PI * (k + 1) as f64 / 3600.0) < 0.0).count();
    println!("rim: g(0) = {:.1}, g(180 deg) = {:.1}; equal readings at {:.6} deg and opposite, {:.6} and {:.6} deg C; sign changes on half the rim: {}",
        g1(0.0), g1(PI), lo * 180.0 / PI, t(lo), t(lo + PI), flips);
    assert!(flips % 2 == 1 && (t(lo) - t(lo + PI)).abs() < 1e-9);
    let tp = |x: f64, y: f64, z: f64| 15.0 - 25.0 * z * z + 6.0 * x + 4.0 * y * z * z; // Borsuk-Ulam, n = 2: modelled deg C
    let pp = |x: f64, y: f64, z: f64| 1013.0 + 9.0 * y - 5.0 * x * z + 7.0 * z * z * z; // and modelled hPa, on a unit Earth
    let g2 = |x: f64, y: f64| -> P {
        let r = (x * x + y * y).sqrt(); let (x, y) = if r > 1.0 { (x / r, y / r) } else { (x, y) };
        let z = (1.0 - x * x - y * y).max(0.0).sqrt();
        (tp(x, y, z) - tp(-x, -y, -z), pp(x, y, z) - pp(-x, -y, -z))
    };
    let w_eq = winding(&g2, &circle(1.0)); println!("earth: winding of the antipodal difference round the equator: {} (odd)", w_eq);
    let (ex, ey) = hunt(&g2, -1.0, -1.0, 2.0); let ez = (1.0 - ex * ex - ey * ey).sqrt();
    let sumsq = |z: f64| { let (x, y) = (14.0 * z * z * z * z * z / 27.0, -7.0 * z * z * z / 9.0); x * x + y * y + z * z };
    let lo = bisect(&|z: f64| sumsq(z) - 1.0, 0.0, 1.0); // by hand: zero needs y = -7z^3/9, x = 14z^5/27; solve sumsq(z) = 1
    println!("earth: point by cell hunt ({:.9}, {:.9}, {:.9}); z by bisection {:.9}", ex, ey, ez, lo);
    println!("earth: there {:.6} deg C, {:.6} hPa; opposite {:.6} deg C, {:.6} hPa", tp(ex, ey, ez), pp(ex, ey, ez), tp(-ex, -ey, -ez), pp(-ex, -ey, -ez));
    assert!(w_eq % 2 == 1 && (ez - lo).abs() < 1e-8 && (ex - 14.0 * lo * lo * lo * lo * lo / 27.0).abs() < 1e-8);
    // the sandwich in the plane: one straight cut halves a square of toast and a triangle of cheese (cm)
    let toast: Vec<P> = vec![(0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0)];
    let cheese: Vec<P> = vec![(13.0, 2.0), (21.0, 4.0), (15.0, 11.0)];
    let h = |th: f64| left(&cheese, th.cos(), th.sin(), halve(&toast, th.cos(), th.sin())) - area(&cheese) / 2.0;
    let th = bisect(&h, 0.0, PI); let (nx, ny) = (th.cos(), th.sin()); let c = halve(&toast, nx, ny);
    println!("sandwich: areas toast {:.1}, cheese {:.1} cm2; h(0) = {:.6}, h(180 deg) = {:.6}", area(&toast), area(&cheese), h(0.0), h(PI));
    println!("sandwich: cut {:.9} x + {:.9} y = {:.9}; halves {:.6} and {:.6} cm2", nx, ny, c, left(&toast, nx, ny, c), left(&cheese, nx, ny, c));
    let share = |p: &[P]| -> f64 { // independent road: count grid points inside the slice and on the cut's left
        let step = 0.02; let (mut n, mut k) = (0u64, 0u64);
        let xs = p.iter().map(|q| q.0); let ys = p.iter().map(|q| q.1);
        let (x0, x1) = (xs.clone().fold(f64::INFINITY, f64::min), xs.fold(f64::NEG_INFINITY, f64::max));
        let (y0, y1) = (ys.clone().fold(f64::INFINITY, f64::min), ys.fold(f64::NEG_INFINITY, f64::max));
        for i in (x0 / step) as i64..=(x1 / step) as i64 { for j in (y0 / step) as i64..=(y1 / step) as i64 {
            let (x, y) = ((i as f64 + 0.5) * step, (j as f64 + 0.5) * step);
            if (0..p.len()).all(|m| { let (a, b) = (p[m], p[(m + 1) % p.len()]); (b.0 - a.0) * (y - a.1) - (b.1 - a.1) * (x - a.0) >= 0.0 }) {
                n += 1; if nx * x + ny * y <= c { k += 1; }
            }
        } }
        k as f64 / n as f64
    };
    let (st, sc) = (share(&toast), share(&cheese));
    println!("sandwich: grid count, 0.02 cm spacing: toast {:.4}, cheese {:.4} on one side; cut misses the toast's centre by under 1e-9: {}",
        st, sc, py((5.0 * nx + 5.0 * ny - c).abs() < 1e-9));
    assert!((st - 0.5).abs() < 0.002 && (sc - 0.5).abs() < 0.002 && (5.0 * nx + 5.0 * ny - c).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
