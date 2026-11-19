-- Genus: the Riemann-Hurwitz count 2 - 2g = 2d - b, with b = d(d - 1) minus twice the deltas, forces g = (d - 1)(d - 2)/2 minus the deltas; the nodal cubic y^2 = x^2(x + 1) is traced by (t^2 - 1, t^3 - t); and the quartic x^4 - x^2 + y^4 + y^3 + y^2 = 1 has no singular point in the complex projective plane.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.MvPolynomial.PDeriv
import Mathlib.Data.Complex.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.FinCases

open MvPolynomial

/-- The degree-genus count. A plane curve of degree `d` is projected onto a line in `d` sheets.
Bezout gives `d (d - 1)` meetings of `F = 0` and `F_y = 0`; each singular point `P` uses up
`2 δ_P` of them without branching, so the branch points number `b = d (d - 1) - 2 ∑ δ_P`.
Riemann-Hurwitz says the curve's Euler characteristic `2 - 2g` equals `2d - b`.
Then the genus is `g = (d - 1)(d - 2)/2 - ∑ δ_P`: the smooth genus less the delta invariant
of every singular point. -/
theorem genus_eq_degree_genus_formula_sub_deltas {ι : Type*} (S : Finset ι) (δ : ι → ℕ)
    (d : ℕ) (g b : ℤ)
    (hb : b = (d : ℤ) * ((d : ℤ) - 1) - 2 * ∑ P ∈ S, (δ P : ℤ))
    (hRH : 2 - 2 * g = 2 * (d : ℤ) - b) :
    g = ((d : ℤ) - 1) * ((d : ℤ) - 2) / 2 - ∑ P ∈ S, (δ P : ℤ) := by
  have h2 : 2 * g + 2 * ∑ P ∈ S, (δ P : ℤ) = ((d : ℤ) - 1) * ((d : ℤ) - 2) := by
    rw [hb] at hRH; linear_combination -hRH
  rw [← h2, show 2 * g + 2 * ∑ P ∈ S, (δ P : ℤ) = 2 * (g + ∑ P ∈ S, (δ P : ℤ)) by ring,
    Int.mul_ediv_cancel_left _ (by norm_num)]
  ring

/-- The house cubic `y^2 = x^2 (x + 1)` is rational: the lines `y = t x` through its node
trace it, and its points are exactly the points `(t^2 - 1, t^3 - t)`. -/
theorem nodal_cubic_points_eq_range_parametrisation (K : Type*) [Field K] :
    {p : K × K | p.2 ^ 2 = p.1 ^ 2 * (p.1 + 1)} =
      Set.range (fun t : K => (t ^ 2 - 1, t ^ 3 - t)) := by
  ext ⟨x, y⟩
  simp only [Set.mem_ofPred_eq, Set.mem_range, Prod.mk.injEq]
  constructor
  · intro h
    by_cases hx : x = 0
    · subst hx
      have hy : y = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp (by simpa using h)
      exact ⟨1, by norm_num, by rw [hy]; norm_num⟩
    · have ht : (y / x) ^ 2 = x + 1 := by
        field_simp
        linear_combination h
      refine ⟨y / x, by linear_combination ht, ?_⟩
      have : (y / x) ^ 3 - y / x = (y / x) * ((y / x) ^ 2 - 1) := by ring
      rw [this, ht]
      field_simp
      ring
  · rintro ⟨t, rfl, rfl⟩
    ring

/-- The quartic `x^4 - x^2 z^2 + y^4 + y^3 z + y^2 z^2 - z^4`, the curve
`x^4 - x^2 + y^4 + y^3 + y^2 = 1` written with `z` (variables `0, 1, 2` are `x, y, z`). -/
noncomputable def smoothQuartic : MvPolynomial (Fin 3) ℂ :=
  X 0 ^ 4 - X 0 ^ 2 * X 2 ^ 2 + X 1 ^ 4 + X 1 ^ 3 * X 2 + X 1 ^ 2 * X 2 ^ 2 - X 2 ^ 4

/-- The quartic `x^4 - x^2 + y^4 + y^3 + y^2 = 1` is smooth over the complex numbers, at
infinity too: the only `(x, y, z)` where the curve and all three partial derivatives vanish
is `(0, 0, 0)`, which is no point of the projective plane. So it has no singular point and
its genus is `(4 - 1)(4 - 2)/2 = 3`. -/
theorem smooth_quartic_no_singular_point (p : Fin 3 → ℂ)
    (hF : eval p smoothQuartic = 0) (hd : ∀ i, eval p (pderiv i smoothQuartic) = 0) :
    p = 0 := by
  have h0 := hd 0
  have h1 := hd 1
  have h2 := hd 2
  simp [smoothQuartic, pderiv_X] at h0 h1 h2
  set x := p 0
  set y := p 1
  set z := p 2
  have hX : x * (2 * x ^ 2 - z ^ 2) = 0 := by linear_combination h0 / 2
  have hY : y * (4 * y ^ 2 + 3 * y * z + 2 * z ^ 2) = 0 := by linear_combination h1
  have hz : z = 0 := by
    rcases mul_eq_zero.mp hX with hx | hX'
    · rcases mul_eq_zero.mp hY with hy | hQ
      · have : z ^ 3 = 0 := by
          rw [hx, hy] at h2; linear_combination -h2 / 4
        exact pow_eq_zero_iff (by norm_num) |>.mp this
      · rw [hx] at h2
        have hL : z ^ 2 * (23 * y + 74 * z) = 0 := by
          linear_combination (4 * y + 5 * z) * hQ - 16 * h2
        rcases mul_eq_zero.mp hL with hz2 | hL'
        · exact pow_eq_zero_iff (by norm_num) |>.mp hz2
        · have : (17856 : ℂ) * z ^ 2 = 0 := by
            linear_combination 529 * hQ - (4 * (23 * y + 74 * z) - 523 * z) * hL'
          have : z ^ 2 = 0 := by
            rcases mul_eq_zero.mp this with h | h
            · norm_num at h
            · exact h
          exact pow_eq_zero_iff (by norm_num) |>.mp this
    · rcases mul_eq_zero.mp hY with hy | hQ
      · have : z ^ 3 = 0 := by
          rw [hy] at h2; linear_combination (-h2 - z * hX') / 5
        exact pow_eq_zero_iff (by norm_num) |>.mp this
      · have hL : z ^ 2 * (23 * y + 90 * z) = 0 := by
          linear_combination (4 * y + 5 * z) * hQ - 16 * h2 - 16 * z * hX'
        rcases mul_eq_zero.mp hL with hz2 | hL'
        · exact pow_eq_zero_iff (by norm_num) |>.mp hz2
        · have : (27248 : ℂ) * z ^ 2 = 0 := by
            linear_combination 529 * hQ - (4 * (23 * y + 90 * z) - 651 * z) * hL'
          have : z ^ 2 = 0 := by
            rcases mul_eq_zero.mp this with h | h
            · norm_num at h
            · exact h
          exact pow_eq_zero_iff (by norm_num) |>.mp this
  have hy : y = 0 := by
    have : y ^ 3 = 0 := by rw [hz] at h1; linear_combination h1 / 4
    exact pow_eq_zero_iff (by norm_num) |>.mp this
  have hx : x = 0 := by
    have : x ^ 3 = 0 := by rw [hz] at h0; linear_combination h0 / 4
    exact pow_eq_zero_iff (by norm_num) |>.mp this
  funext i
  fin_cases i
  · exact hx
  · exact hy
  · exact hz

-- The smooth genus (d - 1)(d - 2)/2 for degrees 1 to 7: 0, 0, 1, 3, 6, 10, 15.
example : ((List.range 7).map fun k => (k + 1 - 1) * (k + 1 - 2) / 2) = [0, 0, 1, 3, 6, 10, 15] := by
  decide
-- The smooth quartic: (4 - 1)(4 - 2)/2 = 3, with 4 * 3 = 12 branch points and 2 - 2*3 = 8 - 12.
example : (4 - 1) * (4 - 2) / 2 = 3 ∧ 4 * 3 = 12 ∧ (2 - 2 * 3 : ℤ) = 2 * 4 - 12 := by norm_num
-- The figure eight: one node, delta 2 * 1 / 2 = 1, genus 3 - 1 = 2, branch points 12 - 2 = 10.
example : 2 * 1 / 2 = 1 ∧ 3 - 1 = 2 ∧ 12 - 2 = 10 ∧ (2 - 2 * 2 : ℤ) = 2 * 4 - 10 := by norm_num
-- The house cubic: (3 - 1)(3 - 2)/2 - 1 = 0; the trifolium's triple point: 3 * 2 / 2 = 3, and 3 - 3 = 0.
example : (3 - 1) * (3 - 2) / 2 - 1 = 0 ∧ 3 * 2 / 2 = 3 ∧ 3 - 3 = 0 := by norm_num
-- Two conics, four nodes: the formula gives 3 - 4 = -1, a genus no surface has.
example : ((4 - 1) * (4 - 2) / 2 - 4 : ℤ) = -1 := by norm_num
-- t = 2 on the house cubic gives (3, 6): 6^2 = 36 = 3^2 * 4.
example : (2 : ℤ) ^ 2 - 1 = 3 ∧ (2 : ℤ) ^ 3 - 2 = 6 ∧ (6 : ℤ) ^ 2 = 3 ^ 2 * (3 + 1) := by norm_num
-- The figure eight's node: the lowest-degree part -x^2 + y^2 splits into two different tangents.
example (x y : ℚ) : -x ^ 2 + y ^ 2 = (y - x) * (y + x) := by ring
-- The trifolium (x^2 + y^2)^2 = z(x^3 - 3xy^2) is traced by (1 - 3t^2, t - 3t^3, (1 + t^2)^2).
example (t : ℚ) :
    ((1 - 3 * t ^ 2) ^ 2 + (t - 3 * t ^ 3) ^ 2) ^ 2 =
      (1 + t ^ 2) ^ 2 * ((1 - 3 * t ^ 2) ^ 3 - 3 * (1 - 3 * t ^ 2) * (t - 3 * t ^ 3) ^ 2) := by
  ring

#print axioms genus_eq_degree_genus_formula_sub_deltas
#print axioms nodal_cubic_points_eq_range_parametrisation
#print axioms smooth_quartic_no_singular_point
