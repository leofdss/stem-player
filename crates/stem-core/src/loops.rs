// ── Tipos ─────────────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MarkerId(u64);

#[derive(Debug, Clone)]
pub struct Marker {
    pub id: MarkerId,
    pub label: Option<String>,
    pub position: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LoopRegion {
    pub start: u64,
    pub end: u64,
}

#[derive(Debug, thiserror::Error, PartialEq, Eq)]
pub enum LoopError {
    #[error("region start must be strictly less than end")]
    EmptyRegion,
    #[error("position is beyond track length")]
    OutOfBounds,
}

#[derive(Debug)]
pub struct LoopEngine {
    track_len: u64,
    markers: Vec<Marker>,
    next_id: u64,
    region: Option<LoopRegion>,
    enabled: bool,
}

// ── API ───────────────────────────────────────────────────────────────────────

impl LoopEngine {
    pub fn new(track_len: u64) -> Self {
        Self {
            track_len,
            markers: Vec::new(),
            next_id: 0,
            region: None,
            enabled: false,
        }
    }

    pub fn add_marker(
        &mut self,
        position: u64,
        label: Option<String>,
    ) -> Result<MarkerId, LoopError> {
        if position >= self.track_len {
            return Err(LoopError::OutOfBounds);
        }
        let id = MarkerId(self.next_id);
        self.next_id += 1;
        self.markers.push(Marker {
            id,
            label,
            position,
        });
        Ok(id)
    }

    pub fn remove_marker(&mut self, id: MarkerId) {
        self.markers.retain(|m| m.id != id);
    }

    pub fn markers(&self) -> &[Marker] {
        &self.markers
    }

    pub fn set_region(&mut self, start: u64, end: u64) -> Result<(), LoopError> {
        if start >= end {
            return Err(LoopError::EmptyRegion);
        }
        if end > self.track_len {
            return Err(LoopError::OutOfBounds);
        }
        self.region = Some(LoopRegion { start, end });
        Ok(())
    }

    pub fn region(&self) -> Option<&LoopRegion> {
        self.region.as_ref()
    }

    pub fn enable(&mut self) {
        self.enabled = true;
    }

    pub fn disable(&mut self) {
        self.enabled = false;
    }

    pub fn is_enabled(&self) -> bool {
        self.enabled
    }

    // Loop inativo ou sem região → position + frames (sem wrap).
    // Loop ativo com position dentro de [start, end) → wrap por módulo ao cruzar end.
    // position fora da região → apenas soma (o playhead entra na região naturalmente).
    pub fn advance(&self, position: u64, frames: u64) -> u64 {
        if let (true, Some(region)) = (self.enabled, &self.region)
            && position >= region.start
            && position < region.end
        {
            let raw = position + frames;
            if raw < region.end {
                return raw;
            }
            let size = region.end - region.start;
            return region.start + ((raw - region.start) % size);
        }
        position + frames
    }
}

// ── Testes ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    // ── helpers ───────────────────────────────────────────────────────────────

    fn engine(track_len: u64) -> LoopEngine {
        LoopEngine::new(track_len)
    }

    fn engine_with_active_region(track_len: u64, start: u64, end: u64) -> LoopEngine {
        let mut e = LoopEngine::new(track_len);
        e.set_region(start, end).unwrap();
        e.enable();
        e
    }

    // ── 2. Marcadores ─────────────────────────────────────────────────────────

    #[test]
    fn add_marker_valid_position_returns_unique_id_and_appears_in_list() {
        // Scenario: Marcador criado com sucesso
        let mut e = engine(1000);

        let id_a = e.add_marker(100, Some("intro".into())).unwrap();
        let id_b = e.add_marker(500, None).unwrap();

        assert_ne!(id_a, id_b, "ids must be unique");
        let markers = e.markers();
        assert_eq!(markers.len(), 2);
        assert!(markers.iter().any(|m| m.id == id_a && m.position == 100));
        assert!(markers.iter().any(|m| m.id == id_b && m.position == 500));
    }

    #[test]
    fn add_marker_at_track_boundary_is_valid() {
        let mut e = engine(1000);
        // posição igual a track_len − 1 é o último frame válido
        let result = e.add_marker(999, None);
        assert!(result.is_ok());
    }

    #[test]
    fn add_marker_beyond_track_len_returns_out_of_bounds() {
        // Scenario: Marcador fora dos limites da faixa
        let mut e = engine(1000);
        let err = e.add_marker(1000, None).unwrap_err();
        assert_eq!(err, LoopError::OutOfBounds);
    }

    #[test]
    fn remove_marker_removes_it_from_list() {
        let mut e = engine(1000);
        let id = e.add_marker(200, None).unwrap();
        e.remove_marker(id);
        assert!(e.markers().iter().all(|m| m.id != id));
    }

    // ── 3. Região de loop ─────────────────────────────────────────────────────

    #[test]
    fn set_region_valid_stores_region() {
        // Scenario: Região válida
        let mut e = engine(1000);
        e.set_region(100, 400).unwrap();
        let r = e.region().expect("region must be set");
        assert_eq!(r.start, 100);
        assert_eq!(r.end, 400);
    }

    #[test]
    fn set_region_start_equal_end_returns_empty_region() {
        // Scenario: Região vazia ou invertida — start == end
        let mut e = engine(1000);
        let err = e.set_region(300, 300).unwrap_err();
        assert_eq!(err, LoopError::EmptyRegion);
    }

    #[test]
    fn set_region_start_greater_than_end_returns_empty_region() {
        // Scenario: Região vazia ou invertida — start > end
        let mut e = engine(1000);
        let err = e.set_region(500, 200).unwrap_err();
        assert_eq!(err, LoopError::EmptyRegion);
    }

    #[test]
    fn set_region_end_beyond_track_len_returns_out_of_bounds() {
        // Scenario: Região fora dos limites
        let mut e = engine(1000);
        let err = e.set_region(900, 1001).unwrap_err();
        assert_eq!(err, LoopError::OutOfBounds);
    }

    #[test]
    fn set_region_end_exactly_at_track_len_is_valid() {
        // end == track_len é o limite semiaberto válido
        let mut e = engine(1000);
        assert!(e.set_region(0, 1000).is_ok());
    }

    #[test]
    fn region_returns_none_when_not_set() {
        let e = engine(1000);
        assert!(e.region().is_none());
    }

    // ── 3.5 Ativar / desativar ────────────────────────────────────────────────

    #[test]
    fn enable_disable_toggles_state() {
        // Scenario: Alternar o estado do loop
        let mut e = engine(1000);
        e.set_region(0, 500).unwrap();

        e.enable();
        assert!(e.is_enabled());

        e.disable();
        assert!(!e.is_enabled());
    }

    #[test]
    fn loop_starts_disabled() {
        let e = engine(1000);
        assert!(!e.is_enabled());
    }

    // ── 4. Reposicionamento ───────────────────────────────────────────────────

    #[test]
    fn advance_within_region_returns_simple_sum() {
        // Scenario: Avanço dentro da região
        // região [100, 500), posição 200, avança 100 → 300 (não cruza 500)
        let e = engine_with_active_region(1000, 100, 500);
        assert_eq!(e.advance(200, 100), 300);
    }

    #[test]
    fn advance_to_exact_end_wraps_to_start() {
        // posição 400, avança 100 → raw == end → volta ao início
        // start + (raw - start) % size = 100 + (500 - 100) % 400 = 100 + 0 = 100
        let e = engine_with_active_region(1000, 100, 500);
        assert_eq!(e.advance(400, 100), 100);
    }

    #[test]
    fn advance_crossing_end_wraps_preserving_overshoot() {
        // Scenario: Avanço que cruza o fim da região
        // região [100, 500), posição 450, avança 100 → raw 550
        // excedente = 550 − 500 = 50, resultado = 100 + 50 = 150
        let e = engine_with_active_region(1000, 100, 500);
        assert_eq!(e.advance(450, 100), 150);
    }

    #[test]
    fn advance_larger_than_region_wraps_with_modulo() {
        // Scenario: Avanço maior que a região
        // região [0, 100), posição 0, avança 250 → 250 % 100 = 50
        let e = engine_with_active_region(1000, 0, 100);
        assert_eq!(e.advance(0, 250), 50);
    }

    #[test]
    fn advance_multiple_wraps_in_single_call() {
        // região [0, 100), posição 0, avança 305 → 305 % 100 = 5
        let e = engine_with_active_region(1000, 0, 100);
        assert_eq!(e.advance(0, 305), 5);
    }

    #[test]
    fn advance_loop_inactive_no_wrap() {
        // Scenario: Loop inativo — avança além do fim sem wrap
        let mut e = engine(1000);
        e.set_region(100, 500).unwrap();
        // loop NÃO está habilitado
        assert_eq!(e.advance(450, 100), 550);
    }

    #[test]
    fn advance_no_region_no_wrap() {
        // Sem região definida, loop inativo por definição
        let e = engine(1000);
        assert_eq!(e.advance(900, 50), 950);
    }

    #[test]
    fn advance_position_outside_region_no_wrap_until_inside() {
        // playhead antes da região: apenas soma, sem wrap
        // região [200, 400), posição 50, avança 100 → 150 (ainda fora)
        let e = engine_with_active_region(1000, 200, 400);
        assert_eq!(e.advance(50, 100), 150);
    }

    // ── casos de borda da spec ────────────────────────────────────────────────

    #[test]
    fn advance_region_starting_at_frame_zero() {
        // região começa no primeiro frame da faixa
        let e = engine_with_active_region(1000, 0, 50);
        assert_eq!(e.advance(40, 20), 10); // 40 + 20 = 60 → 0 + (60 % 50) = 10
    }

    #[test]
    fn advance_region_ending_at_last_frame() {
        // região termina no último frame da faixa
        let e = engine_with_active_region(1000, 950, 1000);
        // posição 980, avança 30 → raw 1010 → start + (1010 − 950) % 50 = 950 + 10 = 960
        assert_eq!(e.advance(980, 30), 960);
    }

    #[test]
    fn add_marker_label_is_preserved() {
        let mut e = engine(1000);
        let id = e.add_marker(42, Some("verse".into())).unwrap();
        let marker = e.markers().iter().find(|m| m.id == id).unwrap();
        assert_eq!(marker.label.as_deref(), Some("verse"));
        assert_eq!(marker.position, 42);
    }
}
