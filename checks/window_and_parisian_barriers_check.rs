// Window and Parisian barriers -- the same check as the Python, in Rust.  No crates.
// Road 1: condition on the price when the window opens and integrate the 16-02
// down-and-out formula over it (Simpson).  Road 2: a double integral of the payoff
// against the reflected transition density, no formula blocks.  Road 3: a 252-step
// simulation with the Brownian-bridge chance of a touch, which also prices the
// Parisian clause; it is checked against the 16-02 and 16-03 formulas.
use std::f64::consts::PI;
const S: f64 = 100.0; const K: f64 = 100.0; const H: f64 = 80.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const T0: f64 = 0.5;
fn nu() -> f64 { R - Q - 0.5 * SIG * SIG }
fn mu() -> f64 { nu() / (SIG * SIG) }
fn bl() -> f64 { (H / S).ln() }
fn dens(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 {                                   // bell-curve area left of x, by its series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut tot, mut n) = (x, x, 1.0);
    while term.abs() > 1e-17 * tot.abs() + 1e-300 { n += 2.0; term *= x * x / n; tot += term; }
    0.5 + dens(x) * tot
}
fn call(s: f64, tau: f64) -> f64 {                         // plain call, block A of 16-02
    let v = SIG * tau.sqrt(); let d1 = (s / K).ln() / v + (1.0 + mu()) * v;
    s * (-Q * tau).exp() * ncdf(d1) - K * (-R * tau).exp() * ncdf(d1 - v)
}
fn doc(s: f64, tau: f64, h: f64) -> f64 {                  // down-and-out call, strike above barrier: A - C
    if s <= h { return 0.0; }
    let (v, m) = (SIG * tau.sqrt(), mu()); let y1 = (h * h / (s * K)).ln() / v + (1.0 + m) * v;
    let c = s * (-Q * tau).exp() * (h / s).powf(2.0 * m + 2.0) * ncdf(y1) - K * (-R * tau).exp() * (h / s).powf(2.0 * m) * ncdf(y1 - v);
    call(s, tau) - c
}
fn touch(s: f64, tau: f64) -> f64 {                        // chance a down line at H is touched within tau
    let (v, c) = (SIG * tau.sqrt(), (H / s).ln());
    ncdf((c - nu() * tau) / v) + (H / s).powf(2.0 * mu()) * ncdf((c + nu() * tau) / v)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, c: f64, n: usize) -> f64 {
    let h = (c - a) / n as f64; let mut tot = f(a) + f(c);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * tot
}
fn f_at(t: f64, x: f64) -> f64 { dens((x - nu() * t) / (SIG * t.sqrt())) / (SIG * t.sqrt()) }
fn avg_at<G: Fn(f64) -> f64>(t0: f64, g: G, lo: f64, hi: f64) -> f64 {   // average of g(price at t0)
    simpson(|x| f_at(t0, x) * g(S * x.exp()), lo, hi, 2000)
}
fn window(t0: f64, h: f64) -> f64 {                        // road 1: discounted average of the knock-out at t0
    if t0 <= 0.0 { return doc(S, T, h); }
    if t0 >= T { return call(S, T); }
    (-R * t0).exp() * avg_at(t0, |s| doc(s, T - t0, h), (h / S).ln(), nu() * t0 + 10.0 * SIG * t0.sqrt())
}
fn window_2d(t0: f64, n: usize) -> f64 {                   // road 2: payoff against reflected density
    let (tau, b) = (T - t0, bl()); let sd = SIG * tau.sqrt(); let g = |z: f64| dens((z - nu() * tau) / sd) / sd;
    let (xh, yh) = (nu() * t0 + 9.0 * SIG * t0.sqrt(), nu() * T + 9.0 * SIG * T.sqrt());
    let over_y = |x: f64| {
        let tilt = (2.0 * nu() * (b - x) / (SIG * SIG)).exp();
        f_at(t0, x) * simpson(|y| (S * y.exp() - K) * (g(y - x) - tilt * g(y - 2.0 * b + x)), (K / S).ln(), yh, n)
    };
    (-R * T).exp() * simpson(over_y, b, xh, n)
}
fn main() {
    let (nu, b) = (nu(), bl());
    let (van, docv) = (call(S, T), doc(S, T, H));
    let (w1, w2) = (window(T0, H), window_2d(T0, 400));
    let (lo, hi) = (b - 10.0 * SIG * T0.sqrt(), nu * T0 + 10.0 * SIG * T0.sqrt());
    let below = (-R * T0).exp() * avg_at(T0, |s| call(s, T - T0), lo, b);   // value of paths under 80 at 0.5
    let tl = (2.0 * nu * b / (SIG * SIG)).exp();                              // front window: barrier 0 to 0.5 only
    let front = (-R * T0).exp() * simpson(|x| (f_at(T0, x) - tl * f_at(T0, x - 2.0 * b)) * call(S * x.exp(), T - T0), b, hi, 2000);
    let bgk = doc(S, T, H * (-0.5826 * SIG * (T / 252.0).sqrt()).exp());   // 16-03: daily checks = barrier pushed out
    let p_below = ncdf((b - nu * T0) / (SIG * T0.sqrt()));
    let p_win = p_below + avg_at(T0, |s| touch(s, T - T0), b, hi);
    // ---- road 3: simulation, 252 daily closes ----
    let mut state: u64 = 20261123;
    let mut uniform = || { state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((state >> 11) as f64 + 0.5) / 9007199254740992.0 };
    let (paths, steps, open) = (150000usize, 252usize, 126usize);
    let dt = T / steps as f64; let drift = nu * dt; let vol = SIG * dt.sqrt(); let v2 = vol * vol;
    let days = [1usize, 2, 3, 5, 10, 20];
    let mut acc = [[0.0f64; 2]; 10]; let mut hits = [0usize; 6];   // 0 full, 1 window, 2..8 the D's, 8 cumulative 5, 9 direct D 5
    let add = |acc: &mut [[f64; 2]; 10], k: usize, x: f64| { acc[k][0] += x; acc[k][1] += x * x; };
    for _ in 0..paths {
        let (mut x, mut wf, mut ww, mut run, mut best, mut cum) = (0.0f64, 1.0f64, 1.0f64, 0usize, 0usize, 0usize);
        let mut zs: Vec<f64> = Vec::new();
        for i in 1..=steps {
            if zs.is_empty() {
                let u1 = uniform(); let u2 = uniform(); let m = (-2.0 * u1.ln()).sqrt();
                zs = vec![m * (2.0 * PI * u2).sin(), m * (2.0 * PI * u2).cos()];
            }
            let y = x + drift + vol * zs.pop().unwrap();
            let keep = if x <= b || y <= b { 0.0 } else { 1.0 - (-2.0 * (x - b) * (y - b) / v2).exp() };
            wf *= keep;                                    // whole year, watched every instant
            if i == open && y <= b { ww = 0.0; }           // window opens with the price under the line
            if i > open { ww *= keep; }
            if y < b { run += 1; cum += 1; best = best.max(run); } else { run = 0; }
            x = y;
        }
        let p = (-R * T).exp() * (S * x.exp() - K).max(0.0);   // lost value: what the knock-out takes away
        add(&mut acc, 0, p * (1.0 - wf)); add(&mut acc, 1, p * (1.0 - ww));
        add(&mut acc, 8, if cum >= 5 { p } else { 0.0 }); add(&mut acc, 9, if best < 5 { p } else { 0.0 });
        for (j, &d) in days.iter().enumerate() {
            add(&mut acc, 2 + j, if best >= d { p } else { 0.0 }); if best >= d { hits[j] += 1; }
        }
    }
    let mc = |k: usize| { let m = acc[k][0] / paths as f64;
        (van - m, ((acc[k][1] / paths as f64 - m * m).max(0.0) / paths as f64).sqrt()) };
    println!("house: S 100, K 100, barrier 80, r 5%, q 2%, sigma 20%, T 1; window opens at 0.5");
    println!("plain call                         {:.6}", van);
    println!("down-and-out, whole year (16-02)   {:.6}", docv);
    println!("window 0.5 to 1, road 1 (1-D)      {:.6}", w1);
    println!("window 0.5 to 1, road 2 (2-D)      {:.6}", w2);
    let (mw, sw) = mc(1); let (mf, sf) = mc(0);
    println!("window 0.5 to 1, road 3 simulated  {:.4} +/- {:.4}", mw, sw);
    println!("whole year simulated, bridge       {:.4} +/- {:.4}", mf, sf);
    println!("daily-checked whole year (16-03)   {:.6}  lost {:.6}", bgk, van - bgk);
    println!("Parisian: knocked out after D consecutive daily closes below 80");
    let mut par = [0.0f64; 6];
    for (j, &d) in days.iter().enumerate() {
        let (pv, se) = mc(2 + j); par[j] = pv;
        println!("  D {:2} days  {:.4} +/- {:.4}  lost {:.4}  paths knocked out {:.4}", d, pv, se, van - pv, hits[j] as f64 / paths as f64);
    }
    let m5 = acc[9][0] / paths as f64;
    println!("direct average of the D 5 payoff {:.4} +/- {:.4}", m5, ((acc[9][1] / paths as f64 - m5 * m5) / paths as f64).sqrt());
    println!("simulation gaps in standard errors: window {:.2}, whole year {:.2}, D 1 {:.2}", (mw - w1).abs() / sw, (mf - docv).abs() / sf, (par[0] - bgk).abs() / mc(2).1);
    println!("worked: log price at 0.5 centre {:.6} spread {:.6}; discount {:.6}", nu * T0, SIG * T0.sqrt(), (-R * T0).exp());
    println!("worked: chance under 80 at 0.5 {:.6}; chance of touching 80 in the window {:.6}; whole year {:.6}", p_below, p_win, touch(S, T));
    for s6 in [80.0, 85.0, 90.0, 100.0, 110.0] {
        println!("worked: price at 0.5 {:5.1}  6-month call {:9.6}  6-month knock-out {:9.6}  lost {:8.6}", s6, call(s6, 0.5), doc(s6, 0.5, H), call(s6, 0.5) - doc(s6, 0.5, H));
    }
    println!("worked: lost value {:.6} = under 80 at the opening {:.6} + touched later {:.6}; whole year {:.6}", van - w1, below, van - w1 - below, van - docv);
    println!("wrong: whole-year formula for the window          {:.6}", docv);
    println!("wrong: half the whole-year discount              {:.6}", van - 0.5 * (van - docv));
    println!("wrong: paths under 80 at 0.5 kept alive           {:.6}", w1 + below);
    println!("wrong: barrier in the first half instead (front)  {:.6}", front);
    println!("wrong: Parisian counting 5 days in total, not in a row {:.4}", mc(8).0);
    let ts: Vec<f64> = (0..11).map(|i| i as f64 / 10.0).collect();
    println!("chart, window opens {}", ts.iter().map(|t| format!("{:5.1}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, price        {}", ts.iter().map(|&t| format!("{:5.3}", window(t, H))).collect::<Vec<_>>().join(" "));
    println!("try: window opens 0.25 {:.6}; window with barrier 85 {:.6}", window(0.25, H), window(T0, 85.0));
    assert!((docv - 9.133306).abs() < 1e-6 && (van - 9.227006).abs() < 1e-6, "16-02 house numbers");
    assert!((w1 - w2).abs() < 1e-6, "conditioning and the reflected double integral must agree");
    assert!((mw - w1).abs() < 3.0 * sw && (mf - docv).abs() < 3.0 * sf, "simulation within three standard errors");
    assert!((par[0] - bgk).abs() < 3.0 * mc(2).1, "Parisian with D = 1 is the daily knock-out of 16-03");
    assert!(docv < w1 && w1 < van && bgk < par[3] && par[3] < van, "bounds: full-life barrier <= window, Parisian <= plain call");
    assert!(par.windows(2).all(|p| p[0] <= p[1]), "a longer wait kills fewer paths");
    assert!(mc(8).0 < par[3], "five days in total happens more often than five in a row");
    println!("ALL CHECKS PASS");
}
