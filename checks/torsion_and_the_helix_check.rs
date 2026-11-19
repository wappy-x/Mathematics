// Torsion and the helix -- the same check as the Python, in Rust.  No crates.
// A spiral staircase handrail: radius 0.8 m, rising 2.8 m per full turn.
// Torsion comes three ways: the closed form, finite differences of the binormal,
// and a polygon through the rail's posts.  A fourth road rebuilds the rail from
// curvature and torsion alone by RK4, and it must come out a helix of the same size.
use std::f64::consts::PI;

type V = [f64; 3];
fn add(u: V, v: V) -> V { [u[0] + v[0], u[1] + v[1], u[2] + v[2]] }
fn mul(k: f64, u: V) -> V { [k * u[0], k * u[1], k * u[2]] }
fn sub(u: V, v: V) -> V { add(u, mul(-1.0, v)) }
fn dot(u: V, v: V) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn cross(u: V, v: V) -> V { [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]] }
fn size(u: V) -> f64 { dot(u, u).sqrt() }
fn unit(u: V) -> V { mul(1.0 / size(u), u) }

const A: f64 = 0.8;                            // radius, metres
const RISE: f64 = 2.8;                         // rise per turn, metres
fn c0() -> f64 { RISE / (2.0 * PI) }           // rise per radian of turning
fn rail(t: f64) -> V { [A * t.cos(), A * t.sin(), c0() * t] }

fn closed_form(a: f64, c: f64) -> (f64, f64) { (a / (a * a + c * c), c / (a * a + c * c)) }   // road 1

fn frame(t: f64) -> (V, V, V, f64) {           // T, N, B from finite differences in the angle t
    let k = 1e-3;
    let d1 = mul(0.5 / k, sub(rail(t + k), rail(t - k)));
    let d2 = mul(1.0 / (k * k), add(sub(rail(t + k), mul(2.0, rail(t))), rail(t - k)));
    let (tt, b) = (unit(d1), unit(cross(d1, d2)));
    (tt, cross(b, tt), b, size(d1))
}

fn tau_by_differences(t: f64) -> f64 {         // road 2: B' = -tau N, and d/ds = (1/speed) d/dt
    let k = 1e-3;
    let (_, n, _, speed) = frame(t);
    let db = mul(0.5 / k, sub(frame(t + k).2, frame(t - k).2));
    -dot(db, n) / speed
}

fn posts(n: f64, a: f64, c: f64, flip: f64) -> Vec<V> {   // n posts per turn; flip=-1 is the mirror
    (0..4).map(|i| { let t = 2.0 * PI * i as f64 / n; [flip * a * t.cos(), a * t.sin(), c * t] }).collect()
}

fn polygon(p: &[V]) -> (f64, f64, f64) {       // road 3: turning and twisting angles between posts
    let e: Vec<V> = (0..3).map(|i| sub(p[i + 1], p[i])).collect();
    let (b1, b2) = (unit(cross(e[0], e[1])), unit(cross(e[1], e[2])));
    let bend = size(cross(e[0], e[1])).atan2(dot(e[0], e[1]));
    let twist = dot(cross(b1, b2), unit(e[1])).atan2(dot(b1, b2));
    (bend / size(e[1]), twist / size(e[1]), twist.to_degrees())
}

type Y = [V; 4];
fn rebuild(kap: f64, tau: f64, length: f64, steps: usize) -> (f64, f64, f64) {   // road 4: kappa, tau only
    let f = |y: &Y| -> Y { [y[1], mul(kap, y[2]), add(mul(-kap, y[1]), mul(tau, y[3])), mul(-tau, y[2])] };
    let go = |y: &Y, k: &Y, h: f64| -> Y { [0, 1, 2, 3].map(|j| add(y[j], mul(h, k[j]))) };
    let mut y: Y = [[0.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
    let h = length / steps as f64;
    let mut path = vec![y[0]];
    for _ in 0..steps {
        let k1 = f(&y);
        let k2 = f(&go(&y, &k1, h / 2.0));
        let k3 = f(&go(&y, &k2, h / 2.0));
        let k4 = f(&go(&y, &k3, h));
        y = [0, 1, 2, 3].map(|j| add(y[j], mul(h / 6.0, add(add(k1[j], mul(2.0, k2[j])), add(mul(2.0, k3[j]), k4[j])))));
        path.push(y[0]);
    }
    let m = kap * kap + tau * tau;             // the axis: along tau T + kappa B, through r + (kappa/m) N
    let (u, p0) = (unit([tau, 0.0, kap]), [0.0, kap / m, 0.0]);
    let radii: Vec<f64> = path.iter().map(|&r| size(sub(sub(r, p0), mul(dot(sub(r, p0), u), u)))).collect();
    let lo = radii.iter().cloned().fold(f64::INFINITY, f64::min);
    let hi = radii.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    (lo, hi, dot(path[path.len() - 1], u))
}

fn main() {
    let c = c0();
    let (kap, tau) = closed_form(A, c);
    let m = kap * kap + tau * tau;
    let speed = (A * A + c * c).sqrt();
    let l = 2.0 * PI * speed;                  // rail length of one full turn
    println!("rise per radian c = 2.8 / (2 pi)       {:.6} m", c);
    println!("a^2 + c^2                              {:.6} m^2", A * A + c * c);
    println!("speed sqrt(a^2 + c^2), per radian      {:.6} m", speed);
    println!("rail length of one turn                {:.6} m", l);
    println!("pitch angle of the rail                {:.4} deg", (c / A).atan().to_degrees());
    println!("1 closed form: kappa                   {:.6} 1/m", kap);
    println!("1 closed form: tau                     {:.6} 1/m", tau);
    println!("  as degrees per metre: kappa, tau     {:.2} {:.2}", kap.to_degrees(), tau.to_degrees());
    let taus: Vec<f64> = [0.0, 1.0, 2.0, 4.0].iter().map(|&t| tau_by_differences(t)).collect();
    let shown: Vec<String> = taus.iter().map(|x| format!("{:.6}", x)).collect();
    println!("2 differences: tau at t = 0, 1, 2, 4   {}", shown.join(" "));
    let (p14, p140) = (polygon(&posts(14.0, A, c, 1.0)), polygon(&posts(140.0, A, c, 1.0)));
    println!("3 posts, 14 per turn: kappa, tau       {:.6} {:.6}", p14.0, p14.1);
    println!("3 posts, 140 per turn: kappa, tau      {:.6} {:.6}", p140.0, p140.1);
    println!("  tau error at 14 and 140 posts        {:.6} {:.6}", (p14.1 - tau).abs(), (p140.1 - tau).abs());
    println!("  twist between neighbouring planes    {:.4} deg at 14 posts", p14.2);
    println!("kappa^2 + tau^2 = 1 / (a^2 + c^2)       {:.6} 1/m^2", m);
    println!("rebuilt helix from kappa, tau: a, c    {:.6} {:.6}", kap / m, tau / m);
    let (r24, r48) = (rebuild(kap, tau, l, 24), rebuild(kap, tau, l, 48));
    for (name, r) in [("4 RK4, 24 steps", r24), ("4 RK4, 48 steps", r48)] {
        println!("{}: radius min, max, rise   {:.6} {:.6} {:.6}", name, r.0, r.1, r.2);
    }
    println!("  radius error at 24 and 48 steps      {:.9} {:.9}", A - r24.0, A - r48.0);
    let mut back = posts(14.0, A, c, 1.0);
    back.reverse();
    println!("reverse the direction of travel: tau   {:.6}", polygon(&back).1);
    let mirror = polygon(&posts(14.0, A, c, -1.0)).1;
    println!("mirror staircase (x -> -x): tau        {:.6}", mirror);
    let flat = rebuild(kap, 0.0, l, 100);
    println!("wrong: tau per radian, not per metre   {:.6}", c / speed);
    println!("wrong: slope c / a read as the twist   {:.6}", c / A);
    println!("wrong: keep kappa, drop tau: radius    {:.6} m, rise {:.6} m", flat.1, flat.2);
    let line: Vec<V> = (0..3).map(|i| [0.0, 0.0, 0.3 * i as f64]).collect();
    println!("wrong: straight landing |e1 x e2|      {:.6}", size(cross(sub(line[1], line[0]), sub(line[2], line[1]))));
    for (label, h) in [("try: rise 4.0 m", 4.0), ("try: rise 5.026548 m (c = a)", 2.0 * PI * A), ("try: rise 10.0 m", 10.0)] {
        let (k, t) = closed_form(A, h / (2.0 * PI));
        println!("{:<38} kappa {:.6} tau {:.6}", label, k, t);
    }
    let (k12, t12) = closed_form(1.2, c);
    println!("try: radius 1.2 m, rise 2.8 m          kappa {:.6} tau {:.6}", k12, t12);
    let dna = closed_form(1.0, 3.4 / (2.0 * PI));
    println!("DNA phosphates, 1.0 nm, 3.4 nm a turn  kappa {:.6} tau {:.6} 1/nm", dna.0, dna.1);
    for (name, t) in [("far", PI / 2.0), ("near", 3.0 * PI / 2.0)] {
        let (tt, _, b, _) = frame(t);
        println!("figure, {} point at height {:.3} m: T ({:.4}, {:.4}) B ({:.4}, {:.4})", name, rail(t)[2], tt[0], tt[2], b[0], b[2]);
    }
    assert!((kap - 0.953983).abs() < 1e-6 && (tau - 0.531409).abs() < 2e-6);   // the hand-worked numbers
    assert!(taus.iter().all(|x| (x - tau).abs() < 1e-6));                       // differences against the formula
    assert!((p140.1 - tau).abs() < 1e-3 && (p140.1 - tau).abs() < (p14.1 - tau).abs());   // posts converge
    assert!((r48.0 - A).abs() < 1e-5 && (r48.0 - A).abs() < (r24.0 - A).abs());  // kappa, tau alone give radius 0.8
    assert!((r48.1 - A).abs() < 1e-5 && (r48.2 - RISE).abs() < 1e-9);           // ... and rise 2.8 m per turn
    assert!((mirror + p14.1).abs() < 1e-12 && flat.2.abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
