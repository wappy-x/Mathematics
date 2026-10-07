// Normal subgroups and quotient groups -- the same check as the Python, in Rust.  No crates.
// Two collapses: the integers by the multiples of 12, giving the clock, and the 8 ways a
// square tile sits down, by its 4 turns.  A move is (r, f): r quarter turns, f = 1 if flipped.
type M = (i32, i32);
// mul does b first, then a, as with functions; inv is the move that undoes a.
fn mul(a: M, b: M) -> M { ((a.0 + if a.1 == 0 { b.0 } else { -b.0 }).rem_euclid(4), a.1 ^ b.1) }
fn inv(a: M) -> M { ((if a.1 == 0 { -a.0 } else { a.0 }).rem_euclid(4), a.1) }
fn uniq<T: Ord>(mut v: Vec<T>) -> Vec<T> { v.sort(); v.dedup(); v }
fn pile_of(g: M, h: &[M]) -> Vec<M> { uniq(h.iter().map(|&x| mul(g, x)).collect()) }
// the tile again, as a map of the 4 corners; back reads a flip off such a map
fn act(a: M) -> Vec<usize> { (0..4).map(|i| (a.0 + if a.1 == 0 { i } else { -i })
    .rem_euclid(4) as usize).collect() }
fn back(p: &[usize]) -> i32 { if (p[1] as i32 - p[0] as i32).rem_euclid(4) == 3 { 1 } else { 0 } }
// road one to the clock's piles: no remainder operator anywhere in it
fn multiple_of_12(d: i32) -> bool { let mut d = d.abs(); while d >= 12 { d -= 12; } d == 0 }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn sorted_sizes(s: &[Vec<M>], keep: &[M], all: bool) -> Vec<usize> {
    let mut c: Vec<usize> = s.iter().filter(|p| all || p.iter().all(|m| keep.contains(m)))
        .map(|p| p.len()).collect();
    c.sort(); c
}
fn main() {
    let w: Vec<i32> = (-24..36).collect();
    let g: Vec<M> = (0..4).flat_map(|r| (0..2).map(move |f| (r, f))).collect();
    let by_subtraction = uniq(w.iter().map(|&a| w.iter().cloned()
        .filter(|&b| multiple_of_12(a - b)).collect::<Vec<i32>>()).collect::<Vec<_>>());
    let by_remainder = uniq(w.iter().map(|&a| w.iter().cloned()
        .filter(|&b| b.rem_euclid(12) == a.rem_euclid(12)).collect::<Vec<i32>>()).collect::<Vec<_>>());
    println!("integers -24 to 35 collapsed by the multiples of 12: {} piles by \
subtraction, {} by remainder", by_subtraction.len(), by_remainder.len());
    println!("15 and -9 read {} and {} on the face; 7 plus 8 is pile {}",
             15 % 12, (-9i32).rem_euclid(12), (7 + 8) % 12);
    let (turns, flips): (Vec<M>, Vec<M>) = ((0..4).map(|r| (r, 0)).collect(), vec![(0, 0), (0, 1)]);
    let turns_normal = g.iter().all(|&a| turns.iter().all(|&h| turns.contains(&mul(mul(a, h), inv(a)))));
    let geometry = g.iter().all(|&a| g.iter().all(|&b| act(mul(a, b))
        == act(b).iter().map(|&i| act(a)[i]).collect::<Vec<usize>>()));
    let parity = g.iter().all(|&a| g.iter().all(|&b|
        back(&act(mul(a, b))) == (back(&act(a)) + back(&act(b))) % 2));
    let turn_piles = uniq(g.iter().map(|&a| pile_of(a, &turns)).collect::<Vec<_>>());
    let seats = uniq(g.iter().map(|&a| uniq(g.iter().map(|&x| mul(mul(x, a), inv(x)))
        .collect::<Vec<M>>())).collect::<Vec<_>>());
    let (classes, inside) = (sorted_sizes(&seats, &turns, true), sorted_sizes(&seats, &turns, false));
    println!("tile moves {}, turns {}: all {} conjugates of a turn are turns {}, piles {}",
             g.len(), turns.len(), g.len() * turns.len(), tf(turns_normal), turn_piles.len());
    println!("the same 8 moves as corner maps: all {} products agree {}; a flip is the \
corners running backwards, and flips add mod 2 {}: the 2-clock", g.len() * g.len(), tf(geometry), tf(parity));
    println!("classes of look-alike moves: {}, by size {:?}; the turns are whole classes \
{:?} adding to {}", classes.len(), classes, inside, inside.iter().sum::<usize>());
    let (quarter, flip, half) = ((1, 0), (0, 1), (2, 0));
    let (conj, same) = (mul(mul(quarter, flip), inv(quarter)), mul(mul(half, flip), inv(half)));
    let flip_piles = uniq(g.iter().map(|&a| pile_of(a, &flips)).collect::<Vec<_>>());
    let (one, two) = (pile_of(quarter, &flips), pile_of(mul(flip, quarter), &flips));
    println!("flip subgroup {:?}, piles {}: a quarter turn carries {:?} to {:?}, outside \
it; the half turn carries it to {:?}, inside", flips, flip_piles.len(), flip, conj, same);
    println!("one pile, two names, each times a quarter turn: {:?} and {:?}", one, two);
    let z24: Vec<i32> = (0..24).collect();
    let ker: Vec<i32> = z24.iter().cloned().filter(|x| x % 12 == 0).collect();
    let image = uniq(z24.iter().map(|x| x % 12).collect::<Vec<i32>>());
    let kp = |x: i32| -> Vec<i32> { uniq(ker.iter().map(|k| (x + k).rem_euclid(24)).collect()) };
    let piles = uniq(z24.iter().map(|&x| kp(x)).collect::<Vec<_>>());
    let mut vals: Vec<i32> = piles.iter().map(|p| p[0] % 12).collect(); vals.sort();
    let onto = vals == image;
    let keeps = z24.iter().all(|&x| z24.iter().all(|&y| kp(x + y)[0] % 12 == (x % 12 + y % 12) % 12));
    println!("24-clock under x -> x mod 12: 13 reads {}; kernel {:?} of {}; piles {}; {} / {} = {}; image {}",
             13 % 12, ker, ker.len(), piles.len(), z24.len(), ker.len(), z24.len() / ker.len(), image.len());
    println!("pile to value is one-to-one and onto the image {}, and keeps addition on all \
{} pairs {}", tf(onto), z24.len() * z24.len(), tf(keeps));
    let whole = uniq(z24.iter().map(|&x| uniq(z24.iter().map(|k| (x + k).rem_euclid(24))
        .collect::<Vec<i32>>())).collect::<Vec<_>>());
    println!("the four mistakes: {} answers for one product, {} members counted instead of \
{} piles, a flip subgroup passing a half-turn-only test ({}), and {} pile against an image \
of {}", uniq(vec![one.clone(), two.clone()]).len(), g.len(), turn_piles.len(),
             tf(flips.contains(&same)), whole.len(), image.len());
    assert!(by_subtraction == by_remainder && by_subtraction.len() == 12);
    assert!(turns_normal && geometry && parity && turn_piles.len() == 2 && inside == vec![1, 1, 2]);
    assert!(conj == (2, 1) && !flips.contains(&conj) && same == flip && one != two);
    assert!(piles.len() == z24.len() / ker.len() && z24.len() / ker.len() == image.len()
            && image.len() == 12 && onto && keeps);
    println!("ALL CHECKS PASS");
}
