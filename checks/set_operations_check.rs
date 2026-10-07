// Set operations -- the same check as set_operations_check.py, in Rust.  No
// crates.  A 12-film watchlist: six films stream on service A, five on B, two
// on both.  Walk the list once into piles, then count the answers a second way.
const FILMS: [&str; 12] = ["Drift", "Ember", "Fathom", "Glint", "Halo", "Ivory",
                           "Kestrel", "Lantern", "Moth", "Nectar", "Onyx", "Pike"];
fn has(list: &[&str], f: &str) -> bool { list.iter().any(|x| *x == f) }
fn pick(test: impl Fn(&str) -> bool) -> Vec<&'static str> {   // walk all twelve films
    FILMS.iter().copied().filter(|f| test(f)).collect()
}
fn main() {
    let (a, b) = (&FILMS[..6], &FILMS[4..9]);    // service A, service B
    let union = pick(|f| has(a, f) || has(b, f));
    let both = pick(|f| has(a, f) && has(b, f));
    let a_only = pick(|f| has(a, f) && !has(b, f));
    let b_only = pick(|f| has(b, f) && !has(a, f));
    let neither = pick(|f| !has(a, f) && !has(b, f));         // not on A, and not on B
    let outside = pick(|f| !has(&union, f));                  // the other road
    let rows: [(&str, usize); 8] = [("films on the watchlist", FILMS.len()),
        ("films on service A", a.len()), ("films on service B", b.len()),
        ("on both, A and B", both.len()), ("A or B, the union", union.len()),
        ("A minus B, on A only", a_only.len()), ("B minus A, on B only", b_only.len()),
        ("not on either", outside.len())];
    for (label, n) in rows { println!("{:<30}{:>4}", label, n); }
    println!("not on A: {} -- not on B: {} -- in both of those lists: {}",
             pick(|f| !has(a, f)).len(), pick(|f| !has(b, f)).len(), neither.len());
    println!("A only: {} | both: {} | B only: {} | neither: {}", a_only.join(", "),
             both.join(", "), b_only.join(", "), outside.join(", "));
    println!("the three mistakes come out at {}, {} and {}",
             a.len() + b.len(), a.len() - b.len(), FILMS.len() - both.len());
    assert!(union.len() == 6 + 5 - 2 && outside.len() == 12 - 9);   // by arithmetic
    assert!(outside == neither && neither == ["Nectar", "Onyx", "Pike"]); // De Morgan
    assert!(both == ["Halo", "Ivory"] && a_only.len() == 4 && b_only.len() == 3);
    println!("ALL CHECKS PASS");
}
