// Knock-in and knock-out forwards -- the check behind the card.  Rust std only, no crates.
// House FX market: EURUSD 1.10, USD 5%, EUR 3%, vol 10%, 1 year; knock-in 1.05, knock-out 1.20; USD per 1 EUR.
// Roads: (1) barrier blocks A-D + bisection; (2) Simpson integral of payoff times bridge survival + bisection;
// (3) Monte Carlo with its own random numbers. Identity checks, not a road: forward = call - put, KIKO = forward - UIC + DOP.
use std::f64::consts::PI;
const S0: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03; const T: f64 = 1.0;
const VOL: f64 = 0.10; const LO: f64 = 1.05; const HI: f64 = 1.20;
const NAMES: [&str; 4] = ["plain forward", "participating 50%", "knock-in forward", "KIKO"];

fn n(x: f64) -> f64 { // normal CDF, own series: 0.5 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() || k < 5.0 { term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0; }
    0.5 + total * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn blocks(k: f64, h: f64, eta: f64, phi: f64, v: f64) -> [f64; 4] {
    let s = v * T.sqrt(); let mu = (RD - RF - 0.5 * v * v) / (v * v);
    let x1 = (S0 / k).ln() / s + (1.0 + mu) * s; let x2 = (S0 / h).ln() / s + (1.0 + mu) * s;
    let y1 = (h * h / (S0 * k)).ln() / s + (1.0 + mu) * s; let y2 = (h / S0).ln() / s + (1.0 + mu) * s;
    let (fs, fk) = (S0 * (-RF * T).exp(), k * (-RD * T).exp());
    let (hp, hm) = ((h / S0).powf(2.0 * mu + 2.0), (h / S0).powf(2.0 * mu));
    [phi * (fs * n(phi * x1) - fk * n(phi * (x1 - s))), phi * (fs * n(phi * x2) - fk * n(phi * (x2 - s))),
     phi * (fs * hp * n(eta * y1) - fk * hm * n(eta * (y1 - s))), phi * (fs * hp * n(eta * y2) - fk * hm * n(eta * (y2 - s)))]
}
// call, put, down-and-in put, up-and-out call, up-and-in call, down-and-out put
fn legs(k: f64, v: f64, lo: f64, hi: f64) -> [f64; 6] {
    let [a1, b1, c1, d1] = blocks(k, hi, -1.0, 1.0, v); let [a, b, c, d] = blocks(k, lo, 1.0, -1.0, v);
    let (uoc, uic) = if k < hi { (a1 - b1 + c1 - d1, b1 - c1 + d1) } else { (0.0, a1) };
    let (dip, dop) = if k > lo { (b - c + d, a - b + c - d) } else { (a, 0.0) };
    [a1, a, dip, uoc, uic, dop]
}
fn structure(i: usize, l: &[f64], p: f64) -> f64 {
    match i { 0 => l[0] - l[1], 1 => l[0] - p * l[1], 2 => l[0] - l[2], _ => l[3] - l[2] }
}
fn value(i: usize, k: f64, v: f64, lo: f64, hi: f64, p: f64) -> f64 { structure(i, &legs(k, v, lo, hi), p) }
fn bisect(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64, trace: &mut Vec<(usize, f64, f64, f64, f64)>) -> f64 {
    for i in 0..80 {
        let m = 0.5 * (a + b); let fm = f(m);
        if i < 7 { trace.push((i + 1, a, b, m, fm)); }
        if fm > 0.0 { a = m; } else { b = m; }
    }
    0.5 * (a + b)
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 400; let h = (b - a) / n as f64; let mut tot = f(a) + f(b);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    tot * h / 3.0
}
fn by_integral(i: usize, k: f64) -> f64 { // road 2: no blocks, no N; survival of a bridge pinned at both ends
    let (m, s, kx) = ((RD - RF - 0.5 * VOL * VOL) * T, VOL * T.sqrt(), (k / S0).ln());
    let (al, ah) = ((LO / S0).ln(), (HI / S0).ln());
    let dens = move |x: f64| (-(x - m).powi(2) / (2.0 * s * s)).exp() / (s * (2.0 * PI).sqrt());
    let surv_l = move |x: f64| if x > al { 1.0 - (-2.0 * al * (al - x) / (s * s)).exp() } else { 0.0 };
    let surv_h = move |x: f64| if x < ah { 1.0 - (-2.0 * ah * (ah - x) / (s * s)).exp() } else { 0.0 };
    let call = move |x: f64| (S0 * x.exp() - k) * dens(x); let put = move |x: f64| (k - S0 * x.exp()) * dens(x);
    let over = |f: &dyn Fn(f64) -> f64, a: f64, b: f64| -> f64 { // integrate between kinks only
        let mut cuts = vec![a, b];
        for c in [kx, al, ah] { if a < c && c < b && !cuts.contains(&c) { cuts.push(c); } }
        cuts.sort_by(|p, q| p.partial_cmp(q).unwrap());
        (0..cuts.len() - 1).map(|j| simpson(f, cuts[j], cuts[j + 1])).sum()
    };
    let (lo_x, hi_x) = (m - 10.0 * s, m + 10.0 * s);
    let c = over(&call, kx, hi_x); let p = over(&put, lo_x, kx);
    let uoc = if kx < ah { over(&|x: f64| call(x) * surv_h(x), kx, ah) } else { 0.0 };
    let dip = over(&|x: f64| put(x) * (1.0 - surv_l(x)), lo_x, kx);
    let d = (-RD * T).exp();
    structure(i, &[c * d, p * d, dip * d, uoc * d], 0.5)
}
fn unif(st: &mut u64) -> f64 { // splitmix64, then 53 bits into (0, 1)
    *st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = *st;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
}
fn monte_carlo(k1: f64, k2: f64) -> ([f64; 4], [f64; 4]) { // road 3: bridge test for each wall each month
    let (paths, steps) = (100000, 12); let dt = T / steps as f64;
    let (drift, sd) = ((RD - RF - 0.5 * VOL * VOL) * dt, VOL * dt.sqrt());
    let (al, ah, disc) = ((LO / S0).ln(), (HI / S0).ln(), (-RD * T).exp());
    let (mut sm, mut sq, mut st) = ([0.0; 4], [0.0; 4], 20261123u64);
    for _ in 0..paths {
        let (mut x, mut hl, mut hh) = (0.0f64, false, false);
        for _ in 0..steps {
            let z = (-2.0 * unif(&mut st).ln()).sqrt() * (2.0 * PI * unif(&mut st)).cos();
            let (u3, u4) = (unif(&mut st), unif(&mut st));
            let y = x + drift + sd * z;
            hl = hl || y <= al || u3 < (-2.0 * (x - al) * (y - al) / (sd * sd)).exp();
            hh = hh || y >= ah || u4 < (-2.0 * (ah - x) * (ah - y) / (sd * sd)).exp();
            x = y;
        }
        let stt = S0 * x.exp(); let (fl, fh) = (hl as i32 as f64, hh as i32 as f64);
        let v = [disc * ((stt - k1).max(0.0) - fl * (k1 - stt).max(0.0)),
                 disc * ((1.0 - fh) * (stt - k2).max(0.0) - fl * (k2 - stt).max(0.0)), fl, fh];
        for j in 0..4 { sm[j] += v[j]; sq[j] += v[j] * v[j]; }
    }
    let mean = sm.map(|t| t / paths as f64);
    let mut se = [0.0; 4];
    for j in 0..4 { se[j] = ((sq[j] / paths as f64 - mean[j] * mean[j]).max(0.0) / paths as f64).sqrt(); }
    (mean, se)
}
fn main() {
    let fwd = S0 * ((RD - RF) * T).exp(); // covered interest parity
    println!("house: EURUSD 1.10, USD 5%, EUR 3%, vol 10%, 1 year, knock-in 1.05, knock-out 1.20");
    let (mut ks, mut trace, mut junk) = ([0.0; 4], Vec::new(), Vec::new());
    for i in 0..4 {
        let tr = if i == 3 { &mut trace } else { &mut junk };
        ks[i] = bisect(&|k| value(i, k, VOL, LO, HI, 0.5), 1.00, 1.20, tr);
        let ki = bisect(&|k| by_integral(i, k), 1.00, 1.20, &mut junk);
        println!("zero-cost strike  {:<18} blocks {:.6}  integral {:.6}", NAMES[i], ks[i], ki);
        assert!((ki - ks[i]).abs() < 1e-8, "{}", NAMES[i]);
    }
    println!("forward by parity {:.6}, so the plain-forward strike is the parity forward", fwd);
    assert!((ks[0] - fwd).abs() < 1e-10);
    for i in [2, 3] {
        let l = legs(ks[i], VOL, LO, HI);
        println!("legs at {} strike {:.6}: call {:.6} put {:.6} DIP {:.6} UOC {:.6}", NAMES[i], ks[i], l[0], l[1], l[2], l[3]);
    }
    let lf = legs(fwd, VOL, LO, HI); let dfd = (-RD * T).exp();
    println!("at K = forward: call {:.6} = put {:.6}; DIP {:.6}; DOP = put - DIP {:.6}", lf[0], lf[1], lf[2], lf[5]);
    println!("first-order strike shift DOP/e^(-rd T) = {:.6}/{:.6} = {:.6}; guess {:.6}", lf[5], dfd, lf[5] / dfd, fwd + lf[5] / dfd);
    println!("actual shift {:.6}", ks[2] - fwd);
    println!("KIKO bisection: step, low, high, mid, value at mid");
    for (i, a, b, m, fm) in &trace { println!("  {}  {:.6}  {:.6}  {:.6}  {:+.6}", i, a, b, m, fm); }
    println!("value to the importer (US cents per euro) against strike");
    println!("  strike  forward  knock-in fwd  KIKO");
    for k in [1.04, 1.06, 1.08, 1.10, 1.12, 1.14, 1.16] {
        let v = |i| 100.0 * value(i, k, VOL, LO, HI, 0.5);
        println!("  {:.2}  {:7.3}  {:7.3}  {:7.3}", k, v(0), v(2), v(3));
    }
    let (kk, kf) = (ks[3], ks[2]);
    let l = legs(kk, VOL, LO, HI); let fv = S0 * (-RF * T).exp() - kk * dfd;
    println!("KIKO strike {:.6} below forward: forward value {:.6} = UIC {:.6} - DOP {:.6} = {:.6}", fwd - kk, fv, l[4], l[5], l[4] - l[5]);
    assert!((fv - (l[4] - l[5])).abs() < 1e-12 && (l[0] - l[1] - fv).abs() < 1e-12);
    println!("rate paid per euro: path / forward / knock-in fwd / KIKO");
    for (desc, stt, hl, hh) in [("ends 1.15, no touch", 1.15, false, false), ("ends 1.08, no touch", 1.08, false, false),
                                ("touches 1.05, ends 1.08", 1.08, true, false), ("touches 1.20, ends 1.25", 1.25, false, true),
                                ("touches 1.05, ends 1.02", 1.02, true, false)] {
        let kif = if stt > kf || hl { kf } else { stt };
        let kiko = if (stt > kk && !hh) || (stt < kk && hl) { kk } else { stt };
        println!("  {:<24} {:.6}  {:.6}  {:.6}", desc, fwd, kif, kiko);
    }
    let (mc, se) = monte_carlo(kf, kk);
    for (j, (lab, kx)) in [("knock-in forward", kf), ("KIKO", kk)].iter().enumerate() {
        println!("Monte Carlo value of {} at {:.6}: {:+.6}  (se {:.6})", lab, kx, mc[j], se[j]);
        assert!(mc[j].abs() < 4.0 * se[j], "{}", lab);
    }
    for (j, (h, eta)) in [(LO, 1.0), (HI, -1.0)].iter().enumerate() { // chance of a touch from the no-touch dollar
        let s = VOL * T.sqrt(); let mu = (RD - RF - 0.5 * VOL * VOL) / (VOL * VOL);
        let x2 = (S0 / h).ln() / s + (1.0 + mu) * s; let y2 = (h / S0).ln() / s + (1.0 + mu) * s;
        let p = 1.0 - (n(eta * (x2 - s)) - (h / S0).powf(2.0 * mu) * n(eta * (y2 - s)));
        println!("chance of touching {:.2} in the year: formula {:.6}  Monte Carlo {:.6}", h, p, mc[2 + j]);
        assert!((mc[2 + j] - p).abs() < 4.0 * se[2 + j]);
    }
    let tries: [(&str, Box<dyn Fn(f64) -> f64>); 5] = [
        ("KIKO, knock-out 1.25", Box::new(|k| value(3, k, VOL, LO, 1.25, 0.5))),
        ("knock-in forward, knock-in 1.00", Box::new(|k| value(2, k, VOL, 1.00, HI, 0.5))),
        ("knock-in forward, vol 12%", Box::new(|k| value(2, k, 0.12, LO, HI, 0.5))),
        ("participating 75%", Box::new(|k| value(1, k, VOL, LO, HI, 0.75))),
        ("KIKO without the knock-in", Box::new(|k| { let l = legs(k, VOL, LO, HI); l[3] - l[1] }))];
    for (lab, f) in tries.iter() { println!("try: {:<33} strike {:.6}", lab, bisect(f.as_ref(), 1.00, 1.20, &mut junk)); }
    println!("ALL CHECKS PASS");
}
