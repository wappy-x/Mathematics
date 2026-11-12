-- Slater's condition: for a convex problem with one inequality and a strictly feasible plan, the best price bound equals the best cost and is reached by some price, a zero gap certifies a plan, and the card's open-or-shut valves keep a gap of 100 - 89 = 11 kW.
import Mathlib.Analysis.Convex.Function
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Order.Bounds.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum

open Finset

namespace SlaterCondition

/-! ## The general problem

Plans live in a real vector space `E`; `X` is the set of allowed plans, `f0` the cost and
`f1` the one inequality (`f1 x ≤ 0` means the plan is feasible). -/

variable {E : Type*} [AddCommGroup E] [Module ℝ E]

/-- The best cost `p⋆`: the infimum of the cost over the allowed plans with `f1 x ≤ 0`. -/
noncomputable def pStar (X : Set E) (f0 f1 : E → ℝ) : ℝ :=
  sInf (f0 '' {x | x ∈ X ∧ f1 x ≤ 0})

/-- The priced costs at price `lam`: the values `f0 x + lam * f1 x` over all allowed plans.
The dual function `q(lam)` is their greatest lower bound. -/
def priced (X : Set E) (f0 f1 : E → ℝ) (lam : ℝ) : Set ℝ :=
  (fun x => f0 x + lam * f1 x) '' X

/-- The bounds that prices give: every value `q(lam)` with `lam ≥ 0` and `q(lam)` finite.
The best bound `d⋆` is the largest of them. -/
def dualValues (X : Set E) (f0 f1 : E → ℝ) : Set ℝ :=
  {v | ∃ lam : ℝ, 0 ≤ lam ∧ IsGLB (priced X f0 f1 lam) v}

omit [AddCommGroup E] [Module ℝ E] in
/-- Helper: a feasible plan's cost bounds the best cost `p⋆` from above. -/
theorem pStar_le_of_feasible (X : Set E) (f0 f1 : E → ℝ)
    (hfinite : BddBelow (f0 '' {x | x ∈ X ∧ f1 x ≤ 0})) (x : E) (hx : x ∈ X)
    (hfeas : f1 x ≤ 0) : pStar X f0 f1 ≤ f0 x :=
  csInf_le hfinite ⟨x, ⟨hx, hfeas⟩, rfl⟩

#print axioms pStar_le_of_feasible

/-- Helper: a lower bound on the priced costs at a price `lam ≥ 0`, when some plan is
feasible, is at most the best cost. -/
theorem le_pStar_of_lowerBound (X : Set E) (f0 f1 : E → ℝ) (lam b : ℝ) (hlam : 0 ≤ lam)
    (hb : b ∈ lowerBounds (priced X f0 f1 lam)) (x : E) (hx : x ∈ X) (hfeas : f1 x ≤ 0) :
    b ≤ pStar X f0 f1 := by
  have hne : (f0 '' {x | x ∈ X ∧ f1 x ≤ 0}).Nonempty := ⟨f0 x, x, ⟨hx, hfeas⟩, rfl⟩
  apply le_csInf hne
  rintro _ ⟨y, ⟨hy, hyf⟩, rfl⟩
  have h1 := hb ⟨y, hy, rfl⟩
  have h2 : lam * f1 y ≤ 0 := mul_nonpos_of_nonneg_of_nonpos hlam hyf
  simp only at h1
  linarith

#print axioms le_pStar_of_lowerBound

/-- Helper (the convexity step): mixing a plan that breaks the rule with one that meets it
with room to spare gives a plan exactly on the rule, so the two price ratios are ordered. -/
theorem slope_le (X : Set E) (f0 f1 : E → ℝ)
    (hf0 : ConvexOn ℝ X f0) (hf1 : ConvexOn ℝ X f1)
    (hfinite : BddBelow (f0 '' {x | x ∈ X ∧ f1 x ≤ 0}))
    (x y : E) (hx : x ∈ X) (hy : y ∈ X) (hfx : 0 < f1 x) (hfy : f1 y < 0) :
    (pStar X f0 f1 - f0 x) / f1 x ≤ (f0 y - pStar X f0 f1) / (-f1 y) := by
  set a := f1 x with ha
  set b := -f1 y with hb
  have hb0 : 0 < b := by linarith
  have hab : 0 < a + b := by linarith
  set t := b / (a + b) with ht
  set u := a / (a + b) with hu
  have ht0 : 0 ≤ t := div_nonneg hb0.le hab.le
  have hu0 : 0 ≤ u := div_nonneg (le_of_lt hfx) hab.le
  have htu : t + u = 1 := by rw [ht, hu, ← add_div]; field_simp; ring
  have hz : t • x + u • y ∈ X := hf0.1 hx hy ht0 hu0 htu
  have h1 := hf1.2 hx hy ht0 hu0 htu
  have h0 := hf0.2 hx hy ht0 hu0 htu
  simp only [smul_eq_mul] at h1 h0
  have hzero : t * f1 x + u * f1 y = 0 := by
    rw [ht, hu]; field_simp; rw [← ha]; linarith
  have hp := pStar_le_of_feasible X f0 f1 hfinite _ hz (by linarith)
  have key : pStar X f0 f1 ≤ t * f0 x + u * f0 y := le_trans hp h0
  rw [div_le_div_iff₀ hfx hb0]
  have : pStar X f0 f1 * (a + b) ≤ b * f0 x + a * f0 y := by
    have e1 : t * (a + b) = b := by rw [ht]; field_simp
    have e2 : u * (a + b) = a := by rw [hu]; field_simp
    have := mul_le_mul_of_nonneg_right key hab.le
    calc pStar X f0 f1 * (a + b) ≤ (t * f0 x + u * f0 y) * (a + b) := this
      _ = (t * (a + b)) * f0 x + (u * (a + b)) * f0 y := by ring
      _ = b * f0 x + a * f0 y := by rw [e1, e2]
  nlinarith

#print axioms slope_le

/-- Slater's theorem with one inequality (the card's main claim): if the allowed plans `X`
form a convex set, the cost `f0` and the inequality `f1` are convex on it, some allowed plan
has `f1 < 0` (meets the rule with room to spare), and the best cost `p⋆` is finite, then the
best price bound equals the best cost, `d⋆ = p⋆`, and some price `lam⋆ ≥ 0` reaches it,
`q(lam⋆) = p⋆`. -/
theorem slater_zero_duality_gap (X : Set E) (f0 f1 : E → ℝ) (hX : Convex ℝ X)
    (hf0 : ConvexOn ℝ X f0) (hf1 : ConvexOn ℝ X f1)
    (hslater : ∃ x ∈ X, f1 x < 0)
    (hfinite : BddBelow (f0 '' {x | x ∈ X ∧ f1 x ≤ 0})) :
    IsGreatest (dualValues X f0 f1) (pStar X f0 f1) := by
  obtain ⟨x0, hx0, hx0f⟩ := hslater
  set p := pStar X f0 f1 with hp
  set T : Set ℝ := (fun y => (f0 y - p) / (-f1 y)) '' {y | y ∈ X ∧ f1 y < 0} with hT
  have hTne : T.Nonempty := ⟨_, x0, ⟨hx0, hx0f⟩, rfl⟩
  have hTnn : ∀ v ∈ T, 0 ≤ v := by
    rintro _ ⟨y, ⟨hy, hyf⟩, rfl⟩
    have := pStar_le_of_feasible X f0 f1 hfinite y hy hyf.le
    exact div_nonneg (by linarith) (by linarith)
  have hTbdd : BddBelow T := ⟨0, hTnn⟩
  set lam := sInf T with hlam
  have hlam0 : 0 ≤ lam := le_csInf hTne hTnn
  have hlow : p ∈ lowerBounds (priced X f0 f1 lam) := by
    rintro _ ⟨x, hx, rfl⟩
    show p ≤ f0 x + lam * f1 x
    rcases lt_trichotomy (f1 x) 0 with h | h | h
    · have hle : lam ≤ (f0 x - p) / (-f1 x) := csInf_le hTbdd ⟨x, ⟨hx, h⟩, rfl⟩
      have hpos : 0 < -f1 x := by linarith
      rw [le_div_iff₀ hpos] at hle
      linarith
    · have := pStar_le_of_feasible X f0 f1 hfinite x hx h.le
      rw [h]; linarith
    · have hle : (p - f0 x) / f1 x ≤ lam := by
        apply le_csInf hTne
        rintro _ ⟨y, ⟨hy, hyf⟩, rfl⟩
        exact slope_le X f0 f1 hf0 hf1 hfinite x y hx hy h hyf
      rw [div_le_iff₀ h] at hle
      linarith
  refine ⟨⟨lam, hlam0, hlow, ?_⟩, ?_⟩
  · intro b hb
    exact le_pStar_of_lowerBound X f0 f1 lam b hlam0 hb x0 hx0 hx0f.le
  · rintro v ⟨l, hl, hv⟩
    exact le_pStar_of_lowerBound X f0 f1 l v hl hv.1 x0 hx0 hx0f.le

/-- The stopping certificate (weak duality, no convexity needed): if a plan `x` is allowed
and meets the rule, `q` is the bound `q(lam)` proved by a price `lam ≥ 0`, and the plan's
cost is within `ε` of that bound, then the plan's cost is within `ε` of the best cost. -/
theorem gap_certifies_plan (X : Set E) (f0 f1 : E → ℝ) (lam q ε : ℝ) (hlam : 0 ≤ lam)
    (hq : IsGLB (priced X f0 f1 lam) q) (x : E) (hx : x ∈ X) (hfeas : f1 x ≤ 0)
    (hgap : f0 x - q ≤ ε) :
    f0 x - pStar X f0 f1 ≤ ε := by
  have := le_pStar_of_lowerBound X f0 f1 lam q hlam hq.1 x hx hfeas
  linarith

/-! ## The valves

Main `i` delivers `flow i` L/s when open and its pump draws `power i` kW: A 60 L/s for
45 kW, B 50 L/s for 55 kW, C 45 L/s for 60 kW. Demand is 100 L/s. A valve pattern is the
set of mains left open. -/

/-- Flow of each main when open, L/s (A, B, C). -/
def flow : Fin 3 → ℕ := ![60, 50, 45]

/-- Pump power of each main when open, kW (A, B, C). -/
def power : Fin 3 → ℕ := ![45, 55, 60]

/-- The valves' dual function from the card: `q(lam) = lam * D + Σ min(0, c_i - lam * a_i)`
with `D = 100`. -/
noncomputable def valveQ (lam : ℝ) : ℝ :=
  lam * 100 + min 0 (45 - lam * 60) + min 0 (55 - lam * 50) + min 0 (60 - lam * 45)

/-- The valves keep a duality gap: the cheapest open-or-shut pattern that delivers at least
100 L/s draws 100 kW, while the best bound any price `lam ≥ 0` proves is 89 kW. -/
theorem valve_duality_gap :
    IsLeast {c | ∃ s : Finset (Fin 3), 100 ≤ ∑ i ∈ s, flow i ∧ c = ∑ i ∈ s, power i} 100 ∧
    IsGreatest {v | ∃ lam : ℝ, 0 ≤ lam ∧ v = valveQ lam} 89 := by
  refine ⟨⟨⟨{0, 1}, by decide, by decide⟩, ?_⟩, ⟨⟨11 / 10, by norm_num, by norm_num [valveQ]⟩, ?_⟩⟩
  · rintro c ⟨s, hs, rfl⟩
    revert s
    decide
  · rintro v ⟨lam, hl, rfl⟩
    unfold valveQ
    have hA1 := min_le_left (0 : ℝ) (45 - lam * 60)
    have hA2 := min_le_right (0 : ℝ) (45 - lam * 60)
    have hB1 := min_le_left (0 : ℝ) (55 - lam * 50)
    have hB2 := min_le_right (0 : ℝ) (55 - lam * 50)
    have hC1 := min_le_left (0 : ℝ) (60 - lam * 45)
    rcases le_total lam (11 / 10) with h | h <;> linarith

/-! ## The card's worked numbers -/

-- Opening A and B gives 110 L/s for 100 kW.
example : (∑ i ∈ ({0, 1} : Finset (Fin 3)), flow i) = 110 ∧
    (∑ i ∈ ({0, 1} : Finset (Fin 3)), power i) = 100 := by decide

-- Listing all eight patterns: every pattern that meets 100 L/s draws at least 100 kW.
example : ∀ s : Finset (Fin 3), 100 ≤ ∑ i ∈ s, flow i → 100 ≤ ∑ i ∈ s, power i := by decide

-- All three valves open beat demand by 55 L/s: the valves have a strictly feasible plan.
example : (100 : ℤ) - (60 + 50 + 45) = -55 := by norm_num

-- The best price is B's kW per L/s, 55 / 50 = 1.1, and the bound there is 89 kW.
example : valveQ (11 / 10) = 89 := by norm_num [valveQ]

-- By hand: credit 110, A's net -21, B's net 0, C's net 10.5.
example : (11 / 10 : ℚ) * 100 = 110 ∧ (45 : ℚ) - 11 / 10 * 60 = -21 ∧
    (55 : ℚ) - 11 / 10 * 50 = 0 ∧ (60 : ℚ) - 11 / 10 * 45 = 21 / 2 := by norm_num

-- The blend at the hull point: all of A and 80 percent of B meets demand exactly for 89 kW.
example : (60 : ℚ) + 4 / 5 * 50 = 100 ∧ (45 : ℚ) + 4 / 5 * 55 = 89 := by norm_num

-- The valve gap is 11 kW, 11 percent of 100 kW.
example : (100 : ℕ) - 89 = 11 := by decide

-- No strict point: one main at 3/4 kW per L/s, rule (w - 40)^2 ≤ 0. At price 1 the priced
-- minimum is at w = 317/8 and falls short of p⋆ = 30 by 9/64 kW (0.140625).
example : (30 : ℚ) - (3 / 4 * (317 / 8) + 1 * (317 / 8 - 40) ^ 2) = 9 / 64 := by norm_num

#print axioms slater_zero_duality_gap
#print axioms gap_certifies_plan
#print axioms valve_duality_gap

end SlaterCondition
