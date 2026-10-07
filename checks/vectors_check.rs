// Vectors -- the same check as the Python, in Rust.  No crates.  A delivery
// cyclist rides (3 km east, 4 km north), then rides (2, -1).  Two roads to the
// finish: adding the two legs component by component, and walking the whole
// ride one kilometre at a time to see where the bike actually stops.
fn add(p: &[i64], q: &[i64]) -> Vec<i64> {          // slot by slot
    p.iter().zip(q.iter()).map(|(a, b)| a + b).collect()
}
fn scale(k: i64, p: &[i64]) -> Vec<i64> {           // every slot times k
    p.iter().map(|a| k * a).collect()
}
fn fmt(v: &[i64]) -> String {
    let parts: Vec<String> = v.iter().map(|a| a.to_string()).collect();
    format!("({})", parts.join(", "))
}
fn show(name: &str, value: String) { println!("{:<46}{:>18}", name, value); }
fn row(name: &str, values: &[f64]) {
    let parts: Vec<String> = values.iter().map(|v| format!("{:.2}", v)).collect();
    println!("{:<46}{}", name, parts.join(" "));
}
fn main() {
    let u: Vec<i64> = vec![3, 4];                   // the two legs, two numbers each
    let v: Vec<i64> = vec![2, -1];
    let week: Vec<i64> = vec![12, 9, 15, 11];       // the same two rules on four numbers
    let evening: Vec<i64> = vec![3, 4, 2, 6];
    let total = add(&u, &v);                        // road one: add the two lists
    let (mut east, mut north) = (0i64, 0i64);       // road two: walk it, 1 km at a time
    let mut steps: Vec<(i64, i64)> = vec![(1, 0); 3];
    steps.extend(vec![(0, 1); 4]);
    steps.extend(vec![(1, 0); 2]);
    steps.extend(vec![(0, -1); 1]);
    for (de, dn) in &steps { east += de; north += dn; }
    let walked = vec![east, north];
    let zero = scale(0, &u);                        // the ride that never happened
    show("first leg u", fmt(&u));
    show("second leg v", fmt(&v));
    show("u + v, added component by component", fmt(&total));
    show("where the ride ends, walked one km at a time", fmt(&walked));
    show("2u, the first leg ridden twice", fmt(&scale(2, &u)));
    show("u + u, the same doubling by adding", fmt(&add(&u, &u)));
    show("the zero vector, never left the shop", fmt(&zero));
    show("u + 0", fmt(&add(&u, &zero)));
    show("u + (-u)", fmt(&add(&u, &scale(-1, &u))));
    let path: Vec<f64> = (0..6).map(|i| {           // the two legs, bent at (3, 4)
        let x = i as f64;
        if x <= 3.0 { 4.0 * x / 3.0 } else { 4.0 - (x - 3.0) / 2.0 }
    }).collect();
    let arrow: Vec<f64> = (0..6)                    // the one arrow, straight to (5, 3)
        .map(|i| total[1] as f64 * i as f64 / total[0] as f64).collect();
    row("path chart, km north at 0,1,2,3,4,5 km east", &path);
    row("arrow chart, km north at the same six points", &arrow);
    let mut bars = u.clone();
    bars.extend(scale(2, &u));
    show("bar chart, east and north of u then of 2u", fmt(&bars));
    show("a week of rides in R^4, WEEK + EVENING", fmt(&add(&week, &evening)));
    let flattened: i64 = u.iter().sum::<i64>() + v.iter().sum::<i64>();
    let multiplied: Vec<i64> = u.iter().zip(v.iter()).map(|(a, b)| a * b).collect();
    let half_scaled = vec![2 * u[0], u[1]];
    println!("the three mistakes come out at {}, {} and {}",
             flattened, fmt(&multiplied), fmt(&half_scaled));
    assert!(total == vec![5, 3] && walked == total);     // two roads, one finish
    assert!(scale(2, &u) == vec![6, 8] && add(&u, &u) == scale(2, &u));
    assert!(add(&u, &zero) == u && add(&u, &scale(-1, &u)) == vec![0, 0]);
    assert!(add(&week, &evening) == vec![15, 13, 17, 17] && add(&week, &evening).len() == 4);
    println!("ALL CHECKS PASS");
}
