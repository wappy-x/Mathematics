// Forward, backward and central differences -- the check behind the card.
// Rust std only.  The function is the price P(y), in dollars, of $10,000,000
// face of a 30-year bond paying a 4% coupon once a year, at an annual yield y
// near 4.5%.  The step h is one basis point, 0.0001.
// Road one: difference quotients from repriced values.  Road two: the exact
// slope from the price's closed-form derivative.  Road three: the error each
// quotient should have, from Taylor's theorem, using the exact P'' and P'''.
const FACE: f64 = 10_000_000.0;
const CPN: f64 = 0.04;
const YEARS: usize = 30;
const Y0: f64 = 0.045;
const BP: f64 = 0.0001;
type Rule = fn(&dyn Fn(f64) -> f64, f64, f64) -> f64;

fn derivs(y: f64) -> [f64; 4] {
    // P, P', P'', P''' by summing the cash flows
    let d = 1.0 / (1.0 + y);
    let (mut df, mut s) = (1.0, [0.0f64; 4]);
    for t in 1..=YEARS {
        df *= d; // discount factor 1/(1+y)^t by repeated multiply
        let a = FACE * CPN + if t == YEARS { FACE } else { 0.0 };
        let tf = t as f64;
        s[0] += a * df;
        s[1] -= tf * a * df * d;
        s[2] += ((t * (t + 1)) as f64) * a * df * d * d;
        s[3] -= ((t * (t + 1) * (t + 2)) as f64) * a * df * d * d * d;
    }
    s
}
fn p(y: f64) -> f64 { derivs(y)[0] }
fn fwd(f: &dyn Fn(f64) -> f64, y: f64, h: f64) -> f64 { (f(y + h) - f(y)) / h }
fn bwd(f: &dyn Fn(f64) -> f64, y: f64, h: f64) -> f64 { (f(y) - f(y - h)) / h }
fn ctr(f: &dyn Fn(f64) -> f64, y: f64, h: f64) -> f64 { (f(y + h) - f(y - h)) / (2.0 * h) }
fn fwd3(f: &dyn Fn(f64) -> f64, y: f64, h: f64) -> f64 {
    (-3.0 * f(y) + 4.0 * f(y + h) - f(y + 2.0 * h)) / (2.0 * h)
}
fn bwd3(f: &dyn Fn(f64) -> f64, y: f64, h: f64) -> f64 {
    (3.0 * f(y) - 4.0 * f(y - h) + f(y - 2.0 * h)) / (2.0 * h)
}
fn bp(x: f64) -> f64 { x * BP } // dollars per unit of yield -> dollars per bp

fn main() {
    let pf = |y: f64| p(y);
    let [p0, p1, p2, p3] = derivs(Y0);
    println!("price P(4.50%) = {:.6}; P(4.51%) = {:.6}; P(4.49%) = {:.6}; P(4.52%) = {:.6}; P(4.48%) = {:.6}",
        p0, p(Y0 + BP), p(Y0 - BP), p(Y0 + 2.0 * BP), p(Y0 - 2.0 * BP));
    println!("exact slope P' = {:.6} $/bp; P'' = {:.0}; P''' = {:.0}", bp(p1), p2, p3);
    let rules: [(&str, Rule, f64, i32); 5] = [("forward", fwd, p2 / 2.0, 1), ("backward", bwd, -p2 / 2.0, 1),
        ("central", ctr, p3 / 6.0, 2), ("one-sided 3-point up", fwd3, -p3 / 3.0, 2),
        ("one-sided 3-point down", bwd3, -p3 / 3.0, 2)];
    let mut ratio = Vec::new();
    for (name, rule, c, k) in rules.iter() {
        // c * h^k is the leading error Taylor predicts
        let est = rule(&pf, Y0, BP);
        let (err, pred) = (bp(est - p1), bp(c * BP.powi(*k)));
        ratio.push(err / pred);
        println!("{}: {:.6} $/bp; error {:+.6}; Taylor predicts {:+.6}; ratio {:.4}", name, est * BP, err, pred, err / pred);
    }
    println!("forward and backward averaged = {:.6} $/bp, central's value", bp(fwd(&pf, Y0, BP) + bwd(&pf, Y0, BP)) / 2.0);
    let steps = [64.0f64, 32.0, 16.0, 8.0, 4.0, 2.0, 1.0]; // steps in basis points
    let lgs: Vec<String> = steps.iter().map(|s| format!("{:.2}", s.log10())).collect();
    println!("chart steps h (bp): log10 h [{}]", lgs.join(", "));
    let errs: Vec<Vec<f64>> = rules.iter()
        .map(|(_, rule, _, _)| steps.iter().map(|s| bp(rule(&pf, Y0, s * BP) - p1).abs()).collect()).collect();
    for i in [0usize, 2, 3] {
        let e = &errs[i];
        let lg: Vec<String> = e.iter().map(|v| format!("{:.2}", v.log10())).collect();
        let hr: Vec<String> = (0..e.len() - 1).map(|j| format!("{:.3}", e[j] / e[j + 1])).collect();
        println!("chart {}: log10 error [{}]; halving ratios {}", rules[i].0, lg.join(", "), hr.join(", "));
    }
    println!("ladder: rungs 4.50% to 4.54%, one bp apart, each priced once");
    let lad: Vec<f64> = (0..5).map(|k| Y0 + (k as f64) * BP).collect();
    let pv: Vec<f64> = lad.iter().map(|&y| p(y)).collect();
    for (k, &y) in lad.iter().enumerate() {
        let exact = bp(derivs(y)[1]);
        let (two, three, how) = if k == 0 {
            ((pv[1] - pv[0]) / BP, (-3.0 * pv[0] + 4.0 * pv[1] - pv[2]) / (2.0 * BP), "up only")
        } else if k == 4 {
            ((pv[4] - pv[3]) / BP, (3.0 * pv[4] - 4.0 * pv[3] + pv[2]) / (2.0 * BP), "down only")
        } else {
            let c = (pv[k + 1] - pv[k - 1]) / (2.0 * BP);
            (c, c, "both sides")
        };
        println!("rung +{} bp ({}): exact {:.4}; two-point {:.4} err {:+.4}; best available {:.4} err {:+.4}",
            k, how, exact, bp(two), bp(two) - exact, bp(three), bp(three) - exact);
    }
    let uneven = (p(Y0 + BP) - p(Y0 - 2.0 * BP)) / (3.0 * BP); // up 1 bp, down 2 bp
    let half = (p(Y0 + BP) - p(Y0 - BP)) / BP; // forgot the 2 in 2h
    let yk = 0.04; // where P hits par
    let par = p(yk);
    let cap = move |y: f64| p(y).min(par); // callable at par, crude
    let p1k = derivs(yk)[1]; // smooth slope just above 4%
    let kink: Vec<(&str, f64, f64, f64)> = [("1", 1.0), ("0.01", 0.01)].iter()
        .map(|&(lab, s)| (lab, ctr(&cap, yk, s * BP), fwd(&cap, yk, s * BP), bwd(&cap, yk, s * BP))).collect();
    println!("breaks: uneven pair +1/-2 bp over 3h {:.6} err {:+.6}; central over h not 2h {:.4}",
        bp(uneven), bp(uneven - p1), bp(half));
    for (lab, c, f, b) in kink.iter() {
        println!("breaks: capped at par, y = 4.00%, h = {} bp: up {:.4}, down {:.4}, central {:.4}; uncapped slope {:.4}",
            lab, bp(*f), bp(*b), bp(*c), bp(p1k));
    }
    assert!((ratio[0] - 1.0).abs() < 0.01 && (ratio[1] - 1.0).abs() < 0.01); // first-order law
    assert!((ratio[2] - 1.0).abs() < 1e-3 && (ratio[3] - 1.0).abs() < 0.01);
    let (f, c) = (&errs[0], &errs[2]);
    assert!(1.9 < f[5] / f[6] && f[5] / f[6] < 2.1); // halve h, halve error
    assert!(3.9 < c[5] / c[6] && c[5] / c[6] < 4.1); // halve h, quarter error
    assert!(bp(uneven - p1).abs() > 100.0 * bp(ctr(&pf, Y0, BP) - p1).abs()); // uneven pair is first order
    assert!((kink[1].1 - p1k).abs() > 0.4 * p1k.abs()); // kink: no shrinking with h
    println!("ALL CHECKS PASS");
}
