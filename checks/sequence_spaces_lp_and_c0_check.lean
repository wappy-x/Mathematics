-- Sequence spaces: the four sequence spaces nest strictly as ℓ¹ ⊂ ℓ² ⊂ c₀ ⊂ ℓ^∞, the norms nest the other way, and c₀ is separable while ℓ^∞ is not.
import Mathlib.Analysis.Normed.Lp.lpSpace
import Mathlib.Analysis.PSeries
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Topology.Order.LiminfLimsup
import Mathlib.Tactic.NormNum

open Filter Topology
open scoped ENNReal

/-- The chain of sequence spaces: every real sequence with finite 1-norm has finite 2-norm,
every sequence with finite 2-norm tends to 0, and every sequence tending to 0 is bounded;
each inclusion is strict (witnesses `1/n`, `1/√n` and the constant sequence `1`).
Here `ℓ^p` is Mathlib's `Memℓp` and `c₀` is the set of sequences tending to 0. -/
theorem lp_one_ssubset_lp_two_ssubset_c0_ssubset_lp_infty :
    {x : ℕ → ℝ | Memℓp x 1} ⊂ {x : ℕ → ℝ | Memℓp x 2} ∧
    {x : ℕ → ℝ | Memℓp x 2} ⊂ {x : ℕ → ℝ | Tendsto x atTop (𝓝 0)} ∧
    {x : ℕ → ℝ | Tendsto x atTop (𝓝 0)} ⊂ {x : ℕ → ℝ | Memℓp x ∞} := by
  have h1 : (1 : ℝ≥0∞).toReal = 1 := by norm_num
  have h2 : (2 : ℝ≥0∞).toReal = 2 := by norm_num
  have hp1 : (0 : ℝ) < (1 : ℝ≥0∞).toReal := by norm_num
  have hp2 : (0 : ℝ) < (2 : ℝ≥0∞).toReal := by norm_num
  refine ⟨⟨fun x hx => Memℓp.of_exponent_ge hx (by norm_num), fun h => ?_⟩,
    ⟨fun x hx => ?_, fun h => ?_⟩, ⟨fun x hx => ?_, fun h => ?_⟩⟩
  · -- witness 1/n: in ℓ², not in ℓ¹
    have hmem : Memℓp (fun n : ℕ => ((n : ℝ))⁻¹) 2 := by
      rw [memℓp_gen_iff hp2, h2]
      refine (Real.summable_nat_pow_inv (p := 2)).2 (by norm_num) |>.congr (fun n => ?_)
      simp [inv_pow]
    have := h hmem
    simp only [Set.mem_ofPred_eq] at this
    rw [memℓp_gen_iff hp1, h1] at this
    exact Real.not_summable_natCast_inv (this.congr (fun n => by simp))
  · -- ℓ² ⊆ c₀
    simp only [Set.mem_ofPred_eq] at hx ⊢
    have ht := (hx.summable hp2).tendsto_atTop_zero
    rw [h2] at ht
    have hs := (Real.continuous_sqrt.tendsto 0).comp ht
    rw [Real.sqrt_zero] at hs
    rw [tendsto_zero_iff_norm_tendsto_zero]
    refine hs.congr (fun i => ?_)
    rw [Function.comp_apply, Real.rpow_two, Real.sqrt_sq (norm_nonneg _)]
  · -- witness 1/√n: in c₀, not in ℓ²
    have ht : Tendsto (fun n : ℕ => (Real.sqrt n)⁻¹) atTop (𝓝 0) :=
      tendsto_inv_atTop_zero.comp (Real.tendsto_sqrt_atTop.comp tendsto_natCast_atTop_atTop)
    have := h ht
    simp only [Set.mem_ofPred_eq] at this
    rw [memℓp_gen_iff hp2, h2] at this
    refine Real.not_summable_natCast_inv (this.congr (fun n => ?_))
    rw [Real.rpow_two, norm_inv, Real.norm_eq_abs, abs_of_nonneg (Real.sqrt_nonneg _), inv_pow,
      Real.sq_sqrt (Nat.cast_nonneg _)]
  · -- c₀ ⊆ ℓ^∞
    simp only [Set.mem_ofPred_eq] at hx ⊢
    rw [memℓp_infty_iff]
    exact hx.norm.bddAbove_range
  · -- witness: the constant 1
    have hmem : Memℓp (fun _ : ℕ => (1 : ℝ)) ∞ := by
      rw [memℓp_infty_iff]
      exact ⟨1, by rintro _ ⟨n, rfl⟩; simp⟩
    have := h hmem
    simp only [Set.mem_ofPred_eq, tendsto_const_nhds_iff] at this
    norm_num at this

/-- The norms nest the other way: the sup norm of a sequence in `ℓ²` is at most its 2-norm,
and the 2-norm of a sequence in `ℓ¹` is at most its 1-norm. -/
theorem sup_norm_le_two_norm_le_one_norm :
    (∀ x : lp (fun _ : ℕ => ℝ) 2,
      ‖lp.linearMapOfLE ℝ (fun _ : ℕ => ℝ) (le_top : (2 : ℝ≥0∞) ≤ ∞) x‖ ≤ ‖x‖) ∧
    (∀ x : lp (fun _ : ℕ => ℝ) 1,
      ‖lp.linearMapOfLE ℝ (fun _ : ℕ => ℝ) (one_le_two : (1 : ℝ≥0∞) ≤ 2) x‖ ≤ ‖x‖) := by
  refine ⟨fun x => ?_, fun x => ?_⟩
  · refine lp.norm_le_of_forall_le (norm_nonneg x) (fun i => ?_)
    simpa using lp.norm_apply_le_norm (by norm_num : (2 : ℝ≥0∞) ≠ 0) x i
  · have hp : (0 : ℝ) < (2 : ℝ≥0∞).toReal := by norm_num
    refine lp.norm_le_of_forall_sum_le hp (norm_nonneg x) (fun s => ?_)
    have h1 := lp.sum_rpow_le_norm_rpow (by norm_num : (0 : ℝ) < (1 : ℝ≥0∞).toReal) x s
    have h2 : (2 : ℝ≥0∞).toReal = 2 := by norm_num
    simp only [lp.coe_linearMapOfLE_apply, ENNReal.toReal_one, Real.rpow_one] at h1 ⊢
    rw [h2]
    simp only [Real.rpow_two]
    calc ∑ i ∈ s, ‖x i‖ ^ 2 ≤ (∑ i ∈ s, ‖x i‖) ^ 2 :=
          Finset.sum_sq_le_sq_sum_of_nonneg (fun _ _ => norm_nonneg _)
      _ ≤ ‖x‖ ^ 2 := pow_le_pow_left₀ (Finset.sum_nonneg (fun _ _ => norm_nonneg _)) h1 2

/-- `c₀`, the sequences tending to 0 with the sup norm, is separable: some countable set comes
within any tolerance of every member. `ℓ^∞` is not separable. -/
theorem c0_separable_and_lp_infty_not_separable :
    TopologicalSpace.IsSeparable
      {x : lp (fun _ : ℕ => ℝ) ∞ | Tendsto (fun n => x n) atTop (𝓝 0)} ∧
    ¬ TopologicalSpace.SeparableSpace (lp (fun _ : ℕ => ℝ) ∞) := by
  constructor
  · -- finitely supported rational sequences form a countable set whose closure contains c₀
    let g : (Σ N : ℕ, Fin N → ℚ) → ℕ → ℝ :=
      fun q n => if h : n < q.1 then ((q.2 ⟨n, h⟩ : ℚ) : ℝ) else 0
    have hg : ∀ q, Memℓp (g q) ∞ := by
      intro q
      refine (memℓp_zero ?_).of_exponent_ge (by simp)
      refine (Set.finite_lt_nat q.1).subset ?_
      intro n hn
      by_contra h
      simp only [Set.mem_ofPred_eq] at hn h
      exact hn (by simp [g, h])
    let G : (Σ N : ℕ, Fin N → ℚ) → lp (fun _ : ℕ => ℝ) ∞ := fun q => ⟨g q, hg q⟩
    refine ⟨Set.range G, Set.countable_range G, ?_⟩
    intro x hx
    rw [Metric.mem_closure_iff]
    intro ε hε
    obtain ⟨N, hN⟩ := (Metric.tendsto_atTop.1 hx) (ε / 2) (by positivity)
    have hq : ∀ n : ℕ, ∃ r : ℚ, |x n - r| < ε / 2 := by
      intro n
      obtain ⟨r, hr1, hr2⟩ := exists_rat_btwn (show x n - ε / 2 < x n by linarith)
      exact ⟨r, by rw [abs_lt]; constructor <;> linarith⟩
    choose r hr using hq
    refine ⟨G ⟨N, fun i => r i⟩, ⟨_, rfl⟩, ?_⟩
    rw [dist_eq_norm]
    refine lt_of_le_of_lt (lp.norm_le_of_forall_le (by positivity : (0 : ℝ) ≤ ε / 2)
      (fun n => ?_)) (by linarith)
    rw [lp.coeFn_sub, Pi.sub_apply, Real.norm_eq_abs]
    show |x n - g ⟨N, fun i => r i⟩ n| ≤ ε / 2
    simp only [g]
    split_ifs with h
    · exact (hr n).le
    · have := hN n (not_lt.1 h)
      rw [Real.dist_eq, sub_zero] at this
      rw [sub_zero]
      exact this.le
  · -- the 0-1 sequences are uncountably many, pairwise at distance 1
    classical
    intro hsep
    obtain ⟨D, hDc, hDd⟩ := TopologicalSpace.exists_countable_dense (lp (fun _ : ℕ => ℝ) ∞)
    have hmem : ∀ A : Set ℕ, Memℓp (fun n => if n ∈ A then (1 : ℝ) else 0) ∞ := by
      intro A
      rw [memℓp_infty_iff]
      refine ⟨1, ?_⟩
      rintro _ ⟨n, rfl⟩
      dsimp only
      split_ifs <;> simp
    let f : Set ℕ → lp (fun _ : ℕ => ℝ) ∞ := fun A => ⟨_, hmem A⟩
    have hf : ∀ A B : Set ℕ, A ≠ B → 1 ≤ dist (f A) (f B) := by
      intro A B hAB
      obtain ⟨n, hn⟩ : ∃ n, ¬ (n ∈ A ↔ n ∈ B) := by
        by_contra h
        push Not at h
        exact hAB (Set.ext h)
      rw [dist_eq_norm]
      refine le_trans ?_ (lp.norm_apply_le_norm ENNReal.top_ne_zero _ n)
      rw [lp.coeFn_sub, Pi.sub_apply]
      show 1 ≤ ‖(if n ∈ A then (1 : ℝ) else 0) - (if n ∈ B then (1 : ℝ) else 0)‖
      by_cases hA : n ∈ A <;> by_cases hB : n ∈ B <;> simp_all
    have hpick : ∀ A : Set ℕ, ∃ d ∈ D, dist (f A) d < 1 / 2 :=
      fun A => hDd.exists_dist_lt (f A) (by norm_num)
    choose φ hφD hφ using hpick
    have hinj : Function.Injective (fun A : Set ℕ => (⟨φ A, hφD A⟩ : D)) := by
      intro A B hAB
      simp only [Subtype.mk.injEq] at hAB
      by_contra hne
      have h1 := hf A B hne
      have h2 := dist_triangle (f A) (φ A) (f B)
      have h4 : dist (φ A) (f B) < 1 / 2 := by rw [hAB, dist_comm]; exact hφ B
      linarith [hφ A]
    have : Countable D := hDc.to_subtype
    obtain ⟨e, he⟩ := Countable.exists_injective_nat D
    exact Function.cantor_injective _ (he.comp hinj)

-- The guitar note `x_n = r^(n-1)` with `r = 0.98 = 49/50`: 1-norm `1/(1 - r) = 50`.
example : (1 : ℚ) / (1 - 49 / 50) = 50 := by norm_num
-- Its sum of squares is `1/(1 - r²) = 2500/99 = 25.2525...`.
example : (1 : ℚ) / (1 - (49 / 50) ^ 2) = 2500 / 99 := by norm_num
-- The first five peaks: `0.98² = 0.9604`, `0.98³ = 0.941192`, `0.98⁴ = 0.92236816`.
example : ((49 : ℚ) / 50) ^ 2 = 9604 / 10000 := by norm_num
example : ((49 : ℚ) / 50) ^ 3 = 941192 / 1000000 := by norm_num
example : ((49 : ℚ) / 50) ^ 4 = 92236816 / 100000000 := by norm_num
-- The note is down to a thousandth (-60 dB) first after 342 cycles: `0.98^342 ≤ 0.001 < 0.98^341`.
set_option exponentiation.threshold 400 in
example : ((49 : ℚ) / 50) ^ 342 ≤ 1 / 1000 ∧ 1 / 1000 < ((49 : ℚ) / 50) ^ 341 := by norm_num
-- On/off patterns: 8 slots give 256 patterns and 32640 pairs; 10 slots give 1024 and 523776.
example : 2 ^ 8 = 256 ∧ 256 * 255 / 2 = 32640 := by norm_num
example : 2 ^ 10 = 1024 ∧ 1024 * 1023 / 2 = 523776 := by norm_num
-- The unit lists: `e₃ - e₇` has 1-norm 2 and sup norm 1.
example : |(1 : ℤ)| + |(-1 : ℤ)| = 2 ∧ max |(1 : ℤ)| |(-1 : ℤ)| = 1 := by norm_num

#print axioms lp_one_ssubset_lp_two_ssubset_c0_ssubset_lp_infty
#print axioms sup_norm_le_two_norm_le_one_norm
#print axioms c0_separable_and_lp_infty_not_separable
