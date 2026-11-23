// Kolmogorov complexity -- the same check as kolmogorov_complexity_check.py, in Rust, std only.
// K(x) is only bounded above, by the named programs held below as text and measured.  Pi comes
// from a small-number spigot and from Machin's formula on a hand-made big whole number.

const PI_PROG: &str = r#"def pi_digits(n):
    q, r, t, k, m, x = 1, 0, 1, 1, 3, 3
    out = []
    while len(out) < n:
        if 4 * q + r - t < m * t:
            out.append(m)
            q, r, m = 10 * q, 10 * (r - m * t), 10 * (3 * q + r) // t - 10 * m
        else:
            q, r, t, k, m, x = (q * k, (2 * q + r) * x, t * x, k + 1,
                                (q * (7 * k + 2) + r * x) // (t * x), x + 2)
    return "".join(map(str, out))
"#;
const BERRY_PROG: &str = r#"def gamma(r):                     # Elias gamma code of r >= 1: (length - 1) zeros, then r in binary
    b = ""
    while r: b, r = str(r % 2) + b, r // 2
    return "0" * (len(b) - 1) + b
def describe(x):                  # estimator E's description: first bit, then each run length in gamma
    out, i = [x[0]], 0
    while i < len(x):
        j = i
        while j < len(x) and x[j] == x[i]: j += 1
        out.append(gamma(j - i)); i = j
    return "".join(out)
def E(x): return len(describe(x))
def berry(L):                     # the construction: the first string, shortest first, that E rates above L
    m = 1
    while True:
        for v in range(2 ** m):
            x = "".join(str(v >> (m - 1 - i) & 1) for i in range(m))
            if E(x) > L: return x
        m += 1
"#;
const FL_PROG: &str = "x = 2026\nfor i in range(10**6):\n    x = (x + 0x9E3779B97F4A7C15) % 2**64\n    z = (x ^ x >> 30) * 0xBF58476D1CE4E5B9 % 2**64\n    z = (z ^ z >> 27) * 0x94D049BB133111EB % 2**64\n    print((z ^ z >> 31) >> 63, end=\"\")\n";
fn spigot(ndig: usize) -> String {               // road 1: a base-10000 spigot on small numbers
    let (a, mut c, mut e, mut s) = (10000u64, ndig / 4 * 14, 0u64, String::new());
    let mut f = vec![a / 5; c + 1]; f[c] = 0;
    while c > 0 {
        let (mut d, mut g, mut b) = (0u64, 2 * c as u64, c);
        loop {
            d += f[b] * a; g -= 1; f[b] = d % g; d /= g; g -= 1; b -= 1;
            if b == 0 { break; }
            d *= b as u64;
        }
        s += &format!("{:04}", e + d / a); e = d % a; c -= 14;
    }
    s
}
// Big whole numbers: base 10^9 limbs, least significant first, signed until the end.
const BASE: i64 = 1_000_000_000;
fn div_small(a: &[i64], d: i64) -> Vec<i64> {
    let (mut out, mut rem) = (vec![0; a.len()], 0);
    for i in (0..a.len()).rev() { let cur = rem * BASE + a[i]; out[i] = cur / d; rem = cur % d; }
    out
}
fn machin(n: usize) -> String {                  // road 2: pi = 16 atan(1/5) - 4 atan(1/239)
    let len = (n + 10) / 9 + 2;
    let (mut one, mut acc) = (vec![0i64; len], vec![0i64; len]);
    one[(n + 10) / 9] = 10i64.pow(((n + 10) % 9) as u32);
    for (x, coef) in [(5i64, 16i64), (239, -4)] {
        let (mut term, mut k, mut sign) = (div_small(&one, x), 1, coef);
        while term.iter().any(|&v| v != 0) {
            let t = div_small(&term, k);
            for i in 0..len { acc[i] += sign * t[i]; }
            term = div_small(&term, x * x); k += 2; sign = -sign;
        }
    }
    let mut carry = 0;
    for v in acc.iter_mut() { let s = *v + carry; *v = s.rem_euclid(BASE); carry = s.div_euclid(BASE); }
    let mut i = len - 1; while acc[i] == 0 { i -= 1; }
    let mut s = acc[i].to_string();
    for j in (0..i).rev() { s += &format!("{:09}", acc[j]); }
    s[..n].to_string()
}
fn flips(seed: u64, n: usize) -> String {        // SplitMix64, top bit of each output
    let mut x = seed; let mut out = String::with_capacity(n);
    for _ in 0..n {
        x = x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        out.push(if (z ^ (z >> 31)) >> 63 == 1 { '1' } else { '0' });
    }
    out
}
fn gamma(r: usize) -> String { let b = format!("{:b}", r); "0".repeat(b.len() - 1) + &b }
fn describe(x: &[u8]) -> String {                // estimator E: first bit, then run lengths in gamma
    let mut out = String::new(); out.push(x[0] as char); let mut i = 0;
    while i < x.len() { let mut j = i; while j < x.len() && x[j] == x[i] { j += 1; } out += &gamma(j - i); i = j; }
    out
}
fn e_len(x: &[u8]) -> usize { describe(x).len() }
fn decode(d: &[u8]) -> Vec<u8> {
    let (mut bit, mut i, mut out) = (d[0], 1, Vec::new());
    while i < d.len() {
        let mut z = 0; while d[i] == b'0' { z += 1; i += 1; }
        let mut r = 0; for &c in &d[i..i + z + 1] { r = 2 * r + (c - b'0') as usize; }
        i += z + 1;
        for _ in 0..r { out.push(bit); }
        bit = if bit == b'0' { b'1' } else { b'0' };
    }
    out
}
fn bits(v: u64, m: usize) -> Vec<u8> { (0..m).map(|i| if v >> (m - 1 - i) & 1 == 1 { b'1' } else { b'0' }).collect() }
fn berry(l: usize) -> Vec<u8> {
    let mut m = 1;
    loop { for v in 0..(1u64 << m) { let x = bits(v, m); if e_len(&x) > l { return x; } } m += 1; }
}

fn main() {
    let pi_bytes = |n: u64| PI_PROG.len() + format!("print(pi_digits({}))\n", n).len();
    let n = 1000;
    let (pi_a, pi_b) = (spigot(n), machin(n));
    let counts: Vec<usize> = (0..10).map(|d| pi_a.matches(&d.to_string()).count()).collect();
    let h_emp: f64 = counts.iter().map(|&c| c as f64 / n as f64 * (n as f64 / c as f64).log2()).sum();
    let six = pi_a.find("999999").unwrap();
    println!("pi, spigot road, first 30 digits  {}", &pi_a[..30]);
    println!("pi, Machin road, first 30 digits  {}", &pi_b[..30]);
    println!("pi, roads agree on digits         {} of {}", pi_a.bytes().zip(pi_b.bytes()).filter(|(a, b)| a == b).count(), n);
    println!("pi, six 9s start at place         {}", six);
    println!("pi, digit counts 0..9             {}", counts.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "));
    println!("pi, digit-frequency entropy      {:.4} bits per digit (log2 10 = {:.4})", h_emp, 10f64.log2());
    println!("named pi program, bytes           {} + call line", PI_PROG.len());
    for nn in [10u64, 1000, 1000000] {
        println!("n = {:>7}: pi as text {:>7} bits, packed {:>7} bits, named program {:>5} bits",
                 nn, 8 * nn, (nn as f64 * 10f64.log2()) as u64 + 1, 8 * pi_bytes(nn));
    }
    let big = 1000000;
    let coins = flips(2026, big);
    let ones = coins.matches('1').count();
    println!("flips, seed 2026, first 32        {}", &coins[..32]);
    println!("flips, ones out of 1000000        {}", ones);
    println!("flips, E in bits                  {}", e_len(coins.as_bytes()));
    println!("flips, named generator program    {} bytes = {} bits", FL_PROG.len(), 8 * FL_PROG.len());
    let patt = "0011".repeat(250000);
    let alt = "01".repeat(500000);
    println!("0011 x 250000: E {} bits; program print('0011' * 250000) is {} bits", e_len(patt.as_bytes()), 8 * "print('0011' * 250000)\n".len());
    println!("01 x 500000:   E {} bits; program print('01' * 500000) is {} bits", e_len(alt.as_bytes()), 8 * "print('01' * 500000)\n".len());
    let m = 16;
    let mut small = [0usize; 5];
    for v in 0..(1u64 << m) {
        let x = bits(v, m);
        assert!(decode(describe(&x).as_bytes()) == x, "E's descriptions must decode back");
        let e = e_len(&x);
        for k in 0..5 { if e < m - k { small[k] += 1; } }
    }
    for k in 0..5 {
        println!("16-bit strings with E < {}: {:>5} of 65536; any method: at most {:>5}", m - k, small[k], (1usize << (m - k)) - 1);
    }
    println!("chance K < 999980 for 1000000 true flips: below 1 in {}", 1u64 << 20);
    for l in [4usize, 8, 12, 16, 20] {
        let x = berry(l);
        println!("berry({:>2}) prints {:<14} E = {:>2}, length {:>2}", l, std::str::from_utf8(&x).unwrap(), e_len(&x), x.len());
    }
    println!("berry program bytes, L = 1000000  {}", BERRY_PROG.len() + "print(berry(1000000))\n".len());
    println!("chart, log10 n                {}", (1..7).map(|e| format!("{:>5}", e)).collect::<Vec<_>>().join(" "));
    println!("chart, log10 bits, pi packed  {}", (1..7).map(|e| format!("{:5.2}", (((10f64.powi(e) * 10f64.log2()) as u64 + 1) as f64).log10())).collect::<Vec<_>>().join(" "));
    println!("chart, log10 bits, pi program {}", (1..7).map(|e| format!("{:5.2}", ((8 * pi_bytes(10u64.pow(e as u32))) as f64).log10())).collect::<Vec<_>>().join(" "));
    println!("chart, log10 bits, true flips {}", (1..7).map(|e| format!("{:5.2}", e as f64)).collect::<Vec<_>>().join(" "));

    assert!(pi_a == pi_b, "spigot and Machin roads must agree on every digit");
    assert!(pi_a.starts_with("31415926535897932384626433832795"), "published opening digits");
    assert!(six == 762, "the six 9s start at decimal place 762");
    assert!((0..5).all(|k| small[k] <= (1 << (m - k)) - 1), "counting bound");
    assert!(e_len(patt.as_bytes()) == 1 + 3 * 500000 && e_len(alt.as_bytes()) == 1 + 1000000, "E by runs against E by formula");
    assert!(((ones as f64) - big as f64 / 2.0).abs() < 3.0 * (big as f64).sqrt() / 2.0, "flips within 3 standard errors of half");
    println!("ALL CHECKS PASS");
}
