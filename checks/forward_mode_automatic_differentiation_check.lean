-- Forward-mode automatic differentiation: running a program of sums, products, quotients, exp and log on the dual number y + 1ε returns its value plus its exact derivative times ε.
import Mathlib.Algebra.DualNumber
import Mathlib.Analysis.SpecialFunctions.Log.Deriv

open DualNumber TrivSqZeroExt

/-- A straight-line program in one input: the input `y`, real constants, and the
operations `+`, `−`, `×`, `÷`, `exp` and `log`, each line built from earlier lines. -/
inductive Prog : Type
  | var : Prog
  | const : ℝ → Prog
  | add : Prog → Prog → Prog
  | sub : Prog → Prog → Prog
  | mul : Prog → Prog → Prog
  | div : Prog → Prog → Prog
  | exp : Prog → Prog
  | log : Prog → Prog

namespace Prog

/-- The plain run of the program on a real input. -/
noncomputable def eval : Prog → ℝ → ℝ
  | var, y => y
  | const c, _ => c
  | add p q, y => p.eval y + q.eval y
  | sub p q, y => p.eval y - q.eval y
  | mul p q, y => p.eval y * q.eval y
  | div p q, y => p.eval y / q.eval y
  | exp p, y => Real.exp (p.eval y)
  | log p, y => Real.log (p.eval y)

/-- The card's rule for `exp` on a dual number: `exp (a + bε) = e^a + e^a b ε`. -/
noncomputable def dualExp (x : DualNumber ℝ) : DualNumber ℝ :=
  inl (Real.exp x.fst) + (Real.exp x.fst * x.snd) • ε

/-- The card's rule for `log` on a dual number: `log (a + bε) = log a + (b / a) ε`. -/
noncomputable def dualLog (x : DualNumber ℝ) : DualNumber ℝ :=
  inl (Real.log x.fst) + (x.snd / x.fst) • ε

/-- The same program run on dual numbers: constants enter with slope part 0, and
`+`, `−`, `×`, `÷` are Mathlib's dual-number arithmetic (`÷` is multiplication by the inverse). -/
noncomputable def evalDual : Prog → DualNumber ℝ → DualNumber ℝ
  | var, x => x
  | const c, _ => inl c
  | add p q, x => p.evalDual x + q.evalDual x
  | sub p q, x => p.evalDual x - q.evalDual x
  | mul p q, x => p.evalDual x * q.evalDual x
  | div p q, x => p.evalDual x * (q.evalDual x)⁻¹
  | exp p, x => dualExp (p.evalDual x)
  | log p, x => dualLog (p.evalDual x)

/-- "Every operation has a slope where it runs": every divisor is nonzero and every
`log` input is positive at the point `y`. -/
def HasSlopeAt : Prog → ℝ → Prop
  | var, _ => True
  | const _, _ => True
  | add p q, y => p.HasSlopeAt y ∧ q.HasSlopeAt y
  | sub p q, y => p.HasSlopeAt y ∧ q.HasSlopeAt y
  | mul p q, y => p.HasSlopeAt y ∧ q.HasSlopeAt y
  | div p q, y => p.HasSlopeAt y ∧ q.HasSlopeAt y ∧ q.eval y ≠ 0
  | exp p, y => p.HasSlopeAt y
  | log p, y => p.HasSlopeAt y ∧ 0 < p.eval y

end Prog

/-- Componentwise form of forward mode: the real part of the dual run is the plain run,
and the slope part is a derivative of the plain run. -/
theorem forward_mode_components (p : Prog) (y : ℝ) (h : p.HasSlopeAt y) :
    (p.evalDual (inl y + ε)).fst = p.eval y ∧
      HasDerivAt p.eval (p.evalDual (inl y + ε)).snd y := by
  induction p with
  | var =>
    refine ⟨?_, ?_⟩
    · simp [Prog.evalDual, Prog.eval]
    · have : (fun y : ℝ => Prog.var.eval y) = id := by funext z; rfl
      simp only [Prog.evalDual, snd_add, snd_inl, snd_eps, zero_add, this]
      exact hasDerivAt_id y
  | const c =>
    refine ⟨by simp [Prog.evalDual, Prog.eval], ?_⟩
    have : (fun y : ℝ => (Prog.const c).eval y) = fun _ => c := by funext z; rfl
    simp only [Prog.evalDual, snd_inl, this]
    exact hasDerivAt_const y c
  | add p q ihp ihq =>
    obtain ⟨hp1, hp2⟩ := ihp h.1
    obtain ⟨hq1, hq2⟩ := ihq h.2
    refine ⟨by simp [Prog.evalDual, Prog.eval, hp1, hq1], ?_⟩
    have : (fun y : ℝ => (Prog.add p q).eval y) = fun z => p.eval z + q.eval z := by
      funext z; rfl
    simp only [Prog.evalDual, snd_add, this]
    exact hp2.add hq2
  | sub p q ihp ihq =>
    obtain ⟨hp1, hp2⟩ := ihp h.1
    obtain ⟨hq1, hq2⟩ := ihq h.2
    refine ⟨by simp [Prog.evalDual, Prog.eval, hp1, hq1], ?_⟩
    have : (fun y : ℝ => (Prog.sub p q).eval y) = fun z => p.eval z - q.eval z := by
      funext z; rfl
    simp only [Prog.evalDual, snd_sub, this]
    exact hp2.sub hq2
  | mul p q ihp ihq =>
    obtain ⟨hp1, hp2⟩ := ihp h.1
    obtain ⟨hq1, hq2⟩ := ihq h.2
    refine ⟨by simp [Prog.evalDual, Prog.eval, hp1, hq1], ?_⟩
    have : (fun y : ℝ => (Prog.mul p q).eval y) = fun z => p.eval z * q.eval z := by
      funext z; rfl
    simp only [Prog.evalDual, DualNumber.snd_mul, this]
    convert hp2.mul hq2 using 1
    simp [hp1, hq1]
    ring
  | div p q ihp ihq =>
    obtain ⟨hp1, hp2⟩ := ihp h.1
    obtain ⟨hq1, hq2⟩ := ihq h.2.1
    have hq0 : q.eval y ≠ 0 := h.2.2
    refine ⟨by simp [Prog.evalDual, Prog.eval, hp1, hq1, div_eq_mul_inv], ?_⟩
    have : (fun y : ℝ => (Prog.div p q).eval y) = fun z => p.eval z / q.eval z := by
      funext z; rfl
    simp only [Prog.evalDual, DualNumber.snd_mul, this]
    convert hp2.div hq2 hq0 using 1
    simp [hp1, hq1, smul_eq_mul, MulOpposite.smul_eq_mul_unop]
    field_simp
    ring
  | exp p ihp =>
    obtain ⟨hp1, hp2⟩ := ihp h
    refine ⟨by simp [Prog.evalDual, Prog.eval, Prog.dualExp, hp1], ?_⟩
    have : (fun y : ℝ => (Prog.exp p).eval y) = fun z => Real.exp (p.eval z) := by
      funext z; rfl
    simp only [Prog.evalDual, Prog.dualExp, this]
    convert hp2.exp using 1
    simp [hp1]
  | log p ihp =>
    obtain ⟨hp1, hp2⟩ := ihp h.1
    have hpos : 0 < p.eval y := h.2
    refine ⟨by simp [Prog.evalDual, Prog.eval, Prog.dualLog, hp1], ?_⟩
    have : (fun y : ℝ => (Prog.log p).eval y) = fun z => Real.log (p.eval z) := by
      funext z; rfl
    simp only [Prog.evalDual, Prog.dualLog, this]
    convert hp2.log hpos.ne' using 1
    simp [hp1]

#print axioms forward_mode_components

/-- Forward mode is exact: if every operation of the program has a slope where it runs,
then running the program on the seeded input `y + 1ε` returns `P(y) + P'(y) ε`, where
`P` is the plain program, `P` is differentiable at `y`, and `P'(y)` is its derivative. -/
theorem forward_mode_gives_exact_derivative (p : Prog) (y : ℝ) (h : p.HasSlopeAt y) :
    DifferentiableAt ℝ p.eval y ∧
      p.evalDual (inl y + ε) = inl (p.eval y) + deriv p.eval y • ε := by
  obtain ⟨h1, h2⟩ := forward_mode_components p y h
  refine ⟨h2.differentiableAt, ?_⟩
  ext
  · simp [h1]
  · simp [h2.deriv]

/-- Dual multiplication is the product rule:
`(a + bε)(c + dε) = ac + (ad + bc) ε`. -/
theorem dual_mul_is_product_rule (a b c d : ℝ) :
    (inl a + b • ε : DualNumber ℝ) * (inl c + d • ε) = inl (a * c) + (a * d + b * c) • ε := by
  ext <;> simp [smul_eq_mul, MulOpposite.smul_eq_mul_unop]

/-- Dual division is the quotient rule: for `c ≠ 0`,
`(a + bε) ÷ (c + dε) = a/c + ((b − (a/c) d)/c) ε`. -/
theorem dual_div_is_quotient_rule (a b c d : ℝ) (hc : c ≠ 0) :
    (inl a + b • ε : DualNumber ℝ) * (inl c + d • ε)⁻¹ =
      inl (a / c) + ((b - (a / c) * d) / c) • ε := by
  ext
  · simp [div_eq_mul_inv]
  · simp [smul_eq_mul, MulOpposite.smul_eq_mul_unop]
    field_simp
    ring

-- The card's operation counts for n coupons: 3n + 8 plain and 10n + 22 dual.
-- 30-year bond, n = 60: 188 plain, 622 dual.
example : 3 * 60 + 8 = 188 ∧ 10 * 60 + 22 = 622 := by norm_num
-- 1-year bond, n = 2: 14 plain, 42 dual.
example : 3 * 2 + 8 = 14 ∧ 10 * 2 + 22 = 42 := by norm_num
-- 5-year bond, n = 10: 38 plain, 122 dual.
example : 3 * 10 + 8 = 38 ∧ 10 * 10 + 22 = 122 := by norm_num
-- 10-year bond, n = 20: 68 plain, 222 dual.
example : 3 * 20 + 8 = 68 ∧ 10 * 20 + 22 = 222 := by norm_num

#print axioms forward_mode_gives_exact_derivative
#print axioms dual_mul_is_product_rule
#print axioms dual_div_is_quotient_rule
