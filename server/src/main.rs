//! Main Web Server Runtime for the Wordle Online Service

use hyper::server::conn::http1;
use hyper_util::rt::TokioIo;
use server::{serve::BattleService, state::ServerState};
use std::{env, sync::Arc};
use tokio::{net::TcpListener, sync::Mutex};

#[tokio::main]
async fn main() {
    let port = env::var("PORT").unwrap_or_else(|_| "9449".to_string());
    let addr = format!("0.0.0.0:{}", port);

    let listener = TcpListener::bind(&addr)
        .await
        .expect("Failed to bind to default");

    let state = Arc::new(Mutex::new(ServerState::sample_config()));
    let service = BattleService::from(state);

    loop {
        let (socket, _) = listener
            .accept()
            .await
            .expect("Failed to accept connection");

        let io = TokioIo::new(socket);

        let service_local = service.clone();
        tokio::spawn(async move {
            if let Err(e) = http1::Builder::new()
                .serve_connection(io, service_local)
                .await
            {
                eprintln!("Error serving connection: {e}");
            }
        });
    }
}
