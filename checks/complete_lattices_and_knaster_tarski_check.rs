// Knaster-Tarski -- the same check as the Python, in Rust.  No crates.  The 16 subsets of {1, 2, 3, 4}
// ordered by "inside", each kept as four on-off bits, and f(S) = {1} plus every step of S along 1 -> 2, 3 -> 4, 4 -> 3.
const STEP: [u8; 4] = [0b0010, 0, 0b1000, 0b0100];             // where 1, 2, 3 and 4 point
const U: u8 = 0b1111;
fn f(s: u8) -> u8 { (0..4).filter(|i| s >> i & 1 == 1).fold(0b0001, |acc, i| acc | STEP[i]) }
fn inside(s: u8, t: u8) -> bool { s & !t == 0 }
fn show(s: u8) -> String { format!("{{{}}}", (0..4).filter(|i| s >> i & 1 == 1).map(|i| (i + 1).to_string()).collect::<Vec<_>>().join(", ")) }
fn run(s: u8, n: usize) -> Vec<u8> { let mut v = vec![s]; for _ in 0..n { v.push(f(*v.last().unwrap())); } v }
fn shows(v: &[u8]) -> String { v.iter().map(|&s| show(s)).collect::<Vec<_>>().join(", ") }
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn main() {
    let (up, down, odd) = (run(0, 3), run(U, 1), run(0b0100, 4));
    let (mut reach, mut todo) = (0b0001u8, vec![0usize]);       // second road: walk the arrows from 1
    while let Some(x) = todo.pop() { for y in 0..4 { if STEP[x] >> y & 1 == 1 && reach >> y & 1 == 0 { reach |= 1 << y; todo.push(y); } } }
    let all: Vec<u8> = (0..16).collect();
    let fixed: Vec<u8> = all.iter().cloned().filter(|&s| f(s) == s).collect();
    let closed: Vec<u8> = all.iter().cloned().filter(|&s| inside(f(s), s)).collect();
    let post: Vec<u8> = all.iter().cloned().filter(|&s| inside(s, f(s))).collect();
    let pairs: Vec<(u8, u8)> = all.iter().flat_map(|&s| all.iter().map(move |&t| (s, t))).filter(|&(s, t)| inside(s, t)).collect();
    let (meet, join) = (closed.iter().fold(U, |a, &s| a & s), post.iter().fold(0, |a, &s| a | s));   // third road: Tarski's formula
    let mut fr: Vec<(u64, u64)> = vec![(0, 1)];               // the fractions: x -> (2x + 2) / (x + 2)
    for _ in 0..6 { let (p, q) = *fr.last().unwrap(); let (p, q) = (2 * p + 2 * q, p + 2 * q); let g = gcd(p, q); fr.push((p / g, q / g)); }
    let kept = pairs.iter().filter(|&&(s, t)| inside(f(s), f(t))).count();
    let comp = all.iter().filter(|&&s| U & !s == s).count();
    println!("climb from the empty set: {}", shows(&up));
    println!("climb down from the top: {} | walk from 1 reaches {}", shows(&down), show(reach));
    println!("order kept on {} of {} pairs S inside T", kept, pairs.len());
    println!("fixed points among {} subsets: {}", all.len(), shows(&fixed));
    println!("closed sets (f(S) inside S): {}, all of them in common {}", closed.len(), show(meet));
    println!("sets inside their own f(S): {}, all of them together {}", post.len(), show(join));
    println!("climb from {{3}}: {} | complement map, fixed points: {}", shows(&odd), comp);
    let (lp, lq) = fr[5];
    println!("fractions climb: {} = {:.5}, never fixed", fr[..6].iter().map(|(p, q)| format!("{}/{}", p, q)).collect::<Vec<_>>().join(", "), lp as f64 / lq as f64);
    assert!(up[3] == up[2] && up[3] == reach && reach == meet && meet == fixed[0] && fixed.len() == 2 && down[1] == join && join == U && U == fixed[1]);
    assert!(pairs.len() == 81 && closed.len() == 2 && post.len() == 6 && closed.iter().fold(0, |a, &s| a | s) == U && kept == 81 && comp == 0);
    assert!(odd[2] == odd[4] && odd[4] != odd[3] && (0..6).all(|i| fr[i] != fr[i + 1]) && fr[5] == (41, 29));
    println!("ALL CHECKS PASS");
}
