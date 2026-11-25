-- Bochner's theorem: on a closed space the integrated Bochner formula forces every harmonic 1-form to vanish under positive Ricci curvature and to be parallel, at most n of them, under non-negative Ricci curvature, and on the round globe the integrated Weitzenböck identity reads 16π/3 = 8π/3 + 8π/3.
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.OpenPos
import Mathlib.LinearAlgebra.BilinearMap
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open MeasureTheory Real

/-- A continuous non-negative function on a compact space whose integral against a finite
measure that charges every nonempty open set is zero vanishes everywhere. -/
lemma bochner_continuous_nonneg_integral_zero
    {M : Type*} [TopologicalSpace M] [CompactSpace M] [MeasurableSpace M] [BorelSpace M]
    (μ : Measure M) [IsFiniteMeasure μ] [μ.IsOpenPosMeasure]
    (g : M → ℝ) (hg : Continuous g) (hnn : ∀ x, 0 ≤ g x) (hint : ∫ x, g x ∂μ = 0) :
    ∀ x, g x = 0 := by
  have hi : Integrable g μ :=
    hg.integrable_of_hasCompactSupport (HasCompactSupport.of_compactSpace g)
  have hae : g =ᵐ[μ] 0 := (integral_eq_zero_iff_of_nonneg (fun x => hnn x) hi).mp hint
  have h := (hg.ae_eq_iff_eq μ continuous_const).mp hae
  intro x
  exact congrFun h x

#print axioms bochner_continuous_nonneg_integral_zero

/-- Positive Ricci curvature leaves no harmonic 1-form. Mathlib has no Ricci curvature of a
Riemannian manifold, so the geometry enters as data at each point x of the space M: the form's
value ω(x) in the covectors E x, its covariant derivative ∇ω(x) in a normed space F x, Ricci
curvature Ric_x as a bilinear form on E x, and the half Laplacian (1/2) Δ_g |ω|² as a function.
The space is closed: compact, with its volume a finite measure that gives every nonempty open
set positive volume, and, having no edge, the Laplacian integrates to zero over it. If the
Bochner formula (1/2) Δ_g |ω|² = |∇ω|² + Ric(ω, ω) holds at every point and Ricci curvature is
positive, Ric_x(v, v) > 0 for every covector v ≠ 0, then ω = 0 at every point. -/
theorem positive_ricci_kills_harmonic_one_forms
    {M : Type*} [TopologicalSpace M] [CompactSpace M] [MeasurableSpace M] [BorelSpace M]
    (μ : Measure M) [IsFiniteMeasure μ] [μ.IsOpenPosMeasure]
    {E F : M → Type*} [∀ x, AddCommGroup (E x)] [∀ x, Module ℝ (E x)]
    [∀ x, NormedAddCommGroup (F x)]
    (ω : (x : M) → E x) (nablaω : (x : M) → F x)
    (Ric : (x : M) → LinearMap.BilinForm ℝ (E x)) (halfLap : M → ℝ)
    (h_cont_nabla : Continuous fun x => ‖nablaω x‖ ^ 2)
    (h_cont_ric : Continuous fun x => Ric x (ω x) (ω x))
    (h_bochner : ∀ x, halfLap x = ‖nablaω x‖ ^ 2 + Ric x (ω x) (ω x))
    (h_closed : ∫ x, halfLap x ∂μ = 0)
    (h_ric_pos : ∀ x (v : E x), v ≠ 0 → 0 < Ric x v v) :
    ∀ x, ω x = 0 := by
  have hcont : Continuous halfLap := by
    have : halfLap = fun x => ‖nablaω x‖ ^ 2 + Ric x (ω x) (ω x) := funext h_bochner
    rw [this]; exact h_cont_nabla.add h_cont_ric
  have hnn : ∀ x, 0 ≤ Ric x (ω x) (ω x) := by
    intro x
    by_cases h : ω x = 0
    · rw [h]; simp
    · exact (h_ric_pos x (ω x) h).le
  have hzero := bochner_continuous_nonneg_integral_zero μ halfLap hcont
    (fun x => by rw [h_bochner]; exact add_nonneg (sq_nonneg _) (hnn x)) h_closed
  intro x
  by_contra hx
  have h1 := h_ric_pos x (ω x) hx
  have h2 := hzero x
  rw [h_bochner] at h2
  nlinarith [sq_nonneg ‖nablaω x‖]

/-- Non-negative Ricci curvature leaves at most n harmonic 1-forms, all parallel. Take a
vector space H of harmonic 1-forms on a closed space M, each obeying the Bochner formula
(1/2) Δ_g |ω|² = |∇ω|² + Ric(ω, ω), with the Laplacian integrating to zero over M. If Ricci
curvature is non-negative, Ric_x(v, v) ≥ 0 for every covector v, then every form in H is
parallel, ∇ω = 0 everywhere. A parallel form is fixed by its value at one point p (parallel
transport), so if the covectors at p form a space of dimension n, then H has dimension at most n:
b_1 ≤ n. -/
theorem nonneg_ricci_harmonic_forms_parallel_and_at_most_n
    {M : Type*} [TopologicalSpace M] [CompactSpace M] [MeasurableSpace M] [BorelSpace M]
    (μ : Measure M) [IsFiniteMeasure μ] [μ.IsOpenPosMeasure]
    {E F : M → Type*} [∀ x, AddCommGroup (E x)] [∀ x, Module ℝ (E x)]
    [∀ x, NormedAddCommGroup (F x)]
    (H : Submodule ℝ ((x : M) → E x))
    (nabla : ((x : M) → E x) → (x : M) → F x)
    (Ric : (x : M) → LinearMap.BilinForm ℝ (E x))
    (halfLap : ((x : M) → E x) → M → ℝ)
    (h_cont_nabla : ∀ ω ∈ H, Continuous fun x => ‖nabla ω x‖ ^ 2)
    (h_cont_ric : ∀ ω ∈ H, Continuous fun x => Ric x (ω x) (ω x))
    (h_bochner : ∀ ω ∈ H, ∀ x, halfLap ω x = ‖nabla ω x‖ ^ 2 + Ric x (ω x) (ω x))
    (h_closed : ∀ ω ∈ H, ∫ x, halfLap ω x ∂μ = 0)
    (h_ric_nonneg : ∀ x (v : E x), 0 ≤ Ric x v v)
    (p : M) (n : ℕ) [FiniteDimensional ℝ (E p)] (h_dim : Module.finrank ℝ (E p) = n)
    (h_parallel : ∀ ω ∈ H, (∀ x, nabla ω x = 0) → ω p = 0 → ω = 0) :
    (∀ ω ∈ H, ∀ x, nabla ω x = 0) ∧ Module.rank ℝ H ≤ n := by
  have hpar : ∀ ω ∈ H, ∀ x, nabla ω x = 0 := by
    intro ω hω
    have hcont : Continuous (halfLap ω) := by
      have : halfLap ω = fun x => ‖nabla ω x‖ ^ 2 + Ric x (ω x) (ω x) := funext (h_bochner ω hω)
      rw [this]; exact (h_cont_nabla ω hω).add (h_cont_ric ω hω)
    have hzero := bochner_continuous_nonneg_integral_zero μ (halfLap ω) hcont
      (fun x => by rw [h_bochner ω hω]; exact add_nonneg (sq_nonneg _) (h_ric_nonneg x _))
      (h_closed ω hω)
    intro x
    have h2 := hzero x
    rw [h_bochner ω hω] at h2
    have h3 := h_ric_nonneg x (ω x)
    have h4 : ‖nabla ω x‖ ^ 2 = 0 := by nlinarith [sq_nonneg ‖nabla ω x‖]
    have h5 : ‖nabla ω x‖ = 0 := by simpa using h4
    exact norm_eq_zero.mp h5
  refine ⟨hpar, ?_⟩
  let ev : H →ₗ[ℝ] E p :=
    { toFun := fun ω => (ω : (x : M) → E x) p
      map_add' := fun a b => rfl
      map_smul' := fun c a => rfl }
  have hinj : Function.Injective ev := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro ω hω
    have h0 : (ω : (x : M) → E x) = 0 :=
      h_parallel ω ω.2 (hpar ω ω.2) hω
    exact Subtype.ext h0
  have : FiniteDimensional ℝ H := Module.Finite.of_injective ev hinj
  have hle : Module.finrank ℝ H ≤ n :=
    h_dim ▸ LinearMap.finrank_le_finrank_of_injective hinj
  rw [← Module.finrank_eq_rank]
  exact_mod_cast hle

/-- The whole globe, by hand. On the round globe of radius R, with polar angle φ and area
element R² sin φ dφ dθ, take the height f = R cos φ and ω = df. Its source is δω = 2 cos φ / R,
its change squared is |∇ω|² = 2 cos² φ / R², and its Ricci term is Ric(ω, ω) = sin² φ / R².
Integrated over the globe these give 16π/3, 8π/3 and 8π/3, whatever R is: the Weitzenböck
identity 16π/3 = 8π/3 + 8π/3 (the form has no swirl). -/
theorem globe_weitzenbock_integrals (R : ℝ) (hR : 0 < R) :
    2 * π * ∫ φ in (0 : ℝ)..π, (2 * cos φ / R) ^ 2 * (R ^ 2 * sin φ) = 16 * π / 3 ∧
    2 * π * ∫ φ in (0 : ℝ)..π, (2 * cos φ ^ 2 / R ^ 2) * (R ^ 2 * sin φ) = 8 * π / 3 ∧
    2 * π * ∫ φ in (0 : ℝ)..π, (sin φ ^ 2 / R ^ 2) * (R ^ 2 * sin φ) = 8 * π / 3 := by
  have hR0 : R ≠ 0 := hR.ne'
  -- ∫ cos² sin = 2/3 via the antiderivative -cos³/3
  have hc : ∫ φ in (0 : ℝ)..π, cos φ ^ 2 * sin φ = 2 / 3 := by
    have := intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun φ => -(cos φ ^ 3) / 3) (f' := fun φ => cos φ ^ 2 * sin φ) (a := 0) (b := π)
      (fun x _ => by
        have h := ((hasDerivAt_cos x).pow 3).neg.div_const 3
        convert h using 1; push_cast; ring)
      (by apply Continuous.intervalIntegrable; fun_prop)
    rw [this]; simp; norm_num
  -- ∫ sin³ = 4/3 via the antiderivative -cos + cos³/3
  have hs : ∫ φ in (0 : ℝ)..π, sin φ ^ 3 = 4 / 3 := by
    have := intervalIntegral.integral_eq_sub_of_hasDerivAt
      (f := fun φ => -cos φ + cos φ ^ 3 / 3) (f' := fun φ => sin φ ^ 3) (a := 0) (b := π)
      (fun x _ => by
        have h := (hasDerivAt_cos x).neg.add (((hasDerivAt_cos x).pow 3).div_const 3)
        convert h using 1; push_cast
        rw [show sin x ^ 3 = sin x * sin x ^ 2 by ring, sin_sq]; ring)
      (by apply Continuous.intervalIntegrable; fun_prop)
    rw [this]; simp; norm_num
  have e1 : (fun φ => (2 * cos φ / R) ^ 2 * (R ^ 2 * sin φ)) = fun φ => 4 * (cos φ ^ 2 * sin φ) := by
    funext φ; field_simp; ring
  have e2 : (fun φ => (2 * cos φ ^ 2 / R ^ 2) * (R ^ 2 * sin φ)) = fun φ => 2 * (cos φ ^ 2 * sin φ) := by
    funext φ; field_simp
  have e3 : (fun φ => (sin φ ^ 2 / R ^ 2) * (R ^ 2 * sin φ)) = fun φ => sin φ ^ 3 := by
    funext φ; field_simp
  refine ⟨?_, ?_, ?_⟩
  · rw [e1, intervalIntegral.integral_const_mul, hc]; ring
  · rw [e2, intervalIntegral.integral_const_mul, hc]; ring
  · rw [e3, hs]; ring

-- The closed forms on the globe add up: 16π/3 = 8π/3 + 8π/3.
example : 16 * π / 3 = 8 * π / 3 + 8 * π / 3 := by ring
-- London, by hand: with s = sin φ, c = cos φ, R⁴ |∇ω|² = 2c²/s⁴ = 2 (1/s²)(1/s² - 1).
example (s c : ℝ) (hs : s ≠ 0) (h : s ^ 2 + c ^ 2 = 1) :
    2 * c ^ 2 / s ^ 4 = 2 * (1 / s ^ 2) * (1 / s ^ 2 - 1) := by
  have hc : c ^ 2 = 1 - s ^ 2 := by linarith
  rw [hc]; field_simp
-- The code's triangulated surfaces: V - E + F = b_0 - b_1 + b_2 with the printed b_1.
-- Octahedron (a sphere): 6 - 12 + 8 = 1 - 0 + 1, so b_1 = 0.
example : (6 : ℤ) - 12 + 8 = 1 - 0 + 1 := by norm_num
-- 3 by 3 torus: 9 - 27 + 18 = 1 - 2 + 1, so b_1 = 2 = n, the equality case.
example : (9 : ℤ) - 27 + 18 = 1 - 2 + 1 := by norm_num
-- 3 by 1 band (an edge, so b_2 = 0): 6 - 12 + 6 = 1 - 1 + 0, so b_1 = 1.
example : (6 : ℤ) - 12 + 6 = 1 - 1 + 0 := by norm_num

#print axioms positive_ricci_kills_harmonic_one_forms
#print axioms nonneg_ricci_harmonic_forms_parallel_and_at_most_n
#print axioms globe_weitzenbock_integrals
