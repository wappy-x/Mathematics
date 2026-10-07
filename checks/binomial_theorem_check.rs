// The binomial theorem -- the same check as the Python, in Rust.  No crates.  Three roads
// to (10 + 1)^4 = 14,641: Pascal's triangle built by adding neighbours, the same counts from
// factorials, and all 16 picks multiplied out.  Then $100 at 5%, and (100 + 10 + 1)^3 = 111^3.
fn rows() -> Vec<Vec<i128>> {                    // road one: a row from the row above
    let mut out: Vec<Vec<i128>> = vec![vec![1]];
    for _ in 0..10 {
        let p = out[out.len() - 1].clone();
        let mut r: Vec<i128> = (0..p.len() - 1).map(|i| p[i] + p[i + 1]).collect();
        r.insert(0, 1); r.push(1);
        out.push(r);
    }
    out
}
fn fact(m: i128) -> i128 { let mut out = 1; for i in 2..=m { out *= i } out }
fn choose(n: i128, k: i128) -> i128 { fact(n) / (fact(k) * fact(n - k)) }   // road two
fn expand(rows: &[Vec<i128>], a: i128, b: i128, n: usize) -> Vec<i128> {
    (0..=n).map(|k| rows[n][k] * a.pow((n - k) as u32) * b.pow(k as u32)).collect()
}
fn picks(parts: &[i128], n: u32) -> i128 {       // road three: every pick from every bracket
    let m = parts.len() as i128;
    let mut total = 0;
    for word in 0..m.pow(n) {
        let (mut prod, mut w) = (1i128, word);
        for _ in 0..n { prod *= parts[(w % m) as usize]; w /= m }
        total += prod;
    }
    total
}
fn split3(a: i128, b: i128, c: i128, n: i128) -> i128 {    // n!/(i! j! l!) over every split
    let mut total = 0;
    for i in 0..=n { for j in 0..=(n - i) {
        let l = n - i - j;
        total += fact(n) / (fact(i) * fact(j) * fact(l)) * a.pow(i as u32) * b.pow(j as u32) * c.pow(l as u32);
    }}
    total
}
fn money(c: i128) -> String { format!("{}.{:02}", c / 100, c % 100) }       // cents as dollars
fn main() {
    let rw = rows();
    let (terms, signed) = (expand(&rw, 10, 1, 4), expand(&rw, 10, -1, 4));
    let (sum_t, sum_s): (i128, i128) = (terms.iter().sum(), signed.iter().sum());
    let digits: i128 = rw[5].iter().map(|v| v.to_string()).collect::<String>().parse().unwrap();
    let cents: Vec<i128> = (0..=10).map(|m| {                          // exact, in whole cents
        let partial: i128 = (0..=m).map(|k| rw[10][k] * 100i128.pow((10 - k) as u32) * 5i128.pow(k as u32)).sum();
        (partial + 5 * 10i128.pow(15)) / 10i128.pow(16)
    }).collect();
    let mut grown = 100.0f64;
    for _ in 0..10 { grown *= 1.05 }             // the same ten years, by multiplying
    let alt = |r: &Vec<i128>| -> i128 { r.iter().enumerate().map(|(k, v)| if k % 2 == 0 { *v } else { -v }).sum() };
    let laws = rw.iter().enumerate()
        .all(|(n, r)| r.iter().sum::<i128>() == 1i128 << n && (n == 0 || alt(r) == 0));
    let row10: i128 = rw[10].iter().sum();
    let by_fact: Vec<i128> = (0..=4).map(|k| choose(4, k)).collect();
    println!("row 4 by adding neighbours: {:?}; by factorials: {:?}", rw[4], by_fact);
    println!("(10 + 1)^4 term by term: {} = {}; 11^4 = {}",
             terms.iter().map(|t| t.to_string()).collect::<Vec<String>>().join(" + "), sum_t, 11i128.pow(4));
    println!("all {} picks from the four brackets, multiplied and added: {}", 2i32.pow(4), picks(&[10, 1], 4));
    println!("(10 - 1)^4 term by term: {:?} adds to {}; 9^4 = {}", signed, sum_s, 9i128.pow(4));
    println!("row 5: {:?}; pasted together as digits {}, but 11^5 = {}", rw[5], digits, 11i128.pow(5));
    println!("row 10: {:?}", rw[10]);
    println!("row 10 added up: {}; with alternating signs: {}", row10, alt(&rw[10]));
    println!("every row 0 to 10 adds to 2^n, and alternates to 0 after row 0: {}",
             if laws { "yes" } else { "no" });
    println!("$100 at 5% for ten years, one term at a time: {}",
             cents.iter().map(|&c| money(c)).collect::<Vec<String>>().join(" "));
    println!("the same balance by multiplying 1.05 in ten times: {:.2}", grown);
    println!("first two terms alone: {}, simple interest; the other nine: {}",
             money(cents[1]), money(cents[10] - cents[1]));
    println!("(100 + 10 + 1)^3 by split counts: {}; 111^3 = {}", split3(100, 10, 1, 3), 111i128.pow(3));
    println!("all {} picks from the three brackets, multiplied and added: {}", 3i32.pow(3), picks(&[100, 10, 1], 3));
    println!("one bracket each: 3!/(1!1!1!) = {} orders, term {}", fact(3) / fact(1).pow(3), fact(3) * 100 * 10);
    println!("mistake 1, (10 + 1)^4 read as 10^4 + 1^4: {}, not {}", 10i128.pow(4) + 1, sum_t);
    println!("mistake 2, the counts dropped: {}, not {}", (0..=4).map(|k| 10i128.pow(4 - k)).sum::<i128>(), sum_t);
    println!("mistake 3, (10 - 1)^4 with the minus signs lost: {}, not {}", sum_t, sum_s);
    assert!(sum_t == picks(&[10, 1], 4) && sum_t == 11i128.pow(4) && sum_t == 14641);
    assert!(by_fact == rw[4] && row10 == 1i128 << 10);
    assert!(sum_s == 9i128.pow(4) && (grown * 100.0).round() as i128 == cents[10] && cents[10] == 16289);
    assert!(split3(100, 10, 1, 3) == picks(&[100, 10, 1], 3) && split3(100, 10, 1, 3) == 111i128.pow(3) && laws);
    println!("ALL CHECKS PASS");
}
