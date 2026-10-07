// Exponential generating functions -- the same check as the Python, in Rust.  No
// crates.  A Scrabble rack holds five tiles: A, A, B, B, C.  How many words of each
// length it can spell is found three ways: by multiplying one series per letter and
// reading n! times the coefficient of x^n, by choosing which places each letter
// fills, and by listing every word.  Lengths n = 0 up to 5.
const RACK: [(char, i64); 3] = [('A', 2), ('B', 2), ('C', 1)];
const TOP: usize = 5;
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn fact(n: i64) -> i64 { if n < 2 { 1 } else { n * fact(n - 1) } }
fn choose(n: i64, k: i64) -> i64 { fact(n) / (fact(k) * fact(n - k)) }   // C(n, k)
fn frac(a: i64, b: i64) -> String {                                    // lowest terms
    let g = if gcd(a, b) == 0 { 1 } else { gcd(a, b) };
    if b / g == 1 { format!("{}", a / g) } else { format!("{}/{}", a / g, b / g) }
}
fn row(num: &[i64], den: i64) -> String {
    num.iter().map(|&c| frac(c, den)).collect::<Vec<String>>().join(", ")
}
fn conv(p: &[i64], q: &[i64]) -> Vec<i64> {                            // plain product
    (0..p.len() + q.len() - 1).map(|n| (0..=n).filter(|&i| i < p.len() && n - i < q.len())
        .map(|i| p[i] * q[n - i]).sum()).collect()
}
fn bconv(u: &[i64], v: &[i64]) -> Vec<i64> {                           // split the places
    (0..u.len().min(v.len())).map(|n| (0..=n).map(|k| choose(n as i64, k as i64) * u[k] * v[n - k]).sum()).collect()
}
fn digits(code: usize, base: usize, n: usize) -> Vec<usize> {
    (0..n).map(|i| code / base.pow(i as u32) % base).collect()
}
fn words(n: usize) -> Vec<Vec<usize>> {                                // list them all
    (0..RACK.len().pow(n as u32)).map(|c| digits(c, RACK.len(), n))
        .filter(|w| (0..RACK.len()).all(|i| w.iter().filter(|&&x| x == i).count() as i64 <= RACK[i].1)).collect()
}
fn shape(w: &[usize]) -> String {                                      // the word's letters, sorted
    let mut s = w.to_vec(); s.sort();
    s.iter().map(|&i| RACK[i].0).collect()
}
fn main() {
    let (mut num, mut den, mut shown) = (vec![1i64], 1i64, Vec::new());  // road one
    for &(_, copies) in RACK.iter() {
        num = conv(&num, &(0..=copies).map(|j| fact(copies) / fact(j)).collect::<Vec<i64>>());
        den *= fact(copies);
        shown.push(row(&num, den));
    }
    let egf: Vec<i64> = (0..=TOP).map(|n| fact(n as i64) * num[n] / den).collect();
    let (mut acc, mut parts) = (vec![0i64; TOP + 1], Vec::new());        // road two
    acc[0] = 1;
    for &(_, copies) in RACK.iter() {
        acc = bconv(&acc, &(0..=TOP).map(|j| if j <= copies as usize { 1 } else { 0 }).collect::<Vec<i64>>());
        parts.push(acc.clone());
    }
    let ab = &parts[1];
    let listed: Vec<i64> = (0..=TOP).map(|n| words(n).len() as i64).collect();
    let mut keys: Vec<String> = words(4).iter().map(|w| shape(w)).collect();
    keys.sort();
    let mut kinds: Vec<(String, i64)> = Vec::new();
    for s in keys { match kinds.last_mut() { Some(k) if k.0 == s => k.1 += 1, _ => kinds.push((s, 1)) } }
    let mut osel = vec![1i64];                                  // the ordinary series
    for &(_, copies) in RACK.iter() { osel = conv(&osel, &vec![1i64; copies as usize + 1]) }
    let tiles = (0..5usize.pow(4)).filter(|&c| { let mut d = digits(c, 5, 4); d.sort(); d.dedup(); d.len() == 4 }).count() as i64;
    let (s3, s4, mp) = (choose(4, 3) * ab[3], ab[4], fact(5) / (fact(2) * fact(2)));
    println!("rack: {}; one series per letter", RACK.iter().map(|&(l, c)| format!("{} x {}", l, c)).collect::<Vec<String>>().join(", "));
    println!("coefficients of x^0 up, after the A tile: {}", shown[0]);
    println!("after the B tile as well: {}", shown[1]);
    println!("after the C tile, the whole rack: {}", shown[2]);
    println!("road one, n! times the coefficient of x^n: {:?}", egf);
    println!("road two, choosing which places each letter fills: {:?}", acc);
    println!("road three, listing every word: {:?}", listed);
    println!("the split at n = 4: C(4,3) x {} = {}, C(4,4) x {} = {}, total {}", ab[3], s3, ab[4], s4, s3 + s4);
    println!("four-letter words: 4! x {} = {} x {} = {}", frac(num[4], den), fact(4), frac(num[4], den), egf[4]);
    println!("five-letter words: 5! x {} = {} x {} = {}, and 5!/(2! 2!) = {}", frac(num[5], den), fact(5), frac(num[5], den), egf[5], mp);
    println!("the four-letter words by selection: {}", kinds.iter().map(|(s, c)| format!("{} {}", s, c)).collect::<Vec<String>>().join(", "));
    println!("mistake 1, the ordinary series read ordinarily: {} selections, not {} words", osel[4], egf[4]);
    println!("mistake 2, the coefficient of x^4 left as it stands: {}, not a count", frac(num[4], den));
    println!("mistake 3, all five tiles taken as distinct: {}, each word {} times over", tiles, tiles / egf[4]);
    println!("mistake 4, no division by 2! but still times 4!: {} x {} = {}", fact(4), osel[4], fact(4) * osel[4]);
    assert!(egf == listed);                          // the series road against the listing
    assert!(acc == listed);                          // the choosing road against the listing
    assert!(listed[5] == mp && tiles == listed[4] * fact(2) * fact(2));
    assert!(osel[4] == kinds.len() as i64);          // selections, two ways
    println!("ALL CHECKS PASS");
}
