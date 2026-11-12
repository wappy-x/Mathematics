// Bisection and bracketing -- the check behind the card.  std only, no crates.
// A $300,000 loan is repaid by 300 monthly payments of $1,800 (illustrative).
// Which yearly rate r, compounded monthly, makes the payments worth the loan?
// Road 1 halves a bracket.  Road 2 is the secant step, which keeps no bracket.
// Road 3 turns each rate back into a payment by the closed annuity formula.
// Then the floor of neighbouring doubles, the outward search, and four breaks.
const LOAN: f64 = 300000.0;
const MONTHS: usize = 300;

fn gap_at(r: f64, pay: f64) -> f64 { // value today of the payments, minus the loan
    let (v, mut d, mut s) = (1.0 / (1.0 + r / 12.0), 1.0, 0.0);
    for _ in 0..MONTHS {
        d *= v;
        s += d;
    }
    pay * s - LOAN
}
fn gap(r: f64) -> f64 { gap_at(r, 1800.0) }

fn payment(r: f64) -> f64 { // road 3: closed form, L i (1+i)^N / ((1+i)^N - 1)
    let (i, mut p) = (r / 12.0, 1.0);
    for _ in 0..MONTHS { p *= 1.0 + i; }
    LOAN * i * p / (p - 1.0)
}

struct Run { m: f64, k: i32, why: &'static str, seen: Vec<f64>, a: f64, b: f64 }

fn bisect(g: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64, t_abs: f64, t_rel: f64, show: bool) -> Run {
    let (mut ga, mut k, mut seen) = (g(a), 0, vec![(a + b) / 2.0]);
    loop {
        let m = (a + b) / 2.0;
        if (b - a) / 2.0 <= t_abs + t_rel * m.abs() { return Run { m, k, why: "test", seen, a, b }; }
        if m == a || m == b { return Run { m, k, why: "floor", seen, a, b }; }
        let gm = g(m);
        if gm == 0.0 { return Run { m, k, why: "zero", seen, a, b }; }
        if (gm > 0.0) == (ga > 0.0) { a = m; ga = gm; } else { b = m; }
        k += 1;
        seen.push((a + b) / 2.0);
        if show && k <= 4 {
            println!("halving {}: m = {:.4}%, gap {:.2}, keep [{:.4}%, {:.4}%]", k, 100.0 * m, gm, 100.0 * a, 100.0 * b);
        }
        if k == 3000 { return Run { m, k, why: "cap", seen, a, b }; }
    }
}

fn steps_needed(a: f64, b: f64, tol: f64) -> i32 { // smallest k with (b - a) / 2^(k+1) <= tol
    let mut k = 0;
    while (b - a) / 2f64.powi(k + 1) > tol { k += 1; }
    k
}

fn find_bracket(g: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> (f64, f64, i32) {
    let (mut ga, mut gb, mut n) = (g(a), g(b), 0); // step outward, doubling the width
    while (ga > 0.0) == (gb > 0.0) && n < 40 {
        let w = b - a;
        if ga.abs() < gb.abs() { b = a; gb = ga; a -= 2.0 * w; ga = g(a); }
        else { a = b; ga = gb; b += 2.0 * w; gb = g(b); }
        n += 1;
    }
    (a, b, n)
}

fn secant(g: &dyn Fn(f64) -> f64, mut x0: f64, mut x1: f64) -> f64 { // road 2: the chord
    let (mut g0, mut g1) = (g(x0), g(x1));
    for _ in 0..50 {
        if g1 == g0 { break; }
        let x2 = x1 - g1 * (x1 - x0) / (g1 - g0);
        x0 = x1; x1 = x2; g0 = g1;
        g1 = g(x1);
    }
    x1
}

fn next_double(x: f64) -> f64 { f64::from_bits(x.to_bits() + 1) } // x > 0, from its bits

fn e(x: f64, p: usize) -> String { // Python's e-notation: two-digit exponent with a sign
    let s = format!("{:.*e}", p, x);
    let (m, ex) = s.split_once('e').unwrap();
    let n: i32 = ex.parse().unwrap();
    format!("{}e{}{:02}", m, if n < 0 { '-' } else { '+' }, n.abs())
}

fn main() {
    let (a0, b0, t_abs, t_rel) = (0.01, 0.15, 1e-6, 1e-5);
    println!("ends: gap(1%) = {:.2}, gap(15%) = {:.2}", gap(a0), gap(b0));
    let tol_floor = t_abs + t_rel * a0; // |m| >= 1% inside this bracket, so this tol is the least
    let k_pred = steps_needed(a0, b0, tol_floor);
    let q = (b0 - a0) / (2.0 * tol_floor);
    println!("promised: {} halvings, least tolerance {}, log2 of {:.1} = {:.3}", k_pred, e(tol_floor, 3), q, q.log2());
    let r1 = bisect(&gap, a0, b0, t_abs, t_rel, true);
    let bound = (r1.b - r1.a) / 2.0;
    println!("road 1: {} halvings, stopped by {}, rate {:.6}%, bound {}", r1.k, r1.why, 100.0 * r1.m, e(bound, 3));
    let r2 = secant(&gap, 0.05, 0.06);
    println!("road 2, secant from 5% and 6%: rate {:.10}%", 100.0 * r2);
    let true1 = (r1.m - r2).abs();
    println!("true error {}, bound / true = {:.1}", e(true1, 3), bound / true1);
    println!("road 3, payment at road 1: {:.4}, at road 2: {:.4}", payment(r1.m), payment(r2));
    println!("cost: 2 end values + {} midpoints = {} evaluations of 300 terms", r1.k, 2 + r1.k);
    let (fa, fb, nb) = find_bracket(&gap, 0.01, 0.02);
    println!("outward from [1%, 2%]: [{:.0}%, {:.0}%] after {} widenings", 100.0 * fa, 100.0 * fb, nb);
    let fl = bisect(&gap, a0, b0, 0.0, 0.0, false);
    println!("floor: {} halvings, stopped by {}, width {}, log2(0.14 / width) = {:.2}", fl.k, fl.why, e(fl.b - fl.a, 3), ((b0 - a0) / (fl.b - fl.a)).log2());
    let nbr = next_double(fl.a) == fl.b;
    println!("floor ends are neighbours: {}; floor minus road 2 = {}", if nbr { "yes" } else { "no" }, e(fl.m - r2, 3));
    let ks: Vec<i32> = (0..41).step_by(4).collect();
    println!("chart, k: {}", ks.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, log10 bound: {}", ks.iter().map(|&k| format!("{:.2}", ((b0 - a0) / 2f64.powi(k + 1)).log10())).collect::<Vec<_>>().join(" "));
    println!("chart, log10 true error: {}", ks.iter().map(|&k| format!("{:.2}", (fl.seen[k as usize] - r2).abs().log10())).collect::<Vec<_>>().join(" "));
    let px = |r: f64| 30.0 + (r - 0.01) / 0.14 * 300.0;
    let mut br = vec![(0.01, 0.15)];
    for &m in &fl.seen[..4] {
        let (lo, hi) = *br.last().unwrap();
        br.push(if gap(m) > 0.0 { (m, hi) } else { (lo, m) });
    }
    println!("figure, brackets in %: {}", br.iter().map(|(lo, hi)| format!("[{:.4},{:.4}]", 100.0 * lo, 100.0 * hi)).collect::<Vec<_>>().join(" "));
    println!("figure, x pixels: {} root {:.1}", br.iter().map(|&(lo, hi)| format!("{:.1}-{:.1}", px(lo), px(hi))).collect::<Vec<_>>().join(" "), px(r2));
    // ---- what breaks ----
    let lo9 = |r: f64| gap_at(r, 900.0);
    let r9 = bisect(&lo9, a0, b0, t_abs, t_rel, false).m;
    let (a9, b9, n9) = find_bracket(&lo9, a0, b0);
    let s9 = bisect(&lo9, a9, b9, t_abs, t_rel, false).m;
    println!("$900 a month: gap(1%) {:.2}, gap(15%) {:.2}; blind halving says {:.4}%", lo9(a0), lo9(b0), 100.0 * r9);
    println!("  outward search: [{:.0}%, {:.0}%] after {}; rate {:.4}%", 100.0 * a9, 100.0 * b9, n9, 100.0 * s9);
    let pole = |r: f64| 1.0 / (r - 0.07);
    let rp = bisect(&pole, a0, b0, t_abs, t_rel, false).m;
    println!("jump at 7%: closes on {:.6}%, where the function is {}", 100.0 * rp, e(pole(rp), 4));
    let ra = bisect(&gap, a0, b0, 1e-20, 0.0, false);
    println!("t_abs = 1e-20 alone: {} halvings, stopped by {}, never by the test", ra.k, ra.why);
    let free = |r: f64| gap_at(r, 1000.0);
    let rz = bisect(&free, -0.02, b0, 0.0, t_rel, false);
    let rm = bisect(&free, -0.02, b0, t_abs, t_rel, false);
    println!("$1000 a month, true rate 0: t_rel alone {} halvings, stopped by {} at {}", rz.k, rz.why, e(rz.m, 3));
    println!("  mixed test: {} halvings, stopped by {} at {}", rm.k, rm.why, e(rm.m, 3));
    // ---- try changing ----
    println!("try: t_abs 1e-8 and t_rel 1e-7 need {} halvings", steps_needed(a0, b0, 1e-8 + 1e-7 * a0));
    println!("try: bracket [0%, 100%] needs {} halvings", steps_needed(0.0, 1.0, t_abs));
    let r20 = bisect(&|r: f64| gap_at(r, 2000.0), a0, b0, t_abs, t_rel, false);
    println!("try: $2,000 a month gives {:.4}% in {} halvings", 100.0 * r20.m, r20.k);
    assert!(r1.k == k_pred && r1.why == "test"); // the promise, kept to the step
    assert!(true1 <= bound); // bisection meets secant within its bound
    assert!((payment(r2) - 1800.0).abs() < 1e-6); // closed form turns the rate back into $1,800
    assert!(nbr && (fl.m - r2).abs() < 1e-13); // floor: neighbouring doubles, near road 2
    assert!(gap(fa) > 0.0 && 0.0 > gap(fb) && lo9(a9) > 0.0 && 0.0 > lo9(b9)); // a real bracket
    assert!((s9 - secant(&lo9, -0.01, -0.005)).abs() < bound); // the negative rate, by secant too
    assert!(ra.why == "floor" && rz.why != "test" && rm.why == "test");
    println!("ALL CHECKS PASS");
}
