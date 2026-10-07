// The risk-neutral probability -- the same check as the Python, in Rust.  No
// crates.  One year, one step, on the house market: Acme at 100, strike 100,
// cash paying 5 percent, a 2 percent dividend yield, 20 percent volatility.
// The weight q is found twice, the put is priced twice, and the no-arbitrage
// claim is tested market by market.
const S: f64 = 100.0;
const K: f64 = 100.0;
const R_RATE: f64 = 0.05;
const Y: f64 = 0.02;
const SIGMA: f64 = 0.20;
const T: f64 = 1.0;

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {                       // our own root finder: halve the bracket
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn solve2(a11: f64, a12: f64, a21: f64, a22: f64, b1: f64, b2: f64) -> (f64, f64) {
    let det = a11 * a22 - a12 * a21;        // two equations, two unknowns: Cramer's rule
    ((b1 * a22 - a12 * b2) / det, (a11 * b2 - b1 * a21) / det)
}

fn copy_cost(u: f64, d: f64, bank: f64, pay_u: f64, pay_d: f64) -> (f64, f64, f64) {
    let (sh, cs) = solve2(S * u * (Y * T).exp(), bank, S * d * (Y * T).exp(), bank, pay_u, pay_d);
    (sh, cs, sh * S + cs)                   // the real-world odds are never consulted
}

fn weighted(bank: f64, pay_u: f64, pay_d: f64, w: f64) -> f64 {
    (w * pay_u + (1.0 - w) * pay_d) / bank  // discounted average, weight w on the up branch
}

fn one(name: &str, v: f64) { println!("{:<44}{:>14.6}", name, v) }

fn main() {
    let (u, d) = ((SIGMA * T.sqrt()).exp(), (-SIGMA * T.sqrt()).exp());
    let (r, y) = (R_RATE, Y);
    let (rr, bank) = (((r - y) * T).exp(), (r * T).exp());
    let (put_u, put_d) = ((K - S * u).max(0.0), (K - S * d).max(0.0));
    let (call_u, call_d) = ((S * u - K).max(0.0), (S * d - K).max(0.0));
    let q = (rr - d) / (u - d);                                    // road 1: the formula
    let q_bis = bisect(|w| w * u + (1.0 - w) * d - rr, -2.0, 2.0); // road 2: solve for it
    let put_q = weighted(bank, put_u, put_d, q);                   // road 1: the q-average
    let (sh, cs, put_copy) = copy_cost(u, d, bank, put_u, put_d);  // road 2: the copy's bill
    let call_q = weighted(bank, call_u, call_d, q);
    let parity_left = call_q - put_q;
    let parity_right = S * (-y * T).exp() - K * (-r * T).exp();

    println!("Acme, one year, one step: S 100, K 100, r 5 percent, dividend 2 percent, vol 20 percent");
    one("u, the up factor", u);
    one("d, the down factor", d);
    one("u - d, the width of the fork", u - d);
    one("R, the share's growth factor e^((r-y)T)", rr);
    one("R - d, how far R sits above the down factor", rr - d);
    one("the bank's growth factor e^(rT)", bank);
    one("up node, S times u", S * u);
    one("down node, S times d", S * d);
    one("put payoff up, max(K - Su, 0)", put_u);
    one("put payoff down, max(K - Sd, 0)", put_d);
    one("call payoff up, max(Su - K, 0)", call_u);
    one("1 q by the formula (R - d)/(u - d)", q);
    one("2 q by bisection on q u + (1-q) d = R", q_bis);
    one("  1 - q, the weight on the down branch", 1.0 - q);
    one("3 put by the discounted q-average", put_q);
    one("4 put by the copy, shares plus cash", put_copy);
    one("  shares in the copy", sh);
    one("  cash in the copy", cs);
    one("5 call by the discounted q-average", call_q);
    one("  call minus put", parity_left);
    one("  S e^(-yT) - K e^(-rT)", parity_right);
    one("6 q-average of the share, q Su + (1-q) Sd", q * S * u + (1.0 - q) * S * d);
    one("  the same, discounted at the bank rate", (q * S * u + (1.0 - q) * S * d) / bank);
    one("  S e^(-yT), the prepaid share", S * (-y * T).exp());

    println!("real-world odds move the guess, not the copy's bill:");
    println!("{:<34}{:>12}{:>22}", "p, the real chance of an up move", "copy cost", "p-average of the put");
    for p in [0.30_f64, 0.50, 0.70] {
        println!("{:<34.2}{:>12.6}{:>22.6}", p, copy_cost(u, d, bank, put_u, put_d).2,
                 weighted(bank, put_u, put_d, p));
    }

    println!("borrow S e^(-yT), hold one share, owe S R at the end.  Gains, by state:");
    println!("{:>8}{:>8}{:>8}{:>9}{:>9}{:>9}   the free trade, if any", "u", "d", "R", "q", "up", "down");
    for (uu, dd, big_r) in [(u, d, rr), (u, d, 1.30), (u, d, 0.80), (u, d, u), (1.10, 0.95, rr), (u, d, d)] {
        let qq = (big_r - dd) / (uu - dd);
        let (up_gain, down_gain) = (S * uu - S * big_r, S * dd - S * big_r);
        let move_ = if up_gain.min(down_gain) >= 0.0 && up_gain.max(down_gain) > 0.0 {
            "borrow the cash, hold the share"
        } else if up_gain.max(down_gain) <= 0.0 && up_gain.min(down_gain) < 0.0 {
            "short the share, lend the cash"
        } else {
            "none: each trade loses in one state"
        };
        println!("{:>8.4}{:>8.4}{:>8.4}{:>9.4}{:>9.2}{:>9.2}   {}", uu, dd, big_r, qq, up_gain, down_gain, move_);
        assert_eq!(0.0 < qq && qq < 1.0, dd < big_r && big_r < uu);
        if 0.0 < qq && qq < 1.0 {
            assert!(up_gain.min(down_gain) < 0.0 && 0.0 < up_gain.max(down_gain));
        } else {
            assert!(up_gain.min(down_gain) >= 0.0 || up_gain.max(down_gain) <= 0.0);
            assert!(up_gain.abs().max(down_gain.abs()) > 0.0);
        }
    }

    println!("the weight drifts towards a half as the step shrinks:");
    println!("{:>18}{:>12}{:>12}{:>12}", "steps in the year", "u", "d", "q");
    let mut fine: Vec<f64> = Vec::new();
    for n in [1_u32, 2, 4, 12, 252] {
        let dt = T / n as f64;
        let (un, dn) = ((SIGMA * dt.sqrt()).exp(), (-SIGMA * dt.sqrt()).exp());
        fine.push((((r - y) * dt).exp() - dn) / (un - dn));
        println!("{:>18}{:>12.6}{:>12.6}{:>12.6}", n, un, dn, fine[fine.len() - 1]);
    }

    let q_nodiv = (bank - d) / (u - d);
    one("wrong: the real odds p = 0.70 as the weight", weighted(bank, put_u, put_d, 0.70));
    one("wrong: no dividend, q = (e^(rT) - d)/(u - d)", q_nodiv);
    one("  the put it gives", weighted(bank, put_u, put_d, q_nodiv));
    one("wrong: q and 1 - q swapped", weighted(bank, put_u, put_d, 1.0 - q));
    one("wrong: the average, never discounted", q * put_u + (1.0 - q) * put_d);

    let mut across = String::from("chart, R across        ");
    let mut down = String::from("chart, q down          ");
    for i in 0..10 {
        let big_r = 0.80 + 0.05 * i as f64;
        across.push_str(&format!("{:>7.2}", big_r));
        down.push_str(&format!("{:>7.2}", (big_r - d) / (u - d)));
    }
    println!("{}", across);
    println!("{}", down);
    let mut bars = String::from("the put under weights 0.30, q, 0.50, 0.70 ");
    for w in [0.30, q, 0.50, 0.70] { bars.push_str(&format!("{:>8.2}", weighted(bank, put_u, put_d, w))) }
    println!("{}", bars);

    assert!((q_bis - q).abs() < 1e-12);                    // two roads to the weight
    assert!((put_copy - put_q).abs() < 1e-10);             // the copy's bill vs the q-average
    assert!((sh * S * u * (y * T).exp() + cs * bank - put_u).abs() < 1e-10);   // copy matches up
    assert!((sh * S * d * (y * T).exp() + cs * bank - put_d).abs() < 1e-10);   // copy matches down
    assert!((parity_left - parity_right).abs() < 1e-10);   // an identity the weights never see
    assert!(((q * S * u + (1.0 - q) * S * d) / bank - S * (-y * T).exp()).abs() < 1e-10);  // the share too
    assert!((fine[4] - 0.5).abs() < (fine[0] - 0.5).abs());  // finer steps, flatter weight
    println!("ALL CHECKS PASS");
}
