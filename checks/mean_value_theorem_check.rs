// Mean value theorem -- the same check as the Python, in Rust, std only.
// A train runs 100 km in 1 hour, rest to rest: s(t) = 100(3t^2 - 2t^3) km at
// t hours.  Three roads to the times its speed is exactly 100 km/h: the
// quadratic formula, bisection on a difference-quotient speed, and Rolle's
// road (lowest and highest lead over a steady 100 km/h, found on a grid).
fn s(t: f64) -> f64 { 100.0 * (3.0 * t * t - 2.0 * t * t * t) }
fn lead(t: f64) -> f64 { s(t) - 100.0 * t }
fn speed(f: &dyn Fn(f64) -> f64, t: f64, h: f64) -> f64 { (f(t + h) - f(t - h)) / (2.0 * h) }
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if (f(lo) < 0.0) == (f(mid) < 0.0) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn extreme(f: &dyn Fn(f64) -> f64, sign: f64) -> f64 {
    let mut k = 0;
    for i in 1..=1000 { if sign * f(i as f64 / 1000.0) < sign * f(k as f64 / 1000.0) { k = i } }
    let (mut lo, mut hi) = ((k as f64 - 1.0) / 1000.0, (k as f64 + 1.0) / 1000.0);
    for _ in 0..100 {
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if sign * f(a) < sign * f(b) { hi = b } else { lo = a }
    }
    (lo + hi) / 2.0
}
fn main() {
    let h0 = 1e-5;
    let avg = (s(1.0) - s(0.0)) / (1.0 - 0.0);
    let exact = [(3.0 - 3f64.sqrt()) / 6.0, (3.0 + 3f64.sqrt()) / 6.0];
    let dv = |t: f64| speed(&s, t, h0) - avg;
    let bis = [bisect(&dv, 0.0, 0.5), bisect(&dv, 0.5, 1.0)];
    let rol = [extreme(&lead, 1.0), extreme(&lead, -1.0)];
    println!("trip: {:.0} km in 1 h; average speed {:.0} km/h", s(1.0) - s(0.0), avg);
    let v: Vec<String> = (0..11).map(|k| { let t = k as f64 / 10.0; format!("{}", (600.0 * t * (1.0 - t)).round() as i64) }).collect();
    println!("speed at minutes 0, 6, ..., 60: [{}]", v.join(", "));
    println!("road 1, quadratic formula, sqrt 3 = {:.6}: c1 = {:.6} h ({:.2} min), c2 = {:.6} h ({:.2} min)", 3f64.sqrt(), exact[0], 60.0 * exact[0], exact[1], 60.0 * exact[1]);
    println!("road 2, bisection on difference-quotient speed: c1 = {:.6}, c2 = {:.6}", bis[0], bis[1]);
    println!("road 3, Rolle: lead lowest at {:.6} h, {:.2} km; highest at {:.6} h, {:.2} km", rol[0], lead(rol[0]), rol[1], lead(rol[1]));
    println!("positions at c1 and c2: {:.2} km and {:.2} km", s(exact[0]), s(exact[1]));
    for h in [0.1, 0.01, 0.001] {
        let (r, l) = ((lead(rol[0] + h) - lead(rol[0])) / h, (lead(rol[0] - h) - lead(rol[0])) / -h);
        println!("lead's slope over a step of {} h after c1: {:+.4}, before c1: {:+.4}", h, r, l);
    }
    let q: Vec<String> = [0.1, 0.01, 0.001].iter().map(|&h| format!("{:.4}", speed(&s, exact[0], h))).collect();
    println!("difference-quotient speed at c1, steps 0.1, 0.01, 0.001: {}", q.join(", "));
    let (x, y) = (|t: f64| 40.0 + 280.0 * t, |km: f64| 210.0 - 1.8 * km);
    let pts: Vec<String> = [(1.0 / 3.0, 0.0), (2.0 / 3.0, 100.0), (1.0, 100.0)].iter().map(|&(t, k)| format!("{:.1},{:.1}", x(t), y(k))).collect();
    println!("figure, curve M 40,210 C {}", pts.join(" "));
    for (i, &c) in exact.iter().enumerate() {
        let e = [(x(c - 0.1), y(s(c) - 10.0)), (x(c + 0.1), y(s(c) + 10.0))];
        println!("figure, tangent {} at ({:.1},{:.1}) from ({:.1},{:.1}) to ({:.1},{:.1})", i + 1, x(c), y(s(c)), e[0].0, e[0].1, e[1].0, e[1].1);
    }
    let corner = |t: f64| if t <= 0.5 { 200.0 * t } else { 100.0 };
    let jump = |t: f64| if t >= 1.0 { 100.0 } else { 0.0 };
    let gap = |t: f64| if t < 0.5 { 0.0 } else { 100.0 }; // undefined at exactly 0.5
    let (c1, c2) = (speed(&corner, 0.25, h0), speed(&corner, 0.75, h0));
    println!("breaks 1, corner: average {:.0}; speed {:.0} before 30 min, {:.0} after", corner(1.0) - corner(0.0), c1, c2);
    println!("breaks 2, jump at the end: average {:.0}; speed {:.0} at every inside time", jump(1.0) - jump(0.0), speed(&jump, 0.5, h0));
    println!("breaks 3, gap at 30 min: rate {:.0} and {:.0}, values {:.0} and {:.0}", speed(&gap, 0.25, h0), speed(&gap, 0.75, h0), gap(0.25), gap(0.75));
    assert!(exact.iter().zip(bis.iter()).all(|(e, b)| (e - b).abs() < 1e-6)); // formula vs bisection
    assert!(exact.iter().zip(rol.iter()).all(|(e, r)| (e - r).abs() < 1e-6)); // formula vs Rolle
    assert!((speed(&s, exact[0], 0.001) - 600.0 * exact[0] * (1.0 - exact[0])).abs() < 1e-3);
    let cavg = corner(1.0) - corner(0.0); // the corner trip's own average
    assert!((c1 - cavg).abs() > 99.0 && (c2 - cavg).abs() > 99.0);
    println!("ALL CHECKS PASS");
}
