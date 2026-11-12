// Brent's method -- the check behind the card.  std only, no crates.
// A kiln's steel shell (6 m2, emissivity 0.85) sheds heat to 20 C air by
// radiation and convection (h = 8 W/m2K).  A gas meter says the loss is
// 12,000 W (illustrative).  Which shell temperature t, in C, explains it?
// Roads: bisection to the last bit; Brent; Dekker; a factorised residual.
const SIG: f64 = 5.670374419e-8; const AREA: f64 = 6.0; const EMIS: f64 = 0.85;
const HC: f64 = 8.0; const TA: f64 = 293.15;

fn kiln(t: f64, loss: f64) -> f64 {
    let tk = t + 273.15;
    AREA * (EMIS * SIG * (tk * tk * tk * tk - TA * TA * TA * TA) + HC * (tk - TA)) - loss
}
fn kiln_factored(t: f64, loss: f64) -> f64 {
    let tk = t + 273.15;
    AREA * (tk - TA) * (EMIS * SIG * (tk * tk + TA * TA) * (tk + TA) + HC) - loss
}
fn x9(x: f64) -> f64 { x * x * x * x * x * x * x * x * x }

fn iqi(a: f64, b: f64, c: f64, fa: f64, fb: f64, fc: f64) -> f64 {
    a * fb * fc / ((fa - fb) * (fa - fc)) + b * fa * fc / ((fb - fa) * (fb - fc))
        + c * fa * fb / ((fc - fa) * (fc - fb))
}

// Python-style e-notation: 1.234e-06
fn sci(x: f64, d: usize) -> String {
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

struct Step { kind: &'static str, x: f64, fx: f64, w: f64 }

fn solve(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, delta: f64, mode: &str) -> (Option<f64>, usize, Vec<Step>) {
    let (fl, fh) = (f(lo), f(hi));
    if (fl < 0.0) == (fh < 0.0) { return (None, 2, vec![]); }
    let (mut b, mut fb, mut c, mut fc) = (hi, fh, lo, fl);
    if fc.abs() < fb.abs() { std::mem::swap(&mut b, &mut c); std::mem::swap(&mut fb, &mut fc); }
    let (mut a, mut fa, mut n, mut lg) = (c, fc, 2usize, Vec::new());
    let (mut s1, mut s2) = ((c - b).abs(), (c - b).abs());
    while (c - b).abs() / 2.0 > delta && fb != 0.0 {
        let m = (b + c) / 2.0;
        let (p, mut kind) = if (mode == "brent" || mode == "notest") && a != c && fa != fb && fa != fc && fb != fc {
            (iqi(a, b, c, fa, fb, fc), "IQI")
        } else if fa != fb { (b - fb * (b - a) / (fb - fa), "secant") } else { (m, "no chord") }; // a = b: halve
        let st = (p - b).abs();
        let ok = if mode == "dekker" { (p - b) * (c - b) > 0.0 && st < (m - b).abs() }
                 else { (p - b) * (c - b) > 0.0 && st < 0.75 * (c - b).abs()
                        && (mode == "notest" || st.max(delta) < s2 / 2.0) };
        let new;
        if mode == "bisect" || !(ok || kind == "no chord") { new = m; kind = "halve"; }
        else if st < delta { new = b + if c > b { delta } else { -delta }; kind = "nudge"; }
        else { new = p; }
        s2 = s1; s1 = (new - b).abs();
        let fnew = f(new); n += 1;
        a = b; fa = fb;
        if (fnew < 0.0) == (fc < 0.0) { c = b; fc = fb; }
        b = new; fb = fnew;
        if fc.abs() < fb.abs() { std::mem::swap(&mut b, &mut c); std::mem::swap(&mut fb, &mut fc); }
        lg.push(Step { kind, x: new, fx: fnew, w: (c - b).abs() });
    }
    (Some(b), n, lg)
}

fn promise(w: f64, delta: f64) -> i32 {
    let mut k = 0;
    while w / 2f64.powi(k) > 2.0 * delta { k += 1; }
    k
}

fn main() {
    let loss = 12000.0;
    let kf = |t: f64| kiln(t, loss);
    let (mut lo, mut hi) = (20.0f64, 520.0f64);
    loop {
        let m = (lo + hi) / 2.0;
        if m == lo || m == hi { break; }
        if kf(m) < 0.0 { lo = m } else { hi = m }
    }
    let r = if kf(lo).abs() <= kf(hi).abs() { lo } else { hi };
    let tk = r + 273.15;
    let d1 = AREA * (4.0 * EMIS * SIG * tk * tk * tk + HC);
    let (d2, d3) = (AREA * 12.0 * EMIS * SIG * tk * tk, AREA * 24.0 * EMIS * SIG * tk);
    let cc = (3.0 * d2 * d2 - d1 * d3) / (6.0 * d1 * d1);
    let (dl, k) = (1e-6, promise(500.0, 1e-6)); let kb = ((k + 1) * (k + 2)) as usize;
    println!("reference root t* (C)          {:.12}", r);
    println!("slope f'(t*) (W per C)         {:.6}", d1);
    println!("f(20) and f(520) (W)           {:.3} {:.3}", kf(20.0), kf(520.0));
    println!("delta {} C; promise k = {}; bound (k+1)(k+2) = {}", sci(dl, 0), k, kb);
    let mut res = Vec::new();
    for mode in ["bisect", "dekker", "brent"] {
        let (x, n, lg) = solve(&kf, 20.0, 520.0, dl, mode);
        let x = x.unwrap();
        println!("{:<7} evaluations {:>3}  t = {:.9}  true error {}", mode, n, x, sci(x - r, 3));
        res.push((x, n, lg));
    }
    println!("Brent on the kiln: step, kind, t, f(t) in W, bracket width");
    for (i, s) in res[2].2.iter().enumerate() {
        println!("  {}  {:<6} {:16.9} {:13.6} {}", i + 1, s.kind, s.x, s.fx, sci(s.w, 3));
    }
    let xb = res[2].0;
    println!("factorised residual at Brent's t  {} W; bound f' x 2 delta {}",
             sci(kiln_factored(xb, loss), 3), sci(d1 * 2.0 * dl, 3));
    println!("error bound 2 delta over Brent's true error  {:.1}", 2.0 * dl / (xb - r).abs());
    for (lab, i) in [("bisect", 0usize), ("brent ", 2)] {
        let v: Vec<String> = (0..7).map(|j| format!("{:.2}", res[i].2[j].w.log10())).collect();
        println!("chart, log10 bracket width, evals 3-9, {} {}", lab, v.join(" "));
    }
    let mut xs = vec![20.0, 520.0, 270.0];
    for _ in 0..6 {
        let l = xs.len();
        let (a, b, c) = (xs[l - 3], xs[l - 2], xs[l - 1]);
        xs.push(iqi(a, b, c, kf(a), kf(b), kf(c)));
    }
    let e: Vec<f64> = xs.iter().map(|v| v - r).collect();
    println!("pure IQI from 20, 520, 270; predicted C = (3f''^2 - f'f''')/(6f'^2) = {}", sci(cc, 4));
    for i in 3..9 {
        let ratio = e[i] / (e[i - 1] * e[i - 2] * e[i - 3]);
        let order = (e[i] / e[i - 1]).abs().ln() / (e[i - 1] / e[i - 2]).abs().ln();
        println!("  x{}  error {:>10}  e/(e e e) {:>10}  order {:.4}", i, sci(e[i], 3), sci(ratio, 3), order);
    }
    let (mut pl, mut ph) = (1.0f64, 2.0f64);
    for _ in 0..60 {
        let pm = (pl + ph) / 2.0;
        if pm * pm * pm - pm * pm - pm - 1.0 < 0.0 { pl = pm } else { ph = pm }
    }
    let mut dg = vec![1.0f64, 2.0, 3.0];
    for _ in 0..40 { let l = dg.len(); dg.push(dg[l - 1] + dg[l - 2] + dg[l - 3]); }
    let dr = dg[dg.len() - 1] / dg[dg.len() - 2];
    println!("order of IQI: root of p^3=p^2+p+1 {:.6}; digit law ratio {:.6}", pl, dr);
    let k9 = promise(2.3, dl); let k9b = ((k9 + 1) * (k9 + 2)) as usize;
    println!("x^9 on [-1, 1.3]: promise k = {}; bound (k+1)(k+2) = {}", k9, k9b);
    let mut cnt = std::collections::HashMap::new();
    for mode in ["bisect", "dekker", "brent", "notest"] {
        let (x, n, lg) = solve(&x9, -1.0, 1.3, dl, mode);
        cnt.insert(mode, n);
        let (h, nc) = (lg.iter().filter(|s| s.kind == "halve").count(), lg.iter().filter(|s| s.kind == "no chord").count());
        println!("  {:<7} evaluations {:>3}  answer {}  halvings {}, {} of them with no chord", mode, n, sci(x.unwrap(), 3), h + nc, nc);
    }
    let dk = solve(&x9, -1.0, 1.3, dl, "dekker").2;
    let v: Vec<String> = [25usize, 50, 100, 140].iter().map(|&j| format!("{:.3}", dk[j - 1].w)).collect();
    println!("  Dekker bracket width after 25, 50, 100, 140 steps {}", v.join(" "));
    let mut sx = vec![-1.0f64, 1.3];
    while sx[sx.len() - 1].abs() > dl {
        let (p, q) = (sx[sx.len() - 2], sx[sx.len() - 1]);
        sx.push(q - x9(q) * (q - p) / (x9(q) - x9(p)));
    }
    println!("  plain secant: {} evaluations to reach |x| <= 1e-06", sx.len());
    let bad = solve(&kf, 150.0, 520.0, dl, "brent");
    println!("break: bracket [150, 520], f(150) = {:.3} W: answer {}", kf(150.0),
             match bad.0 { None => "None".to_string(), Some(v) => format!("{}", v) });
    for l2 in [6000.0, 24000.0] {
        let (x, n, _) = solve(&|t| kiln(t, l2), 20.0, 520.0, dl, "brent");
        println!("try: loss {:.0} W -> t = {:.6} C in {} evaluations", l2, x.unwrap(), n);
    }
    for dd in [1e-3, 1e-9] {
        println!("try: delta {} -> bisection {}, Brent {}", sci(dd, 0),
                 solve(&kf, 20.0, 520.0, dd, "bisect").1, solve(&kf, 20.0, 520.0, dd, "brent").1);
    }
    assert!((res[0].0 - r).abs() <= dl && (res[2].0 - r).abs() <= 2.0 * dl);
    assert!((res[1].0 - r).abs() <= 2.0 * dl, "Dekker must land inside 2 delta");
    assert!(res[0].1 == (k + 2) as usize, "bisection keeps its promise");
    assert!(kiln_factored(xb, loss).abs() <= 1.01 * d1 * 2.0 * dl, "residual road agrees");
    assert!(res[2].1 <= kb && cnt["brent"] <= k9b);
    assert!(cnt["dekker"].min(cnt["notest"]) > 4 * cnt["brent"], "the halving test must cure the slow case");
    assert!((e[7] / (e[6] * e[5] * e[4]) / cc - 1.0).abs() < 0.02, "IQI error law");
    assert!((pl - dr).abs() < 1e-9, "two roads to the order 1.839");
    assert!(bad.0.is_none(), "no sign change must be refused");
    println!("ALL CHECKS PASS");
}
