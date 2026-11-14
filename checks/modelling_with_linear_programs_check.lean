-- Linear programs: a linear program "maximise c ⬝ x subject to A x ≤ b, x ≥ 0" with an allowed plan and a ceiling on the target has a best plan at a corner of its convex region, non-negative weights on the limits cap every plan, and the bakery's best plan is 12 sponge and 6 fruit for £840.
import Mathlib.Analysis.Convex.Extreme
import Mathlib.Analysis.Convex.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Real.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.NatFactorial
import Mathlib.Tactic.Linarith
import Mathlib.LinearAlgebra.Matrix.DotProduct
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Topology.Algebra.Module.FiniteDimension

open Matrix

/-- The allowed plans of a linear program in standard form: every list of amounts `x` that keeps
each limit row within its allowance (`A x ≤ b`, entry by entry) and has no negative amount
(`x ≥ 0`). One row of `A` per limit, one column per decision. -/
def allowedPlans {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) : Set (Fin n → ℝ) :=
  {x | A *ᵥ x ≤ b ∧ 0 ≤ x}

section CornerHelpers

open Filter Topology

/-- Helper: in a region cut out by finitely many limits `G k ⬝ᵥ x ≤ β k` that holds no whole
line, with a ceiling on the target, every allowed plan is matched or beaten by a corner. The
proof moves along a line inside the region until one more limit becomes tight. -/
theorem lp_helper_corner_above {n : ℕ} {ι : Type*} [Fintype ι]
    (G : ι → Fin n → ℝ) (β : ι → ℝ) (c : Fin n → ℝ)
    (hpt : ∀ d : Fin n → ℝ, (∀ k, G k ⬝ᵥ d = 0) → d = 0)
    (hceil : BddAbove ((fun x => c ⬝ᵥ x) '' {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k})) :
    ∀ N : ℕ, ∀ x ∈ {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k},
      (Finset.univ.filter (fun k => G k ⬝ᵥ x < β k)).card = N →
      ∃ v ∈ Set.extremePoints ℝ {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k},
        c ⬝ᵥ x ≤ c ⬝ᵥ v := by
  intro N
  induction N using Nat.strong_induction_on with
  | _ N ih =>
  intro x hx hN
  by_cases hext : x ∈ Set.extremePoints ℝ {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k}
  · exact ⟨x, hext, le_rfl⟩
  rw [mem_extremePoints_iff_left] at hext
  push Not at hext
  obtain ⟨y, hy, z, hz, hseg, hyx⟩ := hext hx
  obtain ⟨a, b', ha, hb, hab, hxe⟩ := hseg
  have hd0 : y - x ≠ 0 := sub_ne_zero.mpr hyx
  have htight : ∀ k, G k ⬝ᵥ x = β k → G k ⬝ᵥ (y - x) = 0 := by
    intro k hk
    have h1 : G k ⬝ᵥ y ≤ β k := hy k
    have h2 : G k ⬝ᵥ z ≤ β k := hz k
    have h3 : G k ⬝ᵥ x = a * (G k ⬝ᵥ y) + b' * (G k ⬝ᵥ z) := by
      rw [← hxe]; simp [dotProduct_add, dotProduct_smul]
    have h4 : a * β k + b' * β k = β k := by rw [← add_mul, hab, one_mul]
    have h5 : b' * (G k ⬝ᵥ z) ≤ b' * β k := mul_le_mul_of_nonneg_left h2 hb.le
    have h6 : G k ⬝ᵥ y = β k := by
      by_contra hne
      have h7 : a * (G k ⬝ᵥ y) < a * β k :=
        mul_lt_mul_of_pos_left (lt_of_le_of_ne h1 hne) ha
      linarith
    rw [dotProduct_sub, h6, hk, sub_self]
  have hex : ∃ e : Fin n → ℝ, 0 ≤ c ⬝ᵥ e ∧ (∀ k, G k ⬝ᵥ x = β k → G k ⬝ᵥ e = 0) ∧
      ∃ k, 0 < G k ⬝ᵥ e := by
    obtain ⟨k0, hk0⟩ : ∃ k, G k ⬝ᵥ (y - x) ≠ 0 := by
      by_contra h
      push Not at h
      exact hd0 (hpt _ h)
    obtain ⟨M, hM⟩ := hceil
    have unb : ∀ e : Fin n → ℝ, (∀ k, G k ⬝ᵥ e ≤ 0) → c ⬝ᵥ e ≤ 0 := by
      intro e he
      by_contra hce
      push Not at hce
      set t := (|M - c ⬝ᵥ x| + 1) / (c ⬝ᵥ e) with ht
      have ht0 : 0 ≤ t := by positivity
      have hmem : x + t • e ∈ {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k} := by
        intro k
        simp only [dotProduct_add, dotProduct_smul, smul_eq_mul]
        have := hx k
        have := he k
        nlinarith
      have hle := hM ⟨_, hmem, rfl⟩
      simp only [dotProduct_add, dotProduct_smul, smul_eq_mul] at hle
      have hte : t * (c ⬝ᵥ e) = |M - c ⬝ᵥ x| + 1 := div_mul_cancel₀ _ hce.ne'
      have := le_abs_self (M - c ⬝ᵥ x)
      linarith
    rcases le_total 0 (c ⬝ᵥ (y - x)) with hcd | hcd
    · by_cases hpos : ∃ k, 0 < G k ⬝ᵥ (y - x)
      · exact ⟨y - x, hcd, htight, hpos⟩
      · push Not at hpos
        have := unb _ hpos
        refine ⟨-(y - x), ?_, fun k hk => ?_, k0, ?_⟩
        · rw [dotProduct_neg]; linarith
        · rw [dotProduct_neg, htight k hk, neg_zero]
        · rw [dotProduct_neg]
          have := lt_of_le_of_ne (hpos k0) hk0
          linarith
    · by_cases hpos : ∃ k, 0 < G k ⬝ᵥ (-(y - x))
      · refine ⟨-(y - x), ?_, fun k hk => ?_, hpos⟩
        · rw [dotProduct_neg]; linarith
        · rw [dotProduct_neg, htight k hk, neg_zero]
      · push Not at hpos
        have h1 := unb _ hpos
        rw [dotProduct_neg] at h1
        refine ⟨y - x, by linarith, htight, k0, ?_⟩
        have h2 := hpos k0
        rw [dotProduct_neg] at h2
        exact lt_of_le_of_ne (by linarith) (Ne.symm hk0)
  obtain ⟨e, hce, hte, hkpos⟩ := hex
  have hS : (Finset.univ.filter (fun k => 0 < G k ⬝ᵥ e)).Nonempty := by
    obtain ⟨k, hk⟩ := hkpos
    exact ⟨k, by simp [hk]⟩
  obtain ⟨k0, hk0S, hk0min⟩ := (Finset.univ.filter (fun k => 0 < G k ⬝ᵥ e)).exists_min_image
    (fun k => (β k - G k ⬝ᵥ x) / (G k ⬝ᵥ e)) hS
  simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hk0S hk0min
  set t := (β k0 - G k0 ⬝ᵥ x) / (G k0 ⬝ᵥ e) with ht
  have ht0 : 0 ≤ t := div_nonneg (by linarith [hx k0]) hk0S.le
  have hGx' : ∀ k, G k ⬝ᵥ (x + t • e) = G k ⬝ᵥ x + t * G k ⬝ᵥ e := by
    intro k
    simp [dotProduct_add, dotProduct_smul]
  have hx' : x + t • e ∈ {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k} := by
    intro k
    rw [hGx']
    rcases le_or_gt (G k ⬝ᵥ e) 0 with hk | hk
    · nlinarith [hx k]
    · have := hk0min k hk
      rw [le_div_iff₀ hk] at this
      linarith
  have hk0t : G k0 ⬝ᵥ (x + t • e) = β k0 := by
    rw [hGx', ht, div_mul_cancel₀ _ hk0S.ne']
    ring
  have hk0s : G k0 ⬝ᵥ x < β k0 := by
    rcases (hx k0).lt_or_eq with h | h
    · exact h
    · exact absurd (hte k0 h) hk0S.ne'
  have hsub : Finset.univ.filter (fun k => G k ⬝ᵥ (x + t • e) < β k) ⊂
      Finset.univ.filter (fun k => G k ⬝ᵥ x < β k) := by
    rw [Finset.ssubset_iff_of_subset]
    · refine ⟨k0, by simp [hk0s], ?_⟩
      rw [Finset.mem_filter]
      rintro ⟨-, h⟩
      rw [hk0t] at h
      exact lt_irrefl _ h
    · intro k
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      intro hk
      rcases (hx k).lt_or_eq with h | h
      · exact h
      · rw [hGx', hte k h] at hk
        linarith
  obtain ⟨v, hv, hcv⟩ := ih _ (hN ▸ Finset.card_lt_card hsub) (x + t • e) hx' rfl
  refine ⟨v, hv, le_trans ?_ hcv⟩
  simp only [dotProduct_add, dotProduct_smul, smul_eq_mul]
  nlinarith

/-- Helper: a region cut out by finitely many limits has only finitely many corners, because
two corners with the same tight limits are equal. -/
theorem lp_helper_corners_finite {n : ℕ} {ι : Type*} [Fintype ι]
    (G : ι → Fin n → ℝ) (β : ι → ℝ) :
    (Set.extremePoints ℝ {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k}).Finite := by
  apply Set.Finite.of_finite_image (f := fun v => {k | G k ⬝ᵥ v = β k}) (Set.toFinite _)
  intro v hv w hw hvw
  simp only at hvw
  have hvP : ∀ k, G k ⬝ᵥ v ≤ β k := hv.1
  have hwP : ∀ k, G k ⬝ᵥ w ≤ β k := hw.1
  have hdt : ∀ k, G k ⬝ᵥ v = β k → G k ⬝ᵥ (w - v) = 0 := by
    intro k hk
    have hk' : k ∈ {k | G k ⬝ᵥ w = β k} := hvw ▸ hk
    simp only [Set.mem_ofPred_eq] at hk'
    rw [dotProduct_sub, hk, hk', sub_self]
  have hev : ∀ᶠ ε in 𝓝 (0 : ℝ), ∀ k, G k ⬝ᵥ (v - ε • (w - v)) ≤ β k := by
    rw [Filter.eventually_all]
    intro k
    rcases (hvP k).lt_or_eq with h | h
    · have hc : Tendsto (fun ε : ℝ => G k ⬝ᵥ v - ε * G k ⬝ᵥ (w - v)) (𝓝 0)
          (𝓝 (G k ⬝ᵥ v)) :=
        (continuous_const.sub (continuous_id.mul continuous_const)).tendsto' _ _ (by simp)
      filter_upwards [hc.eventually_lt_const h] with ε hε
      rw [dotProduct_sub, dotProduct_smul, smul_eq_mul]
      linarith
    · filter_upwards with ε
      rw [dotProduct_sub, dotProduct_smul, smul_eq_mul, hdt k h, h]
      simp
  obtain ⟨ε, hε, hεpos⟩ :=
    ((hev.filter_mono nhdsWithin_le_nhds).and (self_mem_nhdsWithin (s := Set.Ioi (0 : ℝ)))).exists
  have hεpos' : (0 : ℝ) < ε := hεpos
  have hseg : v ∈ openSegment ℝ (v - ε • (w - v)) w := by
    refine ⟨1 / (1 + ε), ε / (1 + ε), by positivity, by positivity, by field_simp, ?_⟩
    ext i
    simp only [Pi.add_apply, Pi.smul_apply, Pi.sub_apply, smul_eq_mul]
    field_simp
    ring
  exact ((mem_extremePoints.1 hv).2 _ hε _ hw.1 hseg).2.symm

/-- Helper: the corner theorem for any region cut out by finitely many limits that holds no
whole line. -/
theorem lp_helper_corner_general {n : ℕ} {ι : Type*} [Fintype ι]
    (G : ι → Fin n → ℝ) (β : ι → ℝ) (c : Fin n → ℝ)
    (hpt : ∀ d : Fin n → ℝ, (∀ k, G k ⬝ᵥ d = 0) → d = 0)
    (hfeas : {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k}.Nonempty)
    (hceil : BddAbove ((fun x => c ⬝ᵥ x) '' {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k})) :
    ∃ v ∈ Set.extremePoints ℝ {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k},
      ∀ p ∈ {x : Fin n → ℝ | ∀ k, G k ⬝ᵥ x ≤ β k}, c ⬝ᵥ p ≤ c ⬝ᵥ v := by
  obtain ⟨x0, hx0⟩ := hfeas
  obtain ⟨v0, hv0, -⟩ := lp_helper_corner_above G β c hpt hceil _ x0 hx0 rfl
  obtain ⟨v, hv, hmax⟩ :=
    Set.exists_max_image _ (fun x => c ⬝ᵥ x) (lp_helper_corners_finite G β) ⟨v0, hv0⟩
  refine ⟨v, hv, fun p hp => ?_⟩
  obtain ⟨w, hw, hpw⟩ := lp_helper_corner_above G β c hpt hceil _ p hp rfl
  exact hpw.trans (hmax w hw)

/-- Helper: the allowed plans written as one list of limits: the rows of `A`, and `-x j ≤ 0`
for each decision `j`. -/
theorem lp_helper_allowedPlans_eq {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) :
    allowedPlans A b = {x : Fin n → ℝ | ∀ k, Sum.elim (fun i => A i)
      (fun j => -(Pi.single j 1 : Fin n → ℝ)) k ⬝ᵥ x ≤ Sum.elim b 0 k} := by
  ext x
  simp only [allowedPlans, Set.mem_ofPred_eq, Sum.forall, Sum.elim_inl, Sum.elim_inr,
    Pi.le_def, Pi.zero_apply]
  simp [mulVec, dotProduct, Pi.single_apply]

end CornerHelpers

/-- The corner theorem. Maximise the straight-line target `c ⬝ᵥ x` over the plans with
`A x ≤ b` and `x ≥ 0`, with amounts that can be split (real numbers) and known, fixed numbers
`A`, `b`, `c`. If at least one plan fits every limit, and there is a ceiling (the target is
bounded above on the allowed plans), then the best plan is at a corner: some corner (extreme
point) of the region of allowed plans earns at least as much as every allowed plan. The card
proves this for two decisions; it holds for any number `n`. -/
theorem best_plan_is_at_a_corner {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) (c : Fin n → ℝ)
    (hfeas : (allowedPlans A b).Nonempty)
    (hceil : BddAbove ((fun x => c ⬝ᵥ x) '' allowedPlans A b)) :
    ∃ v ∈ Set.extremePoints ℝ (allowedPlans A b),
      ∀ p ∈ allowedPlans A b, c ⬝ᵥ p ≤ c ⬝ᵥ v := by
  rw [lp_helper_allowedPlans_eq] at hfeas hceil ⊢
  refine lp_helper_corner_general _ _ c ?_ hfeas hceil
  intro d hd
  funext j
  have h := hd (Sum.inr j)
  simp [dotProduct, Pi.single_apply] at h
  simpa using h

/-- The allowed plans form a convex region: a mix `t p + (1 - t) q` of two allowed plans, with
`t` between 0 and 1, is again an allowed plan. -/
theorem allowed_plans_convex {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ) :
    Convex ℝ (allowedPlans A b) := by
  intro x hx y hy a b' ha hb hab
  refine ⟨fun i => ?_, fun j => ?_⟩
  · have h1 := hx.1 i
    have h2 := hy.1 i
    simp only [mulVec_add, mulVec_smul, Pi.add_apply, Pi.smul_apply, smul_eq_mul]
    have h3 : a * (A *ᵥ x) i ≤ a * b i := mul_le_mul_of_nonneg_left h1 ha
    have h4 : b' * (A *ᵥ y) i ≤ b' * b i := mul_le_mul_of_nonneg_left h2 hb
    have h5 : a * b i + b' * b i = b i := by rw [← add_mul, hab, one_mul]
    linarith
  · have h1 := hx.2 j
    have h2 := hy.2 j
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply] at h1 h2 ⊢
    positivity

/-- The certificate. If non-negative weights `y` on the limits make the limit rows add up to
the target, term by term (`y A = c`), then no allowed plan earns more than the weighted
allowances: `c ⬝ᵥ x ≤ y ⬝ᵥ b` for every plan with `A x ≤ b` and `x ≥ 0`. -/
theorem weights_cap_every_plan {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (b : Fin m → ℝ)
    (c : Fin n → ℝ) (y : Fin m → ℝ) (hy : 0 ≤ y) (hrows : y ᵥ* A = c)
    (x : Fin n → ℝ) (hx : x ∈ allowedPlans A b) :
    c ⬝ᵥ x ≤ y ⬝ᵥ b := by
  rw [← hrows, ← dotProduct_mulVec]
  exact dotProduct_le_dotProduct_of_nonneg_left hx.1 hy

/-! The bakery: `x₁` sponge batches, `x₂` fruit-cake batches a day.
Maximise `40 x₁ + 60 x₂` with oven `2 x₁ + 4 x₂ ≤ 48`, flour `20 x₁ + 10 x₂ ≤ 300`,
demand `x₂ ≤ 10`, and `x₁, x₂ ≥ 0`. -/

-- 4 ovens × 12 hours = 48 oven hours.
example : 4 * 12 = 48 := by norm_num
-- The best plan (12, 6) fits: oven and flour exactly used, demand slack 4; margin £840.
example : (!![(2 : ℤ), 4; 20, 10; 0, 1] *ᵥ ![12, 6]) = ![48, 300, 6] := by decide
example : ![(48 : ℤ), 300, 10] - ![48, 300, 6] = ![0, 0, 4] := by decide
example : ![(40 : ℤ), 60] ⬝ᵥ ![12, 6] = 840 := by decide
-- By hand: x₁ = 24 - 2 x₂, then 20 (24 - 2 x₂) + 10 x₂ = 480 - 30 x₂ = 300 gives x₂ = 6, x₁ = 12.
example : 480 - 30 * 6 = 300 ∧ 24 - 2 * 6 = 12 := by norm_num
-- The other four corners (15, 0), (4, 10), (0, 10), (0, 0) earn £600, £760, £600 and £0.
example : 40 * 15 + 60 * 0 = 600 ∧ 40 * 4 + 60 * 10 = 760 ∧ 40 * 0 + 60 * 10 = 600 ∧
    40 * 0 + 60 * 0 = 0 := by norm_num
-- Corners checked: (15, 0) and (4, 10) fit every limit.
example : 2 * 15 + 4 * 0 ≤ 48 ∧ 20 * 15 + 10 * 0 ≤ 300 ∧
    2 * 4 + 4 * 10 ≤ 48 ∧ 20 * 4 + 10 * 10 ≤ 300 := by norm_num
-- The oven line meets the bottom axis at (24, 0), which needs 480 kg of flour: it breaks a limit.
example : 2 * 24 + 4 * 0 = 48 ∧ 20 * 24 + 10 * 0 = 480 ∧ 480 > 300 := by norm_num
-- No allowed plan, whole or split, earns more than £840.
example : ∀ x₁ x₂ : ℝ, 0 ≤ x₁ → 0 ≤ x₂ → 2 * x₁ + 4 * x₂ ≤ 48 → 20 * x₁ + 10 * x₂ ≤ 300 →
    x₂ ≤ 10 → 40 * x₁ + 60 * x₂ ≤ 840 := by
  intro x₁ x₂ _ _ h1 h2 _
  linarith
-- The certificate: weights 40/3 on oven and 2/3 on flour rebuild the margin row and cap it at
-- 640 + 200 = 840.
example : (40 / 3 : ℚ) * 2 + 2 / 3 * 20 = 40 ∧ (40 / 3 : ℚ) * 4 + 2 / 3 * 10 = 60 := by norm_num
example : (40 / 3 : ℚ) * 48 = 640 ∧ (2 / 3 : ℚ) * 300 = 200 ∧ (640 : ℚ) + 200 = 840 := by
  norm_num
-- Step 0: the midpoint (8, 8) of the oven edge from (12, 6) to (4, 10) earns £800, the average.
example : (12 + 4) / 2 = 8 ∧ (6 + 10) / 2 = 8 ∧ 40 * 8 + 60 * 8 = 800 ∧ (840 + 760) / 2 = 800 := by
  norm_num
-- Margin per oven hour: sponge 40 / 2 = £20, fruit 60 / 4 = £15.
example : 40 / 2 = 20 ∧ 60 / 4 = 15 := by norm_num
-- Grid of tenths: 11,481 of the 29,161 plans fit.
example : ((Finset.range 241 ×ˢ Finset.range 121).filter (fun p : ℕ × ℕ =>
    2 * p.1 + 4 * p.2 ≤ 480 ∧ 20 * p.1 + 10 * p.2 ≤ 3000 ∧ p.2 ≤ 100)).card = 11481 := by
  decide +kernel
example : 241 * 121 = 29161 := by norm_num
-- Leave out flour: (24, 0) "earns" £960.
example : 40 * 24 + 60 * 0 = 960 := by norm_num
-- With 310 kg of flour the program's plan is (38/3, 17/3), margin 2540/3 (about 846.67).
example : (2 : ℚ) * (38 / 3) + 4 * (17 / 3) = 48 ∧ (20 : ℚ) * (38 / 3) + 10 * (17 / 3) = 310 ∧
    (40 : ℚ) * (38 / 3) + 60 * (17 / 3) = 2540 / 3 := by norm_num
-- Rounding to (13, 6) claims £880 but is over by 2 oven hours and 10 kg of flour.
example : 40 * 13 + 60 * 6 = 880 ∧ 2 * 13 + 4 * 6 = 48 + 2 ∧ 20 * 13 + 10 * 6 = 310 + 10 := by
  norm_num
-- Rounding down to (12, 5) earns £780; the best whole plan with 310 kg is (12, 6), £840.
example : 40 * 12 + 60 * 5 = 780 ∧ 2 * 12 + 4 * 6 ≤ 48 ∧ 20 * 12 + 10 * 6 ≤ 310 := by norm_num
example : ∀ p < 25, ∀ q < 11, 2 * p + 4 * q ≤ 48 → 20 * p + 10 * q ≤ 310 →
    40 * p + 60 * q ≤ 840 := by
  decide
-- Mixed units, flour as 12 bags: the plan (0, 6/5) "earns" £72.
example : (40 : ℚ) * 0 + 60 * (6 / 5) = 72 ∧ (20 : ℚ) * 0 + 10 * (6 / 5) = 12 := by norm_num
-- At least 14 sponge: best plan (14, 2), £680. Exactly 8 fruit: best plan (8, 8), £800.
example : 2 * 14 + 4 * 2 ≤ 48 ∧ 20 * 14 + 10 * 2 = 300 ∧ 40 * 14 + 60 * 2 = 680 := by norm_num
example : 2 * 8 + 4 * 8 = 48 ∧ 20 * 8 + 10 * 8 ≤ 300 ∧ 40 * 8 + 60 * 8 = 800 := by norm_num
-- At least 20 sponge is infeasible: it needs more than 300 kg of flour.
example : ∀ x₁ x₂ : ℝ, 20 ≤ x₁ → 0 ≤ x₂ → ¬ (20 * x₁ + 10 * x₂ ≤ 300) := by
  intro x₁ x₂ h1 h2 h3
  linarith
-- Try: sponge margin £130 gives (15, 0), £1,950; sponge margin £20 gives (4, 10), £680.
example : 130 * 15 + 60 * 0 = 1950 ∧ 20 * 4 + 60 * 10 = 680 := by norm_num
-- Try: 400 kg of flour gives (56/3, 8/3), margin 2720/3 (about 906.67).
example : (2 : ℚ) * (56 / 3) + 4 * (8 / 3) = 48 ∧ (20 : ℚ) * (56 / 3) + 10 * (8 / 3) = 400 ∧
    (40 : ℚ) * (56 / 3) + 60 * (8 / 3) = 2720 / 3 := by norm_num
-- Candidates: 5 choose 2 = 10; 30 choose 10 = 30,045,015; 60 choose 20 = 4,191,844,505,805,495.
example : Nat.choose 5 2 = 10 := by decide
example : Nat.choose 30 10 = 30045015 := by
  rw [Nat.choose_eq_descFactorial_div_factorial]; norm_num [Nat.factorial]
example : Nat.choose 60 20 = 4191844505805495 := by
  rw [Nat.choose_eq_descFactorial_div_factorial]; norm_num [Nat.factorial]

#print axioms lp_helper_corner_above
#print axioms lp_helper_corners_finite
#print axioms lp_helper_corner_general
#print axioms lp_helper_allowedPlans_eq
#print axioms best_plan_is_at_a_corner
#print axioms allowed_plans_convex
#print axioms weights_cap_every_plan
