// Banach's fixed point theorem -- the same check as the Python, in Rust.  No crates.
// Four cafes reset their coffee prices each morning: half their own target price,
// plus half the average of the other three cafes' prices.  Prices are in cents.
// Road one runs the passes exactly (prices times 6^n are whole numbers).  Road two
// solves for the settled prices by the closed form.  Road three predicts every
// error from the rule's two shrink rates, 1/2 and -1/6.  The theorem's bound is
// then set beside the true error.  Exact numbers print by integer rounding.
const TGT: [i128; 4] = [280, 315, 350, 420]; // each cafe's target price, cents
const P0: [i128; 4] = [300, 300, 300, 300]; // today's prices, cents

fn fmt(num: i128, den: i128, k: u32) -> String {
    // num/den to k decimals, half rounded up
    let s = if num < 0 { "-" } else { "" };
    let t = 10i128.pow(k);
    let v = (num.abs() * t * 2 + den) / (2 * den);
    if k == 0 { format!("{}{}", s, v) } else { format!("{}{}.{:0w$}", s, v / t, v % t, w = k as usize) }
}

fn step(p: &[i128; 4], d: i128) -> ([i128; 4], i128) {
    // one pass on prices p/d; returns new p, new d = 6d
    let s: i128 = p.iter().sum();
    let mut out = [0i128; 4];
    for i in 0..4 { out[i] = 3 * TGT[i] * d + s - p[i]; }
    (out, 6 * d)
}

fn dist(a: &[i128; 4], b: &[i128; 4]) -> i128 {
    // worst-case distance d_inf between two lists
    (0..4).map(|i| (a[i] - b[i]).abs()).max().unwrap()
}

fn times(p: &[i128; 4], k: i128) -> [i128; 4] { [p[0] * k, p[1] * k, p[2] * k, p[3] * k] }

fn rnd(st: &mut u64) -> u64 {
    // SplitMix64
    *st = st.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *st;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn ratio(p: &[i128; 4], r: &[i128; 4]) -> (i128, i128) {
    // d(Tp, Tr) / d(p, r) as (num, den)
    (dist(&step(p, 1).0, &step(r, 1).0), 6 * dist(p, r))
}

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a } else { gcd(b, a % b) } }

fn main() {
    // ---- road two: the settled prices, (3 c_i + sum of targets) / 7 ----
    let st_sum: i128 = TGT.iter().sum();
    for t in TGT { assert!((3 * t + st_sum) % 7 == 0); }
    let ps: [i128; 4] = [0, 1, 2, 3].map(|i| (3 * TGT[i] + st_sum) / 7);
    assert!(step(&ps, 1).0 == times(&ps, 6)); // the rule leaves them unchanged
    println!("settled prices (3 c + {}) / 7, cents: {}, {}, {}, {}", st_sum, ps[0], ps[1], ps[2], ps[3]);

    // ---- the contraction constant: a formula, 1000 random pairs, one bad pair ----
    let mut st: u64 = 2026;
    let (mut bn, mut bd) = (0i128, 1i128);
    for _ in 0..1000 {
        let p = [0; 4].map(|_: i128| 200 + (rnd(&mut st) % 301) as i128);
        let r = [0; 4].map(|_: i128| 200 + (rnd(&mut st) % 301) as i128);
        if p != r {
            let (n, d) = ratio(&p, &r);
            if n * bd > bn * d { bn = n; bd = d; }
        }
    }
    assert!(2 * bn <= bd); // no pair shrinks by less than half
    let (sn, sd) = ratio(&P0.map(|x| x + 10), &P0);
    assert!(2 * sn == sd); // an even shift shrinks by exactly half
    let (on, od) = ratio(&[310, 290, 300, 300], &P0);
    println!("q by formula: 1/2 x (3 x 1/3) = 1/2; worst of 1000 random pairs: {}", fmt(bn, bd, 6));
    println!("even 10-cent shift: ratio {}; pair (310, 290, 300, 300): ratio {}", fmt(sn, sd, 6), fmt(on, od, 6));

    // ---- the passes, the true error, and the theorem's two bounds ----
    let (mut p, mut d) = (P0, 1i128);
    let mut prev: Option<[i128; 4]> = None;
    let d01 = dist(&step(&P0, 1).0, &times(&P0, 6)); // first step, times 6
    println!("first step d(p1, p0) = {} cents; first-step bound = {} / 2^n cents", fmt(d01, 6, 2), fmt(d01, 3, 0));
    println!("n, p_n (cents), true error, first-step bound, last-step bound");
    let (mut nf, mut nl, mut nt) = (None, None, None);
    let (mut le, mut lb, mut e5) = (vec![], vec![], String::new());
    for n in 0..21u32 {
        let e: [i128; 4] = [0, 1, 2, 3].map(|i| p[i] - ps[i] * d);
        for i in 0..4 {
            // road three: 1/2 and -1/6 rates
            let z = P0[i] - ps[i];
            let sg = if n % 2 == 0 { 1 } else { -1 };
            assert!(4 * e[i] == -165 * 3i128.pow(n) + sg * (4 * z + 165));
        }
        let err = e.iter().map(|x| x.abs()).max().unwrap();
        assert!(err * 3 * 2i128.pow(n) <= d01 * d); // first-step bound holds
        let last = prev.map(|q| dist(&p, &times(&q, 6)));
        if let Some(l) = last { assert!(err <= l); } // last-step bound holds (q/(1-q) = 1)
        if nf.is_none() && d01 <= 3 * 2i128.pow(n) { nf = Some(n); }
        if nl.is_none() && last.map_or(false, |l| l <= d) { nl = Some(n); }
        if nt.is_none() && err <= d { nt = Some(n); }
        if n == 5 { e5 = fmt(err, d, 4); }
        if n <= 10 {
            let ls = match last { Some(l) => fmt(l, d, 4), None => "-".to_string() };
            let pr: Vec<String> = p.iter().map(|&x| fmt(x, d, 2)).collect();
            println!("{}, {}, {}, {}, {}", n, pr.join(" "), fmt(err, d, 4), fmt(d01, 3 * 2i128.pow(n), 4), ls);
            le.push(format!("{:.2}", (err as f64 / d as f64).log10()));
            lb.push(format!("{:.2}", (d01 as f64 / 3.0 / 2f64.powi(n as i32)).log10()));
        }
        let nx = step(&p, d);
        prev = Some(p);
        p = nx.0;
        d = nx.1;
    }
    println!("within 1 cent: promised by first-step bound at n = {}, by last-step bound at n = {}, true at n = {}",
             nf.unwrap(), nl.unwrap(), nt.unwrap());
    println!("chart, log10 true error: {}", le.join(", "));
    println!("chart, log10 first-step bound: {}", lb.join(", "));

    // ---- what breaks ----
    let q6 = fmt(d01, 5 * 6i128.pow(5), 4); // (1/6)^5 / (5/6) x first step
    println!("trusting the one pair, q = 1/6: 'bound' at n = 5 is {} cents; true error {}", q6, e5);
    let mut m = P0;
    for _ in 0..10 {
        let s: i128 = m.iter().sum();
        m = m.map(|x| (s - x) / 3 + 10); // match the rivals' average, plus 10
    }
    assert!(m == [400; 4]);
    println!("rivals' average plus 10 cents, q = 1: after 10 passes {}, {}, {}, {} and climbing", m[0], m[1], m[2], m[3]);
    let (mut a, mut b) = (1i128, 1i128);
    let mut gaps = vec![];
    for _ in 0..4 {
        // x/2 + 1/x on the fractions in [1, 2]
        let (mut a2, mut b2) = (a * a + 2 * b * b, 2 * a * b);
        let g = gcd(a2, b2);
        a2 /= g;
        b2 /= g;
        gaps.push(((a2 * b - a * b2).abs(), b * b2));
        a = a2;
        b = b2;
    }
    for w in gaps.windows(2) { assert!(2 * w[1].0 * w[0].1 <= w[0].0 * w[1].1); } // each gap at most half the last
    println!("fractions only: x4 = {}/{}, x4^2 - 2 = {}/{}; the limit is sqrt 2, not a fraction", a, b, a * a - 2 * b * b, b * b);
    let mut w = 1.0f64;
    for _ in 0..1000 { w += 1.0 / w; } // x + 1/x on [1, infinity): every gap shrinks
    assert!(w * w >= 2001.0); // x_n^2 >= 1 + 2n: it never settles
    println!("x + 1/x from 1: x_1000 = {:.4}, still climbing; gap 100 to 101 shrinks to {:.6}", w, (101.0 + 1.0 / 101.0) - (100.0 + 1.0 / 100.0));

    // ---- curves: Picard's map for y' = y on [0, 1/2] halves the largest gap ----
    let ex = 0.5f64.exp();
    let (mut s, mut term) = (0.0f64, 1.0f64);
    for k in 1..30 { s += term; term = term * 0.5 / k as f64; }
    assert!((s - ex).abs() < 1e-15); // e^(1/2) two ways
    let fact = |n: i128| (1..=n).product::<i128>();
    let mut row = vec![];
    for n in 1..7i128 {
        let num: i128 = (0..=n).map(|k| 2i128.pow((n - k) as u32) * fact(n) / fact(k)).sum();
        let err = ex - num as f64 / (2i128.pow(n as u32) * fact(n)) as f64; // largest gap sits at t = 1/2
        let bound = 0.5f64.powi(n as i32);
        assert!(0.0 < err && err <= bound); // bound: q^n / (1 - q) x d(y1, y0)
        row.push(format!("{:.8} <= {:.8}", err, bound));
    }
    println!("e^(1/2) = {:.10}; Picard error, bound, n = 1..6:", ex);
    println!("{}", row[..3].join("; "));
    println!("{}", row[3..].join("; "));
    println!("ALL CHECKS PASS");
}
