// Stock borrow and repo -- the same check as the Python file, in Rust.  Standard
// library only, no crates.  The random numbers, the option integrals (Simpson's
// rule) and the root finder are written out here.  Acme trades at 100.00, the bank
// rate is 5%, the dividend yield 2%, the borrow fee 1% a year, delivery in one year.
// Compile: rustc --edition 2021 -O stock_borrow_repo_and_the_equity_forward_check.rs

const S: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const B: f64 = 0.01;
const T: f64 = 1.0;

/// Road 1, the formula: spot carried at the bank rate less dividend less fee.
fn fwd(s: f64, r: f64, q: f64, b: f64, t: f64) -> f64 {
    s * ((r - q - b) * t).exp()
}

/// A small linear congruential generator, then Box-Muller for bell-curve draws.
struct Rng(u64);
impl Rng {
    fn step(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let u1 = self.step() + 1e-300;
        let u2 = self.step();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

/// Roads 2 and 3: the hedge run day by day down a random Acme path.
/// Long: borrow cash at r, buy shares, lend them out; dividends and fee buy more.
/// Short: borrow shares and sell them; the cash stays with the lender as collateral
/// and earns the rebate r - fee; dividends owed are paid by shorting a sliver more.
fn ledger(seed: u64, fee: f64, long: bool) -> (f64, f64) {
    let (days, sigma) = (365, 0.3);
    let dt = T / days as f64;
    let mut z = Rng(seed);
    let mut price = S;
    let grow = if long { Q + fee } else { Q };
    let rate = if long { R } else { R - fee };
    let mut shares = (-grow * T).exp();
    let mut cash = shares * price;
    for _ in 0..days {
        price *= ((R - Q - 0.5 * sigma * sigma) * dt + sigma * dt.sqrt() * z.normal()).exp();
        cash *= (rate * dt).exp();
        let income = shares * price * ((grow * dt).exp() - 1.0);
        shares += income / price;
    }
    assert!((shares - 1.0).abs() < 1e-12);
    (cash, price)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, c: f64, n: usize) -> f64 {
    let h = (c - a) / n as f64;
    let mut s = f(a) + f(c);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

/// A call or put priced by averaging its payoff over the bell curve, split at the kink.
fn option(k: f64, call: bool, rr: f64, carry: f64) -> f64 {
    let sigma = 0.2;
    let m = S.ln() + (rr - carry - 0.5 * sigma * sigma) * T;
    let v = sigma * T.sqrt();
    let dens = |z: f64| (-z * z / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt();
    let zk = (k.ln() - m) / v;
    let val = if call {
        simpson(&|z: f64| ((m + v * z).exp() - k) * dens(z), zk, 10.0, 2000)
    } else {
        simpson(&|z: f64| (k - (m + v * z).exp()) * dens(z), -10.0, zk, 2000)
    };
    (-rr * T).exp() * val
}

fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if g(lo) * g(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn out(label: &str, x: f64, d: usize) {
    println!("{:<46}{:>14.*}", label, d, x);
}

fn main() {
    println!("Acme 100.00, r 5%, q 2%, borrow fee 1%, T 1 year");
    let (f, f0) = (fwd(S, R, Q, B, T), fwd(S, R, Q, 0.0, T));
    out("forward with the borrow fee", f, 4);
    out("forward ignoring the fee", f0, 4);
    out("gap the fee makes", f0 - f, 4);
    out("share fraction to buy, exp(-(q+b)T)", (-(Q + B) * T).exp(), 6);
    out("cost of that fraction, prepaid forward", S * (-(Q + B) * T).exp(), 4);
    out("repo rate rho = r - b, percent", 100.0 * (R - B), 4);
    out("forward as S exp((rho - q)T)", S * ((R - B - Q) * T).exp(), 4);
    assert!((f - 102.0201).abs() < 5e-5 && (f0 - 103.0455).abs() < 5e-5);

    println!("roads 2 and 3: day-by-day ledgers on random paths, sigma 30%");
    for seed in 1..=3u64 {
        let (c_long, p_end) = ledger(seed, B, true);
        let (c_short, _) = ledger(seed, B, false);
        println!("  path {}: Acme ends {:8.2}  long break-even {:9.4}  short break-even {:9.4}",
                 seed, p_end, c_long, c_short);
        assert!((c_long - f).abs() < 1e-6 && (c_short - f).abs() < 1e-6);
    }

    println!("arbitrage ledgers, profit on delivery day");
    out("  quote 103.0455 (fee ignored): carry and lend", f0 - f, 4);
    out("  quote 101.0000: short, pay the fee", f - 101.0, 4);
    let (lo, hi) = (fwd(S, R, Q, 0.010, T), fwd(S, R, Q, 0.008, T));
    out("band, shorts pay 1.00%: lowest forward", lo, 4);
    out("band, lenders get 0.80%: highest forward", hi, 4);
    assert!(lo < f0 && lo < hi && hi < f0);

    println!("inverse 1: a listed forward 102.0201, SOFR 5%, known dividend 2%");
    let fq = 102.0201;
    let carry = (fq / S).ln() / T;
    out("carry ln(F/S)/T, percent", 100.0 * carry, 4);
    out("implied yield r - carry, percent", 100.0 * (R - carry), 4);
    out("implied repo rho = q + carry, percent", 100.0 * (Q + carry), 4);
    let b_log = R - Q - carry;
    let b_bis = bisect(&|x: f64| fwd(S, R, Q, x, T) - fq, -0.5, 0.5);
    out("implied borrow fee, by logarithm, percent", 100.0 * b_log, 4);
    out("implied borrow fee, by bisection, percent", 100.0 * b_bis, 4);
    assert!((b_log - 0.01).abs() < 1e-5 && (b_bis - b_log).abs() < 1e-9);

    println!("inverse 2: box spread and parity, options priced with r 5%, q+b 3%");
    let mut g = [0.0; 3];
    for (i, k) in [90.0, 100.0, 110.0].iter().enumerate() {
        let c = option(*k, true, R, Q + B);
        let p = option(*k, false, R, Q + B);
        g[i] = c - p;
        println!("  strike {}: call {:8.4}  put {:8.4}  call - put {:8.4}", k, c, p, g[i]);
    }
    let d = (g[0] - g[2]) / 20.0;
    let rb = -d.ln() / T;
    let fb = 100.0 + g[1] / d;
    out("box: discount factor D", d, 6);
    out("box: rate -ln(D)/T, percent", 100.0 * rb, 4);
    out("parity at 100: forward 100 + (C - P)/D", fb, 4);
    out("implied repo q + ln(F/S)/T, percent", 100.0 * (Q + (fb / S).ln() / T), 4);
    out("implied borrow fee, percent", 100.0 * (rb - Q - (fb / S).ln() / T), 4);
    assert!((rb - R).abs() < 1e-6 && (fb - f).abs() < 1e-5);
    assert!((rb - Q - (fb / S).ln() / T - B).abs() < 1e-6);

    println!("what breaks");
    out("  fee left out", f0, 4);
    out("  fee added to the cost of carry", fwd(S, R, Q, -B, T), 4);
    out("  whole implied yield read as dividend, %", 100.0 * (R - carry), 4);
    out("  dividend forgotten, fee read as, %", 100.0 * (R - carry), 4);
    let short_f = fwd(S, R, Q, B, 1.0 / 12.0) - 0.01;
    out("  short-dated 1-month quote 0.01 low: fee, %", 100.0 * (R - Q - (short_f / S).ln() * 12.0), 4);

    println!("how it moves: one-year forward against the fee");
    for fee in [0.0, 0.01, 0.05, 0.10, 0.25] {
        out(&format!("  fee {:5.1}%", 100.0 * fee), fwd(S, R, Q, fee, T), 2);
    }
    let row = |name: &str, h: &dyn Fn(f64) -> String| {
        println!("{}{}", name, (0..6).map(|t| h(t as f64)).collect::<String>());
    };
    row("chart, years      ", &|t| format!("{:>8}", t as i64));
    row("chart, no fee     ", &|t| format!("{:8.2}", fwd(S, R, Q, 0.0, t)));
    row("chart, fee 1%     ", &|t| format!("{:8.2}", fwd(S, R, Q, B, t)));
    println!("ALL CHECKS PASS");
}
