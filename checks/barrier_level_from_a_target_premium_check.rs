// Solving for the barrier -- the same check as barrier_level_from_a_target_premium_check.py, in Rust.
// EURUSD 1.10, USD rate 5%, EUR rate 3%, vol 10%, one year, 1 EUR notional, prices in USD.
// Std only: the normal CDF is a series, the integrals are Simpson's rule, the root finder is
// bisection, the random numbers are splitmix64.
use std::f64::consts::PI;
const S: f64 = 1.10; const K: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03;
const SIG: f64 = 0.10; const T: f64 = 1.0;
const MU: f64 = RD - RF - 0.5 * SIG * SIG;

fn n_cdf(x: f64) -> f64 {                   // bell-curve area left of x, by its Taylor series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut t, mut s) = (x, x);
    for k in 1..200 { t *= x * x / (2 * k + 1) as f64; s += t; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn dd(x: f64) -> f64 { (-RD * x).exp() }
fn d2(x: f64, k: f64, rd: f64, rf: f64, s: f64) -> f64 { ((x / k).ln() + (rd - rf - 0.5 * s * s) * T) / (s * T.sqrt()) }
fn call(x: f64, k: f64, rd: f64, rf: f64) -> f64 {
    let v = SIG * T.sqrt(); let e = d2(x, k, rd, rf, SIG);
    x * (-rf * T).exp() * n_cdf(e + v) - k * (-rd * T).exp() * n_cdf(e)
}
fn alpha(rd: f64, rf: f64) -> f64 { 2.0 * (rd - rf - 0.5 * SIG * SIG) / (SIG * SIG) }
// Road 1: closed forms by the method of images (a mirror start at H^2/S)
fn do_img_r(h: f64, rd: f64, rf: f64) -> f64 { call(S, K, rd, rf) - (h / S).powf(alpha(rd, rf)) * call(h * h / S, K, rd, rf) }
fn do_img(h: f64) -> f64 { do_img_r(h, RD, RF) }
fn ot_img(h: f64) -> f64 { dd(T) * (n_cdf(d2(S, h, RD, RF, SIG)) + (h / S).powf(alpha(RD, RF)) * n_cdf(-d2(h * h / S, h, RD, RF, SIG))) }
fn dig(k: f64, s: f64) -> f64 { dd(T) * n_cdf(d2(S, k, RD, RF, s)) }
// Road 2: integrate the payoff against the density of paths that never met the wall (no N used)
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let n = 4000; let h = (b - a) / n as f64; let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn alive(x: f64, b: f64) -> f64 {
    let v = SIG * T.sqrt();
    (phi((x - MU * T) / v) - (2.0 * MU * b / (SIG * SIG)).exp() * phi((x - 2.0 * b - MU * T) / v)) / v
}
fn do_int(h: f64) -> f64 {
    let (b, v) = ((h / S).ln(), SIG * T.sqrt());
    dd(T) * simpson(|x| (S * x.exp() - K) * alive(x, b), (K / S).ln(), MU * T + 10.0 * v)
}
fn ot_int(h: f64) -> f64 {
    let (b, v) = ((h / S).ln(), SIG * T.sqrt());
    dd(T) * (1.0 - simpson(|x| alive(x, b), MU * T - 10.0 * v, b))
}
fn dig_int(k: f64) -> f64 {
    let v = SIG * T.sqrt();
    dd(T) * simpson(|x| phi((x - MU * T) / v) / v, (k / S).ln(), MU * T + 10.0 * v)
}
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64, target: f64) -> f64 {
    let mut flo = f(lo) - target;         // f must change side of target between lo and hi
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi); let fm = f(mid) - target;
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
// Road 3: Monte Carlo, monthly steps, Brownian-bridge chance of touching between months
fn unif(st: &mut u64) -> f64 {
    *st = st.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *st;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 1e-17
}
fn mc(h: f64, is_do: bool, st: &mut u64) -> (f64, f64) {
    let (paths, steps) = (40000, 12);
    let (b, dt) = ((h / S).ln(), T / steps as f64);
    let (mut tot, mut tot2) = (0.0, 0.0);
    for _ in 0..paths {
        let (mut x, mut live) = (0.0_f64, 1.0_f64);
        for _ in 0..steps {
            let u1 = unif(st); let u2 = unif(st);
            let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
            let y = x + MU * dt + SIG * dt.sqrt() * z;
            if (y - b) * (x - b) <= 0.0 { live = 0.0; }
            else { live *= 1.0 - (-2.0 * (b - x) * (b - y) / (SIG * SIG * dt)).exp(); }
            x = y;
        }
        let pay = if is_do { live * (S * x.exp() - K).max(0.0) } else { 1.0 - live };
        tot += pay; tot2 += pay * pay;
    }
    let m = tot / paths as f64;
    (dd(T) * m, dd(T) * ((tot2 / paths as f64 - m * m) / paths as f64).sqrt())
}
fn main() {
    let (d, v) = (dd(T), SIG * T.sqrt());
    let vanilla = call(S, K, RD, RF); let target = 0.5 * vanilla;
    let (h1, h2) = (bisect(do_img, 0.5, S, target), bisect(do_int, 0.5, S, target));
    let (u1, u2) = (bisect(ot_img, S, 3.0, 0.30), bisect(ot_int, S, 3.0, 0.30));
    let k1 = S * ((RD - RF - 0.5 * SIG * SIG) * T - v * bisect(n_cdf, -9.0, 9.0, 0.30 / d)).exp();
    let k2 = bisect(dig_int, 0.5, 3.0, 0.30);
    let p12 = dig(1.20, SIG); let z = bisect(n_cdf, -9.0, 9.0, p12 / d); let a = (S / 1.20).ln() + (RD - RF) * T;
    let (lo_q, hi_q) = (-z - (z * z + 2.0 * a).sqrt(), -z + (z * z + 2.0 * a).sqrt());
    let peak = (-2.0 * a / T).sqrt();
    let (lo_b, hi_b) = (bisect(|s| dig(1.20, s), 0.001, peak, p12), bisect(|s| dig(1.20, s), peak, 3.0, p12));
    let mut st: u64 = 20260927;
    let (mc_do, se_do) = mc(h1, true, &mut st); let (mc_ot, se_ot) = mc(u1, false, &mut st);
    let hb = 1e-5;
    let wr = bisect(|h| do_img_r(h, RF, RD), 0.5, S, target); let tw = bisect(|h| 2.0 * dig(h, SIG), S, 3.0, 0.30);
    let rows: Vec<(&str, f64)> = vec![("forward F = S e^((rd-rf)T)", S * ((RD - RF) * T).exp()), ("house: vanilla EUR call 1.10", vanilla), ("house: down-and-out, H 1.05, images", do_img(1.05)),
        ("house: down-and-out, H 1.05, integral", do_int(1.05)), ("house: one-touch 1.20, images", ot_img(1.20)),
        ("house: one-touch 1.20, integral", ot_int(1.20)), ("image exponent alpha", alpha(RD, RF)),
        ("target: half the vanilla", target), ("KO level, road 1 images", h1), ("KO level, road 2 integral", h2),
        ("  mirror start H^2/S", h1 * h1 / S), ("  (H/S)^alpha", (h1 / S).powf(alpha(RD, RF))), ("  vanilla at mirror start", call(h1 * h1 / S, K, RD, RF)),
        ("KO price at level, road 1", do_img(h1)), ("KO price at level, road 3 MC", mc_do), ("  MC standard error", se_do),
        ("KO slope dP/dH at level, road 1", (do_img(h1 + hb) - do_img(h1 - hb)) / (2.0 * hb)),
        ("KO slope dP/dH at level, road 2", (do_int(h1 + hb) - do_int(h1 - hb)) / (2.0 * hb)),
        ("touch level for 0.30, road 1", u1), ("touch level for 0.30, road 2", u2),
        ("touch price at level, road 3 MC", mc_ot), ("  MC standard error", se_ot),
        ("touch ceiling D (level at spot)", d), ("digital strike for 0.30, road 1", k1),
        ("digital strike for 0.30, road 2", k2), ("digital at the touch level", dig(u1, SIG)),
        ("digital 1.20 at 10% vol", p12), ("vol root low, quadratic", lo_q), ("vol root high, quadratic", hi_q),
        ("vol root low, bisection", lo_b), ("vol root high, bisection", hi_b),
        ("vol at the peak", peak), ("digital 1.20 peak price", dig(1.20, peak)),
        ("wrong: rates swapped, KO level", wr),
        ("wrong: digital strike as touch level", ot_img(k1)),
        ("wrong: touch = 2 x digital, level", tw), ("  true touch price there", ot_img(tw)),
        ("wrong: bracket 1%..200%, price at 1%", dig(1.20, 0.01)), ("  price at 200%", dig(1.20, 2.0))];
    for (name, x) in &rows { println!("{:<40}{:>12.6}", name, x); }
    for f in [0.10, 0.25, 0.75, 0.90] {
        println!("{:<40}{:>12.6}", format!("KO level for {:.0}% of vanilla", f * 100.0), bisect(do_img, 0.5, S, f * vanilla));
    }
    let row = |xs: &[f64], g: &dyn Fn(f64) -> f64, p: usize| xs.iter().map(|&x| format!("{:.*}", p, g(x))).collect::<Vec<_>>().join(" ");
    let (mut lo, mut hi, mut tr) = (1.00_f64, 1.10_f64, Vec::new());
    for _ in 0..6 {
        let m = 0.5 * (lo + hi); let p = do_img(m); tr.push((m, p));
        if p > target { lo = m; } else { hi = m; }
    }
    println!("bisection H  {}", tr.iter().map(|t| format!("{:.6}", t.0)).collect::<Vec<_>>().join(" "));
    println!("bisection P  {}", tr.iter().map(|t| format!("{:.6}", t.1)).collect::<Vec<_>>().join(" "));
    let lv = [0.95, 1.00, 1.02, 1.04, 1.05, 1.06, 1.07, 1.08, 1.09, 1.10];
    println!("chart KO level  {}", row(&lv, &|x| x, 2));
    println!("chart KO price  {}", row(&lv, &|x| do_img(x.min(S)), 4));
    let up = [1.10, 1.15, 1.20, 1.25, 1.30, 1.35, 1.40];
    println!("chart up level  {}", row(&up, &|x| x, 2));
    println!("chart touch %   {}", row(&up, &|x| 100.0 * ot_img(x), 2));
    println!("chart digital % {}", row(&up, &|x| 100.0 * dig(x, SIG), 2));
    let vs = [0.02, 0.05, 0.10, 0.20, 0.30, 0.40, 0.60, 0.80, 1.00, 1.34, 1.60, 2.00];
    println!("chart vol       {}", row(&vs, &|x| x, 2));
    println!("chart dig 1.20 % {}", row(&vs, &|x| 100.0 * dig(1.20, x), 2));

    assert!((do_img(1.05) - 0.041661).abs() < 5e-7, "house knock-out");
    assert!((ot_img(1.20) - 0.4142).abs() < 5e-5, "house one-touch");
    assert!((h1 - h2).abs() < 1e-6 && (u1 - u2).abs() < 1e-6 && (k1 - k2).abs() < 1e-6, "roads 1 and 2 agree on each level");
    assert!((mc_do - target).abs() < 4.0 * se_do && (mc_ot - 0.30).abs() < 4.0 * se_ot, "simulation lands on the targets");
    assert!((lo_q - lo_b).abs() < 1e-6 && (hi_q - hi_b).abs() < 1e-6 && (lo_q - SIG).abs() < 1e-6, "two vols, two ways");
    println!("ALL CHECKS PASS");
}
