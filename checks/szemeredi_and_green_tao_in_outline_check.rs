// Long progressions -- the same check as the Python, in Rust.  No crates.
// A progression is a, a+d, a+2d, ... with step d > 0.  The card's example is
// 5, 11, 17, 23, 29.  Road one tests primes by a sieve, road two by trial
// division.  The smallest prime progressions found by search must obey the
// mod-p rule proved on the card.  Small-set facts (van der Waerden, the largest
// set with no 3-term progression) are found by exhaustive search.  The rough
// number counts are made by a sieve and again by Legendre's formula.
use std::collections::HashSet;
fn commas(n: usize) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
fn list(v: &[usize]) -> String {
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn trial(n: usize) -> bool { n > 1 && (2..).take_while(|q| q * q <= n).all(|q| n % q != 0) }
fn sieve(n: usize, upto: usize) -> Vec<bool> {      // crosses out multiples of primes <= upto
    let mut s = vec![true; n + 1]; s[0] = false; s[1] = false;
    for i in 2..=upto.min(n) {
        if upto < n || s[i] { let mut j = if upto < n { i } else { i * i }; while j <= n { s[j] = false; j += i; } }
    }
    s
}
fn has3(s: &[usize]) -> bool {
    let t: HashSet<usize> = s.iter().cloned().collect();
    (0..s.len()).any(|i| (i + 1..s.len()).any(|j| (s[i] + s[j]) % 2 == 0 && t.contains(&((s[i] + s[j]) / 2))))
}
fn mono3(col: usize, n: usize) -> bool {
    (1..n).any(|d| (1..(n + 1).saturating_sub(2 * d)).any(|a| {
        let (x, y, z) = (col >> (a - 1) & 1, col >> (a + d - 1) & 1, col >> (a + 2 * d - 1) & 1);
        x == y && y == z }))
}
fn dfs(pos: usize, c: usize, n: usize, want: usize, r: &[usize], ch: &mut Vec<usize>, cs: &mut HashSet<i64>) -> bool {
    if c == want { return true; }
    if pos > n || c + r[n - pos + 1] < want { return false; }
    if !ch.iter().any(|&y| cs.contains(&(2 * y as i64 - pos as i64))) {
        ch.push(pos); cs.insert(pos as i64);
        if dfs(pos + 1, c + 1, n, want, r, ch, cs) { return true; }
        ch.pop(); cs.remove(&(pos as i64));
    }
    dfs(pos + 1, c, n, want, r, ch, cs)
}
fn r3(top: usize) -> Vec<usize> {                  // largest set in 1..n with no 3-term progression
    let mut r = vec![0usize; top + 1];
    for n in 1..=top {
        let want = r[n - 1] + 1; r[n] = want;
        if !dfs(1, 0, n, want, &r.clone(), &mut Vec::new(), &mut HashSet::new()) { r[n] = want - 1; }
    }
    r
}
fn base3(n: usize) -> Vec<usize> {                 // 1 + numbers with base-3 digits 0 and 1
    (0..n).filter(|&m| (0..11).all(|j| (m / 3usize.pow(j)) % 3 < 2)).map(|m| m + 1).collect()
}
fn legendre(n: i64, ps: &[usize]) -> i64 {         // sum of mu(d) floor(n/d) over d | P(z)
    let mut t = 0i64;
    for m in 0..(1usize << ps.len()) {
        let (mut d, mut s) = (1i64, 1i64);
        for (j, &p) in ps.iter().enumerate() { if m >> j & 1 == 1 { d *= p as i64; s = -s; } }
        t += s * (n / d);
    }
    t
}
fn main() {
    let big = 1_000_000usize;
    let sv = sieve(big, big);
    let pr: Vec<usize> = (0..=big).filter(|&i| sv[i]).collect();
    let ex: Vec<usize> = (0..5).map(|i| 5 + 6 * i).collect();
    println!("example: {} sieve {} trial {}", list(&ex), py(ex.iter().all(|&n| sv[n])), py(ex.iter().all(|&n| trial(n))));
    println!("residues mod 5: {} ; next term 35 = 5 x 7 ; term before -1", list(&ex.iter().map(|n| n % 5).collect::<Vec<_>>()));
    let skip: Vec<usize> = pr.iter().cloned().filter(|&p| 5 < p && p < 29 && !ex.contains(&p)).collect();
    println!("primes between 5 and 29 that it skips: {}", list(&skip));
    assert!(ex.iter().all(|&n| sv[n]) && ex.iter().all(|&n| trial(n)) && !trial(35));
    let d6 = [6usize, 30];                            // the two steps tried for six terms
    let six: Vec<usize> = d6.iter().map(|&d| pr.iter().filter(|&&a| a + 5 * d <= big && (0..6).all(|i| sv[a + d * i])).count()).collect();
    let st: Vec<String> = d6.iter().zip(&six).map(|(d, c)| format!("step {}: {}", d, commas(*c))).collect();
    println!("6-term prime progressions up to 10^6: {}", st.join(" ; "));
    println!("k | first term | step | last term | primes p <= k dividing step");
    for k in 3..=10usize {
        let (mut a, mut d, mut last) = (0, 0, 0);
        'outer: for &l in &pr {
            for dd in 1..=(l - 2) / (k - 1) {
                if (0..k).all(|i| sv[l - i * dd]) { a = l - (k - 1) * dd; d = dd; last = l; break 'outer; }
            }
        }
        let small: Vec<usize> = pr.iter().cloned().filter(|&p| p <= k).collect();
        let div: Vec<usize> = small.iter().cloned().filter(|p| d % p == 0).collect();
        println!("{} | {} | {} | {} | {}", k, a, d, commas(last), list(&div));
        for &p in &small { assert!(d % p == 0 || (p >= a && (p - a) % d == 0 && p <= last)); }
        assert!((0..k).all(|i| trial(a + i * d)));
    }
    let m4 = 10_000usize;
    let mut cnt = [0usize; 9];
    for &a in pr.iter().take_while(|&&a| a <= m4) {
        for d in 1..=(m4 - a) / 2 {
            let mut r = 1;
            while r < 8 && a + r * d <= m4 && sv[a + r * d] { r += 1; }
            for k in 3..=r { cnt[k] += 1; }
        }
    }
    let cs: Vec<String> = cnt[3..9].iter().map(|&c| format!("'{}'", commas(c))).collect();
    println!("prime progressions with every term <= {}: k=3..8: [{}]", commas(m4), cs.join(", "));
    let free8: Vec<usize> = (0..256).filter(|&c| !mono3(c, 8)).collect();
    let free9: Vec<usize> = (0..512).filter(|&c| !mono3(c, 9)).collect();
    println!("2-colourings of 1..8 with no one-colour 3-term progression: {}; of 1..9: {}", free8.len(), free9.len());
    let dodge: String = (0..8).map(|i| if free8[0] >> i & 1 == 1 { 'B' } else { 'R' }).collect();
    println!("one that dodges, 1..8: {}", dodge);
    assert!(free8.len() > 0 && free9.is_empty());
    let r = r3(60);
    println!("N | r3(N) | r3(N)/N | base-3 set size | its share");
    for &n in &[9usize, 20, 27, 40, 60, 81, 729, 59049] {
        let b = base3(n);
        if n <= 729 { assert!(!has3(&b)); }
        let rr = if n <= 60 { format!("{} | {:.3}", r[n], r[n] as f64 / n as f64) } else { "- | -".to_string() };
        println!("{} | {} | {} | {:.3}", commas(n), rr, commas(b.len()), b.len() as f64 / n as f64);
    }
    let brute: Vec<usize> = (1..=12usize).map(|n| (0..1usize << n).filter(|&s| {
        let set: Vec<usize> = (0..n).filter(|i| s >> i & 1 == 1).map(|i| i + 1).collect(); !has3(&set)
    }).map(|s| s.count_ones() as usize).max().unwrap()).collect();
    println!("r3(1..12) by trying every subset: {}", list(&brute));
    assert!(brute[..] == r[1..13] && r[20] == 9);
    let pw: Vec<usize> = (0..20).map(|j| 1usize << j).collect();
    println!("powers of 2 up to 10^6: {} numbers, 3-term progressions: {}", pw.len(), has3(&pw) as u8);
    println!("N | z | primes <= N | share of all | z-rough in 2..N | primes among them | share");
    let mut chart: Vec<(f64, f64)> = Vec::new();
    for e in 3..=6u32 {
        let n = 10usize.pow(e);
        let z = ((n as f64).powf(0.25) + 1e-9) as usize;
        let ps: Vec<usize> = pr.iter().cloned().filter(|&p| p <= z).collect();
        let m = sieve(n, z);
        let rough = m.iter().filter(|&&b| b).count();
        let pin = pr.iter().filter(|&&p| z < p && p <= n).count();
        let pi = pin + ps.len();
        assert!(rough as i64 == legendre(n as i64, &ps) - 1 && pin == pr.iter().filter(|&&p| p <= n && m[p]).count());
        chart.push((pi as f64 / n as f64, pin as f64 / rough as f64));
        println!("10^{} | {} | {} | {:.4} | {} | {} | {:.4}", e, z, commas(pi), pi as f64 / n as f64, commas(rough), commas(pin), pin as f64 / rough as f64);
    }
    println!("chart, share of all: {}", chart.iter().map(|c| format!("{:.3}", c.0)).collect::<Vec<_>>().join(", "));
    println!("chart, share of rough: {}", chart.iter().map(|c| format!("{:.3}", c.1)).collect::<Vec<_>>().join(", "));
    let zt = 100usize;                                // try: z = N^(1/3) = 100
    let m = sieve(big, zt);
    let rough = m.iter().filter(|&&b| b).count();
    let below = pr.iter().filter(|&&p| p <= zt).count();
    println!("try: z = {} at 10^6: rough {}, prime share {:.4}", zt, commas(rough), (pr.len() - below) as f64 / rough as f64);
    assert!(six[0] == 0 && 0 < six[1] && pr.len() == 78498 && chart[3].1 > 0.5 && 0.5 > 6.0 * chart[3].0);
    println!("ALL CHECKS PASS");
}
