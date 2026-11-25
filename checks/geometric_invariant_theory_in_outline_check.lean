-- Quotients by group actions: for a finite group the spectrum of the invariant ring has one point per orbit, invariants are constant on orbit closures, and j takes equal values exactly on the six reorderings of a cross-ratio.
import Mathlib.RingTheory.Invariant.Basic
import Mathlib.RingTheory.Ideal.Pointwise
import Mathlib.RingTheory.Spectrum.Prime.Basic
import Mathlib.Topology.Separation.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic

open scoped Pointwise

/-- The j-coordinate of four points on the line with cross-ratio `l`:
`j = 256 (l^2 - l + 1)^3 / (l^2 (l - 1)^2)`. -/
def jOfLambda {K : Type*} [Field K] (l : K) : K :=
  256 * (l ^ 2 - l + 1) ^ 3 / (l ^ 2 * (l - 1) ^ 2)

/-- The cross-ratio of four points: where `z₄` lands when `z₁, z₂, z₃` go to `0, ∞, 1`. -/
def crossRatio {K : Type*} [Field K] (z₁ z₂ z₃ z₄ : K) : K :=
  (z₄ - z₁) * (z₃ - z₂) / ((z₄ - z₂) * (z₃ - z₁))

/-- The binary-quartic invariant `I = a₀a₄ - 4a₁a₃ + 3a₂²`. -/
def quarticI {K : Type*} [Field K] (a₀ a₁ a₂ a₃ a₄ : K) : K :=
  a₀ * a₄ - 4 * a₁ * a₃ + 3 * a₂ ^ 2

/-- The binary-quartic invariant `J = a₀a₂a₄ + 2a₁a₂a₃ - a₀a₃² - a₁²a₄ - a₂³`. -/
def quarticJ {K : Type*} [Field K] (a₀ a₁ a₂ a₃ a₄ : K) : K :=
  a₀ * a₂ * a₄ + 2 * a₁ * a₂ * a₃ - a₀ * a₃ ^ 2 - a₁ ^ 2 * a₄ - a₂ ^ 3

/-- Clearing denominators: the difference of two j-values factors into the six
linear factors `μ - σ(l)`, one for each reordering `σ`. -/
theorem jOfLambda_cross_mul_factor (l μ : ℂ) :
    (μ ^ 2 - μ + 1) ^ 3 * (l ^ 2 * (l - 1) ^ 2) - (l ^ 2 - l + 1) ^ 3 * (μ ^ 2 * (μ - 1) ^ 2)
      = -((μ - l) * (l * μ - 1) * (μ - 1 + l) * ((1 - l) * μ - 1) * ((l - 1) * μ - l) *
          (l * μ - (l - 1))) := by
  ring

#print axioms jOfLambda_cross_mul_factor

/-- For a finite group `G` acting on the coordinate ring `B` of a space over a field `k`,
the quotient `Spec k[X]^G` has one point per orbit: every prime of the invariant ring
comes from a prime of `B`, and two primes of `B` give the same point of the quotient
exactly when the group moves one onto the other. -/
theorem spec_invariants_one_point_per_orbit (k B G : Type*) [Field k] [CommRing B]
    [Algebra k B] [Group G] [Finite G] [MulSemiringAction G B] [SMulCommClass G k B] :
    (∀ q : PrimeSpectrum (FixedPoints.subalgebra k B G),
        ∃ P : Ideal B, P.IsPrime ∧
          P.comap (algebraMap (FixedPoints.subalgebra k B G) B) = q.asIdeal) ∧
    (∀ P Q : Ideal B, P.IsPrime → Q.IsPrime →
        (P.comap (algebraMap (FixedPoints.subalgebra k B G) B) =
            Q.comap (algebraMap (FixedPoints.subalgebra k B G) B) ↔
          ∃ g : G, Q = g • P)) := by
  have : Algebra.IsIntegral (FixedPoints.subalgebra k B G) B :=
    Algebra.IsInvariant.isIntegral (FixedPoints.subalgebra k B G) B G
  refine ⟨fun q => ?_, fun P Q hP hQ => ⟨fun h => ?_, ?_⟩⟩
  · obtain ⟨P, -, hP, hPq⟩ := Ideal.exists_ideal_over_prime_of_isIntegral q.asIdeal (⊥ : Ideal B)
      (by
        intro x hx
        rw [Ideal.mem_comap, Ideal.mem_bot] at hx
        have : x = 0 := Subtype.ext hx
        rw [this]; exact q.asIdeal.zero_mem)
    exact ⟨P, hP, hPq⟩
  · exact Algebra.IsInvariant.exists_smul_of_under_eq (FixedPoints.subalgebra k B G) B G P Q h
  · rintro ⟨g, rfl⟩
    exact (Ideal.under_smul (FixedPoints.subalgebra k B G) P g).symm

/-- An invariant cannot separate an orbit from its limit: a continuous function that the
group leaves alone takes the same value at two points whose orbit closures meet. -/
theorem invariant_agrees_when_orbit_closures_meet {G X Y : Type*} [Group G] [MulAction G X]
    [TopologicalSpace X] [TopologicalSpace Y] [T1Space Y]
    (f : X → Y) (hf : Continuous f) (hinv : ∀ (g : G) (x : X), f (g • x) = f x)
    (x y : X)
    (hmeet : (closure (MulAction.orbit G x) ∩ closure (MulAction.orbit G y)).Nonempty) :
    f x = f y := by
  have key : ∀ a : X, closure (MulAction.orbit G a) ⊆ f ⁻¹' {f a} := by
    intro a
    apply closure_minimal
    · rintro _ ⟨g, rfl⟩
      simp [hinv]
    · exact isClosed_singleton.preimage hf
  obtain ⟨z, hzx, hzy⟩ := hmeet
  have h1 : f z = f x := key x hzx
  have h2 : f z = f y := key y hzy
  rw [← h1, h2]

/-- Over ℂ, for cross-ratios of four distinct points (`λ, μ ≠ 0, 1`), the j-invariant takes
equal values exactly when `μ` is one of the six reorderings
`λ, 1/λ, 1 - λ, 1/(1 - λ), λ/(λ - 1), (λ - 1)/λ`. -/
theorem j_eq_iff_six_reorderings (l μ : ℂ) (hl0 : l ≠ 0) (hl1 : l ≠ 1)
    (hμ0 : μ ≠ 0) (hμ1 : μ ≠ 1) :
    jOfLambda μ = jOfLambda l ↔
      (μ = l ∨ μ = 1 / l ∨ μ = 1 - l ∨ μ = 1 / (1 - l) ∨
        μ = l / (l - 1) ∨ μ = (l - 1) / l) := by
  have hl1' : l - 1 ≠ 0 := sub_ne_zero.mpr hl1
  have hl1'' : 1 - l ≠ 0 := sub_ne_zero.mpr (Ne.symm hl1)
  have hμ1' : μ - 1 ≠ 0 := sub_ne_zero.mpr hμ1
  have hDl : l ^ 2 * (l - 1) ^ 2 ≠ 0 := by positivity
  have hDμ : μ ^ 2 * (μ - 1) ^ 2 ≠ 0 := by positivity
  have step1 : jOfLambda μ = jOfLambda l ↔
      (μ ^ 2 - μ + 1) ^ 3 * (l ^ 2 * (l - 1) ^ 2) - (l ^ 2 - l + 1) ^ 3 * (μ ^ 2 * (μ - 1) ^ 2)
        = 0 := by
    unfold jOfLambda
    rw [div_eq_div_iff hDμ hDl, sub_eq_zero]
    constructor
    · intro h; linear_combination h / 256
    · intro h; linear_combination 256 * h
  rw [step1, jOfLambda_cross_mul_factor, neg_eq_zero]
  simp only [mul_eq_zero, sub_eq_zero]
  have e2 : l * μ = 1 ↔ μ = 1 / l := by
    rw [eq_div_iff hl0]; constructor <;> intro h <;> linear_combination h
  have e3 : μ - 1 + l = 0 ↔ μ = 1 - l := by
    constructor <;> intro h <;> linear_combination h
  have e4 : (1 - l) * μ = 1 ↔ μ = 1 / (1 - l) := by
    rw [eq_div_iff hl1'']; constructor <;> intro h <;> linear_combination h
  have e5 : (l - 1) * μ = l ↔ μ = l / (l - 1) := by
    rw [eq_div_iff hl1']; constructor <;> intro h <;> linear_combination h
  have e6 : l * μ = l - 1 ↔ μ = (l - 1) / l := by
    rw [eq_div_iff hl0]; constructor <;> intro h <;> linear_combination h
  rw [e2, e4, e5, e6]
  simp only [e3, or_assoc]

-- The posts at 0, 10, 20, 30 m and the photo at 0, 200, 300, 360 px share cross-ratio 3/4.
example : crossRatio (0 : ℚ) 10 20 30 = 3 / 4 := by norm_num [crossRatio]
example : crossRatio (0 : ℚ) 200 300 360 = 3 / 4 := by norm_num [crossRatio]
-- The camera z ↦ 600z/(z + 20) sends the posts to the photo.
example : ((fun z : ℚ => 600 * z / (z + 20)) '' {0, 10, 20, 30}) = {0, 200, 300, 360} := by
  norm_num [Set.image_insert_eq]
-- The 24 orderings of the posts give the six values -3, -1/3, 1/4, 3/4, 4/3, 4.
example : (1 / (3 / 4 : ℚ), 1 - (3 / 4 : ℚ), 1 / (1 - (3 / 4 : ℚ)),
    (3 / 4 : ℚ) / (3 / 4 - 1), (3 / 4 - 1 : ℚ) / (3 / 4)) = (4 / 3, 1 / 4, 4, -3, -1 / 3) := by
  norm_num
-- j of the posts, by hand: 256 × (13/16)^3 / (9/256) = 35152/9.
example : (3 / 4 : ℚ) ^ 2 - 3 / 4 + 1 = 13 / 16 := by norm_num
example : (3 / 4 : ℚ) ^ 2 * (3 / 4 - 1) ^ 2 = 9 / 256 := by norm_num
example : jOfLambda (3 / 4 : ℚ) = 35152 / 9 := by norm_num [jOfLambda]
-- All six reorderings give the same j.
example : jOfLambda (-3 : ℚ) = 35152 / 9 ∧ jOfLambda (-1 / 3 : ℚ) = 35152 / 9 ∧
    jOfLambda (1 / 4 : ℚ) = 35152 / 9 ∧ jOfLambda (4 / 3 : ℚ) = 35152 / 9 ∧
    jOfLambda (4 : ℚ) = 35152 / 9 := by
  norm_num [jOfLambda]
-- The posts' quartic x(x - 10y)(x - 20y)(x - 30y) = x^4 - 60x^3y + 1100x^2y^2 - 6000xy^3.
example (x y : ℚ) : x * (x - 10 * y) * (x - 20 * y) * (x - 30 * y) =
    x ^ 4 - 60 * x ^ 3 * y + 1100 * x ^ 2 * y ^ 2 - 6000 * x * y ^ 3 := by ring
-- Its I and J (a₀..a₄ = 1, -15, 550/3, -1500, 0), and j = 1728 I^3 / (I^3 - 27 J^2) = 35152/9.
example : quarticI (1 : ℚ) (-15) (550 / 3) (-1500) 0 = 32500 / 3 := by norm_num [quarticI]
example : quarticJ (1 : ℚ) (-15) (550 / 3) (-1500) 0 = -4375000 / 27 := by norm_num [quarticJ]
example : 1728 * (32500 / 3 : ℚ) ^ 3 / ((32500 / 3) ^ 3 - 27 * (-4375000 / 27) ^ 2) = 35152 / 9 := by
  norm_num
-- The harmonic set λ = -1, 2, 1/2: j = 256 × 27/4 = 1728.
example : jOfLambda (-1 : ℚ) = 256 * (27 / 4) ∧ (256 : ℚ) * (27 / 4) = 1728 := by
  norm_num [jOfLambda]
example : jOfLambda (2 : ℚ) = 1728 ∧ jOfLambda (1 / 2 : ℚ) = 1728 := by norm_num [jOfLambda]
-- xy(x - y)(x + y) = x^3y - xy^3 has J = 0 and j = 1728.
example : quarticJ (0 : ℚ) (1 / 4) 0 (-1 / 4) 0 = 0 := by norm_num [quarticJ]
-- The stability table: x y^3 has I = J = 0; x^2 y^2 and x^2 y^2 - x^3 y have I = 1/12, J = -1/216.
example : quarticI (0 : ℚ) 0 0 (1 / 4) 0 = 0 ∧ quarticJ (0 : ℚ) 0 0 (1 / 4) 0 = 0 := by
  norm_num [quarticI, quarticJ]
example : quarticI (0 : ℚ) 0 (1 / 6) 0 0 = 1 / 12 ∧ quarticJ (0 : ℚ) 0 (1 / 6) 0 0 = -1 / 216 ∧
    (1 / 12 : ℚ) ^ 3 - 27 * (-1 / 216) ^ 2 = 0 := by
  norm_num [quarticI, quarticJ]
example : quarticI (0 : ℚ) (-1 / 4) (1 / 6) 0 0 = 1 / 12 ∧
    quarticJ (0 : ℚ) (-1 / 4) (1 / 6) 0 0 = -1 / 216 := by
  norm_num [quarticI, quarticJ]

#print axioms spec_invariants_one_point_per_orbit
#print axioms invariant_agrees_when_orbit_closures_meet
#print axioms j_eq_iff_six_reorderings
