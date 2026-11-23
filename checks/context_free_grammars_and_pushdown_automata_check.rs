// Grammars and a stack -- the same check as the Python, in Rust.  std only, no crates.
// A song sheet is a string of sections: v verse, c chorus, b bridge.  An arch song climbs to one
// bridge and comes back down in mirror order, and the grammar  S -> vSv | cSc | b  says exactly that.
// Five roads must agree on all 29524 sheets of 0 to 9 sections: a stack machine built by hand, a
// stack machine built from the grammar, the table method (CYK) on Chomsky normal form, the
// grammar's strings listed by derivation, and the plain definition (one b, in the middle, a mirror).
use std::collections::{HashMap, HashSet};

// ---- the stack machine, written out here first (later cards copy this part) ----
// A move is (state, read, pop, push, next).  "" means read nothing or pop nothing; push is written
// top first.  The stack is a string whose last letter is the top; Z is the bottom marker, shown as ⊥.
// run() tries every choice, depth first, and returns the moves of a run that reaches state "yes"
// with the whole sheet read.  Every stack symbol above Z costs at least one more section, so a run
// holding more of them than sections left is dropped: that keeps the search finite.
type Mv = (String, String, String, String, String);
type Path = Vec<(String, String)>;
fn mv(p: &str, a: &str, x: &str, y: &str, r: &str) -> Mv { (p.into(), a.into(), x.into(), y.into(), r.into()) }
fn run(moves: &[Mv], w: &str, start: &str, cap: Option<usize>) -> (Option<Path>, usize) {
    let mut todo: Vec<(String, usize, String, Path)> = vec![(start.into(), 0, "Z".into(), vec![])];
    let (mut seen, mut far) = (HashSet::new(), 0);
    while let Some((q, i, st, path)) = todo.pop() {
        far = far.max(i);
        if q == "yes" && i == w.len() { return (Some(path), far); }
        if !seen.insert((q.clone(), i, st.clone())) { continue; }
        for (p, a, x, y, r) in moves.iter().rev() {
            if *p != q || (!a.is_empty() && w.get(i..i + 1) != Some(a.as_str())) || !st.ends_with(x.as_str()) { continue; }
            let s2 = format!("{}{}", &st[..st.len() - x.len()], y.chars().rev().collect::<String>());
            let i2 = i + a.len();
            if s2.len() as i64 - 1 > (w.len() - i2) as i64 || cap.map_or(false, |c| s2.len() as i64 - 1 > c as i64) { continue; }
            let mut p2 = path.clone(); p2.push((if a.is_empty() { "ε".into() } else { a.clone() }, s2.clone()));
            todo.push((r.clone(), i2, s2, p2));
        }
    }
    (None, far)
}
fn ok(m: &[Mv], w: &str, start: &str, cap: Option<usize>) -> bool { run(m, w, start, cap).0.is_some() }
fn from_grammar(rules: &[(&str, &str)]) -> Vec<Mv> {  // one state: swap the top variable for a rule, or match a letter
    let mut m = vec![mv("start", "", "", "S", "loop")];
    for (a, u) in rules { m.push(mv("loop", "", a, u, "loop")); }
    for t in ["v", "c", "b"] { m.push(mv("loop", t, t, "", "loop")); }
    m.push(mv("loop", "", "Z", "", "yes")); m
}
// ---- road 3: the table method on Chomsky normal form, counting parse trees ----
fn cyk(w: &str, bins: &[(char, char, char)], ones: &[(char, char)]) -> (u64, u64) {
    let (n, mut splits, ch) = (w.len(), 0u64, w.chars().collect::<Vec<char>>());
    let mut t: HashMap<(usize, usize), HashMap<char, u64>> = HashMap::new();
    for i in 0..n { t.insert((i, 1), ones.iter().filter(|o| o.0 == ch[i]).map(|o| (o.1, 1)).collect()); }
    for l in 2..=n {
        for i in 0..=n - l {
            let mut cell: HashMap<char, u64> = HashMap::new();
            for k in 1..l {
                splits += 1;
                for &(a, b, c) in bins {
                    let m = t[&(i, k)].get(&b).unwrap_or(&0) * t[&(i + k, l - k)].get(&c).unwrap_or(&0);
                    if m > 0 { *cell.entry(a).or_insert(0) += m; }
                }
            }
            t.insert((i, l), cell);
        }
    }
    (if n > 0 { *t[&(0, n)].get(&'S').unwrap_or(&0) } else { 0 }, splits)
}
// ---- road 4: list the grammar's strings; road 5: the plain definition ----
fn listed(rules: &[(&str, &str)], nmax: usize) -> HashSet<String> {
    let (mut forms, mut done) = (vec!["S".to_string()], HashSet::new());
    while let Some(f) = forms.pop() {
        match f.find('S') {
            None => { done.insert(f); }
            Some(j) => for (_, u) in rules { let g = format!("{}{}{}", &f[..j], u, &f[j + 1..]); if g.len() <= nmax { forms.push(g); } },
        }
    }; done
}
fn rev(w: &str) -> String { w.chars().rev().collect() }
fn arch(w: &str) -> bool { w.len() % 2 == 1 && w.matches('b').count() == 1 && &w[w.len() / 2..w.len() / 2 + 1] == "b" && w == rev(w) }
fn sheets(alpha: &str, nmax: usize) -> Vec<String> {
    let (mut lvl, mut out) = (vec![String::new()], vec![String::new()]);
    for _ in 0..nmax {
        lvl = lvl.iter().flat_map(|s| alpha.chars().map(move |a| format!("{}{}", s, a))).collect();
        out.extend(lvl.iter().cloned());
    }; out
}
fn queue_ok(w: &str) -> bool {  // the mistake: read the first half back first in, first out
    let (mut line, mut down) = (std::collections::VecDeque::new(), false);
    for a in w.chars() {
        if !down { if a == 'b' { down = true; } else { line.push_back(a); } }
        else if line.pop_front() != Some(a) { return false; }
    }
    down && line.is_empty()
}
fn choose(n: u64, k: u64) -> u64 { (0..k).fold(1, |r, j| r * (n - j) / (j + 1)) }
fn show(st: &str) -> String { if st.is_empty() { "(empty)".into() } else { st.replace('Z', "⊥") } }
fn word(b: bool, y: &str, n: &str) -> String { (if b { y } else { n }).to_string() }
fn arch_of(n: usize) -> String { let h: String = "vc".repeat(n)[..(n - 1) / 2].to_string(); format!("{}b{}", h, rev(&h)) }
fn main() {
    let hand = vec![mv("up", "v", "", "v", "up"), mv("up", "c", "", "c", "up"), mv("up", "b", "", "", "down"),
                    mv("down", "v", "v", "", "down"), mv("down", "c", "c", "", "down"), mv("down", "", "Z", "", "yes")];
    let mut guess: Vec<Mv> = hand.iter().filter(|m| m.1 != "b").cloned().collect();
    guess.push(mv("up", "", "", "", "down"));  // no bridge: guess the middle
    let rules = [("S", "vSv"), ("S", "cSc"), ("S", "b")]; let gram = from_grammar(&rules);
    let cb = [('S', 'V', 'P'), ('S', 'C', 'R'), ('P', 'S', 'V'), ('R', 'S', 'C')];
    let co = [('v', 'V'), ('c', 'C'), ('b', 'S')];
    let (song, bad, deep) = ("vvcbcvv", "vvcbvcv", "vvccbccvv");
    println!("song sheet {}: {} sections, verse verse chorus bridge chorus verse verse", song, song.len());
    let path = run(&hand, song, "up", None).0.unwrap(); println!("hand-built machine, move by move (stack bottom to top):");
    for (k, (a, st)) in path.iter().enumerate() { println!("  move {}  read {}  stack {}", k + 1, a, show(st)); }
    let gpath = run(&gram, song, "start", None).0.unwrap();
    let (mut i, mut forms) = (0, Vec::<String>::new());
    for (a, st) in &gpath {
        if a != "ε" { i += 1; }
        let f = format!("{}{}", &song[..i], rev(st).replace('Z', ""));
        if forms.last() != Some(&f) { forms.push(f); }
    }
    let (trees, splits7) = cyk(song, &cb, &co);
    println!("grammar-built machine: {} moves; derivation {}", gpath.len(), forms.join(" ⇒ "));
    println!("parse trees for {}: {}; table method used {} splits", song, trees, splits7);
    let bad_far = run(&hand, bad, "up", None).1;
    println!("bad sheet {}: hand-built {}, grammar-built {}; stuck after {} sections", bad,
             word(ok(&hand, bad, "up", None), "accepts", "rejects"), word(ok(&gram, bad, "start", None), "accepts", "rejects"), bad_far);
    let (all, list) = (sheets("vcb", 9), listed(&rules, 9));
    let (mut agree, mut yes) = (0, Vec::<String>::new());
    for w in &all {
        let v = [ok(&hand, w, "up", None), ok(&gram, w, "start", None), cyk(w, &cb, &co).0 > 0, list.contains(w), arch(w)];
        if v.iter().all(|&b| b == v[0]) { agree += 1; }
        if v[4] { yes.push(w.clone()); }
    }
    let bylen: Vec<usize> = [1, 3, 5, 7, 9].iter().map(|&n| yes.iter().filter(|w| w.len() == n).count()).collect();
    let most = yes.iter().map(|w| cyk(w, &cb, &co).0).max().unwrap();
    println!("all sheets of 0 to 9 sections: {}; all five roads agree on {}", all.len(), agree);
    println!("arch songs of 1 3 5 7 9 sections: {}; total {}; most parse trees {}",
             bylen.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" "), yes.len(), most);
    let big: Vec<(usize, usize, u64)> = [7, 15, 101].iter()
        .map(|&n| (n, run(&hand, &arch_of(n), "up", None).0.unwrap().len(), cyk(&arch_of(n), &cb, &co).1)).collect();
    println!("cost at 7, 15, 101 sections: stack moves {}; table splits {}",
             big.iter().map(|b| b.1.to_string()).collect::<Vec<_>>().join(", "), big.iter().map(|b| b.2.to_string()).collect::<Vec<_>>().join(", "));
    println!("what breaks:"); let qa: Vec<&String> = all.iter().filter(|w| queue_ok(w)).collect(); let qarch = qa.iter().filter(|w| arch(w)).count();
    println!("  queue for stack: vvcbvvc {}, {} {}; accepts {} sheets, {} of them arch", word(queue_ok("vvcbvvc"), "accepted", "rejected"),
             song, word(queue_ok(song), "accepted", "rejected"), qa.len(), qarch);
    let (hold3, miss3) = (sheets("vc", 3).len(), yes.iter().filter(|w| !ok(&hand, w, "up", Some(3))).count());
    println!("  fixed memory, stack capped at 3 ({} contents): {} {}; misses {} of {} arch songs", hold3, deep,
             word(ok(&hand, deep, "up", Some(3)), "accepted", "rejected"), miss3, yes.len());
    let even = sheets("vc", 8); let ga: Vec<&String> = even.iter().filter(|w| ok(&guess, w, "up", None)).collect();
    let mirrors = ga.iter().filter(|w| w.len() % 2 == 0 && **w == &rev(w)).count();
    println!("  no bridge: vccv hand-built {}, guessing machine {}; of {} bridge-less sheets it accepts {}, even mirrors {}",
             word(ok(&hand, "vccv", "up", None), "accepts", "rejects"), word(ok(&guess, "vccv", "up", None), "accepts", "rejects"),
             even.len(), ga.len(), mirrors);
    let (ab, ao) = ([('S', 'S', 'S')], [('v', 'S'), ('c', 'S'), ('b', 'S')]);
    let (amb7, amb9) = (cyk(song, &ab, &ao).0, cyk(deep, &ab, &ao).0);
    println!("  grammar S -> SS | v | c | b: {} has {} parse trees, closed form {}", song, amb7, choose(12, 6) / 7);
    println!("try changing:"); let l11 = listed(&rules, 11);
    let (m4a, m4b) = (yes.iter().filter(|w| !ok(&hand, w, "up", Some(4))).count(), l11.iter().filter(|w| !ok(&hand, w, "up", Some(4))).count());
    println!("  cap 4: misses {} of {} up to 9 sections, {} of {} up to 11", m4a, yes.len(), m4b, l11.len());
    let r2 = [("S", "vSv"), ("S", "cSc"), ("S", "b"), ("S", "vSc"), ("S", "cSv")];
    let (l2, g2) = (listed(&r2, 9), from_grammar(&r2));
    let (g2ok, h2ok) = (l2.iter().filter(|w| ok(&g2, w, "start", None)).count(), l2.iter().filter(|w| ok(&hand, w, "up", None)).count());
    println!("  add S -> vSc | cSv: {} songs up to 9 sections; grammar-built accepts {}, hand-built {}", l2.len(), g2ok, h2ok);
    println!("  ambiguous grammar on {}: {} parse trees, closed form {}", deep, amb9, choose(16, 8) / 9);
    let l15 = listed(&rules, 15).len(); println!("  arch songs up to 15 sections: {}", l15);
    let st3: Vec<&str> = path[..3].iter().map(|p| p.1.as_str()).collect();
    assert!(path.last().unwrap() == &("ε".to_string(), String::new()) && st3 == ["Zv", "Zvv", "Zvvc"] && path.len() == song.len() + 1);
    assert!(forms == ["S", "vSv", "vvSvv", "vvcScvv", song] && gpath.len() == 13 && trees == 1);
    assert!(!ok(&hand, bad, "up", None) && !ok(&gram, bad, "start", None) && bad_far == 4);
    assert!(agree == all.len() && agree == 29524 && bylen == [1, 2, 4, 8, 16] && most == 1);
    assert!(big.iter().all(|&(n, m, s)| m == n + 1 && s as usize == (n * n * n - n) / 6) && big[2].2 == 171700);
    assert!(qa.len() == 31 && qarch == 13 && !queue_ok(song));
    assert!(miss3 == 16 && !ok(&hand, deep, "up", Some(3)) && ok(&hand, deep, "up", None) && hold3 == 15);
    assert!(ga.len() == 31 && mirrors == 31 && !ok(&hand, "vccv", "up", None));
    assert!(amb7 == 132 && amb7 == choose(12, 6) / 7 && amb9 == 1430 && amb9 == choose(16, 8) / 9);
    assert!(l2.len() == 341 && g2ok == 341 && l15 == 255);
    println!("ALL CHECKS PASS");
}
