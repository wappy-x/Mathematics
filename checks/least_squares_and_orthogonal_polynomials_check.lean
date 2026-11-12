-- Fitting instead of passing through: in a basis of polynomials orthogonal on the data points, each least-squares coefficient is one division, each added term lowers the squared misses by its own share, and a three-term recurrence builds such a basis for any distinct points.
import Mathlib.Algebra.Polynomial.Monic
import Mathlib.Algebra.Polynomial.Eval.Defs
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Tactic.LinearCombination

open Polynomial


/-- The overlap of two polynomials on the points `x 0, …, x (m - 1)`: `∑ⱼ f(xⱼ) g(xⱼ)`.
Two polynomials are orthogonal on the points when their overlap is 0, and `overlap x p p`
is the squared size `‖p‖²` of `p` on the points. -/
noncomputable def overlap {m : ℕ} (x : Fin m → ℝ) (f g : ℝ[X]) : ℝ :=
  ∑ j, f.eval (x j) * g.eval (x j)

/-- The sum of squared misses `∑ⱼ (yⱼ − ∑ₖ cₖ pₖ(xⱼ))²` of the curve with coefficients
`c 0, …, c n` in the basis `p 0, …, p n`, against the data `y` at the points `x`. -/
noncomputable def misses {m n : ℕ} (x y : Fin m → ℝ) (p : ℕ → ℝ[X]) (c : Fin (n + 1) → ℝ) : ℝ :=
  ∑ j, (y j - ∑ k : Fin (n + 1), c k * (p k).eval (x j)) ^ 2

/-- The card's coefficient formula: the data's overlap with `p` divided by `p`'s squared size,
`(∑ⱼ yⱼ p(xⱼ)) / ‖p‖²`. -/
noncomputable def orthoCoeff {m : ℕ} (x y : Fin m → ℝ) (p : ℝ[X]) : ℝ :=
  (∑ j, y j * p.eval (x j)) / overlap x p p

lemma overlap_comm' {m : ℕ} (x : Fin m → ℝ) (f g : ℝ[X]) : overlap x f g = overlap x g f := by
  unfold overlap; exact Finset.sum_congr rfl fun j _ => mul_comm _ _

lemma overlap_sub_right' {m : ℕ} (x : Fin m → ℝ) (f g h : ℝ[X]) :
    overlap x f (g - h) = overlap x f g - overlap x f h := by
  unfold overlap; rw [← Finset.sum_sub_distrib]
  exact Finset.sum_congr rfl fun j _ => by rw [eval_sub]; ring

lemma overlap_add_left' {m : ℕ} (x : Fin m → ℝ) (f g h : ℝ[X]) :
    overlap x (f + g) h = overlap x f h + overlap x g h := by
  unfold overlap; rw [← Finset.sum_add_distrib]
  exact Finset.sum_congr rfl fun j _ => by rw [eval_add]; ring

lemma overlap_C_mul_left' {m : ℕ} (x : Fin m → ℝ) (a : ℝ) (f g : ℝ[X]) :
    overlap x (C a * f) g = a * overlap x f g := by
  unfold overlap; rw [Finset.mul_sum]
  exact Finset.sum_congr rfl fun j _ => by rw [eval_mul, eval_C]; ring

lemma overlap_C_mul_right' {m : ℕ} (x : Fin m → ℝ) (a : ℝ) (f g : ℝ[X]) :
    overlap x f (C a * g) = a * overlap x f g := by
  rw [overlap_comm', overlap_C_mul_left', overlap_comm']

lemma overlap_X_sub_C_mul_right' {m : ℕ} (x : Fin m → ℝ) (a : ℝ) (f g : ℝ[X]) :
    overlap x f ((X - C a) * g) = overlap x (X * f) g - a * overlap x f g := by
  unfold overlap; rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
  exact Finset.sum_congr rfl fun j _ => by
    simp only [eval_mul, eval_sub, eval_X, eval_C]; ring

lemma overlap_self_nonneg' {m : ℕ} (x : Fin m → ℝ) (f : ℝ[X]) : 0 ≤ overlap x f f :=
  Finset.sum_nonneg fun _ _ => mul_self_nonneg _

lemma overlap_self_pos' {m : ℕ} (x : Fin m → ℝ) (f : ℝ[X]) (hf : f ≠ 0)
    (hd : f.natDegree < (Finset.univ.image x).card) : 0 < overlap x f f := by
  rcases (overlap_self_nonneg' x f).lt_or_eq with h | h
  · exact h
  · exfalso; apply hf
    apply eq_zero_of_natDegree_lt_card_of_eval_eq_zero' f _ _ hd
    intro r hr
    obtain ⟨j, -, rfl⟩ := Finset.mem_image.mp hr
    have := (Finset.sum_eq_zero_iff_of_nonneg
      (fun j _ => mul_self_nonneg (f.eval (x j)))).mp h.symm j (Finset.mem_univ _)
    exact mul_self_eq_zero.mp this

/-- With orthogonal `p k`, any coefficients `c'` miss by the misses of `c` plus
`∑ₖ (c'ₖ − cₖ)² ‖pₖ‖²`, when `c` satisfies `cₖ ‖pₖ‖² = ∑ⱼ yⱼ pₖ(xⱼ)`. -/
lemma misses_eq_add' {m n : ℕ} (x y : Fin m → ℝ) (p : ℕ → ℝ[X])
    (horth : ∀ i ≤ n, ∀ k ≤ n, i ≠ k → overlap x (p i) (p k) = 0)
    (c c' : Fin (n + 1) → ℝ)
    (hc : ∀ k : Fin (n + 1), c k * overlap x (p k) (p k) = ∑ j, y j * (p k).eval (x j)) :
    misses x y p c' = misses x y p c + ∑ k, (c' k - c k) ^ 2 * overlap x (p k) (p k) := by
  have swap : ∀ (f : Fin m → ℝ) (e : Fin (n + 1) → ℝ),
      ∑ j, f j * ∑ i : Fin (n + 1), e i * (p i).eval (x j) =
        ∑ i : Fin (n + 1), e i * ∑ j, f j * (p i).eval (x j) := by
    intro f e; simp_rw [Finset.mul_sum]; rw [Finset.sum_comm]
    exact Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => by ring
  have cross : ∀ (e : Fin (n + 1) → ℝ) (i : Fin (n + 1)),
      ∑ j, (∑ k : Fin (n + 1), e k * (p k).eval (x j)) * (p i).eval (x j) =
        e i * overlap x (p i) (p i) := by
    intro e i
    have := swap (fun j => (p i).eval (x j)) e
    rw [show (∑ j, (∑ k : Fin (n + 1), e k * (p k).eval (x j)) * (p i).eval (x j)) =
      ∑ j, (p i).eval (x j) * ∑ k : Fin (n + 1), e k * (p k).eval (x j) from
        Finset.sum_congr rfl fun j _ => mul_comm _ _, this]
    rw [Finset.sum_eq_single i]
    · rfl
    · intro k _ hk
      have h0 : overlap x (p i) (p k) = 0 :=
        horth i i.is_le k k.is_le (fun h => hk (Fin.ext h).symm)
      unfold overlap at h0; rw [h0, mul_zero]
    · simp
  set e : Fin (n + 1) → ℝ := fun k => c k - c' k with he
  have hsplit : ∀ j, y j - ∑ k : Fin (n + 1), c' k * (p k).eval (x j) =
      (y j - ∑ k : Fin (n + 1), c k * (p k).eval (x j)) +
        ∑ k : Fin (n + 1), e k * (p k).eval (x j) := by
    intro j; simp only [he, sub_mul, Finset.sum_sub_distrib]; ring
  have hrs : ∑ j, (y j - ∑ k : Fin (n + 1), c k * (p k).eval (x j)) *
      ∑ k : Fin (n + 1), e k * (p k).eval (x j) = 0 := by
    rw [swap]
    refine Finset.sum_eq_zero fun i _ => ?_
    have : ∑ j, (y j - ∑ k : Fin (n + 1), c k * (p k).eval (x j)) * (p i).eval (x j) = 0 := by
      simp only [sub_mul, Finset.sum_sub_distrib]
      rw [cross, hc]; ring
    rw [this, mul_zero]
  have hss : ∑ j, (∑ k : Fin (n + 1), e k * (p k).eval (x j)) ^ 2 =
      ∑ k, (c' k - c k) ^ 2 * overlap x (p k) (p k) := by
    simp_rw [sq]
    rw [swap]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [cross, he]; ring
  unfold misses
  simp_rw [hsplit, add_sq, Finset.sum_add_distrib]
  rw [← hss]; simp_rw [mul_assoc, ← Finset.mul_sum, hrs]; ring


/-- Least squares in an orthogonal basis. Let `p 0, …, p n` be polynomials, `p k` of degree `k`,
orthogonal on the points `x j`, and let the points take at least `n + 1` distinct values. Then
the coefficients `c k = (∑ⱼ yⱼ pₖ(xⱼ)) / ‖pₖ‖²`, one division each, give the smallest possible
sum of squared misses, and no other choice of coefficients does as well. -/
theorem least_squares_coeff_eq_overlap_div_norm_sq {m n : ℕ} (x y : Fin m → ℝ) (p : ℕ → ℝ[X])
    (hdeg : ∀ k ≤ n, (p k).degree = k)
    (horth : ∀ i ≤ n, ∀ k ≤ n, i ≠ k → overlap x (p i) (p k) = 0)
    (hdist : n + 1 ≤ (Finset.univ.image x).card) :
    ∀ c' : Fin (n + 1) → ℝ,
      misses x y p (fun k : Fin (n + 1) => orthoCoeff x y (p k)) ≤ misses x y p c' ∧
      (misses x y p c' ≤ misses x y p (fun k : Fin (n + 1) => orthoCoeff x y (p k)) →
        c' = fun k : Fin (n + 1) => orthoCoeff x y (p k)) := by
  intro c'
  have hN : ∀ k : Fin (n + 1), 0 < overlap x (p k) (p k) := fun k => by
    have hk := hdeg k k.is_le
    apply overlap_self_pos'
    · intro h; rw [h, degree_zero] at hk; exact WithBot.bot_ne_coe hk
    · rw [natDegree_eq_of_degree_eq_some hk]; have := k.is_le; omega
  have hc : ∀ k : Fin (n + 1), orthoCoeff x y (p k) * overlap x (p k) (p k) =
      ∑ j, y j * (p k).eval (x j) := fun k => div_mul_cancel₀ _ (hN k).ne'
  have key := misses_eq_add' x y p horth _ c' hc
  have hnn : ∀ k ∈ Finset.univ, 0 ≤ (c' k - orthoCoeff x y (p k)) ^ 2 * overlap x (p k) (p k) :=
    fun k _ => mul_nonneg (sq_nonneg _) (hN k).le
  refine ⟨?_, fun hle => ?_⟩
  · rw [key]; exact le_add_of_nonneg_right (Finset.sum_nonneg hnn)
  · rw [key] at hle
    have h0 : ∑ k, (c' k - orthoCoeff x y (p k)) ^ 2 * overlap x (p k) (p k) = 0 := by
      have := Finset.sum_nonneg hnn
      linarith
    funext k
    have h1 := (Finset.sum_eq_zero_iff_of_nonneg hnn).mp h0 k (Finset.mem_univ _)
    have h2 := (mul_eq_zero.mp h1).resolve_right (hN k).ne'
    have h3 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h2
    linarith

/-- Each added term removes its own share of the misses. With `p 0, …, p n` orthogonal on the
points and `S k` the squared misses of the fit through degree `k` with the one-division
coefficients `c i`, raising the degree from `k` to `k + 1 ≤ n` lowers the squared misses by exactly
`c (k + 1)² ‖p (k + 1)‖²`: `S k − S (k + 1) = c (k + 1)² ‖p (k + 1)‖²`. -/
theorem misses_sub_misses_succ {m n : ℕ} (x y : Fin m → ℝ) (p : ℕ → ℝ[X])
    (horth : ∀ i ≤ n, ∀ k ≤ n, i ≠ k → overlap x (p i) (p k) = 0) (k : ℕ) (hk : k + 1 ≤ n) :
    misses x y p (fun i : Fin (k + 1) => orthoCoeff x y (p i)) -
        misses x y p (fun i : Fin (k + 2) => orthoCoeff x y (p i)) =
      orthoCoeff x y (p (k + 1)) ^ 2 * overlap x (p (k + 1)) (p (k + 1)) := by
  have hsum : ∀ j, ∑ i : Fin (k + 2), orthoCoeff x y (p i) * (p i).eval (x j) =
      ∑ i : Fin (k + 1), orthoCoeff x y (p i) * (p i).eval (x j) +
        orthoCoeff x y (p (k + 1)) * (p (k + 1)).eval (x j) := fun j => by
    rw [Fin.sum_univ_castSucc]; simp only [Fin.val_castSucc, Fin.val_last]
  have hSQ : ∑ j, (∑ i : Fin (k + 1), orthoCoeff x y (p i) * (p i).eval (x j)) *
      (p (k + 1)).eval (x j) = 0 := by
    simp_rw [Finset.sum_mul]; rw [Finset.sum_comm]
    refine Finset.sum_eq_zero fun i _ => ?_
    have h := horth i (by have := i.is_le; omega) (k + 1) hk (by have := i.is_le; omega)
    unfold overlap at h
    simp_rw [mul_assoc]; rw [← Finset.mul_sum, h, mul_zero]
  unfold misses
  simp_rw [hsum]
  have expand : ∀ (a s b q : ℝ), (a - (s + b * q)) ^ 2 =
      (a - s) ^ 2 - 2 * b * (a * q) + 2 * b * (s * q) + b ^ 2 * (q * q) := fun _ _ _ _ => by ring
  simp_rw [expand]
  simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum]
  rw [hSQ]
  change _ - (_ - _ * (∑ j, y j * (p (k + 1)).eval (x j)) + _ + _ * overlap x (p (k + 1)) (p (k + 1))) = _
  unfold orthoCoeff
  by_cases hN : overlap x (p (k + 1)) (p (k + 1)) = 0
  · rw [hN]; simp
  · have h := div_mul_cancel₀ (∑ j, y j * (p (k + 1)).eval (x j)) hN
    linear_combination
      (-2 * ((∑ j, y j * (p (k + 1)).eval (x j)) / overlap x (p (k + 1)) (p (k + 1)))) * h

/-- The three-term recurrence builds an orthogonal basis for any points. Start from `p 0 = 1`
(and `p (-1) = 0`) and set `p (k + 1) = (x − αₖ) pₖ − βₖ pₖ₋₁` with
`αₖ = ∑ⱼ xⱼ pₖ(xⱼ)² / ‖pₖ‖²` and `βₖ = ‖pₖ‖² / ‖pₖ₋₁‖²`. Then every `p k` has degree `k` and
leading coefficient 1, and when the points take at least `n + 1` distinct values,
`p 0, …, p n` are orthogonal on the points. -/
theorem three_term_recurrence_orthogonal {m n : ℕ} (x : Fin m → ℝ) (p : ℕ → ℝ[X])
    (hdist : n + 1 ≤ (Finset.univ.image x).card)
    (h0 : p 0 = 1)
    (h1 : p 1 = (X - C (overlap x (X * p 0) (p 0) / overlap x (p 0) (p 0))) * p 0)
    (hrec : ∀ k, p (k + 2) =
      (X - C (overlap x (X * p (k + 1)) (p (k + 1)) / overlap x (p (k + 1)) (p (k + 1)))) * p (k + 1)
        - C (overlap x (p (k + 1)) (p (k + 1)) / overlap x (p k) (p k)) * p k) :
    (∀ k, (p k).Monic ∧ (p k).natDegree = k) ∧
      ∀ i k, i < k → k ≤ n → overlap x (p i) (p k) = 0 := by
  have hmon : ∀ k, ((p k).Monic ∧ (p k).natDegree = k) ∧
      ((p (k + 1)).Monic ∧ (p (k + 1)).natDegree = k + 1) := by
    intro k
    induction k with
    | zero =>
      refine ⟨⟨by rw [h0]; exact monic_one, by rw [h0, natDegree_one]⟩, ?_⟩
      rw [h1, h0, mul_one]
      exact ⟨monic_X_sub_C _, natDegree_X_sub_C _⟩
    | succ k ih =>
      obtain ⟨⟨_, hd0⟩, hm1, hd1⟩ := ih
      refine ⟨⟨hm1, hd1⟩, ?_⟩
      rw [hrec k]
      generalize overlap x (X * p (k + 1)) (p (k + 1)) / overlap x (p (k + 1)) (p (k + 1)) = α
      generalize overlap x (p (k + 1)) (p (k + 1)) / overlap x (p k) (p k) = β
      have hqm : ((X - C α) * p (k + 1)).Monic := (monic_X_sub_C _).mul hm1
      have hqd : ((X - C α) * p (k + 1)).natDegree = k + 1 + 1 := by
        rw [(monic_X_sub_C _).natDegree_mul hm1, natDegree_X_sub_C, hd1]; ring
      have hlt : (C β * p k).natDegree < ((X - C α) * p (k + 1)).natDegree :=
        lt_of_le_of_lt (natDegree_C_mul_le _ _) (by omega)
      refine ⟨hqm.sub_of_left (degree_lt_degree hlt), ?_⟩
      rw [natDegree_sub_eq_left_of_natDegree_lt hlt, hqd]
  have hNpos : ∀ k ≤ n, overlap x (p k) (p k) ≠ 0 := fun k hk =>
    (overlap_self_pos' x (p k) (hmon k).1.1.ne_zero (by rw [(hmon k).1.2]; omega)).ne'
  have hX0 : X * p 0 = p 1 + C (overlap x (X * p 0) (p 0) / overlap x (p 0) (p 0)) * p 0 := by
    rw [h1]; ring
  have hXs : ∀ i, X * p (i + 1) = p (i + 2) +
      C (overlap x (X * p (i + 1)) (p (i + 1)) / overlap x (p (i + 1)) (p (i + 1))) * p (i + 1) +
      C (overlap x (p (i + 1)) (p (i + 1)) / overlap x (p i) (p i)) * p i := by
    intro i; rw [hrec i]; ring
  have hXo : ∀ i K, (∀ i' < K, overlap x (p i') (p K) = 0) → i < K →
      overlap x (X * p i) (p K) = overlap x (p (i + 1)) (p K) := by
    intro i K hK hi
    cases i with
    | zero => rw [hX0, overlap_add_left', overlap_C_mul_left', hK 0 hi, mul_zero, add_zero]
    | succ i =>
      show overlap x (X * p (i + 1)) (p K) = overlap x (p (i + 2)) (p K)
      rw [hXs i, overlap_add_left', overlap_add_left', overlap_C_mul_left', overlap_C_mul_left',
        hK (i + 1) hi, hK i (by omega)]
      ring
  have main : ∀ k, k ≤ n → ∀ i < k, overlap x (p i) (p k) = 0 := by
    intro k
    induction k using Nat.strong_induction_on with
    | _ k ih =>
    intro hk i hi
    rcases k with _ | _ | k
    · omega
    · obtain rfl : i = 0 := by omega
      rw [h1, overlap_X_sub_C_mul_right', div_mul_cancel₀ _ (hNpos 0 (by omega)), sub_self]
    · rw [hrec k, overlap_sub_right', overlap_X_sub_C_mul_right', overlap_C_mul_right']
      have IH1 := ih (k + 1) (by omega) (by omega)
      have IH0 := ih k (by omega) (by omega)
      rcases (show i < k ∨ i = k ∨ i = k + 1 by omega) with h | h | h
      · rw [hXo i (k + 1) IH1 (by omega), IH1 (i + 1) (by omega), IH1 i (by omega), IH0 i h]
        ring
      · rw [h, hXo k (k + 1) IH1 (by omega), IH1 k (by omega),
          div_mul_cancel₀ _ (hNpos k (by omega))]
        ring
      · rw [h, overlap_comm' x (p (k + 1)) (p k), IH1 k (by omega),
          div_mul_cancel₀ _ (hNpos (k + 1) (by omega))]
        ring
  exact ⟨fun k => (hmon k).1, fun i k hik hkn => main k hkn i hik⟩

/-! The card's whole-number checks on its 360 months: `t = 2j − 361 = 360 x`, `j = 1, …, 360`. -/

-- The whole-number polynomials q₀ = 1, q₁ = t, q₂ = 3t² − (m² − 1), q₃ = 5t³ − (3m² − 7)t
-- are exactly orthogonal on the 360 points: all six cross products sum to 0.
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360, (2 * j - 361) = 0 := by decide +kernel
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360, (3 * (2 * j - 361) ^ 2 - (360 ^ 2 - 1)) = 0 := by
  decide +kernel
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360,
    (5 * (2 * j - 361) ^ 3 - (3 * 360 ^ 2 - 7) * (2 * j - 361)) = 0 := by decide +kernel
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360,
    (2 * j - 361) * (3 * (2 * j - 361) ^ 2 - (360 ^ 2 - 1)) = 0 := by decide +kernel
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360,
    (2 * j - 361) * (5 * (2 * j - 361) ^ 3 - (3 * 360 ^ 2 - 7) * (2 * j - 361)) = 0 := by
  decide +kernel
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360,
    (3 * (2 * j - 361) ^ 2 - (360 ^ 2 - 1)) *
      (5 * (2 * j - 361) ^ 3 - (3 * 360 ^ 2 - 7) * (2 * j - 361)) = 0 := by decide +kernel

-- The sums of odd powers used in the proof: T₂ = m(m² − 1)/3 and T₄ = m(m² − 1)(3m² − 7)/15.
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360, (2 * j - 361) ^ 2 = 360 * (360 ^ 2 - 1) / 3 := by
  decide +kernel
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360, (2 * j - 361) ^ 4 =
    360 * (360 ^ 2 - 1) * (3 * 360 ^ 2 - 7) / 15 := by decide +kernel

-- The Legendre overlaps on the points, exactly: ∑ P₀P₂ = −1/(2m) and ∑ P₁P₃ = −7(m² − 1)/(6m³).
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360,
    (3 * (((2 * j - 361 : ℤ) : ℚ) / 360) ^ 2 - 1) / 2 = -1 / (2 * 360) := by decide +kernel
example : ∑ j ∈ Finset.Icc (1 : ℤ) 360,
    (((2 * j - 361 : ℤ) : ℚ) / 360) *
      ((5 * (((2 * j - 361 : ℤ) : ℚ) / 360) ^ 3 - 3 * (((2 * j - 361 : ℤ) : ℚ) / 360)) / 2) =
    -7 * (360 ^ 2 - 1) / (6 * 360 ^ 3) := by decide +kernel

-- The flop counts of Step 6 at m = 360: normal equations m(n + 1)² + (n + 1)³/3 (whole-number
-- division, as the code counts) and the recurrence 13 m (n + 1), for 4 and 16 coefficients.
example : 360 * 4 ^ 2 + 4 ^ 3 / 3 = 5781 := by norm_num
example : 360 * 16 ^ 2 + 16 ^ 3 / 3 = 93525 := by norm_num
example : 13 * 360 * 4 = 18720 := by norm_num
example : 13 * 360 * 16 = 74880 := by norm_num

#print axioms overlap_comm'
#print axioms overlap_sub_right'
#print axioms overlap_add_left'
#print axioms overlap_C_mul_left'
#print axioms overlap_C_mul_right'
#print axioms overlap_X_sub_C_mul_right'
#print axioms overlap_self_nonneg'
#print axioms overlap_self_pos'
#print axioms misses_eq_add'
#print axioms least_squares_coeff_eq_overlap_div_norm_sq
#print axioms misses_sub_misses_succ
#print axioms three_term_recurrence_orthogonal
