// Interest rate swaps -- the same check as interest_rate_swaps_check.py, in Rust.
// Standard library only, no crates.  One 5-year swap, 4.5 percent fixed paid
// annually against a 12-month floating rate, 10,000,000 notional, valued on the
// bootstrapped curve by three roads that share no shortcut:
//   road 1, two bonds: the floating note at par, less a fixed-coupon bond;
//   road 2, a strip of forwards: each year's net payment at its forward rate;
//   road 3, a rate tree fitted to the curve, where the floating rates are random,
//           summing each node's net payment at today's price for that node.
const N: f64 = 10_000_000.0;
const K: f64 = 0.045;
const YEARS: usize = 5;

// the bootstrapped curve, with bump added to every quote
fn curve(swaps: &[(usize, f64)], bump: f64) -> Vec<f64> {
    let mut d = vec![1.0_f64, 1.0 / (1.042 + bump)];   // today, and the 12-month deposit
    for &(n, s) in swaps {
        let b: f64 = d[1..n].iter().sum();
        d.push((1.0 - (s + bump) * b) / (1.0 + s + bump));
    }
    d
}

fn strip(d: &[f64]) -> f64 {                          // road 2 on any curve
    (1..=YEARS).map(|i| N * (d[i - 1] / d[i] - 1.0 - K) * d[i]).sum()
}

fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

// additive rate tree fitted to the curve; q holds today's price of 1 paid at each node
fn tree(d: &[f64], sigma: f64) -> (Vec<Vec<f64>>, Vec<Vec<f64>>) {
    let (mut rates, mut prices, mut q) = (Vec::new(), Vec::new(), vec![1.0_f64]);
    for i in 0..YEARS {
        let node = |th: f64, j: usize| th + sigma * (2.0 * j as f64 - i as f64);
        let f = |th: f64| q.iter().enumerate().map(|(j, x)| x / (1.0 + node(th, j))).sum::<f64>() - d[i + 1];
        let th = bisect(f, -0.5, 0.5);
        let r: Vec<f64> = (0..=i).map(|j| node(th, j)).collect();
        let mut nq = vec![0.0; i + 2];
        for (j, x) in q.iter().enumerate() {
            nq[j] += 0.5 * x / (1.0 + r[j]);
            nq[j + 1] += 0.5 * x / (1.0 + r[j]);
        }
        rates.push(r);
        prices.push(q);
        q = nq;
    }
    (rates, prices)
}

fn strip_on_tree(d: &[f64], sigma: f64) -> f64 {   // each node's net payment, known at the node
    let (rates, prices) = tree(d, sigma);
    let mut v = 0.0;
    for i in 0..YEARS {
        for (q, r) in prices[i].iter().zip(&rates[i]) { v += q * N * (r - K) / (1.0 + r); }
    }
    v
}

// roll back: the note and the fixed bond at every node, ex-payment
fn by_tree(rates: &[Vec<f64>], principal: f64) -> Vec<(Vec<f64>, Vec<f64>)> {
    let last = &rates[YEARS - 1];
    let note: Vec<f64> = last.iter().map(|r| principal * (1.0 + r) / (1.0 + r)).collect();
    let bond: Vec<f64> = last.iter().map(|r| principal * (1.0 + K) / (1.0 + r)).collect();
    let mut layers = vec![(note, bond)];
    for i in (0..YEARS - 1).rev() {
        let (n1, b1) = layers[0].clone();
        let r = &rates[i];
        let note = (0..=i).map(|j| (0.5 * (n1[j] + n1[j + 1]) + principal * r[j]) / (1.0 + r[j])).collect();
        let bond = (0..=i).map(|j| (0.5 * (b1[j] + b1[j + 1]) + principal * K) / (1.0 + r[j])).collect();
        layers.insert(0, (note, bond));
    }
    layers
}

fn main() {
    let swaps = [(2usize, 0.0440_f64), (3, 0.0455), (4, 0.0462), (5, 0.0465)];
    let d = curve(&swaps, 0.0);
    let f: Vec<f64> = (1..=YEARS).map(|i| d[i - 1] / d[i] - 1.0).collect();

    let fixed_coupons: f64 = (1..=YEARS).map(|i| K * N * d[i]).sum();
    let fixed_bond = fixed_coupons + N * d[YEARS];
    let note = N;                                     // worth par on a reset date: the card's claim
    let road1 = note - fixed_bond;

    let net: Vec<f64> = (0..YEARS).map(|i| N * (f[i] - K)).collect();
    let pv: Vec<f64> = (0..YEARS).map(|i| net[i] * d[i + 1]).collect();
    let road2: f64 = pv.iter().sum();
    let float_leg: f64 = (0..YEARS).map(|i| N * f[i] * d[i + 1]).sum();

    let t1 = tree(&d, 0.01).0;
    let layers = by_tree(&t1, N);
    let (road3, road3b) = (strip_on_tree(&d, 0.01), strip_on_tree(&d, 0.02));

    println!("swap: notional {:.2}, fixed {:.2}%, coupon {:.2} a year, {} years", N, 100.0 * K, K * N, YEARS);
    println!("year  discount factor  forward rate  net to fixed payer  worth today");
    for i in 1..=YEARS {
        println!("{:>4}  {:15.8}  {:11.4}%  {:18.2}  {:11.2}", i, d[i], 100.0 * f[i - 1], net[i - 1], pv[i - 1]);
    }
    let fs: Vec<String> = f.iter().map(|x| format!("{:.2}", 100.0 * x)).collect();
    println!("chart, forward rate %  {}   fixed 4.50", fs.join(" "));
    let a: f64 = d[1..].iter().sum();
    println!("annuity, sum of D                  {:18.6}", a);
    println!("par rate on this curve (1-D5)/A    {:17.4}%", 100.0 * (1.0 - d[5]) / a);
    println!("fixed leg, coupons only            {:18.2}", fixed_coupons);
    println!("floating leg, forwards             {:18.2}", float_leg);
    println!("floating leg, N(1 - D5)            {:18.2}", N * (1.0 - d[5]));
    println!("fixed bond, principal part N D5   {:18.2}", N * d[YEARS]);
    println!("fixed bond, coupons + principal    {:18.2}", fixed_bond);
    println!("floating note, principal included  {:18.2}", note);
    println!("road 1, note - fixed bond          {:18.2}", road1);
    println!("road 2, strip of forwards          {:18.2}", road2);
    println!("road 3, rate tree, sigma 1%        {:18.2}", road3);
    println!("road 3, rate tree, sigma 2%        {:18.2}", road3b);
    println!("tree, today: note and fixed bond   {:18.2} {:14.2}", layers[0].0[0], layers[0].1[0]);
    for j in 0..3 {
        println!("tree, year 2 node {}: rate {:6.4}%  note {:14.2}  bond {:14.2}",
                 j, 100.0 * t1[2][j], layers[2].0[j], layers[2].1[j]);
    }
    println!("wrong: net payments not discounted {:18.2}", net.iter().sum::<f64>());
    let wrong_par: f64 = N * (0.042 - K) * d[1] + swaps.iter().map(|&(n, s)| N * (s - K) * d[n]).sum::<f64>();
    println!("wrong: par quotes used as forwards {:18.2}", wrong_par);
    println!("wrong: note at par, bond no principal {:15.2}", N - fixed_coupons);
    let at_par: f64 = (0..YEARS).map(|i| N * (f[i] - 0.0465) * d[i + 1]).sum();
    println!("try: fixed rate 4.65%, strip       {:18.2}", (at_par * 100.0).round() / 100.0 + 0.0);
    println!("try: receive fixed instead         {:18.2}", -road2);
    let (du, dd) = (curve(&swaps, 0.0001), curve(&swaps, -0.0001));   // every quote up, and down, 1 bp
    let (up, down) = (strip(&du) - road2, strip(&dd) - road2);
    println!("all quotes up 1 bp, change         {:18.2}", up);
    println!("all quotes down 1 bp, change       {:18.2}", down);
    println!("DV01, (up - down) / 2              {:18.2}", (up - down) / 2.0);
    println!("tree sigma 1% to 2%, change        {:18.2}", ((road3b - road3) * 100.0).round() / 100.0 + 0.0);

    assert!((road1 - road2).abs() < 1e-6, "two bonds and the strip of forwards agree");
    assert!((road3 - road2).abs() < 1e-4 && (road3b - road2).abs() < 1e-4, "the rate tree lands on the strip");
    assert!(layers[2].0.iter().all(|v| (v - N).abs() < 1e-4), "the note is worth par at every year-2 reset");
    assert!((float_leg - N * (1.0 - d[5])).abs() < 1e-6, "forwards telescope to N(1 - D5)");
    assert!((layers[0].1[0] - fixed_bond).abs() < 1e-4, "the tree reprices the fixed bond");
    assert!(((1.0 - d[5]) / a - 0.0465).abs() < 1e-12, "the curve reprices the 5-year par quote");
    assert!(((1.0 - du[5]) / du[1..].iter().sum::<f64>() - 0.0466).abs() < 1e-12, "the bumped curve reprices the bumped quote");
    assert!(up > 0.0 && 0.0 > down && (up + down).abs() < 0.01 * up, "payer gains as rates rise, nearly linearly");
    println!("ALL CHECKS PASS");
}
