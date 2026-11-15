-- Inner products: Cauchy–Schwarz with its equality case, complex polarization, and the Jordan–von Neumann test that a norm comes from an inner product exactly when it obeys the parallelogram law.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.OfNorm
import Mathlib.NumberTheory.Zsqrtd.GaussianInt

open ComplexConjugate

/-- Cauchy–Schwarz: in any real or complex inner product space (first slot conjugated), the
inner product is at most the product of the two lengths in size, `‖⟨x, y⟩‖ ≤ ‖x‖ ‖y‖`, with
equality exactly when one of `x`, `y` is a scalar multiple of the other. -/
theorem cauchy_schwarz_with_equality_case {𝕜 E : Type*} [RCLike 𝕜] [NormedAddCommGroup E]
    [InnerProductSpace 𝕜 E] (x y : E) :
    ‖inner 𝕜 x y‖ ≤ ‖x‖ * ‖y‖ ∧
      (‖inner 𝕜 x y‖ = ‖x‖ * ‖y‖ ↔ (∃ c : 𝕜, y = c • x) ∨ ∃ c : 𝕜, x = c • y) := by
  refine ⟨norm_inner_le_norm x y, ?_⟩
  constructor
  · intro h
    by_cases hx : x = 0
    · exact Or.inr ⟨0, by simp [hx]⟩
    · have := ((norm_inner_eq_norm_tfae 𝕜 x y).out 1 3).1 h
      exact Or.inl (this.resolve_left hx)
  · rintro (h | h)
    · exact ((norm_inner_eq_norm_tfae 𝕜 x y).out 1 3).2 (Or.inr h)
    · have := ((norm_inner_eq_norm_tfae 𝕜 y x).out 1 3).2 (Or.inr h)
      rw [norm_inner_symm, this, mul_comm]

/-- Polarization identity with complex scalars: four length readings give the inner product,
`⟨x, y⟩ = (1/4) ∑_{m=0}^{3} i^(-m) ‖x + i^m y‖²`. -/
theorem complex_polarization_identity {E : Type*} [NormedAddCommGroup E]
    [InnerProductSpace ℂ E] (x y : E) :
    inner ℂ x y =
      (1 / 4 : ℂ) * ∑ m ∈ Finset.range 4,
        (Complex.I ^ m)⁻¹ * ((‖x + Complex.I ^ m • y‖ : ℂ) ^ 2) := by
  rw [inner_eq_sum_norm_sq_div_four (𝕜 := ℂ) x y]
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, RCLike.I_to_complex]
  have h2 : Complex.I ^ 2 • y = -y := by simp
  have h3 : Complex.I ^ 3 • y = -(Complex.I • y) := by
    rw [pow_succ', mul_smul, h2]; simp
  rw [h2, h3, ← sub_eq_add_neg, ← sub_eq_add_neg]
  simp only [pow_zero, pow_one, one_smul, inv_one, one_mul, zero_add]
  have hI2 : (Complex.I ^ 2)⁻¹ = -1 := by simp
  have hI3 : (Complex.I ^ 3)⁻¹ = Complex.I := by
    rw [pow_succ, Complex.I_sq]; simp
  rw [hI2, hI3, Complex.inv_I]
  simp only [RCLike.ofReal_eq_complex_ofReal]
  ring

/-- Jordan–von Neumann: a norm on a real or complex vector space comes from an inner product
(conjugate-symmetric, linear in the second slot, positive on nonzero vectors, with
`⟨x, x⟩ = ‖x‖²`) exactly when it obeys the parallelogram law
`‖x + y‖² + ‖x - y‖² = 2‖x‖² + 2‖y‖²` for every pair. -/
theorem norm_from_inner_product_iff_parallelogram_law {𝕜 E : Type*} [RCLike 𝕜]
    [NormedAddCommGroup E] [NormedSpace 𝕜 E] :
    (∃ ip : E → E → 𝕜,
        (∀ x y, ip y x = conj (ip x y)) ∧
        (∀ x y z, ip x (y + z) = ip x y + ip x z) ∧
        (∀ (c : 𝕜) x y, ip x (c • y) = c * ip x y) ∧
        (∀ x, x ≠ 0 → 0 < RCLike.re (ip x x)) ∧
        (∀ x, ip x x = ((‖x‖ ^ 2 : ℝ) : 𝕜))) ↔
      ∀ x y : E, ‖x + y‖ ^ 2 + ‖x - y‖ ^ 2 = 2 * ‖x‖ ^ 2 + 2 * ‖y‖ ^ 2 := by
  constructor
  · rintro ⟨ip, hsymm, hadd, hsmul, -, hnorm⟩ x y
    have haddl : ∀ a b z, ip (a + b) z = ip a z + ip b z := by
      intro a b z
      rw [hsymm, hadd, map_add, ← hsymm, ← hsymm]
    have hneg : ∀ a z, ip a (-z) = -ip a z := by
      intro a z
      rw [← neg_one_smul 𝕜 z, hsmul]; ring
    have hnegl : ∀ a z, ip (-a) z = -ip a z := by
      intro a z
      rw [hsymm, hneg, map_neg, ← hsymm]
    have key : ip (x + y) (x + y) + ip (x - y) (x - y) = 2 * ip x x + 2 * ip y y := by
      simp only [sub_eq_add_neg, haddl, hadd, hneg, hnegl, neg_neg]
      ring
    rw [hnorm, hnorm, hnorm, hnorm] at key
    apply (RCLike.ofReal_injective (K := 𝕜))
    push_cast at key ⊢
    exact key
  · intro h
    let _ : InnerProductSpace 𝕜 E := InnerProductSpace.ofNorm 𝕜 (fun x y => by
      have := h x y
      simp only [← pow_two]
      linarith)
    refine ⟨fun x y => inner 𝕜 x y, fun x y => (inner_conj_symm (𝕜 := 𝕜) y x).symm,
      fun x y z => inner_add_right x y z, fun c x y => inner_smul_right x y c,
      fun x hx => ?_, fun x => ?_⟩
    · exact (re_inner_self_pos (𝕜 := 𝕜)).2 hx
    · show inner 𝕜 x x = _
      rw [inner_self_eq_norm_sq_to_K]; push_cast; rfl

-- The card's worked numbers on clips A = 2, 5, 3, -1, -4, -3, -2, 0 and B = 1, 2, 5, 3, -1, -3, -3, -4.
-- Inner product of A and B, and their squared lengths.
example : (List.zipWith (· * ·) [2, 5, 3, -1, -4, -3, -2, 0] [1, 2, 5, 3, -1, -3, -3, -4]).sum
    = (43 : ℤ) := by decide
example : (List.zipWith (· * ·) [2, 5, 3, -1, -4, -3, -2, 0] [2, 5, 3, -1, -4, -3, -2, 0]).sum
    = (68 : ℤ) := by decide
example : (List.zipWith (· * ·) [1, 2, 5, 3, -1, -3, -3, -4] [1, 2, 5, 3, -1, -3, -3, -4]).sum
    = (74 : ℤ) := by decide
-- A slid one sample against B: inner product 68.
example : (List.zipWith (· * ·) [0, 2, 5, 3, -1, -4, -3, -2] [1, 2, 5, 3, -1, -3, -3, -4]).sum
    = (68 : ℤ) := by decide
-- The split for the slid clips: Pythagoras 74 = 68 + 6, slack 5032 - 4624 = 408 = 68 × 6.
example : (74 : ℤ) = 68 + (1 + 1 + 4) ∧ (68 * 74 - 68 ^ 2 : ℤ) = 408 ∧ (408 : ℤ) = 68 * 6 := by
  norm_num
-- Parallelogram law and real polarization for A and B: 228 + 56 = 2 × 68 + 2 × 74, (228 - 56)/4 = 43.
example : (List.zipWith (· * ·) [3, 7, 8, 2, -5, -6, -5, -4] [3, 7, 8, 2, -5, -6, -5, -4]).sum
    = (228 : ℤ) ∧
    (List.zipWith (· * ·) [1, 3, -2, -4, -3, 0, 1, 4] [1, 3, -2, -4, -3, 0, 1, 4]).sum = (56 : ℤ) ∧
    (228 + 56 : ℤ) = 2 * 68 + 2 * 74 ∧ (228 - 56 : ℤ) = 4 * 43 := by decide
-- The sum meter fails the law on A and B (1924 against 1768) but passes on A and 2A (4000 against 4000).
example : (40 ^ 2 + 18 ^ 2 : ℤ) = 1924 ∧ (2 * 20 ^ 2 + 2 * 22 ^ 2 : ℤ) = 1768 ∧
    (60 ^ 2 + 20 ^ 2 : ℤ) = 2 * 20 ^ 2 + 2 * 40 ^ 2 := by norm_num
-- The peak meter fails it: 8² + 4² = 80 against 2 × 5² + 2 × 5² = 100.
example : (8 ^ 2 + 4 ^ 2 : ℤ) = 80 ∧ (2 * 5 ^ 2 + 2 * 5 ^ 2 : ℤ) = 100 := by norm_num
-- Complex frames X = (9, -1 - 6i, 1), Y = (11, -4 + i, 1) as Gaussian integers:
-- ⟨X, Y⟩ = 98 - 25i, squared lengths 119 and 139, |⟨X, Y⟩|² = 10229 < 16541 = 119 × 139.
example : star (⟨9, 0⟩ : GaussianInt) * ⟨11, 0⟩ + star (⟨-1, -6⟩ : GaussianInt) * ⟨-4, 1⟩
    + star (⟨1, 0⟩ : GaussianInt) * ⟨1, 0⟩ = ⟨98, -25⟩ := by decide
example : (81 + 37 + 1 : ℤ) = 119 ∧ (121 + 17 + 1 : ℤ) = 139 ∧ (98 ^ 2 + 25 ^ 2 : ℤ) = 10229 ∧
    (10229 : ℤ) < 119 * 139 := by norm_num
-- Dropping the conjugate gives a complex "squared length": 81 + (-1 - 6i)² + 1 = 47 + 12i.
example : (⟨9, 0⟩ : GaussianInt) * ⟨9, 0⟩ + (⟨-1, -6⟩ : GaussianInt) * ⟨-1, -6⟩
    + (⟨1, 0⟩ : GaussianInt) * ⟨1, 0⟩ = ⟨47, 12⟩ := by decide
-- Complex polarization from the four readings 454, 308, 62, 208: real part 98, imaginary part -25.
example : (454 - 62 : ℤ) = 4 * 98 ∧ (208 - 308 : ℤ) = 4 * (-25) := by norm_num

#print axioms cauchy_schwarz_with_equality_case
#print axioms complex_polarization_identity
#print axioms norm_from_inner_product_iff_parallelogram_law
