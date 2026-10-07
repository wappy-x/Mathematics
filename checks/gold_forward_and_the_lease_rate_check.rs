// Gold forward and the lease rate -- the same check as the Python, in Rust.
// Standard library only, no crates.  The forward is reached four ways that
// share no formula: the closed form, the break-even quote of the
// cash-and-carry ledger found by bisection, both loans rolled day by day, and
// an average over simulated gold prices from a hand-written generator.
use std::f64::consts::PI;

const S: f64 = 2000.0; // spot, USD per troy ounce
const R: f64 = 0.05; // dollar rate, continuously compounded
const L: f64 = 0.01; // lease rate, continuously compounded
const T: f64 = 1.0; // years to delivery

fn forward(s: f64, r: f64, l: f64, t: f64) -> f64 { s * ((r - l) * t).exp() } // road 1

// forward quoted too high: sell it, buy gold and lend it, deliver 1 oz at T
fn rich(fq: f64) -> [f64; 5] {
    let oz = (-L * T).exp(); // gold bought today and lent out
    let usd = oz * S; // dollars borrowed to pay for it
    let back = oz * (L * T).exp(); // ounces returned at T
    let debt = usd * (R * T).exp(); // dollars owed at T
    [oz, usd, back, debt, back * fq - debt]
}

// forward quoted too low: buy it, borrow gold and sell it, owe 1 oz at T
fn cheap(fq: f64) -> [f64; 5] {
    let oz = (-L * T).exp(); // gold borrowed today and sold
    let usd = oz * S; // dollars lent out
    let deposit = usd * (R * T).exp(); // dollars back at T
    let owed = oz * (L * T).exp(); // ounces owed to the gold lender at T
    [oz, usd, deposit, owed, deposit - owed * fq]
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    let mut flo = f(lo);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        let fm = f(mid);
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn daily_roll(days: f64) -> f64 { // road 3: both loans rolled once a day
    let (mut oz, mut debt) = (1.0_f64, S);
    for _ in 0..((days * T) as usize) {
        oz *= 1.0 + L / 365.0;
        debt *= 1.0 + R / 365.0;
    }
    debt / oz
}

struct Lcg(u64); // road 4: 64-bit linear congruential generator
impl Lcg {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn mc_mean(rng: &mut Lcg, drift: f64, sigma: f64, pairs: usize) -> (f64, f64) {
    let (mut tot, mut tot2) = (0.0_f64, 0.0_f64);
    for _ in 0..pairs {
        let u1 = rng.uniform();
        let u2 = rng.uniform();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos(); // Box-Muller
        for zz in [z, -z] {
            let st = S * ((drift - 0.5 * sigma * sigma) * T + sigma * T.sqrt() * zz).exp();
            tot += st;
            tot2 += st * st;
        }
    }
    let n = (2 * pairs) as f64;
    let m = tot / n;
    (m, ((tot2 / n - m * m) / n).sqrt())
}

fn implied(q: f64) -> f64 { R - (q / S).ln() / T } // the lease rate a quote implies

fn show(name: &str, v: f64) { println!("{:<40}{:>16.6}", name, v); }
fn show2(name: &str, v: f64) { println!("{:<40}{:>16.2}", name, v); }
fn show12(name: &str, v: f64) { println!("{:<40}{:>16.12}", name, v); }

fn main() {
    let f = forward(S, R, L, T);
    let f_root = bisect(|q| rich(q)[4], 0.0, 10.0 * S);
    let f_day = daily_roll(365.0);
    let mut rng = Lcg(20260927);
    let (f_mc, se) = mc_mean(&mut rng, R - L, 0.15, 100000);
    let (real_mc, _) = mc_mean(&mut rng, 0.08, 0.15, 100000);
    let implied_root = bisect(|x| forward(S, R, x, T) - 2100.0, -1.0, 1.0);

    println!("gold 2000 USD/oz, dollars 5%, lease 1%, 1 year");
    show("1 formula S e^((r-l)T)", f);
    show("2 ledger break-even, bisection", f_root);
    show("3 both loans rolled daily, 365 days", f_day);
    show2("4 Monte Carlo, vol 15%, 200000 draws", f_mc);
    show2("  standard error", se);
    show2("  mean if gold drifts at 8%", real_mc);
    let rn = ["gold bought and lent (oz)", "dollars borrowed", "gold returned at T (oz)", "dollar debt at T", "profit at T"];
    for (n, v) in rn.iter().zip(rich(2100.0)) { show(&format!("rich 2100: {}", n), v); }
    let cn = ["gold borrowed and sold (oz)", "dollars lent", "deposit at T", "gold owed at T (oz)", "profit at T"];
    for (n, v) in cn.iter().zip(cheap(2060.0)) { show(&format!("cheap 2060: {}", n), v); }
    show("route A today: F e^(-rT)", f * (-R * T).exp());
    show("route B today: S e^(-lT)", S * (-L * T).exp());
    show("carry factor e^((r-l)T)", ((R - L) * T).exp());
    show("premium ln(F/S)/T", (f / S).ln() / T);
    show("  simple premium F/S - 1", f / S - 1.0);
    show12("implied lease at 2100, log inverse", implied(2100.0));
    show12("implied lease at 2100, bisection", implied_root);
    show("full-carry ceiling S e^(rT)", forward(S, R, 0.0, T));
    show("wrong: forgot the lease", forward(S, R, 0.0, T));
    show("  2100 then looks cheap by", forward(S, R, 0.0, T) - 2100.0);
    show("wrong: lease added", forward(S, R, -L, T));
    show("wrong: simple gap S(1+(r-l)T)", S * (1.0 + (R - L) * T));
    show("wrong: discounted, not grown", S * (-(R - L) * T).exp());
    show("wrong: lent 1 oz, cash at T", 2100.0 - S * (R * T).exp());
    show("  loose ounces left over", (L * T).exp() - 1.0);
    show("try: lease 5%", forward(S, R, 0.05, T));
    show("try: lease 8%", forward(S, R, 0.08, T));
    show("try: 5 years", forward(S, R, L, 5.0));
    show("try: dollars 2%", forward(S, 0.02, L, T));
    let row = |label: &str, cells: Vec<String>| println!("{:<19}{}", label, cells.concat());
    row("chart, years", (0..6).map(|t| format!("{:>9}", t)).collect());
    row("chart, lease 1%", (0..6).map(|t| format!("{:>9.2}", forward(S, R, L, t as f64))).collect());
    row("chart, no lease", (0..6).map(|t| format!("{:>9.2}", forward(S, R, 0.0, t as f64))).collect());
    let quotes = [2040.0_f64, 2060.0, 2080.0, 2100.0, 2120.0];
    row("chart, quote", quotes.iter().map(|q| format!("{:>9.0}", q)).collect());
    row("chart, implied %", quotes.iter().map(|q| format!("{:>9.2}", 100.0 * implied(*q))).collect());

    assert!((f - 2081.621548384777).abs() < 1e-9, "formula vs the value worked out by series");
    assert!((f_root - f).abs() < 1e-8, "the ledger breaks even exactly at the formula");
    assert!((f_day - f).abs() < 0.01, "daily compounding lands within a cent");
    assert!((f_mc - f).abs() < 3.0 * se, "risk-neutral average of the gold price is the forward");
    assert!((real_mc - f).abs() > 50.0, "a real-world forecast is a different number");
    assert!((implied(2100.0) - 0.001209835831).abs() < 1e-12, "log inverse vs the value worked out by series");
    assert!((implied_root - implied(2100.0)).abs() < 1e-12, "bisection inverse agrees with the log inverse");
    assert!((rich(2100.0)[4] - 18.378451615223).abs() < 1e-9, "rich ledger locks in the quote minus the forward");
    assert!((cheap(2060.0)[4] - 21.621548384777).abs() < 1e-9, "cheap ledger locks in the forward minus the quote");
    println!("ALL CHECKS PASS");
}
