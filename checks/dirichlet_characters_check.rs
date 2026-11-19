// Dirichlet characters mod 10 and the primes ending in 3 -- the same check as the
// Python, in Rust.  No crates.  A character value i^k is stored exactly as k mod 4,
// and every sum is a Gaussian integer (re, im), so no rounding enters.
// Road one counts primes by last digit.  Road two adds each character over the
// primes and filters with orthogonality.  The characters themselves are found
// twice: from the generator 3, and by trying every possible table.
type G = (i64, i64);
const Q: usize = 10;
const X: usize = 1_000_000;
const IPOW: [G; 4] = [(1, 0), (0, 1), (-1, 0), (0, -1)];   // i^0, i^1, i^2, i^3

fn gcd(mut a: usize, mut b: usize) -> usize {   // Euclid's algorithm, written out
    while b != 0 { (a, b) = (b, a % b) }
    a
}
fn gadd(a: G, b: G) -> G { (a.0 + b.0, a.1 + b.1) }
fn gmul(a: G, b: G) -> G { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn conj(a: G) -> G { (a.0, -a.1) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn show(z: G) -> String {                       // a Gaussian integer as text: 24 + 44i
    let (re, im) = z;
    if im == 0 { return re.to_string() }
    let i_part = format!("{}i", if im.abs() == 1 { String::new() } else { im.abs().to_string() });
    if re == 0 { return format!("{}{}", if im < 0 { "-" } else { "" }, i_part) }
    format!("{} {} {}", re, if im < 0 { "-" } else { "+" }, i_part)
}

fn units_of(q: usize) -> Vec<usize> { (1..q).filter(|&n| gcd(n, q) == 1).collect() }

fn all_characters(q: usize) -> (usize, Vec<Vec<usize>>) {   // brute force: every multiplicative table
    let units = units_of(q);
    let m = units.len();                        // values are m-th roots of unity, m = phi(q)
    let mut found = Vec::new();
    for code in 0..m.pow(m as u32) {
        let mut e = vec![0usize; q];
        for (j, &u) in units.iter().enumerate() { e[u] = (code / m.pow(j as u32)) % m }
        if e[1] == 0 && units.iter().all(|&a| units.iter().all(|&b| e[a * b % q] == (e[a] + e[b]) % m)) {
            found.push(units.iter().map(|&u| e[u]).collect());
        }
    }
    (m, found)
}

fn main() {
    let units = units_of(Q);
    let mut ind = [usize::MAX; Q];              // road A: powers of the generator 3
    let (mut k, mut g) = (0, 1);
    while ind[g] == usize::MAX { ind[g] = k; g = g * 3 % Q; k += 1 }
    let chars: Vec<Vec<usize>> = (0..4).map(|j| (0..Q).map(|u| if ind[u] == usize::MAX { 0 } else { j * ind[u] % 4 }).collect()).collect();
    let val = |j: usize, n: usize| -> G { if gcd(n, Q) > 1 { (0, 0) } else { IPOW[chars[j][n % Q]] } };

    let pw: Vec<usize> = (0..4).map(|k| 3usize.pow(k) % Q).collect();
    println!("units mod 10: {:?}; powers of 3: {:?}", units, pw);
    println!("n       {}", units.iter().map(|u| format!("{:>4}", u)).collect::<String>());
    for j in 0..4 {
        println!("chi_{}   {}", j, units.iter().map(|&u| format!("{:>4}", show(IPOW[chars[j][u]]))).collect::<String>());
    }
    let (_, mut brute) = all_characters(Q);     // road B: try all 4^4 = 256 tables
    brute.sort();
    let mut from_gen: Vec<Vec<usize>> = (0..4).map(|j| units.iter().map(|&u| chars[j][u]).collect()).collect();
    from_gen.sort();
    println!("characters mod 10 by trying all 256 tables: {}; same as from the generator: {}", brute.len(), yn(brute == from_gen));
    assert!(brute == from_gen);
    for q in [7, 8, 12] {
        let (m, found) = all_characters(q);
        let real = found.iter().filter(|f| f.iter().all(|&v| 2 * v % m == 0)).count();
        println!("mod {}: phi = {}, characters found = {}, real ones = {}", q, m, found.len(), real);
        assert!(found.len() == m);              // as many characters as units
    }

    let mult = (0..4).all(|j| (1..=200).all(|a| (1..=200).all(|b| val(j, a * b) == gmul(val(j, a), val(j, b)))));
    println!("chi(ab) = chi(a) chi(b) for every a, b up to 200 and every chi: {}", yn(mult));
    assert!(mult);
    let mut rows = [[(0i64, 0i64); 4]; 4];
    for j in 0..4 { for kk in 0..4 { for &u in &units { rows[j][kk] = gadd(rows[j][kk], gmul(val(j, u), conj(val(kk, u)))) } } }
    let rs: Vec<String> = rows.iter().map(|r| r.iter().map(|&z| show(z)).collect::<Vec<_>>().join(" ")).collect();
    println!("sum over n of chi_j(n) times conj chi_k(n): {}", rs.join(" | "));
    let filt: Vec<String> = (1..=10).map(|n| show((0..4).fold((0, 0), |s, j| gadd(s, gmul(conj(val(j, 3)), val(j, n)))))).collect();
    println!("sum over chi of conj chi(3) chi(n), n = 1..10: {}", filt.join(" "));
    assert!((0..4).all(|j| (0..4).all(|kk| rows[j][kk] == if j == kk { (4, 0) } else { (0, 0) })));
    assert!(filt == ["0", "0", "4", "0", "0", "0", "0", "0", "0", "0"]);

    let mut sieve = vec![true; X];              // primes below a million
    sieve[0] = false; sieve[1] = false;
    let mut p = 2;
    while p * p < X { if sieve[p] { let mut m = p * p; while m < X { sieve[m] = false; m += p } } p += 1 }
    println!("x        primes  end 1  end 3  end 7  end 9  S(chi_0)  S(chi_1)  S(chi_2)  4 x end 3 - S(chi_0)  ratio");
    let mut count = [0i64; 10];
    let mut s = [(0i64, 0i64); 4];
    let mut pi = 0;
    for p in 2..X {
        if sieve[p] {
            pi += 1;
            count[p % 10] += 1;                 // road one: read the last digit
            for j in 0..4 { s[j] = gadd(s[j], val(j, p)) }   // road two: add each character
        }
        if p + 1 == 10_000 || p + 1 == 100_000 || p + 1 == 1_000_000 {
            println!("{:<8} {:>6} {:>6} {:>6} {:>6} {:>6} {:>9} {:>9} {:>9}  {:>19}  {:.6}", p + 1, pi, count[1], count[3], count[7], count[9],
                     show(s[0]), show(s[1]), show(s[2]), 4 * count[3] - s[0].0, count[3] as f64 / (s[0].0 as f64 / 4.0));
        }
    }
    println!("S(chi_3) = {}, the conjugate of S(chi_1); primes ending in 2 or 5: {}", show(s[3]), count[2] + count[5]);
    println!("filter: end digit a, (1/4) sum of conj chi(a) S(chi), direct count");
    for &a in &units {
        let tot = (0..4).fold((0, 0), |t, j| gadd(t, gmul(conj(val(j, a)), s[j])));
        println!("  {}: {} / 4 = {}, direct {}", a, show(tot), tot.0 / 4, count[a]);
        assert!(tot.1 == 0 && tot.0 == 4 * count[a]);   // road two against road one, each class
    }
    let terms: Vec<G> = (0..4).map(|j| gmul(conj(val(j, 3)), s[j])).collect();
    let tsum: i64 = terms.iter().map(|t| t.0).sum();
    println!("ending in 3, term by term: {} = {}", terms.iter().map(|&t| format!("({})", show(t))).collect::<Vec<_>>().join(" + "), tsum);
    let mut dft = [(0i64, 0i64); 4];            // the same sums as a 4-point transform of the counts
    for j in 0..4 { for kk in 0..4 { dft[j] = gadd(dft[j], gmul((count[3usize.pow(kk as u32) % Q], 0), IPOW[j * kk % 4])) } }
    println!("transform of counts at 1, 3, 9, 7: {}", dft.iter().map(|&z| show(z)).collect::<Vec<_>>().join(" "));
    assert!(dft == s);                          // characters on a cyclic group are DFT columns
    println!("chart, bars {} {} {} {}, line {}", count[1], count[3], count[7], count[9], s[0].0 / 4);
    let lead = terms[1..].iter().map(|t| t.0).sum::<i64>() / 4;   // the three non-trivial terms, divided by 4
    let gap = units.iter().map(|&a| (count[a] as f64 - s[0].0 as f64 / 4.0).abs()).fold(0.0, f64::max);
    println!("lead of ending 3 over an even quarter: ({}) / 4 = {}; largest gap from {}: {:.2} percent",
             terms[1..].iter().map(|t| t.0.to_string()).collect::<Vec<_>>().join(" + "), lead, s[0].0 / 4, 100.0 * gap / (s[0].0 as f64 / 4.0));

    let wrong1 = (0..4).map(|j| gmul(val(j, 3), s[j]).0).sum::<i64>() / 4;
    let wrong2 = tsum / 10;
    let wrong3 = (terms[0].0 + terms[2].0) / 4;
    let wrong4 = (0..4).map(|j| gmul(conj(val(j, 5)), s[j]).0).sum::<i64>() / 4;
    println!("mistake 1, no conjugate: {}, the count ending in 7, not {}", wrong1, count[3]);
    println!("mistake 2, divide by q = 10, not phi(10) = 4: {}, not {}", wrong2, count[3]);
    println!("mistake 3, real characters only: {}, the average of {} and {}", wrong3, count[3], count[7]);
    println!("mistake 4, class 5, which shares a factor with 10: {}, though the prime 5 ends in 5", wrong4);
    let naive = |n: usize| -> usize { [0, 0, 0, 1, 0, 0, 0, 2, 0, 3][n] };   // 1, i, -1, -i in order of size
    let mut bad = (0, 0);
    'outer: for &a in &units { for &b in &units { if naive(a * b % Q) != (naive(a) + naive(b)) % 4 { bad = (a, b); break 'outer } } }
    println!("pattern 1, i, -1, -i on 1, 3, 7, 9: fails at {} x {}: f({}) = {}, f({}) f({}) = {}", bad.0, bad.1, bad.0 * bad.1 % Q,
             show(IPOW[naive(bad.0 * bad.1 % Q)]), bad.0, bad.1, show(IPOW[(naive(bad.0) + naive(bad.1)) % 4]));
    assert!(wrong1 == count[7] && wrong4 == 0);
    println!("ALL CHECKS PASS");
}
