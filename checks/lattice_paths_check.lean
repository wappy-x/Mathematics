-- Lattice paths: the routes that step only east or north from a start corner to the corner m blocks east and n blocks north number C(m + n, n), the route counts on the corners follow Pascal's rule, and the routes through a named corner number the routes to it times the routes onward, with the card's museum, cafe and cut numbers checked.
import Mathlib.Data.Set.Card
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.Group.Prod
import Mathlib.Algebra.BigOperators.Group.List.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic

namespace LatticePaths

/-! A walk is a list of steps, each one block east or one block north, never back. The start
corner is `(0, 0)`, and a corner is written `(blocks east, blocks north)`. A route to a corner is
any walk that ends there: its length is not fixed in advance. -/

/-- One block of a walk: east or north. -/
inductive Step
  | east
  | north
  deriving DecidableEq

/-- The move one step makes: east adds one block east, north adds one block north. -/
def Step.move : Step → ℕ × ℕ
  | .east => (1, 0)
  | .north => (0, 1)

/-- The corner a walk ends on: the sum of its moves, starting from `(0, 0)`. -/
def corner (r : List Step) : ℕ × ℕ := (r.map Step.move).sum

/-- The corners a walk stands on, in order, the start corner included. -/
def corners (r : List Step) : List (ℕ × ℕ) := r.inits.map corner

/-- The routes from the start to the corner `p`: every east-or-north walk that ends at `p`. -/
def routesTo (p : ℕ × ℕ) : Set (List Step) := {r | corner r = p}


lemma corner_cons (s : Step) (r : List Step) : corner (s :: r) = s.move + corner r := by
  simp [corner]

lemma corner_append (t u : List Step) : corner (t ++ u) = corner t + corner u := by
  simp [corner]

lemma length_eq_corner (r : List Step) : r.length = (corner r).1 + (corner r).2 := by
  induction r with
  | nil => rfl
  | cons s r ih =>
    cases s <;> simp [corner_cons, Step.move, ih] <;> omega

lemma routesTo_zero_zero : routesTo (0, 0) = {[]} := by
  ext r
  cases r with
  | nil => simp [routesTo, corner, Prod.ext_iff]
  | cons s r =>
    cases s <;> simp [routesTo, corner_cons, Step.move, Prod.ext_iff]

lemma routesTo_succ_zero (a : ℕ) :
    routesTo (a + 1, 0) = List.cons Step.east '' routesTo (a, 0) := by
  ext r
  cases r with
  | nil => simp [routesTo, corner, Prod.ext_iff]
  | cons s r =>
    cases s <;> simp [routesTo, corner_cons, Step.move, Prod.ext_iff]
    all_goals omega

lemma routesTo_zero_succ (b : ℕ) :
    routesTo (0, b + 1) = List.cons Step.north '' routesTo (0, b) := by
  ext r
  cases r with
  | nil => simp [routesTo, corner, Prod.ext_iff]
  | cons s r =>
    cases s <;> simp [routesTo, corner_cons, Step.move, Prod.ext_iff]
    all_goals omega

lemma routesTo_succ_succ (a b : ℕ) :
    routesTo (a + 1, b + 1) =
      List.cons Step.east '' routesTo (a, b + 1) ∪ List.cons Step.north '' routesTo (a + 1, b) := by
  ext r
  cases r with
  | nil => simp [routesTo, corner, Prod.ext_iff]
  | cons s r =>
    cases s <;> simp [routesTo, corner_cons, Step.move, Prod.ext_iff] <;> omega

lemma ncard_cons_image (s : Step) (X : Set (List Step)) :
    (List.cons s '' X).ncard = X.ncard :=
  Set.ncard_image_of_injective X (List.cons_injective)

lemma routesTo_finite_card (a b : ℕ) :
    (routesTo (a, b)).Finite ∧ (routesTo (a, b)).ncard = (a + b).choose b := by
  induction a generalizing b with
  | zero =>
    induction b with
    | zero => simp [routesTo_zero_zero]
    | succ b ih =>
      rw [routesTo_zero_succ, ncard_cons_image]
      refine ⟨ih.1.image _, ?_⟩
      rw [ih.2]; simp
  | succ a iha =>
    induction b with
    | zero =>
      rw [routesTo_succ_zero, ncard_cons_image]
      refine ⟨(iha 0).1.image _, ?_⟩
      rw [(iha 0).2]; simp
    | succ b ihb =>
      have h1 := iha (b + 1)
      have hdisj : Disjoint (List.cons Step.east '' routesTo (a, b + 1))
          (List.cons Step.north '' routesTo (a + 1, b)) := by
        rw [Set.disjoint_left]
        rintro r ⟨x, -, rfl⟩ ⟨y, -, hy⟩
        simp at hy
      rw [routesTo_succ_succ]
      refine ⟨(h1.1.image _).union (ihb.1.image _), ?_⟩
      rw [Set.ncard_union_eq hdisj (h1.1.image _) (ihb.1.image _), ncard_cons_image,
        ncard_cons_image, h1.2, ihb.2,
        show a + 1 + (b + 1) = (a + 1 + b) + 1 by omega, Nat.choose_succ_succ',
        show a + (b + 1) = a + 1 + b by omega]
      omega

lemma mem_corners {p : ℕ × ℕ} {r : List Step} :
    p ∈ corners r ↔ ∃ t u, r = t ++ u ∧ corner t = p := by
  simp only [corners, List.mem_map, List.mem_inits]
  constructor
  · rintro ⟨t, ⟨u, rfl⟩, ht⟩
    exact ⟨t, u, rfl, ht⟩
  · rintro ⟨t, u, rfl, ht⟩
    exact ⟨t, ⟨u, rfl⟩, ht⟩

lemma through_eq_image (m n a b : ℕ) (ha : a ≤ m) (hb : b ≤ n) :
    {r | r ∈ routesTo (m, n) ∧ (a, b) ∈ corners r} =
      (fun x : List Step × List Step => x.1 ++ x.2) ''
        (routesTo (a, b) ×ˢ routesTo (m - a, n - b)) := by
  ext r
  simp only [Set.mem_ofPred_eq, Set.mem_image, Set.mem_prod, Prod.exists, routesTo]
  constructor
  · rintro ⟨hr, h⟩
    obtain ⟨t, u, rfl, ht⟩ := mem_corners.1 h
    refine ⟨t, u, ⟨ht, ?_⟩, rfl⟩
    rw [corner_append, ht] at hr
    have h1 := congrArg Prod.fst hr
    have h2 := congrArg Prod.snd hr
    simp only [Prod.fst_add, Prod.snd_add] at h1 h2
    ext <;> simp <;> omega
  · rintro ⟨t, u, ⟨ht, hu⟩, rfl⟩
    refine ⟨?_, mem_corners.2 ⟨t, u, rfl, ht⟩⟩
    rw [corner_append, ht, hu]
    ext <;> simp <;> omega

/-- Lattice paths. A route that only steps east or north is nothing but the order of its steps,
so the routes across a grid `m` blocks east and `n` blocks north number `C(m + n, n)`. Either
side may be zero. -/
theorem card_routes_eq_choose (m n : ℕ) :
    (routesTo (m, n)).ncard = (m + n).choose n := by
  exact (routesTo_finite_card m n).2

/-- Pascal's triangle is the map. Write on every corner the number of routes to it: the bottom
edge and the left edge are all 1s, and every other corner's number is the sum of its west
neighbour's and its south neighbour's. -/
theorem routes_to_corner_pascal :
    (∀ a : ℕ, (routesTo (a, 0)).ncard = 1) ∧
      (∀ b : ℕ, (routesTo (0, b)).ncard = 1) ∧
      ∀ a b : ℕ, (routesTo (a + 1, b + 1)).ncard =
        (routesTo (a, b + 1)).ncard + (routesTo (a + 1, b)).ncard := by
  refine ⟨fun a => ?_, fun b => ?_, fun a b => ?_⟩
  · rw [(routesTo_finite_card a 0).2]; simp
  · rw [(routesTo_finite_card 0 b).2]; simp
  · rw [(routesTo_finite_card _ _).2, (routesTo_finite_card _ _).2, (routesTo_finite_card _ _).2,
      show a + 1 + (b + 1) = (a + 1 + b) + 1 by omega, Nat.choose_succ_succ',
      show a + (b + 1) = a + 1 + b by omega]
    omega

/-- Through a corner is a multiply, around it is a subtract. For a named corner `a` blocks east
and `b` blocks north inside the grid to `(m, n)`, the routes that stand on it number
`C(a + b, b) × C((m − a) + (n − b), n − b)`, and the routes clear of it are the total minus
that product. -/
theorem card_routes_through_corner (m n a b : ℕ) (ha : a ≤ m) (hb : b ≤ n) :
    {r | r ∈ routesTo (m, n) ∧ (a, b) ∈ corners r}.ncard =
        (a + b).choose b * ((m - a) + (n - b)).choose (n - b) ∧
      {r | r ∈ routesTo (m, n) ∧ (a, b) ∉ corners r}.ncard =
        (m + n).choose n - (a + b).choose b * ((m - a) + (n - b)).choose (n - b) := by
  have hthrough : {r | r ∈ routesTo (m, n) ∧ (a, b) ∈ corners r}.ncard =
      (a + b).choose b * ((m - a) + (n - b)).choose (n - b) := by
    rw [through_eq_image m n a b ha hb, Set.InjOn.ncard_image, Set.ncard_prod,
      (routesTo_finite_card _ _).2, (routesTo_finite_card _ _).2]
    rintro ⟨t, u⟩ ⟨ht, -⟩ ⟨t', u'⟩ ⟨ht', -⟩ h
    have hl : t.length = t'.length := by
      rw [length_eq_corner, length_eq_corner t']
      simp only [routesTo, Set.mem_ofPred_eq] at ht ht'
      rw [ht, ht']
    obtain ⟨h1, h2⟩ := List.append_inj h hl
    simp only at h1 h2
    rw [h1, h2]
  refine ⟨hthrough, ?_⟩
  have hfin := (routesTo_finite_card m n).1
  have key := Set.ncard_inter_add_ncard_sdiff_eq_ncard (routesTo (m, n))
    {r | (a, b) ∈ corners r} hfin
  change {r | r ∈ routesTo (m, n) ∧ (a, b) ∈ corners r}.ncard + _ = _ at key
  rw [hthrough, (routesTo_finite_card m n).2] at key
  change (routesTo (m, n) \ {r | (a, b) ∈ corners r}).ncard = _
  omega

/-- Every order of `len` east-or-north steps, `2 ^ len` walks in all. Used only to list routes in
the checks below. -/
def walks (len : ℕ) : List (List Step) := (List.replicate len [Step.east, Step.north]).sections

-- Hotel to museum: 7 blocks east, 4 north, C(11, 4) = 330 routes; also C(11, 7) = 330.
example : Nat.choose 11 4 = 330 ∧ Nat.choose 11 7 = 330 := by decide
example : 11 * 10 * 9 * 8 / (4 * 3 * 2 * 1) = 330 := by decide
-- Listing all 2048 orders of 11 steps: exactly 330 end at the museum.
example : (walks 11).length = 2048 := by decide +kernel
example : ((walks 11).filter (fun r => corner r = (7, 4))).length = 330 := by decide +kernel
-- The row E E N N E E E N E N E is a route to the museum, and it stands on the cafe at (3, 2).
example : corner [.east, .east, .north, .north, .east, .east, .east, .north, .east, .north, .east]
    = (7, 4) := by decide
example : (3, 2) ∈ corners [.east, .east, .north, .north, .east, .east, .east, .north, .east,
    .north, .east] := by decide
-- The map, row north 4: 1, 5, 15, 35, 70, 126, 210, 330; and row north 3 ends in 120.
example : (List.range 8).map (fun a => Nat.choose (a + 4) 4) = [1, 5, 15, 35, 70, 126, 210, 330] := by
  decide
example : Nat.choose (7 + 3) 3 = 120 ∧ Nat.choose (6 + 4) 4 = 210 := by decide
-- The last step into the museum: 210 from the west + 120 from the south = 330.
example : 210 + 120 = 330 := by decide
-- A diagonal of the map is a row of Pascal's triangle: 1, 4, 6, 4, 1.
example : (List.range 5).map (fun b => Nat.choose 4 b) = [1, 4, 6, 4, 1] := by decide
-- The cafe at (3, 2): C(5, 2) = 10 routes to it, C(6, 2) = 15 onward, 150 through, 180 avoid it.
example : Nat.choose 5 2 = 10 ∧ Nat.choose 6 2 = 15 ∧ 10 * 15 = 150 ∧ 330 - 150 = 180 := by decide
example : ((walks 11).filter (fun r => corner r = (7, 4) ∧ (3, 2) ∈ corners r)).length = 150 := by
  decide +kernel
example : ((walks 11).filter (fun r => corner r = (7, 4) ∧ (3, 2) ∉ corners r)).length = 180 := by
  decide +kernel
-- The cut five blocks out: groups of 15, 100, 150, 60 and 5 routes, adding to C(11, 4) = 330.
example : (List.range 5).map (fun k => Nat.choose 5 k * Nat.choose 6 (4 - k)) = [15, 100, 150, 60, 5] := by
  decide
example : Nat.choose 11 4 = ∑ k ∈ Finset.range 5, Nat.choose 5 k * Nat.choose 6 (4 - k) := by decide
-- The mistakes: labelled north steps give 7920 = 24 × 330; adding the cafe halves gives 25;
-- through-counts over all 40 corners add to 3960 = 12 × 330; all step orders number 2 ^ 11 = 2048.
example : 11 * 10 * 9 * 8 = 7920 ∧ 7920 = 24 * 330 := by decide
example : 10 + 15 = 25 := by decide
example : (∑ a ∈ Finset.range 8, ∑ b ∈ Finset.range 5,
    Nat.choose (a + b) b * Nat.choose (11 - a - b) (4 - b)) = 3960 ∧ 3960 = 12 * 330 := by decide
example : 2 ^ 11 = 2048 := by decide
-- Try changing: museum one block south, C(10, 3) = 120; cafe at (4, 1), C(5, 1) × C(6, 3) = 100.
example : Nat.choose (7 + 3) 3 = 120 ∧ Nat.choose 5 1 * Nat.choose 6 3 = 100 := by decide
-- A square grid, 5 by 5: C(10, 5) = 252 routes, 42 of which never cross the diagonal.
example : Nat.choose 10 5 = 252 := by decide
example : ((walks 10).filter (fun r => corner r = (5, 5) ∧
    ∀ p ∈ corners r, p.2 ≤ p.1)).length = 42 := by decide +kernel
-- Nothing to go north: one route along the edge, C(7 + 0, 0) = 1.
example : Nat.choose (7 + 0) 0 = 1 := by decide

#print axioms corner_cons
#print axioms corner_append
#print axioms length_eq_corner
#print axioms routesTo_zero_zero
#print axioms routesTo_succ_zero
#print axioms routesTo_zero_succ
#print axioms routesTo_succ_succ
#print axioms ncard_cons_image
#print axioms routesTo_finite_card
#print axioms mem_corners
#print axioms through_eq_image
#print axioms card_routes_eq_choose
#print axioms routes_to_corner_pascal
#print axioms card_routes_through_corner

end LatticePaths
