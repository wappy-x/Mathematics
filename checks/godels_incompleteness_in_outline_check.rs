// Godel's theorems -- the same check as godels_incompleteness_in_outline_check.py,
// in Rust.  No crates.  It numbers sentences, builds the sentence G that speaks
// about its own number, and checks a proof in arithmetic step by step.  A code
// number is kept as its base-16 digits; a small big-number routine prints it.
use std::collections::HashSet;
const SYMS: &[u8] = b"?0S+*=()~xPD";        // a symbol's code is its place in this list
fn code(c: u8) -> u8 { SYMS.iter().position(|&s| s == c).unwrap() as u8 }
fn godel(s: &str) -> Vec<u8> { s.bytes().map(code).collect() }   // base-16 digits
fn small(d: &[u8]) -> u64 { d.iter().fold(0, |n, &x| n * 16 + x as u64) }
fn decimal(d: &[u8]) -> String {             // big number: limbs of nine decimal digits
    let mut limbs: Vec<u64> = vec![0];
    for &x in d {
        let mut carry = x as u64;
        for l in limbs.iter_mut() { let v = *l * 16 + carry; *l = v % 1_000_000_000; carry = v / 1_000_000_000; }
        if carry > 0 { limbs.push(carry); }
    }
    let mut s = limbs.last().unwrap().to_string();
    for l in limbs.iter().rev().skip(1) { s.push_str(&format!("{:09}", l)); }
    s
}
fn decode(mut n: u64) -> String {            // back again, by division only
    let mut out = Vec::new();
    while n > 0 { out.insert(0, SYMS[(n % 16) as usize]); n /= 16; }
    String::from_utf8(out).unwrap()
}
fn num_bits(bits: &[bool]) -> String {       // the numeral, from the bits of n
    let start = match bits.iter().position(|&b| b) { Some(p) => p, None => return "0".into() };
    let mut t = String::from("S0");          // the leading 1; then double, adding S on a 1 bit
    for &b in &bits[start + 1..] { t = format!("{}(SS0*{})", if b { "S" } else { "" }, t); }
    t
}
fn bits_of(d: &[u8]) -> Vec<bool> { d.iter().flat_map(|&x| (0..4).rev().map(move |k| x >> k & 1 == 1)).collect() }
fn num(n: u64) -> String { num_bits(&(0..64).rev().map(|k| n >> k & 1 == 1).collect::<Vec<_>>()) }
fn value(t: &[u8], i: usize) -> (u64, usize) {  // read a term's value off its symbols
    if t[i] == b'0' { return (0, i + 1); }
    if t[i] == b'S' { let (v, j) = value(t, i + 1); return (v + 1, j); }
    let (a, j) = value(t, i + 1); let (b, k) = value(t, j + 1);  // '(' a op b ')'
    (if t[j] == b'+' { a + b } else { a * b }, k + 1)
}
fn diag(s: &str) -> String { s.replace('x', &num(small(&godel(s)))) }   // road A: on symbols
fn diag_arith(n: u64) -> Vec<u8> {           // road B: the same map on numbers only
    let (mut lo, mut m) = (Vec::new(), n);
    while m > 0 && m % 16 != code(b'x') as u64 { lo.insert(0, (m % 16) as u8); m /= 16; }
    let mut out: Vec<u8> = godel(&decode(m / 16)); // the digits left of x
    out.extend(godel(&num(n))); out.extend(lo); out
}
fn row(name: &str, v: String) { println!("{:<44}{}", name, v); }

#[derive(Clone, PartialEq, Eq, Hash)]
enum T { Z, S(Box<T>), Op(u8, Box<T>, Box<T>) }
fn term(s: &[u8], i: usize) -> (T, usize) {  // parse "SS0*SS0" style terms into trees
    if s[i] == b'0' { return (T::Z, i + 1); }
    if s[i] == b'S' { let (t, j) = term(s, i + 1); return (T::S(Box::new(t)), j); }
    let (a, j) = term(s, i + 1); let (b, k) = term(s, j + 1);
    (T::Op(s[j], Box::new(a), Box::new(b)), k + 1)
}
fn show(t: &T) -> String { match t { T::Z => "0".into(), T::S(a) => format!("S{}", show(a)),
    T::Op(o, a, b) => format!("({}{}{})", show(a), *o as char, show(b)) } }
fn sc(t: T) -> T { T::S(Box::new(t)) }
fn op(o: u8, a: T, b: T) -> T { T::Op(o, Box::new(a), Box::new(b)) }
fn root(t: &T, extra: bool) -> Vec<T> {      // every rule that fits at the top of t
    let mut out = Vec::new();
    if let T::Op(o, a, b) = t {
        match (o, &**b) {
            (b'+', T::Z) => out.push((**a).clone()),                                  // a+0 = a
            (b'+', T::S(c)) => out.push(sc(op(b'+', (**a).clone(), (**c).clone()))),   // a+Sb = S(a+b)
            (b'*', T::Z) => out.push(T::Z),                                           // a*0 = 0
            (b'*', T::S(c)) => out.push(op(b'+', op(b'*', (**a).clone(), (**c).clone()), (**a).clone())),
            _ => {}
        }
    }
    if extra && *t == T::Z { out.push(sc(T::Z)); }                                   // the bad axiom 0 = S0
    out
}
fn steps(t: &T, extra: bool) -> Vec<T> {     // every term one rule-use away from t
    let mut out = root(t, extra);
    match t {
        T::Z => {}
        T::S(a) => out.extend(steps(a, extra).into_iter().map(sc)),
        T::Op(o, a, b) => {
            out.extend(steps(a, extra).into_iter().map(|u| op(*o, u, (**b).clone())));
            out.extend(steps(b, extra).into_iter().map(|u| op(*o, (**a).clone(), u)));
        }
    }
    out
}
fn checker(chain: &[T], extra: bool) -> bool { chain.windows(2).all(|w| steps(&w[0], extra).contains(&w[1])) }
fn shortest(start: &T, goal: &T, cap: usize) -> Option<usize> {  // breadth-first proof search, capped
    let (mut level, mut seen) = (vec![start.clone()], HashSet::from([start.clone()]));
    for d in 0..=cap {
        if level.contains(goal) { return Some(d); }
        let mut next = Vec::new();
        for t in &level { for u in steps(t, false) { if seen.insert(u.clone()) { next.push(u); } } }
        level = next;
    }
    None
}

fn main() {
    println!("-- numbering --");
    let one = "S0+S0=SS0";
    row("code of the sentence S0+S0=SS0 (1 + 1 = 2)", small(&godel(one)).to_string());
    row("decoded back by division", decode(small(&godel(one))));
    let x = "~P(D(x))";
    let gx = small(&godel(x));
    row("code of the template X = ~P(D(x))", gx.to_string());
    row("numeral of that code, in symbols", num(gx).len().to_string());
    row("value read back off the numeral", value(num(gx).as_bytes(), 0).0.to_string());
    println!("-- the sentence G = X with its own code put in --");
    let g = diag(x);
    let gg = godel(&g);
    let gd = decimal(&gg);
    row("length of G, in symbols", g.len().to_string());
    row("digits in the code of G", gd.len().to_string());
    row("code of G begins", gd[..12].to_string());
    row("code of G ends", gd[gd.len() - 12..].to_string());
    let inner = value(&g.as_bytes()[5..g.len() - 2], 0).0;   // road C: the term D is applied to
    row("D's argument inside G evaluates to", inner.to_string());
    row("road A and road B agree on the code of G", cap(godel(&diag(x)) == diag_arith(gx)));
    row("D(argument) is the code of G itself", cap(diag_arith(inner) == gg));

    println!("-- a proof in arithmetic: 2 x 2 = 4, one rule per line --");
    let mut chain = vec![term(b"(SS0*SS0)", 0).0];
    loop { let s = steps(chain.last().unwrap(), false); if s.is_empty() { break; } chain.push(s[0].clone()); }
    for (i, t) in chain.iter().enumerate() { println!("line {:<3}{}", i, show(t)); }
    let four = sc(sc(sc(sc(T::Z))));
    let best = shortest(&chain[0], &four, 20);
    row("lines the checker accepts", cap(checker(&chain, false)));
    row("rule uses, first rule each time", (chain.len() - 1).to_string());
    row("rule uses, shortest proof by search", best.unwrap().to_string());
    row("2 x 2 by machine arithmetic", (2 * 2).to_string());
    println!("-- what breaks --");
    let mut bad = chain.clone(); bad.push(sc(four.clone()));
    row("2 x 2 = 5, checked with the true rules", cap(checker(&bad, false)));
    row("2 x 2 = 5, checked with 0 = S0 added", cap(checker(&bad, true)));
    let r = shortest(&chain[0], &four, best.unwrap() - 1);
    row(&format!("search capped at {} rule uses", best.unwrap() - 1), r.map_or("none up to the cap".into(), |v| v.to_string()));
    let h = format!("~P({})", num(small(&godel("~P(x)"))));
    let pointed = value(&h.as_bytes()[3..h.len() - 1], 0).0;   // the number H's numeral stands for
    row("H = ~P(x) filled without D points at", pointed.to_string());
    row("digits in the code of H itself", decimal(&godel(&h)).len().to_string());
    let fits: Vec<usize> = (1..=400).filter(|&l| num_bits(&bits_of(&godel(&"0".repeat(l)))).len() <= l).collect();
    row("sentence holding its own numeral, 1 to 400", if fits.is_empty() { "none up to 400".into() } else { format!("{:?}", fits) });
    row("numeral of the smallest 8-symbol code", num_bits(&bits_of(&godel("00000000"))).len().to_string());

    assert!(decode(small(&godel(one))) == one && small(&godel(one)) == 0x213215221);
    assert!(value(num(gx).as_bytes(), 0).0 == gx && gx == 0x8A6B6977);   // numeral and code agree
    assert!(godel(&diag(x)) == diag_arith(gx));                          // road A against road B
    assert!(inner == gx && diag_arith(inner) == gg);                     // road C: G names itself
    assert!(checker(&chain, false) && value(show(chain.last().unwrap()).as_bytes(), 0).0 == 2 * 2 && *chain.last().unwrap() == four);
    assert!(best.unwrap() <= chain.len() - 1 && r.is_none());
    assert!(!checker(&bad, false) && checker(&bad, true));
    assert!(decode(pointed) == "~P(x)");                                // H points at the template, not at itself
    let (lo_h, hi_h) = ([vec![code(h.as_bytes()[0])], vec![0u8; h.len() - 1]].concat(), vec![15u8; h.len()]);
    assert!(decimal(&godel(&h)).len() == decimal(&lo_h).len() && decimal(&lo_h).len() == decimal(&hi_h).len()); // from H's length
    assert!(fits.is_empty());
    println!("ALL CHECKS PASS");
}
fn cap(b: bool) -> String { if b { "True".into() } else { "False".into() } }
