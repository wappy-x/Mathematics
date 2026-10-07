// Fractions -- the same check as fractions_check.py, in Rust.  No crates.  A
// pizza cut into 8 slices for three people, and a recipe wanting 3/4 cup of
// flour when you make half a batch.  Second road: the story counted in eighths.
fn hcf(a: i64, b: i64) -> i64 { if b == 0 { a } else { hcf(b, a % b) } }

fn tidy(t: i64, b: i64) -> (i64, i64) { (t / hcf(t, b), b / hcf(t, b)) }  // 2/8 -> 1/4

fn add(x: (i64, i64), y: (i64, i64)) -> (i64, i64) {   // a common bottom, add the tops
    tidy(x.0 * y.1 + y.0 * x.1, x.1 * y.1)
}

fn times(x: (i64, i64), y: (i64, i64)) -> (i64, i64) { // tops times tops, bottoms times bottoms
    tidy(x.0 * y.0, x.1 * y.1)
}

fn row(name: &str, f: (i64, i64)) { println!("{:<34}{:>3}/{}", name, f.0, f.1); }

fn main() {
    let (yours, friend, share) = ((3i64, 8i64), (1i64, 4i64), tidy(8, 3));
    let (both, flour) = (add(yours, friend), times((1, 2), (3, 4)));
    let (left, scoops) = (add((1, 1), (-both.0, both.1)), times(flour, (8, 1))); // take away: add a minus top
    row(&format!("you ate {} of the 8 slices", yours.0), yours);
    row("your friend ate a quarter", (2, 8));
    row("together", both);
    row("left in the box", left);
    row("half a batch of 3/4 cup, in cups", flour);
    row("that flour in 1/8-cup scoops", scoops);
    row("a fair share of the 8 slices", share);
    println!("a fair share is {} slices and {}/{} of a slice",
             share.0 / share.1, share.0 % share.1, share.1);
    let (m1, m2) = (tidy(3 + 1, 8 + 4), times(yours, (1, 8)));
    println!("the three mistakes come out at {}/{}, {}/{} and {}",
             m1.0, m1.1, m2.0, m2.1, 8 / 3);
    assert!(both == tidy(3 + 2, 8) && left == tidy(8 - 5, 8));
    assert!(flour == tidy(6 / 2, 8) && share.0 == 2 * share.1 + 2);
    assert!(scoops == (3, 1) && times(scoops, (1, 8)) == flour);
    println!("ALL CHECKS PASS");
}
