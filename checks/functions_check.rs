// Functions -- the same check as functions_check.py, in Rust.  No crates.  A vending machine: 6 buttons,
// 5 snacks stocked.  The wiring is read forwards, button by button, then backwards, snack by snack.
const BUTTONS: [&str; 6] = ["A1", "A2", "A3", "B1", "B2", "B3"];
const SNACKS: [&str; 5] = ["crisps", "chocolate", "flapjack", "gum", "mints"];
const WIRING: [(&str, &str); 6] = [("A1", "crisps"), ("A2", "crisps"), ("A3", "chocolate"), ("B1", "flapjack"), ("B2", "gum"), ("B3", "gum")];
const SOLD_OUT: [&str; 2] = ["chocolate", "mints"];
fn out(pairs: &[(&'static str, &'static str)], b: &str) -> Vec<&'static str> {          // forwards: the snacks this button hands out
    pairs.iter().filter(|p| p.0 == b).map(|p| p.1).collect()
}
fn preimage(pairs: &[(&'static str, &'static str)], target: &[&str]) -> Vec<&'static str> {   // backwards: every button whose snack is in target
    BUTTONS.iter().cloned().filter(|b| out(pairs, b).iter().any(|s| target.contains(s))).collect()
}
fn image(pairs: &[(&'static str, &'static str)], buttons: &[&str]) -> Vec<&'static str> {     // forwards: every snack those buttons hand out
    SNACKS.iter().cloned().filter(|s| buttons.iter().any(|b| out(pairs, b).contains(s))).collect()
}
fn join(xs: &[&str]) -> String { xs.join(", ") }
fn main() {
    let counts: Vec<usize> = SNACKS.iter().map(|s| preimage(&WIRING, &[s]).len()).collect();
    let answered: Vec<usize> = BUTTONS.iter().map(|b| out(&WIRING, b).len()).collect();
    let (rng, rng2) = (image(&WIRING, &BUTTONS), SNACKS.iter().cloned().enumerate().filter(|&(i, _)| counts[i] > 0).map(|(_, s)| s).collect::<Vec<&str>>());   // two routes to the range
    let indicator: Vec<usize> = SNACKS.iter().map(|s| if SOLD_OUT.contains(s) { 1 } else { 0 }).collect();
    let (jam, double): (Vec<(&str, &str)>, Vec<(&str, &str)>) = (WIRING.iter().cloned().filter(|p| p.0 != "B3").collect(), WIRING.iter().cloned().chain([("A1", "chocolate")]).collect());   // B3 gives nothing; A1 drops two
    let (crisps, mints, sold) = (preimage(&WIRING, &["crisps"]), preimage(&WIRING, &["mints"]), preimage(&WIRING, &SOLD_OUT));
    let img = image(&WIRING, &["A1", "A3"]);
    println!("buttons (domain): {} -- {}", join(&BUTTONS), BUTTONS.len());
    println!("snacks stocked (codomain): {} -- {}", join(&SNACKS), SNACKS.len());
    println!("wiring: {}", WIRING.iter().map(|p| format!("{} {}", p.0, p.1)).collect::<Vec<String>>().join(", "));
    println!("every button answered exactly once: {}, {} pairs for {} buttons", if answered == vec![1; BUTTONS.len()] { "yes" } else { "no" }, WIRING.len(), BUTTONS.len());
    println!("range (snacks actually given): {} -- {}", join(&rng), rng.len());
    println!("buttons per snack: {} -- {} in total", SNACKS.iter().zip(&counts).map(|(s, n)| format!("{} {}", s, n)).collect::<Vec<String>>().join(", "), counts.iter().sum::<usize>());
    println!("preimage of crisps: {} -- {} buttons; preimage of mints: none -- {} buttons", join(&crisps), crisps.len(), mints.len());
    println!("image of A1 and A3: {} -- {} snacks", join(&img), img.len());
    println!("sold out {{{}}}: indicator {}, sum {}; buttons hitting it: {} -- {}", join(&SOLD_OUT), indicator.iter().map(|i| i.to_string()).collect::<Vec<String>>().join(" "), indicator.iter().sum::<usize>(), join(&sold), sold.len());
    println!("broken: a jammed B3 answers {} of {}; A1 dropping two answers {} pairs for {} buttons", jam.len(), BUTTONS.len(), double.len(), BUTTONS.len());
    assert!(answered == vec![1; 6] && WIRING.len() == 6 && jam.len() == 5 && double.len() == 7);
    assert!(rng == ["crisps", "chocolate", "flapjack", "gum"] && rng == rng2 && rng.len() == 4 && !rng.contains(&"mints"));
    assert!(counts == [2, 1, 1, 2, 0] && counts.iter().sum::<usize>() == BUTTONS.len() && crisps == ["A1", "A2"] && mints.is_empty());
    assert!(indicator.iter().sum::<usize>() == 2 && sold == ["A3"] && img == ["crisps", "chocolate"] && preimage(&double, &["chocolate"]) == ["A1", "A3"]);
    println!("ALL CHECKS PASS");
}
