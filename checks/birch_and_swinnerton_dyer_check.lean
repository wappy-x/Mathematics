-- Birch and Swinnerton-Dyer: the sign of the functional equation fixes the parity of the order of vanishing at s = 1, a point with y ≠ 0 on y^2 = x^3 - n^2 x gives a right triangle of area n, and on the area-5 curve G = (-4, 6) doubles to (1681/144, -62279/1728) while the three points with y = 0 have order 2.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.Analysis.Analytic.Order
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Analysis.SpecialFunctions.Gamma.Deriv
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.Data.Nat.Squarefree
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Tactic

namespace BirchSwinnertonDyerMillennium

open Finset WeierstrassCurve

/-- The curve `E_n : y^2 = x^3 - n^2 x` as a Mathlib Weierstrass curve over a commutative ring `R`
(`a₄ = -n^2`, every other coefficient `0`). The card's curve is `E_5 : y^2 = x^3 - 25x`. -/
def E (R : Type*) [CommRing R] (n : ℤ) : WeierstrassCurve R :=
  ⟨0, 0, 0, -((n : R) ^ 2), 0⟩

/-- `N_p` for `E_n`: the pairs `(x, y)` modulo `p` with `y^2 = x^3 - n^2 x`, plus 1 for the
point `O` at infinity. Then `a_p = p + 1 - N_p`. -/
def Np (p : ℕ) [NeZero p] (n : ℤ) : ℕ :=
  #(univ.filter (fun q : ZMod p × ZMod p => q.2 ^ 2 = q.1 ^ 3 - (n : ZMod p) ^ 2 * q.1)) + 1

/-- The whole numbers `x` with `|x| ≤ m` and `a x^2 ≤ m`: the only values a coordinate with
coefficient `a ≥ 1` can take in a solution of `a x^2 + b y^2 + c z^2 = m`. -/
def coordRange (a m : ℕ) : Finset ℤ :=
  (Icc (-(m : ℤ)) m).filter (fun x => (a : ℤ) * x ^ 2 ≤ m)

/-- The number of whole solutions `(x, y, z)` of `a x^2 + b y^2 + c z^2 = m`, for `a, b, c ≥ 1`. -/
def formCount (a b c m : ℕ) : ℕ :=
  #((coordRange a m ×ˢ coordRange b m ×ˢ coordRange c m).filter
    (fun t : ℤ × ℤ × ℤ => (a : ℤ) * t.1 ^ 2 + b * t.2.1 ^ 2 + c * t.2.2 ^ 2 = m))

/-- Tunnell's count `A_n`: solutions of `2x^2 + y^2 + 8z^2 = n` for odd `n`; for even `n`,
of `4x^2 + y^2 + 8z^2 = n/2`. -/
def tunnellA (n : ℕ) : ℕ := if n % 2 = 1 then formCount 2 1 8 n else formCount 4 1 8 (n / 2)

/-- Tunnell's count `B_n`: solutions of `2x^2 + y^2 + 32z^2 = n` for odd `n`; for even `n`,
of `4x^2 + y^2 + 32z^2 = n/2`. -/
def tunnellB (n : ℕ) : ℕ := if n % 2 = 1 then formCount 2 1 32 n else formCount 4 1 32 (n / 2)

/-- The sign fixes only the parity. Let `L(s)` be analytic at `s = 1` and not identically zero
near 1, and let its completed function `Λ(s) = N^(s/2) (2π)^(-s) Γ(s) L(s)`, with conductor
`N > 0`, obey the mirror rule `Λ(2 - s) = w Λ(s)` near `s = 1`, with sign `w = ±1`. Then the
order of vanishing of `L` at `s = 1` is odd when `w = -1` and even when `w = +1`. In particular
`w = -1` forces `L(1) = 0`, as for `E_5`, and `w = +1` does not force `L(1) ≠ 0`, as for `E_41`. -/
theorem sign_fixes_parity_of_order_of_vanishing (N : ℕ) (hN : 0 < N) (L : ℂ → ℂ) (w : ℂ)
    (hw : w = 1 ∨ w = -1) (hL : AnalyticAt ℂ L 1) (hnz : analyticOrderAt L 1 ≠ ⊤)
    (hfe : ∀ᶠ s in nhds (1 : ℂ),
      (N : ℂ) ^ ((2 - s) / 2) * ((2 * Real.pi : ℝ) : ℂ) ^ (-(2 - s)) * Complex.Gamma (2 - s) *
          L (2 - s) =
        w * ((N : ℂ) ^ (s / 2) * ((2 * Real.pi : ℝ) : ℂ) ^ (-s) * Complex.Gamma s * L s)) :
    (w = -1 → Odd (analyticOrderNatAt L 1)) ∧ (w = 1 → Even (analyticOrderNatAt L 1)) := by
  set k := analyticOrderNatAt L 1 with hk
  have hord : analyticOrderAt L 1 = (k : ℕ∞) := (Nat.cast_analyticOrderNatAt hnz).symm
  obtain ⟨h, hha, hh1, hLh⟩ := hL.analyticOrderAt_eq_natCast.mp hord
  obtain ⟨g, hg⟩ : ∃ g : ℂ → ℂ, g = fun s =>
      (N : ℂ) ^ (s / 2) * ((2 * Real.pi : ℝ) : ℂ) ^ (-s) * Complex.Gamma s := ⟨_, rfl⟩
  have hN0 : (N : ℂ) ≠ 0 := by exact_mod_cast hN.ne'
  have hpi0 : ((2 * Real.pi : ℝ) : ℂ) ≠ 0 := by
    have : (2 * Real.pi : ℝ) ≠ 0 := by positivity
    exact_mod_cast this
  have hgc : ContinuousAt g 1 := by
    rw [hg]
    have hG : ContinuousAt Complex.Gamma 1 := Complex.differentiableAt_Gamma_one.continuousAt
    have h1 : ContinuousAt (fun s : ℂ => (N : ℂ) ^ (s / 2)) 1 :=
      ContinuousAt.const_cpow (by fun_prop) (Or.inl hN0)
    have h2 : ContinuousAt (fun s : ℂ => ((2 * Real.pi : ℝ) : ℂ) ^ (-s)) 1 :=
      ContinuousAt.const_cpow (by fun_prop) (Or.inl hpi0)
    exact (h1.mul h2).mul hG
  have hg1 : g 1 ≠ 0 := by
    rw [hg]
    simp only [Complex.Gamma_one, mul_one]
    exact mul_ne_zero (Complex.cpow_ne_zero_iff.mpr (Or.inl hN0))
      (Complex.cpow_ne_zero_iff.mpr (Or.inl hpi0))
  have hfe' : ∀ᶠ s in nhds (1 : ℂ), g (2 - s) * L (2 - s) = w * (g s * L s) := by
    filter_upwards [hfe] with s hs
    rw [hg]
    beta_reduce
    linear_combination hs
  have hrefl : ContinuousAt (fun s : ℂ => 2 - s) 1 := by fun_prop
  have hT : Filter.Tendsto (fun s : ℂ => 2 - s) (nhds 1) (nhds 1) := by
    have := hrefl.tendsto
    rwa [show (2 : ℂ) - 1 = 1 by norm_num] at this
  have hLh' : ∀ᶠ s in nhds (1 : ℂ), L (2 - s) = (2 - s - 1) ^ k • h (2 - s) := hT.eventually hLh
  have hφ : ContinuousAt (fun s => (-1 : ℂ) ^ k * (g (2 - s) * h (2 - s))) 1 := by
    have hg2 : ContinuousAt (fun s => g (2 - s)) 1 :=
      ContinuousAt.comp_of_eq (g := g) (f := fun s : ℂ => 2 - s) hgc hrefl (by norm_num)
    have hh2 : ContinuousAt (fun s => h (2 - s)) 1 :=
      ContinuousAt.comp_of_eq (g := h) (f := fun s : ℂ => 2 - s) hha.continuousAt hrefl
        (by norm_num)
    exact continuousAt_const.mul (hg2.mul hh2)
  have hψ : ContinuousAt (fun s => w * (g s * h s)) 1 :=
    continuousAt_const.mul (hgc.mul hha.continuousAt)
  have hev : (fun s => (-1 : ℂ) ^ k * (g (2 - s) * h (2 - s))) =ᶠ[nhdsWithin 1 {1}ᶜ]
      (fun s => w * (g s * h s)) := by
    have hall := hfe'.and (hLh.and hLh')
    filter_upwards [nhdsWithin_le_nhds hall, self_mem_nhdsWithin] with s hs hs1
    obtain ⟨h1, h2, h3⟩ := hs
    rw [h2, h3] at h1
    have hs' : (s - 1) ^ k ≠ 0 := pow_ne_zero _ (sub_ne_zero.mpr hs1)
    have e : (2 - s - 1) ^ k = (-1 : ℂ) ^ k * (s - 1) ^ k := by
      rw [← mul_pow]; ring_nf
    rw [e] at h1
    simp only [smul_eq_mul] at h1
    apply mul_left_cancel₀ hs'
    linear_combination h1
  have key := tendsto_nhds_unique
    ((hφ.tendsto.mono_left nhdsWithin_le_nhds).congr' hev)
    (hψ.tendsto.mono_left nhdsWithin_le_nhds)
  simp only [show (2 : ℂ) - 1 = 1 by norm_num] at key
  have hne : g 1 * h 1 ≠ 0 := mul_ne_zero hg1 hh1
  have hsign : (-1 : ℂ) ^ k = w := by
    apply mul_right_cancel₀ hne
    linear_combination key
  constructor
  · intro hw1
    rw [hw1] at hsign
    rcases Nat.even_or_odd k with he | ho
    · rw [he.neg_one_pow] at hsign; norm_num at hsign
    · exact ho
  · intro hw1
    rw [hw1] at hsign
    rcases Nat.even_or_odd k with he | ho
    · exact he
    · rw [ho.neg_one_pow] at hsign; norm_num at hsign

/-- Step 1: a point with `y ≠ 0` is a triangle. For a rational point `(x, y)` on
`E_n : y^2 = x^3 - n^2 x` with `y ≠ 0`, the numbers `a = (x^2 - n^2)/y`, `b = 2nx/y` and
`c = (x^2 + n^2)/y` satisfy `a^2 + b^2 = c^2` and `a b / 2 = n`: with signs dropped, a right
triangle of area `n`. -/
theorem point_with_y_ne_zero_gives_triangle_of_area_n (n : ℕ) (x y : ℚ)
    (hE : (E ℚ n).toAffine.Equation x y) (hy : y ≠ 0) :
    let a := (x ^ 2 - (n : ℚ) ^ 2) / y
    let b := 2 * (n : ℚ) * x / y
    let c := (x ^ 2 + (n : ℚ) ^ 2) / y
    a ^ 2 + b ^ 2 = c ^ 2 ∧ a * b / 2 = n := by
  intro a b c
  have hE' : y ^ 2 = x ^ 3 - (n : ℚ) ^ 2 * x := by
    rw [WeierstrassCurve.Affine.equation_iff] at hE
    simp only [E] at hE
    push_cast at hE
    linear_combination hE
  refine ⟨?_, ?_⟩
  · simp only [a, b, c]
    field_simp
    ring
  · simp only [a, b]
    field_simp
    linear_combination (-(n : ℚ)) * hE'

/-- Step 2 and the torsion points, in Mathlib's chord-and-tangent group on `E_5 : y^2 = x^3 - 25x`
over `ℚ`. `G = (-4, 6)` is a nonsingular point and `G + G = 2G = (1681/144, -62279/1728)`; each of
`(0, 0)`, `(5, 0)` and `(-5, 0)` is a nonsingular point `T` with `T + T = O`. -/
theorem area_five_curve_doubling_and_two_torsion :
    (∃ (hG : (E ℚ 5).toAffine.Nonsingular (-4) 6)
        (h2G : (E ℚ 5).toAffine.Nonsingular (1681 / 144) (-62279 / 1728)),
        Affine.Point.some (-4) 6 hG + Affine.Point.some (-4) 6 hG =
          Affine.Point.some (1681 / 144) (-62279 / 1728) h2G) ∧
      ∀ t ∈ ({0, 5, -5} : Finset ℚ), ∃ hT : (E ℚ 5).toAffine.Nonsingular t 0,
        Affine.Point.some t 0 hT + Affine.Point.some t 0 hT = 0 := by
  refine ⟨⟨by rw [WeierstrassCurve.Affine.nonsingular_iff, WeierstrassCurve.Affine.equation_iff]; norm_num [E],
    by rw [WeierstrassCurve.Affine.nonsingular_iff, WeierstrassCurve.Affine.equation_iff]; norm_num [E], ?_⟩, ?_⟩
  · rw [Affine.Point.add_self_of_Y_ne (by norm_num [E])]
    simp only [Affine.Point.some.injEq]
    norm_num [E, WeierstrassCurve.Affine.addY, WeierstrassCurve.Affine.slope]
  · intro t ht
    simp only [Finset.mem_insert, Finset.mem_singleton] at ht
    rcases ht with rfl | rfl | rfl <;>
    exact ⟨by rw [WeierstrassCurve.Affine.nonsingular_iff, WeierstrassCurve.Affine.equation_iff]; norm_num [E],
      Affine.Point.add_self_of_Y_eq (by norm_num [E])⟩

/-! ## The card's worked numbers -/

-- Fibonacci's triangle: (3/2)^2 + (20/3)^2 = 1681/36 = (41/6)^2, and the area is 5.
example : ((3 : ℚ) / 2) ^ 2 + (20 / 3) ^ 2 = 1681 / 36 ∧ ((41 : ℚ) / 6) ^ 2 = 1681 / 36 ∧
    (3 : ℚ) / 2 * (20 / 3) / 2 = 5 := by norm_num
-- G = (-4, 6) lies on y^2 = x^3 - 25x: 36 = -64 + 100.
example : (6 : ℤ) ^ 2 = 36 ∧ (-4 : ℤ) ^ 3 - 25 * (-4) = -64 + 100 ∧ (-64 : ℤ) + 100 = 36 := by norm_num
example : (E ℚ 5).toAffine.Equation (-4) 6 := by
  norm_num [E, WeierstrassCurve.Affine.equation_iff]
-- The triangle from G: (16 - 25)/6 = -3/2, 10 * (-4)/6 = -20/3, (16 + 25)/6 = 41/6.
example : ((16 : ℚ) - 25) / 6 = -3 / 2 ∧ (10 : ℚ) * (-4) / 6 = -20 / 3 ∧ ((16 : ℚ) + 25) / 6 = 41 / 6 := by
  norm_num
-- The torsion points (0, 0), (5, 0), (-5, 0) lie on the curve; (4, 0) does not.
example : (E ℚ 5).toAffine.Equation 0 0 ∧ (E ℚ 5).toAffine.Equation 5 0 ∧
    (E ℚ 5).toAffine.Equation (-5) 0 ∧ ¬ (E ℚ 5).toAffine.Equation 4 0 := by
  norm_num [E, WeierstrassCurve.Affine.equation_iff]
-- Tangent slope at G: (3 * 16 - 25)/(2 * 6) = 23/12; x(2G) = (23/12)^2 - 2(-4) = 1681/144;
-- y(2G) = (23/12)(-4 - 1681/144) - 6 = -62279/1728.
example : ((3 : ℚ) * 16 - 25) / (2 * 6) = 23 / 12 ∧ ((23 : ℚ) / 12) ^ 2 - 2 * (-4) = 1681 / 144 ∧
    (23 : ℚ) / 12 * (-4 - 1681 / 144) - 6 = -62279 / 1728 := by norm_num
-- 2G lies on the curve, and its x-coordinate 1681/144 is not a whole number.
example : (E ℚ 5).toAffine.Equation (1681 / 144) (-62279 / 1728) := by
  norm_num [E, WeierstrassCurve.Affine.equation_iff]
example : ((1681 : ℚ) / 144).den = 144 := by norm_num
-- The triangle from 2G: sides 1519/492, 4920/1519, 3344161/747348, right, with area 5.
example :
    let x : ℚ := 1681 / 144
    let y : ℚ := -62279 / 1728
    |(x ^ 2 - 25) / y| = 1519 / 492 ∧ |2 * 5 * x / y| = 4920 / 1519 ∧
      |(x ^ 2 + 25) / y| = 3344161 / 747348 := by norm_num
example : ((1519 : ℚ) / 492) ^ 2 + (4920 / 1519) ^ 2 = (3344161 / 747348) ^ 2 ∧
    (1519 : ℚ) / 492 * (4920 / 1519) / 2 = 5 := by norm_num
-- Points of E_5 modulo p, O included: 3:4, 7:8, 11:12, 13:20, 17:20, 19:20, 23:24, 29:40.
example : Np 3 5 = 4 := by decide
example : Np 7 5 = 8 := by decide
example : Np 11 5 = 12 := by decide
example : Np 13 5 = 20 := by decide
example : Np 17 5 = 20 := by decide
example : Np 19 5 = 20 := by decide
example : Np 23 5 = 24 := by decide
example : Np 29 5 = 40 := by decide
-- a_13 = 13 + 1 - 20 = -6, and Hasse's bound a_p^2 ≤ 4p holds on the table.
example : (13 : ℤ) + 1 - 20 = -6 := by norm_num
example : [((3 : ℤ), (0 : ℤ)), (7, 0), (11, 0), (13, -6), (17, -2), (19, 0), (23, 0), (29, -10)].all
    (fun q => q.2 ^ 2 ≤ 4 * q.1) = true := by decide
-- The conductor of E_5 is 32 * 5^2 = 800.
example : 32 * 5 ^ 2 = 800 := by norm_num
-- Tunnell's counts: A_5 = B_5 = 0, so L(E_5, 1) = 0; for 41 they are (32, 16), and 32 = 2 * 16.
example : tunnellA 5 = 0 ∧ tunnellB 5 = 0 := by decide
example : tunnellA 41 = 32 ∧ tunnellB 41 = 16 := by decide
-- The sign rule w = -1 exactly when n is 5, 6 or 7 modulo 8: 5 and 157 give 5, 41 gives 1.
example : 5 % 8 = 5 ∧ 157 % 8 = 5 ∧ 41 % 8 = 1 := by decide
-- There are 61 square-free numbers from 1 to 100.
example : #((Icc 1 100).filter Squarefree) = 61 := by decide +kernel
-- The three classes hold 25 + 33 + 3 = 61 numbers.
example : 25 + 33 + 3 = 61 := by norm_num

#print axioms sign_fixes_parity_of_order_of_vanishing
#print axioms point_with_y_ne_zero_gives_triangle_of_area_n
#print axioms area_five_curve_doubling_and_two_torsion

end BirchSwinnertonDyerMillennium
