// Futures margining and the forward-futures difference -- the same check as the
// Python, in Rust.  No crates.  Nothing is called that already holds an answer:
// the quote tree, the margin ledger, the bisection search and the hyperbolic
// tangent are written out here.  Acme: spot 100.00, bank 5 percent a year
// continuously compounded, dividend yield 2 percent, one year, settled at six
// months and at expiry.  The futures quote jumps 10.00 at every settlement.
const S0: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const T: f64 = 1.0; const DT: f64 = 0.5; const MOVE: f64 = 10.0; const DAYS: usize = 252;
const PATHS: [(&str, [i32; 2]); 4] = [("up, up", [1, 1]), ("up, down", [1, -1]),
                                      ("down, up", [-1, 1]), ("down, down", [-1, -1])];
const TILTS: [f64; 3] = [0.0, 0.03, -0.03];

fn f0() -> f64 { S0 * ((R - Q) * T).exp() }          // cash and carry: where the quote tree starts

fn quotes(path: &[i32; 2]) -> [f64; 3] {             // the futures quote after each settlement
    let (mut out, mut acc) = ([f0(); 3], 0.0);
    for i in 0..2 { acc += path[i] as f64; out[i + 1] = f0() + MOVE * acc; }
    out
}

fn bank(path: &[i32; 2], tilt: f64) -> [f64; 2] {    // growth per half year; tilt ties rates to the quote
    [(R * DT).exp(), ((R + tilt * path[0] as f64) * DT).exp()]
}

fn ledger(path: &[i32; 2], sizes: &[f64; 2], tilt: f64) -> f64 {   // road 1: carry the balance forward
    let (f, b) = (quotes(path), bank(path, tilt));
    let mut v = 0.0;
    for i in 0..2 { v = v * b[i] + sizes[i] * (f[i + 1] - f[i]); }
    v
}

fn bank_units(path: &[i32; 2], sizes: &[f64; 2], tilt: f64) -> f64 {  // road 2: hold it in bank units
    let (f, b) = (quotes(path), bank(path, tilt));
    let (mut units, mut level) = (0.0, 1.0);         // level is the bank account at the settlement date
    for i in 0..2 { level *= b[i]; units += sizes[i] * (f[i + 1] - f[i]) / level; }
    units * level
}

fn tail(path: &[i32; 2], tilt: f64) -> [f64; 2] { [1.0 / bank(path, tilt)[1], 1.0] }

fn prices(tilt: f64) -> (f64, f64, f64) {            // four equally likely paths: plain and weighted
    let (mut plain, mut weighted, mut bond) = (0.0, 0.0, 0.0);
    for (_, path) in PATHS.iter() {
        let (f, b) = (quotes(path), bank(path, tilt));
        let d = 1.0 / (b[0] * b[1]);                 // today's worth of a dollar paid at expiry
        plain += 0.25 * f[2]; weighted += 0.25 * f[2] * d; bond += 0.25 * d;
    }
    (plain, weighted / bond, weighted * (Q * T).exp())
}

fn forward_by_search(tilt: f64) -> f64 {             // road 2 to the forward: worth nothing today
    let value = |k: f64| -> f64 {
        let mut v = 0.0;
        for (_, p) in PATHS.iter() { v += 0.25 * (quotes(p)[2] - k) / (bank(p, tilt)[0] * bank(p, tilt)[1]); }
        v
    };
    let (mut lo, mut hi) = (50.0, 200.0);
    for _ in 0..200 { let mid = 0.5 * (lo + hi); if value(mid) > 0.0 { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}

fn futures_backward() -> f64 {                       // road 2 to the futures price: average backwards
    let mut level = vec![f0() + 2.0 * MOVE, f0(), f0() - 2.0 * MOVE];
    while level.len() > 1 { level = (0..level.len() - 1).map(|i| 0.5 * (level[i] + level[i + 1])).collect(); }
    level[0]
}

fn tanh(x: f64) -> f64 { (x.exp() - (-x).exp()) / (x.exp() + (-x).exp()) }   // written out, not called in
fn tidy(x: f64) -> f64 { if x.abs() < 1e-9 { 0.0 } else { x } }             // a clean zero for a billionth

fn daily(tailed: bool) -> (f64, Vec<f64>) {          // 252 settlements: quote up 10.00, then back down
    let g = (R / DAYS as f64).exp();
    let (mut v, mut marks) = (0.0, vec![0.0]);
    for day in 1..=DAYS {
        let step = MOVE / (DAYS / 2) as f64 * if day <= DAYS / 2 { 1.0 } else { -1.0 };
        v = v * g + step * if tailed { (-R * (T - day as f64 / DAYS as f64)).exp() } else { 1.0 };
        if day % 63 == 0 { marks.push(v) }
    }
    (v, marks)
}

fn row(label: &str, value: f64) { println!("{:<46}{:>14.6}", label, value); }

fn join(values: &[f64], places: usize) -> String {
    values.iter().map(|v| if places == 2 { format!("{:.2}", v) } else { format!("{:6.0}", v) })
        .collect::<Vec<String>>().join(" ")
}

fn table(title: String, tailed: bool) {
    println!("{}", title);
    println!("{:<18}{:>14}{:>14}{:>14}{:>14}", "path", "final quote", "futures cash", "forward pay", "difference");
    for (name, path) in PATHS.iter() {
        let sizes = if tailed { tail(path, 0.0) } else { [1.0, 1.0] };
        let (f, v) = (quotes(path), ledger(path, &sizes, 0.0));
        println!("{:<18}{:>14.6}{:>14.6}{:>14.6}{:>14.6}", name, f[2], v, f[2] - f0(), tidy(v - (f[2] - f0())));
    }
}

fn main() {
    println!("Acme spot {:.2}, bank {:.0} percent, dividend yield {:.0} percent, one year", S0, R * 100.0, Q * 100.0);
    row("futures quote today, S e^(r-q)T", f0());
    row("half-year bank growth factor, flat rates", bank(&[1, 1], 0.0)[1]);
    row("today's worth of a dollar at expiry, flat bank", 1.0 / ((R * DT).exp() * bank(&[1, 1], 0.0)[1]));
    println!("quote tree: {:.6} -> {:.6} or {:.6}", f0(), f0() + MOVE, f0() - MOVE);
    println!("         -> {:.6}, {:.6} or {:.6}", f0() + 2.0 * MOVE, f0(), f0() - 2.0 * MOVE);
    println!();
    table("one contract held throughout, flat rates".to_string(), false);
    let mut widest: f64 = 0.0;
    for t in TILTS.iter() { for (_, p) in PATHS.iter() {
        widest = widest.max((ledger(p, &[1.0, 1.0], *t) - bank_units(p, &[1.0, 1.0], *t)).abs()); } }
    row("widest gap between the two ledger roads, 12 cases", tidy(widest));
    println!();
    table(format!("tailed sizes {:.6} then 1.000000, flat rates", tail(&[1, 1], 0.0)[0]), true);
    println!("a settlement of {:.2} at six months grows to {:.6} by expiry; tailed, {:.6} grows to {:.6}",
             MOVE, MOVE * bank(&[1, 1], 0.0)[1], tail(&[1, 1], 0.0)[0] * MOVE,
             tail(&[1, 1], 0.0)[0] * MOVE * bank(&[1, 1], 0.0)[1]);
    println!("tail needed once the bank tilts: {:.6} after a rise, {:.6} after a fall",
             (-0.08 * DT).exp(), (-0.02 * DT).exp());
    println!();
    let (one_day, marks) = daily(false);
    println!("daily settlement, {} steps, quote up {:.2} then back down", DAYS, MOVE);
    row("one contract, cash at expiry", one_day);
    row("tailed sizes, cash at expiry", tidy(daily(true).0));
    println!("margin balance at months 0, 3, 6, 9, 12: {}", join(&marks, 2));
    println!();
    println!("futures price and forward price, three banks");
    println!("{:<30}{:>13}{:>13}{:>13}{:>13}", "bank", "futures", "forward", "gap", "Acme spot");
    for (label, tilt) in [("flat at 5 percent", 0.0), ("up with Acme, 8 or 2", 0.03),
                          ("down with Acme, 2 or 8", -0.03)] {
        let (fut, fwd, spot) = prices(tilt);
        println!("{:<30}{:>13.6}{:>13.6}{:>13.6}{:>13.6}", label, fut, fwd, tidy(fut - fwd), spot);
    }
    row("gap by the closed form, MOVE tanh(tilt DT)", MOVE * tanh(0.03 * DT));
    println!("try: a quote moving 20.00 a settlement -> cash {:.6}, gap {:.6}",
             2.0 * MOVE * ((R * DT).exp() - 1.0), 2.0 * MOVE * tanh(0.03 * DT));
    println!();
    let by_rate: Vec<f64> = [0.0, 0.02, 0.05, 0.08].iter().map(|x| MOVE * ((x * DT).exp() - 1.0)).collect();
    println!("bars, gap on path up-down by bank rate:   {}", join(&by_rate, 2));
    let by_tilt: Vec<f64> = [0.0, 0.01, 0.03, 0.06].iter().map(|x| MOVE * tanh(x * DT)).collect();
    println!("bars, price gap by rate tilt:             {}", join(&by_tilt, 2));
    let grid = [-0.06, -0.04, -0.02, 0.0, 0.02, 0.04, 0.06];
    println!("chart, rate tilt in points:               {}",
             join(&grid.iter().map(|x| x * 100.0).collect::<Vec<f64>>(), 0));
    println!("chart, futures price:                     {}",
             join(&grid.iter().map(|x| prices(*x).0).collect::<Vec<f64>>(), 2));
    println!("chart, forward price:                     {}",
             join(&grid.iter().map(|x| prices(*x).1).collect::<Vec<f64>>(), 2));
    println!();
    println!("what breaks");
    let ud = quotes(&[1, -1]);
    row("settlements added with no interest", tidy((ud[1] - ud[0]) + (ud[2] - ud[1])));
    row("one contract where a forward was wanted", ledger(&[1, -1], &[1.0, 1.0], 0.0));
    row("tail taken from today, not from the date", ledger(&[1, -1], &[(-R * T).exp(), 1.0], 0.0));
    row("futures quoted at the forward, rates up", prices(0.03).0 - prices(0.03).1);
    for t in TILTS.iter() { for (_, p) in PATHS.iter() {            // two ledger roads, then tailing
        assert!((ledger(p, &[1.0, 1.0], *t) - bank_units(p, &[1.0, 1.0], *t)).abs() < 1e-12);
        assert!((ledger(p, &tail(p, *t), *t) - (quotes(p)[2] - f0())).abs() < 1e-12); } }
    assert!(ledger(&[-1, 1], &tail(&[1, 1], 0.03), 0.03).abs() > 0.2);  // one size cannot serve both
    assert!(daily(true).0.abs() < 1e-12);                           // the same tail, 252 settlements
    assert!((futures_backward() - prices(0.0).0).abs() < 1e-12);    // backwards tree vs the path average
    for t in TILTS.iter() { assert!((forward_by_search(*t) - prices(*t).1).abs() < 1e-9); }
    assert!((prices(0.0).1 - S0 * ((R - Q) * T).exp()).abs() < 1e-12);  // flat: forward = cash and carry
    assert!((prices(0.0).2 - S0).abs() < 1e-9);                         // Acme's spot comes back at 100.00
    for t in [0.03, -0.03] { assert!(((prices(t).0 - prices(t).1) - MOVE * tanh(t * DT)).abs() < 1e-12); }
    assert!(prices(0.03).0 > prices(0.03).1 && prices(-0.03).0 < prices(-0.03).1);
    println!("ALL CHECKS PASS");
}
