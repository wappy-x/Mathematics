// Splitting into groups -- the same check as the Python, in Rust.  No crates.
// Nine players, A to I, are split into three piles.  The named count (tables
// numbered 1, 2, 3) and the unnamed count are each reached twice, by roads that
// share no arithmetic: hand out table numbers and count, or divide factorials.
use std::collections::HashMap;
const PLAYERS: &str = "ABCDEFGHI";
const EVEN: [usize; 3] = [3, 3, 3];
const ODD: [usize; 3] = [4, 3, 2];

fn fact(m: u64) -> u64 {                       // 1 x 2 x ... x m, written out here
    let mut out = 1;
    for j in 2..=m { out *= j }
    out
}

fn choose(a: usize, b: usize) -> u64 {         // C(a, b) from Pascal's triangle alone
    let mut row: Vec<u64> = vec![1];
    for _ in 0..a {
        let mut next: Vec<u64> = vec![1];
        for i in 0..row.len() - 1 { next.push(row[i] + row[i + 1]) }
        next.push(1); row = next;
    }
    row[b]
}

fn by_factorials(sizes: &[usize]) -> u64 {     // road two: n! divided by each pile's factorial
    let mut out = fact(sizes.iter().sum::<usize>() as u64);
    for &s in sizes { out /= fact(s as u64) }
    out
}

fn labellings(sizes: &[usize]) -> Vec<String> {  // road one: every way to hand out table numbers
    let (k, chars) = (sizes.len(), PLAYERS.chars().collect::<Vec<char>>());
    let mut out = Vec::new();
    for code in 0..k.pow(chars.len() as u32) {
        let tags: Vec<usize> = (0..chars.len()).map(|i| (code / k.pow(i as u32)) % k).collect();
        if (0..k).all(|t| tags.iter().filter(|&&x| x == t).count() == sizes[t]) {
            let mut piles: Vec<String> = (0..k).map(|t| (0..chars.len())
                .filter(|&i| tags[i] == t).map(|i| chars[i]).collect()).collect();
            piles.sort();
            out.push(piles.join(" "));
        }
    }
    out
}

fn com(v: u64) -> String {                     // 1680 printed 1,680, as written on the card
    let (s, mut out) = (v.to_string(), String::new());
    for (i, ch) in s.chars().enumerate() {
        out.push(ch);
        if (s.len() - i - 1) % 3 == 0 && i < s.len() - 1 { out.push(',') }
    }
    out
}

fn main() {
    let (even, mut orbit) = (labellings(&EVEN), HashMap::<String, u64>::new());
    for s in &even { *orbit.entry(s.clone()).or_insert(0) += 1 }
    let mut odd = labellings(&ODD);
    odd.sort(); odd.dedup();
    let seq = [choose(9, 3), choose(6, 3), choose(3, 3)];
    let (named, unnamed, even_piles) = (even.len() as u64, orbit.len() as u64, fact(3).pow(3));
    let same = unnamed > 0 && orbit.values().all(|&v| v == fact(3));
    println!("nine players, A to I, into three piles at tables numbered 1, 2 and 3");
    println!("road one, every labelling: 3^9 = {} in all, {} put three players at each table", com(3u64.pow(9)), com(named));
    println!("road two, factorials: 9! / (3! 3! 3!) = {} / {} = {}", com(fact(9)), even_piles, com(by_factorials(&EVEN)));
    println!("road three, choose in turn: C(9,3) x C(6,3) x C(3,3) = {} x {} x {} = {}", seq[0], seq[1], seq[2], com(seq[0] * seq[1] * seq[2]));
    println!("unnamed trios, by collecting the distinct splits: {}", com(unnamed));
    println!("unnamed trios, by formula: {} / 3! = {} / {} = {}", com(named), com(named), fact(3), com(named / fact(3)));
    println!("every unnamed split wears exactly {} sets of table numbers: {}", fact(3), if same { "yes" } else { "no" });
    println!("piles of 4, 3 and 2: 9! / (4! 3! 2!) = {} named, and {} unnamed", com(by_factorials(&ODD)), com(odd.len() as u64));
    println!("mistake 1, dividing by 3! when the tables are numbered: {}, not {}", com(named / 6), com(named));
    println!("mistake 2, forgetting the last pile's 3!: {}, not {}", com(fact(9) / (fact(3) * fact(3))), com(named));
    println!("mistake 3, dividing by 3! when the piles are 4, 3 and 2: {}, not {}", com(by_factorials(&ODD) / 6), com(by_factorials(&ODD)));
    assert!(named == by_factorials(&EVEN) && by_factorials(&EVEN) == seq[0] * seq[1] * seq[2]);
    assert!(unnamed == by_factorials(&EVEN) / fact(3) && same);
    assert!(odd.len() as u64 == by_factorials(&ODD));           // uneven piles, brute against formula
    assert!(choose(9, 3) * fact(3) * fact(6) == fact(9));       // Pascal against factorials
    println!("ALL CHECKS PASS");
}
