-- Frames in outline: if a family of building blocks measures every signal with between A and B times its energy, A > 0, then the frame operator can be undone, the dual blocks rebuild every signal, and an error e in the measurements moves the rebuild by at most ‖e‖/√A.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum

open scoped InnerProductSpace

theorem frame_op_exists
    {𝕜 : Type*} [RCLike 𝕜] {N : ℕ} {ι : Type*} [Fintype ι]
    (g : ι → EuclideanSpace 𝕜 (Fin N)) :
    ∃ L : EuclideanSpace 𝕜 (Fin N) →ₗ[𝕜] EuclideanSpace 𝕜 (Fin N),
      ∀ f, L f = ∑ k, ⟪g k, f⟫_𝕜 • g k :=
  ⟨{ toFun := fun f => ∑ k, ⟪g k, f⟫_𝕜 • g k
     map_add' := fun x y => by simp [inner_add_right, add_smul, Finset.sum_add_distrib]
     map_smul' := fun c x => by simp [inner_smul_right, mul_smul, Finset.smul_sum] },
   fun _ => rfl⟩


theorem frame_inner_self
    {𝕜 : Type*} [RCLike 𝕜] {N : ℕ} {ι : Type*} [Fintype ι]
    (g : ι → EuclideanSpace 𝕜 (Fin N)) (f : EuclideanSpace 𝕜 (Fin N)) :
    ⟪f, ∑ k, ⟪g k, f⟫_𝕜 • g k⟫_𝕜 = ((∑ k, ‖⟪g k, f⟫_𝕜‖ ^ 2 : ℝ) : 𝕜) := by
  rw [inner_sum]
  push_cast
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [inner_smul_right, ← inner_conj_symm f (g k), RCLike.mul_conj]


theorem frame_symm
    {𝕜 : Type*} [RCLike 𝕜] {N : ℕ} {ι : Type*} [Fintype ι]
    (g : ι → EuclideanSpace 𝕜 (Fin N)) (f h : EuclideanSpace 𝕜 (Fin N)) :
    ⟪∑ k, ⟪g k, f⟫_𝕜 • g k, h⟫_𝕜 = ⟪f, ∑ k, ⟪g k, h⟫_𝕜 • g k⟫_𝕜 := by
  rw [sum_inner, inner_sum]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [inner_smul_left, inner_smul_right, inner_conj_symm, mul_comm]

#print axioms frame_op_exists
#print axioms frame_inner_self
#print axioms frame_symm

/-- **The frame inequality gives a stable rebuild.** A signal is a list of `N` samples, real or
complex, with the card's inner product `⟨f, h⟩ = ∑_t f(t) conj(h(t))`; in Mathlib's convention
this is `⟪h, f⟫`, so the coefficient `⟨f, g_k⟩` is `⟪g k, f⟫`. Let `g_k` be a finite family of
building blocks with frame bounds `0 < A ≤ B`: for every signal `f`,
`A ‖f‖² ≤ ∑_k |⟨f, g_k⟩|² ≤ B ‖f‖²`. Then the frame operator `S f = ∑_k ⟨f, g_k⟩ g_k` can be
undone, its inverse enlarges a signal by at most `1/A`, every signal is rebuilt from its
measurements with the dual blocks, `f = ∑_k ⟨f, g_k⟩ S⁻¹ g_k`, and if the measurements carry an
error list `e`, the rebuild `S⁻¹ ∑_k (⟨f, g_k⟩ + e_k) g_k` is off from `f` by at most
`‖e‖ / √A`, where `‖e‖ = √(∑_k |e_k|²)`. -/
theorem frame_rebuild_error_le_error_div_sqrt_lower_bound
    {𝕜 : Type*} [RCLike 𝕜] {N : ℕ} {ι : Type*} [Fintype ι]
    (g : ι → EuclideanSpace 𝕜 (Fin N)) {A B : ℝ} (hA : 0 < A) (hAB : A ≤ B)
    (hframe : ∀ f : EuclideanSpace 𝕜 (Fin N),
      A * ‖f‖ ^ 2 ≤ ∑ k, ‖⟪g k, f⟫_𝕜‖ ^ 2 ∧ ∑ k, ‖⟪g k, f⟫_𝕜‖ ^ 2 ≤ B * ‖f‖ ^ 2) :
    ∃ S : EuclideanSpace 𝕜 (Fin N) ≃ₗ[𝕜] EuclideanSpace 𝕜 (Fin N),
      (∀ f, S f = ∑ k, ⟪g k, f⟫_𝕜 • g k) ∧
      (∀ f, ‖S.symm f‖ ≤ ‖f‖ / A) ∧
      (∀ f, f = ∑ k, ⟪g k, f⟫_𝕜 • S.symm (g k)) ∧
      (∀ (f : EuclideanSpace 𝕜 (Fin N)) (e : ι → 𝕜),
        ‖S.symm (∑ k, (⟪g k, f⟫_𝕜 + e k) • g k) - f‖ ≤
          Real.sqrt (∑ k, ‖e k‖ ^ 2) / Real.sqrt A) := by
  obtain ⟨L, hL⟩ := frame_op_exists g
  -- lower bound ‖L f‖ ≥ A ‖f‖
  have hlow : ∀ f, A * ‖f‖ ≤ ‖L f‖ := by
    intro f
    have h1 : A * ‖f‖ ^ 2 ≤ ‖f‖ * ‖L f‖ := by
      calc A * ‖f‖ ^ 2 ≤ ∑ k, ‖⟪g k, f⟫_𝕜‖ ^ 2 := (hframe f).1
        _ = ‖⟪f, L f⟫_𝕜‖ := by
          rw [hL, frame_inner_self, RCLike.norm_ofReal, abs_of_nonneg (Finset.sum_nonneg fun _ _ => by positivity)]
        _ ≤ ‖f‖ * ‖L f‖ := norm_inner_le_norm f (L f)
    rcases (norm_nonneg f).eq_or_lt with h0 | hpos
    · rw [← h0]; simp
    · nlinarith
  have hinj : Function.Injective L := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro f hf
    have := hlow f
    rw [hf, norm_zero] at this
    have : ‖f‖ ≤ 0 := by nlinarith
    exact norm_le_zero_iff.mp this
  set S := LinearEquiv.ofInjectiveEndo L hinj with hSdef
  have hS : ∀ f, S f = ∑ k, ⟪g k, f⟫_𝕜 • g k := fun f => hL f
  refine ⟨S, hS, ?_, ?_, ?_⟩
  · intro f
    rw [le_div_iff₀ hA, mul_comm]
    have := hlow (S.symm f)
    have h2 : L (S.symm f) = f := S.apply_symm_apply f
    rwa [h2] at this
  · intro f
    conv_lhs => rw [← S.symm_apply_apply f, hS, map_sum]
    simp only [map_smul]
  · intro f e
    set h := S.symm (∑ k, e k • g k) with hh
    have hkey : S.symm (∑ k, (⟪g k, f⟫_𝕜 + e k) • g k) - f = h := by
      simp only [add_smul, Finset.sum_add_distrib, map_add]
      rw [← hS, S.symm_apply_apply]
      abel
    rw [hkey]
    have hSh : ∑ k, ⟪g k, h⟫_𝕜 • g k = ∑ k, e k • g k := by
      rw [← hS, hh, S.apply_symm_apply]
    set Q := ∑ k, ‖⟪g k, h⟫_𝕜‖ ^ 2 with hQ
    set E := ∑ k, ‖e k‖ ^ 2 with hE
    have hQ0 : 0 ≤ Q := Finset.sum_nonneg fun _ _ => by positivity
    have hE0 : 0 ≤ E := Finset.sum_nonneg fun _ _ => by positivity
    have hQle : Q ≤ ∑ k, ‖e k‖ * ‖⟪g k, h⟫_𝕜‖ := by
      have : (Q : 𝕜) = ∑ k, e k * ⟪h, g k⟫_𝕜 := by
        rw [← frame_inner_self, hSh, inner_sum]
        refine Finset.sum_congr rfl fun k _ => ?_
        rw [inner_smul_right]
      have h3 : Q = ‖(Q : 𝕜)‖ := by
        rw [RCLike.norm_ofReal, abs_of_nonneg hQ0]
      rw [h3, this]
      refine (norm_sum_le _ _).trans (le_of_eq ?_)
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [norm_mul, ← inner_conj_symm, RCLike.norm_conj]
    have hCS := Finset.sum_mul_sq_le_sq_mul_sq Finset.univ (fun k => ‖e k‖) (fun k => ‖⟪g k, h⟫_𝕜‖)
    have hQE : Q ≤ E := by
      have : Q ^ 2 ≤ E * Q := by
        calc Q ^ 2 ≤ (∑ k, ‖e k‖ * ‖⟪g k, h⟫_𝕜‖) ^ 2 := pow_le_pow_left₀ hQ0 hQle 2
          _ ≤ E * Q := hCS
      rcases hQ0.eq_or_lt with h0 | hpos
      · rw [← h0]; exact hE0
      · nlinarith
    have hAh : A * ‖h‖ ^ 2 ≤ E := ((hframe h).1).trans hQE
    rw [← Real.sqrt_div' _ hA.le, show ‖h‖ = Real.sqrt (‖h‖ ^ 2) from
      (Real.sqrt_sq (norm_nonneg h)).symm]
    apply Real.sqrt_le_sqrt
    rw [le_div_iff₀ hA]
    linarith

/-- **A tight frame rebuilds with its own blocks.** If the frame is tight, `A = B > 0`, so that
`∑_k |⟨f, g_k⟩|² = A ‖f‖²` for every signal `f`, then the frame operator is `A` times the
identity and every signal is rebuilt with the blocks themselves, divided by `A`:
`f = (1/A) ∑_k ⟨f, g_k⟩ g_k`. -/
theorem tight_frame_rebuilds_with_its_own_blocks
    {𝕜 : Type*} [RCLike 𝕜] {N : ℕ} {ι : Type*} [Fintype ι]
    (g : ι → EuclideanSpace 𝕜 (Fin N)) {A : ℝ} (hA : 0 < A)
    (htight : ∀ f : EuclideanSpace 𝕜 (Fin N), ∑ k, ‖⟪g k, f⟫_𝕜‖ ^ 2 = A * ‖f‖ ^ 2) :
    ∀ f : EuclideanSpace 𝕜 (Fin N), f = (A : 𝕜)⁻¹ • ∑ k, ⟪g k, f⟫_𝕜 • g k := by
  obtain ⟨L, hL⟩ := frame_op_exists g
  set T := L - (A : 𝕜) • LinearMap.id with hT
  have hTsymm : T.IsSymmetric := by
    intro x y
    simp only [hT, LinearMap.sub_apply, LinearMap.smul_apply, LinearMap.id_apply, inner_sub_left,
      inner_sub_right, inner_smul_left, inner_smul_right, hL, frame_symm, RCLike.conj_ofReal]
  have hT0 : T = 0 := by
    rw [← hTsymm.inner_map_self_eq_zero]
    intro x
    simp only [hT, LinearMap.sub_apply, LinearMap.smul_apply, LinearMap.id_apply, inner_sub_left,
      inner_smul_left, RCLike.conj_ofReal, hL]
    rw [frame_symm, frame_inner_self, htight, inner_self_eq_norm_sq_to_K]
    push_cast
    ring
  intro f
  have := congrArg (fun M => M f) hT0
  simp only [hT, LinearMap.sub_apply, LinearMap.smul_apply, LinearMap.id_apply,
    LinearMap.zero_apply, hL, sub_eq_zero] at this
  rw [this, smul_smul, inv_mul_cancel₀ (by exact_mod_cast hA.ne'), one_smul]

/-- **A tight frame of unit blocks has `A` = blocks per dimension.** If every block has length 1
and the frame is tight with bound `A`, `∑_k |⟨f, g_k⟩|² = A ‖f‖²` for every signal of `N`
samples, then `A · N` is the number of blocks: for the Mercedes frame, three unit vectors in the
plane, `A = 3/2`. -/
theorem unit_tight_frame_bound_mul_dim_eq_card
    {𝕜 : Type*} [RCLike 𝕜] {N : ℕ} {ι : Type*} [Fintype ι]
    (g : ι → EuclideanSpace 𝕜 (Fin N)) {A : ℝ} (hunit : ∀ k, ‖g k‖ = 1)
    (htight : ∀ f : EuclideanSpace 𝕜 (Fin N), ∑ k, ‖⟪g k, f⟫_𝕜‖ ^ 2 = A * ‖f‖ ^ 2) :
    A * N = Fintype.card ι := by
  set b := EuclideanSpace.basisFun (Fin N) 𝕜
  have h1 : ∑ j, ∑ k, ‖⟪g k, b j⟫_𝕜‖ ^ 2 = A * N := by
    simp_rw [htight, b.orthonormal.1 _]
    simp [mul_comm]
  have h2 : ∑ k, ∑ j, ‖⟪g k, b j⟫_𝕜‖ ^ 2 = Fintype.card ι := by
    simp_rw [b.sum_sq_norm_inner_left, hunit]
    simp
  rw [← h1, ← h2, Finset.sum_comm]

-- Mercedes frame (unit vectors at 90, 210, 330 degrees): for f = (3/5, 4/5), of energy 1,
-- the squared coefficients add to 3/2 times the energy.
example : ((3 / 5 : ℝ) * 0 + 4 / 5 * 1) ^ 2
    + ((3 / 5 : ℝ) * (-(Real.sqrt 3 / 2)) + 4 / 5 * (-1 / 2)) ^ 2
    + ((3 / 5 : ℝ) * (Real.sqrt 3 / 2) + 4 / 5 * (-1 / 2)) ^ 2
    = 3 / 2 * ((3 / 5) ^ 2 + (4 / 5) ^ 2) := by
  ring_nf
  norm_num

-- Mercedes frame: the coefficients (1, 1, 1) build the zero vector, so coefficients are not unique.
example : ((0 : ℝ) + -(Real.sqrt 3 / 2) + Real.sqrt 3 / 2, (1 : ℝ) + -1 / 2 + -1 / 2) = (0, 0) := by
  norm_num

-- Mercedes frame: three unit blocks in two dimensions give A = 3/2.
example : (3 : ℚ) / 2 * 2 = 3 := by norm_num

-- The bird call: 10 s at 6400 samples a second is 64,000 samples; pitch 1000 + 150 × 10 = 2500 Hz.
example : (6400 : ℕ) * 10 = 64000 ∧ (1000 : ℕ) + 150 * 10 = 2500 := by norm_num

-- A 256-sample window lasts 256/6400 s = 40 ms; hop 128 is 20 ms; channels 6400/256 = 25 Hz apart.
example : (256 : ℚ) / 6400 = 40 / 1000 ∧ (128 : ℚ) / 6400 = 20 / 1000 ∧ (6400 : ℚ) / 256 = 25 := by
  norm_num

-- Hop 128 gives 64000/128 = 500 slices of 256 channels: 128,000 atoms, 2 per sample.
example : (64000 : ℕ) / 128 = 500 ∧ 500 * 256 = 128000 ∧ 128000 = 2 * 64000 := by norm_num

-- Grid area per atom: a = 20 ms, b = 25 Hz, so ab = 1/2; plain 40 ms blocks give ab = 1.
example : (20 / 1000 : ℚ) * 25 = 1 / 2 ∧ (40 / 1000 : ℚ) * 25 = 1 := by norm_num

-- Hann window of energy 1: H² · 3L/8 = 1 with H² = 8/(3 × 256), so M H² = 256 × 8/768 = 8/3,
-- and the limiting bounds are 8/3 × 1/2 = 4/3 and 8/3 × 1 = 8/3, with B/A = 2.
example : (8 / (3 * 256) : ℚ) * (3 * 256 / 8) = 1 ∧ (256 : ℚ) * (8 / (3 * 256)) = 8 / 3 ∧
    (8 / 3 : ℚ) * (1 / 2) = 4 / 3 ∧ (8 / 3 : ℚ) / (4 / 3) = 2 := by norm_num

-- Average of M G is atoms per sample, M/a: 256/128 = 2 at hop 128; 256/64 = 4 at hop 64,
-- with 64000/64 × 256 = 256,000 atoms.
example : (256 : ℕ) / 128 = 2 ∧ (256 : ℕ) / 64 = 4 ∧ 64000 / 64 * 256 = 256000 := by norm_num

-- Even channels only, hop 256: 64000/256 × 128 = 32,000 atoms for 64,000 samples;
-- channel 49 is 49 × 6400/256 = 1225 Hz.
example : (64000 : ℕ) / 256 * 128 = 32000 ∧ (49 : ℕ) * 6400 / 256 = 1225 := by norm_num

#print axioms frame_rebuild_error_le_error_div_sqrt_lower_bound
#print axioms tight_frame_rebuilds_with_its_own_blocks
#print axioms unit_tight_frame_bound_mul_dim_eq_card
