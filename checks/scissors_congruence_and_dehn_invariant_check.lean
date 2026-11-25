-- Scissors congruence: the rectangle-to-square slide lands exactly, the regular tetrahedron's dihedral angle arccos(1/3) is no rational multiple of π, and so an angle score exists that gives every cube Dehn invariant 0 and every regular tetrahedron a non-zero one.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.LinearAlgebra.Basis.VectorSpace
import Mathlib.LinearAlgebra.Dual.Lemmas
import Mathlib.Tactic

open Real

def tetSeq : ℕ → ℤ
  | 0 => 1
  | 1 => 1
  | (n + 2) => 2 * tetSeq (n + 1) - 9 * tetSeq n

lemma tetSeq_succ_modEq (n : ℕ) : tetSeq (n + 1) ≡ 2 ^ n [ZMOD 3] := by
  induction n with
  | zero => decide
  | succ n ih =>
    show 2 * tetSeq (n + 1) - 9 * tetSeq n ≡ 2 ^ (n + 1) [ZMOD 3]
    have h9 : (9 : ℤ) * tetSeq n ≡ 0 [ZMOD 3] :=
      (Int.modEq_zero_iff_dvd).2 (Dvd.dvd.mul_right (by norm_num) _)
    calc 2 * tetSeq (n + 1) - 9 * tetSeq n ≡ 2 * 2 ^ n - 0 [ZMOD 3] := (ih.mul_left 2).sub h9
      _ = 2 ^ (n + 1) := by ring

lemma tetSeq_not_dvd (n : ℕ) : ¬ (3 : ℤ) ∣ tetSeq n := by
  rcases n with _ | n
  · decide
  · intro h
    have h1 := (tetSeq_succ_modEq n).symm.trans ((Int.modEq_zero_iff_dvd).2 h)
    have h2 : (3 : ℤ) ∣ 2 ^ n := (Int.modEq_zero_iff_dvd).1 h1
    have h3 : (3 : ℤ) ∣ 2 := Int.Prime.dvd_pow' (by norm_num) h2
    omega

lemma three_pow_mul_cos (n : ℕ) :
    (3 : ℝ) ^ n * cos (n * arccos (1 / 3)) = tetSeq n := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    match n, ih with
    | 0, _ => simp [tetSeq]
    | 1, _ =>
      rw [pow_one, Nat.cast_one, one_mul, cos_arccos (by norm_num) (by norm_num)]
      simp [tetSeq]
    | (n + 2), ih =>
      have h1 := ih (n + 1) (by omega)
      have h0 := ih n (by omega)
      set θ := arccos (1 / 3)
      have hc : cos θ = 1 / 3 := cos_arccos (by norm_num) (by norm_num)
      have key : cos (((n + 2 : ℕ) : ℝ) * θ) =
          2 * cos θ * cos (((n + 1 : ℕ) : ℝ) * θ) - cos ((n : ℝ) * θ) := by
        have e1 : ((n + 2 : ℕ) : ℝ) * θ = ((n + 1 : ℕ) : ℝ) * θ + θ := by push_cast; ring
        have e2 : (n : ℝ) * θ = ((n + 1 : ℕ) : ℝ) * θ - θ := by push_cast; ring
        rw [e1, e2, cos_add, cos_sub]; ring
      have ha : (tetSeq (n + 2) : ℝ) = 2 * tetSeq (n + 1) - 9 * tetSeq n := by
        rw [show tetSeq (n + 2) = 2 * tetSeq (n + 1) - 9 * tetSeq n from rfl]; push_cast; ring
      rw [key, hc, ha, ← h1, ← h0]
      ring

lemma arccos_one_third_irrational (q : ℚ) : arccos (1 / 3) ≠ (q : ℝ) * π := by
  intro h
  have hden : (0 : ℝ) < q.den := by exact_mod_cast q.den_pos
  have h2 : ((2 * q.den : ℕ) : ℝ) * arccos (1 / 3) = (q.num : ℝ) * (2 * π) := by
    rw [h]
    have : (q : ℝ) = q.num / q.den := by exact_mod_cast (Rat.num_div_den q).symm
    rw [this]; push_cast; field_simp
  have h3 := three_pow_mul_cos (2 * q.den)
  rw [h2, cos_int_mul_two_pi, mul_one] at h3
  have h4 : ((3 ^ (2 * q.den) : ℤ) : ℝ) = (tetSeq (2 * q.den) : ℝ) := by push_cast; exact h3
  have h5 : (3 : ℤ) ^ (2 * q.den) = tetSeq (2 * q.den) := by exact_mod_cast h4
  apply tetSeq_not_dvd (2 * q.den)
  rw [← h5]
  exact dvd_pow_self 3 (by have := q.den_pos; omega)


#print axioms tetSeq_succ_modEq
#print axioms tetSeq_not_dvd
#print axioms three_pow_mul_cos
#print axioms arccos_one_third_irrational

/-- Hilbert's third problem, the cube and the regular tetrahedron. An angle score is a rule
f on angles where scores add when angles add and a fraction of an angle gets that fraction of
the score (a ℚ-linear map from ℝ to ℝ), with f(π) = 0. There is such a score with
f(arccos(1/3)) = 1. With it, a cube of any edge a (12 edges, all at 90° = π/2) has Dehn
invariant 12 · a · f(π/2) = 0, while a regular tetrahedron of any edge e > 0 (6 edges, all at
the angle arccos(1/3)) has Dehn invariant 6 · e · f(arccos(1/3)), which is not 0. -/
theorem cube_and_tetrahedron_dehn_invariants_differ :
    ∃ f : ℝ →ₗ[ℚ] ℝ, f π = 0 ∧ f (arccos (1 / 3)) = 1 ∧
      ∀ a e : ℝ, 0 < e →
        (12 : ℝ) * a * f (π / 2) = 0 ∧ (6 : ℝ) * e * f (arccos (1 / 3)) ≠ 0 := by
  set p : Submodule ℚ ℝ := Submodule.span ℚ {π}
  have hx : arccos (1 / 3) ∉ p := by
    intro hm
    obtain ⟨q, hq⟩ := Submodule.mem_span_singleton.1 hm
    apply arccos_one_third_irrational q
    rw [← hq, Rat.smul_def]
  obtain ⟨g, hg, hgp⟩ := Submodule.exists_dual_map_eq_bot_of_notMem hx inferInstance
  have hpi : g π = 0 := by
    have : g π ∈ p.map g := Submodule.mem_map_of_mem (Submodule.mem_span_singleton_self π)
    rw [hgp] at this; exact this
  have hf1 : ((Algebra.linearMap ℚ ℝ).comp ((g (arccos (1 / 3)))⁻¹ • g)) (arccos (1 / 3)) = 1 := by
    simp only [LinearMap.comp_apply, LinearMap.smul_apply, smul_eq_mul, inv_mul_cancel₀ hg,
      Algebra.linearMap_apply, map_one]
  have hf0 : ((Algebra.linearMap ℚ ℝ).comp ((g (arccos (1 / 3)))⁻¹ • g)) π = 0 := by
    simp only [LinearMap.comp_apply, LinearMap.smul_apply, smul_eq_mul, hpi, mul_zero,
      Algebra.linearMap_apply, map_zero]
  refine ⟨(Algebra.linearMap ℚ ℝ).comp ((g (arccos (1 / 3)))⁻¹ • g), hf0, hf1, ?_⟩
  · have hhalf : ((Algebra.linearMap ℚ ℝ).comp ((g (arccos (1 / 3)))⁻¹ • g)) (π / 2) = 0 := by
      set f := (Algebra.linearMap ℚ ℝ).comp ((g (arccos (1 / 3)))⁻¹ • g)
      have e : f π = f (π / 2) + f (π / 2) := by rw [← map_add]; ring_nf
      linarith
    intro a e he
    refine ⟨by rw [hhalf]; ring, ?_⟩
    rw [hf1]; positivity

/-- Step 5: the regular tetrahedron's dihedral angle θ = arccos(1/3) is not π times a fraction. -/
theorem arccos_one_third_ne_rat_mul_pi (q : ℚ) : arccos (1 / 3) ≠ (q : ℝ) * π := by
  exact arccos_one_third_irrational q

/-- Step 2: a rectangle oriented with its longer side along the base (0 < W ≤ L) has square side
s = √(L W), which lies between W and L so the cut from (0, W) to (s, 0) lands on the base.
Sliding the piece above the cut far enough to bring its right edge from L to s (a fraction
t = (L − s)/s of the cut, so a rise of t · W) raises the top by exactly s − W. The overhanging
triangle, with legs L − s and s − W, fits beside the square (L − s ≤ s) exactly when L ≤ 4W. -/
theorem rectangle_slide_lands_on_square {L W : ℝ} (hW : 0 < W) (hWL : W ≤ L) :
    W ≤ √(L * W) ∧ √(L * W) ≤ L ∧
      (L - √(L * W)) / √(L * W) * W = √(L * W) - W ∧
      (L - √(L * W) ≤ √(L * W) ↔ L ≤ 4 * W) := by
  have hL : 0 < L := lt_of_lt_of_le hW hWL
  have hLW : 0 < L * W := mul_pos hL hW
  have hs : 0 < √(L * W) := Real.sqrt_pos.2 hLW
  have hs2 : √(L * W) ^ 2 = L * W := Real.sq_sqrt hLW.le
  refine ⟨?_, ?_, ?_, ?_⟩
  · nlinarith
  · nlinarith
  · field_simp
    nlinarith
  · constructor
    · intro h; nlinarith
    · intro h; nlinarith [sq_nonneg (L - 2 * √(L * W))]

-- The roof-truss triangle with legs 3 m and 4 m has area 6 m², and its 3 m by 2 m rectangle too.
example : (3 * 4 : ℚ) / 2 = 6 := by norm_num
example : (3 * 2 : ℕ) = 6 := by decide
-- The slide condition W ≤ L ≤ 4W holds for L = 3, W = 2.
example : (2 : ℕ) ≤ 3 ∧ (3 : ℕ) ≤ 4 * 2 := by decide

/-- a_n = 3^n cos(nθ) in whole numbers: a_0 = a_1 = 1 and a_{n+1} = 2 a_n − 9 a_{n−1}. -/
def a : ℕ → ℤ
  | 0 => 1
  | 1 => 1
  | (n + 2) => 2 * a (n + 1) - 9 * a n

-- The card's values 1, 1, −7, −23, 17, 241, 329, −1511, −5983, none divisible by 3.
example : (List.range 9).map a = [1, 1, -7, -23, 17, 241, 329, -1511, -5983] := by decide
example : ∀ n < 62, ¬ (3 : ℤ) ∣ a n := by decide
-- Five tetrahedra round one edge: cos(5θ) = 241/243, not 1, so 5θ is not a whole turn.
example : (241 : ℤ) ≠ 3 ^ 5 := by decide

#print axioms cube_and_tetrahedron_dehn_invariants_differ
#print axioms arccos_one_third_ne_rat_mul_pi
#print axioms rectangle_slide_lands_on_square
