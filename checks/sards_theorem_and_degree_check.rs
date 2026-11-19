// Sard's theorem and degree -- the check behind the card.  Rust std only, no crates.
// A spinner: one turn of the knob (angle t) drives the pointer to F(t) = G t + A sin t radians.
// The degree comes three ways: preimages counted with signs, net turns read from pointer
// positions alone, and the integral of the slope F'.  Signs are re-read in a second chart.
use std::collections::BTreeMap;
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;
const G: i32 = 2; // gear ratio
const A: f64 = 3.0; // wobble, radians
const N: usize = 3600; // grid steps

fn f(t: f64) -> f64 { G as f64 * t + A * t.sin() } // pointer angle, not wrapped, radians
fn df(t: f64) -> f64 { G as f64 + A * t.cos() } // slope: pointer turn per knob turn
fn deg(x: f64) -> f64 { x.to_degrees() }
fn fix(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } } // print -0.00 as 0.00
fn sgn(s: f64) -> i32 { if s.abs() < 1e-9 { 0 } else if s > 0.0 { 1 } else { -1 } }

// knob angles where g = y + whole turns; g is a formula on all reals, g(t + TAU) = g(t) + G TAU
fn preimages(g: &dyn Fn(f64) -> f64, y: f64, lo: f64, hi: f64, closed: bool) -> Vec<f64> {
    let ts: Vec<f64> = (0..N).map(|i| lo + (i as f64 + 0.5) * (hi - lo) / N as f64).collect();
    let mut out = Vec::new();
    for i in 0..(if closed { N } else { N - 1 }) {
        let (mut a, mut b) = (ts[i], if i < N - 1 { ts[i + 1] } else { ts[0] + TAU });
        let ka = ((g(a) - y) / TAU).floor();
        let kb = ((g(b) - y) / TAU).floor();
        if ka != kb { // the cell crosses the level y + max(ka, kb) turns
            let lev = y + TAU * ka.max(kb);
            for _ in 0..60 { // bisection
                let m = (a + b) / 2.0;
                if (g(a) - lev) * (g(m) - lev) <= 0.0 { b = m } else { a = m }
            }
            let r = ((a + b) / 2.0).rem_euclid(TAU);
            out.push(if r > TAU - 1e-9 { 0.0 } else { r });
        }
    }
    out.sort_by(|p, q| p.partial_cmp(q).unwrap());
    out
}

fn signed(g: &dyn Fn(f64) -> f64, dg: &dyn Fn(f64) -> f64, y: f64, hi: f64, closed: bool) -> i32 {
    preimages(g, y, 0.0, hi, closed).iter().map(|&t| sgn(dg(t))).sum()
}

fn net_turns(g: &dyn Fn(f64) -> f64) -> f64 { // road 2: positions only, small turns by atan2
    let (mut total, mut prev) = (0.0, (g(0.0).cos(), g(0.0).sin()));
    for i in 1..=N {
        let x = g(TAU * i as f64 / N as f64);
        let p = (x.cos(), x.sin());
        total += (prev.0 * p.1 - prev.1 * p.0).atan2(prev.0 * p.0 + prev.1 * p.1);
        prev = p;
    }
    total / TAU
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { // road 3: integral of the slope
    let h = (b - a) / N as f64;
    let mut s = 0.0;
    for i in 0..=N {
        let w = if i == 0 || i == N { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * g(a + i as f64 * h);
    }
    h / 3.0 * s
}

fn chart_slope(t: f64, y: f64) -> f64 { // second chart: u = tan((angle - c)/2), c = 0 or pi
    let cs = if t.cos() > 0.0 { 0.0 } else { PI };
    let cy = if y.cos() > 0.0 { 0.0 } else { PI };
    let phi = |u: f64| ((f(cs + 2.0 * u.atan()) - cy) / 2.0).tan();
    let (u, h) = (((t - cs) / 2.0).tan(), 1e-6);
    (phi(u + h) - phi(u - h)) / (2.0 * h)
}
fn join(v: &[String], sep: &str) -> String { v.join(sep) }
fn main() {
    println!("spinner: pointer = {} x knob + {:.1} rad x sin(knob); wobble {:.2} deg", G, A, deg(A));
    let knobs: Vec<i32> = (0..=360).step_by(15).collect();
    println!("chart,knob,{}", join(&knobs.iter().map(|k| k.to_string()).collect::<Vec<_>>(), ","));
    println!("chart,pointer,{}", join(&knobs.iter().map(|&k| format!("{:.1}", deg(f((k as f64).to_radians())))).collect::<Vec<_>>(), ","));
    println!("chart,gear only,{}", join(&knobs.iter().map(|&k| format!("{:.1}", (G * k) as f64)).collect::<Vec<_>>(), ","));

    let mut crit = Vec::new(); // critical points: where the slope changes sign
    for i in 0..N {
        let (mut a, mut b) = ((i as f64 + 0.5) * TAU / N as f64, (i as f64 + 1.5) * TAU / N as f64);
        if df(a) * df(b) < 0.0 {
            for _ in 0..60 {
                let m = (a + b) / 2.0;
                if df(a) * df(m) <= 0.0 { b = m } else { a = m }
            }
            crit.push(((a + b) / 2.0).rem_euclid(TAU));
        }
    }
    let cvals: Vec<f64> = crit.iter().map(|&c| deg(f(c)).rem_euclid(360.0)).collect();
    println!("critical knob angles (slope 0): {}", join(&crit.iter().map(|&c| format!("{:.2}", deg(c))).collect::<Vec<_>>(), " "));
    println!("critical values (pointer): {}", join(&cvals.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>(), " "));

    for (name, yd) in [("12 o'clock", 0), ("3 o'clock", 90), ("6 o'clock", 180), ("9 o'clock", 270)] {
        let ts = preimages(&f, (yd as f64).to_radians(), 0.0, TAU, true);
        let s: i32 = ts.iter().map(|&t| sgn(df(t))).sum();
        println!("target {} ({} deg): {} -> unsigned {}, signed {}", name, yd,
                 join(&ts.iter().map(|&t| format!("{:.2}({:+.3})", fix(deg(t)), df(t))).collect::<Vec<_>>(), " "), ts.len(), s);
    }
    let ts0 = preimages(&f, 0.0, 0.0, TAU, true);
    println!("by hand: {}", join(&ts0.iter().map(|&t| format!("{:.2} {:+.2} = {:.2}", G as f64 * deg(t), fix(deg(A * t.sin())), deg(f(t)))).collect::<Vec<_>>(), "; "));
    let cs: Vec<f64> = ts0.iter().map(|&t| chart_slope(t, 0.0)).collect();
    println!("slopes read in the tan charts: {}", join(&cs.iter().map(|s| format!("{:+.3}", s)).collect::<Vec<_>>(), " "));
    assert!(cs.iter().zip(&ts0).all(|(&s, &t)| sgn(s) == sgn(df(t))), "a chart change flipped a sign");

    let mut tally: BTreeMap<usize, usize> = BTreeMap::new();
    let mut signs = std::collections::BTreeSet::new();
    for j in 0..360 { // targets at 0.5, 1.5, ..., 359.5 degrees
        let ts = preimages(&f, (j as f64 + 0.5).to_radians(), 0.0, TAU, true);
        *tally.entry(ts.len()).or_insert(0) += 1;
        signs.insert(ts.iter().map(|&t| sgn(df(t))).sum::<i32>());
    }
    println!("unsigned counts over 360 targets: {}", join(&tally.iter().map(|(k, v)| format!("{} at {}", k, v)).collect::<Vec<_>>(), ", "));
    println!("signed counts over 360 targets: {:?}", signs.iter().collect::<Vec<_>>());
    let (d1, d2, d3) = (signed(&f, &df, 0.0, TAU, true), net_turns(&f), simpson(&df, 0.0, TAU) / TAU);
    println!("road 1 signed count {}; road 2 net turns {:.6}; road 3 slope integral {:.6}", d1, d2, d3);
    assert!(signs.len() == 1 && signs.contains(&d1) && (d2 - d1 as f64).abs() < 1e-9 && (d3 - d1 as f64).abs() < 1e-9, "the three roads disagree");
    assert!((tally.len() > 1) == !crit.is_empty(), "unsigned counts vary exactly when the map folds");

    let mut covers = Vec::new();
    for (m, lab) in [(36usize, "10"), (360, "1"), (3600, "0.1")] { // Sard: image of the arcs holding a critical point
        let (w, mut tot) = (TAU / m as f64, 0.0);
        for i in 0..m {
            if df(i as f64 * w) * df((i + 1) as f64 * w) < 0.0 { // samples, plus the turning point itself
                let vals: Vec<f64> = (0..=200).map(|k| f(i as f64 * w + w * k as f64 / 200.0)).chain(crit.iter().filter(|&&c| (c / w) as usize == i).map(|&c| f(c))).collect();
                tot += deg(vals.iter().fold(f64::MIN, |a, &v| a.max(v)) - vals.iter().fold(f64::MAX, |a, &v| a.min(v)));
            }
        }
        println!("sard cover, {} arcs of {} deg: bad values fill {:.6} deg", m, lab, tot);
        covers.push(tot);
    }
    assert!(covers.windows(2).all(|p| p[0] > 50.0 * p[1]), "a tenfold finer cover shrinks like the square");

    if !crit.is_empty() { // what breaks 1: count at a critical value
        let yc = f(crit[0]);
        let mut near: Vec<f64> = preimages(&f, yc, 0.0, TAU, true).into_iter().filter(|t| (t - crit[0]).abs() > 1e-3).collect();
        near.push(crit[0]);
        near.sort_by(|p, q| p.partial_cmp(q).unwrap());
        println!("at critical value {:.2}: knob {} -> {} points, one has no sign", cvals[0],
                 join(&near.iter().map(|&t| format!("{:.2}({:+.3})", deg(t), fix(df(t)))).collect::<Vec<_>>(), " "), near.len());
        assert!(sgn(df(crit[0])) == 0 && (near.len() as i32 - 1 - d1) % 2 == 0, "transverse points = degree mod 2");
    }
    let op: Vec<i32> = (0..360).map(|j| signed(&f, &df, (j as f64 + 0.5).to_radians(), 240f64.to_radians(), false)).collect();
    let mut seen = op.clone();
    seen.sort();
    seen.dedup();
    println!("knob limited to 0-240 deg: signed count {} at 359.5 deg, {} at 179.5 deg; values seen {:?}", op[359], op[179], seen);
    assert!(seen.len() > 1, "an open source lets the signed count change");

    let mut cells = vec![(0.0f64, 1.0f64, 0.0f64, 1.0f64)]; // what breaks 2: the devil's staircase
    let (mut cov, mut img) = (0.0, 0.0);
    for k in 1..=12 {
        cells = cells.iter().flat_map(|&(a, b, ca, cb)| vec![(a, a + (b - a) / 3.0, ca, (ca + cb) / 2.0),
                                                             (b - (b - a) / 3.0, b, (ca + cb) / 2.0, cb)]).collect();
        if k == 4 || k == 8 || k == 12 {
            cov = cells.iter().fold(0.0, |s, c| s + (c.1 - c.0));
            img = cells.iter().fold(0.0, |s, c| s + (c.3 - c.2));
            println!("staircase stage {}: rough points covered by length {:.6}, their images {:.6} turn", k, cov, img);
        }
    }
    assert!((cov - (2.0f64 / 3.0).powi(12)).abs() < 1e-12 && (img - 1.0).abs() < 1e-12);
    println!("staircase: slope 0 on gaps of length {:.6}, so slope integral -> 0 turns; pointer turns {:.0}", 1.0 - cov, img);

    let (mf, mdf) = (|t: f64| -f(t), |t: f64| -df(t));
    let mirror = (signed(&mf, &mdf, 0.0, TAU, true), net_turns(&mf));
    println!("mirrored dial: signed count {}, net turns {:.6}", mirror.0, mirror.1);
    assert!(mirror.0 == -d1 && (mirror.1 + d1 as f64).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
