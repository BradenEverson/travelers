//! Server State, including registry of all source code files for all submissions ever (todo:
//! MongoDB)

use std::collections::HashMap;

use uuid::Uuid;

/// The server's internal state for matchmaking
#[derive(Debug, Default)]
pub struct ServerState {
    /// All fighters that can be pooled from
    pub fighters: HashMap<Uuid, Traveler>,
}

impl ServerState {
    /// Registers a new fighter and returns their UUID
    pub fn register(&mut self, new: Traveler) -> Uuid {
        let new_id = Uuid::new_v4();
        self.fighters.insert(new_id, new);

        new_id
    }
}

/// A fighter's script with some additional metadata
#[derive(Debug, Default, Clone)]
pub struct Traveler {
    /// Source code in FightScript
    pub source_code: String,
    /// How many wins
    pub wins: usize,
    /// How many loses
    pub losses: usize,
}
