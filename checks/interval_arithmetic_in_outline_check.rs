// Interval arithmetic -- the same check as the Python, in Rust.  No crates.
// A footbridge support reaction from toleranced inputs, carried as intervals
// [lo, hi] with every endpoint rounded outward; then two long computations: the
// tracker's ten-million-step total and a solver update whose interval explodes.
type Iv = (f64, f64);
fn step(x: f64, d: i64) -> f64 {              // the neighbouring double: d = +1 up, -1 down
    if x == 0.0 { return d as f64 * 5e-324; }
    let b = x.to_bits() as i64;
    f64::from_bits((b + if x > 0.0 { d } else { -d }) as u64)
}
fn out(lo: f64, hi: f64) -> Iv { (step(lo, -1), step(hi, 1)) }   // round outward
fn add(x: Iv, y: Iv) -> Iv { out(x.0 + y.0, x.1 + y.1) }
fn sub(x: Iv, y: Iv) -> Iv { out(x.0 - y.1, x.1 - y.0) }
fn ends(p: [f64; 4]) -> Iv {
    out(p.iter().cloned().fold(f64::INFINITY, f64::min), p.iter().cloned().fold(f64::NEG_INFINITY, f64::max))
}
fn mul(x: Iv, y: Iv) -> Iv { ends([x.0 * y.0, x.0 * y.1, x.1 * y.0, x.1 * y.1]) }
fn div(x: Iv, y: Iv) -> Iv {
    assert!(y.0 > 0.0 || y.1 < 0.0, "divisor interval contains zero");
    ends([x.0 / y.0, x.0 / y.1, x.1 / y.0, x.1 / y.1])
}
fn iv(mid: f64, tol: f64) -> Iv { out(mid - tol, mid + tol) }
fn show(name: &str, x: Iv, d: usize) {
    println!("{:<36}[{:.d$}, {:.d$}]  width {:.d$}", name, x.0, x.1, x.1 - x.0, d = d);
}
fn dec6(num: i128, den: i128) -> String {
    let q = (2 * num * 1_000_000 + den) / (2 * den);
    format!("{}.{:06}", q / 1_000_000, q % 1_000_000)
}
fn ratio(x: f64) -> (u128, u32) {              // x = m / 2^k, for a normal 0 < x < 2^52
    let b = x.to_bits();
    ((b & ((1u64 << 52) - 1) | (1u64 << 52)) as u128, (1075 - ((b >> 52) & 0x7ff)) as u32)
}
fn main() {
    // ---- the footbridge: reaction at support A, R = P (L - a) / L ----
    let (cart, cargo) = (iv(30.0, 1.0), iv(20.0, 1.0));          // kN
    let p = add(cart, cargo);                                     // load on the deck, kN
    let (l, a) = (iv(20.0, 0.05), iv(8.0, 0.10));                 // span and position, m
    let naive = div(mul(p, sub(l, a)), l);                        // as written: L twice
    let tight = mul(p, sub((1.0, 1.0), div(a, l)));               // rewritten: each once
    show("load P = cart + cargo, kN", p, 6);
    show("span L, m", l, 6);
    show("position a, m", a, 6);
    show("L - a, m", sub(l, a), 6);
    show("P (L - a), kN m", mul(p, sub(l, a)), 6);
    show("a / L", div(a, l), 6);
    show("1 - a / L", sub((1.0, 1.0), div(a, l)), 6);
    println!("{:<36}{:.6}", "nominal reaction 50 x 12 / 20, kN", 50.0 * (20.0 - 8.0) / 20.0);
    show("as written, P (L - a) / L", naive, 6);
    show("rewritten, P (1 - a / L)", tight, 6);
    let (lo_n, lo_d, hi_n, hi_d): (i128, i128, i128, i128) = (48 * 1185, 1995, 52 * 1215, 2005);
    println!("{:<36}[{}, {}]  width {}", "exact range, whole numbers", dec6(lo_n, lo_d), dec6(hi_n, hi_d),
             dec6(hi_n * lo_d - lo_n * hi_d, lo_d * hi_d));
    let mut grid = Vec::new();
    for pp in [48.0, 49.0, 50.0, 51.0, 52.0] { for k in 0..11 { for j in 0..11 {
        let (x, ll) = (7.9 + 0.02 * k as f64, 19.95 + 0.01 * j as f64);
        grid.push(pp * (ll - x) / ll);
    } } }
    let gmin = grid.iter().cloned().fold(f64::INFINITY, f64::min);
    let gmax = grid.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    println!("{:<36}[{:.6}, {:.6}]", "brute force, 605 input points", gmin, gmax);
    println!("over-width of the as-written form: {:.4} times", (naive.1 - naive.0) / (tight.1 - tight.0));
    let (ex_lo, ex_hi) = (lo_n as f64 / lo_d as f64, hi_n as f64 / hi_d as f64);
    for (name, x) in [("nominal", (30.0, 30.0)), ("exact range", (ex_lo, ex_hi)), ("rewritten", tight), ("as written", naive)] {
        let s = ((x.0 - 28.0) / 0.08 + 0.5) as usize;
        let e = ((x.1 - 28.0) / 0.08 + 0.5) as usize;
        println!("{:<12}{:7.3} |{}{}{}| {:.3}", name, x.0, ".".repeat(s), "#".repeat(e - s + 1), ".".repeat(50 - e), x.1);
    }
    let ((tn, tk), (un, uk)) = (ratio(tight.0), ratio(tight.1));  // the ends as m / 2^k, exactly
    assert!(tn * (lo_d as u128) <= (lo_n as u128) << tk && (hi_n as u128) << uk <= un * (hi_d as u128)); // encloses, no rounding
    assert!(ex_lo <= tight.0 + 1e-9 && tight.1 - 1e-9 <= ex_hi);   // and hugs it
    assert!(naive.0 < ex_lo - 0.1 && naive.1 > ex_hi + 0.1);       // still encloses, but loose
    assert!(tight.0 <= gmin && gmax <= tight.1 && (gmin - ex_lo).abs() < 1e-12);

    // ---- multiplying across zero: an off-centre load, moment = P x c ----
    let c = out(-0.02, 0.03);                                     // offset of the load, m
    let m = mul(p, c);
    show("moment P x c, four products, kN m", m, 4);
    println!("{:<36}[{:.4}, {:.4}]", "moment, lo x lo and hi x hi only", p.0 * c.0, p.1 * c.1);
    let corners = [48.0 * -0.02, 48.0 * 0.03, 52.0 * -0.02, 52.0 * 0.03];
    println!("four corner products: {}", corners.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(", "));
    let cmin = corners.iter().cloned().fold(f64::INFINITY, f64::min);
    assert!((m.0 - cmin).abs() < 1e-12 && (m.0 - (-1.04)).abs() < 1e-12 && p.0 * c.0 > m.0 + 0.05);
    println!("wrong subtraction [L_lo - a_lo, L_hi - a_hi]: [{:.2}, {:.2}]", l.0 - a.0, l.1 - a.1);

    // ---- the tracker: 0.1 added ten million times, as an interval ----
    let tenth = (step(0.1, -1), 0.1);
    let ((ml, kl), (mh, kh)) = (ratio(tenth.0), ratio(tenth.1));
    assert!(10 * ml < (1u128 << kl) && 10 * mh > (1u128 << kh));  // the pair really brackets 1/10
    let (mut total, mut plain) = ((0.0f64, 0.0f64), 0.0f64);
    for _ in 0..10_000_000 {
        total = add(total, tenth);                                // the interval rule, rounded outward
        plain += 0.1;
    }
    let (s_lo, s_hi) = total;
    println!("{:<36}[{:.6}, {:.6}]  width {:.6}", "tracker total, interval", s_lo, s_hi, s_hi - s_lo);
    println!("{:<36}{:.6}  true error {:.6}", "tracker total, plain sum", plain, 1e6 - plain);
    println!("bound over true error: {:.2}", (s_hi - s_lo) / (1e6 - plain));
    assert!(s_lo < 1e6 && 1e6 < s_hi && s_lo <= plain && plain <= s_hi && plain < 1e6 && s_hi - s_lo < 0.002);

    // ---- a solver update, x <- x - 0.5 (x - 10), twenty times ----
    let x0 = out(9.95, 10.05);
    let (mut xa, mut xb) = (x0, x0);
    let mut rows = Vec::new();
    let (mut a20, mut b20) = (x0, x0);
    for k in 0..21 {
        if k % 2 == 0 { rows.push((k, (xa.1 - xa.0).log10(), (xb.1 - xb.0).log10())); }
        xa = sub(xa, mul((0.5, 0.5), sub(xa, (10.0, 10.0))));    // as written: x twice
        xb = add(mul((0.5, 0.5), xb), (5.0, 5.0));                // rewritten: 0.5 x + 5
        if k == 19 { a20 = xa; b20 = xb; }
    }
    let (wa, wb) = (a20.1 - a20.0, b20.1 - b20.0);
    println!("step                    {}", rows.iter().map(|r| format!("{:>7}", r.0)).collect::<String>());
    println!("log10 width, as written {}", rows.iter().map(|r| format!("{:>7.2}", r.1)).collect::<String>());
    println!("log10 width, rewritten  {}", rows.iter().map(|r| format!("{:>7.2}", r.2)).collect::<String>());
    show("after 20 steps, as written", a20, 3);
    show("after 20 steps, rewritten", b20, 9);
    assert!((wa / (0.1 * 1.5f64.powi(20)) - 1.0).abs() < 1e-9 && (wb / (0.1 * 0.5f64.powi(20)) - 1.0).abs() < 1e-5);
    println!("widths after 20 steps, as written over true: {:.4} billion", wa / (0.1 * 0.5f64.powi(20)) / 1e9);
    println!("ALL CHECKS PASS");
}
