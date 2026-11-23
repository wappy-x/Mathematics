-- Percolation: on a square-grid box with one more column of pores than rows, the chances of crossing at p and at 1 - p add to exactly one.
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Finite
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.Finset.Powerset
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.CharP.Two
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.BigOperators.Fin

open Finset

/-- The step relation of the box: pore `(x, y)` sits in column `x` and row `y`.
A channel runs to the next pore in the same row, or, in an inner column only
(not the first or last column), to the next pore in the same column. -/
def boxStep (n : ℕ) (a b : Fin (n + 1) × Fin n) : Prop :=
  (a.2 = b.2 ∧ a.1.val + 1 = b.1.val) ∨
  (a.1 = b.1 ∧ 0 < a.1.val ∧ a.1.val < n ∧ a.2.val + 1 = b.2.val)

instance (n : ℕ) : DecidableRel (boxStep n) := fun a b => by
  unfold boxStep; infer_instance

/-- The box of pores with `n + 1` columns and `n` rows, as a graph on the square grid.
Its edges are the box's channels; the vertical channels of the first and last
columns are left out, as on the card. -/
def boxGraph (n : ℕ) : SimpleGraph (Fin (n + 1) × Fin n) :=
  SimpleGraph.fromRel (boxStep n)

instance (n : ℕ) : DecidableRel (boxGraph n).Adj :=
  inferInstanceAs (DecidableRel (SimpleGraph.fromRel (boxStep n)).Adj)

/-- The number of channels in the box, `E` on the card. -/
def numChannels (n : ℕ) : ℕ := (boxGraph n).edgeFinset.card

/-- An open-and-closed pattern, given as the finite set `S` of open channels, lets water
cross: some pore in the left column is joined by open channels to some pore in the
right column. -/
def Crosses (n : ℕ) (S : Finset (Sym2 (Fin (n + 1) × Fin n))) : Prop :=
  ∃ y y' : Fin n,
    (SimpleGraph.fromEdgeSet (S : Set (Sym2 (Fin (n + 1) × Fin n)))).Reachable (0, y) (Fin.last n, y')

/-- `a_k` on the card: how many patterns with exactly `k` open channels let water cross. -/
noncomputable def crossCount (n k : ℕ) : ℕ := by
  classical
  exact (((boxGraph n).edgeFinset.powersetCard k).filter (Crosses n)).card

/-- `f(p)` on the card: the chance that water crosses the box when every channel is open
with chance `p`, independently, written as `∑ a_k p^k (1 - p)^(E - k)`. -/
noncomputable def crossChance (n : ℕ) (p : ℝ) : ℝ :=
  ∑ k ∈ range (numChannels n + 1),
    (crossCount n k : ℝ) * p ^ k * (1 - p) ^ (numChannels n - k)


namespace FairBox

/-- Adjacency in the box, in terms of coordinates. -/
def adjN (n ax ay bx by' : ℕ) : Prop :=
  (ay = by' ∧ ax + 1 = bx) ∨ (ay = by' ∧ bx + 1 = ax) ∨
  (ax = bx ∧ 0 < ax ∧ ax < n ∧ ay + 1 = by') ∨ (ax = bx ∧ 0 < ax ∧ ax < n ∧ by' + 1 = ay)

lemma boxAdj_iff (n : ℕ) (a b : Fin (n + 1) × Fin n) :
    (boxGraph n).Adj a b ↔ adjN n a.1.val a.2.val b.1.val b.2.val := by
  rw [boxGraph, SimpleGraph.fromRel_adj]
  simp only [boxStep, adjN, ne_eq, Prod.ext_iff, Fin.ext_iff]
  omega

/-- A pore from coordinates. -/
def mkV (n : ℕ) (hn : 0 < n) (x y : ℕ) : Fin (n + 1) × Fin n :=
  (⟨x % (n + 1), Nat.mod_lt _ (Nat.succ_pos n)⟩, ⟨y % n, Nat.mod_lt _ hn⟩)

lemma mkV_eq_iff (n : ℕ) (hn : 0 < n) (x y : ℕ) (hx : x < n + 1) (hy : y < n)
    (v : Fin (n + 1) × Fin n) : v = mkV n hn x y ↔ v.1.val = x ∧ v.2.val = y := by
  simp only [mkV, Prod.ext_iff, Fin.ext_iff, Nat.mod_eq_of_lt hx, Nat.mod_eq_of_lt hy]

/-- The dual channel of the channel `s(a, b)`, rotated back onto the box. -/
def dualPair (n : ℕ) (a b : Fin (n + 1) × Fin n) : Sym2 (Fin (n + 1) × Fin n) :=
  s(mkV n a.2.pos ((a.2.val + b.2.val + 1) / 2) ((a.1.val + b.1.val - 1) / 2),
    mkV n a.2.pos ((a.2.val + b.2.val + 2) / 2) ((a.1.val + b.1.val) / 2))

lemma dualPair_comm (n : ℕ) (a b : Fin (n + 1) × Fin n) : dualPair n a b = dualPair n b a := by
  unfold dualPair
  rw [Nat.add_comm a.1.val, Nat.add_comm a.2.val]

/-- The duality map on channels. -/
def dualMap (n : ℕ) : Sym2 (Fin (n + 1) × Fin n) → Sym2 (Fin (n + 1) × Fin n) :=
  Sym2.lift ⟨dualPair n, dualPair_comm n⟩

lemma dualMap_mk (n : ℕ) (a b : Fin (n + 1) × Fin n) : dualMap n s(a, b) = dualPair n a b := by
  simp [dualMap]

/-- The dual channel, as an equation in coordinates. -/
lemma eq_dualMap_iff (n : ℕ) (q q' a b : Fin (n + 1) × Fin n) (h : (boxGraph n).Adj q q') :
    s(a, b) = dualMap n s(q, q') ↔
      (a.1.val = (q.2.val + q'.2.val + 1) / 2 ∧ a.2.val = (q.1.val + q'.1.val - 1) / 2 ∧
        b.1.val = (q.2.val + q'.2.val + 2) / 2 ∧ b.2.val = (q.1.val + q'.1.val) / 2) ∨
      (b.1.val = (q.2.val + q'.2.val + 1) / 2 ∧ b.2.val = (q.1.val + q'.1.val - 1) / 2 ∧
        a.1.val = (q.2.val + q'.2.val + 2) / 2 ∧ a.2.val = (q.1.val + q'.1.val) / 2) := by
  rw [boxAdj_iff] at h
  unfold adjN at h
  have h1 := q.1.isLt; have h2 := q.2.isLt; have h3 := q'.1.isLt; have h4 := q'.2.isLt
  rw [dualMap_mk, dualPair, Sym2.eq_iff, mkV_eq_iff _ _ _ _ (by omega) (by omega),
    mkV_eq_iff _ _ _ _ (by omega) (by omega), mkV_eq_iff _ _ _ _ (by omega) (by omega),
    mkV_eq_iff _ _ _ _ (by omega) (by omega)]
  tauto

lemma dualMap_adj (n : ℕ) (q q' : Fin (n + 1) × Fin n) (h : (boxGraph n).Adj q q') :
    dualMap n s(q, q') ∈ (boxGraph n).edgeSet := by
  have h' := h
  rw [boxAdj_iff] at h
  unfold adjN at h
  have h1 := q.1.isLt; have h2 := q.2.isLt; have h3 := q'.1.isLt; have h4 := q'.2.isLt
  rw [dualMap_mk, dualPair, SimpleGraph.mem_edgeSet, boxAdj_iff]
  simp only [mkV, adjN, Nat.mod_eq_of_lt (show (q.2.val + q'.2.val + 1) / 2 < n + 1 by omega),
    Nat.mod_eq_of_lt (show (q.2.val + q'.2.val + 2) / 2 < n + 1 by omega),
    Nat.mod_eq_of_lt (show (q.1.val + q'.1.val - 1) / 2 < n by omega),
    Nat.mod_eq_of_lt (show (q.1.val + q'.1.val) / 2 < n by omega)]
  omega

lemma dualMap_dualMap (n : ℕ) (q q' : Fin (n + 1) × Fin n) (h : (boxGraph n).Adj q q') :
    dualMap n (dualMap n s(q, q')) = s(q, q') := by
  have h' := h
  rw [boxAdj_iff] at h
  unfold adjN at h
  have h1 := q.1.isLt; have h2 := q.2.isLt; have h3 := q'.1.isLt; have h4 := q'.2.isLt
  rw [dualMap_mk n q q', dualPair, dualMap_mk, dualPair, Sym2.eq_iff]
  simp only [mkV, Prod.ext_iff, Fin.ext_iff,
    Nat.mod_eq_of_lt (show (q.2.val + q'.2.val + 1) / 2 < n + 1 by omega),
    Nat.mod_eq_of_lt (show (q.2.val + q'.2.val + 2) / 2 < n + 1 by omega),
    Nat.mod_eq_of_lt (show (q.1.val + q'.1.val - 1) / 2 < n by omega),
    Nat.mod_eq_of_lt (show (q.1.val + q'.1.val) / 2 < n by omega)]
  have e1 : ((q.1.val + q'.1.val - 1) / 2 + (q.1.val + q'.1.val) / 2 + 1) / 2 % (n + 1)
      = ((q.1.val + q'.1.val - 1) / 2 + (q.1.val + q'.1.val) / 2 + 1) / 2 :=
    Nat.mod_eq_of_lt (by omega)
  have e2 : ((q.1.val + q'.1.val - 1) / 2 + (q.1.val + q'.1.val) / 2 + 2) / 2 % (n + 1)
      = ((q.1.val + q'.1.val - 1) / 2 + (q.1.val + q'.1.val) / 2 + 2) / 2 :=
    Nat.mod_eq_of_lt (by omega)
  have e3 : ((q.2.val + q'.2.val + 1) / 2 + (q.2.val + q'.2.val + 2) / 2 - 1) / 2 % n
      = ((q.2.val + q'.2.val + 1) / 2 + (q.2.val + q'.2.val + 2) / 2 - 1) / 2 :=
    Nat.mod_eq_of_lt (by omega)
  have e4 : ((q.2.val + q'.2.val + 1) / 2 + (q.2.val + q'.2.val + 2) / 2) / 2 % n
      = ((q.2.val + q'.2.val + 1) / 2 + (q.2.val + q'.2.val + 2) / 2) / 2 :=
    Nat.mod_eq_of_lt (by omega)
  rw [e1, e2, e3, e4]
  omega

#print axioms boxAdj_iff
#print axioms mkV_eq_iff
#print axioms dualPair_comm
#print axioms dualMap_mk
#print axioms eq_dualMap_iff
#print axioms dualMap_adj
#print axioms dualMap_dualMap

end FairBox

namespace FairBox

lemma zmod2_eq_of_add_eq_zero {a b : ZMod 2} (h : a + b = 0) : a = b := by
  rw [← CharTwo.sub_eq_add] at h
  exact sub_eq_zero.mp h

lemma walk_telescope {V : Type*} {G : SimpleGraph V} {u v : V} (w : G.Walk u v)
    (f : V → ZMod 2) (F : V → V → ZMod 2)
    (hF : ∀ d ∈ w.darts, F d.fst d.snd = f d.fst + f d.snd) :
    (w.darts.map (fun d => F d.fst d.snd)).sum = f u + f v := by
  induction w with
  | nil => simp [CharTwo.add_self_eq_zero]
  | cons h p ih =>
    simp only [SimpleGraph.Walk.darts_cons, List.mem_cons, forall_eq_or_imp] at hF
    simp only [SimpleGraph.Walk.darts_cons, List.map_cons, List.sum_cons]
    rw [hF.1, ih hF.2]
    have key : ∀ a b c : ZMod 2, a + b + (b + c) = a + c := by decide
    exact key _ _ _

lemma walk_const {V : Type*} {G : SimpleGraph V} {u v : V} (w : G.Walk u v)
    (N : V → ZMod 2) (h : ∀ a b, G.Adj a b → N a = N b) : N u = N v := by
  induction w with
  | nil => rfl
  | cons hadj p ih => exact (h _ _ hadj).trans ih

/-- Does the channel `(a, b)` cross column gap `Y` below row `X`? -/
def indN (X Y ax ay bx by' : ℕ) : ZMod 2 :=
  if ay = by' ∧ ay < X ∧ ax + bx = 2 * Y + 1 then 1 else 0

/-- The potential whose jumps account for a dual channel. -/
def gqN (X Y X' Y' vx vy : ℕ) : ZMod 2 :=
  if X = X' ∧ vx = (Y + Y' + 1) / 2 ∧ vy < X then 1 else 0

lemma indN_step (n ax ay bx by' X Y X' Y' : ℕ)
    (hab : adjN n ax ay bx by') (hq : adjN n X Y X' Y')
    (hne : ¬ ((ax = (Y + Y' + 1) / 2 ∧ ay = (X + X' - 1) / 2 ∧
        bx = (Y + Y' + 2) / 2 ∧ by' = (X + X') / 2) ∨
      (bx = (Y + Y' + 1) / 2 ∧ by' = (X + X' - 1) / 2 ∧
        ax = (Y + Y' + 2) / 2 ∧ ay = (X + X') / 2))) :
    indN X Y ax ay bx by' + indN X' Y' ax ay bx by' =
      gqN X Y X' Y' ax ay + gqN X Y X' Y' bx by' := by
  unfold indN gqN
  rcases hab with ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2, h3, h4⟩ | ⟨h1, h2, h3, h4⟩ <;>
  rcases hq with ⟨k1, k2⟩ | ⟨k1, k2⟩ | ⟨k1, k2, k3, k4⟩ | ⟨k1, k2, k3, k4⟩ <;>
  subst_vars <;>
  split_ifs <;> first | rfl | (exfalso; omega)

lemma indN_top (n Y ax ay bx by' : ℕ) (hab : adjN n ax ay bx by') (ha : ay < n) :
    indN n Y ax ay bx by' = (if ax ≤ Y then 1 else 0) + (if bx ≤ Y then 1 else 0) := by
  unfold adjN at hab
  unfold indN
  split_ifs <;> first | decide | (exfalso; omega)

lemma indN_bot (Y ax ay bx by' : ℕ) : indN 0 Y ax ay bx by' = 0 := by
  unfold indN
  rw [ite_eq_right_iff.mpr (fun h => by omega)]

#print axioms zmod2_eq_of_add_eq_zero
#print axioms walk_telescope
#print axioms walk_const
#print axioms indN_step
#print axioms indN_top
#print axioms indN_bot

end FairBox

namespace FairBox

lemma not_both (n : ℕ) (S : Finset (Sym2 (Fin (n + 1) × Fin n)))
    (hS : S ⊆ (boxGraph n).edgeFinset) (h1 : Crosses n S)
    (h2 : Crosses n (((boxGraph n).edgeFinset \ S).image (dualMap n))) : False := by
  obtain ⟨y0, y1, ⟨w⟩⟩ := h1
  obtain ⟨c0, c1, ⟨w'⟩⟩ := h2
  have hd : ∀ d ∈ w.darts, s(d.fst, d.snd) ∈ S ∧ (boxGraph n).Adj d.fst d.snd := by
    intro d _
    have hadj := d.adj
    rw [SimpleGraph.fromEdgeSet_adj] at hadj
    refine ⟨hadj.1, ?_⟩
    have := hS hadj.1
    rwa [SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet] at this
  let N : Fin (n + 1) × Fin n → ZMod 2 := fun q =>
    (w.darts.map (fun d =>
      indN q.1.val q.2.val d.fst.1.val d.fst.2.val d.snd.1.val d.snd.2.val)).sum
  have hN : ∀ q q', (SimpleGraph.fromEdgeSet
      ((((boxGraph n).edgeFinset \ S).image (dualMap n) : Finset _) : Set _)).Adj q q' →
      N q = N q' := by
    intro q q' hqq'
    rw [SimpleGraph.fromEdgeSet_adj] at hqq'
    obtain ⟨hmem, -⟩ := hqq'
    rw [Finset.mem_coe, Finset.mem_image] at hmem
    obtain ⟨e, he, hdualMape⟩ := hmem
    rw [Finset.mem_sdiff] at he
    obtain ⟨heE, heS⟩ := he
    induction e using Sym2.ind with | _ a b => ?_
    rw [SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet] at heE
    have hqadj : (boxGraph n).Adj q q' := by
      have := dualMap_adj n a b heE
      rw [hdualMape] at this
      exact this
    have hback : dualMap n s(q, q') = s(a, b) := by rw [← hdualMape, dualMap_dualMap n a b heE]
    apply zmod2_eq_of_add_eq_zero
    simp only [N]
    rw [← List.sum_map_add]
    refine Eq.trans (walk_telescope w
      (fun v => gqN q.1.val q.2.val q'.1.val q'.2.val v.1.val v.2.val)
      (fun u v => indN q.1.val q.2.val u.1.val u.2.val v.1.val v.2.val +
        indN q'.1.val q'.2.val u.1.val u.2.val v.1.val v.2.val) ?_) ?_
    · intro d hdw
      obtain ⟨hdS, hdadj⟩ := hd d hdw
      apply indN_step n _ _ _ _ _ _ _ _ ((boxAdj_iff n _ _).mp hdadj)
        ((boxAdj_iff n _ _).mp hqadj)
      intro hc
      have heq : s(d.fst, d.snd) = dualMap n s(q, q') := (eq_dualMap_iff n q q' _ _ hqadj).mpr hc
      rw [hback] at heq
      rw [heq] at hdS
      exact heS hdS
    · have hq := (boxAdj_iff n _ _).mp hqadj
      unfold adjN at hq
      have := q.2.isLt
      have := q'.2.isLt
      simp only [Fin.val_zero, Fin.val_last]
      unfold gqN
      split_ifs <;> first | rfl | (exfalso; omega)
  have hconst := walk_const w' N hN
  have h0 : N ((0 : Fin (n + 1)), c0) = 0 := by
    simp [N, indN_bot]
  have hlast : N (Fin.last n, c1) = 1 := by
    simp only [N, Fin.val_last]
    refine Eq.trans (walk_telescope w
      (fun v => if v.1.val ≤ c1.val then 1 else 0)
      (fun u v => indN n c1.val u.1.val u.2.val v.1.val v.2.val) ?_) ?_
    · intro d hdw
      exact indN_top n _ _ _ _ _ ((boxAdj_iff n _ _).mp (hd d hdw).2) d.fst.2.isLt
    · have := c1.isLt
      have hc : ¬ n ≤ c1.val := by omega
      simp [hc]
  rw [h0, hlast] at hconst
  exact absurd hconst (by decide)

#print axioms not_both

end FairBox

namespace FairBox

lemma z2_four : ∀ a b c d : ZMod 2, a + b + (c + d) + (c + a) + (d + b) = 0 := by decide

lemma range_telescope (f : ℕ → ZMod 2) (m : ℕ) :
    ∑ i ∈ Finset.range m, (f i + f (i + 1)) = f 0 + f m := by
  induction m with
  | zero => simp [CharTwo.add_self_eq_zero]
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have key : ∀ a b c : ZMod 2, a + b + (b + c) = a + c := by decide
    exact key _ _ _

lemma sum2_ite (m1 m2 k1 k2 : ℕ) (A : ZMod 2) :
    ∑ x ∈ Finset.range m1, ∑ y ∈ Finset.range m2, (if x = k1 ∧ y = k2 then A else 0) =
      if k1 < m1 ∧ k2 < m2 then A else 0 := by
  by_cases h1 : k1 < m1 <;> by_cases h2 : k2 < m2 <;> simp [ite_and, h1, h2]

instance (n ax ay bx by' : ℕ) : Decidable (adjN n ax ay bx by') := by
  unfold adjN; infer_instance

/-- The parity of the number of cut dual channels at the dual pore `(X, Y)`, written out. -/
def FzN (G : ℕ → ℕ → ZMod 2) (n X Y x y : ℕ) : ZMod 2 :=
  if adjN n X Y x y then G ((Y + y + 1) / 2) ((X + x - 1) / 2) + G ((Y + y + 2) / 2) ((X + x) / 2)
  else 0

lemma FzN_interior (G : ℕ → ℕ → ZMod 2) (n X Y x y : ℕ) (hX0 : 0 < X) (hXn : X < n) :
    FzN G n X Y x y =
      (if x = X + 1 ∧ y = Y then G Y X + G (Y + 1) X else 0) +
      (if x = X - 1 ∧ y = Y then G Y (X - 1) + G (Y + 1) (X - 1) else 0) +
      (if 0 < Y then (if x = X ∧ y = Y - 1 then G Y (X - 1) + G Y X else 0) else 0) +
      (if x = X ∧ y = Y + 1 then G (Y + 1) (X - 1) + G (Y + 1) X else 0) := by
  unfold FzN
  by_cases hadj : adjN n X Y x y
  · rw [ite_eq_left hadj]
    unfold adjN at hadj
    split_ifs <;> (try simp only [add_zero, zero_add]) <;>
      first | rfl | (exfalso; omega) | (congr 1 <;> congr 1 <;> omega)
  · rw [ite_eq_right hadj]
    unfold adjN at hadj
    split_ifs <;> first | rfl | (exfalso; omega)

lemma FzN_bottom (G : ℕ → ℕ → ZMod 2) (n Y x y : ℕ) :
    FzN G n 0 Y x y = if x = 1 ∧ y = Y then G Y 0 + G (Y + 1) 0 else 0 := by
  unfold FzN
  by_cases hadj : adjN n 0 Y x y
  · rw [ite_eq_left hadj]
    unfold adjN at hadj
    split_ifs <;> first | rfl | (exfalso; omega) | (congr 1 <;> congr 1 <;> omega)
  · rw [ite_eq_right hadj]
    unfold adjN at hadj
    split_ifs <;> first | rfl | (exfalso; omega)

lemma sum_FzN_interior (G : ℕ → ℕ → ZMod 2) (n X Y : ℕ) (hX0 : 0 < X) (hXn : X < n)
    (hY : Y < n) (hG0 : ∀ r < n, G 0 r = 1) (hGn : ∀ r < n, G n r = 0) :
    ∑ x ∈ Finset.range (n + 1), ∑ y ∈ Finset.range n, FzN G n X Y x y = 0 := by
  simp only [FzN_interior G n X Y _ _ hX0 hXn, Finset.sum_add_distrib]
  rw [sum2_ite, sum2_ite, sum2_ite]
  have e3 : ∑ x ∈ Finset.range (n + 1), ∑ y ∈ Finset.range n,
      (if 0 < Y then (if x = X ∧ y = Y - 1 then G Y (X - 1) + G Y X else 0) else 0) =
      G Y (X - 1) + G Y X := by
    by_cases h : 0 < Y
    · simp only [h, ite_true]
      rw [sum2_ite, ite_eq_left (by omega)]
    · simp only [h, ite_false, Finset.sum_const_zero]
      have : Y = 0 := by omega
      subst this
      rw [hG0 _ (by omega), hG0 _ (by omega)]
      decide
  rw [e3, ite_eq_left (by omega), ite_eq_left (by omega)]
  have e4 : (if X < n + 1 ∧ Y + 1 < n then G (Y + 1) (X - 1) + G (Y + 1) X else 0) =
      G (Y + 1) (X - 1) + G (Y + 1) X := by
    split_ifs with h
    · rfl
    · have : Y + 1 = n := by omega
      rw [this, hGn _ (by omega), hGn _ (by omega)]
      decide
  rw [e4]
  have := z2_four (G Y X) (G (Y + 1) X) (G Y (X - 1)) (G (Y + 1) (X - 1))
  rw [← this]

lemma sum_FzN_bottom (G : ℕ → ℕ → ZMod 2) (n Y : ℕ) (hn : 1 ≤ n) (hY : Y < n) :
    ∑ x ∈ Finset.range (n + 1), ∑ y ∈ Finset.range n, FzN G n 0 Y x y = G Y 0 + G (Y + 1) 0 := by
  simp only [FzN_bottom]
  rw [sum2_ite, ite_eq_left (by omega)]

#print axioms z2_four
#print axioms range_telescope
#print axioms sum2_ite
#print axioms FzN_interior
#print axioms FzN_bottom
#print axioms sum_FzN_interior
#print axioms sum_FzN_bottom

end FairBox

namespace FairBox

lemma zmod2_ite_eq (z : ZMod 2) : (if z = 1 then (1 : ZMod 2) else 0) = z := by
  fin_cases z <;> rfl

lemma at_least_one (n : ℕ) (hn : 1 ≤ n) (S : Finset (Sym2 (Fin (n + 1) × Fin n)))
    (hS : S ⊆ (boxGraph n).edgeFinset) (h : ¬ Crosses n S) :
    Crosses n (((boxGraph n).edgeFinset \ S).image (dualMap n)) := by
  classical
  by_contra hT
  let GS := SimpleGraph.fromEdgeSet (S : Set (Sym2 (Fin (n + 1) × Fin n)))
  let C : Set (Fin (n + 1) × Fin n) := {v | ∃ y, GS.Reachable (0, y) v}
  let G : ℕ → ℕ → ZMod 2 := fun x y =>
    if hxy : x < n + 1 ∧ y < n then
      (if ((⟨x, hxy.1⟩, ⟨y, hxy.2⟩) : Fin (n + 1) × Fin n) ∈ C then 1 else 0)
    else 0
  let g : Fin (n + 1) × Fin n → ZMod 2 := fun v => G v.1.val v.2.val
  have hg : ∀ v, g v = if v ∈ C then 1 else 0 := by
    intro v
    simp only [g, G, dite_eq_left (And.intro v.1.isLt v.2.isLt)]
  have hG0 : ∀ r < n, G 0 r = 1 := by
    intro r hr
    simp only [G, dite_eq_left (And.intro (Nat.succ_pos n) hr)]
    rw [ite_eq_left]
    refine ⟨⟨r, hr⟩, ?_⟩
    have e : ((⟨0, Nat.succ_pos n⟩ : Fin (n + 1)), (⟨r, hr⟩ : Fin n)) =
        ((0 : Fin (n + 1)), (⟨r, hr⟩ : Fin n)) := by
      ext <;> simp
    rw [e]
  have hGn : ∀ r < n, G n r = 0 := by
    intro r hr
    simp only [G, dite_eq_left (And.intro (Nat.lt_succ_self n) hr)]
    rw [ite_eq_right]
    rintro ⟨y, hy⟩
    exact h ⟨y, ⟨r, hr⟩, hy⟩
  have hclosed : ∀ a b, s(a, b) ∈ S → g a = g b := by
    intro a b hab
    have hadj : (boxGraph n).Adj a b := by
      have := hS hab
      rwa [SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet] at this
    have hGS : GS.Adj a b := by
      rw [SimpleGraph.fromEdgeSet_adj]
      exact ⟨hab, hadj.ne⟩
    rw [hg, hg]
    by_cases ha : a ∈ C
    · have hb : b ∈ C := by
        obtain ⟨y, hy⟩ := ha
        exact ⟨y, hy.trans hGS.reachable⟩
      rw [ite_eq_left ha, ite_eq_left hb]
    · have hb : b ∉ C := by
        rintro ⟨y, hy⟩
        exact ha ⟨y, hy.trans hGS.symm.reachable⟩
      rw [ite_eq_right ha, ite_eq_right hb]
  let δ : Sym2 (Fin (n + 1) × Fin n) → ZMod 2 :=
    Sym2.lift ⟨fun a b => g a + g b, fun a b => add_comm _ _⟩
  have hδS : ∀ e ∈ S, δ e = 0 := by
    intro e
    induction e using Sym2.ind with
    | _ a b =>
      intro he
      simp only [δ, Sym2.lift_mk]
      rw [hclosed a b he]
      exact CharTwo.add_self_eq_zero _
  have hδdualMap : ∀ q q', (boxGraph n).Adj q q' → δ (dualMap n s(q, q')) =
      G ((q.2.val + q'.2.val + 1) / 2) ((q.1.val + q'.1.val - 1) / 2) +
      G ((q.2.val + q'.2.val + 2) / 2) ((q.1.val + q'.1.val) / 2) := by
    intro q q' hq
    have hq' := (boxAdj_iff n q q').mp hq
    unfold adjN at hq'
    have := q.1.isLt; have := q.2.isLt; have := q'.1.isLt; have := q'.2.isLt
    rw [dualMap_mk, dualPair]
    simp only [δ, Sym2.lift_mk, g, mkV]
    rw [Nat.mod_eq_of_lt (show (q.2.val + q'.2.val + 1) / 2 < n + 1 by omega),
      Nat.mod_eq_of_lt (show (q.2.val + q'.2.val + 2) / 2 < n + 1 by omega),
      Nat.mod_eq_of_lt (show (q.1.val + q'.1.val - 1) / 2 < n by omega),
      Nat.mod_eq_of_lt (show (q.1.val + q'.1.val) / 2 < n by omega)]
  let H : SimpleGraph (Fin (n + 1) × Fin n) :=
    { Adj := fun q q' => (boxGraph n).Adj q q' ∧ δ (dualMap n s(q, q')) = 1
      symm := ⟨fun q q' hq => ⟨hq.1.symm, by rw [Sym2.eq_swap]; exact hq.2⟩⟩
      loopless := ⟨fun q hq => (boxGraph n).loopless.irrefl q hq.1⟩ }
  have hHT : H ≤ SimpleGraph.fromEdgeSet
      ((((boxGraph n).edgeFinset \ S).image (dualMap n) : Finset _) : Set _) := by
    intro q q' hq
    rw [SimpleGraph.fromEdgeSet_adj]
    refine ⟨?_, hq.1.ne⟩
    rw [Finset.mem_coe, Finset.mem_image]
    refine ⟨dualMap n s(q, q'), ?_, dualMap_dualMap n q q' hq.1⟩
    rw [Finset.mem_sdiff, SimpleGraph.mem_edgeFinset]
    refine ⟨dualMap_adj n q q' hq.1, fun hmem => ?_⟩
    have := hδS _ hmem
    rw [hq.2] at this
    exact absurd this (by decide)
  let K : Set (Fin (n + 1) × Fin n) := {q | ∃ c, H.Reachable (0, c) q}
  have hKtop : ∀ c, (Fin.last n, c) ∉ K := fun c ⟨c0, hr⟩ => hT ⟨c0, c, hr.mono hHT⟩
  have hKbot : ∀ c, ((0 : Fin (n + 1)), c) ∈ K := fun c => ⟨c, SimpleGraph.Reachable.refl _⟩
  have hKcl : ∀ q q', H.Adj q q' → q ∈ K → q' ∈ K := fun q q' hqq ⟨c, hr⟩ =>
    ⟨c, hr.trans hqq.reachable⟩
  let H' : SimpleGraph (Fin (n + 1) × Fin n) :=
    { Adj := fun q q' => H.Adj q q' ∧ q ∈ K
      symm := ⟨fun q q' hq => ⟨(show H.Adj q q' from hq.1).symm, hKcl q q' hq.1 hq.2⟩⟩
      loopless := ⟨fun q hq => H.loopless.irrefl q hq.1⟩ }
  have hz : ∑ v, (H'.degree v : ZMod 2) = 0 := by
    have := congrArg (Nat.cast : ℕ → ZMod 2) (H'.sum_degrees_eq_twice_card_edges)
    push_cast at this
    rw [this]
    exact mul_eq_zero_of_left (by decide) _
  let D : Fin (n + 1) × Fin n → ZMod 2 := fun q =>
    ∑ q', if (boxGraph n).Adj q q' then δ (dualMap n s(q, q')) else 0
  have hdeg : ∀ q, (H'.degree q : ZMod 2) = if q ∈ K then D q else 0 := by
    intro q
    rw [← SimpleGraph.card_neighborFinset_eq_degree, SimpleGraph.neighborFinset_eq_filter,
      Finset.natCast_card_filter]
    split_ifs with hqK
    · simp only [D]
      apply Finset.sum_congr rfl
      intro q' _
      by_cases hb : (boxGraph n).Adj q q'
      · simp only [H', H, hb, hqK, true_and, and_true]
        exact zmod2_ite_eq _
      · simp [H', H, hb]
    · apply Finset.sum_eq_zero
      intro q' _
      simp [H', hqK]
  have hDsum : ∀ q : Fin (n + 1) × Fin n,
      D q = ∑ x ∈ Finset.range (n + 1), ∑ y ∈ Finset.range n, FzN G n q.1.val q.2.val x y := by
    intro q
    simp only [D]
    rw [Fintype.sum_prod_type]
    rw [← Fin.sum_univ_eq_sum_range (fun x => ∑ y ∈ Finset.range n, FzN G n q.1.val q.2.val x y)
      (n + 1)]
    apply Finset.sum_congr rfl
    intro x _
    rw [← Fin.sum_univ_eq_sum_range (fun y => FzN G n q.1.val q.2.val x.val y) n]
    apply Finset.sum_congr rfl
    intro y _
    unfold FzN
    by_cases hb : (boxGraph n).Adj q (x, y)
    · rw [ite_eq_left hb, ite_eq_left ((boxAdj_iff n q (x, y)).mp hb), hδdualMap q (x, y) hb]
    · rw [ite_eq_right hb, ite_eq_right (fun h' => hb ((boxAdj_iff n q (x, y)).mpr h'))]
  have hint : ∀ q : Fin (n + 1) × Fin n, 0 < q.1.val → q.1.val < n → D q = 0 :=
    fun q h0 hn' => by
      rw [hDsum]
      exact sum_FzN_interior G n _ _ h0 hn' q.2.isLt hG0 hGn
  have hbot : ∀ c : Fin n, D ((0 : Fin (n + 1)), c) = G c.val 0 + G (c.val + 1) 0 := fun c => by
    rw [hDsum]
    exact sum_FzN_bottom G n c.val hn c.isLt
  have htotal : ∑ q, (if q ∈ K then D q else 0) = 1 := by
    rw [Fintype.sum_prod_type, Fin.sum_univ_succ]
    have hrest : ∑ X : Fin n, ∑ Y : Fin n,
        (if (X.succ, Y) ∈ K then D (X.succ, Y) else 0) = 0 := by
      apply Finset.sum_eq_zero
      intro X _
      apply Finset.sum_eq_zero
      intro Y _
      by_cases hX : X.val + 1 < n
      · rw [hint (X.succ, Y) (by simp) (by simpa using hX)]
        simp
      · have hl : X.succ = Fin.last n := by
          ext
          simp only [Fin.val_succ, Fin.val_last]
          omega
        rw [hl, ite_eq_right (hKtop Y)]
    rw [hrest, add_zero]
    have hb0 : ∀ Y : Fin n, (if ((0 : Fin (n + 1)), Y) ∈ K then D (0, Y) else 0) =
        G Y.val 0 + G (Y.val + 1) 0 := fun Y => by
      rw [ite_eq_left (hKbot Y), hbot]
    simp only [hb0]
    rw [Fin.sum_univ_eq_sum_range (fun y => G y 0 + G (y + 1) 0) n,
      range_telescope (fun y => G y 0) n]
    rw [hG0 0 (by omega), hGn 0 (by omega)]
    rfl
  have hfin : ∑ q, (H'.degree q : ZMod 2) = ∑ q, (if q ∈ K then D q else 0) :=
    Finset.sum_congr rfl (fun q _ => hdeg q)
  rw [hz, htotal] at hfin
  exact absurd hfin (by decide)

#print axioms zmod2_ite_eq
#print axioms at_least_one

end FairBox

namespace FairBox

lemma dualMap_mem (n : ℕ) (e : Sym2 (Fin (n + 1) × Fin n)) (he : e ∈ (boxGraph n).edgeFinset) :
    dualMap n e ∈ (boxGraph n).edgeFinset := by
  induction e using Sym2.ind with
  | _ a b =>
    rw [SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet] at he
    rw [SimpleGraph.mem_edgeFinset]
    exact dualMap_adj n a b he

lemma dualMap_invol (n : ℕ) (e : Sym2 (Fin (n + 1) × Fin n)) (he : e ∈ (boxGraph n).edgeFinset) :
    dualMap n (dualMap n e) = e := by
  induction e using Sym2.ind with
  | _ a b =>
    rw [SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet] at he
    exact dualMap_dualMap n a b he

lemma image_dualMap_dualMap (n : ℕ) (A : Finset (Sym2 (Fin (n + 1) × Fin n)))
    (hA : A ⊆ (boxGraph n).edgeFinset) : (A.image (dualMap n)).image (dualMap n) = A := by
  ext x
  simp only [Finset.mem_image]
  constructor
  · rintro ⟨y, ⟨z, hz, rfl⟩, rfl⟩
    rw [dualMap_invol n z (hA hz)]
    exact hz
  · intro hx
    exact ⟨dualMap n x, ⟨x, hx, rfl⟩, dualMap_invol n x (hA hx)⟩

lemma card_image_dualMap (n : ℕ) (A : Finset (Sym2 (Fin (n + 1) × Fin n)))
    (hA : A ⊆ (boxGraph n).edgeFinset) : (A.image (dualMap n)).card = A.card := by
  apply Finset.card_image_of_injOn
  intro a ha b hb hab
  rw [← dualMap_invol n a (hA ha), hab, dualMap_invol n b (hA hb)]

lemma image_dualMap_sub (n : ℕ) (A : Finset (Sym2 (Fin (n + 1) × Fin n)))
    (hA : A ⊆ (boxGraph n).edgeFinset) : A.image (dualMap n) ⊆ (boxGraph n).edgeFinset := by
  intro x hx
  rw [Finset.mem_image] at hx
  obtain ⟨y, hy, rfl⟩ := hx
  exact dualMap_mem n y (hA hy)

lemma duality (n : ℕ) (hn : 1 ≤ n) (S : Finset (Sym2 (Fin (n + 1) × Fin n)))
    (hS : S ⊆ (boxGraph n).edgeFinset) :
    Crosses n (((boxGraph n).edgeFinset \ S).image (dualMap n)) ↔ ¬ Crosses n S :=
  ⟨fun hT hS' => not_both n S hS hS' hT, at_least_one n hn S hS⟩

lemma count_duality (n : ℕ) (hn : 1 ≤ n) (k : ℕ) (hk : k ≤ numChannels n) :
    crossCount n k + crossCount n (numChannels n - k) = (numChannels n).choose k := by
  classical
  unfold crossCount numChannels
  unfold numChannels at hk
  have hcount : ((((boxGraph n).edgeFinset.powersetCard
        ((boxGraph n).edgeFinset.card - k)).filter (Crosses n)).card) =
      ((((boxGraph n).edgeFinset.powersetCard k).filter (fun S => ¬ Crosses n S)).card) := by
    apply Finset.card_nbij' (fun T => (boxGraph n).edgeFinset \ T.image (dualMap n))
      (fun S => ((boxGraph n).edgeFinset \ S).image (dualMap n))
    · intro T hT
      simp only [Finset.coe_filter, Set.mem_ofPred_eq, Finset.mem_powersetCard] at hT ⊢
      obtain ⟨⟨hTE, hTc⟩, hTx⟩ := hT
      have hsub := image_dualMap_sub n T hTE
      refine ⟨⟨Finset.sdiff_subset, ?_⟩, ?_⟩
      · rw [Finset.card_sdiff_of_subset hsub, card_image_dualMap n T hTE, hTc]
        omega
      · rw [← duality n hn _ Finset.sdiff_subset, Finset.sdiff_sdiff_eq_self hsub,
          image_dualMap_dualMap n T hTE]
        exact hTx
    · intro S hS
      simp only [Finset.coe_filter, Set.mem_ofPred_eq, Finset.mem_powersetCard] at hS ⊢
      obtain ⟨⟨hSE, hSc⟩, hSx⟩ := hS
      refine ⟨⟨image_dualMap_sub n _ Finset.sdiff_subset, ?_⟩, ?_⟩
      · rw [card_image_dualMap n _ Finset.sdiff_subset, Finset.card_sdiff_of_subset hSE, hSc]
      · rw [duality n hn S hSE]
        exact hSx
    · intro T hT
      simp only [Finset.coe_filter, Set.mem_ofPred_eq, Finset.mem_powersetCard] at hT
      have hsub := image_dualMap_sub n T hT.1.1
      simp only
      rw [Finset.sdiff_sdiff_eq_self hsub, image_dualMap_dualMap n T hT.1.1]
    · intro S hS
      simp only [Finset.coe_filter, Set.mem_ofPred_eq, Finset.mem_powersetCard] at hS
      simp only
      rw [image_dualMap_dualMap n _ Finset.sdiff_subset, Finset.sdiff_sdiff_eq_self hS.1.1]
  rw [hcount, Finset.card_filter_add_card_filter_not, Finset.card_powersetCard]

#print axioms dualMap_mem
#print axioms dualMap_invol
#print axioms image_dualMap_dualMap
#print axioms card_image_dualMap
#print axioms image_dualMap_sub
#print axioms duality
#print axioms count_duality

end FairBox

/-- The fair box. Open each channel of a square-grid box with one more column of pores
than rows with chance `p`, independently. Then the chance that water crosses from the
left face to the right face at `p`, plus the same chance at `1 - p`, is exactly one. -/
theorem fair_box_crossing_chance (n : ℕ) (hn : 1 ≤ n) (p : ℝ) (hp0 : 0 ≤ p) (hp1 : p ≤ 1) :
    crossChance n p + crossChance n (1 - p) = 1 := by
  clear hp0 hp1
  unfold crossChance
  have hrefl := Finset.sum_range_reflect
    (fun k => (crossCount n k : ℝ) * (1 - p) ^ k * (1 - (1 - p)) ^ (numChannels n - k))
    (numChannels n + 1)
  calc _ = ∑ j ∈ range (numChannels n + 1),
        p ^ j * (1 - p) ^ (numChannels n - j) * ((numChannels n).choose j : ℝ) := by
        rw [← hrefl, ← Finset.sum_add_distrib]
        apply Finset.sum_congr rfl
        intro j hj
        rw [Finset.mem_range] at hj
        have h1 : numChannels n + 1 - 1 - j = numChannels n - j := by omega
        have h2 : numChannels n - (numChannels n - j) = j := by omega
        simp only [h1, h2, sub_sub_cancel]
        have hc := FairBox.count_duality n hn j (by omega)
        have hc' : (crossCount n j : ℝ) + (crossCount n (numChannels n - j) : ℝ) =
            ((numChannels n).choose j : ℝ) := by
          exact_mod_cast hc
        rw [← hc']
        ring
    _ = (p + (1 - p)) ^ numChannels n := (add_pow p (1 - p) (numChannels n)).symm
    _ = 1 := by simp

/-- The duality count. On the same box, for every `k` from `0` to `E`, the crossing
patterns with `k` open channels and the crossing patterns with `E - k` open channels
together number exactly `C(E, k)`: a crossing path and a blocking wall mirror each other. -/
theorem crossing_count_duality (n : ℕ) (hn : 1 ≤ n) (k : ℕ) (hk : k ≤ numChannels n) :
    crossCount n k + crossCount n (numChannels n - k) = (numChannels n).choose k := by
  exact FairBox.count_duality n hn k hk

/-- The box is crossed exactly half the time at `p = 1/2`, at every size. -/
theorem fair_box_at_one_half (n : ℕ) (hn : 1 ≤ n) :
    crossChance n (1 / 2) = 1 / 2 := by
  have h := fair_box_crossing_chance n hn (1 / 2) (by norm_num) (by norm_num)
  norm_num at h ⊢
  linarith

-- The 4-by-3 box: 9 channels across and 4 up-down, 13 in all, so 2^13 = 8192 patterns.
example : numChannels 3 = 13 := by decide
example : 9 + 4 = 13 ∧ 2 ^ 13 = 8192 := by norm_num

-- The card's counts a_0, ..., a_13 for the 4-by-3 box obey the duality for every k,
-- and add up to 4096, exactly half of the 8192 patterns.
example :
    let a : List ℕ := [0, 0, 0, 3, 38, 209, 627, 1089, 1078, 677, 283, 78, 13, 1]
    (∀ k : Fin 14, a.getD k 0 + a.getD (13 - k) 0 = Nat.choose 13 k) ∧
      a.sum = 4096 ∧ 2 * 4096 = 2 ^ 13 := by
  decide

-- The two duality lines worked by hand on the card.
example : 3 + 283 = Nat.choose 13 3 ∧ Nat.choose 13 3 = 286 := by decide
example : 627 + 1089 = Nat.choose 13 6 ∧ Nat.choose 13 6 = 1716 := by decide

-- The wrong shape: the 3-by-3 box has 8 channels and 172 of its 256 patterns cross, not half.
example : 2 ^ 8 = 256 ∧ 2 * 172 ≠ 256 := by decide

#print axioms fair_box_crossing_chance
#print axioms crossing_count_duality
#print axioms fair_box_at_one_half
