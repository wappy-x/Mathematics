// Kyle's lambda and the square-root law -- the check behind the card.  Rust std only.
// A stock at $100 that trades 1,000,000 shares a day; a sale of 100,000 shares (10% of the day).
// The random numbers, the root finder and the fits are written here.
use std::f64::consts::PI;

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let a = self.unif();
        let b = self.unif();
        (-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos()
    }
}

// sell q shares into a book with one-cent levels; return the price fall in dollars
fn walk(q: f64, depth_at: &dyn Fn(f64) -> f64) -> f64 {
    let (mut k, mut left) = (0.0, q);
    while left > 1e-9 {
        k += 1.0;
        left -= depth_at(k);
    }
    0.01 * k
}

// least-squares slope of log(price fall) on log(size)
fn fit_exponent(sizes: &[f64], depth_at: &dyn Fn(f64) -> f64) -> f64 {
    let xs: Vec<f64> = sizes.iter().map(|q| q.ln()).collect();
    let ys: Vec<f64> = sizes.iter().map(|&q| walk(q, depth_at).ln()).collect();
    let m = xs.len() as f64;
    let mx = xs.iter().sum::<f64>() / m;
    let my = ys.iter().sum::<f64>() / m;
    let num: f64 = xs.iter().zip(&ys).map(|(a, b)| (a - mx) * (b - my)).sum();
    let den: f64 = xs.iter().map(|a| (a - mx) * (a - mx)).sum();
    num / den
}

fn main() {
    let (p0, sv, su) = (100.0_f64, 1.20_f64, 200_000.0_f64);
    let (q, vd, sd, y_const) = (100_000.0_f64, 1_000_000.0_f64, 0.01_f64, 1.0_f64);

    // road 1: the closed form
    let lam = sv / (2.0 * su);
    let beta = su / sv;
    let v_ins = p0 - q / beta;
    let x_ins = beta * (v_ins - p0);
    let p_after = p0 + lam * x_ins;

    // road 2: the two best responses as an equation, solved by bisection
    let dealer_slope = |l: f64| {
        let b = 1.0 / (2.0 * l);
        b * sv * sv / (b * b * sv * sv + su * su)
    };
    let (mut lo, mut hi) = (1e-9_f64, 1e-3_f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if dealer_slope(mid) - mid > 0.0 { lo = mid } else { hi = mid }
    }
    let lam_bis = 0.5 * (lo + hi);

    // road 3: the insider's best order by brute force, lambda held fixed
    let (mut best_x, mut best_pay) = (0.0_f64, -1e18_f64);
    for k in -400..=400 {
        let x = 500.0 * k as f64;
        let pay = x * (v_ins - p0 - lam * x);
        if pay > best_pay { best_x = x; best_pay = pay; }
    }

    // road 4: simulate 200,000 auctions and let the dealer fit a line
    let mut rng = Rng(20260928);
    let n = 200_000;
    let (mut sy, mut syy, mut sv_y, mut s_ins, mut s_noise, mut s_deal, mut s_res) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    for _ in 0..n {
        let w = sv * rng.normal();
        let u = su * rng.normal();
        let x = beta * w;
        let y = x + u;
        let price_move = lam * y;
        sy += y; syy += y * y; sv_y += w * y;
        s_ins += x * (w - price_move); s_noise += u * (w - price_move); s_deal += y * (price_move - w);
        s_res += (w - price_move) * (w - price_move);
    }
    let nf = n as f64;
    let lam_mc = (sv_y / nf) / (syy / nf - (sy / nf) * (sy / nf));

    // the square-root law, and a latent order book that produces it
    let i_sqrt = y_const * sd * (q / vd).sqrt();
    let l_slope = 2.0 * q / ((i_sqrt * p0) * (i_sqrt * p0));
    let vshape = move |k: f64| l_slope * (0.01 * k) * 0.01;
    let flat = move |k: f64| { let _ = k; 0.01 / lam };
    let sizes = [10_000.0, 20_000.0, 50_000.0, 100_000.0, 200_000.0, 400_000.0];
    let exp_v = fit_exponent(&sizes, &vshape);
    let exp_f = fit_exponent(&sizes, &flat);

    let rows: Vec<(&str, f64)> = vec![
        ("kyle: lambda, $ per million shares of flow", lam * 1e6),
        ("kyle: lambda by bisection", lam_bis * 1e6),
        ("kyle: lambda from 200,000 auctions", lam_mc * 1e6),
        ("kyle: depth 1/lambda, shares per $1", 1.0 / lam),
        ("kyle: beta, shares per $ of mispricing", beta),
        ("kyle: value that makes insider sell 100k", v_ins),
        ("kyle: best order, brute force", best_x),
        ("kyle: price after the sale, noise = 0", p_after),
        ("kyle: move in percent", 100.0 * (p_after - p0) / p0),
        ("kyle: sd of value before, $", sv),
        ("kyle: sd of value after, formula", sv / 2.0_f64.sqrt()),
        ("kyle: sd of value after, simulated", (s_res / nf).sqrt()),
        ("kyle: insider profit per auction, formula", sv * su / 2.0),
        ("kyle: insider profit, simulated", s_ins / nf),
        ("kyle: noise traders' result, simulated", s_noise / nf),
        ("kyle: dealer result, simulated", s_deal / nf),
        ("kyle: insider profit on this sale", x_ins * (v_ins - p0 - lam * x_ins)),
        ("sqrt: impact of 10% of volume, percent", 100.0 * i_sqrt),
        ("sqrt: in dollars per share", i_sqrt * p0),
        ("sqrt: book walk, dollars per share", walk(q, &vshape)),
        ("sqrt: book slope L, shares per $ per $", l_slope),
        ("fit: exponent, V-shaped book", exp_v),
        ("fit: exponent, Kyle's flat book", exp_f),
        ("wrong: no factor 2, move in percent", -100.0 * (sv / su) * q / p0),
        ("wrong: participation in percent, not fraction", 100.0 * sd * 10.0_f64.sqrt()),
        ("wrong: annual vol 16% for daily", 100.0 * 0.16 * 0.1_f64.sqrt()),
        ("try: noise sd doubled, kyle move %", -100.0 * sv / (4.0 * su) * q / p0),
        ("try: value sd doubled, kyle move %", -100.0 * 2.0 * sv / (2.0 * su) * q / p0),
        ("try: 40% of volume, sqrt percent", 100.0 * sd * 0.4_f64.sqrt()),
        ("try: Y = 0.5, sqrt percent", 100.0 * 0.5 * sd * 0.1_f64.sqrt()),
    ];
    for (name, v) in &rows {
        println!("{:<46} {:>16.4}", name, v);
    }
    println!();
    println!("chart: percent of daily volume      1      2      5     10     20     40");
    let parts = [0.01, 0.02, 0.05, 0.10, 0.20, 0.40];
    let line = |f: &dyn Fn(f64) -> String| parts.iter().map(|&p| f(p)).collect::<String>();
    println!("chart: sqrt law, % move        {}", line(&|p| format!("{:7.3}", 100.0 * sd * p.sqrt())));
    println!("chart: kyle line, % move       {}", line(&|p| format!("{:7.3}", 100.0 * lam * p * vd / p0)));
    println!("chart: sqrt book walk, $       {}", line(&|p| format!("{:7.2}", walk(p * vd, &vshape))));

    assert!((lam_bis - lam).abs() < 1e-12 * lam * 1e3, "bisection must land on sigma_v / (2 sigma_u)");
    assert!((lam_mc - lam).abs() < 0.02 * lam, "the dealer's fitted slope on simulated auctions");
    assert!((best_x - x_ins).abs() < 1e-6, "brute-force best order equals beta times mispricing");
    assert!((s_ins / nf - sv * su / 2.0).abs() < 0.03 * sv * su / 2.0, "simulated insider profit vs formula");
    assert!(((s_res / nf).sqrt() - sv / 2.0_f64.sqrt()).abs() < 0.01 * sv, "half the value variance is left after the auction");
    assert!((s_noise / nf + sv * su / 2.0).abs() < 0.03 * sv * su / 2.0, "the crowd loses what the insider gains");
    assert!((s_deal / nf).abs() < 0.03 * sv * su / 2.0, "the dealer breaks even");
    assert!((walk(q, &vshape) - i_sqrt * p0).abs() <= 0.01, "book walk within one cent of the square-root formula");
    assert!((exp_v - 0.5).abs() < 0.05, "fitted exponent of the V-shaped book is one half");
    assert!((exp_f - 1.0).abs() < 0.02, "fitted exponent of the flat book is one");
    println!("ALL CHECKS PASS");
}
