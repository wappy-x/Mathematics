-- MIP* = RE: for the CHSH game, entangled players whose measurements commute have CHSH sum at most 2√2 (by an exact sum of squares), players with fixed answer tables win at most 3 of 4 rounds, and the card's whole-number examples are exact.
import Mathlib.Algebra.Star.CHSH
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.Module
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.FieldSimp

/-- Tsirelson's bound, the CHSH squeeze from above (the card's Step 2): in any ordered
\*-algebra over ℝ (such as the operators on a quantum system), if the four measurements
A₀, A₁, B₀, B₁ are self-adjoint, each squares to the identity, and each A commutes with
each B, then the CHSH operator W = A₀B₀ + A₀B₁ + A₁B₀ − A₁B₁ is at most 2√2 times the
identity. So entangled players win the CHSH game with chance at most 1/2 + 2√2/8. -/
theorem chsh_operator_le_two_sqrt_two {R : Type*} [Ring R] [PartialOrder R] [StarRing R]
    [StarOrderedRing R] [Algebra ℝ R] [IsOrderedModule ℝ R] [StarModule ℝ R]
    (A₀ A₁ B₀ B₁ : R)
    (hA₀ : A₀ ^ 2 = 1) (hA₁ : A₁ ^ 2 = 1) (hB₀ : B₀ ^ 2 = 1) (hB₁ : B₁ ^ 2 = 1)
    (sA₀ : star A₀ = A₀) (sA₁ : star A₁ = A₁) (sB₀ : star B₀ = B₀) (sB₁ : star B₁ = B₁)
    (c₀₀ : A₀ * B₀ = B₀ * A₀) (c₀₁ : A₀ * B₁ = B₁ * A₀)
    (c₁₀ : A₁ * B₀ = B₀ * A₁) (c₁₁ : A₁ * B₁ = B₁ * A₁) :
    A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁ ≤ (2 * √2) • (1 : R) := by
  have h := tsirelson_inequality A₀ A₁ B₀ B₁
    ⟨hA₀, hA₁, hB₀, hB₁, sA₀, sA₁, sB₀, sB₁, c₀₀, c₀₁, c₁₀, c₁₁⟩
  have e : √2 ^ 3 = 2 * √2 := by
    rw [pow_succ, Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2)]
  rwa [e] at h

/-- The card's sum-of-squares identity: if each of A₀, A₁, B₀, B₁ squares to the identity
and each A commutes with each B, then
2√2 I − W = (1/√2) [ (A₀ − (B₀ + B₁)/√2)² + (A₁ − (B₀ − B₁)/√2)² ]. -/
theorem chsh_sum_of_squares {R : Type*} [Ring R] [Algebra ℝ R] (A₀ A₁ B₀ B₁ : R)
    (hA₀ : A₀ ^ 2 = 1) (hA₁ : A₁ ^ 2 = 1) (hB₀ : B₀ ^ 2 = 1) (hB₁ : B₁ ^ 2 = 1)
    (c₀₀ : A₀ * B₀ = B₀ * A₀) (c₀₁ : A₀ * B₁ = B₁ * A₀)
    (c₁₀ : A₁ * B₀ = B₀ * A₁) (c₁₁ : A₁ * B₁ = B₁ * A₁) :
    (2 * √2) • (1 : R) - (A₀ * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁) =
      (√2)⁻¹ • ((A₀ - (√2)⁻¹ • (B₀ + B₁)) ^ 2 + (A₁ - (√2)⁻¹ • (B₀ - B₁)) ^ 2) := by
  have h2 : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have hne : √2 ≠ 0 := by positivity
  have hs : 2 * √2 = 4 * (√2)⁻¹ := by field_simp; linarith
  have hss : (√2)⁻¹ * (√2)⁻¹ = 1 / 2 := by
    rw [← mul_inv, h2]; norm_num
  rw [hs]
  generalize (√2)⁻¹ = s at hss ⊢
  simp only [sq, sub_mul, mul_sub, add_mul, mul_add, smul_add, smul_sub]
  simp only [Algebra.mul_smul_comm, Algebra.smul_mul_assoc, ← mul_smul]
  simp only [← sq, hA₀, hA₁, hB₀, hB₁]
  simp only [← c₀₀, ← c₀₁, ← c₁₀, ← c₁₁]
  have q2 : s ^ 2 = 1 / 2 := by rw [sq, hss]
  have q3 : s ^ 3 = s / 2 := by rw [pow_succ, q2]; ring
  match_scalars <;> ring_nf <;> simp only [q2, q3] <;> ring

/-- The classical CHSH bound: whatever fixed answer tables a (first player, question x)
and b (second player, question y) the players use, at most 3 of the 4 question pairs
(x, y) are won, where a pair is won when a x XOR b y equals x AND y. -/
theorem chsh_classical_wins_le_three (a b : Bool → Bool) :
    (Finset.univ.filter (fun q : Bool × Bool => (a q.1 ^^ b q.2) = (q.1 && q.2))).card ≤ 3 := by
  revert a b
  decide

-- Worked numbers: of the 16 answer tables, exactly 8 win 3 of the 4 question pairs.
example : (Finset.univ.filter (fun ab : (Bool → Bool) × (Bool → Bool) =>
    (Finset.univ.filter (fun q : Bool × Bool =>
      (ab.1 q.1 ^^ ab.2 q.2) = (q.1 && q.2))).card = 3)).card = 8 := by
  decide

-- 561 = 3 × 11 × 17 is composite, yet Fermat's base-2 test gives 2^560 mod 561 = 1.
example : 561 = 3 * 11 * 17 ∧ ¬ Nat.Prime 561 ∧ 2 ^ 560 % 561 = 1 := by
  refine ⟨by norm_num, by norm_num, by decide +kernel⟩

-- 31 is prime; from 1 to 100 there are 25 primes.
example : Nat.Prime 31 ∧ ((Finset.range 101).filter Nat.Prime).card = 25 := by
  refine ⟨by norm_num, by decide +kernel⟩

#print axioms chsh_operator_le_two_sqrt_two
#print axioms chsh_sum_of_squares
#print axioms chsh_classical_wins_le_three
