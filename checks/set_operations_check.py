# Set operations -- the check behind the card.  Nothing is imported.  A 12-film
# watchlist: six films stream on service A, five on B, two on both.  Walk the
# list once, sorting each film into a pile, then count the answers a second way.
FILMS = ["Drift", "Ember", "Fathom", "Glint", "Halo", "Ivory",
         "Kestrel", "Lantern", "Moth", "Nectar", "Onyx", "Pike"]
A, B = FILMS[:6], FILMS[4:9]         # service A, service B; Halo and Ivory on both
def pick(test):                      # walk all twelve films, keep the yeses
    return [f for f in FILMS if test(f)]
union = pick(lambda f: f in A or f in B)
both = pick(lambda f: f in A and f in B)
a_only = pick(lambda f: f in A and f not in B)
b_only = pick(lambda f: f in B and f not in A)
neither = pick(lambda f: f not in A and f not in B)     # not on A, and not on B
outside = pick(lambda f: f not in union)                # the other road: not (A or B)
for label, films in [("films on the watchlist", FILMS), ("films on service A", A),
                     ("films on service B", B), ("on both, A and B", both),
                     ("A or B, the union", union), ("A minus B, on A only", a_only),
                     ("B minus A, on B only", b_only), ("not on either", outside)]:
    print(f"{label:<30}{len(films):>4}")
print(f"not on A: {len(pick(lambda f: f not in A))} -- not on B: "
      f"{len(pick(lambda f: f not in B))} -- in both of those lists: {len(neither)}")
print("A only: " + ", ".join(a_only) + " | both: " + ", ".join(both)
      + " | B only: " + ", ".join(b_only) + " | neither: " + ", ".join(outside))
print(f"the three mistakes come out at {len(A) + len(B)}, {len(A) - len(B)} "
      f"and {len(FILMS) - len(both)}")
assert len(union) == 6 + 5 - 2 and len(outside) == 12 - 9      # counted by arithmetic
assert outside == neither and neither == ["Nectar", "Onyx", "Pike"]   # De Morgan
assert both == ["Halo", "Ivory"] and len(a_only) == 4 and len(b_only) == 3
print("ALL CHECKS PASS")
