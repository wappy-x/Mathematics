// The Mandelbrot set -- the same check as the Python, in Rust.  No crates.  f(z) = z*z + c,
// and c is in M when the orbit of 0 stays bounded.  Road one iterates the orbit; road two is
// the algebra of fixed points and 2-cycles; road three rescales the logistic map.
#[derive(Clone, Copy, PartialEq)] struct C(f64, f64);   // a complex number: real part, imaginary part
fn add(a: C, b: C) -> C { C(a.0 + b.0, a.1 + b.1) }
fn mul(a: C, b: C) -> C { C(a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn sc(k: f64, a: C) -> C { C(k * a.0, k * a.1) }
fn md(a: C) -> f64 { a.0.hypot(a.1) }
fn orbit(c: C, z: C, n: usize) -> Vec<C> {          // z and its next n images
    let mut out = vec![z];
    for _ in 0..n { let w = *out.last().unwrap(); out.push(add(mul(w, w), c)) }
    out
}
fn escape(c: C, n: usize) -> usize {                // first step with |z| > 2, or 0 if none
    let mut z = C(0.0, 0.0);
    for k in 1..=n { z = add(mul(z, z), c); if md(z) > 2.0 { return k } }
    0
}
fn regrows(c: C) -> usize {                         // 1 if the orbit passes 2, then fails to grow
    let k = escape(c, 50);
    if k == 0 { return 0 }
    let rs: Vec<f64> = orbit(c, orbit(c, C(0.0, 0.0), k)[k], 6).iter().map(|&z| md(z)).collect();
    rs.windows(2).any(|w| w[1] <= w[0]) as usize
}
fn f4(x: f64) -> String { format!("{:.4}", (x * 1e4).round() / 1e4 + 0.0) }   // no negative zero
fn cx(z: C) -> String { format!("{}{}{}i", f4(z.0), if (z.1 * 1e4).round() < 0.0 { "-" } else { "+" }, f4(z.1.abs())) }
fn g(zs: &[C]) -> String {                          // whole-number points, written like -1+i
    zs.iter().map(|z| {
        let (a, b) = (z.0 as i64, z.1 as i64);
        let s = match b { 1 => "i".to_string(), -1 => "-i".to_string(), _ => format!("{}i", b) };
        if b == 0 { a.to_string() } else if a == 0 { s } else { format!("{}{}{}", a, if b > 0 { "+" } else { "" }, s) }
    }).collect::<Vec<_>>().join(", ")
}
fn card(l: C) -> C { add(sc(0.5, l), sc(-0.25, mul(l, l))) }    // the cardioid: fixed point with multiplier l
fn re(x: f64) -> C { C(x, 0.0) }
fn main() {
    let (i, z0) = (C(0.0, 1.0), C(0.0, 0.0));
    let oi = orbit(i, z0, 5); let m_i = sc(4.0, mul(oi[2], oi[3]));   // 2-cycle multiplier: f' = 2z at both points
    println!("house c = -1: orbit of 0 is {}; orbit of 2 is {}", g(&orbit(re(-1.0), z0, 4)), g(&orbit(re(-1.0), re(2.0), 3)));
    println!("c = i: orbit of 0 is {}: a 2-cycle, so i is in M", g(&oi));
    println!("c = i: cycle multiplier 4(-1+i)(-i) = {}, size {}; |c + 1| = {}", g(&[m_i]), f4(md(m_i)), f4(md(C(1.0, 1.0))));
    println!("c = 1: orbit of 0 is {}; first |z| > 2 at step {}", g(&orbit(re(1.0), z0, 4)), escape(re(1.0), 1000));
    println!("cardioid: lambda = 1 gives c = {}, lambda = -1 gives c = {}, |c + 1| = {}",
             f4(card(re(1.0)).0), f4(card(re(-1.0)).0), f4(md(add(card(re(-1.0)), re(1.0)))));
    let lams = [("0.5", re(0.5)), ("0.5i", C(0.0, 0.5))];
    let ps: Vec<C> = lams.iter().map(|&(_, l)| orbit(card(l), z0, 400)[400]).collect();
    for (k, &(name, l)) in lams.iter().enumerate() {
        println!("lambda = {}: c = {}, orbit of 0 settles at {}, measured 2z = {}", name, cx(card(l)), cx(ps[k]), cx(sc(2.0, ps[k])));
    }
    let c2 = -1.1; let a = orbit(re(c2), z0, 400)[400].0; let b = a * a + c2;
    println!("c = {}: orbit settles on {} and {}; 4ab = {}, formula 4(c + 1) = {}", c2, f4(a), f4(b), f4(4.0 * a * b), f4(4.0 * (c2 + 1.0)));
    let pts: Vec<C> = (-30..=30).flat_map(|x| (-30..=30).map(move |y| C(x as f64 / 10.0, y as f64 / 10.0))).collect();
    let held = pts.iter().filter(|&&c| md(c) > 2.0 && escape(c, 50) == 0).count();
    let regrew: usize = pts.iter().map(|&c| regrows(c)).sum();
    println!("grid of {} c: with |c| > 2 and bounded {}; passed 2 then failed to grow {}", pts.len(), held, regrew);
    let ring: Vec<C> = (0..200).map(|k| { let t = 2.0 * std::f64::consts::PI * k as f64 / 200.0; C(t.cos(), t.sin()) }).collect();
    let edge = ring.iter().map(|&w| card(sc(0.99, w))).chain(ring.iter().map(|&w| add(re(-1.0), sc(0.24, w))))
        .filter(|&c| escape(c, 1000) > 0).count();
    println!("400 c just inside the cardioid and the disc, 1000 steps each: escaped {}", edge);
    let (r, zs) = (3.2, orbit(card(re(3.2)), z0, 50));
    let mut xs = vec![0.5];
    for _ in 0..50 { let x = *xs.last().unwrap(); xs.push(r * x * (1.0 - x)) }
    let gap = xs.iter().zip(&zs).map(|(&x, &z)| md(add(re(r * (0.5 - x)), sc(-1.0, z)))).fold(0.0, f64::max);
    println!("logistic r = 3.2 from x = 1/2, rescaled by z = r(1/2 - x): matches c = {} for 50 steps: {}",
             f4(card(re(r)).0), if gap < 1e-9 { "yes" } else { "no" });
    println!("slow escape: c = 0.26 first passes 2 at step {}", escape(re(0.26), 1000));
    println!("mistake, |z| >= 2 as escape: c = -2 has orbit {}, never past 2: {}", g(&orbit(re(-2.0), z0, 4)),
             if escape(re(-2.0), 1000) == 0 { "yes" } else { "no" });
    let o = orbit(re(0.75), z0, 3).iter().map(|z| f4(z.0)).collect::<Vec<_>>().join(", ");
    println!("mistake, cardioid sign flipped: lambda = 1 gives c = {}, orbit {}, out at step {}", f4(0.5 + 0.25), o, escape(re(0.75), 1000));
    println!("mistake, disc |c + 1| < 1: c = -1.9 gets 2-cycle multiplier 4(c + 1) = {}", f4(4.0 * (-1.9 + 1.0)));
    println!("figure, cusp {}, back {}, disc centre -1 radius {}, points i 1 -1 -2, 100 px per unit", f4(card(re(1.0)).0), f4(card(re(-1.0)).0), f4(0.25));
    assert!(oi[2] == oi[4] && oi[2] == C(-1.0, 1.0) && oi[3] == oi[5] && oi[3] == C(0.0, -1.0) && escape(re(1.0), 1000) == 3);
    assert!(md(add(sc(2.0, ps[0]), re(-0.5))) < 1e-9 && md(add(sc(2.0, ps[1]), C(0.0, -0.5))) < 1e-9);
    assert!((4.0 * a * b - 4.0 * (c2 + 1.0)).abs() < 1e-9);
    assert!(held == 0 && regrew == 0 && edge == 0 && escape(card(re(-1.0)), 1000) == 0);
    assert!(gap < 1e-9);
    println!("ALL CHECKS PASS");
}
