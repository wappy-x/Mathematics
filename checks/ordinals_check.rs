// Ordinals -- the same check as the Python, in Rust.  No crates.  An ordinal below ω·ω is (a, b): a full hotels, then b people.
type O = (u32, u32);
fn name(o: O) -> String {
    let w = match o.0 { 0 => String::new(), 1 => "ω".to_string(), a => format!("ω·{}", a) };
    if !w.is_empty() && o.1 > 0 { format!("{}+{}", w, o.1) } else if w.is_empty() { o.1.to_string() } else { w }
}
fn add(x: O, y: O) -> O { if y.0 > 0 { (x.0 + y.0, y.1) } else { (x.0, x.1 + y.1) } } // y queues behind x
fn bad(x: O, y: O) -> O { if y.0 > 0 { y } else { add(x, y) } } // "an endless line swallows what is in front"
fn walk(blocks: &[Option<u32>]) -> (O, bool) {   // the same rule, piece by piece: None is a full hotel; Some(n) is n people
    let (mut a, mut b, mut last) = (0, 0, false); // ω·a + b people stand ahead of the next one
    for blk in blocks {     // after a full hotel the count of people restarts, and nobody is last
        match blk { None => { a += 1; b = 0; last = false } Some(n) => { b += n; last = *n > 0 } }
    }
    ((a, b), last)
}
fn main() {
    let (w, one, h, p) = ((1, 0), (0, 1), None, 5u32);   // p: the room the back guest is sent to
    let rows: [(&str, O, Vec<Option<u32>>); 4] = [("the hotel, room by room", w, vec![h]), ("late guest at the back", add(w, one), vec![h, Some(1)]),
        ("late guest at the front", add(one, w), vec![Some(1), h]), ("two hotels in a row", add(w, w), vec![h, h])];
    println!("{:<26}{:<13}{:<12}last person", "line-up", "by the rule", "by walking");
    for (label, rule, blocks) in &rows {
        let (o, last) = walk(blocks); assert!(o == *rule && last == (rule.1 > 0)); // rule and walk agree
        println!("{:<26}{:<13}{:<12}{}", label, name(*rule), name(o), if last { "yes" } else { "no" });
    }
    let rooms: Vec<u32> = [0u32, 1, 2, 3, 4, 5].iter().map(|&g| if g == 0 { 1 } else { g + 1 }).collect(); // 0 is L
    let pairs: Vec<u32> = (1..4u32).flat_map(|k| [2 * k - 1, 2 * k]).collect();  // 2·ω: two places per pair
    let mut vn: Vec<Vec<usize>> = vec![vec![]];   // ordinal i as the list of ordinals below it
    for i in 0..3 { let mut next = vn[i].clone(); next.push(i); vn.push(next); }   // all so far, plus itself
    assert!(rooms == (1..7).collect::<Vec<u32>>() && pairs == rooms);   // both pairings keep order and fill places 1 to 6
    assert!(vn.iter().enumerate().all(|(i, v)| v.len() == i && (i == 0 || v.contains(&(i - 1)))) && w < add(w, one) && add(w, one) < add(w, w));
    assert!(add(w, one) != add(one, w) && bad(w, w) != add(w, w) && add((0, 2), (0, 3)) == walk(&[Some(3), Some(2)]).0);
    let s = |v: &[u32]| v.iter().map(|x| x.to_string()).collect::<Vec<_>>();
    println!("front guest re-paired: L, 1, 2, 3, 4, 5 go to rooms {}, order kept", s(&rooms).join(", "));
    println!("back guest sent to room {}: {} rooms ahead of it, but guests 1 to {} all stand ahead of him", p, (1..p).count(), p);
    println!("2·ω, pair k takes places 2k-1 and 2k: {} ..., so 2·ω = ω; ω·2 = {}", s(&pairs).join(" "), name(add(w, w)));
    println!("finite line-ups: 2+3 = {} and 3+2 = {}", name(add((0, 2), (0, 3))), name(add((0, 3), (0, 2))));
    println!("von Neumann: {}", vn.iter().enumerate().map(|(i, v)| format!("{} = {{{}}}", i, v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))).collect::<Vec<_>>().join(", "));
    println!("order: ω < ω+1 < ω·2; mistakes come out at {}, {} and {}", name(add(w, one)), name(add(w, w)), name(bad(w, w)));
    println!("ALL CHECKS PASS");
}
