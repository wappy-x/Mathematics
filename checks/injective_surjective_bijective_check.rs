// One-to-one and onto -- the same check as the Python, in Rust.  No crates.  The
// 24-hour clock read onto a 12-hour dial, then eight guests seated two ways.
// Route 1 reads the arrows forwards; route 2 counts the arrivals at each output.
fn dial(h: i64) -> i64 { if h % 12 == 0 { 12 } else { h % 12 } }   // 00:00 and 12:00 both give dial 12
fn arrivals(pairs: &[(i64, i64)], codomain: &[i64]) -> Vec<usize> {   // route 2: inputs landing on each output
    codomain.iter().map(|c| pairs.iter().filter(|p| p.1 == *c).count()).collect()
}
fn verdict(pairs: &[(i64, i64)], codomain: &[i64]) -> String {
    let mut hits: Vec<i64> = pairs.iter().map(|p| p.1).collect();
    hits.sort_unstable(); hits.dedup();
    let mut cod: Vec<i64> = codomain.to_vec();
    cod.sort_unstable(); cod.dedup(); assert!(hits.iter().all(|h| cod.contains(h)), "an output landed outside the codomain");
    let (one_to_one, onto) = (hits.len() == pairs.len(), cod.iter().all(|c| hits.contains(c)));   // route 1
    let n = arrivals(pairs, codomain);
    assert_eq!((one_to_one, onto), (*n.iter().max().unwrap() <= 1, *n.iter().min().unwrap() >= 1));   // the routes agree
    format!("{}{}", if one_to_one { "one-to-one" } else { "not one-to-one" }, if onto { " and onto" } else { " and not onto" })
}
fn show(label: &str, pairs: &[(i64, i64)], codomain: &[i64], unit: &str) {
    let n = arrivals(pairs, codomain);
    println!("{}: {}", label, verdict(pairs, codomain));
    println!("  arrivals at each {}: {} -- {} in total, {} with none arriving", unit,
             n.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(" "),
             n.iter().sum::<usize>(), n.iter().filter(|&&x| x == 0).count());
}
fn main() {
    let (dial12, seats, ten): (Vec<i64>, Vec<i64>, Vec<i64>) = ((1..=12).collect(), (1..=8).collect(), (1..=10).collect());
    let (clock, seated): (Vec<(i64, i64)>, Vec<(i64, i64)>) = ((0..24).map(|h| (h, dial(h))).collect(), (1..=8).map(|g| (g, g)).collect());   // guest 1 in seat 1
    let mut nine = seated.clone(); nine.push((9, 1));                             // a ninth guest, still eight seats
    let crowd: Vec<(i64, i64)> = (1..=8).zip([1, 2, 3, 3, 5, 6, 7, 8]).collect(); // two guests take seat 3
    show("the clock, 24 hours (0 to 23) onto 12 dial numbers", &clock, &dial12, "dial number");
    println!("  01:00 gives dial {}, 13:00 gives dial {}, 12:00 gives dial {}, 00:00 gives dial {}", dial(1), dial(13), dial(12), dial(0));
    show("eight guests, eight numbered seats", &seated, &seats, "seat");
    show("the same eight guests in a ten-seat row", &seated, &ten, "seat");
    println!("breaks: nine guests into eight seats -- {}, one seat holds {}", verdict(&nine, &seats), arrivals(&nine, &seats).iter().max().unwrap());
    println!("breaks: two guests crowd seat 3 -- {}, {} seats of 8 filled", verdict(&crowd, &seats), 8 - arrivals(&crowd, &seats).iter().filter(|&&x| x == 0).count());
    assert!(verdict(&clock, &dial12) == "not one-to-one and onto" && arrivals(&clock, &dial12) == vec![2; 12]);
    assert!(verdict(&seated, &seats) == "one-to-one and onto" && verdict(&seated, &ten) == "one-to-one and not onto");
    assert!(*arrivals(&nine, &seats).iter().max().unwrap() == 2 && arrivals(&crowd, &seats).iter().filter(|&&x| x == 0).count() == 1 && arrivals(&clock, &dial12).iter().sum::<usize>() == 24);
    println!("ALL CHECKS PASS");
}
