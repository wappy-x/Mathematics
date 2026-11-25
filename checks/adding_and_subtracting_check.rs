// The check behind the card, in Rust: twelve apples at 75 cents, a $10 bill,
// four friends, everything in whole cents.  No crates, nothing imported.
fn main() {
    const APPLES: i64 = 12;
    const PRICE: i64 = 75;
    const PAID: i64 = 1000;
    // First way: put one apple's price on the pile at a time, keeping the bill.
    let mut bill = 0i64;
    let mut running: Vec<i64> = Vec::new();
    for _ in 0..APPLES {
        bill = bill + PRICE;
        running.push(bill);
    }
    // Second way, the cross-check: the tens digits and the ones digits, added as piles.
    let (mut tens, mut ones) = (0i64, 0i64);
    for _ in 0..APPLES {
        tens = tens + PRICE / 10;
        ones = ones + PRICE % 10;
    }
    let piles = tens * 10 + ones;
    let change = PAID - bill;
    let share = PRICE + PRICE + PRICE;
    let each = change / 4;                    // the change, shared four ways
    println!("one apple, cents           {:>5}", PRICE);
    println!("twelve apples, added up    {:>5}", bill);
    println!("twelve apples, by piles    {:>5}", piles);
    println!("   {} x {} = {} tens, {} x {} = {} ones", APPLES, PRICE / 10, tens, APPLES, PRICE % 10, ones);
    println!("paid with, cents           {:>5}", PAID);
    println!("change, cents              {:>5}", change);
    println!("check: change + bill       {:>5}", change + bill);
    println!("one friend's three apples  {:>5}", share);
    println!("each friend's change       {:>5}", each);
    let cents: Vec<String> = running.iter().map(|v| v.to_string()).collect();
    println!("running bill, cents:  {}", cents.join(" "));
    println!("the three mistakes: {}, {}, {}", (5 + 5) % 10 + (7 + 7) % 10 * 10, 1 * 1000 + (9 - 0) * 100, 900 - 1000);
    assert!(bill == piles, "the two roads to the bill must agree");
    assert!(change + bill == PAID && each * 4 == change, "change + bill is the note; change splits 4 ways");
    assert!(share + share + share + share == bill, "four shares must be the whole basket");
    println!("ALL CHECKS PASS");
}
