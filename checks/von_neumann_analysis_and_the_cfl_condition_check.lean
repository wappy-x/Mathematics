-- Von Neumann analysis: a linear scheme with constant weights on a repeating grid stays bounded exactly when no Fourier mode comes back larger than it went in, the explicit heat step passes this test exactly when r ≤ 1/2, and an explicit one-cell scheme with Courant number above 1 cannot see data that changes the true wave.
import Mathlib.Analysis.SpecialFunctions.Complex.CircleAddChar
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.SpecialFunctions.SmoothTransition
import Mathlib.Analysis.Fourier.ZMod
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter
import Mathlib.Tactic.NormNum

open Real

lemma stdAddChar_conj {N : ℕ} [NeZero N] (x : ZMod N) :
    (starRingEnd ℂ) (ZMod.stdAddChar x) = ZMod.stdAddChar (-x) := by
  have h1 : ‖ZMod.stdAddChar x‖ = 1 := by
    rw [ZMod.stdAddChar_apply]; exact Circle.norm_coe _
  have h2 : ZMod.stdAddChar x * (starRingEnd ℂ) (ZMod.stdAddChar x) = 1 := by
    rw [Complex.mul_conj', h1]; simp
  have h3 : ZMod.stdAddChar x * ZMod.stdAddChar (-x) = 1 := by
    rw [← AddChar.map_add_eq_mul]; simp
  have h0 : ZMod.stdAddChar x ≠ 0 := by
    intro h; rw [h] at h1; simp at h1
  exact mul_left_cancel₀ h0 (h2.trans h3.symm)

#print axioms stdAddChar_conj

lemma norm_stdAddChar {N : ℕ} [NeZero N] (x : ZMod N) : ‖ZMod.stdAddChar x‖ = 1 := by
  rw [ZMod.stdAddChar_apply]; exact Circle.norm_coe _

#print axioms norm_stdAddChar

lemma parseval_modes {N : ℕ} [NeZero N] (a : ZMod N → ℂ) :
    ∑ j, ‖∑ k, a k * ZMod.stdAddChar (k * j)‖ ^ 2 = (N : ℝ) * ∑ k, ‖a k‖ ^ 2 := by
  classical
  apply Complex.ofReal_injective
  push_cast
  simp_rw [← Complex.mul_conj']
  have e1 : ∀ j : ZMod N, (∑ k, a k * ZMod.stdAddChar (k * j)) *
      (starRingEnd ℂ) (∑ k, a k * ZMod.stdAddChar (k * j)) =
      ∑ k, ∑ l, a k * ZMod.stdAddChar (k * j) *
        ((starRingEnd ℂ) (a l) * ZMod.stdAddChar (-(l * j))) := by
    intro j
    rw [map_sum, Finset.sum_mul_sum]
    simp_rw [map_mul, stdAddChar_conj]
  have key : ∀ k l : ZMod N, ∑ j : ZMod N, a k * ZMod.stdAddChar (k * j) *
      ((starRingEnd ℂ) (a l) * ZMod.stdAddChar (-(l * j))) =
      a k * (starRingEnd ℂ) (a l) * (if k - l = 0 then (N : ℂ) else 0) := by
    intro k l
    have hs := AddChar.sum_mulShift (k - l) (ZMod.isPrimitive_stdAddChar N)
    simp only [ZMod.card, Nat.cast_ite, Nat.cast_zero] at hs
    rw [← hs, Finset.mul_sum]
    refine Finset.sum_congr rfl fun j _ => ?_
    have : ZMod.stdAddChar (k * j) * ZMod.stdAddChar (-(l * j)) =
        ZMod.stdAddChar (j * (k - l)) := by
      rw [← AddChar.map_add_eq_mul]; congr 1; ring
    rw [← this]; ring
  simp_rw [e1]
  rw [Finset.sum_comm]
  have e2 : ∀ k : ZMod N, ∑ j : ZMod N, ∑ l : ZMod N, a k * ZMod.stdAddChar (k * j) *
        ((starRingEnd ℂ) (a l) * ZMod.stdAddChar (-(l * j))) =
      a k * (starRingEnd ℂ) (a k) * N := by
    intro k
    rw [Finset.sum_comm]
    simp_rw [key, sub_eq_zero, mul_ite, mul_zero]
    simp
  simp_rw [e2, Finset.mul_sum]
  refine Finset.sum_congr rfl fun k _ => ?_
  ring

#print axioms parseval_modes

lemma mode_eigen {N : ℕ} [NeZero N]
    (S : (ZMod N → ℂ) →ₗ[ℂ] (ZMod N → ℂ))
    (hS : ∀ (u : ZMod N → ℂ) (j : ZMod N), S (fun i => u (i + 1)) j = S u (j + 1))
    (k : ZMod N) :
    S (fun j => ZMod.stdAddChar (k * j)) =
      (S (fun j => ZMod.stdAddChar (k * j)) 0) • (fun j => ZMod.stdAddChar (k * j)) := by
  set e : ZMod N → ℂ := fun j => ZMod.stdAddChar (k * j) with he
  have shift : (fun i => e (i + 1)) = ZMod.stdAddChar k • e := by
    funext i
    simp only [he, Pi.smul_apply, smul_eq_mul]
    rw [← AddChar.map_add_eq_mul]; congr 1; ring
  have step : ∀ j, S e (j + 1) = ZMod.stdAddChar k * S e j := by
    intro j
    rw [← hS, shift, map_smul]; rfl
  have nat : ∀ m : ℕ, S e (m : ZMod N) = ZMod.stdAddChar (k * (m : ZMod N)) * S e 0 := by
    intro m
    induction m with
    | zero => simp
    | succ m ih =>
      push_cast
      rw [step, ih, ← mul_assoc, ← AddChar.map_add_eq_mul]
      congr 2; ring
  funext j
  have := nat j.val
  rw [ZMod.natCast_zmod_val] at this
  rw [this]
  simp only [Pi.smul_apply, smul_eq_mul, he]
  ring

#print axioms mode_eigen

lemma mode_pow {N : ℕ}
    (S : (ZMod N → ℂ) →ₗ[ℂ] (ZMod N → ℂ)) (e : ZMod N → ℂ) (g : ℂ) (hg : S e = g • e) :
    ∀ n : ℕ, (S ^ n) e = g ^ n • e := by
  intro n
  induction n with
  | zero => simp
  | succ n ih =>
    rw [pow_succ, Module.End.mul_apply, hg, map_smul, ih, smul_smul, pow_succ]
    ring_nf

#print axioms mode_pow

lemma iterate_local {α : Type*} (step : (ℤ → α) → ℤ → α)
    (hstep : ∀ (u v : ℤ → α) (j : ℤ), (∀ i, |i - j| ≤ 1 → u i = v i) → step u j = step v j) :
    ∀ (m : ℕ) (u v : ℤ → α) (j : ℤ), (∀ i, |i - j| ≤ m → u i = v i) →
      step^[m] u j = step^[m] v j := by
  intro m
  induction m with
  | zero => intro u v j h; simpa using h j (by simp)
  | succ m ih =>
    intro u v j h
    rw [Function.iterate_succ_apply, Function.iterate_succ_apply]
    apply ih
    intro i hi
    apply hstep
    intro i' hi'
    apply h
    have : |i' - j| ≤ |i' - i| + |i - j| := by
      have := abs_sub_le i' i j; simpa using this
    push_cast; linarith

#print axioms iterate_local

/-- Von Neumann analysis on a repeating grid of N points, with one old level.
Let S be one step of a scheme: a linear map on the grid readings u : ZMod N → ℂ whose weights
do not change from point to point, so shifting the readings one cell shifts the output one cell.
The Fourier mode with wave number k is the wave j ↦ e^(2πi k j / N) (Mathlib's
`ZMod.stdAddChar (k * j)`). Measure the size of the readings by the sum of |u_j|².
Then the scheme is stable (some constant C bounds the size after any number of steps by
C times the starting size) exactly when every factor g that a mode comes back multiplied by
has |g| ≤ 1. -/
theorem stable_iff_every_growth_factor_at_most_one {N : ℕ} [NeZero N]
    (S : (ZMod N → ℂ) →ₗ[ℂ] (ZMod N → ℂ))
    (hS : ∀ (u : ZMod N → ℂ) (j : ZMod N), S (fun i => u (i + 1)) j = S u (j + 1)) :
    (∃ C : ℝ, ∀ (n : ℕ) (u : ZMod N → ℂ),
        ∑ j, ‖(S ^ n) u j‖ ^ 2 ≤ C * ∑ j, ‖u j‖ ^ 2) ↔
      ∀ (k : ZMod N) (g : ℂ),
        S (fun j => ZMod.stdAddChar (k * j)) = g • (fun j => ZMod.stdAddChar (k * j)) →
          ‖g‖ ≤ 1 := by
  have hNpos : (0 : ℝ) < N := by exact_mod_cast Nat.pos_of_ne_zero (NeZero.ne N)
  constructor
  · rintro ⟨C, hC⟩ k g hg
    by_contra hlt
    push Not at hlt
    have hb : ∀ n : ℕ, (‖g‖ ^ 2) ^ n ≤ C := by
      intro n
      have h1 := hC n (fun j => ZMod.stdAddChar (k * j))
      rw [mode_pow S _ g hg n] at h1
      simp only [Pi.smul_apply, smul_eq_mul, norm_mul, norm_pow, norm_stdAddChar, mul_one,
        one_pow, Finset.sum_const, Finset.card_univ, ZMod.card, nsmul_eq_mul] at h1
      rw [← pow_mul, mul_comm 2 n, pow_mul]
      nlinarith
    obtain ⟨n, hn⟩ := pow_unbounded_of_one_lt C (by nlinarith : (1 : ℝ) < ‖g‖ ^ 2)
    exact absurd (hb n) (not_le.2 hn)
  · intro h
    refine ⟨1, fun n u => ?_⟩
    set e : ZMod N → ZMod N → ℂ := fun k j => ZMod.stdAddChar (k * j) with he
    set g : ZMod N → ℂ := fun k => S (e k) 0 with hgdef
    have heig : ∀ k, S (e k) = g k • e k := fun k => mode_eigen S hS k
    have hg1 : ∀ k, ‖g k‖ ≤ 1 := fun k => h k (g k) (heig k)
    set a : ZMod N → ℂ := fun k => (N : ℂ)⁻¹ * ZMod.dft u k with ha
    have hu : u = ∑ k, a k • e k := by
      funext j
      have := congrFun (ZMod.dft.symm_apply_apply u) j
      rw [ZMod.invDFT_apply] at this
      rw [← this, Finset.sum_apply, smul_eq_mul, Finset.mul_sum]
      refine Finset.sum_congr rfl fun k _ => ?_
      simp only [Pi.smul_apply, smul_eq_mul, he, ha]
      ring
    have hSn : (S ^ n) u = ∑ k, (a k * g k ^ n) • e k := by
      conv_lhs => rw [hu]
      rw [map_sum]
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [map_smul, mode_pow S (e k) (g k) (heig k) n, smul_smul, mul_comm]
    have hval : ∀ (b : ZMod N → ℂ) (j : ZMod N),
        (∑ k, b k • e k) j = ∑ k, b k * ZMod.stdAddChar (k * j) := by
      intro b j
      rw [Finset.sum_apply]
      rfl
    have lhs : ∑ j, ‖(S ^ n) u j‖ ^ 2 = (N : ℝ) * ∑ k, ‖a k * g k ^ n‖ ^ 2 := by
      rw [hSn]; simp_rw [hval]; exact parseval_modes _
    have rhs : ∑ j, ‖u j‖ ^ 2 = (N : ℝ) * ∑ k, ‖a k‖ ^ 2 := by
      conv_lhs => rw [hu]
      simp_rw [hval]; exact parseval_modes _
    rw [lhs, rhs, one_mul]
    apply mul_le_mul_of_nonneg_left _ hNpos.le
    apply Finset.sum_le_sum
    intro k _
    rw [norm_mul, norm_pow, mul_pow]
    have h0 : 0 ≤ ‖g k‖ ^ n := by positivity
    have h1 : ‖g k‖ ^ n ≤ 1 := pow_le_one₀ (norm_nonneg _) (hg1 k)
    have h2 : (‖g k‖ ^ n) ^ 2 ≤ 1 := by nlinarith
    nlinarith [sq_nonneg ‖a k‖]

/-- The explicit heat step u_j ← r u_(j-1) + (1 - 2r) u_j + r u_(j+1), with mesh ratio
r = αΔt/h² ≥ 0, multiplies the wave with turn θ = ξh between neighbours by
g = 1 - 4r sin²(θ/2). Every such factor has |g| ≤ 1 exactly when r ≤ 1/2. -/
theorem explicit_heat_step_stable_iff (r : ℝ) (hr : 0 ≤ r) :
    (∀ θ : ℝ, |1 - 4 * r * Real.sin (θ / 2) ^ 2| ≤ 1) ↔ r ≤ 1 / 2 := by
  constructor
  · intro h
    have := h π
    rw [Real.sin_pi_div_two, abs_le] at this
    linarith [this.1]
  · intro h θ
    have h0 : 0 ≤ Real.sin (θ / 2) ^ 2 := sq_nonneg _
    have h1 : Real.sin (θ / 2) ^ 2 ≤ 1 := Real.sin_sq_le_one _
    rw [abs_le]
    constructor <;> nlinarith [mul_nonneg hr h0]

/-- The CFL condition is necessary. Take any explicit scheme whose stencil reaches one cell each
way (the new value at point j depends only on the old values at j - 1, j, j + 1), started from
the samples of a starting shape f at the grid points x_i = i h, and read off after n ≥ 1 steps.
Let the true answer be d'Alembert's formula for a bar starting at rest,
u(x, t) = (f(x - ct) + f(x + ct)) / 2. If the Courant number ν = |c|Δt/h is above 1, there are
two smooth starting shapes on which the scheme computes the same value at point j after n steps,
while the true answers at x = j h, t = n Δt differ. So the computed answers cannot converge to
the true ones for every start. -/
theorem cfl_condition_necessary {α : Type*} (step : (ℤ → α) → ℤ → α)
    (hstep : ∀ (u v : ℤ → α) (j : ℤ), (∀ i, |i - j| ≤ 1 → u i = v i) → step u j = step v j)
    (init : ℝ → α) (read : α → ℝ) (h Δt c : ℝ) (hh : 0 < h) (hΔt : 0 < Δt)
    (hν : 1 < |c| * Δt / h) (j : ℤ) (n : ℕ) (hn : 0 < n) :
    ∃ f g : ℝ → ℝ, ContDiff ℝ 2 f ∧ ContDiff ℝ 2 g ∧
      read ((step^[n] fun i => init (f (i * h))) j) =
        read ((step^[n] fun i => init (g (i * h))) j) ∧
      (f (j * h - c * (n * Δt)) + f (j * h + c * (n * Δt))) / 2 ≠
        (g (j * h - c * (n * Δt)) + g (j * h + c * (n * Δt))) / 2 := by
  refine ⟨fun _ => 0, fun x => Real.smoothTransition (x - (j + n) * h), contDiff_const,
    Real.smoothTransition.contDiff.comp (contDiff_id.sub contDiff_const), ?_, ?_⟩
  · congr 1
    apply iterate_local step hstep
    intro i hi
    have hi' : (i : ℝ) ≤ j + n := by
      have := (abs_le.1 hi).2
      exact_mod_cast (by linarith : i ≤ j + n)
    simp only
    rw [Real.smoothTransition.zero_of_nonpos]
    nlinarith
  · have hν' : h < |c| * Δt := by rwa [lt_div_iff₀ hh, one_mul] at hν
    have hn' : (1 : ℝ) ≤ n := by exact_mod_cast hn
    have key : ∀ y : ℝ, y = |c| * (n * Δt) →
        0 < Real.smoothTransition (j * h + y - (j + n) * h) := by
      intro y hy
      apply Real.smoothTransition.pos_of_pos
      subst hy
      nlinarith
    have nn := Real.smoothTransition.nonneg
    simp only [zero_add, zero_div]
    intro heq
    rcases le_or_gt 0 c with hc | hc
    · have := key (c * (n * Δt)) (by rw [abs_of_nonneg hc])
      linarith [nn (j * h - c * (n * Δt) - (j + n) * h)]
    · have := key (-c * (n * Δt)) (by rw [abs_of_neg hc])
      have e : (j:ℝ) * h + -c * (n * Δt) = j * h - c * (n * Δt) := by ring
      rw [e] at this
      linarith [nn (j * h + c * (n * Δt) - (j + n) * h)]

-- Heat limit: h²/(2α) with h = 0.01 m and α = 1.25e-5 m²/s is 4 s.
example : ((1 : ℚ) / 100) ^ 2 / (2 * (125 / 10 ^ 7)) = 4 := by norm_num
-- A 4.08 s heat step gives r = αΔt/h² = 0.51.
example : ((125 : ℚ) / 10 ^ 7) * (408 / 100) / ((1 / 100) ^ 2) = 51 / 100 := by norm_num
-- Sound limit: h/c with h = 0.01 m and c = 5000 m/s is 2 µs.
example : ((1 : ℚ) / 100) / 5000 = 2 / 10 ^ 6 := by norm_num
-- A 2.04 µs sound step gives ν = cΔt/h = 1.02.
example : (5000 : ℚ) * (204 / 10 ^ 8) / (1 / 100) = 102 / 100 := by norm_num
-- Centred transport at ν = 0.5: the worst size squared is 1 + ν² = 5/4, above 1.
example : (1 : ℚ) + (1 / 2) ^ 2 = 5 / 4 := by norm_num
-- Leapfrog at ν = 1 on the zigzag ξh = π: β = 1 - 2 = -1 and g² - 2βg + 1 = (g + 1)², a double root -1.
example (g : ℚ) : g ^ 2 - 2 * (1 - 2 * 1 ^ 2) * g + 1 = (g + 1) ^ 2 := by ring
-- Heat at r = 0.5: the stencil's reach h/Δt is 0.25 cm/s at h = 0.01 m and 2.50 cm/s at h = 0.001 m.
example : ((1 : ℚ) / 100) / 4 * 100 = 1 / 4 := by norm_num
example : ((1 : ℚ) / 1000) / (4 / 100) * 100 = 5 / 2 := by norm_num
-- Cost of 1200 s at 5 flops per interior point: 300 steps × 99 points, then 30000 steps × 999 points.
example : (1200 / 4) * 99 * 5 = 148500 := by norm_num
example : 30000 * 999 * 5 = 149850000 := by norm_num

#print axioms stable_iff_every_growth_factor_at_most_one
#print axioms explicit_heat_step_stable_iff
#print axioms cfl_condition_necessary
