// Vandermonde's identity -- the same check as the Python, in Rust.  No crates.  Ten
// musicians, 6 guitarists and 4 drummers, and a band is 5 of them, order ignored.
// The bands are counted twice by roads sharing no arithmetic: every band listed one
// at a time, and the split C(6,k) x C(4,5-k) read off a triangle built by addition
// alone.  Equal groups then turn the same sum into a sum of squares.
const GUITARS: i64 = 6;  const DRUMS: i64 = 4;  const SEATS: i64 = 5;
fn triangle(top: usize) -> Vec<Vec<i64>> {   // every count from addition alone, no factorials
    let mut rows: Vec<Vec<i64>> = vec![vec![1]];
    for n in 1..=top {
        let up = &rows[n - 1];
        let mut r: Vec<i64> = (1..n).map(|k| up[k - 1] + up[k]).collect();
        r.insert(0, 1);  r.push(1);  rows.push(r);
    }
    rows
}
fn c(t: &[Vec<i64>], n: i64, k: i64) -> i64 {   // picks of k from n, and zero off the row
    if k < 0 || k > n { 0 } else { t[n as usize][k as usize] }
}
fn listed(pool: i64, seats: i64, first: i64) -> Vec<i64> {  // road one: every band listed
    let mut counts = vec![0i64; seats as usize + 1];
    for mask in 0..(1i64 << pool) {
        let chosen: Vec<i64> = (0..pool).filter(|i| mask >> i & 1 == 1).collect();
        if chosen.len() as i64 == seats {
            counts[chosen.iter().filter(|&&i| i < first).count()] += 1;
        }
    }
    counts
}
fn split(t: &[Vec<i64>], m: i64, n: i64, r: i64) -> Vec<i64> {   // road two: k from the first group
    (0..=r).map(|k| c(t, m, k) * c(t, n, r - k)).collect()
}
fn grid(name: &str, xs: &[i64]) {
    let mut line = format!("{:<33}", name);
    for x in xs { line.push_str(&format!("{:>6}", x)); }
    println!("{}", line);
}
fn flat(xs: &[i64]) -> String { xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn total(xs: &[i64]) -> i64 { xs.iter().sum() }
fn main() {
    let t = triangle(16);
    let by_hand = listed(GUITARS + DRUMS, SEATS, GUITARS);
    let terms = split(&t, GUITARS, DRUMS, SEATS);
    let whole = c(&t, GUITARS + DRUMS, SEATS);
    let even = listed(2 * SEATS, SEATS, SEATS);
    let squares: Vec<i64> = (0..=SEATS).map(|k| c(&t, SEATS, k) * c(&t, SEATS, k)).collect();
    let (mut triples, mut holds) = (0i64, 0i64);
    for m in 0..9 { for n in 0..9 { for r in 0..(m + n + 3) {
        triples += 1;
        if c(&t, m + n, r) == total(&split(&t, m, n, r)) { holds += 1 }
    }}}
    let same_k: Vec<i64> = (0..=DRUMS).map(|k| c(&t, GUITARS, k) * c(&t, DRUMS, k)).collect();
    let stopped: i64 = total(&terms[..SEATS as usize]);
    let (mut lineups, mut orderings) = (1i64, 1i64);
    for i in 0..SEATS { lineups *= GUITARS + DRUMS - i }
    for i in 1..=SEATS { orderings *= i }
    let shared = total(&listed(GUITARS + DRUMS - 1, SEATS, 0));
    println!("{} musicians: {} guitarists and {} drummers; a band is {} of them, order ignored",
             GUITARS + DRUMS, GUITARS, DRUMS, SEATS);
    grid("guitarists in the band, k", &(0..=SEATS).collect::<Vec<i64>>());
    grid("ways to choose those guitarists", &(0..=SEATS).map(|k| c(&t, GUITARS, k)).collect::<Vec<i64>>());
    grid("ways to fill the rest from 4", &(0..=SEATS).map(|k| c(&t, DRUMS, SEATS - k)).collect::<Vec<i64>>());
    grid("bands with that many guitarists", &terms);
    println!("road one, every band listed and sorted by guitarist count: {}, adding to {}", flat(&by_hand), total(&by_hand));
    println!("road two, the products above added: {}; the whole pool at once, C(10,5) = {}", total(&terms), whole);
    println!("row 10 of the triangle: {}, adding to {}, middle entry {}", flat(&t[10]), total(&t[10]), t[10][SEATS as usize]);
    println!("5 guitarists and 5 drummers instead: {}, adding to {}", flat(&even), total(&even));
    println!("the same six terms as the squares of row 5 ({}): {}", flat(&t[5]), flat(&squares));
    println!("the identity on every m, n up to 8 and every r up to m+n+2: {} of {} triples hold", holds, triples);
    println!("mistake 1, the same k in both groups: {} = {}, not {}",
             same_k.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" + "), total(&same_k), whole);
    println!("mistake 2, k stopped at 4, the drummer count: {}, not {}", stopped, whole);
    println!("mistake 3, line-ups counted instead of bands: {} = {} x {}, not {}", lineups, whole, orderings, whole);
    println!("mistake 4, one player on both lists: 9 people give {} bands, the split still says {}", shared, total(&terms));
    assert!(by_hand == terms && total(&by_hand) == whole);      // listing against the split, and against C(10,5)
    assert!(even == squares && total(&even) == whole);          // equal groups: listing against squares of row 5
    assert!(holds == triples && lineups == whole * orderings);
    assert!(shared == c(&t, GUITARS + DRUMS - 1, SEATS) && total(&same_k) == c(&t, GUITARS + DRUMS, DRUMS));
    println!("ALL CHECKS PASS");
}
