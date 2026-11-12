-- Two goals at once: a weighted sum with a weight that is not negative always picks a Pareto-optimal choice, in a convex problem every Pareto point with a finite frontier slope is picked by some weight, and the card's property fund is Pareto optimal yet never picked by any weight.
import Mathlib.Data.Real.Basic
import Mathlib.Analysis.Convex.Function
import Mathlib.LinearAlgebra.AffineSpace.AffineMap
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Algebra.Order.Archimedean.Real.Basic

/-- `y` dominates `x` for the two goals "make `V` small" and "make `R` large":
`y` has at most the variance and at least the return of `x`, and is strictly better on one. -/
def Dominates {α : Type*} (V R : α → ℝ) (y x : α) : Prop :=
  V y ≤ V x ∧ R x ≤ R y ∧ (V y < V x ∨ R x < R y)

/-- `x` is a feasible choice in `S` that no feasible choice dominates. -/
def ParetoOptimal {α : Type*} (S : Set α) (V R : α → ℝ) (x : α) : Prop :=
  x ∈ S ∧ ¬ ∃ y ∈ S, Dominates V R y x

/-- Half 1. If `x` minimises the weighted sum `V - τ R` over the feasible set, with a weight
`τ ≥ 0`, then `x` is Pareto optimal. When `τ = 0` this needs the minimiser to be unique. -/
theorem weighted_sum_answer_is_pareto_optimal {α : Type*} (S : Set α) (V R : α → ℝ)
    (τ : ℝ) (hτ : 0 ≤ τ) (x : α) (hx : x ∈ S)
    (hmin : ∀ y ∈ S, V x - τ * R x ≤ V y - τ * R y)
    (huniq : τ = 0 → ∀ y ∈ S, (∀ z ∈ S, V y - τ * R y ≤ V z - τ * R z) → y = x) :
    ParetoOptimal S V R x := by
  refine ⟨hx, ?_⟩
  rintro ⟨y, hy, h1, h2, h3⟩
  have hm := hmin y hy
  have hle : V y - τ * R y ≤ V x - τ * R x := by nlinarith
  rcases eq_or_lt_of_le hτ with h0 | hpos
  · subst h0
    have hyx : y = x := huniq rfl y hy (fun z hz => by
      have := hmin z hz; linarith)
    subst hyx
    rcases h3 with h3 | h3 <;> linarith
  · have hVeq : V y = V x := by nlinarith
    have hReq : R y = R x := by
      have : τ * (R y - R x) ≤ 0 := by linarith
      have : R y - R x ≤ 0 := by
        by_contra hc; push Not at hc; nlinarith
      linarith
    rcases h3 with h3 | h3 <;> linarith

/-- Half 2. Take a convex set of choices, a variance `V` that is convex on it and a return `R`
that is a straight-line (affine) function. If `x` is Pareto optimal and the frontier's slope at
`x` is finite (going down from `x` in return, the variance saved per point of return given up is
bounded by some `c`), then `x` is a weighted-sum answer for some weight `τ ≥ 0`, and `τ` is the
slope of a line that supports the frontier at `x`. -/
theorem convex_pareto_point_is_weighted_sum_answer {E : Type*} [AddCommGroup E] [Module ℝ E]
    (S : Set E) (hS : Convex ℝ S) (V : E → ℝ) (hV : ConvexOn ℝ S V) (R : E →ᵃ[ℝ] ℝ)
    (x : E) (hx : ParetoOptimal S V R x)
    (hslope : ∃ c : ℝ, ∀ y ∈ S, R y ≤ R x → V x - V y ≤ c * (R x - R y)) :
    ∃ τ : ℝ, 0 ≤ τ ∧ ∀ y ∈ S, V x - τ * R x ≤ V y - τ * R y := by
  obtain ⟨hxS, hnd⟩ := hx
  obtain ⟨c, hc⟩ := hslope
  -- points with equal return have at least `x`'s variance
  have heq : ∀ z ∈ S, R z = R x → V x ≤ V z := by
    intro z hz hR
    by_contra h; push Not at h
    exact hnd ⟨z, hz, h.le, hR.ge, Or.inl h⟩
  -- points with higher return have strictly higher variance
  have hup : ∀ z ∈ S, R x < R z → V x < V z := by
    intro z hz hR
    by_contra h; push Not at h
    exact hnd ⟨z, hz, h, hR.le, Or.inr hR⟩
  -- the key convexity inequality
  have key : ∀ y₁ ∈ S, ∀ y₂ ∈ S, R y₁ < R x → R x < R y₂ →
      (R y₂ - R x) * (V x - V y₁) ≤ (R x - R y₁) * (V y₂ - V x) := by
    intro y₁ h₁ y₂ h₂ hr₁ hr₂
    set a := R y₂ - R x with ha
    set b := R x - R y₁ with hb
    have ha0 : 0 < a := by linarith
    have hb0 : 0 < b := by linarith
    have hab0 : 0 < a + b := by linarith
    set t := a / (a + b) with ht
    set u := b / (a + b) with hu
    have ht0 : 0 ≤ t := by positivity
    have hu0 : 0 ≤ u := by positivity
    have htu : t + u = 1 := by
      rw [ht, hu, ← add_div, div_self hab0.ne']
    have hzS : t • y₁ + u • y₂ ∈ S := hS h₁ h₂ ht0 hu0 htu
    have hVz := hV.2 h₁ h₂ ht0 hu0 htu
    have hRz : R (t • y₁ + u • y₂) = t • R y₁ + u • R y₂ := Convex.combo_affine_apply htu
    simp only [smul_eq_mul] at hVz hRz
    have hRzx : R (t • y₁ + u • y₂) = R x := by
      rw [hRz, ht, hu]
      field_simp
      rw [ha, hb]; ring
    have h3 := heq _ hzS hRzx
    have h4 : V x ≤ t * V y₁ + u * V y₂ := le_trans h3 hVz
    rw [ht, hu] at h4
    rw [div_mul_eq_mul_div, div_mul_eq_mul_div, ← add_div, le_div_iff₀ hab0] at h4
    nlinarith
  set L : Set ℝ := insert 0 {s | ∃ y ∈ S, R y < R x ∧ s = (V x - V y) / (R x - R y)} with hL
  have hLb : BddAbove L := by
    refine ⟨max c 0, ?_⟩
    rintro s (rfl | ⟨y, hy, hr, rfl⟩)
    · exact le_max_right _ _
    · have hpos : 0 < R x - R y := by linarith
      rw [div_le_iff₀ hpos]
      have := hc y hy hr.le
      nlinarith [le_max_left c 0, le_max_right c 0]
  have hLne : L.Nonempty := ⟨0, Set.mem_insert _ _⟩
  refine ⟨sSup L, le_csSup hLb (Set.mem_insert _ _), ?_⟩
  intro y hy
  rcases lt_trichotomy (R y) (R x) with hr | hr | hr
  · have hpos : 0 < R x - R y := by linarith
    have hmem : (V x - V y) / (R x - R y) ∈ L := Or.inr ⟨y, hy, hr, rfl⟩
    have := le_csSup hLb hmem
    rw [div_le_iff₀ hpos] at this
    nlinarith
  · have := heq y hy hr
    rw [hr]; linarith
  · have hpos : 0 < R y - R x := by linarith
    have hτle : sSup L ≤ (V y - V x) / (R y - R x) := by
      apply csSup_le hLne
      rintro s (rfl | ⟨y₁, hy₁, hr₁, rfl⟩)
      · have := hup y hy hr
        positivity
      · have hb : 0 < R x - R y₁ := by linarith
        rw [div_le_div_iff₀ hb hpos]
        have := key y₁ hy₁ y hy hr₁ hr
        linarith
    rw [le_div_iff₀ hpos] at hτle
    nlinarith

/-- The card's five funds, in order gilt, corporate bond, property, UK equity, emerging
markets: variance (percent squared). -/
noncomputable def fundVar : Fin 5 → ℝ := ![25, 64, 196, 256, 625]

/-- The card's five funds: expected return (percent a year). -/
noncomputable def fundRet : Fin 5 → ℝ := ![3, 4, 5, 13 / 2, 9]

/-- The dent. Under the one-fund rule, the property fund (index 2) is Pareto optimal; yet for
every weight `τ` some other fund scores at least 55.2 = 276/5 lower on `variance - τ × return`,
so no weighted sum ever picks it; and the limit "return at least 5%" picks it, since every fund
meeting that limit has at least property's variance. -/
theorem property_fund_pareto_optimal_but_never_weighted_sum_answer :
    ParetoOptimal (Set.univ : Set (Fin 5)) fundVar fundRet 2 ∧
    (∀ τ : ℝ, ∃ j : Fin 5, j ≠ 2 ∧
      fundVar j - τ * fundRet j + 276 / 5 ≤ fundVar 2 - τ * fundRet 2) ∧
    (∀ j : Fin 5, 5 ≤ fundRet j → fundVar 2 ≤ fundVar j) := by
  refine ⟨⟨Set.mem_univ _, ?_⟩, ?_, ?_⟩
  · rintro ⟨j, -, h1, h2, h3⟩
    revert h1 h2 h3
    fin_cases j <;> norm_num [fundVar, fundRet]
  · intro τ
    by_cases h : τ ≤ 384 / 5
    · refine ⟨1, by decide, ?_⟩
      norm_num [fundVar, fundRet]
      linarith
    · refine ⟨3, by decide, ?_⟩
      norm_num [fundVar, fundRet]
      linarith
  · intro j hj
    revert hj
    fin_cases j <;> norm_num [fundVar, fundRet]

-- The 60/40 average of the corporate bond and UK equity points returns exactly 5%.
example : (3 / 5 : ℚ) * 4 + (2 / 5) * (13 / 2) = 5 := by norm_num
-- Its variance is 140.8 = 704/5, so property's 196 trails it by 55.2 = 276/5.
example : (3 / 5 : ℚ) * 64 + (2 / 5) * 256 = 704 / 5 := by norm_num
example : (196 : ℚ) - 704 / 5 = 276 / 5 := by norm_num
-- Switch points of the one-fund sweep: 39, 76.8 = 384/5 and 147.6 = 738/5.
example : ((64 : ℚ) - 25) / (4 - 3) = 39 := by norm_num
example : ((256 : ℚ) - 64) / (13 / 2 - 4) = 384 / 5 := by norm_num
example : ((625 : ℚ) - 256) / (9 - 13 / 2) = 738 / 5 := by norm_num
-- All in emerging markets from τ = 2 × 625 / (9 − 6.5) = 500.
example : 2 * (625 : ℚ) / (9 - 13 / 2) = 500 := by norm_num
-- Variances are the squared standard deviations 5, 8, 14, 16, 25.
example : ((5 : ℕ) ^ 2, (8 : ℕ) ^ 2, (14 : ℕ) ^ 2, (16 : ℕ) ^ 2, (25 : ℕ) ^ 2)
    = (25, 64, 196, 256, 625) := by decide
-- Twice the variances in the τ = 50 hand calculation.
example : (2 * 25, 2 * 64, 2 * 196, 2 * 256, 2 * 625) = (50, 128, 392, 512, 1250) := by decide
-- The 2% grid has C(54, 4) = 316,251 splits.
example : Nat.choose 54 4 = 316251 := by decide
-- Every one of the five funds is Pareto optimal under the one-fund rule.
example : ∀ i : Fin 5, ParetoOptimal (Set.univ : Set (Fin 5)) fundVar fundRet i := by
  intro i
  refine ⟨Set.mem_univ _, ?_⟩
  rintro ⟨j, -, h1, h2, h3⟩
  revert h1 h2 h3
  fin_cases i <;> fin_cases j <;> norm_num [fundVar, fundRet]

#print axioms weighted_sum_answer_is_pareto_optimal
#print axioms convex_pareto_point_is_weighted_sum_answer
#print axioms property_fund_pareto_optimal_but_never_weighted_sum_answer
