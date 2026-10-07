// Convenience yield implied by the forward -- the same check as the Python, in Rust.
// Standard library only, no crates.  Crude at 80, rates 5%, storage 2% a year,
// one-year market forward at 84.  Three roads to the implied yield y that share
// no step: the closed form, bisection with no logarithm, and a series on the gap.
// Compile: rustc --edition 2021 -O convenience_yield_implied_by_the_forward_check.rs

fn forward(s: f64, r: f64, u: f64, y: f64, t: f64) -> f64 {   // the carry formula, forwards
    s * ((r + u - y) * t).exp()
}

fn y_closed(s: f64, r: f64, u: f64, f: f64, t: f64) -> f64 {  // road 1: backwards, one log
    r + u - (f / s).ln() / t
}

fn y_bisect(s: f64, r: f64, u: f64, f: f64, t: f64) -> f64 {  // road 2: never takes a log
    let (mut lo, mut hi) = (-1.0_f64, 1.0_f64);
    while forward(s, r, u, lo, t) < f { lo *= 2.0; }          // forward falls as y rises
    while forward(s, r, u, hi, t) > f { hi *= 2.0; }
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if forward(s, r, u, mid, t) > f { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn y_series(s: f64, r: f64, u: f64, f: f64, t: f64) -> f64 {  // road 3: -ln(1 - x) as a series
    let c = s * ((r + u) * t).exp();
    let x = (c - f) / c;
    let (mut total, mut term, mut k) = (0.0_f64, x, 1.0_f64);
    while term.abs() > 1e-18 {
        total += term / k;
        k += 1.0;
        term *= x;
    }
    total / t
}

fn main() {
    let (s, r, u, f, t) = (80.0_f64, 0.05_f64, 0.02_f64, 84.0_f64, 1.0_f64);
    let c = s * ((r + u) * t).exp();
    let g = c - f;
    let (y1, y2, y3) = (y_closed(s, r, u, f, t), y_bisect(s, r, u, f, t), y_series(s, r, u, f, t));

    let h = 0.01;                                              // slope: bump the forward a cent
    let slope_bump = (y_closed(s, r, u, f + h, t) - y_closed(s, r, u, f - h, t)) / (2.0 * h);
    let f1m = forward(s, r, u, y1, 1.0 / 12.0);                // a one-month quote, same yield
    let cent_1m = y_closed(s, r, u, f1m - 0.01, 1.0 / 12.0) - y1;

    let rows: Vec<(&str, f64)> = vec![
        ("ceiling C = S e^((r+u)T)", c), ("gap G = C - F, delivery day", g),
        ("gap in today's dollars", g * (-r * t).exp()), ("ln(F/S)", (f / s).ln()),
        ("sell 80, bank it: S e^(rT)", s * (r * t).exp()), ("storage saved: C - S e^(rT)", c - s * (r * t).exp()),
        ("1 closed form y", y1), ("2 bisection, no log", y2), ("3 series on the gap", y3),
        ("  first term only, G/C", g / c), ("forward rebuilt from y", forward(s, r, u, y1, t)),
        ("boundary: F = C gives y", y_closed(s, r, u, c, t)),
        ("boundary: F = S gives y", y_closed(s, r, u, s, t)),
        ("boundary: F = 86.50 gives y", y_closed(s, r, u, 86.50, t)),
        ("boundary: F = 1.00 gives y", y_closed(s, r, u, 1.00, t)),
        ("slope dy/dF by bump", slope_bump), ("  -1/(F T)", -1.0 / (f * t)),
        ("one-month forward, same y", f1m), ("  y moved by a 1-cent error", cent_1m),
        ("  same cent on the 1-year quote", y_closed(s, r, u, f - 0.01, t) - y1),
        ("wrong: 5% annual as continuous", r - (1.0 + r).ln()),
        ("wrong: storage left out", y_closed(s, r, 0.0, f, t)),
        ("wrong: F/S - 1 for ln(F/S)", r + u - (f / s - 1.0) / t),
        ("wrong: ln(S/F), sign flipped", r + u - (s / f).ln() / t),
        ("wrong: T = 12 for a year", y_closed(s, r, u, f, 12.0)),
        ("gold: 2000, 5%, fwd 2081.62", y_closed(2000.0, 0.05, 0.0, 2081.62, 1.0)),
        ("try: storage 3%", y_closed(s, r, 0.03, f, t)), ("try: rates 4%", y_closed(s, 0.04, u, f, t)),
        ("try: 6-month forward 82", y_closed(s, r, u, 82.0, 0.5)),
    ];
    for (name, v) in &rows { println!("{:<32} {:>12.6}", name, v); }

    println!();
    println!("inventory state    forward   implied y %");         // illustrative quotes, not market data
    let states = [("glut", 85.50_f64), ("comfortable", 84.00), ("tight", 81.00), ("squeeze", 78.00)];
    let mut ys: Vec<f64> = Vec::new();
    for (name, fq) in states.iter() {
        ys.push(y_closed(s, r, u, *fq, t));
        println!("{:<16} {:9.2} {:12.2}", name, fq, 100.0 * ys[ys.len() - 1]);
    }

    println!();
    let grid: Vec<f64> = (0..11).map(|i| 76.0 + i as f64).collect();
    let curve: Vec<f64> = grid.iter().map(|fq| y_closed(s, r, u, *fq, t)).collect();
    let fs: Vec<String> = grid.iter().map(|fq| format!("{:6.0}", fq)).collect();
    let vs: Vec<String> = curve.iter().map(|v| format!("{:6.2}", 100.0 * v)).collect();
    println!("chart, forward  {}", fs.join(" "));
    println!("chart, y %      {}", vs.join(" "));

    assert!((y2 - y1).abs() < 1e-12, "bisection (no log) must land on the closed form");
    assert!((y3 - y1).abs() < 1e-12, "series on the gap must land on the closed form");
    assert!((forward(s, r, u, y1, t) - f).abs() < 1e-9, "the implied yield must rebuild the market forward");
    assert!((slope_bump - (-1.0 / (f * t))).abs() < 1e-8, "bumped slope vs -1/(F T)");
    assert!(curve.windows(2).all(|w| w[0] > w[1]), "y must fall strictly as the forward rises: one answer per quote");
    assert!(ys.windows(2).all(|w| w[0] < w[1]), "tighter market, lower forward, higher y");
    println!("ALL CHECKS PASS");
}
