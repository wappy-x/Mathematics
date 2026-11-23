// Polynomial reductions and NP-completeness -- the same check as the Python, in Rust.  No crates.
// A school timetable becomes a clash graph (the map f) and a graph becomes a timetable (the map g).
// Each map is run, its cost is counted, and on every small instance it sends yes to yes and no to no:
// a search over timetables and a search over colourings give the same answers.
use std::collections::BTreeSet;
type Lines = Vec<(usize, usize)>;
const EXAMS: [&str; 7] = ["Art", "Biology", "Chemistry", "Drama", "English", "French", "Geography"];

fn f(students: &[Vec<usize>]) -> (usize, Lines) {   // one line per pair of exams one student sits
    let (mut pairs, mut lines) = (0, BTreeSet::new());
    for s in students {
        for i in 0..s.len() {
            for j in i + 1..s.len() {
                pairs += 1;
                lines.insert((s[i].min(s[j]), s[i].max(s[j])));
            }
        }
    }
    (pairs, lines.into_iter().collect())
}

fn g(lines: &Lines) -> Vec<Vec<usize>> {             // one student per line, sitting its two ends
    lines.iter().map(|&(a, b)| vec![a, b]).collect()
}

fn assignment(mut code: usize, m: usize, k: usize) -> Vec<usize> {
    let mut out = Vec::new();
    for _ in 0..m { out.push(code % k); code /= k }
    out
}

fn fits(a: &[usize], s: &[usize]) -> bool {          // a student's exams all in different sessions
    s.iter().map(|&e| a[e]).collect::<BTreeSet<_>>().len() == s.len()
}

fn count_tt(students: &[Vec<usize>], m: usize, k: usize) -> usize {   // road one: by students
    (0..k.pow(m as u32)).filter(|&c| { let a = assignment(c, m, k); students.iter().all(|s| fits(&a, s)) }).count()
}

fn count_col(lines: &Lines, m: usize, k: usize) -> usize {           // road two: by lines
    (0..k.pow(m as u32)).filter(|&c| { let a = assignment(c, m, k); lines.iter().all(|&(u, v)| a[u] != a[v]) }).count()
}

fn fewest(lines: &Lines, m: usize) -> usize {
    (1..=m).find(|&k| count_col(lines, m, k) > 0).unwrap()
}

fn two_sessions_bfs(lines: &Lines, m: usize) -> (bool, usize) {
    let adj: Vec<Vec<usize>> = (0..m).map(|u| (0..m).filter(|&v| lines.contains(&(u, v)) || lines.contains(&(v, u))).collect()).collect();
    let (mut side, mut steps, mut ok) = (vec![-1i32; m], 0, true);
    for start in 0..m {
        if side[start] >= 0 { continue }
        side[start] = 0;
        let mut queue = std::collections::VecDeque::from([start]);
        while let Some(u) = queue.pop_front() {
            steps += 1;
            for &v in &adj[u] {
                steps += 1;
                if side[v] < 0 { side[v] = 1 - side[u]; queue.push_back(v) } else if side[v] == side[u] { ok = false }
            }
        }
    }
    (ok, steps)
}

fn splitmix(state: u64) -> (u64, u64) {
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn random_school(mut state: u64, m: usize, students: usize, size: usize) -> (u64, Vec<Vec<usize>>) {
    let mut school = Vec::new();
    for _ in 0..students {
        let mut s: Vec<usize> = Vec::new();
        while s.len() < size {
            let (st, z) = splitmix(state);
            state = st;
            let e = (z % m as u64) as usize;
            if !s.contains(&e) { s.push(e) }
        }
        school.push(s);
    }
    (state, school)
}

fn sci(x: u128) -> String {                          // 3 significant figures, rounded with integers only
    let d = x.to_string();
    let t = (d[..4].parse::<u32>().unwrap() + 5) / 10;
    format!("{}.{:02}e{}", t / 100, t % 100, d.len() - 1)
}

fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }

fn main() {
    let school: Vec<Vec<usize>> = vec![vec![0, 1, 2], vec![2, 3], vec![3, 4], vec![4, 5], vec![5, 6], vec![6, 0], vec![1, 4], vec![3, 4]];
    let m = EXAMS.len();
    let (pairs, lines) = f(&school);
    let ini = |e: usize| EXAMS[e].chars().next().unwrap();
    println!("school: {} exams, {} students, {} pairs written, {} clash lines", m, school.len(), pairs, lines.len());
    println!("clash lines: {}", lines.iter().map(|&(u, v)| format!("{}{}", ini(u), ini(v))).collect::<Vec<_>>().join(" "));
    let written = school.iter().map(|s| s.iter().map(|&e| ini(e)).collect::<String>()).collect::<Vec<_>>().join("/"); // the input
    println!("input written out: {}, n = {} symbols; f writes {} pairs, under n^2 = {}", written, written.len(), pairs, written.len().pow(2));
    let counts: Vec<(usize, usize)> = [2, 3].iter().map(|&k| (count_tt(&school, m, k), count_col(&lines, m, k))).collect();
    for (i, k) in [2, 3].iter().enumerate() {
        println!("{} sessions: {} timetables by students, {} colourings of f(school)", k, counts[i].0, counts[i].1);
    }
    let best = (0..3usize.pow(m as u32)).map(|c| assignment(c, m, 3)).find(|a| lines.iter().all(|&(u, v)| a[u] != a[v])).unwrap();
    println!("fewest sessions {}; first timetable: {}", fewest(&lines, m),
             (0..m).map(|e| format!("{} {}", EXAMS[e], best[e] + 1)).collect::<Vec<_>>().join(", "));
    let checks: usize = school.iter().map(|s| s.len() * (s.len() - 1) / 2).sum();
    println!("verifier on that timetable: {} pair checks, accepted: {}", checks, yn(school.iter().all(|s| fits(&best, s))));
    let all_pairs: Lines = (0..4).flat_map(|a| (a + 1..4).map(move |b| (a, b))).collect();
    let graphs: Vec<Lines> = (0..64).map(|mask: usize| (0..6).filter(|i| mask >> i & 1 == 1).map(|i| all_pairs[i]).collect()).collect();
    let agree_g = graphs.iter().map(|gr| [1, 2, 3].iter().filter(|&&k| (count_col(gr, 4, k) > 0) == (count_tt(&g(gr), 4, k) > 0)).count()).sum::<usize>();
    let round_trip = graphs.iter().filter(|gr| f(&g(gr)).1 == **gr).count();
    println!("g on all 64 graphs with 4 dots, k = 1, 2, 3: {} of 192 answers agree; f(g(G)) = G for {} of 64", agree_g, round_trip);
    let (mut state, mut agree_f, mut yes) = (2026u64, 0, 0);
    for _ in 0..200 {
        let (st, sc) = random_school(state, 6, 5, 2 + (state % 2) as usize);
        state = st;
        for k in [2, 3] {
            let direct = count_tt(&sc, 6, k) > 0;
            if direct == (count_col(&f(&sc).1, 6, k) > 0) { agree_f += 1 }
            if direct { yes += 1 }
        }
    }
    println!("f on 200 random schools, k = 2 and 3: {} of 400 answers agree; {} yes, {} no", agree_f, yes, 400 - yes);
    let mut cost = Vec::new();
    for size in [10usize, 20, 40, 80] {
        let (_, sc) = random_school(7, size, 2 * size, 5);
        let (p, ls) = f(&sc);
        cost.push(p);
        println!("cost at {} exams, {} students of 5 exams: f writes {} pairs, {} lines; search tries 3^{} = {}",
                 size, 2 * size, p, ls.len(), size, sci(3u128.pow(size as u32)));
    }
    let apex = graphs.iter().filter(|gr| {
        let mut big = (*gr).clone();
        for v in 0..4 { big.push((v, 4)) }
        (count_col(gr, 4, 2) > 0) == (count_col(&big, 5, 3) > 0)
    }).count();
    println!("mistake 1, wrong direction: 2 sessions -> 3 sessions plus one all-clash exam agrees on {} of 64 graphs", apex);
    let (ok_full, st_full) = two_sessions_bfs(&lines, m);
    let dropped = f(&school[1..]).1;
    let (ok_drop, st_drop) = two_sessions_bfs(&dropped, m);
    println!("  yet 2 sessions is easy: alternating search on the school {} in {} steps, without student 1 {} in {} steps",
             yn(ok_full), st_full, yn(ok_drop), st_drop);
    println!("mistake 2, a 'reduction' that searches first: {} assignments at {} exams, {} at 40", 3usize.pow(m as u32), m, sci(3u128.pow(40)));
    println!("mistake 3, dropping student 1 is no reduction: fewest sessions {}, true answer {}", fewest(&dropped, m), fewest(&lines, m));
    for (k, r) in [(4usize, 2usize), (9, 3)] {                              // k: the grid's side, also its colours
        let cells: Vec<(usize, usize)> = (0..k).flat_map(|i| (0..k).map(move |j| (i, j))).collect();
        let mut e = 0;
        for x in 0..k * k {
            for y in x + 1..k * k {
                let (a, b) = (cells[x], cells[y]);
                if a.0 == b.0 || a.1 == b.1 || (a.0 / r == b.0 / r && a.1 / r == b.1 / r) { e += 1 }
            }
        }
        println!("sudoku {} by {} as colouring: {} cells, {} lines, {} colours; plus {} digit dots joined in {} lines",
                 k, k, k * k, e, k, k, k * (k - 1) / 2);
        assert!(e == k * k * (3 * k - 2 * r - 1) / 2);                    // count against a formula
    }
    assert!(counts[0] == (0, 0) && counts[1].0 == counts[1].1 && counts[1].0 > 0);   // two searches, one answer
    assert!(agree_g == 192 && round_trip == 64 && agree_f == 400);       // yes to yes, no to no
    assert!(apex == 64 && ok_full == (counts[0].0 > 0) && ok_drop == (fewest(&dropped, m) == 2));
    assert!(cost == vec![200, 400, 800, 1600] && pairs == checks && pairs <= written.len().pow(2));
    println!("ALL CHECKS PASS");
}
