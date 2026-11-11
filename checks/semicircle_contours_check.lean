-- The semicircle contour: for a ratio of polynomials p/q whose bottom degree beats the top by at least 2 and whose bottom has no real zero, the integral over the whole real line converges and equals 2πi times the sum of the residues (the 1/(z - a) Laurent coefficients) at the zeros of q above the real axis, segment plus arc already equals that sum at every radius beyond the poles, and so the area under 1/(1 + x^2) is π and under 1/(1 + x^2)^2 is π/2.
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Complex.CauchyIntegral
import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Topology.Algebra.Polynomial
import Mathlib.FieldTheory.IsAlgClosed.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic

/-! The plane is `ℂ`; `I` is i and `Complex.exp` is e^z. `p.eval z / q.eval z` is the ratio
`f(z) = p(z)/q(z)` of two polynomials with complex coefficients. `q.roots.toFinset` is the set of
zeros of `q`, the places `a` where `f` may blow up; `0 < a.im` says `a` lies above the real axis.
`∫ x : ℝ, g x` is the integral over the whole real line, and `Integrable g` says it converges
absolutely, so both tails are finite on their own. `HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z)`
says the two-sided Laurent series `∑ c n (z - a)ⁿ`, over every whole number `n`, adds up to
`f(z)`; the residue `Res(f, a)` is its coefficient of `1/(z - a)`, that is `c (-1)`. The upper arc
`C_R` is `z = R e^(it)` for `t` from `0` to `π`, with `dz = i R e^(it) dt`. -/

open Complex Polynomial MeasureTheory

namespace SemicircleContours

/-! ### Helper lemmas for the proofs below -/

section Helpers

open Filter Topology Metric

lemma pf_extend (T : Finset ℂ) (g : ℂ → ℂ) (P : ℂ[X]) (N M : ℕ) (hNM : N ≤ M) (d : ℂ → ℕ → ℂ)
    (h : ∀ z ∉ T, g z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹) :
    ∀ z ∉ T, g z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range M,
      (if k < N then d b k else 0) * ((z - b) ^ (k + 1))⁻¹ := by
  intro z hz
  rw [h z hz]
  congr 1
  refine Finset.sum_congr rfl fun b _ => ?_
  rw [← Finset.sum_range_add_sum_Ico _ hNM]
  have h2 : ∑ k ∈ Finset.Ico N M, (if k < N then d b k else 0) * ((z - b) ^ (k + 1))⁻¹ = 0 :=
    Finset.sum_eq_zero fun k hk => by
      rw [Finset.mem_Ico] at hk
      simp [show ¬ k < N by omega]
  rw [h2, add_zero]
  refine Finset.sum_congr rfl fun k hk => ?_
  rw [Finset.mem_range] at hk
  simp [hk]

lemma pf_add (T : Finset ℂ) (g₁ g₂ : ℂ → ℂ)
    (h₁ : ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g₁ z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹)
    (h₂ : ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g₂ z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g₁ z + g₂ z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
  obtain ⟨P₁, N₁, d₁, e₁⟩ := h₁
  obtain ⟨P₂, N₂, d₂, e₂⟩ := h₂
  have f₁ := pf_extend T g₁ P₁ N₁ (max N₁ N₂) (le_max_left _ _) d₁ e₁
  have f₂ := pf_extend T g₂ P₂ N₂ (max N₁ N₂) (le_max_right _ _) d₂ e₂
  refine ⟨P₁ + P₂, max N₁ N₂, fun b k => (if k < N₁ then d₁ b k else 0) +
    (if k < N₂ then d₂ b k else 0), fun z hz => ?_⟩
  rw [f₁ z hz, f₂ z hz, eval_add]
  simp only [add_mul, Finset.sum_add_distrib]
  ring

lemma pf_smul (T : Finset ℂ) (g : ℂ → ℂ) (c : ℂ)
    (h : ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      c * g z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
  obtain ⟨P, N, d, e⟩ := h
  refine ⟨C c * P, N, fun b k => c * d b k, fun z hz => ?_⟩
  rw [e z hz, eval_mul, eval_C, mul_add, Finset.mul_sum]
  simp only [Finset.mul_sum, mul_assoc]

lemma pf_congr (T : Finset ℂ) (g₁ g₂ : ℂ → ℂ) (hg : ∀ z ∉ T, g₁ z = g₂ z)
    (h : ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g₁ z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g₂ z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
  obtain ⟨P, N, d, e⟩ := h
  exact ⟨P, N, d, fun z hz => (hg z hz) ▸ e z hz⟩

lemma pf_sum (T : Finset ℂ) {ι : Type*} (s : Finset ι) (g : ι → ℂ → ℂ)
    (h : ∀ i ∈ s, ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g i z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      ∑ i ∈ s, g i z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
  classical
  induction s using Finset.induction_on with
  | empty => exact ⟨0, 0, fun _ _ => 0, fun z _ => by simp⟩
  | insert i s hi ih =>
    have := pf_add T (g i) (fun z => ∑ j ∈ s, g j z) (h i (Finset.mem_insert_self _ _))
      (ih fun j hj => h j (Finset.mem_insert_of_mem hj))
    obtain ⟨P, N, d, e⟩ := this
    exact ⟨P, N, d, fun z hz => by rw [Finset.sum_insert hi]; exact e z hz⟩

lemma pf_poly (T : Finset ℂ) (Q : ℂ[X]) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      Q.eval z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ :=
  ⟨Q, 0, fun _ _ => 0, fun z _ => by simp⟩

lemma pf_pole (T : Finset ℂ) (c : ℂ) (hc : c ∈ T) (n : ℕ) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      ((z - c) ^ (n + 1))⁻¹ = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
  classical
  refine ⟨0, n + 1, fun b k => if b = c ∧ k = n then 1 else 0, fun z _ => ?_⟩
  simp only [eval_zero, zero_add, ite_mul, one_mul, zero_mul]
  rw [Finset.sum_eq_single c]
  · simp
  · intro b _ hb; simp [hb]
  · intro h; exact absurd hc h

lemma pf_simple_div (T : Finset ℂ) (b c : ℂ) (hb : b ∈ T) (hc : c ∈ T) (hbc : b ≠ c) (n : ℕ) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      ((z - b) ^ (n + 1))⁻¹ / (z - c) =
        P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
  have hcb : c - b ≠ 0 := sub_ne_zero.2 (Ne.symm hbc)
  induction n with
  | zero =>
    have := pf_smul T _ (c - b)⁻¹ (pf_add T _ _ (pf_pole T c hc 0)
      (pf_smul T _ (-1) (pf_pole T b hb 0)))
    refine pf_congr T _ _ (fun z hz => ?_) this
    have h1 : z - b ≠ 0 := sub_ne_zero.2 fun h => hz (h ▸ hb)
    have h2 : z - c ≠ 0 := sub_ne_zero.2 fun h => hz (h ▸ hc)
    field_simp
    ring
  | succ n ih =>
    have := pf_smul T _ (c - b)⁻¹ (pf_add T _ _ ih
      (pf_smul T _ (-1) (pf_pole T b hb (n + 1))))
    refine pf_congr T _ _ (fun z hz => ?_) this
    have h1 : z - b ≠ 0 := sub_ne_zero.2 fun h => hz (h ▸ hb)
    have h2 : z - c ≠ 0 := sub_ne_zero.2 fun h => hz (h ▸ hc)
    field_simp
    ring

lemma pf_div (T : Finset ℂ) (g : ℂ → ℂ) (c : ℂ) (hc : c ∈ T)
    (h : ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g z / (z - c) = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
  classical
  obtain ⟨P, N, d, e⟩ := h
  have hP : ∃ (P' : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      P.eval z / (z - c) =
        P'.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
    have := pf_add T _ _ (pf_poly T (P /ₘ (X - C c))) (pf_smul T _ (P.eval c) (pf_pole T c hc 0))
    refine pf_congr T _ _ (fun z hz => ?_) this
    have h2 : z - c ≠ 0 := sub_ne_zero.2 fun h => hz (h ▸ hc)
    have key := modByMonic_add_div P (X - C c)
    rw [modByMonic_X_sub_C_eq_C_eval] at key
    conv_rhs => rw [← key]
    simp only [eval_add, eval_C, eval_mul, eval_sub, eval_X]
    field_simp
    ring
  have hT : ∀ b ∈ T, ∀ k ∈ Finset.range N, ∃ (P' : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      ((z - b) ^ (k + 1))⁻¹ / (z - c) =
        P'.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
    intro b hb k _
    by_cases hbc : b = c
    · subst hbc
      refine pf_congr T _ _ (fun z hz => ?_) (pf_pole T b hb (k + 1))
      have h2 : z - b ≠ 0 := sub_ne_zero.2 fun h => hz (h ▸ hb)
      field_simp
      ring
    · exact pf_simple_div T b c hb hc hbc k
  have hsum := pf_add T _ _ hP (pf_sum T T _ fun b hb =>
    pf_sum T (Finset.range N) _ fun k hk => pf_smul T _ (d b k) (hT b hb k hk))
  refine pf_congr T _ _ (fun z hz => ?_) hsum
  rw [e z hz, add_div, Finset.sum_div]
  congr 1
  refine Finset.sum_congr rfl fun b _ => ?_
  rw [Finset.sum_div]
  refine Finset.sum_congr rfl fun k _ => ?_
  ring

lemma pf_rational (p q : ℂ[X]) (hq : q ≠ 0) :
    ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ q.roots.toFinset,
      p.eval z / q.eval z =
        P.eval z + ∑ b ∈ q.roots.toFinset, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
  classical
  set T := q.roots.toFinset
  have key : ∀ s : Multiset ℂ, s ≤ q.roots → ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      p.eval z / (s.map fun b => z - b).prod =
        P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹ := by
    intro s
    induction s using Multiset.induction_on with
    | empty => intro _; exact pf_congr T _ _ (fun z _ => by simp) (pf_poly T p)
    | cons a s ih =>
      intro hs
      have ha : a ∈ T := Multiset.mem_toFinset.2 (Multiset.mem_of_le hs (Multiset.mem_cons_self _ _))
      have := pf_div T _ a ha (ih ((Multiset.le_cons_self s a).trans hs))
      refine pf_congr T _ _ (fun z hz => ?_) this
      rw [Multiset.map_cons, Multiset.prod_cons, div_div, mul_comm]
  have hfac := C_leadingCoeff_mul_prod_multiset_X_sub_C (IsAlgClosed.card_roots_eq_natDegree (p := q))
  have hl : q.leadingCoeff ≠ 0 := leadingCoeff_ne_zero.2 hq
  have := pf_smul T _ (q.leadingCoeff)⁻¹ (key q.roots le_rfl)
  refine pf_congr T _ _ (fun z hz => ?_) this
  conv_rhs => rw [← hfac]
  rw [eval_mul, eval_C, eval_multiset_prod, Multiset.map_map]
  simp only [Function.comp_def, eval_sub, eval_X, eval_C]
  rw [mul_comm q.leadingCoeff, ← div_div, div_eq_inv_mul (_ / _)]

lemma pf_to_prim (T : Finset ℂ) (g : ℂ → ℂ)
    (h : ∃ (P : ℂ[X]) (N : ℕ) (d : ℂ → ℕ → ℂ), ∀ z ∉ T,
      g z = P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b k * ((z - b) ^ (k + 1))⁻¹) :
    ∃ (H h : ℂ → ℂ) (e : ℂ → ℂ), (∀ z ∉ T, HasDerivAt H (h z) z ∧ ContinuousAt h z) ∧
      ∀ z ∉ T, g z = h z + ∑ b ∈ T, e b * (z - b)⁻¹ := by
  obtain ⟨P, N, d₀, e₀⟩ := h
  obtain ⟨d, e₁⟩ : ∃ d : ℂ → ℕ → ℂ, ∀ z ∉ T, g z = P.eval z + ∑ b ∈ T,
      ∑ k ∈ Finset.range (N + 1), d b k * ((z - b) ^ (k + 1))⁻¹ :=
    ⟨_, pf_extend T g P N (N + 1) (Nat.le_succ N) d₀ e₀⟩
  refine ⟨fun z => ∑ i ∈ Finset.range (P.natDegree + 1), P.coeff i * (z ^ (i + 1) / (i + 1)) +
      ∑ b ∈ T, ∑ k ∈ Finset.range N, d b (k + 1) * (-((k : ℂ) + 1))⁻¹ * ((z - b) ^ (k + 1))⁻¹,
    fun z => P.eval z + ∑ b ∈ T, ∑ k ∈ Finset.range N, d b (k + 1) * ((z - b) ^ (k + 2))⁻¹,
    fun b => d b 0, fun z hz => ⟨?_, ?_⟩, fun z hz => ?_⟩
  · have hb : ∀ b ∈ T, z - b ≠ 0 := fun b hb => sub_ne_zero.2 fun h => hz (h ▸ hb)
    beta_reduce
    rw [eval_eq_sum_range]
    refine HasDerivAt.add (HasDerivAt.fun_sum fun i _ => ?_) (HasDerivAt.fun_sum fun b hbT =>
      HasDerivAt.fun_sum fun k _ => ?_)
    · have := ((hasDerivAt_pow (i + 1) z).div_const ((i : ℂ) + 1)).const_mul (P.coeff i)
      convert this using 1
      have : (i : ℂ) + 1 ≠ 0 := by exact_mod_cast Nat.succ_ne_zero i
      field_simp
      push_cast
      ring
    · have h1 := (((hasDerivAt_id z).sub_const b).pow (k + 1)).inv
        (pow_ne_zero _ (by simpa using hb b hbT))
      have h2 := h1.const_mul (d b (k + 1) * (-((k : ℂ) + 1))⁻¹)
      convert h2 using 1
      · ext w; simp [Pi.inv_apply]
      · have : (k : ℂ) + 1 ≠ 0 := by exact_mod_cast Nat.succ_ne_zero k
        have h3 := hb b hbT
        simp only [id, Pi.pow_apply]
        field_simp
        push_cast
        ring
  · have hb : ∀ b ∈ T, z - b ≠ 0 := fun b hb => sub_ne_zero.2 fun h => hz (h ▸ hb)
    refine ContinuousAt.add P.continuous.continuousAt ?_
    refine tendsto_finsetSum _ fun b hbT => tendsto_finsetSum _ fun k _ => ?_
    refine ContinuousAt.mul continuousAt_const (ContinuousAt.inv₀ ?_ (pow_ne_zero _ (hb b hbT)))
    fun_prop
  · rw [e₁ z hz, add_assoc, ← Finset.sum_add_distrib]
    congr 1
    refine Finset.sum_congr rfl fun b _ => ?_
    rw [Finset.sum_range_succ']
    simp

lemma seg_ftc (F f : ℂ → ℂ) (R : ℝ)
    (h : ∀ x : ℝ, x ∈ Set.uIcc (-R) R → HasDerivAt F (f x) x ∧ ContinuousAt f x) :
    ∫ x in (-R)..R, f x = F R - F ↑(-R) := by
  refine intervalIntegral.integral_eq_sub_of_hasDerivAt (f := fun x : ℝ => F x)
    (fun x hx => (h x hx).1.comp_ofReal) (ContinuousOn.intervalIntegrable fun x hx => ?_)
  exact ((h x hx).2.comp continuous_ofReal.continuousAt).continuousWithinAt

lemma hasDerivAt_arc (R t : ℝ) :
    HasDerivAt (fun t : ℝ => (R : ℂ) * exp (t * I)) (I * R * exp (t * I)) t := by
  have := ((hasDerivAt_mul_const (x := (t : ℂ)) I).cexp.comp_ofReal (z := t)).const_mul (R : ℂ)
  convert this using 1
  ring

lemma arc_ftc (F f : ℂ → ℂ) (R t₀ t₁ : ℝ)
    (h : ∀ t ∈ Set.uIcc t₀ t₁, HasDerivAt F (f (R * exp (t * I))) (R * exp (t * I)) ∧
      ContinuousAt f (R * exp (t * I))) :
    ∫ t in t₀..t₁, f (R * exp (t * I)) * (I * R * exp (t * I)) =
      F (R * exp (t₁ * I)) - F (R * exp (t₀ * I)) := by
  refine intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun t : ℝ => F (R * exp (t * I)))
    (fun t ht => (h t ht).1.comp t (hasDerivAt_arc R t))
    (ContinuousOn.intervalIntegrable fun t ht => ?_)
  refine ContinuousAt.continuousWithinAt (ContinuousAt.mul ?_ (by fun_prop))
  exact ContinuousAt.comp (f := fun t : ℝ => (R : ℂ) * exp (t * I)) (h t ht).2
    (hasDerivAt_arc R t).continuousAt

lemma norm_arc (R t : ℝ) : ‖(R : ℂ) * exp (t * I)‖ = |R| := by
  rw [norm_mul, norm_exp_ofReal_mul_I, Complex.norm_real, Real.norm_eq_abs, mul_one]

lemma im_arc (R t : ℝ) : ((R : ℂ) * exp (t * I)).im = R * Real.sin t := by
  simp [mul_im, exp_ofReal_mul_I_re, exp_ofReal_mul_I_im]

lemma inv_contour (b : ℂ) (R : ℝ) (hb : ‖b‖ < R) (hbi : b.im ≠ 0) :
    (∫ x in (-R)..R, ((x : ℂ) - b)⁻¹) +
        (∫ t in (0 : ℝ)..Real.pi, ((R : ℂ) * exp (t * I) - b)⁻¹ * (I * R * exp (t * I))) =
      if 0 < b.im then 2 * Real.pi * I else 0 := by
  have hR : 0 < R := lt_of_le_of_lt (norm_nonneg _) hb
  have hne : ∀ t : ℝ, (R : ℂ) * exp (t * I) - b ≠ 0 := by
    intro t h
    have := norm_arc R t
    rw [sub_eq_zero.1 h, abs_of_pos hR] at this
    linarith
  have hcont : ∀ z : ℂ, z ≠ b → ContinuousAt (fun z : ℂ => (z - b)⁻¹) z := fun z hz =>
    (continuousAt_id.sub continuousAt_const).inv₀ (sub_ne_zero.2 hz)
  have hderiv : ∀ z : ℂ, z - b ∈ slitPlane →
      HasDerivAt (fun z : ℂ => log (z - b)) ((z - b)⁻¹) z := fun z hz => by
    simpa using ((hasDerivAt_id z).sub_const b).clog hz
  have hreal : ∀ x : ℝ, (x : ℂ) ≠ b := fun x h => hbi (by rw [← h]; simp)
  have hseg : ∀ x : ℝ, x ∈ Set.uIcc (-R) R → (x : ℂ) - b ∈ slitPlane →
      HasDerivAt (fun z : ℂ => log (z - b)) (((x : ℂ) - b)⁻¹) x ∧
        ContinuousAt (fun z : ℂ => (z - b)⁻¹) x := fun x _ hx => ⟨hderiv _ hx, hcont _ (hreal x)⟩
  have hS : (∀ x : ℝ, (x : ℂ) - b ∈ slitPlane) →
      ∫ x in (-R)..R, ((x : ℂ) - b)⁻¹ = log ((R : ℂ) - b) - log (((-R : ℝ) : ℂ) - b) :=
    fun hsl => seg_ftc (fun z : ℂ => log (z - b)) (fun z => (z - b)⁻¹) R
    (fun x hx => hseg x hx (hsl x))
  have harc : ∀ t₀ t₁ : ℝ, (∀ t ∈ Set.uIcc t₀ t₁, (R : ℂ) * exp (t * I) - b ∈ slitPlane) →
      ∫ t in t₀..t₁, ((R : ℂ) * exp (t * I) - b)⁻¹ * (I * R * exp (t * I)) =
        log (R * exp (t₁ * I) - b) - log (R * exp (t₀ * I) - b) := fun t₀ t₁ hsl =>
    arc_ftc (fun z : ℂ => log (z - b)) (fun z => (z - b)⁻¹) R t₀ t₁
      (fun t ht => ⟨hderiv _ (hsl t ht), hcont _ (sub_ne_zero.1 (hne t))⟩)
  have e0 : (R : ℂ) * exp (((0 : ℝ) : ℂ) * I) = R := by simp
  have epi : (R : ℂ) * exp ((Real.pi : ℂ) * I) = ((-R : ℝ) : ℂ) := by
    rw [exp_pi_mul_I]; push_cast; ring
  have e2pi : (R : ℂ) * exp (((2 * Real.pi : ℝ) : ℂ) * I) = R := by
    push_cast; rw [exp_two_pi_mul_I, mul_one]
  rcases lt_or_gt_of_ne hbi with hneg | hpos
  · -- the pole lies below: the whole contour stays in the upper half plane
    simp only [not_lt.2 hneg.le, ite_false]
    have h1 := hS fun x => by
      rw [mem_slitPlane_iff]; right; simp; linarith
    have h2 := harc 0 Real.pi fun t ht => by
      rw [Set.uIcc_of_le Real.pi_pos.le] at ht
      rw [mem_slitPlane_iff]; right
      rw [sub_im, im_arc]
      have := Real.sin_nonneg_of_nonneg_of_le_pi ht.1 ht.2
      nlinarith
    rw [h1, h2, e0, epi]
    ring
  · -- the pole lies above: compare with the full circle and the lower half
    simp only [hpos, ite_true]
    have h1 := hS fun x => by
      rw [mem_slitPlane_iff]; right; simp; linarith
    have h2 := harc Real.pi (2 * Real.pi) fun t ht => by
      rw [Set.uIcc_of_le (by linarith [Real.pi_pos])] at ht
      rw [mem_slitPlane_iff]; right
      rw [sub_im, im_arc]
      have := Real.sin_nonpos_of_nonpos_of_neg_pi_le (x := t - 2 * Real.pi) (by linarith [ht.2])
        (by linarith [ht.1])
      rw [Real.sin_sub_two_pi] at this
      nlinarith
    have hint : ∀ t₀ t₁ : ℝ, IntervalIntegrable
        (fun t : ℝ => ((R : ℂ) * exp (t * I) - b)⁻¹ * (I * R * exp (t * I))) MeasureTheory.volume
        t₀ t₁ := fun t₀ t₁ => by
      refine Continuous.intervalIntegrable ?_ _ _
      refine Continuous.mul ?_ (by fun_prop)
      exact continuous_iff_continuousAt.2 fun t =>
        ContinuousAt.comp (f := fun t : ℝ => (R : ℂ) * exp (t * I))
          (hcont _ (sub_ne_zero.1 (hne t))) (hasDerivAt_arc R t).continuousAt
    have hcirc : ∫ t in (0 : ℝ)..(2 * Real.pi),
        ((R : ℂ) * exp (t * I) - b)⁻¹ * (I * R * exp (t * I)) = 2 * Real.pi * I := by
      have := circleIntegral.integral_sub_inv_of_mem_ball (c := 0) (R := R) (w := b)
        (by simpa using hb)
      rw [circleIntegral] at this
      rw [← this]
      refine intervalIntegral.integral_congr fun t _ => ?_
      simp only [deriv_circleMap, circleMap_zero, smul_eq_mul]
      ring
    rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 Real.pi)
      (hint Real.pi (2 * Real.pi)), h2, e2pi, epi] at hcirc
    rw [h1, ← hcirc]
    ring

lemma integral_add_sum (a₀ a₁ : ℝ) (T : Finset ℂ) (e : ℂ → ℂ) (u : ℝ → ℂ) (v : ℂ → ℝ → ℂ)
    (hu : Continuous u) (hv : ∀ b ∈ T, Continuous (v b)) :
    ∫ t in a₀..a₁, (u t + ∑ b ∈ T, e b * v b t) =
      (∫ t in a₀..a₁, u t) + ∑ b ∈ T, e b * ∫ t in a₀..a₁, v b t := by
  rw [intervalIntegral.integral_add (f := u) (g := fun t => ∑ b ∈ T, e b * v b t)
    (hu.intervalIntegrable _ _)
    ((continuous_finsetSum _ fun b hb => continuous_const.mul (hv b hb)).intervalIntegrable _ _),
    intervalIntegral.integral_finsetSum (f := fun b t => e b * v b t) fun b hb =>
      (continuous_const.mul (hv b hb)).intervalIntegrable _ _]
  congr 1
  exact Finset.sum_congr rfl fun b _ => intervalIntegral.integral_const_mul _ _

lemma contAt_inv_sub (b z : ℂ) (h : z ≠ b) : ContinuousAt (fun w : ℂ => (w - b)⁻¹) z :=
  (continuousAt_id.sub continuousAt_const).inv₀ (sub_ne_zero.2 h)

lemma arc_zero (R : ℝ) : (R : ℂ) * exp (((0 : ℝ) : ℂ) * I) = R := by simp

lemma arc_pi (R : ℝ) : (R : ℂ) * exp ((Real.pi : ℂ) * I) = ((-R : ℝ) : ℂ) := by
  rw [exp_pi_mul_I]; push_cast; ring

lemma contour_eq (T : Finset ℂ) (g H h e : ℂ → ℂ)
    (hH : ∀ z ∉ T, HasDerivAt H (h z) z ∧ ContinuousAt h z)
    (hg : ∀ z ∉ T, g z = h z + ∑ b ∈ T, e b * (z - b)⁻¹) (R : ℝ)
    (hreal : ∀ x : ℝ, (x : ℂ) ∉ T) (hR : ∀ b ∈ T, ‖b‖ < R) :
    (∫ x in (-R)..R, g x) + (∫ t in (0 : ℝ)..Real.pi, g (R * exp (t * I)) * (I * R * exp (t * I))) =
      ∑ b ∈ T, e b * (if 0 < b.im then 2 * Real.pi * I else 0) := by
  have harcT : ∀ t : ℝ, (R : ℂ) * exp (t * I) ∉ T := fun t ht => by
    have := hR _ ht
    rw [norm_arc] at this
    linarith [le_abs_self R]
  have hbi : ∀ b ∈ T, b.im ≠ 0 := fun b hb him => hreal b.re (by
    convert hb using 1; exact Complex.ext rfl (by simp [him]))
  have hS : ∫ x in (-R)..R, g x = ∫ x in (-R)..R, (h x + ∑ b ∈ T, e b * ((x : ℂ) - b)⁻¹) :=
    intervalIntegral.integral_congr fun x _ => hg x (hreal x)
  have hU : ∫ t in (0 : ℝ)..Real.pi, g (R * exp (t * I)) * (I * R * exp (t * I)) =
      ∫ t in (0 : ℝ)..Real.pi, (h (R * exp (t * I)) * (I * R * exp (t * I)) +
        ∑ b ∈ T, e b * (((R : ℂ) * exp (t * I) - b)⁻¹ * (I * R * exp (t * I)))) := by
    refine intervalIntegral.integral_congr fun t _ => ?_
    rw [hg _ (harcT t), add_mul, Finset.sum_mul]
    simp only [mul_assoc]
  have hγ : Continuous fun t : ℝ => (R : ℂ) * exp (t * I) := by fun_prop
  have e1 := integral_add_sum (-R) R T e (fun x : ℝ => h x) (fun b x => ((x : ℂ) - b)⁻¹)
    (continuous_iff_continuousAt.2 fun x => (hH x (hreal x)).2.comp continuous_ofReal.continuousAt)
    (fun b hb => continuous_iff_continuousAt.2 fun x =>
      (contAt_inv_sub b x fun h => hreal x (h ▸ hb)).comp continuous_ofReal.continuousAt)
  have e2 := integral_add_sum 0 Real.pi T e
    (fun t : ℝ => h (R * exp (t * I)) * (I * R * exp (t * I)))
    (fun b t => ((R : ℂ) * exp (t * I) - b)⁻¹ * (I * R * exp (t * I)))
    ((continuous_iff_continuousAt.2 fun t => ContinuousAt.comp
      (f := fun t : ℝ => (R : ℂ) * exp (t * I)) (hH _ (harcT t)).2 hγ.continuousAt).mul
        (by fun_prop))
    (fun b hb => (continuous_iff_continuousAt.2 fun t => ContinuousAt.comp
      (f := fun t : ℝ => (R : ℂ) * exp (t * I))
      (contAt_inv_sub b ((R : ℂ) * exp (t * I)) fun h => harcT t (h ▸ hb))
        hγ.continuousAt).mul (by fun_prop))
  beta_reduce at e1 e2
  rw [hS, hU, e1, e2]
  rw [seg_ftc H h R (fun x _ => hH x (hreal x)),
    arc_ftc H h R 0 Real.pi (fun t _ => hH _ (harcT t)), arc_zero, arc_pi]
  rw [add_add_add_comm, sub_add_sub_cancel', sub_self, zero_add, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun b hb => ?_
  rw [← mul_add, inv_contour b R (hR b hb) (hbi b hb)]

lemma circle_eq (T : Finset ℂ) (g H h e : ℂ → ℂ)
    (hH : ∀ z ∉ T, HasDerivAt H (h z) z ∧ ContinuousAt h z)
    (hg : ∀ z ∉ T, g z = h z + ∑ b ∈ T, e b * (z - b)⁻¹) (a : ℂ) (ha : a ∈ T) (ρ : ℝ)
    (hρ : 0 < ρ) (hsep : ∀ b ∈ T, b ≠ a → ρ < ‖b - a‖) :
    (∮ z in C(a, ρ), g z) = 2 * Real.pi * I * e a := by
  classical
  have hsph : ∀ z ∈ sphere a ρ, z ∉ T := fun z hz hzT => by
    rw [mem_sphere_iff_norm] at hz
    by_cases hza : z = a
    · rw [hza, sub_self, norm_zero] at hz; linarith
    · linarith [hsep z hzT hza]
  have hcm : ∀ θ : ℝ, circleMap a ρ θ ∉ T := fun θ =>
    hsph _ (circleMap_mem_sphere a hρ.le θ)
  have h0 := circleIntegral.integral_eq_zero_of_hasDerivWithinAt hρ.le
    (f := H) (f' := h) (fun z hz => (hH z (hsph z hz)).1.hasDerivWithinAt)
  have hb : ∀ b ∈ T, (∮ z in C(a, ρ), (z - b)⁻¹) = if b = a then 2 * Real.pi * I else 0 := by
    intro b hbT
    split_ifs with hba
    · subst hba; exact circleIntegral.integral_sub_inv_of_mem_ball (mem_ball_self hρ)
    · have hfar : ∀ z ∈ closedBall a ρ, z - b ≠ 0 := fun z hz h => by
        rw [sub_eq_zero] at h
        rw [h, mem_closedBall_iff_norm] at hz
        linarith [hsep b hbT hba]
      exact circleIntegral_eq_zero_of_differentiable_on_off_countable hρ.le Set.countable_empty
        (fun z hz => ((continuousAt_id.sub continuousAt_const).inv₀ (hfar z hz)).continuousWithinAt)
        (fun z hz => ((differentiableAt_id.sub (differentiableAt_const _)).inv
          (hfar z (ball_subset_closedBall hz.1))))
  rw [circleIntegral.integral_congr hρ.le (g := fun z => h z + ∑ b ∈ T, e b * (z - b)⁻¹)
    (fun z hz => hg z (hsph z hz))]
  simp only [circleIntegral, deriv_circleMap, smul_eq_mul] at h0 hb ⊢
  have hcmc := continuous_circleMap a ρ
  have hrw : ∀ θ : ℝ, circleMap 0 ρ θ * I * (h (circleMap a ρ θ) +
      ∑ b ∈ T, e b * (circleMap a ρ θ - b)⁻¹) = circleMap 0 ρ θ * I * h (circleMap a ρ θ) +
      ∑ b ∈ T, e b * (circleMap 0 ρ θ * I * (circleMap a ρ θ - b)⁻¹) := fun θ => by
    rw [mul_add, Finset.mul_sum]
    congr 1
    exact Finset.sum_congr rfl fun b _ => by ring
  simp_rw [hrw]
  have e1 := integral_add_sum 0 (2 * Real.pi) T e
    (fun θ => circleMap 0 ρ θ * I * h (circleMap a ρ θ))
    (fun b θ => circleMap 0 ρ θ * I * (circleMap a ρ θ - b)⁻¹)
    ((continuous_circleMap 0 ρ).mul continuous_const |>.mul
      (continuous_iff_continuousAt.2 fun θ => (hH _ (hcm θ)).2.comp hcmc.continuousAt))
    (fun b hbT => (continuous_circleMap 0 ρ).mul continuous_const |>.mul
      (continuous_iff_continuousAt.2 fun θ =>
        (contAt_inv_sub b (circleMap a ρ θ) fun h => hcm θ (h ▸ hbT)).comp hcmc.continuousAt))
  beta_reduce at e1
  rw [e1]
  rw [h0, zero_add, Finset.sum_congr rfl fun b hbT => by rw [hb b hbT]]
  simp only [mul_ite, mul_zero, Finset.sum_ite_eq', ha, ite_true]
  ring

lemma laurent_circle (f : ℂ → ℂ) (a : ℂ) (c : ℤ → ℂ) (r : ℝ)
    (hl : ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r → HasSum (fun n : ℤ ↦ c n * (z - a) ^ n) (f z))
    (ρ : ℝ) (hρ : 0 < ρ) (hρr : ρ < r) :
    (∮ z in C(a, ρ), f z) = 2 * Real.pi * I * c (-1) := by
  have hnorm : ∀ θ : ℝ, ‖circleMap a ρ θ - a‖ = ρ := fun θ => by
    rw [circleMap_sub_center, norm_circleMap_zero, abs_of_pos hρ]
  have hsum : Summable fun n : ℤ => ‖c n‖ * ρ ^ n := by
    have := (hl (a + ρ) (by simp [abs_of_pos hρ, hρ]) (by simp [abs_of_pos hρ, hρr])).summable
    rw [← summable_norm_iff] at this
    refine this.congr fun n => ?_
    simp [norm_zpow, abs_of_pos hρ]
  have hne : ∀ θ : ℝ, circleMap a ρ θ - a ≠ 0 := fun θ h => by
    have := hnorm θ; rw [h, norm_zero] at this; linarith
  have key := intervalIntegral.hasSum_integral_of_dominated_convergence (a := 0) (b := 2 * Real.pi)
    (μ := MeasureTheory.volume)
    (F := fun (n : ℤ) (θ : ℝ) => deriv (circleMap a ρ) θ • (c n * (circleMap a ρ θ - a) ^ n))
    (f := fun θ => deriv (circleMap a ρ) θ • f (circleMap a ρ θ))
    (fun n θ => ρ * (‖c n‖ * ρ ^ n))
    (fun n => by
      refine Continuous.aestronglyMeasurable ?_
      simp only [deriv_circleMap, smul_eq_mul]
      exact ((continuous_circleMap 0 ρ).mul continuous_const).mul (continuous_const.mul
        (((continuous_circleMap a ρ).sub continuous_const).zpow₀ n fun θ => Or.inl (hne θ))))
    (fun n => MeasureTheory.ae_of_all _ fun θ _ => by
      simp only [deriv_circleMap, smul_eq_mul, norm_mul, norm_zpow, hnorm, norm_circleMap_zero,
        norm_I, abs_of_pos hρ, mul_one]
      rfl)
    (MeasureTheory.ae_of_all _ fun θ _ => hsum.mul_left ρ)
    intervalIntegrable_const
    (MeasureTheory.ae_of_all _ fun θ _ => by
      have := hl (circleMap a ρ θ) (by rw [hnorm]; exact hρ) (by rw [hnorm]; exact hρr)
      exact this.const_smul _)
  have hterm : ∀ n : ℤ, ∫ θ in (0 : ℝ)..2 * Real.pi,
      deriv (circleMap a ρ) θ • (c n * (circleMap a ρ θ - a) ^ n) =
        if n = -1 then 2 * Real.pi * I * c (-1) else 0 := by
    intro n
    have : ∫ θ in (0 : ℝ)..2 * Real.pi,
        deriv (circleMap a ρ) θ • (c n * (circleMap a ρ θ - a) ^ n) =
          c n * ∮ z in C(a, ρ), (z - a) ^ n := by
      rw [circleIntegral, ← intervalIntegral.integral_const_mul]
      refine intervalIntegral.integral_congr fun θ _ => ?_
      simp only [smul_eq_mul]
      ring
    rw [this]
    split_ifs with hn
    · subst hn
      simp_rw [zpow_neg_one]
      rw [circleIntegral.integral_sub_inv_of_mem_ball (mem_ball_self hρ)]
      ring
    · rw [circleIntegral.integral_sub_zpow_of_ne hn, mul_zero]
  simp_rw [hterm] at key
  rw [circleIntegral]
  exact key.unique (hasSum_ite_eq (-1 : ℤ) _)

lemma exists_small_radius (T : Finset ℂ) (a : ℂ) (r : ℝ) (hr : 0 < r) :
    ∃ ρ : ℝ, 0 < ρ ∧ ρ < r ∧ ∀ b ∈ T, b ≠ a → ρ < ‖b - a‖ := by
  have h1 : ∀ᶠ ρ in 𝓝[>] (0 : ℝ), 0 < ρ := self_mem_nhdsWithin
  have h2 : ∀ᶠ ρ in 𝓝[>] (0 : ℝ), ρ < r := nhdsWithin_le_nhds (eventually_lt_nhds hr)
  have h3 : ∀ᶠ ρ in 𝓝[>] (0 : ℝ), ∀ b ∈ T, b ≠ a → ρ < ‖b - a‖ := by
    rw [Filter.eventually_all_finset]
    intro b _
    by_cases hba : b = a
    · exact Filter.Eventually.of_forall fun ρ h => absurd hba h
    · have : ∀ᶠ ρ in 𝓝[>] (0 : ℝ), ρ < ‖b - a‖ :=
        nhdsWithin_le_nhds (eventually_lt_nhds (norm_pos_iff.2 (sub_ne_zero.2 hba)))
      exact this.mono fun ρ h _ => h
  obtain ⟨ρ, hρ1, hρ2, hρ3⟩ := (h1.and (h2.and h3)).exists
  exact ⟨ρ, hρ1, hρ2, hρ3⟩

lemma segment_arc_aux (p q : ℂ[X]) (hreal : ∀ x : ℝ, q.eval (x : ℂ) ≠ 0)
    (R : ℝ) (hR : ∀ a ∈ q.roots.toFinset, ‖a‖ < R)
    (coeff : ℂ → ℤ → ℂ)
    (hlaurent : ∀ a ∈ q.roots.toFinset, 0 < a.im → ∃ r > 0, ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ coeff a n * (z - a) ^ n) (p.eval z / q.eval z)) :
    (∫ x in (-R)..R, p.eval (x : ℂ) / q.eval (x : ℂ)) +
        (∫ t in (0 : ℝ)..Real.pi,
          p.eval (R * exp (t * I)) / q.eval (R * exp (t * I)) * (I * R * exp (t * I))) =
      2 * Real.pi * I * ∑ a ∈ q.roots.toFinset.filter (fun a ↦ 0 < a.im), coeff a (-1) := by
  classical
  have hq : q ≠ 0 := by
    rintro rfl
    exact hreal 0 (by simp)
  obtain ⟨H, h, e, hH, hg⟩ := pf_to_prim q.roots.toFinset _ (pf_rational p q hq)
  have hrealT : ∀ x : ℝ, (x : ℂ) ∉ q.roots.toFinset := fun x hx =>
    hreal x ((mem_roots hq).1 (Multiset.mem_toFinset.1 hx))
  have hc := contour_eq q.roots.toFinset (fun z => p.eval z / q.eval z) H h e hH hg R hrealT hR
  beta_reduce at hc
  rw [hc, Finset.sum_filter, Finset.mul_sum]
  refine Finset.sum_congr rfl fun a ha => ?_
  split_ifs with him
  · obtain ⟨r, hr, hl⟩ := hlaurent a ha him
    obtain ⟨ρ, hρ, hρr, hsep⟩ := exists_small_radius q.roots.toFinset a r hr
    have h1 := circle_eq q.roots.toFinset (fun z => p.eval z / q.eval z) H h e hH hg a ha ρ hρ hsep
    have h2 := laurent_circle (fun z => p.eval z / q.eval z) a (coeff a) r hl ρ hρ hρr
    rw [h1] at h2
    rw [mul_left_cancel₀ two_pi_I_ne_zero h2]
    ring
  · simp

lemma norm_eval_le (p : ℂ[X]) (n : ℕ) (hn : p.natDegree ≤ n) (z : ℂ) (hz : 1 ≤ ‖z‖) :
    ‖p.eval z‖ ≤ (∑ i ∈ Finset.range (p.natDegree + 1), ‖p.coeff i‖) * ‖z‖ ^ n := by
  rw [eval_eq_sum_range, Finset.sum_mul]
  refine (norm_sum_le _ _).trans (Finset.sum_le_sum fun i hi => ?_)
  rw [norm_mul, norm_pow]
  refine mul_le_mul_of_nonneg_left (pow_le_pow_right₀ hz ?_) (norm_nonneg _)
  rw [Finset.mem_range] at hi
  omega

lemma rational_decay (p q : ℂ[X]) (hdeg : p.natDegree + 2 ≤ q.natDegree) :
    ∃ C R₀ : ℝ, 1 ≤ R₀ ∧ ∀ z : ℂ, R₀ ≤ ‖z‖ → ‖p.eval z / q.eval z‖ ≤ C / ‖z‖ ^ 2 := by
  set n := q.natDegree with hn
  have hq : q ≠ 0 := by
    rintro rfl
    simp [hn] at hdeg
  set c := q.leadingCoeff
  have hc : 0 < ‖c‖ := norm_pos_iff.2 (leadingCoeff_ne_zero.2 hq)
  set A := ∑ i ∈ Finset.range (p.natDegree + 1), ‖p.coeff i‖
  set B := ∑ i ∈ Finset.range (q.eraseLead.natDegree + 1), ‖q.eraseLead.coeff i‖
  have hB : 0 ≤ B := Finset.sum_nonneg fun _ _ => norm_nonneg _
  refine ⟨2 * A / ‖c‖, max 1 (2 * B / ‖c‖), le_max_left _ _, fun z hz => ?_⟩
  have hz1 : 1 ≤ ‖z‖ := (le_max_left _ _).trans hz
  have hzB : 2 * B / ‖c‖ ≤ ‖z‖ := (le_max_right _ _).trans hz
  have hzpos : 0 < ‖z‖ := by linarith
  have hlow : ‖c‖ / 2 * ‖z‖ ^ n ≤ ‖q.eval z‖ := by
    have hsplit := eraseLead_add_C_mul_X_pow q
    have hE := norm_eval_le q.eraseLead (n - 1) (eraseLead_natDegree_le q) z hz1
    have hq' : q.eval z = q.eraseLead.eval z + c * z ^ n := by
      have := congrArg (eval z) hsplit
      rw [eval_add, eval_mul, eval_C, eval_pow, eval_X] at this
      exact this.symm
    have hpow : ‖z‖ ^ n = ‖z‖ ^ (n - 1) * ‖z‖ := by
      rw [← pow_succ]; congr 1; omega
    have h1 : ‖c * z ^ n‖ ≤ ‖q.eval z‖ + ‖q.eraseLead.eval z‖ := by
      have : c * z ^ n = q.eval z - q.eraseLead.eval z := by rw [hq']; ring
      rw [this]
      exact norm_sub_le _ _
    rw [norm_mul, norm_pow] at h1
    have h2 : B * ‖z‖ ^ (n - 1) ≤ ‖c‖ / 2 * ‖z‖ ^ n := by
      rw [hpow, div_le_iff₀ hc] at *
      have : 0 ≤ ‖z‖ ^ (n - 1) := by positivity
      nlinarith
    linarith
  have hup := norm_eval_le p (n - 2) (by omega) z hz1
  have hqpos : 0 < ‖c‖ / 2 * ‖z‖ ^ n := by positivity
  rw [norm_div]
  calc ‖p.eval z‖ / ‖q.eval z‖ ≤ A * ‖z‖ ^ (n - 2) / (‖c‖ / 2 * ‖z‖ ^ n) :=
        div_le_div₀ (by positivity) hup hqpos hlow
    _ = 2 * A / ‖c‖ / ‖z‖ ^ 2 := by
        have : ‖z‖ ^ n = ‖z‖ ^ (n - 2) * ‖z‖ ^ 2 := by rw [← pow_add]; congr 1; omega
        rw [this]
        field_simp

lemma integrable_inv_one_add_sq_sq : Integrable (fun x : ℝ ↦ 1 / (1 + x ^ 2) ^ 2) := by
  refine integrable_inv_one_add_sq.mono'
    (continuous_const.div (by fun_prop) fun x => by positivity).aestronglyMeasurable
    (Filter.Eventually.of_forall fun x => ?_)
  have h1 : 1 ≤ 1 + x ^ 2 := by nlinarith
  rw [Real.norm_eq_abs, abs_of_nonneg (by positivity), one_div]
  exact inv_anti₀ (by positivity) (by nlinarith)

lemma integral_inv_one_add_sq_sq :
    ∫ x : ℝ, 1 / (1 + x ^ 2) ^ 2 = Real.pi / 2 := by
  have hint := integrable_inv_one_add_sq_sq
  have hderiv : ∀ x : ℝ, HasDerivAt (fun x : ℝ => x / (2 * (1 + x ^ 2)) + Real.arctan x / 2)
      (1 / (1 + x ^ 2) ^ 2) x := by
    intro x
    have hpos : (2 * (1 + x ^ 2)) ≠ 0 := by positivity
    have h1 := (hasDerivAt_id' x).div (((hasDerivAt_pow 2 x).const_add 1).const_mul 2) hpos
    have h2 := (Real.hasDerivAt_arctan x).div_const 2
    refine (h1.add h2).congr_deriv ?_
    have : (1 + x ^ 2) ≠ 0 := by positivity
    push_cast
    field_simp
    ring
  have hfrac : ∀ l : Filter ℝ, Tendsto (fun x : ℝ => x⁻¹) l (𝓝 0) → (∀ᶠ x in l, x ≠ 0) →
      Tendsto (fun x : ℝ => x / (2 * (1 + x ^ 2))) l (𝓝 0) := by
    intro l hl hne
    have : Tendsto (fun x : ℝ => x⁻¹ / (2 * (x⁻¹ ^ 2 + 1))) l (𝓝 (0 / (2 * (0 ^ 2 + 1)))) :=
      hl.div ((hl.pow 2 |>.add tendsto_const_nhds).const_mul 2) (by norm_num)
    rw [show (0 : ℝ) / (2 * (0 ^ 2 + 1)) = 0 by norm_num] at this
    refine this.congr' (hne.mono fun x hx => ?_)
    field_simp
  have htop := (hfrac atTop tendsto_inv_atTop_zero (eventually_ne_atTop 0)).add
    ((Real.tendsto_arctan_atTop.mono_right nhdsWithin_le_nhds).div_const 2)
  have hbot := (hfrac atBot tendsto_inv_atBot_zero (eventually_ne_atBot 0)).add
    ((Real.tendsto_arctan_atBot.mono_right nhdsWithin_le_nhds).div_const 2)
  rw [integral_of_hasDerivAt_of_tendsto hderiv hint hbot htop]
  ring

#print axioms pf_extend
#print axioms pf_add
#print axioms pf_smul
#print axioms pf_congr
#print axioms pf_sum
#print axioms pf_poly
#print axioms pf_pole
#print axioms pf_simple_div
#print axioms pf_div
#print axioms pf_rational
#print axioms pf_to_prim
#print axioms seg_ftc
#print axioms hasDerivAt_arc
#print axioms arc_ftc
#print axioms norm_arc
#print axioms im_arc
#print axioms inv_contour
#print axioms integral_add_sum
#print axioms contAt_inv_sub
#print axioms arc_zero
#print axioms arc_pi
#print axioms contour_eq
#print axioms circle_eq
#print axioms laurent_circle
#print axioms exists_small_radius
#print axioms segment_arc_aux
#print axioms norm_eval_le
#print axioms rational_decay
#print axioms integrable_inv_one_add_sq_sq
#print axioms integral_inv_one_add_sq_sq

end Helpers

/-- **The semicircle contour.** Let `f = p/q` be a ratio of polynomials, with the degree of the
bottom `q` at least the degree of the top `p` plus 2, and `q` never zero on the real line. Near
each zero `a` of `q` above the real axis, let `coeff a` be the coefficients of `f`'s Laurent
series on some punctured disc `0 < |z - a| < r`, so `Res(f, a) = coeff a (-1)`. Then the integral
of `f` over the whole real line converges (both tails are finite on their own) and
`∫_{-∞}^{∞} f(x) dx = 2πi ∑_{Im a > 0} Res(f, a)`. -/
theorem integral_rational_eq_two_pi_I_mul_sum_upper_residues
    (p q : ℂ[X]) (hdeg : p.natDegree + 2 ≤ q.natDegree)
    (hreal : ∀ x : ℝ, q.eval (x : ℂ) ≠ 0)
    (coeff : ℂ → ℤ → ℂ)
    (hlaurent : ∀ a ∈ q.roots.toFinset, 0 < a.im → ∃ r > 0, ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ coeff a n * (z - a) ^ n) (p.eval z / q.eval z)) :
    Integrable (fun x : ℝ ↦ p.eval (x : ℂ) / q.eval (x : ℂ)) ∧
      ∫ x : ℝ, p.eval (x : ℂ) / q.eval (x : ℂ) =
        2 * Real.pi * I * ∑ a ∈ q.roots.toFinset.filter (fun a ↦ 0 < a.im), coeff a (-1) := by
  classical
  obtain ⟨C, R₀, hR₀, hdec⟩ := rational_decay p q hdeg
  have hC : 0 ≤ C := by
    have h := (norm_nonneg _).trans (hdec (R₀ : ℂ) (by simp [abs_of_pos (by linarith : (0 : ℝ) < R₀)]))
    have hs : 0 < ‖(R₀ : ℂ)‖ ^ 2 := by simp; positivity
    have := mul_nonneg h hs.le
    rwa [div_mul_cancel₀ _ hs.ne'] at this
  have hcont : Continuous fun x : ℝ ↦ p.eval (x : ℂ) / q.eval (x : ℂ) :=
    (p.continuous.comp continuous_ofReal).div (q.continuous.comp continuous_ofReal) hreal
  obtain ⟨M, hM⟩ := (isCompact_Icc (a := -R₀) (b := R₀)).exists_bound_of_continuousOn
    hcont.continuousOn
  have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM 0 ⟨by linarith, by linarith⟩)
  have hbd : ∀ x : ℝ, ‖p.eval (x : ℂ) / q.eval (x : ℂ)‖ ≤
      (M * (1 + R₀ ^ 2) + 2 * C) * (1 + x ^ 2)⁻¹ := by
    intro x
    have hx1 : 0 < 1 + x ^ 2 := by positivity
    rw [← div_eq_mul_inv, le_div_iff₀ hx1]
    have hn := norm_nonneg (p.eval (x : ℂ) / q.eval (x : ℂ))
    by_cases hx : |x| ≤ R₀
    · have h := hM x (abs_le.1 hx)
      have hx2 : x ^ 2 ≤ R₀ ^ 2 := by
        rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg x) hx 2
      nlinarith
    · have hx' : R₀ < |x| := lt_of_not_ge hx
      have h := hdec (x : ℂ) (by rw [Complex.norm_real, Real.norm_eq_abs]; exact hx'.le)
      rw [Complex.norm_real, Real.norm_eq_abs, sq_abs] at h
      have hx2 : 1 ≤ x ^ 2 := by
        rw [← sq_abs]; nlinarith [abs_nonneg x]
      have h' : ‖p.eval (x : ℂ) / q.eval (x : ℂ)‖ * x ^ 2 ≤ C := by
        rwa [le_div_iff₀ (by positivity)] at h
      nlinarith [mul_nonneg hM0 (by positivity : (0 : ℝ) ≤ 1 + R₀ ^ 2)]
  have hint : Integrable fun x : ℝ ↦ p.eval (x : ℂ) / q.eval (x : ℂ) :=
    (integrable_inv_one_add_sq.const_mul _).mono' hcont.aestronglyMeasurable
      (Filter.Eventually.of_forall hbd)
  refine ⟨hint, ?_⟩
  have hS : Filter.Tendsto (fun R : ℝ ↦ ∫ x in (-R)..R, p.eval (x : ℂ) / q.eval (x : ℂ))
      Filter.atTop (nhds (∫ x : ℝ, p.eval (x : ℂ) / q.eval (x : ℂ))) :=
    intervalIntegral_tendsto_integral hint Filter.tendsto_neg_atTop_atBot Filter.tendsto_id
  have hU : Filter.Tendsto (fun R : ℝ ↦ ∫ t in (0 : ℝ)..Real.pi,
      p.eval (R * exp (t * I)) / q.eval (R * exp (t * I)) * (I * R * exp (t * I))) Filter.atTop
        (nhds 0) := by
    refine squeeze_zero_norm' ?_
      (tendsto_const_nhds.div_atTop Filter.tendsto_id :
        Filter.Tendsto (fun R : ℝ ↦ C * Real.pi / R) Filter.atTop (nhds 0))
    filter_upwards [Filter.eventually_ge_atTop R₀] with R hR
    have hRpos : 0 < R := by linarith
    have hb := intervalIntegral.norm_integral_le_of_norm_le_const (a := 0) (b := Real.pi)
      (C := C / R ^ 2 * R)
      (f := fun t : ℝ ↦ p.eval (R * exp (t * I)) / q.eval (R * exp (t * I)) * (I * R * exp (t * I)))
      (fun t _ => by
        rw [norm_mul]
        have h1 := hdec (R * exp (t * I)) (by rw [norm_arc, abs_of_pos hRpos]; exact hR)
        rw [norm_arc, abs_of_pos hRpos] at h1
        have h2 : ‖I * R * exp (t * I)‖ = R := by
          rw [mul_assoc, norm_mul, norm_I, one_mul, norm_arc, abs_of_pos hRpos]
        rw [h2]
        exact mul_le_mul_of_nonneg_right h1 hRpos.le)
    refine hb.trans (le_of_eq ?_)
    rw [sub_zero, abs_of_pos Real.pi_pos]
    field_simp
  have hev : ∀ᶠ R : ℝ in Filter.atTop,
      (2 * Real.pi * I * ∑ a ∈ q.roots.toFinset.filter (fun a ↦ 0 < a.im), coeff a (-1)) -
        (∫ t in (0 : ℝ)..Real.pi,
          p.eval (R * exp (t * I)) / q.eval (R * exp (t * I)) * (I * R * exp (t * I))) =
      ∫ x in (-R)..R, p.eval (x : ℂ) / q.eval (x : ℂ) := by
    have : ∀ᶠ R : ℝ in Filter.atTop, ∀ a ∈ q.roots.toFinset, ‖a‖ < R :=
      (Filter.eventually_all_finset _).2 fun a _ => Filter.eventually_gt_atTop _
    filter_upwards [this] with R hR
    rw [← segment_arc_aux p q hreal R hR coeff hlaurent]
    ring
  have hlim := (tendsto_const_nhds.sub hU).congr' hev
  rw [sub_zero] at hlim
  exact tendsto_nhds_unique hS hlim

/-- **The engine: segment plus arc equals the residue sum at every finite radius.** Let
`f = p/q` be a ratio of polynomials with `q` never zero on the real line, and let `R` exceed the
distance from `0` of every zero of `q`. With `Res(f, a) = coeff a (-1)` as above, the integral
along the real segment from `-R` to `R` plus the integral along the upper arc `z = R e^(it)`,
`t` from `0` to `π`, equals `2πi ∑_{Im a > 0} Res(f, a)`. -/
theorem segment_add_arc_eq_two_pi_I_mul_sum_upper_residues
    (p q : ℂ[X]) (hreal : ∀ x : ℝ, q.eval (x : ℂ) ≠ 0)
    (R : ℝ) (hR : ∀ a ∈ q.roots.toFinset, ‖a‖ < R)
    (coeff : ℂ → ℤ → ℂ)
    (hlaurent : ∀ a ∈ q.roots.toFinset, 0 < a.im → ∃ r > 0, ∀ z : ℂ, 0 < ‖z - a‖ → ‖z - a‖ < r →
      HasSum (fun n : ℤ ↦ coeff a n * (z - a) ^ n) (p.eval z / q.eval z)) :
    (∫ x in (-R)..R, p.eval (x : ℂ) / q.eval (x : ℂ)) +
        (∫ t in (0 : ℝ)..Real.pi,
          p.eval (R * exp (t * I)) / q.eval (R * exp (t * I)) * (I * R * exp (t * I))) =
      2 * Real.pi * I * ∑ a ∈ q.roots.toFinset.filter (fun a ↦ 0 < a.im), coeff a (-1) := by
  exact segment_arc_aux p q hreal R hR coeff hlaurent

/-- **The lighthouse and its square.** The area under `1/(1 + x^2)` over the whole real line
converges and is `π`, so the whole shore catches the whole sweep; the area under
`1/(1 + x^2)^2` converges and is `π/2`. -/
theorem integral_inv_one_add_sq_eq_pi_and_sq_eq_pi_div_two :
    Integrable (fun x : ℝ ↦ 1 / (1 + x ^ 2)) ∧ ∫ x : ℝ, 1 / (1 + x ^ 2) = Real.pi ∧
      Integrable (fun x : ℝ ↦ 1 / (1 + x ^ 2) ^ 2) ∧
        ∫ x : ℝ, 1 / (1 + x ^ 2) ^ 2 = Real.pi / 2 := by
  refine ⟨?_, ?_, integrable_inv_one_add_sq_sq, integral_inv_one_add_sq_sq⟩
  · simpa only [one_div] using integrable_inv_one_add_sq
  · simpa only [one_div] using integral_univ_inv_one_add_sq

/-! ### The card's worked numbers -/

-- The poles: 1 + z^2 = (z - i)(z + i), so the poles are i and -i.
example (z : ℂ) : 1 + z ^ 2 = (z - I) * (z + I) := by
  ring_nf; rw [I_sq]; ring
-- Residue at i of 1/(1 + z^2): 1/(z + i) at z = i is 1/(2i) = -i/2.
example : (1 : ℂ) / (I + I) = -I / 2 := by
  field_simp; ring_nf; rw [I_sq]; ring
-- Loop value: 2πi × (-i/2) = π.
example : 2 * (Real.pi : ℂ) * I * (-I / 2) = Real.pi := by
  ring_nf; rw [I_sq]; ring
-- Lighthouse share: π/π = 1.
example : Real.pi / Real.pi = 1 := div_self Real.pi_ne_zero
-- Squared: residue -2/(2i)^3 = -i/4, and loop value 2πi × (-i/4) = π/2.
example : (-2 : ℂ) / (2 * I) ^ 3 = -I / 4 := by
  field_simp; ring_nf; simp
example : 2 * (Real.pi : ℂ) * I * (-I / 4) = Real.pi / 2 := by
  ring_nf; rw [I_sq]; ring
-- Mistake, both poles summed: 1/(2i) + 1/(-2i) = 0, so 2πi × 0 = 0.
example : (1 : ℂ) / (2 * I) + 1 / (-2 * I) = 0 := by
  field_simp; ring
-- Mistake, simple-pole rule at the double pole: 2πi/(2i)^2 = -πi/2.
example : 2 * (Real.pi : ℂ) * I / (2 * I) ^ 2 = -(Real.pi * I) / 2 := by
  rw [mul_pow, I_sq]; ring
-- ML bound at R = 2: |1 + z^2| ≥ R^2 - 1 = 3, so M ≤ 1/3, L = 2π, and ML = 2π/3.
example : (2 : ℝ) ^ 2 - 1 = 3 := by norm_num
example : Real.pi * 2 / (2 ^ 2 - 1) = 2 * Real.pi / 3 := by ring

#print axioms integral_rational_eq_two_pi_I_mul_sum_upper_residues
#print axioms segment_add_arc_eq_two_pi_I_mul_sum_upper_residues
#print axioms integral_inv_one_add_sq_eq_pi_and_sq_eq_pi_div_two

end SemicircleContours
