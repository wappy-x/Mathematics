// Autocallables and Phoenix notes -- the same check as the Python, in Rust.  No crates.
// Uniforms: the printed recurrence; normals: Box-Muller; bell-curve area: its own series.
use std::f64::consts::PI;

const S0: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; // house
const CALL: f64 = 100.0; const KI: f64 = 70.0; const ISSUE: f64 = 98.0; // call, knock-in, target
const SEED: u64 = 20261123; const PATHS: usize = 100000; const DT: f64 = 0.25; // 12 quarters
const PHX: f64 = 0.02;                          // the Phoenix coupon, per quarter
const COUPONS: [f64; 6] = [0.05, 0.06, 0.07, 0.08, 0.09, 0.10];
const MOD: u64 = 1 << 32;
const MU: f64 = R - Q - 0.5 * SIG * SIG;        // pricing-world growth per year

fn uniform(state: &mut u64) -> f64 {           // one step of the recurrence
    *state = (1664525 * *state + 1013904223) % MOD;
    (*state as f64 + 0.5) / MOD as f64
}

fn normal_pair(state: &mut u64) -> (f64, f64) { // Box-Muller: two uniforms -> two normals
    let u = uniform(state);
    let v = uniform(state);
    let (rad, ang) = ((-2.0 * u.ln()).sqrt(), 2.0 * PI * v);
    (rad * ang.cos(), rad * ang.sin())
}

fn ncdf(x: f64) -> f64 {                        // bell-curve area left of x, Taylor series
    if x < -9.0 || x > 9.0 {
        return if x < 0.0 { 0.0 } else { 1.0 };
    }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t {
        t = s;
        i += 2.0;
        b *= x * x / i;
        s = t + b;
    }
    0.5 + s * (-0.5 * x * x - 0.91893853320467274178).exp()
}

fn at_maturity(s: f64) -> (f64, f64) {          // year 2, not called: year 3 valued at year 2
    let d2 = |k: f64| ((s / k).ln() + MU) / SIG;
    let a = 100.0 - 100.0 * ncdf(-d2(KI)) + s * (R - Q).exp() * ncdf(-d2(KI) - SIG);
    ((-R).exp() * a, (-R).exp() * 300.0 * ncdf(d2(CALL)))
}

fn roll(cont: &dyn Fn(f64) -> (f64, f64), year: f64, s: f64) -> (f64, f64) {
    let n = 160;                                // one year back: call region exact, rest by Simpson
    let zc = (((CALL / s).ln() - MU) / SIG).min(9.0);
    let (h, mut sa, mut sb) = ((zc + 9.0) / n as f64, 0.0, 0.0);
    for i in 0..=n {
        let z = -9.0 + i as f64 * h;
        let wt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let w = wt * (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
        let (a, b) = cont(s * (MU + SIG * z).exp());
        sa += w * a;
        sb += w * b;
    }
    let up = 1.0 - ncdf(zc);                    // chance of being called at this date
    ((-R).exp() * (sa * h / 3.0 + up * 100.0), (-R).exp() * (sb * h / 3.0 + up * 100.0 * year))
}

fn main() {
    let (qa, qb) = roll(&|s| roll(&at_maturity, 2.0, s), 1.0, S0);   // road 2: quadrature
    let e: Vec<f64> = (0..13).map(|j| (-R * DT * j as f64).exp()).collect();
    let mut acc = [0.0f64; 22];
    let mut state = SEED;
    let mut first: Option<(Vec<f64>, usize, f64, f64, f64, f64)> = None;
    for _ in 0..PATHS {
        let (mut s, mut path) = (S0, Vec::with_capacity(12));
        for _ in 0..6 {
            let (z1, z2) = normal_pair(&mut state);
            for z in [z1, z2] {
                s *= (MU * DT + SIG * DT.sqrt() * z).exp();
                path.push(s);
            }
        }
        let (y1, y2, y3) = (path[3], path[7], path[11]);
        let end3 = if y3 >= KI { 100.0 } else { y3 };      // redemption at year 3, S0 = 100
        let k = if y1 >= CALL { 1 } else if y2 >= CALL { 2 } else { 3 };
        let a = if k < 3 { 100.0 * e[4 * k] } else { e[12] * end3 };
        let b = if k < 3 || y3 >= CALL { 100.0 * k as f64 * e[4 * k] } else { 0.0 };
        let (a_d3, b_d3) = (a * e[12] / e[4 * k], b * e[12] / e[4 * k]);
        let hit = k == 3 && y3 < KI;
        let a_ki = if hit { e[12] * (100.0 - (KI - y3)) } else { a };
        let loss = if hit { e[12] * (100.0 - y3) } else { 0.0 };
        let (mut owed, mut pa, mut pb, mut pbn, mut last) = (0usize, 0.0, 0.0, 0.0, 12usize);
        for j in 1..=12 {                                  // Phoenix, road 1: a ledger
            let sj = path[j - 1];
            owed += 1;
            if sj >= KI { pb += 100.0 * owed as f64 * e[j]; pbn += 100.0 * e[j]; owed = 0; }
            if (j == 4 || j == 8) && sj >= CALL { pa = 100.0 * e[j]; last = j; break; }
            if j == 12 { pa = e[12] * (if sj >= KI { 100.0 } else { sj }); }
        }
        let (mut pb2, mut nxt) = (0.0, 0usize);            // road 2: each quarter's coupon
        for j in (1..=last).rev() {                         // is paid at the next good date
            if path[j - 1] >= KI { nxt = j; }
            pb2 += if nxt > 0 { 100.0 * e[nxt] } else { 0.0 };
        }
        let dig = if path[0] >= KI { e[1] } else { 0.0 };
        let f = |c: bool| if c { 1.0 } else { 0.0 };
        let row = [a, b, a * a, a * b, b * b, a_d3, b_d3, a_ki, loss, pa, pb, pbn, pb2, dig,
                   f(k == 1), f(k == 2), f(k == 3 && y3 >= CALL), f(k == 3 && KI <= y3 && y3 < CALL),
                   f(hit), k as f64, e[4] * y1, e[4] * y1 * e[4] * y1];
        for (x, v) in acc.iter_mut().zip(row.iter()) { *x += v; }
        if first.is_none() { first = Some((path.clone(), k, a, b, pa, pb)); }
    }
    let m: Vec<f64> = acc.iter().map(|x| x / PATHS as f64).collect();
    let (a, b) = (m[0], m[1]);
    let (p1, p2, p3u, p3m, p3d) = (m[14], m[15], m[16], m[17], m[18]);
    let b_sure = 100.0 * (e[4] + e[8] + e[12]);      // coupon read as certain, every year
    let se = |c: f64| {                               // standard error of the price at coupon c
        ((m[2] + 2.0 * c * m[3] + c * c * m[4] - (a + c * b).powi(2)) / (PATHS - 1) as f64).sqrt() };
    let fair = (ISSUE - a) / b;                       // the price is A + cB: solve the line
    let (mut lo, mut hi) = (0.0f64, 0.5f64);          // a search on the same line, for illustration
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if a + mid * b < ISSUE { lo = mid; } else { hi = mid; } }
    let fair_q = (ISSUE - qa) / qb;
    let (d2q, d2c) = (((S0 / KI).ln() + MU * DT) / (SIG * DT.sqrt()), ((S0 / CALL).ln() + MU) / SIG);
    let fp = first.unwrap();
    println!("house: S0 = 100  r = 5%  q = 2%  sigma = 20%   autocall 100, knock-in 70, target {:.0}", ISSUE);
    println!("{} paths of 12 quarterly steps from seed {}", PATHS, SEED);
    let qs: Vec<String> = fp.0.iter().map(|x| format!("{:.2}", x)).collect();
    println!("first path, Acme each quarter: {}", qs.join(" "));
    println!("first path: ends in year {}, autocall redemption {:.6}  coupon part {:.6}", fp.1, fp.2, fp.3);
    println!("            Phoenix redemption {:.6}  coupon units {:.6}", fp.4, fp.5);
    println!("outcomes   called year 1 {:.6}  (closed form N({:.2}) {:.6})  year 2 {:.6}", p1, d2c, ncdf(d2c), p2);
    println!("           year 3 at or above 100 {:.6}   70 to 100 {:.6}   below 70 {:.6}", p3u, p3m, p3d);
    println!("expected life in years {:.6}", m[19]);
    println!("discount factors year 1 {:.6}  year 2 {:.6}  year 3 {:.6}", e[4], e[8], e[12]);
    println!("Acme at year 1, discounted  MC {:.6}  se {:.6}  S0 e^-q {:.6}",
             m[20], ((m[21] - m[20] * m[20]) / (PATHS - 1) as f64).sqrt(), S0 * (-Q).exp());
    println!("A, redemption value      MC {:.6}   quadrature {:.6}", a, qa);
    println!("B, value per unit coupon MC {:.6}   quadrature {:.6}", b, qb);
    println!("knock-in loss L, discounted MC {:.6}", m[8]);
    println!("by hand, B: {:.6} + {:.6} + {:.6}", 100.0 * e[4] * p1, 200.0 * e[8] * p2, 300.0 * e[12] * p3u);
    println!("by hand, A: {:.6} - L;  gap 98 - A {:.6}",
             100.0 * (e[4] * p1 + e[8] * p2 + e[12] * (p3u + p3m + p3d)), ISSUE - a);
    println!("coupon   MC price   std error   quadrature");
    for c in COUPONS {
        println!("{:5.0}%  {:10.6}  {:10.6}  {:11.6}", c * 100.0, a + c * b, se(c), qa + c * qb);
    }
    println!("fair coupon for {:.0}: line {:.6}%  bisection {:.6}%  quadrature {:.6}%",
             ISSUE, fair * 100.0, 0.5 * (lo + hi) * 100.0, fair_q * 100.0);
    println!("std error of the price at the fair coupon {:.6}; of the coupon {:.6}%", se(fair), se(fair) / b * 100.0);
    println!("Phoenix first coupon as a digital, per $1  MC {:.6}   closed form {:.6}", m[13], e[1] * ncdf(d2q));
    println!("  chance Acme is below 70 at quarter 1  MC {:.6}   closed form {:.6}", 1.0 - m[13] / e[1], ncdf(-d2q));
    println!("Phoenix coupon units  ledger {:.6}   next-good-date scan {:.6}", m[10], m[12]);
    println!("Phoenix redemption {:.6}  price at 2% a quarter {:.6}", m[9], m[9] + PHX * m[10]);
    println!("Phoenix fair quarterly coupon for {:.0}: {:.6}%  four quarters {:.6}%", ISSUE,
             (ISSUE - m[9]) / m[10] * 100.0, 4.0 * (ISSUE - m[9]) / m[10] * 100.0);
    println!("what breaks");
    println!("  coupon read as certain for 3 years: fair coupon {:.6}%", (ISSUE - a) / b_sure * 100.0);
    println!("  every payment discounted from year 3: fair coupon {:.6}%", (ISSUE - m[5]) / m[6] * 100.0);
    println!("  loss counted only below 70: fair coupon {:.6}%", (ISSUE - m[7]) / b * 100.0);
    println!("  Phoenix without memory, 2% a quarter: price {:.6}", m[9] + PHX * m[11]);
    let cs: Vec<String> = COUPONS.iter().map(|c| format!("{:6.0}", c * 100.0)).collect();
    let ps: Vec<String> = COUPONS.iter().map(|c| format!("{:6.2}", a + c * b)).collect();
    println!("chart, coupon %   {}", cs.join(" "));
    println!("chart, MC price   {}", ps.join(" "));

    assert!((a - qa).abs() < 4.0 * se(0.0), "redemption value: simulation agrees with quadrature");
    assert!((b - qb).abs() < 4.0 * ((m[4] - b * b) / (PATHS - 1) as f64).sqrt(), "coupon value: the same");
    assert!((fair - fair_q).abs() < 0.002, "fair coupon: simulation agrees with quadrature");
    assert!((p1 - ncdf(d2c)).abs() < 0.005, "year-1 call chance is a digital");
    assert!((m[13] / e[1] - ncdf(d2q)).abs() < 4.0 * (ncdf(d2q) * ncdf(-d2q) / PATHS as f64).sqrt(),
            "first Phoenix coupon is a digital");
    assert!((m[10] - m[12]).abs() < 1e-9, "memory ledger equals the next-good-date scan");
    let fwd_se = ((m[21] - m[20] * m[20]) / (PATHS - 1) as f64).sqrt();
    assert!((m[20] - S0 * (-Q).exp()).abs() < 4.0 * fwd_se, "pricing-world growth: Acme vs S0 e^-q");
    println!("ALL CHECKS PASS");
}
