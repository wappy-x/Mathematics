// Greeks of a futures option (Black-76), Brent house example. Rust std only, no crates.
use std::f64::consts::PI;

fn n_cdf(x: f64) -> f64 { // normal CDF from its own series: erf(z) = 2/sqrt(pi) e^-z^2 sum 2^n z^(2n+1)/(1*3*..*(2n+1))
    let z = x.abs() / 2f64.sqrt();
    let e = if z > 6.0 { 1.0 } else {
        let (mut term, mut total, mut n) = (z, z, 0.0);
        while term > 1e-17 * total {
            n += 1.0;
            term *= 2.0 * z * z / (2.0 * n + 1.0);
            total += term;
        }
        2.0 / PI.sqrt() * (-z * z).exp() * total
    };
    if x >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn d12(f: f64, k: f64, s: f64, t: f64) -> (f64, f64) {
    let d1 = ((f / k).ln() + 0.5 * s * s * t) / (s * t.sqrt());
    (d1, d1 - s * t.sqrt())
}
fn b76(f: f64, k: f64, r: f64, s: f64, t: f64) -> f64 { // premium-paid call, dollars per barrel
    let (d1, d2) = d12(f, k, s, t);
    (-r * t).exp() * (f * n_cdf(d1) - k * n_cdf(d2))
}
fn greeks(f: f64, k: f64, r: f64, s: f64, t: f64) -> [f64; 5] { // delta, gamma, vega, theta (per year), rho
    let (d1, _) = d12(f, k, s, t);
    let dd = (-r * t).exp();
    let v = b76(f, k, r, s, t);
    [dd * n_cdf(d1), dd * phi(d1) / (f * s * t.sqrt()), dd * f * phi(d1) * t.sqrt(),
     r * v - dd * f * phi(d1) * s / (2.0 * t.sqrt()), -t * v]
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17;
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn main() {
    let (f, k, r, s, t, lot) = (85.0f64, 85.0f64, 0.05f64, 0.30f64, 0.5f64, 1000.0f64);
    let (d1, d2) = d12(f, k, s, t);
    let dd = (-r * t).exp();
    let v = b76(f, k, r, s, t);
    let [dl, ga, ve, th, rh] = greeks(f, k, r, s, t);
    let h = 1e-3; // road 2: bump and reprice
    let dl_b = (b76(f + h, k, r, s, t) - b76(f - h, k, r, s, t)) / (2.0 * h);
    let ga_b = (b76(f + 0.1, k, r, s, t) - 2.0 * v + b76(f - 0.1, k, r, s, t)) / 0.01;
    let ve_b = (b76(f, k, r, s + h, t) - b76(f, k, r, s - h, t)) / (2.0 * h);
    let th_b = -(b76(f, k, r, s, t + h) - b76(f, k, r, s, t - h)) / (2.0 * h);
    let rh_b = (b76(f, k, r + h, s, t) - b76(f, k, r - h, s, t)) / (2.0 * h);
    let q = |f_: f64, r_: f64| b76(f_, k, r_, s, t) / (-r_ * t).exp(); // margined quote: nothing paid up front
    let qdl_b = (q(f + h, r) - q(f - h, r)) / (2.0 * h);
    let qrh_b = (q(f, r + h) - q(f, r - h)) / (2.0 * h);
    let qth = -f * phi(d1) * s / (2.0 * t.sqrt());
    // road 3: Simpson integral over the lognormal, above the strike only (no kink inside)
    let zs = ((k / f).ln() + 0.5 * s * s * t) / (s * t.sqrt());
    let m = 4000usize;
    let w = (8.0 - zs) / m as f64;
    let (mut v_int, mut dl_int) = (0.0f64, 0.0f64);
    for i in 0..=m {
        let z = zs + i as f64 * w;
        let c = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let ft = f * (-0.5 * s * s * t + s * t.sqrt() * z).exp();
        v_int += c * (ft - k) * phi(z);
        dl_int += c * (ft / f) * phi(z);
    }
    v_int *= dd * w / 3.0;
    dl_int *= dd * w / 3.0;
    // road 4: Acme, the house stock, priced on spot (Black-Scholes) and on its one-year future (Black-76)
    let (sp, ka, ra, qa, sa, ta) = (100.0f64, 100.0f64, 0.05f64, 0.02f64, 0.20f64, 1.0f64);
    let b1 = ((sp / ka).ln() + (ra - qa + 0.5 * sa * sa) * ta) / (sa * ta.sqrt());
    let b2 = b1 - sa * ta.sqrt();
    let c_bs = sp * (-qa * ta).exp() * n_cdf(b1) - ka * (-ra * ta).exp() * n_cdf(b2);
    let fa = sp * ((ra - qa) * ta).exp();
    let c_76 = b76(fa, ka, ra, sa, ta);
    let ga76 = greeks(fa, ka, ra, sa, ta);
    let spot_delta = (-qa * ta).exp() * n_cdf(b1);
    let stock_rho = ka * ta * (-ra * ta).exp() * n_cdf(b2);
    let chain_rho = ga76[4] + ga76[0] * ta * fa; // rho at fixed future + delta * dF/dr
    // road 5: sell the Brent call, hedge daily with futures, 2000 paths, own random numbers
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let (paths, steps) = (2000usize, 126usize);
    let dt = t / steps as f64;
    let mut acc = [[0.0f64; 2]; 3]; // plain, untailed N(d1), tailed e^-rT N(d1)
    let (mut u2, mut rad) = (0.0f64, 0.0f64);
    for _p in 0..paths {
        let (mut fp, mut g) = (f, [0.0f64; 3]);
        for kk in 0..steps {
            let tau = t - kk as f64 * dt;
            let nd = n_cdf(d12(fp, k, s, tau).0);
            let z = if kk % 2 == 0 {
                let u1 = rng.unif(); u2 = rng.unif(); rad = (-2.0 * u1.ln()).sqrt(); rad * (2.0 * PI * u2).cos()
            } else { rad * (2.0 * PI * u2).sin() };
            let fnext = fp * (-0.5 * s * s * dt + s * dt.sqrt() * z).exp();
            for (j, hr) in [0.0, nd, (-r * tau).exp() * nd].iter().enumerate() {
                g[j] = g[j] * (r * dt).exp() + hr * (fnext - fp);
            }
            fp = fnext;
        }
        for j in 0..3 {
            let x = (fp - k).max(0.0) - g[j];
            acc[j][0] += x; acc[j][1] += x * x;
        }
    }
    let est: Vec<(f64, f64)> = acc.iter().map(|a| {
        let mu = a[0] / paths as f64;
        let sd = (a[1] / paths as f64 - mu * mu).sqrt();
        (dd * mu, dd * sd / (paths as f64).sqrt())
    }).collect();
    let rows: [(&str, f64); 34] = [
        ("d1", d1), ("N(d1)", n_cdf(d1)), ("e^-rT", dd),
        ("1 formula V", v), ("2 Simpson integral V", v_int),
        ("delta formula", dl), ("delta bump", dl_b), ("delta integral", dl_int),
        ("delta in barrels, per option", dl * lot), ("gamma formula", ga), ("gamma bump", ga_b),
        ("vega per unit formula", ve), ("vega per unit bump", ve_b),
        ("vega per vol point, per barrel", ve / 100.0), ("vega per vol point, per lot", ve / 100.0 * lot),
        ("theta per year formula", th), ("theta per year bump", th_b),
        ("theta per day, per barrel", th / 365.0), ("theta per day, per lot", th / 365.0 * lot),
        ("rho per unit formula", rh), ("rho per unit bump", rh_b), ("rho per unit, per lot", rh * lot),
        ("rho per basis point, per lot", rh * lot / 1e4),
        ("margined quote V_m = V e^rT", v / dd), ("margined delta bump", qdl_b),
        ("margined theta per day, per barrel", qth / 365.0), ("margined rho bump", qrh_b),
        ("Acme Black-Scholes call", c_bs), ("Acme Black-76 on 1y future", c_76),
        ("Acme spot delta, shares", spot_delta), ("Acme futures delta, lots", ga76[0]),
        ("Acme stock rho", stock_rho), ("Acme -T C + delta T F", chain_rho),
        ("wrong: N(d1) lots, $ per $1 per lot", (n_cdf(d1) - dl) * lot),
    ];
    for (name, x) in rows.iter() { println!("{:<36} {:>13.6}", name, x); }
    println!("{:<36} {:>13.6}", "wrong: stock rho formula, Brent", k * t * dd * n_cdf(d2));
    println!("{:<36} {:>13.6}", "wrong: theta per year, per lot", th * lot);
    let a = dd * f * phi(d1);
    println!("hand: sigma sqrt T {:.6}  d2 {:.6}  N(d2) {:.6}  phi(d1) {:.6}", s * t.sqrt(), d2, n_cdf(d2), phi(d1));
    println!("hand: A = e^-rT F phi(d1) {:.6}  rV {:.6}  A sigma/(2 sqrt T) {:.6}  V per lot {:.6}", a, r * v, a * s / (2.0 * t.sqrt()), v * lot);
    let labs = ["3 sim V, no hedge", "3 sim V, N(d1) lots", "3 sim V, e^-rT N(d1) lots"];
    for (lab, (e, se)) in labs.iter().zip(est.iter()) { println!("{:<27} {:>9.6}  standard error {:.6}", lab, e, se); }
    let fs: Vec<f64> = (0..9).map(|i| 65.0 + 5.0 * i as f64).collect();
    let line = |vals: Vec<String>| vals.join(" ");
    println!("chart, Brent future  {}", line(fs.iter().map(|x| format!("{:6.0}", x)).collect()));
    println!("chart, V per barrel  {}", line(fs.iter().map(|&x| format!("{:6.2}", b76(x, k, r, s, t))).collect()));
    println!("chart, V + delta dF  {}", line(fs.iter().map(|&x| format!("{:6.2}", v + dl * (x - f))).collect()));
    for (lab, tt) in [("lots, 6m, paid", 0.5), ("lots, 3m, paid", 0.25), ("lots, 2w, paid", 1.0 / 26.0)] {
        println!("{:<20} {}", lab, line(fs.iter().map(|&x| format!("{:6.2}", greeks(x, k, r, s, tt)[0])).collect()));
    }
    let tl = [0.5, 1.0 / 3.0, 1.0 / 6.0, 1.0 / 12.0, 1.0 / 24.0, 1.0 / 52.0];
    println!("time left, F = 90   {}", line(tl.iter().map(|&x| format!("{:6.3}", greeks(90.0, k, r, s, x)[0])).collect()));
    for (mo, fm) in [(0, 85.0), (1, 88.0), (2, 93.0), (3, 87.0), (4, 80.0), (5, 84.0)] {
        let tt = (6 - mo) as f64 / 12.0;
        let g = greeks(fm, k, r, s, tt);
        println!("story month {}  F {:5.1}  V {:6.3}  lots {:6.4}  gamma {:6.4}", mo, fm, b76(fm, k, r, s, tt), g[0], g[1]);
    }
    assert!((v - 7.002679).abs() < 5e-7, "formula vs the shelf's house call 7.002679");
    assert!((v_int - v).abs() < 1e-8 && (dl_int - dl).abs() < 1e-8, "integral road lands on formula price and delta");
    assert!((dl_b - dl).abs() < 1e-8 && (ga_b - ga).abs() < 1e-6 && (ve_b - ve).abs() < 1e-5, "bumps match closed forms");
    assert!((th_b - th).abs() < 1e-5 && (rh_b - rh).abs() < 1e-6, "theta and rho = -T V by bumping");
    assert!((qdl_b - n_cdf(d1)).abs() < 1e-8 && qrh_b.abs() < 1e-8, "margined delta N(d1), margined rho zero");
    assert!((c_76 - 9.227005508154).abs() < 1e-9 && (chain_rho - stock_rho).abs() < 1e-9, "Acme both ways");
    assert!((est[2].0 - v).abs() < 3.0 * est[2].1 && est[2].1 < est[1].1 && est[1].1 < est[0].1 / 5.0, "hedged simulation");
    println!("ALL CHECKS PASS");
}
