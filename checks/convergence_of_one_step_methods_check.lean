-- From local error to global error: a one-step method whose increment is Lipschitz and whose local truncation error is at most C h^p ends every run off by at most C h^p (e^(Λ t_n) - 1) / Λ.
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Analysis.Normed.Module.Basic

open Real

/-- The power `(1 + hΛ)^n` sits below `e^(Λ n h)`, so the discrete bound sits below the exponential one. -/
theorem one_step_pow_bound_le_exp (h Λ B : ℝ) (hh : 0 ≤ h) (hΛ : 0 < Λ) (hB : 0 ≤ B)
    (n : ℕ) : B * ((1 + h * Λ) ^ n - 1) / Λ ≤ B * (exp (Λ * (n * h)) - 1) / Λ := by
  have h1 : 0 ≤ 1 + h * Λ := by positivity
  have h2 : 1 + h * Λ ≤ exp (h * Λ) := by linarith [Real.add_one_le_exp (h * Λ)]
  have h3 : (1 + h * Λ) ^ n ≤ exp (Λ * (n * h)) := by
    have : exp (Λ * (n * h)) = exp (h * Λ) ^ n := by
      rw [← Real.exp_nat_mul]; ring_nf
    rw [this]
    exact pow_le_pow_left₀ h1 h2 n
  apply div_le_div_of_nonneg_right _ hΛ.le
  apply mul_le_mul_of_nonneg_left _ hB
  linarith

/-- A discrete Gronwall bound along a run of `N` steps, with `B ≥ 0`. -/
theorem one_step_gronwall_upto (a : ℕ → ℝ) (h Λ B : ℝ) (N : ℕ) (hh : 0 ≤ h) (hΛ : 0 < Λ)
    (h0 : a 0 ≤ 0) (hrec : ∀ m < N, a (m + 1) ≤ (1 + h * Λ) * a m + h * B) :
    ∀ n ≤ N, a n ≤ B * ((1 + h * Λ) ^ n - 1) / Λ := by
  intro n
  induction n with
  | zero => intro _; simpa using h0
  | succ m ih =>
    intro hm
    have ihm := ih (by omega)
    have hpos : 0 ≤ 1 + h * Λ := by positivity
    calc a (m + 1) ≤ (1 + h * Λ) * a m + h * B := hrec m (by omega)
      _ ≤ (1 + h * Λ) * (B * ((1 + h * Λ) ^ m - 1) / Λ) + h * B := by gcongr
      _ = B * ((1 + h * Λ) ^ (m + 1) - 1) / Λ := by
        field_simp
        ring

/-- One RK stage: the gap after a stage is at most `L (gap + c D)`. -/
theorem one_step_rk_stage {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℝ → E → E) (L c D : ℝ) (hL : 0 ≤ L) (hc : 0 ≤ c)
    (hf : ∀ t a b, ‖f t a - f t b‖ ≤ L * ‖a - b‖) (s : ℝ) (u v ku kv : E)
    (hk : ‖ku - kv‖ ≤ D) :
    ‖f s (u + c • ku) - f s (v + c • kv)‖ ≤ L * (‖u - v‖ + c * D) := by
  calc ‖f s (u + c • ku) - f s (v + c • kv)‖ ≤ L * ‖(u + c • ku) - (v + c • kv)‖ := hf _ _ _
    _ ≤ L * (‖u - v‖ + c * D) := by
      apply mul_le_mul_of_nonneg_left _ hL
      have : (u + c • ku) - (v + c • kv) = (u - v) + c • (ku - kv) := by
        rw [smul_sub]; abel
      rw [this]
      calc ‖(u - v) + c • (ku - kv)‖ ≤ ‖u - v‖ + ‖c • (ku - kv)‖ := norm_add_le _ _
        _ = ‖u - v‖ + c * ‖ku - kv‖ := by rw [norm_smul, Real.norm_of_nonneg hc]
        _ ≤ ‖u - v‖ + c * D := by gcongr

/-- The global error bound. A one-step method steps `xs (n+1) = xs n + h • Φ (t_n) (xs n) h`
with `t_n = n h`, starting from the exact value `xs 0 = x 0`. Suppose its increment function
`Φ` stretches the gap between two states by at most `Λ` in size, and the local truncation error
`τ_n = (x (t_(n+1)) - x (t_n)) / h - Φ (t_n) (x (t_n)) h` of the exact solution `x` has size at
most `C h^p` at every step of the run. Then after `n ≤ N` steps the global error
`e_n = x (t_n) - xs n` has size at most `C h^p (e^(Λ t_n) - 1) / Λ`: order `p` per step gives
order `p` overall. -/
theorem global_error_le_of_local_truncation_error
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (Φ : ℝ → E → ℝ → E) (x : ℝ → E) (xs : ℕ → E)
    (h Λ C : ℝ) (p N : ℕ) (hh : 0 < h) (hΛ : 0 < Λ)
    (hLip : ∀ t a b, ‖Φ t a h - Φ t b h‖ ≤ Λ * ‖a - b‖)
    (hstep : ∀ n, xs (n + 1) = xs n + h • Φ (n * h) (xs n) h)
    (hstart : xs 0 = x 0)
    (htau : ∀ n < N,
      ‖h⁻¹ • (x ((n + 1) * h) - x (n * h)) - Φ (n * h) (x (n * h)) h‖ ≤ C * h ^ p) :
    ∀ n ≤ N, ‖x (n * h) - xs n‖ ≤ C * h ^ p * (exp (Λ * (n * h)) - 1) / Λ := by
  intro n hn
  have hB : 0 ≤ C * h ^ p ∨ n = 0 := by
    rcases Nat.eq_zero_or_pos n with h0 | hpos
    · exact Or.inr h0
    · left
      have := htau 0 (by omega)
      exact le_trans (norm_nonneg _) this
  have key : ∀ m < N, ‖x (((m + 1 : ℕ) : ℝ) * h) - xs (m + 1)‖ ≤
      (1 + h * Λ) * ‖x ((m : ℝ) * h) - xs m‖ + h * (C * h ^ p) := by
    intro m hm
    have hτ := htau m hm
    have hd : x (((m + 1 : ℕ) : ℝ) * h) - xs (m + 1) =
        (x ((m : ℝ) * h) - xs m) + h • (Φ (m * h) (x (m * h)) h - Φ (m * h) (xs m) h)
          + h • (h⁻¹ • (x ((m + 1) * h) - x (m * h)) - Φ (m * h) (x (m * h)) h) := by
      rw [hstep m, smul_sub, smul_sub, smul_smul, mul_inv_cancel₀ hh.ne', one_smul]
      push_cast
      abel
    rw [hd]
    calc _ ≤ ‖(x ((m : ℝ) * h) - xs m) + h • (Φ (m * h) (x (m * h)) h - Φ (m * h) (xs m) h)‖
          + ‖h • (h⁻¹ • (x ((m + 1) * h) - x (m * h)) - Φ (m * h) (x (m * h)) h)‖ :=
          norm_add_le _ _
      _ ≤ (‖x ((m : ℝ) * h) - xs m‖ + ‖h • (Φ (m * h) (x (m * h)) h - Φ (m * h) (xs m) h)‖)
          + ‖h • (h⁻¹ • (x ((m + 1) * h) - x (m * h)) - Φ (m * h) (x (m * h)) h)‖ := by
          gcongr; exact norm_add_le _ _
      _ = (‖x ((m : ℝ) * h) - xs m‖ + h * ‖Φ (m * h) (x (m * h)) h - Φ (m * h) (xs m) h‖)
          + h * ‖h⁻¹ • (x ((m + 1) * h) - x (m * h)) - Φ (m * h) (x (m * h)) h‖ := by
          rw [norm_smul, norm_smul, Real.norm_of_nonneg hh.le]
      _ ≤ (‖x ((m : ℝ) * h) - xs m‖ + h * (Λ * ‖x (m * h) - xs m‖)) + h * (C * h ^ p) := by
          gcongr
          exact hLip _ _ _
      _ = (1 + h * Λ) * ‖x ((m : ℝ) * h) - xs m‖ + h * (C * h ^ p) := by ring
  have h0 : ‖x (((0 : ℕ) : ℝ) * h) - xs 0‖ ≤ 0 := by simp [hstart]
  have hg := one_step_gronwall_upto (fun m => ‖x ((m : ℝ) * h) - xs m‖) h Λ (C * h ^ p) N
    hh.le hΛ h0 key n hn
  rcases hB with hB | hn0
  · exact le_trans hg (one_step_pow_bound_le_exp h Λ _ hh.le hΛ hB n)
  · subst hn0; simp [hstart]

/-- The discrete Gronwall lemma. If `a_0 = 0` and `a_(m+1) ≤ (1 + hΛ) a_m + hB` for every `m`,
with `h`, `Λ`, `B` positive, then `a_n ≤ B ((1 + hΛ)^n - 1) / Λ` for every `n`, and this is at
most `B (e^(Λ n h) - 1) / Λ`. -/
theorem discrete_gronwall
    (a : ℕ → ℝ) (h Λ B : ℝ) (hh : 0 < h) (hΛ : 0 < Λ) (hB : 0 < B)
    (h0 : a 0 = 0) (hrec : ∀ m, a (m + 1) ≤ (1 + h * Λ) * a m + h * B) :
    ∀ n, a n ≤ B * ((1 + h * Λ) ^ n - 1) / Λ ∧
      B * ((1 + h * Λ) ^ n - 1) / Λ ≤ B * (exp (Λ * (n * h)) - 1) / Λ := by
  intro n
  refine ⟨one_step_gronwall_upto a h Λ B (n + 1) hh.le hΛ h0.le (fun m _ => hrec m) n
    (by omega), one_step_pow_bound_le_exp h Λ B hh.le hΛ hB.le n⟩

/-- RK4's increment inherits a Lipschitz constant from the rate law. If the rate law `f`
stretches gaps by at most `L`, then RK4's increment
`Φ = (k₁ + 2 k₂ + 2 k₃ + k₄) / 6` stretches them by at most
`Λ = L (1 + hL/2 + (hL)^2/6 + (hL)^3/24)`. -/
theorem rk4_increment_lipschitz
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : ℝ → E → E) (L h : ℝ) (hh : 0 < h)
    (hf : ∀ t a b, ‖f t a - f t b‖ ≤ L * ‖a - b‖) :
    let Φ : ℝ → E → E := fun t y =>
      let k₁ := f t y
      let k₂ := f (t + h / 2) (y + (h / 2) • k₁)
      let k₃ := f (t + h / 2) (y + (h / 2) • k₂)
      let k₄ := f (t + h) (y + h • k₃)
      (1 / 6 : ℝ) • (k₁ + (2 : ℝ) • k₂ + (2 : ℝ) • k₃ + k₄)
    ∀ t a b, ‖Φ t a - Φ t b‖ ≤
      L * (1 + h * L / 2 + (h * L) ^ 2 / 6 + (h * L) ^ 3 / 24) * ‖a - b‖ := by
  intro Φ t a b
  by_cases hab : a = b
  · subst hab; simp
  have hL : 0 ≤ L := by
    have h1 := hf t a b
    have h2 : 0 < ‖a - b‖ := norm_pos_iff.mpr (sub_ne_zero.mpr hab)
    by_contra hneg0
    have hneg : L < 0 := not_le.mp hneg0
    have : L * ‖a - b‖ < 0 := mul_neg_of_neg_of_pos hneg h2
    linarith [norm_nonneg (f t a - f t b)]
  set d := ‖a - b‖ with hd
  have e1 : ‖f t a - f t b‖ ≤ L * d := hf t a b
  have e2 := one_step_rk_stage f L (h / 2) (L * d) hL (by positivity) hf (t + h / 2) a b
    (f t a) (f t b) e1
  have e3 := one_step_rk_stage f L (h / 2) (L * (d + h / 2 * (L * d))) hL (by positivity) hf
    (t + h / 2) a b _ _ e2
  have e4 := one_step_rk_stage f L h (L * (d + h / 2 * (L * (d + h / 2 * (L * d))))) hL
    hh.le hf (t + h) a b _ _ e3
  rw [← hd] at e2 e3 e4
  simp only [Φ]
  rw [← smul_sub]
  have hsplit : ∀ (A1 A2 A3 A4 B1 B2 B3 B4 : E),
      (A1 + (2 : ℝ) • A2 + (2 : ℝ) • A3 + A4) - (B1 + (2 : ℝ) • B2 + (2 : ℝ) • B3 + B4)
        = (A1 - B1) + (2 : ℝ) • (A2 - B2) + (2 : ℝ) • (A3 - B3) + (A4 - B4) := by
    intros; simp only [smul_sub]; abel
  rw [hsplit, norm_smul, Real.norm_of_nonneg (by norm_num)]
  set D1 := f t a - f t b
  set D2 := f (t + h / 2) (a + (h / 2) • f t a) - f (t + h / 2) (b + (h / 2) • f t b)
  set D3 := f (t + h / 2) (a + (h / 2) • f (t + h / 2) (a + (h / 2) • f t a)) -
    f (t + h / 2) (b + (h / 2) • f (t + h / 2) (b + (h / 2) • f t b))
  have hn : ‖D1 + (2 : ℝ) • D2 + (2 : ℝ) • D3 + (f (t + h) (a + h • f (t + h / 2)
      (a + (h / 2) • f (t + h / 2) (a + (h / 2) • f t a))) - f (t + h) (b + h • f (t + h / 2)
      (b + (h / 2) • f (t + h / 2) (b + (h / 2) • f t b))))‖ ≤
      ‖D1‖ + 2 * ‖D2‖ + 2 * ‖D3‖ + ‖f (t + h) (a + h • f (t + h / 2)
      (a + (h / 2) • f (t + h / 2) (a + (h / 2) • f t a))) - f (t + h) (b + h • f (t + h / 2)
      (b + (h / 2) • f (t + h / 2) (b + (h / 2) • f t b)))‖ := by
    have g : ∀ (X Y Z W : E), ‖X + (2 : ℝ) • Y + (2 : ℝ) • Z + W‖ ≤
        ‖X‖ + 2 * ‖Y‖ + 2 * ‖Z‖ + ‖W‖ := by
      intro X Y Z W
      have hY : ‖(2 : ℝ) • Y‖ = 2 * ‖Y‖ := by rw [norm_smul]; norm_num
      have hZ : ‖(2 : ℝ) • Z‖ = 2 * ‖Z‖ := by rw [norm_smul]; norm_num
      have a1 := norm_add_le (X + (2 : ℝ) • Y + (2 : ℝ) • Z) W
      have a2 := norm_add_le (X + (2 : ℝ) • Y) ((2 : ℝ) • Z)
      have a3 := norm_add_le X ((2 : ℝ) • Y)
      linarith
    exact g _ _ _ _
  calc _ ≤ 1 / 6 * (L * d + 2 * (L * (d + h / 2 * (L * d)))
        + 2 * (L * (d + h / 2 * (L * (d + h / 2 * (L * d)))))
        + L * (d + h * (L * (d + h / 2 * (L * (d + h / 2 * (L * d))))))) := by
        gcongr
        refine hn.trans ?_
        gcongr
    _ = L * (1 + h * L / 2 + (h * L) ^ 2 / 6 + (h * L) ^ 3 / 24) * d := by ring

-- Halving the step: the global error falls by 2^4 = 16, one step's error by 2^5 = 32.
example : (2 : ℕ) ^ 4 = 16 := by norm_num
example : (2 : ℕ) ^ 5 = 32 := by norm_num
-- RK4's weights add to 1; the faulty weights of mistake 3 add to 7/6.
example : (1 / 6 + 1 / 3 + 1 / 3 + 1 / 6 : ℚ) = 1 := by norm_num
example : (1 / 6 + 1 / 3 + 1 / 3 + 1 / 3 : ℚ) = 7 / 6 := by norm_num
-- The weighted slope bounds of the RK4 proof add up to the card's Λ / L.
example (z : ℚ) : (1 + 2 * (1 + z / 2) + 2 * (1 + z / 2 + z ^ 2 / 4)
    + (1 + z + z ^ 2 / 2 + z ^ 3 / 4)) / 6 = 1 + z / 2 + z ^ 2 / 6 + z ^ 3 / 24 := by ring

#print axioms one_step_pow_bound_le_exp
#print axioms one_step_gronwall_upto
#print axioms one_step_rk_stage
#print axioms global_error_le_of_local_truncation_error
#print axioms discrete_gronwall
#print axioms rk4_increment_lipschitz
