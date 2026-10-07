// Committee and chair -- the same check as the Python, in Rust.  No crates.  An
// office of 10 picks a committee of any size and one chair from inside it.  The
// (committee, chair) pairs are counted by roads that share no arithmetic: every
// committee walked one at a time, the closed form 10 x 2^9 read off Pascal's
// triangle, and every committee paired with the one holding those it leaves out.
const N: usize = 10;
const FRONT: [&str; 4] = ["Farah", "Gus", "Hana", "Ivo"];

fn committees(n: usize) -> Vec<Vec<usize>> {   // every committee: one bit per person, in or out
    let mut out: Vec<Vec<usize>> =
        (0..(1usize << n)).map(|m| (0..n).filter(|i| m >> i & 1 == 1).collect()).collect();
    out.sort_by(|a, b| (a.len(), a).cmp(&(b.len(), b)));
    out
}

fn triangle(top: usize) -> Vec<Vec<u64>> {     // Pascal's rule: each entry from the two above
    let mut rows: Vec<Vec<u64>> = vec![vec![1]];
    for n in 1..=top {
        let r: Vec<u64> = (0..=n)
            .map(|k| if k == 0 || k == n { 1 } else { rows[n - 1][k - 1] + rows[n - 1][k] }).collect();
        rows.push(r);
    }
    rows
}

fn letters(s: &[usize]) -> String {            // one committee, written by first letters
    s.iter().map(|&i| FRONT[i].chars().next().unwrap()).collect() }
fn spaced(v: &[u64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let (rows, m) = (triangle(N), FRONT.len());
    let front = committees(m);
    let mut front_pairs: Vec<(Vec<usize>, usize)> = Vec::new();   // committee first, chair inside
    for s in &front { for &c in s { front_pairs.push((s.clone(), c)) } }
    let front_sizes: Vec<u64> = (0..=m)
        .map(|k| front_pairs.iter().filter(|(s, _)| s.len() == k).count() as u64).collect();
    let office = committees(N);                // road one: walk all 1,024 committees
    let pairs: u64 = office.iter().map(|s| s.len() as u64).sum();
    let listed: Vec<u64> = (0..=N)
        .map(|k| office.iter().filter(|s| s.len() == k).map(|s| s.len() as u64).sum()).collect();
    let absorbed: Vec<u64> =                   // road two: chair first, rest from the other nine
        (0..=N).map(|k| if k >= 1 { N as u64 * rows[N - 1][k - 1] } else { 0 }).collect();
    let closed = N as u64 * (1u64 << (N - 1));
    let complement = (office.len() / 2) as u64 * N as u64;   // road three: a committee and the rest
    let row_total: u64 = rows[N].iter().sum();
    println!("office of {}; a committee of any size, one chair from inside it", N);
    println!("front room of {} -- {} -- every committee|chair pair listed:", m, FRONT.join(", "));
    for k in 1..=m {
        let got: Vec<String> = front_pairs.iter().filter(|(s, _)| s.len() == k)
            .map(|(s, c)| format!("{}|{}", letters(s), FRONT[*c].chars().next().unwrap())).collect();
        println!("  size {}: {}  ->  {}", k, got.join(" "), got.len());
    }
    println!("  total {}; chair first: {} x 2^{} = {} x {} = {}", front_pairs.len(), m, m - 1, m,
             1 << (m - 1), m * (1 << (m - 1)));
    println!("row {} of the triangle: {}  adds to {}", N, spaced(&rows[N]), row_total);
    println!("pairs by committee size, k C({},k): {}", N, spaced(&listed));
    println!("the same terms, chair first, {} C({},k-1): {}  (agree: {})",
             N, N - 1, spaced(&absorbed), yn(listed == absorbed));
    println!("the eleven terms added: {}; chair first in one step: {} x 2^{} = {} x {} = {}",
             listed.iter().sum::<u64>(), N, N - 1, N, 1u64 << (N - 1), closed);
    println!("every committee walked one at a time: {} pairs over {} committees", pairs, office.len());
    println!("complement pairing: {} pairs of committees x {} people = {}",
             office.len() / 2, N, complement);
    println!("average committee size: {} / {} = {}", pairs, office.len(), pairs / office.len() as u64);
    println!("the k = 3 term: 3 x {} = {} = {} x C({},2) = {} x {}",
             rows[N][3], 3 * rows[N][3], N, N - 1, N, rows[N - 1][2]);
    println!("mistakes: a chair from the whole office gives {}, not {}; dropping the k gives {}, \
not {}; shifting the index gives {} x C({},3) = {} at k = 3, not {}",
             N as u64 * office.len() as u64, pairs, row_total, pairs,
             N, N - 1, N as u64 * rows[N - 1][3], 3 * rows[N][3]);
    assert!(pairs == closed);                           // every committee walked, against the formula
    assert!(listed == absorbed);                        // size by size: committee first vs chair first
    assert!(row_total == 1024 && complement == pairs);  // the house row sum, and the third road
    assert!(front_sizes == vec![0, 4, 12, 12, 4] && front_pairs.len() == m * (1 << (m - 1)));
    println!("ALL CHECKS PASS");
}
