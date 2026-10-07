// The rules of sum and product -- the same check as the Python, in Rust.  No
// crates.  The lunch deal: 4 breads x 5 fillings x 3 sauces, or one of 3 soups
// instead.  Every count is reached twice: once from the stage sizes, multiplied
// or added, and once by building every lunch and counting them one at a time, a
// road that never multiplies or adds a stage size at all.
fn build<'a>(stages: &[&[&'a str]]) -> Vec<Vec<&'a str>> {   // road two: pile the rows up
    let mut rows: Vec<Vec<&str>> = vec![Vec::new()];
    for stage in stages {
        let mut next: Vec<Vec<&str>> = Vec::new();
        for row in &rows {
            for pick in stage.iter() { let mut r = row.clone(); r.push(pick); next.push(r) }
        }
        rows = next;
    }
    rows
}
fn distinct(rows: &[Vec<&str>]) -> usize {                   // rows unlike every earlier row
    let mut seen: Vec<&Vec<&str>> = Vec::new();
    for r in rows { if !seen.contains(&r) { seen.push(r) } }
    seen.len()
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let breads: &[&str] = &["rye", "white", "sourdough", "flat"];
    let fillings: &[&str] = &["cheese", "ham", "tuna", "falafel", "egg"];
    let sauces: &[&str] = &["chilli", "mustard", "none"];
    let soups: &[&str] = &["tomato", "lentil", "pea"];
    let squad: Vec<i64> = (1..=20).collect();                // the squad's 20 shirt numbers
    let pairs = build(&[breads, fillings]);
    let running: Vec<usize> = (0..breads.len())
        .map(|k| pairs.iter().filter(|p| breads[..=k].contains(&p[0])).count())
        .collect();
    let sandwiches = build(&[breads, fillings, sauces]);
    let by_stages = breads.len() * fillings.len() * sauces.len();     // road one
    let mut lunches: Vec<Vec<&str>> = sandwiches
        .iter().map(|s| { let mut r = vec!["sandwich"]; r.extend(s); r }).collect();
    for s in soups { lunches.push(vec!["soup", s]) }
    let by_cases = by_stages + soups.len();
    let mut leaders: Vec<(i64, i64)> = Vec::new();           // captain, then vice-captain
    for &c in &squad { for &v in &squad { if v != c { leaders.push((c, v)) } } }
    let by_shrinking = squad.len() * (squad.len() - 1);
    let rye = sandwiches.iter().filter(|s| s[0] == "rye").count();
    let chilli = sandwiches.iter().filter(|s| s[2] == "chilli").count();
    let both = sandwiches.iter().filter(|s| s[0] == "rye" && s[2] == "chilli").count();
    let either = sandwiches.iter().filter(|s| s[0] == "rye" || s[2] == "chilli").count();
    let mut captains: Vec<i64> = leaders.iter().map(|&(c, _)| c).collect();
    captains.dedup();
    println!("stage sizes: {} breads, {} fillings, {} sauces; and {} soups in the other case",
             breads.len(), fillings.len(), sauces.len(), soups.len());
    println!("bread-and-filling pairs, counted one bread at a time: {:?}", running);
    println!("sandwiches, stage sizes multiplied: {} x {} x {} = {}",
             breads.len(), fillings.len(), sauces.len(), by_stages);
    println!("sandwiches, every one built and counted: {}; no two alike: {}",
             sandwiches.len(), yn(distinct(&sandwiches) == sandwiches.len()));
    println!("first built and last: {} and {}",
             sandwiches[0].join(" + "), sandwiches[sandwiches.len() - 1].join(" + "));
    println!("lunches, the two cases added: {} + {} = {}", by_stages, soups.len(), by_cases);
    println!("lunches, every one built and counted: {}; no lunch counted twice: {}",
             lunches.len(), yn(distinct(&lunches) == lunches.len()));
    println!("captain then vice-captain, stage sizes multiplied: {} x {} = {}",
             squad.len(), squad.len() - 1, by_shrinking);
    println!("the same, every ordered pair of two different players listed: {}", leaders.len());
    println!("rye sandwiches {}, chilli sandwiches {}, both {}, either {}", rye, chilli, both, either);
    println!("mistake 1, stage sizes added: {} + {} + {} = {}, not {}", breads.len(), fillings.len(),
             sauces.len(), breads.len() + fillings.len() + sauces.len(), by_stages);
    println!("mistake 2, the two cases multiplied: {} x {} = {}, not {}",
             by_stages, soups.len(), by_stages * soups.len(), by_cases);
    println!("mistake 3, the vice-captain drawn from all {}: {} x {} = {}, not {}",
             squad.len(), squad.len(), squad.len(), squad.len() * squad.len(), by_shrinking);
    println!("mistake 4, overlapping groups added: {} + {} = {}, not {}", rye, chilli, rye + chilli, either);
    assert!(sandwiches.len() == by_stages && distinct(&sandwiches) == by_stages);
    assert!(lunches.len() == by_cases && distinct(&lunches) == sandwiches.len() + soups.len());
    assert!(leaders.len() == by_shrinking && captains.len() == squad.len());
    assert!(either == rye + chilli - both && both == fillings.len());
    println!("ALL CHECKS PASS");
}
