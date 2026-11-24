// Cardinal arithmetic -- the same check as cardinal_arithmetic_check.py, in Rust.  No crates.
// The full hotel takes a second hotel, then a coach of coaches; then the 0-1 lists outgrow it.
use std::collections::BTreeSet;
fn coach(m: u64, n: u64) -> u64 { (1u64 << m) * (2 * n + 1) }   // coach m, seat n -> room
fn back(mut r: u64) -> (u64, u64) {                               // room -> (coach, seat)
    let mut m = 0;
    while r % 2 == 0 { r /= 2; m += 1; }
    (m, (r - 1) / 2)
}
fn place(m: u64, n: u64) -> u64 { let k = m.max(n); k * k + if m < k { m } else { k + n } + 1 }
fn main() {
    let sorted = |mut v: Vec<u64>| { v.sort(); v };
    let merged = sorted((1..=500).map(|n| 2 * n).chain((1..=500).map(|n| 2 * n - 1)).collect());
    let rooms = sorted((0..10).flat_map(|m| (0..500).map(move |n| coach(m, n))).filter(|&r| r <= 1000).collect());
    let mut shells: Vec<(u64, u64, u64)> = (0..30).flat_map(|m| (0..30).map(move |n| (m.max(n), m, n))).collect();
    shells.sort();                                                // second road: sort
    let places: Vec<u64> = shells.iter().map(|&(_, m, n)| place(m, n)).collect();
    let count = |v: &Vec<u64>| v.iter().collect::<BTreeSet<_>>().len();
    println!("merge: hotel A room 7 -> {}, hotel B room 7 -> {}; rooms 1-1000 filled once: {}", 2 * 7, 2 * 7 - 1, count(&merged));
    println!("coaches: (0,0) -> room {}, (2,1) -> room {}, (3,4) -> room {}", coach(0, 0), coach(2, 1), coach(3, 4));
    let (m12, s12) = back(12);
    println!("room 12 -> halve {} times -> odd part {} -> coach {}, seat {}", m12, 12 >> m12, m12, s12);
    println!("coach rule: guests landing in rooms 1-1000: {}, different rooms: {}", rooms.len(), count(&rooms));
    println!("shells by max: pairs below 30: {}, places used once: {}, (2,1) at place {}", places.len(), count(&places), place(2, 1));
    let lists: BTreeSet<String> = (0..8).map(|i| format!("{:03b}", i)).collect();
    let pairs = (0..3).flat_map(|c| (0..4).map(move |s| (c, s))).count();
    println!("finite: 3 + 4 = {}, 3 x 4 = {}, 0-1 lists of length 3: {}", [1; 3].iter().chain([2; 4].iter()).count(), pairs, lists.len());
    let third: f64 = (2..60).step_by(2).map(|i| 2f64.powi(-i)).sum();   // 0.010101... in binary
    let (half_a, half_b): (f64, f64) = (0.5, (2..60).map(|i| 2f64.powi(-i)).sum());
    println!("binary lists as points: 0.0101... = {:.6}; 0.1000... = {:.6}, 0.0111... = {:.6}", third, half_a, half_b);
    let plus = (0..10u64).flat_map(|m| (0..10).map(move |n| m + n + 1)).collect::<BTreeSet<_>>().len();
    let noodd = (0..10u64).flat_map(|m| (0..10).map(move |n| (1u64 << m) * (n + 1))).collect::<BTreeSet<_>>().len();
    let left = (1..=100).filter(|r| r % 2 == 1).count();          // the even rooms emptied
    println!("mistakes: room m+n+1 puts 100 guests in {} rooms; room 2^m(n+1) in {}; evens out leaves {} of rooms 1-100 full", plus, noodd, left);
    assert!(merged == (1..=1000).collect::<Vec<u64>>() && rooms == (1..=1000).collect::<Vec<u64>>());
    assert!((1..=1000).all(|r| { let (m, n) = back(r); coach(m, n) == r }) && back(12) == (2, 1));
    assert!(places == (1..=900).collect::<Vec<u64>>() && place(2, 1) == 8);   // formula = sorted order
    assert!((third - 1.0 / 3.0).abs() < 1e-12 && (half_b - half_a).abs() < 1e-12 && plus == 2 * 10 - 1 && noodd == 55 && left == 50);
    println!("ALL CHECKS PASS");
}
