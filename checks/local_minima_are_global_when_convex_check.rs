// Local minima are global when convex -- the same check as the Python, in Rust.
// No crates.  A roaster blends Brazil, Colombia and Sumatra beans.  The shares
// x = (xB, xC, xE) add to 1, the blend's strength score must reach 7, and each
// bean's price per kilo climbs 50p for every tenth of the blend it supplies.
type X = [f64; 3];
const BASE: X = [6.0, 9.0, 11.0];
const RISE: f64 = 5.0;
const SCORE: X = [5.0, 6.0, 9.0];
const NEED: f64 = 7.0;
const FLAT: X = [9.5, 11.0, 15.5]; // a second quote: flat prices, no rise
const E: X = [0.0, 0.0, 1.0];
const P: X = [0.5, 0.0, 0.5];
const Q: X = [0.0, 2.0 / 3.0, 1.0 / 3.0]; // corners of the allowed set

fn cost(x: &X) -> f64 { (0..3).map(|i| BASE[i] * x[i] + RISE * x[i] * x[i]).sum() }
fn flat(x: &X) -> f64 { (0..3).map(|i| FLAT[i] * x[i]).sum() }
fn strength(x: &X) -> f64 { (0..3).map(|i| SCORE[i] * x[i]).sum() }
fn allowed(x: &X, need: f64, least: f64) -> bool { // least > 0: the minimum-order rule
    if x.iter().any(|&v| v < -1e-12) || strength(x) < need - 1e-12 { return false; }
    !x.iter().any(|&v| v > 1e-12 && v < least - 1e-12)
}
fn mix(x: &X, y: &X, th: f64) -> X { [0, 1, 2].map(|i| th * x[i] + (1.0 - th) * y[i]) }
fn edge(c: f64) -> X { [(2.0 - 3.0 * c) / 4.0, c, (2.0 - c) / 4.0] } // strength exactly 7
fn show(x: &X) -> String { format!("({:.3}, {:.3}, {:.3})", x[0], x[1], x[2]) }
fn list(v: &[f64]) -> String { v.iter().map(|a| format!("{:.3}", a)).collect::<Vec<_>>().join(", ") }

fn moves() -> Vec<X> {
    let mut m = Vec::new();
    for i in 0..3 { for j in 0..3 { if i != j {      // six swaps between two beans
        let mut d = [0.0; 3]; d[i] = 1.0; d[j] = -1.0; m.push(d);
    } } }
    m.push([-0.75, 1.0, -0.25]); m.push([0.75, -1.0, 0.25]); // two moves along strength 7
    m
}

fn compass(start: X, need: f64, least: f64) -> (X, usize) { // road 1: looks only nearby
    let (mut x, mut h, mut steps) = (start, 0.1, 0);
    let ms = moves();
    while h > 1e-7 {
        let mut best: Option<X> = None;
        for m in &ms {
            let y = [0, 1, 2].map(|i| x[i] + h * m[i]);
            if allowed(&y, need, least) && cost(&y) < cost(&x) - 1e-15
                && best.map_or(true, |b| cost(&y) < cost(&b)) { best = Some(y); }
        }
        match best { Some(y) => { x = y; steps += 1; } None => h /= 2.0 } // else look closer
    }
    (x, steps)
}

fn grid(n: usize, least: f64, price: fn(&X) -> f64) -> (f64, Vec<X>, usize) { // road 4
    let mut pts = Vec::new();
    for i in 0..=n { for j in 0..=(n - i) {
        let x = [i as f64 / n as f64, j as f64 / n as f64, (n - i - j) as f64 / n as f64];
        if allowed(&x, NEED, least) { pts.push(x); }
    } }
    let best = pts.iter().map(|x| price(x)).fold(f64::INFINITY, f64::min);
    let arg: Vec<X> = pts.iter().filter(|x| price(x) < best + 1e-9).cloned().collect();
    (best, arg, pts.len())
}

fn main() {
    println!("bean prices at zero share, pounds a kilo: ({:.1}, {:.1}, {:.1}) ; rise per tenth of the blend: {:.2}",
             BASE[0], BASE[1], BASE[2], RISE / 10.0);
    println!("strength scores: ({}, {}, {}) ; the blend needs at least {}", SCORE[0], SCORE[1], SCORE[2], NEED);
    println!("corners of the allowed set: E {} P {} Q {}", show(&E), show(&P), show(&Q));
    println!("cost at the corners: {}", list(&[cost(&E), cost(&P), cost(&Q)]));
    let mut runs = Vec::new();
    for (name, start) in [("E", E), ("P", P), ("Q", Q)] {
        let (x, n) = compass(start, NEED, 0.0);
        runs.push(x);
        println!("compass search from {}: {} cost {:.3} after {} moves", name, show(&x), cost(&x), n);
    }
    let xs = runs[0];
    let (c0, c1, c2) = (cost(&edge(0.0)), cost(&edge(1.0 / 3.0)), cost(&edge(2.0 / 3.0))); // road 2
    let a = (c2 - 2.0 * c1 + c0) * 9.0 / 2.0; // cost along the edge = c0 + b c + a c^2
    let b = (c1 - c0) * 3.0 - a / 3.0;
    let cv = -b / (2.0 * a);
    println!("along the strength-7 edge: cost = {:.3} + ({:.3}) xC + {:.3} xC^2", c0, b, a);
    println!("slope zero at xC = {:.3}: blend {} cost {:.3}", cv, show(&edge(cv)), cost(&edge(cv)));
    println!("at x*: base part {:.3}, rise part {:.3}", (0..3).map(|i| BASE[i] * xs[i]).sum::<f64>(),
             (0..3).map(|i| RISE * xs[i] * xs[i]).sum::<f64>());
    let g: X = [0, 1, 2].map(|i| BASE[i] + 2.0 * RISE * xs[i]); // road 3: the certificate
    let hd = 1e-5;
    let gd: X = [0, 1, 2].map(|i| {
        let (mut up, mut dn) = (xs, xs); up[i] += hd; dn[i] -= hd;
        (cost(&up) - cost(&dn)) / (2.0 * hd)
    });
    let cert: Vec<f64> = [E, P, Q].iter().map(|c| (0..3).map(|i| g[i] * (c[i] - xs[i])).sum()).collect();
    println!("gradient at x*: {} ; by central difference: {}", show(&g), show(&gd));
    let shown: Vec<f64> = cert.iter().map(|v| (v * 1e9).round() / 1e9 + 0.0).collect();
    println!("slope from x* toward E, P, Q: {}", list(&shown));
    let (best, arg, npts) = grid(200, 0.0, cost);
    println!("every allowed blend in steps of 1/200: {} blends, cheapest {:.3} at {}", npts, best, show(&arg[0]));
    for th in [0.9, 0.5] { // the chord bound on the segment from x* to E
        let m = mix(&xs, &E, th);
        println!("{:.0}% x* + {:.0}% E = {}, strength {:.3}, cost {:.3}, chord {:.3}", th * 100.0,
                 (1.0 - th) * 100.0, show(&m), strength(&m), cost(&m), th * cost(&xs) + (1.0 - th) * cost(&E));
    }
    println!("flat quote at P, Q, their midpoint, E: {}", list(&[flat(&P), flat(&Q), flat(&mix(&P, &Q, 0.5)), flat(&E)]));
    println!("flat quote minus 2, divided by 1.5: {} = the strength scores", show(&FLAT.map(|p| (p - 2.0) / 1.5)));
    let (fbest, ties, _) = grid(60, 0.0, flat);
    let st: Vec<f64> = ties.iter().map(strength).collect();
    println!("flat quote, every blend in steps of 1/60: {} tie at {:.3}, strengths {:.3} to {:.3}", ties.len(), fbest,
             st.iter().cloned().fold(f64::INFINITY, f64::min), st.iter().cloned().fold(f64::NEG_INFINITY, f64::max));
    let along: Vec<f64> = (0..7).map(|k| cost(&edge(k as f64 / 10.0))).collect();
    let along_f: Vec<f64> = (0..7).map(|k| flat(&edge(k as f64 / 10.0))).collect();
    println!("cost along the edge, xC = 0 to 0.6: {}", list(&along));
    println!("flat quote along the edge:          {}", list(&along_f));
    let (u, _) = compass(E, 0.0, 0.0); // what breaks 1: the strength rule dropped
    let gu: X = [0, 1, 2].map(|i| BASE[i] + 2.0 * RISE * u[i]); // gradient at the dip: equal entries, not zero
    println!("mistake 1, no strength rule: {} cost {:.3}, strength {:.3}, gradient {}", show(&u), cost(&u), strength(&u), show(&gu));
    let (s1, _) = compass(E, NEED, 0.4); // what breaks 2 and 3: the 40% minimum order
    let (s2, _) = compass([0.0, 0.4, 0.6], NEED, 0.4);
    let (r_best, r_arg, _) = grid(200, 0.4, cost);
    println!("mistake 2, 40% rule, search from E: stuck at {} cost {:.3}", show(&s1), cost(&s1));
    println!("mistake 3, 40% rule, search from (0, 0.4, 0.6): stuck at {} cost {:.3}", show(&s2), cost(&s2));
    println!("40% rule, every allowed blend in steps of 1/200: cheapest {:.3} at {}", r_best, show(&r_arg[0]));
    let m = mix(&E, &P, 0.9);
    println!("the broken step: 90% E + 10% P = {} cost {:.3}, allowed under the 40% rule: {}", show(&m), cost(&m),
             if allowed(&m, NEED, 0.4) { "yes" } else { "no" });
    println!("figure, E (0, 0), P (0.5, 0), Q (0, 0.667), x* (0.35, 0.2), dip ({:.2}, {:.2}), in (xB, xC)", u[0], u[1]);

    assert!(runs.iter().all(|r| (0..3).all(|i| (r[i] - [0.35, 0.2, 0.45][i]).abs() < 1e-5)));
    assert!((cv - 0.2).abs() < 1e-9 && (cost(&edge(cv)) - cost(&xs)).abs() < 1e-9); // by hand = search
    assert!(cert.iter().all(|&v| v > -1e-6) && (0..3).all(|i| (g[i] - gd[i]).abs() < 1e-6)); // certificate
    assert!((best - cost(&xs)).abs() < 1e-9 && arg == vec![[0.35, 0.2, 0.45]]); // enumeration
    assert!(ties.len() == 11 && ties.iter().all(|x| (strength(x) - NEED).abs() < 1e-9));
    assert!((cost(&u) - 9.7).abs() < 1e-9 && strength(&u) < NEED); // the dip is not allowed
    let (gmin, gmax) = (gu.iter().cloned().fold(f64::INFINITY, f64::min), gu.iter().cloned().fold(f64::NEG_INFINITY, f64::max));
    assert!(gmax - gmin < 1e-6 && gmin > 0.0); // its gradient: level along every swap, yet not zero
    assert!(cost(&s1) > cost(&s2) && cost(&s2) > r_best + 1.0 && !allowed(&m, NEED, 0.4) && cost(&m) < cost(&E));
    println!("ALL CHECKS PASS");
}
