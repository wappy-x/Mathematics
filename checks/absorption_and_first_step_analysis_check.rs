// Absorption and first-step analysis -- the same check as the Python, in Rust.
// std only.  A 10-square snakes-and-ladders board, one six-sided die, ladder
// 3 -> 7, snake 8 -> 2, reaching or passing square 10 finishes.  Road 1 solves
// the first-step equations in exact fractions (i128, overflow checked), road 2
// pushes the chance mass forward, road 3 is a seeded SplitMix64 simulation.
use std::fmt;
const L: usize = 10;

#[derive(Clone, Copy, PartialEq)]
struct Fr { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d).max(1) * d.signum(); Fr { n: n / g, d: d / g } }
impl Fr {
    fn add(self, o: Fr) -> Fr { fr(self.n.checked_mul(o.d).unwrap().checked_add(o.n.checked_mul(self.d).unwrap()).unwrap(), self.d.checked_mul(o.d).unwrap()) }
    fn sub(self, o: Fr) -> Fr { self.add(Fr { n: -o.n, d: o.d }) }
    fn mul(self, o: Fr) -> Fr { fr(self.n.checked_mul(o.n).unwrap(), self.d.checked_mul(o.d).unwrap()) }
    fn div(self, o: Fr) -> Fr { fr(self.n.checked_mul(o.d).unwrap(), self.d.checked_mul(o.n).unwrap()) }
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
}
impl fmt::Display for Fr {   // printed as Python prints a Fraction
    fn fmt(&self, w: &mut fmt::Formatter) -> fmt::Result { if self.d == 1 { write!(w, "{}", self.n) } else { write!(w, "{}/{}", self.n, self.d) } } }
fn zero() -> Fr { fr(0, 1) }  fn one() -> Fr { fr(1, 1) }
// resting squares and, for each, its six landings (indexed by square)
fn board(jumps: &[(usize, usize)], pit: Option<usize>) -> (Vec<usize>, Vec<Vec<usize>>) {
    let jump = |s: usize| jumps.iter().find(|j| j.0 == s).map(|j| j.1);
    let land = |s: usize| if s >= L { L } else { jump(s).unwrap_or(s) };
    let rest: Vec<usize> = (0..L).filter(|&s| jump(s).is_none()).collect();
    let moves = (0..L).map(|s| if Some(s) == pit { vec![s; 6] } else { (1..=6).map(|r| land(s + r)).collect() }).collect();
    (rest, moves)
}
fn solve(a: &Vec<Vec<Fr>>, b: &Vec<Fr>) -> Option<Vec<Fr>> {   // Gauss-Jordan, exact
    let n = a.len();
    let mut m: Vec<Vec<Fr>> = a.iter().zip(b).map(|(r, v)| { let mut r = r.clone(); r.push(*v); r }).collect();
    for c in 0..n {
        let p = (c..n).find(|&r| m[r][c].n != 0)?;
        m.swap(c, p);
        for r in 0..n {
            if r != c && m[r][c].n != 0 {
                let (f, row_c) = (m[r][c].div(m[c][c]), m[c].clone());
                for k in 0..=n { m[r][k] = m[r][k].sub(f.mul(row_c[k])); }
            }
        }
    }
    Some((0..n).map(|i| m[i][n].div(m[i][i])).collect())
}
// road 1: t = one + Q t, or with a trap h = r + Q h
fn first_step(jumps: &[(usize, usize)], trap: Option<usize>, pit: Option<usize>, one_: i128) -> (Vec<usize>, Vec<Vec<Fr>>, Option<Vec<Fr>>) {
    let (rest, moves) = board(jumps, pit);
    let live: Vec<usize> = rest.into_iter().filter(|&s| Some(s) != trap).collect();
    let n = live.len();
    let mut a: Vec<Vec<Fr>> = (0..n).map(|i| (0..n).map(|j| fr((i == j) as i128, 1)).collect()).collect();
    let mut b = Vec::new();
    for (i, &s) in live.iter().enumerate() {
        b.push(match trap { None => fr(one_, 1), Some(tr) => fr(moves[s].iter().filter(|&&e| e == tr).count() as i128, 6) });
        for &e in &moves[s] { if let Some(j) = live.iter().position(|&x| x == e) { a[i][j] = a[i][j].sub(fr(1, 6)); } }
    }
    let sol = solve(&a, &b); (live, a, sol)
}
fn t0(jumps: &[(usize, usize)]) -> f64 { first_step(jumps, None, None, 1).2.unwrap()[0].f() }

struct Rng(u64);
impl Rng {
    fn roll(&mut self) -> usize {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        1 + ((((z ^ (z >> 31)) >> 32) * 6) >> 32) as usize
    }
}
fn main() {
    let (seed, games) = (20260929u64, 100000usize);
    let (j, j2): (&[(usize, usize)], &[(usize, usize)]) = (&[(3, 7), (8, 2)], &[(3, 7), (8, 8)]);
    let (rest, moves) = board(j, None);
    let moves2 = board(j2, None).1;
    println!("board: squares 0-9 then finish 10; ladder 3->7, snake 8->2; one die");
    for &s in &rest { println!("from {}: rolls 1-6 land on {:?}", s, moves[s]); }
    let (live, iq, t) = first_step(j, None, None, 1); let t = t.unwrap();
    println!("road 1, exact: expected turns from 0 = {} = {:.6}", t[0], t[0].f());
    println!("t by square {}", live.iter().zip(&t).map(|(s, v)| format!("{}:{:.4}", s, v.f())).collect::<Vec<_>>().join(" "));
    let (hl, a2, h) = first_step(j2, Some(8), None, 1); let h = h.unwrap();
    let hs = |s: usize| h[hl.iter().position(|&x| x == s).unwrap()];
    println!("road 1, exact: chance of meeting the snake before finishing, from 0 = {} = {:.6}", h[0], h[0].f());
    println!("h by square {}", hl.iter().zip(&h).map(|(s, v)| format!("{}:{}", s, v)).collect::<Vec<_>>().join(" "));
    let rf: Vec<Fr> = hl.iter().map(|&s| fr(moves2[s].iter().filter(|&&e| e == L).count() as i128, 6)).collect();
    let fin = solve(&a2, &rf).unwrap()[0];
    println!("two traps from 0: snake {:.6}, finish {:.6}, sum {}", h[0].f(), fin.f(), h[0].add(fin));
    // fundamental matrix N = (I - Q)^-1, column by column
    let n = live.len();
    let cols: Vec<Vec<Fr>> = (0..n).map(|c| solve(&iq, &(0..n).map(|i| fr((i == c) as i128, 1)).collect()).unwrap()).collect();
    let nm: Vec<Vec<Fr>> = (0..n).map(|i| (0..n).map(|c| cols[c][i]).collect()).collect();
    let ok = (0..n).all(|i| (0..n).all(|c| (0..n).fold(zero(), |acc, k| acc.add(nm[i][k].mul(iq[k][c]))) == fr((i == c) as i128, 1)));
    let row_sum = nm[0].iter().fold(zero(), |acc, v| acc.add(*v));
    println!("N row for square 0 (expected visits) {}", live.iter().zip(&nm[0]).map(|(s, v)| format!("{}:{:.4}", s, v.f())).collect::<Vec<_>>().join(" "));
    println!("row sum = {:.6}; N (I - Q) = I exactly: {}", row_sum.f(), if ok { "yes" } else { "no" });
    let cols2: Vec<Vec<Fr>> = (0..hl.len()).map(|c| solve(&a2, &(0..hl.len()).map(|i| fr((i == c) as i128, 1)).collect()).unwrap()).collect();   // N' = (I - Q')^-1, head a trap
    let b: Vec<Fr> = [8, L].iter().map(|&e| (0..hl.len()).fold(zero(), |acc, k| acc.add(cols2[k][0].mul(fr(moves2[hl[k]].iter().filter(|&&x| x == e).count() as i128, 6))))).collect();   // row 0 of B = N' R'
    println!("N' row for square 0, head a trap (expected visits) {}; B = N' R': snake {:.6}, finish {:.6}", hl.iter().enumerate().map(|(j, s)| format!("{}:{:.4}", s, cols2[j][0].f())).collect::<Vec<_>>().join(" "), b[0].f(), b[1].f());
    let slides = (0..n).fold(zero(), |acc, k| acc.add(nm[0][k].mul(fr(moves2[live[k]].iter().filter(|&&e| e == 8).count() as i128, 6))));
    let slides2 = hs(0).div(one().sub(hs(2)));
    println!("expected slides per game: N-row . slide chances = {:.6}; h0/(1-h2) = {:.6}", slides.f(), slides2.f());
    // hand table: carry x = t(2); each square is a + b x, worked from the top down
    let mut ab = vec![(zero(), zero()); L + 1]; ab[9] = (one(), zero()); ab[2] = (zero(), one());
    let step = |ab: &Vec<(Fr, Fr)>, s: usize| moves[s].iter().fold((one(), zero()), |acc, &e| (acc.0.add(ab[e].0.div(fr(6, 1))), acc.1.add(ab[e].1.div(fr(6, 1)))));
    for s in [7, 6, 5, 4] { ab[s] = step(&ab, s); }
    let xe = step(&ab, 2); let x = xe.0.div(one().sub(xe.1));
    for s in [7usize, 6, 5, 4] { println!("hand: t({}) = {:.4} + {:.4} x = {:.4}", s, ab[s].0.f(), ab[s].1.f(), ab[s].0.add(ab[s].1.mul(x)).f()); }
    println!("hand: x = {:.4} + {:.4} x, so x = {} = {:.4}", xe.0.f(), xe.1.f(), x, x.f());
    // road 2: push the chance mass forward one turn at a time
    let (mut dist, mut alive, mut et, mut pt, mut hit) = (vec![0.0f64; L], 1.0f64, 0.0f64, Vec::new(), 0.0f64); dist[0] = 1.0;
    for _ in 1..200 {
        et += alive;
        let (mut new, mut done) = (vec![0.0f64; L], 0.0f64);
        for s in 0..L { if dist[s] > 0.0 { for &e in &moves[s] { if e == L { done += dist[s] / 6.0 } else { new[e] += dist[s] / 6.0 } } } }
        pt.push(done); alive = new.iter().sum(); dist = new;
    }
    let mut d2 = vec![0.0f64; L]; d2[0] = 1.0;
    for _ in 0..200 {
        let mut new = vec![0.0f64; L];
        for s in 0..L { if d2[s] > 0.0 { for &e in &moves2[s] { if e == 8 { hit += d2[s] / 6.0 } else if e != L { new[e] += d2[s] / 6.0 } } } }
        d2 = new;
    }
    println!("road 2, mass pushed 199 turns: expected turns {:.6}; snake-first chance {:.6}; mass left {:.1e}", et, hit, alive);
    println!("chart, percent of games ending on turn 1-10: {}", pt[..10].iter().map(|p| format!("{:.2}", 100.0 * p)).collect::<Vec<_>>().join(" "));
    println!("chart, percent ending after turn 10: {:.2}", 100.0 * pt[10..].iter().sum::<f64>());
    let eta = rest.iter().map(|&s| moves[s].iter().map(|&e1| if e1 == L { 6 } else { moves[e1].iter().filter(|&&e2| e2 == L).count() }).sum::<usize>()).min().unwrap();
    println!("finiteness: worst chance of finishing within 2 turns = {}/36, so E[turns] <= 2*36/{} = {:.1}", eta, eta, 72.0 / eta as f64);
    // road 3: seeded simulation, SplitMix64
    let mut rng = Rng(seed);
    let (mut st, mut st2, mut sh, mut ss, mut ss2) = (0u64, 0u64, 0u64, 0u64, 0u64);
    for _ in 0..games {
        let (mut pos, mut turns, mut met, mut sl) = (0usize, 0u64, 0u64, 0u64);
        while pos < L {
            pos += rng.roll(); turns += 1;
            if pos == 8 { met = 1; sl += 1; }
            if let Some(jj) = j.iter().find(|jj| jj.0 == pos) { pos = jj.1; }
        }
        st += turns; st2 += turns * turns; sh += met; ss += sl; ss2 += sl * sl;
    }
    let g = games as f64; let m = st as f64 / g; let se = ((st2 as f64 / g - m * m) / g).sqrt();
    let ph = sh as f64 / g; let seh = (ph * (1.0 - ph) / g).sqrt(); let ms = ss as f64 / g; let ses = ((ss2 as f64 / g - ms * ms) / g).sqrt();
    println!("road 3, {} games, seed {}: turns {:.4} +/- {:.4}; met snake {:.4} +/- {:.4}", games, seed, m, se, ph, seh);
    println!("road 3, slides per game {:.4} +/- {:.4}", ms, ses);
    // mistakes and variations
    println!("mistake, drop the 1 for the turn played: t(0) = {:.4}", first_step(j, None, None, 0).2.unwrap()[0].f());
    println!("mistake, 10 squares / 3.5 per roll = {:.4}", 10.0 / 3.5);
    let pay: Vec<Vec<usize>> = (0..L).map(|s| match j.iter().find(|jj| jj.0 == s) { Some(jj) => vec![jj.1; 6], None => board(&[], None).1[s].clone() }).collect();
    let a: Vec<Vec<Fr>> = (0..L).map(|i| (0..L).map(|c| fr((i == c) as i128, 1).sub(fr(pay[i].iter().filter(|&&e| e == c).count() as i128, 6))).collect()).collect();
    println!("mistake, a turn spent on each climb or slide: t(0) = {:.4}", solve(&a, &vec![one(); L]).unwrap()[0].f());
    let (pl, pa, psol) = first_step(&[(3, 7)], None, Some(8), 1); let prow = &pa[pl.iter().position(|&s| s == 8).unwrap()];
    println!("broken, a pit on 8 instead of the snake: row 8 of I - Q = {}; unique solution: {}", prow.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "), if psol.is_none() { "none" } else { "yes" });
    let fh = first_step(&[(3, 7)], Some(8), None, 1).2.unwrap();
    println!("broken, pit as a trap: chance of reaching the finish from 0 = {:.6}", one().sub(fh[0]).f());
    println!("try, no snake: t(0) = {:.4}; no ladder: t(0) = {:.4}", t0(&[(3, 7)]), t0(&[(8, 2)]));
    println!("try, snake 8->0: t(0) = {:.4}", t0(&[(3, 7), (8, 0)]));
    println!("try, plain board: t(0) = {:.4}", t0(&[]));
    println!("figure, square centres x = 20 + 32 s: ladder 3->7 at {}->{}, snake 8->2 at {}->{}", 20 + 32 * 3, 20 + 32 * 7, 20 + 32 * 8, 20 + 32 * 2);
    assert!((t[0].f() - et).abs() < 1e-12);            // exact solve against mass flow
    assert!((h[0].f() - hit).abs() < 1e-12);           // the same for the snake chance
    assert!(ok && row_sum == t[0]);                    // N inverts I - Q, and N times ones is t
    assert!((m - t[0].f()).abs() < 4.0 * se);          // simulation within 4 standard errors
    assert!((ph - h[0].f()).abs() < 4.0 * seh && (ms - slides.f()).abs() < 4.0 * ses);
    assert!(h[0].add(fin) == one());                   // two traps: the chances add to 1
    assert!(b[0] == h[0] && b[1] == fin);              // B = N' R' against the two solved systems
    assert!(slides == slides2);                        // two routes to the expected slides
    assert!(psol.is_none());                           // the pit board has no unique answer
    assert!(x == t[2] && [7usize, 6, 5, 4].iter().all(|&s| ab[s].0.add(ab[s].1.mul(x)) == t[live.iter().position(|&l| l == s).unwrap()]));   // hand table = exact solve
    assert!([7usize, 6, 5, 4].iter().all(|&s| ab[s].1 == hs(s)) && xe.1 == hs(2));   // Step 5: multiples of x are h
    assert!((pt.iter().sum::<f64>() - 1.0).abs() < 1e-12 && (pt.iter().enumerate().map(|(k, p)| (k + 1) as f64 * p).sum::<f64>() - et).abs() < 1e-9);   // chart law
    println!("ALL CHECKS PASS");
}
