// Constant-product pool and loss-versus-rebalancing: the check behind the card.
// std only. Roads: closed forms; the arbitrageur's best trade found by ternary
// search; gamma by finite differences; the daily loss by Simpson's rule over the
// bell curve; a simulated year of daily arbitrage. Output matches the Python.
const X0: f64 = 10.0;
const Y0: f64 = 600000.0;
const P0: f64 = 60000.0;
const SIG: f64 = 0.80;
const K: f64 = X0 * Y0;
const MASK: u64 = 0xFFFFFFFFFFFFFFFF;

fn v(p: f64) -> f64 { 2.0 * (K * p).sqrt() } // pool value once arbitrage sets its price to p
fn hold(p: f64) -> f64 { X0 * p + Y0 } // value of simply holding the deposit
fn lvr_step(val: f64, r: f64) -> f64 { val / 2.0 * (r.sqrt() - 1.0).powi(2) } // one jump of ratio r
fn sci(x: f64, d: usize) -> String { // Python-style 1.2345e-05
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        let mut s = self.0;
        s ^= (s << 13) & MASK; s ^= s >> 7; s ^= (s << 17) & MASK;
        self.0 = s;
        ((s >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

// mean LVR and s.e.; mean LVR and IL at `marks` even times; IL s.e.
fn year(rng: &mut Rng, steps: usize, paths: usize, marks: usize) -> (f64, f64, Vec<f64>, Vec<f64>, f64) {
    let (mut tot, mut tot2, mut il2) = (0.0, 0.0, 0.0);
    let (mut lv, mut il) = (vec![0.0; marks], vec![0.0; marks]);
    let (e, every) = (SIG * (1.0 / steps as f64).sqrt(), steps / marks);
    let n = paths as f64;
    for _ in 0..paths {
        let (mut p, mut loss) = (P0, 0.0);
        for i in 1..=steps {
            let u1 = rng.unif();
            let u2 = rng.unif();
            let z = (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos();
            let pn = p * (-e * e / 2.0 + e * z).exp();
            loss += (K / p).sqrt() * (pn - p) - (v(pn) - v(p)); // rebalancer minus pool
            p = pn;
            if i % every == 0 { // IL: held minus pool, unhedged
                lv[i / every - 1] += loss / n;
                il[i / every - 1] += (hold(p) - v(p)) / n;
            }
        }
        tot += loss;
        tot2 += loss * loss;
        il2 += (hold(p) - v(p)) * (hold(p) - v(p));
    }
    let (m, mi) = (tot / n, il[marks - 1]);
    (m, ((tot2 / n - m * m) / n).sqrt(), lv, il, ((il2 / n - mi * mi) / n).sqrt())
}

fn main() {
    println!("pool: k = {:.0}, price {:.0}, value {:.0}", K, P0, v(P0));

    // ---- road 1 against road 2: holdings after the move to 66,000 ----
    let p1 = 66000.0;
    let (x1, y1) = ((K / p1).sqrt(), (K * p1).sqrt());
    let profit = |d: f64| d * p1 - (K / (X0 - d) - Y0); // arbitrageur buys d BTC, pays the pool
    let (mut lo, mut hi) = (0.0, X0 - 1e-9);
    for _ in 0..200 {
        let a = lo + (hi - lo) / 3.0;
        let b = hi - (hi - lo) / 3.0;
        if profit(a) < profit(b) { lo = a } else { hi = b }
    }
    let d = (lo + hi) / 2.0;
    let paid = K / (X0 - d) - Y0;
    println!("after 66000: formula x = {:.4} BTC, y = {:.0} USDC", x1, y1);
    println!("after 66000: arbitrage search x = {:.4} BTC, pays {:.0} USDC for {:.4} BTC", X0 - d, paid, d);
    println!("arbitrageur's average price {:.0}, profit {:.0}", paid / d, profit(d));
    assert!((X0 - d - x1).abs() < 1e-6 && (profit(d) - lvr_step(v(P0), p1 / P0)).abs() < 1e-6);
    let (v1, h1) = (v(p1), hold(p1));
    println!("pool value {:.0}, held {:.0}, loss {:.0} = {:.3}%", v1, h1, h1 - v1, 100.0 * (1.0 - v1 / h1));
    let r = p1 / P0;
    assert!(((1.0 - v1 / h1) - (1.0 - 2.0 * r.sqrt() / (1.0 + r))).abs() < 1e-12); // ratio form
    assert!((v1 - (x1 * p1 + y1)).abs() < 1e-6 && v1 < h1); // AM-GM

    // ---- delta and gamma: derivative formulas against finite differences ----
    let h = 1.0;
    let dfd = (v(P0 + h) - v(P0 - h)) / (2.0 * h);
    let gfd = (v(P0 + h) - 2.0 * v(P0) + v(P0 - h)) / (h * h);
    let g = -X0 / (2.0 * P0);
    println!("delta {:.6} BTC (holdings {:.6}); gamma {} per USD (formula {})", dfd, X0, sci(gfd, 4), sci(g, 4));
    assert!((dfd - X0).abs() < 1e-6 && (gfd - g).abs() < 1e-8);
    let rent = 0.5 * g.abs() * SIG * SIG * P0 * P0;
    println!("rent 1/2|gamma|sigma^2 P^2 = {:.0} USD a year = {:.2}% of value, {:.2} a day", rent, 100.0 * rent / v(P0), rent / 365.0);
    assert!((rent / v(P0) - SIG * SIG / 8.0).abs() < 1e-12);
    for s in [0.4f64, 0.8, 1.2] {
        println!("sigma {:.0}%: LVR rate {:.2}% a year = {:.0} USD", 100.0 * s, 100.0 * s * s / 8.0, s * s / 8.0 * v(P0));
    }
    println!("fee break-even at 0.30%: volume {:.0} a year, {:.0} a day", rent / 0.003, rent / 0.003 / 365.0);

    // ---- one day's expected loss: Simpson's rule over the bell curve ----
    let dt = 1.0 / 365.0;
    let f = |z: f64| ((-SIG * SIG * dt / 2.0 + SIG * dt.sqrt() * z).exp().sqrt() - 1.0).powi(2)
        * (-z * z / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt();
    let (n, a) = (4000usize, 10.0);
    let w = 2.0 * a / n as f64;
    let mut q = 0.0;
    for i in 0..=n {
        let c = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        q += c * f(-a + i as f64 * w);
    }
    q *= w / 3.0;
    let qx = 2.0 * (1.0 - (-SIG * SIG * dt / 8.0).exp());
    println!("day: Simpson E[(sqrtR-1)^2] = {}, exact {}, sigma^2 dt/4 = {}", sci(q, 8), sci(qx, 8), sci(SIG * SIG * dt / 4.0, 8));
    assert!((q - qx).abs() < 1e-12);
    println!("day one expected LVR {:.2} USD", v(P0) / 2.0 * q);
    let exact = v(P0) * (1.0 - (-SIG * SIG / 8.0).exp());
    println!("one year expected LVR {:.0} (rate times starting value {:.0})", exact, SIG * SIG / 8.0 * v(P0));

    // ---- round trip 60,000 -> 66,000 -> 60,000 ----
    let (up, dn) = (lvr_step(v(P0), r), lvr_step(v(p1), P0 / p1));
    println!("round trip: up {:.0}, down {:.0}, LVR {:.0}; held-vs-pool loss at the end {:.0}", up, dn, up + dn, hold(P0) - v(P0));
    let reb = (X0 - x1) * p1 - (X0 - x1) * P0; // rebalancer sells at 66,000, buys back at 60,000
    assert!((reb - (up + dn)).abs() < 1e-6);

    // ---- simulated year: arbitrage every step, zero drift ----
    let mut rng = Rng(88172645463325252);
    let (m, se, lv, il, seil) = year(&mut rng, 365, 2000, 5);
    println!("simulated year, daily: mean LVR {:.0} (s.e. {:.0}), exact {:.0}", m, se, exact);
    println!("simulated year, daily: mean impermanent loss at the end {:.0} (s.e. {:.0})", il[4], seil);
    assert!((m - exact).abs() < 4.0 * se);
    assert!((il[4] - exact).abs() < 4.0 * seil); // unhedged LP: on average IL equals LVR
    let (mw, sew, _, _, _) = year(&mut rng, 52, 2000, 1);
    println!("simulated year, weekly: mean LVR {:.0} (s.e. {:.0})", mw, sew);
    assert!((mw - exact).abs() < 4.0 * sew);

    // ---- what breaks, try changing, chart ----
    let v0 = v(P0);
    println!("breaks: sigma^2/2 -> {:.0}; sigma^2/4 -> {:.0}; sigma/8 -> {:.0}", SIG * SIG / 2.0 * v0, SIG * SIG / 4.0 * v0, SIG / 8.0 * v0);
    println!("try: jump to 120000: IL {:.2}%, one-jump LVR {:.0}", 100.0 * (1.0 - v(120000.0) / hold(120000.0)), lvr_step(v0, 2.0));
    println!("try: jump to 30000: IL {:.2}%, one-jump LVR {:.0}", 100.0 * (1.0 - v(30000.0) / hold(30000.0)), lvr_step(v0, 0.5));
    let ps: Vec<f64> = (3..=12).map(|i| i as f64 * 10000.0).collect();
    let pool: Vec<String> = ps.iter().map(|&p| format!("{:.0}", v(p) / 1000.0)).collect();
    let held: Vec<String> = ps.iter().map(|&p| format!("{:.0}", hold(p) / 1000.0)).collect();
    println!("chart pool (thousand USD): {}", pool.join(", "));
    println!("chart held (thousand USD): {}", held.join(", "));
    let form: Vec<f64> = (0..5).map(|j| v0 * (1.0 - (-SIG * SIG * (j + 1) as f64 / 5.0 / 8.0).exp())).collect();
    for (name, ys) in [("formula", &form), ("mean LVR", &lv), ("mean IL", &il)] { // year in fifths
        let cells: Vec<String> = ys.iter().map(|y| format!("{:.1}", y / 1000.0)).collect();
        println!("chart {} (thousand USD): 0.0, {}", name, cells.join(", "));
    }
    println!("ALL CHECKS PASS");
}
