-- Generating functions: multiplying two formal power series convolves their coefficient lists, the series of all 1s is the one inverse of 1 - x, and squaring it counts n + 1 splits.
import Mathlib.RingTheory.PowerSeries.WellKnown
import Mathlib.Order.Interval.Finset.Nat

open PowerSeries

/-- Multiplying two series convolves the two lists: the coefficient of `x^n` in `A(x) B(x)`
is the sum over every split of `n` into a first piece `k` and a second piece `n - k`
of `a_k * b_(n-k)`. -/
theorem coeff_mul_eq_convolution {R : Type*} [CommSemiring R] (A B : PowerSeries R) (n : ℕ) :
    coeff n (A * B) = ∑ k ∈ Finset.range (n + 1), coeff k A * coeff (n - k) B := by
  rw [coeff_mul, Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk]

/-- The series of all 1s is the inverse of `1 - x`: it multiplies `1 - x` to give `1`,
and nothing else does. -/
theorem one_sub_X_mul_ones_eq_one_and_unique {R : Type*} [CommRing R] :
    (1 - X) * mk (fun _ => (1 : R)) = 1 ∧
      ∀ A : PowerSeries R, (1 - X) * A = 1 → A = mk (fun _ => (1 : R)) := by
  have h : (1 - X) * mk (fun _ => (1 : R)) = 1 := by
    rw [mul_comm]
    exact mk_one_mul_one_sub_eq_one R
  refine ⟨h, fun A hA => ?_⟩
  calc A = (mk (fun _ => (1 : R)) * (1 - X)) * A := by rw [mul_comm _ (1 - X), h, one_mul]
    _ = mk (fun _ => (1 : R)) * ((1 - X) * A) := by rw [mul_assoc]
    _ = mk (fun _ => (1 : R)) := by rw [hA, mul_one]

/-- Ones against ones: the series of all 1s, squared, has `n + 1` on `x^n`,
one for each split of `n` into two ordered whole-number pieces. -/
theorem coeff_ones_sq {R : Type*} [CommSemiring R] (n : ℕ) :
    coeff n (mk (fun _ => (1 : R)) ^ 2) = (n + 1 : R) := by
  rw [pow_two, coeff_mul]
  simp only [coeff_mk, mul_one, Finset.sum_const, Finset.Nat.card_antidiagonal, nsmul_eq_mul]
  push_cast
  ring

/-- One die: the coefficient of `x^k` in `x + x^2 + ... + x^6`. -/
def die (k : ℕ) : ℕ := if 1 ≤ k ∧ k ≤ 6 then 1 else 0

-- The coefficient of x^7 in the die series squared, as the convolution: 6.
example : ∑ k ∈ Finset.range 8, die k * die (7 - k) = 6 := by decide

-- The convolution for every total 0 to 12: 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1 from total 2 on.
example : (List.range 13).map (fun n => ∑ k ∈ Finset.range (n + 1), die k * die (n - k)) =
    [0, 0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] := by decide

-- The other road: listing all ordered rolls of two dice and tallying totals gives the same counts.
example : (List.range 13).map (fun n =>
    ((Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).filter (fun p : ℕ × ℕ => p.1 + p.2 = n)).card) =
    [0, 0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1] := by decide

-- The eleven counts add to 36, and 6 faces times 6 faces is 36.
example : (Finset.Icc 2 12).sum (fun n => ∑ k ∈ Finset.range (n + 1), die k * die (n - k)) = 36 := by
  decide
example : (Finset.Icc 1 6 ×ˢ Finset.Icc 1 6).card = 36 := by decide

-- Mistake 2 on the card: faces numbered 0 to 5 leave only 4 ways to make 7.
example : ∑ k ∈ Finset.range 8, (if k ≤ 5 then 1 else 0) * (if 7 - k ≤ 5 then 1 else 0) = 4 := by
  decide

#print axioms coeff_mul_eq_convolution
#print axioms one_sub_X_mul_ones_eq_one_and_unique
#print axioms coeff_ones_sq
