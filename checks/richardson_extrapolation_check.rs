// Richardson extrapolation -- the same check as the Python, in Rust.  No crates.
// The bond (illustrative): $1,000 face, 30 years, a $40 coupon once a year, priced
// at a 5% yield.  x is the yield in basis points (bp), so bumps h are in bp and
// every derivative is in dollars per bp.  Road 1: the price formula differentiated
// term by term.  Road 2: central differences, alone and combined (Richardson).
// Road 3: the Taylor series, predicting each difference's error from P''' and P^(5).
const C: f64 = 40.0;
const F: f64 = 1000.0;
const N: usize = 30;
const X0: f64 = 500.0;
const BP: f64 = 1e-4;
fn price(x: f64) -> f64 {                       // discount factors by repeated multiply
    let (v, mut d, mut s) = (1.0 / (1.0 + x * BP), 1.0, 0.0);
    for _ in 1..=N { d *= v; s += C * d; }
    s + F * d
}
fn deriv(x: f64, k: usize) -> f64 {             // k-th derivative of price, term by term
    let (v, mut s) = (1.0 / (1.0 + x * BP), 0.0);
    for t in 1..=N {
        let (mut f, mut d) = (1.0, 1.0);
        for _ in 0..t + k { d *= v; }
        for j in 0..k { f *= -((t + j) as f64) * BP; }
        s += (C + if t == N { F } else { 0.0 }) * f * d;
    }
    s
}
fn cen(p: &dyn Fn(f64) -> f64, h: f64) -> f64 { (p(X0 + h) - p(X0 - h)) / (2.0 * h) }
fn rich(p: &dyn Fn(f64) -> f64, h: f64) -> f64 { (4.0 * cen(p, h) - cen(p, 2.0 * h)) / 3.0 }
fn sci(v: f64, prec: usize, plus: bool) -> String {   // Python-style e-notation
    let s = format!("{:.*e}", prec, v);
    let (m, ex) = s.split_once('e').unwrap();
    let n: i32 = ex.parse().unwrap();
    let sign = if plus && v >= 0.0 { "+" } else { "" };
    format!("{}{}e{}{:02}", sign, m, if n < 0 { '-' } else { '+' }, n.abs())
}
fn e(v: f64) -> String { sci(v, 3, true) }
fn main() {
    let pf = |x: f64| price(x);
    let (p0, p1, p3, p5) = (price(X0), deriv(X0, 1), deriv(X0, 3), deriv(X0, 5));
    println!("price at 5%, dollars                 {:.10}", p0);
    println!("exact P', dollars per bp             {:.10}", p1);
    println!("P''' per bp^3 and P^(5) per bp^5     {} {}", sci(p3, 6, false), sci(p5, 6, false));
    let (d1, d2) = (cen(&pf, 1.0), cen(&pf, 2.0));
    let r1 = (4.0 * d1 - d2) / 3.0;
    let est = (d2 - d1) / 3.0;                  // the free error estimate for D(1)
    for (name, val) in [("central, 1 bp each way", d1), ("central, 2 bp each way", d2),
                        ("Richardson (4 D(1) - D(2))/3", r1)] {
        println!("{:<30}{:.12}  error {}", name, val, e(val - p1));
    }
    println!("error ratio D(2)/D(1)                {:.4}", (d2 - p1) / (d1 - p1));
    println!("gap D(2)-D(1) {:.12}, a third of it {:.12}", d2 - d1, est);
    println!("free estimate (D(2)-D(1))/3          {}  ratio to true {:.5}", e(est), est / (d1 - p1));
    println!("series: P'''h^2/6 + P5 h^4/120, h=1  {}", e(p3 / 6.0 + p5 / 120.0));
    println!("series: -P5 h^4/30, h=1              {}", e(-p5 / 30.0));
    let r8 = (rich(&pf, 8.0) - p1) / (-p5 * 8f64.powi(4) / 30.0);
    println!("R(8) error over -P5 h^4/30, h=8      {:.5}", r8);
    println!("gain at 1 bp, central error / Richardson error  {}", sci(((d1 - p1) / (r1 - p1)).abs(), 4, false));
    let (sh, q1) = (|x: f64| price(x - 50.0), deriv(450.0, 1)); // the shelf's $10m position at 4.50%
    println!("shelf $10m at 4.50%: price {:.6}; error central {:+.6}, Richardson {} $/bp",
             10000.0 * price(450.0), 10000.0 * (cen(&sh, 1.0) - q1), e(10000.0 * (rich(&sh, 1.0) - q1)));
    println!("h bp, log10 h, central error, Richardson error, log10 of each");
    let sweep: Vec<f64> = (-8..=3).rev().map(|k| 4f64.powi(k)).collect();
    let (mut ce, mut re) = (vec![], vec![]);
    for &h in &sweep {
        let (a, b) = (cen(&pf, h) - p1, rich(&pf, h) - p1);
        ce.push(a.abs()); re.push(b.abs());
        println!("{:12.9} {:6.2} {} {} {:6.2} {:6.2}", h, h.log10(), e(a), e(b), a.abs().log10(), b.abs().log10());
    }
    let u = 2f64.powi(-53);                     // unit roundoff, written out
    let eta = u * (1.0 + X0 * BP) * p1.abs() / BP;   // price moved by one rounding of 1 + y
    let hr = (45.0 * eta / (4.0 * p5.abs())).powf(0.2);
    let hc = (3.0 * eta / p3.abs()).powf(1.0 / 3.0);
    println!("rounding per price eta, dollars      {}", sci(eta, 3, false));
    println!("best h, Richardson and central, bp   {:.3} {:.4}", hr, hc);
    let (mr, mc) = (p5.abs() * hr.powi(4) / 30.0 + 1.5 * eta / hr, p3.abs() * hc * hc / 6.0 + eta / hc);
    println!("error model at best h, R and central {} {}", sci(mr, 2, false), sci(mc, 2, false));
    let argmin = |v: &Vec<f64>| (0..v.len()).fold(0, |b, i| if v[i] < v[b] { i } else { b });
    let (ir, ic) = (argmin(&re), argmin(&ce));
    println!("observed best: Richardson {} at h {:.4}, central {} at h {:.4}",
             sci(re[ir], 2, false), sweep[ir], sci(ce[ic], 2, false), sweep[ic]);
    println!("u {}; model over measured best, R and central {:.1} {:.1}; best-step ratio {:.0}; R(4^-8) over R(1) {:.0}",
             sci(u, 3, false), mr / re[ir], mc / ce[ic], hr / hc, re[11] / re[3]);
    // what breaks
    let fwd = |h: f64| (price(X0 + h) - p0) / h;
    let w1 = 2.0 * d1 - d2;                     // treats the error as size h, not h^2
    let w2 = (4.0 * fwd(1.0) - fwd(2.0)) / 3.0; // forward difference: error is size h
    let w3 = (4.0 * d1 - cen(&pf, 3.0)) / 3.0;  // bumps 1 and 3 with the factor for 1 and 2
    let ok3 = (9.0 * d1 - cen(&pf, 3.0)) / 8.0; // the right factor, 3^2 = 9
    let w4 = rich(&pf, 4f64.powi(-8));
    let cents = |x: f64| (price(x) * 100.0 + 0.5).floor() / 100.0;
    let w5 = rich(&cents, 1.0);
    println!("prices to the cent: central 1 bp {}, central 8 bp {}, Richardson 32 bp {}",
             e(cen(&cents, 1.0) - p1), e(cen(&cents, 8.0) - p1), e(rich(&cents, 32.0) - p1));
    let cap = price(X0 - 0.5);                  // a cap half a bp below: a kink
    let capped = |x: f64| price(x).min(cap);
    let w6 = rich(&capped, 1.0);
    for (name, val) in [("weights 2 and 1", w1), ("forward differences, 4 and 3", w2),
                        ("bumps 1 and 3, factor 4", w3), ("bumps 1 and 3, factor 9", ok3),
                        ("Richardson at h = 4^-8 bp", w4), ("prices to the cent", w5),
                        ("capped price, kink at 499.5 bp", w6)] {
        println!("{:<32}{:.10}  error {}", name, val, e(val - p1));
    }
    assert!((r1 - p1).abs() < 1e-10 && (d1 - p1).abs() > 1e-7);      // the gain is real
    assert!(((d2 - p1) / (d1 - p1) - 4.0).abs() < 0.01);             // central: order 2
    assert!((re[1] / re[2] / 256.0 - 1.0).abs() < 0.01);             // Richardson: order 4
    assert!(((d1 - p1) / (p3 / 6.0 + p5 / 120.0) - 1.0).abs() < 1e-3); // series predicts error
    assert!((r8 - 1.0).abs() < 1e-2);                              // series predicts R's error
    assert!((est / (d1 - p1) - 1.0).abs() < 1e-3);                   // free estimate
    assert!(sweep[ir] >= 0.25 && sweep[ir] <= 4.0 && re[11] > 100.0 * re[3]); // rounding stops it
    assert!([w1, w2, w3, w5, w6].iter().all(|w| (w - p1).abs() > 1e-7));
    assert!((ok3 - p1).abs() < 1e-10 && (w6 - p1).abs() > 0.01);
    println!("ALL CHECKS PASS");
}
