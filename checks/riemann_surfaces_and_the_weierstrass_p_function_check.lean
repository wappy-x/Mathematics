-- Riemann surfaces: for any lattice the Weierstrass p-function and its derivative repeat over the lattice and land on the cubic y^2 = 4x^3 - g2 x - g3, the half periods give its three roots, and the lattice of 1 and i gives j = 1728.
import Mathlib.Analysis.SpecialFunctions.Elliptic.Weierstrass
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.NumberTheory.ModularForms.EisensteinSeries.QExpansion

open PeriodPair

lemma square_lattice_G_eq (L : PeriodPair) (h1 : L.ω₁ = 1) (hi : L.ω₂ = Complex.I) (n : ℕ) :
    L.G n = ∑' p : ℤ × ℤ, (((p.1 : ℂ) + p.2 * Complex.I) ^ n)⁻¹ := by
  rw [PeriodPair.G, ← L.latticeEquivProd.symm.toEquiv.tsum_eq]
  simp [latticeEquiv_symm_apply, h1, hi]

/-- Turning the square lattice a quarter turn. -/
def square_lattice_rot : ℤ × ℤ ≃ ℤ × ℤ where
  toFun p := (-p.2, p.1)
  invFun p := (p.2, -p.1)
  left_inv p := by simp
  right_inv p := by simp

lemma square_lattice_G_six (L : PeriodPair) (h1 : L.ω₁ = 1) (hi : L.ω₂ = Complex.I) :
    L.G 6 = 0 := by
  rw [square_lattice_G_eq L h1 hi]
  set f : ℤ × ℤ → ℂ := fun p => (((p.1 : ℂ) + p.2 * Complex.I) ^ 6)⁻¹ with hf
  have key : ∀ p, f (square_lattice_rot p) = - f p := by
    intro p
    simp only [hf, square_lattice_rot, Equiv.coe_fn_mk]
    have : ((((-p.2 : ℤ) : ℂ) + ((p.1 : ℤ) : ℂ) * Complex.I) ^ 6)
        = -(((p.1 : ℂ) + p.2 * Complex.I) ^ 6) := by
      have hI : Complex.I ^ 6 = -1 := by
        rw [show (6:ℕ) = 2 * 3 by rfl, pow_mul, Complex.I_sq]; norm_num
      have : (((-p.2 : ℤ) : ℂ) + ((p.1 : ℤ) : ℂ) * Complex.I)
          = Complex.I * ((p.1 : ℂ) + p.2 * Complex.I) := by
        push_cast; ring_nf; rw [Complex.I_sq]; ring
      rw [this, mul_pow, hI]; ring
    rw [this, inv_neg]
  have h := square_lattice_rot.tsum_eq f
  simp only [key, tsum_neg] at h
  exact CharZero.eq_neg_self_iff.mp h.symm |> fun h' => by simpa using h'

lemma square_lattice_G_four_ne_zero (L : PeriodPair) (h1 : L.ω₁ = 1) (hi : L.ω₂ = Complex.I) :
    L.G 4 ≠ 0 := by
  have H := tsum_eisSummand_eq_tsum_sigma_mul_cexp_pow (k := 4) (by norm_num) (by decide)
    UpperHalfPlane.I
  have hL : L.G 4 = ∑' v : Fin 2 → ℤ,
      EisensteinSeries.eisSummand ((4 : ℕ) : ℤ) v UpperHalfPlane.I := by
    rw [square_lattice_G_eq L h1 hi, ← (finTwoArrowEquiv ℤ).symm.tsum_eq,
      ← (Equiv.prodComm ℤ ℤ).tsum_eq]
    refine tsum_congr fun p => ?_
    simp [EisensteinSeries.eisSummand, UpperHalfPlane.coe_I]
    ring_nf
  rw [hL, H]
  set S : ℝ := ∑' n : ℕ+, ((ArithmeticFunction.sigma 3 n : ℕ) : ℝ) * Real.exp (-2 * Real.pi) ^ (n : ℕ)
    with hS
  have hS0 : 0 ≤ S := tsum_nonneg fun n => by positivity
  have hq : Complex.exp (2 * ↑Real.pi * Complex.I * ↑UpperHalfPlane.I)
      = ((Real.exp (-2 * Real.pi) : ℝ) : ℂ) := by
    rw [UpperHalfPlane.coe_I, Complex.ofReal_exp]
    congr 1
    push_cast
    ring_nf
    rw [Complex.I_sq]; ring
  have hT : ∑' (n : ℕ+), ((ArithmeticFunction.sigma (4 - 1) n : ℕ) : ℂ)
      * Complex.exp (2 * ↑Real.pi * Complex.I * ↑UpperHalfPlane.I) ^ (n : ℕ) = (S : ℂ) := by
    rw [hq, hS, Complex.ofReal_tsum]
    push_cast
    rfl
  rw [hT]
  have hz : riemannZeta ((4 : ℕ) : ℂ) = ((Real.pi ^ 4 / 90 : ℝ) : ℂ) := by
    push_cast; exact riemannZeta_four
  have hp : (-2 * (Real.pi : ℂ) * Complex.I) ^ 4 = ((16 * Real.pi ^ 4 : ℝ) : ℂ) := by
    push_cast
    ring_nf
    rw [Complex.I_pow_four]; ring
  rw [hz, hp]
  have : (2 * ((Real.pi ^ 4 / 90 : ℝ) : ℂ) + 2 * (((16 * Real.pi ^ 4 : ℝ) : ℂ) /
      ((4 - 1).factorial : ℕ)) * (S : ℂ)) =
      ((2 * (Real.pi ^ 4 / 90) + 2 * (16 * Real.pi ^ 4 / 6) * S : ℝ) : ℂ) := by
    push_cast
    norm_num [Nat.factorial]
  rw [this, Complex.ofReal_ne_zero]
  have := Real.pi_pos
  positivity

#print axioms square_lattice_G_eq
#print axioms square_lattice_rot
#print axioms square_lattice_G_six
#print axioms square_lattice_G_four_ne_zero

/-- For a lattice spanned by two periods in different directions, the Weierstrass function
`℘` and its derivative `℘'` repeat when `z` moves by any lattice point, so they are functions
on the torus; `℘'` really is the derivative of `℘` away from the lattice; and every point `z`
off the lattice goes to a point `(℘ z, ℘' z)` of the cubic `y^2 = 4x^3 - g₂ x - g₃`, whose
coefficients are the lattice sums `g₂ = 60 ∑' ω⁻⁴` and `g₃ = 140 ∑' ω⁻⁶`. -/
theorem weierstrassP_maps_torus_to_cubic (L : PeriodPair) :
    (∀ (l : L.lattice) (z : ℂ), ℘[L] (z + l) = ℘[L] z ∧ ℘'[L] (z + l) = ℘'[L] z) ∧
    (∀ z : ℂ, z ∉ L.lattice → HasDerivAt ℘[L] (℘'[L] z) z) ∧
    (∀ z : ℂ, z ∉ L.lattice →
      ℘'[L] z ^ 2 = 4 * ℘[L] z ^ 3
        - (60 * ∑' l : L.lattice, ((l : ℂ) ^ 4)⁻¹) * ℘[L] z
        - 140 * ∑' l : L.lattice, ((l : ℂ) ^ 6)⁻¹) := by
  refine ⟨fun l z => ⟨L.weierstrassP_add_coe z l, L.derivWeierstrassP_add_coe z l⟩, fun z hz => ?_,
    fun z hz => L.derivWeierstrassP_sq z hz⟩
  have hd : DifferentiableAt ℂ ℘[L] z :=
    (L.analyticOnNhd_weierstrassP z hz).differentiableAt
  simpa using hd.hasDerivAt

/-- At a half period (a point `z` off the lattice with `2z` on it) the derivative `℘'` is 0,
so the curve crosses the x-axis there: `℘ z` is a root of `4x^3 - g₂ x - g₃`. -/
theorem half_period_gives_root_of_cubic (L : PeriodPair) (z : ℂ)
    (h2 : 2 * z ∈ L.lattice) (hz : z ∉ L.lattice) :
    ℘'[L] z = 0 ∧ 4 * ℘[L] z ^ 3 - L.g₂ * ℘[L] z - L.g₃ = 0 := by
  have h0 : ℘'[L] z = 0 := by
    have e1 := L.derivWeierstrassP_neg z
    have e2 := L.derivWeierstrassP_sub_coe z ⟨2 * z, h2⟩
    have : z - 2 * z = -z := by ring
    simp only [this] at e2
    linear_combination (e2.symm.trans e1) / 2
  refine ⟨h0, ?_⟩
  have := L.derivWeierstrassP_sq z hz
  rw [h0] at this
  linear_combination -this

/-- The square lattice of `1` and `i` has `g₃ = 0`, and its j-invariant
`j = 1728 g₂^3 / (g₂^3 - 27 g₃^2)` is exactly 1728 (so in particular `g₂ ≠ 0`). -/
theorem square_lattice_j_eq_1728 (L : PeriodPair) (h1 : L.ω₁ = 1) (hi : L.ω₂ = Complex.I) :
    L.g₃ = 0 ∧ 1728 * L.g₂ ^ 3 / (L.g₂ ^ 3 - 27 * L.g₃ ^ 2) = 1728 := by
  have h3 : L.g₃ = 0 := by rw [PeriodPair.g₃, square_lattice_G_six L h1 hi, mul_zero]
  have h2 : L.g₂ ≠ 0 :=
    mul_ne_zero (by norm_num) (square_lattice_G_four_ne_zero L h1 hi)
  refine ⟨h3, ?_⟩
  rw [h3]
  field_simp
  ring

-- sigma_3(2) = 1^3 + 2^3 = 9, the second coefficient of the q-series for g₂.
example : ArithmeticFunction.sigma 3 2 = 9 := by decide

-- The lattice of 1 and 2i has j = 287496 = 66^3.
example : (66 : ℕ) ^ 3 = 287496 := by norm_num

-- A smooth plane cubic has genus (3 - 1)(3 - 2)/2 = 1.
example : (3 - 1) * (3 - 2) / 2 = 1 := by norm_num

-- One period only: g₂ = 4/3, g₃ = -8/27 give g₂^3 - 27 g₃^2 = 0, so j has no value.
example : (4 / 3 : ℚ) ^ 3 - 27 * (-8 / 27) ^ 2 = 0 := by norm_num

-- With x = X - 1/3 and y = Y/2, the cubic Y^2 = 4X^3 - (4/3)X + 8/27 is the house cubic y^2 = x^3 + x^2.
example (X : ℚ) : 4 * ((X - 1 / 3) ^ 3 + (X - 1 / 3) ^ 2) = 4 * X ^ 3 - 4 / 3 * X + 8 / 27 := by ring

#print axioms weierstrassP_maps_torus_to_cubic
#print axioms half_period_gives_root_of_cubic
#print axioms square_lattice_j_eq_1728
