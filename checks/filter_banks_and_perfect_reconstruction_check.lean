-- Filter banks: a two-band filter bank gives back every input exactly, one fixed delay late, if and only if its alias term is zero and its through term is a pure delay.
import Mathlib.Algebra.Polynomial.AlgebraMap
import Mathlib.Algebra.Polynomial.Coeff
import Mathlib.Algebra.Polynomial.Degree.TrailingDegree
import Mathlib.Algebra.Ring.Parity
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

/-! A filter is a finite causal filter, written as a polynomial in `w = z⁻¹`:
its taps are the coefficients, so `H = ∑ h[k] w^k` stands for `H(z) = ∑ h[k] z^(-k)`.
Replacing `z` by `-z` is replacing `w` by `-w`, which is Mathlib's `p.comp (-X)`.
A signal is any two-sided list of real samples `x : ℤ → ℝ`.

* `filt p x` runs the filter causally: `y[n] = ∑ p.coeff k * x[n - k]`.
* `halveStuff y` keeps one sample in two and puts a zero back between them:
  even-numbered samples kept, odd-numbered ones zeroed (both bands keep the even ones).
* `bank H G F0 F1 x` splits `x` with the analysis pair `H`, `G`, halves and stuffs both bands,
  rebuilds them with the synthesis pair `F0`, `F1`, and adds.
* `throughTerm` is `T(z) = ½[F0(z)H(z) + F1(z)G(z)]` and
  `aliasTerm` is `A(z) = ½[F0(z)H(-z) + F1(z)G(-z)]`. -/

open Polynomial

/-- Run a causal finite filter with taps `p.coeff k` over a two-sided signal. -/
noncomputable def filt (p : ℝ[X]) (x : ℤ → ℝ) : ℤ → ℝ :=
  fun n => p.sum fun k a => a * x (n - k)

/-- Halving then stuffing: keep the even-numbered samples, zero the odd-numbered ones. -/
def halveStuff (y : ℤ → ℝ) : ℤ → ℝ :=
  fun n => if Even n then y n else 0

/-- The two-band bank: analysis `H`, `G`; halve and stuff each band; synthesis `F0`, `F1`; add. -/
noncomputable def bank (H G F0 F1 : ℝ[X]) (x : ℤ → ℝ) : ℤ → ℝ :=
  filt F0 (halveStuff (filt H x)) + filt F1 (halveStuff (filt G x))

/-- The through term `T(z) = ½[F0(z)H(z) + F1(z)G(z)]`. -/
noncomputable def throughTerm (H G F0 F1 : ℝ[X]) : ℝ[X] :=
  C (1 / 2) * (F0 * H + F1 * G)

/-- The alias term `A(z) = ½[F0(z)H(-z) + F1(z)G(-z)]`. -/
noncomputable def aliasTerm (H G F0 F1 : ℝ[X]) : ℝ[X] :=
  C (1 / 2) * (F0 * H.comp (-X) + F1 * G.comp (-X))

lemma fb_coeff_comp_negX (p : ℝ[X]) (k : ℕ) : (p.comp (-X)).coeff k = (-1) ^ k * p.coeff k := by
  have h : (-X : ℝ[X]) = C (-1) * X := by simp
  rw [h, comp_C_mul_X_coeff, mul_comm]

lemma fb_filt_add (p q : ℝ[X]) (x : ℤ → ℝ) : filt (p + q) x = filt p x + filt q x := by
  funext n
  simp only [filt, Pi.add_apply]
  exact Polynomial.sum_add_index p q _ (fun _ => by simp) (fun _ _ _ => by ring)

lemma fb_filt_monomial (k : ℕ) (a : ℝ) (x : ℤ → ℝ) (n : ℤ) :
    filt (monomial k a) x n = a * x (n - k) := by
  simp only [filt]
  exact Polynomial.sum_monomial_index _ _ (by simp)

lemma fb_filt_add_sig (p : ℝ[X]) (x y : ℤ → ℝ) : filt p (x + y) = filt p x + filt p y := by
  funext n
  simp [filt, Polynomial.sum_def, mul_add, Finset.sum_add_distrib]

lemma fb_filt_mul (p q : ℝ[X]) (x : ℤ → ℝ) : filt (p * q) x = filt p (filt q x) := by
  induction p using Polynomial.induction_on' with
  | add p1 p2 h1 h2 => rw [add_mul, fb_filt_add, fb_filt_add, h1, h2]
  | monomial i a =>
    induction q using Polynomial.induction_on' with
    | add q1 q2 h1 h2 => rw [mul_add, fb_filt_add, h1, h2, fb_filt_add, fb_filt_add_sig]
    | monomial j b =>
      funext n
      rw [monomial_mul_monomial, fb_filt_monomial, fb_filt_monomial, fb_filt_monomial,
        Nat.cast_add, ← sub_sub]
      ring

lemma fb_filt_C (c : ℝ) (y : ℤ → ℝ) (n : ℤ) : filt (C c) y n = c * y n := by
  rw [← monomial_zero_left, fb_filt_monomial]
  simp

lemma fb_filt_zero (x : ℤ → ℝ) : filt 0 x = 0 := by
  funext n
  simp [filt]

lemma fb_filt_X_pow (l : ℕ) (x : ℤ → ℝ) (n : ℤ) : filt (X ^ l) x n = x (n - l) := by
  rw [X_pow_eq_monomial, fb_filt_monomial, one_mul]

/-- The sign `(-1)^n` on the integers. -/
noncomputable def fbSg (n : ℤ) : ℝ := if Even n then 1 else -1

lemma fb_sg_sub (n : ℤ) (k : ℕ) : (-1 : ℝ) ^ k * fbSg (n - k) = fbSg n := by
  rcases Nat.even_or_odd k with hk | hk
  · have hk' : Even (k : ℤ) := by exact_mod_cast hk
    by_cases hn : Even n
    · have : Even (n - k) := hn.sub hk'
      simp [fbSg, hk.neg_one_pow, hn, this]
    · have : ¬ Even (n - k) := by
        intro h; exact hn (by simpa using h.add hk')
      simp [fbSg, hk.neg_one_pow, hn, this]
  · have hk' : Odd (k : ℤ) := by exact_mod_cast hk
    by_cases hn : Even n
    · have : ¬ Even (n - k) := by
        rw [Int.not_even_iff_odd]; exact hn.sub_odd hk'
      simp [fbSg, hk.neg_one_pow, hn, this]
    · have : Even (n - k) := by
        rw [Int.not_even_iff_odd] at hn; exact hn.sub_odd hk'
      simp [fbSg, hk.neg_one_pow, hn, this]

lemma fb_monomial_comp_negX (k : ℕ) (a : ℝ) :
    (monomial k a).comp (-X) = monomial k ((-1) ^ k * a) := by
  ext m
  rw [fb_coeff_comp_negX, coeff_monomial, coeff_monomial]
  split_ifs with h
  · subst h; rfl
  · ring

lemma fb_twist (p : ℝ[X]) (x : ℤ → ℝ) :
    filt (p.comp (-X)) (fun n => fbSg n * x n) = fun n => fbSg n * filt p x n := by
  induction p using Polynomial.induction_on' with
  | add p1 p2 h1 h2 =>
    funext n
    rw [add_comp, fb_filt_add, fb_filt_add, Pi.add_apply, Pi.add_apply, congrFun h1 n,
      congrFun h2 n]
    ring
  | monomial k a =>
    funext n
    rw [fb_monomial_comp_negX, fb_filt_monomial, fb_filt_monomial, ← fb_sg_sub n k]
    ring

lemma fb_bank_eq (H G F0 F1 : ℝ[X]) (x : ℤ → ℝ) :
    bank H G F0 F1 x =
      filt (throughTerm H G F0 F1) x + filt (aliasTerm H G F0 F1) (fun n => fbSg n * x n) := by
  have key : ∀ P Q : ℝ[X], filt P (halveStuff (filt Q x)) =
      filt (C (1 / 2) * P * Q) x + filt (C (1 / 2) * P * Q.comp (-X)) (fun n => fbSg n * x n) := by
    intro P Q
    have hs : halveStuff (filt Q x) =
        filt (C (1 / 2)) (filt Q x + filt (Q.comp (-X)) (fun n => fbSg n * x n)) := by
      funext n
      rw [fb_filt_C, fb_twist, Pi.add_apply]
      unfold halveStuff fbSg
      split_ifs <;> ring
    rw [hs, ← fb_filt_mul, fb_filt_add_sig, ← fb_filt_mul, ← fb_filt_mul, mul_comm P (C _)]
  unfold bank
  rw [key, key]
  have hT : throughTerm H G F0 F1 = C (1 / 2) * F0 * H + C (1 / 2) * F1 * G := by
    unfold throughTerm; ring
  have hA : aliasTerm H G F0 F1 = C (1 / 2) * F0 * H.comp (-X) + C (1 / 2) * F1 * G.comp (-X) := by
    unfold aliasTerm; ring
  rw [hT, hA, fb_filt_add, fb_filt_add]
  abel

lemma fb_impulse (p : ℝ[X]) (m : ℤ) (v : ℝ) (j : ℕ) :
    filt p (fun n => if n = m then v else 0) (m + j) = p.coeff j * v := by
  simp only [filt, Polynomial.sum_def]
  rw [Finset.sum_eq_single j]
  · simp
  · intro k _ hk
    have : m + (j : ℤ) - k ≠ m := by
      intro h; apply hk; omega
    simp [this]
  · intro hj
    rw [Polynomial.notMem_support_iff.mp hj]
    simp

lemma fb_sg_impulse (m : ℤ) (v : ℝ) :
    (fun n => fbSg n * (if n = m then v else 0)) = fun n => if n = m then fbSg m * v else 0 := by
  funext n
  split_ifs with h
  · subst h; rfl
  · simp

lemma fb_mono_of_tr (p : ℝ[X]) (h : p.natTrailingDegree = p.natDegree) :
    p = C (p.coeff p.natDegree) * X ^ p.natDegree := by
  ext n
  rw [coeff_C_mul_X_pow]
  obtain hn | rfl | hn := lt_trichotomy n p.natDegree
  · rw [if_neg hn.ne, coeff_eq_zero_of_lt_natTrailingDegree (h ▸ hn)]
  · simp
  · rw [if_neg hn.ne', coeff_eq_zero_of_natDegree_lt hn]

lemma fb_factor_monomial (E O : ℝ[X]) (r : ℝ) (hr : r ≠ 0) (l : ℕ) (h : E * O = C r * X ^ l) :
    E ≠ 0 ∧ O ≠ 0 ∧ E = C (E.coeff E.natDegree) * X ^ E.natDegree ∧
      O = C (O.coeff O.natDegree) * X ^ O.natDegree := by
  have hE : E ≠ 0 := by rintro rfl; simp [hr] at h
  have hO : O ≠ 0 := by rintro rfl; simp [hr] at h
  have hdeg : E.natDegree + O.natDegree = l := by
    rw [← natDegree_mul hE hO, h, natDegree_C_mul_X_pow l r hr]
  have htr : E.natTrailingDegree + O.natTrailingDegree = l := by
    rw [← natTrailingDegree_mul hE hO, h, C_mul_X_pow_eq_monomial, natTrailingDegree_monomial hr]
  have h1 := natTrailingDegree_le_natDegree (p := E)
  have h2 := natTrailingDegree_le_natDegree (p := O)
  exact ⟨hE, hO, fb_mono_of_tr E (by omega), fb_mono_of_tr O (by omega)⟩

/-- A two-band filter bank with fixed linear filters `H`, `G` (analysis) and `F0`, `F1`
(synthesis), in which both bands keep the even-numbered samples and nothing changes the
bands between split and rejoin, gives back every input exactly, `ℓ` samples late
(`x~[n] = x[n - ℓ]`), if and only if the alias term is zero (`A(z) = 0`) and the through
term is a pure delay (`T(z) = z^(-ℓ)`). -/
theorem perfect_reconstruction_iff_no_alias_and_pure_delay (H G F0 F1 : ℝ[X]) (ℓ : ℕ) :
    (∀ x : ℤ → ℝ, bank H G F0 F1 x = fun n => x (n - ℓ)) ↔
      aliasTerm H G F0 F1 = 0 ∧ throughTerm H G F0 F1 = X ^ ℓ := by
  constructor
  · intro h
    have hd : ∀ x : ℤ → ℝ, ∀ n, filt (throughTerm H G F0 F1) x n +
        filt (aliasTerm H G F0 F1) (fun n => fbSg n * x n) n = x (n - ℓ) := by
      intro x n
      have := congrFun (h x) n
      rw [fb_bank_eq] at this
      exact this
    have e0 : ∀ j : ℕ, (throughTerm H G F0 F1).coeff j + (aliasTerm H G F0 F1).coeff j =
        if j = ℓ then 1 else 0 := by
      intro j
      have := hd (fun n => if n = 0 then 1 else 0) ((0 : ℤ) + j)
      beta_reduce at this
      rw [fb_sg_impulse, fb_impulse, fb_impulse] at this
      have hs : fbSg 0 = 1 := by simp [fbSg]
      rw [hs] at this
      split_ifs at this ⊢ <;> first | omega | linarith
    have e1 : ∀ j : ℕ, (throughTerm H G F0 F1).coeff j - (aliasTerm H G F0 F1).coeff j =
        if j = ℓ then 1 else 0 := by
      intro j
      have := hd (fun n => if n = 1 then 1 else 0) ((1 : ℤ) + j)
      beta_reduce at this
      rw [fb_sg_impulse, fb_impulse, fb_impulse] at this
      have hs : fbSg 1 = -1 := by simp [fbSg]
      rw [hs] at this
      split_ifs at this ⊢ <;> first | omega | linarith
    refine ⟨?_, ?_⟩
    · ext j
      have h0 := e0 j
      have h1 := e1 j
      rw [coeff_zero]
      split_ifs at h0 h1 <;> linarith
    · ext j
      have h0 := e0 j
      have h1 := e1 j
      rw [coeff_X_pow]
      split_ifs at h0 h1 ⊢ <;> linarith
  · rintro ⟨hA, hT⟩ x
    funext n
    rw [fb_bank_eq, hA, hT, fb_filt_zero, Pi.add_apply, fb_filt_X_pow, Pi.zero_apply, add_zero]

/-- The cross-mirror rule `F0(z) = G(-z)`, `F1(z) = -H(-z)` makes the alias term zero for
any analysis pair `H`, `G`. With it, the bank rebuilds exactly with delay `ℓ` if and only if
the product filter `P(z) = H(z)F0(z)` is half-band: `ℓ` is odd, tap `ℓ` of `P` is 1, and every
other odd-numbered tap of `P` is 0. -/
theorem cross_mirror_rule_kills_alias_and_needs_half_band (H G : ℝ[X]) (ℓ : ℕ) :
    aliasTerm H G (G.comp (-X)) (-H.comp (-X)) = 0 ∧
      ((∀ x : ℤ → ℝ, bank H G (G.comp (-X)) (-H.comp (-X)) x = fun n => x (n - ℓ)) ↔
        Odd ℓ ∧ ∀ k : ℕ, Odd k → (H * G.comp (-X)).coeff k = if k = ℓ then 1 else 0) := by
  have hA : aliasTerm H G (G.comp (-X)) (-H.comp (-X)) = 0 := by
    unfold aliasTerm; ring
  refine ⟨hA, ?_⟩
  rw [perfect_reconstruction_iff_no_alias_and_pure_delay, hA]
  simp only [true_and]
  obtain ⟨P, hP⟩ : ∃ P, P = H * G.comp (-X) := ⟨_, rfl⟩
  rw [← hP]
  have hT : ∀ k : ℕ, (throughTerm H G (G.comp (-X)) (-H.comp (-X))).coeff k =
      if Odd k then P.coeff k else 0 := by
    intro k
    have e : throughTerm H G (G.comp (-X)) (-H.comp (-X)) = C (1 / 2) * (P - P.comp (-X)) := by
      rw [hP, mul_comp_neg_X, comp_neg_X_comp_neg_X]
      unfold throughTerm
      ring
    rw [e, coeff_C_mul, coeff_sub, fb_coeff_comp_negX]
    rcases Nat.even_or_odd k with hk | hk
    · rw [if_neg (Nat.not_odd_iff_even.mpr hk), hk.neg_one_pow]; ring
    · rw [if_pos hk, hk.neg_one_pow]; ring
  constructor
  · intro h
    have hc : ∀ k, (throughTerm H G (G.comp (-X)) (-H.comp (-X))).coeff k =
        if k = ℓ then 1 else 0 := fun k => by rw [h, coeff_X_pow]
    have hl : Odd ℓ := by
      by_contra hn
      have := hc ℓ
      rw [hT, if_neg hn] at this
      simp at this
    refine ⟨hl, fun k hk => ?_⟩
    have := hc k
    rw [hT, if_pos hk] at this
    exact this
  · rintro ⟨hl, hk⟩
    ext k
    rw [hT, coeff_X_pow]
    by_cases ho : Odd k
    · rw [if_pos ho, hk k ho]
    · rw [if_neg ho, if_neg]
      rintro rfl
      exact ho hl

/-- The original mirror pair: the high-pass is the mirror of the low-pass, `G(z) = H(-z)`,
with the cross-mirror synthesis filters. If this bank rebuilds every input exactly with delay
`ℓ`, then `H` has just two nonzero taps, `c` at an even-numbered position `a` and `d` at an
odd-numbered position `b`, with `2cd = 1` and `a + b = ℓ`. -/
theorem mirror_pair_exact_only_with_two_taps (H : ℝ[X]) (ℓ : ℕ)
    (hPR : ∀ x : ℤ → ℝ,
      bank H (H.comp (-X)) ((H.comp (-X)).comp (-X)) (-H.comp (-X)) x = fun n => x (n - ℓ)) :
    ∃ a b : ℕ, ∃ c d : ℝ, Even a ∧ Odd b ∧ c ≠ 0 ∧ d ≠ 0 ∧
      H = C c * X ^ a + C d * X ^ b ∧ 2 * c * d = 1 ∧ a + b = ℓ := by
  have hT := ((perfect_reconstruction_iff_no_alias_and_pure_delay _ _ _ _ ℓ).mp hPR).2
  rw [comp_neg_X_comp_neg_X] at hT
  unfold throughTerm at hT
  obtain ⟨E, hE⟩ : ∃ E, E = C (1 / 2 : ℝ) * (H + H.comp (-X)) := ⟨_, rfl⟩
  obtain ⟨O, hO⟩ : ∃ O, O = C (1 / 2 : ℝ) * (H - H.comp (-X)) := ⟨_, rfl⟩
  have hEO : E * O = C (1 / 2) * X ^ ℓ := by
    rw [hE, hO]
    linear_combination C (1 / 2 : ℝ) * hT
  obtain ⟨hE0, hO0, hEm, hOm⟩ := fb_factor_monomial E O (1 / 2) (by norm_num) ℓ hEO
  have hEc : ∀ k, E.coeff k = (1 / 2) * ((1 + (-1) ^ k) * H.coeff k) := by
    intro k
    rw [hE, coeff_C_mul, coeff_add, fb_coeff_comp_negX]
    ring
  have hOc : ∀ k, O.coeff k = (1 / 2) * ((1 - (-1) ^ k) * H.coeff k) := by
    intro k
    rw [hO, coeff_C_mul, coeff_sub, fb_coeff_comp_negX]
    ring
  have hc : E.coeff E.natDegree ≠ 0 := by
    rw [coeff_natDegree]; exact leadingCoeff_ne_zero.mpr hE0
  have hd : O.coeff O.natDegree ≠ 0 := by
    rw [coeff_natDegree]; exact leadingCoeff_ne_zero.mpr hO0
  have hprod : C (E.coeff E.natDegree) * X ^ E.natDegree *
      (C (O.coeff O.natDegree) * X ^ O.natDegree) = C (1 / 2) * X ^ ℓ := by
    rw [← hEm, ← hOm]; exact hEO
  have hprod' : C (E.coeff E.natDegree * O.coeff O.natDegree) * X ^ (E.natDegree + O.natDegree) =
      C (1 / 2) * X ^ ℓ := by
    rw [← hprod, C_mul, pow_add]; ring
  have hab : E.natDegree + O.natDegree = ℓ := by
    have := congrArg natDegree hprod'
    rwa [natDegree_C_mul_X_pow _ _ (mul_ne_zero hc hd),
      natDegree_C_mul_X_pow _ _ (by norm_num)] at this
  refine ⟨E.natDegree, O.natDegree, E.coeff E.natDegree, O.coeff O.natDegree, ?_, ?_, hc, hd,
    ?_, ?_, hab⟩
  · rcases Nat.even_or_odd E.natDegree with h | h
    · exact h
    · exfalso; apply hc; rw [hEc, h.neg_one_pow]; ring
  · rcases Nat.even_or_odd O.natDegree with h | h
    · exfalso; apply hd; rw [hOc, h.neg_one_pow]; ring
    · exact h
  · have h2 : C (1 / 2 : ℝ) * 2 = 1 := by rw [← C_ofNat, ← C_mul]; norm_num
    rw [← hEm, ← hOm, hE, hO]
    linear_combination (-H) * h2
  · rw [hab] at hprod'
    have := congrArg (coeff · ℓ) hprod'
    simp only [coeff_C_mul_X_pow, if_pos] at this
    linarith

/-! The card's whole-number checks. -/

-- Haar, every filter times √2: H = 1 + w, G = 1 - w, F0 = 1 + w, F1 = -1 + w (w = z⁻¹).
-- The cross-mirror rule holds: F0 = G(-w) and F1 = -H(-w).
example : (1 - X : ℤ[X]).comp (-X) = 1 + X ∧ -(1 + X : ℤ[X]).comp (-X) = -1 + X := by
  constructor <;> simp [sub_comp]; ring
-- 2(F0 H + F1 G) has taps 0, 4, 0 (that is 4T = 4w: T = z^(-1)).
example : (1 + X) * (1 + X) + (-1 + X) * (1 - X) = (4 * X : ℤ[X]) := by ring
-- 2(F0 H(-w) + F1 G(-w)) has taps 0, 0, 0 (4A = 0).
example : (1 + X) * (1 + X : ℤ[X]).comp (-X) + (-1 + X) * (1 - X : ℤ[X]).comp (-X) = 0 := by
  simp [sub_comp]; ring
-- The Haar product filter P = (1, 2, 1)/2.
example : (1 + X) * (1 + X : ℤ[X]) = 1 + 2 * X + X ^ 2 := by ring

-- The 5/3 pair as whole-number numerators: H = (-1, 2, 6, 2, -1)/8, G = (1, -2, 1)/2,
-- F0 = (1, 2, 1)/2, F1 = (1, 2, -6, 2, 1)/8. The cross-mirror rule holds: G = F0(-w), F1 = -H(-w).
example : (1 + 2 * X + X ^ 2 : ℤ[X]).comp (-X) = 1 - 2 * X + X ^ 2 ∧
    -(-1 + 2 * X + 6 * X ^ 2 + 2 * X ^ 3 - X ^ 4 : ℤ[X]).comp (-X) =
      1 + 2 * X - 6 * X ^ 2 + 2 * X ^ 3 + X ^ 4 := by
  constructor <;> simp [sub_comp] <;> ring
-- 16P = 16 H F0 has taps -1, 0, 9, 16, 9, 0, -1.
example : (-1 + 2 * X + 6 * X ^ 2 + 2 * X ^ 3 - X ^ 4 : ℤ[X]) * (1 + 2 * X + X ^ 2) =
    -1 + 0 * X + 9 * X ^ 2 + 16 * X ^ 3 + 9 * X ^ 4 + 0 * X ^ 5 - X ^ 6 := by ring
-- 16(F0 H + F1 G) has taps 0, 0, 0, 32, 0, 0, 0 (32T = 32w³: T = z^(-3)).
example : (1 + 2 * X + X ^ 2 : ℤ[X]) * (-1 + 2 * X + 6 * X ^ 2 + 2 * X ^ 3 - X ^ 4) +
    (1 + 2 * X - 6 * X ^ 2 + 2 * X ^ 3 + X ^ 4) * (1 - 2 * X + X ^ 2) = 32 * X ^ 3 := by ring
-- 16(F0 H(-w) + F1 G(-w)) is 0: no alias.
example : (1 + 2 * X + X ^ 2 : ℤ[X]) * (-1 + 2 * X + 6 * X ^ 2 + 2 * X ^ 3 - X ^ 4 : ℤ[X]).comp (-X) +
    (1 + 2 * X - 6 * X ^ 2 + 2 * X ^ 3 + X ^ 4) * (1 - 2 * X + X ^ 2 : ℤ[X]).comp (-X) = 0 := by
  simp [sub_comp]; ring
-- The 5/3 bank itself, with its fractional taps: A = 0 and T = z^(-3).
example : aliasTerm (C (1 / 8) * (-1 + 2 * X + 6 * X ^ 2 + 2 * X ^ 3 - X ^ 4))
      (C (1 / 2) * (1 - 2 * X + X ^ 2)) (C (1 / 2) * (1 + 2 * X + X ^ 2))
      (C (1 / 8) * (1 + 2 * X - 6 * X ^ 2 + 2 * X ^ 3 + X ^ 4)) = 0 ∧
    throughTerm (C (1 / 8) * (-1 + 2 * X + 6 * X ^ 2 + 2 * X ^ 3 - X ^ 4))
      (C (1 / 2) * (1 - 2 * X + X ^ 2)) (C (1 / 2) * (1 + 2 * X + X ^ 2))
      (C (1 / 8) * (1 + 2 * X - 6 * X ^ 2 + 2 * X ^ 3 + X ^ 4)) = X ^ 3 := by
  constructor
  · simp only [aliasTerm, mul_comp, C_comp, sub_comp, add_comp, neg_comp, one_comp, X_comp, pow_comp,
      ofNat_comp]
    ring
  · have hc : C (1 / 2 : ℝ) * C (1 / 2) * C (1 / 8) * 32 = 1 := by
      rw [← C_mul, ← C_mul, ← C_ofNat, ← C_mul]; norm_num
    simp only [throughTerm]
    linear_combination X ^ 3 * hc

#print axioms perfect_reconstruction_iff_no_alias_and_pure_delay
#print axioms cross_mirror_rule_kills_alias_and_needs_half_band
#print axioms mirror_pair_exact_only_with_two_taps
#print axioms fb_coeff_comp_negX
#print axioms fb_filt_add
#print axioms fb_filt_monomial
#print axioms fb_filt_add_sig
#print axioms fb_filt_mul
#print axioms fb_filt_C
#print axioms fb_filt_zero
#print axioms fb_filt_X_pow
#print axioms fb_sg_sub
#print axioms fb_monomial_comp_negX
#print axioms fb_twist
#print axioms fb_bank_eq
#print axioms fb_impulse
#print axioms fb_sg_impulse
#print axioms fb_mono_of_tr
#print axioms fb_factor_monomial
