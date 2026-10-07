// Barrier inverses -- the check behind the card.  Rust std only, no crates.
// Three roads to a barrier price: the closed form, an integral over where the share
// ends weighted by the Brownian-bridge chance of never touching, and a finite-difference
// grid.  The normal CDF, the integrator, the grid and both root finders are written here.
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn n(x: f64) -> f64 { // 1/2 + phi(x) * (x + x^3/3 + x^5/(3*5) + ...)
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while t.abs() > 1e-17 * s.abs() { t *= x * x / (2.0 * k + 1.0); s += t; k += 1.0; }
    0.5 + phi(x) * s
}
fn vanilla(sig: f64) -> f64 {
    let v = sig * T.sqrt(); let d1 = ((S / K).ln() + (R - Q + 0.5 * sig * sig) * T) / v;
    S * (-Q * T).exp() * n(d1) - K * (-R * T).exp() * n(d1 - v)
}
fn down_out(h: f64, sig: f64) -> f64 { // road 1, closed form, barrier h <= strike K
    let v = sig * T.sqrt(); let lam = (R - Q + 0.5 * sig * sig) / (sig * sig);
    let y = (h * h / (S * K)).ln() / v + lam * v;
    let d_in = S * (-Q * T).exp() * (h / S).powf(2.0 * lam) * n(y) - K * (-R * T).exp() * (h / S).powf(2.0 * lam - 2.0) * n(y - v);
    vanilla(sig) - d_in
}
fn up_out(h: f64, sig: f64) -> f64 { // road 1, closed form, barrier h above strike K
    let v = sig * T.sqrt(); let lam = (R - Q + 0.5 * sig * sig) / (sig * sig);
    let x1 = (S / h).ln() / v + lam * v; let y = (h * h / (S * K)).ln() / v + lam * v; let y1 = (h / S).ln() / v + lam * v;
    let u_in = S * (-Q * T).exp() * n(x1) - K * (-R * T).exp() * n(x1 - v)
        - S * (-Q * T).exp() * (h / S).powf(2.0 * lam) * (n(-y) - n(-y1))
        + K * (-R * T).exp() * (h / S).powf(2.0 * lam - 2.0) * (n(-y + v) - n(-y1 + v));
    vanilla(sig) - u_in
}
fn bridge(h: f64, sig: f64, up: bool) -> f64 { // road 2: Simpson over the end point z
    let nn = 4000; let v = sig * T.sqrt(); let m = (R - Q - 0.5 * sig * sig) * T;
    let a = ((K / S).ln() - m) / v;
    let b = if up { (((h / S).ln() - m) / v).min(12.0) } else { 12.0 };
    let hh = (b - a) / nn as f64; let mut tot = 0.0;
    for i in 0..=nn {
        let z = a + i as f64 * hh; let st = S * (m + v * z).exp();
        let alive = 1.0 - (-2.0 * (S / h).ln() * (st / h).ln() / (sig * sig * T)).exp();
        let w = if i == 0 || i == nn { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * (st - K) * alive * phi(z);
    }
    (-R * T).exp() * tot * hh / 3.0
}
fn grid(h: f64, sig: f64, up: bool) -> f64 { // road 3: explicit finite differences in log price
    let m = 40usize; let dx = (h / S).ln().abs() / m as f64; let j = m + (6.0 * sig * T.sqrt() / dx) as usize + 2;
    let lo = if up { h.ln() - j as f64 * dx } else { h.ln() };
    let xs: Vec<f64> = (0..=j).map(|i| lo + i as f64 * dx).collect();
    let mut v: Vec<f64> = xs.iter().map(|x| (x.exp() - K).max(0.0)).collect();
    v[if up { j } else { 0 }] = 0.0;
    let steps = (T * sig * sig / (0.9 * dx * dx)) as usize + 1; let dt = T / steps as f64;
    let nu = R - Q - 0.5 * sig * sig; let a = 0.5 * sig * sig / (dx * dx); let b = nu / (2.0 * dx);
    for k in 1..=steps {
        let mut w = vec![0.0; j + 1];
        for i in 1..j {
            w[i] = v[i] + dt * (a * (v[i + 1] - 2.0 * v[i] + v[i - 1]) + b * (v[i + 1] - v[i - 1]) - R * v[i]);
        }
        if !up { w[j] = (xs[j] - Q * k as f64 * dt).exp() - K * (-R * k as f64 * dt).exp(); }
        v = w;
    }
    v[if up { j - m } else { m }]
}
fn bisect(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> Option<f64> { // needs a sign change
    let mut fa = f(a);
    if fa * f(b) > 0.0 { return None; }
    for _ in 0..80 {
        let c = 0.5 * (a + b); let fc = f(c);
        if (fc > 0.0) == (fa > 0.0) { a = c; fa = fc; } else { b = c; }
    }
    Some(0.5 * (a + b))
}
fn secant(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 { // second root finder, on road 2
    let (mut fa, mut fb) = (f(a), f(b));
    for _ in 0..40 {
        if fb == fa { break; }
        let c = b - fb * (b - a) / (fb - fa); a = b; fa = fb; b = c; fb = f(b);
    }
    b
}
fn out(label: &str, x: Option<f64>) {
    match x { Some(v) => println!("{:<40} {:>12.6}", label, v), None => println!("{:<40}         none", label) }
}
fn row(label: &str, xs: &[f64], w: usize, p: usize) {
    let parts: Vec<String> = xs.iter().map(|x| format!("{:w$.p$}", x, w = w, p = p)).collect();
    println!("{}{}", label, parts.join(" "));
}
fn main() {
    let sig = 0.20;
    let c = vanilla(sig); let do80 = down_out(80.0, sig); let do80b = bridge(80.0, sig, false);
    out("vanilla call, vol 20%", Some(c)); out("down-and-out, barrier 80, formula", Some(do80));
    out("down-and-out, barrier 80, bridge", Some(do80b)); out("down-and-in, barrier 80", Some(c - do80));
    let lam = (R - Q + 0.5 * sig * sig) / (sig * sig); out("lambda at vol 20%", Some(lam));
    out("y at barrier 80", Some((80.0f64 * 80.0 / (S * K)).ln() / (sig * T.sqrt()) + lam * sig * T.sqrt()));
    let levels = [50.0, 60.0, 70.0, 80.0, 85.0, 88.0, 90.0, 92.0, 94.0, 96.0, 98.0, 100.0];
    row("chart, barrier  ", &levels, 6, 0);
    row("chart, DO price ", &levels.iter().map(|&h| down_out(h, sig)).collect::<Vec<_>>(), 6, 2);
    let (mut a, mut b, mut mids) = (50.0, 100.0, Vec::new());
    for _ in 0..7 { let c = 0.5 * (a + b); mids.push(c); if down_out(c, sig) > 8.0 { a = c; } else { b = c; } }
    println!("bisection, midpoint {}", mids.iter().map(|h| format!("{:.6}", h)).collect::<Vec<_>>().join(" "));
    row("bisection, DO price ", &mids.iter().map(|&h| down_out(h, sig)).collect::<Vec<_>>(), 9, 4);
    let h1 = bisect(&|h| down_out(h, sig) - 8.0, 50.0, 100.0).unwrap();
    let h2 = secant(&|h| bridge(h, sig, false) - 8.0, 85.0, 92.0);
    out("level for 8.00, bisection on formula", Some(h1)); out("level for 8.00, secant on bridge", Some(h2));
    out("DO at that level, formula", Some(down_out(h1, sig))); out("DO at that level, bridge", Some(bridge(h1, sig, false)));
    let gd = grid(h1, sig, false); out("DO at that level, grid", Some(gd));
    out("level for 9.30 (above vanilla)", bisect(&|h| down_out(h, sig) - 9.30, 50.0, 99.999));
    out("daily-monitored contract level", Some(h1 * (0.5826 * sig * (1.0f64 / 252.0).sqrt()).exp()));
    let dv: Vec<String> = [0.1, 0.2, 0.3, 0.4].iter().map(|&s| format!("{:.4}", down_out(h1, s))).collect();
    println!("DO at that level, vol 10 20 30 40%: {}", dv.join(" "));
    let vols = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.10, 0.12, 0.15, 0.20, 0.30, 0.40, 0.60];
    row("chart, vol %    ", &vols.iter().map(|s| 100.0 * s).collect::<Vec<_>>(), 5, 0);
    row("chart, UO price ", &vols.iter().map(|&s| up_out(120.0, s)).collect::<Vec<_>>(), 5, 2);
    let lim0 = S * (-Q * T).exp() - K * (-R * T).exp();
    out("UO limit as vol -> 0", Some(lim0)); out("UO at vol 1%", Some(up_out(120.0, 0.01)));
    out("UO at vol 20%, formula", Some(up_out(120.0, sig))); out("UO at vol 20%, bridge", Some(bridge(120.0, sig, true)));
    let g20 = grid(120.0, sig, true); out("UO at vol 20%, grid", Some(g20));
    let vega = |s: f64| (up_out(120.0, s + 1e-5) - up_out(120.0, s - 1e-5)) / 2e-5;
    let vega_b = |s: f64| (bridge(120.0, s + 1e-4, true) - bridge(120.0, s - 1e-4, true)) / 2e-4;
    let pk = bisect(&vega, 0.03, 0.12).unwrap(); out("peak vol", Some(pk)); out("peak price", Some(up_out(120.0, pk)));
    let lo1 = bisect(&|s| up_out(120.0, s) - 3.5, 0.01, pk).unwrap(); let hi1 = bisect(&|s| up_out(120.0, s) - 3.5, pk, 1.0).unwrap();
    let lo2 = secant(&|s| bridge(120.0, s, true) - 3.5, 0.04, 0.05); let hi2 = secant(&|s| bridge(120.0, s, true) - 3.5, 0.09, 0.10);
    out("quote 3.50: low vol, formula", Some(lo1)); out("quote 3.50: low vol, bridge", Some(lo2));
    out("quote 3.50: high vol, formula", Some(hi1)); out("quote 3.50: high vol, bridge", Some(hi2));
    let (glo, ghi) = (grid(120.0, lo1, true), grid(120.0, hi1, true));
    out("grid price at low vol", Some(glo)); out("grid price at high vol", Some(ghi));
    out("vega at low vol, formula", Some(vega(lo1))); out("vega at low vol, bridge", Some(vega_b(lo1)));
    out("vega at high vol, formula", Some(vega(hi1))); out("vega at high vol, bridge", Some(vega_b(hi1)));
    out("quote 2.00: the one vol", bisect(&|s| up_out(120.0, s) - 2.0, pk, 1.0));
    out("quote 2.00: root below the peak", bisect(&|s| up_out(120.0, s) - 2.0, 0.01, pk));
    out("quote 4.00: root below the peak", bisect(&|s| up_out(120.0, s) - 4.0, 0.01, pk));
    out("quote 4.00: root above the peak", bisect(&|s| up_out(120.0, s) - 4.0, pk, 1.0));
    out("quote 3.50: bisection on 1% to 60%", bisect(&|s| up_out(120.0, s) - 3.5, 0.01, 0.60));
    let s1 = sig - (up_out(120.0, sig) - 3.5) / vega(sig); let s2 = s1 - (up_out(120.0, s1) - 3.5) / vega(s1);
    let s3 = s2 - (up_out(120.0, s2) - 3.5) / vega(s2);
    out("vega at 20%, formula", Some(vega(sig))); out("newton from 20%, step 1", Some(s1)); out("newton from 20%, step 2", Some(s2));
    println!("{:<40} {:>12}", "newton from 20%, step 3 below zero", if s3 < 0.0 { "yes" } else { "no" });
    let van_b = bridge(1e-9, sig, false); // a barrier so low it is never touched
    let iv = bisect(&|s| vanilla(s) - van_b, 0.01, 1.0).unwrap();
    out("vanilla quote, by integral", Some(van_b)); out("vanilla implied vol", Some(iv));
    out("UO at the vanilla vol", Some(up_out(120.0, iv))); out("market UO 1.20: spread over model", Some(1.20 - up_out(120.0, iv)));
    out("try: level for 5.00", bisect(&|h| down_out(h, sig) - 5.0, 50.0, 99.999));
    let b130 = bisect(&|s| up_out(130.0, s + 1e-5) - up_out(130.0, s - 1e-5), 0.03, 0.2).unwrap();
    out("try: barrier 130, peak vol", Some(b130)); out("try: barrier 130, peak price", Some(up_out(130.0, b130)));

    assert!((do80 - 9.133306).abs() < 1e-6 && (do80b - do80).abs() < 1e-7, "barrier 80 on two roads and the shelf's number");
    assert!((h1 - h2).abs() < 1e-6 && (gd - 8.0).abs() < 0.01 && bisect(&|h| bridge(h, sig, false) - 9.30, 50.0, 99.999).is_none(), "the level on three roads; none for 9.30");
    assert!((lo1 - lo2).abs() < 1e-6 && (hi1 - hi2).abs() < 1e-6, "two implied vols on two roads");
    assert!((glo - 3.5).abs() < 0.01 && (ghi - 3.5).abs() < 0.01 && (g20 - up_out(120.0, sig)).abs() < 0.01, "grid agrees");
    assert!(vega_b(lo1) > 0.0 && vega_b(hi1) < 0.0 && [(0.01, pk), (pk, 1.0)].iter().all(|&(a, b)| bisect(&|s| bridge(120.0, s, true) - 4.0, a, b).is_none()), "opposite vegas; no vol for 4.00");
    assert!((up_out(120.0, 0.01) - lim0).abs() < 1e-3 && (iv - 0.2).abs() < 1e-6, "low-vol limit; vanilla vol recovered");
    println!("ALL CHECKS PASS");
}
