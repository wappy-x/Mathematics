// Choosing the step -- the check behind the card.  Rust std only, no crates.
// Road 1: exact derivatives of the bond price as float sums, and the par identity.
// Road 2: difference quotients at many steps over 201 yields; the best found by search.
// Road 3: the best step predicted from the measured noise and the error law.
type Rule = fn(&dyn Fn(f64) -> f64, f64, f64) -> f64;

fn price(y: f64) -> f64 { // 30-year bond, 5% annual coupon, $100 face
    let d = 1.0 / (1.0 + y);
    let (mut df, mut s) = (1.0, 0.0);
    for _ in 1..31 { df *= d; s += 5.0 * df; }
    s + 100.0 * df
}
fn bp(b: f64) -> f64 { price(b / 1e4) } // the same bond, yield kept in basis points

fn deriv(y: f64, k: usize) -> f64 { // k-th derivative in closed form, as a float sum
    let d = 1.0 / (1.0 + y);
    let mut s = 0.0;
    for t in 1..31usize {
        let (mut r, mut dp) = (1.0, 1.0);
        for j in 0..k { r *= -((t + j) as f64); }
        for _ in 0..t + k { dp *= d; }
        s += (if t < 30 { 5.0 } else { 105.0 }) * r * dp;
    }
    s
}

fn cbrt(a: f64) -> f64 { // cube root by Newton's method, + - * / only
    let mut r = 1.0;
    for _ in 0..200 { r = (2.0 * r + a / (r * r)) / 3.0; }
    r
}
fn root(a: f64, n: usize) -> f64 {
    if n == 2 { a.sqrt() } else if n == 3 { cbrt(a) } else { a.sqrt().sqrt() }
}
fn pow2(h: f64) -> f64 { // nearest power of two: an exactly stored step
    let mut p = 1.0;
    while p > h { p /= 2.0; }
    while p * 2.0 <= h { p *= 2.0; }
    if h / p > 2f64.sqrt() { p * 2.0 } else { p }
}

fn fwd(f: &dyn Fn(f64) -> f64, x: f64, h: f64) -> f64 { (f(x + h) - f(x)) / h }
fn cen(f: &dyn Fn(f64) -> f64, x: f64, h: f64) -> f64 { (f(x + h) - f(x - h)) / (2.0 * h) }
fn sec(f: &dyn Fn(f64) -> f64, x: f64, h: f64) -> f64 { (f(x + h) - 2.0 * f(x) + f(x - h)) / (h * h) }
fn e(v: f64) -> String { format!("{:.2e}", v) }
fn rel(v: f64, t: f64) -> f64 { (v - t).abs() / t.abs() }

fn rms(g: Rule, h: f64, k: usize, unit: f64, ys: &[f64], ts: &[Vec<f64>]) -> f64 {
    let mut s = 0.0; // typical relative error of rule g; h in x's units
    for (i, &y) in ys.iter().enumerate() {
        let v = if unit == 1.0 { g(&price, y, h) } else {
            let mut u = 1.0;
            for _ in 0..k { u *= unit; }
            g(&bp, y * unit, h) * u
        };
        s += rel(v, ts[k][i]).powi(2);
    }
    (s / ys.len() as f64).sqrt()
}

fn main() {
    let eps = 2f64.powi(-52);
    let x = 0.05;
    let dd: Vec<f64> = (0..5).map(|k| deriv(x, k)).collect();
    assert!((dd[0] - 100.0).abs() < 1e-12); // coupon = yield: a par bond is worth its face
    let c = cbrt(eps);
    assert!(rel(c * c * c, eps) < 1e-15); // the cube root cubes back
    assert!(rel(cen(&price, x, 1e-6), dd[1]) < 1e-9 && rel(sec(&price, x, 1e-4), dd[2]) < 1e-6);
    println!("house: 30-year bond, 5% coupon, yield 0.05, price {:.9}", dd[0]);
    println!("eps_mach = {}; its roots 1/2, 1/3, 1/4: {}, {}, {}", e(eps), e(eps.sqrt()), e(c), e(eps.sqrt().sqrt()));
    println!("exact: P' = {:.9} ({:.6} per bp), P'' = {:.7}", dd[1], dd[1] / 1e4, dd[2]);
    println!("exact: P''' = {:.6}, P'''' = {:.4}", dd[3], dd[4]);

    let mut vals: Vec<f64> = (0..400).map(|i| price(x + i as f64 * 1e-12)).collect();
    for _ in 0..4 { vals = (0..vals.len() - 1).map(|i| vals[i + 1] - vals[i]).collect(); }
    let eta = (vals.iter().fold(0.0, |s, v| s + v * v) / vals.len() as f64 / 70.0).sqrt();
    println!("noise: eta = {} dollars from 4th differences of 400 prices, {:.1} eps P", e(eta), eta / (eps * dd[0]));
    println!("scale: (P/|P^(j)|)^(1/j) for j = 2, 3, 4: {:.4}, {:.4}, {:.4}",
             (dd[0] / dd[2]).sqrt(), cbrt(dd[0] / dd[3].abs()), (dd[0] / dd[4]).sqrt().sqrt());

    let h = 1e-12;
    let (v, vb) = (fwd(&price, x, h), fwd(&bp, 500.0, h) * 1e4);
    println!("trillionth, decimal: slope {:.7}, rel error {}, truncation part {}",
             v, e(rel(v, dd[1])), e(h * dd[2] / 2.0 / dd[1].abs()));
    let st = (500.0 + h) - 500.0;
    println!("trillionth, bp: slope {:.1}, step taken {:.6e} bp, {} too long", vb, st, e((st - h) / h));
    assert!(vb == 0.0 && rel(v, dd[1]) > 1e5 * h * dd[2] / 2.0 / dd[1].abs());

    let ys: Vec<f64> = (0..201).map(|i| 0.049 + i as f64 * 1e-5).collect();
    let ts: Vec<Vec<f64>> = (0..3).map(|k| ys.iter().map(|&y| deriv(y, k)).collect()).collect();
    let rows: [(&str, Rule, usize, usize, f64, f64); 3] = [
        ("forward", fwd, 1, 1, dd[2] / 2.0, 2.0), ("central", cen, 2, 1, dd[3] / 6.0, 1.0),
        ("second", sec, 2, 2, dd[4] / 12.0, 4.0)];
    let mut p10 = vec![1.0];
    for _ in 0..16 { let l = p10[p10.len() - 1]; p10.push(l * 10.0); }
    println!("chart, log10 h: [{}]", (1..13).map(|j| format!("{:.0}", (1.0f64 / p10[j]).log10())).collect::<Vec<_>>().join(", "));
    println!("rule     rule h   rms err  bp h     bp err   h* (eta) rms err  law      ratio best 10^-j rms err");
    for &(name, g, p, k, a, b) in rows.iter() {
        let hr = pow2(root(eps, p + k) * x);
        let hb = pow2(root(eps, p + k) * 500.0);
        let (er, eb) = (rms(g, hr, k, 1.0, &ys, &ts), rms(g, hb, k, 1e4, &ys, &ts));
        let hs = root(k as f64 * b * eta / (p as f64 * a.abs()), p + k);
        let es = rms(g, hs, k, 1.0, &ys, &ts);
        let law = (1.0 + p as f64 / k as f64) * a.abs() * (if p == 1 { hs } else { hs * hs }) / dd[k].abs();
        let errs: Vec<f64> = (1..16).map(|j| rms(g, 1.0 / p10[j], k, 1.0, &ys, &ts)).collect();
        let mut j = 0;
        for i in 0..errs.len() { if errs[i] < errs[j] { j = i; } }
        let j = j + 1;
        println!("{:<8} {:<8} {:<8} {:<8} {:<8} {:<8} {:<8} {:<8} {:.2}  {:<10} {}", name, e(hr), e(er),
                 e(hb), e(eb), e(hs), e(es), e(law), es / law, j, e(errs[j - 1]));
        assert!(hs / 10.0 < 1.0 / p10[j] && 1.0 / p10[j] < hs * 10.0 && es / law > 0.3 && es / law < 1.0 && es < errs[j - 1]);
        let pts: Vec<String> = errs[..12].iter().map(|v| format!("{:.2}", v.log10())).collect();
        println!("chart, {}, [{}]", name, pts.join(", "));
    }

    for &(base, label) in [(2f64.powi(-30), "2^-30"), (2f64.powi(-40), "2^-40")].iter() {
        let (a, b) = (rms(fwd, base, 1, 1.0, &ys, &ts), rms(fwd, base * 1.0001, 1, 1.0, &ys, &ts));
        println!("step {}: rms rel error {}; same step x1.0001: {}", label, e(a), e(b));
        assert!(b > 1.5 * a); // the inexact step is clearly worse
    }
    let (t8, r8, r9) = (1e-8 * dd[2] / 2.0 / dd[1].abs(), rms(fwd, 1e-8, 1, 1.0, &ys, &ts), rms(fwd, 1e-9, 1, 1.0, &ys, &ts));
    println!("powers of ten: 1e-8 truncation alone {}; 1e-9 rms rel error {}", e(t8), e(r9));
    assert!((r8 / t8 - 1.0).abs() < 0.01 && r9 > 1.5 * rms(fwd, 2f64.powi(-30), 1, 1.0, &ys, &ts)); // 1e-8 too big; 1e-9 inexact

    let d = 0.005; // prices quoted to the cent
    let q = |y: f64| (price(y) * 100.0 + 0.5).floor() / 100.0;
    let hq = cbrt(3.0 * d / dd[3].abs());
    let est = dd[3].abs() * hq * hq / 6.0 + d / hq; // the law's estimate
    let vq: Vec<f64> = [1e-12, 1e-4, hq].iter().map(|&h| cen(&q, x, h)).collect();
    println!("cent quotes: 3 eta/|P3| = {}, h* = {:.4e}, quotes {:.2} and {:.2}",
             e(3.0 * d / dd[3].abs()), hq, q(x - hq), q(x + hq));
    println!("cent quotes: central at 1e-12 {:.1}; at 1 bp {:.1} (rel {})", vq[0], vq[1], e(rel(vq[1], dd[1])));
    println!("cent quotes: best h {}, slope {:.1}, error {:.2}, estimate {:.2}, ratio {:.2}",
             e(hq), vq[2], (vq[2] - dd[1]).abs(), est, (vq[2] - dd[1]).abs() / est);
    assert!(vq[0] == 0.0 && (vq[2] - dd[1]).abs() <= est && rel(vq[1], dd[1]) > 0.01);
    let qe = |h: f64| ((0..ys.len()).map(|i| (cen(&q, ys[i], h) - ts[1][i]).powi(2)).fold(0.0, |s, v| s + v) / ys.len() as f64).sqrt();
    assert!(qe(hq) < 0.1 * qe(1e-4)); // typical over 201 yields: the law's step beats a 1 bp bump tenfold, not by luck
    let (a, w) = (0.004, 1e-4);
    let pi = std::f64::consts::PI;
    let wig = |y: f64| price(y) + a * (2.0 * pi * (y - x) / w).sin();
    let vw = cen(&wig, x, 1e-7);
    println!("wiggle a = {}, w = {}: slope gap {:.1}, computed {:.1}", a, w, 2.0 * pi * a / w, vw);
    assert!(((vw - dd[1]) - 2.0 * pi * a / w).abs() < 1.0);

    println!("breaks: unscaled step sqrt(eps) on 500 bp: rms {}", e(rms(fwd, pow2(eps.sqrt()), 1, 1e4, &ys, &ts)));
    println!("breaks: second derivative at central's step: rms {}", e(rms(sec, pow2(cbrt(eps) * x), 2, 1.0, &ys, &ts)));
    let hq2 = cbrt(3.0 * 0.0005 / dd[3].abs());
    let qt = |y: f64| (price(y) * 1000.0 + 0.5).floor() / 1000.0;
    println!("try: tenth-cent quotes: best h {}, error {:.2}", e(hq2), (cen(&qt, x, hq2) - dd[1]).abs());
    let (y0, t0) = (0.0001, deriv(0.0001, 1));
    println!("try: yield 0.0001: forward rel error {} with |x|; {} with x_typ 0.05",
             e(rel(fwd(&price, y0, pow2(eps.sqrt() * y0)), t0)), e(rel(fwd(&price, y0, pow2(eps.sqrt() * 0.05)), t0)));
    println!("ALL CHECKS PASS");
}
