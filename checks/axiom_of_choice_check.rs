// The axiom of choice -- the same check as the Python one, in Rust.  No crates.
// Ten lost-property boxes, two socks in each.  Count every full pick -- one sock
// out of every box, all at once -- twice: by multiplying, and by building them.
const SOCKS: [&str; 2] = ["left", "right"];
fn full_picks(boxes: &[Vec<&'static str>]) -> Vec<Vec<&'static str>> {
    let mut picks: Vec<Vec<&'static str>> = vec![Vec::new()];
    for b in boxes {                    // every way to take one thing out of every box
        let mut next = Vec::new();
        for p in &picks { for s in b { let mut q = p.clone(); q.push(*s); next.push(q); } }
        picks = next;
    }
    picks
}

fn row(name: &str, value: usize) { println!("{:<44}{:>5}", name, value); }

fn main() {
    let ten: Vec<Vec<&str>> = (0..10).map(|_| SOCKS.to_vec()).collect();
    let three: Vec<Vec<&str>> = (0..3).map(|_| SOCKS.to_vec()).collect();
    let mut gap: Vec<Vec<&str>> = (0..9).map(|_| SOCKS.to_vec()).collect();
    gap.push(Vec::new());                          // one box with nothing in it
    let picks = full_picks(&ten);
    let shoe_rule: Vec<&str> = ten.iter().map(|_| "left").collect();
    let mut mult = 1;
    for b in &ten { mult = mult * b.len(); }       // the second road: 2 x 2 x ... x 2
    let named = picks.iter().filter(|p| *p == &shoe_rule).count();
    let mut kept: Vec<&Vec<&str>> = picks.iter().filter(|p| p.len() == ten.len()).collect(); kept.sort(); kept.dedup();
    row("boxes of socks", ten.len());
    row("socks in each box", SOCKS.len());
    row("full picks, by multiplying", mult);
    row("full picks, by building every one", picks.len());
    row("full picks with only three boxes", full_picks(&three).len());
    row("full picks when one box is empty", full_picks(&gap).len());
    row("picks the shoe rule names", named);
    row("different picks, ten socks in each", kept.len());
    assert!(mult == 1024 && picks.len() == 1024 && kept.len() == 1024);
    assert!(full_picks(&three).len() == 8 && full_picks(&gap).len() == 0);
    assert!(named == 1 && picks.contains(&shoe_rule));
    println!("ALL CHECKS PASS");
}
