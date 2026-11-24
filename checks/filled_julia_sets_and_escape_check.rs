// Filled Julia sets -- the same check as the Python, in Rust.  No crates.
// The map is f(z) = z*z + c.  Road one: iterate and watch for |z| > max(2, |c|).
// Road two: exact algebra -- the golden-ratio edge for c = -1, the unit disc for c = 0.
use std::f64::consts::PI;
type C = (f64, f64);                          // a complex number as (real, imaginary)

fn f(z: C, c: C) -> C { (z.0 * z.0 - z.1 * z.1 + c.0, 2.0 * z.0 * z.1 + c.1) }
fn modulus(z: C) -> f64 { z.0.hypot(z.1) }

fn orbit(z: C, c: C, steps: usize) -> Vec<C> {    // z, f(z), f(f(z)), ... as a list
    let mut out = vec![z];
    for _ in 0..steps { let last = *out.last().unwrap(); out.push(f(last, c)) }
    out
}

fn escape_step(mut z: C, c: C, cap: usize) -> Option<usize> {   // first n beyond the radius
    let r = modulus(c).max(2.0);
    for n in 0..=cap {
        if modulus(z) > r { return Some(n) }
        z = f(z, c);
    }
    None
}

fn row(zs: &[C]) -> String {                  // orbits printed here are all real
    zs.iter().map(|z| format!("{:.6}", z.0)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let (m1, re) = ((-1.0, 0.0), |x: f64| (x, 0.0));
    println!("c = -1, start 0: {}", row(&orbit(re(0.0), m1, 4)));
    println!("c = -1, start 2: {}", row(&orbit(re(2.0), m1, 3)));
    let (a, b) = (orbit(re(1.5), m1, 6), orbit(re(1.7), m1, 3));
    println!("start 1.5: {}", row(&a));
    let o = orbit(re(1.5), m1, 1000); let big = o.iter().map(|&z| modulus(z)).fold(0.0, f64::max);
    println!("start 1.5: largest |z_n| over 1000 steps {:.6}; steps 999 and 1000: {}", big, row(&o[999..]));
    println!("start 1.7: {}; first beyond 2 at step {}", row(&b), escape_step(re(1.7), m1, 50).unwrap());
    let (b2, b3) = (modulus(b[2]), modulus(b[3]));
    let bound = b2 * (b2 - 1.0);
    println!("escape lemma at step 2: |z_3| >= {:.4} x {:.4} = {:.6}; actual {:.6}", b2, b2 - 1.0, bound, b3);
    let (mut worst, mut pairs) = (f64::INFINITY, 0);
    for x in -8..=8 { for y in -8..=8 { for k in 1..=10 { for t in 0..24 {
        let c = (x as f64 / 2.0, y as f64 / 2.0);
        let (r, th) = (modulus(c).max(2.0) * (1.0 + k as f64 / 10.0), t as f64 * PI / 12.0);
        let z = (r * th.cos(), r * th.sin());
        worst = worst.min(modulus(f(z, c)) / (modulus(z) * (modulus(z) - 1.0)));
        pairs += 1;
    }}}}
    println!("lemma on {} pairs (z, c) with |z| > max(2, |c|): smallest |f(z)| / (|z|(|z| - 1)) = {:.6}", pairs, worst);
    let (mut lo, mut hi) = (1.5_f64, 1.7_f64);   // bisection: 1.5 stays, 1.7 escapes
    for _ in 0..40 {
        let mid = (lo + hi) / 2.0;
        if escape_step(re(mid), m1, 1000).is_some() { hi = mid } else { lo = mid }
    }
    let phi = (1.0 + 5f64.sqrt()) / 2.0;
    println!("edge of the filled set on the real line, by bisection: {:.6}; golden ratio (1 + sqrt 5)/2 = {:.6}", lo, phi);
    let near = escape_step(re(1.6181), m1, 1000).unwrap();
    let stays = escape_step(re(1.618), m1, 1000).is_none();
    println!("near the edge: start 1.6180 stays for 1000 steps: {}; start 1.6181 escapes at step {}", if stays { "yes" } else { "no" }, near);
    let (h, mut inside) = (0.015, 0);
    for i in -100..=100 { for j in -100..=100 {
        if escape_step((i as f64 * h, j as f64 * h), (0.0, 0.0), 40).is_none() { inside += 1 }
    }}
    println!("c = 0 on a 201 x 201 grid, spacing {}: {} points stay; area {:.4}; unit disc pi = {:.4}", h, inside, inside as f64 * h * h, PI);
    let z6 = (0.5, 23f64.sqrt() / 2.0);           // a root of z*z - z + 6 = 0: a fixed point for c = 6
    let w6 = f(z6, (6.0, 0.0));
    println!("mistake 1, radius 2 when c = 6: z = {:.6} + {:.6}i has |z| = {:.6} > 2, yet f(z) = {:.6} + {:.6}i: it never moves",
             z6.0, z6.1, modulus(z6), w6.0, w6.1);
    println!("mistake 2, >= 2 instead of > 2, c = -2: start 2 gives {}", row(&orbit(re(2.0), (-2.0, 0.0), 3)));
    println!("mistake 3, stop after 5 steps: 1.6181 is at {:.6}, not out yet, but escapes at step {}", orbit(re(1.6181), m1, 5)[5].0, near);
    assert!(orbit(re(0.0), m1, 4).iter().map(|z| z.0).collect::<Vec<_>>() == vec![0.0, -1.0, 0.0, -1.0, 0.0]);
    assert!((b[3].0 - 5.61569841).abs() < 1e-12 && escape_step(re(1.7), m1, 50) == Some(2));
    assert!(escape_step(re(1.5), m1, 1000).is_none() && b3 >= bound && modulus((w6.0 - z6.0, w6.1 - z6.1)) < 1e-12);
    assert!(escape_step(z6, (6.0, 0.0), 10).is_none() && escape_step(re(2.0), (-2.0, 0.0), 50).is_none()); // mistakes 1, 2 stay
    assert!(worst >= 1.0 && modulus(o[1000]) < 1e-9);              // the lemma; 1.5 lands on the cycle
    assert!((lo - phi).abs() < 1e-9 && stays && near == 8);       // bisection meets the algebra
    assert!((inside as f64 * h * h - PI).abs() < 0.05);           // the grid meets the unit disc
    println!("ALL CHECKS PASS");
}
