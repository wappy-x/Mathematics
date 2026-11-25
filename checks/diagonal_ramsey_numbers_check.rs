// Diagonal Ramsey numbers -- the same check as the Python, in Rust.  No crates.
// R(k,k): the fewest dots n such that every red/blue colouring of the lines of K(n) has k dots joined
// all in one colour.  Ceilings: Erdos-Szekeres, three roads.  Floors: Erdos's count, and real colourings.

fn binom_pascal(n: usize, k: usize) -> u128 {  // road 1: build Pascal's triangle row by row
    let mut row: Vec<u128> = vec![1];
    for _ in 0..n {
        let mut next = vec![1u128];
        for i in 0..row.len() - 1 { next.push(row[i] + row[i + 1]); }
        next.push(1);
        row = next;
    }
    row[k]
}

fn binom_prod(n: u128, k: u128) -> u128 {      // road 2: falling product over a factorial
    let (mut top, mut bot) = (1u128, 1u128);
    for i in 0..k { top *= n - i; bot *= i + 1; }
    top / bot
}

fn rec(s: u128, t: u128) -> u128 {             // road 3: the recursion R(s,t) <= R(s-1,t) + R(s,t-1)
    if s == 2 { t } else if t == 2 { s } else { rec(s - 1, t) + rec(s, t - 1) }
}

fn count_floor(k: u128) -> u128 {              // largest n with 2 C(n,k) < 2^C(k,2): some colouring dodges
    let mut n = k;
    while 2 * binom_prod(n + 1, k) < 1u128 << binom_prod(k, 2) { n += 1; }
    n
}

fn cliques(adj: &[u128], m: u128, k: u32, lo: usize) -> u64 {  // k-sets inside m, every line among them in adj
    if k == 0 { return 1; }
    (lo..adj.len()).filter(|&v| m >> v & 1 == 1).map(|v| cliques(adj, adj[v] & m, k - 1, v + 1)).sum()
}

fn full(q: usize) -> u128 { if q == 128 { u128::MAX } else { (1u128 << q) - 1 } }

fn paley(q: usize) -> (Vec<u128>, Vec<u128>) {  // red line i-j when the gap j - i is a nonzero square mod q
    let sq: Vec<usize> = (1..q).map(|x| x * x % q).collect();
    let red: Vec<u128> = (0..q).map(|i| (0..q).filter(|&j| sq.contains(&((j + q - i) % q)) && j != i).map(|j| 1u128 << j).sum()).collect();
    let blue: Vec<u128> = red.iter().enumerate().map(|(i, &a)| full(q) ^ a ^ (1u128 << i)).collect();
    (red, blue)
}

fn dodgers(n: usize) -> u64 {                   // colourings of K(n) with no one-colour triangle, by listing
    let mut idx = vec![vec![0usize; n]; n];
    let mut b = 0;
    for i in 0..n { for j in i + 1..n { idx[i][j] = b; b += 1; } }
    let mut tri = vec![];
    for a in 0..n { for x in a + 1..n { for c in x + 1..n { tri.push((idx[a][x], idx[a][c], idx[x][c])); } } }
    let mut good = 0;
    for col in 0u32..1 << b {
        if tri.iter().all(|&(x, y, z)| { let s = (col >> x & 1) + (col >> y & 1) + (col >> z & 1); s > 0 && s < 3 }) { good += 1; }
    }
    good
}

fn sci(log10x: f64) -> String {                 // a number given by its log10, printed as m.mme+XX
    let e = log10x.floor();
    format!("{:.2}e+{}", 10f64.powf(log10x - e), e as i64)
}

fn known(k: u128) -> (u128, u128) {
    match k { 3 => (6, 6), 4 => (18, 18), 5 => (43, 46), 6 => (102, 160), 7 => (205, 492), 8 => (282, 1518), 9 => (565, 4956), _ => (798, 16064) }
}

fn main() {
    println!("k = 5, the card's example");
    let (p5, q5, r5) = (binom_pascal(8, 4), binom_prod(8, 4), rec(5, 5));
    println!("ceiling, Erdos-Szekeres: C(8,4) = {} by Pascal's triangle, {} by the falling product, {} by the recursion", p5, q5, r5);
    let f5 = count_floor(5);
    println!("floor, clean form: 2^(5/2) = {:.2}, so R(5,5) > {}", 32f64.sqrt(), 32f64.sqrt().floor() as u64);
    println!("floor, exact count: 2 x C({},5) = {} < 2^10 = {} <= 2 x C({},5) = {}, so R(5,5) > {}",
             f5, 2 * binom_prod(f5, 5), 1u32 << 10, f5 + 1, 2 * binom_prod(f5 + 1, 5), f5);
    let (red37, blue37) = paley(37);
    let (k5r, k5b) = (cliques(&red37, full(37), 5, 0), cliques(&blue37, full(37), 5, 0));
    println!("floor, Paley colouring of K(37): one-colour K(5)s {} red + {} blue of {}, so R(5,5) > 37", k5r, k5b, binom_prod(37, 5));
    let (red41, blue41) = paley(41);
    let k41 = cliques(&red41, full(41), 5, 0) + cliques(&blue41, full(41), 5, 0);
    println!("the same rule on K(41): one-colour K(5)s {}, so the pattern stops", k41);
    println!("known, quoted: {} <= R(5,5) <= {}", known(5).0, known(5).1);
    println!("lines among 43 dots C(43,2) = {}; fifth roots 43^(1/5) = {:.2}, 46^(1/5) = {:.2}; sqrt(2) = {:.2}",
             binom_prod(43, 2), 43f64.powf(0.2), 46f64.powf(0.2), 2f64.sqrt());
    let (d5, d6) = (dodgers(5), dodgers(6));
    println!("search: K(5) colourings with no one-colour triangle {} of {}; K(6) {} of {}, so R(3,3) = 6", d5, 1u32 << 10, d6, 1u32 << 15);
    let (red17, blue17) = paley(17);
    let k17 = cliques(&red17, full(17), 4, 0) + cliques(&blue17, full(17), 4, 0);
    println!("Paley colouring of K(17): one-colour K(4)s {} of {}, so R(4,4) > 17", k17, binom_prod(17, 4));
    let (red101, blue101) = paley(101);
    let k101 = (cliques(&red101, red101[0], 5, 0), cliques(&blue101, blue101[0], 5, 0));
    println!("Paley colouring of K(101): one-colour K(6)s through dot 0, {} red + {} blue; shifting moves any K(6) onto dot 0, so R(6,6) > 101", k101.0, k101.1);
    println!("  k  2^(k/2)  count floor  known lower  known upper  C(2k-2,k-1)     4^(k-1)");
    for k in 3u128..11 {
        let (lo, hi) = known(k);
        println!("{:>3}{:>9.2}{:>13}{:>13}{:>13}{:>13}{:>12}", k, ((1u128 << k) as f64).sqrt(), count_floor(k), lo, hi, binom_prod(2 * k - 2, k - 1), 1u128 << (2 * (k - 1)));
    }
    println!("k = 100");
    let l10c: f64 = (1..100).map(|i| ((99 + i) as f64 / i as f64).log10()).sum();
    println!("floor 2^50 = {} = {}; ceiling C(198,99) = {}; 4^100 = {}", 1u64 << 50, sci(50.0 * 2f64.log10()), sci(l10c), sci(200.0 * 2f64.log10()));
    println!("2^50 to C(198,99) spans {} powers of ten", l10c.floor() as i64 - (50.0 * 2f64.log10()).floor() as i64);
    let b7 = 4.0 - 2f64.powi(-7);
    println!("(4 - 2^-7)^100 = {}; 3.8^100 = {}", sci(100.0 * b7.log10()), sci(100.0 * 3.8f64.log10()));
    let (mut lc, mut k, mut cross): (f64, u64, [u64; 2]) = (0.0, 1, [0, 0]);
    while cross[0] == 0 || cross[1] == 0 {      // lc = log2 C(2k-2, k-1), grown one k at a time
        lc += (((2 * k - 1) * (2 * k)) as f64 / (k * k) as f64).log2();
        k += 1;
        for (i, base) in [3.8f64, b7].iter().enumerate() {
            if cross[i] == 0 && (k as f64) * base.log2() < lc { cross[i] = k; }
        }
    }
    println!("first k where base^k falls below C(2k-2,k-1): 3.8 at k = {}, 4 - 2^-7 = {} at k = {}", cross[0], b7, cross[1]);
    let ks: Vec<u128> = (2..21).step_by(2).collect();
    println!("chart, k: {}", ks.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, log2 floor k/2: {}", ks.iter().map(|&k| format!("{:.2}", k as f64 / 2.0)).collect::<Vec<_>>().join(", "));
    println!("chart, log2 C(2k-2,k-1): {}", ks.iter().map(|&k| format!("{:.2}", (binom_prod(2 * k - 2, k - 1) as f64).log2())).collect::<Vec<_>>().join(", "));
    println!("chart, log2 4^k: {}", ks.iter().map(|&k| format!("{:.2}", 2.0 * k as f64)).collect::<Vec<_>>().join(", "));
    println!("mistake 1, clean floor taken as the count's best: R(5,5) > {} against > {}", 32f64.sqrt().floor() as u64, f5);
    println!("mistake 2, ceiling read as the value: R(5,5) = {} against at most 46", p5);
    println!("mistake 3, 4^k written for the ceiling: 4^5 = {} against C(8,4) = {}", 1u32 << 10, p5);
    assert!(p5 == q5 && q5 == r5 && r5 == 70);  // three roads to the ceiling agree
    assert!((2..12u128).all(|k| binom_pascal(2 * k as usize - 2, k as usize - 1) == binom_prod(2 * k - 2, k - 1)
        && binom_prod(2 * k - 2, k - 1) == rec(k, k) && rec(k, k) <= 1u128 << (2 * (k - 1))));
    assert!(2 * binom_prod(f5, 5) < 1024 && 1024 <= 2 * binom_prod(f5 + 1, 5) && f5 >= 32f64.sqrt().floor() as u128);
    assert!((d5, d6) == (12, 0) && k17 == 0 && (k5r, k5b) == (0, 0) && k41 > 0 && k101 == (0, 0));
    assert!((3u128..11).all(|k| count_floor(k) < known(k).0 && known(k).0 <= known(k).1 && known(k).1 <= binom_prod(2 * k - 2, k - 1)));
    assert!(cross[0] < 100 && 100 < cross[1]);  // the 2023 base beats the binomial only for very large k
    println!("ALL CHECKS PASS");
}
