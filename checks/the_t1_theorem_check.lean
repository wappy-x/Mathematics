-- The T(1) theorem: the Cotlar-Stein lemma, the corner kernel's antisymmetry and size bound, and the mean oscillation 4/e of 2 ln|x| on intervals centred at the corner.
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open scoped InnerProduct

namespace CotlarSteinAux

/-- Sum of `f l` over all lists `l` of length `n` with entries in `S`. -/
def lsum {M : Type*} [AddCommMonoid M] (S : Finset ℤ) : ℕ → (List ℤ → M) → M
  | 0, f => f []
  | n + 1, f => ∑ i ∈ S, lsum S n (fun l => f (i :: l))

theorem lsum_mul_left {R : Type*} [NonUnitalNonAssocSemiring R] (S : Finset ℤ) (n : ℕ)
    (x : R) (f : List ℤ → R) : lsum S n (fun l => x * f l) = x * lsum S n f := by
  induction n generalizing f with
  | zero => rfl
  | succ n ih =>
    simp only [lsum]
    rw [Finset.mul_sum]
    exact Finset.sum_congr rfl (fun i _ => ih (fun l => f (i :: l)))

theorem lsum_mono (S : Finset ℤ) (n : ℕ) (f g : List ℤ → ℝ) (h : ∀ l, f l ≤ g l) :
    lsum S n f ≤ lsum S n g := by
  induction n generalizing f g with
  | zero => exact h []
  | succ n ih =>
    simp only [lsum]
    exact Finset.sum_le_sum (fun i _ => ih _ _ (fun l => h (i :: l)))

theorem lsum_nonneg (S : Finset ℤ) (n : ℕ) (f : List ℤ → ℝ) (h : ∀ l, 0 ≤ f l) :
    0 ≤ lsum S n f := by
  induction n generalizing f with
  | zero => exact h []
  | succ n ih =>
    simp only [lsum]
    exact Finset.sum_nonneg (fun i _ => ih _ (fun l => h (i :: l)))

theorem norm_lsum_le {M : Type*} [SeminormedAddCommGroup M] (S : Finset ℤ) (n : ℕ)
    (f : List ℤ → M) : ‖lsum S n f‖ ≤ lsum S n (fun l => ‖f l‖) := by
  induction n generalizing f with
  | zero => exact le_rfl
  | succ n ih =>
    simp only [lsum]
    exact (norm_sum_le _ _).trans (Finset.sum_le_sum (fun i _ => ih _))

variable {A : Type*} [NormedRing A] [StarRing A]

/-- `V true i = (U i)⋆`, `V false i = U i`. -/
def V (U : ℤ → A) : Bool → ℤ → A
  | true, i => star (U i)
  | false, i => U i

/-- The alternating word `V b i₁ * V (!b) i₂ * V b i₃ * ⋯`. -/
def word (U : ℤ → A) : Bool → List ℤ → A
  | _, [] => 1
  | b, i :: l => V U b i * word U (!b) l

/-- The pair-grouping bound: `a(i₁-i₂)² a(i₃-i₄)² ⋯`, with `a 0` for a lone last letter. -/
def G (a : ℤ → ℝ) : List ℤ → ℝ
  | [] => 1
  | [_] => a 0
  | i :: j :: l => a (i - j) ^ 2 * G a l

/-- The chain weight `a(i₁-i₂) a(i₂-i₃) ⋯`. -/
def C (a : ℤ → ℝ) : List ℤ → ℝ
  | [] => 1
  | [_] => 1
  | i :: j :: l => a (i - j) * C a (j :: l)

theorem G_nonneg (a : ℤ → ℝ) (ha : ∀ s, 0 ≤ a s) : ∀ l, 0 ≤ G a l
  | [] => zero_le_one
  | [_] => ha 0
  | _ :: _ :: l => mul_nonneg (sq_nonneg _) (G_nonneg a ha l)

theorem C_nonneg (a : ℤ → ℝ) (ha : ∀ s, 0 ≤ a s) : ∀ l, 0 ≤ C a l
  | [] => zero_le_one
  | [_] => zero_le_one
  | _ :: j :: l => mul_nonneg (ha _) (C_nonneg a ha (j :: l))

theorem G_mul_G (a : ℤ → ℝ) : ∀ (l : List ℤ) (i : ℤ), G a (i :: l) * G a l = a 0 * C a (i :: l) ^ 2
  | [], i => by simp [G, C]
  | j :: l, i => by
    have := G_mul_G a l j
    simp only [G, C] at this ⊢
    calc a (i - j) ^ 2 * G a l * G a (j :: l) = a (i - j) ^ 2 * (G a (j :: l) * G a l) := by ring
      _ = _ := by rw [this]; ring

theorem norm_VV_le (U : ℤ → A) (a : ℤ → ℝ) (h_left : ∀ i j, ‖star (U i) * U j‖ ≤ a (i - j) ^ 2)
    (h_right : ∀ i j, ‖U i * star (U j)‖ ≤ a (i - j) ^ 2) (b : Bool) (i j : ℤ) :
    ‖V U b i * V U (!b) j‖ ≤ a (i - j) ^ 2 := by
  cases b
  · exact h_right i j
  · exact h_left i j

/-- The alternating product of `n` factors `Y b * Y (!b) * ⋯` with `Y true = T⋆`, `Y false = T`. -/
def Z (U : ℤ → A) (S : Finset ℤ) : Bool → ℕ → A
  | _, 0 => 1
  | b, n + 1 => (∑ i ∈ S, V U b i) * Z U S (!b) n

theorem Z_eq (U : ℤ → A) (S : Finset ℤ) : ∀ (n : ℕ) (b : Bool), Z U S b n = lsum S n (word U b)
  | 0, b => rfl
  | n + 1, b => by
    simp only [Z, lsum, word, Finset.sum_mul]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    rw [Z_eq U S n (!b), lsum_mul_left]

variable [CStarRing A]

theorem norm_V_le (U : ℤ → A) (a : ℤ → ℝ) (h_left : ∀ i j, ‖star (U i) * U j‖ ≤ a (i - j) ^ 2)
    (ha : ∀ s, 0 ≤ a s) (b : Bool) (i : ℤ) : ‖V U b i‖ ≤ a 0 := by
  have h : ‖U i‖ ≤ a 0 := by
    have h1 := h_left i i
    rw [CStarRing.norm_star_mul_self, sub_self] at h1
    nlinarith [norm_nonneg (U i), ha 0]
  cases b <;> simp [V, h]

theorem norm_word_le_G (U : ℤ → A) (a : ℤ → ℝ) (ha : ∀ s, 0 ≤ a s) (h1 : ‖(1 : A)‖ ≤ 1)
    (h_left : ∀ i j, ‖star (U i) * U j‖ ≤ a (i - j) ^ 2)
    (h_right : ∀ i j, ‖U i * star (U j)‖ ≤ a (i - j) ^ 2) :
    ∀ (l : List ℤ) (b : Bool), ‖word U b l‖ ≤ G a l
  | [], b => by simpa [word, G] using h1
  | [i], b => by
    simp only [word, G, mul_one]
    exact norm_V_le U a h_left ha b i
  | i :: j :: l, b => by
    simp only [word, G, Bool.not_not]
    rw [← mul_assoc]
    calc ‖V U b i * V U (!b) j * word U b l‖ ≤ ‖V U b i * V U (!b) j‖ * ‖word U b l‖ :=
          norm_mul_le _ _
      _ ≤ a (i - j) ^ 2 * G a l :=
          mul_le_mul (norm_VV_le U a h_left h_right b i j)
            (norm_word_le_G U a ha h1 h_left h_right l b) (norm_nonneg _) (sq_nonneg _)

theorem norm_word_le_C (U : ℤ → A) (a : ℤ → ℝ) (ha : ∀ s, 0 ≤ a s) (h1 : ‖(1 : A)‖ ≤ 1)
    (h_left : ∀ i j, ‖star (U i) * U j‖ ≤ a (i - j) ^ 2)
    (h_right : ∀ i j, ‖U i * star (U j)‖ ≤ a (i - j) ^ 2) (b : Bool) (i : ℤ) (l : List ℤ) :
    ‖word U b (i :: l)‖ ≤ a 0 * C a (i :: l) := by
  have hA := norm_word_le_G U a ha h1 h_left h_right (i :: l) b
  have hB : ‖word U b (i :: l)‖ ≤ a 0 * G a l := by
    simp only [word]
    exact (norm_mul_le _ _).trans (mul_le_mul (norm_V_le U a h_left ha b i)
      (norm_word_le_G U a ha h1 h_left h_right l (!b)) (norm_nonneg _) (ha 0))
  have hsq : ‖word U b (i :: l)‖ ^ 2 ≤ (a 0 * C a (i :: l)) ^ 2 := by
    calc ‖word U b (i :: l)‖ ^ 2 = ‖word U b (i :: l)‖ * ‖word U b (i :: l)‖ := sq _
      _ ≤ G a (i :: l) * (a 0 * G a l) :=
          mul_le_mul hA hB (norm_nonneg _) (G_nonneg a ha _)
      _ = a 0 * (G a (i :: l) * G a l) := by ring
      _ = (a 0 * C a (i :: l)) ^ 2 := by rw [G_mul_G]; ring
  exact (pow_le_pow_iff_left₀ (norm_nonneg _) (mul_nonneg (ha 0) (C_nonneg a ha _))
    two_ne_zero).mp hsq

theorem sum_shift_le (a : ℤ → ℝ) (ha : ∀ s, 0 ≤ a s) (ha_sum : Summable a) (S : Finset ℤ)
    (i : ℤ) : ∑ j ∈ S, a (i - j) ≤ ∑' s, a s := by
  have hs : Summable (fun j => a (i - j)) := (Equiv.subLeft i).summable_iff.mpr ha_sum
  calc ∑ j ∈ S, a (i - j) ≤ ∑' j, a (i - j) := hs.sum_le_tsum S (fun j _ => ha _)
    _ = ∑' s, a s := (Equiv.subLeft i).tsum_eq a

theorem lsum_C_le (a : ℤ → ℝ) (ha : ∀ s, 0 ≤ a s) (ha_sum : Summable a) (S : Finset ℤ) :
    ∀ (n : ℕ) (i : ℤ), lsum S n (fun l => C a (i :: l)) ≤ (∑' s, a s) ^ n
  | 0, i => by simp [lsum, C]
  | n + 1, i => by
    have hΛ : 0 ≤ ∑' s, a s := tsum_nonneg ha
    simp only [lsum, C]
    calc ∑ j ∈ S, lsum S n (fun l => a (i - j) * C a (j :: l))
        = ∑ j ∈ S, a (i - j) * lsum S n (fun l => C a (j :: l)) :=
          Finset.sum_congr rfl (fun j _ => lsum_mul_left S n _ _)
      _ ≤ ∑ j ∈ S, a (i - j) * (∑' s, a s) ^ n :=
          Finset.sum_le_sum (fun j _ => mul_le_mul_of_nonneg_left (lsum_C_le a ha ha_sum S n j) (ha _))
      _ = (∑ j ∈ S, a (i - j)) * (∑' s, a s) ^ n := by rw [Finset.sum_mul]
      _ ≤ (∑' s, a s) * (∑' s, a s) ^ n :=
          mul_le_mul_of_nonneg_right (sum_shift_le a ha ha_sum S i) (pow_nonneg hΛ n)
      _ = (∑' s, a s) ^ (n + 1) := by ring

theorem cotlar_stein_power (U : ℤ → A) (a : ℤ → ℝ) (ha : ∀ s, 0 ≤ a s) (ha_sum : Summable a)
    (h1 : ‖(1 : A)‖ ≤ 1)
    (h_left : ∀ i j, ‖star (U i) * U j‖ ≤ a (i - j) ^ 2)
    (h_right : ∀ i j, ‖U i * star (U j)‖ ≤ a (i - j) ^ 2) (S : Finset ℤ) (n : ℕ) :
    ‖Z U S true (n + 1)‖ ≤ S.card * (∑' s, a s) ^ (n + 1) := by
  have hΛ : 0 ≤ ∑' s, a s := tsum_nonneg ha
  have ha0 : a 0 ≤ ∑' s, a s := ha_sum.le_tsum 0 (fun j _ => ha j)
  rw [Z_eq]
  refine (norm_lsum_le S (n + 1) _).trans ?_
  simp only [lsum]
  calc ∑ i ∈ S, lsum S n (fun l => ‖word U true (i :: l)‖)
      ≤ ∑ i ∈ S, lsum S n (fun l => a 0 * C a (i :: l)) :=
        Finset.sum_le_sum (fun i _ => lsum_mono S n _ _
          (fun l => norm_word_le_C U a ha h1 h_left h_right true i l))
    _ = ∑ i ∈ S, a 0 * lsum S n (fun l => C a (i :: l)) :=
        Finset.sum_congr rfl (fun i _ => lsum_mul_left S n _ _)
    _ ≤ ∑ _i ∈ S, (∑' s, a s) * (∑' s, a s) ^ n :=
        Finset.sum_le_sum (fun i _ => mul_le_mul ha0 (lsum_C_le a ha ha_sum S n i)
          (lsum_nonneg S n _ (fun l => C_nonneg a ha _)) hΛ)
    _ = S.card * (∑' s, a s) ^ (n + 1) := by rw [Finset.sum_const, nsmul_eq_mul]; ring

omit [CStarRing A] in
theorem Z_two_mul (U : ℤ → A) (S : Finset ℤ) (m : ℕ) :
    Z U S true (2 * m) = (star (∑ j ∈ S, U j) * ∑ j ∈ S, U j) ^ m := by
  induction m with
  | zero => simp [Z]
  | succ m ih =>
    rw [show 2 * (m + 1) = 2 * m + 1 + 1 by ring, pow_succ', ← ih]
    simp only [Z, star_sum, V, Bool.not_true, Bool.not_false, mul_assoc]

theorem le_of_pow_le_mul_pow (x y c : ℝ) (hy : 0 ≤ y)
    (h : ∀ k : ℕ, x ^ (2 * 2 ^ k) ≤ c * y ^ (2 * 2 ^ k)) : x ≤ y := by
  by_contra hxy
  push Not at hxy
  rcases hy.eq_or_lt with hy0 | hy0
  · subst hy0
    have := h 0
    rw [show 2 * 2 ^ 0 = 2 by norm_num, zero_pow two_ne_zero, mul_zero] at this
    nlinarith [pow_pos hxy 2]
  · set r := x / y with hr
    have hr1 : 1 < r := by rw [hr, one_lt_div hy0]; exact hxy
    obtain ⟨k, hk⟩ := exists_nat_gt (c / (r - 1))
    have hpos : 0 < r - 1 := by linarith
    have hN : (k : ℝ) ≤ ((2 * 2 ^ k : ℕ) : ℝ) := by
      exact_mod_cast (Nat.lt_two_pow_self (n := k)).le.trans (by omega)
    have hb : 1 + ((2 * 2 ^ k : ℕ) : ℝ) * (r - 1) ≤ r ^ (2 * 2 ^ k) := by
      have := one_add_mul_le_pow (a := r - 1) (by linarith) (2 * 2 ^ k)
      simpa using this
    have hc : r ^ (2 * 2 ^ k) ≤ c := by
      have hyN : 0 < y ^ (2 * 2 ^ k) := pow_pos hy0 _
      rw [hr, div_pow, div_le_iff₀ hyN]
      exact h k
    have : c < k * (r - 1) := by rwa [div_lt_iff₀ hpos] at hk
    nlinarith


#print axioms lsum_mul_left
#print axioms lsum_mono
#print axioms lsum_nonneg
#print axioms norm_lsum_le
#print axioms G_nonneg
#print axioms C_nonneg
#print axioms G_mul_G
#print axioms norm_VV_le
#print axioms Z_eq
#print axioms norm_V_le
#print axioms norm_word_le_G
#print axioms norm_word_le_C
#print axioms sum_shift_le
#print axioms lsum_C_le
#print axioms cotlar_stein_power
#print axioms Z_two_mul
#print axioms le_of_pow_le_mul_pow

end CotlarSteinAux

theorem integral_abs_two_log_sub (r : ℝ) (hr : 0 < r) :
    ∫ x in (0:ℝ)..r, |2 * Real.log x - (2 * Real.log r - 2)| = 4 * r / Real.exp 1 := by
  set c := 2 * Real.log r - 2 with hc
  set m := r / Real.exp 1 with hm
  have he : 0 < Real.exp 1 := Real.exp_pos 1
  have hm0 : 0 < m := div_pos hr he
  have hmr : m ≤ r := div_le_self hr.le (Real.one_le_exp zero_le_one)
  have hlogm : Real.log m = Real.log r - 1 := by
    rw [hm, Real.log_div hr.ne' he.ne', Real.log_exp]
  have hint : ∀ a b : ℝ, IntervalIntegrable (fun x => |2 * Real.log x - c|) MeasureTheory.volume a b :=
    fun a b => ((intervalIntegral.intervalIntegrable_log'.const_mul 2).sub
      intervalIntegrable_const).abs
  rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 m) (hint m r)]
  have h1 : ∫ x in (0:ℝ)..m, |2 * Real.log x - c| = ∫ x in (0:ℝ)..m, (c - 2 * Real.log x) := by
    refine intervalIntegral.integral_congr_ae (Filter.Eventually.of_forall (fun x hx => ?_))
    rw [Set.uIoc_of_le hm0.le] at hx
    have : Real.log x ≤ Real.log m := Real.log_le_log hx.1 hx.2
    rw [abs_of_nonpos (by rw [hc]; linarith), neg_sub]
  have h2 : ∫ x in m..r, |2 * Real.log x - c| = ∫ x in m..r, (2 * Real.log x - c) := by
    refine intervalIntegral.integral_congr_ae (Filter.Eventually.of_forall (fun x hx => ?_))
    rw [Set.uIoc_of_le hmr] at hx
    have : Real.log m ≤ Real.log x := Real.log_le_log hm0 hx.1.le
    rw [abs_of_nonneg (by rw [hc]; linarith)]
  rw [h1, h2, intervalIntegral.integral_sub intervalIntegrable_const
      (intervalIntegral.intervalIntegrable_log'.const_mul 2),
    intervalIntegral.integral_sub (intervalIntegral.intervalIntegrable_log'.const_mul 2)
      intervalIntegrable_const,
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
    intervalIntegral.integral_const, intervalIntegral.integral_const, integral_log, integral_log]
  simp only [smul_eq_mul, Real.log_zero, mul_zero, sub_zero, add_zero, hlogm, hc]
  have : r = m * Real.exp 1 := by rw [hm, div_mul_cancel₀ _ he.ne']
  rw [show 4 * r / Real.exp 1 = 4 * m by rw [hm]; ring]
  rw [this, Real.log_mul hm0.ne' he.ne', Real.log_exp] at *
  ring_nf

#print axioms integral_abs_two_log_sub

/-- The Cotlar-Stein lemma: if operators `U j` on a Hilbert space overlap only a little,
`‖U i† U j‖ ≤ a(i - j)²` and `‖U i U j†‖ ≤ a(i - j)²`, where the overlap sizes `a(s) ≥ 0`
have a finite sum `Λ = ∑ a(s)`, then every finite sum of the `U j` has norm at most `Λ`,
however many pieces it has. -/
theorem cotlar_stein {𝕜 E : Type*} [RCLike 𝕜] [NormedAddCommGroup E] [InnerProductSpace 𝕜 E]
    [CompleteSpace E] (U : ℤ → E →L[𝕜] E) (a : ℤ → ℝ) (ha_nonneg : ∀ s, 0 ≤ a s)
    (ha_sum : Summable a) (h_left : ∀ i j, ‖(U i)† * U j‖ ≤ a (i - j) ^ 2)
    (h_right : ∀ i j, ‖U i * (U j)†‖ ≤ a (i - j) ^ 2) (S : Finset ℤ) :
    ‖∑ j ∈ S, U j‖ ≤ ∑' s, a s := by
  have hl : ∀ i j, ‖star (U i) * U j‖ ≤ a (i - j) ^ 2 := by
    intro i j; rw [ContinuousLinearMap.star_eq_adjoint]; exact h_left i j
  have hr : ∀ i j, ‖U i * star (U j)‖ ≤ a (i - j) ^ 2 := by
    intro i j; rw [ContinuousLinearMap.star_eq_adjoint]; exact h_right i j
  have h1 : ‖(1 : E →L[𝕜] E)‖ ≤ 1 := ContinuousLinearMap.norm_id_le
  set T := ∑ j ∈ S, U j with hT
  refine CotlarSteinAux.le_of_pow_le_mul_pow ‖T‖ (∑' s, a s) S.card
    (tsum_nonneg ha_nonneg) (fun k => ?_)
  have hpow := CotlarSteinAux.cotlar_stein_power U a ha_nonneg ha_sum h1 hl hr S (2 * 2 ^ k - 1)
  have hk : 2 * 2 ^ k - 1 + 1 = 2 * 2 ^ k := by have := Nat.one_le_two_pow (n := k); omega
  rw [hk, CotlarSteinAux.Z_two_mul, (IsSelfAdjoint.star_mul_self T).norm_pow_two_pow,
    CStarRing.norm_star_mul_self] at hpow
  calc ‖T‖ ^ (2 * 2 ^ k) = (‖T‖ * ‖T‖) ^ 2 ^ k := by rw [pow_mul, sq]
    _ ≤ _ := hpow

/-- The corner's kernel `K(x, y) = (|x| - |y|)/(x - y)²` is antisymmetric, `K(y, x) = -K(x, y)`,
so the commutator's transpose is minus itself, and it has size at most `1/|x - y|`. -/
theorem corner_kernel_antisymm_and_size (x y : ℝ) (hxy : x ≠ y) :
    (|y| - |x|) / (y - x) ^ 2 = -((|x| - |y|) / (x - y) ^ 2) ∧
      |(|x| - |y|) / (x - y) ^ 2| ≤ 1 / |x - y| := by
  constructor
  · rw [show (y - x) ^ 2 = (x - y) ^ 2 by ring, ← neg_div, neg_sub]
  · have hpos : 0 < |x - y| := abs_pos.mpr (sub_ne_zero.mpr hxy)
    rw [abs_div, abs_of_nonneg (sq_nonneg (x - y)), ← sq_abs (x - y), div_le_div_iff₀ (by positivity) hpos]
    calc |(|x| - |y|)| * |x - y| ≤ |x - y| * |x - y| :=
          mul_le_mul_of_nonneg_right (abs_abs_sub_abs_le_abs_sub x y) hpos.le
      _ = 1 * |x - y| ^ 2 := by ring

/-- On every interval `(-r, r)` centred at the corner, the mean oscillation of `2 ln|x|`,
the average distance from its own average, is exactly `4/e`. -/
theorem mean_oscillation_two_log_abs_centred (r : ℝ) (hr : 0 < r) :
    (1 / (2 * r)) * (∫ x in (-r)..r,
        abs (2 * Real.log |x| - (1 / (2 * r)) * ∫ y in (-r)..r, 2 * Real.log |y|)) =
      4 / Real.exp 1 := by
  have hc : (1 / (2 * r)) * ∫ y in (-r)..r, 2 * Real.log |y| = 2 * Real.log r - 2 := by
    simp only [Real.log_abs]
    rw [intervalIntegral.integral_const_mul, integral_log, Real.log_neg_eq_log]
    field_simp
    ring
  rw [hc]
  simp only [Real.log_abs]
  have hint : ∀ a b : ℝ, IntervalIntegrable (fun x => |2 * Real.log x - (2 * Real.log r - 2)|)
      MeasureTheory.volume a b :=
    fun a b => ((intervalIntegral.intervalIntegrable_log'.const_mul 2).sub
      intervalIntegrable_const).abs
  rw [← intervalIntegral.integral_add_adjacent_intervals (hint (-r) 0) (hint 0 r)]
  have hneg : ∫ x in (-r)..0, |2 * Real.log x - (2 * Real.log r - 2)| =
      ∫ x in (0:ℝ)..r, |2 * Real.log x - (2 * Real.log r - 2)| := by
    have h := intervalIntegral.integral_comp_neg (a := 0) (b := r)
      (fun x => |2 * Real.log x - (2 * Real.log r - 2)|)
    rw [neg_zero] at h
    rw [← h]
    simp only [Real.log_neg_eq_log]
  rw [hneg, integral_abs_two_log_sub r hr]
  field_simp
  ring

#print axioms cotlar_stein
#print axioms corner_kernel_antisymm_and_size
#print axioms mean_oscillation_two_log_abs_centred
