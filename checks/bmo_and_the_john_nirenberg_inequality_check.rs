// BMO and the John-Nirenberg inequality -- the same check as the Python script, in Rust.
// std only, no crates.  f(t) = ln|t|, and the partner of a 1 V gate open from t = 0 to t = 1 s:
// Hg(t) = (1/pi) ln|t/(t - 1)| volts.  Every mean oscillation is found two ways:
// exactly, from an antiderivative split where f crosses its mean, and by the midpoint rule.
use std::f64::consts::{E, PI};

struct Func { h: Box<dyn Fn(f64) -> f64>, big_f: Box<dyn Fn(f64) -> f64>, roots: Box<dyn Fn(f64) -> Vec<f64>> }
fn xl(t: f64) -> f64 { if t != 0.0 { t * t.abs().ln() } else { 0.0 } }
fn log_fn() -> Func {
    Func { h: Box::new(|t: f64| t.abs().ln()), big_f: Box::new(|t: f64| xl(t) - t),
           roots: Box::new(|m: f64| vec![m.exp(), -m.exp()]) }
}
fn partner(p: f64, q: f64) -> Func { // (1/pi) ln|(t-p)/(t-q)|: H of a 1 V gate on [p, q]
    Func {
        h: Box::new(move |t: f64| ((t - p) / (t - q)).abs().ln() / PI),
        big_f: Box::new(move |t: f64| (xl(t - p) - xl(t - q)) / PI),
        roots: Box::new(move |m: f64| {
            let r = (PI * m).exp();
            let mut v = vec![(p + r * q) / (1.0 + r)];
            if (r - 1.0).abs() > 1e-12 { v.push((p - r * q) / (1.0 - r)); } v }),
    }
}
fn osc(f: &Func, a: f64, b: f64, mm: Option<f64>) -> (f64, f64) {
    let mean = ((f.big_f)(b) - (f.big_f)(a)) / (b - a);
    let m = mm.unwrap_or(mean);
    let mut r: Vec<f64> = (f.roots)(m).into_iter().filter(|&t| a < t && t < b).collect();
    r.sort_by(|x, y| x.partial_cmp(y).unwrap());
    let mut pts = vec![a]; pts.extend(r); pts.push(b);
    let mut s = 0.0;
    for w in pts.windows(2) {
        let (p, q) = (w[0], w[1]); let sg = if (f.h)(p + 0.37 * (q - p)) > m { 1.0 } else { -1.0 };
        s += sg * ((f.big_f)(q) - (f.big_f)(p) - m * (q - p));
    }
    (mean, s / (b - a))
}
fn mid<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let w = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 0..n { s += f(a + (k as f64 + 0.5) * w); } w * s
}
fn golden<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..120 {
        let (x1, x2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(x1) > f(x2) { hi = x2 } else { lo = x1 }
    }
    (lo + hi) / 2.0
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn jn(lam: f64, b: f64) -> f64 { E * (-lam / (2.0 * E * b)).exp() }
fn tlog(lam: f64) -> f64 { (-1.0 - lam).exp() + f64::max(0.0, 1.0 - (lam - 1.0).exp()) }

fn main() {
    let (lg, hg) = (log_fn(), partner(0.0, 1.0));
    // 1. ln|t| on [0, 1]: mean -1, mean oscillation 2/e; the same on [0, a] and [-a, a].
    let (m01, o01) = osc(&lg, 0.0, 1.0, None);
    let o_mid = mid(|v| 3.0 * v * v * (3.0 * v.ln() + 1.0).abs(), 0.0, 1.0, 200000);
    println!("ln|t| on [0,1]: mean {:.6}; mean oscillation exact {:.6}, midpoint {:.6}, 2/e = {:.6}", m01, o01, o_mid, 2.0 / E);
    assert!((m01 + 1.0).abs() < 1e-12 && (o01 - 2.0 / E).abs() < 1e-12 && (o_mid - 2.0 / E).abs() < 1e-6);
    for (lab, a) in [("0.001", 0.001), ("1000", 1000.0)] {
        let (m, o) = osc(&lg, 0.0, a, None);
        let o2 = osc(&lg, -a, a, None).1;
        println!("ln|t| on [0,{}]: mean {:.6}, mean oscillation {:.6}; on [-{},{}]: {:.6}", lab, m, o, lab, lab, o2);
        assert!((o - 2.0 / E).abs() < 1e-9 && (o2 - 2.0 / E).abs() < 1e-9);
    }
    // 2. Its BMO norm: by scaling and mirroring, every interval is some [u, 1] with -1 <= u < 1.
    let grid = (0..2000).map(|k| osc(&lg, -1.0 + k as f64 / 1000.0, 1.0, None).1).fold(f64::MIN, f64::max);
    let u = golden(|u| osc(&lg, u, 1.0, None).1, -0.5, 0.0);
    let (mu, b) = osc(&lg, u, 1.0, None);
    let mut c = mid(|v| 3.0 * v * v * (3.0 * v.ln() - mu).abs(), 0.0, 1.0, 200000);
    c += mid(|v| 3.0 * v * v * (3.0 * v.ln() - mu).abs(), 0.0, (-u).powf(1.0 / 3.0), 200000);
    println!("BMO norm of ln|t|: largest at [{:.5}, 1], mean {:.6}, oscillation {:.6}; midpoint {:.6}; grid of 2000 {:.6}",
             u, mu, b, c / (1.0 - u), grid);
    assert!(grid <= b + 1e-12 && b - grid < 1e-5 && (c / (1.0 - u) - b).abs() < 1e-6 && b > 2.0 / E);

    // 3. The gate g has BMO norm 1/2; its partner Hg is unbounded but has a finite BMO norm.
    let gate = |t: f64| if 0.0 < t && t < 1.0 { 1.0 } else { 0.0 };
    let gm = mid(gate, -1.0, 1.0, 20000) / 2.0; let go = mid(|t| (gate(t) - gm).abs(), -1.0, 1.0, 20000) / 2.0;
    let gbest = (0..1001).map(|k| { let th = k as f64 / 1000.0; 2.0 * th * (1.0 - th) }).fold(f64::MIN, f64::max);
    println!("gate g: on [-1,1] mean {:.6}, mean oscillation {:.6}; over all intervals 2 th (1 - th) peaks at {:.6}", gm, go, gbest);
    assert!((go - 0.5).abs() < 1e-9 && (gbest - go).abs() < 1e-12);
    println!("Hg at 0.001 s past the edge: {:.3} V; at 0.000001 s: {:.3} V", (hg.h)(1.001), (hg.h)(1.000001));
    let (mh, oh) = osc(&hg, 0.0, 1.0, None);
    let oh_mid = 2.0 * mid(|v| 3.0 * v * v * (hg.h)(v.powf(3.0)).abs(), 0.0, 0.5f64.powf(1.0 / 3.0), 200000);
    println!("Hg on [0,1]: mean {:.6}; mean oscillation exact {:.6}, midpoint {:.6}, (2/pi) ln 2 = {:.6}", mh, oh, oh_mid, 2.0 * 2f64.ln() / PI);
    assert!(mh.abs() < 1e-12 && (oh - 2.0 * 2f64.ln() / PI).abs() < 1e-12 && (oh_mid - oh).abs() < 1e-6);
    let s = golden(|s| osc(&hg, 0.5 - s, 0.5 + s, None).1, 0.3, 1.5); let bh = osc(&hg, 0.5 - s, 0.5 + s, None).1;
    let mut grid_h = f64::MIN;
    for i in 0..250 { for j in (i + 1)..251 { grid_h = grid_h.max(osc(&hg, -2.0 + 0.02 * i as f64, -2.0 + 0.02 * j as f64, None).1); } }
    println!("BMO norm of Hg: largest at [{:.4}, {:.4}], half-width {:.6}, oscillation {:.6} V; grid of 31375 intervals {:.6} V",
             0.5 - s, 0.5 + s, s, bh, grid_h);
    assert!(grid_h <= bh + 1e-9 && bh - grid_h < 1e-3);

    // 4. Singular integrals map L-infinity into BMO: ||Hf||_BMO <= 2 (sqrt 2 + ln(3)/pi) ||f||_inf.
    let hor = mid(|s| 1.0 / (PI * (2.0 * s.exp() - 1.0)) + 1.0 / (PI * (2.0 * s.exp() + 1.0)), 0.0, 30.0, 300000);
    println!("smoothness constant, integral of |K(t-1) - K(t)| over |t| > 2: {:.6}, ln(3)/pi = {:.6}", hor, 3f64.ln() / PI);
    assert!((3f64.ln() / PI - hor).abs() < 1e-9);
    let cc = 2.0 * (2f64.sqrt() + 3f64.ln() / PI);
    println!("bound: 2 x (sqrt 2 + ln(3)/pi) = 2 x ({:.6} + {:.6}) = {:.6}; Hg uses {:.6} of it, ratio {:.6}",
             2f64.sqrt(), 3f64.ln() / PI, cc, bh, bh / cc);
    let (near, far) = (partner(0.5, 1.0), partner(0.0, 0.5)); // I = [0.75, 1.25], centre 1, doubled I = [0.5, 1.5]
    let n1 = osc(&near, 0.75, 1.25, Some(0.0)).1;
    let n2 = (0..5001).map(|k| ((far.h)(0.75 + k as f64 / 10000.0) - (far.h)(1.0)).abs()).fold(f64::MIN, f64::max);
    let (m_i, o_i) = osc(&hg, 0.75, 1.25, None);
    let o_i_mid = [1.0, -1.0].iter().map(|&sg| mid(|v| 3.0 * v * v * ((1.0 + 1.0 / (sg * v.powf(3.0))).abs().ln() / PI - m_i).abs(), 0.0, 0.25f64.powf(1.0 / 3.0), 100000)).sum::<f64>() / 0.5;
    println!("I = [0.75,1.25]: near part average |Hf1| {:.6} <= sqrt 2; far part |Hf2 - Hf2(1)| at most {:.6} <= ln(3)/pi; so MO <= 2 x {:.6} = {:.6}; true MO {:.6}, midpoint {:.6}",
             n1, n2, n1 + n2, 2.0 * (n1 + n2), o_i, o_i_mid);
    assert!(n1 <= 2f64.sqrt() && n2 <= 3f64.ln() / PI && o_i <= 2.0 * (n1 + n2) && (o_i - o_i_mid).abs() < 1e-6);

    // 5. John-Nirenberg: share of I where |f - f_I| > lam is at most e exp(-lam / (2e ||f||_BMO)).
    let n = 1000000;
    for lam in [1, 2, 4, 8] {
        let l = lam as f64;
        let cnt = (0..n).filter(|&k| (((k as f64 + 0.5) / n as f64).ln() + 1.0).abs() > l).count() as f64 / n as f64;
        println!("ln|t|, I = [0,1], lam = {}: share exact {:.6}, grid {:.6}; bound {:.6}; bound/true {:.1}",
                 lam, tlog(l), cnt, jn(l, b), jn(l, b) / tlog(l));
        assert!((cnt - tlog(l)).abs() < 2e-6 && tlog(l) <= jn(l, b));
    }
    for lam in [0.5, 1.0, 2.0] {
        let cnt = (0..n).filter(|&k| (hg.h)((k as f64 + 0.5) / n as f64).abs() > lam).count() as f64 / n as f64;
        let ex = 2.0 / (1.0 + (PI * lam).exp());
        println!("Hg, I = [0,1], lam = {:.1} V: share exact {:.6}, grid {:.6}; bound {:.6}", lam, ex, cnt, jn(lam, bh));
        assert!((cnt - ex).abs() < 2e-6 && ex <= jn(lam, bh));
    }
    let al = E * b; // the stopping level of the proof, alpha = e ||f||_BMO
    let (avg16, avg8) = (osc(&lg, 0.0, 1.0 / 16.0, Some(-1.0)).1, osc(&lg, 0.0, 1.0 / 8.0, Some(-1.0)).1); // average of |ln t + 1|
    println!("stopping level alpha = e x ||f||_BMO = {:.6} x {:.6} = {:.6}; [0,1/8] averages {:.6} (go on), [0,1/16] averages {:.6} (stop), <= 2 alpha = {:.6}",
             E, b, al, avg8, avg16, 2.0 * al);
    assert!(avg8 <= al && al < avg16 && avg16 <= 2.0 * al && 1.0 / 16.0 <= 1.0 / al);
    for k in [1, 2, 3] {
        let len = 16f64.powf(-(k as f64));
        println!("generation {}: box [0, 16^-{}] of length {:.8}; its mean differs from f_I by {:.6}; beyond lam = {:.6} the share is at most {:.8}",
                 k, k, len, osc(&lg, 0.0, len, None).0 + 1.0, k as f64 * 2.0 * al, len);
        assert!(tlog(k as f64 * 2.0 * al) <= len);
    }
    let beta: f64 = 0.5; // the rate of Step 6
    let ei = (-1f64).exp() / (1.0 - beta) + (beta.exp() - (-1f64).exp()) / (1.0 + beta);
    let ei_mid = mid(|v| 4.0 * v.powf(3.0) * (beta * (4.0 * v.ln() + 1.0).abs()).exp(), 0.0, 1.0, 200000);
    println!("average of exp(beta |ln t + 1|) on [0,1], beta = {:.1}: exact {:.6}, midpoint {:.6}; finite exactly when beta is below 1", beta, ei, ei_mid);
    assert!((ei - ei_mid).abs() < 1e-6);

    // 6. What breaks: no single interval decides; a bounded factor; units.
    for (lab, a) in [("1", 1.0f64), ("0.01", 0.01), ("0.000001", 0.000001)] {
        let sq_mo = 2.0 * mid(|v| 2.0 * v * (1.0 / v - 2.0 / a.sqrt()).abs(), 0.0, (a / 4.0).powf(0.5), 20000) / a; // t = v^2
        let sl = mid(|v| 3.0 * v * v * (3.0 * v.ln()).abs(), 0.0, a.powf(1.0 / 3.0), 20000) / a;
        println!("on [0,{}]: t^(-1/2) mean oscillation {:.6}; on [-{},{}]: sgn(t) ln|t| mean oscillation {:.6}, 1 - ln a = {:.6}",
                 lab, sq_mo, lab, lab, sl, 1.0 - a.ln());
        assert!((sq_mo - 1.0 / a.sqrt()).abs() < 1e-6 * sq_mo && (sl - (1.0 - a.ln())).abs() < 1e-4);
    }
    for lam in [8, 98] {
        println!("I = [0,1], lam = {}: t^(-1/2) share 1/(2+lam)^2 = {:.6}; ln|t| share 10^{:.2}",
                 lam, 1.0 / ((2 + lam) * (2 + lam)) as f64, tlog(lam as f64).ln() / 10f64.ln());
    }
    println!("I = [0,1], lam = 5: 10 ln|t| share {:.6}; ln|t| share {:.6}", tlog(0.5), tlog(5.0));

    // 7. Chart points.
    let ts: Vec<f64> = (0..30).map(|k| -0.95 + 0.1 * k as f64).collect();
    println!("chart t s: [{}]", join(&ts, 2));
    println!("chart g V: [{}]", join(&ts.iter().map(|&t| gate(t)).collect::<Vec<_>>(), 0));
    println!("chart Hg V: [{}]", join(&ts.iter().map(|&t| (hg.h)(t)).collect::<Vec<_>>(), 3));
    let ls: Vec<f64> = (0..9).map(|k| 2.0 * k as f64).collect(); let lg10 = |x: f64| x.ln() / 10f64.ln();
    let sq = |l: f64| if l < 1.0 { 1.0 / (2.0 + l).powf(2.0) + f64::max(0.0, 1.0 - 1.0 / (2.0 - l).powf(2.0)) } else { 1.0 / (2.0 + l).powf(2.0) };
    println!("chart log10 share ln|t|: [{}]", join(&ls.iter().map(|&x| lg10(tlog(x))).collect::<Vec<_>>(), 2));
    println!("chart log10 bound ln|t|: [{}]", join(&ls.iter().map(|&x| lg10(f64::min(1.0, jn(x, b)))).collect::<Vec<_>>(), 2));
    println!("chart log10 share t^(-1/2): [{}]", join(&ls.iter().map(|&x| lg10(sq(x))).collect::<Vec<_>>(), 2));
    println!("ALL CHECKS PASS");
}
