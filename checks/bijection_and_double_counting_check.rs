// Bijections and double counting -- the same check as the Python, in Rust.  No
// crates.  Twenty teams play a single round robin.  The matches are counted
// twice over: by listing every one, and by arithmetic.  Then the ways to pick
// the playoff six are matched one to one with the ways to pick the fourteen
// who miss out, by swapping every mark in a twenty-mark string.
const N: u32 = 20;
const K: u32 = 6;
const SMALL: [u32; 5] = [2, 3, 4, 5, 6];

fn factorial(n: u32) -> u128 {              // written out here, no crates
    let mut out: u128 = 1;
    for i in 2..=(n as u128) { out *= i }
    out
}

fn choose(n: u32, k: u32) -> u128 {         // road two: n! / (k! x (n-k)!)
    factorial(n) / (factorial(k) * factorial(n - k))
}

fn matches(n: u32) -> Vec<(u32, u32)> {     // road one: each match written once
    let mut out = Vec::new();
    for a in 1..=n { for b in (a + 1)..=n { out.push((a, b)) } }
    out
}

fn slips(n: u32) -> Vec<(u32, u32)> {       // one slip per team, per opponent
    let mut out = Vec::new();
    for a in 1..=n { for b in 1..=n { if a != b { out.push((a, b)) } } }
    out
}

fn marks(teams: &[u32]) -> String {         // a set of teams as a twenty-mark string
    (1..=N).map(|t| if teams.contains(&t) { '1' } else { '0' }).collect()
}

fn main() {
    let (listed, ordered) = (matches(N), slips(N));
    let mut tally = vec![0u32; ((N + 1) * (N + 1)) as usize];
    for &(a, b) in &ordered {               // file each slip under the match it names
        tally[(a.min(b) * (N + 1) + a.max(b)) as usize] += 1;
    }
    let mut counts: Vec<u32> = tally.iter().copied().filter(|&c| c > 0).collect();
    counts.sort(); counts.dedup();
    let by_listing: Vec<usize> = SMALL.iter().map(|&m| matches(m).len()).collect();
    let six: Vec<u32> = (0..(1u32 << N)).filter(|s| s.count_ones() == K).collect();
    let fourteen: Vec<u32> = (0..(1u32 << N)).filter(|s| s.count_ones() == N - K).collect();
    let mut flipped: Vec<u32> = six.iter().map(|s| s ^ ((1u32 << N) - 1)).collect();
    flipped.sort();                         // swap every mark
    let mut lows: Vec<u32> = six.iter().map(|s| s.trailing_zeros()).collect();
    lows.sort(); lows.dedup();
    let pick: Vec<u32> = vec![2, 5, 9, 11, 14, 20];
    let rest: Vec<u32> = (1..=N).filter(|t| !pick.contains(t)).collect();
    let row = |name: &str, vals: Vec<String>| println!("{}{}", name, vals.join(""));
    println!("league of {} teams, each plays {} others", N, N - 1);
    println!("road one, by listing: {} slips (team, opponent) and {} matches", ordered.len(), listed.len());
    println!("road two, by arithmetic: {} x {} / 2 = {} matches, and C({}, 2) = {}",
             N, N - 1, N * (N - 1) / 2, N, choose(N, 2));
    println!("slips per match, smallest and largest: {} and {}", counts[0], counts[counts.len() - 1]);
    println!("the five-team grid: {} cells, {} blanked, {} filled, {} matches", 5 * 5, 5, 5 * 4, 5 * 4 / 2);
    row("teams          ", SMALL.iter().map(|m| format!("{:>4}", m)).collect());
    row("matches listed ", by_listing.iter().map(|v| format!("{:>4}", v)).collect());
    row("n(n-1)/2       ", SMALL.iter().map(|m| format!("{:>4}", m * (m - 1) / 2)).collect());
    println!("strings of {} marks: {} in all; picking {} of {} by listing them: {}, by formula C({}, {}) = {}",
             N, 1u32 << N, K, N, six.len(), N, K, choose(N, K));
    println!("picking {} of {}: by listing marks {}, by formula C({}, {}) = {}",
             N - K, N, fourteen.len(), N, N - K, choose(N, N - K));
    println!("swapping marks sends the {}-team strings onto the {}-team strings, none repeated: {}",
             K, N - K, if flipped == fourteen { "yes" } else { "no" });
    println!("one pick: {:?} -> {} -> swapped -> {} -> {:?}", pick, marks(&pick), marks(&rest), rest);
    println!("mistake 1, stopping at the slips: {} matches, not {}", ordered.len(), listed.len());
    println!("mistake 2, letting a team play itself: {} slips, {} matches", N * N, N * N / 2);
    println!("mistake 3, filing the {} picks under their smallest team: {} buckets", six.len(), lows.len());
    assert!(listed.len() as u32 == N * (N - 1) / 2 && listed.len() == ordered.len() / 2);
    assert!(by_listing == SMALL.iter().map(|&m| (m * (m - 1) / 2) as usize).collect::<Vec<usize>>());
    assert!(six.len() as u128 == choose(N, K) && fourteen.len() as u128 == choose(N, N - K));
    assert!(flipped == fourteen && counts == vec![2]);
    println!("ALL CHECKS PASS");
}
