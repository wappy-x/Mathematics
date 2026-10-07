// Pigeonhole, extended -- the same check as the Python, in Rust.  No crates.  100
// emails go into 12 folders and the fullest folder is found three ways: by the
// formula, by dealing the emails out one at a time, and by trying every filing at
// small sizes.  Then ten days of arrivals, and a run totalling a multiple of 10.
const N: i64 = 100;
const K: i64 = 12;
const M: i64 = 10;

fn ceil_div(n: i64, k: i64) -> i64 { (n + k - 1) / k }   // road one: n over k, rounded up

fn fullest(code: i64, n: i64, k: i64) -> i64 {           // the fullest box in one filing
    let (mut loads, mut c) = (vec![0i64; k as usize], code);
    for _ in 0..n { loads[(c % k) as usize] += 1; c /= k }
    *loads.iter().max().unwrap()
}

fn prefixes(vals: &[i64]) -> Vec<i64> {                  // running totals, the first one empty
    (0..=vals.len()).map(|j| vals[..j].iter().sum()).collect()
}

fn first_repeat(rs: &[i64]) -> Option<(usize, usize)> {  // the two boxes that must collide
    let mut seen: Vec<Option<usize>> = vec![None; M as usize];
    for (i, &r) in rs.iter().enumerate() {
        match seen[r as usize] { Some(j) => return Some((j, i)), None => seen[r as usize] = Some(i) }
    }
    None
}

fn runs(vals: &[i64], m: i64) -> Vec<(i64, i64, i64)> {  // road two: check every run directly
    let mut out = Vec::new();
    for i in 0..vals.len() { for j in i..vals.len() {
        let s: i64 = vals[i..=j].iter().sum();
        if s % m == 0 { out.push((i as i64 + 1, j as i64 + 1, s)) }
    } }
    out
}

fn main() {
    let arrivals: Vec<i64> = vec![23, 41, 17, 8, 36, 52, 12, 29, 4, 31];
    let (mut loads, q, r) = (vec![0i64; K as usize], N / K, N % K);
    for i in 0..N { loads[(i % K) as usize] += 1 }        // road two: hand the emails out in turn
    let cases: Vec<(i64, i64)> = (1..9).flat_map(|n| (1..5).map(move |k| (n, k))).collect();
    let attained = cases.iter().all(|&(n, k)|
        (0..k.pow(n as u32)).map(|c| fullest(c, n, k)).min().unwrap() == ceil_div(n, k));
    let (pre, found) = (prefixes(&arrivals), runs(&arrivals, M));
    let rems: Vec<i64> = pre.iter().map(|p| p % M).collect();
    let (i0, i1) = first_repeat(&rems).unwrap();
    let (mut seed, mut pig, mut hit) = (1i64, 0i64, 0i64);
    for _ in 0..2000 {                                   // our own random numbers, no crates
        let mut lst: Vec<i64> = Vec::new();
        for _ in 0..10 { seed = (1103515245 * seed + 12345) % 2147483648; lst.push(seed % 97 + 1) }
        let rs: Vec<i64> = prefixes(&lst).iter().map(|p| p % M).collect();
        if first_repeat(&rs).is_some() { pig += 1 }
        if !runs(&lst, M).is_empty() { hit += 1 }
    }
    let mx = *loads.iter().max().unwrap();
    println!("{} emails into {} folders: average load {}/{} = {:.4}, rounded up {}", N, K, N, K, N as f64 / K as f64, ceil_div(N, K));
    println!("cap every folder at {}: {} x {} = {}, {} emails left over; evenly, {} = {} x {} + {}", q, K, q, K * q, N - K * q, N, q, K, r);
    println!("{} folders of {} and {} folders of {}: {} + {} = {}", r, q + 1, K - r, q, r * (q + 1), (K - r) * q, N);
    println!("dealt one at a time, folder loads: {:?}, fullest {}", loads, mx);
    println!("every filing of n items into k boxes, n = 1..8, k = 1..4: {} cases, bound met and attained: {}", cases.len(), if attained { "yes" } else { "no" });
    println!("mistake 1, whole part of n/k plus 1, on 120 emails in {} folders: {}, the truth is {}\nmistake 2, 13 folders counted instead of {}: {}, not {}", K, 120 / K + 1, ceil_div(120, K), K, ceil_div(N, 13), ceil_div(N, K));
    println!("ten days of arrivals: {:?}\nrunning totals, starting with the empty one: {:?}\nremainders after dividing by {}: {:?}", arrivals, pre, M, rems);
    println!("{} totals into {} remainder boxes: totals {} and {} both leave {}\ndays {} to {} sum to {} - {} = {}, a multiple of {}", pre.len(), M, pre[i0], pre[i1], rems[i1], i0 + 1, i1, pre[i1], pre[i0], pre[i1] - pre[i0], M);
    println!("every run summing to a multiple of {}, by search: {:?}", M, found);
    println!("mistake 3, the empty total left out: {} totals, {} boxes, nothing forced", pre.len() - 1, M);
    println!("2000 random ten-day lists: {} found a run by remainders, {} by search", pig, hit);
    assert!(ceil_div(N, K) == mx && loads.iter().filter(|&&x| x == q + 1).count() as i64 == r);
    assert!(attained && fullest(0, N, K) == N);
    assert!((i0, i1) == (4, 7) && found.contains(&(i0 as i64 + 1, i1 as i64, pre[i1] - pre[i0])));
    assert!(pig == 2000 && hit == 2000);
    println!("ALL CHECKS PASS");
}
