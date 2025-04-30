//! Server State, including registry of all source code files for all submissions ever (todo:
//! MongoDB)

use std::{collections::HashMap, str::FromStr};

use rand::{rng, seq::IteratorRandom};
use serde::Serialize;
use uuid::Uuid;

/// Most travelers in a fight
const MATCHMAKER_MAX: usize = 32;

/// The server's internal state for matchmaking
#[derive(Debug, Default)]
pub struct ServerState {
    /// All fighters that can be pooled from
    pub fighters: HashMap<Uuid, Traveler>,
}

impl ServerState {
    /// Gets the source code for a fighter if they exist
    pub fn get_source(&self, id: Uuid) -> Option<String> {
        self.fighters.get(&id).map(|t| t.source_code.clone())
    }

    /// Marks a traveler as winning the round
    pub fn win(&mut self, id: Uuid) {
        self.fighters.get_mut(&id).map(|t| t.wins += 1);
    }

    /// Marks a traveler as losing the round
    pub fn lose(&mut self, id: Uuid) {
        self.fighters.get_mut(&id).map(|t| t.losses += 1);
    }

    /// Registers a new fighter and returns their UUID
    pub fn update(&mut self, new: Traveler, id: Uuid) -> Uuid {
        if let Some(existing) = self.fighters.get_mut(&id) {
            *existing = new;
            id
        } else {
            self.register(new)
        }
    }

    /// Registers a new fighter and returns their UUID
    pub fn register(&mut self, new: Traveler) -> Uuid {
        let new_id = Uuid::new_v4();
        self.fighters.insert(new_id, new);

        new_id
    }

    /// Creates a set of fighters for a battle
    pub fn matchmake(&self, initiator: Uuid) -> Vec<Traveler> {
        let init = self.fighters[&initiator].clone();
        let mut contendors: Vec<_> = self
            .fighters
            .iter()
            .filter(|(key, _)| *key != &initiator)
            .map(|(_, v)| v.clone())
            .collect();

        let mut fighters = vec![init];

        for _ in 0..(contendors.len().min(MATCHMAKER_MAX - 1)) {
            let (i, out) = contendors
                .iter()
                .cloned()
                .enumerate()
                .choose(&mut rng())
                .unwrap();

            fighters.push(out);
            contendors.remove(i);
        }

        fighters
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

impl FromStr for Traveler {
    type Err = ();
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(Self {
            source_code: s.into(),
            wins: 0,
            losses: 0,
        })
    }
}

impl Traveler {
    /// Creates a new traveler from source
    pub fn from_source<STR: Into<String>>(src: STR) -> Self {
        Self {
            source_code: src.into(),
            wins: 0,
            losses: 0,
        }
    }

    /// When a traveler wins
    pub fn win(&mut self) {
        self.wins += 1;
    }

    /// When a traveler loses
    pub fn lose(&mut self) {
        self.losses += 1;
    }
}

/// Match metadata for js
#[derive(Clone, Debug, Serialize)]
pub struct Match {
    /// Creator's script
    pub creator: String,
    /// All other scripts
    pub others: Vec<String>,
}
