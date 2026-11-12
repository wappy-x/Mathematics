// Auctions and mechanism design -- the check behind the card.  std only, no crates.
// Money in thousands of pounds.  Five firms; each value spread evenly between 0 and 100.
const N: usize = 5;
const TOP: f64 = 100.0;
const DAY: [(&str, f64); 5] = [("A", 82.0), ("B", 71.0), ("C", 64.0), ("D", 55.0), ("E", 40.0)];
const BETA: f64 = (N as f64 - 1.0) / N as f64; // first-price shading factor, derived on the card

fn top_two(xs: &[f64]) -> (f64, f64) { // largest and second largest, no sorting
    let (mut a, mut b) = (-1.0, -1.0);
    for &x in xs {
        if x > a { b = a; a = x; } else if x > b { b = x; }
    }
    (a, b)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut inner = 0.0;
    for i in 1..n { inner += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    (f(a) + f(b) + inner) * h / 3.0
}

fn p(v: f64) -> f64 { (v / TOP).powf(N as f64 - 1.0) } // chance a value v is the highest of five
fn m(v: f64, r: f64) -> f64 { // expected payment, any auction (envelope)
    if v >= r { v * p(v) - simpson(&p, r, v, 200) } else { 0.0 }
}
fn vick(v: f64, b: f64, c: f64) -> f64 { if b > c { v - c } else { 0.0 } } // c: highest rival bid
fn vick_exp(v: f64, b: f64) -> f64 { // rivals truthful: pay their highest when below b
    let c = b.min(TOP);
    simpson(&|y: f64| (v - y) * (N as f64 - 1.0) * y.powf(N as f64 - 2.0) / TOP.powf(N as f64 - 1.0), 0.0, c, 400)
}
fn fp_exp(v: f64, b: f64, beta: f64, rho: f64) -> f64 { // rivals bid beta x value; rho < 1 is risk aversion
    let w = (b / (beta * TOP)).min(1.0).powf(N as f64 - 1.0);
    if b < v { (v - b).powf(rho) * w } else { (v - b) * w }
}
fn argmax(xs: &[f64], f: &dyn Fn(f64) -> f64) -> f64 {
    let (mut best, mut fb) = (xs[0], f(xs[0]));
    for &x in &xs[1..] { let y = f(x); if y > fb { best = x; fb = y; } }
    best
}
fn best_total(skip: &str) -> f64 {
    let xs: Vec<f64> = DAY.iter().filter(|(k, _)| *k != skip).map(|&(_, v)| v).collect();
    let mut best = f64::MIN;
    for i in 0..xs.len() { for j in i + 1..xs.len() { best = best.max(xs[i] + xs[j]); } }
    best
}

struct SplitMix(u64);
impl SplitMix {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}

fn main() {
    let nf = N as f64;
    // ---- the day: five sealed bids ----
    let vals: Vec<f64> = DAY.iter().map(|&(_, v)| v).collect();
    let (hi, second) = top_two(&vals);
    let (fp_hi, _) = top_two(&vals.iter().map(|v| BETA * v).collect::<Vec<f64>>());
    println!("day, values:      {}", DAY.iter().map(|(k, v)| format!("{} {:.0}", k, v)).collect::<Vec<_>>().join("  "));
    println!("day, first-price bids at 0.8 v: {}", DAY.iter().map(|(k, v)| format!("{} {:.1}", k, BETA * v)).collect::<Vec<_>>().join("  "));
    println!("day, Vickrey: A wins, pays {:.2}, profit {:.2}", second, hi - second);
    println!("day, first-price: A wins, pays {:.2}, profit {:.2}", fp_hi, hi - fp_hi);

    // ---- road 1: closed forms ----
    let rev_v = (nf - 1.0) / (nf + 1.0) * TOP; // average second-highest of five: k/(n+1)
    let rev_f = BETA * nf / (nf + 1.0) * TOP; // 0.8 times the average highest
    let u82 = 82f64.powf(nf) / (nf * TOP.powf(nf - 1.0)); // area under P from 0 to 82
    println!("road 1, Vickrey revenue (n-1)/(n+1) x 100   {:.4}", rev_v);
    println!("road 1, first-price revenue 0.8 x n/(n+1) x 100 {:.4}", rev_f);
    println!("road 1, firm A: win chance P(82) {:.4}, profit U(82) {:.4}, payment m(82) {:.4}", p(82.0), u82, 82.0 * p(82.0) - u82);

    // ---- road 2: exhaustive grids and integrals ----
    let grid: Vec<f64> = (0..201).map(|i| 0.5 * i as f64).collect();
    let mut gap = f64::MAX;
    for &v in &[82.0, 60.0] { for &b in &grid { for &c in &grid { gap = gap.min(vick(v, v, c) - vick(v, b, c)); } } }
    println!("road 2, Vickrey: truth minus best other bid, worst case over {} cases {:.4}", 2 * grid.len() * grid.len(), gap);
    let fine: Vec<f64> = (0..10001).map(|i| 0.01 * i as f64).collect();
    let best_v = argmax(&grid, &|b| vick_exp(82.0, b));
    let best_f = argmax(&fine, &|b| fp_exp(82.0, b, BETA, 1.0));
    println!("road 2, firm A best bid: Vickrey {:.2} (profit {:.4}), first-price {:.2} (profit {:.4})",
             best_v, vick_exp(82.0, best_v), best_f, fp_exp(82.0, best_f, BETA, 1.0));
    let pay_v = simpson(&|y: f64| y * (nf - 1.0) * y.powf(nf - 2.0) / TOP.powf(nf - 1.0), 0.0, 82.0, 2000);
    println!("road 2, firm A expected payment: Vickrey {:.4}, first-price {:.4}", pay_v, best_f * p(best_f / BETA));
    let rev_env = nf * simpson(&|v| m(v, 0.0), 0.0, TOP, 400) / TOP;
    let rev_os = simpson(&|y: f64| y * nf * (nf - 1.0) * (y / TOP).powf(nf - 2.0) * (1.0 - y / TOP) / TOP, 0.0, TOP, 2000);
    println!("road 2, revenue: envelope integral {:.4}, second-highest integral {:.4}", rev_env, rev_os);
    let bids: Vec<f64> = (0..13).map(|i| 40.0 + 5.0 * i as f64).collect();
    println!("chart, bid      {}", bids.iter().map(|b| format!("{:6.0}", b)).collect::<Vec<_>>().join(" "));
    println!("chart, Vickrey  {}", bids.iter().map(|&b| format!("{:6.2}", vick_exp(82.0, b))).collect::<Vec<_>>().join(" "));
    println!("chart, first    {}", bids.iter().map(|&b| format!("{:6.2}", fp_exp(82.0, b, BETA, 1.0))).collect::<Vec<_>>().join(" "));

    // ---- road 3: simulation, SplitMix64 seed 20261111 ----
    let mut rng = SplitMix(20261111);
    let mm = 200000;
    println!("road 3, {} synthetic auctions of {} values, SplitMix64 seed {}", mm, N, rng.0);
    let names = ["Vickrey", "first-price", "all-pay", "Vickrey, reserve 50", "first-price, reserve 50"];
    let mut acc = [[0.0f64; 2]; 5];
    for _ in 0..mm {
        let vs: Vec<f64> = (0..N).map(|_| TOP * rng.unif()).collect();
        let (h, s) = top_two(&vs);
        let mut allpay = 0.0; // each bids m(v) = 0.8 v^5 / 100^4
        for &v in &vs { allpay += BETA * v.powf(nf) / TOP.powf(nf - 1.0); }
        let fp_res = if h >= 50.0 { h - (h.powf(nf) - 50f64.powf(nf)) / (nf * h.powf(nf - 1.0)) } else { 0.0 }; // bid v - (v^5 - 50^5) / (5 v^4)
        let xs = [s, BETA * h, allpay, if h >= 50.0 { s.max(50.0) } else { 0.0 }, fp_res];
        for k in 0..5 { acc[k][0] += xs[k]; acc[k][1] += xs[k] * xs[k]; }
    }
    let mut sim = [(0.0f64, 0.0f64); 5];
    for k in 0..5 {
        let mean = acc[k][0] / mm as f64;
        let sd = (acc[k][1] / mm as f64 - mean * mean).sqrt();
        sim[k] = (mean, sd / (mm as f64).sqrt());
        println!("road 3, {:<23} mean {:8.4}  sd {:7.4}  standard error {:.4}", names[k], mean, sd, sim[k].1);
    }

    // ---- what breaks, and the try-changing box ----
    let (rho, beta_r) = (0.5, (nf - 1.0) / (nf - 1.0 + 0.5));
    let best_r = argmax(&fine, &|b| fp_exp(82.0, b, beta_r, rho));
    println!("break, seller reads first-price bids as values: expects {:.4}", nf / (nf + 1.0) * TOP);
    println!("break, A bids its value 82 in first-price: profit {:.4}", fp_exp(82.0, 82.0, BETA, 1.0));
    println!("break, A shades to 65.6 in Vickrey today: {}, profit {:.2}", if 65.6 > 71.0 { "wins" } else { "loses" }, vick(82.0, 65.6, 71.0));
    println!("break, E (value 40) bids 90 in Vickrey today: profit {:.2}", vick(40.0, 90.0, 82.0));
    println!("break, risk-averse (square-root) first-price: A bids {:.2}, revenue {:.4}", best_r, beta_r * nf / (nf + 1.0) * TOP);
    let rev_res = nf * simpson(&|v| m(v, 50.0), 50.0, TOP, 400) / TOP;
    println!("try, reserve 50: envelope revenue {:.4}", rev_res);
    for &n in &[2.0f64, 10.0] {
        println!("try, {} firms: shading {:.2}, revenue {:.4}", n, (n - 1.0) / n, (n - 1.0) / (n + 1.0) * TOP);
    }
    // two identical contracts, one each at most: VCG = what each winner's presence costs the others
    for &(k, v) in &DAY[..2] {
        println!("VCG, two contracts: {} pays {:.2}", k, best_total(k) - (best_total("") - v));
    }

    assert!(gap >= 0.0, "truth is never beaten in Vickrey");
    assert!(best_v == 82.0 && (best_f - 65.6).abs() < 0.011, "grid best responses: 82 and 0.8 x 82");
    assert!((vick_exp(82.0, best_v) - u82).abs() < 1e-6 && (fp_exp(82.0, best_f, BETA, 1.0) - u82).abs() < 1e-3, "envelope profit");
    assert!((pay_v - (82.0 * p(82.0) - u82)).abs() < 1e-6, "Vickrey payment by integral vs envelope m(v)");
    assert!((rev_env - rev_v).abs() < 1e-6 && (rev_os - rev_v).abs() < 1e-6, "revenue equivalence, two integrals");
    assert!((0..3).all(|k| (sim[k].0 - rev_v).abs() < 4.0 * sim[k].1), "simulated revenues");
    assert!((3..5).all(|k| (sim[k].0 - rev_res).abs() < 4.0 * sim[k].1), "reserve price, both rules simulated vs envelope");
    assert!((best_r - 82.0 * beta_r).abs() < 0.011, "risk-averse best response 4v/4.5");
    println!("ALL CHECKS PASS");
}
