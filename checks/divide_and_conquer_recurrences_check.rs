// Divide-and-conquer recurrences -- the same check as the Python, in Rust.  No
// crates.  A deck of 1,024 cards is sorted by merging halves and searched by
// halving.  Each recurrence T(n) = a T(n/b) + f(n) is totalled twice: level by
// level, and by the closed form the proof gives.  The shuffle is written here.
const N: u64 = 1024;
const K: u32 = 10;                          // 1024 cards, 10 halvings down to one
fn levels(a: u64, d: u32) -> Vec<u64> {     // a^j jobs of size N/2^j, each costing size^d
    (0..K).map(|j| a.pow(j) * (N >> j).pow(d)).collect()
}
fn shuffled() -> Vec<u64> {                 // written out, so both languages agree
    let (mut deck, mut x): (Vec<u64>, u64) = ((1..=N).collect(), 20260914);
    for i in (1..N as usize).rev() {
        x = (1103515245 * x + 12345) % (1 << 31);
        let j = (x % (i as u64 + 1)) as usize;
        deck.swap(i, j);
    }
    deck
}
fn merge_sort(cards: &[u64], tally: &mut u64) -> Vec<u64> {   // road two: comparisons made
    if cards.len() < 2 { return cards.to_vec() }
    let h = cards.len() / 2;
    let (a, b) = (merge_sort(&cards[..h], tally), merge_sort(&cards[h..], tally));
    let (mut out, mut i, mut j) = (Vec::new(), 0, 0);
    while i < a.len() && j < b.len() {
        *tally += 1;
        if a[i] <= b[j] { out.push(a[i]); i += 1 } else { out.push(b[j]); j += 1 }
    }
    out.extend_from_slice(&a[i..]);
    out.extend_from_slice(&b[j..]);
    out
}
fn halvings(t: u64, cards: &[u64]) -> i64 { // narrow the window until one card is left
    let (mut lo, mut hi, mut n) = (0usize, cards.len() - 1, 0i64);
    while lo < hi {
        let mid = (lo + hi) / 2;
        n += 1;
        if cards[mid] < t { lo = mid + 1 } else { hi = mid }
    }
    if cards[lo] == t { n } else { -1 }     // -1 would mark a search that missed
}
fn main() {
    let shapes: [(u64, u32, &str); 4] = [(2, 1, "a=2 b=2 f(n)=n  "), (1, 0, "a=1 b=2 f(n)=1  "),
                                         (3, 1, "a=3 b=2 f(n)=n  "), (2, 2, "a=2 b=2 f(n)=n^2")];
    let names = ["case 1, the leaves win  ", "case 2, every level ties", "case 3, the top wins    "];
    let mut tally: u64 = 0;
    let deck = merge_sort(&shuffled(), &mut tally);
    let found: Vec<i64> = deck.iter().map(|&t| halvings(t, &deck)).collect();
    let tables: Vec<Vec<u64>> = shapes.iter().map(|&(a, d, _)| levels(a, d)).collect();
    let totals: Vec<u64> = tables.iter().map(|t| t.iter().sum()).collect();
    let closed: Vec<u64> = vec![K as u64 * N, K as u64, 2 * (3u64.pow(K) - 2u64.pow(K)), 2 * N * (N - 1)];
    let by_root: Vec<usize> = shapes.iter().map(|&(a, d, _)|
        if a > 2u64.pow(d) { 1 } else if a == 2u64.pow(d) { 2 } else { 3 }).collect();
    let by_mass: Vec<usize> = totals.iter().zip(&tables).map(|(&s, t)|
        if s > K as u64 * t[0] { 1 } else if s == K as u64 * t[0] { 2 } else { 3 }).collect();
    let in_order: Vec<u64> = (1..=N).collect();
    let (most, fewest) = (*found.iter().max().unwrap(), *found.iter().min().unwrap());
    println!("deck of {} cards: {} levels, piece sizes {:?}, piles {:?}", N, K,
             (0..K).map(|j| N >> j).collect::<Vec<u64>>(), (0..K).map(|j| 1u64 << j).collect::<Vec<u64>>());
    println!("merge sort, road one, {} levels of at most {} comparisons: {}", K, N, K as u64 * N);
    println!("merge sort, road two, {} comparisons counted on the shuffled deck, which comes out in order: {}",
             tally, if deck == in_order { "yes" } else { "no" });
    println!("binary search, road one, one probe per level: {} probes", totals[1]);
    println!("binary search, road two, over all {} targets: most {}, fewest {}", N, most, fewest);
    for (i, &(a, d, tag)) in shapes.iter().enumerate() {
        println!("{}  log_b a = {:.6}, f is n^{:.6}  ->  {}  total {}",
                 tag, (a as f64).log2(), d as f64, names[by_root[i] - 1], totals[i]);
    }
    println!("level costs, a=3 b=2 f(n)=n:   {:?}", tables[2]);
    println!("level costs, a=2 b=2 f(n)=n^2: {:?}", tables[3]);
    println!("leaves alone 3^{} = {}; unrolled total {} = 2 x (3^{} - 2^{})", K, 3u64.pow(K), totals[2], K, K);
    println!("top level alone {}; unrolled total {} = 2 x {} x {}", tables[3][0], totals[3], N, N - 1);
    println!("mistake 1, quoting the top merge alone: {}, not {}", tables[0][0], totals[0]);
    println!("mistake 2, a=3 read as n log n: {}; mistake 3, leaves x levels: {}", totals[0], 3u64.pow(K) * K as u64);
    assert!(totals == closed);              // level by level against the closed forms
    assert!(deck == in_order && tally <= K as u64 * N);
    assert!(most == K as i64 && fewest == K as i64);   // measured halvings against the level count
    assert!(by_root == by_mass && by_root == vec![2, 2, 1, 3]);
    println!("ALL CHECKS PASS");
}
