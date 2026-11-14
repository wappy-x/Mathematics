-- Loop shaping: a lead compensator's phase peaks at the geometric mean of its zero and pole, with sine (1 - α)/(1 + α) and gain Kc/√α there.
import Mathlib.Analysis.SpecialFunctions.Complex.Arg
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Complex

/-- The lead section C₁(s) = Kc (T s + 1)/(α T s + 1). -/
noncomputable def lead (Kc T α : ℝ) (s : ℂ) : ℂ :=
  (Kc : ℂ) * ((T : ℂ) * s + 1) / ((α : ℂ) * (T : ℂ) * s + 1)

lemma arg_eq_arctan_of_re_pos {z : ℂ} (h : 0 < z.re) : arg z = Real.arctan (z.im / z.re) := by
  have hab : |arg z| < Real.pi / 2 := abs_arg_lt_pi_div_two_iff.2 (Or.inl h)
  obtain ⟨h1, h2⟩ := abs_lt.1 hab
  rw [← tan_arg, Real.arctan_tan h1 h2]

lemma lead_eq (Kc T α ω : ℝ) :
    lead Kc T α (ω * I) = ⟨Kc * (1 + α * (T * ω) ^ 2) / (1 + (α * T * ω) ^ 2),
      Kc * (1 - α) * (T * ω) / (1 + (α * T * ω) ^ 2)⟩ := by
  unfold lead
  have hd : ((α : ℂ) * T * (ω * I) + 1) ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp at this
  rw [div_eq_iff hd]
  have hp : (0:ℝ) < 1 + (α * T * ω) ^ 2 := by positivity
  apply Complex.ext <;> simp <;> field_simp <;> ring

lemma arg_lead (Kc T α ω : ℝ) (hKc : 0 < Kc) (hα0 : 0 < α) :
    arg (lead Kc T α (ω * I)) = Real.arctan ((1 - α) * (T * ω) / (1 + α * (T * ω) ^ 2)) := by
  have hp : (0:ℝ) < 1 + (α * T * ω) ^ 2 := by positivity
  have hq : (0:ℝ) < 1 + α * (T * ω) ^ 2 := by positivity
  rw [lead_eq, arg_eq_arctan_of_re_pos (by simp only; positivity)]
  congr 1
  simp only
  field_simp

lemma key (s x : ℝ) (hs : 0 < s) (hx : 0 < x) (hne : x ≠ 1 / s) (h1 : s ^ 2 < 1) :
    (1 - s ^ 2) * x / (1 + s ^ 2 * x ^ 2) < (1 - s ^ 2) * (1 / s) / (1 + s ^ 2 * (1 / s) ^ 2) := by
  have hsx : s * x - 1 ≠ 0 := by
    intro h; apply hne; field_simp; linarith
  have e : (1 - s ^ 2) * (1 / s) / (1 + s ^ 2 * (1 / s) ^ 2) = (1 - s ^ 2) / (2 * s) := by
    field_simp; ring
  rw [e, div_lt_div_iff₀ (by positivity) (by positivity)]
  nlinarith [mul_pos (sub_pos.2 h1) (lt_of_le_of_ne (sq_nonneg (s * x - 1)) (Ne.symm (pow_ne_zero 2 hsx)))]

#print axioms arg_eq_arctan_of_re_pos
#print axioms lead_eq
#print axioms arg_lead
#print axioms key

/-- A lead section with gain Kc > 0, time constant T > 0 and pole-to-zero ratio 0 < α < 1 has
its phase (the argument of C₁(jω)) at its single maximum over ω > 0 at the geometric mean
ω_m = 1/(T √α) of its zero 1/T and its pole 1/(α T); the peak phase φ_m satisfies
sin φ_m = (1 - α)/(1 + α), equivalently α = (1 - sin φ_m)/(1 + sin φ_m). -/
theorem lead_phase_peaks_at_geometric_mean (Kc T α : ℝ) (hKc : 0 < Kc) (hT : 0 < T)
    (hα0 : 0 < α) (hα1 : α < 1) :
    (∀ ω : ℝ, 0 < ω → ω ≠ 1 / (T * Real.sqrt α) →
      arg (lead Kc T α (ω * I)) < arg (lead Kc T α ((1 / (T * Real.sqrt α) : ℝ) * I))) ∧
    Real.sin (arg (lead Kc T α ((1 / (T * Real.sqrt α) : ℝ) * I))) = (1 - α) / (1 + α) ∧
    α = (1 - Real.sin (arg (lead Kc T α ((1 / (T * Real.sqrt α) : ℝ) * I)))) /
      (1 + Real.sin (arg (lead Kc T α ((1 / (T * Real.sqrt α) : ℝ) * I)))) := by
  have hsin : Real.sin (arg (lead Kc T α ((1 / (T * Real.sqrt α) : ℝ) * I))) = (1 - α) / (1 + α) := by
    rw [arg_lead _ _ _ _ hKc hα0, Real.sin_arctan]
    obtain ⟨s, hs0, rfl⟩ : ∃ s, 0 < s ∧ α = s ^ 2 :=
      ⟨Real.sqrt α, Real.sqrt_pos.2 hα0, (Real.sq_sqrt hα0.le).symm⟩
    rw [Real.sqrt_sq hs0.le]
    have hm : T * (1 / (T * s)) = 1 / s := by field_simp
    rw [hm]
    have e : 1 + ((1 - s ^ 2) * (1 / s) / (1 + s ^ 2 * (1 / s) ^ 2)) ^ 2 = ((1 + s ^ 2) / (2 * s)) ^ 2 := by
      field_simp; ring
    rw [e, Real.sqrt_sq (by positivity)]
    field_simp; ring
  refine ⟨?_, hsin, ?_⟩
  · intro ω hω hne
    rw [arg_lead _ _ _ _ hKc hα0, arg_lead _ _ _ _ hKc hα0, Real.arctan_lt_arctan_iff]
    obtain ⟨s, hs0, rfl⟩ : ∃ s, 0 < s ∧ α = s ^ 2 :=
      ⟨Real.sqrt α, Real.sqrt_pos.2 hα0, (Real.sq_sqrt hα0.le).symm⟩
    rw [Real.sqrt_sq hs0.le] at hne ⊢
    have hm : T * (1 / (T * s)) = 1 / s := by field_simp
    rw [hm]
    apply key s (T * ω) hs0 (by positivity) _ hα1
    intro h; apply hne; rw [← hm] at h; exact mul_left_cancel₀ hT.ne' h
  · rw [hsin]
    field_simp; ring

/-- At its phase peak ω_m = 1/(T √α), the lead's gain is Kc/√α: one over root alpha times its
low-frequency gain Kc. -/
theorem lead_gain_at_peak (Kc T α : ℝ) (hKc : 0 < Kc) (hT : 0 < T)
    (hα0 : 0 < α) (hα1 : α < 1) :
    ‖lead Kc T α ((1 / (T * Real.sqrt α) : ℝ) * I)‖ = Kc / Real.sqrt α := by
  rw [← pow_left_inj₀ (norm_nonneg _) (by positivity) two_ne_zero, Complex.sq_norm, lead_eq,
    normSq_mk]
  obtain ⟨s, hs0, rfl⟩ : ∃ s, 0 < s ∧ α = s ^ 2 :=
    ⟨Real.sqrt α, Real.sqrt_pos.2 hα0, (Real.sq_sqrt hα0.le).symm⟩
  rw [Real.sqrt_sq hs0.le]
  field_simp
  ring

/-- A 45° lead needs α = (1 - sin 45°)/(1 + sin 45°) = 3 - 2√2. -/
theorem lead_alpha_for_45_degrees :
    (1 - Real.sin (Real.pi / 4)) / (1 + Real.sin (Real.pi / 4)) = 3 - 2 * Real.sqrt 2 := by
  rw [Real.sin_pi_div_four]
  have h2 : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hp : 0 < Real.sqrt 2 := by positivity
  rw [div_eq_iff (by positivity)]
  nlinarith

#print axioms lead_phase_peaks_at_geometric_mean
#print axioms lead_gain_at_peak
#print axioms lead_alpha_for_45_degrees
