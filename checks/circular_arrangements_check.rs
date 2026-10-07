// Round tables and bracelets -- the same check as the Python, in Rust.  No
// crates.  Eight guests sit round one table; six different beads hang on one
// bracelet.  Every count is reached twice: once from the factorial, once by
// listing every order in a row and sorting that whole list into classes.
use std::collections::{BTreeMap, BTreeSet};
type Seq = Vec<u8>;

fn fact(n: u64) -> u64 {                        // n!, written out rather than imported
    let mut out = 1;
    for k in 2..=n { out *= k }
    out
}

fn orders(items: &[u8]) -> Vec<Seq> {           // every order of the items in a row
    if items.len() <= 1 { return vec![items.to_vec()] }
    let mut out = Vec::new();
    for i in 0..items.len() {
        let mut rest = items.to_vec();
        let head = rest.remove(i);
        for tail in orders(&rest) { let mut one = vec![head]; one.extend(tail); out.push(one) }
    }
    out
}

fn distinct(items: &[u8]) -> Vec<Seq> {         // repeated items make the same order twice
    orders(items).into_iter().collect::<BTreeSet<Seq>>().into_iter().collect()
}
fn turns(s: &[u8]) -> Vec<Seq> {                // the rotations of one order
    (0..s.len()).map(|k| { let mut v = s[k..].to_vec(); v.extend_from_slice(&s[..k]); v }).collect()
}

fn tag(s: &[u8], flip: bool) -> Seq {           // one name shared by a whole class
    let mut family = turns(s);
    if flip { let mut back = s.to_vec(); back.reverse(); family.extend(turns(&back)) }
    family.into_iter().min().unwrap()
}

fn classes(seqs: &[Seq], flip: bool) -> BTreeMap<Seq, usize> {   // class name -> orders it holds
    let mut out = BTreeMap::new();
    for s in seqs { *out.entry(tag(s, flip)).or_insert(0) += 1 }
    out
}

fn size(cls: &BTreeMap<Seq, usize>) -> usize {  // the size every class shares, 0 if they differ
    let found: BTreeSet<usize> = cls.values().copied().collect();
    if found.len() == 1 { *found.iter().next().unwrap() } else { 0 }
}
fn mirrors(cls: &BTreeMap<Seq, usize>) -> usize {   // classes unchanged by turning the ring over
    cls.keys().filter(|t| { let mut b = t.to_vec(); b.reverse(); tag(&b, false) == **t }).count()
}

fn main() {
    let (table, four) = (distinct(&[0, 1, 2, 3, 4, 5, 6, 7]), distinct(&[0, 1, 2, 3]));
    let (beads, three) = (distinct(&[0, 1, 2, 3, 4, 5]), distinct(&[0, 1, 2]));
    let mixed = distinct(&[0, 0, 1, 1, 2, 3]);  // beads R R B B G Y
    let (seatings, small) = (classes(&table, false), classes(&four, false));
    let (necks, bracs) = (classes(&beads, false), classes(&beads, true));
    let (mneck, mbrac) = (classes(&mixed, false), classes(&mixed, true));
    let fixed = table.iter().filter(|s| s[0] == 0).count();   // guest 0 nailed to one chair
    println!("8 guests in 8 numbered chairs: 8! = {} orders in a row", table.len());
    println!("one seating turns up once per rotation: classes of {}", size(&seatings));
    println!("{} / {} = {} seatings round the table, and 7! = {}", table.len(), size(&seatings), seatings.len(), fact(7));
    println!("nailing one guest to one chair and ordering the other 7: {}", fixed);
    println!("treating clockwise and anticlockwise as one would give {}, not {}", seatings.len() / 2, seatings.len());
    println!("4 guests, the picture: 4! = {} orders, {} / 4 = {} seatings", four.len(), four.len(), small.len());
    println!("6 different beads: 6! = {} orders, {} / 6 = {} necklaces", beads.len(), beads.len(), necks.len());
    println!("turning the ring over pairs them off: {} / 2 = {} bracelets, and 5!/2 = {}", necks.len(), bracs.len(), fact(5) / 2);
    println!("brute force, orders sorted into turn-or-flip classes: {} classes of {}", bracs.len(), size(&bracs));
    println!("necklaces of 6 different beads unchanged by the flip: {}", mirrors(&necks));
    println!("3 different beads: {} necklaces, {} bracelet", classes(&three, false).len(), classes(&three, true).len());
    println!("beads R R B B G Y: {} different orders, {} necklaces", mixed.len(), mneck.len());
    println!("halving those {} gives {}, but brute force finds {} bracelets", mneck.len(), mneck.len() / 2, mbrac.len());
    println!("{} necklaces are unchanged by the flip: ({} + {}) / 2 = {}", mirrors(&mneck), mneck.len(), mirrors(&mneck), mbrac.len());
    assert!(table.len() as u64 == fact(8) && seatings.len() as u64 == fact(7) && fixed as u64 == fact(7));
    assert!(size(&seatings) == 8 && seatings.len() * size(&seatings) == table.len());
    assert!(necks.len() as u64 == fact(5) && bracs.len() as u64 == fact(5) / 2 && mirrors(&necks) == 0);
    assert!(2 * mbrac.len() == mneck.len() + mirrors(&mneck) && mbrac.len() != mneck.len() / 2);
    println!("ALL CHECKS PASS");
}
