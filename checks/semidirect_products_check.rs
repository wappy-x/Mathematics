// Semidirect products -- the same check as the Python, in Rust.  No crates.
// A move is a pair (a, s): a on an n-clock, s on an m-clock.  The twisted
// rule is (a, s)(b, t) = (a + u^s b, s + t), u a multiplier on the n-clock.
// Road two never uses the rule: the pair is the map x -> u^s x + a on the n
// points, and two maps compose point by point, the right-hand map first.
type P = (i64, i64);

fn pw(u: i64, k: i64, n: i64) -> i64 { (0..k).fold(1, |acc, _| acc * u % n) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
struct Grp { n: i64, m: i64, u: i64, bad: bool, all: Vec<P> }
impl Grp {
    fn new(n: i64, m: i64, u: i64, bad: bool) -> Grp {     // bad: the mistake, twisting by t
        Grp { n, m, u, bad, all: (0..m).flat_map(|s| (0..n).map(move |a| (a, s))).collect() }
    }
    fn f(&self, x: P, y: P) -> P {
        let k = if self.bad { y.1 } else { x.1 };
        ((x.0 + pw(self.u, k, self.n) * y.0) % self.n, (x.1 + y.1) % self.m)
    }
    fn pts(&self, x: P) -> Vec<i64> { (0..self.n).map(|p| (pw(self.u, x.1, self.n) * p + x.0) % self.n).collect() }
    fn agree(&self) -> bool {
        let mut maps: Vec<Vec<i64>> = self.all.iter().map(|&x| self.pts(x)).collect();
        let ok = self.all.iter().all(|&x| self.all.iter().all(|&y| self.pts(self.f(x, y))
            == self.pts(y).iter().map(|&q| self.pts(x)[q as usize]).collect::<Vec<i64>>()));
        maps.sort(); maps.dedup();
        ok && maps.len() == self.all.len()
    }
    fn broken(&self) -> usize {
        let g = &self.all;
        g.iter().map(|&x| g.iter().map(|&y| g.iter().filter(|&&z|
            self.f(self.f(x, y), z) != self.f(x, self.f(y, z))).count()).sum::<usize>()).sum()
    }
    fn commute(&self) -> usize {
        self.all.iter().map(|&x| self.all.iter().filter(|&&y| self.f(x, y) == self.f(y, x)).count()).sum()
    }
    fn order(&self, x: P) -> i64 { let (mut k, mut y) = (1, x); while y != (0, 0) { k += 1; y = self.f(y, x) } k }
    fn inv(&self, g: P) -> P { *self.all.iter().find(|&&y| self.f(g, y) == (0, 0)).unwrap() }
}

fn main() {
    let t = Grp::new(4, 2, 3, false);
    let (tok, tbroken, tcomm) = (t.agree(), t.broken(), t.commute());
    let (flip, quarter, n): (P, P, Vec<P>) = ((0, 1), (1, 0), (0..4).map(|a| (a, 0)).collect());
    let (stay, undo) = (t.all.iter().all(|&g| n.iter().all(|&x| n.contains(&t.f(t.f(g, x), t.inv(g))))), t.inv(quarter));
    println!("tile, u = 3: rule matches the corner maps on 64 products: {}", yn(tok));
    println!("flip, quarter turn, flip = {:?}; undo of a quarter turn = {:?}", t.f(t.f(flip, quarter), flip), undo);
    println!("turn then flip = {:?}; flip then turn = {:?}", t.f(flip, quarter), t.f(quarter, flip));
    println!("commuting pairs: tile {} of 64, untwisted (u = 1) {} of 64", tcomm, Grp::new(4, 2, 1, false).commute());
    println!("turns keep their shape under all 32 conjugations: {}", yn(stay));
    for (name, k) in [("flips {r0, f}", vec![(0, 0), flip]), ("half turn {r0, r2}", vec![(0, 0), (2, 0)])] {
        let mut prods: Vec<P> = n.iter().flat_map(|&x| k.iter().map(move |&y| (x, y))).map(|(x, y)| t.f(x, y)).collect();
        prods.sort(); prods.dedup();
        println!("turns with {}: share {}, products give {}", name, n.iter().filter(|x| k.contains(x)).count(), prods.len());
    }
    let s = Grp::new(7, 3, 2, false);
    let (sok, sbroken, scomm) = (s.agree(), s.broken(), s.commute());
    let ords: Vec<i64> = s.all.iter().map(|&x| s.order(x)).collect();
    let cnt = |o: i64| ords.iter().filter(|&&v| v == o).count();
    let (n7, n3) = (cnt(7) / 6, cnt(3) / 2);
    println!("order 21, u = 2, 2^3 = 8 = {} mod 7: matches maps {}, broken triples {}", 8 % 7, yn(sok), sbroken);
    println!("orders: 1 x{}, 3 x{}, 7 x{}; commuting pairs {} of 441", cnt(1), cnt(3), cnt(7), scomm);
    println!("subgroups of order 7: {}; of order 3: {}; (1, 1) twice {:?}, thrice {:?}", n7, n3, s.f((1, 1), (1, 1)), s.f(s.f((1, 1), (1, 1)), (1, 1)));
    let z = Grp::new(7, 3, 1, false);
    let longest = z.all.iter().map(|&x| z.order(x)).max().unwrap();
    let (ff, re) = (Grp::new(7, 3, 4, false), |x: P| (x.0, 2 * x.1 % 3));
    let same = s.all.iter().all(|&x| s.all.iter().all(|&y| re(s.f(x, y)) == ff.f(re(x), re(y))));
    println!("u = 1: longest order {}, commuting pairs {}; u = 4 is u = 2 relabelled: {}", longest, z.commute(), yn(same));
    for (p, q) in [(7i64, 3i64), (5, 3), (3, 2)] {
        let us: Vec<i64> = (1..p).filter(|&u| pw(u, q, p) == 1).collect();
        println!("order {}: u with u^{} = 1 mod {}: {:?}; {} divides {}: {}", p * q, q, p, us, q, p - 1, yn((p - 1) % q == 0));
        assert!((us.len() > 1) == ((p - 1) % q == 0) && (us.len() == 1 || us.len() as i64 == q));
    }
    let (bbroken, wbroken) = (Grp::new(7, 3, 3, false).broken(), Grp::new(4, 2, 3, true).broken());
    println!("mistake, u = 3 on the 7-clock, 3^3 = {} mod 7: broken triples {} of 9261", 27 % 7, bbroken);
    println!("mistake, twisting by the right-hand flip: broken triples {} of 512", wbroken);
    assert!(tok && sok && tbroken == 0 && sbroken == 0);          // rule = composed maps
    assert!(t.f(t.f(flip, quarter), flip) == undo && stay && tcomm < 64);
    assert!(n7 == 1 && n3 % 3 == 1 && 7 % n3 == 0 && longest == 21 && 21 > *ords.iter().max().unwrap());
    assert!(same && bbroken > 0 && wbroken > 0);
    println!("ALL CHECKS PASS");
}
