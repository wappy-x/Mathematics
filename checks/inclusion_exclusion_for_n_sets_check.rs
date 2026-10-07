// Inclusion-exclusion for any number of sets -- the same check as the Python, in Rust.
// No crates.  A hotel of 100 guests with three amenities, then the numbers 1 to 1000
// sieved by 2, 3, 5 and by 2, 3, 5, 7.  Every count is reached twice: by the signed
// sum of overlaps, and by walking the members one at a time.
const REGIONS: [(u8, i64); 8] = [(7, 5), (3, 15), (5, 10), (6, 5), (1, 20), (2, 15), (4, 10), (0, 20)];

fn roster() -> Vec<u8> {                              // one entry per guest: which amenities
    let mut out = Vec::new();
    for (mask, n) in REGIONS { for _ in 0..n { out.push(mask) } }
    out
}
fn pick(items: &[i64], j: usize) -> Vec<Vec<i64>> {   // every j of the items, order kept
    if j == 0 { return vec![Vec::new()] }
    let mut out = Vec::new();
    for (i, &x) in items.iter().enumerate() {
        for rest in pick(&items[i + 1..], j - 1) { out.push([vec![x], rest].concat()) }
    }
    out
}
fn overlaps(items: &[i64], size: &dyn Fn(&[i64]) -> i64) -> Vec<Vec<i64>> {   // layer by layer
    (1..=items.len()).map(|j| pick(items, j).iter().map(|c| size(c)).collect()).collect()
}
fn union(ls: &[Vec<i64>]) -> i64 {                    // S_1 - S_2 + S_3 - ...
    ls.iter().enumerate().map(|(j, r)| { let s: i64 = r.iter().sum(); if j % 2 == 0 { s } else { -s } }).sum()
}
fn choose(n: i64, k: i64) -> i64 {                    // Pascal's triangle, built here
    let mut row = vec![1i64];
    for _ in 0..n {
        let mut next = vec![0i64; row.len() + 1];
        for (i, &v) in row.iter().enumerate() { next[i] += v; next[i + 1] += v }
        row = next;
    }
    row[k as usize]
}
fn guests_with(bits: &[i64], all: &[u8]) -> i64 {     // guests holding every amenity named
    let mask: u8 = bits.iter().map(|&t| 1u8 << t).sum();
    all.iter().filter(|&&g| g & mask == mask).count() as i64
}
fn prod(ds: &[i64]) -> i64 { ds.iter().product() }
fn multiples_of_all(ds: &[i64]) -> i64 { 1000 / prod(ds) }   // 1 to 1000 divisible by all of ds
fn none_of(ds: &[i64], limit: i64) -> i64 {           // road two: test every number in turn
    (1..=limit).filter(|x| ds.iter().all(|d| x % d != 0)).count() as i64
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn totals(ls: &[Vec<i64>]) -> Vec<i64> { ls.iter().map(|r| r.iter().sum()).collect() }

fn main() {
    let (all, amen) = (roster(), vec![0i64, 1, 2]);
    let th = overlaps(&amen, &|c: &[i64]| guests_with(c, &all));
    let hl = totals(&th);
    let (hotel, walk) = (union(&th), all.iter().filter(|&&m| m != 0).count() as i64);
    let ones: Vec<i64> = (1..=8).map(|k| (1..=k).map(|j| if j % 2 == 1 { choose(k, j) } else { -choose(k, j) }).sum()).collect();
    let pascal: Vec<i64> = (0..=4).map(|j| choose(4, j)).collect();
    let (t3, t4) = (overlaps(&[2, 3, 5], &multiples_of_all), overlaps(&[2, 3, 5, 7], &multiples_of_all));
    let (l3, l4) = (totals(&t3), totals(&t4));
    let (none3, none4) = (1000 - union(&t3), 1000 - union(&t4));
    let (blocks, per) = (1000 / 30, none_of(&[2, 3, 5], 30));
    let spare = (991..=1000).filter(|x: &i64| [2, 3, 5].iter().all(|d| x % d != 0)).count() as i64;
    println!("hotel: {} guests; singles {:?}, pairs {:?}, all three {:?}", all.len(), th[0], th[1], th[2]);
    println!("layers S1 {}, S2 {}, S3 {}  ->  union {} - {} + {} = {}", hl[0], hl[1], hl[2], hl[0], hl[1], hl[2], hotel);
    println!("the same {}, by walking the roster guest by guest: {}", hotel, yn(hotel == walk));
    println!("guests who took nothing: {} - {} = {}", all.len(), hotel, all.len() as i64 - hotel);
    println!("a guest in k of the amenities is counted, for k = 1 to 8: {:?}", ones);
    println!("Pascal's row for k = 4, the counts that alternate: {:?}", pascal);
    println!("mistake 1, add the three counts and stop: {}, not {}", hl[0], hotel);
    println!("mistake 2, stop after the pairs: {}, not {}", hl[0] - hl[1], hotel);
    println!("mistake 3, subtract the triple instead of adding: {}, not {}", hl[0] - hl[1] - hl[2], hotel);
    println!("1 to 1000, none of 2, 3, 5: layers {:?}  ->  union {}, none {}", l3, union(&t3), none3);
    println!("1 to 1000, none of 2, 3, 5: by testing each number {}", none_of(&[2, 3, 5], 1000));
    println!("1 to 1000, none of 2, 3, 5: {} blocks of 30 x {} + {} left over = {}", blocks, per, spare, blocks * per + spare);
    println!("1 to 1000, by 2, 3, 5, 7: singles {:?}, pairs {:?}, triples {:?}, all four {:?}", t4[0], t4[1], t4[2], t4[3]);
    println!("1 to 1000, none of 2, 3, 5, 7: layers {:?}  ->  union {}, none {}", l4, union(&t4), none4);
    println!("1 to 1000, none of 2, 3, 5, 7: by testing each number {}", none_of(&[2, 3, 5, 7], 1000));
    assert!(hotel == walk && hotel == 80);                              // sieve against a head count
    assert!(all.len() as i64 - hotel == 20 && hl == vec![120, 45, 5]);  // the layers, one at a time
    assert!(none3 == none_of(&[2, 3, 5], 1000) && none3 == blocks * per + spare);
    assert!(none4 == none_of(&[2, 3, 5, 7], 1000) && ones == vec![1i64; 8]);
    println!("ALL CHECKS PASS");
}
