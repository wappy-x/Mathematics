// Negating a quantifier -- the same check as the Python one, in Rust.  No crates.
// Five bags at the gate: weight in kg, and whether each one went in the cabin.
// Road 1 reads every/some straight off the list; road 2 counts.  They agree.
const KG: [i64; 5] = [4, 5, 6, 9, 11];
const CABIN: [bool; 5] = [true, true, false, false, false];
fn tf(b: bool) -> &'static str { if b { "T" } else { "F" } }
fn row(name: &str, b: bool) { println!("{:<37}{:>2}", name, tf(b)); }
fn main() {
    let light: Vec<usize> = (0..KG.len()).filter(|&i| KG[i] < 7).collect();  // the bags the sign is about
    let broke: Vec<usize> = light.iter().cloned().filter(|&i| !CABIN[i]).collect();
    let (every_in, some_out) = (light.iter().all(|&i| CABIN[i]), light.iter().any(|&i| !CABIN[i]));
    let (some_big, every_small) = (KG.iter().any(|&w| w > 20), KG.iter().all(|&w| w <= 20));
    let every_out = light.iter().all(|&i| !CABIN[i]);                  // the wreck
    let mut kgs = format!("{:<24}", "bags at the gate, in kg");
    for w in KG { kgs.push_str(&format!("{:>3}", w)); }
    println!("{}", kgs);
    let mut yn = format!("{:<24}", "did it go in the cabin?");
    for c in CABIN { yn.push_str(&format!("{:>3}", if c { "Y" } else { "N" })); }
    println!("{}", yn);
    println!("bags under 7 kg {}: in the cabin {}, refused {}", light.len(), light.len() - broke.len(), broke.len());
    row("every bag under 7 kg in the cabin?", every_in);
    row("some bag under 7 kg refused?", some_out);
    row("some bag over 20 kg?", some_big);
    row("every bag 20 kg or under?", every_small);
    row("the wreck, every under-7 bag refused", every_out);
    println!("{}", broke.first().map_or("no counterexample: the sign stands".to_string(),
        |&b| format!("counterexample: bag {} at {} kg; 1 bag kills 'every', {} to kill 'some'", b + 1, KG[b], KG.len())));
    let mut n = 0;
    for p in 0..8 {
        let q = [p & 1 == 1, p & 2 == 2, p & 4 == 4];
        assert!((!q.iter().all(|&v| v)) == q.iter().any(|&v| !v)
                && (!q.iter().any(|&v| v)) == q.iter().all(|&v| !v));
        n += 1;
    }
    println!("all {} yes/no patterns for the light bags: both swaps hold", n);
    assert!(light.len() == 3 && broke.len() == 1 && KG[broke[0]] == 6);
    assert!(every_in == broke.is_empty() && !broke.is_empty() == some_out);   // road 2: counts
    assert!(!every_in && some_out && !every_out && !some_big);
    println!("ALL CHECKS PASS");
}
