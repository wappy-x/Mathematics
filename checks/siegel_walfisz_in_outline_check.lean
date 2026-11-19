-- Siegel-Walfisz: Siegel's bound 1 − β > c/q^(1/(2A)) keeps an exceptional zero's term x^β below x e^(−c√log x) for every modulus q up to (log x)^A, the prime count in a class a mod q is the average over characters of χ̄(a) times the character's prime sum, and a modulus growing like a power of x makes Siegel's saving exponent fall to 0.
import Mathlib.NumberTheory.DirichletCharacter.Orthogonality
import Mathlib.NumberTheory.MulChar.Lemmas
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Nat.Totient
import Mathlib.Tactic.NormNum.Prime
import Mathlib.RingTheory.RootsOfUnity.AlgebraicallyClosed
import Mathlib.Analysis.Complex.Polynomial.Basic

open Filter Topology Finset

/-- **From Siegel's bound to the error term (the card's folded proof).** Fix a power A > 0 and
put ε = 1/(2A). Take x ≥ 3 and a modulus q (a positive whole number) with q ≤ (log x)^A. If a
real zero β obeys Siegel's bound 1 − β > c/q^ε with a constant c > 0, then the zero's term
x^β is below x e^(−c√log x): the same shape as the error from all the other zeros. -/
theorem exceptional_zero_term_lt_of_siegel_bound {A c x β : ℝ} {q : ℕ} (hA : 0 < A) (hc : 0 < c)
    (hx : 3 ≤ x) (hq0 : 0 < q) (hq : (q : ℝ) ≤ Real.log x ^ A)
    (hβ : c / (q : ℝ) ^ (1 / (2 * A)) < 1 - β) :
    x ^ β < x * Real.exp (-c * Real.sqrt (Real.log x)) := by
  have hx0 : 0 < x := by linarith
  have hL1 : 0 < Real.log x := Real.log_pos (by linarith)
  set L := Real.log x with hL
  have hL0 : 0 < L := hL1
  have hq1 : (0 : ℝ) < q := by exact_mod_cast hq0
  have hqe : (q : ℝ) ^ (1 / (2 * A)) ≤ Real.sqrt L := by
    rw [Real.sqrt_eq_rpow]
    calc (q : ℝ) ^ (1 / (2 * A)) ≤ (L ^ A) ^ (1 / (2 * A)) :=
          Real.rpow_le_rpow hq1.le hq (by positivity)
      _ = L ^ (1 / 2 : ℝ) := by
          rw [← Real.rpow_mul hL0.le]; congr 1; field_simp
  have hqpos : 0 < (q : ℝ) ^ (1 / (2 * A)) := Real.rpow_pos_of_pos hq1 _
  have hs : 0 < Real.sqrt L := Real.sqrt_pos.mpr hL0
  have h2 : c / Real.sqrt L ≤ c / (q : ℝ) ^ (1 / (2 * A)) :=
    div_le_div_of_nonneg_left hc.le hqpos hqe
  have h3 : β * L < L - c * Real.sqrt L := by
    have : β < 1 - c / Real.sqrt L := by linarith
    have hLs : L = Real.sqrt L * Real.sqrt L := (Real.mul_self_sqrt hL0.le).symm
    have := mul_lt_mul_of_pos_right this hL0
    calc β * L < (1 - c / Real.sqrt L) * L := this
      _ = L - c * Real.sqrt L := by
        rw [sub_mul, one_mul, div_mul_eq_mul_div, mul_div_assoc, Real.div_sqrt]
  rw [Real.rpow_def_of_pos hx0]
  conv_rhs => rw [← Real.exp_log hx0]
  rw [← Real.exp_add, Real.exp_lt_exp, ← hL]
  nlinarith

/-- **The count in a class is an average over characters (Step 1).** For a modulus q ≥ 1, a
remainder a sharing no factor with q, and a whole number x, the number of primes p ≤ x with
p ≡ a mod q equals 1/φ(q) times the sum, over all Dirichlet characters χ mod q, of χ̄(a) times
the sum of χ(p) over the primes p ≤ x. -/
theorem prime_count_in_class_eq_character_average {q : ℕ} [NeZero q] {a : ℕ} (ha : a.Coprime q)
    (x : ℕ) :
    ((((range (x + 1)).filter (fun p ↦ p.Prime ∧ p ≡ a [MOD q])).card : ℕ) : ℂ) =
      1 / (q.totient : ℂ) * ∑ χ : DirichletCharacter ℂ q,
        starRingEnd ℂ (χ (a : ZMod q)) * ∑ p ∈ (range (x + 1)).filter Nat.Prime, χ (p : ZMod q) := by
  have hu : IsUnit (a : ZMod q) := (ZMod.isUnit_iff_coprime a q).mpr ha
  have key : ∀ χ : DirichletCharacter ℂ q, starRingEnd ℂ (χ (a : ZMod q)) = χ (a : ZMod q)⁻¹ := by
    intro χ
    have h1 : starRingEnd ℂ (χ (a : ZMod q)) = (χ (a : ZMod q))⁻¹ := by
      rw [← Complex.star_def, MulChar.star_apply', MulChar.inv_apply_eq_inv']
    rw [h1]
    refine (eq_inv_of_mul_eq_one_left ?_).symm
    rw [← map_mul, ZMod.inv_mul_of_unit _ hu, map_one]
  have hφ : (q.totient : ℂ) ≠ 0 := by
    exact_mod_cast (Nat.totient_pos.mpr (Nat.pos_of_ne_zero (NeZero.ne q))).ne'
  have hswap : ∑ χ : DirichletCharacter ℂ q,
        starRingEnd ℂ (χ (a : ZMod q)) * ∑ p ∈ (range (x + 1)).filter Nat.Prime, χ (p : ZMod q) =
      ∑ p ∈ (range (x + 1)).filter Nat.Prime, ∑ χ : DirichletCharacter ℂ q,
        χ (a : ZMod q)⁻¹ * χ (p : ZMod q) := by
    simp_rw [key, Finset.mul_sum]
    exact Finset.sum_comm
  rw [hswap]
  simp_rw [DirichletCharacter.sum_char_inv_mul_char_eq ℂ hu]
  rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const,
    nsmul_eq_mul, Finset.filter_filter]
  field_simp
  congr 2
  ext p
  simp only [Finset.mem_filter, ZMod.natCast_eq_natCast_iff]
  constructor
  · rintro ⟨h1, h2, h3⟩; exact ⟨h1, h2, h3.symm⟩
  · rintro ⟨h1, h2, h3⟩; exact ⟨h1, h2, h3.symm⟩

/-- **Why the modulus must stay small (Step 6).** If the modulus grows like a power of x,
q = x^δ with δ > 0, then Siegel's saving exponent log x / q^ε tends to 0 as x grows, for
every ε > 0: the bound saves nothing. -/
theorem siegel_exponent_tendsto_zero_of_power_modulus {δ ε : ℝ} (hδ : 0 < δ) (hε : 0 < ε) :
    Tendsto (fun x : ℝ ↦ Real.log x / (x ^ δ) ^ ε) atTop (𝓝 0) := by
  have h := (isLittleO_log_rpow_atTop (mul_pos hδ hε)).tendsto_div_nhds_zero
  refine h.congr' ?_
  filter_upwards [eventually_ge_atTop (0 : ℝ)] with x hx
  rw [Real.rpow_mul hx]

-- φ(7) = 6: six classes mod 7 can hold primes other than 7.
example : Nat.totient 7 = 6 := by decide
-- The moduli of the card's table: φ(11) = 10, φ(13) = 12, φ(101) = 100, φ(1009) = 1008, φ(9973) = 9972.
example : Nat.totient 11 = 10 ∧ Nat.totient 13 = 12 ∧ Nat.totient 101 = 100 ∧
    Nat.totient 1009 = 1008 ∧ Nat.totient 9973 = 9972 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> rw [Nat.totient_prime (by norm_num)]
-- Every q from 3 to 13: φ(q) is 2, 2, 4, 2, 6, 4, 6, 4, 10, 4, 12.
example : (List.range' 3 11).map Nat.totient = [2, 2, 4, 2, 6, 4, 6, 4, 10, 4, 12] := by decide
-- Class 0 mod 7 holds only the prime 7.
example (p : ℕ) (hp : p.Prime) (h : p ≡ 0 [MOD 7]) : p = 7 := by
  have h7 : 7 ∣ p := Nat.modEq_zero_iff_dvd.mp h
  exact ((Nat.prime_dvd_prime_iff_eq (by norm_num) hp).mp h7).symm
-- The squares mod 7 are 1, 2, 4 (Euler's criterion: a³ ≡ 1), and 3, 5, 6 give a³ ≡ −1 ≡ 6.
example : (List.range' 1 6).map (fun a ↦ a ^ 3 % 7) = [1, 1, 6, 1, 6, 6] := by decide
-- The class counts 1 + 13,063 + 13,065 + 13,105 + 13,069 + 13,105 + 13,090 make the 78,498 primes.
example : 1 + 13063 + 13065 + 13105 + 13069 + 13105 + 13090 = 78498 := by norm_num
-- The spread: 13,105 − 13,063 = 42 primes.
example : 13105 - 13063 = 42 := by norm_num
-- The square classes 1, 2, 4 hold 39,197; the others 39,300; a lead of 103.
example : 13063 + 13065 + 13069 = 39197 ∧ 13105 + 13105 + 13090 = 39300 ∧ 39300 - 39197 = 103 := by
  norm_num
-- Dividing by q instead of φ(q): 78,498 / 7 is exactly 11,214.
example : 78498 = 7 * 11214 := by norm_num

#print axioms exceptional_zero_term_lt_of_siegel_bound
#print axioms prime_count_in_class_eq_character_average
#print axioms siegel_exponent_tendsto_zero_of_power_modulus
