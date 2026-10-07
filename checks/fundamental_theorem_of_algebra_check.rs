// The fundamental theorem of algebra -- the same check as the Python, in Rust.
// No crates.  A complex number a + bi is the integer pair (a, b), and i times i
// = -1 is the only new rule.  Two independent roads to every root: road one puts
// it into the polynomial, road two multiplies the brackets (x - root) back out.
type C = (i64, i64);
const I: C = (0, 1);
fn add(p: C, q: C) -> C { (p.0 + q.0, p.1 + q.1) }
fn mul(p: C, q: C) -> C { (p.0 * q.0 - p.1 * q.1, p.0 * q.1 + p.1 * q.0) }
fn metres(h: i64) -> String { format!("{}.{:02}", h / 100, h % 100) }  // hundredths of a metre
fn pair(z: C) -> String { format!("({}, {})", z.0, z.1) }
fn value_at(coeffs: &[i64], z: C) -> C {   // road one: the polynomial at z
    let (mut out, mut power) = ((0, 0), (1, 0));   // coefficients, constant first
    for &c in coeffs {
        out = add(out, mul((c, 0), power));
        power = mul(power, z);
    }
    out
}
fn from_roots(lead: i64, roots: &[C]) -> Vec<C> {  // road two: lead*(x - r1)...
    let mut coeffs = vec![(lead, 0)];
    for &r in roots {
        let mut nxt = vec![(0, 0); coeffs.len() + 1];
        for (j, &c) in coeffs.iter().enumerate() {
            nxt[j] = add(nxt[j], mul(c, (-r.0, -r.1)));
            nxt[j + 1] = add(nxt[j + 1], c);
        }
        coeffs = nxt;
    }
    coeffs
}
fn show(z: C) -> String {                  // the pair (a, b) written as a + bi
    let (a, b) = z;
    if b == 0 { return a.to_string(); }
    let tail = if b.abs() == 1 { "i".to_string() } else { format!("{}i", b.abs()) };
    if b > 0 { format!("{} + {}", a, tail) } else { format!("{} - {}", a, tail) }
}
fn main() {
    // the football: height 20t - 5t^2 and 5t^2 - 20t + 25 at t = k/10 s, in hundredths
    let heights: Vec<i64> = (0..41).map(|k| 200 * k - 5 * k * k).collect();
    let floors: Vec<i64> = (0..41).map(|k| 5 * (k * k - 40 * k + 500)).collect();
    let (max_h, min_p) = (*heights.iter().max().unwrap(), *floors.iter().min().unwrap());
    let real_hits = floors.iter().filter(|&&v| v == 0).count();
    let examples: Vec<(i64, Vec<i64>, Vec<C>, &str)> = vec![
        (5, vec![25, -20, 5], vec![(2, 1), (2, -1)], "5t^2 - 20t + 25"),
        (1, vec![-6, 11, -6, 1], vec![(1, 0), (2, 0), (3, 0)], "x^3 - 6x^2 + 11x - 6"),
        (1, vec![1, -2, 1], vec![(1, 0), (1, 0)], "x^2 - 2x + 1")];
    let (r1, r2) = (examples[0].2[0], examples[0].2[1]);   // the ball's two roots
    let gap = add(r1, (-r2.0, -r2.1));                     // r1 - r2, which is 2i
    let (disc, alt) = ((-20i64).pow(2) - 4 * 5 * 25, 25 * mul(gap, gap).0);  // two roads
    println!("i times i, as the pair (real part, i part): {}", pair(mul(I, I)));
    println!("height 20t - 5t^2 in metres, t = 0 to 4 seconds in half-seconds:");
    let mut row = String::from("  ");
    for k in (0..41).step_by(5) { row.push_str(&format!("{:>7}", metres(heights[k]))); }
    println!("{}", row);
    println!("the highest height on a tenth-second grid is {} m, leaving the 25 m \
              target {} m out of reach", metres(max_h), metres(2500 - max_h));
    println!("5t^2 - 20t + 25 over {} grid times: lowest value {}, real roots found {}",
             floors.len(), metres(min_p), real_hits);
    println!("its discriminant: {} from b^2 - 4ac, {} from 25 x (root gap)^2; 10 x 10 \
              = {}, so the square root of {} is 10i", disc, alt, 10 * 10, disc);
    for (lead, coeffs, roots, label) in &examples {
        let roots_s: Vec<String> = roots.iter().map(|&r| show(r)).collect();
        let road_one: Vec<String> = roots.iter().map(|&r| pair(value_at(coeffs, r))).collect();
        let back = from_roots(*lead, roots);
        let road_two: Vec<String> = back.iter().map(|c| c.0.to_string()).collect();
        println!("{} = 0, degree {}, roots {}", label, coeffs.len() - 1, roots_s.join(", "));
        println!("  road one, the polynomial at each root: {}", road_one.join(", "));
        println!("  road two, brackets multiplied back, constant first: {}", road_two.join(", "));
        assert!(roots.iter().all(|&r| value_at(coeffs, r) == (0, 0))
            && back == coeffs.iter().map(|&c| (c, 0)).collect::<Vec<C>>());
    }
    let bad = value_at(&examples[0].1, (1, 0)).0;   // t = 1, from misreading the root
    let wrong = (from_roots(1, &[r1, r2])[0].0, bad, 25 - bad);
    println!("mistakes: leading 5 dropped leaves constant {} not 25; times 1 and 3 \
              give {} not 0, a height of {} m not 25 m", wrong.0, wrong.1, wrong.2);
    assert!(mul(I, I) == (-1, 0));
    assert!(max_h == 2000 && max_h + min_p == 2500 && disc == alt);
    assert!(real_hits == 0 && wrong == (5, 10, 15));
    println!("ALL CHECKS PASS");
}
