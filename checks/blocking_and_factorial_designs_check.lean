-- Blocking and factorial designs: in a randomised block design the strip effects cancel exactly from every contrast of the treatment averages, each two-by-two factorial effect then has variance σ²/r, and under complete randomisation the leftover strip imbalance has average zero and average square S_b²/r.
import Mathlib.Probability.Moments.Variance
import Mathlib.Probability.Independence.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.Prod
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp

open MeasureTheory ProbabilityTheory Finset

/-- Relabelling the plots by a permutation keeps every group size. -/
lemma deal_comp_perm {n r : ℕ} (a : Fin n → Fin 2 × Fin 2)
    (ha : ∀ k, (univ.filter fun i => a i = k).card = r)
    (σ : Equiv.Perm (Fin n)) : ∀ k, (univ.filter fun i => (a ∘ σ) i = k).card = r := by
  intro k
  rw [← ha k]
  exact Finset.card_equiv σ (by intro i; simp)

/-- Sums over deals are unchanged by relabelling the plots. -/
lemma sum_deals_comp_perm {n r : ℕ} (g : (Fin n → Fin 2 × Fin 2) → ℝ)
    (σ : Equiv.Perm (Fin n)) :
    ∑ a ∈ (univ.filter fun a : Fin n → Fin 2 × Fin 2 =>
        ∀ k, (univ.filter fun i => a i = k).card = r), g (a ∘ σ) =
      ∑ a ∈ (univ.filter fun a : Fin n → Fin 2 × Fin 2 =>
        ∀ k, (univ.filter fun i => a i = k).card = r), g a := by
  apply Finset.sum_nbij' (fun a => a ∘ σ) (fun a => a ∘ σ.symm)
  · intro a ha
    simp only [mem_filter, mem_univ, true_and] at ha ⊢
    exact deal_comp_perm a ha σ
  · intro a ha
    simp only [mem_filter, mem_univ, true_and] at ha ⊢
    exact deal_comp_perm a ha σ.symm
  · intro a _
    funext i
    simp
  · intro a _
    funext i
    simp
  · intro a _
    rfl

#print axioms deal_comp_perm
#print axioms sum_deals_comp_perm

/-- The strips cancel from every contrast. A two-by-two factorial is laid out in `r ≥ 1` strips,
and each of the four combinations `k = (f, w)` (fertiliser setting, water setting) appears exactly
once in each strip `j`. Strip effects add: the yield is `y j k = μ k + β j + ε j k`, the true mean
of the combination plus the strip's effect plus noise. Take any contrast: weights `c k` on the four
combination averages `ȳ k = (1/r) ∑ⱼ y j k` that add to zero. Then the contrast of the averages
equals the same contrast of the true means plus the contrast of the average noises, with no strip
term left, whatever the strip effects are. -/
theorem blocked_contrast_cancels_strip_effects
    (r : ℕ) (hr : 0 < r)
    (μ : Fin 2 × Fin 2 → ℝ) (β : Fin r → ℝ) (ε : Fin r → Fin 2 × Fin 2 → ℝ)
    (y : Fin r → Fin 2 × Fin 2 → ℝ) (hy : ∀ j k, y j k = μ k + β j + ε j k)
    (c : Fin 2 × Fin 2 → ℝ) (hc : ∑ k, c k = 0) :
    ∑ k, c k * ((1 / (r : ℝ)) * ∑ j, y j k) =
      ∑ k, c k * μ k + ∑ k, c k * ((1 / (r : ℝ)) * ∑ j, ε j k) := by
  have hr' : (r : ℝ) ≠ 0 := by exact_mod_cast hr.ne'
  have h1 : ∀ k, c k * ((1 / (r : ℝ)) * ∑ j, y j k) =
      c k * μ k + c k * ((1 / (r : ℝ)) * ∑ j, ε j k) + c k * ((∑ j, β j) / r) := by
    intro k
    simp only [hy, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      nsmul_eq_mul]
    field_simp
    ring
  simp only [h1, Finset.sum_add_distrib, ← Finset.sum_mul, hc, zero_mul, add_zero]

/-- With blocks, each effect is unbiased with variance `σ²/r`. Same layout and additive model:
`y j k = μ k + β j + ε (j, k)`, where the twelve (in general `4r`) plot noises are independent,
have finite variance, average zero, and all have the same variance `σ²`. Take one of the card's
contrasts: weights of plus or minus one half on the four combinations that add to zero (this
covers `F̂`, `Ŵ` and `Î`). Then the estimate `∑ₖ c k ȳ k` is centred on the true effect `∑ₖ c k μ k`, and its variance
is exactly `σ²/r`, the same for all three effects. -/
theorem blocked_factorial_effect_unbiased_and_variance
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (r : ℕ) (hr : 0 < r)
    (μ : Fin 2 × Fin 2 → ℝ) (β : Fin r → ℝ) (σ : ℝ)
    (ε : Fin r × (Fin 2 × Fin 2) → Ω → ℝ)
    (h_indep : iIndepFun ε P)
    (h_finite : ∀ i, MemLp (ε i) 2 P)
    (h_mean : ∀ i, P[ε i] = 0)
    (h_var : ∀ i, Var[ε i; P] = σ ^ 2)
    (c : Fin 2 × Fin 2 → ℝ) (hc : ∀ k, c k = 1 / 2 ∨ c k = -1 / 2) (hsum : ∑ k, c k = 0) :
    P[fun ω => ∑ k, c k * ((1 / (r : ℝ)) * ∑ j, (μ k + β j + ε (j, k) ω))] = ∑ k, c k * μ k ∧
      Var[fun ω => ∑ k, c k * ((1 / (r : ℝ)) * ∑ j, (μ k + β j + ε (j, k) ω)); P] =
        σ ^ 2 / r := by
  have hr' : (r : ℝ) ≠ 0 := by exact_mod_cast hr.ne'
  set Y : Fin r × (Fin 2 × Fin 2) → Ω → ℝ := fun i ω => (c i.2 / r) * ε i ω with hY
  have hX : (fun ω => ∑ k, c k * ((1 / (r : ℝ)) * ∑ j, (μ k + β j + ε (j, k) ω)))
      = fun ω => (∑ k, c k * μ k) + ∑ i, Y i ω := by
    funext ω
    have h1 : ∀ k, c k * ((1 / (r : ℝ)) * ∑ j, (μ k + β j + ε (j, k) ω)) =
        c k * μ k + ∑ j, Y (j, k) ω + c k * ((∑ j, β j) / r) := by
      intro k
      simp only [hY, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
        nsmul_eq_mul, ← Finset.mul_sum]
      field_simp
      ring
    rw [Finset.sum_congr rfl (fun k _ => h1 k)]
    simp only [Finset.sum_add_distrib, ← Finset.sum_mul, hsum, zero_mul, add_zero]
    congr 1
    rw [Finset.sum_comm]
    exact (Fintype.sum_prod_type (fun i => Y i ω)).symm
  have hYm : ∀ i, MemLp (Y i) 2 P := fun i => (h_finite i).const_mul _
  have hYi : ∀ i, Integrable (Y i) P := fun i => (hYm i).integrable one_le_two
  have hsumY : (fun ω => ∑ i, Y i ω) = ∑ i, Y i := by funext ω; simp
  rw [hX]
  constructor
  · rw [integral_add (integrable_const _) (integrable_finsetSum _ fun i _ => hYi i),
      integral_finsetSum _ fun i _ => hYi i]
    simp [hY, integral_const_mul, h_mean]
  · rw [variance_const_add, hsumY, IndepFun.variance_sum (fun i _ => hYm i)]
    · have hv : ∀ i, Var[Y i; P] = (c i.2 / r) ^ 2 * σ ^ 2 := by
        intro i
        rw [hY]
        simp only
        rw [variance_const_mul, h_var]
      simp only [hv]
      have hc2 : ∀ k, (c k / r) ^ 2 * σ ^ 2 = σ ^ 2 / (4 * r ^ 2) := by
        intro k
        rcases hc k with h | h <;> rw [h] <;> field_simp <;> ring
      simp only [hc2, Finset.sum_const, Finset.card_univ, Fintype.card_prod, Fintype.card_fin,
        nsmul_eq_mul]
      push_cast
      field_simp
    · intro i _ j _ hij
      exact (h_indep.indepFun hij).comp (measurable_const_mul _) (measurable_const_mul _)
    · rw [hsumY]
      exact (memLp_finsetSum' _ fun i _ => hYm i).aestronglyMeasurable

/-- Ignore the strips, and they become noise. Number the `N = 4r` plots and give plot `i` its
strip baseline `b i`. Complete randomisation deals the plots into the four combinations, `r` plots
each, every such deal equally likely. For a contrast with weights of plus or minus one half that
add to zero, the strip part of the estimate is `∑ₖ c k · (average of b over the plots dealt to k)`.
Over all deals this strip part averages exactly zero (no bias), and its average square, which is
then its variance, is exactly `S_b²/r`, where `S_b² = ∑ᵢ (b i − b̄)² / (N − 1)`. -/
theorem complete_randomisation_strip_imbalance
    (r : ℕ) (hr : 0 < r) (b : Fin (4 * r) → ℝ)
    (c : Fin 2 × Fin 2 → ℝ) (hc : ∀ k, c k = 1 / 2 ∨ c k = -1 / 2) (hsum : ∑ k, c k = 0) :
    let deals : Finset (Fin (4 * r) → Fin 2 × Fin 2) :=
      univ.filter fun a => ∀ k, (univ.filter fun i => a i = k).card = r
    let strip_part : (Fin (4 * r) → Fin 2 × Fin 2) → ℝ := fun a =>
      ∑ k, c k * ((1 / (r : ℝ)) * ∑ i ∈ univ.filter (fun i => a i = k), b i)
    let b_bar : ℝ := (∑ i, b i) / (4 * r : ℝ)
    let S_b2 : ℝ := (∑ i, (b i - b_bar) ^ 2) / (4 * r - 1 : ℝ)
    (∑ a ∈ deals, strip_part a) / deals.card = 0 ∧
      (∑ a ∈ deals, strip_part a ^ 2) / deals.card = S_b2 / r := by
  intro deals strip_part b_bar S_b2
  have hr' : (r : ℝ) ≠ 0 := by exact_mod_cast hr.ne'
  have hr1 : (1 : ℝ) ≤ r := by exact_mod_cast hr
  have hN1 : (4 * r - 1 : ℝ) ≠ 0 := by linarith
  have hc2 : ∀ k, c k * c k = 1 / 4 := by
    intro k; rcases hc k with h | h <;> rw [h] <;> norm_num
  have hmem : ∀ a, a ∈ deals ↔ ∀ k, (univ.filter fun i => a i = k).card = r := by
    intro a; simp [deals]
  have hsp : ∀ a, strip_part a = (1 / (r : ℝ)) * ∑ i, c (a i) * b i := by
    intro a
    simp only [strip_part]
    rw [← Finset.sum_fiberwise univ a (fun i => c (a i) * b i), Finset.mul_sum]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [Finset.mul_sum, Finset.mul_sum, Finset.mul_sum]
    refine Finset.sum_congr rfl fun i hi => ?_
    rw [(mem_filter.1 hi).2]; ring
  have hzero : ∀ a ∈ deals, ∑ i, c (a i) = 0 := by
    intro a ha
    rw [← Finset.sum_fiberwise univ a (fun i => c (a i))]
    have h : ∀ k, ∑ i ∈ univ.filter (fun i => a i = k), c (a i) = r * c k := by
      intro k
      rw [Finset.sum_congr rfl (fun i hi => show c (a i) = c k by rw [(mem_filter.1 hi).2]),
        sum_const, (hmem a).1 ha k, nsmul_eq_mul]
    simp only [h, ← Finset.mul_sum, hsum, mul_zero]
  have hinv : ∀ (g : (Fin (4 * r) → Fin 2 × Fin 2) → ℝ) (σ : Equiv.Perm (Fin (4 * r))),
      ∑ a ∈ deals, g (a ∘ σ) = ∑ a ∈ deals, g a := fun g σ => sum_deals_comp_perm g σ
  -- a deal exists
  have hne : deals.Nonempty := by
    let e : Fin 4 ≃ Fin 2 × Fin 2 := Fintype.equivOfCardEq (by simp)
    refine ⟨fun i => e (finProdFinEquiv.symm i).1, (hmem _).2 fun k => ?_⟩
    rw [Finset.card_equiv (finProdFinEquiv.symm) (t := ({e.symm k} ×ˢ univ))]
    · simp
    · intro i
      simp only [mem_filter, mem_univ, true_and, mem_product, mem_singleton, and_true]
      exact ⟨fun h => by rw [← h, Equiv.symm_apply_apply],
        fun h => by rw [h, Equiv.apply_symm_apply]⟩
  have hcard : (deals.card : ℝ) ≠ 0 := by exact_mod_cast hne.card_pos.ne'
  let i0 : Fin (4 * r) := ⟨0, by omega⟩
  let i1 : Fin (4 * r) := ⟨1, by omega⟩
  have h01 : i0 ≠ i1 := by simp [i0, i1, Fin.ext_iff]
  -- first moment
  set T : Fin (4 * r) → ℝ := fun i => ∑ a ∈ deals, c (a i) with hT
  have hTconst : ∀ i, T i = T i0 := by
    intro i
    have h := hinv (fun a => c (a i0)) (Equiv.swap i0 i)
    simp only [Function.comp_apply, Equiv.swap_apply_left] at h
    exact h
  have hTsum : ∑ i, T i = 0 := by
    simp only [hT]
    rw [Finset.sum_comm]
    exact Finset.sum_eq_zero hzero
  have hT0 : ∀ i, T i = 0 := by
    have h : ∑ i, T i = (4 * r : ℝ) * T i0 := by
      simp only [hTconst, sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]
      push_cast; ring
    intro i
    rw [hTconst]
    have h4 : (4 * r : ℝ) ≠ 0 := by positivity
    rw [hTsum] at h
    exact (mul_eq_zero.1 h.symm).resolve_left h4
  -- second moment
  set G : Fin (4 * r) → Fin (4 * r) → ℝ := fun i j => ∑ a ∈ deals, c (a i) * c (a j) with hG
  have hGperm : ∀ (σ : Equiv.Perm (Fin (4 * r))) i j, G (σ i) (σ j) = G i j :=
    fun σ i j => hinv (fun a => c (a i) * c (a j)) σ
  have hGdiag : ∀ i, G i i = deals.card / 4 := by
    intro i
    simp only [hG, hc2, sum_const, nsmul_eq_mul]
    ring
  have hGrow : ∀ i, ∑ j, G i j = 0 := by
    intro i
    simp only [hG]
    rw [Finset.sum_comm]
    exact Finset.sum_eq_zero fun a ha => by rw [← Finset.mul_sum, hzero a ha, mul_zero]
  set O := G i0 i1 with hO
  have hGoff : ∀ i j, i ≠ j → G i j = O := by
    intro i j hij
    set τ := Equiv.swap i0 i
    set m := τ i1
    have hm : m ≠ i := by
      intro h
      have : τ i1 = τ i0 := by rw [show τ i0 = i from Equiv.swap_apply_left _ _]; exact h
      exact h01 (τ.injective this).symm
    have h1 := hGperm τ i0 i1
    have h2 := hGperm (Equiv.swap m j) (τ i0) (τ i1)
    rw [show τ i0 = i from Equiv.swap_apply_left _ _] at h1 h2
    rw [Equiv.swap_apply_of_ne_of_ne hm.symm hij] at h2
    change G i (Equiv.swap m j m) = G i m at h2
    rw [Equiv.swap_apply_left] at h2
    rw [h2]
    exact h1
  have hGform : ∀ i j, G i j = O + if i = j then (deals.card / 4 - O) else 0 := by
    intro i j
    by_cases h : i = j
    · subst h; simp [hGdiag]
    · simp [h, hGoff i j h]
  have hOval : O = -(deals.card : ℝ) / (4 * (4 * r - 1)) := by
    have h := hGrow i0
    simp only [hGform, sum_add_distrib, sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul,
      Finset.sum_ite_eq, mem_univ, ite_true] at h
    push_cast at h
    field_simp
    linarith
  refine ⟨?_, ?_⟩
  · have h : ∑ a ∈ deals, strip_part a = 0 := by
      rw [Finset.sum_congr rfl (fun a _ => hsp a), ← Finset.mul_sum, Finset.sum_comm]
      simp_rw [← Finset.sum_mul]
      have h0 : ∀ x, (∑ a ∈ deals, c (a x)) = 0 := fun x => hT0 x
      simp [h0]
    rw [h, zero_div]
  · have hpair : ∀ i j, ∑ a ∈ deals, (c (a i) * b i) * (c (a j) * b j) = b i * b j * G i j := by
      intro i j
      simp only [hG, Finset.mul_sum]
      exact Finset.sum_congr rfl fun a _ => by ring
    have hsq : ∑ a ∈ deals, strip_part a ^ 2 =
        (1 / (r : ℝ)) ^ 2 * ∑ i, ∑ j, b i * b j * G i j := by
      calc ∑ a ∈ deals, strip_part a ^ 2
          = (1 / (r : ℝ)) ^ 2 * ∑ a ∈ deals, ∑ i, ∑ j, (c (a i) * b i) * (c (a j) * b j) := by
            rw [Finset.mul_sum]
            refine Finset.sum_congr rfl fun a _ => ?_
            rw [hsp a, mul_pow, sq (∑ i, c (a i) * b i), Finset.sum_mul_sum]
        _ = (1 / (r : ℝ)) ^ 2 * ∑ i, ∑ j, ∑ a ∈ deals, (c (a i) * b i) * (c (a j) * b j) := by
            rw [Finset.sum_comm]
            congr 1
            refine Finset.sum_congr rfl fun i _ => ?_
            rw [Finset.sum_comm]
        _ = (1 / (r : ℝ)) ^ 2 * ∑ i, ∑ j, b i * b j * G i j := by
            simp_rw [hpair]
    have hdouble : ∑ i, ∑ j, b i * b j * G i j =
        O * (∑ i, b i) ^ 2 + (deals.card / 4 - O) * ∑ i, b i ^ 2 := by
      simp only [hGform, mul_add, sum_add_distrib, mul_ite, mul_zero, Finset.sum_ite_eq,
        mem_univ, ite_true]
      rw [sq, Finset.sum_mul_sum, Finset.mul_sum, Finset.mul_sum]
      congr 1
      · refine Finset.sum_congr rfl fun i _ => ?_
        rw [Finset.mul_sum]
        exact Finset.sum_congr rfl fun j _ => by ring
      · exact Finset.sum_congr rfl fun i _ => by ring
    have hvar : ∑ i, (b i - b_bar) ^ 2 = ∑ i, b i ^ 2 - (∑ i, b i) ^ 2 / (4 * r) := by
      simp only [b_bar, sub_sq, sum_add_distrib, sum_sub_distrib, sum_const, card_univ,
        Fintype.card_fin, nsmul_eq_mul, ← Finset.sum_mul, ← Finset.mul_sum]
      push_cast
      field_simp
      ring
    rw [hsq, hdouble]
    simp only [S_b2]
    rw [hvar, hOval]
    have hN1' : (-1 + (r : ℝ) * 4) ≠ 0 := by linarith
    field_simp
    ring_nf
    field_simp
    ring

-- Worked numbers, by hand. The season: top 17, 19, 22, 34; middle 19, 24, 27, 35;
-- bottom 23, 31, 29, 39 (neither, fertiliser, water, both).
-- The four combination averages: 59/3 = 19.67, 74/3 = 24.67, 26, 36.
example : ((17 + 19 + 23 : ℚ) / 3) = 59 / 3 := by norm_num
example : ((19 + 24 + 31 : ℚ) / 3) = 74 / 3 := by norm_num
example : ((22 + 27 + 29 : ℚ) / 3) = 26 := by norm_num
example : ((34 + 35 + 39 : ℚ) / 3) = 36 := by norm_num
-- F̂ = 7.50, Ŵ = 53/6 = 8.83, Î = 2.50.
example : ((74 / 3 + 36 : ℚ) / 2 - (59 / 3 + 26) / 2) = 15 / 2 := by norm_num
example : ((26 + 36 : ℚ) / 2 - (59 / 3 + 74 / 3) / 2) = 53 / 6 := by norm_num
example : (((36 - 26 : ℚ) - (74 / 3 - 59 / 3)) / 2) = 5 / 2 := by norm_num
-- Fertiliser adds 5 on dry plots and 10 on watered ones; the additive guess for "both" is 31.
example : (74 / 3 - 59 / 3 : ℚ) = 5 ∧ (36 - 26 : ℚ) = 10 := by norm_num
example : (74 / 3 + 26 - 59 / 3 : ℚ) = 31 := by norm_num
-- Strip averages 23, 26.25, 30.50; overall average 319/12 = 26.58.
example : ((17 + 19 + 22 + 34 : ℚ) / 4) = 23 ∧ ((19 + 24 + 27 + 35 : ℚ) / 4) = 105 / 4 ∧
    ((23 + 31 + 29 + 39 : ℚ) / 4) = 61 / 2 := by norm_num
example : ((23 + 105 / 4 + 61 / 2 : ℚ) / 3) = 319 / 12 := by norm_num
-- Residual sum of squares 109/6 = 18.17 (yield − strip average − combination average + 319/12),
-- s² = 18.17/6 = 109/36 = 3.03, and the squared standard error s²/r = 109/108.
example :
    let g : ℚ := 319 / 12
    let res : ℚ → ℚ → ℚ → ℚ := fun y s m => y - s - m + g
    (res 17 23 (59/3))^2 + (res 19 23 (74/3))^2 + (res 22 23 26)^2 + (res 34 23 36)^2 +
    (res 19 (105/4) (59/3))^2 + (res 24 (105/4) (74/3))^2 + (res 27 (105/4) 26)^2 +
      (res 35 (105/4) 36)^2 +
    (res 23 (61/2) (59/3))^2 + (res 31 (61/2) (74/3))^2 + (res 29 (61/2) 26)^2 +
      (res 39 (61/2) 36)^2 = 109 / 6 := by norm_num
example : ((109 / 6 : ℚ) / ((3 - 1) * (4 - 1))) = 109 / 36 ∧ ((109 / 36 : ℚ) / 3) = 109 / 108 := by
  norm_num
-- Strips ignored: within-combination sum of squares 394/3 = 131.33 = 109/6 + strip SS 679/6 (113.17),
-- s² = (394/3)/8 = 197/12 = 16.42.
example : (109 / 6 + 679 / 6 : ℚ) = 394 / 3 := by norm_num
example : (4 * ((23 - 319 / 12) ^ 2 + (105 / 4 - 319 / 12) ^ 2 + (61 / 2 - 319 / 12) ^ 2) : ℚ) =
    679 / 6 := by norm_num
example : ((394 / 3 : ℚ) / (4 * (3 - 1))) = 197 / 12 := by norm_num
-- Step 4: strip effects −4, 0, +4 over 12 plots give S_b² = 8 · 4² / 11 = 128/11 = 11.64,
-- S_b²/r = 128/33 = 3.8788, and with σ² = 9/4 the variance ratio (σ² + S_b²)/σ² = 611/99 = 6.17.
example : ((8 * 4 ^ 2 : ℚ) / 11) = 128 / 11 ∧ ((128 / 11 : ℚ) / 3) = 128 / 33 := by norm_num
example : (((9 / 4 + 128 / 11 : ℚ) / 3) / ((9 / 4) / 3)) = 611 / 99 := by norm_num
-- 369,600 ways to deal twelve plots into four groups of three.
example : Nat.choose 12 3 * Nat.choose 9 3 * Nat.choose 6 3 * Nat.choose 3 3 = 369600 := by decide
-- Step 2: four weights squared 1/4, each average with variance σ²/r: σ²/r = 4σ²/N with N = 4r.
example (σ r : ℝ) (hr : r ≠ 0) : 4 * (1 / 4) * (σ ^ 2 / r) = 4 * σ ^ 2 / (4 * r) := by
  field_simp
-- Step 3: one-at-a-time on 12 plots (4 per setting) has variance 6σ²/12, and 18 plots
-- (6 per setting) are needed to reach the factorial's 4σ²/12.
example (σ : ℝ) : σ ^ 2 / 4 + σ ^ 2 / 4 = 6 * σ ^ 2 / 12 := by ring
example (σ : ℝ) : σ ^ 2 / 6 + σ ^ 2 / 6 = 4 * σ ^ 2 / 12 := by ring
example : 6 * 12 / 4 = 18 := by norm_num
-- The detailed proof's last step: 1/(rN) + 1/(rN(N − 1)) = 1/(r(N − 1)).
example (r N : ℝ) (hr : r ≠ 0) (hN : N ≠ 0) (hN1 : N - 1 ≠ 0) :
    1 / (r * N) + 1 / (r * N * (N - 1)) = 1 / (r * (N - 1)) := by
  field_simp
  ring
-- The Latin square (0 neither, 1 fertiliser, 2 water, 3 both): every symbol once in each strip
-- and once in each column.
example :
    let L : Fin 4 → Fin 4 → Fin 4 := ![![0, 1, 2, 3], ![1, 0, 3, 2], ![2, 3, 0, 1], ![3, 2, 1, 0]]
    (∀ j, Function.Bijective (L j)) ∧ (∀ col, Function.Bijective fun j => L j col) := by
  decide

#print axioms blocked_contrast_cancels_strip_effects
#print axioms blocked_factorial_effect_unbiased_and_variance
#print axioms complete_randomisation_strip_imbalance
