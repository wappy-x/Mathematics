// Jarrow-Yildirim: a 5-year 0% zero-coupon inflation floor, Black on the model's volatility. Roads: closed-form
// variance vs quadrature; Black vs payoff integral; Monte Carlo of the model vs both; three routes to the YoY term.
// Rust has no erf, so the bell-curve area is added up from thin slices under the curve.
use std::f64::consts::PI;

const T: f64 = 5.0; const K: f64 = 1.0; const VOL: f64 = 0.02; const RN: f64 = 0.035; const BE: f64 = 0.01;
const AN: f64 = 0.10; const SN: f64 = 0.010; const AR: f64 = 0.05; const SR: f64 = 0.008;
const RNR: f64 = 0.90; const RNI: f64 = 0.20; const RRI: f64 = -0.10;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut acc = 0.0;
    for i in 1..n { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h); }
    (f(lo) + f(hi) + acc) * h / 3.0
}
fn ncdf(x: f64) -> f64 { 0.5 + simpson(&phi, 0.0, x, 4000) }
fn b(a: f64, t: f64) -> f64 { (1.0 - (-a * t).exp()) / a }
fn disc(t: f64, rn: f64) -> f64 { (1.0 + rn).powf(-t) }
fn fwd(t: f64, be: f64) -> f64 { (1.0 + be).powf(t) }

fn pieces(t: f64, si: f64, rnr: f64, rni: f64, rri: f64) -> [f64; 6] {   // the six variance terms
    let (i_n, i_r) = ((t - b(AN, t)) / AN, (t - b(AR, t)) / AR);
    let i_nn = (t - 2.0 * b(AN, t) + b(2.0 * AN, t)) / AN.powi(2);
    let i_rr = (t - 2.0 * b(AR, t) + b(2.0 * AR, t)) / AR.powi(2);
    let i_nr = (t - b(AN, t) - b(AR, t) + b(AN + AR, t)) / (AN * AR);
    [si * si * t, SN * SN * i_nn, SR * SR * i_rr,
     2.0 * rni * SN * si * i_n, -2.0 * rri * SR * si * i_r, -2.0 * rnr * SN * SR * i_nr]
}
fn sum6(p: [f64; 6]) -> f64 { let mut s = 0.0; for x in p { s += x; } s }
fn jyvol_c(t: f64, si: f64, rnr: f64, rni: f64, rri: f64) -> f64 { (sum6(pieces(t, si, rnr, rni, rri)) / t).sqrt() }
fn jyvol(t: f64, si: f64) -> f64 { jyvol_c(t, si, RNR, RNI, RRI) }
fn jyvol_quad(t: f64, si: f64) -> f64 {          // integrate the instantaneous variance over time
    let inst = |s: f64| {
        let (bn, br) = (b(AN, t - s), b(AR, t - s));
        si * si + SN * SN * bn * bn + SR * SR * br * br + 2.0 * RNI * SN * si * bn
            - 2.0 * RRI * SR * si * br - 2.0 * RNR * SN * SR * bn * br
    };
    (simpson(&inst, 0.0, t, 2000) / t).sqrt()
}
fn black(f: f64, k: f64, w: f64, put: bool) -> f64 {
    let d1 = ((f / k).ln() + 0.5 * w * w) / w; let d2 = d1 - w;
    if put { k * ncdf(-d2) - f * ncdf(-d1) } else { f * ncdf(d1) - k * ncdf(d2) }
}
fn zc(k: f64, put: bool, be: f64, vol: f64, t: f64) -> f64 { 100.0 * disc(t, RN) * black(fwd(t, be), k, vol * t.sqrt(), put) }
fn zc_integral(k: f64, put: bool) -> f64 {        // payoff averaged over the lognormal ratio
    let (w, f) = (VOL * T.sqrt(), fwd(T, BE));
    let x = |z: f64| f * (-0.5 * w * w + w * z).exp();
    let pay = |z: f64| (if put { (k - x(z)).max(0.0) } else { (x(z) - k).max(0.0) }) * phi(z);
    let (mut lo, mut hi) = (-12.0, 12.0);
    for _ in 0..200 { let mid = 0.5 * (lo + hi); if x(mid) < k { lo = mid } else { hi = mid } }
    100.0 * disc(T, RN) * (simpson(&pay, -12.0, lo, 2000) + simpson(&pay, lo, 12.0, 2000))
}

fn monte_carlo(paths: usize, steps: usize, si: f64, seed: u64) -> (f64, f64, f64, f64, f64) {
    let mut st = seed;
    let mut u = || {                               // splitmix64, then a uniform strictly inside (0, 1)
        st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = st;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    let dt = T / steps as f64; let sq = dt.sqrt(); let fnr = (1.0 + RN).ln(); let frr = ((1.0 + RN) / (1.0 + BE)).ln();
    let l22 = (1.0 - RNR.powi(2)).sqrt(); let l32 = (RRI - RNI * RNR) / l22; let l33 = (1.0 - RNI.powi(2) - l32.powi(2)).sqrt();
    let phn: Vec<f64> = (0..=steps).map(|k| fnr + SN.powi(2) / (2.0 * AN.powi(2)) * (1.0 - (-AN * k as f64 * dt).exp()).powi(2)).collect();
    let phr: Vec<f64> = (0..=steps).map(|k| frr + SR.powi(2) / (2.0 * AR.powi(2)) * (1.0 - (-AR * k as f64 * dt).exp()).powi(2)).collect();
    let (mut sd, mut sf, mut sfl, mut sl, mut sl2) = (0.0, 0.0, 0.0, 0.0, 0.0);
    let mut pair: Vec<f64> = Vec::with_capacity(paths);
    let mut zs = vec![(0.0, 0.0, 0.0); steps];
    for _ in 0..paths {
        for k in 0..steps {
            let r1 = (-2.0 * u().ln()).sqrt(); let t1 = 2.0 * PI * u();
            let r2 = (-2.0 * u().ln()).sqrt(); let t2 = 2.0 * PI * u();
            zs[k] = (r1 * t1.cos(), r1 * t1.sin(), r2 * t2.cos());
        }
        let mut pv = 0.0;
        for sg in [1.0, -1.0] {                    // each draw and its mirror image
            let (mut xn, mut xr, mut lni, mut intn) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
            for k in 0..steps {
                let (z1, z2, z3) = (sg * zs[k].0, sg * zs[k].1, sg * zs[k].2);
                let (w2, w3) = (RNR * z1 + l22 * z2, RNI * z1 + l32 * z2 + l33 * z3);
                let (nn, rr) = (phn[k] + xn, phr[k] + xr);
                lni += (nn - rr - 0.5 * si * si) * dt + si * sq * w3;
                let xn1 = xn - AN * xn * dt + SN * sq * z1;
                xr += (-AR * xr - RRI * SR * si) * dt + SR * sq * w2;
                intn += 0.5 * (nn + phn[k + 1] + xn1) * dt; xn = xn1;
            }
            let (d, i) = ((-intn).exp(), lni.exp());
            let f = d * (K - i).max(0.0);
            sd += d; sf += d * i; sfl += f; sl += d * lni; sl2 += d * lni * lni; pv += 0.5 * f;
        }
        pair.push(pv);
    }
    let m = (2 * paths) as f64; let pn = paths as f64;
    let mut mu = 0.0; for p in &pair { mu += p; } mu /= pn;
    let mut v = 0.0; for p in &pair { v += (p - mu).powi(2); }
    let se = (v / (pn - 1.0) / pn).sqrt();
    (sd / m, sf / m, ((sl2 / sd - (sl / sd).powi(2)) / T).sqrt(), 100.0 * sfl / m, 100.0 * se)
}

fn conv(t0: f64, t1: f64, si: f64) -> f64 {      // year-on-year correction, this card's arrangement
    let br = b(AR, t0);
    SR * b(AR, t1 - t0) * (RRI * si * br + RNR * SN * (br - b(AN + AR, t0)) / AN - 0.5 * SR * br * br)
}
fn conv_pub(t0: f64, t1: f64, si: f64) -> f64 {  // the arrangement published by Mercurio (2005)
    let (br, bn, g) = (b(AR, t0), b(AN, t0), RNR * SN / (AN + AR));
    SR * b(AR, t1 - t0) * (br * (RRI * si - 0.5 * SR * br + g * (1.0 + AR * bn)) - g * bn)
}
fn conv_quad(t0: f64, t1: f64, si: f64) -> f64 { // the integral before it is done in closed form
    let g = |s: f64| (-AR * (t0 - s)).exp() * (RRI * si + RNR * SN * b(AN, t0 - s) - SR * b(AR, t0 - s));
    SR * b(AR, t1 - t0) * simpson(&g, 0.0, t0, 2000)
}
fn row(label: &str, v: f64, d: usize) { println!("{:<40}{:>14.*}", label, d, v); }

fn main() {
    let rest = sum6(pieces(T, 0.0, RNR, RNI, RRI)); let c1 = sum6(pieces(T, 1.0, RNR, RNI, RRI)) - T - rest;
    let si = (-c1 + (c1 * c1 - 4.0 * T * (rest - VOL * VOL * T)).sqrt()) / (2.0 * T);
    let w = VOL * T.sqrt(); let f = fwd(T, BE); let d1 = ((f / K).ln() + 0.5 * w * w) / w; let d2 = d1 - w;
    let (flo, flo_i) = (zc(K, true, BE, VOL, T), zc_integral(K, true));
    let (cap3, cap3_i) = (zc(1.03f64.powf(5.0), false, BE, VOL, T), zc_integral(1.03f64.powf(5.0), false));
    let (par_l, par_r) = (zc_integral(K, false) - flo_i, 100.0 * disc(T, RN) * (f - K));
    let (mc_d, mc_f, mc_v, mc_fl, mc_se) = monte_carlo(20000, 100, si, 1);
    let lk0 = 100.0 * disc(T, RN) * f; let lk1 = lk0 + flo;
    let (y0, y1) = ((100.0 / lk0).powf(0.2) - 1.0, (100.0 / lk1).powf(0.2) - 1.0);
    let seas = 110.0 * disc(T, RN) * black(f, 1.0 / 1.10, w, true);
    let (c5, c20) = (conv(4.0, 5.0, si), conv(19.0, 20.0, si));
    let v0 = jyvol_c(T, si, 0.0, 0.0, 0.0);
    println!("inputs: T 5y, strike ratio 1.00, ZC vol 2.00 pct, nominal 3.50 pct, breakeven 1.00 pct");
    row("D(5), nominal discount factor", disc(T, RN), 6); row("F, forward index ratio (1.01^5)", f, 6);
    row("P_r(0,5), real bond = D F", disc(T, RN) * f, 6);
    let labs = ["index", "nominal bond", "real bond", "nominal x index", "real x index", "nominal x real"];
    for (lab, p) in labs.iter().zip(pieces(T, si, RNR, RNI, RRI)) { row(&format!("variance piece, {}", lab), p, 8); }
    row("sigma_I, index vol solved, pct", 100.0 * si, 6); row("rates-only vol (sigma_I = 0), pct", 100.0 * jyvol(T, 0.0), 6);
    row("ZC vol, closed form, pct", 100.0 * jyvol(T, si), 6); row("ZC vol, Simpson in time, pct", 100.0 * jyvol_quad(T, si), 6);
    row("ZC vol, Monte Carlo, pct", 100.0 * mc_v, 6);
    row("MC: P_n(0,5)", mc_d, 6); row("MC: P_r(0,5)", mc_f, 6); row("w = vol sqrt(T)", w, 6);
    row("d1", d1, 6); row("d2", d2, 6); row("N(-d2)", ncdf(-d2), 6); row("N(-d1)", ncdf(-d1), 6);
    row("1 floor 0%, Black, per 100", flo, 6); row("2 floor 0%, payoff integral, per 100", flo_i, 6);
    row("3 floor 0%, Monte Carlo, per 100", mc_fl, 6); row("  Monte Carlo standard error", mc_se, 6);
    row("cap 3% a year (K 1.159274), Black", cap3, 6); row("cap 3% a year, payoff integral", cap3_i, 6);
    row("parity: cap 1.00 minus floor 1.00", par_l, 6); row("parity: D (F - 1) x 100", par_r, 6);
    row("house: floor at 2.5% breakeven", zc(K, true, 0.025, VOL, T), 6); row("house: F at 2.5% (1.025^5)", fwd(T, 0.025), 6);
    row("linker without floor, per 100", lk0, 6); row("linker with floor, per 100", lk1, 6);
    row("real yield without floor, pct", 100.0 * y0, 6); row("real yield with floor, pct", 100.0 * y1, 6);
    row("floor in real yield, bp", 1e4 * (y0 - y1), 6); row("seasoned linker (ratio 1.10), floor", seas, 6);
    println!("YoY year 5: C, bp (card, published, Simpson) {:.6} {:.6} {:.6}", 1e4 * c5,
             1e4 * conv_pub(4.0, 5.0, si), 1e4 * conv_quad(4.0, 5.0, si));
    row("YoY year 20: C, bp", 1e4 * c20, 6);
    row("YoY year 20 forward, pct", 100.0 * ((1.0 + BE) * c20.exp() - 1.0), 6);
    row("wrong: index vol only, rates ignored", zc(K, true, BE, si, T), 6); row("wrong: discounted with real bond", flo * f, 6);
    row("wrong: correlations set to 0, vol pct", 100.0 * v0, 6);
    row("wrong: correlations set to 0, floor", zc(K, true, BE, v0, T), 6);
    row("wrong: breakeven ignored (F = 1)", zc(K, true, 0.0, VOL, T), 6);
    row("try: ZC vol 3%", zc(K, true, BE, 0.03, T), 6); row("try: 10 years, ZC vol pct", 100.0 * jyvol(10.0, si), 6);
    row("try: 10 years, floor", zc(K, true, BE, jyvol(10.0, si), 10.0), 6); row("try: breakeven 0.5%", zc(K, true, 0.005, VOL, T), 6);
    let bes = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5];
    println!("chart, breakeven pct  {}", bes.iter().map(|x| format!("{:>8.1}", x)).collect::<String>());
    println!("chart, floor per 100  {}", bes.iter().map(|x| format!("{:>8.3}", zc(K, true, x / 100.0, VOL, T))).collect::<String>());
    println!("chart, ZC vol pct     {}", (1..11).map(|t| format!("{:>6.2}", 100.0 * jyvol(t as f64, si))).collect::<String>());
    assert!((jyvol(T, si) - jyvol_quad(T, si)).abs() < 1e-10);          // closed-form integrals against quadrature
    assert!((flo - flo_i).abs() < 1e-9 && (cap3 - cap3_i).abs() < 1e-9); // Black against the payoff integral
    assert!((par_l - par_r).abs() < 1e-9);                             // parity: cap minus floor is a swap
    assert!((mc_fl - flo).abs() < 4.0 * mc_se);                        // the simulated model prices the same floor
    assert!((mc_v - VOL).abs() < 3e-4 && (mc_d - disc(T, RN)).abs() < 1e-4 && (mc_f - disc(T, RN) * f).abs() < 1e-4);
    assert!((c5 - conv_pub(4.0, 5.0, si)).abs() < 1e-14 && (c5 - conv_quad(4.0, 5.0, si)).abs() < 1e-12);
    assert!((flo * 1000.0).round() == 258.0);                          // the spec's quoted price
    println!("ALL CHECKS PASS");
}
