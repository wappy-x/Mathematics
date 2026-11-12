// Floating point in practice -- the same check as floating_point_in_practice_check.py, in Rust.
// Standard library only, no crates.  to_bits only hands over the 64 stored bits;
// every exact value is then worked out in whole numbers (u128), which cannot round,
// and the machine's answers are checked against them.
// Compile: rustc --edition 2021 -O floating_point_in_practice_check.rs -o /tmp/fp_check
const U: f64 = 1.0 / 9007199254740992.0;          // unit roundoff 2^-53: half of machine epsilon

fn exact(x: f64) -> (u128, i32) {                 // a positive normal double: x = m / 2^k, m has 53 bits
    let b = x.to_bits();
    (((1u64 << 52) + (b & ((1u64 << 52) - 1))) as u128, 52 - (((b >> 52) & 0x7FF) as i32 - 1023))
}

fn round53(m: u128, k: i32) -> (u128, i32) {      // round m / 2^k to 53 significant bits, ties to even
    let mut drop = (128 - m.leading_zeros() as i32 - 53).max(0);
    let (mut q, r, half) = (m >> drop, m & ((1u128 << drop) - 1), (1u128 << drop) >> 1);
    if r > half || (drop > 0 && r == half && q & 1 == 1) { q += 1; }
    if q >> 53 != 0 { q >>= 1; drop += 1; }
    (q, k - drop)
}

fn nearest(p: u128, q: u128) -> (u128, i32) {     // the double nearest p/q, by long division in base two
    let mut k = 0;
    while (p << k) / q < (1u128 << 52) { k += 1; }
    let (mut m, r) = ((p << k) / q, (p << k) % q);
    if 2 * r > q || (2 * r == q && m & 1 == 1) { m += 1; }
    (m, k)
}

fn decimal(m: u128, k: i32) -> String {           // exact decimal expansion of m / 2^k: it always ends
    let mask = (1u128 << k) - 1;
    let (mut r, mut out) = (m & mask, String::new());
    while r != 0 { r *= 10; out.push_str(&(r >> k).to_string()); r &= mask; }
    format!("{}.{}", m >> k, if out.is_empty() { "0".to_string() } else { out })
}

fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn yn(flag: bool) -> &'static str { if flag { "yes" } else { "no" } }
fn row(label: &str, value: String) { println!("{:<34} {}", label, value); }

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn main() {
    // ---- 1. reading the 64 bits of 0.1 ----
    let b = 0.1f64.to_bits();
    let s = format!("{:064b}", b);
    row("0.1 as 64 bits", format!("{} {} {}", &s[0..1], &s[1..12], &s[12..]));
    row("sign, exponent field, fraction", format!("{} {} {}", b >> 63, (b >> 52) & 0x7FF, b & ((1u64 << 52) - 1)));
    row("1 + f/2^52, and e - 1023", format!("{} {}", 1.0 + (b & ((1u64 << 52) - 1)) as f64 / (1u64 << 52) as f64,
        ((b >> 52) & 0x7FF) as i32 - 1023));
    for (name, x, p) in [("0.1", 0.1f64, 1u128), ("0.2", 0.2, 2), ("0.3", 0.3, 3)] {
        assert!(exact(x) == nearest(p, 10), "{}: stored bits must be the nearest double to p/10", name);
        let (m, k) = exact(x);
        row(&format!("{} stored exactly", name), decimal(m, k));
    }
    let (m1, k1) = exact(0.1);
    row("0.1 as a whole number over 2^k", format!("{} / 2^{}", m1, k1));
    row("0.3 as a whole number over 2^k", format!("{} / 2^{}", exact(0.3).0, exact(0.3).1));
    row("0.1 stored minus 1/10", sci((m1 * 10 - (1u128 << k1)) as f64 / (10u128 << k1) as f64));

    // ---- 2. the sum, rounded by hand and by the machine ----
    let (m2, k2) = exact(0.2);
    let exact_sum = m1 + (m2 << (k1 - k2));       // both over 2^56, no rounding
    let (rm, rk) = round53(exact_sum, k1);
    let total = 0.1f64 + 0.2;
    assert!((rm, rk) == exact(total), "own rounding must match the machine's sum");
    assert!(total.to_bits() == 0.3f64.to_bits() + 1, "the sum lands one step above stored 0.3");
    assert!(exact_sum & 3 == 2, "the two dropped bits must be exactly half: a tie");
    row("exact sum of the stored inputs", decimal(exact_sum, k1));
    row("sum over 2^56; 53 bits over 2^54", format!("{}; {} -> {}", exact_sum, exact_sum >> 2, rm));
    row("bits dropped to fit 53, out of", format!("{} of 4: a tie, so round to even", exact_sum & 3));
    row("machine sum 0.1 + 0.2", format!("{} = {}", total, decimal(rm, rk)));
    row("gap to stored 0.3, in ulps", format!("{}", total.to_bits() - 0.3f64.to_bits()));
    let rel = (rm * 4 - exact_sum) as f64 / exact_sum as f64;
    row("relative error of the add", format!("{} = {:.4} u", sci(rel), rel / U));
    row("0.1 + 0.2 == 0.3", yn(total == 0.3).to_string());

    // ---- 3. machine epsilon: from the layout and by halving ----
    let eps_layout = f64::from_bits(1.0f64.to_bits() + 1) - 1.0;
    let mut eps = 1.0f64;
    while 1.0 + eps / 2.0 != 1.0 { eps /= 2.0; }
    assert!(eps == eps_layout && eps == 2.0 * U, "halving loop must stop at the layout's gap");
    row("next double after 1, minus 1", sci(eps_layout));
    row("halving loop stops at", sci(eps));
    row("unit roundoff u = eps/2", sci(U));
    let big = 9007199254740992.0f64;              // 2^53
    for (name, x) in [("0.3", 0.3f64), ("1", 1.0), ("100000", 1e5), ("2^53", big)] {
        row(&format!("ulp at {}", name), sci(f64::from_bits(x.to_bits() + 1) - x));
    }
    row("2^53, and 2^53 + 1 - 2^53", format!("{:.0} {:.0}", big, big + 1.0 - big));
    assert!(big + 1.0 == big && big - 1.0 + 1.0 == big, "the 1 vanishes above 2^53 only");

    // ---- 4. the promise, tested: 20,000 random sums and products ----
    let mut g = SplitMix(2026);
    let (mut bad, mut worst) = (0, 0.0f64);
    for _ in 0..10000 {                           // exponent fields 1013..1033: 2^-10 up to 2^11
        let x = f64::from_bits(((1013 + g.next() % 21) << 52) | (g.next() >> 12));
        let y = f64::from_bits(((1013 + g.next() % 21) << 52) | (g.next() >> 12));
        let ((mx, kx), (my, ky)) = (exact(x), exact(y));
        let kk = kx.max(ky);
        for (m, k, got) in [((mx << (kk - kx)) + (my << (kk - ky)), kk, x + y), (mx * my, kx + ky, x * y)] {
            let (rm, rk) = round53(m, k);
            if (rm, rk) != exact(got) { bad += 1; }
            let diff = ((rm << (k - rk)) as i128 - m as i128).unsigned_abs();
            worst = worst.max(diff as f64 / m as f64 / U);
        }
    }
    row("random sums and products checked", "20000".to_string());
    row("disagreements with own rounding", format!("{}", bad));
    row("worst relative error, in u", format!("{:.6}", worst));
    assert!(bad == 0 && worst <= 1.0, "every operation must be the exact answer, rounded once");

    // ---- 5. where it shows up: 0.1 added n times, 100 times 1.05 ten times ----
    let (mut acc, mut n, mut ten) = (0.0f64, 0u64, 0.0f64);
    for target in [10u64, 100, 1000, 10000, 100000, 1000000] {
        while n < target { acc += 0.1; n += 1; }
        let (ma, ka) = exact(acc);
        let diff = ((ma << (k1 - ka)) as i128 - (n as u128 * m1) as i128).unsigned_abs();
        let err = diff as f64 / (1u128 << k1) as f64;   // against the exact sum of n stored 0.1s
        let bound = (n - 1) as f64 * U * n as f64 * 0.1; // worst case, to first order in u
        assert!(0.0 < err && err <= bound, "the sum's error must stay under the worst-case bound");
        if n == 10 { ten = acc; }
        if n == 10 || n == 1000000 {
            row(&format!("0.1 added {} times", n), format!("{}, off {}", acc, sci(acc - n as f64 / 10.0)));
        }
        row(&format!("chart n={}: log10 err, bound", n), format!("{:.2} {:.2}", err.log10(), bound.log10()));
    }
    let mut x = 100.0f64;
    for _ in 0..10 { x *= 1.05; }
    let (mx, kx) = exact(x);
    let big_n: i128 = 162889462677744140625;      // 100 * 1.05^10, exactly, over 10^18
    let num = (mx as i128 * 1_000_000_000_000_000_000 - (big_n << kx)).unsigned_abs();
    let rel_p = num as f64 / (big_n << kx) as f64;
    row("100 * 1.05, ten times", format!("{}, rel. error {:.2} u", x, rel_p / U));
    assert!(rel_p <= 20.0 * U, "a stored 1.05 and ten roundings: at most about 20 u");

    // ---- 6. what breaks, and the special values ----
    row("0.1 added ten times == 1.0", yn(ten == 1.0).to_string());
    row("1 + 1e-17 == 1, 1e-17 == 0", format!("{} {}", yn(1.0 + 1e-17 == 1.0), yn(1e-17 == 0.0)));
    let top = f64::from_bits(0x7FEFFFFFFFFFFFFF);
    let inf = top * 2.0;
    row("largest double", format!("{:.16e}", top));
    row("largest * 2; is inf - inf itself", format!("{} {}", inf, yn(inf - inf == inf - inf)));
    row("-0.0 == 0.0; same bits", format!("{} {}", yn(-0.0 == 0.0f64), yn((-0.0f64).to_bits() == 0.0f64.to_bits())));
    println!("ALL CHECKS PASS");
}
