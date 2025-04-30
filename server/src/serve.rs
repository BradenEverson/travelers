//! Service Implementation

use http_body_util::{BodyExt, Full};
use hyper::{
    Method, Request, Response, StatusCode,
    body::{self, Bytes},
    service::Service,
};
use std::{
    collections::HashMap, fs::File, future::Future, io::Read, pin::Pin, str::FromStr, sync::Arc,
};
use tokio::sync::Mutex;
use url::{Url, form_urlencoded};
use uuid::Uuid;

use crate::state::{Match, ServerState, Traveler};

/// The service responsible for creating new battles
#[derive(Clone)]
pub struct BattleService {
    state: Arc<Mutex<ServerState>>,
}

impl From<Arc<Mutex<ServerState>>> for BattleService {
    fn from(state: Arc<Mutex<ServerState>>) -> Self {
        Self { state }
    }
}

impl Service<Request<body::Incoming>> for BattleService {
    type Response = Response<Full<Bytes>>;
    type Error = hyper::http::Error;
    type Future = Pin<Box<dyn Future<Output = Result<Self::Response, Self::Error>> + Send>>;

    fn call(&self, req: Request<body::Incoming>) -> Self::Future {
        let mut response = Response::builder();
        let state = self.state.clone();

        let res = async move {
            match (req.method(), req.uri().path()) {
                (&Method::GET, "/") => {
                    let mut buf = vec![];
                    let mut page = File::open("frontend/index.html").expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");
                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, "/dojo") => {
                    let mut buf = vec![];
                    let mut page = File::open("frontend/dojo.html").expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");
                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, "/battle") => {
                    let mut buf = vec![];
                    let mut page = File::open("frontend/battle.html").expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");
                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, "/get") => {
                    let uri = req.uri().to_string();
                    let queries = generate_query_map(uri);

                    let id = &queries["id"];
                    let uuid = Uuid::from_str(id).expect("Get UUID from id param");

                    let src = state.lock().await.get_source(uuid).unwrap_or(String::new());

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(src.as_bytes())))
                }

                (&Method::GET, "/leaderboard") => {
                    let mut buf = vec![];
                    let mut page =
                        File::open("frontend/leaderboard.html").expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");
                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, "/rankings") => {
                    todo!()
                }

                (&Method::GET, "/lose") => {
                    let uri = req.uri().to_string();
                    let queries = generate_query_map(uri);

                    let id = &queries["id"];
                    let uuid = Uuid::from_str(id).expect("Get UUID from id param");

                    state.lock().await.lose(uuid);

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::new()))
                }

                (&Method::GET, "/win") => {
                    let uri = req.uri().to_string();
                    let queries = generate_query_map(uri);

                    let id = &queries["id"];
                    let uuid = Uuid::from_str(id).expect("Get UUID from id param");

                    state.lock().await.win(uuid);

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::new()))
                }

                (&Method::GET, "/create") => {
                    let uri = req.uri().to_string();
                    let queries = generate_query_map(uri);

                    let id = &queries["id"];
                    let uuid = Uuid::from_str(id).expect("Get UUID from id param");

                    let games = state.lock().await.matchmake(uuid);

                    let us = games[0].source_code.clone();
                    let them: Vec<_> = games[1..].iter().map(|t| t.source_code.clone()).collect();

                    let m = Match {
                        creator: us,
                        others: them,
                    };

                    let buf = serde_json::to_string(&m).expect("Failed to deserialize");

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(buf.as_bytes())))
                }

                (&Method::GET, wasm) if wasm.starts_with("/wasm") => {
                    let mut buf = vec![];
                    let mut w =
                        File::open(format!("frontend{}", wasm)).expect("Failed to find wasm");

                    w.read_to_end(&mut buf).expect("Failed to read to buffer");

                    if wasm.ends_with("js") {
                        response = response.header("content-type", "text/javascript");
                    } else if wasm.ends_with("wasm") {
                        response = response.header("content-type", "application/wasm");
                    }

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::GET, "/favicon.ico") => {
                    let mut buf = vec![];
                    let mut page = File::open("frontend/favicon.ico").expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");
                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                (&Method::POST, "/register") => {
                    let body = req.collect().await.expect("Failed to collect body");
                    let body_bytes = body.to_bytes();

                    let form_params: HashMap<String, String> =
                        form_urlencoded::parse(&body_bytes).into_owned().collect();

                    let travler = Traveler::from_source(&form_params["code"]);

                    let id = if let Some(existing_id) = form_params.get("id") {
                        let uuid = Uuid::from_str(existing_id).expect("Parse ID");

                        state.lock().await.update(travler, uuid)
                    } else {
                        state.lock().await.register(travler)
                    };

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(
                            format!("{id}").as_bytes(),
                        )))
                }

                (&Method::GET, fs) if fs.starts_with("/frontend/") => {
                    let mut buf = vec![];
                    let mut page = File::open(&fs[1..]).expect("Failed to find file");
                    page.read_to_end(&mut buf)
                        .expect("Failed to read to buffer");

                    if fs.ends_with("css") {
                        response = response.header("content-type", "text/css");
                    }

                    response
                        .status(StatusCode::OK)
                        .body(Full::new(Bytes::copy_from_slice(&buf)))
                }

                other_combo => {
                    unimplemented!("{other_combo:?} is not a valid route pair for this server :(")
                }
            }
        };

        Box::pin(res)
    }
}

/// Creates a map for all query params
pub fn generate_query_map(uri: String) -> HashMap<String, String> {
    let request_url = Url::parse(&format!("https://site.com/{}", uri)).unwrap();

    request_url
        .query_pairs()
        .map(|(k, v)| (k.to_string(), v.to_string()))
        .collect()
}
