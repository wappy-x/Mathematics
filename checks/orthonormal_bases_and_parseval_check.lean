-- Orthonormal bases: for an orthonormal set in a Hilbert space the squared coefficients never exceed the energy, every square-summable list is some signal's list, energy in equals energy out for every signal exactly when no nonzero signal is perpendicular to the whole set, and every separable infinite-dimensional Hilbert space is a copy of ℓ².
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open scoped InnerProductSpace lp

variable {𝕜 : Type*} [RCLike 𝕜] {E : Type*} [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]

theorem orthonormal_dist_ge_one {ι : Type*} {e : ι → E} (he : Orthonormal 𝕜 e) {i j : ι}
    (hij : i ≠ j) : 1 ≤ ‖e i - e j‖ := by
  have h := @norm_sub_sq 𝕜 E _ _ _ (e i) (e j)
  rw [he.1 i, he.1 j, he.2 hij] at h
  simp at h
  nlinarith [norm_nonneg (e i - e j)]

theorem orthonormal_countable [TopologicalSpace.SeparableSpace E] {ι : Type*} {e : ι → E}
    (he : Orthonormal 𝕜 e) : Countable ι := by
  refine Pairwise.countable_of_isOpen_disjoint (s := fun i => Metric.ball (e i) (1 / 2))
    ?_ (fun _ => Metric.isOpen_ball) (fun i => ⟨e i, Metric.mem_ball_self (by norm_num : (0:ℝ) < 1 / 2)⟩)
  intro i j hij
  apply Metric.ball_disjoint_ball
  have := orthonormal_dist_ge_one he hij
  rw [dist_eq_norm]
  linarith

/-- Parseval's identity as the test of a basis. Let `e` be an orthonormal family in a Hilbert
space `E`. The squared coefficients `‖⟪e i, f⟫‖²` add up to the energy `‖f‖²` for every `f`
exactly when only the zero vector is perpendicular to every member `e i`. -/
theorem parseval_iff_complete [CompleteSpace E] {ι : Type*} {e : ι → E}
    (he : Orthonormal 𝕜 e) :
    (∀ f : E, HasSum (fun i => ‖⟪e i, f⟫_𝕜‖ ^ 2) (‖f‖ ^ 2)) ↔
      (∀ z : E, (∀ i, ⟪e i, z⟫_𝕜 = 0) → z = 0) := by
  constructor
  · intro h z hz
    have h1 := h z
    simp only [hz, norm_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow] at h1
    have h2 : ‖z‖ ^ 2 = 0 := (hasSum_zero.unique h1).symm
    simpa using h2
  · intro h f
    have hsp : (Submodule.span 𝕜 (Set.range e))ᗮ = ⊥ := by
      rw [Submodule.eq_bot_iff]
      intro z hz
      apply h z
      intro i
      exact Submodule.inner_right_of_mem_orthogonal (Submodule.subset_span (Set.mem_range_self i)) hz
    set b := HilbertBasis.mkOfOrthogonalEqBot he hsp
    have hb : ⇑b = e := HilbertBasis.coe_mkOfOrthogonalEqBot he hsp
    have h2 := lp.hasSum_norm (p := 2) (by norm_num) (b.repr f)
    simp only [ENNReal.toReal_ofNat, Real.rpow_two, b.repr_apply_apply, hb,
      LinearIsometryEquiv.norm_map] at h2
    exact h2

/-- Bessel's inequality and the Riesz–Fischer theorem. For any orthonormal family `e` in a
Hilbert space `E`: every vector's squared coefficients have a finite sum, at most its energy
`‖f‖²`; and every list `c` whose squared sizes have a finite sum is some vector's list of
coefficients, namely the sum `∑ c i • e i`, converging in norm. -/
theorem bessel_inequality_and_riesz_fischer [CompleteSpace E] {ι : Type*} {e : ι → E}
    (he : Orthonormal 𝕜 e) :
    (∀ f : E, Summable (fun i => ‖⟪e i, f⟫_𝕜‖ ^ 2) ∧ ∑' i, ‖⟪e i, f⟫_𝕜‖ ^ 2 ≤ ‖f‖ ^ 2) ∧
    (∀ c : ι → 𝕜, Summable (fun i => ‖c i‖ ^ 2) →
      ∃ g : E, HasSum (fun i => c i • e i) g ∧ ∀ i, ⟪e i, g⟫_𝕜 = c i) := by
  refine ⟨fun f => ⟨he.inner_products_summable f, he.tsum_inner_products_le f⟩, ?_⟩
  intro c hc
  have hs : Summable (fun i => c i • e i) := by
    have := (he.orthogonalFamily.summable_iff_norm_sq_summable c).2 hc
    simpa [LinearIsometry.toSpanSingleton_apply] using this
  refine ⟨∑' i, c i • e i, hs.hasSum, fun i => ?_⟩
  classical
  have h1 := hs.hasSum.mapL (innerSL 𝕜 (e i))
  have h2 : (fun j => (innerSL 𝕜 (e i)) (c j • e j)) = fun j => if j = i then c i else 0 := by
    funext j
    rw [innerSL_apply_apply, inner_smul_right, orthonormal_iff_ite.1 he]
    split_ifs with h1 h2 h2
    · subst h1; simp
    · exact absurd h1.symm h2
    · exact absurd h2.symm h1
    · simp
  rw [h2] at h1
  have h3 := h1.unique (hasSum_ite_eq i (c i))
  simpa [innerSL_apply_apply] using h3

/-- Every separable Hilbert space of infinite dimension is a copy of `ℓ²`: it has an orthonormal
sequence `e 0, e 1, …` that only the zero vector is perpendicular to, and sending each vector
to its list of coefficients `⟪e n, f⟫` is a linear map onto `ℓ²(ℕ, 𝕜)` that keeps norms. -/
theorem separable_hilbert_space_is_copy_of_l2 [CompleteSpace E]
    [TopologicalSpace.SeparableSpace E] (hE : ¬ FiniteDimensional 𝕜 E) :
    ∃ e : ℕ → E, Orthonormal 𝕜 e ∧ (∀ z : E, (∀ n, ⟪e n, z⟫_𝕜 = 0) → z = 0) ∧
      ∃ U : E ≃ₗᵢ[𝕜] ℓ²(ℕ, 𝕜), ∀ f n, U f n = ⟪e n, f⟫_𝕜 := by
  obtain ⟨w, b, -⟩ := exists_hilbertBasis 𝕜 E
  have hc : Countable w := orthonormal_countable b.orthonormal
  have hinf : Infinite w := by
    by_contra hfin
    rw [not_infinite_iff_finite] at hfin
    have := Fintype.ofFinite w
    exact hE (Module.Finite.of_basis b.toOrthonormalBasis.toBasis)
  obtain ⟨eqv⟩ : Nonempty (w ≃ ℕ) := nonempty_equiv_of_countable
  have ho : Orthonormal 𝕜 (b ∘ eqv.symm) := b.orthonormal.comp _ eqv.symm.injective
  have hsp : ⊤ ≤ (Submodule.span 𝕜 (Set.range (b ∘ eqv.symm))).topologicalClosure := by
    rw [Set.range_comp, Equiv.range_eq_univ, Set.image_univ, b.dense_span]
  set b' := HilbertBasis.mk ho hsp
  have hb' : ⇑b' = b ∘ eqv.symm := HilbertBasis.coe_mk ho hsp
  refine ⟨b ∘ eqv.symm, ho, ?_, b'.repr, ?_⟩
  · intro z hz
    apply b'.repr.injective
    rw [map_zero]
    ext n
    rw [b'.repr_apply_apply, hb', hz]
    rfl
  · intro f n
    rw [b'.repr_apply_apply, hb']

/-- The 8-sample rehearsal: the samples 0, √2/2, 1, √2/2, 0, 0, 0, 0 have mean square 1/4. -/
example : ((0 : ℝ) ^ 2 + (√2 / 2) ^ 2 + 1 ^ 2 + (√2 / 2) ^ 2 + 0 ^ 2 + 0 ^ 2 + 0 ^ 2 + 0 ^ 2) / 8
    = 1 / 4 := by
  ring_nf
  norm_num

/-- The rehearsal's four nonzero coefficients (1 + √2)/8, √2/4, −√2/8, (1 − √2)/8:
their squares add to the energy 1/4, Parseval with 8 sides. -/
example : ((1 + √2) / 8) ^ 2 + (√2 / 4) ^ 2 + (-√2 / 8) ^ 2 + ((1 - √2) / 8) ^ 2 = (1 : ℝ) / 4 := by
  ring_nf
  norm_num

/-- The clip's whole ledger: steady part 1/π², tone 1/8, even harmonics (2/π²)(π² − 8)/16,
together exactly the energy 1/4. -/
example : 1 / Real.pi ^ 2 + 1 / 8 + (2 / Real.pi ^ 2) * ((Real.pi ^ 2 - 8) / 16) = (1 : ℝ) / 4 := by
  have : Real.pi ≠ 0 := Real.pi_ne_zero
  field_simp
  ring

#print axioms orthonormal_dist_ge_one
#print axioms orthonormal_countable
#print axioms parseval_iff_complete
#print axioms bessel_inequality_and_riesz_fischer
#print axioms separable_hilbert_space_is_copy_of_l2
