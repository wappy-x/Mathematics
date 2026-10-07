// Swap DV01 and hedging -- the same check as swap_dv01_and_hedging_check.py, in Rust.
// Standard library only, no crates.  The bootstrap, the swap pricer, the bump
// and the exact slope are all written out here.
// Compile: rustc --edition 2021 -O swap_dv01_and_hedging_check.rs -o /tmp/swap_dv01_check

const QUOTES: [f64; 10] = [0.042, 0.044, 0.0455, 0.0462, 0.0465,   // the house curve, years 1 to 5
                           0.0467, 0.0468, 0.0469, 0.0470, 0.0471]; // years 6 to 10, extended at its last forward
const N: f64 = 10_000_000.0;
const K: f64 = 0.045;
const BP: f64 = 0.0001;

fn boot(q: &[f64]) -> Vec<f64> {                       // D(n) = (1 - S_n * sum of earlier D) / (1 + S_n)
    let mut d = Vec::new();
    let mut b = 0.0;
    for &s in q { let x = (1.0 - s * b) / (1.0 + s); d.push(x); b += x; }
    d
}

fn boot_slope(q: &[f64]) -> Vec<f64> {                 // the recursion's derivative when every quote moves together
    let (mut b, mut db, mut out) = (0.0, 0.0, Vec::new());
    for &s in q {
        let x = (1.0 - s * b) / (1.0 + s);
        let dx = (-(b + s * db) * (1.0 + s) - (1.0 - s * b)) / ((1.0 + s) * (1.0 + s));
        out.push(dx); b += x; db += dx;
    }
    out
}

fn payer(d: &[f64], k: f64, n: usize, notional: f64) -> f64 {   // receive floating as a strip of forwards, pay k
    let (mut prev, mut flt, mut fix) = (1.0, 0.0, 0.0);
    for i in 0..n {
        flt += (prev / d[i] - 1.0) * d[i];
        fix += k * d[i];
        prev = d[i];
    }
    notional * (flt - fix)
}

fn value(q: &[f64], k: f64, n: usize, notional: f64, shift: f64) -> f64 {
    let moved: Vec<f64> = q.iter().map(|x| x + shift).collect();
    payer(&boot(&moved), k, n, notional)
}

fn dv01(q: &[f64], k: f64, n: usize, notional: f64, h: f64) -> f64 {
    (value(q, k, n, notional, h) - value(q, k, n, notional, -h)) / (2.0 * h) * BP
}

fn money(x: f64) -> String {                           // 1234567.891 -> "1,234,567.89"
    let s = format!("{:.2}", x);
    let (sign, body) = if s.starts_with('-') { ("-", &s[1..]) } else { ("", &s[..]) };
    let (int, frac) = body.split_at(body.find('.').unwrap());
    let mut out = String::new();
    for (i, c) in int.chars().enumerate() {
        if i > 0 && (int.len() - i) % 3 == 0 { out.push(','); }
        out.push(c);
    }
    format!("{}{}{}", sign, out, frac)
}

fn book(shifts: &[f64], hedge: f64, v5: f64, par10: f64) -> (f64, f64) {
    let q: Vec<f64> = QUOTES.iter().zip(shifts).map(|(x, s)| x + s).collect();
    let p5 = payer(&boot(&q), K, 5, N) - v5;
    let p10 = -(payer(&boot(&q), par10, 10, hedge) - payer(&boot(&QUOTES), par10, 10, hedge));
    (p5, p10)
}

fn main() {
    let d = boot(&QUOTES);
    let a5: f64 = d[..5].iter().sum();
    let a10: f64 = d.iter().sum();
    let (par5, par10) = ((1.0 - d[4]) / a5, (1.0 - d[9]) / a10);
    println!("the house curve: par quotes with annual coupons, bootstrapped");
    for i in 0..10 { println!("  year {:>2}   quote {:6.4} %   D = {:.8}", i + 1, 100.0 * QUOTES[i], d[i]); }
    println!("5-year annuity A5 {:>22.6}    par rate {:.4} %", a5, 100.0 * par5);
    println!("10-year annuity A10 {:>20.6}    par rate {:.4} %", a10, 100.0 * par10);

    let v5 = payer(&d, K, 5, N);
    let flt_strip = v5 + N * K * a5;
    println!("\nthe 5-year swap: pay 4.5% fixed on 10,000,000, receive floating");
    println!("  floating leg, strip of forwards {:>16}", money(flt_strip));
    println!("  floating leg, N (1 - D(5))      {:>16}", money(N * (1.0 - d[4])));
    println!("  fixed leg, N K A5               {:>16}", money(N * K * a5));
    println!("  value to the payer              {:>16}", money(v5));

    let dv_bump = dv01(&QUOTES, K, 5, N, BP);
    let dd = boot_slope(&QUOTES);
    let dv_exact = N * (-dd[4] - K * dd[..5].iter().sum::<f64>()) * BP;
    let pv01 = N * a5 * BP;
    let dv_par = dv01(&QUOTES, par5, 5, N, BP);
    println!("\nDV01 of the 5-year payer, dollars per basis point");
    println!("  1 bump every quote, rebuild     {:>16}", money(dv_bump));
    println!("  2 exact slope through bootstrap {:>16}", money(dv_exact));
    println!("  PV01 shortcut N A5 x 0.0001     {:>16}", money(pv01));
    println!("  gap, PV01 minus DV01            {:>16}", money(pv01 - dv_bump));
    println!("  same swap struck at par 4.65%   {:>16}", money(dv_par));

    let dv10_unit = dv01(&QUOTES, par10, 10, 1.0, BP);
    let hedge = dv_bump / dv10_unit;
    println!("\nhedge: receive fixed on a 10-year swap at its par rate, 4.71%");
    println!("  10-year DV01 per million        {:>16}", money(1e6 * dv10_unit));
    println!("  hedge notional                  {:>16}", money(hedge));
    println!("  net DV01 of the pair            {:>16}", money(dv_bump - hedge * dv10_unit));

    let moves = [-100i32, -75, -50, -25, 0, 25, 50, 75, 100];
    let pl: Vec<(f64, f64)> = moves.iter().map(|&m| book(&[m as f64 * BP; 10], hedge, v5, par10)).collect();
    println!("\nparallel moves, P&L in thousands of dollars");
    let row = |label: &str, xs: Vec<String>| println!("{}{}", label, xs.join(" "));
    row("chart, move bp  ", moves.iter().map(|m| format!("{:>8}", m)).collect());
    row("chart, unhedged ", pl.iter().map(|p| format!("{:>8.2}", p.0 / 1e3)).collect());
    row("chart, hedged   ", pl.iter().map(|p| format!("{:>8.2}", (p.0 + p.1) / 1e3)).collect());

    let mut tw = [0.0; 10];
    for j in 1..=5 { tw[4 + j] = j as f64 * 2.0 * BP; }
    let (tw5, tw10) = book(&tw, hedge, v5, par10);
    println!("\nsteepener, years 6-10 up 2,4,6,8,10 bp: 5y {}  hedge {}  net {}", money(tw5), money(tw10), money(tw5 + tw10));

    println!("\nwhat breaks, net DV01 or DV01 in dollars per basis point");
    println!("  hedge with 10,000,000 of the 10-year  {:>12}", money(dv_bump - N * dv10_unit));
    println!("  pay fixed on the 10-year instead      {:>12}", money(dv_bump + hedge * dv10_unit));
    let zb = |h: f64| {
        let dz: Vec<f64> = d.iter().enumerate().map(|(i, x)| x * (-h * (i as f64 + 1.0)).exp()).collect();
        payer(&dz, K, 5, N)
    };
    println!("  bump zero rates, not the quotes       {:>12}", money((zb(BP) - zb(-BP)) / 2.0));

    println!("\na year at a time, quotes unchanged: DV01 of each leg and of the pair");
    for j in 0..5 {
        let a = dv01(&QUOTES, K, 5 - j, N, BP);
        let b = hedge * dv01(&QUOTES, par10, 10 - j, 1.0, BP);
        println!("  at time {}   5y leg {:>9}   hedge {:>9}   net {:>9}", j, money(a), money(b), money(a - b));
    }

    let a7: f64 = d[..7].iter().sum();
    println!("\ntry: hedge with the 7-year at par instead  {}", money(dv_bump / dv01(&QUOTES, (1.0 - d[6]) / a7, 7, 1.0, BP)));
    println!("try: bump by 10 bp and divide by 10        {}", money(dv01(&QUOTES, K, 5, N, 10.0 * BP)));

    assert!((d[4] - 0.79621728).abs() < 5e-9, "D(5) must match the bootstrapping card");
    assert!((par5 - QUOTES[4]).abs() < 1e-12, "the curve must reprice its own 5-year quote");
    assert!((flt_strip - N * (1.0 - d[4])).abs() < 1e-6, "strip of forwards vs N(1 - D(5))");
    assert!((dv_bump - dv_exact).abs() < 0.01, "bump road vs exact-slope road");
    assert!((dv_par - pv01).abs() < 0.01, "at par, DV01 must equal N A5 x 1bp");
    assert!((pl[5].0 + pl[5].1).abs() < 0.01 * pl[5].0.abs(), "hedge must cut a 25bp parallel move by 99%");
    println!("ALL CHECKS PASS");
}
