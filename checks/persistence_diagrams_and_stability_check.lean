-- Persistence diagram and stability: if two price feeds differ by at most δ on every day, then the pools of one feed that last from level s to level t number at most the pools of the other that last from s + δ to t - δ (the counting half of the stability theorem), a bar's distance from the diagonal is half its length, and the feeds' sublevel shapes interleave.
import Mathlib.Combinatorics.SimpleGraph.Hasse
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Connected
import Mathlib.Data.Set.Card
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Tactic.NormNum

namespace PersistenceStability

open SimpleGraph

variable {n : ℕ}

/-- The days under water at level `t`: those whose close is at most `t`. -/
def under (f : Fin n → ℝ) (t : ℝ) : Set (Fin n) :=
  {i | f i ≤ t}

/-- The shape `K_t` of a feed `f` with `n` daily closes: the days with close at most `t`,
neighbouring days linked when both are under water (the path graph on the days, restricted). -/
def K (f : Fin n → ℝ) (t : ℝ) : SimpleGraph (under f t) :=
  (pathGraph n).induce (under f t)

/-- The rank of the map on `H_0` from level `s` to level `t`, read concretely on pools: the number
of pools of `K_t` that contain at least one day already under water at level `s`. By the
fundamental fact of persistence it counts the bars born by `s` and still alive at `t`. -/
noncomputable def rank (f : Fin n → ℝ) (s t : ℝ) : ℕ :=
  Set.ncard {c : (K f t).ConnectedComponent |
    ∃ v : under f t, f v ≤ s ∧ (K f t).connectedComponentMk v = c}

/-- The counting half of the stability theorem (Step 3): if the two feeds differ by at most `δ`
on every day and `s + δ ≤ t - δ`, then the bars of `f` covering the levels `s` to `t` number at
most the bars of `g` covering `s + δ` to `t - δ`. -/
theorem rank_le_rank_of_gap_le (f g : Fin n → ℝ) (δ s t : ℝ)
    (hgap : ∀ i, |f i - g i| ≤ δ) (hst : s + δ ≤ t - δ) :
    rank f s t ≤ rank g (s + δ) (t - δ) := by
  have hsub : ∀ v : Fin n, g v ≤ t - δ → f v ≤ t := by
    intro v hv
    have := (abs_sub_le_iff.mp (hgap v)).1
    linarith
  let φ : K g (t - δ) →g K f t :=
    { toFun := fun v => ⟨v.1, hsub v.1 v.2⟩
      map_rel' := fun h => h }
  unfold rank
  refine le_trans (Set.ncard_le_ncard (t := (ConnectedComponent.map φ) ''
    {c : (K g (t - δ)).ConnectedComponent |
      ∃ v : under g (t - δ), g v ≤ s + δ ∧ (K g (t - δ)).connectedComponentMk v = c}) ?_)
    Set.ncard_image_le
  rintro c ⟨v, hv, rfl⟩
  have hg : g v ≤ s + δ := by
    have := (abs_sub_le_iff.mp (hgap v)).2
    linarith
  have hw : (v : Fin n) ∈ under g (t - δ) := by
    show g v ≤ t - δ
    linarith
  refine ⟨(K g (t - δ)).connectedComponentMk ⟨v.1, hw⟩, ⟨⟨v.1, hw⟩, hg, rfl⟩, ?_⟩
  rw [ConnectedComponent.map_mk]
  rfl

/-- A point's distance from the diagonal is half its persistence (Step 1): the worst-case
distance from `(b, d)` to the nearest diagonal point `(x, x)` is `(d - b) / 2`. -/
theorem dist_to_diagonal_eq_half_persistence (b d : ℝ) (hbd : b ≤ d) :
    (⨅ x : ℝ, max |b - x| |d - x|) = (d - b) / 2 := by
  have hlow : ∀ x : ℝ, (d - b) / 2 ≤ max |b - x| |d - x| := by
    intro x
    have h1 := le_max_left |b - x| |d - x|
    have h2 := le_max_right |b - x| |d - x|
    have h3 := neg_abs_le (b - x)
    have h4 := le_abs_self (d - x)
    linarith
  apply le_antisymm
  · have hmid : max |b - (b + d) / 2| |d - (b + d) / 2| = (d - b) / 2 := by
      have e1 : b - (b + d) / 2 = -((d - b) / 2) := by ring
      have e2 : d - (b + d) / 2 = (d - b) / 2 := by ring
      have hnn : 0 ≤ (d - b) / 2 := by linarith
      rw [e1, e2, abs_neg, abs_of_nonneg hnn, max_self]
    rw [← hmid]
    exact ciInf_le ⟨(d - b) / 2, by rintro _ ⟨x, rfl⟩; exact hlow x⟩ ((b + d) / 2)
  · exact le_ciInf hlow

/-- The two families of shapes interleave (Steps 0 and 2): if the feeds differ by at most `δ`
on every day, then `K^f_t ⊆ K^g_{t+δ} ⊆ K^f_{t+2δ}`, read on the days under water (a shape
is the path graph restricted to its days, so its links carry over with them). -/
theorem under_interleave (f g : Fin n → ℝ) (δ t : ℝ) (hgap : ∀ i, |f i - g i| ≤ δ) :
    under f t ⊆ under g (t + δ) ∧ under g (t + δ) ⊆ under f (t + 2 * δ) := by
  constructor
  · intro i hi
    have := (abs_sub_le_iff.mp (hgap i)).2
    show g i ≤ t + δ
    have hi' : f i ≤ t := hi
    linarith
  · intro i hi
    have := (abs_sub_le_iff.mp (hgap i)).1
    show f i ≤ t + 2 * δ
    have hi' : g i ≤ t + δ := hi
    linarith

/-! The card's worked numbers, in whole cents. -/

/-- Feed 1's sixteen closes, in cents. -/
def feed1 : List ℤ :=
  [9000, 9240, 9190, 9510, 9730, 9680, 10150, 10400,
   9920, 9600, 9870, 9810, 10190, 10360, 10320, 10500]

/-- Feed 2's sixteen closes, in cents. -/
def feed2 : List ℤ :=
  [9011, 9266, 9212, 9497, 9738, 9670, 10143, 10387,
   9923, 9605, 9848, 9827, 10218, 10360, 10346, 10470]

-- The largest daily gap between the feeds is 30 cents (day 15: 105.00 - 104.70).
example : (List.zipWith (fun a b => |a - b|) feed1 feed2).max? = some 30 := by decide

-- The big dip (96.00, 104.00) sits 400 cents from the diagonal; the small dips 25, 25, 30, 20.
example : ((10400 : ℚ) - 9600) / 2 = 400 := by norm_num
example : ((9240 : ℚ) - 9190) / 2 = 25 ∧ ((9730 : ℚ) - 9680) / 2 = 25 ∧
    ((9870 : ℚ) - 9810) / 2 = 30 ∧ ((10360 : ℚ) - 10320) / 2 = 20 := by norm_num

-- Bar lengths 50, 800, 50, 60, 40 cents: five longer than 30, one longer than 60.
example : [50, 800, 50, 60, 40].countP (fun x => decide (30 < x)) = 5 := by decide
example : [50, 800, 50, 60, 40].countP (fun x => decide (60 < x)) = 1 := by decide

-- The matching's costs in cents: big dips 13; the three small pairs 26, 10, 22; the two dips
-- near 103 each to the diagonal at 20 and 7; the never-ending bars 11. Worst cost 26, under 30.
example : max |(9605 : ℤ) - 9600| |(10387 : ℤ) - 10400| = 13 := by decide
example : max |(9212 : ℤ) - 9190| |(9266 : ℤ) - 9240| = 26 := by decide
example : max |(9670 : ℤ) - 9680| |(9738 : ℤ) - 9730| = 10 := by decide
example : max |(9827 : ℤ) - 9810| |(9848 : ℤ) - 9870| = 22 := by decide
example : ((10360 : ℚ) - 10346) / 2 = 7 ∧ |(9011 : ℤ) - 9000| = 11 := by norm_num
example : [13, 26, 10, 22, 20, 7, 11].max? = some (26 : ℤ) ∧ (26 : ℤ) ≤ 30 := by decide

#print axioms rank_le_rank_of_gap_le
#print axioms dist_to_diagonal_eq_half_persistence
#print axioms under_interleave

end PersistenceStability
