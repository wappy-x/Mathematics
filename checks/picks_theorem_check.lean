-- Pick's theorem, the counting half: each straight run between grid points holds as many grid points past its start as the gcd of its two steps, and a fence that never crosses itself holds the sum of those counts. The area formula A = I + B/2 - 1 itself is not stated here.
import Mathlib.Analysis.Convex.Segment
import Mathlib.Topology.Connected.Basic
import Mathlib.Topology.Bornology.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Data.Set.Card
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum

/-- A grid point (x, y), with whole-number coordinates, as a point of the plane. -/
def toR (z : ℤ × ℤ) : ℝ × ℝ := ((z.1 : ℝ), (z.2 : ℝ))

/-- The fence with corners `v 0, v 1, …, v (n-1)` in order: the union of its straight runs
from each corner to the next, the last run going back to `v 0`. -/
def fence {n : ℕ} [NeZero n] (v : Fin n → ℝ × ℝ) : Set (ℝ × ℝ) :=
  ⋃ i : Fin n, segment ℝ (v i) (v (i + 1))

/-- The fence does not cross itself: two different runs share no point, except that a run and
the next one share the corner between them. -/
def NoSelfCrossing {n : ℕ} [NeZero n] (v : Fin n → ℝ × ℝ) : Prop :=
  ∀ i j : Fin n, i ≠ j →
    segment ℝ (v i) (v (i + 1)) ∩ segment ℝ (v j) (v (j + 1)) ⊆
      {x | (j = i + 1 ∧ x = v j) ∨ (i = j + 1 ∧ x = v i)}

/-- One straight run from grid point p to grid point q, stepping Δx east and Δy north, holds
gcd(|Δx|, |Δy|) grid points, counting the point it ends at but not the one it starts from. -/
theorem edge_grid_points_eq_gcd (p q : ℤ × ℤ) :
    {z : ℤ × ℤ | toR z ∈ segment ℝ (toR p) (toR q) ∧ z ≠ p}.ncard =
      Nat.gcd (q.1 - p.1).natAbs (q.2 - p.2).natAbs := by
  rw [segment_eq_image']
  have hgi : ((Int.gcd (q.1 - p.1) (q.2 - p.2) : ℕ) : ℤ) =
      (Nat.gcd (q.1 - p.1).natAbs (q.2 - p.2).natAbs : ℤ) := rfl
  generalize hg : Nat.gcd (q.1 - p.1).natAbs (q.2 - p.2).natAbs = g at hgi ⊢
  have key : ∀ z : ℤ × ℤ, (toR z ∈ (fun θ : ℝ => toR p + θ • (toR q - toR p)) '' Set.Icc 0 1) ↔
      ∃ t : ℝ, 0 ≤ t ∧ t ≤ 1 ∧ ((z.1 - p.1 : ℤ) : ℝ) = t * ((q.1 - p.1 : ℤ) : ℝ) ∧
        ((z.2 - p.2 : ℤ) : ℝ) = t * ((q.2 - p.2 : ℤ) : ℝ) := by
    intro z
    simp only [Set.mem_image, Set.mem_Icc, toR, Prod.ext_iff, Prod.fst_add, Prod.snd_add,
      Prod.smul_fst, Prod.smul_snd, Prod.fst_sub, Prod.snd_sub, smul_eq_mul]
    push_cast
    constructor
    · rintro ⟨t, ⟨h0, h1⟩, e1, e2⟩; exact ⟨t, h0, h1, by linarith, by linarith⟩
    · rintro ⟨t, h0, h1, e1, e2⟩; exact ⟨t, ⟨h0, h1⟩, by linarith, by linarith⟩
  rcases Nat.eq_zero_or_pos g with h0 | hpos
  · subst h0
    have := Int.gcd_eq_zero_iff.mp (by exact_mod_cast hgi)
    convert Set.ncard_empty (ℤ × ℤ) using 2
    ext z
    simp only [Set.mem_setOf_eq, key, Set.mem_empty_iff_false, iff_false, not_and]
    rintro ⟨t, -, -, e1, e2⟩ hne
    rw [this.1] at e1; rw [this.2] at e2
    simp only [Int.cast_zero, mul_zero] at e1 e2
    apply hne
    have h1 : z.1 - p.1 = 0 := by exact_mod_cast e1
    have h2 : z.2 - p.2 = 0 := by exact_mod_cast e2
    ext <;> omega
  · set a := q.1 - p.1 with ha
    set b := q.2 - p.2 with hb
    have hda : (g : ℤ) ∣ a := hgi ▸ Int.gcd_dvd_left a b
    have hdb : (g : ℤ) ∣ b := hgi ▸ Int.gcd_dvd_right a b
    obtain ⟨a', ha'⟩ := hda
    obtain ⟨b', hb'⟩ := hdb
    have hbez : (g : ℤ) = a * Int.gcdA a b + b * Int.gcdB a b := hgi ▸ Int.gcd_eq_gcd_ab a b
    have hgpos : (0 : ℤ) < g := by exact_mod_cast hpos
    have hne : a' ≠ 0 ∨ b' ≠ 0 := by
      by_contra h
      rw [not_or, not_not, not_not] at h
      rw [ha', hb', h.1, h.2] at hbez
      simp at hbez
      omega
    let f : ℤ → ℤ × ℤ := fun k => (p.1 + k * a', p.2 + k * b')
    have hset : {z : ℤ × ℤ | toR z ∈ (fun θ : ℝ => toR p + θ • (toR q - toR p)) '' Set.Icc 0 1 ∧
        z ≠ p} = ((Finset.Icc (1 : ℤ) g).image f : Set (ℤ × ℤ)) := by
      ext z
      simp only [Set.mem_setOf_eq, key, Finset.coe_image, Finset.coe_Icc, Set.mem_image,
        Set.mem_Icc]
      constructor
      · rintro ⟨⟨t, h0, h1, e1, e2⟩, hz⟩
        set m := (z.1 - p.1) * Int.gcdA a b + (z.2 - p.2) * Int.gcdB a b with hm
        have hmr : (m : ℝ) = t * g := by
          have : ((g : ℤ) : ℝ) = (a : ℝ) * Int.gcdA a b + b * Int.gcdB a b := by
            exact_mod_cast hbez
          push_cast at this
          rw [hm]; push_cast
          rw [this]
          push_cast at e1 e2
          rw [e1, e2]; ring
        have hgr : (0 : ℝ) < g := by exact_mod_cast hpos
        have em1 : z.1 - p.1 = m * a' := by
          have : ((z.1 - p.1 : ℤ) : ℝ) = ((m * a' : ℤ) : ℝ) := by
            rw [e1, ha']; push_cast; rw [hmr]; ring
          exact_mod_cast this
        have em2 : z.2 - p.2 = m * b' := by
          have : ((z.2 - p.2 : ℤ) : ℝ) = ((m * b' : ℤ) : ℝ) := by
            rw [e2, hb']; push_cast; rw [hmr]; ring
          exact_mod_cast this
        have hm0 : (0 : ℝ) ≤ m := by rw [hmr]; positivity
        have hm1 : (m : ℝ) ≤ g := by rw [hmr]; nlinarith
        have hm0' : 0 ≤ m := by exact_mod_cast hm0
        have hm1' : m ≤ g := by exact_mod_cast hm1
        have hmne : m ≠ 0 := by
          rintro h0
          apply hz
          rw [h0] at em1 em2
          ext <;> simp at em1 em2 <;> omega
        refine ⟨m, ⟨by omega, hm1'⟩, ?_⟩
        ext <;> simp only [f] <;> linarith
      · rintro ⟨k, ⟨h1, h2⟩, rfl⟩
        refine ⟨⟨(k : ℝ) / g, by positivity, ?_, ?_, ?_⟩, ?_⟩
        · rw [div_le_one (by exact_mod_cast hpos)]; exact_mod_cast h2
        · simp only [f, ha']; push_cast; field_simp; ring
        · simp only [f, hb']; push_cast; field_simp; ring
        · intro h
          simp only [f, Prod.ext_iff] at h
          have k1 : k * a' = 0 := by omega
          have k2 : k * b' = 0 := by omega
          rcases mul_eq_zero.mp k1 with hk | hk
          · omega
          rcases mul_eq_zero.mp k2 with hk' | hk'
          · omega
          tauto
    have hinj : Function.Injective f := by
      intro k l hkl
      simp only [f, Prod.ext_iff] at hkl
      rcases hne with h | h
      · exact mul_right_cancel₀ h (by linarith)
      · exact mul_right_cancel₀ h (by linarith)
    rw [hset, Set.ncard_coe_finset, Finset.card_image_of_injective _ hinj, Int.card_Icc]
    simp

/-- For a grid polygon whose corners differ from their neighbours and whose fence never crosses
itself, the number of grid points on the fence is the sum, over the runs, of the gcd of each
run's two steps. -/
theorem fence_grid_points_eq_sum_gcd {n : ℕ} [NeZero n] (hn : 3 ≤ n) (v : Fin n → ℤ × ℤ)
    (hcorners : ∀ i : Fin n, v (i + 1) ≠ v i)
    (hsimple : NoSelfCrossing (fun i => toR (v i))) :
    {z : ℤ × ℤ | toR z ∈ fence (fun i => toR (v i))}.ncard =
      ∑ i : Fin n, Nat.gcd ((v (i + 1)).1 - (v i).1).natAbs ((v (i + 1)).2 - (v i).2).natAbs := by
  classical
  set S : Fin n → Set (ℤ × ℤ) := fun i =>
    {z : ℤ × ℤ | toR z ∈ segment ℝ (toR (v i)) (toR (v (i + 1))) ∧ z ≠ v i} with hS
  have hinj : ∀ z w : ℤ × ℤ, toR z = toR w → z = w := by
    intro z w h
    simp only [toR, Prod.ext_iff, Int.cast_inj] at h
    exact Prod.ext h.1 h.2
  have hfin : ∀ i, (S i).Finite := by
    intro i
    apply Set.finite_of_ncard_ne_zero
    rw [hS]
    dsimp only
    rw [edge_grid_points_eq_gcd]
    intro h
    rw [Nat.gcd_eq_zero_iff] at h
    apply hcorners i
    ext <;> omega
  let T : Fin n → Finset (ℤ × ℤ) := fun i => (hfin i).toFinset
  have hcover : {z : ℤ × ℤ | toR z ∈ fence (fun i => toR (v i))} =
      ↑(Finset.univ.biUnion T) := by
    ext z
    simp only [Set.mem_setOf_eq, fence, Set.mem_iUnion, Finset.coe_biUnion, Finset.coe_univ,
      Set.mem_univ, T, Set.Finite.coe_toFinset, hS]
    constructor
    · rintro ⟨i, hi⟩
      by_cases hz : z = v i
      · refine ⟨i - 1, trivial, ?_, ?_⟩
        · rw [sub_add_cancel, hz]; exact right_mem_segment ℝ _ _
        · have := hcorners (i - 1); rw [sub_add_cancel] at this; rw [hz]; exact this
      · exact ⟨i, trivial, hi, hz⟩
    · rintro ⟨i, -, hi, -⟩; exact ⟨i, hi⟩
  have hdisj : ((Finset.univ : Finset (Fin n)) : Set (Fin n)).PairwiseDisjoint T := by
    intro i _ j _ hij
    rw [Function.onFun, Finset.disjoint_left]
    intro z hzi hzj
    simp only [T, Set.Finite.mem_toFinset, hS, Set.mem_setOf_eq] at hzi hzj
    rcases hsimple i j hij ⟨hzi.1, hzj.1⟩ with ⟨-, h⟩ | ⟨-, h⟩
    · exact hzj.2 (hinj _ _ h)
    · exact hzi.2 (hinj _ _ h)
  rw [hcover, Set.ncard_coe_finset, Finset.card_biUnion hdisj]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [← edge_grid_points_eq_gcd]
  exact (Set.ncard_eq_toFinset_card _ (hfin i)).symm

/-! ### The card's worked numbers -/

/-- Twice the turn of c seen from the walk a → b, on whole numbers: positive on the left. -/
def turnZ (a b c : ℤ × ℤ) : ℤ := (b.1 - a.1) * (c.2 - a.2) - (b.2 - a.2) * (c.1 - a.1)

/-- The house-shaped plot, corners anticlockwise. -/
def house : List (ℤ × ℤ) := [(0, 0), (4, 0), (4, 3), (2, 5), (0, 3)]

/-- The plot's runs, each from one corner to the next. -/
def houseRuns : List ((ℤ × ℤ) × (ℤ × ℤ)) :=
  [((0, 0), (4, 0)), ((4, 0), (4, 3)), ((4, 3), (2, 5)), ((2, 5), (0, 3)), ((0, 3), (0, 0))]

-- Edge steps (4, 0), (0, 3), (-2, 2), (-2, -2), (0, -3): divisors 4, 3, 2, 2, 3, so B = 14.
example : Nat.gcd 4 0 + Nat.gcd 0 3 + Nat.gcd 2 2 + Nat.gcd 2 2 + Nat.gcd 0 3 = 14 := by decide

-- The plot is convex, so a grid point is strictly inside when it is strictly left of every run,
-- and on the fence when it is left of or on every run and on at least one: 10 inside, 14 on it.
example : ((Finset.Icc (0 : ℤ) 4 ×ˢ Finset.Icc (0 : ℤ) 5).filter
    (fun z => houseRuns.all (fun r => decide (0 < turnZ r.1 r.2 z)))).card = 10 := by decide
example : ((Finset.Icc (0 : ℤ) 4 ×ˢ Finset.Icc (0 : ℤ) 5).filter
    (fun z => houseRuns.all (fun r => decide (0 ≤ turnZ r.1 r.2 z)) ∧
      houseRuns.any (fun r => decide (turnZ r.1 r.2 z = 0)))).card = 14 := by decide

-- Pick's area 10 + 14/2 - 1 = 16, and the shoelace sum gives twice the area as 32.
example : (10 : ℚ) + 14 / 2 - 1 = 16 := by norm_num
example : 0 * 0 - 0 * 4 + (4 * 3 - 0 * 4) + (4 * 5 - 3 * 2) + (2 * 3 - 5 * 0) + (0 * 0 - 3 * 0)
    = (32 : ℤ) := by norm_num

-- 1,600 square metres at 100 m² a square; 10 trees inside from the corners alone: 16 - 14/2 + 1.
example : (16 : ℕ) * 100 = 1600 := by norm_num
example : (16 : ℚ) - 14 / 2 + 1 = 10 := by norm_num

-- Gluing: the 4 by 3 box scores 6 + 7 - 1 = 12, the roof 1 + 4 - 1 = 4; the cut holds 5 points,
-- so I = 6 + 1 + 3 = 10 and B = 14 + 8 - 2 × 3 - 2 = 14.
example : (4 - 1) * (3 - 1) = 6 ∧ 2 * 4 + 2 * 3 = 14 ∧ 6 + 14 / 2 - 1 = 12 := by decide
example : 1 + 8 / 2 - 1 = 4 ∧ 4 * 2 - 2 - 2 = 4 ∧ 12 + 4 = 16 := by decide
example : 6 + 1 + (5 - 2) = 10 ∧ 14 + 8 - 2 * (5 - 2) - 2 = 14 := by decide

-- The survey field A to F: B = 8 + 1 + 2 + 2 + 1 + 5 = 19, I = 33, area 33 + 19/2 - 1 = 41.5,
-- and the shoelace sum gives twice the area as 83.
example : Nat.gcd 8 0 + Nat.gcd 1 5 + Nat.gcd 4 2 + Nat.gcd 2 4 + Nat.gcd 3 2 + Nat.gcd 0 5
    = 19 := by decide
example : (33 : ℚ) + 19 / 2 - 1 = 83 / 2 := by norm_num
example : (2 * 1 - 1 * 10) + (10 * 6 - 1 * 11) + (11 * 4 - 6 * 7) + (7 * 8 - 4 * 5)
    + (5 * 6 - 8 * 2) + (2 * 1 - 6 * 2) = (83 : ℤ) := by norm_num

-- The house doubled: B = 28, I = 51, area 51 + 28/2 - 1 = 64 = 4 × 16.
example : Nat.gcd 8 0 + Nat.gcd 0 6 + Nat.gcd 4 4 + Nat.gcd 4 4 + Nat.gcd 0 6 = 28 := by decide
example : (51 : ℚ) + 28 / 2 - 1 = 64 ∧ (64 : ℚ) = 4 * 16 := by norm_num

-- The usual mistakes: -1 left out gives 17, corners only as B gives 11.5, gcd + 1 per edge 18.5.
example : (10 : ℚ) + 14 / 2 = 17 ∧ (10 : ℚ) + 5 / 2 - 1 = 23 / 2 ∧
    (10 : ℚ) + (14 + 5) / 2 - 1 = 37 / 2 := by norm_num

#print axioms edge_grid_points_eq_gcd
#print axioms fence_grid_points_eq_sum_gcd
