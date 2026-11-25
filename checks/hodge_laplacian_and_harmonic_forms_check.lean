-- Hodge's theorem: on a finite cochain complex with an inner product, every cohomology class holds exactly one harmonic cochain, so the harmonic count is the Betti number, and the torus breeze splits into its average dx plus an exact part.
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.LinearAlgebra.Dimension.RankNullity
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open Real

variable {V₀ V₁ V₂ : Type*}
  [NormedAddCommGroup V₀] [InnerProductSpace ℝ V₀] [FiniteDimensional ℝ V₀]
  [NormedAddCommGroup V₁] [InnerProductSpace ℝ V₁] [FiniteDimensional ℝ V₁]
  [NormedAddCommGroup V₂] [InnerProductSpace ℝ V₂] [FiniteDimensional ℝ V₂]

/-- The Hodge Laplacian in the middle degree of `V₀ → V₁ → V₂`: `d δ + δ d`, where the
codifferential `δ` is the adjoint of `d` for the inner product (the grid version of Step 7). -/
noncomputable def hodgeLaplacian (d₀ : V₀ →ₗ[ℝ] V₁) (d₁ : V₁ →ₗ[ℝ] V₂) : V₁ →ₗ[ℝ] V₁ :=
  d₀ ∘ₗ LinearMap.adjoint d₀ + LinearMap.adjoint d₁ ∘ₗ d₁

theorem adjoint_apply_eq_zero_iff_mem_orthogonal_range
    (d₀ : V₀ →ₗ[ℝ] V₁) (ω : V₁) :
    LinearMap.adjoint d₀ ω = 0 ↔ ω ∈ (LinearMap.range d₀)ᗮ := by
  rw [Submodule.mem_orthogonal]
  constructor
  · rintro h u ⟨v, rfl⟩
    rw [← LinearMap.adjoint_inner_right, h, inner_zero_right]
  · intro h
    apply ext_inner_left ℝ
    intro v
    rw [LinearMap.adjoint_inner_right, inner_zero_right]
    exact h _ ⟨v, rfl⟩

#print axioms adjoint_apply_eq_zero_iff_mem_orthogonal_range

theorem inner_hodgeLaplacian_self
    (d₀ : V₀ →ₗ[ℝ] V₁) (d₁ : V₁ →ₗ[ℝ] V₂) (ω : V₁) :
    inner ℝ (hodgeLaplacian d₀ d₁ ω) ω =
      inner ℝ (LinearMap.adjoint d₀ ω) (LinearMap.adjoint d₀ ω) + inner ℝ (d₁ ω) (d₁ ω) := by
  simp only [hodgeLaplacian, LinearMap.add_apply, LinearMap.comp_apply, inner_add_left]
  rw [← LinearMap.adjoint_inner_right d₀, LinearMap.adjoint_inner_left d₁]

#print axioms inner_hodgeLaplacian_self

theorem hodgeLaplacian_eq_zero_iff
    (d₀ : V₀ →ₗ[ℝ] V₁) (d₁ : V₁ →ₗ[ℝ] V₂) (ω : V₁) :
    hodgeLaplacian d₀ d₁ ω = 0 ↔ d₁ ω = 0 ∧ LinearMap.adjoint d₀ ω = 0 := by
  constructor
  · intro h
    have h1 := inner_hodgeLaplacian_self d₀ d₁ ω
    rw [h, inner_zero_left] at h1
    have a := real_inner_self_nonneg (x := LinearMap.adjoint d₀ ω)
    have b := real_inner_self_nonneg (x := d₁ ω)
    refine ⟨(inner_self_eq_zero (𝕜 := ℝ)).mp (by linarith), (inner_self_eq_zero (𝕜 := ℝ)).mp (by linarith)⟩
  · rintro ⟨h1, h2⟩
    simp [hodgeLaplacian, h1, h2]

#print axioms hodgeLaplacian_eq_zero_iff

theorem harmonic_iff_closed_and_mem_orthogonal
    (d₀ : V₀ →ₗ[ℝ] V₁) (d₁ : V₁ →ₗ[ℝ] V₂) (ω : V₁) :
    hodgeLaplacian d₀ d₁ ω = 0 ↔ d₁ ω = 0 ∧ ω ∈ (LinearMap.range d₀)ᗮ := by
  rw [hodgeLaplacian_eq_zero_iff, adjoint_apply_eq_zero_iff_mem_orthogonal_range]

#print axioms harmonic_iff_closed_and_mem_orthogonal

theorem hasDerivAt_cos_antideriv (L : ℝ) (hL : 0 < L) (x : ℝ) :
    HasDerivAt (fun x => -(L / (2 * π)) * cos (2 * π * x / L))
      (sin (2 * π * x / L)) x := by
  have h1 : HasDerivAt (fun x => 2 * π * x / L) (2 * π / L) x := by
    simpa using ((hasDerivAt_id x).const_mul (2 * π)).div_const L
  have h2 := (h1.cos).const_mul (-(L / (2 * π)))
  convert h2 using 1
  field_simp [pi_ne_zero, hL.ne']

#print axioms hasDerivAt_cos_antideriv

theorem hasDerivAt_sin_sq_antideriv (L : ℝ) (hL : 0 < L) (x : ℝ) :
    HasDerivAt (fun x => x / 2 - L / (8 * π) * sin (2 * (2 * π * x / L)))
      (sin (2 * π * x / L) ^ 2) x := by
  have h1 : HasDerivAt (fun x => 2 * (2 * π * x / L)) (2 * (2 * π / L)) x := by
    simpa using (((hasDerivAt_id x).const_mul (2 * π)).div_const L).const_mul 2
  have h2 : HasDerivAt (fun x => x / 2 - L / (8 * π) * sin (2 * (2 * π * x / L)))
      (1 / 2 - L / (8 * π) * (cos (2 * (2 * π * x / L)) * (2 * (2 * π / L)))) x :=
    ((hasDerivAt_id' x).div_const 2).sub ((h1.sin).const_mul (L / (8 * π)))
  convert h2 using 1
  rw [cos_two_mul, cos_sq']
  field_simp [pi_ne_zero, hL.ne']
  ring

#print axioms hasDerivAt_sin_sq_antideriv

/-- Hodge's theorem, in its finite (grid) form: when `d` after `d` is zero, every closed
cochain `ω` has exactly one harmonic cochain `h` in its class (`ω - h` is exact), and so the
number of independent harmonic cochains is the Betti number, the dimension of the closed
cochains minus the dimension of the exact ones. -/
theorem every_class_has_exactly_one_harmonic_form
    (d₀ : V₀ →ₗ[ℝ] V₁) (d₁ : V₁ →ₗ[ℝ] V₂) (hdd : d₁ ∘ₗ d₀ = 0) :
    (∀ ω : V₁, d₁ ω = 0 →
      ∃! h : V₁, hodgeLaplacian d₀ d₁ h = 0 ∧ ω - h ∈ LinearMap.range d₀) ∧
    Module.finrank ℝ (LinearMap.ker (hodgeLaplacian d₀ d₁)) +
        Module.finrank ℝ (LinearMap.range d₀) =
      Module.finrank ℝ (LinearMap.ker d₁) := by
  have hrange : ∀ y ∈ LinearMap.range d₀, d₁ y = 0 := by
    rintro y ⟨v, rfl⟩
    exact LinearMap.congr_fun hdd v
  have hexists : ∀ ω : V₁, d₁ ω = 0 →
      ∃ h : V₁, hodgeLaplacian d₀ d₁ h = 0 ∧ ω - h ∈ LinearMap.range d₀ := by
    intro ω hω
    obtain ⟨y, hy, z, hz, rfl⟩ := (LinearMap.range d₀).exists_add_mem_mem_orthogonal ω
    refine ⟨z, ?_, by simpa using hy⟩
    rw [harmonic_iff_closed_and_mem_orthogonal]
    refine ⟨?_, hz⟩
    rw [map_add, hrange y hy, zero_add] at hω
    exact hω
  have hinf : LinearMap.ker (hodgeLaplacian d₀ d₁) ⊓ LinearMap.range d₀ = ⊥ := by
    rw [eq_bot_iff]
    rintro x ⟨hx1, hx2⟩
    rw [SetLike.mem_coe, LinearMap.mem_ker, harmonic_iff_closed_and_mem_orthogonal] at hx1
    have := (LinearMap.range d₀).inf_orthogonal_eq_bot
    rw [eq_bot_iff] at this
    exact this ⟨hx2, hx1.2⟩
  have hsup : LinearMap.ker (hodgeLaplacian d₀ d₁) ⊔ LinearMap.range d₀ = LinearMap.ker d₁ := by
    apply le_antisymm
    · apply sup_le
      · intro x hx
        rw [LinearMap.mem_ker, harmonic_iff_closed_and_mem_orthogonal] at hx
        exact hx.1
      · intro x hx
        exact hrange x hx
    · intro ω hω
      obtain ⟨h, hh, hd⟩ := hexists ω hω
      have : ω = h + (ω - h) := by abel
      rw [this]
      exact Submodule.add_mem_sup hh hd
  refine ⟨?_, ?_⟩
  · intro ω hω
    obtain ⟨h, hh, hd⟩ := hexists ω hω
    refine ⟨h, ⟨hh, hd⟩, ?_⟩
    rintro h' ⟨hh', hd'⟩
    have hmem : h' - h ∈ LinearMap.ker (hodgeLaplacian d₀ d₁) ⊓ LinearMap.range d₀ := by
      refine ⟨?_, ?_⟩
      · show hodgeLaplacian d₀ d₁ (h' - h) = 0
        rw [map_sub, hh, hh', sub_zero]
      · have := Submodule.sub_mem _ hd hd'
        rwa [show ω - h - (ω - h') = h' - h by abel] at this
    rw [hinf, Submodule.mem_bot, sub_eq_zero] at hmem
    exact hmem
  · have := Submodule.finrank_sup_add_finrank_inf_eq
      (LinearMap.ker (hodgeLaplacian d₀ d₁)) (LinearMap.range d₀)
    rw [hsup, hinf, finrank_bot, add_zero] at this
    exact this.symm

/-- Harmonic means closed and coclosed: the Hodge Laplacian kills a cochain exactly when
`d` kills it and the codifferential `δ` (the adjoint of `d`) kills it. -/
theorem harmonic_iff_closed_and_coclosed
    (d₀ : V₀ →ₗ[ℝ] V₁) (d₁ : V₁ →ₗ[ℝ] V₂) (ω : V₁) :
    hodgeLaplacian d₀ d₁ ω = 0 ↔ d₁ ω = 0 ∧ LinearMap.adjoint d₀ ω = 0 := by
  exact hodgeLaplacian_eq_zero_iff d₀ d₁ ω

/-- The card's breeze on a loop of length `L`: `(1 + sin(2πx/L)) dx` is its harmonic part `dx`
plus the exact part `d(-(L/2π) cos(2πx/L))`. The harmonic coefficient is the average, 1; the
mean squares are 3/2 for the breeze, 1 for `dx` and 1/2 for the exact part. -/
theorem breeze_splits_into_harmonic_dx_plus_exact (L : ℝ) (hL : 0 < L) :
    (∀ x : ℝ, HasDerivAt (fun x => -(L / (2 * π)) * cos (2 * π * x / L))
      (sin (2 * π * x / L)) x) ∧
    (1 / L) * ∫ x in (0 : ℝ)..L, (1 + sin (2 * π * x / L)) = 1 ∧
    (1 / L) * ∫ x in (0 : ℝ)..L, (1 + sin (2 * π * x / L)) ^ 2 = 3 / 2 ∧
    (1 / L) * ∫ x in (0 : ℝ)..L, (sin (2 * π * x / L)) ^ 2 = 1 / 2 := by
  have hc : Continuous fun x : ℝ => sin (2 * π * x / L) := by fun_prop
  have hLL : 2 * π * L / L = 2 * π := by field_simp
  have hs : sin (2 * (2 * π)) = 0 := by rw [sin_two_mul, sin_two_pi]; simp
  have hF := hasDerivAt_cos_antideriv L hL
  have hG := hasDerivAt_sin_sq_antideriv L hL
  refine ⟨hF, ?_, ?_, ?_⟩
  · rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun x => x + -(L / (2 * π)) * cos (2 * π * x / L))
      (fun x _ => (hasDerivAt_id x).add (hF x)) ((continuous_const.add hc).intervalIntegrable _ _)]
    simp only [hLL, cos_two_pi, mul_zero, zero_div, cos_zero]
    field_simp
    ring
  · have hd : ∀ x, HasDerivAt
        (fun x => x + 2 * (-(L / (2 * π)) * cos (2 * π * x / L)) +
          (x / 2 - L / (8 * π) * sin (2 * (2 * π * x / L))))
        ((1 + sin (2 * π * x / L)) ^ 2) x := by
      intro x
      exact (((hasDerivAt_id' x).add ((hF x).const_mul 2)).add (hG x)).congr_deriv (by ring)
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hd x)
      (((continuous_const.add hc).pow 2).intervalIntegrable _ _)]
    simp only [hLL, cos_two_pi, mul_zero, zero_div, cos_zero, sin_zero, hs]
    field_simp
    ring
  · rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hG x)
      ((hc.pow 2).intervalIntegrable _ _)]
    simp only [hLL, mul_zero, zero_div, sin_zero, hs]
    field_simp
    ring

-- The 8 x 4 grid torus: V - E + F = 32 - 64 + 32 = b0 - b1 + b2 = 1 - 2 + 1.
example : (8 * 4 : ℤ) - 2 * (8 * 4) + 8 * 4 = 1 - 2 + 1 := by norm_num
-- The cube standing in for the globe: 8 - 12 + 6 = 1 - 0 + 1.
example : (8 : ℤ) - 12 + 6 = 1 - 0 + 1 := by norm_num
-- Dropping half the Laplacian on the 8 x 4 grid: 64 - (32 - 1) = 33 "holes", not 2.
example : (64 : ℕ) - (32 - 1) = 33 := by norm_num

#print axioms every_class_has_exactly_one_harmonic_form
#print axioms harmonic_iff_closed_and_coclosed
#print axioms breeze_splits_into_harmonic_dx_plus_exact
