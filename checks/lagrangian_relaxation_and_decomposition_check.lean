-- Lagrangian relaxation: pricing a shared budget gives an upper bound on every legal booking at every price λ ≥ 0, the priced problem splits stage by stage, and the best bound equals the best blend of whole stage plans.
import Mathlib.Data.Fintype.Pi
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Topology.Order.Lattice
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.LinearCombination

open Finset

namespace LagrangianRelaxation

/-! ## The model

There is a finite set of stages `σ`. Stage `s` has acts of type `ι s`. A plan for stage `s`
is the set of its acts it books (a `Finset (ι s)`), and `X s` is the list of plans that fit
stage `s`'s own rule. A booking `t` picks one set of acts for every stage; it obeys the stage
rules when `t ∈ Fintype.piFinset X`. Act `i` of stage `s` has profit `p s i` and needs
`c s i` crew-hours; `C` is the shared crew budget, the awkward constraint. -/

variable {σ : Type*} [Fintype σ] [DecidableEq σ] {ι : σ → Type*} [∀ s, DecidableEq (ι s)]

/-- Total profit of a booking. -/
def profit (p : ∀ s, ι s → ℝ) (t : ∀ s, Finset (ι s)) : ℝ := ∑ s, ∑ i ∈ t s, p s i

/-- Total crew-hours a booking uses. -/
def crew (c : ∀ s, ι s → ℝ) (t : ∀ s, Finset (ι s)) : ℝ := ∑ s, ∑ i ∈ t s, c s i

/-- The priced score at crew price `lam`: profit plus `lam` times the unused crew budget. -/
def pricedScore (p c : ∀ s, ι s → ℝ) (C lam : ℝ) (t : ∀ s, Finset (ι s)) : ℝ :=
  profit p t + lam * (C - crew c t)

/-- The dual function `q(λ)`: the true maximum of the priced score over every booking that
obeys the stage rules, with the crew rule dropped. -/
noncomputable def q (X : ∀ s, Finset (Finset (ι s))) (hX : (Fintype.piFinset X).Nonempty)
    (p c : ∀ s, ι s → ℝ) (C lam : ℝ) : ℝ :=
  (Fintype.piFinset X).sup' hX (pricedScore p c C lam)

/-- Helper: one-dimensional crossing point for the price. -/
lemma key_crossing {α : Type*} (T : Finset α) (a b : α → ℝ) (t0 : α) (ht0 : t0 ∈ T)
    (hb0 : 0 ≤ b t0) :
    ∃ lam : ℝ, 0 ≤ lam ∧ ∃ t1 ∈ T, ∃ t2 ∈ T, ∃ θ : ℝ, 0 ≤ θ ∧ θ ≤ 1 ∧
      0 ≤ θ * b t1 + (1 - θ) * b t2 ∧ lam * (θ * b t1 + (1 - θ) * b t2) = 0 ∧
      (∀ u ∈ T, a u + lam * b u ≤ a t1 + lam * b t1) ∧
      a t2 + lam * b t2 = a t1 + lam * b t1 := by
  classical
  by_cases h0 : ∃ t ∈ T, 0 ≤ b t ∧ ∀ u ∈ T, a u ≤ a t
  · obtain ⟨t, ht, hbt, hmax⟩ := h0
    refine ⟨0, le_rfl, t, ht, t, ht, 1, zero_le_one, le_rfl, by simpa using hbt, by simp, ?_, rfl⟩
    intro u hu; simpa using hmax u hu
  push Not at h0
  set A := T.filter (fun u => 0 ≤ b u) with hAdef
  set B := T.filter (fun u => b u < 0) with hBdef
  have ht0A : t0 ∈ A := by simp [hAdef, ht0, hb0]
  have hA : A.Nonempty := ⟨t0, ht0A⟩
  obtain ⟨m, hm, hmmax⟩ := T.exists_max_image a ⟨t0, ht0⟩
  have hbm : b m < 0 := by
    by_contra hcon; push Not at hcon
    obtain ⟨u, hu, hlt⟩ := h0 m hm hcon
    exact absurd (hmmax u hu) (not_le.2 hlt)
  have hmB : m ∈ B := by simp [hBdef, hm, hbm]
  have hB : B.Nonempty := ⟨m, hmB⟩
  set FA : ℝ → ℝ := fun l => A.sup' hA (fun u => a u + l * b u) with hFA
  set FB : ℝ → ℝ := fun l => B.sup' hB (fun u => a u + l * b u) with hFB
  have hcont : Continuous (fun l => FA l - FB l) := by
    apply Continuous.sub
    · exact Continuous.finset_sup'_apply hA (fun i _ => by fun_prop)
    · exact Continuous.finset_sup'_apply hB (fun i _ => by fun_prop)
  have hg0 : FA 0 - FB 0 < 0 := by
    obtain ⟨u, hu, hu_eq⟩ := A.exists_mem_eq_sup' hA (fun u => a u + 0 * b u)
    have huT : u ∈ T := (Finset.mem_filter.1 hu).1
    have hbu : 0 ≤ b u := (Finset.mem_filter.1 hu).2
    obtain ⟨v, hv, hlt⟩ := h0 u huT hbu
    have h1 : a m + 0 * b m ≤ FB 0 := Finset.le_sup' (fun u => a u + 0 * b u) hmB
    have h2 := hmmax v hv
    have h3 : FA 0 = a u + 0 * b u := hu_eq
    rw [h3]; simp at h1 ⊢; linarith
  set L := max 0 (B.sup' hB (fun u => (a u - a t0) / (- b u))) with hL
  have hL0 : 0 ≤ L := le_max_left _ _
  have hgL : 0 ≤ FA L - FB L := by
    have h1 : FB L ≤ a t0 := by
      apply Finset.sup'_le
      intro u hu
      have hbu : b u < 0 := (Finset.mem_filter.1 hu).2
      have h4 : (a u - a t0) / (- b u) ≤ L :=
        le_trans (Finset.le_sup' (fun u => (a u - a t0) / (- b u)) hu) (le_max_right _ _)
      rw [div_le_iff₀ (by linarith)] at h4
      linarith
    have h2 : a t0 + L * b t0 ≤ FA L := Finset.le_sup' (fun u => a u + L * b u) ht0A
    have h3 : 0 ≤ L * b t0 := mul_nonneg hL0 hb0
    linarith
  obtain ⟨lam, ⟨hl0, -⟩, hgl⟩ :=
    intermediate_value_Icc hL0 hcont.continuousOn ⟨hg0.le, hgL⟩
  have hEq : FA lam = FB lam := by simp only at hgl; linarith
  obtain ⟨t1, ht1, ht1eq⟩ := A.exists_mem_eq_sup' hA (fun u => a u + lam * b u)
  obtain ⟨t2, ht2, ht2eq⟩ := B.exists_mem_eq_sup' hB (fun u => a u + lam * b u)
  have hFA1 : FA lam = a t1 + lam * b t1 := ht1eq
  have hFB2 : FB lam = a t2 + lam * b t2 := ht2eq
  have ht1T : t1 ∈ T := (Finset.mem_filter.1 ht1).1
  have hb1 : 0 ≤ b t1 := (Finset.mem_filter.1 ht1).2
  have ht2T : t2 ∈ T := (Finset.mem_filter.1 ht2).1
  have hb2 : b t2 < 0 := (Finset.mem_filter.1 ht2).2
  have hden : 0 < b t1 - b t2 := by linarith
  have hθ : (- b t2 / (b t1 - b t2)) * b t1 + (1 - (- b t2 / (b t1 - b t2))) * b t2 = 0 := by
    field_simp; ring
  refine ⟨lam, hl0, t1, ht1T, t2, ht2T, - b t2 / (b t1 - b t2), ?_, ?_, ?_, ?_, ?_, ?_⟩
  · exact div_nonneg (by linarith) hden.le
  · rw [div_le_one hden]; linarith
  · rw [hθ]
  · rw [hθ, mul_zero]
  · intro u hu
    by_cases hbu : 0 ≤ b u
    · have : u ∈ A := by simp [hAdef, hu, hbu]
      have := Finset.le_sup' (fun u => a u + lam * b u) this
      rw [← hFA1]; exact this
    · have : u ∈ B := by simp [hBdef, hu, not_le.1 hbu]
      have := Finset.le_sup' (fun u => a u + lam * b u) this
      rw [← hFA1, hEq]; exact this
  · rw [← hFA1, ← hFB2, hEq]

/-- Helper: the priced score split by stage. -/
lemma pricedScore_eq (p c : ∀ s, ι s → ℝ) (C lam : ℝ) (t : ∀ s, Finset (ι s)) :
    pricedScore p c C lam t = lam * C + ∑ s, ∑ i ∈ t s, (p s i - lam * c s i) := by
  simp only [pricedScore, profit, crew, Finset.sum_sub_distrib, ← Finset.mul_sum]
  ring

/-- Helper: the dual function is attained by any booking that beats all others. -/
lemma q_eq_of_max (X : ∀ s, Finset (Finset (ι s))) (hX : (Fintype.piFinset X).Nonempty)
    (p c : ∀ s, ι s → ℝ) (C lam : ℝ) (t1 : ∀ s, Finset (ι s)) (ht1 : t1 ∈ Fintype.piFinset X)
    (hmax : ∀ u ∈ Fintype.piFinset X, pricedScore p c C lam u ≤ pricedScore p c C lam t1) :
    q X hX p c C lam = pricedScore p c C lam t1 :=
  le_antisymm (Finset.sup'_le _ _ hmax) (Finset.le_sup' _ ht1)

/-- Weak duality (the card's main claim): for every price `lam ≥ 0`, the priced maximum
`q(lam)` is an upper bound on the profit of every booking that obeys both the stage rules
and the shared crew budget. So no legal booking can beat `q(lam)`. -/
theorem profit_le_lagrangian_bound (X : ∀ s, Finset (Finset (ι s))) (p c : ∀ s, ι s → ℝ)
    (C lam : ℝ) (hlam : 0 ≤ lam) (t : ∀ s, Finset (ι s)) (ht : t ∈ Fintype.piFinset X)
    (hcrew : crew c t ≤ C) :
    profit p t ≤ q X ⟨t, ht⟩ p c C lam := by
  have h1 : profit p t ≤ pricedScore p c C lam t := by
    unfold pricedScore
    nlinarith [mul_nonneg hlam (sub_nonneg.2 hcrew)]
  exact h1.trans (Finset.le_sup' _ ht)

/-- Decomposition: once the crew rule is a price, the priced maximum falls apart by stage.
`q(lam)` equals `lam * C` plus, for each stage, that stage's best plan scored by net value
`p - lam * c`. -/
theorem lagrangian_bound_decomposes (X : ∀ s, Finset (Finset (ι s))) (hX : ∀ s, (X s).Nonempty)
    (p c : ∀ s, ι s → ℝ) (C lam : ℝ) :
    q X (Fintype.piFinset_nonempty.2 hX) p c C lam =
      lam * C + ∑ s, (X s).sup' (hX s) (fun P => ∑ i ∈ P, (p s i - lam * c s i)) := by
  classical
  apply le_antisymm
  · apply Finset.sup'_le
    intro t ht
    rw [pricedScore_eq]
    gcongr with s hs
    exact Finset.le_sup' (fun P => ∑ i ∈ P, (p s i - lam * c s i)) (Fintype.mem_piFinset.1 ht s)
  · choose P hP hPeq using fun s =>
      (X s).exists_mem_eq_sup' (hX s) (fun P => ∑ i ∈ P, (p s i - lam * c s i))
    have hPmem : P ∈ Fintype.piFinset X := Fintype.mem_piFinset.2 hP
    calc _ = pricedScore p c C lam P := by
          rw [pricedScore_eq]
          congr 1
          exact Finset.sum_congr rfl (fun s _ => hPeq s)
      _ ≤ _ := Finset.le_sup' _ hPmem

/-- Geoffrion's theorem: when some booking obeys every rule (so the master program is
feasible), the best Lagrangian bound `z_LD = min over lam ≥ 0 of q(lam)` is attained, and it
equals the best profit when each stage may blend its whole plans with weights
`w s P ≥ 0` summing to 1, subject to the crew budget, but may not slice single acts. -/
theorem lagrangian_dual_eq_best_blend (X : ∀ s, Finset (Finset (ι s))) (p c : ∀ s, ι s → ℝ)
    (C : ℝ) (t : ∀ s, Finset (ι s)) (ht : t ∈ Fintype.piFinset X) (hcrew : crew c t ≤ C) :
    ∃ z : ℝ,
      IsLeast {v | ∃ lam : ℝ, 0 ≤ lam ∧ v = q X ⟨t, ht⟩ p c C lam} z ∧
      IsGreatest {v | ∃ w : ∀ s, Finset (ι s) → ℝ,
          (∀ s P, 0 ≤ w s P) ∧ (∀ s, ∑ P ∈ X s, w s P = 1) ∧
          ∑ s, ∑ P ∈ X s, w s P * (∑ i ∈ P, c s i) ≤ C ∧
          v = ∑ s, ∑ P ∈ X s, w s P * (∑ i ∈ P, p s i)} z := by
  classical
  have hXs : ∀ s, (X s).Nonempty := fun s => ⟨t s, Fintype.mem_piFinset.1 ht s⟩
  -- every blend that fits the crew budget is at most q(lam), for every lam ≥ 0
  have hub : ∀ lam : ℝ, 0 ≤ lam → ∀ w : ∀ s, Finset (ι s) → ℝ, (∀ s P, 0 ≤ w s P) →
      (∀ s, ∑ P ∈ X s, w s P = 1) →
      ∑ s, ∑ P ∈ X s, w s P * (∑ i ∈ P, c s i) ≤ C →
      ∑ s, ∑ P ∈ X s, w s P * (∑ i ∈ P, p s i) ≤ q X ⟨t, ht⟩ p c C lam := by
    intro lam hlam w hw0 hw1 hwc
    have hq : q X ⟨t, ht⟩ p c C lam = lam * C +
        ∑ s, (X s).sup' (hXs s) (fun P => ∑ i ∈ P, (p s i - lam * c s i)) :=
      lagrangian_bound_decomposes X hXs p c C lam
    rw [hq]
    have hs : ∀ s, ∑ P ∈ X s, w s P * (∑ i ∈ P, p s i) ≤
        (X s).sup' (hXs s) (fun P => ∑ i ∈ P, (p s i - lam * c s i)) +
          lam * ∑ P ∈ X s, w s P * (∑ i ∈ P, c s i) := by
      intro s
      set M := (X s).sup' (hXs s) (fun P => ∑ i ∈ P, (p s i - lam * c s i)) with hM
      have hP : ∀ P ∈ X s, w s P * (∑ i ∈ P, p s i) ≤
          w s P * M + lam * (w s P * (∑ i ∈ P, c s i)) := by
        intro P hP
        have hle : ∑ i ∈ P, (p s i - lam * c s i) ≤ M :=
          Finset.le_sup' (fun P => ∑ i ∈ P, (p s i - lam * c s i)) hP
        rw [Finset.sum_sub_distrib, ← Finset.mul_sum] at hle
        nlinarith [mul_le_mul_of_nonneg_left hle (hw0 s P)]
      calc _ ≤ ∑ P ∈ X s, (w s P * M + lam * (w s P * (∑ i ∈ P, c s i))) :=
            Finset.sum_le_sum hP
        _ = _ := by
          rw [Finset.sum_add_distrib, ← Finset.sum_mul, hw1 s, one_mul, ← Finset.mul_sum]
    have hsum := Finset.sum_le_sum (fun s (_ : s ∈ (Finset.univ : Finset σ)) => hs s)
    rw [Finset.sum_add_distrib, ← Finset.mul_sum] at hsum
    nlinarith [mul_le_mul_of_nonneg_left hwc hlam]
  -- find a price and two bookings that meet at it
  obtain ⟨lam, hlam, t1, ht1, t2, ht2, θ, hθ0, hθ1, hslack0, hslack, hmax, heq⟩ :=
    key_crossing (Fintype.piFinset X) (profit p) (fun u => C - crew c u) t ht (sub_nonneg.2 hcrew)
  have hq1 : q X ⟨t, ht⟩ p c C lam = pricedScore p c C lam t1 :=
    q_eq_of_max X ⟨t, ht⟩ p c C lam t1 ht1 (fun u hu => hmax u hu)
  let w : ∀ s, Finset (ι s) → ℝ := fun s P =>
    θ * (if P = t1 s then 1 else 0) + (1 - θ) * (if P = t2 s then 1 else 0)
  have hstage : ∀ s (g : Finset (ι s) → ℝ),
      ∑ P ∈ X s, w s P * g P = θ * g (t1 s) + (1 - θ) * g (t2 s) := by
    intro s g
    simp only [w, add_mul, Finset.sum_add_distrib, mul_assoc, ← Finset.mul_sum, ite_mul, one_mul,
      zero_mul, Finset.sum_ite_eq', Fintype.mem_piFinset.1 ht1 s, Fintype.mem_piFinset.1 ht2 s,
      ite_true]
  have hsum : ∀ g : ∀ s, Finset (ι s) → ℝ, ∑ s, ∑ P ∈ X s, w s P * g s P =
      θ * ∑ s, g s (t1 s) + (1 - θ) * ∑ s, g s (t2 s) := by
    intro g
    rw [Finset.sum_congr rfl (fun s _ => hstage s (g s)), Finset.sum_add_distrib,
      Finset.mul_sum, Finset.mul_sum]
  have hw0 : ∀ s P, 0 ≤ w s P := by
    intro s P
    exact add_nonneg (mul_nonneg hθ0 (by split_ifs <;> norm_num))
      (mul_nonneg (by linarith) (by split_ifs <;> norm_num))
  have hw1 : ∀ s, ∑ P ∈ X s, w s P = 1 := by
    intro s
    have h := hstage s (fun _ => 1)
    simp only [mul_one] at h
    rw [h]; ring
  have hcb : ∑ s, ∑ P ∈ X s, w s P * (∑ i ∈ P, c s i) = θ * crew c t1 + (1 - θ) * crew c t2 :=
    hsum (fun s P => ∑ i ∈ P, c s i)
  have hpb : ∑ s, ∑ P ∈ X s, w s P * (∑ i ∈ P, p s i) = θ * profit p t1 + (1 - θ) * profit p t2 :=
    hsum (fun s P => ∑ i ∈ P, p s i)
  have hval : ∑ s, ∑ P ∈ X s, w s P * (∑ i ∈ P, p s i) = q X ⟨t, ht⟩ p c C lam := by
    rw [hpb, hq1]
    simp only [pricedScore] at *
    linear_combination (1 - θ) * heq - hslack
  refine ⟨q X ⟨t, ht⟩ p c C lam, ⟨⟨lam, hlam, rfl⟩, ?_⟩, ⟨⟨w, hw0, hw1, ?_, hval.symm⟩, ?_⟩⟩
  · rintro v ⟨l, hl, rfl⟩
    rw [← hval]
    exact hub l hl w hw0 hw1 (by rw [hcb]; linarith)
  · rw [hcb]; linarith
  · rintro v ⟨w', h0', h1', hc', rfl⟩
    exact hub lam hlam w' h0' h1' hc' 

/-! ## The festival, checked exactly

Stages 0, 1, 2 are Main, Tent and Acoustic; acts 0, 1, 2 on each are M1 M2 M3, T1 T2 T3,
A1 A2 A3. Each stage has a 6-hour evening and the crew budget is 16 crew-hours. -/

/-- Stage hours of each act. -/
def hrs : Fin 3 → Fin 3 → ℕ := ![![3, 2, 4], ![4, 3, 3], ![2, 3, 4]]
/-- Crew-hours of each act. -/
def crw : Fin 3 → Fin 3 → ℤ := ![![2, 6, 6], ![5, 3, 2], ![6, 4, 2]]
/-- Profit of each act, in £k. -/
def prf : Fin 3 → Fin 3 → ℤ := ![![12, 12, 5], ![8, 7, 9], ![10, 12, 8]]
/-- The plans of each stage that fit its 6-hour evening. -/
def plans (s : Fin 3) : Finset (Finset (Fin 3)) :=
  (univ : Finset (Finset (Fin 3))).filter (fun P => ∑ i ∈ P, hrs s i ≤ 6)
/-- The bookings that also fit the 16 crew-hours. -/
def legal : Finset (Fin 3 → Finset (Fin 3)) :=
  (Fintype.piFinset plans).filter (fun t => ∑ s, ∑ i ∈ t s, crw s i ≤ 16)

-- Main has 6 plans that fit, Tent 5, Acoustic 6; 122 bookings fit the crew budget.
example : (plans 0).card = 6 ∧ (plans 1).card = 5 ∧ (plans 2).card = 6 := by decide
example : legal.card = 122 := by decide +kernel

-- The best real booking makes £48k: M1 + M2, T2 + T3, A3, using 15 crew-hours.
example : (∑ s, ∑ i ∈ (![{0, 1}, {1, 2}, {2}] : Fin 3 → Finset (Fin 3)) s, prf s i) = 48 ∧
    (∑ s, ∑ i ∈ (![{0, 1}, {1, 2}, {2}] : Fin 3 → Finset (Fin 3)) s, crw s i) = 15 := by decide
example : ∀ t ∈ legal, ∑ s, ∑ i ∈ t s, prf s i ≤ 48 := by decide +kernel

-- At a price of £2k per crew-hour, the stage maxima of net value are 8, 6 and 4.
example : (∀ P ∈ plans 0, ∑ i ∈ P, (prf 0 i - 2 * crw 0 i) ≤ 8) ∧
    (∀ P ∈ plans 1, ∑ i ∈ P, (prf 1 i - 2 * crw 1 i) ≤ 6) ∧
    (∀ P ∈ plans 2, ∑ i ∈ P, (prf 2 i - 2 * crw 2 i) ≤ 4) := by decide

-- So q(2) = 2 * 16 + 8 + 6 + 4 = 50, and it is reached by M1 + M2, T2 + T3, A2.
example : ∀ t ∈ Fintype.piFinset plans,
    ∑ s, ∑ i ∈ t s, prf s i + 2 * (16 - ∑ s, ∑ i ∈ t s, crw s i) ≤ 50 := by decide +kernel
example : (∑ s, ∑ i ∈ (![{0, 1}, {1, 2}, {1}] : Fin 3 → Finset (Fin 3)) s, prf s i) +
    2 * (16 - ∑ s, ∑ i ∈ (![{0, 1}, {1, 2}, {1}] : Fin 3 → Finset (Fin 3)) s, crw s i) = 50 := by
  decide

-- The blend that reaches £50k: M1 + M2, T2 + T3, and half of A2 with half of A3.
example : (24 : ℚ) + 16 + (1 / 2) * 12 + (1 / 2) * 8 = 50 ∧
    (8 : ℚ) + 5 + (1 / 2) * 4 + (1 / 2) * 2 = 16 := by norm_num

-- The LP booking: M1, 7/12 of M2, T2, T3, A2, 3/4 of A3 earns £53k with exactly 16 crew-hours.
example : (12 : ℚ) + 7 / 12 * 12 + 7 + 9 + 12 + 3 / 4 * 8 = 53 ∧
    (2 : ℚ) + 7 / 12 * 6 + 3 + 2 + 4 + 3 / 4 * 2 = 16 := by norm_num

end LagrangianRelaxation

open LagrangianRelaxation

#print axioms profit_le_lagrangian_bound
#print axioms lagrangian_bound_decomposes
#print axioms lagrangian_dual_eq_best_blend
#print axioms key_crossing
#print axioms pricedScore_eq
#print axioms q_eq_of_max
