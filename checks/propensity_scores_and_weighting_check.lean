-- Propensity scores: if, given the measurements, treatment is unrelated to the potential outcomes and every score lies strictly between 0 and 1, then weighting each patient by one over the chance of the treatment they got recovers the average outcome under each treatment, the score balances the measurements and keeps that unrelatedness, and on a table of strata the weighting equals the back-door formula, with the kidney-stone numbers checked exactly.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

open Finset
open scoped Classical

noncomputable section


variable {Ω ι : Type*} [Fintype Ω]

/-- The chance of an event `A` on a finite space where outcome `ω` has chance `P ω`. -/
def prob (P : Ω → ℝ) (A : Ω → Prop) : ℝ :=
  ∑ ω ∈ univ.filter A, P ω

/-- The propensity score `e(x) = P(T = 1 | X = x)`: the chance of treatment A
among the patients whose measurement is `x`. -/
def score (P : Ω → ℝ) (X : Ω → ι) (T : Ω → Bool) (x : ι) : ℝ :=
  prob P (fun ω => X ω = x ∧ T ω = true) / prob P (fun ω => X ω = x)

/-- A chance written as a sum over every outcome. -/
lemma prob_eq_sum_ite (P : Ω → ℝ) (A : Ω → Prop) :
    prob P A = ∑ ω, if A ω then P ω else 0 := by
  unfold prob; rw [Finset.sum_filter]

lemma prob_congr (P : Ω → ℝ) {A B : Ω → Prop} (h : ∀ ω, A ω ↔ B ω) :
    prob P A = prob P B := by
  have : A = B := funext fun ω => propext (h ω)
  rw [this]

lemma prob_nonneg (P : Ω → ℝ) (hP : ∀ ω, 0 ≤ P ω) (A : Ω → Prop) : 0 ≤ prob P A := by
  unfold prob; exact Finset.sum_nonneg (fun ω _ => hP ω)

lemma prob_of_not (P : Ω → ℝ) {A : Ω → Prop} (h : ∀ ω, ¬ A ω) : prob P A = 0 := by
  rw [prob_eq_sum_ite]; simp [h]

/-- Inside a stratum of chance zero, every event has chance zero. -/
lemma prob_zero_of_imp (P : Ω → ℝ) (hP : ∀ ω, 0 ≤ P ω) (X : Ω → ι) (x : ι)
    (h0 : prob P (fun ω => X ω = x) = 0) (A : Ω → Prop) (hA : ∀ ω, A ω → X ω = x) :
    prob P A = 0 := by
  unfold prob at h0 ⊢
  have hz := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => hP i)).1 h0
  apply Finset.sum_eq_zero
  intro ω hω
  exact hz ω (by simpa using hA ω (by simpa using hω))

/-- Splitting a chance over the outcomes of a map. -/
lemma sum_fiber (P : Ω → ℝ) (Q : Ω → Prop) [DecidablePred Q] {β : Type*} [DecidableEq β] (g : Ω → β) (φ : β → ℝ) :
    ∑ ω, (if Q ω then P ω else 0) * φ (g ω) =
      ∑ y ∈ univ.image g, prob P (fun ω => Q ω ∧ g ω = y) * φ y := by
  rw [← Finset.sum_fiberwise_of_maps_to (g := g) (t := univ.image g)
    (fun ω _ => Finset.mem_image_of_mem g (Finset.mem_univ ω))]
  apply Finset.sum_congr rfl
  intro y _
  rw [prob_eq_sum_ite, Finset.sum_mul, Finset.sum_filter]
  apply Finset.sum_congr rfl
  intro ω _
  by_cases hg : g ω = y <;> by_cases hq : Q ω <;> simp [hg, hq]

/-- Inside a stratum, the chance of each treatment is the score, or one minus it. -/
lemma prob_X_T (P : Ω → ℝ) (hP : ∀ ω, 0 ≤ P ω) (X : Ω → ι) (T : Ω → Bool) (x : ι) (t : Bool) :
    prob P (fun ω => X ω = x ∧ T ω = t) =
      (if t then score P X T x else 1 - score P X T x) * prob P (fun ω => X ω = x) := by
  by_cases h0 : prob P (fun ω => X ω = x) = 0
  · rw [h0, mul_zero]; exact prob_zero_of_imp P hP X x h0 _ (fun ω h => h.1)
  · have split : prob P (fun ω => X ω = x) =
        prob P (fun ω => X ω = x ∧ T ω = true) + prob P (fun ω => X ω = x ∧ T ω = false) := by
      simp only [prob_eq_sum_ite]
      rw [← Finset.sum_add_distrib]
      apply Finset.sum_congr rfl
      intro ω _
      cases hT : T ω <;> by_cases hx : X ω = x <;> simp [hx]
    cases t
    · simp only [Bool.false_eq_true, ↓reduceIte, score]
      rw [sub_mul, div_mul_cancel₀ _ h0, one_mul]
      linarith
    · simp only [↓reduceIte, score]
      rw [div_mul_cancel₀ _ h0]

/-- No unmeasured confounding, stratum by stratum: the joint chance is the treatment chance times
the outcome chance. -/
lemma prob_cond (P : Ω → ℝ) (hP : ∀ ω, 0 ≤ P ω) (X : Ω → ι) (T : Ω → Bool) (YA YB : Ω → ℝ)
    (hcond : ∀ (x : ι) (t : Bool) (a b : ℝ),
      prob P (fun ω => X ω = x ∧ T ω = t ∧ YA ω = a ∧ YB ω = b) * prob P (fun ω => X ω = x) =
        prob P (fun ω => X ω = x ∧ T ω = t) * prob P (fun ω => X ω = x ∧ YA ω = a ∧ YB ω = b))
    (x : ι) (t : Bool) (a b : ℝ) :
    prob P (fun ω => X ω = x ∧ T ω = t ∧ YA ω = a ∧ YB ω = b) =
      (if t then score P X T x else 1 - score P X T x) *
        prob P (fun ω => X ω = x ∧ YA ω = a ∧ YB ω = b) := by
  by_cases h0 : prob P (fun ω => X ω = x) = 0
  · rw [prob_zero_of_imp P hP X x h0 _ (fun ω h => h.1),
      prob_zero_of_imp P hP X x h0 (fun ω => X ω = x ∧ YA ω = a ∧ YB ω = b) (fun ω h => h.1),
      mul_zero]
  · have h := hcond x t a b
    rw [prob_X_T P hP X T x t] at h
    apply mul_right_cancel₀ h0
    rw [h]; ring

/-- Adding strata: if each stratum's chances keep the ratio `k`, so do the totals. -/
lemma prob_ratio_of_strata (P : Ω → ℝ) (X : Ω → ι) (R R' : Ω → Prop) (k : ℝ)
    (h : ∀ x, prob P (fun ω => R ω ∧ X ω = x) = k * prob P (fun ω => R' ω ∧ X ω = x)) :
    prob P R = k * prob P R' := by
  have e1 : prob P R = ∑ ω, (if R ω then P ω else 0) * (fun _ : ι => (1 : ℝ)) (X ω) := by
    rw [prob_eq_sum_ite]; simp
  have e2 : prob P R' = ∑ ω, (if R' ω then P ω else 0) * (fun _ : ι => (1 : ℝ)) (X ω) := by
    rw [prob_eq_sum_ite]; simp
  rw [e1, e2, sum_fiber P R X (fun _ : ι => (1 : ℝ)), sum_fiber P R' X (fun _ : ι => (1 : ℝ)),
    Finset.mul_sum]
  apply Finset.sum_congr rfl
  intro x _
  rw [h x]; ring

/-- Among patients with score `s`, the chance of each treatment is `s`, or one minus it, times the
chance of `R`, whenever that holds stratum by stratum. -/
lemma prob_score_level (P : Ω → ℝ) (X : Ω → ι) (T : Ω → Bool) (s k : ℝ) (A B : Ω → Prop)
    (hstrat : ∀ x, score P X T x = s →
      prob P (fun ω => A ω ∧ X ω = x) = k * prob P (fun ω => B ω ∧ X ω = x)) :
    prob P (fun ω => score P X T (X ω) = s ∧ A ω) =
      k * prob P (fun ω => score P X T (X ω) = s ∧ B ω) := by
  apply prob_ratio_of_strata P X
  intro x
  by_cases hs : score P X T x = s
  · have h1 : prob P (fun ω => (score P X T (X ω) = s ∧ A ω) ∧ X ω = x) =
        prob P (fun ω => A ω ∧ X ω = x) := by
      apply prob_congr; intro ω
      constructor
      · rintro ⟨⟨_, h⟩, hx⟩; exact ⟨h, hx⟩
      · rintro ⟨h, hx⟩; exact ⟨⟨by rw [hx, hs], h⟩, hx⟩
    have h2 : prob P (fun ω => (score P X T (X ω) = s ∧ B ω) ∧ X ω = x) =
        prob P (fun ω => B ω ∧ X ω = x) := by
      apply prob_congr; intro ω
      constructor
      · rintro ⟨⟨_, h⟩, hx⟩; exact ⟨h, hx⟩
      · rintro ⟨h, hx⟩; exact ⟨⟨by rw [hx, hs], h⟩, hx⟩
    rw [h1, h2]; exact hstrat x hs
  · rw [prob_of_not P (A := fun ω => (score P X T (X ω) = s ∧ A ω) ∧ X ω = x)
        (fun ω h => hs (by rw [← h.2]; exact h.1.1)),
      prob_of_not P (A := fun ω => (score P X T (X ω) = s ∧ B ω) ∧ X ω = x)
        (fun ω h => hs (by rw [← h.2]; exact h.1.1)), mul_zero]


/-- The card's theorem, weighting half. Patients `ω` form a finite probability space with
chances `P ω`. `X` is the measurement, `T` the treatment (`true` for A), `YA` and `YB` the
potential outcomes, and the outcome seen is `YA` on A and `YB` on B. Suppose no unmeasured
confounding, `(Y(A), Y(B)) ⊥ T | X`, and overlap, `0 < e(X) < 1`. Then the average of
`T Y / e(X)` is the average outcome had everyone got A, `E[Y(A)]`, and the average of
`(1 - T) Y / (1 - e(X))` is `E[Y(B)]`. -/
theorem ipw_recovers_average_outcome_under_each_treatment
    (P : Ω → ℝ) (hP : ∀ ω, 0 ≤ P ω) (hP1 : ∑ ω, P ω = 1)
    (X : Ω → ι) (T : Ω → Bool) (YA YB : Ω → ℝ)
    (hcond : ∀ (x : ι) (t : Bool) (a b : ℝ),
      prob P (fun ω => X ω = x ∧ T ω = t ∧ YA ω = a ∧ YB ω = b) * prob P (fun ω => X ω = x) =
        prob P (fun ω => X ω = x ∧ T ω = t) * prob P (fun ω => X ω = x ∧ YA ω = a ∧ YB ω = b))
    (hoverlap : ∀ x : ι, 0 < prob P (fun ω => X ω = x) →
      0 < score P X T x ∧ score P X T x < 1) :
    ∑ ω, P ω * ((if T ω then 1 else 0) * (if T ω then YA ω else YB ω) / score P X T (X ω)) =
        ∑ ω, P ω * YA ω ∧
    ∑ ω, P ω * ((if T ω then 0 else 1) * (if T ω then YA ω else YB ω) /
        (1 - score P X T (X ω))) =
      ∑ ω, P ω * YB ω := by
  have key : ∀ (t : Bool) (x : ι) (a b v : ℝ),
      prob P (fun ω => X ω = x ∧ T ω = t ∧ YA ω = a ∧ YB ω = b) *
          (v / (if t then score P X T x else 1 - score P X T x)) =
        prob P (fun ω => X ω = x ∧ YA ω = a ∧ YB ω = b) * v := by
    intro t x a b v
    rw [prob_cond P hP X T YA YB hcond x t a b]
    by_cases h0 : prob P (fun ω => X ω = x) = 0
    · rw [prob_zero_of_imp P hP X x h0 (fun ω => X ω = x ∧ YA ω = a ∧ YB ω = b) (fun ω h => h.1)]
      ring
    · have hpos : 0 < prob P (fun ω => X ω = x) :=
        lt_of_le_of_ne (prob_nonneg P hP _) (Ne.symm h0)
      obtain ⟨h1, h2⟩ := hoverlap x hpos
      have hc : (if t then score P X T x else 1 - score P X T x) ≠ 0 := by
        cases t
        · simp only [Bool.false_eq_true, ↓reduceIte]; exact (sub_pos.2 h2).ne'
        · simp only [↓reduceIte]; exact h1.ne'
      field_simp
  set g : Ω → ι × ℝ × ℝ := fun ω => (X ω, YA ω, YB ω) with hg
  have hR : ∀ φ : ι × ℝ × ℝ → ℝ, ∑ ω, P ω * φ (g ω) =
      ∑ y ∈ univ.image g, prob P (fun ω => X ω = y.1 ∧ YA ω = y.2.1 ∧ YB ω = y.2.2) * φ y := by
    intro φ
    rw [show (∑ ω, P ω * φ (g ω)) = ∑ ω, (if True then P ω else 0) * φ (g ω) by simp,
      sum_fiber]
    apply Finset.sum_congr rfl
    intro y _
    congr 1
    apply prob_congr
    intro ω
    obtain ⟨x, a, b⟩ := y
    simp only [hg, Prod.mk.injEq, true_and]
  have hL : ∀ (t : Bool) (φ : ι × ℝ × ℝ → ℝ), ∑ ω, (if T ω = t then P ω else 0) * φ (g ω) =
      ∑ y ∈ univ.image g,
        prob P (fun ω => X ω = y.1 ∧ T ω = t ∧ YA ω = y.2.1 ∧ YB ω = y.2.2) * φ y := by
    intro t φ
    rw [sum_fiber]
    apply Finset.sum_congr rfl
    intro y _
    congr 1
    apply prob_congr
    intro ω
    obtain ⟨x, a, b⟩ := y
    simp only [hg, Prod.mk.injEq]
    tauto
  constructor
  · have e1 : ∑ ω, P ω * ((if T ω then 1 else 0) * (if T ω then YA ω else YB ω) /
          score P X T (X ω)) =
        ∑ ω, (if T ω = true then P ω else 0) *
          (fun y : ι × ℝ × ℝ => y.2.1 / (if true then score P X T y.1 else 1 - score P X T y.1))
            (g ω) := by
      apply Finset.sum_congr rfl
      intro ω _
      cases hT : T ω <;> simp [hg]
    have e2 : ∑ ω, P ω * YA ω = ∑ ω, P ω * (fun y : ι × ℝ × ℝ => y.2.1) (g ω) := by
      simp [hg]
    rw [e1, e2]
    beta_reduce
    rw [hL true (fun y : ι × ℝ × ℝ =>
        y.2.1 / (if true then score P X T y.1 else 1 - score P X T y.1)),
      hR (fun y : ι × ℝ × ℝ => y.2.1)]
    apply Finset.sum_congr rfl
    intro y _
    exact key true y.1 y.2.1 y.2.2 y.2.1
  · have e1 : ∑ ω, P ω * ((if T ω then 0 else 1) * (if T ω then YA ω else YB ω) /
          (1 - score P X T (X ω))) =
        ∑ ω, (if T ω = false then P ω else 0) *
          (fun y : ι × ℝ × ℝ => y.2.2 / (if false then score P X T y.1 else 1 - score P X T y.1))
            (g ω) := by
      apply Finset.sum_congr rfl
      intro ω _
      cases hT : T ω <;> simp [hg]
    have e2 : ∑ ω, P ω * YB ω = ∑ ω, P ω * (fun y : ι × ℝ × ℝ => y.2.2) (g ω) := by
      simp [hg]
    rw [e1, e2]
    beta_reduce
    rw [hL false (fun y : ι × ℝ × ℝ =>
        y.2.2 / (if false then score P X T y.1 else 1 - score P X T y.1)),
      hR (fun y : ι × ℝ × ℝ => y.2.2)]
    apply Finset.sum_congr rfl
    intro y _
    exact key false y.1 y.2.1 y.2.2 y.2.2

/-- The card's theorem, score half (Rosenbaum and Rubin). With no unmeasured confounding given
`X`, the single number `e(X)` is enough. Balancing: among patients with the same score, the
treatment is unrelated to the measurement. Carry-over: among patients with the same score, the
treatment is unrelated to the potential outcomes, `(Y(A), Y(B)) ⊥ T | e(X)`. -/
theorem score_balances_and_keeps_no_confounding
    (P : Ω → ℝ) (hP : ∀ ω, 0 ≤ P ω) (hP1 : ∑ ω, P ω = 1)
    (X : Ω → ι) (T : Ω → Bool) (YA YB : Ω → ℝ)
    (hcond : ∀ (x : ι) (t : Bool) (a b : ℝ),
      prob P (fun ω => X ω = x ∧ T ω = t ∧ YA ω = a ∧ YB ω = b) * prob P (fun ω => X ω = x) =
        prob P (fun ω => X ω = x ∧ T ω = t) * prob P (fun ω => X ω = x ∧ YA ω = a ∧ YB ω = b)) :
    (∀ (s : ℝ) (t : Bool) (x : ι),
      prob P (fun ω => score P X T (X ω) = s ∧ T ω = t ∧ X ω = x) *
          prob P (fun ω => score P X T (X ω) = s) =
        prob P (fun ω => score P X T (X ω) = s ∧ T ω = t) *
          prob P (fun ω => score P X T (X ω) = s ∧ X ω = x)) ∧
    (∀ (s : ℝ) (t : Bool) (a b : ℝ),
      prob P (fun ω => score P X T (X ω) = s ∧ T ω = t ∧ YA ω = a ∧ YB ω = b) *
          prob P (fun ω => score P X T (X ω) = s) =
        prob P (fun ω => score P X T (X ω) = s ∧ T ω = t) *
          prob P (fun ω => score P X T (X ω) = s ∧ YA ω = a ∧ YB ω = b)) := by
  have hlevel : ∀ (s : ℝ) (t : Bool), prob P (fun ω => score P X T (X ω) = s ∧ T ω = t) =
      (if t then s else 1 - s) * prob P (fun ω => score P X T (X ω) = s) := by
    intro s t
    have h := prob_score_level P X T s (if t then s else 1 - s) (fun ω => T ω = t)
      (fun _ => True) (by
        intro x hs
        rw [prob_congr P (B := fun ω => X ω = x ∧ T ω = t) (fun ω => and_comm),
          prob_X_T P hP X T x t, hs]
        congr 1
        apply prob_congr
        intro ω
        simp)
    rw [h]
    congr 1
    apply prob_congr
    intro ω
    simp
  refine ⟨?_, ?_⟩
  · intro s t x
    by_cases hs : score P X T x = s
    · have h1 : prob P (fun ω => score P X T (X ω) = s ∧ T ω = t ∧ X ω = x) =
          prob P (fun ω => X ω = x ∧ T ω = t) := by
        apply prob_congr
        intro ω
        constructor
        · rintro ⟨_, ht, hx⟩; exact ⟨hx, ht⟩
        · rintro ⟨hx, ht⟩; exact ⟨by rw [hx, hs], ht, hx⟩
      have h2 : prob P (fun ω => score P X T (X ω) = s ∧ X ω = x) =
          prob P (fun ω => X ω = x) := by
        apply prob_congr
        intro ω
        constructor
        · rintro ⟨_, hx⟩; exact hx
        · rintro hx; exact ⟨by rw [hx, hs], hx⟩
      rw [h1, h2, hlevel, prob_X_T P hP X T x t, hs]
      ring
    · rw [prob_of_not P (A := fun ω => score P X T (X ω) = s ∧ T ω = t ∧ X ω = x)
          (fun ω h => hs (by rw [← h.2.2]; exact h.1)),
        prob_of_not P (A := fun ω => score P X T (X ω) = s ∧ X ω = x)
          (fun ω h => hs (by rw [← h.2]; exact h.1))]
      ring
  · intro s t a b
    have h := prob_score_level P X T s (if t then s else 1 - s)
      (fun ω => T ω = t ∧ YA ω = a ∧ YB ω = b) (fun ω => YA ω = a ∧ YB ω = b) (by
        intro x hs
        rw [prob_congr P (B := fun ω => X ω = x ∧ T ω = t ∧ YA ω = a ∧ YB ω = b)
            (fun ω => by tauto),
          prob_cond P hP X T YA YB hcond x t a b, hs]
        congr 1
        apply prob_congr
        intro ω
        tauto)
    rw [h, hlevel]
    ring

/-- Step 1, on a table. In each stratum `x`, `nA x` patients got A and `nB x` got B, every cell
filled, and `cA x`, `cB x` of them were cured; `N` is everyone and the counted score is
`e x = nA x / (nA x + nB x)`. Each arm's weights, `1 / e` and `1 / (1 - e)`, add to `N`, and the
weighted cure rates equal the back-door sums: each stratum's cure rate averaged with the
stratum's share of everyone. -/
theorem ipw_equals_backdoor_on_strata {κ : Type*} (S : Finset κ) (nA nB cA cB : κ → ℕ)
    (hA : ∀ x ∈ S, 0 < nA x) (hB : ∀ x ∈ S, 0 < nB x) :
    let N : ℝ := ∑ x ∈ S, ((nA x : ℝ) + nB x)
    let e : κ → ℝ := fun x => (nA x : ℝ) / ((nA x : ℝ) + nB x)
    ∑ x ∈ S, (nA x : ℝ) * (1 / e x) = N ∧
    ∑ x ∈ S, (nB x : ℝ) * (1 / (1 - e x)) = N ∧
    (1 / N) * ∑ x ∈ S, (cA x : ℝ) * (1 / e x) =
      ∑ x ∈ S, (((nA x : ℝ) + nB x) / N) * ((cA x : ℝ) / nA x) ∧
    (1 / N) * ∑ x ∈ S, (cB x : ℝ) * (1 / (1 - e x)) =
      ∑ x ∈ S, (((nA x : ℝ) + nB x) / N) * ((cB x : ℝ) / nB x) := by
  intro N e
  have hApos : ∀ x ∈ S, (0 : ℝ) < nA x := fun x hx => Nat.cast_pos.2 (hA x hx)
  have hBpos : ∀ x ∈ S, (0 : ℝ) < nB x := fun x hx => Nat.cast_pos.2 (hB x hx)
  have hsum : ∀ x ∈ S, (0 : ℝ) < (nA x : ℝ) + nB x := fun x hx =>
    add_pos (hApos x hx) (hBpos x hx)
  have h1e : ∀ x ∈ S, 1 / e x = ((nA x : ℝ) + nB x) / nA x := fun x _ => by
    simp only [e, one_div_div]
  have h1me : ∀ x ∈ S, 1 / (1 - e x) = ((nA x : ℝ) + nB x) / nB x := fun x hx => by
    have hs := (hsum x hx).ne'
    have h : 1 - e x = (nB x : ℝ) / ((nA x : ℝ) + nB x) := by
      simp only [e]; field_simp; ring
    rw [h, one_div_div]
  refine ⟨?_, ?_, ?_, ?_⟩
  · apply Finset.sum_congr rfl
    intro x hx
    rw [h1e x hx]
    have := (hApos x hx).ne'
    field_simp
  · apply Finset.sum_congr rfl
    intro x hx
    rw [h1me x hx]
    have := (hBpos x hx).ne'
    field_simp
  · rw [Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro x hx
    rw [h1e x hx]
    ring
  · rw [Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro x hx
    rw [h1me x hx]
    ring


end

/-! ### The kidney-stone numbers, as exact fractions
Small stones: A cured 81 of 87, B 234 of 270, 357 in all. Large stones: A cured 192 of 263,
B 55 of 80, 343 in all. 700 patients. -/

-- A's weights rebuild 357 and 343, B's too, so each arm weighs 700.
example :
    (87 : ℚ) * (1 / (87 / 357)) = 357 ∧ (263 : ℚ) * (1 / (263 / 343)) = 343 ∧
    (270 : ℚ) * (1 / (1 - 87 / 357)) = 357 ∧ (80 : ℚ) * (1 / (1 - 263 / 343)) = 343 ∧
    (357 : ℚ) + 343 = 700 := by
  norm_num

-- The weighted cure rates equal the back-door sums: A 634983/762700 (0.8325), B 6231/8000 (0.7789).
example :
    (1 / 700 : ℚ) * (81 * (1 / (87 / 357)) + 192 * (1 / (263 / 343))) =
      357 / 700 * (81 / 87) + 343 / 700 * (192 / 263) ∧
    (357 / 700 * (81 / 87) + 343 / 700 * (192 / 263) : ℚ) = 634983 / 762700 ∧
    (1 / 700 : ℚ) * (234 * (1 / (1 - 87 / 357)) + 55 * (1 / (1 - 263 / 343))) =
      357 / 700 * (234 / 270) + 343 / 700 * (55 / 80) ∧
    (357 / 700 * (234 / 270) + 343 / 700 * (55 / 80) : ℚ) = 6231 / 8000 := by
  norm_num

-- The ATE is 3274803/61016000 (+5.37 points); the raw gap is 273/350 - 289/350 = -8/175 (-4.57 points).
example :
    (634983 / 762700 : ℚ) - 6231 / 8000 = 3274803 / 61016000 ∧
    (273 : ℚ) / 350 - 289 / 350 = -8 / 175 := by
  norm_num

-- Weighted, both arms have the hospital's large-stone share, 343/700 = 49/100.
example :
    (263 : ℚ) * (1 / (263 / 343)) / 700 = 49 / 100 ∧
    (80 : ℚ) * (1 / (1 - 263 / 343)) / 700 = 49 / 100 := by
  norm_num

#print axioms prob_eq_sum_ite
#print axioms prob_congr
#print axioms prob_nonneg
#print axioms prob_of_not
#print axioms prob_zero_of_imp
#print axioms sum_fiber
#print axioms prob_X_T
#print axioms prob_cond
#print axioms prob_ratio_of_strata
#print axioms prob_score_level
#print axioms ipw_recovers_average_outcome_under_each_treatment
#print axioms score_balances_and_keeps_no_confounding
#print axioms ipw_equals_backdoor_on_strata
