// Truncation versus rounding -- the check behind the card.  Rust std only.
// Road one: closed forms (the stone's speed 29.4 m/s and its truncation 4.9h;
// pi; e).  Road two: each method run at many steps, error against its law.
// Road three: the same slope in single precision, where only rounding changes.
const U: f64 = 1.0 / 9007199254740992.0; // 2^-53, unit roundoff of a double
const V: f64 = 29.4; // exact speed at t = 3 s
fn sci(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }
fn s(t: f64) -> f64 { 4.9 * t * t } // metres fallen after t seconds
fn s32(t: f32) -> f32 { 4.9f32 * t * t } // the same, in single precision
fn fwd_at(h: f64, t: f64) -> f64 { (s(t + h) - s(t)) / h }
fn fwd(h: f64) -> f64 { fwd_at(h, 3.0) }
fn ctr(h: f64) -> f64 { (s(3.0 + h) - s(3.0 - h)) / (2.0 * h) }
fn fwd32(h: f64) -> f64 {
    let h = h as f32;
    ((s32(3.0f32 + h) - s32(3.0)) / h) as f64
}
fn lg(x: f64) -> f64 { x.abs().log10() }
fn halve(h: f64) -> f64 { (fwd(h) - fwd(h / 2.0)) / (fwd(h / 2.0) - fwd(h / 4.0)) }
fn main() {
    let e = std::f64::consts::E;
    let pi = std::f64::consts::PI;
    println!("stone: s(3) = {:.12} m, s(3.01) = {:.12} m, exact speed 29.4 m/s; u = {}", s(3.0), s(3.01), sci(U, 2));
    let (mut fl, mut cl) = (Vec::new(), Vec::new());
    for k in 1..14 {
        let h = 10f64.powi(-k);
        let (f, c) = (fwd(h), ctr(h));
        fl.push(format!("{:.2}", lg(f - V)));
        cl.push(format!("{:.2}", lg(c - V)));
        println!("h=1e-{}: forward {:.12} err {} = trunc {} + round {} (estimate {}); central err {}",
            k, f, sci(f - V, 2), sci(4.9 * h, 2), sci(f - V - 4.9 * h, 2), sci(2.0 * U * s(3.0) / h, 2), sci(c - V, 2));
    }
    println!("chart forward log10 err: {}", fl.join(", "));
    println!("chart central log10 err: {}", cl.join(", "));
    println!("step actually taken at h=1e-12: (3 + h) - 3 = {}", sci((3.0 + 1e-12) - 3.0, 6));
    let (q2, q12) = (halve(1e-2), halve(1e-12));
    println!("halving test (change over next change, 2 if truncation rules): h=1e-2 {:.6}; h=1e-12 {:.6}", q2, q12);
    for h in [1e-2, 1e-3, 1e-12] {
        println!("precision test h={}: double {:.6}, single {:.6}, shift {}", sci(h, 0), fwd(h), fwd32(h), sci(fwd32(h) - fwd(h), 2));
    }
    println!("stone at t=30 s, h=1e-12: forward err {}, truncation still {}", sci(fwd_at(1e-12, 30.0) - 294.0, 2), sci(4.9e-12, 2));
    // cut-off series for e = 1 + 1/1! + 1/2! + ...
    let (mut term, mut tot) = (1.0f64, 1.0f64);
    let mut ser = [0.0f64; 21];
    for n in 1..21 {
        term /= n as f64;
        tot += term;
        ser[n] = tot - e;
    }
    for n in [5usize, 10, 15, 16, 17, 20] {
        let mut nxt = 1.0f64;
        for j in 1..n + 2 {
            nxt /= j as f64;
        }
        println!("series to 1/{}!: err {}, next term {}", n, sci(ser[n], 2), sci(nxt, 2));
    }
    // trapezoid rule for pi = integral of 4/(1+x^2) from 0 to 1; law -h^2/6
    let mut tr = [0.0f64; 8];
    for k in 1..8 {
        let n = 10u64.pow(k as u32);
        let mut acc = 3.0f64;
        for i in 1..n {
            let x = i as f64 / n as f64;
            acc += 4.0 / (1.0 + x * x);
        }
        tr[k] = acc / n as f64 - pi;
        let law = -1.0 / (6.0 * n as f64 * n as f64);
        println!("trapezoid n=1e{}: err {}, law {}, ratio {:.4}", k, sci(tr[k], 2), sci(law, 2), tr[k] / law + 0.0);
    }
    // Euler steps for y' = y, y(0) = 1, to y(1) = e; law -e/(2N)
    let mut eu = [0.0f64; 8];
    for k in 1..8 {
        let n = 10u64.pow(k as u32);
        let nf = n as f64;
        let mut y = 1.0f64;
        for _ in 0..n {
            y += y / nf;
        }
        eu[k] = y - e;
        println!("Euler N=1e{}: err {}, law {}, ratio {:.6}", k, sci(eu[k], 2), sci(-e / (2.0 * nf), 2), eu[k] / (-e / (2.0 * nf)));
    }
    // the house example: 0.1 added ten million times (no truncation at all)
    let mut tot = 0.0f64;
    for _ in 0..10_000_000 {
        tot += 0.1;
    }
    let bound = 1e7 * U * 1e6;
    println!("tracker: 0.1 added 1e7 times = {:.10}, err {}, bound n u total {}, ratio {:.3}", tot, sci(tot - 1e6, 2), sci(bound, 2), (1e6 - tot) / bound);
    let (mut t8, mut y) = (0.0f64, 1.0f64); // two "Try changing" experiments
    for _ in 0..10_000_000 {
        t8 += 0.125;
        y *= 1.0 + 1.0 / 1e7;
    }
    println!("try: 0.125 added 1e7 times err {}; Euler as y *= 1 + 1/N at N=1e7: ratio {:.6}", sci(t8 - 1.25e6, 2), (y - e) / (-e / 2e7));
    let fact11: f64 = (1..12).map(|j| j as f64).product();
    assert!((fwd(1e-2) - V - 4.9e-2).abs() < 1e-11); // truncation is exactly 4.9h
    assert!((ctr(1e-12) - V).abs() > 1e7 * (ctr(1e-2) - V).abs()); // central: pure rounding grows
    assert!((fwd(1e-8) - V).abs() * 1000.0 < (fwd(1e-12) - V).abs()); // a smaller step got worse
    assert!((q2 - 2.0).abs() < 1e-6 && (q12 - 2.0).abs() > 1.0); // halving test tells them apart
    assert!(fwd32(1e-12) == 0.0 && (fwd32(1e-2) - fwd(1e-2)).abs() < 1e-3);
    assert!(1.0 < -ser[10] * fact11 && -ser[10] * fact11 < 1.1 && ser[20].abs() <= 2.0 * U * e); // tail, then floor
    assert!((1..5).all(|k| (tr[k] * 6.0 * 100f64.powi(k as i32) + 1.0).abs() < 1e-3) && tr[7] > 0.0); // law, then flip
    assert!((3..8).all(|k| (eu[k] / (-e / (2.0 * 10f64.powi(k as i32))) - 1.0).abs() < 2e-3));
    assert!(0.0 < 1e6 - tot && 1e6 - tot < bound);
    println!("ALL CHECKS PASS");
}
