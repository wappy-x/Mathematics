// Stars and bars -- the same check as the Python, in Rust.  No crates.  Five
// identical scoops across three flavours; twelve identical tins on three
// shelves with none empty; the number 6 written as an ordered sum of positive
// parts.  Every count is reached twice, by roads that share no arithmetic.
const SCOOPS: i64 = 5; const FLAVOURS: i64 = 3; const TINS: i64 = 12;
const SHELVES: i64 = 3; const TARGET: i64 = 6;
fn choose(m: i64, r: i64) -> i64 {             // C(m, r), built one factor at a time
    let mut out = 1;
    for i in 0..r { out = out * (m - i) / (i + 1) }
    out
}
fn tubs_listed(n: i64, k: i64, low: i64) -> Vec<Vec<i64>> {   // road one: every way in full
    if k == 0 { return if n == 0 { vec![Vec::new()] } else { Vec::new() } }
    let mut out = Vec::new();
    for first in low..=n {
        for rest in tubs_listed(n - first, k - 1, low) {
            let mut tub = vec![first]; tub.extend(rest); out.push(tub);
        }
    }
    out
}
fn rows_listed(n: i64, k: i64) -> Vec<Vec<i64>> {   // road two: every row of stars and bars
    let slots = n + k - 1;
    let mut out = Vec::new();
    for mask in 0..(1i64 << slots) {           // one bit per slot, a 1 means a bar
        let bars: Vec<i64> = (0..slots).filter(|&s| (mask >> s) & 1 == 1).collect();
        if bars.len() as i64 == k - 1 {
            let mut cut = vec![-1]; cut.extend(&bars); cut.push(slots);
            out.push((0..k as usize).map(|i| cut[i + 1] - cut[i] - 1).collect());
        }
    }
    out.sort();
    out
}
fn picture(tub: &[i64]) -> String {            // the row of stars and bars for one tub
    tub.iter().map(|&c| "*".repeat(c as usize)).collect::<Vec<String>>().join("|")
}
fn show(tub: &[i64]) -> String {               // a tub written (a, b, c), as Python writes it
    format!("({})", tub.iter().map(|c| c.to_string()).collect::<Vec<String>>().join(", "))
}
fn main() {
    let mut tubs = tubs_listed(SCOOPS, FLAVOURS, 0); tubs.sort();
    let rows = rows_listed(SCOOPS, FLAVOURS);
    let ladder: Vec<i64> = (0..=SCOOPS).map(|c| SCOOPS - c + 1).collect();  // road three
    let sum_ladder: i64 = ladder.iter().sum();
    let full = tubs_listed(TINS, SHELVES, 1);
    let gift = tubs_listed(TINS - SHELVES, SHELVES, 0);
    let mut comps: Vec<Vec<i64>> = Vec::new();
    for k in 1..=TARGET { comps.extend(tubs_listed(TARGET, k, 1)) }
    let listed: Vec<i64> = (1..=TARGET).map(|k| tubs_listed(TARGET, k, 1).len() as i64).collect();
    let formula: Vec<i64> = (1..=TARGET).map(|k| choose(TARGET - 1, k - 1)).collect();
    let mut shapes: Vec<Vec<i64>> = Vec::new();
    for tub in &tubs {
        let mut s = tub.clone(); s.sort(); s.reverse();
        if !shapes.contains(&s) { shapes.push(s) }
    }
    let shown = [[5, 0, 0], [2, 0, 3], [0, 5, 0], [1, 2, 2]];
    let four: Vec<String> = shown.iter().map(|t| format!("{} -> {}", show(t), picture(t))).collect();
    println!("{} scoops across {} flavours, a flavour may be skipped", SCOOPS, FLAVOURS);
    println!("  four tubs written out: {}", four.join(", "));
    println!("  every tub listed: {}", tubs.len());
    println!("  {} stars and {} bars in {} slots: {} rows, the same list: {}; C(7, 2) = {}", SCOOPS,
             FLAVOURS - 1, SCOOPS + FLAVOURS - 1, rows.len(), if tubs == rows { "yes" } else { "no" }, choose(7, 2));
    println!("  chocolate 0 to {}, the rest shared by two flavours: {:?}, adding to {}", SCOOPS, ladder, sum_ladder);
    println!("{} tins on {} shelves, no shelf left empty", TINS, SHELVES);
    println!("  every arrangement listed: {}; C(11, 2) = {}", full.len(), choose(11, 2));
    println!("  one tin to each shelf first, then {} shared with empties allowed: {}", TINS - SHELVES, gift.len());
    println!("{} as an ordered sum of positive parts: {} ways", TARGET, comps.len());
    println!("  split by number of parts, listed: {:?}", listed);
    println!("  split by number of parts, from C(5, parts - 1): {:?}", formula);
    println!("  cut or leave each of the {} gaps: 2 x 2 x 2 x 2 x 2 = {}", TARGET - 1, 1i64 << (TARGET - 1));
    println!("wrong turns on the {}-scoop tub: C(7, 3) = {}, C(5, 2) = {}, C(4, 2) = {}, \
flavours left unlabelled = {}", SCOOPS, choose(7, 3), choose(5, 2), choose(4, 2), shapes.len());
    assert!(tubs == rows && tubs.len() as i64 == choose(SCOOPS + FLAVOURS - 1, FLAVOURS - 1));
    assert!(sum_ladder == tubs.len() as i64 && tubs.len() == 21);
    assert!(full.len() as i64 == choose(TINS - 1, SHELVES - 1) && full.len() == gift.len());
    assert!(listed == formula && comps.len() as i64 == 1i64 << (TARGET - 1));
    println!("ALL CHECKS PASS");
}
