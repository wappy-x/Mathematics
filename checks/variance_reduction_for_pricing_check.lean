-- Cheaper Monte Carlo: with the best slope a control variate cuts the variance to (1 - ρ²) times the plain one without moving the target, a mirrored pair of a one-way payoff is at most half as noisy as one path, and the arithmetic-average ticket pays at least the geometric one on every path.
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.IdentDistrib

open MeasureTheory ProbabilityTheory

/-! A path is a point `ω` of a probability space `(Ω, P)`. A payoff is a real random
variable with finite variance (`MemLp _ 2 P`). `Var[X; P]` is Mathlib's variance,
`cov[X, Y; P]` its covariance, and `∫ ω, X ω ∂P` the true average `E[X]`.
The slope is `β = cov(X, Y) / var(Y)` and the correlation is
`ρ = cov(X, Y) / (√var(X) · √var(Y))`. -/

variable {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]

lemma cv_var_sub_mul (X Y : Ω → ℝ) (hX : MemLp X 2 P) (hY : MemLp Y 2 P) (c : ℝ) :
    Var[fun ω => X ω - c * Y ω; P] = Var[X; P] - 2 * c * cov[X, Y; P] + c ^ 2 * Var[Y; P] := by
  rw [variance_fun_sub hX (hY.const_mul c), variance_const_mul, covariance_const_mul_right]
  ring

#print axioms cv_var_sub_mul

lemma cv_cov_sq_le (X Y : Ω → ℝ) (hX : MemLp X 2 P) (hY : MemLp Y 2 P) :
    cov[X, Y; P] ^ 2 ≤ Var[X; P] * Var[Y; P] := by
  have key := cv_var_sub_mul X Y hX hY
  have hnn : ∀ c : ℝ, 0 ≤ Var[X; P] - 2 * c * cov[X, Y; P] + c ^ 2 * Var[Y; P] := by
    intro c; rw [← key c]; exact variance_nonneg _ _
  have hvX := variance_nonneg X P
  rcases (variance_nonneg Y P).eq_or_lt with hv | hv
  · rw [← hv]
    by_contra hc
    have hc0 : cov[X, Y; P] ≠ 0 := by
      intro h; apply hc; rw [h]; simp
    have h := hnn ((Var[X; P] + 1) / (2 * cov[X, Y; P]))
    rw [← hv] at h
    have e : 2 * ((Var[X; P] + 1) / (2 * cov[X, Y; P])) * cov[X, Y; P] = Var[X; P] + 1 := by
      field_simp
    linarith
  · have := hnn (cov[X, Y; P] / Var[Y; P])
    have h2 : Var[X; P] - 2 * (cov[X, Y; P] / Var[Y; P]) * cov[X, Y; P] +
        (cov[X, Y; P] / Var[Y; P]) ^ 2 * Var[Y; P]
        = (Var[X; P] * Var[Y; P] - cov[X, Y; P] ^ 2) / Var[Y; P] := by
      field_simp; ring
    rw [h2] at this
    have := (div_nonneg_iff.mp this)
    rcases this with ⟨h, _⟩ | ⟨_, h⟩
    · linarith
    · linarith

#print axioms cv_cov_sq_le

lemma av_cov_nonpos (Z : Ω → ℝ) (f g : ℝ → ℝ) (hf : Monotone f) (hg : Antitone g)
    (hA : MemLp (fun ω => f (Z ω)) 2 P) (hB : MemLp (fun ω => g (Z ω)) 2 P) :
    cov[fun ω => f (Z ω), fun ω => g (Z ω); P] ≤ 0 := by
  set b := ∫ ω, g (Z ω) ∂P with hb
  have hBi : Integrable (fun ω => g (Z ω)) P := hB.integrable one_le_two
  have hB0 : ∫ ω, (g (Z ω) - b) ∂P = 0 := by
    rw [integral_sub hBi (integrable_const _)]; simp [hb]
  have hcov : ∀ a : ℝ, cov[fun ω => f (Z ω), fun ω => g (Z ω); P]
      = ∫ ω, (f (Z ω) - a) * (g (Z ω) - b) ∂P := by
    intro a
    rw [← covariance_sub_const_left (hA.integrable one_le_two) a,
      ← covariance_sub_const_right hBi b,
      covariance_eq_sub (X := fun ω => f (Z ω) - a) (Y := fun ω => g (Z ω) - b)
        (hA.sub (memLp_const a)) (hB.sub (memLp_const b))]
    simp only [hB0, mul_zero, sub_zero]
    rfl
  by_cases h1 : ∃ z1, g z1 < b
  · by_cases h2 : ∃ z2, b < g z2
    · obtain ⟨z1, hz1⟩ := h1
      obtain ⟨z2, hz2⟩ := h2
      set S := {z | b < g z} with hS
      have hlt : ∀ w ∈ S, ∀ z, g z < b → w < z := by
        intro w hw z hz
        by_contra h
        push Not at h
        have := hg h
        simp only [hS, Set.mem_ofPred_eq] at hw
        linarith
      have hbdd : BddAbove (f '' S) := ⟨f z1, by
        rintro _ ⟨w, hw, rfl⟩; exact hf (hlt w hw z1 hz1).le⟩
      have hne : (f '' S).Nonempty := ⟨f z2, z2, hz2, rfl⟩
      rw [hcov (sSup (f '' S))]
      apply integral_nonpos
      intro ω
      simp only [Pi.zero_apply]
      rcases lt_trichotomy (g (Z ω)) b with h | h | h
      · have : sSup (f '' S) ≤ f (Z ω) := by
          apply csSup_le hne
          rintro _ ⟨w, hw, rfl⟩
          exact hf (hlt w hw _ h).le
        exact mul_nonpos_of_nonneg_of_nonpos (by linarith) (by linarith)
      · rw [h]; simp
      · have : f (Z ω) ≤ sSup (f '' S) := le_csSup hbdd ⟨Z ω, h, rfl⟩
        exact mul_nonpos_of_nonpos_of_nonneg (by linarith) (by linarith)
    · push Not at h2
      have hnn : 0 ≤ fun ω => b - g (Z ω) := fun ω => by simp [h2 (Z ω)]
      have hz : ∫ ω, (b - g (Z ω)) ∂P = 0 := by
        rw [integral_sub (integrable_const _) hBi]; simp [hb]
      have hae := (integral_eq_zero_iff_of_nonneg hnn
        ((integrable_const _).sub hBi)).mp hz
      rw [hcov 0]
      apply integral_nonpos_of_ae
      filter_upwards [hae] with ω hω
      simp only [Pi.zero_apply] at hω ⊢
      have : g (Z ω) - b = 0 := by linarith
      rw [this]; simp
  · push Not at h1
    have hnn : 0 ≤ fun ω => g (Z ω) - b := fun ω => by simp [h1 (Z ω)]
    have hae := (integral_eq_zero_iff_of_nonneg hnn
      (hBi.sub (integrable_const _))).mp hB0
    rw [hcov 0]
    apply integral_nonpos_of_ae
    filter_upwards [hae] with ω hω
    simp only [Pi.zero_apply] at hω ⊢
    rw [hω]; simp

#print axioms av_cov_nonpos

/-- A control variate. Let `X` be the payoff and `Y` a companion payoff on the same path,
both with finite variance. With the slope `β = cov(X, Y) / var(Y)` and the correlation `ρ`:
what is left, `X - β Y`, scatters `(1 - ρ²)` times as widely as `X`;
no other slope `c` leaves less scatter; and subtracting any slope `c` times the companion's
slip from its true value `E[Y]` leaves the true average unchanged. -/
theorem control_variate_shrinks_variance_by_one_minus_rho_sq (X Y : Ω → ℝ)
    (hX : MemLp X 2 P) (hY : MemLp Y 2 P) :
    Var[fun ω => X ω - cov[X, Y; P] / Var[Y; P] * Y ω; P] =
        (1 - (cov[X, Y; P] / (Real.sqrt Var[X; P] * Real.sqrt Var[Y; P])) ^ 2) * Var[X; P] ∧
    (∀ c : ℝ, Var[fun ω => X ω - cov[X, Y; P] / Var[Y; P] * Y ω; P] ≤
        Var[fun ω => X ω - c * Y ω; P]) ∧
    (∀ c : ℝ, ∫ ω, (X ω - c * (Y ω - ∫ ω', Y ω' ∂P)) ∂P = ∫ ω, X ω ∂P) := by
  have key := cv_var_sub_mul X Y hX hY
  have cs := cv_cov_sq_le X Y hX hY
  have hvX := variance_nonneg X P
  refine ⟨?_, ?_, ?_⟩
  · rw [key]
    rcases (variance_nonneg Y P).eq_or_lt with hv | hv
    · rw [← hv] at cs ⊢
      have : cov[X, Y; P] = 0 := by nlinarith
      simp [this]
    · rcases hvX.eq_or_lt with hx | hx
      · rw [← hx] at cs ⊢
        have : cov[X, Y; P] = 0 := by nlinarith
        simp [this]
      · rw [show (cov[X, Y; P] / (Real.sqrt Var[X; P] * Real.sqrt Var[Y; P])) ^ 2
            = cov[X, Y; P] ^ 2 / (Var[X; P] * Var[Y; P]) by
          rw [div_pow, mul_pow, Real.sq_sqrt hvX, Real.sq_sqrt hv.le]]
        field_simp
        ring
  · intro c
    rw [key, key]
    rcases (variance_nonneg Y P).eq_or_lt with hv | hv
    · rw [← hv] at cs ⊢
      have : cov[X, Y; P] = 0 := by nlinarith
      simp [this]
    · have h2 : (Var[X; P] - 2 * c * cov[X, Y; P] + c ^ 2 * Var[Y; P]) -
          (Var[X; P] - 2 * (cov[X, Y; P] / Var[Y; P]) * cov[X, Y; P] +
            (cov[X, Y; P] / Var[Y; P]) ^ 2 * Var[Y; P])
          = (c * Var[Y; P] - cov[X, Y; P]) ^ 2 / Var[Y; P] := by
        field_simp; ring
      have : 0 ≤ (c * Var[Y; P] - cov[X, Y; P]) ^ 2 / Var[Y; P] := by positivity
      linarith
  · intro c
    have hXi : Integrable X P := hX.integrable one_le_two
    have hYi : Integrable Y P := hY.integrable one_le_two
    have h1 : Integrable (fun ω => Y ω - ∫ ω', Y ω' ∂P) P := hYi.sub (integrable_const _)
    have h2 : Integrable (fun ω => c * (Y ω - ∫ ω', Y ω' ∂P)) P := h1.const_mul c
    rw [integral_sub hXi h2, integral_const_mul, integral_sub hYi (integrable_const _)]
    simp

/-- Mirrors. Let `Z` be a shock whose law is unchanged by flipping its sign (as for a
bell-curve shock), and let the payoff `f` move one way (never fall as the shock rises),
with finite variance. Then the pair average `½[f(Z) + f(-Z)]` has variance
`½ var f(Z) + ½ cov(f(Z), f(-Z))`, that covariance is never positive, and so the pair is at
most half as noisy as one path. -/
theorem antithetic_pair_at_most_half_as_noisy (Z : Ω → ℝ)
    (hsym : IdentDistrib Z (fun ω => -Z ω) P P) (f : ℝ → ℝ) (hf : Monotone f)
    (hL2 : MemLp (fun ω => f (Z ω)) 2 P) :
    Var[fun ω => (f (Z ω) + f (-Z ω)) / 2; P] =
        Var[fun ω => f (Z ω); P] / 2 + cov[fun ω => f (Z ω), fun ω => f (-Z ω); P] / 2 ∧
    cov[fun ω => f (Z ω), fun ω => f (-Z ω); P] ≤ 0 ∧
    Var[fun ω => (f (Z ω) + f (-Z ω)) / 2; P] ≤ Var[fun ω => f (Z ω); P] / 2 := by
  have hid : IdentDistrib (fun ω => f (Z ω)) (fun ω => f (-Z ω)) P P :=
    hsym.comp hf.measurable
  have hB : MemLp (fun ω => f (-Z ω)) 2 P := hid.memLp_snd hL2
  have hvar : Var[fun ω => (f (Z ω) + f (-Z ω)) / 2; P] =
      Var[fun ω => f (Z ω); P] / 2 + cov[fun ω => f (Z ω), fun ω => f (-Z ω); P] / 2 := by
    have : (fun ω => (f (Z ω) + f (-Z ω)) / 2) = fun ω => (1 / 2 : ℝ) * (f (Z ω) + f (-Z ω)) := by
      ext; ring
    rw [this, variance_const_mul, variance_fun_add hL2 hB, ← hid.variance_eq]
    ring
  have hcov : cov[fun ω => f (Z ω), fun ω => f (-Z ω); P] ≤ 0 :=
    av_cov_nonpos Z f (fun z => f (-z)) hf (fun x y h => hf (neg_le_neg h)) hL2 hB
  refine ⟨hvar, hcov, ?_⟩
  rw [hvar]; linarith

/-- The twin. On every path, with the two observed prices `a, b ≥ 0`, strike `K` and
discount factor `D ≥ 0`, the arithmetic-average ticket pays at least the geometric-average
companion, because the ordinary average `(a + b) / 2` is never below `√(a b)`. -/
theorem arithmetic_ticket_pays_at_least_geometric (a b K D : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hD : 0 ≤ D) :
    D * max (Real.sqrt (a * b) - K) 0 ≤ D * max ((a + b) / 2 - K) 0 := by
  have hs := Real.sq_sqrt (mul_nonneg ha hb)
  have hs0 := Real.sqrt_nonneg (a * b)
  have h : Real.sqrt (a * b) ≤ (a + b) / 2 := by
    nlinarith [sq_nonneg (a - b), sq_nonneg (Real.sqrt (a * b) - (a + b) / 2)]
  apply mul_le_mul_of_nonneg_left _ hD
  exact max_le_max (by linarith) le_rfl

#print axioms control_variate_shrinks_variance_by_one_minus_rho_sq
#print axioms antithetic_pair_at_most_half_as_noisy
#print axioms arithmetic_ticket_pays_at_least_geometric
