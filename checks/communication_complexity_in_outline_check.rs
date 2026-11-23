// Communication complexity -- the same check as the Python, in Rust.  No crates.
// Two warehouses, Leeds (list x) and Bristol (list y), each mark 1,000 product
// codes in stock (1) or out (0), and ask whether the two lists match: EQUALITY.
// Roads: an exhaustive search for the best protocol against the fooling-set
// bound; a fingerprint's error counted prime by prime, simulated, and bounded.
// Lists of 1,000 bits are 16 limbs of 64 bits, lowest limb first.
type Big = Vec<u64>;

fn ceil_log2(m: u64) -> u32 { 64 - (m - 1).leading_zeros() } // fewest bits naming m outcomes

fn best_protocol_bits(n: u32) -> u32 {        // exhaustive search over every protocol
    let size = 1usize << (1 << n);            // rectangles: Leeds rows times Bristol columns
    let mut d = vec![0u32; size * size];
    for r in 0..size {
        for c in 0..size {
            let ones = (r & c).count_ones();
            let cells = r.count_ones() * c.count_ones();
            if ones == 0 || ones == cells { continue }   // one answer fills it
            let mut best = 99;
            let mut s = (r.wrapping_sub(1)) & r;          // Leeds splits its rows: one bit
            while s != 0 {
                best = best.min(1 + d[s * size + c].max(d[(r ^ s) * size + c]));
                s = (s - 1) & r;
            }
            s = (c.wrapping_sub(1)) & c;                  // or Bristol splits its columns
            while s != 0 {
                best = best.min(1 + d[r * size + s].max(d[r * size + (c ^ s)]));
                s = (s - 1) & c;
            }
            d[r * size + c] = best;
        }
    }
    d[size * size - 1]
}

fn sieve(limit: usize) -> Vec<u64> {
    let mut flag = vec![true; limit];
    flag[0] = false; flag[1] = false;
    let mut i = 2;
    while i * i < limit {
        if flag[i] { let mut j = i * i; while j < limit { flag[j] = false; j += i } }
        i += 1;
    }
    (0..limit).filter(|&i| flag[i]).map(|i| i as u64).collect()
}

fn rem(a: &Big, p: u64) -> u64 {               // a mod p, limb by limb from the top
    let mut r: u128 = 0;
    for &l in a.iter().rev() { r = ((r << 64) | l as u128) % p as u128 }
    r as u64
}

fn mul_small(a: &Big, m: u64) -> Big {
    let mut carry: u128 = 0;
    a.iter().map(|&l| { let t = l as u128 * m as u128 + carry; carry = t >> 64; t as u64 }).collect()
}

fn add(a: &Big, b: &Big) -> Big {
    let mut carry = 0u128;
    (0..16).map(|i| { let t = a[i] as u128 + b[i] as u128 + carry; carry = t >> 64; t as u64 }).collect()
}

fn sub_small(a: &Big, m: u64) -> Big {
    let mut out = a.clone();
    let mut borrow = m;
    for l in out.iter_mut() {
        let (v, o) = l.overflowing_sub(borrow);
        *l = v;
        borrow = o as u64;
        if borrow == 0 { break }
    }
    out
}

fn stream_mod(bits: &[u64], p: u64) -> u64 {   // one pass over the list, keeping a remainder
    bits.iter().fold(0, |r, &b| (2 * r + b) % p)
}

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn main() {
    println!("== deterministic: exhaustive search against the fooling-set bound ==");
    for n in 1..=3u32 {
        let (found, bound) = (best_protocol_bits(n), ceil_log2((1u64 << n) + 1));
        println!("n = {}: best protocol {} bits; fooling-set bound {}; send-the-list protocol {}", n, found, bound, n + 1);
        assert!(found == bound && bound == n + 1);
    }
    println!("n = 2 send-the-list transcripts (row x = Leeds, column y = Bristol):");
    for x in 0..4 {
        let cells: Vec<String> = (0..4).map(|y| format!("{:02b}|{}", x, (x == y) as u8)).collect();
        println!("  x = {:02b}: {}", x, cells.join("  "));
    }

    println!("== the warehouses: n = 1000 product codes ==");
    let (n, limit, trials) = (1000usize, 1_000_000u64, 200_000u64);
    let primes = sieve(limit as usize);
    let pbits = ceil_log2(limit);
    println!("send the whole list, plus the answer: {} bits", n + 1);
    println!("primes below {}: {}; bits to name one: {}", limit, primes.len(), pbits);
    println!("fingerprint: prime {} + remainder {} + answer 1 = {} bits", pbits, pbits, 2 * pbits + 1);
    let below1000 = |a: &Big| a[15] >> 40 == 0;               // limb 15 holds bits 960 to 1023
    let (mut d, mut k): (Big, usize) = (vec![0; 16], 0); d[0] = 1;
    while below1000(&mul_small(&d, primes[k])) { d = mul_small(&d, primes[k]); k += 1 }
    let mut g = SplitMix64 { s: 2026 };
    let mut y: Big = (0..16).map(|_| g.next()).collect();
    y[15] &= (1u64 << 38) - 1;                                    // so x = y + d stays below 2^1000
    let x = add(&y, &d);
    let xb: Vec<u64> = (0..n).map(|i| { let j = n - 1 - i; (x[j / 64] >> (j % 64)) & 1 }).collect();
    let fool = primes.iter().filter(|&&p| rem(&x, p) == rem(&y, p)).count();
    println!("worst lists: x - y = product of the first {} primes, largest {}; times the next, {}, it passes 2^{}", k, primes[k - 1], primes[k], n);
    println!("primes that fool the check, counted one by one: {}", fool);
    assert!(fool == k);                                           // construction against count
    assert!(primes[..k].iter().map(|&p| (p as f64).log2()).sum::<f64>() < n as f64 && n as f64 <= primes[..=k].iter().map(|&p| (p as f64).log2()).sum::<f64>()); // and no gap has more
    assert!(primes[primes.len() - 3..].iter().all(|&p| stream_mod(&xb, p) == rem(&x, p)));
    let mut hits = 0u64;
    for _ in 0..trials {
        let p = primes[(g.next() % primes.len() as u64) as usize];
        if rem(&x, p) == rem(&y, p) { hits += 1 }
    }
    let (exact, bound) = (fool as f64 / primes.len() as f64, n as f64 / primes.len() as f64);
    let sim = hits as f64 / trials as f64;
    let sd = (exact * (1.0 - exact) / trials as f64).sqrt();
    println!("error: exact {:.6}; simulated {:.6} over {} runs; bound n/pi {:.6}", exact, sim, trials, bound);
    assert!((sim - exact).abs() < 4.0 * sd && exact <= bound);
    assert!(primes.len() == 78498);                               // the published count below a million
    let mut one = y.clone();
    one[500 / 64] ^= 1u64 << (500 % 64);                          // one product's line flipped
    println!("one line differs: primes that fool the check {}", primes.iter().filter(|&&p| rem(&one, p) == rem(&y, p)).count());
    println!("== growth: bits to settle EQUALITY ==");
    for e in [3u32, 6, 9] {
        let m = 10u64.pow(e);
        let b = ceil_log2(m * m);
        println!("n = 10^{}: whole list {}; fingerprint {}; error at most 1 in {}", e, m + 1, 2 * b + 1, (m as f64 / ((m * m) as f64).ln()).round() as u64);
    }

    println!("== memory: a one-pass checker needs n bits ==");
    let (small, keep) = (10u32, 9u32);                            // keeps the low 9 bits only
    let mut seen = vec![u32::MAX; 1 << keep];
    let (mut a, mut b) = (0u32, 0u32);
    for lst in 0..(1u32 << small) {
        let st = (lst % (1 << keep)) as usize;
        if seen[st] != u32::MAX { a = seen[st]; b = lst; break }
        seen[st] = lst;
    }
    println!("{}-bit memory, {}-bit lists: {} lists, {} states; {:010b} and {:010b} share state {}",
             keep, small, 1u32 << small, 1u32 << keep, a, b, a % (1 << keep));
    let bits = |v: u32| -> Vec<u64> { (0..small).map(|i| ((v >> (small - 1 - i)) & 1) as u64).collect() };
    let said = stream_mod(&bits(b), 1 << keep) == stream_mod(&bits(a), 1 << keep); // the 9-bit checker, run bit by bit
    println!("stream {:010b} then {:010b}: checker says {}, lists differ", b, a, if said { "match" } else { "no match" });
    assert!(said);

    println!("== what breaks ==");
    println!("counting only Leeds's message, n = 2: {} bits, but the search finds {}", ceil_log2(1u64 << 2), best_protocol_bits(2));
    let q = primes[primes.len() - 1];
    println!("fixed prime {}, lists differing by {}: remainders {} and {}: fooled every run",
             q, q, rem(&x, q), rem(&sub_small(&x, q), q));
    let mut d25: Big = vec![0; 16]; d25[0] = 1;
    for &p in &primes[..25] { d25 = mul_small(&d25, p) }
    println!("primes below 100 only: {} of 25 fool the check, error 1", primes[..25].iter().filter(|&&p| rem(&d25, p) == 0).count());
    println!("ALL CHECKS PASS");
}
