// Fixed points and contraction: the same check as the Python, in Rust.  No crates.
// A reservoir takes in 30 m^3/s and lets water out through a pipe, 12 sqrt(x), and a
// notch, 2 x^1.5, where x is the depth in metres.  Find the steady depth x* three ways,
// then test the rate, the one-step bounds, relaxation and the failures.
const Q: f64 = 30.0;
const A: f64 = 12.0;
const B: f64 = 2.0;
fn sci(v: f64) -> String { format!("{:.2e}", v) }          // 1.23e-4
fn out(x: f64) -> f64 { A * x.sqrt() + B * x * x.sqrt() }  // outflow, m^3/s
fn ga_ab(x: f64, a: f64, b: f64) -> f64 { let c = ((Q - a * x.sqrt()) / b).cbrt(); c * c }
fn ga(x: f64) -> f64 { ga_ab(x, A, B) }                   // keep the notch
fn gb(x: f64) -> f64 { let t = (Q - B * x * x.sqrt()) / A; t * t }     // keep the pipe
fn dga(x: f64) -> f64 { -A / (3.0 * B * x.sqrt()) / ((Q - A * x.sqrt()) / B).cbrt() }
fn press(g: &dyn Fn(f64) -> f64, x: f64, n: usize, w: f64) -> Vec<f64> {
    let mut ys = vec![x];                                  // relaxed press: (1 - w) x + w g(x)
    for _ in 0..n { let x = ys[ys.len() - 1]; ys.push((1.0 - w) * x + w * g(x)); }
    ys
}
fn first(ok: &dyn Fn(usize) -> bool) -> usize { (1..=150).find(|&n| ok(n)).unwrap() }
fn vn(i: f64) -> f64 { let mut v = 1.0; for _ in 0..300 { v /= 1.0 + i; } v }  // (1 + i)^-N
fn join(xs: &[f64], f: &dyn Fn(f64) -> String) -> String { xs.iter().map(|&x| f(x)).collect::<Vec<_>>().join(", ") }
fn cardano(p: f64, r: f64) -> f64 {                        // road 1: Cardano on s = sqrt(x), s^3 + p s = r
    let dd = (r * r / 4.0 + p * p * p / 27.0).sqrt();
    let s = (r / 2.0 + dd).cbrt() + (r / 2.0 - dd).cbrt();
    s * s                                                  // x = s^2
}
fn two_sum(u: f64, v: f64) -> (f64, f64) { let s = u + v; let z = s - u; (s, (u - (s - z)) + (v - z)) }
fn two_prod(u: f64, v: f64) -> (f64, f64) {                // u v = p + e exactly, by Dekker's split
    let (p, cu, cv) = (u * v, 134217729.0 * u, 134217729.0 * v);
    let (uh, vh) = (cu - (cu - u), cv - (cv - v));
    (p, ((uh * vh - p) + uh * (v - vh) + (u - uh) * vh) + (u - uh) * (v - vh))
}
fn cubic(x: f64) -> f64 {                                  // b^2 x^3 + 2ab x^2 + a^2 x - Q^2 in double-double
    let (mut r, mut c) = (B * B, 0.0);
    for k in [2.0 * A * B, A * A, -Q * Q] {
        let (p, pe) = two_prod(r, x); let (r2, se) = two_sum(p, k); r = r2; c = c * x + (pe + se);
    }
    r + c
}
fn main() {
    let x1 = cardano(A / B, Q / B);
    let (mut lo, mut hi, mut nh) = (0.0f64, 6.25f64, 0);   // road 2: bisection
    while lo < (lo + hi) / 2.0 && (lo + hi) / 2.0 < hi {
        let mid = (lo + hi) / 2.0;
        if out(mid) < Q { lo = mid } else { hi = mid }
        nh += 1;
    }
    let dlt = -cubic(lo) / (3.0 * B * B * lo * lo + 4.0 * A * B * lo + A * A);
    let (xstar, xlo) = two_sum(lo, dlt);                   // road 4: x* = xstar + xlo, to about 1e-30 m
    let err = |v: f64| (v - xstar) - xlo;                  // true error of a double v near x*
    let d2 = -cubic(hi) / (3.0 * B * B * hi * hi + 4.0 * A * B * hi + A * A);
    assert!(((hi - xstar) + d2 - xlo).abs() < 1e-29);     // road 4 agrees from road 2's other end
    let xa = press(&ga, 2.0, 150, 1.0);                    // road 3: press g_A from 2 m
    let still = (1..=150).find(|&k| xa[k] == xa[k - 1]).unwrap();
    println!("inflow {:.0} m^3/s; outflow = {:.0} sqrt(x) + {:.0} x^1.5; steady depth x* where they match", Q, A, B);
    println!("road 1, Cardano: x* = {:.15} m", x1);
    println!("road 2, bisection: x* = {:.15} m after {} halvings; outflow - inflow = {}, next double up {}",
             lo, nh, sci(out(lo) - Q), sci(out(hi) - Q));
    println!("road 3, pressing g_A from 2: {:.15} m; stops moving at step {}", xa[150], still);
    println!("road 4, one Newton step from road 2 on the squared balance, in double-double: nearest double {:.16} m", xstar);
    println!("   true errors: Cardano {}, bisection {}, g_A {}; spacing of doubles here {}",
             sci(err(x1)), sci(err(lo)), sci(err(xa[150])), sci(2f64.powi(-51)));
    assert!((x1 - xstar).abs() < 4e-15 && (lo - xstar).abs() < 4e-15 && xa[150] == xstar);
    let qs = A / (3.0 * B * xstar);
    let dq = (ga(xstar + 1e-5) - ga(xstar - 1e-5)) / 2e-5;
    println!("slope of g_A at x*: -a/(3 b x*) = {:.6}; difference quotient {:.6}; slope of g_B: {:.6}", -qs, dq, -1.0 / qs);
    assert!((dq + qs).abs() < 1e-8 && (dga(xstar) + qs).abs() < 1e-12);
    let grid: Vec<f64> = (0..=300).map(|k| 2.0 + 1.5 * k as f64 / 300.0).collect();
    let qi = grid.iter().map(|&x| dga(x).abs()).fold(0.0f64, f64::max);
    let mut chord = 0.0f64;
    for &u in &grid { for &v in &grid { if v > u { chord = chord.max((ga(u) - ga(v)).abs() / (v - u)) } } }
    println!("g_A sends [2, 3.5] into [{:.6}, {:.6}]; worst slope q = {:.6} at x = 2; widest chord {:.6}", ga(3.5), ga(2.0), qi, chord);
    assert!(2.0 < ga(3.5) && ga(3.5) < ga(2.0) && ga(2.0) < 3.5 && chord <= qi && (qi - dga(2.0).abs()).abs() < 1e-15);
    println!("multipliers: q/(1-q) = {:.6}, q/(1+q) = {:.6}", qi / (1.0 - qi), qi / (1.0 + qi));
    println!(" k  x_k        error e_k  step d_k  e_k/e_(k-1)  q/(1-q)|d|  q/(1+q)|d|  estimate");
    for k in [1usize, 2, 3, 4, 5, 6, 10, 15, 20] {
        let (e, ep, d) = (xa[k] - xstar, xa[k - 1] - xstar, xa[k] - xa[k - 1]);
        let est = if k > 1 { let qh = d / (xa[k - 1] - xa[k - 2]); sci(qh / (qh - 1.0) * d) } else { "-".to_string() };
        println!("{:2}  {:.6}  {:>9}  {:>8}  {:11.4}  {:>10}  {:>10}  {:>8}", k, xa[k], sci(e), sci(d), e / ep,
                 sci(qi / (1.0 - qi) * d.abs()), sci(qi / (1.0 + qi) * d.abs()), est);
    }
    assert!((1..40).all(|k| (xa[k] - xstar).abs() <= qi / (1.0 + qi) * (xa[k] - xa[k - 1]).abs()));
    let (e20, d20) = ((xa[20] - xstar).abs(), (xa[20] - xa[19]).abs());
    println!("at k = 20, bound / true error: q/(1-q) gives {:.2}, q/(1+q) gives {:.2}; step ratio d_20/d_19 = {:.4}",
             qi / (1.0 - qi) * d20 / e20, qi / (1.0 + qi) * d20 / e20, (xa[20] - xa[19]) / (xa[19] - xa[18]));
    assert!(((xa[20] - xstar) / (xa[19] - xstar) + qs).abs() < 1e-3);
    let d1 = (xa[1] - xa[0]).abs();
    println!("to 1e-6 m: first-step bound promises n = {}, q/(1+q) step bound stops at {}, true error at {}",
             first(&|n| qi.powi(n as i32) / (1.0 - qi) * d1 <= 1e-6),
             first(&|n| qi / (1.0 + qi) * (xa[n] - xa[n - 1]).abs() <= 1e-6), first(&|n| (xa[n] - xstar).abs() <= 1e-6));
    let s0 = (gb(2.01) - gb(2.0)) / 0.01;                  // relax g_B: one nudge estimates its slope
    let w = 1.0 / (1.0 - s0);
    let xr = press(&gb, 2.0, 12, w);
    println!("g_B nudged at 2: slope {:.6}, so w = 1/(1 - slope) = {:.6}; relaxed slope at x*: {:.6}", s0, w, 1.0 - w * (1.0 + 1.0 / qs));
    println!("relaxed g_B errors: {}", join(&xr[..7], &|x| sci(err(x).abs())));
    assert!(((xr[4] - xstar).abs() / (xr[3] - xstar).abs() - (1.0 - w * (1.0 + 1.0 / qs)).abs()).abs() < 1e-4 && (xr[6] - xstar).abs() < 1e-15);
    let xb = press(&gb, 2.0, 40, 1.0);
    println!("break 1, plain g_B depths: {}; at step 40: {:.4}, {:.4}", join(&xb[..9], &|x| format!("{:.4}", x)), xb[39], xb[40]);
    println!("   2 x^1.5 at {:.4} is {:.4} > 30, and the square hides the minus sign", xb[39], B * xb[39] * xb[39].sqrt());
    assert!((gb(gb(xb[40])) - xb[40]).abs() < 1e-9 && (xb[40] - xstar).abs() > 2.8);
    let xo = press(&gb, 2.0, 10, 0.9);
    println!("break 2, over-relaxed w = 0.9, slope {:.4}; errors: {}", 1.0 - 0.9 * (1.0 + 1.0 / qs), join(&xo, &|x| format!("{:.4}", (x - xstar).abs())));
    assert!((xo[10] - xstar).abs() > 2.0 * (xo[0] - xstar).abs());
    println!("break 3, rounding floor: g_A's step from step {} is {:.1}, so q/(1+q)|d| = {:.1}; the true error is {}",
             still, xa[150] - xa[149], qi / (1.0 + qi) * (xa[150] - xa[149]).abs(), sci(err(xa[150])));
    let (l, m) = (300000.0f64, 1271.56f64);                // the shelf's mortgage, as on When to stop
    let gm = |i: f64| m / l * (1.0 - vn(i));
    let (mut lo, mut hi) = (1e-5f64, 0.01f64);
    while lo < (lo + hi) / 2.0 && (lo + hi) / 2.0 < hi {
        let mid = (lo + hi) / 2.0;
        if m * (1.0 - vn(mid)) / mid > l { lo = mid } else { hi = mid }
    }
    let (im, qm) = (lo, m / l * 300.0 * vn(lo) / (1.0 + lo));
    let xm = press(&gm, m / l, 200, 1.0);
    let km = first(&|n| (xm[n] - im).abs() < 1e-12);
    let qh = (xm[10] - xm[9]) / (xm[9] - xm[8]);           // step ratio at step 10
    let wm = 1.0 / (1.0 - qh);
    let ym = press(&gm, xm[10], 30, wm);
    let kr = 10 + (0..=30).find(|&n| (ym[n] - im).abs() < 1e-12).unwrap();
    println!("mortgage, {:.0} loan, 300 payments of {:.2}: rate {:.15} a month; slope of g at it {:.6}; plain steps to 1e-12: {}", l, m, im, qm, km);
    println!("   step ratio at step 10 {:.6}, w = {:.6}; relaxed from step 10, steps to 1e-12: {}", qh, wm, kr);
    assert!((qm - (xm[61] - im) / (xm[60] - im)).abs() < 1e-4 && (kr as f64) < km as f64 / 3.0);
    let lg = |v: f64| format!("{:.2}", err(v).abs().max(1e-16).log10());
    println!("chart, g_A plain:   {}", join(&xa[..13], &lg));
    println!("chart, g_B relaxed: {}", join(&xr, &lg));
    println!("chart, g_B plain:   {}", join(&xb[..13], &lg));
    println!("try: Q = 40 -> x* = {:.6}, slope {:.6}", cardano(A / B, 40.0 / B), -A / (3.0 * B * cardano(A / B, 40.0 / B)));
    println!("try: g_A relaxed, w = {:.3}: errors {}", 1.0 / (1.0 + qs), join(&press(&ga, 2.0, 3, 0.589)[1..], &|x| sci(err(x).abs())));
    println!("try: a = 30, b = 1 -> x* = {:.6}; g_A from 2 ends at {:.3}", cardano(30.0, 30.0),
             press(&|x| ga_ab(x, 30.0, 1.0), 2.0, 150, 1.0)[150]);
    println!("ALL CHECKS PASS");
}
