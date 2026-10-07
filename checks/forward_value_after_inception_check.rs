// An old forward -- the same check as forward_value_after_inception_check.py,
// in Rust, with no crates.  Nothing here already holds the answer: the root
// finder is a bisection, the pretend world's average is Simpson's rule, and the
// copy is stepped hour by hour on a bank account paying simple interest.  Acme:
// spot 100.00 the morning the contract was signed, bank rate 5 percent, yield 2
// percent, one year out; a month later the forward for that same day is 106.00.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const T: f64 = 1.0;
const FT: f64 = 106.0;
const HOURS: usize = 8030;                 // hours in eleven months
const YEAR: f64 = 8760.0;                  // hours in a year

fn mark(spot: f64, strike: f64, r: f64, q: f64, tau: f64) -> f64 {
    spot * (-q * tau).exp() - strike * (-r * tau).exp()   // the shares, less the loan
}

fn clean(v: f64) -> f64 {                  // a residue under a millionth of a cent is zero
    if v.abs() > 1e-8 { v } else { 0.0 }
}

fn bisect<F: Fn(f64) -> f64>(f: F, lo0: f64, hi0: f64) -> f64 {   // a root finder, written out here
    let (mut lo, mut hi) = (lo0, hi0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) <= 0.0 { hi = mid } else { lo = mid }
    }
    0.5 * (lo + hi)
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {   // thin slices under a curve
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        let w = if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn average_delivery(spot: f64, sigma: f64, tau: f64) -> f64 {   // the pretend world's average price
    let slice_at = |z: f64| {
        let bell = (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
        spot * ((R - Q - 0.5 * sigma * sigma) * tau + sigma * tau.sqrt() * z).exp() * bell
    };
    simpson(slice_at, -10.0, 10.0, 40000)
}

fn hourly(rate: f64) -> f64 {              // one dollar, interest added hour by hour for eleven months
    let mut grown = 1.0;
    for _ in 0..HOURS {
        grown *= 1.0 + rate / YEAR;
    }
    grown
}

fn row(name: &str, text: String) {
    println!("{:<50}{:>24}", name, text);
}

fn chart(label: &str, cells: Vec<String>) {        // one wide row: a label, then the values
    println!("{:<34}{}", label, cells.join(""));
}

fn main() {
    let tau = 11.0 / 12.0;
    let scen = [80.0_f64, 95.0, 110.0, 130.0];     // four ways Acme could land on delivery day
    let grid = [96.0_f64, 98.0, 100.0, 102.0, 104.0, 106.0, 108.0, 110.0];
    let left = [11_usize, 9, 6, 3, 0];             // months still to run, for the clock bars
    let mut path: [f64; 13] = [100.00, 0.00, 104.00, 101.50, 98.00, 97.00, 99.50,
                               102.00, 105.00, 106.50, 104.00, 102.50, 101.00];

    let k = S0 * ((R - Q) * T).exp();              // cash and carry, the morning it was signed
    let st = FT * (-(R - Q) * tau).exp();          // today's spot, read back from today's forward price
    let (d, drag) = ((-R * tau).exp(), (-Q * tau).exp());
    let (gap_form, spot_form) = ((FT - k) * d, mark(st, k, R, Q, tau));
    let (grow_q, grow_r) = (hourly(Q), hourly(R));
    let (shares_end, debt_end) = (drag * grow_q, k * d * grow_r);
    let mut worst = 0.0_f64;
    for x in scen.iter() {
        let gap = ((shares_end * x - debt_end) - (x - k)).abs();
        if gap > worst { worst = gap }
    }
    let cost_hourly = st / grow_q - k / grow_r;
    let (avg20, avg60) = (average_delivery(st, 0.20, tau), average_delivery(st, 0.60, tau));
    let (v20, v60) = ((avg20 - k) * d, (avg60 - k) * d);
    let s_zero = bisect(|s| mark(s, k, R, Q, tau), 50.0, 200.0);
    let (h, hr) = (0.01, 0.0001);
    let delta = (mark(st + h, k, R, Q, tau) - mark(st - h, k, R, Q, tau)) / (2.0 * h);
    let gamma = (mark(st + h, k, R, Q, tau) - 2.0 * spot_form + mark(st - h, k, R, Q, tau)) / (h * h);
    let theta = (mark(st, k, R, Q, tau - h) - mark(st, k, R, Q, tau + h)) / (2.0 * h);
    let rho = (mark(st, k, R + hr, Q, tau) - mark(st, k, R - hr, Q, tau)) / (2.0 * hr) / 100.0;
    let qsens = (mark(st, k, R, Q + hr, tau) - mark(st, k, R, Q - hr, tau)) / (2.0 * hr) / 100.0;
    path[1] = st;
    let marks: Vec<f64> = (0..13).map(|m| mark(path[m], k, R, Q, (12 - m) as f64 / 12.0)).collect();

    println!("Acme the morning it was signed: spot 100.00, rate 5 percent, yield 2 percent, one year out");
    row("K, the delivery price locked that morning", format!("{:.6}", k));
    row("the mark that morning, distance from zero", format!("{:.6}", clean(marks[0])));
    println!("one month on, eleven months still to run");
    row("F, today's forward price for that same day", format!("{:.6}", FT));
    row("S, Acme's spot price today", format!("{:.6}", st));
    row("tau, the years still to run", format!("{:.6}", tau));
    row("D = e^-r tau, a dollar due on delivery, priced today", format!("{:.6}", d));
    row("e^-q tau, the share fraction that grows into one", format!("{:.6}", drag));
    row("1 the gap form, (F - K) x D", format!("{:.6}", gap_form));
    row("2 the spot form, S e^-q tau - K D",
        format!("{:.6} - {:.6} = {:.6}", st * drag, k * d, spot_form));
    println!("close-out ledger: the old long at K, plus a new short signed at 106.00");
    println!("{:>22}{:>14}{:>14}{:>14}", "Acme on delivery day", "old long", "new short", "the pair");
    for x in scen.iter() {
        println!("{:>22.2}{:>14.2}{:>14.2}{:>14.2}", x, x - k, FT - x, (x - k) + (FT - x));
    }
    println!("3 the copy, stepped hour by hour from today to delivery");
    row("  shares held on delivery day", format!("{:.6}", shares_end));
    row("  the loan owed on delivery day", format!("{:.6}", debt_end));
    row("  worst gap, the copy's cash against S_T - K", format!("{:.6}", worst));
    row("  what that copy costs today", format!("{:.6}", cost_hourly));
    println!("4 the pretend world's average delivery price, by thin slices");
    row("  volatility 20 percent: average, then the mark", format!("{:.6} {:.6}", avg20, v20));
    row("  volatility 60 percent: average, then the mark", format!("{:.6} {:.6}", avg60, v60));
    row("5 the spot that puts the mark back at zero, hunted", format!("{:.6}", s_zero));
    row("  the same spot, K e^-(r-q)tau", format!("{:.6}", k * (-(R - Q) * tau).exp()));
    row("the mark on delivery day, Acme at 101.00", format!("{:.6}", marks[12]));
    println!("how the mark answers a nudge, with everything else held still");
    row("  delta: bumped, then e^-q tau", format!("{:.6} {:.6}", delta, drag));
    row("  gamma and vega, distance from zero", format!("{:.6} {:.6}", gamma.abs(), ((v60 - v20) / 0.40).abs()));
    row("  theta a year, then a day", format!("{:.6} {:.6}", theta, theta / 365.0));
    row("  rho per 1 percent on r, then on q", format!("{:.6} {:.6}", rho, qsens));
    println!("what breaks");
    row("  spot minus strike", format!("{:.6}", st - k));
    row("  the gap left undiscounted", format!("{:.6}", FT - k));
    row("  the original year discounted, not the months left", format!("{:.6}", mark(st, k, R, Q, T)));
    row("  the dividend yield forgotten", format!("{:.6}", st - k * d));
    row("  the long mark booked on a short, and the truth", format!("{:.6} {:.6}", gap_form, -gap_form));
    chart("chart, months gone", (0..13).map(|m| format!("{:>8}", m)).collect());
    chart("chart, Acme spot that month", path.iter().map(|p| format!("{:>8.2}", p)).collect());
    chart("chart, the mark that month", marks.iter().map(|v| format!("{:>8.2}", clean(*v))).collect());
    chart("chart, Acme spot today", grid.iter().map(|s| format!("{:>8.2}", s)).collect());
    chart("chart, the mark today", grid.iter().map(|s| format!("{:>8.2}", mark(*s, k, R, Q, tau))).collect());
    chart("clock, months still to run", left.iter().map(|m| format!("{:>8}", m)).collect());
    chart("clock, forward price for that day",
          left.iter().map(|m| format!("{:>8.2}", st * ((R - Q) * *m as f64 / 12.0).exp())).collect());
    chart("clock, the mark, Acme frozen",
          left.iter().map(|m| format!("{:>8.2}", mark(st, k, R, Q, *m as f64 / 12.0))).collect());
    assert!((gap_form - spot_form).abs() < 1e-12);          // the two forms of the formula agree
    assert!((shares_end - 1.0).abs() < 1e-6);               // hour by hour, the shares grow into one
    assert!((debt_end - k).abs() < 1e-3);                   // and the loan grows into K
    assert!(worst < 1e-3);                                  // so the copy pays S_T - K on delivery day
    assert!((cost_hourly - gap_form).abs() < 1e-4);         // and it costs what the formula says
    assert!((v20 - gap_form).abs() < 1e-6);                 // the pretend-world average, at 20 percent
    assert!((v60 - gap_form).abs() < 1e-6);                 // and at 60: volatility never enters
    assert!((s_zero - k * (-(R - Q) * tau).exp()).abs() < 1e-9);  // break-even spot, hunted then derived
    assert!((delta - drag).abs() < 1e-9);                   // delta by bumping the spot
    assert!((theta - (Q * st * drag - R * k * d)).abs() < 1e-6);  // theta by bumping the clock
    assert!(marks[0].abs() < 1e-9);                         // nothing changed hands at signing
    println!("ALL CHECKS PASS");
}
