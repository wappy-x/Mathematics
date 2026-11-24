// Group presentations -- the same check as the Python, in Rust.  No crates.  A
// word is a string of letters.  Road one rewrites words with the relations alone.
// Road two is von Dyck's map: send each letter to a concrete move and multiply.
// Road three multiplies the concrete moves together until nothing new appears.
use std::collections::BTreeSet;
type El = Vec<i64>;
type Mul = fn(&El, &El) -> El;
fn reduce(word: &str, rules: &[(&str, &str)]) -> String {   // road one: apply a relation while one fits
    let mut w = word.to_string();
    while let Some(&(old, new)) = rules.iter().find(|(old, _)| w.contains(old)) { w = w.replacen(old, new, 1) }
    w
}
fn image(word: &str, gens: &[(char, El)], mul: Mul, one: &El) -> El {   // road two: von Dyck's map
    word.chars().fold(one.clone(), |out, x| mul(&out, &gens.iter().find(|g| g.0 == x).unwrap().1))
}
fn close(gens: &[(char, El)], mul: Mul, one: &El) -> BTreeSet<El> {   // road three: multiply until nothing new
    let (mut seen, mut todo) = (BTreeSet::from([one.clone()]), vec![one.clone()]);
    while let Some(a) = todo.pop() { for g in gens { let b = mul(&a, &g.1); if seen.insert(b.clone()) { todo.push(b) } } }
    seen
}
fn order(a: &El, mul: Mul, one: &El) -> usize { (1..9).find(|&k| image(&"x".repeat(k), &[('x', a.clone())], mul, one) == *one).unwrap() }
fn words(letters: &[char], n: usize) -> Vec<String> {       // every word of 1 to n letters
    let (mut out, mut layer) = (vec![], vec![String::new()]);
    for _ in 0..n { layer = layer.iter().flat_map(|v| letters.iter().map(move |x| format!("{}{}", v, x))).collect(); out.extend(layer.clone()) }
    out
}
fn turn(p: &El, q: &El) -> El { q.iter().map(|&c| p[c as usize]).collect() }   // corner maps: q first, then p
fn quat(p: &El, q: &El) -> El {
    vec![p[0]*q[0] - p[1]*q[1] - p[2]*q[2] - p[3]*q[3], p[0]*q[1] + p[1]*q[0] + p[2]*q[3] - p[3]*q[2],
         p[0]*q[2] - p[1]*q[3] + p[2]*q[0] + p[3]*q[1], p[0]*q[3] + p[1]*q[2] - p[2]*q[1] + p[3]*q[0]]
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn main() {
    let tile: Vec<(&str, &str)> = vec![("ff", ""), ("rrrr", ""), ("fr", "rrrf")];   // f r f = r^-1, used as f r = r^3 f
    let groups: Vec<(&str, Vec<(&str, &str)>, Vec<(char, El)>, Mul, El)> = vec![
        ("tile <r, f | r^4, f^2, f r f = r^-1>", tile.clone(), vec![('r', vec![1, 2, 3, 0]), ('f', vec![0, 3, 2, 1])], turn, vec![0, 1, 2, 3]),
        ("Q8 <i, j | i^4, i^2 = j^2, j i j^-1 = i^-1>", vec![("jj", "ii"), ("iiii", ""), ("ji", "iiij")],
         vec![('i', vec![0, 1, 0, 0]), ('j', vec![0, 0, 1, 0])], quat, vec![1, 0, 0, 0])];
    let mut twos = vec![];
    for (name, rules, gens, mul, one) in &groups {
        let ws = words(&gens.iter().map(|g| g.0).collect::<Vec<char>>(), 8);
        let im = |w: &str| image(w, gens, *mul, one);
        let holds = rules.iter().all(|(a, b)| im(a) == im(b));
        let mut forms: Vec<String> = ws.iter().map(|w| reduce(w, rules)).collect::<BTreeSet<_>>().into_iter().collect();
        forms.sort_by_key(|w| (w.ends_with('f') || w.ends_with('j'), w.len()));
        let lands = ws.iter().all(|w| im(w) == im(&reduce(w, rules)));
        let moves: BTreeSet<El> = forms.iter().map(|w| im(w)).collect();
        let found = close(gens, *mul, one);
        let orders: Vec<usize> = forms.iter().map(|w| order(&im(w), *mul, one)).collect();
        let n2 = orders.iter().filter(|&&k| k == 2).count(); twos.push(n2);
        println!("{}\n  relations hold on the concrete moves: {}; words of 1 to 8 letters: {}", name, yn(holds), ws.len());
        let shown: Vec<&str> = forms.iter().map(|w| if w.is_empty() { "e" } else { w.as_str() }).collect();
        println!("  normal forms reached: {} ({})", shown.join(" "), forms.len());
        println!("  every word lands where its normal form lands: {}", yn(lands));
        println!("  distinct moves from the forms: {}; moves found by brute closure: {}", moves.len(), found.len());
        println!("  orders: {:?}; elements of order 2: {}", orders, n2);
        assert!(holds && lands && forms.len() == 8 && moves == found && found.len() == 8);
    }
    let free: Vec<usize> = [4, 6, 8].iter()
        .map(|&n| words(&['r', 'f'], n).iter().map(|w| reduce(w, &tile[..2])).collect::<BTreeSet<_>>().len()).collect();
    let half = vec![('r', vec![1, 2, 3, 0]), ('f', vec![2, 3, 0, 1])];          // f sent to the half turn
    let bad = |w: &str| image(w, &half, turn, &vec![0, 1, 2, 3]);
    let miss = words(&['r', 'f'], 8).iter().filter(|w| bad(w) != bad(&reduce(w, &tile))).count();
    println!("mistake 1, drop f r f = r^-1: different elements from words up to 4, 6, 8 letters: {:?}", free);
    println!("mistake 2, f sent to the half turn: f r f lands on {:?}, r^-1 on {:?}; {} of {} words land off their normal form",
             bad("frf"), bad("rrr"), miss, words(&['r', 'f'], 8).len());
    println!("mistake 3, order 8 taken as sameness: elements of order 2, tile {}, Q8 {}", twos[0], twos[1]);
    let (coll, e): (Vec<(&str, &str)>, El) = ([&tile[..2], &[("fr", "rrf")]].concat(), vec![0, 1, 2, 3]);   // f r f = r^2
    let s4 = close(&[('a', vec![1, 0, 2, 3]), ('b', vec![1, 2, 3, 0])], turn, &e);
    let fits: Vec<usize> = s4.iter().flat_map(|r| s4.iter().map(move |f| vec![('r', r.clone()), ('f', f.clone())]))
        .filter(|g| coll.iter().all(|(a, b)| image(a, g, turn, &e) == image(b, g, turn, &e))).map(|g| close(&g, turn, &e).len()).collect();
    let nc = words(&['r', 'f'], 8).iter().map(|w| reduce(w, &coll)).collect::<BTreeSet<_>>().len();
    let ffr = [reduce("ffr", &coll), reduce("ffr", &coll.iter().rev().cloned().collect::<Vec<_>>())];   // two rule orders
    let show = |w: &String| if w.is_empty() { "e".to_string() } else { w.clone() };
    println!("trap, f r f = r^2: {} normal forms; f f r rewrites to {} or to {}; largest model in {} corner maps: {} moves",
             nc, show(&ffr[0]), show(&ffr[1]), s4.len(), fits.iter().max().unwrap());
    assert!(twos == vec![5, 1] && free[0] < free[1] && free[1] < free[2] && bad("frf") != bad("rrr") && miss > 0);
    assert!(nc == 8 && ffr == ["r", ""] && *fits.iter().max().unwrap() == 2);       // so r = e: the group is e and f
    println!("ALL CHECKS PASS");
}
