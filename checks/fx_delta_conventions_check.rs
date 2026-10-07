// FX delta conventions -- the check behind the card.  Rust std only, no crates.
// The bell-curve area is Simpson's rule under the density, prices come by Simpson's rule
// over the payoff, strikes by bisection, and the Monte Carlo uses its own xorshift generator.
use std::f64::consts::PI;
const S: f64 = 1.10; const K: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03;
const VOL: f64 = 0.10; const T: f64 = 1.0;

fn n(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn nn(x: f64) -> f64 {                       // 0.5 plus the area under n from 0 to x
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let m = 4000; let h = x / m as f64; let mut tot = 0.0;
    for i in 0..=m { let w = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; tot += w * n(i as f64 * h); }
    0.5 + tot * h / 3.0
}
fn ninv(p: f64) -> f64 { let mut x = 0.0; for _ in 0..60 { x -= (nn(x) - p) / n(x); } x }
fn d12(s: f64, k: f64, t: f64, v: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (RD - RF + 0.5 * v * v) * t) / (v * t.sqrt()); (d1, d1 - v * t.sqrt())
}
fn deltas(s: f64, k: f64, t: f64, v: f64, phi: f64) -> [f64; 4] {
    let (d1, d2) = d12(s, k, t, v); let f = s * ((RD - RF) * t).exp();
    [phi * (-RF * t).exp() * nn(phi * d1), phi * nn(phi * d1),
     phi * (-RD * t).exp() * k / s * nn(phi * d2), phi * k / f * nn(phi * d2)]
}
fn gk(s: f64, k: f64, t: f64, v: f64, phi: f64) -> f64 {
    let (d1, d2) = d12(s, k, t, v);
    phi * (s * (-RF * t).exp() * nn(phi * d1) - k * (-RD * t).exp() * nn(phi * d2))
}
fn simpson_price(s: f64, k: f64, t: f64, v: f64, phi: f64) -> f64 {   // Road 2, no N
    let m = 4000; let zk = ((k / s).ln() - (RD - RF - 0.5 * v * v) * t) / (v * t.sqrt());
    let (a, b) = if phi > 0.0 { (zk, 9.0) } else { (-9.0, zk) };
    let h = (b - a) / m as f64; let mut tot = 0.0;
    for i in 0..=m {
        let z = a + i as f64 * h; let w = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let st = s * ((RD - RF - 0.5 * v * v) * t + v * t.sqrt() * z).exp();
        tot += w * (phi * (st - k)).max(0.0) * n(z);
    }
    (-RD * t).exp() * tot * h / 3.0
}
fn bumped(k: f64, phi: f64) -> [f64; 4] {    // Road 2: bump spot, reprice by Simpson
    let h = 1e-5;
    let (up, dn) = (simpson_price(S + h, k, T, VOL, phi), simpson_price(S - h, k, T, VOL, phi));
    let fwd_contract = ((-RF * T).exp() * (S + h) - (-RF * T).exp() * (S - h)) / (2.0 * h);
    let spot = (up - dn) / (2.0 * h); let pa = S * (up / (S + h) - dn / (S - h)) / (2.0 * h);
    [spot, spot / fwd_contract, pa, pa / fwd_contract]
}
fn monte_carlo(paths: usize) -> [f64; 4] {  // Road 3: pathwise averages, xorshift + Box-Muller
    let mut st: u64 = 88172645463325252; let (mut acc_s, mut acc_c) = (0.0, 0.0);
    let mut u = || { st ^= st << 13; st ^= st >> 7; st ^= st << 17; ((st >> 11) as f64 + 0.5) / 9007199254740992.0 };
    for _ in 0..paths / 2 {
        let z = (-2.0 * u().ln()).sqrt() * (2.0 * PI * u()).cos();
        for zz in [z, -z] {
            let st_t = S * ((RD - RF - 0.5 * VOL * VOL) * T + VOL * T.sqrt() * zz).exp();
            if st_t > K { acc_s += st_t / S; acc_c += K / S; }
        }
    }
    let ms = (-RD * T).exp() * acc_s / paths as f64; let mc = (-RD * T).exp() * acc_c / paths as f64;
    [ms, ms / (-RF * T).exp(), mc, mc / (-RF * T).exp()]
}
fn strike_for(target: f64, which: usize, phi: f64) -> f64 {
    let (mut lo, mut hi) = if phi > 0.0 { (0.95, 2.5) } else { (0.5, 1.5) };
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if deltas(S, mid, T, VOL, phi)[which] > target { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn row(v: [f64; 4]) -> String { v.iter().map(|x| format!("{:9.4}", x)).collect() }

fn main() {
    let names = ["spot delta", "forward delta", "pa spot delta", "pa forward delta"];
    let (d1, d2) = d12(S, K, T, VOL); let f = S * ((RD - RF) * T).exp();
    let (c, p) = (gk(S, K, T, VOL, 1.0), gk(S, K, T, VOL, -1.0));
    println!("d1 {:.6}   d2 {:.6}   N(d1) {:.6}   N(d2) {:.6}", d1, d2, nn(d1), nn(d2));
    println!("forward F {:.6}   e^-rf T {:.6}   e^-rd T {:.6}", f, (-RF * T).exp(), (-RD * T).exp());
    let cs = simpson_price(S, K, T, VOL, 1.0);
    println!("call C formula {:.6}   Simpson {:.6}   in EUR C/S {:.6}   put P {:.6}", c, cs, c / S, p);
    let (form, bump, mc) = (deltas(S, K, T, VOL, 1.0), bumped(K, 1.0), monte_carlo(400000));
    println!("call deltas          formula    bump      Monte Carlo");
    for i in 0..4 { println!("  {:<18}{:9.6}{:10.6}{:10.4}", names[i], form[i], bump[i], mc[i]); }
    let (pf, pb) = (deltas(S, K, T, VOL, -1.0), bumped(K, -1.0));
    println!("put deltas           formula    bump");
    for i in 0..4 { println!("  {:<18}{:9.6}{:10.6}", names[i], pf[i], pb[i]); }
    println!("hedge for a sold EUR 10,000,000 call, EUR to buy");
    for i in 0..4 { println!("  {:<18}{:12.0}", names[i], 1e7 * form[i]); }
    println!("  premium received  EUR {:.0} = USD {:.0}", 1e7 * c / S, 1e7 * c);
    println!("25-delta call strike  closed form  bisection  pips vs spot  Simpson delta");
    let ks: Vec<f64> = (0..4).map(|i| strike_for(0.25, i, 1.0)).collect();
    let closed = [f * (-VOL * T.sqrt() * ninv(0.25 / (-RF * T).exp()) + 0.5 * VOL * VOL * T).exp(),
                  f * (-VOL * T.sqrt() * ninv(0.25) + 0.5 * VOL * VOL * T).exp()];
    for i in 0..4 {
        let cf = if i < 2 { format!("{:11.5}", closed[i]) } else { format!("{:>11}", "-") };
        println!("  {:<18}{}{:11.5}{:10.1}{:12.6}", names[i], cf, ks[i], (ks[i] - ks[0]) * 1e4, bumped(ks[i], 1.0)[i]);
    }
    println!("25-delta put strike   bisection  pips vs spot");
    let kp: Vec<f64> = (0..4).map(|i| strike_for(-0.25, i, -1.0)).collect();
    for i in 0..4 { println!("  {:<18}{:11.5}{:10.1}", names[i], kp[i], (kp[i] - kp[0]) * 1e4); }
    let (mut lo, mut hi, mut mid) = (0.0, 5.0, 0.0);   // peak of pa call delta: vol sqrt(T) N(d2) = n(d2)
    for _ in 0..200 { mid = 0.5 * (lo + hi); if VOL * T.sqrt() * nn(mid) - n(mid) < 0.0 { lo = mid } else { hi = mid } }
    let k_peak = f * (-mid * VOL * T.sqrt() - 0.5 * VOL * VOL * T).exp();
    let (mut a, mut b) = (0.5, 1.10);              // golden-section search on the pa spot delta itself
    for _ in 0..200 {
        let (c1, c2) = (b - 0.618034 * (b - a), a + 0.618034 * (b - a));
        if deltas(S, c1, T, VOL, 1.0)[2] < deltas(S, c2, T, VOL, 1.0)[2] { a = c1 } else { b = c2 }
    }
    println!("pa call delta peak: strike {:.5} (equation) {:.5} (search), delta {:.6}", k_peak, 0.5 * (a + b), deltas(S, k_peak, T, VOL, 1.0)[2]);
    println!("what breaks");
    println!("  forward delta used as spot hedge, extra EUR {:.0}", 1e7 * (form[1] - form[0]));
    println!("  e^-rd T in spot delta          {:.6}", (-RD * T).exp() * nn(d1));
    println!("  premium subtracted in USD      {:.6}", form[0] - c);
    println!("  pa read as spot, 25d call pips {:.1}", (ks[0] - ks[2]) * 1e4);
    println!("at-the-money-forward strike: spot, forward, pa spot, pa forward");
    for (lab, t) in [("1 month", 1.0 / 12.0), ("1 year", 1.0), ("5 years", 5.0)] {
        let ft = S * ((RD - RF) * t).exp();
        println!("  {:<8}{}", lab, row(deltas(S, ft, t, VOL, 1.0)));
    }
    println!("try: vol 20%        {}", row(deltas(S, K, T, 0.20, 1.0)));
    let grid: Vec<f64> = (0..13).map(|i| 0.80 + 0.05 * i as f64).collect();
    println!("chart, strike    {}", grid.iter().map(|k| format!("{:5.2}", k)).collect::<Vec<_>>().join(" "));
    for (i, lab) in [(0, "chart, spot     "), (1, "chart, forward  "), (2, "chart, pa spot  ")] {
        println!("{} {}", lab, grid.iter().map(|k| format!("{:5.2}", deltas(S, *k, T, VOL, 1.0)[i])).collect::<Vec<_>>().join(" "));
    }

    assert!((cs - c).abs() < 1e-10, "formula vs Simpson premium");
    assert!((0..4).all(|i| (form[i] - bump[i]).abs() < 1e-7), "closed forms vs bump-and-reprice");
    assert!((0..4).all(|i| (form[i] - mc[i]).abs() < 4e-3), "closed forms vs Monte Carlo");
    assert!((0..4).all(|i| (pf[i] - pb[i]).abs() < 1e-7), "put deltas vs bump");
    assert!((0..2).all(|i| (closed[i] - ks[i]).abs() < 1e-9), "closed-form strikes vs bisection");
    assert!((0..4).all(|i| (bumped(ks[i], 1.0)[i] - 0.25).abs() < 1e-6), "each strike really is 25 delta");
    assert!((0..4).all(|i| (bumped(kp[i], -1.0)[i] + 0.25).abs() < 1e-6), "each put strike really is -25 delta");
    assert!((k_peak - 0.5 * (a + b)).abs() < 1e-6, "peak by equation vs by search");
    println!("ALL CHECKS PASS");
}
