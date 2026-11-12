// IEEE 754 doubles -- the same check as ieee_floating_point_check.py, in Rust.
// Standard library only, no crates.  to_bits only hands over the 64 stored bits.
// Reading the three fields, and rounding a fraction into a double in each
// rounding mode, are done here in whole numbers (u128), which cannot round.
// Compile: rustc --edition 2021 -O ieee_floating_point_check.rs -o /tmp/ieee_check

fn fields(b: u64) -> (u64, u64, u64) { (b >> 63, (b >> 52) & 0x7FF, b & ((1u64 << 52) - 1)) }

fn kind(b: u64) -> &'static str {                   // what the exponent field says the pattern is
    let (_, e, f) = fields(b);
    if e == 2047 { return if f != 0 { "NaN" } else { "infinity" }; }
    if e == 0 { return if f != 0 { "subnormal" } else { "zero" }; }
    "normal"
}

fn exact(b: u64) -> (u128, i32) {                   // a positive finite double as m / 2^k, from its fields alone
    let (_, e, f) = fields(b);
    if e == 0 { (f as u128, 1074) } else { (((1u64 << 52) + f) as u128, 1075 - e as i32) }
}

fn bit_len(x: u128) -> i32 { 128 - x.leading_zeros() as i32 }

fn encode(p: u128, q: u128, k: i32, mode: &str) -> u64 {   // the double for p / q / 2^k (p, q > 0)
    let mut l = bit_len(p) - bit_len(q);
    if (p << (-l).max(0)) < (q << l.max(0)) { l -= 1; }
    let e = l - k;                                  // the value lies in [2^E, 2^(E+1))
    if e > 1023 { return if mode == "down" { 0x7FEFFFFFFFFFFFFF } else { 0x7FF << 52 }; }
    let mut sc = e.max(-1022) - 52;                 // the grid there: whole multiples of 2^sc
    let t = -k - sc;
    let (num, den) = if t >= 0 { (p << t, q) } else { (p, q << -t) };
    let (mut m, r) = (num / den, num % den);        // m grid steps, plus a remainder r/den of a step
    if mode == "up" && r != 0 { m += 1; }
    if mode == "nearest" && (2 * r > den || (2 * r == den && m & 1 == 1)) { m += 1; }
    if m >> 53 != 0 { m >>= 1; sc += 1; }
    if m < (1u128 << 52) { return m as u64; }      // subnormal or zero: exponent field 0
    (((sc + 1075) as u64) << 52) | (m - (1u128 << 52)) as u64   // field 2047 here means infinity
}

fn decimal(m: u128, k: i32) -> String {             // exact decimal expansion of m / 2^k: it always ends
    let mask = (1u128 << k) - 1;
    let (mut r, mut out) = (m & mask, String::new());
    while r != 0 { r *= 10; out.push_str(&(r >> k).to_string()); r &= mask; }
    format!("{}.{}", m >> k, if out.is_empty() { "0".to_string() } else { out })
}

fn short(x: f64) -> String { if x != 0.0 && (x.abs() < 1e-4 || x.abs() >= 1e16) { format!("{:e}", x) } else { format!("{:?}", x) } }
fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn yn(flag: bool) -> &'static str { if flag { "yes" } else { "no" } }
fn row(label: &str, value: String) { println!("{:<35} {}", label, value); }

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
    // ---- 1. the three fields of 0.1, 0.2, 0.3 and the machine's 0.1 + 0.2 ----
    let total = 0.1f64 + 0.2;
    for (name, x) in [("0.1", 0.1f64), ("0.2", 0.2), ("0.3", 0.3), ("0.1 + 0.2", total)] {
        let (s, e, f) = fields(x.to_bits());
        row(&format!("{}: s, e, f, E = e - 1023", name), format!("{} {} {} {}", s, e, f, e as i32 - 1023));
    }
    for (name, x, p) in [("0.1", 0.1f64, 1u128), ("0.2", 0.2, 2), ("0.3", 0.3, 3)] {
        assert!(encode(p, 10, 0, "nearest") == x.to_bits(), "{}: own rounding must equal the parser's", name);
    }
    let b = format!("{:064b}", total.to_bits());
    row("0.1 + 0.2 as 64 bits", format!("{} {} {}", &b[0..1], &b[1..12], &b[12..]));
    row("0.1 + 0.2 printed", format!("{:?}", total));
    let (mt, kt) = exact(total.to_bits());
    row("0.1 + 0.2 stored exactly", format!("{} / 2^{} = {}", mt, kt, decimal(mt, kt)));
    let f3 = fields(0.3f64.to_bits()).2 as f64 / 4503599627370496.0;   // misreading 0.3: no hidden 1; no bias
    let mut p1021 = 1.0f64;
    for _ in 0..1021 { p1021 *= 2.0; }
    row("0.3 misread: no leading 1; no bias", format!("{:.4} {}", f3 * 0.25, sci((1.0 + f3) * p1021)));

    // ---- 2. one tenth in three rounding modes ----
    for mode in ["nearest", "down", "up"] {
        let (m, k) = exact(encode(1, 10, 0, mode));
        let off = (10 * m as i128 - (1i128 << k)) as f64 / 10.0;
        row(&format!("1/10 rounded {}", mode), format!("{} / 2^{}, off {:+.1} ulp", m, k, off));
    }
    let gap = encode(1, 10, 0, "up") - encode(1, 10, 0, "down");
    row("up minus down, in ulps", format!("{}", gap));
    assert!(gap == 1, "a number that is not a double sits between two neighbours");

    // ---- 3. the sum: exact sum of the stored inputs, rounded each way ----
    let ((m1, k1), (m2, k2)) = (exact(0.1f64.to_bits()), exact(0.2f64.to_bits()));
    let ex = m1 + (m2 << (k1 - k2));                // both over 2^56: no rounding yet
    row("exact sum of stored inputs", format!("{} / 2^{}, {} of 4 past the grid", ex, k1, ex % 4));
    for mode in ["nearest", "down", "up"] {
        row(&format!("sum rounded {}", mode), short(f64::from_bits(encode(ex, 1, k1, mode))));
    }
    assert!(encode(ex, 1, k1, "nearest") == total.to_bits(), "own rounding must equal the machine's add");
    assert!(encode(ex, 1, k1, "down") == 0.3f64.to_bits(), "rounded down, the sum is the stored 0.3");
    let big = 9007199254740992.0f64 + 1.0;          // a tie whose even neighbour is below
    row("2^53 + 1, a tie, rounded nearest", format!("{:.0}", big));
    assert!(big.to_bits() == encode((1u128 << 53) + 1, 1, 0, "nearest") && big == 9007199254740992.0, "ties go to even");

    // ---- 4. the ends of the range ----
    let top = f64::from_bits(0x7FEFFFFFFFFFFFFF);
    let mut p1023 = 1.0f64;
    for _ in 0..1023 { p1023 *= 2.0; }
    assert!(top == (2.0 - 1.0 / 4503599627370496.0) * p1023, "largest double from its fields");
    let (mut x, mut doublings) = (1.0f64, 0);
    while kind(x.to_bits()) != "infinity" { x *= 2.0; doublings += 1; }
    let (mut y, mut halvings) = (1.0f64, 0);
    while y / 2.0 != 0.0 { y /= 2.0; halvings += 1; }
    assert!((doublings, halvings, y.to_bits()) == (1024, 1074, 1), "range ends from loops, not from fields");
    row("largest double", short(top));
    row("smallest normal, 2^-1022", short(f64::from_bits(1u64 << 52)));
    row("smallest subnormal, 2^-1074", short(y));
    row("doublings from 1 to infinity", format!("{}", doublings));
    row("halvings from 1 before zero", format!("{}", halvings));
    row("largest * 2: kind, bits", format!("{} {:#018x}", kind((top * 2.0).to_bits()), (top * 2.0).to_bits()));
    assert!(encode(1, 1, -1024, "nearest") == (top * 2.0).to_bits(), "past the top, own rounding says inf");

    // ---- 5. subnormals: gradual underflow ----
    let c = f64::from_bits(1u64 << 52);             // 2^-1022
    let a = 1.5 * c;
    let flushed = if kind((a - c).to_bits()) == "subnormal" { 0.0 } else { a - c };   // simulated: no subnormals
    row("1.5*2^-1022 - 2^-1022; if flushed", format!("{}, {}; {}", short(a - c), kind((a - c).to_bits()), short(flushed)));
    assert!(a != c && a - c != 0.0 && (a - c).to_bits() == encode(1, 1, 1023, "nearest"), "x != y means x - y != 0");
    let tiny = 0.1 * f64::from_bits(1u64 << 14);    // 0.1 times 2^-1060, deep in the subnormals
    let ft = fields(tiny.to_bits()).2;
    assert!(tiny.to_bits() == encode(m1, 1, k1 + 1060, "nearest"), "own rounding into the subnormals");
    let rel = (((ft as i128) << 42) - m1 as i128) as f64 / m1 as f64;   // against the exact product
    row("0.1 * 2^-1060: f, bits, rel err", format!("{} {} {}", ft, 64 - ft.leading_zeros(), sci(rel)));

    // ---- 6. infinity, NaN and signed zero ----
    let inf = top * 2.0;
    let nan = inf - inf;
    let (_, e, f) = fields(nan.to_bits());
    row("inf - inf: kind, e, f nonzero", format!("{} {} {}", kind(nan.to_bits()), e, yn(f != 0)));
    row("nan == nan, nan < 1, nan > 1", format!("{} {} {}", yn(nan == nan), yn(nan < 1.0), yn(nan > 1.0)));
    row("nan + 1 is NaN; 1 / inf", format!("{} {}", yn(kind((nan + 1.0).to_bits()) == "NaN"), short(1.0 / inf)));
    let nz = 1e-200f64 * -1e-200;
    row("1e-200 * -1e-200; sign bit", format!("{} {}", short(nz), fields(nz.to_bits()).0));
    row("-0.0 == 0.0; same bits", format!("{} {}", yn(nz == 0.0), yn(nz.to_bits() == 0.0f64.to_bits())));

    // ---- 7. 20,000 random fractions: own rounding against the machine's divide ----
    let mut g = SplitMix(2026);
    let (mut bad, mut subs) = (0, 0);
    for scale in [0i32, 1022] {                     // scale 1022 sends about half into the subnormals
        let mut down = 1.0f64;
        for _ in 0..scale { down /= 2.0; }
        for _ in 0..10000 {
            let p = g.next() >> 11 | 1;
            let q = g.next() >> 11 | 1;
            let got = (p as f64 * down / q as f64).to_bits();
            if got != encode(p as u128, q as u128, scale, "nearest") { bad += 1; }
            if kind(got) == "subnormal" { subs += 1; }
        }
    }
    row("random divides; subnormal results", format!("20000 {}", subs));
    row("disagreements with own rounding", format!("{}", bad));
    assert!(bad == 0, "every divide must be the exact quotient, rounded to nearest");

    // ---- 8. the house example and the figure ----
    let mut acc = 0.0f64;
    for _ in 0..10_000_000 { acc += 0.1; }
    row("0.1 added ten million times", format!("{}, off {}", short(acc), sci(acc - 1e6)));
    row("ulp at 1,000,000", sci(f64::from_bits(1e6f64.to_bits() + 1) - 1e6));
    row("figure, x: sign, exponent, fraction", "20-60 60-160 160-420".to_string());
    println!("ALL CHECKS PASS");
}
