// Digital inverses -- the same check as digital_inverses_vol_and_strike_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x) is
// built by adding thin slices under the curve (Simpson); the quantile is Newton.
use std::f64::consts::PI;

const S: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<G: Fn(f64) -> f64>(g: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {
    if x.abs() > 5.0 { return if x > 0.0 { 1.0 } else { 0.0 }; } // same cut as the Python, for the scan
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn n_inv(p: f64) -> f64 {
    let mut x = 0.0;
    for _ in 0..60 { x -= (n_cdf(x) - p) / phi(x); }
    x
}

fn d() -> f64 { (-R * T).exp() }
fn fwd() -> f64 { S * ((R - Q) * T).exp() }

fn cash(k: f64, sig: f64) -> f64 {
    let w = sig * T.sqrt();
    d() * n_cdf(((fwd() / k).ln() - 0.5 * w * w) / w)
}

fn vols_quadratic(v: f64, k: f64) -> Vec<f64> {           // Road 1
    let (z, m) = (n_inv(v / d()), (fwd() / k).ln());
    let disc = z * z + 2.0 * m;
    if disc < 0.0 { return vec![]; }
    let big = -z - if z >= 0.0 { 1.0 } else { -1.0 } * disc.sqrt();
    let mut roots = if big != 0.0 { vec![big, -2.0 * m / big] } else { vec![0.0] };
    roots.retain(|w| *w > 0.0);
    roots.sort_by(|a, b| a.partial_cmp(b).unwrap());
    roots.dedup();
    roots.iter().map(|w| w / T.sqrt()).collect()
}

fn vols_scan(v: f64, k: f64) -> Vec<f64> {                // Road 2
    let f = |s: f64| cash(k, s) - v;
    let mut found = vec![];
    for i in 0..299 {
        let (mut a, mut b) = (0.005 + 0.01 * i as f64, 0.005 + 0.01 * (i + 1) as f64);
        if f(a) * f(b) < 0.0 {
            for _ in 0..60 {
                let mid = 0.5 * (a + b);
                if f(a) * f(mid) <= 0.0 { b = mid; } else { a = mid; }
            }
            found.push(0.5 * (a + b));
        }
    }
    found
}

fn rule(v: f64, k: f64) -> usize {
    let (z, m) = (n_inv(v / d()), (fwd() / k).ln());
    if m > 0.0 { return 1; }
    if m == 0.0 { return if z < 0.0 { 1 } else { 0 }; }
    let kk = (-2.0 * m).sqrt();
    if z < -kk { 2 } else if z == -kk { 1 } else { 0 }
}

fn density_price(k: f64, sig: f64) -> f64 {               // Road 3
    let w = sig * T.sqrt();
    let c = fwd().ln() - 0.5 * w * w;
    d() * simpson(|u| phi((u - c) / w) / w, k.ln(), c + 12.0 * w, 4000)
}

fn strike_closed(v: f64, sig: f64) -> f64 {
    let (w, z) = (sig * T.sqrt(), n_inv(v / d()));
    fwd() * (-w * z - 0.5 * w * w).exp()
}

fn strike_bisect(v: f64, sig: f64) -> f64 {
    let (mut lo, mut hi) = (50.0_f64, 200.0_f64);
    for _ in 0..100 {
        let mid = (lo * hi).sqrt();
        if cash(mid, sig) > v { lo = mid; } else { hi = mid; }
    }
    (lo * hi).sqrt()
}

fn main() {
    let (dd, f) = (d(), fwd());
    let v = cash(100.0, 0.20);
    let (w1, w2, k1) = (vols_quadratic(v, 100.0), vols_scan(v, 100.0), strike_closed(v, 0.20));
    let v110 = cash(110.0, 0.20);
    let (r110, s110) = (vols_quadratic(v110, 110.0), vols_scan(v110, 110.0));
    let m110 = (f / 110.0).ln();
    let k110 = (-2.0 * m110).sqrt();
    let z_one = n_inv(v);
    let rows: Vec<(&str, f64)> = vec![
        ("discount D = e^-rT", dd), ("forward F = S e^(r-q)T", f), ("quote V, house cash digital", v),
        ("normalised quote y = V/D", v / dd), ("z = N^-1(y)", n_inv(v / dd)), ("m = ln(F/K), K = 100", (f / 100.0).ln()),
        ("1 vol by quadratic", w1[0]), ("  its other root, discarded", -2.0 * (f / 100.0).ln() / w1[0]),
        ("2 vol by scan and bisection", w2[0]),
    ];
    for (name, x) in &rows { println!("{:<40} {:>12.6}", name, x); }
    println!("{:<40} {:>12}", "  roots the scan found", w2.len());
    let rows2: Vec<(&str, f64)> = vec![
        ("3 price at that vol, by integral", density_price(100.0, w1[0])),
        ("1 strike, closed form", k1), ("2 strike, bisection", strike_bisect(v, 0.20)),
        ("3 price at that strike, by integral", density_price(k1, 0.20)),
        ("K = 110: m", m110), ("K = 110: quote at 20%", v110), ("K = 110: z", n_inv(v110 / dd)),
        ("K = 110: small root", r110[0]), ("K = 110: large root", r110[1]), ("K = 110: roots multiply to -2m", -2.0 * m110),
        ("K = 110: scan, small", s110[0]), ("K = 110: scan, large", s110[1]),
        ("K = 110: price at large root, integral", density_price(110.0, r110[1])),
        ("K = 110: turning vol sqrt(-2m)", k110), ("K = 110: top quote D N(-k)", dd * n_cdf(-k110)),
        ("m = 0 ceiling, D/2", 0.5 * dd), ("K where 20% is the turn, F e^(w^2/2)", f * 0.02_f64.exp()),
        ("wrong: normalised by $1", -z_one + (z_one * z_one + 0.06).sqrt()),
        ("wrong: spot for forward, strike", S * (-0.2 * n_inv(v / dd) - 0.02).exp()),
        ("try: K = 120, large root", vols_quadratic(cash(120.0, 0.2), 120.0)[1]),
        ("try: strike for a $0.25 quote", strike_closed(0.25, 0.20)),
        ("try: strike from the put 0.456648", strike_closed(dd - 0.456648, 0.20)),
        ("  house digital put D - V", dd - v),
    ];
    for (name, x) in &rows2 { println!("{:<40} {:>12.6}", name, x); }
    let za = n_inv(v / dd);
    println!("{:<40} {:>12}", "wrong: d1 formula, real roots", if za * za - 0.06 < 0.0 { "none" } else { "some" });
    println!();
    let cases = [(100.0, v), (90.0, 0.70), (f, 0.40), (f, 0.48), (110.0, 0.25), (110.0, 0.34), (110.0, 0.35)];
    for (k, vq) in cases {
        let (a, b, c) = (rule(vq, k), vols_quadratic(vq, k).len(), vols_scan(vq, k).len());
        println!("count  K {:7.2}  quote {:.6}   rule {}  quadratic {}  scan {}", k, vq, a, b, c);
        assert!(a == b && b == c, "moneyness rule, quadratic and scan must agree on the count");
    }
    println!();
    let sigs: Vec<f64> = (1..=10).map(|i| 0.1 * i as f64).collect();
    let line = |label: &str, g: &dyn Fn(f64) -> f64, p: usize| {
        let body: String = sigs.iter().map(|s| format!("{:7.*}", p, g(*s))).collect();
        println!("{:<22}{}", label, body);
    };
    line("chart, vol %", &|s| 100.0 * s, 0);
    line("chart, K 100 cents", &|s| 100.0 * cash(100.0, s), 2);
    line("chart, K 110 cents", &|s| 100.0 * cash(110.0, s), 2);
    line("chart, quote cents", &|_| 100.0 * v110, 2);
    println!("figure, K 100 crossing   w {:.4}  z {:.4}", w1[0], n_inv(v / dd));
    println!("figure, K 110 crossings  w {:.4} and {:.4}  z {:.4}", r110[0], r110[1], n_inv(v110 / dd));
    println!("figure, K 110 peak       w {:.4}  z {:.4}", k110, -k110);

    assert!((v - 0.494581).abs() < 5e-7, "house cash digital, as quoted on the shelf");
    assert!(w2.len() == 1 && (w1[0] - w2[0]).abs() < 1e-9, "K = 100: one vol, quadratic vs scan");
    assert!(s110.len() == 2 && r110.iter().zip(&s110).all(|(a, b)| (a - b).abs() < 1e-9), "K = 110: two vols");
    assert!((density_price(110.0, r110[1]) - v110).abs() < 1e-9, "the second vol reprices the same quote");
    assert!((k1 - strike_bisect(v, 0.20)).abs() < 1e-6 && (k1 - 100.0).abs() < 1e-6, "strike: closed form vs bisection");
    let top = (0..1200).map(|i| cash(110.0, 0.3 + 1e-4 * i as f64)).fold(0.0_f64, f64::max);
    assert!((top - dd * n_cdf(-k110)).abs() < 1e-8, "K = 110: scanned top quote is D N(-k)");
    println!("ALL CHECKS PASS");
}
