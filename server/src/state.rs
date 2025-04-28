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
    /// Constructs a new state with placeholder defaults
    pub fn sample_config() -> Self {
        let mut state = Self::default();

        let up = Traveler::from_str("move up;").unwrap();
        let dancer =
            Traveler::from_str("while (true) { move down; move left; move up; move right; }")
                .unwrap();

        state.register(up);
        state.register(dancer);

        state.fighters.insert(
            Uuid::from_str("7d2c854f-cbf5-48c7-8ae7-5ebf90212ff3").unwrap(),
            Traveler::from_str("move up 10;").unwrap(),
        );

        state
    }
    /// Registers a new fighter and returns their UUID
    pub fn register(&mut self, new: Traveler) -> Uuid {
        let new_id = Uuid::new_v4();
        self.fighters.insert(new_id, new);

        new_id
    }

    /// Creates a set of fighters for a battle
    pub fn matchmake(&self, initiator: Uuid) -> Vec<Traveler> {
        // println!("{self:?}");
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

        println!("{fighters:?}");
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
